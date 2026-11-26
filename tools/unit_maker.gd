extends Control
## 单位卡图形制作工具（M4 界面基座的第一块砖）。
##
## 启动：
##   直接双击 tools\unit_maker.bat
##   或  godot --path . tools/unit_maker.tscn
##
## 想批量验证界面有没有画对（CI / 我自己核对时用）：
##   godot --path . tools/unit_maker.tscn -- --shot=G:/tmp/maker.png --shot-frames=8
##
## 它做什么：
##   左栏列出 cards.json 里所有单位卡 → 点一张就载入中栏预览 + 右栏表单
##   → 改字段 → Ctrl+S（或按钮）写回 cards.json
##   新增 / 覆盖 / 重命名 / 删除 四种写回，全部走 tools/card_lib.gd
##
## 它与 M4 的关系（这是关键设计）：
##   中栏预览用的是 src/ui/card_view.gd —— M4 手牌区将来显示的就是同一个组件。
##   所以在这里调好的「卡面长相」，M4 里不用重做；反过来 M4 改了卡面，
##   这里立刻跟着变。配色与字体来自 src/ui/ui_theme.gd，也只有一份。
##
## 它不做什么：不参战、不校验平衡、不碰 decks/*.json。

const LIST_W := 220
const FORM_W := 300
const PREVIEW_W := 200

## 未保存时窗口标题加 *，避免误关
const BASE_TITLE := "单位卡制作工具"

var _cards: Array = []            # cards.json 里的全部卡（含指令卡）
var _unit_ids: Array[String] = [] # 只挑 type == "unit" 的 id，供列表显示
var _original_id := ""            # 载入时的 id（用来判断是「覆盖」还是「改名」）
var _is_new := true               # 当前表单是不是一张还没存过的新卡
var _dirty := false
var _saving := false              # 防止保存过程中的信号回调把状态弄乱

# ---- 左栏
var _list: ItemList
var _filter: LineEdit
# ---- 中栏
var _preview: CardView
# ---- 右栏表单
var _f_id: LineEdit
var _f_name: LineEdit
var _f_cost: SpinBox
var _f_attack: SpinBox
var _f_defense: SpinBox
var _f_opcost: SpinBox
var _f_count: SpinBox
var _f_element: OptionButton
var _f_class: OptionButton
var _kw_blitz: CheckBox
var _kw_guard: CheckBox
# ---- 底部
var _status: Label
var _errors: RichTextLabel
var _save_btn: Button


func _ready() -> void:
	theme = UiTheme.make_theme()
	get_window().title = BASE_TITLE
	_build_ui()
	_reload()
	if not _handle_selftest():
		_handle_shot_mode()


# ================================================================ 界面

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 8)
	outer.offset_left = 12
	outer.offset_top = 10
	outer.offset_right = -12
	outer.offset_bottom = -10
	add_child(outer)

	outer.add_child(_build_header())

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(body)

	body.add_child(_build_left())
	body.add_child(_build_center())
	body.add_child(_build_right())

	outer.add_child(_build_footer())


func _build_header() -> Control:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)

	head.add_child(UiTheme.label("单位卡制作", UiTheme.FONT_XL, UiTheme.TEXT))
	head.add_child(UiTheme.label(
		"左栏选卡 → 中栏预览（这就是 M4 手牌的样子）→ 右栏改数值 → Ctrl+S 保存",
		UiTheme.FONT_SM, UiTheme.TEXT_DIM
	))

	var spring := Control.new()
	spring.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spring)

	var reload := Button.new()
	reload.text = "重新读取"
	reload.pressed.connect(_on_reload_pressed)
	head.add_child(reload)
	return head


func _build_left() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(LIST_W, 0)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	box.add_child(UiTheme.label("单位卡列表", UiTheme.FONT_MD, UiTheme.TEXT_DIM))

	_filter = LineEdit.new()
	_filter.placeholder_text = "按 id / 名字筛选"
	_filter.text_changed.connect(_on_filter_changed)
	box.add_child(_filter)

	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_list_selected)
	box.add_child(_list)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	box.add_child(btn_row)

	var add := Button.new()
	add.text = "新建"
	add.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add.pressed.connect(_on_new_pressed)
	btn_row.add_child(add)

	var dup := Button.new()
	dup.text = "复制"
	dup.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dup.pressed.connect(_on_duplicate_pressed)
	btn_row.add_child(dup)

	var del := Button.new()
	del.text = "删除"
	del.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	del.pressed.connect(_on_delete_pressed)
	btn_row.add_child(del)

	return panel


