extends SceneTree
## M3.7 通用属性系统（stat_mod 通用层）验收测试 —— 待实现
##
## 运行：
##   ... --headless --path . --script res://tests/pending/stat_system_test.gd
##
## 与 `stat_mod_test.gd` 的分工：
##   - `stat_mod_test.gd` 测**规则**：defense_down 每层让受到的伤害 +1，单位攻击和指令卡都吃。
##   - 本文件测**通用性**：属性查询是一层可复用的东西，不是为 `defense_down` 写死的分支。
##
## 判定标准（本文件的核心）：下面用的 `attack_up` / `defense_up` / 未知属性
## 都**不在** `data/tables/statuses.json` 里，而是运行时注入到 `status_table.statuses`。
## 也就是说：实现不许认状态 id、不许认写死的属性名列表——
## 只要数据里有一条 `stat_mod`，系统就该认它。
##
## 【启用方式】全绿后移到 tests/ 下。

var failures: int = 0
var checks: int = 0
var table: ReactionTable

const EXPECTED_CHECKS := 18

## 运行时注入的状态定义（不进 data/，避免动 data_test 的状态计数）
const ATTACK_UP := {
	"name": "攻击上升",
	"effects": [ { "kind": "stat_mod", "stat": "attack", "value": 2.0, "timing": "passive" } ]
}
const DEFENSE_UP := {
	"name": "防御上升",
	"effects": [ { "kind": "stat_mod", "stat": "defense", "value": 3.0, "timing": "passive" } ]
}
const ATTACK_UP_TURN_START := {
	"name": "错误时机",
	"effects": [ { "kind": "stat_mod", "stat": "attack", "value": 2.0, "timing": "turn_start" } ]
}
const UNKNOWN_STAT := {
	"name": "未知属性",
	"effects": [ { "kind": "stat_mod", "stat": "luck", "value": 9.0, "timing": "passive" } ]
}
## 不写 timing 的 stat_mod：应当按「常驻」处理，而不是被丢掉。
## （validate_data 对 stat_mod 只强制 stat/value，timing 可缺省。）
const NO_TIMING := {
	"name": "无时机字段",
	"effects": [ { "kind": "stat_mod", "stat": "attack", "value": 4.0 } ]
}


