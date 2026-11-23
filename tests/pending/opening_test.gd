extends SceneTree
## E7b 起手与换牌（mulligan）验收测试 —— 待实现
##
## 运行：
##   ... --headless --path . --script res://tests/pending/opening_test.gd
##
## 规格：docs/implementation-tasks.md「## 30. E7b 起手与换牌（P2）」（KARDS 式，2026-11-23 改随机先手）
##   - **先手随机**：`rng.randi_range(0, 1)` → `first_move` ∈ {"player", "enemy"}
##   - `start_battle()`：只决定先后手 + 发牌（先手 4 张 / 后手 5 张），**不开始回合**（turn 仍 0、energy 仍 0）
##   - `begin_first_turn()`：开始先手方第 1 回合；先手是敌方时先跑 `_enemy_turn()` 再进玩家回合
##   - 先手方自己第一个回合**不抽牌**；后手方第一个回合**照常抽 1 张**；之后每回合抽 1
##   - mulligan：只在开局阶段（start_battle 后、begin_first_turn 前），每方每局一次
##     API：`Battle.mulligan(owner: String, cards: Array[Card]) -> bool`
##       - 成功 true / 失败 false（不是自己手牌、已用过、已过开局阶段、空列表 → false）
##   - 可注入：`start_battle()` 只在 `first_move == ""` 时随机，测试可先设 `b.first_move = "player"` 固定
##
## 【启用方式】E7b 全绿后移到 tests/ 下。

var failures: int = 0
var checks: int = 0
var table: ReactionTable

const EXPECTED_CHECKS := 25


