extends SceneTree
## M3.5 卡组构筑（39 张 + 1 HQ）验收测试 —— 待实现
##
## 运行：
##   ... --headless --path . --script res://tests/pending/deck_build_test.gd
##
## 规格：docs/implementation-tasks.md §34
## API 约定：_load_deck(path: String) -> Array[Card]
##   - 合法：展开成 39 张 Card（按 count 重复）
##   - 非法（未知 id / count<=0 / 总数不是 39 / 同名超过 4）→ push_error + 返回空数组，不崩
##
## 【启用方式】M3.5 全绿后移到 tests/ 下。

var failures: int = 0
var checks: int = 0
var table: ReactionTable

const EXPECTED_CHECKS := 11


func _initialize() -> void:
	print("========== 卡组构筑测试（M3.5） ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	_test_api_exists()
	_test_load_player_deck()
	_test_enemy_deck_independent()
	_test_invalid_decks()

	if checks != EXPECTED_CHECKS:
		printerr("  [FAIL] 覆盖不完整：本文件应执行 %d 项检查，实际 %d 项" % [EXPECTED_CHECKS, checks])
		failures += 1

	print("---------------------------------------")
	print("共 %d 项检查，失败 %d 项" % [checks, failures])
	if failures == 0:
		print("PASS")
		quit(0)
	else:
		print("FAIL")
		quit(1)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("  [ok]   %s" % message)
	else:
		failures += 1
		printerr("  [FAIL] %s" % message)


func _check_eq(actual, expected, message: String) -> void:
	_check(actual == expected, "%s（期望 %s，实际 %s）" % [message, str(expected), str(actual)])


func _has_load_deck() -> bool:
	return DataLoader.new().has_method("load_deck")


## 用实例 call 而不是直接 _load_deck()：方法还没实现时直接静态调用会编译报错。
func _load_deck(path: String) -> Array:
	var dl = DataLoader.new()
	if not dl.has_method("load_deck"):
		return []
	var res = dl.call("load_deck", path)
	if typeof(res) == TYPE_ARRAY:
		return res
	return []


func _count_by_id(cards: Array) -> Dictionary:
	var out := {}
	for c in cards:
		var id := str(c.id)
		out[id] = int(out.get(id, 0)) + 1
	return out


func _write_user_deck(name: String, entries: Array) -> String:
	var path := "user://test_deck_%s.json" % name
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({ "name": name, "cards": entries }))
	f.close()
	return path


# ---------------------------------------------------------------- 用例

func _test_api_exists() -> void:
	print("[1] API：DataLoader.load_deck")
	_check(_has_load_deck(), "DataLoader 有 load_deck(path) 方法")


func _test_load_player_deck() -> void:
	print("[2] 加载玩家牌组（39 张）")
	if not _has_load_deck():
		# 跳过分支的条数必须和正常分支一致，否则未实现时项数偏少、
		# PART 1.5 的 checks 数就对不上 EXPECTED_CHECKS（2026-11-25 修）。
		for i in range(3):
			_check(false, "还没有 load_deck，跳过")
		return
	var deck: Array = _load_deck("res://data/decks/player_deck.json")
	_check_eq(deck.size(), 39, "牌组展开后 39 张（HQ 不进牌库）")
	var counts := _count_by_id(deck)
	_check_eq(int(counts.get("footman", 0)), 4, "同名卡展开正确（footman 4 张）")
	_check_eq(int(counts.get("guard", 0)), 3, "同名卡展开正确（guard 3 张）")


func _test_enemy_deck_independent() -> void:
	print("[3] 敌方牌组独立加载")
	if not _has_load_deck():
		for i in range(3):
			_check(false, "跳过")
		return
	var p: Array = _load_deck("res://data/decks/player_deck.json")
	var e: Array = _load_deck("res://data/decks/enemy_deck.json")
	_check_eq(e.size(), 39, "敌方牌组也是 39 张")
	# 用 is_same 判引用同一性。不能写 `p != e`：那是内容比较，双方都是 39 张时恒 true；
	# 也不能写 `p != e or p.size() == e.size()`：后半句恒真，整条断言永远通过（2026-11-25 修）。
	_check(not is_same(p, e), "两次加载不是同一个数组引用")
	_check(not is_same(p[0], e[0]), "展开后的 Card 对象也不共享引用")


func _test_invalid_decks() -> void:
	print("[4] 非法牌组：push_error + 返回空数组")
	if not _has_load_deck():
		for i in range(4):
			_check(false, "跳过")
		return
	var bad_id := _write_user_deck("bad_id", [{ "id": "no_such_card", "count": 39 }])
	_check_eq(_load_deck(bad_id).size(), 0, "未知卡 id → 空数组")

	# 下面三条都必须「只违反一条规则」，否则断言会因为别的原因通过（假绿）。
	# 2026-11-26 修：原 bad_dup 写 [{footman,5},{archer,34}]，两条都超同名上限，
	# 把上限放宽到 5 后 archer 34 仍然触发拦截 → 断言照旧绿，等于没测「同名上限」。
	# 原 bad_count 写 [{footman,0}]，count 0 让总数变成 0 → 连「总数必须 39」也一起违反。

	# 只违反「总数」：每个 id 合法、同名都不超 4，合计 37。
	var bad_total := _write_user_deck("bad_total", [
		{ "id": "footman", "count": 4 },
		{ "id": "archer", "count": 4 },
		{ "id": "fire_mage", "count": 4 },
		{ "id": "tank", "count": 4 },
		{ "id": "fire_bolt", "count": 4 },
		{ "id": "water_blade", "count": 4 },
		{ "id": "thunder_strike", "count": 4 },
		{ "id": "heavy_strike", "count": 4 },
		{ "id": "guard", "count": 3 },
		{ "id": "mend", "count": 2 }])          # 合计 37 张
	_check_eq(_load_deck(bad_total).size(), 0, "总张数不是 39 → 空数组")

	# 只违反「count 必须 > 0」：其余 10 种卡凑满 39 张，每个 id 合法、同名都不超 4。
	var bad_count := _write_user_deck("bad_count", [
		{ "id": "footman", "count": 0 },
		{ "id": "archer", "count": 4 },
		{ "id": "fire_mage", "count": 4 },
		{ "id": "tank", "count": 4 },
		{ "id": "fire_bolt", "count": 4 },
		{ "id": "water_blade", "count": 4 },
		{ "id": "thunder_strike", "count": 4 },
		{ "id": "heavy_strike", "count": 4 },
		{ "id": "guard", "count": 4 },
		{ "id": "mend", "count": 4 },
		{ "id": "fire_burst", "count": 3 }])    # 0 + 4×9 + 3 = 39 张，只违反 count<=0
	_check_eq(_load_deck(bad_count).size(), 0, "count <= 0 → 空数组")

	# 只违反「同名上限 4」：footman 5 张，其余凑满 34，每个 id 合法、总数正好 39。
	var bad_dup := _write_user_deck("bad_dup", [
		{ "id": "footman", "count": 5 },
		{ "id": "archer", "count": 4 },
		{ "id": "fire_mage", "count": 4 },
		{ "id": "tank", "count": 4 },
		{ "id": "fire_bolt", "count": 4 },
		{ "id": "water_blade", "count": 4 },
		{ "id": "thunder_strike", "count": 4 },
		{ "id": "heavy_strike", "count": 4 },
		{ "id": "guard", "count": 4 },
		{ "id": "mend", "count": 2 }])          # 5 + 4×8 + 2 = 39 张
	_check_eq(_load_deck(bad_dup).size(), 0, "同名超过 4 张 → 空数组")