func _initialize() -> void:
	print("========== 通用属性系统测试（M3.7 stat_mod 通用层） ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	# `stat_of` 还没有时直接判红，而不是让整个文件编译失败（那样会显示成 0 项检查、
	# 看不出「是不是根本没实现」，与 deck_build_test 的处理一致）。
	var probe := Battle.new()
	if not probe.has_method("stat_of"):
		for i in range(EXPECTED_CHECKS):
			_check(false, "Battle 还没有 stat_of(unit, stat)（共 %d 项全记失败）" % EXPECTED_CHECKS)
		_finish()
		return

	_test_baseline()
	_test_attack_stat()
	_test_defense_stat()
	_test_combined()
	_test_timing_filter()
	_test_no_timing()
	_test_unknown_stat()

	_finish()


func _finish() -> void:
	if checks != EXPECTED_CHECKS:
		printerr("  [FAIL] 覆盖不完整：本文件应执行 %d 项检查，实际 %d 项" % [EXPECTED_CHECKS, checks])
		failures += 1

	print("---------------------------------------")
	print("共 %d 项检查，失败 %d 项" % [checks, failures])
	if failures == 0:
		print("PASS")
		quit(0)
	else:
		print("FAIL")
		quit(1)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  [ok]   %s" % message)
	else:
		failures += 1
		printerr("  [FAIL] %s" % message)


func _check_eq(actual, expected, message: String) -> void:
	_check(actual == expected, "%s（期望 %s，实际 %s）" % [message, str(expected), str(actual)])


func _new_battle() -> Battle:
	var b := Battle.new()
	var player := Unit.from_dict({ "id": "player", "name": "旅行者", "hp": 60 })
	var enemy := Unit.from_dict({ "id": "enemy", "name": "训练假人", "hp": 9999 })
	var enemies: Array[Unit] = [enemy]
	b.setup(player, enemies, DataLoader.load_cards(), table, 20261201)
	b.start_battle()
	b.energy = 10
	return b


## 注入一个 test-only 状态定义（不进 data/tables/statuses.json）
func _inject(b: Battle, id: String, d: Dictionary) -> void:
	b.status_table.statuses[id] = d


func _atk(b: Battle, attack: int = 3) -> Unit:
	var u := Unit.from_dict({ "id": "atk", "name": "攻", "hp": 20, "attack": attack, "owner": "player" })
	assert(b.board.place(u, "front", 1), "攻击者必须放置成功")
	return u


func _target(b: Battle, hp: int = 10) -> Unit:
	var u := Unit.from_dict({ "id": "tgt", "name": "靶", "hp": hp, "attack": 1, "owner": "enemy" })
	assert(b.board.place(u, "enemy_support", 1), "靶子必须放置成功")
	return u


# ---------------------------------------------------------------- 用例

func _test_baseline() -> void:
	print("[1] 没有 buff 时，两个属性的生效值就是基础值")
	var b := _new_battle()
	var atk := _atk(b)
	var tgt := _target(b)
	_check_eq(b.stat_of(atk, "attack"), 3, "攻击力生效值 = 单位 attack")
	_check_eq(b.stat_of(tgt, "defense"), 0, "防御生效值 = 0（当前没有基础防御字段）")
	b.attack_unit(atk, tgt)
	_check_eq(tgt.hp, 7, "3 点攻击 → 10 - 3 = 7")


func _test_attack_stat() -> void:
	print("[2] passive stat_mod 加在 attack 上：伤害跟着涨（状态定义是运行时注入的）")
	var b := _new_battle()
	var atk := _atk(b)
	var tgt := _target(b)
	_inject(b, "attack_up", ATTACK_UP)
	atk.add_buff(Buff.make("attack_up", 2))
	_check_eq(b.stat_of(atk, "attack"), 5, "攻击力生效值 = 3 + 2")
	_check_eq(b.stat_of(tgt, "defense"), 0, "攻击力 buff 不该影响目标的防御")
	b.attack_unit(atk, tgt)
	_check_eq(tgt.hp, 5, "伤害 5 → 10 - 5 = 5")


func _test_defense_stat() -> void:
	print("[3] passive stat_mod 加在 defense 上：受到的伤害下降，且不会变成负数")
	var b := _new_battle()
	var atk := _atk(b, 2)                       # 只打 2 点，防御 +3 应该全挡掉
	var tgt := _target(b)
	_inject(b, "defense_up", DEFENSE_UP)
	tgt.add_buff(Buff.make("defense_up", 2))
	_check_eq(b.stat_of(tgt, "defense"), 3, "防御生效值 = 0 + 3")
	_check(b.attack_unit(atk, tgt), "攻击本身成立（别被 0 伤害骗成攻击失败）")
	_check_eq(tgt.hp, 10, "伤害 <= 0 时钳到 0（2 - 3 → 0，不掉血、也不回血）")
	# 少了这条：不钳位时伤害是 -1，take_damage(-1) 会走 "护盾够扣" 分支变成
	# shield -= (-1) → 白送 1 点护盾，血量却没变，[3] 前两条照样全绿。
	_check_eq(tgt.shield, 0, "负伤害不该变成护盾")


func _test_combined() -> void:
	print("[4] 两个属性同时被改：互不串台")
	var b := _new_battle()
	var atk := _atk(b)
	var tgt := _target(b)
	_inject(b, "attack_up", ATTACK_UP)
	_inject(b, "defense_up", DEFENSE_UP)
	atk.add_buff(Buff.make("attack_up", 2))
	tgt.add_buff(Buff.make("defense_up", 2))
	tgt.add_buff(Buff.make("defense_down", 2))  # 数据里的真实状态，-1
	_check_eq(b.stat_of(atk, "attack"), 5, "攻击方：3 + 2")
	_check_eq(b.stat_of(tgt, "defense"), 2, "目标：+3 与 -1 相加 = 2")
	b.attack_unit(atk, tgt)
	_check_eq(tgt.hp, 7, "伤害 5 - 2 = 3 → 10 - 3 = 7")


func _test_timing_filter() -> void:
	print("[5] 时机不是 passive 的 stat_mod 不计入生效值")
	var b := _new_battle()
	var atk := _atk(b)
	_inject(b, "bad_timing", ATTACK_UP_TURN_START)
	atk.add_buff(Buff.make("bad_timing", 2))
	_check_eq(b.stat_of(atk, "attack"), 3, "turn_start 的 stat_mod 不算进属性")


func _test_no_timing() -> void:
	print("[6] 没写 timing 的 stat_mod 按常驻算（不该被静默丢掉）")
	var b := _new_battle()
	var atk := _atk(b)
	_inject(b, "no_timing", NO_TIMING)
	atk.add_buff(Buff.make("no_timing", 2))
	_check_eq(b.stat_of(atk, "attack"), 7, "缺 timing → 视为 passive，3 + 4")


func _test_unknown_stat() -> void:
	print("[7] 未知属性名不该崩、也不该串到别的属性上")
	var b := _new_battle()
	var atk := _atk(b)
	var tgt := _target(b)
	_inject(b, "unknown", UNKNOWN_STAT)
	atk.add_buff(Buff.make("unknown", 2))
	_check_eq(b.stat_of(atk, "luck"), 9, "未知属性名照样能查（系统只认数据里的名字）")
	_check_eq(b.stat_of(atk, "attack"), 3, "未知属性不影响攻击力")
	b.attack_unit(atk, tgt)
	_check_eq(tgt.hp, 7, "未知属性不影响伤害")
