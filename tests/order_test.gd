extends SceneTree
## E14 指令卡改造验收测试（待实现）：Order 卡打在棋盘单位 / HQ 上
##
## 运行：
##   ... --headless --path . --script res://tests/pending/order_test.gd
##
## 规格：docs/implementation-tasks.md §25
## 目标规则（2026-11-22 修订）：由 **卡牌数据 `Card.target`** 决定，不是写死 kind：
##   - `enemy`：只能打敌方单位 / 敌方 HQ
##   - `self`：只能打己方单位 / 己方 HQ
##   - 数据没写 target 时，按 kind 推断默认值：damage → enemy，shield/heal → self
##   - `target: "any"`（任意目标）留给 M3，E14 不做
##
## 【启用方式】E14 实现全绿后，把本文件从 tests/pending/ 移到 tests/ 下。

var failures: int = 0
var checks: int = 0
var table: ReactionTable

## 全绿时应执行的检查项数（少执行一条也算红，防"静默跳过"）。
const EXPECTED_CHECKS := 36


func _initialize() -> void:
	print("========== 指令卡测试（E14） ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	_test_default_target()
	_test_shield_heal()
	_test_explicit_target()
	_test_reaction_status()
	_test_death_and_hq()

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
	b.setup(player, enemies, DataLoader.load_cards(), table, 20261122)
	_start(b)
	return b


## target 不传（""）= 数据里没有 target 字段，测"按 kind 推断默认值"。
func _order(id: String, cost: int, kind: String, power: int, element: String = Element.NONE, target: String = "", aura_amount: float = 1.0) -> Card:
	var d := {
		"id": id, "name": id, "type": "order", "cost": cost,
		"element": element, "kind": kind, "power": power, "aura_amount": aura_amount,
	}
	if target != "":
		d["target"] = target
	return Card.from_dict(d)


func _unit(id: String, hp: int, attack: int = 1, owner: String = "player", element: String = Element.NONE) -> Unit:
	return Unit.from_dict({ "id": id, "name": id, "hp": hp, "attack": attack, "owner": owner, "element": element })


func _find_buff(u: Unit, kind: String) -> Buff:
	for b in u.buffs:
		if b.kind == kind:
			return b
	return null


# ---------------------------------------------------------------- 用例

func _test_default_target() -> void:
	print("[1] 默认目标：damage → enemy（不写 target 时按 kind 推断）")
	var b := _new_battle()
	b.energy = 5
	var foe := _unit("foe", 10, 2, "enemy")
	b.board.place(foe, "enemy_support", 1)
	var mine := _unit("mine", 10, 2, "player")
	b.board.place(mine, "player_support", 1)

	var dmg := _order("fire_bolt", 1, "damage", 5, Element.FIRE)
	_check_eq(dmg.target, "enemy", "未写 target 的伤害卡默认 target = enemy")
	b.hand.append(dmg)
	_check(b.play_card(dmg, foe), "伤害指令卡可以打敌方棋盘单位")
	_check_eq(foe.hp, 5, "造成 power 点伤害（10 → 5）")
	_check_eq(b.energy, 4, "扣 1 费")
	_check(not b.hand.has(dmg), "打出的指令卡离开手牌")
	_check_eq(b.board.units_in("enemy_support").size(), 2, "指令卡不进场（棋盘单位数不变：HQ + 敌方单位）")

	var dmg2 := _order("fire_bolt_2", 1, "damage", 5, Element.FIRE)
	b.hand.append(dmg2)
	var energy_before := b.energy
	_check(not b.play_card(dmg2, mine), "target=enemy 的伤害指令卡不能打己方单位")
	_check_eq(b.energy, energy_before, "非法目标不扣费")
	_check(b.hand.has(dmg2), "非法目标的卡留在手里")


func _test_shield_heal() -> void:
	print("[2] 默认目标：shield/heal → self")
	var b := _new_battle()
	b.energy = 5
	var mine := _unit("mine", 10, 2, "player")
	b.board.place(mine, "player_support", 1)
	mine.hp = 6
	var foe := _unit("foe", 10, 2, "enemy")
	b.board.place(foe, "enemy_support", 1)

	var heal0 := _order("mend_probe", 2, "heal", 6)
	_check_eq(heal0.target, "self", "未写 target 的治疗卡默认 target = self")

	var shield := _order("guard", 1, "shield", 6)
	b.hand.append(shield)
	_check(b.play_card(shield, mine), "护盾指令卡可以打己方棋盘单位")
	_check_eq(mine.shield, 6, "护盾值 +power（0 → 6）")

	var heal := _order("mend", 2, "heal", 6)
	b.hand.append(heal)
	_check(b.play_card(heal, mine), "治疗指令卡可以打己方棋盘单位")
	_check_eq(mine.hp, 10, "治疗不超过 max_hp（6 + 6 → 10）")

	var heal2 := _order("mend_2", 2, "heal", 6)
	b.hand.append(heal2)
	var energy_before := b.energy
	_check(not b.play_card(heal2, foe), "target=self 的治疗指令卡不能打敌方单位")
	_check_eq(b.energy, energy_before, "非法目标不扣费")


func _test_explicit_target() -> void:
	print("[3] 显式 target 覆盖：伤害可以打自己、治疗/护盾可以给对方（数据驱动）")
	var b := _new_battle()
	b.energy = 10
	var mine := _unit("mine", 10, 2, "player")
	b.board.place(mine, "player_support", 1)
	var self_dmg := _order("ritual", 1, "damage", 5, Element.NONE, "self")
	b.hand.append(self_dmg)
	_check(b.play_card(self_dmg, mine), "target=self 的伤害卡可以打己方单位")
	_check_eq(mine.hp, 5, "己方单位受到伤害（10 → 5）")

	var b2 := _new_battle()
	b2.energy = 10
	var foe := _unit("foe", 10, 2, "enemy")
	foe.hp = 5
	b2.board.place(foe, "enemy_support", 1)
	var enemy_heal := _order("field_medic", 2, "heal", 6, Element.NONE, "enemy")
	b2.hand.append(enemy_heal)
	_check(b2.play_card(enemy_heal, foe), "target=enemy 的治疗卡可以打敌方单位")
	_check_eq(foe.hp, 10, "敌方单位被治疗（5 + 6 → 10）")

	var b3 := _new_battle()
	b3.energy = 10
	var foe2 := _unit("foe2", 10, 2, "enemy")
	b3.board.place(foe2, "enemy_support", 1)
	var enemy_shield := _order("bribe", 1, "shield", 6, Element.NONE, "enemy")
	b3.hand.append(enemy_shield)
	_check(b3.play_card(enemy_shield, foe2), "target=enemy 的护盾卡可以给敌方单位")
	_check_eq(foe2.shield, 6, "敌方单位获得护盾（0 → 6）")


func _test_reaction_status() -> void:
	print("[4] 元素/反应/状态：指令卡伤害走 compute_damage + _apply_aura")
	var b := _new_battle()
	b.energy = 5
	var foe := _unit("foe", 10, 2, "enemy")
	foe.add_or_refresh_aura(Element.WATER, 1.0, 2)
	b.board.place(foe, "enemy_support", 1)

	var thunder := _order("thunder_strike", 1, "damage", 5, Element.LIGHTNING)
	b.hand.append(thunder)
	_check(b.play_card(thunder, foe), "雷击指令卡打水附着单位成立")
	_check_eq(foe.hp, 5, "感电不改变本次伤害（5 → 5）")
	_check(_find_buff(foe, "shock") != null, "感电反应把 shock 挂到目标身上（C8 接线）")
	_check(not foe.get_aura(Element.WATER).is_empty(), "感电不消耗水槽（v3 共存型）")

	# 火打水：增幅 1.5 → int(floor(6 * 1.5)) = 9
	var b2 := _new_battle()
	b2.energy = 5
	var foe2 := _unit("foe2", 10, 2, "enemy")
	foe2.add_or_refresh_aura(Element.WATER, 1.0, 2)
	b2.board.place(foe2, "enemy_support", 1)
	var fire := _order("fire_bolt", 1, "damage", 6, Element.FIRE)
	b2.hand.append(fire)
	b2.play_card(fire, foe2)
	_check_eq(foe2.hp, 1, "火打水蒸发 1.5 倍并向下取整（10 - 9 = 1）")
	_check(foe2.get_aura(Element.WATER).is_empty(), "蒸发消耗附着（1U 被 consume 清空）")

	# 2U 强附着：炎爆 aura_amount=2
	var b3 := _new_battle()
	b3.energy = 5
	var foe3 := _unit("foe3", 20, 2, "enemy")
	b3.board.place(foe3, "enemy_support", 1)
	var burst := _order("fire_burst", 2, "damage", 8, Element.FIRE, "enemy", 2.0)
	b3.hand.append(burst)
	b3.play_card(burst, foe3)
	_check_eq(float(foe3.get_aura(Element.FIRE).get("amount", 0.0)), 2.0, "炎爆挂 2U 火附着（aura_amount 来自卡牌数据）")


func _test_death_and_hq() -> void:
	print("[5] 死亡移除 / HQ / 免疫")
	var b := _new_battle()
	b.energy = 5
	var foe := _unit("foe", 3, 2, "enemy")
	b.board.place(foe, "enemy_support", 1)
	var dmg := _order("fire_bolt", 1, "damage", 5, Element.FIRE)
	b.hand.append(dmg)
	_check(b.play_card(dmg, foe), "致死伤害指令卡打出")
	_check(b.board.position_of(foe).is_empty(), "普通单位 hp<=0 后从棋盘移除")

	var ehq: Unit = b.board.unit_at("enemy_support", 0)
	var dmg2 := _order("fire_bolt_2", 1, "damage", 5, Element.FIRE)
	b.hand.append(dmg2)
	_check(b.play_card(dmg2, ehq), "伤害指令卡可以打敌方 HQ")
	_check_eq(ehq.hp, 15, "HQ 正常掉血（20 → 15）")
	_check(b.board.unit_at("enemy_support", 0) == ehq, "HQ 被打不会移除（§21）")

	ehq.hp = 2
	var dmg3 := _order("fire_bolt_3", 1, "damage", 5, Element.FIRE)
	b.hand.append(dmg3)
	b.play_card(dmg3, ehq)
	_check(b.is_over() and b.outcome() == "WIN", "打掉敌方 HQ 即胜（outcome = WIN）")

	var b2 := _new_battle()
	b2.energy = 5
	var immune := Unit.from_dict({ "id": "imm", "name": "免疫单位", "hp": 10, "owner": "enemy", "immunities": ["fire"] })
	b2.board.place(immune, "enemy_support", 1)
	var fire := _order("fire_bolt", 1, "damage", 5, Element.FIRE)
	b2.hand.append(fire)
	b2.play_card(fire, immune)
	_check_eq(immune.hp, 10, "免疫火：指令卡伤害为 0、不触发反应")


## 建局：固定玩家先手 + 开始第一个回合（E7b 后 start_battle() 只发牌）
func _start(b: Battle) -> void:
	b.first_move = "player"
	b.start_battle()
	b.begin_first_turn()
