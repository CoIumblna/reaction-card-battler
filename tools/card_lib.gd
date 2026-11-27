class_name CardLib
extends RefCounted
## 卡牌数据的「唯一格式入口」：读、校验、序列化、写回。
##
## 为什么要单独一个文件：
##   以前格式知识散在 tools/add_unit_card.gd 里（KEY_ORDER / _dump / _card_line），
##   再写一个图形工具就会复制第二份 —— 两份迟早不一致，diff 会冒出无意义改动。
##   现在 CLI 工具和图形工具都调这里，改格式只改一处。
##
## 设计要点（很重要，别改）：
##   1. cards.json 的约定是「一张卡占一行」。写回时**不重新序列化整份文件**，
##      只做行级手术（插入 / 替换 / 删除那一行），其它行字节不变。
##      原因：现有文件里指令卡的键顺序并不统一（`guard` 是 power 在前，
##      `fire_bolt` 是 target 在前），整份重排会给没动过的卡造出 diff。
##   2. 数值：整数值的 float 必须写成 `3` 而不是 `3.0`，否则每次保存都是假 diff。
##   3. 写完一定要重新解析一遍自检（条数 + 目标 id），失败就报错让用户回滚。

const CARDS_PATH := "res://data/tables/cards.json"

## 卡牌可选元素：**只有 6 个基础元素**。
## v3 起复合元素 id（electro_charged / frozen）已经整个删掉了 ——
## 感电/冻结改成「两槽共存 + 挂状态」表达，见 docs/element-reactions-v3.md。
## 造卡程序的下拉框、CLI 的 --element 校验都用这份清单。
const ELEMENTS: Array[String] = [
	"none", "fire", "water", "lightning", "ice", "wind", "geo",
]

## 与 tools/validate_data.gd 的 KNOWN_UNIT_CLASSES 保持一致；"" = 未标注
const UNIT_CLASSES: Array[String] = ["", "infantry", "tank", "artillery", "fighter", "bomber"]

## 与 tools/validate_data.gd 的 KNOWN_KEYWORDS 保持一致
const KEYWORDS: Array[String] = ["blitz", "guard"]

const DEFAULT_COUNT := 4
const DEFAULT_OPERATION_COST := 1
## 每张卡在牌组里的默认上限（张）。cards.json 里写 "limit": N 就按 N 算，不写按这个。
## 与 src/core/card.gd 的 Card.DEFAULT_LIMIT 保持一致。
const DEFAULT_LIMIT := 4

## 新单位卡写回时的键顺序。跟现有单位卡的样子保持一致：
##   { "id": "tank", "name": "坦克", "type": "unit", "cost": 4, "element": "none",
##     "attack": 4, "defense": 5, "operation_cost": 1, "unit_class": "tank", "count": 4 }
const KEY_ORDER: Array[String] = [
	"id", "name", "type", "cost", "element",
	"attack", "defense", "operation_cost", "unit_class",
	"kind", "power", "aura_amount", "target", "keywords", "abilities", "limit", "count",
]

const UNIT_CLASS_NAMES := {
	"": "未标注",
	"infantry": "步兵",
	"tank": "坦克",
	"artillery": "炮兵",
	"fighter": "战斗机",
	"bomber": "轰炸机",
}

const KEYWORD_NAMES := {
	"blitz": "闪击",
	"guard": "护卫",
}


# ================================================================ 读

## 读 cards.json。
## 返回 { ok: bool, error: String, text: String, data: Dictionary, cards: Array }
static func read(path: String = CARDS_PATH) -> Dictionary:
	var out := {"ok": false, "error": "", "text": "", "data": {}, "cards": []}
	if not FileAccess.file_exists(path):
		out["error"] = "找不到数据文件：" + path
		return out
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		out["error"] = "数据文件是空的：" + path
		return out
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		out["error"] = "解析失败（顶层必须是对象，检查逗号/引号/BOM）：" + path
		return out
	var cards = data.get("cards", [])
	if typeof(cards) != TYPE_ARRAY:
		out["error"] = "cards 字段不是数组：" + path
		return out
	out["ok"] = true
	out["text"] = text
	out["data"] = data
	out["cards"] = cards
	return out


## 从 cards 数组里按 id 找卡；找不到返回空字典
static func find_card(cards: Array, id: String) -> Dictionary:
	for c in cards:
		if typeof(c) == TYPE_DICTIONARY and str(c.get("id", "")) == id:
			return c
	return {}


static func collect_ids(cards: Array) -> Array[String]:
	var out: Array[String] = []
	for c in cards:
		if typeof(c) == TYPE_DICTIONARY:
			out.append(str(c.get("id", "")))
	return out


