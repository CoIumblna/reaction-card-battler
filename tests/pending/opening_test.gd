extends SceneTree
## E7b 起手与换牌（mulligan）验收测试 —— 待实现
##
## 运行：
##   ... --headless --path . --script res://tests/pending/opening_test.gd
##
## 规格：docs/implementation-tasks.md「## 30. E7b 起手与换牌（P2）」（KARDS 式，2026-11-22 确认）
##   - 先手（玩家）起手 4 张，**自己第一个回合不抽牌**
##   - 后手（敌方）起手 5 张，**自己第一个回合照常抽 1 张**
##   - 之后双方每回合抽 1
##   - mulligan：开局（第一次行动前）每方可以换一次：把指定手牌洗回牌库、再抽等量
##     API 约定：Battle.mulligan(owner: String, cards: Array[Card]) -> bool
##       - 成功 true / 失败 false（不是自己手牌、已用过、已过开局阶段、空列表 → false）
##       - 每方每局只能成功一次；双方对称
##
## 【启用方式】E7b 全绿后移到 tests/ 下。

var failures: int = 0
var checks: int = 0
var table: ReactionTable

const EXPECTED_CHECKS := 16


func _initialize() -> void:
	print("========== 起手 / 换牌测试（E7b） ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	_test_opening_hands()
	_test_first_turn_draw()
	_test_mulligan_player()
	_test_mulligan_enemy()
	_test_mulligan_invalid()
	_test_mulligan_reproducible()

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


func _hand_ids(cards: Array) -> Array[String]:
	var ids: Array[String] = []
	for c in cards:
		ids.append(str(c.id))
	return ids


# ---------------------------------------------------------------- 用例

func _test_opening_hands() -> void:
	print("[1] 起手：先手 4 张 / 后手 5 张")
	var b := _new_battle()
	var total: int = b.deck.size()
	b.start_battle()
	_check_eq(b.hand.size(), 4, "玩家（先手）起手 4 张")
	_check_eq(b.enemy_hand.size(), 5, "敌方（后手）起手 5 张")
	_check_eq(b.deck.size(), total - 4, "玩家牌库扣 4")
	_check_eq(b.enemy_deck.size(), total - 5, "敌方牌库扣 5")


func _test_first_turn_draw() -> void:
	print("[2] 第一个回合抽牌：玩家不抽、敌方抽")
	var b := _new_battle()
	b.start_battle()
	_check_eq(b.hand.size(), 4, "玩家第 1 回合不抽牌（手牌仍 4）")
	b.end_turn()   # 敌方第 1 回合（抽 1）→ 玩家第 2 回合（抽 1）
	_check_eq(b.enemy_hand.size(), 6, "敌方第 1 回合照常抽 1（5 → 6）")
	_check_eq(b.hand.size(), 5, "玩家第 2 回合开始抽 1（4 → 5）")


func _test_mulligan_player() -> void:
	print("[3] mulligan（玩家）：换 1 张、每局一次")
	var b := _new_battle()
	if not b.has_method("mulligan"):
		_check(false, "Battle 还没有 mulligan(owner, cards) 方法")
		_check(false, "跳过")
		_check(false, "跳过")
		return
	b.start_battle()
	var give_back: Card = b.hand[0]
	var hand_before: int = b.hand.size()
	var deck_before: int = b.deck.size()
	_check(b.mulligan("player", [give_back]), "mulligan 成功（指定 1 张）")
	_check_eq(b.hand.size(), hand_before, "换牌后手牌数不变（洗回 1 张再抽 1 张）")
	_check_eq(b.deck.size(), deck_before, "换牌后牌库数不变")
	_check(not b.mulligan("player", [b.hand[0]]), "同一方每局只能 mulligan 一次（第二次返回 false）")


func _test_mulligan_enemy() -> void:
	print("[4] mulligan（敌方）：对称、独立一次")
	var b := _new_battle()
	if not b.has_method("mulligan"):
		_check(false, "跳过")
		_check(false, "跳过")
		return
	b.start_battle()
	_check(b.mulligan("enemy", [b.enemy_hand[0]]), "敌方也可以 mulligan 一次（对称）")
	_check_eq(b.enemy_hand.size(), 5, "敌方换牌后手牌数不变")
	_check(not b.mulligan("enemy", [b.enemy_hand[0]]), "敌方第二次 mulligan 返回 false")


func _test_mulligan_invalid() -> void:
	print("[5] mulligan 非法输入：不是自己手牌 / 空列表")
	var b := _new_battle()
	if not b.has_method("mulligan"):
		_check(false, "跳过")
		_check(false, "跳过")
		return
	b.start_battle()
	var foreign := Card.from_dict({ "id": "not_in_hand", "name": "外来卡", "type": "order", "cost": 1, "kind": "damage", "power": 1 })
	_check(not b.mulligan("player", [foreign]), "不在自己手牌里的卡 → false")
	_check(not b.mulligan("player", []), "空列表 → false")


func _test_mulligan_reproducible() -> void:
	print("[6] mulligan 可复现（同 seed 同结果）")
	var a := _new_battle(777)
	var b := _new_battle(777)
	if not a.has_method("mulligan"):
		_check(false, "跳过")
		_check(false, "跳过")
		return
	a.start_battle()
	b.start_battle()
	a.mulligan("player", [a.hand[0]])
	b.mulligan("player", [b.hand[0]])
	_check_eq(_hand_ids(a.hand), _hand_ids(b.hand), "同 seed + 同换牌选择 → 手牌一致")
	_check_eq(_hand_ids(a.enemy_hand), _hand_ids(b.enemy_hand), "敌方手牌也一致")
