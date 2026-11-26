extends SceneTree
## M3.4 前置验收测试 —— AI 选目标（Guard 相关）
##
## 运行：
##   ... --headless --path . --script res://tests/pending/ai_guard_test.gd
##
## 背景：M3.2 留下一条登记在案的缺陷（docs/implementation-tasks.md §32 遗留）：
## 初版 AI 选目标用的是「这个单位不是 Guard」，而不是「这个单位没被 Guard 保护」。
## 真实卡池出现 guard 卡后，会出现**AI 白扔一整个回合**：
##   - 前线单位一律去打对方 HQ；HQ 被 Guard 保护时 attack_unit 返回 false，
##     但循环不接返回值 → 这个单位既不换目标也不报错，回合空过。
##   - find_first_attackable() 跳过 Guard → 对方前线只有 Guard 时 AI 直接 break。
##
## 规格（本文件就是规格，M3.4 上真实 guard 卡之前必须先让它变绿）：
##   S1 AI 的单位只要还有合法目标，就必须真的打出去，不允许空过。
##   S2 选目标顺序：HQ（可达且未被保护）> 没被保护的非 Guard 单位 > Guard 本身。
##   S3 被 Guard 保护的友军永远不该被 AI 选成目标（打了必被拒 = 白扔）。
##   S4 Guard 本身永远是合法目标（Guard 之间互不保护）。
##   S5 `_is_guarded()` 对不在场上的单位返回 false，不能崩。
##
## 【启用方式】全绿后 git mv 到 tests/ 下，并把 header 改成「已启用」。

var failures: int = 0
var checks: int = 0
var table: ReactionTable

## 全绿时应执行的检查项数。对不上 = 有测试段被跳过 / 运行期脚本报错打断。
const EXPECTED_CHECKS := 14