func _build_center() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PREVIEW_W + 40, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	box.add_child(UiTheme.label("卡面预览", UiTheme.FONT_MD, UiTheme.TEXT_DIM))

	var holder := CenterContainer.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(holder)

	_preview = CardView.new()
	holder.add_child(_preview)

	var hint := UiTheme.label("颜色随元素变化\n保存后 M4 手牌区显示的就是这个样子", UiTheme.FONT_SM, UiTheme.TEXT_DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)

	return panel


func _build_right() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(FORM_W, 0)

	# 字段较多，小窗口下必须能滚，否则底部关键词和保存提示会被裁掉
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)

	box.add_child(UiTheme.label("字段", UiTheme.FONT_MD, UiTheme.TEXT_DIM))

	_f_id = _add_line(box, "id（小写字母/数字/下划线）")
	_f_name = _add_line(box, "名字（中文随便写）")
	_f_cost = _add_spin(box, "费用 cost（1–12）", 1, 12)
	_f_attack = _add_spin(box, "攻击 attack（≥0）", 0, 30)
	_f_defense = _add_spin(box, "防御 defense（≥1）", 1, 30)
	_f_opcost = _add_spin(box, "行动费 operation_cost", 0, 5)
	_f_count = _add_spin(box, "牌组张数 count（1–4）", 1, 4)
	_f_element = _add_option(box, "元素 element")
	_f_class = _add_option(box, "兵科 unit_class")

	for e in CardLib.ELEMENTS:
		_f_element.add_item(Element.display_name(str(e)))
	for c in CardLib.UNIT_CLASSES:
		_f_class.add_item(str(CardLib.UNIT_CLASS_NAMES.get(str(c), str(c))))

	box.add_child(UiTheme.label("关键词 keywords", UiTheme.FONT_SM, UiTheme.TEXT_DIM))
	var kw_row := HBoxContainer.new()
	kw_row.add_theme_constant_override("separation", 12)
	box.add_child(kw_row)
	_kw_blitz = CheckBox.new()
	_kw_blitz.text = "闪击 blitz"
	_kw_blitz.toggled.connect(_on_field_changed)
	kw_row.add_child(_kw_blitz)
	_kw_guard = CheckBox.new()
	_kw_guard.text = "护卫 guard"
	_kw_guard.toggled.connect(_on_field_changed)
	kw_row.add_child(_kw_guard)

	var spring := Control.new()
	spring.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spring)

	box.add_child(UiTheme.label("改动后按 Ctrl+S 保存", UiTheme.FONT_SM, UiTheme.TEXT_DIM))

	return panel


func _build_footer() -> Control:
	var foot := VBoxContainer.new()
	foot.add_theme_constant_override("separation", 6)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	foot.add_child(row)

	_save_btn = Button.new()
	_save_btn.text = "保存到 cards.json（Ctrl+S）"
	_save_btn.pressed.connect(_on_save_pressed)
	row.add_child(_save_btn)

	_status = UiTheme.label("", UiTheme.FONT_SM, UiTheme.TEXT_DIM)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_status)

	_errors = RichTextLabel.new()
	_errors.bbcode_enabled = true
	_errors.fit_content = true
	_errors.custom_minimum_size = Vector2(0, 46)
	_errors.scroll_active = false
	foot.add_child(_errors)

	return foot


func _add_line(parent: Control, label_text: String) -> LineEdit:
	parent.add_child(UiTheme.label(label_text, UiTheme.FONT_SM, UiTheme.TEXT_DIM))
	var le := LineEdit.new()
	le.text_changed.connect(_on_field_changed)
	parent.add_child(le)
	return le


