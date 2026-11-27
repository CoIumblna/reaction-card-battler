extends SceneTree
## CardLib 自检：把 cards.json 复制到临时文件上反复手术，验证
##   1. 读回的东西和原文件一致
##   2. 插入 / 覆盖 / 删除之后，**没动过的行字节不变**（只有目标行变）
##   3. 三种手术组合起来的最终文本能被 JSON 正确解析、条数对
##   4. 非法卡能被 validate_unit 拦下来
##
## 用法： $g --headless --path . --script res://tools/test_card_lib.gd
##
## 注意：它只碰 scrath 文件（user:// 下的临时文件），不碰真数据。

const EXPECTED_CHECKS := 61

const SRC := "res://data/tables/cards.json"
const TMP := "user://_cardlib_scratch.json"

var checks := 0
var fails := 0


func _initialize() -> void:
	print("========== CardLib 自检 ==========")
	_test_read()
	_test_insert()
	_test_replace()
	_test_delete()
	_test_roundtrip_all()
	_test_validate()
	_test_value_format()
	_test_blank()
	_test_element_choices()
	_test_limit()
	print("----------------------------------")
	if checks != EXPECTED_CHECKS:
		printerr("[FAIL] 覆盖不完整：实际 %d 项，EXPECTED_CHECKS = %d" % [checks, EXPECTED_CHECKS])
		fails += 1
	if fails == 0:
		print("共 %d 项检查，失败 0 项" % checks)
		print("PASS")
		quit(0)
	else:
		printerr("共 %d 项检查，失败 %d 项" % [checks, fails])
		printerr("FAIL")
		quit(1)


# ---------------------------------------------------------------- 工具

func _reset_tmp() -> void:
	var src := FileAccess.get_file_as_string(SRC)
	var w := FileAccess.open(TMP, FileAccess.WRITE)
	w.store_string(src)
	w.close()


func _tmp_text() -> String:
	return FileAccess.get_file_as_string(TMP)


func _line_count(t: String) -> int:
	return t.split("\n").size()


## 真数据文件里现在有多少种卡。**不在断言里写死数字** —— M3.4 卡池在扩
## （目标 20+ 种），写死 11 会让每加一张卡就把工具自检弄红，而那不是工具坏了。
func _src_count() -> int:
	return _card_ids(FileAccess.get_file_as_string(SRC)).size()


func _card_ids(t: String) -> Array[String]:
	var out: Array[String] = []
	var d = JSON.parse_string(t)
	if typeof(d) == TYPE_DICTIONARY:
		for c in d.get("cards", []):
			if typeof(c) == TYPE_DICTIONARY:
				out.append(str(c.get("id", "")))
	return out


func _check(cond: bool, msg: String) -> void:
	checks += 1
	if cond:
		print("  [ok] " + msg)
	else:
		fails += 1
		printerr("  [FAIL] " + msg)


# ---------------------------------------------------------------- 测试

func _test_read() -> void:
	print("[1] 读取")
	var r := CardLib.read(SRC)
	_check(bool(r["ok"]), "读取 cards.json 成功")
	_check(str(r["error"]) == "", "没有报错")
	var cards: Array = r["cards"]
	_check(cards.size() == _src_count(), "卡牌种类等于真数据条目数（实际 %d）" % cards.size())
	_check(not CardLib.find_card(cards, "tank").is_empty(), "能找到 tank")
	_check(CardLib.find_card(cards, "no_such_card").is_empty(), "找不到的 id 返回空字典")

	var bad := CardLib.read("res://data/tables/_does_not_exist.json")
	_check(not bool(bad["ok"]), "读不存在的文件返回失败")
	_check(str(bad["error"]) != "", "读不存在文件时有错误信息")


