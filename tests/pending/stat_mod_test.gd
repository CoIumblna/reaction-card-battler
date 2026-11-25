extends SceneTree
## M3.7 数值系统（stat_mod / passive，defense_down）验收测试 —— 待实现
##
## 运行：
##   ... --headless --path . --script res://tests/pending/stat_mod_test.gd
##
## 规格：docs/implementation-tasks.md §M3.7 + data/tables/statuses.json
## 规则（本测试采用的定义，实现按这个）：
##   - `defense_down`：`stat_mod / defense / -1 / passive`
##   - 目标身上每 1 层 defense_down → **受到的伤害 +1**（`abs(value) × stacks`）
##   - 对"单位攻击"和"指令卡伤害"都生效；先加算再走护盾/免疫
##   - 到期后失效（duration 走 Buff.tick_buffs）
##
## 【启用方式】M3.7 全绿后移到 tests/ 下。

var failures: int = 0
var checks: int = 0
var table: ReactionTable

const EXPECTED_CHECKS := 7


func _initialize() -> void:
	print("========== 数值系统测试（M3.7 stat_mod） ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	_test_no_buff()
	_test_defense_down()
	_test_stacks()
	_test_order_damage()
	_test_expiry()

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
	b.setup(player, enemies, DataLoader.load_cards(), table, 20261129)
	b.start_battle()
	b.energy = 10
	return b


func _atk(b: Battle) -> Unit:
	var u := Unit.from_dict({ "id": "atk", "name": "攻", "hp": 20, "attack": 3, "owner": "player" })
	b.board.place(u, "front", 1)
	return u


func _target(b: Battle, hp: int = 10) -> Unit:
	var u := Unit.from_dict({ "id": "tgt", "name": "靶", "hp": hp, "attack": 1, "owner": "enemy" })
	b.board.place(u, "enemy_support", 1)
	return u


# ---------------------------------------------------------------- 用例

func _test_no_buff() -> void:
	print("[1] 没有 buff：伤害 = 攻击力")
	var b := _new_battle()
	var atk := _atk(b)
	var tgt := _target(b)
	b.attack_unit(atk, tgt)
	_check_eq(tgt.hp, 7, "3 点攻击 → 10 - 3 = 7")


func _test_defense_down() -> void:
	print("[2] defense_down：受到的伤害 +1")
	var b := _new_battle()
	var atk := _atk(b)
	var tgt := _target(b)
	tgt.add_buff(Buff.make("defense_down", 2))
	b.attack_unit(atk, tgt)
	_check_eq(tgt.hp, 6, "3 点攻击 + 减防 1 → 伤害 4（10 - 4 = 6）")


func _test_stacks() -> void:
	print("[3] defense_down 叠 2 层：+2 伤害")
	var b := _new_battle()
	var atk := _atk(b)
	var tgt := _target(b)
	tgt.add_buff(Buff.make("defense_down", 2))
	tgt.add_buff(Buff.make("defense_down", 2))
	b.attack_unit(atk, tgt)
	_check_eq(tgt.hp, 5, "3 点攻击 + 2 层减防 → 伤害 5（10 - 5 = 5）")


func _test_order_damage() -> void:
	print("[4] 指令卡伤害同样吃 defense_down")
	var b := _new_battle()
	var tgt := _target(b)
	tgt.add_buff(Buff.make("defense_down", 2))
	var c := Card.from_dict({ "id": "heavy_strike", "name": "重击", "type": "order", "cost": 2, "element": Element.NONE, "kind": "damage", "power": 5, "target": "enemy" })
	b.hand.append(c)
	b.play_card(c, tgt)
	_check_eq(tgt.hp, 4, "5 点指令伤害 + 减防 1 → 伤害 6（10 - 6 = 4）")


func _test_expiry() -> void:
	print("[5] defense_down 到期后恢复")
	var b := _new_battle()
	# 注意：b.end_turn() 会**真的跑一遍敌方 AI**，把 enemy_support 上的单位挪到 front。
	# 所以靶子直接放 front（AI 不会再挪它），攻击者放 player_support（与 front 相邻，跨度 1）。
	# 原来用 _target()（放 enemy_support）+ _atk()（放 front）：靶子被 AI 挪到 front 0 号格后
	# 与攻击者同线，attack_unit 因跨度 0 直接返回 false，血量不变 → 这条断言测的不是「buff 失效」。
	# 2026-11-25 修正，并补一条「攻击必须成立」的防空跑断言。
	var tgt := Unit.from_dict({ "id": "tgt", "name": "靶", "hp": 10, "attack": 1, "owner": "enemy" })
	assert(b.board.place(tgt, "front", 1), "靶子必须放置成功")
	tgt.add_buff(Buff.make("defense_down", 1))
	b.end_turn()   # 玩家新回合开始 → _settle_status 里 tick，duration 1 → 0 移除
	_check_eq(tgt.buffs.size(), 0, "duration 1 的减防在回合开始后移除")
	var atk := Unit.from_dict({ "id": "atk", "name": "攻", "hp": 20, "attack": 3, "owner": "player" })
	assert(b.board.place(atk, "player_support", 1), "攻击者必须放置成功")
	_check(b.attack_unit(atk, tgt), "buff 失效后攻击成立（防空跑）")
	_check_eq(tgt.hp, 7, "buff 失效后伤害恢复正常（10 - 3 = 7）")