func _add_spin(parent: Control, label_text: String, lo: int, hi: int) -> SpinBox:
	parent.add_child(UiTheme.label(label_text, UiTheme.FONT_SM, UiTheme.TEXT_DIM))
	var sb := SpinBox.new()
	sb.min_value = lo
	sb.max_value = hi
	sb.step = 1
	sb.value_changed.connect(_on_field_changed)
	parent.add_child(sb)
	return sb


func _add_option(parent: Control, label_text: String) -> OptionButton:
	parent.add_child(UiTheme.label(label_text, UiTheme.FONT_SM, UiTheme.TEXT_DIM))
	var ob := OptionButton.new()
	ob.item_selected.connect(_on_field_changed)
	parent.add_child(ob)
	return ob


# ================================================================ 数据流

func _reload() -> void:
	var r := CardLib.read()
	if not bool(r["ok"]):
		_set_status("读取失败：" + str(r["error"]), UiTheme.ERR)
		_errors.text = "[color=#ff6b66]%s[/color]" % str(r["error"])
		return
	_cards = r["cards"]
	_refresh_list()
	# 启动时自动选中第一张单位卡，免得表单空着让人以为坏了
	if _f_id.text.strip_edges() == "" and _unit_ids.size() > 0 and _list.get_selected_items().is_empty():
		_list.select(0)
		_on_list_selected(0)
	_set_status("已载入 %d 种卡（其中单位卡 %d 种）" % [_cards.size(), _unit_ids.size()], UiTheme.TEXT_DIM)


func _refresh_list() -> void:
	var keep := _f_id.text if _f_id != null else ""
	_unit_ids.clear()
	_list.clear()
	var needle := _filter.text.strip_edges().to_lower() if _filter != null else ""
	for c in _cards:
		if typeof(c) != TYPE_DICTIONARY:
			continue
		if str(c.get("type", "")) != "unit":
			continue
		var id := str(c.get("id", ""))
		var nm := str(c.get("name", ""))
		if needle != "" and not (id.to_lower().contains(needle) or nm.to_lower().contains(needle)):
			continue
		_unit_ids.append(id)
		_list.add_item("%s  (%s)" % [nm, id])
	for i in range(_unit_ids.size()):
		if _unit_ids[i] == keep:
			_list.select(i)
			break


## 表单 → 卡字典
func _form_to_card() -> Dictionary:
	var card := {}
	card["id"] = _f_id.text.strip_edges()
	card["name"] = _f_name.text.strip_edges()
	card["type"] = "unit"
	card["cost"] = int(_f_cost.value)
	card["element"] = str(CardLib.ELEMENTS[int(_f_element.selected)])
	card["attack"] = int(_f_attack.value)
	card["defense"] = int(_f_defense.value)
	card["operation_cost"] = int(_f_opcost.value)
	card["unit_class"] = str(CardLib.UNIT_CLASSES[int(_f_class.selected)])
	card["count"] = int(_f_count.value)
	var kws: Array[String] = []
	if _kw_blitz.button_pressed:
		kws.append("blitz")
	if _kw_guard.button_pressed:
		kws.append("guard")
	if not kws.is_empty():
		card["keywords"] = kws
	return card


## 卡字典 → 表单
func _card_to_form(card: Dictionary) -> void:
	_saving = true
	_f_id.text = str(card.get("id", ""))
	_f_name.text = str(card.get("name", ""))
	_f_cost.value = int(card.get("cost", 1))
	_f_attack.value = int(card.get("attack", 0))
	_f_defense.value = int(card.get("defense", 1))
	_f_opcost.value = int(card.get("operation_cost", 1))
	_f_count.value = int(card.get("count", 1))
	var element := str(card.get("element", "none"))
	var ei := CardLib.ELEMENTS.find(element)
	_f_element.select(ei if ei >= 0 else 0)
	var cls := str(card.get("unit_class", ""))
	var ci := CardLib.UNIT_CLASSES.find(cls)
	_f_class.select(ci if ci >= 0 else 0)
	var kws: Array = card.get("keywords", [])
	_kw_blitz.button_pressed = kws.has("blitz")
	_kw_guard.button_pressed = kws.has("guard")
	_saving = false
	_refresh_preview()


func _refresh_preview() -> void:
	_preview.set_card(_form_to_card())


