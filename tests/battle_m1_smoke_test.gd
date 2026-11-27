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
const EXPECTED_CHECKS := 54


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


## v3 起附着是多槽（auras），断言某一槽的元素量。没有这一槽 = 直接判红并打印当前全部槽。
func _check_aura(u: Unit, element: String, amount: float, message: String) -> void:
	var a := u.get_aura(element)
	if a.is_empty():
		_check(false, "%s（期望 %s %dU，实际没有这一槽；当前附着：%s）" % [
			message, Element.display_name(element), int(amount), u.describe_auras()])
		return
	_check_eq(float(a.get("amount", 0.0)), amount,
		"%s（%s 槽 %dU）" % [message, Element.display_name(element), int(amount)])


func _has_buff(u: Unit, kind: String) -> bool:
	for b in u.buffs:
		if b.kind == kind:
			return true
	return false


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
	_start(b)
	_check_eq(b.turn, 1, "开战后进入第 1 回合")
	_check_eq(b.hand.size(), 4, "玩家先手：起手 4 张 + 第 1 回合不抽（E7b）")
	_check_eq(b.deck.size(), 16, "牌库扣掉起手 4 张（首回合不抽）")

	var hp_before := b.player.hp
	var deck_before := b.deck.size()
	b.energy = 0
	b.end_turn()
	_check_eq(b.turn, 2, "结束回合后进入第 2 回合")
	# M1 的「敌人每回合打玩家 4 点」在 E15 被删掉（胜负改成 HQ）。玩家血量不再由回合推进改变。
	_check_eq(b.player.hp, hp_before, "end_turn() 不再白扣玩家血量（M1 直伤已退役）")
	_check_eq(b.energy, b.max_energy, "新回合能量回满")
	_check_eq(b.hand.size(), 5, "每回合只抽 1 张（不补满；第 2 回合 4 → 5）")
	_check_eq(b.deck.size(), deck_before - 1, "牌库每回合只扣 1 张")

	# 手牌满时抽牌 → 爆牌：牌从牌堆顶弹出后直接丢弃
	var c := _new_battle()
	c.deck = _make_deck(20)
	_start(c)
	while c.hand.size() < Battle.MAX_HAND:
		c.hand.append(Card.from_dict({ "id": "fill", "name": "填手牌", "cost": 1, "kind": "damage", "power": 1 }))
	var full_deck := c.deck.size()
	c.end_turn()
	_check_eq(c.hand.size(), Battle.MAX_HAND, "手牌满时抽到的牌丢弃，不超上限")
	_check_eq(c.deck.size(), full_deck - 1, "手牌满时依然从牌库弹出（牌库 -1）")


