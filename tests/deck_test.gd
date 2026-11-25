extends SceneTree
## E7a 弃牌堆 / 牌库抽干（KARDS 式疲劳）验收测试 —— 待实现
##
## 运行：
##   ... --headless --path . --script res://tests/pending/deck_test.gd
##
## 规格：docs/implementation-tasks.md §26（2026-11-22 定稿：KARDS 式，不洗回）
##   - 打出的指令卡 → 弃牌堆；单位卡部署不进弃牌堆；失败/非法出牌不进弃牌堆
##   - 手牌满 9 仍要抽 → 牌库照扣，抽到的牌进弃牌堆（burn）
##   - 牌库抽空后仍要抽牌 → 不再抽牌，抽牌方**自己的 HQ** 受到递增伤害：
##     第 1 次 1、第 2 次 2、第 3 次 3……（等差数列，双方独立计数；直接扣 HP，不走护盾/元素）
##   - 敌方完全对称：enemy_discard + 自己的疲劳计数
## E7b（起手 4/5 + 首个回合抽牌差异 + mulligan）另开测试，不在这份里。
##
## 【启用方式】E7a 全绿后移到 tests/ 下。

var failures: int = 0
var checks: int = 0
var table: ReactionTable

## 全绿时应执行的检查项数（少执行一条也算红）。
const EXPECTED_CHECKS := 20