## 当前表单的校验问题（查重时把自己排除掉）
func _current_errors() -> Array[String]:
	var card := _form_to_card()
	var taken: Array[String] = []
	for id in CardLib.collect_ids(_cards):
		if id != _original_id:
			taken.append(id)
	if _is_new and _original_id == "":
		pass
	return CardLib.validate_unit(card, taken)


func _on_field_changed(_x = null) -> void:
	if _saving:
		return
	_dirty = true
	_refresh_preview()
	_refresh_validation()


func _refresh_validation() -> void:
	var errs := _current_errors()
	if errs.is_empty():
		_errors.text = "[color=#73d98c]校验通过[/color]"
		_save_btn.disabled = false
	else:
		var lines: Array[String] = []
		for e in errs:
			lines.append("• " + str(e))
		_errors.text = "[color=#ff6b66]%s[/color]" % "\n".join(lines)
		_save_btn.disabled = true
	get_window().title = BASE_TITLE + ("  *" if _dirty else "")


# ================================================================ 交互

func _on_filter_changed(_t: String) -> void:
	_refresh_list()


func _on_list_selected(index: int) -> void:
	if index < 0 or index >= _unit_ids.size():
		return
	var id := _unit_ids[index]
	var card := CardLib.find_card(_cards, id)
	if card.is_empty():
		return
	_original_id = id
	_is_new = false
	_dirty = false
	_card_to_form(card)
	_refresh_validation()
	_set_status("已载入 " + id, UiTheme.TEXT_DIM)


func _on_new_pressed() -> void:
	var used := CardLib.collect_ids(_cards)
	var n := 1
	while used.has("new_unit_%d" % n):
		n += 1
	var card := CardLib.blank_unit("new_unit_%d" % n)
	_original_id = ""
	_is_new = true
	_dirty = true
	_card_to_form(card)
	_refresh_validation()
	_list.deselect_all()
	_set_status("新卡（还没写进文件）", UiTheme.WARN)


func _on_duplicate_pressed() -> void:
	var card := _form_to_card()
	var used := CardLib.collect_ids(_cards)
	var base := str(card.get("id", "unit"))
	var n := 2
	var new_id := "%s_%d" % [base, n]
	while used.has(new_id):
		n += 1
		new_id = "%s_%d" % [base, n]
	card["id"] = new_id
	card["name"] = str(card.get("name", "")) + " 副本"
	_original_id = ""
	_is_new = true
	_dirty = true
	_card_to_form(card)
	_refresh_validation()
	_list.deselect_all()
	_set_status("已复制为 " + new_id + "（还没写进文件）", UiTheme.WARN)


func _on_delete_pressed() -> void:
	if _is_new or _original_id == "":
		_set_status("当前不是已保存的卡，没有可删的", UiTheme.WARN)
		return
	var err := CardLib.delete_card(CardLib.CARDS_PATH, _original_id)
	if err != "":
		_set_status("删除失败：" + err, UiTheme.ERR)
		return
	_set_status("已删除 " + _original_id, UiTheme.OK)
	_original_id = ""
	_is_new = true
	_dirty = false
	_reload()


func _on_reload_pressed() -> void:
	if _dirty:
		_set_status("有未保存改动，已放弃", UiTheme.WARN)
	_dirty = false
	_reload()
	_refresh_validation()


func _on_save_pressed() -> void:
	_save()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.ctrl_pressed:
		if event.keycode == KEY_S:
			_save()
			accept_event()


func _save() -> void:
	if _save_btn.disabled:
		_set_status("校验没通过，先修字段", UiTheme.ERR)
		return
	var card := _form_to_card()
	var id := str(card.get("id", ""))
	var mode := ""
	if _is_new:
		mode = "insert"
	elif id != _original_id:
		# 改名 = 删旧 + 插新。先确认新 id 不撞车（validate 已查过）
		var del_err := CardLib.delete_card(CardLib.CARDS_PATH, _original_id)
		if del_err != "":
			_set_status("改名失败（删旧卡时）：" + del_err, UiTheme.ERR)
			return
		mode = "insert"
	else:
		mode = "replace"

	var err := CardLib.save_card(CardLib.CARDS_PATH, card, mode)
	if err != "":
		_set_status("保存失败：" + err, UiTheme.ERR)
		_errors.text = "[color=#ff6b66]%s[/color]" % err
		return

	_original_id = id
	_is_new = false
	_dirty = false
	_set_status("已保存 " + id, UiTheme.OK)
	_reload()
	_refresh_validation()


