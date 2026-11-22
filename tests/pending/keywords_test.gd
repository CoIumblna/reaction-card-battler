extends SceneTree
## M3.1 行动经济 + 关键词 + 闪击验收测试 —— 待实现
##
## 运行：
##   ... --headless --path . --script res://tests/pending/keywords_test.gd
##
## 规格：docs/adr/004-m3-keywords.md 决定 1 + docs/m3-scope.md §M3.1
##   - Unit.has_moved / has_attacked 替代 has_acted；回合开始都清
##   - 普通单位：移动或攻击二选一
##   - 坦克（unit_class == "tank"）：移动 + 攻击都能做
##   - 召唤失调：部署当回合两个标志 true；闪击 Blitz：两个标志 false
##   - 闪击 + 坦克：部署当回合可以「移动 + 攻击」
##
## 【启用方式】M3.1 全绿后移到 tests/ 下。

var failures: int = 0
var checks: int = 0
var table: ReactionTable

const EXPECTED_CHECKS := 17


func _initialize() -> void:
	print("========== 行动经济 / 关键词测试（M3.1） ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	_test_card_parse()
	_test_deploy_normal()
	_test_deploy_blitz()
	_test_blitz_can_move()
	_test_blitz_can_attack()
	_test_blitz_not_both()
	_test_blitz_tank_both()
	_test_tank_without_blitz()
	_test_turn_start_clears()

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
	b.setup(player, enemies, DataLoader.load_cards(), table, 20261126)
	b.start_battle()
	return b


func _unit_card(id: String, cost: int, attack: int, defense: int, keywords: Array = [], unit_class: String = "") -> Card:
	return Card.from_dict({
		"id": id, "name": id, "type": "unit", "cost": cost,
		"attack": attack, "defense": defense,
		"keywords": keywords, "unit_class": unit_class,
	})


func _rookie(b: Battle, id: String = "scout") -> Unit:
	b.energy = 10
	var c := _unit_card(id, 1, 2, 2, ["blitz"], "")
	b.hand.append(c)
	b.play_card(c, b.player)
	return b.board.unit_at("player_support", 1)


func _placed(b: Battle, line: String, idx: int, hp: int, attack: int, owner: String) -> Unit:
	var u := Unit.from_dict({ "id": "u_%s_%d" % [line, idx], "name": "单位", "hp": hp, "attack": attack, "owner": owner })
	b.board.place(u, line, idx)
	return u


func _has_flags(u: Unit) -> bool:
	return u != null and u.get("has_moved") != null and u.get("has_attacked") != null


# ---------------------------------------------------------------- 用例

func _test_card_parse() -> void:
	print("[0] Card 数据层：keywords / unit_class 解析")
	var c := _unit_card("tank_blitz", 3, 3, 5, ["blitz"], "tank")
	_check(c.keywords.has("blitz"), "Card.from_dict 解析 keywords（blitz）")
	_check_eq(c.unit_class, "tank", "Card.from_dict 解析 unit_class（tank）")


func _test_deploy_normal() -> void:
	print("[1] 普通单位部署：召唤失调（两个标志都 true）")
	var b := _new_battle()
	b.energy = 5
	var c := _unit_card("footman", 1, 1, 2)
	b.hand.append(c)
	_check(b.play_card(c, b.player), "普通单位部署成功")
	var u: Unit = b.board.unit_at("player_support", 1)
	_check(_has_flags(u) and u.has_moved == true, "普通单位部署当回合 has_moved = true")
	_check(_has_flags(u) and u.has_attacked == true, "普通单位部署当回合 has_attacked = true")


func _test_deploy_blitz() -> void:
	print("[2] 闪击部署：不陷入召唤失调")
	var b := _new_battle()
	b.energy = 5
	var c := _unit_card("scout", 1, 1, 1, ["blitz"])
	b.hand.append(c)
	_check(b.play_card(c, b.player), "闪击单位部署成功")
	var u: Unit = b.board.unit_at("player_support", 1)
	_check(_has_flags(u) and u.has_moved == false, "闪击：部署当回合 has_moved = false")
	_check(_has_flags(u) and u.has_attacked == false, "闪击：部署当回合 has_attacked = false")


func _test_blitz_can_move() -> void:
	print("[3] 闪击：部署当回合可以移动")
	var b := _new_battle()
	var u := _rookie(b)
	if not _has_flags(u):
		_check(false, "还没有 has_moved/has_attacked 字段")
		return
	_check(b.move_unit(u, "front", 0), "闪击单位部署当回合移动成功")


func _test_blitz_can_attack() -> void:
	print("[4] 闪击：部署当回合可以攻击")
	var b := _new_battle()
	var u := _rookie(b)
	if not _has_flags(u):
		_check(false, "还没有 has_moved/has_attacked 字段")
		return
	var foe := _placed(b, "front", 1, 5, 1, "enemy")
	_check(b.attack_unit(u, foe), "闪击单位部署当回合攻击成功（支援线 → 相邻前线）")


func _test_blitz_not_both() -> void:
	print("[5] 非坦克：移动后不能再攻击（二选一）")
	var b := _new_battle()
	var u := _rookie(b)
	if not _has_flags(u):
		_check(false, "还没有 has_moved/has_attacked 字段")
		_check(false, "跳过")
		return
	var foe := _placed(b, "enemy_support", 1, 5, 1, "enemy")
	_check(b.move_unit(u, "front", 0), "先移动成功")
	_check(not b.attack_unit(u, foe), "移动后不能再攻击（非坦克）")


func _test_blitz_tank_both() -> void:
	print("[6] 闪击 + 坦克：部署当回合移动 + 攻击")
	var b := _new_battle()
	b.energy = 10
	var c := _unit_card("tank_blitz", 2, 2, 4, ["blitz"], "tank")
	b.hand.append(c)
	b.play_card(c, b.player)
	var u: Unit = b.board.unit_at("player_support", 1)
	if not _has_flags(u):
		_check(false, "还没有 has_moved/has_attacked 字段")
		_check(false, "跳过")
		return
	var foe := _placed(b, "enemy_support", 1, 9, 1, "enemy")
	_check(b.move_unit(u, "front", 0), "闪击坦克先移动成功")
	_check(b.attack_unit(u, foe), "闪击坦克移动后仍能攻击（坦克例外）")


func _test_tank_without_blitz() -> void:
	print("[7] 坦克没有闪击：部署当回合仍不能行动")
	var b := _new_battle()
	b.energy = 5
	var c := _unit_card("tank", 2, 3, 4, [], "tank")
	b.hand.append(c)
	b.play_card(c, b.player)
	var u: Unit = b.board.unit_at("player_support", 1)
	_check(_has_flags(u) and u.has_moved == true, "坦克（无闪击）部署当回合 has_moved = true")
	_check(_has_flags(u) and u.has_attacked == true, "坦克（无闪击）部署当回合 has_attacked = true")


func _test_turn_start_clears() -> void:
	print("[8] 回合开始清掉两个标志")
	var b := _new_battle()
	var u := _rookie(b)
	if not _has_flags(u):
		_check(false, "还没有 has_moved/has_attacked 字段")
		return
	u.has_moved = true
	u.has_attacked = true
	b.end_turn()
	_check(u.has_moved == false and u.has_attacked == false, "新回合开始两个标志都清 false")