# ================================================================ 校验

## 校验一张单位卡。返回问题列表，空数组 = 合法。
## taken_ids：已存在的 id（保存「新卡」时用来查重；保存旧卡时要把自己的 id 排除掉）
static func validate_unit(card: Dictionary, taken_ids: Array = []) -> Array[String]:
	var errs: Array[String] = []

	var id := str(card.get("id", "")).strip_edges()
	if id == "":
		errs.append("id 不能为空")
	elif not id.is_valid_identifier():
		errs.append("id 只能用字母/数字/下划线，且不能以数字开头：" + id)
	elif id != id.to_lower():
		errs.append("id 必须全小写：" + id)
	elif taken_ids.has(id):
		errs.append("id 已存在：" + id + "（改个 id，或先删除旧卡）")

	if str(card.get("name", "")).strip_edges() == "":
		errs.append("名字不能为空")

	if str(card.get("type", "")) != "unit":
		errs.append("type 必须是 unit")

	var cost := int(card.get("cost", 0))
	if cost < 1:
		errs.append("cost 必须 >= 1（实际 %d）" % cost)
	elif cost > 12:
		errs.append("cost 太大了（> 12，能量上限是 12）：%d" % cost)

	var attack := int(card.get("attack", 0))
	if attack < 0:
		errs.append("attack 必须 >= 0（实际 %d）" % attack)

	var defense := int(card.get("defense", 0))
	if defense < 1:
		errs.append("defense 必须 >= 1（防御 <= 0 的单位一上场就死）")

	var op := int(card.get("operation_cost", DEFAULT_OPERATION_COST))
	if op < 0:
		errs.append("operation_cost 不能为负（实际 %d）" % op)

	var element := str(card.get("element", "none"))
	if not ELEMENTS.has(element):
		errs.append("未知元素：" + element)

	var cls := str(card.get("unit_class", ""))
	if not UNIT_CLASSES.has(cls):
		errs.append("未知兵科：" + cls)

	var count := int(card.get("count", 0))
	if count < 1:
		errs.append("count 必须 >= 1（实际 %d）" % count)

	# 每张卡各自的上限：cards.json 写 "limit": N 就按 N 算，不写按默认 4。
	# count 不能超过这张卡自己的 limit。
	var limit := int(card.get("limit", DEFAULT_LIMIT))
	if limit < 1:
		errs.append("limit 必须 >= 1（实际 %d）" % limit)
	elif count > limit:
		errs.append("count(%d) 不能超过这张卡的 limit(%d)" % [count, limit])

	var kws: Variant = card.get("keywords", [])
	if typeof(kws) != TYPE_ARRAY:
		errs.append("keywords 必须是数组")
	else:
		for kw in kws:
			if not KEYWORDS.has(str(kw)):
				errs.append("未知关键词：" + str(kw))

	return errs


## 造一张「空白单位卡」：所有字段都有值，方便图形界面直接绑控件
static func blank_unit(id: String = "new_unit") -> Dictionary:
	var card := {}
	card["id"] = id
	card["name"] = "新单位"
	card["type"] = "unit"
	card["cost"] = 1
	card["element"] = "none"
	card["attack"] = 1
	card["defense"] = 2
	card["operation_cost"] = DEFAULT_OPERATION_COST
	card["unit_class"] = "infantry"
	card["keywords"] = []
	card["limit"] = DEFAULT_LIMIT
	card["count"] = DEFAULT_COUNT
	return card


# ================================================================ 序列化

static func dump(data: Dictionary) -> String:
	var out: Array[String] = ["{"]
	var keys := data.keys()
	for ki in range(keys.size()):
		var k := str(keys[ki])
		var comma := "" if ki == keys.size() - 1 else ","
		if k == "cards":
			var arr: Array = data[k]
			out.append("  \"cards\": [")
			for i in range(arr.size()):
				var c := "" if i == arr.size() - 1 else ","
				out.append("    " + card_line(arr[i]) + c)
			out.append("  ]" + comma)
		else:
			out.append("  " + JSON.stringify(k) + ": " + value_of(data[k]) + comma)
	out.append("}")
	return "\n".join(out) + "\n"


## 一张卡 → 一行 JSON（键按 KEY_ORDER，未知键排在后面，保证不丢字段）
static func card_line(card: Dictionary) -> String:
	var parts: Array[String] = []
	var seen := {}
	for key in KEY_ORDER:
		if card.has(key):
			parts.append(JSON.stringify(key) + ": " + value_of(card[key]))
			seen[key] = true
	for key in card.keys():
		if not seen.has(str(key)):
			parts.append(JSON.stringify(str(key)) + ": " + value_of(card[key]))
	return "{ " + ", ".join(parts) + " }"