func _initialize() -> void:
	print("========== AI 选目标（Guard）测试（M3.4 前置）==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	_test_headquarters_guarded_falls_back_to_guard()
	_test_front_only_guard_is_attacked()
	_test_never_targets_protected_unit()
	_test_prefers_plain_unit_over_guard()
	_test_is_guarded_offboard_safe()

	if checks != EXPECTED_CHECKS:
		printerr("  [FAIL] 覆盖不完整：本文件应执行 %d 项检查，实际 %d 项（有测试段被跳过 / 运行期脚本报错打断）" % [EXPECTED_CHECKS, checks])
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


# ---------------------------------------------------------------- 建局辅助

## 敌方回合专用建局：清空敌方手牌与牌库，避免「AI 抽到什么卡」污染断言。
## 手牌/牌库清空后仍可正常 _enemy_turn()（抽空牌库 = 疲劳，只扣敌方 HQ 血）。
func _new_battle() -> Battle:
	var b := Battle.new()
	var player := Unit.from_dict({ "id": "player", "name": "旅行者", "hp": 60 })
	var enemy := Unit.from_dict({ "id": "enemy", "name": "训练假人", "hp": 9999 })
	var enemies: Array[Unit] = [enemy]
	b.setup(player, enemies, DataLoader.load_cards(), table, 20261126)
	b.first_move = "player"
	b.start_battle()
	b.begin_first_turn()
	b.enemy_hand.clear()
	b.enemy_deck.clear()
	b.enemy_energy = 10
	b.enemy_max_energy = 10
	return b


func _place(b: Battle, line: String, idx: int, owner: String, hp: int, atk: int, guard: bool = false, id: String = "") -> Unit:
	var d := {
		"id": id if id != "" else "%s_%s_%d" % [owner, line, idx],
		"name": "单位",
		"hp": hp,
		"attack": atk,
		"owner": owner,
		"operation_cost": 1,
	}
	if guard:
		d["keywords"] = ["guard"]
	var u := Unit.from_dict(d)
	# 放置失败必须是硬错误：board.place() 静默返回 false（比如格子被 HQ 占着），
	# 不检查的话后面的断言会全部空跑变绿。
	assert(b.board.place(u, line, idx), "辅助 _place() 放置失败：%s/%d 被占用（支援线 0 格是 HQ，单位只能放 1–4）" % [line, idx])
	return u


func _hq(b: Battle, owner: String) -> Unit:
	return b.board.PLAYER_HQ if owner == "player" else b.board.ENEMY_HQ


# ---------------------------------------------------------------- 用例

func _test_headquarters_guarded_falls_back_to_guard() -> void:
	print("[1] 前线单位：HQ 被 Guard 保护 → 改打 Guard 本身（不许空过）")
	var b := _new_battle()
	var guard := _place(b, "player_support", 1, "player", 6, 0, true)
	var foe := _place(b, "front", 1, "enemy", 9, 3)

	var hq: Unit = _hq(b, "player")
	_check(b._is_guarded(hq), "局面成立：玩家 HQ 确实被 Guard 保护")
	var hq_hp0: int = hq.hp
	var guard_hp0: int = guard.hp

	b._enemy_turn()

	_check_eq(hq.hp, hq_hp0, "HQ 仍是满血（被保护，打不到）")
	_check_eq(guard.hp, guard_hp0 - 3, "打不到 HQ 就改打 Guard 本身（6 → 3）")
	_check(foe.has_attacked, "AI 单位真的出手了（没有白扔回合）")


func _test_front_only_guard_is_attacked() -> void:
	print("[2] 我方前线只有 Guard → 敌方支援线单位打这个 Guard")
	var b := _new_battle()
	var guard := _place(b, "front", 1, "player", 6, 0, true)
	var foe := _place(b, "enemy_support", 1, "enemy", 9, 2)

	var hq: Unit = _hq(b, "player")
	var hq_hp0: int = hq.hp
	var guard_hp0: int = guard.hp

	b._enemy_turn()

	_check_eq(guard.hp, guard_hp0 - 2, "只有一个 Guard 可打时也要打（6 → 4）")
	_check(foe.has_attacked, "AI 单位真的出手了（find_first_attackable 不应该直接 break）")
	_check_eq(hq.hp, hq_hp0, "支援线单位够不到 HQ（两条支援线不相邻）")


func _test_never_targets_protected_unit() -> void:
	print("[3] 被 Guard 保护的友军不能被 AI 选成目标")
	var b := _new_battle()
	_place(b, "player_support", 1, "player", 6, 0, true)
	var victim := _place(b, "player_support", 2, "player", 5, 1)
	_place(b, "front", 1, "enemy", 9, 3)

	var guard: Unit = b.board.unit_at("player_support", 1)
	_check(b._is_guarded(victim), "局面成立：victim 确实被 Guard 保护")
	var guard_hp0: int = guard.hp
	var victim_hp0: int = victim.hp

	b._enemy_turn()

	_check_eq(victim.hp, victim_hp0, "被保护的单位一点血都没掉（AI 没拿它当目标）")
	_check_eq(guard.hp, guard_hp0 - 3, "AI 打到的是 Guard 本身（6 → 3）")


func _test_prefers_plain_unit_over_guard() -> void:
	print("[4] 同线既有 Guard 又有可打的普通单位 → 优先打普通单位")
	var b := _new_battle()
	var guard := _place(b, "player_support", 1, "player", 6, 0, true)
	var plain := _place(b, "player_support", 3, "player", 5, 1)
	_place(b, "front", 1, "enemy", 9, 3)

	_check(not b._is_guarded(plain), "局面成立：slot3 距 Guard 两格，不受保护")
	var guard_hp0: int = guard.hp
	var plain_hp0: int = plain.hp

	b._enemy_turn()

	_check_eq(plain.hp, plain_hp0 - 3, "优先打普通单位（5 → 2）")
	_check_eq(guard.hp, guard_hp0, "Guard 这一回合没被打")


func _test_is_guarded_offboard_safe() -> void:
	print("[5] 不在场上的单位判保护不能崩")
	var b := _new_battle()
	var ghost := Unit.from_dict({ "id": "ghost", "name": "幽灵", "hp": 5, "attack": 1, "owner": "player" })
	# position_of() 对不在场上的单位返回空数组；直接取 [1] 会抛
	# SCRIPT ERROR: Invalid access of index '1' on a base object of type: 'Array'
	_check(not b._is_guarded(ghost), "不在场上的单位不算被保护（返回 false，不崩）")
