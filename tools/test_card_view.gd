extends SceneTree

## CardView 的回归测试（2026-11-26 新增）
##
## 为什么需要这份测试：
## 旧版 CardView.set_card() 用
##     var sb := get_theme_stylebox("panel")
##     var flat: StyleBoxFlat = sb
##     flat.bg_color = ...
## 拿到的 `sb` 是**主题里那一份共享的** StyleBoxFlat（不是控件私有的），
## 于是「原地改颜色」等于改主题。单张预览完全看不出来；
## M4 手牌区一次显示 5 张时，最后一张会把前面所有卡刷成自己的颜色。
##
## 这类 bug 属于「肉眼单卡验证必漏、只有多实例同屏才暴露」的典型，
## 所以固定成自动化断言：3 个检查点全部围绕「是不是同一个对象」。

const EXPECTED_CHECKS := 7

func _initialize() -> void:
	print("=== CardView 多实例样式独立性 ===")
	_test_shared_stylebox_hazard()
	_test_multi_card_independence()
	_test_art_path_lookup()
	print("------------------------------------")
	if checks != EXPECTED_CHECKS:
		printerr("[FAIL] 覆盖不完整：实际跑了 %d 项，EXPECTED_CHECKS 声明 %d 项" % [checks, EXPECTED_CHECKS])
		quit(1)
		return
	print("共 %d 项检查，失败 %d 项" % [checks, fails])
	if fails > 0:
		printerr("FAIL")
		quit(1)
	else:
		print("PASS")
		quit(0)


var checks := 0
var fails := 0


func _check(cond: bool, msg: String) -> void:
	checks += 1
	if cond:
		print("  [ok] %s" % msg)
	else:
		fails += 1
		printerr("  [FAIL] %s" % msg)


## ① 先证明「隐患是真的」：主题分给两个控件的 panel stylebox 是同一个对象。
## 这一条如果哪天失效（Godot 改了行为），说明我们下面那套私有 override
## 是多余的，可以简化 —— 但在此之前它是必须的。
func _test_shared_stylebox_hazard() -> void:
	print("[1] 主题里的 StyleBox 是共享对象（隐患前提）")
	var th := UiTheme.make_theme()
	var a := PanelContainer.new()
	var b := PanelContainer.new()
	a.theme = th
	b.theme = th
	root.add_child(a)
	root.add_child(b)
	var sb_a := a.get_theme_stylebox("panel")
	var sb_b := b.get_theme_stylebox("panel")
	_check(is_same(sb_a, sb_b), "两个控件从主题拿到的是同一个 StyleBox 对象")
	_check(sb_a is StyleBoxFlat and sb_b is StyleBoxFlat, "主题给的是 StyleBoxFlat（可原地改色）")
	a.queue_free()
	b.queue_free()


## ② 真正要保证的：同屏 5 张不同元素的卡，底色必须各自不同、且不是同一对象。
func _test_multi_card_independence() -> void:
	print("[2] 同屏多张卡互不串色")
	var th := UiTheme.make_theme()
	var views: Array[CardView] = []
	var elements := ["fire", "water", "lightning", "ice", "wind"]
	for i in range(elements.size()):
		var v := CardView.new()
		v.theme = th
		root.add_child(v)
		v.set_card({
			"id": "probe_%d" % i, "name": "测试卡%d" % i, "type": "unit",
			"cost": i + 1, "element": elements[i],
			"attack": i, "defense": i + 1, "unit_class": "infantry", "count": 4,
		})
		views.append(v)

	var colors: Array[Color] = []
	for i in range(views.size()):
		var sb := views[i].get_theme_stylebox("panel")
		colors.append((sb as StyleBoxFlat).bg_color if sb is StyleBoxFlat else Color.BLACK)

	var first := colors[0]
	var same_count := 0
	for i in range(colors.size()):
		if colors[i].is_equal_approx(first):
			same_count += 1
	_check(same_count == 1, "5 张不同元素的卡，底色只有 1 种等于第一张（实际 %d 种，说明没有互相覆盖）" % same_count)

	var distinct := true
	for i in range(1, views.size()):
		if is_same(views[i].get_theme_stylebox("panel"), views[0].get_theme_stylebox("panel")):
			distinct = false
	_check(distinct, "每张卡持有自己的 StyleBoxFlat 实例（不是共用主题那一份）")

	# 反向验证：改最后一张，第一张的底色必须纹丝不动
	var before := (views[0].get_theme_stylebox("panel") as StyleBoxFlat).bg_color
	views[views.size() - 1].set_card({
		"id": "late", "name": "后设的", "type": "unit", "cost": 9,
		"element": "fire", "attack": 9, "defense": 9, "unit_class": "tank", "count": 1,
	})
	var after := (views[0].get_theme_stylebox("panel") as StyleBoxFlat).bg_color
	_check(before.is_equal_approx(after), "改最后一张卡的属性后，第一张卡底色不变")

	for v in views:
		v.queue_free()


## ③ 卡图查找约定：卡里有 image 字段就用它，否则按 id 找 assets/cards/<id>.png
func _test_art_path_lookup() -> void:
	print("[3] 卡图路径约定")
	_check(CardView.art_path_of({"id": "footman"}) == "res://assets/cards/footman.png",
		"没有 image 字段时按 id 拼 assets/cards/<id>.png")
	_check(CardView.art_path_of({"id": "footman", "image": "res://assets/cards/custom.png"})
		== "res://assets/cards/custom.png", "image 字段优先于 id 推导")
