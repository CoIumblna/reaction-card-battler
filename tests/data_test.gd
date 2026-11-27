extends SceneTree
## 数据链路测试：JSON 能不能读进来、能不能变成对象、几张表能不能查
##
## 运行：
##   ... --headless --path . --script res://tests/data_test.gd

var failures: int = 0
var checks: int = 0

## 全绿时应执行的检查项数。对不上 = 有测试段被静默跳过（或 SCRIPT ERROR 打断），
## 只看"共 N 项检查、失败 0 项"会假绿，所以这里硬校验。
const EXPECTED_CHECKS := 46


func _initialize() -> void:
	print("========== 数据链路测试 ==========")
	_test_cards()
	_test_enemies()
	_test_elements()
	_test_reactions()
	_test_statuses()

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


## [1]
func _test_cards() -> void:
	print("[1] 卡牌加载")
	# 卡池会随 M3.4 继续扩（目标 20+ 种），期望值不写死，而是直接读 cards.json 独立
	# 按 count 累加算一遍。这样加卡不会弄红测试；但 load_cards() 的「按 count 展开」
	# 一旦写错（少展开 / 多展开 / 单位卡漏展开），这三条会立刻红。
	var raw := DataLoader.load_json("res://data/tables/cards.json")
	var raw_items: Array = raw.get("cards", [])
	var expect_total := 0
	var expect_units := 0
	var expect_kinds := 0
	for item in raw_items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		if str(item.get("id", "")) != "":
			expect_kinds += 1
		var n := int(item.get("count", 1))
		if n < 1:
			n = 1                      # 与 load_cards() 的钳位保持一致
		expect_total += n
		if str(item.get("type", "")) == "unit":
			expect_units += n
	var cards := DataLoader.load_cards()
	_check_eq(cards.size(), expect_total, "牌库张数（按 cards.json 的 count 展开）")
	if cards.is_empty():
		_check(false, "卡牌数组为空，后续检查无法进行")
		return
	var distinct := {}
	for c in cards:
		distinct[c.id] = true
	_check_eq(distinct.size(), expect_kinds, "不同卡牌种类（等于 cards.json 条目数）")
	# M1 的 7 张都是指令卡；漏写 type 时 Card.from_dict 默认成 "unit"，M2 部署会把它们当单位
	_check_eq(cards[0].type, "order", "指令卡 type = order")
	var bad_type := 0
	for c in cards:
		if c.type != "order" and c.type != "unit":
			bad_type += 1
	_check_eq(bad_type, 0, "卡牌 type 只能是 order / unit")
	var unit_cards := 0
	for c in cards:
		if c.type == "unit":
			unit_cards += 1
	_check_eq(unit_cards, expect_units, "单位卡张数（按 cards.json 里 type=unit 的 count 展开）")
	var strong: Card = null
	for c in cards:
		if c.aura_amount >= 2.0:
			strong = c
			break
	_check(strong != null, "存在 2U 强附着卡")
	if strong != null:
		_check_eq(strong.aura_amount, 2.0, "强附着卡 aura_amount = 2U")
	_check(cards[0].id != "", "第一张卡有 id")
	_check_eq(cards[0].display_name, "火球", "第一张卡名字")
	_check_eq(cards[0].cost, 1, "第一张卡费用")
	_check_eq(cards[0].element, Element.FIRE, "第一张卡元素")
	_check_eq(cards[0].describe() != "", true, "describe() 有输出")


## [2]
func _test_enemies() -> void:
	print("[2] 敌人加载")
	var enemies := DataLoader.load_enemies()
	_check_eq(enemies.size(), 3, "敌人数量")
	if enemies.is_empty():
		_check(false, "敌人数组为空")
		return
	_check_eq(enemies[0].display_name, "史莱姆", "第一个敌人名字")
	_check_eq(enemies[0].hp, enemies[0].max_hp, "初始 HP 等于最大 HP")
	# 火史莱姆免疫火
	var fire_slime: Unit = null
	for e in enemies:
		if e.immunities.has(Element.FIRE):
			fire_slime = e
	_check(fire_slime != null, "存在免疫火的敌人（火史莱姆）")
	if fire_slime != null:
		_check(fire_slime.is_immune(Element.FIRE), "is_immune(fire) 为真")
		_check(not fire_slime.is_immune(Element.WATER), "is_immune(water) 为假")


## [3]
func _test_elements() -> void:
	print("[3] 元素工具")
	_check_eq(Element.all().size(), 6, "基础元素数量")
	_check_eq(Element.display_name(Element.FIRE), "火", "fire 显示名")
	_check_eq(Element.display_name(Element.ICE), "冰", "ice 显示名")
	_check_eq(Element.display_name(Element.WIND), "风", "wind 显示名")
	_check_eq(Element.display_name(Element.GEO), "岩", "geo 显示名")
	_check_eq(Element.display_name("electro_charged"), "无", "v3 起复合元素 id 已删除（回落为 无）")
	_check_eq(Element.display_name("unknown"), "无", "未知元素回落为 无")

	_check_eq(Element.pair_key(Element.FIRE, Element.WATER), "fire+water", "火+水")
	_check_eq(Element.pair_key(Element.WATER, Element.FIRE), "fire+water", "水+火（顺序无关）")
	_check_eq(Element.pair_key(Element.ICE, Element.FIRE), "fire+ice", "冰+火")
	_check_eq(Element.pair_key(Element.FIRE, Element.NONE), "", "含 NONE 时返回空串")
	_check_eq(Element.pair_key("", Element.FIRE), "", "含空串时返回空串")


## [4]
func _test_reactions() -> void:
	print("[4] 反应表")
	var table := ReactionTable.new()
	_check(table.load_from_file("res://data/tables/reactions.json"), "加载成功")
	_check_eq(table.reaction_count(), 14, "反应条数（3.0 前）")
	_check(table.has_reaction(Element.FIRE, Element.WATER), "火+水 有反应")

	var vapor := table.get_reaction(Element.FIRE, Element.WATER)
	_check_eq(str(vapor.get("name", "")), "蒸发", "反应名")
	var mult: Dictionary = vapor.get("multiplier_by_attacker", {})
	_check_eq(float(mult.get("fire", 0.0)), 1.5, "火打水 1.5")
	_check_eq(float(mult.get("water", 0.0)), 2.0, "水打火 2.0")

	var overload := table.get_reaction(Element.FIRE, Element.LIGHTNING)
	_check_eq(str(overload.get("name", "")), "超载", "超载名")
	_check(int((overload.get("effects", []) as Array).size()) > 0, "超载有 effects")

	var swirl := table.get_reaction(Element.WIND, Element.FIRE)
	_check_eq(str(swirl.get("name", "")), "扩散", "风+火 查到扩散")
	_check(not swirl.has("trigger_attacker"), "扩散条目没有方向性字段")
	_check(table.get_reaction(Element.FIRE, Element.FIRE).is_empty(), "同元素无反应")


## [5]
func _test_statuses() -> void:
	print("[5] 状态表")
	var st := StatusTable.new()
	_check(st.load_from_file("res://data/tables/statuses.json"), "加载成功")
	_check_eq(st.status_count(), 4, "状态数量")
	_check(st.has_status("shock"), "有感电状态")
	var frozen := st.get_status("immobilized")
	var effects: Array = frozen.get("effects", [])
	_check(effects.size() > 0, "冻结有 effects")
	if effects.size() > 0:
		_check_eq(str(effects[0].get("kind", "")), "disable", "冻结是 disable")
