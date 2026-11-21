extends SceneTree
## M3.2 护卫（Guard）验收测试 —— 按 ADR-004 的**选项 A（暂定）**写：
##   "相邻线有敌方 Guard 时，攻击必须打 Guard，不能越过它打普通单位或 HQ。"
## 若拍板改成 B/C，这一份测试要改。
##
## 运行：
##   ... --headless --path . --script res://tests/pending/guard_test.gd
##
## 规格：docs/m3-scope.md §M3.2 + docs/adr/004-m3-keywords.md 决定 2
## 【启用方式】M3.2 全绿后移到 tests/ 下（runner 自动发现）。

var failures: int = 0
var checks: int = 0
var table: ReactionTable

const EXPECTED_CHECKS := 6


func _initialize() -> void:
	print("========== 护卫 Guard 测试（M3.2，选项 A 暂定） ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")
	_test_guard_blocks()

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
	b.setup(player, enemies, DataLoader.load_cards(), table, 20261124)
	b.start_battle()
	return b


func _guard_unit(id: String, hp: int) -> Unit:
	return Unit.from_dict({ "id": id, "name": id, "hp": hp, "attack": 1, "owner": "enemy", "keywords": ["guard"] })


func _test_guard_blocks() -> void:
	print("[1] Guard：相邻线有 Guard 时不能越过它")
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