## 值 → JSON 文本。整数值的 float 写成整数，避免 `3.0` 这种假 diff。
static func value_of(v) -> String:
	match typeof(v):
		TYPE_STRING:
			return JSON.stringify(v)
		TYPE_INT:
			return str(v)
		TYPE_FLOAT:
			return str(int(v)) if is_equal_approx(v, round(v)) else str(v)
		TYPE_BOOL:
			return "true" if v else "false"
		TYPE_ARRAY:
			var ps: Array[String] = []
			for x in v:
				ps.append(value_of(x))
			return "[" + ", ".join(ps) + "]"
		TYPE_DICTIONARY:
			var ps2: Array[String] = []
			for k in v:
				ps2.append(JSON.stringify(str(k)) + ": " + value_of(v[k]))
			return "{ " + ", ".join(ps2) + " }"
		_:
			return "null"


static func deck_total(cards: Array) -> int:
	var total := 0
	for c in cards:
		if typeof(c) == TYPE_DICTIONARY:
			total += int(c.get("count", 1))
	return total


# ================================================================ 写回（行级手术）

## 保存一张卡。mode: "insert"（新增）| "replace"（覆盖已存在的同 id 卡）
## 返回 "" = 成功；否则是错误信息。
static func save_card(path: String, card: Dictionary, mode: String) -> String:
	var r := read(path)
	if not r["ok"]:
		return str(r["error"])

	var text := str(r["text"])
	var cards: Array = r["cards"]
	var line := card_line(card)
	var id := str(card.get("id", ""))
	var before_n := cards.size()

	var new_text := ""
	if mode == "insert":
		if not find_card(cards, id).is_empty():
			return "id 已存在：" + id
		new_text = surgical_insert(text, line)
	elif mode == "replace":
		if find_card(cards, id).is_empty():
			return "要覆盖的卡不存在：" + id
		new_text = surgical_replace(text, id, line)
	elif mode == "delete":
		return delete_card(path, id)
	else:
		return "未知写入模式：" + mode

	if new_text == "":
		return "拼接失败：cards.json 可能不是「一张卡一行」的格式，请手工检查"

	var werr := write_text(path, new_text)
	if werr != "":
		return werr

	return self_check(path, id, before_n if mode == "replace" else before_n + 1, id if mode == "delete" else "")


## 删除一张卡
static func delete_card(path: String, id: String) -> String:
	var r := read(path)
	if not r["ok"]:
		return str(r["error"])
	var cards: Array = r["cards"]
	if find_card(cards, id).is_empty():
		return "要删除的卡不存在：" + id
	var new_text := surgical_delete(str(r["text"]), id)
	if new_text == "":
		return "拼接失败：cards.json 可能不是「一张卡一行」的格式，请手工检查"
	var werr := write_text(path, new_text)
	if werr != "":
		return werr
	return self_check(path, "", cards.size() - 1, id)


static func write_text(path: String, text: String) -> String:
	var w := FileAccess.open(path, FileAccess.WRITE)
	if w == null:
		return "写文件失败：" + path
	w.store_string(text)
	w.close()
	return ""


## 写完之后重新解析一遍，确认没写坏
static func self_check(path: String, must_have: String, expect_count: int, must_be_gone: String) -> String:
	var r := read(path)
	if not r["ok"]:
		return "写入后解析失败！用 git checkout -- " + path + " 回滚：" + str(r["error"])
	var cards: Array = r["cards"]
	if cards.size() != expect_count:
		return "写入后条数对不上（期望 %d，实际 %d）！用 git checkout -- %s 回滚" % [
			expect_count, cards.size(), path,
		]
	if must_have != "" and find_card(cards, must_have).is_empty():
		return "写入后找不到 id=" + must_have + "，用 git checkout -- " + path + " 回滚"
	if must_be_gone != "" and not find_card(cards, must_be_gone).is_empty():
		return "写入后 " + must_be_gone + " 还在，用 git checkout -- " + path + " 回滚"
	return ""


## 在 cards 数组末尾插一张卡（并给原来的最后一张补逗号）
## 关键：cards.json 允许「一张卡占多行」（学员 2026-11-27 把它重排成了多行缩进格式），
## 所以一切定位都按**卡块**（大括号配对的整段）来做，不能假设「一张卡一行」。
static func surgical_insert(text: String, line: String) -> String:
	var lines := text.split("\n")
	var close := _cards_close_index(lines)
	if close < 0:
		return ""
	var last: Array = _last_card_block(lines, close)
	if last.size() == 2:
		var end_line: String = lines[int(last[1])]
		if not end_line.strip_edges().ends_with(","):
			lines[int(last[1])] = end_line + ","
	lines.insert(close, "    " + line)
	return "\n".join(lines)


