extends SceneTree
## 数据校验器（M3.5 / BACKLOG A5）：改完 data/ 后手动跑，一条命令列出所有非法项。
##
## 用法：
##   $g --headless --path . --script res://tools/validate_data.gd
##   退出码 0 = 数据合法；1 = 有非法项（会逐条打印 文件/位置/原因）
##
## 检查范围：cards.json（字段/枚举/重复 id/张数/limit）、reactions.json（元素配对/效果/状态引用）、
##          statuses.json（效果字段）、elements.json（枚举完整性/duration）、
##          enemies.json（hp/attack/immunities/固有护盾槽）、data/decks/*.json（39 张/每卡 limit）。
## 说明：只做"结构合法性"，不做数值平衡（平衡用 tools/balance_sim.gd）。

var errors: Array[String] = []
var warnings: Array[String] = []

const KNOWN_EFFECT_KINDS := ["damage", "status", "aura", "shield", "heal", "dot", "disable", "stat_mod"]
const KNOWN_CARD_KINDS := ["damage", "shield", "heal"]
const KNOWN_KEYWORDS := ["blitz", "guard"]   # M3 首批；以后加关键词同步这里
# 与 docs/adr/004-m3-keywords.md 决定 3 保持一致（5 类兵科；"" = 未标注，M3.4 补）
const KNOWN_UNIT_CLASSES := ["", "infantry", "tank", "artillery", "fighter", "bomber"]
# 卡牌可以填的元素：只有 6 个基础元素（+ none 占位）。
# v3 起复合元素 id（electro_charged / frozen）整个删了 —— 感电/冻结改成「两槽共存 + 挂状态」，
# 不再有"反应产物也能当附着元素"这种东西。卡上写了非法元素就报错，别让人手填出怪卡。
const CARD_CHOICE_ELEMENTS := ["none", "fire", "water", "lightning", "ice", "wind", "geo"]


func _initialize() -> void:
	print("========== 数据校验 ==========")
	var elements: Array = _load_array("res://data/tables/elements.json", "elements")
	var statuses: Dictionary = _load_dict("res://data/tables/statuses.json", "statuses")
	var reactions: Dictionary = _load_dict("res://data/tables/reactions.json", "reactions")
	var cards: Array = _load_array("res://data/tables/cards.json", "cards")

	var element_ids: Array[String] = []
	if elements.is_empty():
		_error("elements.json", "elements 为空或加载失败")
	else:
		for e in elements:
			if typeof(e) != TYPE_DICTIONARY or str(e.get("id", "")) == "":
				_error("elements.json", "元素项缺 id：%s" % str(e))
			else:
				element_ids.append(str(e["id"]))
				# v3：每个基础元素都要有 duration（附着默认持续几回合），且必须 > 0
				if not e.has("duration") or int(e.get("duration", 0)) <= 0:
					_error("elements.json/%s" % str(e["id"]),
						"缺 duration 或 duration <= 0（v3 起每个元素都要写附着回合数）")

	_check_statuses(statuses)
	_check_reactions(reactions, statuses, element_ids)
	_check_cards(cards, statuses, element_ids)
	_check_enemies(element_ids)
	_check_decks(cards)

	print("---------------------------------------")
	for w in warnings:
		print("  [warn] %s" % w)
	if errors.is_empty():
		print("共 0 条错误、%d 条警告 —— 数据合法" % warnings.size())
		print("PASS")
		quit(0)
	else:
		for e in errors:
			printerr("  [ERROR] %s" % e)
		printerr("共 %d 条错误、%d 条警告" % [errors.size(), warnings.size()])
		printerr("FAIL")
		quit(1)


# ---------------------------------------------------------------- 加载

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		_error(path, "文件不存在")
		return null
	var text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text)
	if data == null:
		_error(path, "JSON 解析失败（检查逗号/引号/BOM）")
	return data


func _load_array(path: String, key: String) -> Array:
	var d = _read_json(path)
	if typeof(d) != TYPE_DICTIONARY:
		return []
	var arr = d.get(key, [])
	if typeof(arr) != TYPE_ARRAY:
		_error(path, "缺少数组字段 `%s`" % key)
		return []
	return arr


