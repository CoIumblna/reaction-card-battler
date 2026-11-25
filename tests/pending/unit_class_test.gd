extends SceneTree
## M3.3 兵科验收测试 —— 待实现
##
## 运行：
##   ... --headless --path . --script res://tests/pending/unit_class_test.gd
##
## 规格：docs/adr/004-m3-keywords.md 决定 3（KARDS 5 类）
##   infantry 步兵 / tank 坦克 / artillery 炮兵 / fighter 战斗机 / bomber 轰炸机
##   本文件覆盖：炮兵无反击、坦克移动+攻击、战斗机/轰炸机越线、轰炸机无反击/不反击
##   （战斗机拦截轰炸机的"只能打战斗机"规则单独在 M3.3b 补）
##   另含 2026-11-25 学员补充的三条：[8] 步兵对照组、[9] 炮兵无视 Guard、[10] 轰炸机无视 Guard
##
## 【启用方式】M3.3 全绿后移到 tests/ 下。

var failures: int = 0
var checks: int = 0
var table: ReactionTable

const EXPECTED_CHECKS := 21


func _initialize() -> void:
	print("========== 兵科测试（M3.3） ==========")
	table = ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")
	_test_artillery_no_counter()
	_test_infantry_counter()
	_test_tank_move_and_attack()
	_test_fighter_cross_line()
	_test_bomber_cross_line()
	_test_bomber_no_counter_when_attacking()
	_test_bomber_no_counter_when_attacked()
	_test_infantry_blocked_by_guard()
	_test_artillery_ignores_guard()
	_test_bomber_ignores_guard()

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


func _new_battle() -> Battle:
	var b := Battle.new()
	var player := Unit.from_dict({ "id": "player", "name": "旅行者", "hp": 60 })
	var enemy := Unit.from_dict({ "id": "enemy", "name": "训练假人", "hp": 9999 })
	var enemies: Array[Unit] = [enemy]
	b.setup(player, enemies, DataLoader.load_cards(), table, 20261128)
	b.start_battle()
	b.energy = 10
	return b


func _unit(id: String, hp: int, attack: int, owner: String, unit_class: String = "infantry") -> Unit:
	return Unit.from_dict({ "id": id, "name": id, "hp": hp, "attack": attack, "owner": owner, "unit_class": unit_class })


func _place(b: Battle, u: Unit, line: String, idx: int) -> Unit:
	b.board.place(u, line, idx)
	return u


# ---------------------------------------------------------------- 用例

func _test_artillery_no_counter() -> void:
	print("[1] 炮兵：攻击时不受反击伤害")
	var b := _new_battle()
	var arty := _place(b, _unit("arty", 5, 3, "player", "artillery"), "front", 1)
	var foe := _place(b, _unit("foe", 10, 2, "enemy"), "enemy_support", 1)
	_check(b.attack_unit(arty, foe), "炮兵攻击成立")
	_check_eq(arty.hp, 5, "炮兵不受反击（攻击力 2 的敌人没有反伤）")
	_check_eq(foe.hp, 7, "目标正常受伤（10 - 3 = 7）")


func _test_infantry_counter() -> void:
	print("[2] 步兵：正常受到反击")
	var b := _new_battle()
	var inf := _place(b, _unit("inf", 5, 3, "player", "infantry"), "front", 1)
	var foe := _place(b, _unit("foe", 10, 2, "enemy"), "enemy_support", 1)
	b.attack_unit(inf, foe)
	_check_eq(inf.hp, 3, "步兵受到反击（5 - 2 = 3）")


func _test_tank_move_and_attack() -> void:
	print("[3] 坦克：一回合可以移动 + 攻击")
	var b := _new_battle()
	var tank := _place(b, _unit("tank", 8, 2, "player", "tank"), "player_support", 1)
	if tank.get("has_moved") == null:
		_check(false, "还没有 has_moved/has_attacked 字段")
		_check(false, "跳过")
		return
	tank.has_moved = false
	tank.has_attacked = false
	var foe := _place(b, _unit("foe", 10, 1, "enemy"), "enemy_support", 1)
	_check(b.move_unit(tank, "front", 0), "坦克先移动成功")
	_check(b.attack_unit(tank, foe), "坦克移动后仍能攻击（兵科例外）")


func _test_fighter_cross_line() -> void:
	print("[4] 战斗机：可从己方支援线直接打对方支援线")
	var b := _new_battle()
	var fighter := _place(b, _unit("fighter", 5, 3, "player", "fighter"), "player_support", 1)
	var foe := _place(b, _unit("foe", 10, 1, "enemy"), "enemy_support", 1)
	_check(b.attack_unit(fighter, foe), "战斗机跨两条线攻击敌方支援线成功")

	var b2 := _new_battle()
	var inf := _place(b2, _unit("inf", 5, 3, "player", "infantry"), "player_support", 1)
	var foe2 := _place(b2, _unit("foe2", 10, 1, "enemy"), "enemy_support", 1)
	_check(not b2.attack_unit(inf, foe2), "步兵不能跨线（支援线直接打支援线）")


