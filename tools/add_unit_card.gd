extends SceneTree
## 单位卡生成器（命令行）：一条命令往 data/tables/cards.json 里加一张单位卡
##
## 用法：
##   godot --headless --path . --script res://tools/add_unit_card.gd -- \
##       --id fire_tank --name 火焰坦克 --cost 3 --attack 3 --defense 4 \
##       --element fire --count 4
##
## 必填：--id --name --cost --attack --defense
## 选填：--element（默认 none）、--count（默认 4）、--unit-class（默认 infantry）、
##       --opcost（默认 1）、--keywords（逗号分隔，默认空）
##
## 它是 tools/unit_maker.bat（图形版）的命令行兄弟：
##   两者**共用同一份**格式与校验逻辑（tools/card_lib.gd），
##   所以命令行加出来的卡和图形界面加出来的卡，字节格式完全一致。
##
## 想图形化地改卡 → 双击 tools\unit_maker.bat

const CardLibRef := preload("res://tools/card_lib.gd")


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


func _add_unit(args: Dictionary) -> String:
	var required := ["id", "name", "cost", "attack", "defense"]
	var missing: Array[String] = []
	for k in required:
		if not args.has(k):
			missing.append("--" + k)
	if not missing.is_empty():
		return "缺少参数：" + ", ".join(missing) + "（--help 看用法）"

	# 读现有数据，用于查重（validate_unit 会拿这个列表判 id 是否重复）
	var r := CardLibRef.read()
	if not bool(r["ok"]):
		return str(r["error"])
	var cards: Array = r["cards"]

	var card := CardLibRef.blank_unit(str(args["id"]))
	card["name"] = str(args["name"])
	card["cost"] = _to_int(args["cost"])
	card["attack"] = _to_int(args["attack"])
	card["defense"] = _to_int(args["defense"])
	card["element"] = str(args.get("element", "none"))
	card["count"] = _to_int(args.get("count", str(CardLibRef.DEFAULT_COUNT)))
	card["unit_class"] = str(args.get("unit-class", "infantry"))
	card["operation_cost"] = _to_int(args.get("opcost", str(CardLibRef.DEFAULT_OPERATION_COST)))

	var kws: Array[String] = []
	var raw_kw := str(args.get("keywords", "")).strip_edges()
	if raw_kw != "":
		for one in raw_kw.split(","):
			var kw := one.strip_edges()
			if kw != "":
				kws.append(kw)
	if not kws.is_empty():
		card["keywords"] = kws

	# 数值合法性判断全在 CardLib，CLI 这边不重复写一套
	var errs := CardLibRef.validate_unit(card, CardLibRef.collect_ids(cards))
	if not errs.is_empty():
		return "\n  - ".join(errs)

	var save_err := CardLibRef.save_card(CardLibRef.CARDS_PATH, card, "insert")
	if save_err != "":
		return save_err

	var after := CardLibRef.read()
	var all_cards: Array = after["cards"]
	print("✓ 已添加单位卡：")
	print("  " + CardLibRef.card_line(card))
	print("  卡牌种类 %d，牌库总张数 %d" % [all_cards.size(), CardLibRef.deck_total(all_cards)])
	print("  文件：" + CardLibRef.CARDS_PATH)
	return ""


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
		return -999   # 故意给一个必被 validate 判死的值，让错误信息统一走 CardLib
	return int(s)


func _usage() -> void:
	print("单位卡生成器（命令行版；图形版见 tools\\unit_maker.bat）")
	print("")
	print("  godot --headless --path . --script res://tools/add_unit_card.gd -- \\")
	print("      --id fire_tank --name 火焰坦克 --cost 3 --attack 3 --defense 4 \\")
	print("      --element fire --count 4")
	print("")
	print("必填：--id --name --cost --attack --defense")
	print("选填：--element（默认 none） --count（默认 4）")
	print("      --unit-class（默认 infantry） --opcost（默认 1）")
	print("      --keywords（逗号分隔，如 blitz,guard）")
	print("元素可选：", ", ".join(CardLibRef.ELEMENTS))
	print("兵科可选：", ", ".join(CardLibRef.UNIT_CLASSES))