func _test_insert() -> void:
	print("[2] 插入")
	_reset_tmp()
	var before := _tmp_text()
	var cards_before := _card_ids(before)

	var card := CardLib.blank_unit("test_wolf")
	card["name"] = "测试狼"
	card["cost"] = 2
	card["attack"] = 3
	card["defense"] = 2
	card["element"] = "wind"
	card["unit_class"] = "infantry"
	card["count"] = 2

	var err := CardLib.save_card(TMP, card, "insert")
	_check(err == "", "插入成功（err=%s）" % err)

	var after := _tmp_text()
	var cards_after := _card_ids(after)
	_check(cards_after.size() == cards_before.size() + 1, "条数 +1（%d → %d）" % [cards_before.size(), cards_after.size()])
	_check(cards_after[cards_after.size() - 1] == "test_wolf", "新卡排在最后")

	# 关键：把新插的那行摘掉之后，剩下的每一行都要和原文件逐字节一致
	var before_lines := before.split("\n")
	var after_lines := after.split("\n")
	var inserted_at := -1
	for i in range(after_lines.size()):
		if after_lines[i] == "    " + CardLib.card_line(card):
			inserted_at = i
			break
	_check(inserted_at >= 0, "能在结果里定位到新插的那一行")

	var trimmed := Array(after_lines)
	if inserted_at >= 0:
		trimmed.remove_at(inserted_at)
	var unchanged := trimmed.size() == before_lines.size()
	if unchanged:
		for i in range(before_lines.size()):
			if trimmed[i] == before_lines[i]:
				continue
			# 允许的唯一改动：原最后一张卡补了行尾逗号
			if trimmed[i] == before_lines[i] + ",":
				continue
			unchanged = false
			printerr("    第 %d 行变了：\n      旧 %s\n      新 %s" % [i, before_lines[i], trimmed[i]])
			break
	_check(unchanged, "插入只动了目标位置，其它行字节不变")

	# 插重复 id 必须拒绝
	var dup := CardLib.save_card(TMP, card, "insert")
	_check(dup != "", "插入重复 id 被拒绝")


func _test_replace() -> void:
	print("[3] 覆盖")
	_reset_tmp()
	var r := CardLib.read(TMP)
	var tank := CardLib.find_card(r["cards"], "tank").duplicate(true)
	tank["defense"] = 9
	var err := CardLib.save_card(TMP, tank, "replace")
	_check(err == "", "覆盖 tank 成功（err=%s）" % err)

	var after := _card_ids(_tmp_text())
	_check(after.size() == _src_count(), "条数不变（%d）" % _src_count())

	var r2 := CardLib.read(TMP)
	var tank2 := CardLib.find_card(r2["cards"], "tank")
	_check(int(tank2.get("defense", 0)) == 9, "defense 改成 9 生效")
	_check(int(tank2.get("attack", 0)) == 4, "其它字段没丢（attack 仍 4）")

	var missing := tank.duplicate(true)
	missing["id"] = "no_such_card"
	var err2 := CardLib.save_card(TMP, missing, "replace")
	_check(err2 != "", "覆盖不存在的卡被拒绝")


func _test_delete() -> void:
	print("[4] 删除")
	_reset_tmp()
	var before := _card_ids(_tmp_text())
	var err := CardLib.delete_card(TMP, "archer")
	_check(err == "", "删除 archer 成功（err=%s）" % err)
	var after := _card_ids(_tmp_text())
	_check(after.size() == before.size() - 1, "条数 -1（%d → %d）" % [before.size(), after.size()])
	_check(not after.has("archer"), "archer 已不在")

	# 删最后一张：前一张的尾逗号必须被去掉，否则 JSON 坏
	var r := CardLib.read(TMP)
	var ids := CardLib.collect_ids(r["cards"])
	var last_id := ids[ids.size() - 1]
	var err2 := CardLib.delete_card(TMP, last_id)
	_check(err2 == "", "删除最后一张（%s）成功" % last_id)
	var r2 := CardLib.read(TMP)
	_check(bool(r2["ok"]), "删最后一张后 JSON 仍可解析")

	var err3 := CardLib.delete_card(TMP, "no_such_card")
	_check(err3 != "", "删除不存在的卡被拒绝")


func _test_roundtrip_all() -> void:
	print("[5] 组合手术")
	_reset_tmp()
	var a := CardLib.blank_unit("zz_one")
	var b := CardLib.blank_unit("zz_two")
	_check(CardLib.save_card(TMP, a, "insert") == "", "插入 zz_one")
	_check(CardLib.save_card(TMP, b, "insert") == "", "插入 zz_two")
	_check(CardLib.delete_card(TMP, "zz_one") == "", "删除 zz_one")
	var r := CardLib.read(TMP)
	_check(bool(r["ok"]) && r["cards"].size() == _src_count() + 1, "最终 %d 种卡且 JSON 合法" % (_src_count() + 1))
	_check(not CardLib.collect_ids(r["cards"]).has("zz_one"), "zz_one 已消失")
	_check(CardLib.collect_ids(r["cards"]).has("zz_two"), "zz_two 仍在")