func _initialize() -> void:
	print("========== 起手 / 换牌测试（E7b） ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	_test_first_move_random()
	_test_opening_hands()
	_test_no_turn_started()
	_test_first_turn_draw()
	_test_mulligan_player()
	_test_mulligan_enemy()
	_test_mulligan_invalid()
	_test_mulligan_after_opening()

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


func _new_battle(seed_value: int = 20261125) -> Battle:
	var b := Battle.new()
	var player := Unit.from_dict({ "id": "player", "name": "旅行者", "hp": 60 })
	var enemy := Unit.from_dict({ "id": "enemy", "name": "训练假人", "hp": 9999 })
	var enemies: Array[Unit] = [enemy]
	b.setup(player, enemies, DataLoader.load_cards(), table, seed_value)
	return b


## 固定先手为玩家（旧断言都是"玩家先手"语义）
func _new_battle_first_player(seed_value: int = 20261125) -> Battle:
	var b := _new_battle(seed_value)
	b.first_move = "player"
	return b


## 固定先手为敌方
func _new_battle_first_enemy(seed_value: int = 20261125) -> Battle:
	var b := _new_battle(seed_value)
	b.first_move = "enemy"
	return b


func _hand_ids(cards: Array) -> Array[String]:
	var ids: Array[String] = []
	for c in cards:
		ids.append(str(c.id))
	return ids


# ---------------------------------------------------------------- 用例

func _test_first_move_random() -> void:
	print("[1] 先手随机 + 可复现")
	var a := _new_battle(4242)
	a.start_battle()
	_check(a.first_move == "player" or a.first_move == "enemy", "first_move 只能是 player 或 enemy（实际 %s）" % a.first_move)

	var b := _new_battle(4242)
	b.start_battle()
	_check_eq(b.first_move, a.first_move, "同 seed 两次开局 → 先手相同（可复现）")

	var saw_player := false
	var saw_enemy := false
	for s in range(1, 41):
		var c := _new_battle(s)
		c.start_battle()
		if c.first_move == "player":
			saw_player = true
		elif c.first_move == "enemy":
			saw_enemy = true
	_check(saw_player and saw_enemy, "seed 1..40 中两种先手都出现过（真的是随机，不是固定一方）")


func _test_opening_hands() -> void:
	print("[2] 起手张数按身份：先手 4 张 / 后手 5 张")
	var p := _new_battle_first_player()
	var total: int = p.deck.size()
	p.start_battle()
	_check_eq(p.hand.size(), 4, "玩家先手：玩家起手 4 张")
	_check_eq(p.enemy_hand.size(), 5, "玩家先手：敌方（后手）起手 5 张")
	_check_eq(p.deck.size(), total - 4, "玩家先手：玩家牌库扣 4")
	_check_eq(p.enemy_deck.size(), total - 5, "玩家先手：敌方牌库扣 5")

	var e := _new_battle_first_enemy()
	var total2: int = e.deck.size()
	e.start_battle()
	_check_eq(e.enemy_hand.size(), 4, "敌方先手：敌方起手 4 张")
	_check_eq(e.hand.size(), 5, "敌方先手：玩家（后手）起手 5 张")


func _test_no_turn_started() -> void:
	print("[3] start_battle() 只发牌，不开始回合")
	var b := _new_battle_first_player()
	b.start_battle()
	_check_eq(b.turn, 0, "发牌后还没进任何回合（turn 仍 0）")
	_check_eq(b.energy, 0, "发牌后没有 Kredit（energy 仍 0）")


func _test_first_turn_draw() -> void:
	print("[4] 第一个回合抽牌：先手不抽、后手抽")
	var b := _new_battle_first_player()
	b.start_battle()
	if not b.has_method("begin_first_turn"):
		_check(false, "Battle 还没有 begin_first_turn() 方法")
		_check(false, "跳过")
		_check(false, "跳过")
		_check(false, "跳过")
		return
	b.begin_first_turn()
	_check_eq(b.hand.size(), 4, "玩家先手：玩家第 1 回合不抽牌（手牌仍 4）")

	var e := _new_battle_first_enemy()
	e.start_battle()
	e.begin_first_turn()
	_check_eq(e.enemy_hand.size(), 4, "敌方先手：敌方第 1 回合不抽牌（手牌仍 4）")
	_check_eq(e.hand.size(), 6, "敌方先手：玩家（后手）第 1 回合照常抽 1（5 → 6）")

	b.end_turn()   # 玩家结束 → 敌方第 1 回合 → 玩家第 2 回合
	_check_eq(b.hand.size(), 5, "之后每回合抽 1：玩家第 2 回合 4 → 5")


func _test_mulligan_player() -> void:
	print("[5] mulligan（玩家）：换掉整手、每局一次")
	var b := _new_battle_first_player()
	if not b.has_method("mulligan"):
		_check(false, "Battle 还没有 mulligan(owner, cards) 方法")
		_check(false, "跳过")
		_check(false, "跳过")
		_check(false, "跳过")
		_check(false, "跳过")
		return
	b.start_battle()
	var hand_before := _hand_ids(b.hand)
	var deck_before: int = b.deck.size()
	var give_back: Array = b.hand.duplicate()
	_check(b.mulligan("player", give_back), "mulligan 成功（换 4 张）")
	_check_eq(b.hand.size(), hand_before.size(), "换牌后手牌数不变（洗回 4 张再抽 4 张）")
	_check_eq(b.deck.size(), deck_before, "换牌后牌库数不变")
	_check(_hand_ids(b.hand) != hand_before, "换牌后手牌内容变了（真的洗回去再抽，不是原地不动）")
	_check(not b.mulligan("player", [b.hand[0]]), "同一方每局只能 mulligan 一次（第二次返回 false）")


func _test_mulligan_enemy() -> void:
	print("[6] mulligan（敌方）：对称、独立一次")
	var b := _new_battle_first_player()
	if not b.has_method("mulligan"):
		_check(false, "跳过")
		_check(false, "跳过")
		return
	b.start_battle()
	var give_back: Array = [b.enemy_hand[0]]
	_check(b.mulligan("enemy", give_back), "敌方也可以 mulligan 一次（对称）")
	_check_eq(b.enemy_hand.size(), 5, "敌方换 1 张后手牌数不变")


func _test_mulligan_invalid() -> void:
	print("[7] mulligan 非法输入：不是自己手牌 / 空列表")
	var b := _new_battle_first_player()
	if not b.has_method("mulligan"):
		_check(false, "跳过")
		_check(false, "跳过")
		return
	b.start_battle()
	var foreign := Card.from_dict({ "id": "not_in_hand", "name": "外来卡", "type": "order", "cost": 1, "kind": "damage", "power": 1 })
	_check(not b.mulligan("player", [foreign]), "不在自己手牌里的卡 → false")
	_check(not b.mulligan("player", []), "空列表 → false")


func _test_mulligan_after_opening() -> void:
	print("[8] 开局阶段结束后不能再 mulligan")
	var b := _new_battle_first_player()
	if not b.has_method("begin_first_turn") or not b.has_method("mulligan"):
		_check(false, "跳过")
		return
	b.start_battle()
	b.begin_first_turn()
	_check(not b.mulligan("player", [b.hand[0]]), "begin_first_turn() 之后 mulligan → false（已过开局阶段）")
