extends SceneTree
## M3.2 护卫 Guard 验收测试 —— 已启用（2026-11-25）
##
## 运行：
##   ... --headless --path . --script res://tests/guard_test.gd
##
## 规格：docs/adr/004-m3-keywords.md 决定 2
##   - Guard 保护**同线左右相邻格**的友军（slot ±1）；跨线不保护
##   - 被保护的友军不能被敌方**单位攻击**选中（attack_unit 返回 false）
##   - Guard 不保护带 guard 词条的单位
##   - HQ 可被保护（HQ 在支援线 0 格）
##   - 指令卡默认无视 Guard
##
## 【启用方式】M3.2 全绿后移到 tests/ 下。

var failures: int = 0
var checks: int = 0
var table: ReactionTable

const EXPECTED_CHECKS := 8


func _initialize() -> void:
	print("========== 护卫 Guard 测试（M3.2） ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	_test_adjacent_protected()
	_test_guard_itself_targetable()
	_test_hq_protected()
	_test_guard_not_protect_guard()
	_test_not_adjacent_not_protected()
	_test_cross_line_not_protected()
	_test_order_ignores_guard()

	if checks != EXPECTED_CHECKS:
		printerr("  [FAIL] 覆盖不完整：本文件应执行 %d 项检查，实际 %d 项" % [EXPECTED_CHECKS, checks])
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
	b.setup(player, enemies, DataLoader.load_cards(), table, 20261127)
	b.start_battle()
	b.energy = 10
	return b


func _attacker(b: Battle, line: String = "front", idx: int = 1) -> Unit:
	var u := Unit.from_dict({ "id": "atk", "name": "攻", "hp": 10, "attack": 2, "owner": "player" })
	b.board.place(u, line, idx)
	return u


func _guard_unit(b: Battle, line: String, idx: int, hp: int = 5) -> Unit:
	var u := Unit.from_dict({ "id": "guard_%s_%d" % [line, idx], "name": "护卫", "hp": hp, "attack": 1, "owner": "enemy", "keywords": ["guard"] })
	b.board.place(u, line, idx)
	return u


func _other_unit(b: Battle, line: String, idx: int, hp: int = 5) -> Unit:
	var u := Unit.from_dict({ "id": "other_%s_%d" % [line, idx], "name": "敌兵", "hp": hp, "attack": 1, "owner": "enemy" })
	b.board.place(u, line, idx)
	return u


func _flags_ok(u: Unit) -> bool:
	return u != null and u.get("has_moved") != null


# ---------------------------------------------------------------- 用例

func _test_adjacent_protected() -> void:
	print("[1] 同线相邻：被 Guard 保护的单位不能被打")
	var b := _new_battle()
	var atk := _attacker(b, "front", 1)
	_guard_unit(b, "enemy_support", 1)
	var victim := _other_unit(b, "enemy_support", 2)
	_check(not b.attack_unit(atk, victim), "Guard 在 slot1 时，同线相邻 slot2 的单位不能被攻击")


func _test_guard_itself_targetable() -> void:
	print("[2] Guard 自己可以被攻击")
	var b := _new_battle()
	var atk := _attacker(b, "front", 1)
	var guard := _guard_unit(b, "enemy_support", 1)
	_check(b.attack_unit(atk, guard), "可以直接攻击 Guard 本身")


func _test_hq_protected() -> void:
	print("[3] HQ 可被 Guard 保护")
	var b := _new_battle()
	var atk := _attacker(b, "front", 1)
	_guard_unit(b, "enemy_support", 1)
	var hq: Unit = b.board.unit_at("enemy_support", 0)
	_check(not b.attack_unit(atk, hq), "支援线 1 格有 Guard 时，单位不能攻击相邻的敌方 HQ")


func _test_guard_not_protect_guard() -> void:
	print("[4] Guard 不保护带 guard 词条的单位")
	var b := _new_battle()
	var atk := _attacker(b, "front", 1)
	_guard_unit(b, "enemy_support", 1)
	var guard2 := _guard_unit(b, "enemy_support", 2)
	_check(b.attack_unit(atk, guard2), "相邻的另一个 Guard 不受保护，可以直接打")


func _test_not_adjacent_not_protected() -> void:
	print("[5] 不同线/不相邻：不受保护")
	var b := _new_battle()
	var atk := _attacker(b, "front", 1)
	_guard_unit(b, "enemy_support", 1)
	var far := _other_unit(b, "enemy_support", 3)
	_check(b.attack_unit(atk, far), "距离 Guard 2 格（slot3）的单位不受保护")


func _test_cross_line_not_protected() -> void:
	print("[6] 跨线不保护（保护只限同线相邻格）")
	var b := _new_battle()
	var atk := _attacker(b, "player_support", 1)
	_guard_unit(b, "enemy_support", 1)
	var victim := _other_unit(b, "front", 1)
	_check(b.attack_unit(atk, victim), "Guard 在敌方支援线，不保护前线的单位")


func _test_order_ignores_guard() -> void:
	print("[7] 指令卡默认无视 Guard")
	var b := _new_battle()
	var atk := _attacker(b, "front", 1)
	_guard_unit(b, "enemy_support", 1)
	var victim := _other_unit(b, "enemy_support", 2, 10)
	b.energy = 10
	var c := Card.from_dict({ "id": "fire_bolt", "name": "火球", "type": "order", "cost": 1, "element": Element.FIRE, "kind": "damage", "power": 5, "target": "enemy" })
	b.hand.append(c)
	_check(b.play_card(c, victim), "被 Guard 保护的敌人仍可被指令卡选中")
	_check_eq(victim.hp, 5, "指令卡伤害正常结算（10 → 5）")
