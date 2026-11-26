class_name CardView
extends PanelContainer
## 一张卡牌的外观（可复用组件）。
##
## 为什么放在 src/ui/ 而不是 tools/：
##   单位制作工具只是它的第一个使用者。M4 的手牌区、战场单位格、
##   卡组编辑器……都要画「一张卡长什么样」。
##   如果画法写在单位制作工具里，M4 就会复制第二份，然后两份长得不一样。
##
## 版式参考 KARDS 的**结构**（不是抄素材）：
##   顶部 名字条 / 左上 费用徽标压住卡图角 / 中部 卡图区 /
##   卡图下 元素·兵科 / 关键词带 / 底部左攻右御 / 页脚 id×张数
##
## 卡图怎么来（约定优于配置）：
##   默认按 id 找 res://assets/cards/<id>.png；
##   卡字典里写了 "image" 字段则优先用它（相对 res:// 的完整路径）。
##   找不到图就显示占位框并把期望路径写出来 —— 这样作者一眼知道该往哪放。
##   注意：手放进 assets/ 的 png 需要引擎导入过（跑一次 --import，
##   或用编辑器打开项目），否则 ResourceLoader.exists() 会是 false。
##
## 它只做「显示」，不认识 Battle / Board / DataLoader，也不改任何数据。
## 输入统一是 Dictionary（cards.json 里的一张卡的形状），
## 所以既能显示「还没保存的草稿」，也能显示「文件里已有的卡」。
##
## 用法：
##   var v := CardView.new()
##   v.set_card({ "id": "tank", "name": "坦克", ... })

const CARD_W := 200
const CARD_H := 300

## 卡图目录（相对 res://）
const ART_DIR := "res://assets/cards/"

## 费用徽标直径
const BADGE := 34

var _card: Dictionary = {}

var _art: TextureRect
var _art_ph: Control          # 占位框（没图时显示）
var _art_hint: Label
var _badge: PanelContainer
var _badge_label: Label
var _name: Label
var _meta: Label
var _keywords: Label
var _atk_value: Label
var _def_value: Label
var _foot: Label

var _flat: StyleBoxFlat       # 本实例私有的卡面样式（不碰主题共享资源）


func _init() -> void:
	custom_minimum_size = Vector2(CARD_W, CARD_H)
	# 只显示，不吃鼠标事件：放进列表/网格里不会挡住点击
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


# ================================================================ 构建

func _build() -> void:
	# 关键：每个 CardView 自己一份 StyleBoxFlat。
	# 之前用 get_theme_stylebox("panel") 拿主题的共享对象再原地改颜色，
	# 单个预览看不出问题，但 M4 一手牌同时显示时，后一张会把前面全改掉。
	_flat = StyleBoxFlat.new()
	_flat.bg_color = UiTheme.PANEL
	_flat.set_corner_radius_all(10)
	_flat.set_border_width_all(2)
	_flat.border_color = UiTheme.LINE
	_flat.content_margin_left = 8
	_flat.content_margin_right = 8
	_flat.content_margin_top = 8
	_flat.content_margin_bottom = 8
	add_theme_stylebox_override("panel", _flat)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	add_child(box)

	# ---- 名字条（顶部整条）
	_name = UiTheme.label("新单位", UiTheme.FONT_LG, UiTheme.TEXT)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_name.custom_minimum_size = Vector2(0, 24)
	box.add_child(_name)

	# ---- 卡图区（费用徽标压住左上角）
	var frame := Control.new()
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.custom_minimum_size = Vector2(0, 150)
	frame.clip_contents = true
	box.add_child(frame)

	_art = TextureRect.new()
	_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.texture = null
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_art)

	_art_ph = Control.new()
	_art_ph.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art_ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_art_ph)

	var ph_bg := ColorRect.new()
	ph_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ph_bg.color = Color(0, 0, 0, 0.28)
	ph_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art_ph.add_child(ph_bg)

	_art_hint = UiTheme.label("卡图占位", UiTheme.FONT_SM, UiTheme.TEXT_DIM)
	_art_hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_art_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_art_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_art_hint.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_art_ph.add_child(_art_hint)

	# 费用徽标：压住卡图左上角（KARDS 那个大数字）
	_badge = PanelContainer.new()
	_badge.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_badge.position = Vector2(0, 0)
	_badge.custom_minimum_size = Vector2(BADGE, BADGE)
	_badge.size = Vector2(BADGE, BADGE)
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_badge)

	_badge_label = UiTheme.label("1", UiTheme.FONT_XL, Color.WHITE)
	_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_badge.add_child(_badge_label)

	# ---- 元素 · 兵科
	_meta = UiTheme.label("元素：无", UiTheme.FONT_SM, UiTheme.TEXT_DIM)
	_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_meta)

	# ---- 关键词带
	_keywords = UiTheme.label("", UiTheme.FONT_SM, UiTheme.WARN)
	_keywords.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_keywords.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	box.add_child(_keywords)

	var sep := HSeparator.new()
	box.add_child(sep)

	# ---- 底部：左攻 右御
	var stats := HBoxContainer.new()
	box.add_child(stats)

	_atk_value = _stat_block(stats, "攻", HORIZONTAL_ALIGNMENT_LEFT)
	var mid := Control.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(mid)
	_def_value = _stat_block(stats, "御", HORIZONTAL_ALIGNMENT_RIGHT)

	# ---- 页脚 id × 张数
	_foot = UiTheme.label("", UiTheme.FONT_SM, UiTheme.TEXT_DIM)
	_foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_foot.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(_foot)


