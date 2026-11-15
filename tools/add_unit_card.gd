extends SceneTree
## 单位卡生成器：一条命令往 data/tables/cards.json 里加一张单位卡
##
## 用法：
##   godot --headless --path . --script res://tools/add_unit_card.gd -- \
##       --id fire_tank --name 火焰坦克 --cost 3 --attack 3 --defense 4 \
##       --element fire --count 4
##
## 必填：--id --name --cost --attack --defense
## 选填：--element（默认 none）、--count（默认 4）
##
## 它会：
##   1. 校验 id（小写下划线、不可重复）、数值、元素 id
##   2. 追加到 cards.json 尾部
##   3. 按项目格式写回（2 空格缩进、每张卡一行、UTF-8 无 BOM）
##   4. 写完重新解析一遍自检

const CARDS_PATH := "res://data/tables/cards.json"
const ELEMENTS := ["none", "fire", "water", "lightning", "ice", "wind", "geo", "electro_charged", "frozen"]
const DEFAULT_COUNT := 4

## 写回时的键顺序（跟现有数据保持一致，方便 diff）
const KEY_ORDER := [
	"id", "name", "type", "cost", "element", "unit_class", "kind", "power",
	"attack", "defense", "aura_amount", "target", "keywords", "abilities", "count",
]


func _initialize() -> void:
	var args := _parse_args(OS.get_cmdline_user_args())
	if args.is_empty() or args.has("help"):
		_usage()
		quit(0)
		return
	var err := _add_unit(args)
	if err != "":
		printerr("✗ " + err)
		quit(1)
	else:
		quit(0)


# ---------------------------------------------------------------- 主流程

func _add_unit(args: Dictionary) -> String:
	var required := ["id", "name", "cost", "attack", "defense"]
	var missing: Array[String] = []
	for k in required:
		if not args.has(k):
			missing.append("--" + k)
	if not missing.is_empty():
		return "缺少参数：" + ", ".join(missing) + "（--help 看用法）"

	var id := str(args["id"])
	var display := str(args["name"])
	if not id.is_valid_identifier():
		return "id 只能用字母/数字/下划线，且不能以数字开头：" + id
	if id != id.to_lower():
		return "id 必须全小写：" + id

	var cost := _to_int(args["cost"])
	if cost < 1:
		return "cost 必须是 >= 1 的整数"
	var attack := _to_int(args["attack"])
	if attack < 0:
		return "attack 必须是 >= 0 的整数"
	var defense := _to_int(args["defense"])
	if defense < 1:
		return "defense 必须是 >= 1 的整数（防御 ≤ 0 的单位一上场就死）"

	var element := str(args.get("element", "none"))
	if not ELEMENTS.has(element):
		return "element 不合法：" + element + "（可选：" + ", ".join(ELEMENTS) + "）"

	var count := _to_int(args.get("count", str(DEFAULT_COUNT)))
	if count < 1:
		return "count 必须是 >= 1 的整数"

	# 读旧数据
	if not FileAccess.file_exists(CARDS_PATH):
		return "找不到数据文件：" + CARDS_PATH
	var text := FileAccess.get_file_as_string(CARDS_PATH)
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return "cards.json 解析失败（顶层必须是对象）"
	var cards: Array = data.get("cards", [])
	if typeof(cards) != TYPE_ARRAY:
		return "cards.json 的 cards 字段不是数组"
	for c in cards:
		if typeof(c) == TYPE_DICTIONARY and str(c.get("id", "")) == id:
			return "id 重复：" + id + "（已存在，先删旧卡或换个 id）"

	# 造卡（键顺序固定）
	var card := {}
	card["id"] = id
	card["name"] = display
	card["type"] = "unit"
	card["cost"] = cost
	card["element"] = element
	card["attack"] = attack
	card["defense"] = defense
	card["count"] = count

	cards.append(card)
	data["cards"] = cards

	# 写回
	var out := _dump(data)
	var w := FileAccess.open(CARDS_PATH, FileAccess.WRITE)
	if w == null:
		return "写文件失败：" + CARDS_PATH
	w.store_string(out)
	w.close()

	# 自检：重新解析
	var check = JSON.parse_string(FileAccess.get_file_as_string(CARDS_PATH))
	if typeof(check) != TYPE_DICTIONARY:
		return "写入后 JSON 校验失败！请用 git checkout -- " + CARDS_PATH + " 回滚"
	if int(check.get("cards", []).size()) != cards.size():
		return "写入后条数对不上！请用 git checkout -- " + CARDS_PATH + " 回滚"

	print("✓ 已添加单位卡：")
	print("  " + _card_line(card))
	print("  卡牌种类 %d，牌库总张数 %d" % [cards.size(), _deck_total(cards)])
	print("  文件：" + CARDS_PATH)
	return ""


# ---------------------------------------------------------------- 输出格式

func _dump(data: Dictionary) -> String:
	var out: Array[String] = ["{"]
	var keys := data.keys()
	for ki in range(keys.size()):
		var k := str(keys[ki])
		var is_last := ki == keys.size() - 1
		var comma := "" if is_last else ","
		if k == "cards":
			var arr: Array = data[k]
			out.append("  \"cards\": [")
			for i in range(arr.size()):
				var c := "" if i == arr.size() - 1 else ","
				out.append("    " + _card_line(arr[i]) + c)
			out.append("  ]" + comma)
		else:
			out.append("  " + JSON.stringify(k) + ": " + _value(data[k]) + comma)
	out.append("}")
	return "\n".join(out) + "\n"


func _card_line(card: Dictionary) -> String:
	var parts: Array[String] = []
	var seen := {}
	for key in KEY_ORDER:
		if card.has(key):
			parts.append(JSON.stringify(key) + ": " + _value(card[key]))
			seen[key] = true
	for key in card.keys():
		if not seen.has(str(key)):
			parts.append(JSON.stringify(str(key)) + ": " + _value(card[key]))
	return "{ " + ", ".join(parts) + " }"


func _value(v) -> String:
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
				ps.append(_value(x))
			return "[" + ", ".join(ps) + "]"
		TYPE_DICTIONARY:
			var ps2: Array[String] = []
			for k in v:
				ps2.append(JSON.stringify(str(k)) + ": " + _value(v[k]))
			return "{ " + ", ".join(ps2) + " }"
		_:
			return "null"


func _deck_total(cards: Array) -> int:
	var total := 0
	for c in cards:
		if typeof(c) == TYPE_DICTIONARY:
			total += int(c.get("count", 1))
	return total


# ---------------------------------------------------------------- 参数

func _parse_args(raw: Array) -> Dictionary:
	var out := {}
	var i := 0
	while i < raw.size():
		var token := str(raw[i])
		if token.begins_with("--"):
			var key := token.substr(2)
			if i + 1 < raw.size() and not str(raw[i + 1]).begins_with("--"):
				out[key] = str(raw[i + 1])
				i += 1
			else:
				out[key] = "true"
		i += 1
	return out


func _to_int(v) -> int:
	var s := str(v)
	if not s.is_valid_int():
		return -1
	return int(s)


func _usage() -> void:
	print("单位卡生成器")
	print("")
	print("  godot --headless --path . --script res://tools/add_unit_card.gd -- \\")
	print("      --id fire_tank --name 火焰坦克 --cost 3 --attack 3 --defense 4 \\")
	print("      --element fire --count 4")
	print("")
	print("必填：--id --name --cost --attack --defense")
	print("选填：--element（默认 none） --count（默认 4）")
	print("元素可选：", ", ".join(ELEMENTS))
