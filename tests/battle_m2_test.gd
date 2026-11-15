extends SceneTree
## M2 流程测试：Kredit 成长 / 单位部署 / 召唤失调 / HQ 接入
##
## 运行：
##   ... --headless --path . --script res://tests/battle_m2_test.gd
##
## M1 的 battle_test.gd 保留不动（旧流程仍在跑）；这里只验收 M2 新加的部分。

var failures: int = 0
var checks: int = 0
var table: ReactionTable


func _initialize() -> void:
	print("========== M2 流程测试 ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	_test_kredit()
	_test_deploy()
	_test_summoning_sickness()
	_test_hq_wired()

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


func _new_battle(player_hp: int = 60) -> Battle:
	var b := Battle.new()
	var player := Unit.from_dict({ "id": "player", "name": "旅行者", "hp": player_hp })
	var enemy := Unit.from_dict({ "id": "enemy", "name": "训练假人", "hp": 9999 })
	var enemies: Array[Unit] = [enemy]
	b.setup(player, enemies, DataLoader.load_cards(), table, 20261115)
	return b


func _unit_card(id: String, cost: int, attack: int, defense: int, element: String = Element.NONE) -> Card:
	return Card.from_dict({
		"id": id, "name": id, "type": "unit", "cost": cost,
		"element": element, "attack": attack, "defense": defense,
	})


# ---------------------------------------------------------------- 用例

func _test_kredit() -> void:
	print("[1] Kredit 成长（M2 / E6）")
	var b := _new_battle()
	_check_eq(b.max_energy, 0, "setup 后 Kredit 上限为 0（还没开战）")

	b.start_battle()
	_check_eq(b.turn, 1, "进入第 1 回合")
	_check_eq(b.max_energy, 1, "第 1 回合 Kredit 上限 = 1")
	_check_eq(b.energy, 1, "回合开始回满到上限")

	b.end_turn()
	_check_eq(b.max_energy, 2, "第 2 回合上限 = 2（每回合 +1）")
	_check_eq(b.energy, 2, "回合开始回满到 2")

	b.end_turn()
	b.end_turn()
	_check_eq(b.max_energy, 4, "第 4 回合上限 = 4")

	# 封顶：KARDS 原版上限 12
	b.max_energy = 12
	b.energy = 0
	b.end_turn()
	_check_eq(b.max_energy, 12, "上限封顶 12（不再增长）")
	_check_eq(b.energy, 12, "封顶后回满到 12")


func _test_deploy() -> void:
	print("[2] 单位部署（M2 / E4）")
	var b := _new_battle()
	b.start_battle()
	var board = b.get("board")
	if board == null:
		_check(false, "Battle 还没有 board 字段（部署的前置）")
		return

	b.energy = 5
	var tank := _unit_card("tank", 3, 3, 4)
	b.hand.append(tank)
	_check(b.play_card(tank, b.player), "单位卡可以打出")
	_check_eq(b.energy, 2, "扣掉 3 费")
	_check_eq(b.hand.has(tank), false, "单位卡移出手牌")

	var u: Unit = board.unit_at("player_support", 1)
	_check(u != null, "单位放在我方支援线第一个空位（1 号）")
	if u != null:
		_check_eq(u.attack, 3, "攻击力取 card.attack")
		_check_eq(u.hp, 4, "hp 取 card.defense")
		_check_eq(u.max_hp, 4, "max_hp 同步为 4")
		_check_eq(u.is_hq, false, "部署的不是 HQ")

	# 支援线还剩 3 个空位（1 号已被占）→ 只能再放 3 个
	b.energy = 10
	var placed := 0
	for i in range(4):
		var c := _unit_card("filler%d" % i, 1, 1, 1)
		b.hand.append(c)
		if b.play_card(c, b.player):
			placed += 1
	_check_eq(placed, 3, "支援线剩余 3 个空位能放（满线共 4 个单位）")

	var over := _unit_card("overflow", 1, 1, 1)
	b.hand.append(over)
	var energy_before := b.energy
	_check_eq(b.play_card(over, b.player), false, "支援线满时部署失败")
	_check_eq(b.energy, energy_before, "失败的部署不扣能量")
	_check_eq(b.hand.has(over), true, "失败的卡留在手里")


func _test_summoning_sickness() -> void:
	print("[3] 召唤失调（M2 / E5）")
	var b := _new_battle()
	b.start_battle()
	var board = b.get("board")
	if board == null:
		_check(false, "Battle 还没有 board 字段（召唤失调的前置）")
		return

	b.energy = 5
	var c := _unit_card("grunt", 1, 2, 2)
	b.hand.append(c)
	b.play_card(c, b.player)
	var u: Unit = board.unit_at("player_support", 1)
	if u == null:
		_check(false, "部署失败，后面没法测召唤失调")
		return
	_check_eq(u.has_acted, true, "部署当回合就标记为已行动（不能动/攻击）")

	b.end_turn()
	_check_eq(u.has_acted, false, "进入下一回合后解除召唤失调")


func _test_hq_wired() -> void:
	print("[4] HQ 接入 Battle（M2 / E3）")
	var b := _new_battle()
	_check(b.get("board") != null, "Battle 持有 Board（setup 时建好）")
	var board = b.get("board")
	if board == null:
		return
	var phq: Unit = board.unit_at("player_support", 0)
	var ehq: Unit = board.unit_at("enemy_support", 0)
	_check(phq != null and phq.is_hq, "我方 HQ 就位")
	_check(ehq != null and ehq.is_hq, "敌方 HQ 就位")
	if phq != null:
		_check_eq(phq.max_hp, 20, "HQ 最大防御 20")
		_check_eq(phq.hp, 20, "HQ 初始满防")
	_check(phq != ehq, "双方 HQ 是两个独立对象")