func _test_validate() -> void:
	print("[6] 校验")
	var good := CardLib.blank_unit("ok_card")
	_check(CardLib.validate_unit(good).is_empty(), "合法卡无报错（%s）" % str(CardLib.validate_unit(good)))

	var bad := CardLib.blank_unit("Bad-Card")
	bad["name"] = ""
	bad["cost"] = 0
	bad["defense"] = 0
	bad["count"] = 9
	bad["element"] = "holy"
	bad["unit_class"] = "wizard"
	var errs := CardLib.validate_unit(bad)
	_check(errs.size() >= 6, "一堆毛病都被抓住（实际 %d 条）" % errs.size())
	_check(_joined(errs).contains("id"), "报错里点了 id 的问题")
	_check(_joined(errs).contains("defense"), "报错里点了 defense 的问题")

	var dup := CardLib.blank_unit("tank")
	_check(not CardLib.validate_unit(dup, ["tank"]).is_empty(), "id 与已有卡重名被抓住")
	_check(CardLib.validate_unit(dup, []).is_empty(), "同样的卡在不重复时是合法的")


func _joined(arr: Array[String]) -> String:
	return "\n".join(arr)


func _test_value_format() -> void:
	print("[7] 数值格式")
	_check(CardLib.value_of(3) == "3", "int 3 → \"3\"")
	_check(CardLib.value_of(3.0) == "3", "float 3.0 → \"3\"（不写 3.0，避免假 diff）")
	_check(CardLib.value_of(1.5) == "1.5", "float 1.5 → \"1.5\"")
	_check(CardLib.value_of("步兵") == "\"步兵\"", "字符串带引号")
	_check(CardLib.value_of(["blitz", "guard"]) == "[\"blitz\", \"guard\"]", "数组序列化")


func _test_blank() -> void:
	print("[8] 空白卡")
	var b := CardLib.blank_unit("abc")
	_check(str(b.get("type", "")) == "unit", "blank_unit 的 type = unit")
	_check(CardLib.validate_unit(b).is_empty(), "空白卡默认值就合法（errs=%s）" % str(CardLib.validate_unit(b)))


## 卡牌可选元素必须只有 6 个基础元素。
## v3 起复合元素 id（electro_charged / frozen）整个删了 —— 感电/冻结改成「两槽共存 + 挂状态」，
## 不再有"反应产物也能当附着元素"这种东西。清单里一旦混进这两个字符串，
## 造卡程序的下拉框就会多出两个不存在的选项，validate_data 也会放过它们。
func _test_element_choices() -> void:
	print("[9] 元素可选清单")
	_check(CardLib.ELEMENTS.size() == 7, "可选元素 7 项（none + 6 基础，实际 %d）" % CardLib.ELEMENTS.size())
	_check(not CardLib.ELEMENTS.has("electro_charged"), "不含 v3 已删除的 electro_charged")
	_check(not CardLib.ELEMENTS.has("frozen"), "不含 v3 已删除的 frozen")
	for e in ["fire", "water", "lightning", "ice", "wind", "geo"]:
		_check(CardLib.ELEMENTS.has(e), "基础元素 %s 在清单里" % e)

	# 用空白卡试：不在清单里的元素必须被 validate 拦下来
	var bad := CardLib.blank_unit("bad_element_card")
	bad["element"] = "electro_charged"
	_check(not CardLib.validate_unit(bad).is_empty(), "已删除的复合元素 id 被 validate_unit 拦下")
	bad["element"] = "frozen"
	_check(not CardLib.validate_unit(bad).is_empty(), "frozen 也被拦下")
	bad["element"] = "lightning"
	_check(CardLib.validate_unit(bad).is_empty(), "普通雷元素合法")


## per-card limit：每张卡自己带上限，缺省 4。
func _test_limit() -> void:
	print("[10] 每张卡的上限（limit）")
	var b := CardLib.blank_unit("limit_card")
	_check(CardLib.validate_unit(b).is_empty(), "空白卡（默认 limit）就合法")
	_check(int(b.get("limit", 0)) == CardLib.DEFAULT_LIMIT,
		"blank_unit 带默认 limit（%d）" % CardLib.DEFAULT_LIMIT)

	var over := CardLib.blank_unit("limit_over")
	over["count"] = int(over.get("limit", 4)) + 1
	_check(not CardLib.validate_unit(over).is_empty(), "count 超过这张卡的 limit 被拦下")

	var strict := CardLib.blank_unit("limit_strict")
	strict["limit"] = 1
	strict["count"] = 2
	_check(not CardLib.validate_unit(strict).is_empty(), "limit=1 的卡带 2 张被拦下")

	strict["count"] = 1
	_check(CardLib.validate_unit(strict).is_empty(), "limit=1 的卡带 1 张合法")

	var zero := CardLib.blank_unit("limit_zero")
	zero["limit"] = 0
	_check(not CardLib.validate_unit(zero).is_empty(), "limit < 1 被拦下")
