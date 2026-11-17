extends SceneTree
## 棋盘测试（M2）：Unit 扩展字段 / Board 初始化 / 容量与占格
##
## 运行：
##   ... --headless --path . --script res://tests/board_test.gd
##
## 这个文件只测"棋盘数据结构"，不测出牌/移动/攻击（那些在 battle_test / combat_test）。

var failures: int = 0
var checks: int = 0

## 全绿时应执行的检查项数。对不上 = 有测试段被静默跳过（或 SCRIPT ERROR 打断），
## 只看"共 N 项检查、失败 0 项"会假绿，所以这里硬校验。
const EXPECTED_CHECKS := 38


func _initialize() -> void:
	print("========== 棋盘测试 ==========")
	_test_unit_ext()
	_test_board_setup()
	_test_capacity_and_place()

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


func _new_board() -> Board:
	var b := Board.new()
	b.setup()
	return b


func _unit(n: int, attack: int = 2, hp: int = 3) -> Unit:
	return Unit.from_dict({ "id": "u%d" % n, "name": "单位%d" % n, "attack": attack, "hp": hp })


# ---------------------------------------------------------------- 用例

func _test_unit_ext() -> void:
	print("[1] Unit 扩展字段（M2 / E1）")
	var u := Unit.from_dict({ "id": "u", "name": "甲", "hp": 3, "attack": 5 })
	# M2 的新字段还没加，所以用 Object.get() 读 —— 缺字段时返回 null 而不是让整个测试脚本崩，
	# 这样你能一次看到所有红，而不是改一个字段跑一次。
	_check_eq(u.get("attack"), 5, "from_dict 读到攻击力")
	_check_eq(u.hp, 3, "hp = 当前防御")
	_check_eq(u.max_hp, 3, "max_hp = 最大防御")
	_check_eq(u.get("has_acted"), false, "新单位本回合未行动")
	_check_eq(u.get("is_hq"), false, "普通单位不是 HQ")

	var hq := Unit.from_dict({ "id": "hq", "name": "HQ", "hp": 20, "is_hq": true })
	_check_eq(hq.get("is_hq"), true, "from_dict 读到 is_hq")
	_check_eq(hq.get("attack"), 0, "HQ 没有攻击力")


func _test_board_setup() -> void:
	print("[2] Board 初始化（M2 / E2、E3）")
	var b := _new_board()
	_check_eq(Board.LINES.size(), 3, "三条战线")
	_check_eq(Board.SLOT_COUNT, 5, "每线 5 格")
	_check_eq(Board.HQ_DEFENSE, 20, "HQ 20 防")

	var hq := b.unit_at("player_support", 0)
	_check(hq != null, "我方支援线 0 号格有 HQ")
	if hq != null:
		_check_eq(hq.is_hq, true, "0 号格是 HQ")
		_check_eq(hq.max_hp, 20, "HQ 最大防御 20")
		_check_eq(hq.hp, 20, "HQ 初始满防")

	var ehq := b.unit_at("enemy_support", 0)
	_check(ehq != null, "敌方支援线 0 号格有 HQ")
	if ehq != null:
		_check_eq(ehq.is_hq, true, "敌方 0 号格也是 HQ")

	# HQ 归属（M2 / E11 前置）：前线共享，必须靠 owner 分敌我
	if hq != null:
		_check_eq(hq.get("owner"), "player", "我方 HQ 归属 player")
	if ehq != null:
		_check_eq(ehq.get("owner"), "enemy", "敌方 HQ 归属 enemy")

	# 双方 HQ 必须是两个独立对象：共用一个对象时，打敌方 HQ 我方也掉防
	_check(hq != b.unit_at("enemy_support", 0), "双方 HQ 是两个独立对象")
	if hq != null and ehq != null:
		ehq.take_damage(5)
		_check_eq(hq.hp, 20, "打敌方 HQ 不影响我方 HQ")

	_check_eq(b.unit_at("front", 0), null, "前线初始为空")
	_check_eq(b.unit_at("no_such_line", 0), null, "非法战线返回 null（不许崩）")
	_check_eq(b.unit_at("front", 99), null, "越界下标返回 null（不许崩）")


func _test_capacity_and_place() -> void:
	print("[3] 容量与占格（M2 / E2）")
	var fresh := _new_board()
	_check_eq(fresh.units_in("front").size(), 0, "空线单位数为 0（不含 null）")
	var b := _new_board()
	_check_eq(b.capacity_of("front"), 5, "前线容量 5")
	_check_eq(b.capacity_of("player_support"), 4, "支援线容量 4（5 格 − HQ）")
	_check_eq(b.first_empty_unit_slot("front"), 0, "前线第一个空位是 0 号")
	_check_eq(b.first_empty_unit_slot("player_support"), 1, "支援线第一个空位是 1 号（0 号是 HQ）")
	_check_eq(b.place(_unit(1), "player_support", 0), false, "HQ 位不能放单位")

	var placed := 0
	for i in range(5):
		if b.place(_unit(i), "front", i):
			placed += 1
	_check_eq(placed, 5, "前线能放满 5 个单位")
	_check_eq(b.place(_unit(9), "front", 0), false, "已占的格不能再放")
	_check_eq(b.first_empty_unit_slot("front"), -1, "前线满 → 返回 -1")
	_check_eq(b.units_in("front").size(), 5, "前线单位数 5")

	var placed2 := 0
	for i in range(1, 5):
		if b.place(_unit(20 + i), "player_support", i):
			placed2 += 1
	_check_eq(placed2, 4, "支援线能放满 4 个单位")
	_check_eq(b.first_empty_unit_slot("player_support"), -1, "支援线满 → 返回 -1")
	_check_eq(b.units_in("player_support").size(), 5, "支援线含 HQ 共 5 个")

	_check_eq(b.place(_unit(30), "front", 99), false, "越界下标不能放")
	_check_eq(b.place(_unit(31), "no_such_line", 0), false, "非法战线不能放")