func _load_dict(path: String, key: String) -> Dictionary:
	var d = _read_json(path)
	if typeof(d) != TYPE_DICTIONARY:
		return {}
	var out = d.get(key, {})
	if typeof(out) != TYPE_DICTIONARY:
		_error(path, "缺少字典字段 `%s`" % key)
		return {}
	return out


# ---------------------------------------------------------------- 各项检查

func _check_statuses(statuses: Dictionary) -> void:
	if statuses.is_empty():
		_error("statuses.json", "statuses 为空")
		return
	for id in statuses:
		var st = statuses[id]
		if typeof(st) != TYPE_DICTIONARY:
			_error("statuses.json", "状态 `%s` 不是对象" % id)
			continue
		var effects = st.get("effects", [])
		if typeof(effects) != TYPE_ARRAY or effects.is_empty():
			_error("statuses.json", "状态 `%s` 缺 effects" % id)
			continue
		for e in effects:
			_check_effect("statuses.json/%s" % id, e, [], [])


func _check_reactions(reactions: Dictionary, statuses: Dictionary, element_ids: Array[String]) -> void:
	if reactions.is_empty():
		_error("reactions.json", "reactions 为空")
		return
	for key in reactions:
		var where := "reactions.json/%s" % key
		var parts := str(key).split("+")
		if parts.size() != 2:
			_error(where, "反应键必须是 `元素+元素`，实际 `%s`" % key)
		else:
			for p in parts:
				if not element_ids.is_empty() and not element_ids.has(p):
					_error(where, "未知元素 `%s`" % p)
		var act = reactions[key]
		if typeof(act) != TYPE_DICTIONARY:
			_error(where, "反应不是对象")
			continue
		var effects = act.get("effects", [])
		if typeof(effects) != TYPE_ARRAY:
			_error(where, "effects 不是数组")
			continue
		for e in effects:
			_check_effect(where, e, statuses.keys(), element_ids)


func _check_effect(where: String, e: Variant, status_ids: Array, element_ids: Array[String]) -> void:
	if typeof(e) != TYPE_DICTIONARY:
		_error(where, "effect 不是对象：%s" % str(e))
		return
	var kind := str(e.get("kind", ""))
	if not KNOWN_EFFECT_KINDS.has(kind):
		_error(where, "未知 effect.kind `%s`" % kind)
		return
	match kind:
		"damage", "dot", "shield", "heal":
			if not e.has("value"):
				_error(where, "`%s` 效果缺 value" % kind)
		"status":
			var sid := str(e.get("id", ""))
			if sid == "":
				_error(where, "status 效果缺 id")
			elif not status_ids.is_empty() and not status_ids.has(sid):
				_error(where, "status 效果引用不存在的状态 `%s`" % sid)
			if not e.has("duration") or float(e.get("duration", 0.0)) <= 0.0:
				_error(where, "status 效果 duration 必须 > 0")
		"aura":
			var el := str(e.get("element", ""))
			if el == "":
				_error(where, "aura 效果缺 element")
			elif not element_ids.is_empty() and not element_ids.has(el):
				_error(where, "aura 效果的 element `%s` 不在 elements.json" % el)
			if not e.has("amount"):
				_error(where, "aura 效果缺 amount")
		"stat_mod":
			if not e.has("stat") or not e.has("value"):
				_error(where, "stat_mod 效果缺 stat/value")
		"disable":
			pass