func _initialize() -> void:
	print("========== 弃牌堆 / 疲劳测试（E7a） ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	_test_fields()
	_test_play_order_to_discard()
	_test_unit_not_discard()
	_test_invalid_not_discard()
	_test_overflow_to_discard()
	_test_fatigue_player()
	_test_fatigue_enemy()
	_test_fatigue_independent()

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
	b.setup(player, enemies, DataLoader.load_cards(), table, 20261123)
	_start(b)
	return b


func _order(id: String, cost: int, kind: String, power: int, element: String = Element.NONE, target: String = "enemy") -> Card:
	return Card.from_dict({
		"id": id, "name": id, "type": "order", "cost": cost,
		"element": element, "kind": kind, "power": power, "target": target,
	})


func _unit(id: String, hp: int, attack: int = 1, owner: String = "player") -> Unit:
	return Unit.from_dict({ "id": id, "name": id, "hp": hp, "attack": attack, "owner": owner })


func _player_hq(b: Battle) -> Unit:
	return b.board.unit_at("player_support", 0)


func _enemy_hq(b: Battle) -> Unit:
	return b.board.unit_at("enemy_support", 0)


# ---------------------------------------------------------------- 用例

func _test_fields() -> void:
	print("[0] 弃牌堆字段")
	var b := _new_battle()
	_check(b.get("discard") != null, "Battle 有 discard 字段（玩家弃牌堆）")
	_check(b.get("enemy_discard") != null, "Battle 有 enemy_discard 字段（敌方弃牌堆）")


func _test_play_order_to_discard() -> void:
	print("[1] 打出的指令卡进弃牌堆")
	var b := _new_battle()
	if b.get("discard") == null:
		_check(false, "还没有 discard 字段，跳过")
		return
	b.energy = 5
	var foe := _unit("foe", 10, 2, "enemy")
	b.board.place(foe, "enemy_support", 1)
	var c := _order("fire_bolt", 1, "damage", 5, Element.FIRE)
	b.hand.append(c)
	_check(b.play_card(c, foe), "指令卡打出成功")
	_check_eq(b.discard.size(), 1, "打出的指令卡进玩家弃牌堆")
	_check(b.discard[0] == c, "弃牌堆里就是这张卡")


func _test_unit_not_discard() -> void:
	print("[2] 单位卡部署后不进弃牌堆")
	var b := _new_battle()
	if b.get("discard") == null:
		_check(false, "还没有 discard 字段，跳过")
		_check(false, "还没有 discard 字段，跳过")
		return
	b.energy = 5
	var u := Unit.from_dict({ "id": "footman", "name": "步兵", "hp": 2, "attack": 1, "owner": "player" })
	var c := Card.from_dict({ "id": "footman", "name": "步兵", "type": "unit", "cost": 1, "attack": 1, "defense": 2 })
	b.hand.append(c)
	_check(b.play_card(c, u), "单位卡部署成功")
	_check_eq(b.discard.size(), 0, "单位卡进场后不进弃牌堆")


func _test_invalid_not_discard() -> void:
	print("[3] 非法/失败的出牌不进弃牌堆")
	var b := _new_battle()
	if b.get("discard") == null:
		_check(false, "还没有 discard 字段，跳过")
		return
	b.energy = 0
	var c := _order("fire_bolt", 1, "damage", 5, Element.FIRE)
	b.hand.append(c)
	_check(not b.play_card(c, _enemy_hq(b)), "能量不足时出牌失败")
	_check_eq(b.discard.size(), 0, "失败的出牌不进弃牌堆")
	_check(b.hand.has(c), "失败的卡留在手里")


func _test_overflow_to_discard() -> void:
	print("[4] 手牌满 9 时抽到的牌进弃牌堆（burn）")
	var b := _new_battle()
	if b.get("discard") == null:
		_check(false, "还没有 discard 字段，跳过")
		_check(false, "还没有 discard 字段，跳过")
		return
	while b.hand.size() < 9:
		b.hand.append(_order("filler", 1, "damage", 1))
	var marker := _order("marker", 1, "damage", 1)
	b.deck.push_front(marker)
	b.end_turn()
	_check_eq(b.hand.size(), 9, "手牌保持 9 张上限（burn 不入手）")
	_check(b.discard.has(marker), "满手牌时抽到的那张进弃牌堆（不是凭空消失）")


func _test_fatigue_player() -> void:
	print("[5] 玩家牌库空：每次该抽牌时自己的 HQ 受递增伤害（1,2,3…）")
	var b := _new_battle()
	if b.get("discard") == null:
		_check(false, "还没有 discard 字段，跳过")
		return
	b.deck.clear()
	var hq := _player_hq(b)
	var hand_before := b.hand.size()
	b.end_turn()
	_check_eq(hq.hp, 19, "牌库空后第 1 次抽牌：玩家 HQ 20 → 19（疲劳 1）")
	b.end_turn()
	_check_eq(hq.hp, 17, "第 2 次抽牌：再受 2 点（19 → 17，累计 1+2=3）")
	_check_eq(b.hand.size(), hand_before, "牌库空时抽不到牌（手牌数不变）")


func _test_fatigue_enemy() -> void:
	print("[6] 敌方牌库空：对称疲劳")
	var b := _new_battle()
	if b.get("discard") == null:
		_check(false, "还没有 discard 字段，跳过")
		_check(false, "还没有 discard 字段，跳过")
		return
	b.enemy_deck.clear()
	var ehq := _enemy_hq(b)
	var phq := _player_hq(b)
	b.end_turn()
	_check_eq(ehq.hp, 19, "敌方回合抽空：敌方 HQ 20 → 19（疲劳 1）")
	b.end_turn()
	_check_eq(ehq.hp, 17, "敌方第 2 次抽空：再受 2 点（19 → 17）")
	_check_eq(phq.hp, 20, "玩家 HQ 不受敌方疲劳影响")


func _test_fatigue_independent() -> void:
	print("[7] 双方疲劳独立计数")
	var b := _new_battle()
	if b.get("discard") == null:
		_check(false, "还没有 discard 字段，跳过")
		return
	b.deck.clear()
	b.enemy_deck.clear()
	b.end_turn()
	_check_eq(_enemy_hq(b).hp, 19, "敌方先抽空：敌方疲劳 1（HQ 19）")
	_check_eq(_player_hq(b).hp, 19, "玩家随后抽空：玩家疲劳 1（HQ 19，独立计数）")


## 建局：固定玩家先手 + 开始第一个回合（E7b 后 start_battle() 只发牌）
func _start(b: Battle) -> void:
	b.first_move = "player"
	b.start_battle()
	b.begin_first_turn()
