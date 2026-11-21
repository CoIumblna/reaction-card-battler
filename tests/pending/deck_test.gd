extends SceneTree
## E7 牌堆/弃牌/换牌验收测试（待实现）
##
## 运行：
##   ... --headless --path . --script res://tests/pending/deck_test.gd
##
## 规格：docs/implementation-tasks.md §26
## 【暂定方案】弃牌堆记录"打出的指令卡 + 手牌满时抽到被丢弃的牌"；牌库抽空时把弃牌堆
## 洗回牌库再抽（避免长局抽干）。§26 的 3 个 ❓ 拍板后，若方案不同我再改这份测试。
## 【启用方式】E7 实现全绿后，把本文件移到 tests/ 下（runner 自动发现）。

var failures: int = 0
var checks: int = 0
var table: ReactionTable

## 全绿时应执行的检查项数（少执行一条也算红）。
const EXPECTED_CHECKS := 18


func _initialize() -> void:
	print("========== 牌堆/弃牌测试（E7） ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	_test_fields()
	_test_play_order_to_discard()
	_test_unit_not_discard()
	_test_invalid_not_discard()
	_test_overflow_to_discard()
	_test_reshuffle_player()
	_test_reshuffle_enemy()

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
	b.setup(player, enemies, DataLoader.load_cards(), table, 20261122)
	b.start_battle()
	return b


func _order(id: String, cost: int, kind: String, power: int, element: String = Element.NONE) -> Card:
	return Card.from_dict({ "id": id, "name": id, "type": "order", "cost": cost, "element": element, "kind": kind, "power": power })


func _unit(id: String, hp: int, attack: int = 1, owner: String = "player") -> Unit:
	return Unit.from_dict({ "id": id, "name": id, "hp": hp, "attack": attack, "owner": owner })


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
	_check(not b.play_card(c, b.player), "能量不足时出牌失败（E7 测试不依赖 E14 的目标规则）")
	_check_eq(b.discard.size(), 0, "失败的出牌不进弃牌堆")
	_check(b.hand.has(c), "失败的卡留在手里")


func _test_overflow_to_discard() -> void:
	print("[4] 手牌满 9 时抽到的牌进弃牌堆")
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
	_check_eq(b.hand.size(), 9, "手牌保持 9 张上限（弃牌不入手）")
	_check(b.discard.has(marker), "满手牌时抽到的那张进弃牌堆（不是凭空消失）")


func _test_reshuffle_player() -> void:
	print("[5] 牌库空时弃牌堆洗回（玩家）")
	var b := _new_battle()
	if b.get("discard") == null:
		_check(false, "还没有 discard 字段，跳过")
		_check(false, "还没有 discard 字段，跳过")
		_check(false, "还没有 discard 字段，跳过")
		return
	var marker := _order("marker", 1, "damage", 1)
	b.discard.append(marker)
	b.deck.clear()
	var hand_before := b.hand.size()
	b.end_turn()
	_check_eq(b.hand.size(), hand_before + 1, "牌库空 + 弃牌堆有牌：洗回后照常抽 1 张（不崩）")
	_check_eq(b.discard.size(), 0, "洗回后弃牌堆清空")
	_check_eq(b.deck.size(), 0, "洗回的那张已被抽走")


func _test_reshuffle_enemy() -> void:
	print("[6] 敌方牌库空时洗回（对称）")
	var b := _new_battle()
	if b.get("enemy_discard") == null:
		_check(false, "还没有 enemy_discard 字段，跳过")
		_check(false, "还没有 enemy_discard 字段，跳过")
		_check(false, "还没有 enemy_discard 字段，跳过")
		return
	var marker := _order("enemy_marker", 1, "damage", 1)
	b.enemy_discard.append(marker)
	b.enemy_deck.clear()
	var hand_before := b.enemy_hand.size()
	b.end_turn()
	_check_eq(b.enemy_hand.size(), hand_before + 1, "敌方牌库空 + 弃牌堆有牌：洗回后照常抽 1 张")
	_check_eq(b.enemy_discard.size(), 0, "敌方洗回后弃牌堆清空")
	_check_eq(b.enemy_deck.size(), 0, "敌方洗回的那张已被抽走")