func _check_cards(cards: Array, statuses: Dictionary, element_ids: Array[String]) -> void:
	if cards.is_empty():
		_error("cards.json", "cards 为空")
		return
	var seen := {}
	var total_count := 0
	for c in cards:
		if typeof(c) != TYPE_DICTIONARY:
			_error("cards.json", "卡牌项不是对象：%s" % str(c))
			continue
		var id := str(c.get("id", ""))
		var where := "cards.json/%s" % (id if id != "" else "<无 id>")
		if id == "":
			_error(where, "卡牌缺 id")
		elif seen.has(id):
			_error(where, "id 重复")
		seen[id] = true
		var ctype := str(c.get("type", ""))
		if ctype != "unit" and ctype != "order":
			_error(where, "type 必须是 unit/order，实际 `%s`" % ctype)
		if not c.has("cost") or int(c.get("cost", -1)) < 0:
			_error(where, "cost 缺失或为负")
		var count := int(c.get("count", 0))
		if count <= 0:
			_error(where, "count 必须 > 0")
		total_count += count
		# 每张卡各自的上限：cards.json 写 "limit": N 就按 N 算，不写按默认 4。
		# 漏写字段绝不能变成"无限制"，所以缺省值必须是个确定数字。
		var limit := int(c.get("limit", DEFAULT_CARD_LIMIT))
		if limit < 1:
			_error(where, "limit 必须 >= 1（实际 %d）" % limit)
		elif count > limit:
			_error(where, "count(%d) 不能超过这张卡的 limit(%d)" % [count, limit])
		var el := str(c.get("element", ""))
		if el != "" and el != "none" and not element_ids.is_empty() and not element_ids.has(el):   # none 是内置占位元素，不在 elements.json
			_error(where, "未知元素 `%s`" % el)
		elif el != "" and not CARD_CHOICE_ELEMENTS.has(el):
			_error(where, "卡牌不能使用元素 `%s`：只允许 %s"
				% [el, "、".join(CARD_CHOICE_ELEMENTS)])
		if ctype == "unit":
			for f in ["attack", "defense"]:
				if not c.has(f) or int(c.get(f, -1)) < 0:
					_error(where, "单位卡缺 %s" % f)
			var cls := str(c.get("unit_class", ""))
			if not KNOWN_UNIT_CLASSES.has(cls):
				_error(where, "未知 unit_class `%s`（允许：%s）" % [cls, "、".join(KNOWN_UNIT_CLASSES)])
			if c.has("operation_cost") and int(c["operation_cost"]) < 0:
				_error(where, "operation_cost 不能为负")
			for kw in _as_array(c.get("keywords", [])):
				if not KNOWN_KEYWORDS.has(str(kw)):
					warnings.append("%s：未知关键词 `%s`（M3 只实现 %s）" % [where, str(kw), "、".join(KNOWN_KEYWORDS)])
		elif ctype == "order":
			var kind := str(c.get("kind", ""))
			if not KNOWN_CARD_KINDS.has(kind):
				_error(where, "指令卡 kind 未知：`%s`（允许：%s）" % [kind, "、".join(KNOWN_CARD_KINDS)])
			if c.has("power") and int(c["power"]) < 0:
				_error(where, "power 不能为负")
	print("  [info] 卡牌种类 %d、牌组总张数 %d" % [seen.size(), total_count])


# ---------------------------------------------------------------- 敌人校验（M3.6b）