func _test_energy() -> void:
	print("[3] 能量与出牌")
	var b := _new_battle()
	_start(b)
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
	print("[4] 元素附着（v3 多槽：1U/2U 附着、反应消耗、共存型反应、风岩不附着）")
	var b := _new_battle()
	_start(b)
	var enemy: Unit = b.enemies[0]
	_check(enemy.auras.is_empty(), "初始无附着（槽数组为空）")
	_check_eq(enemy.describe_auras(), "无", "初始 describe_auras 显示「无」")

	b.energy = 3
	var fire_card := Card.from_dict({ "id": "f", "name": "火球", "cost": 1, "element": "fire", "kind": "damage", "power": 4 })
	b.hand.append(fire_card)
	b.play_card(fire_card, enemy)
	_check_aura(enemy, Element.FIRE, 1.0, "打火卡后挂 1U 火")
	_check_eq(int(enemy.get_aura(Element.FIRE).get("duration", 0)), 2, "普通附着持续 2 回合")

	b.energy = 3
	var fire2 := Card.from_dict({ "id": "f2", "name": "火球", "cost": 1, "element": "fire", "kind": "damage", "power": 4 })
	b.hand.append(fire2)
	b.play_card(fire2, enemy)
	_check_aura(enemy, Element.FIRE, 2.0, "同元素叠加，封顶 2U")
	_check_eq(enemy.auras.size(), 1, "同元素叠加不新增槽（还是 1 槽）")

	# 水打 2U 火：蒸发 consume 1.0 → 火剩 1U，水的残留量 = 1-1 = 0，不入槽
	b.energy = 3
	var water_card := Card.from_dict({ "id": "w", "name": "水刃", "cost": 1, "element": "water", "kind": "damage", "power": 4 })
	b.hand.append(water_card)
	b.play_card(water_card, enemy)
	_check_aura(enemy, Element.FIRE, 1.0, "蒸发消耗 1U：火剩 1U")
	_check(enemy.get_aura(Element.WATER).is_empty(), "蒸发后水槽不残留（残留量被 consume 吃光）")

	# 再水打 1U 火：蒸发把火吃完 → 槽清空
	b.energy = 3
	var water2 := Card.from_dict({ "id": "w2", "name": "水刃", "cost": 1, "element": "water", "kind": "damage", "power": 4 })
	b.hand.append(water2)
	b.play_card(water2, enemy)
	_check(enemy.auras.is_empty(), "蒸发把火吃完 → 槽清空")
	_check_eq(enemy.describe_auras(), "无", "槽清空后 describe_auras 回到「无」")

	# 共存型反应（v3 核心变更）：水 1U + 雷 → 感电。consume 0，两槽都保留，只挂 shock 状态。
	enemy.add_or_refresh_aura(Element.WATER, 1.0, 2)
	b.energy = 3
	var thunder := Card.from_dict({ "id": "t", "name": "雷击", "cost": 1, "element": "lightning", "kind": "damage", "power": 4 })
	b.hand.append(thunder)
	b.play_card(thunder, enemy)
	_check_aura(enemy, Element.WATER, 1.0, "感电不消耗：水槽原地保留 1U")
	_check_aura(enemy, Element.LIGHTNING, 1.0, "感电不消耗：雷也留在新槽里 1U")
	_check_eq(enemy.auras.size(), 2, "感电后是两槽共存（不再是复合元素 id）")
	_check(_has_buff(enemy, "shock"), "感电挂上 shock 状态")

	# 2U 强附着：目标无附着 → 直接挂 2U，持续 3 回合
	var s1 := _new_battle()
	_start(s1)
	var e1: Unit = s1.enemies[0]
	s1.energy = 3
	var strong1 := Card.from_dict({ "id": "sb1", "name": "炎爆", "cost": 1, "element": Element.FIRE, "kind": "damage", "power": 8, "aura_amount": 2 })
	s1.hand.append(strong1)
	s1.play_card(strong1, e1)
	_check_aura(e1, Element.FIRE, 2.0, "2U 火打空目标 → 挂 2U 火")
	_check_eq(int(e1.get_aura(Element.FIRE).get("duration", 0)), 3, "强附着（>1U）持续 3 回合")

	# 2U 火打 1U 水：水被扣光 → 攻击方残留 1U 火附着（原神式）
	var s2 := _new_battle()
	_start(s2)
	var e2: Unit = s2.enemies[0]
	e2.add_or_refresh_aura(Element.WATER, 1.0, 2)
	s2.energy = 3
	var strong2 := Card.from_dict({ "id": "sb2", "name": "炎爆", "cost": 1, "element": Element.FIRE, "kind": "damage", "power": 8, "aura_amount": 2 })
	s2.hand.append(strong2)
	s2.play_card(strong2, e2)
	_check(e2.get_aura(Element.WATER).is_empty(), "2U 火打 1U 水 → 水槽被扣光移除")
	_check_aura(e2, Element.FIRE, 1.0, "2U 火打 1U 水 → 残留 1U 火")

	# 2U 火打 2U 水：水剩 1U，火的残留 2-1 = 1U 也入槽（v3：残留量 > 0 就入槽）
	var s3 := _new_battle()
	_start(s3)
	var e3: Unit = s3.enemies[0]
	e3.add_or_refresh_aura(Element.WATER, 2.0, 3)
	s3.energy = 3
	var strong3 := Card.from_dict({ "id": "sb3", "name": "炎爆", "cost": 1, "element": Element.FIRE, "kind": "damage", "power": 8, "aura_amount": 2 })
	s3.hand.append(strong3)
	s3.play_card(strong3, e3)
	_check_aura(e3, Element.WATER, 1.0, "2U 火打 2U 水 → 水剩 1U")
	_check_aura(e3, Element.FIRE, 1.0, "2U 火打 2U 水 → 火残留 1U 也入槽")

	# 无元素卡不改变附着
	var before := enemy.describe_auras()
	b.energy = 3
	var plain := Card.from_dict({ "id": "p", "name": "重击", "cost": 2, "element": "none", "kind": "damage", "power": 8 })
	b.hand.append(plain)
	b.play_card(plain, enemy)
	_check_eq(enemy.describe_auras(), before, "无元素卡不改变附着")

	# 空附着时打无元素卡：不许凭空挂上 amount
	var fresh := _new_battle()
	_start(fresh)
	var fresh_enemy: Unit = fresh.enemies[0]
	fresh.energy = 3
	var plain2 := Card.from_dict({ "id": "p2", "name": "重击", "cost": 2, "element": "none", "kind": "damage", "power": 8 })
	fresh.hand.append(plain2)
	fresh.play_card(plain2, fresh_enemy)
	_check(fresh_enemy.auras.is_empty(), "空附着 + 无元素卡 → 仍然没有槽")

	# wind / geo 不主动附着
	for el in [Element.WIND, Element.GEO]:
		var nb := _new_battle()
		_start(nb)
		var ne: Unit = nb.enemies[0]
		nb.energy = 3
		var ec := Card.from_dict({ "id": "c_%s" % el, "name": el, "cost": 1, "element": el, "kind": "damage", "power": 4 })
		nb.hand.append(ec)
		nb.play_card(ec, ne)
		_check(ne.auras.is_empty(), "%s 不产生附着（槽数组仍为空）" % el)

	# 但 wind / geo 照样参与反应：扩散 / 结晶都 consume 1.0，只是自己不留附着
	var wb := _new_battle()
	_start(wb)
	var w_enemy: Unit = wb.enemies[0]
	w_enemy.add_or_refresh_aura(Element.FIRE, 2.0, 3)
	wb.energy = 3
	var wind_card := Card.from_dict({ "id": "wnd", "name": "风刃", "cost": 1, "element": Element.WIND, "kind": "damage", "power": 4 })
	wb.hand.append(wind_card)
	wb.play_card(wind_card, w_enemy)
	_check_aura(w_enemy, Element.FIRE, 1.0, "风打火：扩散消耗 1U（2 → 1）")
	_check(w_enemy.get_aura(Element.WIND).is_empty(), "风打火：风自己不留下附着")

	var wb2 := _new_battle()
	_start(wb2)
	var w_enemy2: Unit = wb2.enemies[0]
	w_enemy2.add_or_refresh_aura(Element.FIRE, 1.0, 2)
	wb2.energy = 3
	var wind_card2 := Card.from_dict({ "id": "wnd2", "name": "风刃", "cost": 1, "element": Element.WIND, "kind": "damage", "power": 4 })
	wb2.hand.append(wind_card2)
	wb2.play_card(wind_card2, w_enemy2)
	_check(w_enemy2.auras.is_empty(), "风打 1U 火：消耗完 → 清空，且不留下风")

	var gb := _new_battle()
	_start(gb)
	var g_enemy: Unit = gb.enemies[0]
	g_enemy.add_or_refresh_aura(Element.FIRE, 1.0, 2)
	gb.energy = 3
	var geo_card := Card.from_dict({ "id": "geo1", "name": "岩击", "cost": 1, "element": Element.GEO, "kind": "damage", "power": 4 })
	gb.hand.append(geo_card)
	gb.play_card(geo_card, g_enemy)
	_check(g_enemy.auras.is_empty(), "岩打火：结晶消耗完 → 清空，且不留下岩")

	# 免疫：伤害 0、不触发反应、不消耗附着
	var imm := _new_battle()
	_start(imm)
	var slime: Unit = imm.enemies[0]
	slime.immunities.append(Element.FIRE)
	imm.energy = 3
	var fire3 := Card.from_dict({ "id": "f3", "name": "火球", "cost": 1, "element": "fire", "kind": "damage", "power": 4 })
	imm.hand.append(fire3)
	imm.play_card(fire3, slime)
	_check_eq(slime.hp, slime.max_hp, "免疫元素伤害为 0")
	_check(slime.auras.is_empty(), "免疫元素不产生附着")

func _test_delegation() -> void:
	print("[5] 战斗流程调用伤害模块")
	var b := _new_battle()
	var enemy: Unit = b.enemies[0]
	var plain := b.compute_damage(10, Element.FIRE, enemy)
	_check_eq(int(plain["damage"]), 10, "无附着时伤害 = 基础值")

	enemy.add_or_refresh_aura(Element.WATER, 1.0, 2)
	var reacted := b.compute_damage(10, Element.FIRE, enemy)
	_check_eq(int(reacted["damage"]), 15, "火打水附着 = 10 × 1.5")
	_check_eq(str(reacted["reaction"]), "蒸发", "反应名")

	# 纯算法本身的更多用例在 tests/damage_test.gd
	# 胜负判定 / 自动战斗的用例在 tests/battle_m2_test.gd（M2 起改为「打掉 HQ」）


## 建局：固定玩家先手 + 开始第一个回合（E7b 后 start_battle() 只发牌）
func _start(b: Battle) -> void:
	b.first_move = "player"
	b.start_battle()
	b.begin_first_turn()
