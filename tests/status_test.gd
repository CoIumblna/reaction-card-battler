extends SceneTree
## C8 状态效果测试：dot 掉血 / disable 不能行动 / 反应挂状态
##
## 运行：
##   ... --headless --path . --script res://tests/status_test.gd
##
## 规格：docs/implementation-tasks.md §24
## 【启用方式】做完 E15、准备开 C8 时，把本文件从 tests/pending/ 移到 tests/ 下
## （run_tests.bat 和 CI 会自动发现 tests/*_test.gd，不用改列表）。

var failures: int = 0
var checks: int = 0
var table: ReactionTable

## 全绿时应执行的检查项数（少执行一条也算红，防"静默跳过"）。
const EXPECTED_CHECKS := 12


func _initialize() -> void:
	print("========== 状态效果测试（C8） ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	_test_status_data()
	_test_dot()
	_test_disable()
	_test_reaction_status()

	if checks != EXPECTED_CHECKS:
		printerr("  [FAIL] 覆盖不完整：本文件应执行 %d 项检查，实际 %d 项（有测试段被跳过 / 运行期脚本报错打断）" % [EXPECTED_CHECKS, checks])
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
	b.setup(player, enemies, DataLoader.load_cards(), table, 20261118)
	return b


## 直接往棋盘上摆一个单位（绕开出牌/能量，专测状态结算）
func _place(b: Battle, line: String, index: int, hp: int, attack: int = 1, owner: String = "player", element: String = Element.NONE) -> Unit:
	var u := Unit.from_dict({
		"id": "u_%s_%d" % [line, index], "name": "单位", "hp": hp,
		"attack": attack, "owner": owner, "element": element,
	})
	b.board.place(u, line, index)
	return u


## 某个单位身上有没有指定 kind 的 buff（找不到返回 null）
func _find_buff(u: Unit, kind: String) -> Buff:
	for bf in u.buffs:
		if bf.kind == kind:
			return bf
	return null


# ---------------------------------------------------------------- 用例

func _test_status_data() -> void:
	print("[0] 状态数据接线")
	var b := _new_battle()
	if b.get("status_table") == null:
		_check(false, "Battle 还没有 status_table 字段（C8 的前置，见 §24）")
		return
	_check(b.status_table.has_status("burn") and b.status_table.has_status("immobilized"),
		"setup() 加载了 statuses.json（burn / immobilized 都查得到）")


func _test_dot() -> void:
	print("[1] dot：回合开始掉血（burn）")
	var b := _new_battle()
	_start(b)
	var u := _place(b, "player_support", 1, 5)
	u.add_buff(Buff.make("burn", 2))

	b.end_turn()                      # → 玩家第 2 回合开始：dot
	_check_eq(u.hp, 4, "燃烧掉 1 血（5 → 4）")
	_check_eq(u.buffs.size(), 1, "burn 还在（duration 2 → 1）")

	b.end_turn()                      # → 玩家第 3 回合开始：dot + 到期移除
	_check_eq(u.hp, 3, "第 2 个回合再掉 1（4 → 3）")
	_check_eq(u.buffs.size(), 0, "duration 用完，burn 被移除")


func _test_disable() -> void:
	print("[2] disable：本回合不能行动（immobilized）")
	var b := _new_battle()
	_start(b)
	var u := _place(b, "player_support", 1, 5)
	u.add_buff(Buff.make("immobilized", 1))

	b.end_turn()                      # → 玩家第 2 回合开始：被冻结
	_check_eq(u.has_acted, true, "冻结的单位本回合被标记为不能行动")

	b.energy = 5
	_check_eq(b.move_unit(u, "front", 0), false, "冻结的单位不能移动")

	b.end_turn()                      # → 第 3 回合：冻结已过期
	_check_eq(u.has_acted, false, "冻结 1 回合后恢复（新回合解除）")


func _test_reaction_status() -> void:
	print("[3] 反应挂状态（感电 → shock / 冻结 → immobilized）")
	var b := _new_battle()
	_start(b)
	var atk := _place(b, "front", 1, 5, 3, "player", Element.LIGHTNING)
	var foe := _place(b, "enemy_support", 1, 10, 1, "enemy")
	foe.aura_element = Element.WATER
	foe.aura_amount = 1.0
	b.energy = 5
	_check_eq(b.attack_unit(atk, foe), true, "雷打水附着：攻击成立")

	var shock := _find_buff(foe, "shock")
	_check(shock != null, "感电反应把 shock 挂到目标身上")
	_check(shock != null and shock.duration == 2 and shock.stacks == 1,
		"shock 持续 2 回合、不叠 stack（数据来自 reactions.json）")

	var b2 := _new_battle()
	_start(b2)
	var atk2 := _place(b2, "front", 1, 5, 3, "player", Element.ICE)
	var foe2 := _place(b2, "enemy_support", 1, 10, 1, "enemy")
	foe2.aura_element = Element.WATER
	foe2.aura_amount = 1.0
	b2.energy = 5
	b2.attack_unit(atk2, foe2)
	_check(_find_buff(foe2, "immobilized") != null, "冻结反应把 immobilized 挂到目标身上")


## 建局：固定玩家先手 + 开始第一个回合（E7b 后 start_battle() 只发牌）
func _start(b: Battle) -> void:
	b.first_move = "player"
	b.start_battle()
	b.begin_first_turn()