## 把 id 对应的那一整块（单行或多行）换掉
static func surgical_replace(text: String, id: String, line: String) -> String:
	var lines := text.split("\n")
	var blk: Array = _card_block_of(lines, id)
	if blk.is_empty():
		return ""
	var had_comma := lines[int(blk[1])].strip_edges().ends_with(",")
	var indent := _indent_of(lines[int(blk[0])])
	var merged := indent + line + ("," if had_comma else "")
	for i in range(int(blk[1]), int(blk[0]) - 1, -1):
		lines.remove_at(i)
	lines.insert(int(blk[0]), merged)
	return "\n".join(lines)


## 删掉 id 对应的那一整块（若成了最后一张，去掉它前一张的尾逗号）
static func surgical_delete(text: String, id: String) -> String:
	var lines := text.split("\n")
	var blk: Array = _card_block_of(lines, id)
	if blk.is_empty():
		return ""
	for i in range(int(blk[1]), int(blk[0]) - 1, -1):
		lines.remove_at(i)
	var close := _cards_close_index(lines)
	if close >= 0:
		var last: Array = _last_card_block(lines, close)
		if last.size() == 2:
			var s: String = lines[int(last[1])]
			if s.strip_edges().ends_with(","):
				var pos := s.rfind(",")
				lines[int(last[1])] = s.substr(0, pos) + s.substr(pos + 1)
	return "\n".join(lines)


static func _cards_close_index(lines: PackedStringArray) -> int:
	for i in range(lines.size() - 1, -1, -1):
		if lines[i].strip_edges() == "]":
			return i
	return -1


## 最后一张卡的卡块，返回 [首行, 末行]；没有卡时返回空数组
static func _last_card_block(lines: PackedStringArray, close: int) -> Array:
	var blocks: Array = _card_blocks(lines, close)
	if blocks.is_empty():
		return []
	return blocks[blocks.size() - 1]


## 按 id 找卡块，返回 [首行, 末行]；找不到返回空数组
static func _card_block_of(lines: PackedStringArray, id: String) -> Array:
	var close := _cards_close_index(lines)
	if close < 0:
		return []
	for blk in _card_blocks(lines, close):
		if _id_of_block(lines, blk) == id:
			return blk
	return []


## 扫出 cards 数组里所有卡块。大括号配对，跳过字符串字面量里的括号。
## 只扫 `"cards": [` 之后到数组闭合 `]` 之前，否则会把最外层文件对象的大括号算进来。
static func _card_blocks(lines: PackedStringArray, close: int) -> Array:
	var out: Array = []
	var open := _cards_open_index(lines, close)
	if open < 0:
		return out
	var depth := 0
	var start := -1
	for i in range(open + 1, close):
		var in_str := false
		var escaped := false
		for idx in range(lines[i].length()):
			var c := lines[i][idx]
			if in_str:
				if escaped:
					escaped = false
				elif c == "\\":
					escaped = true
				elif c == "\"":
					in_str = false
				continue
			if c == "\"":
				in_str = true
			elif c == "{":
				if depth == 0:
					start = i
				depth += 1
			elif c == "}":
				depth -= 1
				if depth <= 0:
					depth = 0
					if start >= 0:
						out.append([start, i])
						start = -1
	return out


## cards 数组的 `[` 所在行（跳过字符串里的方括号）
## 先找标准写法 `"cards": [` / `"cards":[`；找不到就退回「以 "cards" 开头的行」，
## 这样缩进或空格写法变了也不会整段失效（2026-11-27 学员重排过格式，踩过这个坑）。
static func _cards_open_index(lines: PackedStringArray, close: int) -> int:
	for i in range(close):
		var s := lines[i].strip_edges()
		if s == "\"cards\": [" or s == "\"cards\":[":
			return i
	for i in range(close):
		if lines[i].strip_edges().begins_with("\"cards\""):
			return i
	return -1


static func _id_of_block(lines: PackedStringArray, blk: Array) -> String:
	var buf := ""
	for i in range(int(blk[0]), int(blk[1]) + 1):
		buf += lines[i] + "\n"
	var s := buf.strip_edges()
	if s.ends_with(","):
		s = s.substr(0, s.length() - 1)
	var d = JSON.parse_string(s)
	if typeof(d) == TYPE_DICTIONARY:
		return str(d.get("id", ""))
	return ""


## 取一行的前导空白（制表符或空格），拼新行时沿用原缩进
static func _indent_of(line: String) -> String:
	var i := 0
	while i < line.length() and (line[i] == "\t" or line[i] == " "):
		i += 1
	return line.substr(0, i)
