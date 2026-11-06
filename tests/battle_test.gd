extends SceneTree
## 战斗流程测试：回合推进、能量与出牌、元素附着、胜负、自动战斗
##
## 运行：
##   ... --headless --path . --script res://tests/battle_test.gd
##
## 这里测的是 Battle 的行为，不是算法。
## 回合交换（turn 推进、敌人行动、能量重置）和元素附着都在这一层。

var failures: int = 0
var checks: int = 0
var table: ReactionTable
var cards: Array[Card] = []
var _setup_warned: bool = false


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
	_test_outcome()
	_test_full_battle()

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


# ---------------------------------------------------------------- 用例

func _test_setup() -> void:
	print("[1] 初始化")
	var b := _new_battle(60, 30, false)   # 不要兜底，这里就是要测 setup() 本身
	_check(b.player != null, "玩家已设置")
	_check_eq(b.enemies.size(), 1, "敌人数")
	_check_eq(b.turn, 0, "回合数从 0 开始")
	_check_eq(b.energy, b.max_energy, "能量已回满")
	_check_eq(b.hand.size(), 0, "开局手牌为空（start_battle 才抽）")


func _test_turn_advance() -> void:
	print("[2] 回合交换：推进 / 敌人行动 / 能量重置")
	var b := _new_battle()
	b.start_battle()
	_check_eq(b.turn, 1, "开战后进入第 1 回合")
	_check_eq(b.hand.size(), Battle.MAX_HAND, "手牌抽到上限")

	var hp_before := b.player.hp
	b.energy = 0
	b.end_turn()
	_check_eq(b.turn, 2, "结束回合后进入第 2 回合")
	_check(b.player.hp < hp_before, "敌人行动后玩家掉血")
	_check_eq(b.energy, b.max_energy, "新回合能量回满")
	_check_eq(b.hand.size(), Battle.MAX_HAND, "新回合手牌补满")


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

	# 无元素卡不改变附着
	var before_element := enemy.aura_element
	b.energy = 3
	var plain := Card.from_dict({ "id": "p", "name": "重击", "cost": 2, "element": "none", "kind": "damage", "power": 8 })
	b.hand.append(plain)
	b.play_card(plain, enemy)
	_check_eq(enemy.aura_element, before_element, "无元素卡不改变附着")

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


func _test_outcome() -> void:
	print("[6] 胜负判定")
	var win := _new_battle()
	win.start_battle()
	win.enemies[0].hp = 0
	_check(win.is_over(), "敌人全灭 → 战斗结束")
	_check_eq(win.outcome(), "WIN", "结果 WIN")

	var lose := _new_battle()
	lose.start_battle()
	lose.player.hp = 0
	_check(lose.is_over(), "玩家倒下 → 战斗结束")
	_check_eq(lose.outcome(), "LOSE", "结果 LOSE")

	var going := _new_battle()
	going.start_battle()
	_check(not going.is_over(), "双方都活着 → 未结束")
	_check_eq(going.outcome(), "RUNNING", "结果 RUNNING")


func _test_full_battle() -> void:
	print("[7] 完整自动战斗")
	var b := _new_battle(60, 24)
	var result := b.run_auto(30)
	_check(result == "WIN" or result == "LOSE", "战斗能正常结束（结果 %s）" % result)
	_check(b.turn > 0, "至少进行了 1 回合")
	_check(b.get_log().length() > 50, "战斗日志非空")