func _set_status(text: String, color: Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)


# ================================================================ 截图模式（验证用）

## --shot=路径 --shot-frames=N ：开窗口、等 N 帧、把界面存成 PNG、退出。
## 这是「界面到底画出来没有」的机器验证手段：
##   godot --path . tools/unit_maker.tscn -- --shot=G:/tmp/x.png
func _handle_shot_mode() -> void:
	var path := ""
	var frames := 8
	for raw in OS.get_cmdline_user_args():
		var a := str(raw)
		if a.begins_with("--shot="):
			path = a.substr(7)
		elif a.begins_with("--shot-frames="):
			frames = int(a.substr(14))
	if path == "":
		return
	_do_shot(path, frames)


func _do_shot(path: String, frames: int) -> void:
	for i in range(frames):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	if err == OK:
		print("SHOT ok ", path, " ", img.get_width(), "x", img.get_height())
		get_tree().quit(0)
	else:
		printerr("SHOT failed err=", err)
		get_tree().quit(1)


# ================================================================ 自检模式（验证用）

## --selftest ：用代码驱动**真实的这个界面**走一遍「选卡 → 改字段 → 保存 → 新建 → 删除」，
## 每一步都读回 cards.json 断言真的写对了，最后把文件还原。
##
## 这是这套工具唯一的「点得动」验证手段：
##   截图只能证明画出来了；这个能证明信号连接、校验、写回、刷新整条链路都通。
## 用法：
##   godot --path . tools/unit_maker.tscn -- --selftest
const SELFTEST_CHECKS := 30

var _st_checks := 0
var _st_fails := 0


func _handle_selftest() -> bool:
	var want := false
	for raw in OS.get_cmdline_user_args():
		if str(raw) == "--selftest":
			want = true
	if not want:
		return false
	_run_selftest()
	return true


func _st(cond: bool, msg: String) -> void:
	_st_checks += 1
	if cond:
		print("  [ok] " + msg)
	else:
		_st_fails += 1
		printerr("  [FAIL] " + msg)


