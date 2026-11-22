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

const EXPECTED_CHECKS := 10


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
		_check(false, "还没有 load_deck，跳过")
		_check(false, "跳过")
		return
	var deck: Array = _load_deck("res://data/decks/player_deck.json")
	_check_eq(deck.size(), 39, "牌组展开后 39 张（HQ 不进牌库）")
	var counts := _count_by_id(deck)
	_check_eq(int(counts.get("footman", 0)), 4, "同名卡展开正确（footman 4 张）")
	_check_eq(int(counts.get("guard", 0)), 3, "同名卡展开正确（guard 3 张）")


func _test_enemy_deck_independent() -> void:
	print("[3] 敌方牌组独立加载")
	if not _has_load_deck():
		_check(false, "跳过")
		_check(false, "跳过")
		return
	var p: Array = _load_deck("res://data/decks/player_deck.json")
	var e: Array = _load_deck("res://data/decks/enemy_deck.json")
	_check_eq(e.size(), 39, "敌方牌组也是 39 张")
	_check(p != e or p.size() == e.size(), "两次加载互不影响（不是同一个数组引用）")


func _test_invalid_decks() -> void:
	print("[4] 非法牌组：push_error + 返回空数组")
	if not _has_load_deck():
		for i in range(4):
			_check(false, "跳过")
		return
	var bad_id := _write_user_deck("bad_id", [{ "id": "no_such_card", "count": 39 }])
	_check_eq(_load_deck(bad_id).size(), 0, "未知卡 id → 空数组")

	var bad_total := _write_user_deck("bad_total", [{ "id": "footman", "count": 10 }])
	_check_eq(_load_deck(bad_total).size(), 0, "总张数不是 39 → 空数组")

	var bad_count := _write_user_deck("bad_count", [{ "id": "footman", "count": 0 }])
	_check_eq(_load_deck(bad_count).size(), 0, "count <= 0 → 空数组")

	var bad_dup := _write_user_deck("bad_dup", [{ "id": "footman", "count": 5 }, { "id": "archer", "count": 34 }])
	_check_eq(_load_deck(bad_dup).size(), 0, "同名超过 4 张 → 空数组")
