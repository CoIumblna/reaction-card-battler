extends SceneTree
## M2 流程测试：Kredit 成长 / 单位部署 / 召唤失调 / HQ 接入
##
## 运行：
##   ... --headless --path . --script res://tests/battle_m2_test.gd
##
## [6] 敌方 AI / [7] 自动对局是 E15 的验收点。牌库顺序、手牌上限、指令卡策略都会影响
## 自动对局能不能打完，规格见 docs/implementation-tasks.md §23。

var failures: int = 0
var checks: int = 0
var table: ReactionTable

## 全绿时应执行的检查项数。对不上 = 有测试段被静默跳过（或 SCRIPT ERROR 打断），
## 只看"共 N 项检查、失败 0 项"会假绿，所以这里硬校验。
const EXPECTED_CHECKS := 63


func _initialize() -> void:
	print("========== M2 流程测试 ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	_test_kredit()
	_test_deploy()
	_test_summoning_sickness()
	_test_hq_wired()
	_test_outcome()
	_test_enemy_ai()
	_test_run_auto()

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


func _new_battle(player_hp: int = 60, p_deck: Array = []) -> Battle:
	var b := Battle.new()
	var player := Unit.from_dict({ "id": "player", "name": "旅行者", "hp": player_hp })
	var enemy := Unit.from_dict({ "id": "enemy", "name": "训练假人", "hp": 9999 })
	var enemies: Array[Unit] = [enemy]
	var cards: Array = p_deck
	if cards.is_empty():
		cards = DataLoader.load_cards()
	b.setup(player, enemies, cards, table, 20261115)
	return b


func _unit_card(id: String, cost: int, attack: int, defense: int, element: String = Element.NONE, operation_cost: int = -1) -> Card:
	var d := {
		"id": id, "name": id, "type": "unit", "cost": cost,
		"element": element, "attack": attack, "defense": defense,
	}
	if operation_cost >= 0:
		d["operation_cost"] = operation_cost   # -1 = 卡上不写这个字段（走 from_dict 缺省 1）
	return Card.from_dict(d)


## [7] 专用牌库：单位卡放在最前面。
## 为什么不用真牌库：cards.json 前 28 张全是指令卡（7 种 × 4），起手 5 + 每回合 1 张，
## 第 4 回合手牌顶到上限 9、之后抽到的全被丢弃 —— 而自动决策不打指令卡（E14 才做），
## 于是整局摸不到一张单位卡，谁都没法上场。这里只测"回合循环能打完"，和牌库内容解耦。
func _make_unit_deck() -> Array[Card]:
	var out: Array[Card] = []
	for i in range(4):
		out.append(_unit_card("footman", 1, 1, 2))
		out.append(_unit_card("archer", 2, 2, 1))
		out.append(_unit_card("fire_mage", 3, 2, 3, Element.FIRE))
		out.append(_unit_card("tank", 4, 4, 5))
	return out


# ---------------------------------------------------------------- 用例

func _test_kredit() -> void:
	print("[1] Kredit 成长（M2 / E6）")
	var b := _new_battle()
	_check_eq(b.max_energy, 0, "setup 后 Kredit 上限为 0（还没开战）")

	_start(b)
	_check_eq(b.turn, 1, "进入第 1 回合")
	_check_eq(b.max_energy, 1, "第 1 回合 Kredit 上限 = 1")
	_check_eq(b.energy, 1, "回合开始回满到上限")

	b.end_turn()
	_check_eq(b.max_energy, 2, "第 2 回合上限 = 2（每回合 +1）")
	_check_eq(b.energy, 2, "回合开始回满到 2")

	b.end_turn()
	b.end_turn()
	_check_eq(b.max_energy, 4, "第 4 回合上限 = 4")

	# 封顶：KARDS 原版上限 12
	b.max_energy = 12
	b.energy = 0
	b.end_turn()
	_check_eq(b.max_energy, 12, "上限封顶 12（不再增长）")
	_check_eq(b.energy, 12, "封顶后回满到 12")


func _test_deploy() -> void:
	print("[2] 单位部署（M2 / E4）")
	var b := _new_battle()
	_start(b)
	var board = b.get("board")
	if board == null:
		_check(false, "Battle 还没有 board 字段（部署的前置）")
		return

	b.energy = 5
	var tank := _unit_card("tank", 3, 3, 4, Element.FIRE)
	b.hand.append(tank)
	_check(b.play_card(tank, b.player), "单位卡可以打出")
	_check_eq(b.energy, 2, "扣掉 3 费")
	_check_eq(b.hand.has(tank), false, "单位卡移出手牌")

	var u: Unit = board.unit_at("player_support", 1)
	_check(u != null, "单位放在我方支援线第一个空位（1 号）")
	if u != null:
		_check_eq(u.attack, 3, "攻击力取 card.attack")
		_check_eq(u.hp, 4, "hp 取 card.defense")
		_check_eq(u.max_hp, 4, "max_hp 同步为 4")
		_check_eq(u.is_hq, false, "部署的不是 HQ")
		_check_eq(u.element, Element.FIRE, "单位带上卡牌元素（丢了这个，单位永远不触发元素反应）")
		_check_eq(u.owner, "player", "玩家部署的单位 owner = player（E15 敌方 AI 靠它分敌我）")
		_check_eq(u.operation_cost, 1, "卡上没写作战费时默认 1（§18）")

	# 支援线还剩 3 个空位（1 号已被占）→ 只能再放 3 个
	b.energy = 10
	var placed := 0
	for i in range(4):
		var c := _unit_card("filler%d" % i, 1, 1, 1)
		b.hand.append(c)
		if b.play_card(c, b.player):
			placed += 1
	_check_eq(placed, 3, "支援线剩余 3 个空位能放（满线共 4 个单位）")

	var over := _unit_card("overflow", 1, 1, 1)
	b.hand.append(over)
	var energy_before := b.energy
	_check_eq(b.play_card(over, b.player), false, "支援线满时部署失败")
	_check_eq(b.energy, energy_before, "失败的部署不扣能量")
	_check_eq(b.hand.has(over), true, "失败的卡留在手里")

	# 0 是合法值（免费移动/攻击），不能被"缺省"吃掉：显式写 operation_cost: 0 的单位要保留 0
	var b9 := _new_battle()
	_start(b9)
	b9.energy = 5
	var scout_card := _unit_card("scout", 1, 1, 1, Element.NONE, 0)
	b9.hand.append(scout_card)
	var deployed_ok := b9.play_card(scout_card, b9.player)
	var scout: Unit = b9.board.unit_at("player_support", 1)
	_check(deployed_ok and scout != null and scout.operation_cost == 0, "显式 operation_cost: 0 会保留（0 是合法值，不是漏写）")


func _test_summoning_sickness() -> void:
	print("[3] 召唤失调（M2 / E5）")
	var b := _new_battle()
	_start(b)
	var board = b.get("board")
	if board == null:
		_check(false, "Battle 还没有 board 字段（召唤失调的前置）")
		return

	b.energy = 5
	var c := _unit_card("grunt", 1, 2, 2)
	b.hand.append(c)
	b.play_card(c, b.player)
	var u: Unit = board.unit_at("player_support", 1)
	if u == null:
		_check(false, "部署失败，后面没法测召唤失调")
		return
	_check_eq(u.has_acted, true, "部署当回合就标记为已行动（不能动/攻击）")

	b.end_turn()
	_check_eq(u.has_acted, false, "进入下一回合后解除召唤失调")

	# §15 说的是"己方所有单位"：已经推进到前线的单位也要清
	# （M2 遗留 bug：_begin_turn 只清 player_support → 前线单位永远不能攻击）
	var front_unit := Unit.from_dict({ "id": "front_grunt", "name": "前线兵", "hp": 20, "attack": 1, "owner": "player" })
	board.place(front_unit, "front", 0)
	front_unit.has_acted = true
	b.end_turn()
	_check_eq(front_unit.has_acted, false, "前线单位在新回合也解除已行动（不只支援线）")


func _test_hq_wired() -> void:
	print("[4] HQ 接入 Battle（M2 / E3）")
	var b := _new_battle()
	_check(b.get("board") != null, "Battle 持有 Board（setup 时建好）")
	var board = b.get("board")
	if board == null:
		return
	var phq: Unit = board.unit_at("player_support", 0)
	var ehq: Unit = board.unit_at("enemy_support", 0)
	_check(phq != null and phq.is_hq, "我方 HQ 就位")
	_check(ehq != null and ehq.is_hq, "敌方 HQ 就位")
	if phq != null:
		_check_eq(phq.max_hp, 20, "HQ 最大防御 20")
		_check_eq(phq.hp, 20, "HQ 初始满防")
	_check(phq != ehq, "双方 HQ 是两个独立对象")


func _test_outcome() -> void:
	print("[5] 胜负看 HQ（M2 / E13）")
	var b := _new_battle()
	_check_eq(b.outcome(), "RUNNING", "开局双方 HQ 都在 → RUNNING")

	var ehq: Unit = b.board.unit_at("enemy_support", 0)
	ehq.hp = 0
	_check(b.is_over(), "敌方 HQ 归零 → 战斗结束")
	_check_eq(b.outcome(), "WIN", "结果 WIN")

	var b2 := _new_battle()
	b2.board.unit_at("player_support", 0).hp = 0
	_check(b2.is_over(), "我方 HQ 归零 → 战斗结束")
	_check_eq(b2.outcome(), "LOSE", "结果 LOSE")

	# M1 的血条模型退役：敌人全灭不再算赢
	var b3 := _new_battle()
	b3.enemies[0].hp = 0
	_check_eq(b3.outcome(), "RUNNING", "M1 的 enemies 全灭不再算赢（只看 HQ）")


func _test_enemy_ai() -> void:
	print("[6] 敌方 AI（M2 / E15）")
	var b := _new_battle()
	var missing: Array[String] = []
	for f in ["enemy_energy", "enemy_max_energy", "enemy_hand", "enemy_deck"]:
		if b.get(f) == null:
			missing.append(f)
	if not missing.is_empty():
		_check(false, "Battle 还没有 %s 字段（敌方 AI 的前置）" % "、".join(missing))
		return

	# 敌方资源和玩家对称：setup 复制牌库、开局发 5 张、每回合抽 1 张、Kredit 每回合 +1
	var total_deck: int = b.deck.size()
	_check_eq(b.enemy_deck.size(), total_deck, "setup 给敌方复制了一份牌库（张数与玩家相同）")
	_start(b)
	_check_eq(b.enemy_hand.size(), 5, "敌方起手 5 张")
	_check_eq(b.enemy_deck.size(), total_deck - 5, "敌方起手从敌方牌库扣 5 张")
	_check_eq(b.deck.size(), total_deck - 4, "双方牌库各自扣牌（不是同一个 Array；玩家先手起手 4）")
	var before: int = int(b.enemy_max_energy)
	b.end_turn()
	_check_eq(b.enemy_max_energy, before + 1, "敌方 Kredit 每回合 +1")
	_check_eq(b.enemy_deck.size(), total_deck - 6, "敌方每回合抽 1 张（牌库再 -1）")

	# 敌方会部署（手牌只给一张便宜的步兵；清空敌方牌库，免得"抽到哪张"影响断言）
	var b2 := _new_battle()
	_start(b2)
	b2.enemy_hand.clear()
	b2.enemy_deck.clear()
	b2.enemy_hand.append(Card.from_dict({ "id": "footman", "name": "步兵", "type": "unit", "cost": 1, "element": "none", "attack": 1, "defense": 2 }))
	b2.enemy_energy = 5
	b2.enemy_max_energy = 5
	b2.end_turn()
	_check_eq(b2.board.units_in("enemy_support").size(), 2, "敌方部署了 1 个单位（HQ + 1，每回合最多 1 次）")
	var deployed: Unit = null
	for u in b2.board.units_in("enemy_support"):
		if not u.is_hq:
			deployed = u
	_check(deployed != null and deployed.owner == "enemy", "敌方部署的单位 owner = enemy（不是 player）")
	_check_eq(b2.board.units_in("player_support").size(), 1, "敌方部署没落到我方支援线（别直接复用 play_card 的玩家分支）")

	# 敌方会推进前线：推的是支援线的单位，不能把 HQ 挪出去
	var b3 := _new_battle()
	_start(b3)
	b3.enemy_hand.clear()
	b3.enemy_deck.clear()
	var foe := Unit.from_dict({ "id": "foe", "name": "敌兵", "hp": 3, "attack": 2, "owner": "enemy" })
	b3.board.place(foe, "enemy_support", 1)
	b3.enemy_energy = 5
	b3.enemy_max_energy = 5
	b3.end_turn()
	var foe_pos := b3.board.position_of(foe)
	_check(foe_pos.size() == 2 and foe_pos[0] == "front", "敌方把支援线的单位推进了前线（推的是单位，不是 HQ）")
	_check(b3.board.unit_at("enemy_support", 0) != null, "HQ 还在原地（HQ 不能移动）")

	# 敌方会攻击相邻线的目标：够得着玩家 HQ 就先打 HQ
	# 注意：front 和 front 不是相邻线（前线独占 → 双方不可能同时在前线），
	# 敌方前线单位的相邻线是我方【支援线】（player_support ↔ front），HQ 就在那儿。
	var b4 := _new_battle()
	_start(b4)
	b4.enemy_hand.clear()
	b4.enemy_deck.clear()
	var foe2 := Unit.from_dict({ "id": "foe2", "name": "敌兵", "hp": 5, "attack": 2, "owner": "enemy" })
	b4.board.place(foe2, "front", 0)
	var mine := Unit.from_dict({ "id": "mine", "name": "我方", "hp": 5, "attack": 1, "owner": "player" })
	b4.board.place(mine, "player_support", 1)
	var player_hq: Unit = b4.board.unit_at("player_support", 0)
	b4.enemy_energy = 5
	b4.enemy_max_energy = 5
	b4.end_turn()
	_check_eq(player_hq.hp, 18, "敌方前线单位打了玩家 HQ（攻击力 2，20 → 18）")
	_check_eq(mine.hp, 5, "没有误打玩家支援线单位（攻击段优先打 HQ）")
	_check(foe2.has_acted, "攻击后攻击者标记为已行动")

	# 敌方单位的 has_acted 也要在敌方回合清零，否则一辈子只能动一次
	b4.enemy_energy = 5
	b4.enemy_max_energy = 5
	b4.end_turn()
	_check_eq(player_hq.hp, 16, "敌方单位下一回合能再次攻击（has_acted 有清零，HQ 18 → 16）")

	# 打不到 HQ 的时候才打单位：敌方支援线单位够不到玩家 HQ（不相邻），只能打我方前线单位
	var b5 := _new_battle()
	_start(b5)
	b5.enemy_hand.clear()
	b5.enemy_deck.clear()
	var front_mine := Unit.from_dict({ "id": "fm", "name": "我前", "hp": 5, "attack": 1, "owner": "player" })
	b5.board.place(front_mine, "front", 1)
	var sup_foe := Unit.from_dict({ "id": "sf", "name": "敌支", "hp": 5, "attack": 2, "owner": "enemy" })
	b5.board.place(sup_foe, "enemy_support", 1)
	b5.enemy_energy = 5
	b5.enemy_max_energy = 5
	b5.end_turn()
	_check_eq(front_mine.hp, 3, "敌方支援线单位打不到 HQ，就打我方前线单位（5 → 3）")
	_check_eq(b5.board.unit_at("player_support", 0).hp, 20, "敌方支援线单位够不到玩家 HQ（两条支援线不相邻）")


func _test_run_auto() -> void:
	print("[7] 自动对局（M2 / E15）")
	# 用单位卡在前的专用牌库（真牌库前 28 张全是指令卡，见 _make_unit_deck 的注释）
	var b := _new_battle(60, _make_unit_deck())
	var result := b.run_auto(30)
	_check(result in ["WIN", "LOSE"], "自动对局能分出胜负（结果 %s）" % result)
	_check(b.is_over(), "结束后 is_over() 为真（RUNNING = 没打完 / 卡死）")
	_check_eq(result, b.outcome(), "返回值与 outcome() 一致")
	_check(b.turn >= 4, "对局跑够回合数（实际 %d 回合；3 回合内结束说明没在棋盘上打）" % b.turn)
	_check(b.turn <= 30, "不超过 max_turns（实际 %d 回合）" % b.turn)
	# 平衡模拟要可复现：同一个 seed 再跑一局，结果必须一样。
	# （这条替代了原来的"日志非空"——日志量是实现细节，不该当验收标准）
	var b2 := _new_battle(60, _make_unit_deck())
	_check_eq(b2.run_auto(30), result, "同 seed 两局结果一致（run_auto 可复现）")


## 建局：固定玩家先手 + 开始第一个回合（E7b 后 start_battle() 只发牌）
func _start(b: Battle) -> void:
	b.first_move = "player"
	b.start_battle()
	b.begin_first_turn()
