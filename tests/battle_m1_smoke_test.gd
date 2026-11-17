extends SceneTree
## M1 冒烟测试：回合推进、能量与出牌、元素附着、伤害转接
##
## 运行：
##   ... --headless --path . --script res://tests/battle_m1_smoke_test.gd
##
## 【M2 起退役说明】胜负判定已改为「打掉 HQ」（E13），run_auto 也随 M2 流程重写，
## 所以本文件不再测 [6] 胜负 和 [7] 自动战斗 —— 那两块由 tests/battle_m2_test.gd 接管。
## 这里保住的是 M1 流程里仍然有效的部分（出牌 / 抽牌 / 附着 / 伤害转接）。
##
## 这里测的是 Battle 的行为，不是算法。
## 回合交换（turn 推进、敌人行动、能量重置）和元素附着都在这一层。

var failures: int = 0
var checks: int = 0
var table: ReactionTable
var cards: Array[Card] = []
var _setup_warned: bool = false

## 全绿时应执行的检查项数。对不上 = 有测试段被静默跳过（或 SCRIPT ERROR 打断），
## 只看"共 N 项检查、失败 0 项"会假绿，所以这里硬校验。
const EXPECTED_CHECKS := 58


func _initialize() -> void:
	print("========== 战斗流程测试 ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")
	cards = DataLoader.load_cards()

	_test_setup()
	_test_turn_advance()
	_test_energy()
	_test_aura()
	_test_delegation()

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


func _new_battle(player_hp: int = 60, enemy_hp: int = 30, fallback: bool = true) -> Battle:
	var b := Battle.new()
	var player := Unit.from_dict({ "id": "player", "name": "旅行者", "hp": player_hp })
	var enemy := Unit.from_dict({ "id": "enemy", "name": "史莱姆", "hp": enemy_hp })
	var enemies: Array[Unit] = [enemy]
	b.setup(player, enemies, cards, table, 20261102)

	# 兜底：setup() 还没实现时把状态直接注入，让后面的断言能跑（而不是整个测试崩掉）。
	# 这样你看到的是「一条 setup 没实现的失败」+「一堆按预期失败的行为断言」。
	if fallback:
		if b.player == null:
			if not _setup_warned:
				_check(false, "setup() 没有保存 player（这是所有战斗测试的前提）")
				_setup_warned = true
			b.player = player
		if b.enemies.is_empty():
			if not _setup_warned:
				_check(false, "setup() 没有保存 enemies")
				_setup_warned = true
			b.enemies = enemies
		if b.reaction_table == null:
			b.reaction_table = table
	return b


## 造一副足够大的测试牌库，用来验证「抽 1 张 / 爆牌」而不受 data/tables/cards.json 张数影响
func _make_deck(n: int) -> Array[Card]:
	var d: Array[Card] = []
	for i in range(n):
		d.append(Card.from_dict({
			"id": "deck_%d" % i,
			"name": "测试牌 %d" % i,
			"cost": 1,
			"element": "none",
			"kind": "damage",
			"power": 3,
		}))
	return d


# ---------------------------------------------------------------- 用例

func _test_setup() -> void:
	print("[1] 初始化")
	var b := _new_battle(60, 30, false)   # 不要兜底，这里就是要测 setup() 本身
	_check(b.player != null, "玩家已设置")
	_check(b.reaction_table != null, "setup() 保存了 reaction_table（没存的话反应会静默失效）")
	_check_eq(b.enemies.size(), 1, "敌人数")
	_check_eq(b.turn, 0, "回合数从 0 开始")
	_check_eq(b.energy, b.max_energy, "能量已回满")
	_check_eq(b.hand.size(), 0, "开局手牌为空（start_battle 才抽）")


