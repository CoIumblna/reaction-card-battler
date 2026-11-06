extends SceneTree
## 单位数值测试：HP / 护盾 / 治疗 / buff 生命周期
##
## 运行：
##   ... --headless --path . --script res://tests/unit_test.gd
##
## 为什么单独一个文件：这些规则 M2 加棋盘后一模一样要复用，
## 而且"护盾怎么吸收""治疗会不会超上限"是最容易写错的细节。

var failures: int = 0
var checks: int = 0


func _initialize() -> void:
	print("========== 单位数值测试 ==========")
	_test_create()
	_test_shield()
	_test_lethal()
	_test_heal()
	_test_buffs()

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


# ---------------------------------------------------------------- 用例

func _test_create() -> void:
	print("[1] 创建")
	var u := Unit.from_dict({ "id": "u1", "name": "测试兵", "hp": 20 })
	_check_eq(u.hp, 20, "初始 HP")
	_check_eq(u.max_hp, 20, "最大 HP")
	_check_eq(u.shield, 0, "初始护盾为 0")
	_check_eq(u.aura_element, Element.NONE, "初始无附着")
	_check_eq(u.aura_amount, 0.0, "初始附着量为 0")
	_check(u.is_alive(), "初始存活")


func _test_shield() -> void:
	print("[2] 护盾吸收")
	var u := Unit.from_dict({ "id": "u2", "name": "测试兵", "hp": 20 })
	u.shield = 5
	var real := u.take_damage(8)
	_check_eq(real, 3, "5 盾吸收后实际掉血 3")
	_check_eq(u.hp, 17, "HP 变为 17")
	_check_eq(u.shield, 0, "护盾被打空")

	u.shield = 10
	var real2 := u.take_damage(4)
	_check_eq(real2, 0, "护盾够时实际掉血 0")
	_check_eq(u.hp, 17, "HP 不变")
	_check_eq(u.shield, 6, "护盾剩 6")


func _test_lethal() -> void:
	print("[3] 致死与存活判断")
	var u := Unit.from_dict({ "id": "u3", "name": "测试兵", "hp": 5 })
	u.take_damage(99)
	_check_eq(u.hp, 0, "HP 不会变负数")
	_check(not u.is_alive(), "HP 为 0 时已死亡")


func _test_heal() -> void:
	print("[4] 治疗")
	var u := Unit.from_dict({ "id": "u4", "name": "测试兵", "hp": 20 })
	u.take_damage(10)
	u.heal(4)
	_check_eq(u.hp, 14, "回复 4 点")
	u.heal(100)
	_check_eq(u.hp, 20, "不超过最大 HP")


func _test_buffs() -> void:
	print("[5] buff 生命周期")
	var u := Unit.from_dict({ "id": "u5", "name": "测试兵", "hp": 20 })
	u.add_buff(Buff.make("burn", 2))
	u.add_buff(Buff.make("shock", 1))
	_check_eq(u.buffs.size(), 2, "挂上 2 个 buff")

	u.tick_buffs()
	_check_eq(u.buffs.size(), 1, "1 回合后 shock（duration 1）已到期移除")
	if not u.buffs.is_empty():
		_check_eq(u.buffs[0].kind, "burn", "剩下的是 burn")
		_check_eq(u.buffs[0].duration, 1, "burn 剩余 1 回合")

	u.tick_buffs()
	_check_eq(u.buffs.size(), 0, "再 1 回合后全部清空")
