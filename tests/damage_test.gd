extends SceneTree
## 伤害结算测试（纯函数）
##
## 运行：
##   ... --headless --path . --script res://tests/damage_test.gd
##
## 规格见 docs/element-reactions.md：倍率只 1.5/2.0、一律向下取整、免疫优先。

var failures: int = 0
var checks: int = 0
var table: ReactionTable


func _initialize() -> void:
	print("========== 伤害结算测试 ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	_test_no_aura()
	_test_vaporize_fire_on_water()
	_test_vaporize_water_on_fire()
	_test_floor()
	_test_immune()
	_test_effects()
	_test_trigger_attacker()
	_test_null_table()

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


func _target(aura: String = Element.NONE, amount: float = 0.0, immunities: Array[String] = []) -> Unit:
	var u := Unit.from_dict({ "id": "dummy", "name": "木桩", "hp": 100 })
	u.aura_element = aura
	u.aura_amount = amount
	u.immunities = immunities
	return u


# ---------------------------------------------------------------- 用例

func _test_no_aura() -> void:
	print("[D1] 目标没有附着")
	var r := Damage.compute(10, Element.FIRE, _target(), table)
	_check_eq(int(r["damage"]), 10, "伤害 = 基础值")
	_check_eq(str(r["reaction"]), "", "没有反应名")
	_check_eq(float(r["multiplier"]), 1.0, "倍率 1.0")
	_check_eq(float(r["consume"]), 0.0, "不消耗附着")


func _test_vaporize_fire_on_water() -> void:
	print("[D2] 蒸发：火打水（×1.5）")
	var r := Damage.compute(10, Element.FIRE, _target(Element.WATER, 1.0), table)
	_check_eq(int(r["damage"]), 15, "10 × 1.5 = 15")
	_check_eq(str(r["reaction"]), "蒸发", "反应名")
	_check_eq(float(r["consume"]), 1.0, "消耗 1U")


func _test_vaporize_water_on_fire() -> void:
	print("[D3] 蒸发：水打火（×2.0）")
	var r := Damage.compute(10, Element.WATER, _target(Element.FIRE, 1.0), table)
	_check_eq(int(r["damage"]), 20, "10 × 2.0 = 20")
	_check_eq(str(r["reaction"]), "蒸发", "对称键查到同一条反应")


func _test_floor() -> void:
	print("[D4] 向下取整")
	var r := Damage.compute(5, Element.FIRE, _target(Element.WATER, 1.0), table)
	_check_eq(int(r["damage"]), 7, "5 × 1.5 = 7.5 → 向下取整 7")


func _test_immune() -> void:
	print("[D5] 元素免疫")
	var fire_slime := _target(Element.WATER, 1.0, [Element.FIRE])
	var r := Damage.compute(10, Element.FIRE, fire_slime, table)
	_check_eq(int(r["damage"]), 0, "免疫时伤害为 0")
	_check(bool(r["immune"]), "immune 标记为真")
	_check_eq(str(r["reaction"]), "", "免疫不触发反应")
	_check_eq(float(r["consume"]), 0.0, "免疫不消耗附着")


func _test_effects() -> void:
	print("[D6] 剧变反应的额外效果")
	var r := Damage.compute(5, Element.FIRE, _target(Element.LIGHTNING, 1.0), table)
	_check_eq(str(r["reaction"]), "超载", "反应名")
	_check_eq(float(r["multiplier"]), 1.0, "剧变反应不乘倍率")
	var effects: Array = r["effects"]
	_check(effects.size() > 0, "有 effects 列表")
	if effects.size() > 0:
		_check_eq(str(effects[0].get("kind", "")), "damage", "超载的第一个效果是额外伤害")


func _test_trigger_attacker() -> void:
	print("[D7] 触发方向限制（风/岩只能主动触发）")
	var wind_hits := Damage.compute(5, Element.WIND, _target(Element.FIRE, 1.0), table)
	_check_eq(str(wind_hits["reaction"]), "扩散", "风打火附着力 → 扩散")

	var fire_hits := Damage.compute(5, Element.FIRE, _target(Element.WIND, 1.0), table)
	_check_eq(str(fire_hits["reaction"]), "", "火打风附着力 → 不触发扩散")


func _test_null_table() -> void:
	print("[D8] 反应表为 null（防御性）")
	var r := Damage.compute(10, Element.FIRE, _target(Element.WATER, 1.0), null)
	_check_eq(int(r["damage"]), 10, "没有反应表也不该崩")
	_check_eq(str(r["reaction"]), "", "无反应")