func _test_turn_advance() -> void:
	print("[2] 回合交换：推进 / 能量重置 / 每回合抽 1 张")
	var b := _new_battle()
	b.deck = _make_deck(20)
	b.start_battle()
	_check_eq(b.turn, 1, "开战后进入第 1 回合")
	_check_eq(b.hand.size(), 6, "起手 5 张 + 第 1 回合抽 1 张")
	_check_eq(b.deck.size(), 14, "牌库扣掉起手 5 张和抽的 1 张")

	var hp_before := b.player.hp
	var deck_before := b.deck.size()
	b.energy = 0
	b.end_turn()
	_check_eq(b.turn, 2, "结束回合后进入第 2 回合")
	# M1 的「敌人每回合打玩家 4 点」在 E15 被删掉（胜负改成 HQ）。玩家血量不再由回合推进改变。
	_check_eq(b.player.hp, hp_before, "end_turn() 不再白扣玩家血量（M1 直伤已退役）")
	_check_eq(b.energy, b.max_energy, "新回合能量回满")
	_check_eq(b.hand.size(), 7, "每回合只抽 1 张（不补满）")
	_check_eq(b.deck.size(), deck_before - 1, "牌库每回合只扣 1 张")

	# 手牌满时抽牌 → 爆牌：牌从牌堆顶弹出后直接丢弃
	var c := _new_battle()
	c.deck = _make_deck(20)
	c.start_battle()
	while c.hand.size() < Battle.MAX_HAND:
		c.hand.append(Card.from_dict({ "id": "fill", "name": "填手牌", "cost": 1, "kind": "damage", "power": 1 }))
	var full_deck := c.deck.size()
	c.end_turn()
	_check_eq(c.hand.size(), Battle.MAX_HAND, "手牌满时抽到的牌丢弃，不超上限")
	_check_eq(c.deck.size(), full_deck - 1, "手牌满时依然从牌库弹出（牌库 -1）")


func _test_energy() -> void:
	print("[3] 能量与出牌")
	var b := _new_battle()
	b.start_battle()
	var heavy := Card.from_dict({ "id": "h", "name": "重击", "cost": 2, "kind": "damage", "power": 10 })
	var light := Card.from_dict({ "id": "l", "name": "火球", "cost": 1, "element": "fire", "kind": "damage", "power": 5 })
	var enemy: Unit = b.enemies[0]

	b.energy = 1
	_check(not b.play_card(heavy, enemy), "能量不足不能出 2 费卡")
	_check_eq(b.energy, 1, "失败出牌不扣能量")

	var hand_before := b.hand.size()
	b.hand.append(light)
	_check(b.play_card(light, enemy), "1 费卡可以打出")
	_check_eq(b.energy, 0, "打出后能量扣光")
	_check_eq(b.hand.size(), hand_before, "打出的卡从手牌移除")