func _test_bomber_cross_line() -> void:
	print("[5] 轰炸机：可越线打支援线")
	var b := _new_battle()
	var bomber := _place(b, _unit("bomber", 5, 3, "player", "bomber"), "player_support", 1)
	var foe := _place(b, _unit("foe", 10, 1, "enemy"), "enemy_support", 1)
	_check(b.attack_unit(bomber, foe), "轰炸机跨线攻击成功")


func _test_bomber_no_counter_when_attacking() -> void:
	print("[6] 轰炸机：攻击非战斗机时不受反击")
	var b := _new_battle()
	var bomber := _place(b, _unit("bomber", 5, 3, "player", "bomber"), "front", 1)
	var foe := _place(b, _unit("foe", 10, 2, "enemy"), "enemy_support", 1)
	_check(b.attack_unit(bomber, foe), "轰炸机攻击成立（否则下面的断言是空跑）")
	_check_eq(bomber.hp, 5, "轰炸机攻击非战斗机不受反击")
	_check_eq(foe.hp, 7, "目标正常受伤（10 - 3 = 7）")


func _test_bomber_no_counter_when_attacked() -> void:
	print("[7] 轰炸机：被攻击时也不能反击")
	var b := _new_battle()
	# 攻击方是敌方单位，必须给它能量 —— 否则 attack_unit 直接因能量不足返回 false，
	# 断言 foe.hp == 10 会「空跑变绿」（2026-11-25 教练修：这一项原来就是假绿）
	b.enemy_energy = 10
	var foe := _place(b, _unit("foe", 10, 2, "enemy"), "front", 1)
	var bomber := _place(b, _unit("bomber", 5, 3, "player", "bomber"), "player_support", 1)
	_check(b.attack_unit(foe, bomber), "敌方攻击轰炸机成立（否则下面的断言是空跑）")
	_check_eq(foe.hp, 10, "轰炸机被打时不能反击（攻击方不掉血）")
	_check_eq(bomber.hp, 3, "轰炸机确实挨了打（5 - 2 = 3）")


## 2026-11-25 学员补充规则：炮兵、轰炸机可以无视 Guard。
## ADR-004 决定 2 原本只写了「指令卡默认无视 Guard」，没写这两种兵科，这里补上。
## 【注意】[9][10] 两项在学员实现前是**预期红的**，这是红基线，不是教练的测试写错。
##
## 局面一律照抄 guard_test 里已验证的形状：Guard 在 enemy_support 1、被保护的敌兵在
## enemy_support 2、攻手放在 front —— 因为 player_support / enemy_support 的 0 号格
## 被 HQ 占着（const HQ_SLOT := 0），单位只能放 1~4 格，别往 0 格塞。

func _guarded_line(b: Battle) -> Array:
	var g := Unit.from_dict({ "id": "guard", "name": "护卫", "hp": 5, "attack": 1, "owner": "enemy", "keywords": ["guard"] })
	if not b.board.place(g, "enemy_support", 1):
		_check(false, "（自检）Guard 放置失败")
	var victim := Unit.from_dict({ "id": "victim", "name": "敌兵", "hp": 10, "attack": 1, "owner": "enemy" })
	if not b.board.place(victim, "enemy_support", 2):
		_check(false, "（自检）被保护单位放置失败")
	# 自检：场上那个 Guard 必须真的带 guard 词条（查棋盘里的对象，不要查本地变量）
	_check(b.board.unit_at("enemy_support", 1).is_guard(), "（自检）场上 Guard 带 guard 词条")
	return [g, victim]


func _test_infantry_blocked_by_guard() -> void:
	print("[8] 对照组：步兵打不动被 Guard 保护的目标")
	var b := _new_battle()
	var pair := _guarded_line(b)
	var inf := Unit.from_dict({ "id": "inf", "name": "步兵", "hp": 9, "attack": 2, "owner": "player", "unit_class": "infantry" })
	b.board.place(inf, "front", 1)
	_check(not b.attack_unit(inf, pair[1]), "步兵无法攻击被保护的目标（对照组，现状应为 true）")


func _test_artillery_ignores_guard() -> void:
	print("[9] 炮兵：无视 Guard")
	var b := _new_battle()
	var pair := _guarded_line(b)
	var arty := Unit.from_dict({ "id": "arty", "name": "炮兵", "hp": 9, "attack": 2, "owner": "player", "unit_class": "artillery" })
	b.board.place(arty, "front", 1)
	_check(b.attack_unit(arty, pair[1]), "炮兵无视 Guard，能攻击被保护的目标")


func _test_bomber_ignores_guard() -> void:
	print("[10] 轰炸机：无视 Guard")
	var b := _new_battle()
	var pair := _guarded_line(b)
	var bomber := Unit.from_dict({ "id": "bomber", "name": "轰炸机", "hp": 9, "attack": 2, "owner": "player", "unit_class": "bomber" })
	b.board.place(bomber, "front", 1)
	_check(b.attack_unit(bomber, pair[1]), "轰炸机无视 Guard，能攻击被保护的目标")
