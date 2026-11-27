extends SceneTree
## M3.6b 固有护盾验收测试（自己挂元素 + 免疫该元素伤害 + 仍可被反应）
##
## 运行：
##   ... --headless --path . --script res://tests/innate_shield_test.gd
##
## 规格：docs/implementation-tasks.md §42（作业单）+ §42.9（用例清单）
##       docs/element-reactions.md §4（两种免疫语义）
##
## 覆盖：① 两种免疫语义（静态 vs 护盾）；② 护盾把伤害归零但反应照算；
##       ③ 盾被反应 consume 啃薄、啃到 0 就破、破了以后吃正常伤害；
##       ④ 共存型反应（感电/冻结 consume 0）不掉盾；⑤ 护盾槽不随时间衰减；
##       ⑥ 破盾后 3 回合重生；⑦ 槽位挤占规则（护盾不让位）；
##       ⑧ 老契约不破 —— 纯静态免疫仍「伤害 0 + 不反应 + 不挂槽」。
##
## 【已启用】2026-11-27：实现落地并全绿，已从 tests/pending/ 移入主套，
## 随 run_tests.bat 一起跑。

var failures: int = 0
var checks: int = 0
var table: ReactionTable

const EXPECTED_CHECKS := 36


func _initialize() -> void:
	print("========== 固有护盾（M3.6b）测试 ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	_test_two_immunity_kinds()
	_test_shield_zero_damage_but_reaction()
	_test_shield_eaten_away()
	_test_coexist_keeps_shield()
	_test_innate_never_decays()
	_test_regen_three_turns()
	_test_slot_eviction()
	_test_static_immunity_unchanged()

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


## 造一个带固有护盾的单位。d = { "fire": 2.0 } 这种简写即可。
func _shielded(d: Dictionary) -> Unit:
	var slots: Array = []
	for el in d:
		slots.append({
			"element": str(el),
			"amount": float(d[el]),
			"duration": 0,
			"innate": true,
		})
	return Unit.from_dict({ "id": "warden", "name": "持盾者", "hp": 100, "auras": slots })


func _plain() -> Unit:
	return Unit.from_dict({ "id": "dummy", "name": "木桩", "hp": 100 })


func _has_buff(u: Unit, kind: String) -> bool:
	for b in u.buffs:
		if b.kind == kind:
			return true
	return false


# ---------------------------------------------------------------- 用例

## [1] 两种免疫语义的三种谓词关系
func _test_two_immunity_kinds() -> void:
	print("[1] 两种免疫语义：静态 vs 护盾")
	var u := _shielded({ Element.FIRE: 2.0 })
	_check(u.is_immune(Element.FIRE), "护盾元素算免疫（is_immune 为真）")
	_check(not u.is_static_immune(Element.FIRE), "但不算静态免疫（否则反应不了）")
	_check(u.has_innate_shield(Element.FIRE), "has_innate_shield 认得这面盾")
	_check(not u.is_immune(Element.WATER), "别的元素不免疫")
	_check_eq(u.active_innate_elements().size(), 1, "active_innate_elements 只有一个元素")

	# 对照：纯静态免疫三者关系反过来
	var s := _plain()
	s.immunities.append(Element.FIRE)
	_check(s.is_static_immune(Element.FIRE) and not s.has_innate_shield(Element.FIRE),
		"静态免疫：is_static_immune 真、has_innate_shield 假")


## [2] 护盾把伤害归零，但反应照样算
func _test_shield_zero_damage_but_reaction() -> void:
	print("[2] 伤害归零但反应照算")
	var u := _shielded({ Element.FIRE: 2.0 })
	var same := Damage.compute(10, Element.FIRE, u, table)
	_check_eq(int(same["damage"]), 0, "火打火盾：伤害归零")
	_check(str(same["immune_source"]) == "shield" and bool(same["immune"]),
		"immune_source 是 shield、immune 为真")
	_check_eq(str(same["reaction"]), "", "同元素不算反应（没有反应名）")

	var other := Damage.compute(10, Element.WATER, u, table)
	_check_eq(int(other["damage"]), 20, "水打火盾：蒸发 2.0 倍，伤害照算")
	_check_eq(str(other["reaction"]), "蒸发", "反应名仍是蒸发")

	# 注意：_apply_aura 结算 water 时 consume 1 会吃盾，但 Damage.compute 只算数不动状态
	_check_eq(float(u.get_aura(Element.FIRE).get("amount", 0.0)), 2.0,
		"compute 只读数、不改盾量（改状态是 _apply_aura 的活）")


## [3] 盾被反应 consume 啃薄 → 啃光 → 破了以后吃正常伤害
func _test_shield_eaten_away() -> void:
	print("[3] 盾被反应啃薄 / 破盾")
	var b := _battle()
	var foe: Unit = b.enemies[0]
	foe.auras.clear()
	foe.auras.append({ "element": Element.FIRE, "amount": 2.0, "duration": 0, "innate": true })

	b._apply_aura(foe, Element.WATER, 1.0)
	_check_eq(float(foe.get_aura(Element.FIRE).get("amount", 0.0)), 1.0, "蒸发 consume 1：2U 火盾 → 1U")

	b._apply_aura(foe, Element.WATER, 1.0)
	_check(foe.get_aura(Element.FIRE).is_empty(), "再一发水把盾啃光 → 槽移除")
	_check(not foe.has_innate_shield(Element.FIRE), "盾没了，has_innate_shield 变假")

	var after := Damage.compute(10, Element.FIRE, foe, table)
	_check_eq(int(after["damage"]), 10, "盾破后火打它吃正常伤害")
	_check_eq(str(after["immune_source"]), "", "此时 immune_source 为空（不再免疫）")


## [4] 共存型反应（consume 0）不掉盾
func _test_coexist_keeps_shield() -> void:
	print("[4] 共存型反应不掉盾")
	var b := _battle()
	var foe: Unit = b.enemies[0]
	foe.auras.clear()
	foe.auras.append({ "element": Element.WATER, "amount": 2.0, "duration": 0, "innate": true })

	b._apply_aura(foe, Element.LIGHTNING, 1.0)
	_check_eq(float(foe.get_aura(Element.WATER).get("amount", 0.0)), 2.0,
		"感电 consume = 0：水盾一滴不掉")
	_check(_has_buff(foe, "shock"), "感电照样挂上 shock")

	var b2 := _battle()
	var foe2: Unit = b2.enemies[0]
	foe2.auras.clear()
	foe2.auras.append({ "element": Element.WATER, "amount": 2.0, "duration": 0, "innate": true })
	b2._apply_aura(foe2, Element.ICE, 1.0)
	_check_eq(float(foe2.get_aura(Element.WATER).get("amount", 0.0)), 2.0,
		"冻结 consume = 0：水盾一滴不掉")
	_check(_has_buff(foe2, "immobilized"), "冻结照样挂上 immobilized")


## [5] 护盾槽不随时间衰减
func _test_innate_never_decays() -> void:
	print("[5] 护盾槽不随时间衰减")
	var u := _shielded({ Element.FIRE: 2.0 })
	var expired_total: Array = []
	for i in range(5):
		for el in u.tick_auras():
			expired_total.append(el)
	_check(u.has_innate_shield(Element.FIRE), "连跑 5 个回合，盾还在")
	_check_eq(float(u.get_aura(Element.FIRE).get("amount", 0.0)), 2.0, "盾量一点没掉")
	_check_eq(int(u.get_aura(Element.FIRE).get("duration", -1)), 0, "duration 仍是 0")
	_check_eq(expired_total.size(), 0, "tick_auras 没把盾当过期附着报出来")


## [6] 破盾后 3 回合重生
func _test_regen_three_turns() -> void:
	print("[6] 破盾后 3 回合重生")
	var u := _shielded({ Element.FIRE: 2.0 })
	# 手动破盾（模拟被反应啃光）
	u.auras.clear()
	_check(not u.tick_innate_shield(), "破盾第 1 回合：不回来")
	_check(not u.tick_innate_shield(), "破盾第 2 回合：还不回来")
	_check(u.tick_innate_shield(), "破盾第 3 回合：盾重新凝聚")
	_check_eq(float(u.get_aura(Element.FIRE).get("amount", 0.0)), 2.0, "重生后盾量回到模板值")

	# 满盾时不倒计时
	var full := _shielded({ Element.FIRE: 2.0 })
	full.innate_timer = 1
	_check(not full.tick_innate_shield() and full.innate_timer == Unit.INNATE_REGEN_TURNS,
		"满盾时既不变动也不倒数（timer 复位）")


## [7] 槽位挤占：护盾不让位
func _test_slot_eviction() -> void:
	print("[7] 槽位挤占规则")
	var u := _shielded({ Element.FIRE: 2.0, Element.WATER: 2.0 })
	u.add_or_refresh_aura(Element.LIGHTNING, 1.0, 2)
	_check_eq(u.auras.size(), 3, "两盾 + 一普通附着 = 3 槽")
	u.add_or_refresh_aura(Element.ICE, 1.0, 2)
	_check(u.has_innate_shield(Element.FIRE) and u.has_innate_shield(Element.WATER),
		"挤占时只动普通槽：两面盾都还在")
	_check(u.get_aura(Element.LIGHTNING).is_empty() and not u.get_aura(Element.ICE).is_empty(),
		"被挤掉的是最旧的普通槽（雷），冰进来了")

	var all := _shielded({ Element.FIRE: 2.0, Element.WATER: 2.0, Element.ICE: 2.0 })
	all.add_or_refresh_aura(Element.LIGHTNING, 1.0, 2)
	_check(all.auras.size() == 3 and all.get_aura(Element.LIGHTNING).is_empty(),
		"3 槽全是盾时普通元素挂不上（护盾优先）")


## [8] 老契约不破：纯静态免疫
func _test_static_immunity_unchanged() -> void:
	print("[8] 老契约：纯静态免疫不变")
	var u := _plain()
	u.immunities.append(Element.FIRE)
	var r := Damage.compute(10, Element.FIRE, u, table)
	_check(int(r["damage"]) == 0 and int(r["reaction_slot"]) == -1,
		"静态免疫：伤害 0、没有反应槽")
	var b := _battle()
	var foe: Unit = b.enemies[0]
	foe.immunities.append(Element.FIRE)
	b._apply_aura(foe, Element.FIRE, 2.0)
	_check(foe.auras.is_empty(), "静态免疫：_apply_aura 连槽都不挂")


func _battle() -> Battle:
	var b := Battle.new()
	var player := Unit.from_dict({ "id": "player", "name": "旅行者", "hp": 60 })
	var enemy := Unit.from_dict({ "id": "enemy", "name": "木桩", "hp": 100 })
	var enemies: Array[Unit] = [enemy]
	b.setup(player, enemies, [], table, 20261127)
	b.first_move = "player"
	b.start_battle()
	return b
