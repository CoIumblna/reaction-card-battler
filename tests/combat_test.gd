extends SceneTree
## 战斗测试（M2）：移动 / 攻击与反击 / 行动花费 / 单位对撞反应 / 前线独占
##
## 运行：
##   ... --headless --path . --script res://tests/combat_test.gd
##
## 只测棋盘上的单位行为；出牌/部署在 battle_m2_test，数据在 data_test。

var failures: int = 0
var checks: int = 0
var table: ReactionTable


func _initialize() -> void:
	print("========== 战斗测试（M2） ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	_test_move()
	_test_attack()
	_test_operation_cost()
	_test_unit_reaction()
	_test_front_exclusive()
	_test_death()

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
	var player := Unit.from_dict({ "id": "player", "name": "旅行者", "hp": 999 })
	var enemy := Unit.from_dict({ "id": "enemy", "name": "训练假人", "hp": 9999 })
	var enemies: Array[Unit] = [enemy]
	b.setup(player, enemies, DataLoader.load_cards(), table, 20261115)
	return b


## 直接往棋盘上摆一个单位（绕开出牌/能量，专测移动与攻击）
func _place(b: Battle, line: String, index: int, attack: int, hp: int, op_cost: int = 1, element: String = Element.NONE, owner: String = "player") -> Unit:
	var u := Unit.from_dict({
		"id": "u_%s_%d" % [line, index], "name": "单位", "hp": hp,
		"attack": attack, "operation_cost": op_cost, "element": element, "owner": owner,
	})
	b.board.place(u, line, index)
	return u


# ---------------------------------------------------------------- 用例

func _test_move() -> void:
	print("[1] 移动（M2 / E8）")
	var b := _new_battle()
	if not b.has_method("move_unit"):
		_check(false, "Battle 还没有 move_unit()（移动的前置）")
		return
	if not b.board.has_method("position_of"):
		_check(false, "Board 还没有 position_of()（移动的前置）")
		return

	var u := _place(b, "player_support", 1, 2, 3)
	b.energy = 20
	_check_eq(b.move_unit(u, "front", 0), true, "支援线 → 前线（相邻）可以移动")
	_check_eq(b.board.position_of(u), ["front", 0], "位置更新为 front / 0")
	_check_eq(b.board.unit_at("player_support", 1), null, "原格清空")
	_check(b.board.unit_at("front", 0) == u, "新格是这个单位")
	_check_eq(u.has_acted, true, "移动后标记为已行动")

	# 不能跳线：支援线不能直接到敌方支援线
	var u2 := _place(b, "player_support", 2, 2, 3)
	b.energy = 20
	_check_eq(b.move_unit(u2, "enemy_support", 0), false, "支援线不能直接跳到敌方支援线（不相邻）")
	_check_eq(b.board.unit_at("player_support", 2) == u2, true, "失败的移动不改变位置")
	_check_eq(u2.has_acted, false, "失败的移动不标记已行动")

	# 目标格被占
	var u3 := _place(b, "player_support", 3, 2, 3)
	b.energy = 20
	_check_eq(b.move_unit(u3, "front", 0), false, "目标格有人不能移过去")
	_check_eq(u3.has_acted, false, "移动失败不算已行动")
	_check_eq(b.energy, 20, "移动失败不扣作战费")

	# 已行动的单位不能再动（含召唤失调）
	var u4 := _place(b, "player_support", 4, 2, 3)
	u4.has_acted = true
	b.energy = 20
	_check_eq(b.move_unit(u4, "front", 1), false, "已行动 / 召唤失调的单位本回合不能再移动")

	# 单向：前线不能退回支援线（撤退是 M3 的 Retreat 关键词，不是常规行动）
	var u5 := _place(b, "front", 2, 2, 3)
	b.energy = 20
	_check_eq(b.move_unit(u5, "player_support", 1), false, "前线不能退回支援线（移动是单向的）")
	_check_eq(b.board.unit_at("front", 2) == u5, true, "被拒绝的撤退不改变位置")


func _test_attack() -> void:
	print("[2] 攻击与反击（M2 / E9）")
	var b := _new_battle()
	if not b.has_method("attack_unit"):
		_check(false, "Battle 还没有 attack_unit()（攻击的前置）")
		return

	# 前线打敌方支援线：互相反击
	var atk := _place(b, "front", 1, 3, 5)
	var def := _place(b, "enemy_support", 2, 2, 4, 1, Element.NONE, "enemy")
	b.energy = 20
	_check_eq(b.attack_unit(atk, def), true, "前线可以攻击敌方支援线")
	_check_eq(def.hp, 1, "目标掉 3 点（4 - 3）")
	_check_eq(atk.hp, 3, "攻击者吃反击 2 点（5 - 2）")
	_check_eq(atk.has_acted, true, "攻击后标记为已行动")

	# 不相邻：我方支援线不能直接打敌方支援线
	var b2 := _new_battle()
	var a2 := _place(b2, "player_support", 1, 3, 5)
	var d2 := _place(b2, "enemy_support", 2, 2, 4, 1, Element.NONE, "enemy")
	b2.energy = 20
	_check_eq(b2.attack_unit(a2, d2), false, "支援线不能直接打敌方支援线（不相邻）")
	_check_eq(d2.hp, 4, "失败的攻击不造成伤害")
	_check_eq(a2.has_acted, false, "失败的攻击不标记已行动")

	# 打 HQ：只掉 HQ 防，不反击
	var b3 := _new_battle()
	var a3 := _place(b3, "front", 1, 3, 5)
	var hq: Unit = b3.board.unit_at("enemy_support", 0)
	b3.energy = 20
	_check_eq(b3.attack_unit(a3, hq), true, "前线可以攻击敌方 HQ")
	_check_eq(hq.hp, 17, "HQ 掉 3 点（20 - 3）")
	_check_eq(a3.hp, 5, "打 HQ 不挨反击")

	b3.energy = 20
	_check_eq(b3.attack_unit(a3, hq), false, "已行动的单位本回合不能再攻击")

	# 不能打友军 / 己方 HQ（各用一个没行动过的攻击者，避免"已行动"掩盖判定）
	var b4 := _new_battle()
	var a4 := _place(b4, "front", 1, 3, 5)
	var ally := _place(b4, "player_support", 2, 2, 4)
	b4.energy = 20
	_check_eq(b4.attack_unit(a4, ally), false, "不能攻击友军单位")
	_check_eq(ally.hp, 4, "友军没掉血")

	var a5 := _place(b4, "front", 3, 3, 5)
	var my_hq: Unit = b4.board.unit_at("player_support", 0)
	b4.energy = 20
	_check_eq(b4.attack_unit(a5, my_hq), false, "不能攻击己方 HQ")
	_check_eq(my_hq.hp, 20, "己方 HQ 没掉血")


func _test_operation_cost() -> void:
	print("[3] 行动花费（M2 / E10）")
	var b := _new_battle()
	if not b.has_method("move_unit") or not b.has_method("attack_unit"):
		_check(false, "Battle 还没有 move_unit / attack_unit（行动花费的前置）")
		return

	# 移动付费
	var u := _place(b, "player_support", 1, 2, 3, 2)
	b.energy = 5
	_check_eq(b.move_unit(u, "front", 0), true, "有钱可以移动")
	_check_eq(b.energy, 3, "移动扣作战费 2 点")

	# 没钱不能动，且不扣费
	var u2 := _place(b, "player_support", 2, 2, 3, 2)
	b.energy = 1
	_check_eq(b.move_unit(u2, "front", 1), false, "能量不足不能移动")
	_check_eq(b.board.unit_at("player_support", 2) == u2, true, "能量不足时不改变位置")
	_check_eq(b.energy, 1, "能量不足时不扣费")

	# 攻击付费
	var atk := _place(b, "front", 2, 3, 5, 2)
	var hq: Unit = b.board.unit_at("enemy_support", 0)
	b.energy = 1
	_check_eq(b.attack_unit(atk, hq), false, "能量不足不能攻击")
	_check_eq(hq.hp, 20, "能量不足时 HQ 不掉血")
	_check_eq(b.energy, 1, "能量不足时不扣费")

	b.energy = 5
	_check_eq(b.attack_unit(atk, hq), true, "有钱可以攻击")
	_check_eq(b.energy, 3, "攻击扣作战费 2 点")


func _test_unit_reaction() -> void:
	print("[4] 单位对撞也走元素反应（M2 / E9）")
	var b := _new_battle()
	if not b.has_method("attack_unit"):
		_check(false, "Battle 还没有 attack_unit()（单位对撞反应的前置）")
		return

	var atk := _place(b, "front", 1, 4, 5, 1, Element.FIRE)
	var def := _place(b, "enemy_support", 2, 2, 10, 1, Element.NONE, "enemy")
	def.aura_element = Element.WATER
	def.aura_amount = 1.0
	b.energy = 20
	_check_eq(b.attack_unit(atk, def), true, "火单位可以攻击水附着的单位")
	_check_eq(def.hp, 4, "蒸发：4 × 1.5 = 6 伤害（10 → 4）")
	_check_eq(def.aura_element, Element.NONE, "水被蒸发消耗完 → 附着清空")
	_check_eq(atk.hp, 3, "反击仍是 2 点（5 → 3）")


func _test_front_exclusive() -> void:
	print("[5] 前线独占（M2 / E11）")
	var b := _new_battle()
	if not b.has_method("move_unit"):
		_check(false, "Battle 还没有 move_unit()（前线独占的前置）")
		return

	var enemy_front := _place(b, "front", 0, 2, 5, 1, Element.NONE, "enemy")
	var mine := _place(b, "player_support", 1, 2, 3)
	b.energy = 20
	_check_eq(b.move_unit(mine, "front", 1), false, "敌方占着前线时不能移进前线")
	_check_eq(b.board.unit_at("player_support", 1) == mine, true, "被拒绝时位置不变")
	_check_eq(mine.has_acted, false, "被拒绝时不算已行动")

	# 把敌方前线单位挪走（E12 死亡移除之前，先用棋盘 API 清场）
	b.board.move("front", 0, "enemy_support", 3)
	b.energy = 20
	_check_eq(b.move_unit(mine, "front", 1), true, "敌方离开前线后可以推进")

	# 己方占着前线时，可以继续往剩余空位推进
	var b2 := _new_battle()
	_place(b2, "front", 0, 2, 5)
	var mine2 := _place(b2, "player_support", 1, 2, 3)
	b2.energy = 20
	_check_eq(b2.move_unit(mine2, "front", 1), true, "己方占着前线时可以继续推进")


func _test_death() -> void:
	print("[6] 死亡与移除（M2 / E12）")
	var b := _new_battle()
	if not b.board.has_method("remove"):
		_check(false, "Board 还没有 remove()（死亡移除的前置）")
		return

	# 目标被打死 → 离场
	var atk := _place(b, "front", 1, 5, 5)
	var def := _place(b, "enemy_support", 2, 2, 3, 1, Element.NONE, "enemy")
	b.energy = 20
	_check_eq(b.attack_unit(atk, def), true, "攻击成立")
	_check_eq(def.hp <= 0, true, "目标血量归零")
	_check_eq(b.board.unit_at("enemy_support", 2), null, "死亡的目标从棋盘移除")
	_check_eq(b.board.units_in("enemy_support").size(), 1, "敌方支援线只剩 HQ")

	# 反击打死攻击者 → 攻击者也离场
	var b2 := _new_battle()
	var a2 := _place(b2, "front", 1, 2, 3)
	var d2 := _place(b2, "enemy_support", 2, 5, 10, 1, Element.NONE, "enemy")
	b2.energy = 20
	_check_eq(b2.attack_unit(a2, d2), true, "攻击成立")
	_check_eq(a2.hp <= 0, true, "攻击者被反击打死")
	_check_eq(b2.board.unit_at("front", 1), null, "死亡的攻击者从棋盘移除")
	_check_eq(d2.hp, 8, "目标受伤但仍活着（10 - 2）")

	# HQ 不会被移除（HQ 归零是 E13 的胜负，不是离场）
	var b3 := _new_battle()
	var a3 := _place(b3, "front", 1, 30, 5)
	var hq: Unit = b3.board.unit_at("enemy_support", 0)
	b3.energy = 20
	_check_eq(b3.attack_unit(a3, hq), true, "攻击敌方 HQ")
	_check_eq(hq.hp, 0, "HQ 血量归零")
	_check(b3.board.unit_at("enemy_support", 0) != null, "HQ 不从棋盘移除（胜负交给 E13）")