func _run_selftest() -> void:
	print("========== 单位卡工具 自检 ==========")
	var backup := FileAccess.get_file_as_string(CardLib.CARDS_PATH)
	_st(backup.length() > 0, "起步：能读到 cards.json 原文（%d 字节）" % backup.length())
	# 真数据里现有多少种卡。**不写死数字** —— M3.4 卡池在扩（目标 20+ 种），
	# 写死 11 会让「学员用工具正常加了一张卡」也被判成工具坏了。
	var base_count := CardLib.collect_ids(CardLib.read()["cards"]).size()

	# ---- 1. 选卡 → 表单被填充
	_st(_unit_ids.size() >= 4, "列表里有 %d 张单位卡" % _unit_ids.size())
	_list.select(0)
	_on_list_selected(0)
	var id0 := _f_id.text
	_st(id0 == "footman", "选第一张 → 表单载入 footman（实际 %s）" % id0)
	_st(int(_f_defense.value) == 2, "载入的 defense = 2（实际 %d）" % int(_f_defense.value))
	_st(_preview != null, "预览控件存在")

	# ---- 2. 改字段 → 预览跟着变 → 校验通过
	_f_attack.value = 7
	_on_field_changed()
	_st(_preview._stats.text.contains("攻 7"), "改 attack 7 → 卡面预览同步（%s）" % _preview._stats.text)
	_st(not _save_btn.disabled, "合法值 → 保存按钮可用")

	# ---- 3. 保存 → 文件真的变了
	_on_save_pressed()
	var r1 := CardLib.read()
	var c1 := CardLib.find_card(r1["cards"], "footman")
	_st(int(c1.get("attack", 0)) == 7, "保存后文件里 footman.attack = 7（实际 %d）" % int(c1.get("attack", 0)))
	_st(int(c1.get("defense", 0)) == 2, "没动的字段没丢：defense 仍 2")
	_st(bool(r1["ok"]), "保存后 JSON 仍合法")
	_st(r1["cards"].size() == base_count, "条数没变（%d）" % base_count)

	# ---- 4. 非法值 → 保存被拦
	# 注意：defense/cost/count 这些走 SpinBox，min_value 已经把下界卡死了，
	# 所以「输入非法」只能从 LineEdit 进来（名字清空、id 带非法字符）。
	_f_name.text = ""
	_on_field_changed()
	_st(_save_btn.disabled, "名字清空 → 保存按钮被禁用")
	_st(_errors.text.contains("名字"), "错误提示点出名字的问题")
	_f_name.text = "步兵"
	_on_field_changed()

	# SpinBox 的下界是硬的：把 defense 设成 0，控件会自己钳到 1
	_f_defense.value = 0
	_st(int(_f_defense.value) == 1, "SpinBox 把 defense=0 钳到 1（控件层就挡住了非法值）")
	_f_defense.value = 2
	_on_field_changed()

	_f_id.text = "Foot man"
	_on_field_changed()
	_st(_save_btn.disabled, "id 含空格 → 保存被拦")
	_st(_errors.text.contains("id"), "错误提示点出 id 的问题")
	_f_id.text = "footman"
	_on_field_changed()
	_st(not _save_btn.disabled, "改回合法 id → 恢复可保存")

	# ---- 5. id 撞车 → 被拦
	_f_id.text = "tank"
	_on_field_changed()
	_st(_save_btn.disabled, "id 改成已存在的 tank → 保存被拦")
	_f_id.text = "footman"
	_on_field_changed()
	_st(not _save_btn.disabled, "改回 footman → 恢复可保存")

	# ---- 6. 新建 → 保存 → 文件多一条 → 删除 → 文件恢复
	_on_new_pressed()
	_st(_is_new, "点了新建 → 标记为新卡")
	_st(_original_id == "", "新卡的 original_id 为空")
	_f_id.text = "zz_selftest"
	_f_name.text = "自检单位"
	_f_cost.value = 3
	_f_attack.value = 2
	_f_defense.value = 4
	_f_count.value = 2
	_on_field_changed()
	_st(not _save_btn.disabled, "新卡字段合法 → 可保存")
	_on_save_pressed()
	var r2 := CardLib.read()
	_st(r2["cards"].size() == base_count + 1, "保存新卡 → 条数 %d（实际 %d）" % [base_count + 1, r2["cards"].size()])
	var c2 := CardLib.find_card(r2["cards"], "zz_selftest")
	_st(str(c2.get("name", "")) == "自检单位", "新卡名字写对")
	_st(int(c2.get("count", 0)) == 2, "新卡 count 写对")
	_st(not _is_new, "保存后不再标记为新卡")

	_on_delete_pressed()
	var r3 := CardLib.read()
	_st(r3["cards"].size() == base_count, "删除后条数回到 %d（实际 %d）" % [base_count, r3["cards"].size()])
	_st(CardLib.find_card(r3["cards"], "zz_selftest").is_empty(), "zz_selftest 已消失")

	# ---- 收尾：把文件还原成自检前的样子
	var werr := CardLib.write_text(CardLib.CARDS_PATH, backup)
	_st(werr == "", "还原 cards.json（%s）" % werr)
	var r4 := CardLib.read()
	var c4 := CardLib.find_card(r4["cards"], "footman")
	_st(int(c4.get("attack", 0)) == 1, "还原后 footman.attack 回到 1（实际 %d）" % int(c4.get("attack", 0)))

	print("------------------------------------")
	if _st_checks != SELFTEST_CHECKS:
		printerr("[FAIL] 覆盖不完整：实际 %d 项，SELFTEST_CHECKS = %d" % [_st_checks, SELFTEST_CHECKS])
		_st_fails += 1
	if _st_fails == 0:
		print("共 %d 项检查，失败 0 项" % _st_checks)
		print("PASS")
		get_tree().quit(0)
	else:
		printerr("共 %d 项检查，失败 %d 项" % [_st_checks, _st_fails])
		printerr("FAIL")
		get_tree().quit(1)