## 敌人数据很小但有两个容易写错的地方：
##   1) immunities 是静态免疫（伤害 0、不反应、不挂槽），v3 起不再用它表达"自带元素护盾"；
##   2) 固有护盾要写在 auras 里，且必须 innate:true + duration:0（护盾槽不随时间衰减）。
## 写错了不会崩，只会静默变成"没有护盾的普通单位"，所以这里逐条抓出来。
func _check_enemies(element_ids: Array[String]) -> void:
	var path := "res://data/tables/enemies.json"
	var enemies: Array = _load_array(path, "enemies")
	if enemies.is_empty():
		_error(path, "enemies 为空或加载失败")
		return
	var seen := {}
	for i in range(enemies.size()):
		var e = enemies[i]
		if typeof(e) != TYPE_DICTIONARY:
			_error("%s[%d]" % [path, i], "敌人项不是对象")
			continue
		var id := str(e.get("id", ""))
		if id == "":
			_error("%s[%d]" % [path, i], "缺 id")
			continue
		if seen.has(id):
			_error(path, "敌人 id 重复：`%s`" % id)
		seen[id] = true
		if str(e.get("name", "")) == "":
			_error(path, "敌人 `%s` 缺 name" % id)
		if int(e.get("hp", 0)) <= 0:
			_error(path, "敌人 `%s` 的 hp 必须 > 0" % id)
		if int(e.get("attack", 0)) < 0:
			_error(path, "敌人 `%s` 的 attack 不能为负" % id)

		var innates: Array[String] = []
		for a in _as_array(e.get("auras", [])):
			if typeof(a) != TYPE_DICTIONARY:
				_error(path, "敌人 `%s` 的 auras 项不是对象" % id)
				continue
			var el := str(a.get("element", ""))
			if not element_ids.has(el):
				_error(path, "敌人 `%s` 的 aura 元素 `%s` 不在 elements.json" % [id, el])
			if not bool(a.get("innate", false)):
				_warn(path, "敌人 `%s` 的 %s 槽不是 innate（普通附着，会随时间消失）" % [id, el])
				continue
			innates.append(el)
			if float(a.get("amount", 0.0)) <= 0.0:
				_error(path, "敌人 `%s` 的护盾 `%s` 的 amount 必须 > 0" % [id, el])
			if int(a.get("duration", -1)) != 0:
				_error(path, "敌人 `%s` 的护盾 `%s` 的 duration 必须写 0（护盾不随时间衰减）" % [id, el])
		if innates.size() > 3:
			_error(path, "敌人 `%s` 的护盾槽 %d 个，超过 Unit.MAX_AURAS(3)" % [id, innates.size()])

		for im in _as_array(e.get("immunities", [])):
			var imel := str(im)
			if not element_ids.has(imel):
				_error(path, "敌人 `%s` 的免疫元素 `%s` 不在 elements.json" % [id, imel])
			if innates.has(imel):
				_error(path, "敌人 `%s` 对 `%s` 同时写了静态免疫和固有护盾，语义冲突（护盾免疫要能被反应啃掉，静态免疫不会）" % [id, imel])
	print("  [info] 敌人 %d 种 ✓" % enemies.size())


func _as_array(v: Variant) -> Array:
	if typeof(v) == TYPE_ARRAY:
		return v
	return []


# ---------------------------------------------------------------- 输出

func _error(where: String, msg: String) -> void:
	errors.append("%s：%s" % [where, msg])


func _warn(where: String, msg: String) -> void:
	warnings.append("%s：%s" % [where, msg])

# ---------------------------------------------------------------- 牌组校验（M3.5）

const DECK_SIZE := 39
const DEFAULT_CARD_LIMIT := 4      # 与 Card.DEFAULT_LIMIT 保持一致；cards.json 写 "limit" 可覆盖


func _check_decks(cards: Array) -> void:
	var dir := "res://data/decks"
	if not DirAccess.dir_exists_absolute(dir):
		return
	var known := {}
	var limits := {}
	for c in cards:
		if typeof(c) == TYPE_DICTIONARY:
			var cid := str(c.get("id", ""))
			known[cid] = true
			limits[cid] = int(c.get("limit", DEFAULT_CARD_LIMIT))
	var files := DirAccess.get_files_at(dir)
	for f in files:
		if not f.ends_with(".json"):
			continue
		var path := "%s/%s" % [dir, f]
		var d = _read_json(path)
		if typeof(d) != TYPE_DICTIONARY:
			continue
		var entries = d.get("cards", [])
		if typeof(entries) != TYPE_ARRAY:
			_error(path, "缺 cards 数组")
			continue
		var total := 0
		var seen := {}
		for e in entries:
			if typeof(e) != TYPE_DICTIONARY:
				_error(path, "cards 项不是对象")
				continue
			var id := str(e.get("id", ""))
			var count := int(e.get("count", 0))
			if id == "" or not known.has(id):
				_error(path, "未知卡牌 id `%s`" % id)
			if count <= 0:
				_error(path, "卡 `%s` 的 count 必须 > 0" % id)
			seen[id] = int(seen.get(id, 0)) + count
			total += count
		for id in seen:
			var limit := int(limits.get(id, DEFAULT_CARD_LIMIT))
			if int(seen[id]) > limit:
				_error(path, "卡 `%s` 超过上限 %d（%d 张）" % [id, limit, int(seen[id])])
		if total != DECK_SIZE:
			_error(path, "牌组张数必须 = %d（实际 %d）" % [DECK_SIZE, total])
		else:
			print("  [info] 牌组 %s：%d 张 ✓" % [f, total])
