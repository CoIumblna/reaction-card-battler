class_name UiTheme
extends RefCounted
## 【M4 界面基座】全局主题：中文字体 + 配色 + 控件样式。
##
## 为什么需要这个文件：
##   Godot 内置默认字体（Open Sans SemiBold）**没有中日韩字形**，
##   直接显示中文会变成一排方块（实测 ThemeDB.fallback_font.has_char("中") == false）。
##   解决办法是从系统里挑一款中文字体：SystemFont 会按 font_names 顺序
##   去操作系统里找第一个存在的字体（Windows 上通常是 Microsoft YaHei）。
##
## 为什么做成「静态函数」而不是 .tres 资源文件：
##   项目里还没有任何资源文件（没有 .tscn / .tres），M4 才建。
##   用代码生成主题的好处是：字体名列表能集中在这一处维护，
##   以后要换字体只改 FONT_NAMES，不用去编辑器里点。
##
## M4 的每一个场景都应该 `theme = UiTheme.make_theme()`，
## 这样配色和字体只有一处定义。

# ---------------------------------------------------------------- 配色

const BG := Color(0.086, 0.098, 0.125)          # 窗口底色
const PANEL := Color(0.137, 0.157, 0.196)       # 面板底色
const PANEL_HI := Color(0.180, 0.204, 0.251)    # 面板高亮（悬停/选中）
const LINE := Color(0.263, 0.298, 0.361)        # 分隔线
const TEXT := Color(0.898, 0.918, 0.957)        # 主文字
const TEXT_DIM := Color(0.596, 0.639, 0.718)    # 次要文字
const ACCENT := Color(0.353, 0.651, 1.0)        # 主强调色
const OK := Color(0.451, 0.851, 0.549)          # 通过 / 成功
const WARN := Color(1.0, 0.722, 0.251)          # 警告
const ERR := Color(1.0, 0.420, 0.400)           # 错误

## 卡牌元素配色：只有 6 个基础元素可选
const ELEMENT_COLORS := {
	"none": Color(0.482, 0.518, 0.588),      # 灰
	"fire": Color(0.925, 0.361, 0.278),      # 红
	"water": Color(0.286, 0.596, 0.925),     # 蓝
	"lightning": Color(0.639, 0.400, 0.925), # 紫（2026-11-26 由黄改紫，与火的橙红拉开）
	"ice": Color(0.451, 0.831, 0.898),       # 青
	"wind": Color(0.435, 0.831, 0.573),      # 绿
	"geo": Color(0.788, 0.627, 0.400),       # 土黄
}

# ---------------------------------------------------------------- 字号

const FONT_SM := 13
const FONT_MD := 15
const FONT_LG := 18
const FONT_XL := 22
const FONT_XXL := 30

## 中文字体候选：按顺序找第一个系统里存在的。
## Microsoft YaHei 是 Win7+ 自带；SimHei / SimSun 是老系统兜底；
## Noto Sans CJK / Source Han Sans 是 Linux/跨平台兜底。
const FONT_NAMES: Array[String] = [
	"Microsoft YaHei UI",
	"Microsoft YaHei",
	"SimHei",
	"Noto Sans CJK SC",
	"Source Han Sans SC",
	"PingFang SC",
	"sans-serif",
]


# ---------------------------------------------------------------- 字体

## 造一个能吃中文的字体对象
static func make_font() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(FONT_NAMES)
	f.allow_system_fallback = true
	return f


## 自检：这个字体真的能画中文吗？
## 返回空字符串 = 正常；否则返回人话原因。
static func font_health() -> String:
	var f := make_font()
	if not f.has_char("中".unicode_at(0)):
		return "字体 " + f.get_font_name() + " 不含中文字形，界面会显示成方块"
	return ""


## 元素配色。v3 起只有 6 个基础元素（复合元素 id 已删除，反应产物改成「两槽共存 + 状态」），
## 所以查不到的一律回落到灰。
static func element_color(element: String) -> Color:
	return ELEMENT_COLORS.get(element, ELEMENT_COLORS["none"])


# ---------------------------------------------------------------- 主题

static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = make_font()
	t.default_font_size = FONT_MD

	# 面板
	t.set_stylebox("panel", "PanelContainer", _sb(PANEL, 8, 1, LINE))
	t.set_stylebox("panel", "Panel", _sb(PANEL, 8, 1, LINE))

	# 按钮
	t.set_stylebox("normal", "Button", _sb(PANEL_HI, 6, 1, LINE))
	t.set_stylebox("hover", "Button", _sb(_mix(PANEL_HI, ACCENT, 0.28), 6, 1, ACCENT))
	t.set_stylebox("pressed", "Button", _sb(_mix(PANEL_HI, ACCENT, 0.5), 6, 1, ACCENT))
	t.set_stylebox("disabled", "Button", _sb(_mix(PANEL, BG, 0.5), 6, 1, LINE))
	t.set_stylebox("focus", "Button", _sb(Color(0, 0, 0, 0), 6, 1, ACCENT))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", TEXT_DIM)

	# 输入框
	t.set_stylebox("normal", "LineEdit", _sb(BG, 5, 1, LINE))
	t.set_stylebox("focus", "LineEdit", _sb(BG, 5, 1, ACCENT))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", TEXT_DIM)
	t.set_color("caret_color", "LineEdit", ACCENT)

	# 数字框
	t.set_stylebox("normal", "SpinBox", _sb(BG, 5, 1, LINE))
	t.set_color("font_color", "SpinBox", TEXT)

	# 列表
	t.set_stylebox("panel", "ItemList", _sb(BG, 6, 1, LINE))
	t.set_stylebox("selected", "ItemList", _sb(_mix(PANEL_HI, ACCENT, 0.35), 4, 0, LINE))
	t.set_stylebox("selected_focus", "ItemList", _sb(_mix(PANEL_HI, ACCENT, 0.45), 4, 0, ACCENT))
	t.set_stylebox("hovered", "ItemList", _sb(PANEL_HI, 4, 0, LINE))
	t.set_color("font_color", "ItemList", TEXT)
	t.set_color("font_selected_color", "ItemList", Color.WHITE)

	# 标签
	t.set_color("font_color", "Label", TEXT)

	# 选项按钮
	t.set_stylebox("normal", "OptionButton", _sb(BG, 5, 1, LINE))
	t.set_stylebox("hover", "OptionButton", _sb(PANEL_HI, 5, 1, ACCENT))
	t.set_stylebox("pressed", "OptionButton", _sb(PANEL_HI, 5, 1, ACCENT))
	t.set_stylebox("focus", "OptionButton", _sb(Color(0, 0, 0, 0), 5, 1, ACCENT))
	t.set_color("font_color", "OptionButton", TEXT)

	# 勾选框
	t.set_color("font_color", "CheckBox", TEXT)
	t.set_color("font_hover_color", "CheckBox", Color.WHITE)

	# 复选类控件用到的弹窗
	t.set_stylebox("panel", "PopupMenu", _sb(PANEL, 6, 1, LINE))
	t.set_color("font_color", "PopupMenu", TEXT)

	return t


static func _sb(fill: Color, radius: int, border: int, border_color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	if border > 0:
		sb.set_border_width_all(border)
		sb.border_color = border_color
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


static func _mix(a: Color, b: Color, t: float) -> Color:
	return a.lerp(b, t)


## 给「一个普通 Label」套上主题（构建代码里高频用到）
static func label(text: String, size: int = FONT_MD, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
