extends SceneTree
## M3.6 元素附着 v3（多槽）验收测试
##
## 运行：
##   ... --headless --path . --script res://tests/aura_v3_test.gd
##
## 规格：docs/element-reactions-v3.md §7（20 条用例）+ docs/adr/005-element-auras-v3.md
## 覆盖：多槽数据结构 / 叠加封顶 / 槽上限替换最旧 / duration tick /
##       共存型反应（感电、冻结不再是复合元素 id）/ 反应优先级 / 风岩不附着 /
##       免疫 / dot 不挂元素 / 描述可读性
##
## 【已启用】2026-11-27：实现落地并全绿，已从 tests/pending/ 移入主套，
## 随 run_tests.bat 一起跑。

var failures: int = 0
var checks: int = 0
var table: ReactionTable

const EXPECTED_CHECKS := 59


func _initialize() -> void:
	print("========== 元素附着 v3（多槽）测试 ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	_test_slot_basics()
	_test_stack_and_cap()
	_test_slot_overflow()
	_test_duration()
	_test_reaction_consume()
	_test_coexist_reactions()
	_test_priority()
	_test_wind_geo()
	_test_immunity_and_dot()
	_test_describe()

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


func _unit() -> Unit:
	return Unit.from_dict({ "id": "dummy", "name": "木桩", "hp": 100 })


func _battle() -> Battle:
	var b := Battle.new()
	var player := Unit.from_dict({ "id": "player", "name": "旅行者", "hp": 60 })
	var enemy := Unit.from_dict({ "id": "enemy", "name": "木桩", "hp": 100 })
	var enemies: Array[Unit] = [enemy]
	b.setup(player, enemies, [], table, 20261127)
	b.first_move = "player"
	b.start_battle()
	return b


# ---------------------------------------------------------------- 用例

func _test_slot_basics() -> void:
	print("[1] 多槽基础：初始空 / 上 1U 得 1 槽")
	var u := _unit()
	_check(u.auras.is_empty(), "初始没有任何附着槽")
	u.add_or_refresh_aura(Element.FIRE, 1.0, 2)
	_check_eq(u.auras.size(), 1, "上 1U 火 → 1 槽")
	_check_eq(float(u.get_aura(Element.FIRE).get("amount", 0.0)), 1.0, "这一槽是 1U 火")
	_check(u.get_aura(Element.WATER).is_empty(), "没上的元素查出来是空字典")

	u.add_or_refresh_aura(Element.WATER, 1.0, 2)
	_check_eq(u.auras.size(), 2, "上水 → 2 槽共存")
	_check_eq(float(u.get_aura(Element.WATER).get("amount", 0.0)), 1.0, "水槽独立存在 1U")


func _test_stack_and_cap() -> void:
	print("[2] 同元素叠加与 2U 封顶")
	var u := _unit()
	u.add_or_refresh_aura(Element.FIRE, 1.0, 2)
	u.add_or_refresh_aura(Element.FIRE, 1.0, 2)
	_check_eq(u.auras.size(), 1, "同元素叠加不新增槽")
	_check_eq(float(u.get_aura(Element.FIRE).get("amount", 0.0)), 2.0, "叠加到 2U")
	u.add_or_refresh_aura(Element.FIRE, 2.0, 2)
	_check_eq(float(u.get_aura(Element.FIRE).get("amount", 0.0)), Unit.MAX_AMOUNT, "超过 2U 的部分被截掉（封顶 MAX_AMOUNT）")


func _test_slot_overflow() -> void:
	print("[3] 槽上限 3：第 4 个元素替换最旧槽")
	var u := _unit()
	u.add_or_refresh_aura(Element.FIRE, 1.0, 2)
	u.add_or_refresh_aura(Element.WATER, 1.0, 2)
	u.add_or_refresh_aura(Element.ICE, 1.0, 2)
	_check_eq(u.auras.size(), 3, "三个元素 → 三槽（刚好到上限）")
	u.add_or_refresh_aura(Element.LIGHTNING, 1.0, 2)
	_check_eq(u.auras.size(), Unit.MAX_AURAS, "上第 4 个元素后仍是 3 槽（不超额）")
	_check(u.get_aura(Element.FIRE).is_empty(), "最旧的「火」槽被挤掉")
	_check(not u.get_aura(Element.LIGHTNING).is_empty(), "新上的「雷」在槽里")


func _test_duration() -> void:
	print("[4] duration：普通 2 / 强附着 3 / 刷新取最大 / 归零移除")
	var u := _unit()
	u.add_or_refresh_aura(Element.FIRE, 1.0, Element.aura_duration(Element.FIRE, 1.0))
	_check_eq(int(u.get_aura(Element.FIRE).get("duration", 0)), 2, "普通附着（1U）持续 2 回合")
	u.add_or_refresh_aura(Element.WATER, 2.0, Element.aura_duration(Element.WATER, 2.0))
	_check_eq(int(u.get_aura(Element.WATER).get("duration", 0)), 3, "强附着（2U）持续 3 回合")

	u.add_or_refresh_aura(Element.FIRE, 1.0, 1)
	_check_eq(int(u.get_aura(Element.FIRE).get("duration", 0)), 2, "再上一次：duration 取两者最大（不缩短）")

	var expired := u.tick_auras()
	_check(not expired.has(Element.FIRE), "火槽 2 → 1 回合，还没到期（不在过期列表里）")
	_check_eq(int(u.get_aura(Element.FIRE).get("duration", 0)), 1, "火槽 tick 后剩 1 回合")
	var expired2 := u.tick_auras()
	_check(expired2.has(Element.FIRE), "再过一回合：火槽到期，出现在过期列表里")
	_check(u.get_aura(Element.FIRE).is_empty(), "到期的槽被移除")


func _test_reaction_consume() -> void:
	print("[5] 反应消耗：蒸发倍率 / 槽剩余 / 残留入槽")
	# 火打水：1.5 倍（纯 Damage.compute，不改状态）
	var tgt := _unit()
	tgt.add_or_refresh_aura(Element.WATER, 1.0, 2)
	var r := Damage.compute(10, Element.FIRE, tgt, table)
	_check_eq(int(r["damage"]), 15, "火打水 = 10 × 1.5 向下取整")
	_check_eq(str(r["reaction"]), "蒸发", "反应名是蒸发")
	_check_eq(int(r["reaction_slot"]), 0, "反应命中第 0 槽")

	# 水打火：2.0 倍
	var tgt2 := _unit()
	tgt2.add_or_refresh_aura(Element.FIRE, 1.0, 2)
	var r2 := Damage.compute(10, Element.WATER, tgt2, table)
	_check_eq(int(r2["damage"]), 20, "水打火 = 10 × 2.0")

	# 2U 火打 1U 水：水槽被扣光移除、火残留 1U 入槽
	var b := _battle()
	var foe: Unit = b.enemies[0]
	foe.add_or_refresh_aura(Element.WATER, 1.0, 2)
	b._apply_aura(foe, Element.FIRE, 2.0)
	_check(foe.get_aura(Element.WATER).is_empty(), "consume 1 把 1U 水扣到 0 → 槽移除")
	_check_eq(float(foe.get_aura(Element.FIRE).get("amount", 0.0)), 1.0, "新元素残留 = 2 - 1 = 1U 火入槽")

	# 2U 火打 2U 水：水剩 1U，火的残留 2-1 = 1U 也入槽
	var b2 := _battle()
	var foe2: Unit = b2.enemies[0]
	foe2.add_or_refresh_aura(Element.WATER, 2.0, 3)
	b2._apply_aura(foe2, Element.FIRE, 2.0)
	_check_eq(float(foe2.get_aura(Element.WATER).get("amount", 0.0)), 1.0, "2U 水被 consume 1 → 剩 1U 保留")
	_check_eq(float(foe2.get_aura(Element.FIRE).get("amount", 0.0)), 1.0, "火的残留 = 2 - 1 = 1U 入槽")

	# 槽满时反应后残留入槽
	var b3 := _battle()
	var foe3: Unit = b3.enemies[0]
	foe3.add_or_refresh_aura(Element.WATER, 2.0, 3)
	foe3.add_or_refresh_aura(Element.ICE, 1.0, 2)
	b3._apply_aura(foe3, Element.FIRE, 2.0)
	_check_eq(foe3.auras.size(), 3, "反应后残留入槽：冰 1 + 水 1 + 火 1 = 3 槽")
	_check_eq(float(foe3.get_aura(Element.FIRE).get("amount", 0.0)), 1.0, "残留的 1U 火确实进了槽")


func _test_coexist_reactions() -> void:
	print("[6] 共存型反应：感电 / 冻结不再产生复合元素 id")
	var b := _battle()
	var foe: Unit = b.enemies[0]
	foe.add_or_refresh_aura(Element.WATER, 1.0, 2)
	b._apply_aura(foe, Element.LIGHTNING, 1.0)
	_check_eq(foe.auras.size(), 2, "感电后两槽共存（水 + 雷）")
	_check_eq(float(foe.get_aura(Element.WATER).get("amount", 0.0)), 1.0, "感电 consume = 0，水槽不动")
	_check_eq(float(foe.get_aura(Element.LIGHTNING).get("amount", 0.0)), 1.0, "雷进了新槽")
	_check(_has_buff(foe, "shock"), "感电挂上 shock 状态")
	_check_eq(foe.get_aura("electro_charged").size(), 0, "没有 electro_charged 这种复合元素槽")

	var b2 := _battle()
	var foe2: Unit = b2.enemies[0]
	foe2.add_or_refresh_aura(Element.WATER, 1.0, 2)
	b2._apply_aura(foe2, Element.ICE, 1.0)
	_check_eq(foe2.auras.size(), 2, "冻结后两槽共存（水 + 冰）")
	_check(_has_buff(foe2, "immobilized"), "冻结挂上 immobilized 状态")
	_check_eq(foe2.get_aura("frozen").size(), 0, "没有 frozen 这种复合元素槽")

	# 超导：状态 + 额外伤害（伤害由 Damage.compute 的 effects 带给调用方）
	var tgt := _unit()
	tgt.add_or_refresh_aura(Element.ICE, 1.0, 2)
	var r := Damage.compute(10, Element.LIGHTNING, tgt, table)
	_check_eq(str(r["reaction"]), "超导", "冰 + 雷 = 超导")
	var has_damage := false
	var has_debuff := false
	for e in r["effects"]:
		if str(e.get("kind", "")) == "damage":
			has_damage = true
		if str(e.get("kind", "")) == "status" and str(e.get("id", "")) == "defense_down":
			has_debuff = true
	_check(has_damage, "超导带额外伤害效果")
	_check(has_debuff, "超导带 defense_down 状态")


func _test_priority() -> void:
	print("[7] 反应优先级：最早创建的槽优先")
	var u := _unit()
	u.add_or_refresh_aura(Element.FIRE, 1.0, 2)
	u.add_or_refresh_aura(Element.WATER, 1.0, 2)
	# 雷同时能与火（超载）和水（感电）反应 —— 应该命中更早的「火」槽
	var slot := Damage.find_reaction_slot(Element.LIGHTNING, u, table)
	_check_eq(slot, 0, "两槽都能反应时，命中下标更小的最早槽")
	var r := Damage.compute(10, Element.LIGHTNING, u, table)
	_check_eq(str(r["reaction"]), "超载", "因此反应是超载（火），不是感电（水）")
	_check_eq(Damage.find_reaction_slot(Element.FIRE, u, table), 1, "同元素槽被跳过，找到后面那个水槽")


func _test_wind_geo() -> void:
	print("[8] 风 / 岩：参与反应但不留附着")
	var b := _battle()
	var foe: Unit = b.enemies[0]
	foe.add_or_refresh_aura(Element.FIRE, 2.0, 3)
	b._apply_aura(foe, Element.WIND, 1.0)
	_check_eq(float(foe.get_aura(Element.FIRE).get("amount", 0.0)), 1.0, "扩散 consume 1：火 2 → 1")
	_check(foe.get_aura(Element.WIND).is_empty(), "风自己不留下槽")

	var b2 := _battle()
	var foe2: Unit = b2.enemies[0]
	b2._apply_aura(foe2, Element.GEO, 1.0)
	_check(foe2.auras.is_empty(), "岩打空目标：什么都不挂")

	var b3 := _battle()
	var foe3: Unit = b3.enemies[0]
	foe3.add_or_refresh_aura(Element.FIRE, 1.0, 2)
	b3._apply_aura(foe3, Element.GEO, 1.0)
	_check(foe3.auras.is_empty(), "结晶把 1U 火吃光 → 槽清空且不留岩")


func _test_immunity_and_dot() -> void:
	print("[9] 免疫 / dot 不改附着")
	var b := _battle()
	var foe: Unit = b.enemies[0]
	foe.immunities.append(Element.FIRE)
	var r := Damage.compute(10, Element.FIRE, foe, table)
	_check_eq(int(r["damage"]), 0, "免疫元素伤害为 0")
	_check_eq(int(r["reaction_slot"]), -1, "免疫时没有反应槽")
	b._apply_aura(foe, Element.FIRE, 1.0)
	_check(foe.auras.is_empty(), "免疫元素不产生附着")

	# dot 只掉血，不挂元素、不触发反应（_settle_status 只扫棋盘上的单位，所以要摆上去）
	var b2 := _battle()
	var foe2 := Unit.from_dict({ "id": "dotted", "name": "带火的木桩", "hp": 100, "owner": "enemy" })
	b2.board.place(foe2, "enemy_support", 1)
	foe2.add_or_refresh_aura(Element.WATER, 1.0, 3)
	foe2.add_buff(Buff.make("burn", 2))
	var before_amount := float(foe2.get_aura(Element.WATER).get("amount", 0.0))
	var before_duration := int(foe2.get_aura(Element.WATER).get("duration", 0))
	var hp_before := foe2.hp
	b2._settle_status("enemy")
	_check_eq(float(foe2.get_aura(Element.WATER).get("amount", 0.0)), before_amount,
		"dot 结算不改变附着元素量")
	_check_eq(foe2.auras.size(), 1, "dot 结算不新增也不删除槽")
	_check_eq(int(foe2.get_aura(Element.WATER).get("duration", 0)), before_duration - 1,
		"dot 结算同回合里附着只按正常节奏 tick 一次（duration -1）")
	_check(foe2.hp < hp_before, "dot 确实掉了血（不是没结算）")

	# 死亡单位不结算 aura tick
	var b3 := _battle()
	var dead := Unit.from_dict({ "id": "dead", "name": "已死木桩", "hp": 10, "owner": "enemy" })
	b3.board.place(dead, "enemy_support", 1)
	dead.add_or_refresh_aura(Element.FIRE, 1.0, 1)
	dead.hp = 0
	b3._settle_status("enemy")
	_check_eq(int(dead.get_aura(Element.FIRE).get("duration", 0)), 1, "已死亡单位的附着不再 tick")


func _test_describe() -> void:
	print("[10] 可读性：describe_auras")
	var u := _unit()
	_check_eq(u.describe_auras(), "无", "没有附着时显示「无」")
	u.add_or_refresh_aura(Element.FIRE, 1.0, 2)
	u.add_or_refresh_aura(Element.WATER, 2.0, 3)
	_check_eq(u.describe_auras(), "火1U(2) 水2U(3)", "多槽按创建顺序拼成可读串")
	_check(u.describe().contains("元素附着"), "describe() 里带附着信息")


func _has_buff(u: Unit, kind: String) -> bool:
	for b in u.buffs:
		if b.kind == kind:
			return true
	return false