func _test_aura() -> void:
	print("[4] 元素附着量（B8：附着 1U/2U、反应消耗、复合元素）")
	var b := _new_battle()
	b.start_battle()
	var enemy: Unit = b.enemies[0]
	_check_eq(enemy.aura_element, Element.NONE, "初始无附着")
	_check_eq(enemy.aura_amount, 0.0, "初始附着量 0")

	b.energy = 3
	var fire_card := Card.from_dict({ "id": "f", "name": "火球", "cost": 1, "element": "fire", "kind": "damage", "power": 4 })
	b.hand.append(fire_card)
	b.play_card(fire_card, enemy)
	_check_eq(enemy.aura_element, Element.FIRE, "打火卡后附着火")
	_check_eq(enemy.aura_amount, 1.0, "附着 1U")

	b.energy = 3
	var fire2 := Card.from_dict({ "id": "f2", "name": "火球", "cost": 1, "element": "fire", "kind": "damage", "power": 4 })
	b.hand.append(fire2)
	b.play_card(fire2, enemy)
	_check_eq(enemy.aura_amount, 2.0, "同元素叠加，封顶 2U")

	b.energy = 3
	var water_card := Card.from_dict({ "id": "w", "name": "水刃", "cost": 1, "element": "water", "kind": "damage", "power": 4 })
	b.hand.append(water_card)
	b.play_card(water_card, enemy)
	_check_eq(enemy.aura_element, Element.FIRE, "蒸发消耗 1U，剩 1U 火 → 保留")
	_check_eq(enemy.aura_amount, 1.0, "剩余 1U")

	b.energy = 3
	var water2 := Card.from_dict({ "id": "w2", "name": "水刃", "cost": 1, "element": "water", "kind": "damage", "power": 4 })
	b.hand.append(water2)
	b.play_card(water2, enemy)
	_check_eq(enemy.aura_element, Element.NONE, "消耗完 → 附着清空")
	_check_eq(enemy.aura_amount, 0.0, "附着量归零")

	# 共存反应 → 复合元素
	enemy.aura_element = Element.WATER
	enemy.aura_amount = 1.0
	b.energy = 3
	var thunder := Card.from_dict({ "id": "t", "name": "雷击", "cost": 1, "element": "lightning", "kind": "damage", "power": 4 })
	b.hand.append(thunder)
	b.play_card(thunder, enemy)
	_check_eq(enemy.aura_element, Element.ELECTRO_CHARGED, "感电 → 附着变复合元素")
	_check_eq(enemy.aura_amount, 1.0, "复合元素固定 1U")

	# 2U 强附着：目标无附着 → 直接挂 2U
	var s1 := _new_battle()
	s1.start_battle()
	var e1: Unit = s1.enemies[0]
	s1.energy = 3
	var strong1 := Card.from_dict({ "id": "sb1", "name": "炎爆", "cost": 1, "element": Element.FIRE, "kind": "damage", "power": 8, "aura_amount": 2 })
	s1.hand.append(strong1)
	s1.play_card(strong1, e1)
	_check_eq(e1.aura_element, Element.FIRE, "2U 火打空目标 → 附着火")
	_check_eq(e1.aura_amount, 2.0, "2U 火打空目标 → 2U")

	# 2U 火打 1U 水：水被扣光 → 攻击方残留 1U 火附着（原神式）
	var s2 := _new_battle()
	s2.start_battle()
	var e2: Unit = s2.enemies[0]
	e2.aura_element = Element.WATER
	e2.aura_amount = 1.0
	s2.energy = 3
	var strong2 := Card.from_dict({ "id": "sb2", "name": "炎爆", "cost": 1, "element": Element.FIRE, "kind": "damage", "power": 8, "aura_amount": 2 })
	s2.hand.append(strong2)
	s2.play_card(strong2, e2)
	_check_eq(e2.aura_element, Element.FIRE, "2U 火打 1U 水 → 残留火附着")
	_check_eq(e2.aura_amount, 1.0, "2U 火打 1U 水 → 残留 1U")

	# 2U 火打 2U 水：水剩 1U → 保留水，攻击方残留丢弃
	var s3 := _new_battle()
	s3.start_battle()
	var e3: Unit = s3.enemies[0]
	e3.aura_element = Element.WATER
	e3.aura_amount = 2.0
	s3.energy = 3
	var strong3 := Card.from_dict({ "id": "sb3", "name": "炎爆", "cost": 1, "element": Element.FIRE, "kind": "damage", "power": 8, "aura_amount": 2 })
	s3.hand.append(strong3)
	s3.play_card(strong3, e3)
	_check_eq(e3.aura_element, Element.WATER, "2U 火打 2U 水 → 保留水")
	_check_eq(e3.aura_amount, 1.0, "2U 火打 2U 水 → 水剩 1U")

	# 无元素卡不改变附着
	var before_element := enemy.aura_element
	var before_amount := enemy.aura_amount
	b.energy = 3
	var plain := Card.from_dict({ "id": "p", "name": "重击", "cost": 2, "element": "none", "kind": "damage", "power": 8 })
	b.hand.append(plain)
	b.play_card(plain, enemy)
	_check_eq(enemy.aura_element, before_element, "无元素卡不改变附着")
	_check_eq(enemy.aura_amount, before_amount, "无元素卡不改变附着量")

	# 空附着时打无元素卡：不许凭空挂上 amount（附着量必须保持 0）
	var fresh := _new_battle()
	fresh.start_battle()
	var fresh_enemy: Unit = fresh.enemies[0]
	fresh.energy = 3
	var plain2 := Card.from_dict({ "id": "p2", "name": "重击", "cost": 2, "element": "none", "kind": "damage", "power": 8 })
	fresh.hand.append(plain2)
	fresh.play_card(plain2, fresh_enemy)
	_check_eq(fresh_enemy.aura_element, Element.NONE, "空附着 + 无元素卡 → 仍无附着")
	_check_eq(fresh_enemy.aura_amount, 0.0, "空附着 + 无元素卡 → 附着量仍 0")

	# wind / geo 不主动附着
	for el in [Element.WIND, Element.GEO]:
		var nb := _new_battle()
		nb.start_battle()
		var ne: Unit = nb.enemies[0]
		nb.energy = 3
		var ec := Card.from_dict({ "id": "c_%s" % el, "name": el, "cost": 1, "element": el, "kind": "damage", "power": 4 })
		nb.hand.append(ec)
		nb.play_card(ec, ne)
		_check_eq(ne.aura_element, Element.NONE, "%s 不产生附着" % el)
		_check_eq(ne.aura_amount, 0.0, "%s 不产生附着量" % el)

	# 但 wind / geo 照样参与反应：扩散 / 结晶都 consume 1.0，只是自己不留附着
	var wb := _new_battle()
	wb.start_battle()
	var w_enemy: Unit = wb.enemies[0]
	w_enemy.aura_element = Element.FIRE
	w_enemy.aura_amount = 2.0
	wb.energy = 3
	var wind_card := Card.from_dict({ "id": "wnd", "name": "风刃", "cost": 1, "element": Element.WIND, "kind": "damage", "power": 4 })
	wb.hand.append(wind_card)
	wb.play_card(wind_card, w_enemy)
	_check_eq(w_enemy.aura_element, Element.FIRE, "风打火：扩散后火附着保留")
	_check_eq(w_enemy.aura_amount, 1.0, "风打火：消耗 1U（2.0 → 1.0）")

	var wb2 := _new_battle()
	wb2.start_battle()
	var w_enemy2: Unit = wb2.enemies[0]
	w_enemy2.aura_element = Element.FIRE
	w_enemy2.aura_amount = 1.0
	wb2.energy = 3
	var wind_card2 := Card.from_dict({ "id": "wnd2", "name": "风刃", "cost": 1, "element": Element.WIND, "kind": "damage", "power": 4 })
	wb2.hand.append(wind_card2)
	wb2.play_card(wind_card2, w_enemy2)
	_check_eq(w_enemy2.aura_element, Element.NONE, "风打火：消耗完 → 清空，且不留下风")
	_check_eq(w_enemy2.aura_amount, 0.0, "风打火：附着量归零")

	var gb := _new_battle()
	gb.start_battle()
	var g_enemy: Unit = gb.enemies[0]
	g_enemy.aura_element = Element.FIRE
	g_enemy.aura_amount = 1.0
	gb.energy = 3
	var geo_card := Card.from_dict({ "id": "geo1", "name": "岩击", "cost": 1, "element": Element.GEO, "kind": "damage", "power": 4 })
	gb.hand.append(geo_card)
	gb.play_card(geo_card, g_enemy)
	_check_eq(g_enemy.aura_element, Element.NONE, "岩打火：结晶消耗完 → 清空，且不留下岩")
	_check_eq(g_enemy.aura_amount, 0.0, "岩打火：附着量归零")

	# 免疫：伤害 0、不触发反应、不消耗附着
	var imm := _new_battle()
	imm.start_battle()
	var slime: Unit = imm.enemies[0]
	slime.immunities.append(Element.FIRE)
	imm.energy = 3
	var fire3 := Card.from_dict({ "id": "f3", "name": "火球", "cost": 1, "element": "fire", "kind": "damage", "power": 4 })
	imm.hand.append(fire3)
	imm.play_card(fire3, slime)
	_check_eq(slime.hp, slime.max_hp, "免疫元素伤害为 0")
	_check_eq(slime.aura_element, Element.NONE, "免疫元素不触发附着")
	_check_eq(slime.aura_amount, 0.0, "免疫元素不残留附着量")

func _test_delegation() -> void:
	print("[5] 战斗流程调用伤害模块")
	var b := _new_battle()
	var enemy: Unit = b.enemies[0]
	var plain := b.compute_damage(10, Element.FIRE, enemy)
	_check_eq(int(plain["damage"]), 10, "无附着时伤害 = 基础值")

	enemy.aura_element = Element.WATER
	enemy.aura_amount = 1.0
	var reacted := b.compute_damage(10, Element.FIRE, enemy)
	_check_eq(int(reacted["damage"]), 15, "火打水附着 = 10 × 1.5")
	_check_eq(str(reacted["reaction"]), "蒸发", "反应名")

	# 纯算法本身的更多用例在 tests/damage_test.gd
	# 胜负判定 / 自动战斗的用例在 tests/battle_m2_test.gd（M2 起改为「打掉 HQ」）
