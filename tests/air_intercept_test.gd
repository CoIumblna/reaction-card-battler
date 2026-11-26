extends SceneTree
## M3.3b 战斗机拦截轰炸机验收测试（已启用 2026-11-26）
##
## 运行：
##   ... --headless --path . --script res://tests/air_intercept_test.gd
##
## 规格：docs/adr/004-m3-keywords.md 决定 3（KARDS 兵科）
##   - 轰炸机攻击**有战斗机的线**时，只能打战斗机（不能打同线的非战斗机）
##   - 目标线没有战斗机时，轰炸机可以正常打非战斗机

var failures: int = 0
var checks: int = 0
var table: ReactionTable

const EXPECTED_CHECKS := 3


func _initialize() -> void:
	print("========== 战斗机拦截轰炸机（M3.3b） ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")
	_test_interception()
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


func _new_battle() -> Battle:
	var b := Battle.new()
	var player := Unit.from_dict({ "id": "player", "name": "旅行者", "hp": 60 })
	var enemy := Unit.from_dict({ "id": "enemy", "name": "训练假人", "hp": 9999 })
	var enemies: Array[Unit] = [enemy]
	b.setup(player, enemies, DataLoader.load_cards(), table, 20261130)
	b.start_battle()
	b.energy = 10
	return b


func _unit(id: String, hp: int, attack: int, owner: String, unit_class: String) -> Unit:
	return Unit.from_dict({ "id": id, "name": id, "hp": hp, "attack": attack, "owner": owner, "unit_class": unit_class })


func _test_interception() -> void:
	print("[1] 轰炸机攻击有战斗机的线：只能打战斗机")
	var b := _new_battle()
	var bomber := _unit("bomber", 5, 3, "player", "bomber")
	b.board.place(bomber, "front", 1)
	var fighter := _unit("fighter", 5, 1, "enemy", "fighter")
	b.board.place(fighter, "enemy_support", 1)
	var other := _unit("other", 5, 1, "enemy", "infantry")
	b.board.place(other, "enemy_support", 2)
	_check(not b.attack_unit(bomber, other), "目标线有战斗机时，轰炸机不能打非战斗机")
	_check(b.attack_unit(bomber, fighter), "轰炸机可以打该线的战斗机")

	var b2 := _new_battle()
	var bomber2 := _unit("bomber2", 5, 3, "player", "bomber")
	b2.board.place(bomber2, "front", 1)
	var other2 := _unit("other2", 5, 1, "enemy", "infantry")
	b2.board.place(other2, "enemy_support", 2)
	_check(b2.attack_unit(bomber2, other2), "目标线没有战斗机时，轰炸机可以打非战斗机")
