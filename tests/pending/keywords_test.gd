extends SceneTree
## M3 关键词验收测试：先覆盖闪击（Blitz）—— 护卫（Guard）等 §M3.2 语义拍板后补
##
## 运行：
##   ... --headless --path . --script res://tests/pending/keywords_test.gd
##
## 规格：docs/m3-scope.md §M3.1（关键词框架 + Blitz）
## 【启用方式】M3.1 全绿后移到 tests/ 下（runner 自动发现）。

var failures: int = 0
var checks: int = 0
var table: ReactionTable

## 全绿时应执行的检查项数（少执行一条也算红）。
const EXPECTED_CHECKS := 15


func _initialize() -> void:
	print("========== 关键词测试（M3.1：Blitz） ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	_test_card_parse_keywords()
	_test_deploy_blitz()
	_test_normal_unit_sickness()
	_test_blitz_can_move()
	_test_blitz_can_attack()
	_test_guard_blocks()

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
	b.start_battle()
	return b


func _unit_card(id: String, cost: int, attack: int, defense: int, keywords: Array = []) -> Card:
	return Card.from_dict({
		"id": id, "name": id, "type": "unit", "cost": cost,
		"attack": attack, "defense": defense, "keywords": keywords,
	})


# ---------------------------------------------------------------- 用例

func _test_card_parse_keywords() -> void:
	print("[0] Card 数据层解析 keywords")
	var c := _unit_card("scout", 1, 1, 1, ["blitz"])
	_check(c.keywords.has("blitz"), "Card.from_dict 解析 keywords（blitz）")


func _test_deploy_blitz() -> void:
	print("[1] 闪击单位部署：keywords 传到 Unit、不陷入召唤失调")
	var b := _new_battle()
	b.energy = 5
	var c := _unit_card("scout", 1, 1, 1, ["blitz"])
	b.hand.append(c)
	_check(b.play_card(c, b.player), "闪击单位部署成功")
	var u: Unit = b.board.unit_at("player_support", 1)
	_check(u != null, "单位落在我方支援线第一个空位")
	var kw = u.get("keywords") if u != null else null
	_check(kw != null and kw.has("blitz"), "部署后 Unit 带上 keywords（blitz）")
	_check(u != null and u.has_acted == false, "闪击：部署当回合不陷入召唤失调（has_acted = false）")


func _test_normal_unit_sickness() -> void:
	print("[2] 对照：普通单位部署当回合仍召唤失调")
	var b := _new_battle()
	b.energy = 5
	var c := _unit_card("footman", 1, 1, 2)
	b.hand.append(c)
	b.play_card(c, b.player)
	var u: Unit = b.board.unit_at("player_support", 1)
	_check(u != null and u.has_acted == true, "普通单位部署当回合 has_acted = true")


func _test_blitz_can_move() -> void:
	print("[3] 闪击单位部署当回合可以移动")
	var b := _new_battle()
	b.energy = 10
	var c := _unit_card("scout", 1, 1, 1, ["blitz"])
	b.hand.append(c)
	b.play_card(c, b.player)
	var u: Unit = b.board.unit_at("player_support", 1)
	_check(u != null and b.move_unit(u, "front", 0), "闪击单位部署当回合成功推进前线")


func _test_blitz_can_attack() -> void:
	print("[4] 闪击单位部署当回合可以攻击")
	var b := _new_battle()
	b.energy = 10
	var c := _unit_card("scout", 1, 1, 1, ["blitz"])
	b.hand.append(c)
	b.play_card(c, b.player)
	var u: Unit = b.board.unit_at("player_support", 1)
	var foe := Unit.from_dict({ "id": "foe", "name": "敌兵", "hp": 5, "attack": 1, "owner": "enemy" })
	b.board.place(foe, "front", 1)
	var ok: bool = u != null and b.attack_unit(u, foe)
	_check(ok, "闪击单位部署当回合成功攻击相邻线敌人")
	_check_eq(foe.hp, 4, "攻击造成 1 点伤害（5 → 4）")


## Guard 段按 ADR-004 的**选项 A（暂定）**写：相邻线有敌方 Guard 时，攻击必须打 Guard，
## 不能越过它打普通单位或 HQ。若拍板改成 B/C，这一节要改。
func _guard_unit(id: String, hp: int) -> Unit:
	return Unit.from_dict({ "id": id, "name": id, "hp": hp, "attack": 1, "owner": "enemy", "keywords": ["guard"] })


func _test_guard_blocks() -> void:
	print("[5] 护卫 Guard：相邻线有 Guard 时不能越过它")
	var b := _new_battle()
	b.energy = 10
	var attacker := Unit.from_dict({ "id": "atk", "name": "攻", "hp": 10, "attack": 2, "owner": "player" })
	b.board.place(attacker, "front", 1)
	var guard := _guard_unit("guard", 5)
	b.board.place(guard, "enemy_support", 1)
	var other := Unit.from_dict({ "id": "other", "name": "敌兵", "hp": 5, "attack": 1, "owner": "enemy" })
	b.board.place(other, "enemy_support", 2)
	var enemy_hq: Unit = b.board.unit_at("enemy_support", 0)

	_check(not b.attack_unit(attacker, other), "Guard 在相邻线时，不能越过它打普通单位")
	attacker.has_acted = false   # 让三条非法目标检查互相独立（实现正确时它们本来就不会标记）
	_check(not b.attack_unit(attacker, enemy_hq), "Guard 在相邻线时，不能越过它打 HQ")
	attacker.has_acted = false
	_check(b.attack_unit(attacker, guard), "可以直接攻击 Guard 本身")
	_check_eq(guard.hp, 3, "Guard 受到 2 点伤害（5 → 3）")

	# Guard 阵亡后，攻击恢复原规则
	var b2 := _new_battle()
	b2.energy = 10
	var guard2 := _guard_unit("guard2", 2)
	b2.board.place(guard2, "enemy_support", 1)
	var other2 := Unit.from_dict({ "id": "other2", "name": "敌兵", "hp": 5, "attack": 1, "owner": "enemy" })
	b2.board.place(other2, "enemy_support", 2)
	var atk2 := Unit.from_dict({ "id": "atk2", "name": "攻", "hp": 10, "attack": 2, "owner": "player" })
	b2.board.place(atk2, "front", 1)
	b2.attack_unit(atk2, guard2)
	var atk3 := Unit.from_dict({ "id": "atk3", "name": "攻", "hp": 10, "attack": 2, "owner": "player" })
	b2.board.place(atk3, "front", 0)
	_check(b2.attack_unit(atk3, other2), "Guard 阵亡后，可以打其他单位")
	_check_eq(other2.hp, 3, "Guard 阵亡后伤害正常结算（5 → 3）")
