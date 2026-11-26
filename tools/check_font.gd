extends SceneTree
## 中文字体体检：确认「界面能不能画中文」这个前提条件。
##
## 用法： $g --headless --path . --script res://tools/check_font.gd
##   退出码 0 = 能找到含中文字形的字体；1 = 找不到（界面会满屏方块）
##
## 为什么单独一个脚本：
##   Godot 内置默认字体（Open Sans SemiBold）没有中日韩字形。
##   如果字体配错了，程序不会报错 —— 只是所有中文变成方块。
##   这类「不报错的错」必须有一个能一条命令验证的检查点，
##   否则每次改界面都要靠肉眼开窗口看。
##
## 判定标准：has_char() 必须传「单个字符的码点」。
##   踩过的坑：直接传 "中" 这种字符串，GDScript 会做隐式转换，
##   结果与预期不符，必须写 "中".unicode_at(0)。

const PROBE := "中文渲染探针"


func _initialize() -> void:
	print("========== 中文字体体检 ==========")

	# 1. 引擎默认字体：预期「不含中文」，用来证明探针本身有效
	var fallback := ThemeDB.fallback_font
	var fallback_ok := fallback != null and fallback.has_char("中".unicode_at(0))
	print("  引擎默认字体 has_char(中) = ", fallback_ok)
	if fallback_ok:
		print("  [note] 默认字体居然含中文，下面的检查会失去区分度（不影响结论）")

	# 2. 我们实际要用的字体：UiTheme.make_font()
	var font := UiTheme.make_font()
	if font == null:
		printerr("[FONT FAIL] UiTheme.make_font() 返回 null")
		printerr("FAIL")
		quit(1)
		return

	var name := font.get_font_name()
	print("  UiTheme 选中字体 = ", name)

	var missing: Array[String] = []
	for i in range(PROBE.length()):
		var ch := PROBE.substr(i, 1)
		if not font.has_char(ch.unicode_at(0)):
			missing.append(ch)

	if not missing.is_empty():
		printerr("[FONT FAIL] 字体 %s 缺少这些字形：%s" % [name, "".join(missing)])
		printerr("  修法：改 src/ui/ui_theme.gd 的 FONT_NAMES，或在本机装一款中文字体")
		printerr("FAIL")
		quit(1)
		return

	# 3. 顺手报告候选列表里哪些真的存在，方便换机器时排查
	print("  候选字体命中情况：")
	for one in UiTheme.FONT_NAMES:
		var f := SystemFont.new()
		f.font_names = PackedStringArray([one])
		var hit := f.has_char("中".unicode_at(0))
		print("    %s%s" % [one, "  ← 可用" if hit else ""])

	print("[FONT OK] %s" % name)
	print("PASS")
	quit(0)
