class_name CardView
extends PanelContainer
## 一张卡牌的外观（可复用组件）。
##
## 为什么放在 src/ui/ 而不是 tools/：
##   单位制作工具只是它的第一个使用者。M4 的手牌区、战场单位格、
##   卡组编辑器、商店……都要画「一张卡长什么样」。
##   如果画法写在单位制作工具里，M4 就会复制第二份，然后两份长得不一样。
##
## 它只做「显示」，不认识 Battle / Board / DataLoader，也不改任何数据。
## 输入统一是 Dictionary（cards.json 里的一张卡的形状），
## 所以既能显示「还没保存的草稿」，也能显示「文件里已有的卡」。
##
## 用法：
##   var v := CardView.new()
##   v.set_card({ "id": "tank", "name": "坦克", ... })

const CARD_W := 168
const CARD_H := 228

var _card: Dictionary = {}
var _title: Label
var _cost_label: Label
var _element_label: Label
var _stats: Label
var _class_label: Label
var _keywords_label: Label
var _count_label: Label
var _id_label: Label


func _init() -> void:
	custom_minimum_size = Vector2(CARD_W, CARD_H)
	# 只显示，不吃鼠标事件：放进列表/网格里不会挡住点击
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func _build() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	add_child(root)

	# ---- 顶部：费用圆 + 名字
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	root.add_child(top)

	_cost_label = UiTheme.label("1", UiTheme.FONT_XL, UiTheme.ACCENT)
	_cost_label.custom_minimum_size = Vector2(34, 0)
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_cost_label)

	_title = UiTheme.label("新单位", UiTheme.FONT_LG, UiTheme.TEXT)
	_title.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_title)

	var sep1 := HSeparator.new()
	root.add_child(sep1)

	# ---- 元素 + 兵科
	_element_label = UiTheme.label("无", UiTheme.FONT_MD, UiTheme.TEXT_DIM)
	root.add_child(_element_label)
	_class_label = UiTheme.label("步兵", UiTheme.FONT_SM, UiTheme.TEXT_DIM)
	root.add_child(_class_label)

	# ---- 中间留白（以后放卡图）
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 46)
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var sep2 := HSeparator.new()
	root.add_child(sep2)

	# ---- 攻击 / 防御
	_stats = UiTheme.label("攻 1   御 2", UiTheme.FONT_XL, UiTheme.TEXT)
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_stats)

	# ---- 关键词
	_keywords_label = UiTheme.label("", UiTheme.FONT_SM, UiTheme.WARN)
	_keywords_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_keywords_label)

	var sep3 := HSeparator.new()
	root.add_child(sep3)

	# ---- 脚注：id + 张数
	var foot := HBoxContainer.new()
	root.add_child(foot)
	_id_label = UiTheme.label("", UiTheme.FONT_SM, UiTheme.TEXT_DIM)
	_id_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_id_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	foot.add_child(_id_label)
	_count_label = UiTheme.label("×4", UiTheme.FONT_SM, UiTheme.TEXT_DIM)
	foot.add_child(_count_label)


## 换一张卡显示
func set_card(card: Dictionary) -> void:
	_card = card
	var element := str(card.get("element", "none"))
	var tint := UiTheme.element_color(element)

	# 卡面底色随元素走：一眼能分出火/水/雷
	var sb := get_theme_stylebox("panel")
	if sb is StyleBoxFlat:
		var flat: StyleBoxFlat = sb
		flat.bg_color = UiTheme.PANEL.lerp(tint, 0.18)
		flat.border_color = tint
		flat.set_border_width_all(2)
		flat.set_corner_radius_all(10)
		flat.content_margin_left = 10
		flat.content_margin_right = 10
		flat.content_margin_top = 8
		flat.content_margin_bottom = 8

	_cost_label.text = str(int(card.get("cost", 1)))
	_cost_label.add_theme_color_override("font_color", tint)

	var name := str(card.get("name", ""))
	_title.text = name if name != "" else "（未命名）"

	var etext := Element.display_name(element)
	if element != "none":
		_element_label.text = "元素：" + etext
		_element_label.add_theme_color_override("font_color", tint)
	else:
		_element_label.text = "元素：无"
		_element_label.add_theme_color_override("font_color", UiTheme.TEXT_DIM)

	var cls := str(card.get("unit_class", ""))
	_class_label.text = "兵科：" + str(CardLib.UNIT_CLASS_NAMES.get(cls, cls if cls != "" else "未标注"))

	_stats.text = "攻 %d   御 %d" % [int(card.get("attack", 0)), int(card.get("defense", 0))]

	var kws: Array[String] = []
	for kw in card.get("keywords", []):
		kws.append(str(CardLib.KEYWORD_NAMES.get(str(kw), str(kw))))
	_keywords_label.text = "、".join(kws) if not kws.is_empty() else ""

	_id_label.text = str(card.get("id", ""))
	_count_label.text = "×%d" % int(card.get("count", 1))