## 底部一个数值块：小标签 + 大数字
func _stat_block(parent: Control, title: String, align: int) -> Label:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	parent.add_child(v)

	var t := UiTheme.label(title, UiTheme.FONT_SM, UiTheme.TEXT_DIM)
	t.horizontal_alignment = align
	v.add_child(t)

	var n := UiTheme.label("0", UiTheme.FONT_XXL, UiTheme.TEXT)
	n.horizontal_alignment = align
	v.add_child(n)
	return n


# ================================================================ 数据 → 外观

## 换一张卡显示
func set_card(card: Dictionary) -> void:
	_card = card
	var element := str(card.get("element", "none"))
	var tint := UiTheme.element_color(element)

	# 卡面底色随元素走：一眼能分出火/水/雷
	_flat.bg_color = UiTheme.PANEL.lerp(tint, 0.16)
	_flat.border_color = tint

	# 费用徽标：元素色实心 + 白字
	var badge_sb := StyleBoxFlat.new()
	badge_sb.bg_color = tint
	badge_sb.set_corner_radius_all(int(BADGE / 2))
	badge_sb.set_border_width_all(2)
	badge_sb.border_color = UiTheme.TEXT.lerp(tint, 0.3)
	badge_sb.content_margin_left = 0
	badge_sb.content_margin_right = 0
	badge_sb.content_margin_top = 0
	badge_sb.content_margin_bottom = 0
	_badge.add_theme_stylebox_override("panel", badge_sb)
	_badge_label.text = str(int(card.get("cost", 1)))

	var nm := str(card.get("name", ""))
	_name.text = nm if nm != "" else "（未命名）"
	_name.add_theme_color_override("font_color", UiTheme.TEXT)

	var etext := Element.display_name(element)
	_meta.text = ("元素：%s   " % etext if element != "none" else "元素：无   ") + _class_text(card)
	_meta.add_theme_color_override("font_color", tint if element != "none" else UiTheme.TEXT_DIM)

	# 卡图
	var art_path := art_path_of(card)
	var tex: Texture2D = null
	if ResourceLoader.exists(art_path):
		var res := load(art_path)
		if res is Texture2D:
			tex = res
	_art.texture = tex
	_art_ph.visible = tex == null
	_art.visible = tex != null
	if tex == null:
		# 只显示文件名，别把 res://assets/cards/ 这种前缀挤进来（会折成三行）
		_art_hint.text = "卡图占位\n" + art_path.get_file()
		_art_hint.tooltip_text = art_path

	# 关键词
	var kws: Array[String] = []
	for kw in card.get("keywords", []):
		kws.append(str(CardLib.KEYWORD_NAMES.get(str(kw), str(kw))))
	_keywords.text = "、".join(kws) if not kws.is_empty() else " "
	_keywords.add_theme_color_override("font_color", UiTheme.WARN)

	_atk_value.text = str(int(card.get("attack", 0)))
	_def_value.text = str(int(card.get("defense", 0)))

	_foot.text = "%s  ×%d" % [str(card.get("id", "")), int(card.get("count", 1))]


## 这张卡该去哪找图：卡里写了 "image" 就用它，否则按 id 约定
static func art_path_of(card: Dictionary) -> String:
	var custom := str(card.get("image", "")).strip_edges()
	if custom != "":
		return custom if custom.begins_with("res://") else "res://" + custom
	var id := str(card.get("id", "")).strip_edges()
	if id == "":
		return ""
	return ART_DIR + id + ".png"


func _class_text(card: Dictionary) -> String:
	var cls := str(card.get("unit_class", ""))
	var cn := str(CardLib.UNIT_CLASS_NAMES.get(cls, cls if cls != "" else "未标注"))
	return "兵科：" + cn


## 自检/测试用：底部两个数字的文本（原来叫 _stats，改版后拆成两个控件）
func stats_text() -> String:
	return "攻 %s   御 %s" % [_atk_value.text, _def_value.text]
