extends SceneTree
## M3.6 平衡模拟器：批量跑自动对局，统计胜率 / 回合数 / 超时，输出 CSV。
##
## 用法（项目根目录）：
##   $g = "..\..\..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"   # 相对仓库根；或先 set GODOT
##   & $g --headless --path . --script res://tools/balance_sim.gd -- --games 10000 --seed 42 --out res://balance.csv
##
## 参数（都可选）：
##   --games N       对局数，默认 100
##   --seed S        起始种子，默认 42（第 i 局用 seed + i，可复现）
##   --max-turns N   单局最大回合，默认 30
##   --out PATH      输出 CSV 路径（可选；不写就只打印汇总）
##   --units-only    只用单位卡组（默认；E14 之前 AI 不打指令卡，混入指令卡会卡死）
##   --all-cards     用 cards.json 全牌库（E14 做完后可用，目前会大量 RUNNING）
##
## 规格：docs/m3-scope.md §M3.6；报告模板 docs/balance-report.md

const DEFAULT_GAMES := 100
const DEFAULT_SEED := 42
const DEFAULT_MAX_TURNS := 30
const PLAYER_HP := 60

var table: ReactionTable


func _initialize() -> void:
	var args := _parse_args(OS.get_cmdline_user_args())
	var games: int = int(args.get("games", DEFAULT_GAMES))
	var seed0: int = int(args.get("seed", DEFAULT_SEED))
	var max_turns: int = int(args.get("max-turns", DEFAULT_MAX_TURNS))
	var out_path: String = str(args.get("out", ""))
	var units_only: bool = not bool(args.get("all-cards", false))

	table = ReactionTable.new()
	if not table.load_from_file("res://data/tables/reactions.json"):
		printerr("[balance_sim] 反应表加载失败")
		quit(2)
		return
	var all_cards: Array = DataLoader.load_cards()
	var base_deck: Array = _build_deck(all_cards, units_only)
	if base_deck.is_empty():
		printerr("[balance_sim] 牌库为空")
		quit(2)
		return

	print("[balance_sim] games=%d seed=%d max_turns=%d deck=%d 张 team=units-only:%s" % [games, seed0, max_turns, base_deck.size(), str(units_only)])
	var win := 0
	var lose := 0
	var running := 0
	var turns_sum := 0
	var rows: Array[String] = []
	var started := Time.get_ticks_msec()

	for i in range(games):
		var seed_value := seed0 + i
		var b := Battle.new()
		var player := Unit.from_dict({ "id": "player", "name": "旅行者", "hp": PLAYER_HP })
		var enemy := Unit.from_dict({ "id": "enemy", "name": "训练假人", "hp": 9999 })
		var enemies: Array[Unit] = [enemy]
		b.setup(player, enemies, base_deck, table, seed_value)
		var result := b.run_auto(max_turns)
		turns_sum += b.turn
		match result:
			"WIN":
				win += 1
			"LOSE":
				lose += 1
			_:
				running += 1
		rows.append("%d,%d,%s,%d" % [i, seed_value, result, b.turn])

	var elapsed := Time.get_ticks_msec() - started
	var winrate := 0.0
	if games > 0:
		winrate = float(win) / float(games) * 100.0
	var avg_turns := 0.0
	if games > 0:
		avg_turns = float(turns_sum) / float(games)

	print("================ 结果 ================")
	print("对局 %d 场，用时 %.1f 秒" % [games, float(elapsed) / 1000.0])
	print("WIN %d / LOSE %d / RUNNING %d" % [win, lose, running])
	print("玩家胜率 %.1f%%（目标 45%%–60%%）" % winrate)
	print("平均回合 %.1f（目标 8–20）" % avg_turns)
	print("超时/RUNNING %.1f%%（目标 < 1%%）" % (float(running) / max(1, games) * 100.0))

	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		if f == null:
			printerr("[balance_sim] 无法写入 CSV：%s" % out_path)
			quit(2)
			return
		f.store_line("game,seed,winner,turns")
		for r in rows:
			f.store_line(r)
		f.close()
		print("CSV：%s（%d 行）" % [out_path, rows.size()])

	if running > 0:
		printerr("[balance_sim] 警告：有 %d 局 RUNNING（没打完），平衡数据会偏" % running)
	quit(0)


func _parse_args(raw: Array) -> Dictionary:
	var out := {}
	var i := 0
	while i < raw.size():
		var a := str(raw[i])
		if a == "--units-only":
			out["all-cards"] = false
			i += 1
		elif a == "--all-cards":
			out["all-cards"] = true
			i += 1
		elif a.begins_with("--") and i + 1 < raw.size():
			out[a.substr(2)] = str(raw[i + 1])
			i += 2
		else:
			i += 1
	return out


## 目前 AI 不打指令卡（E14 之前），默认只留单位卡，否则手牌会被指令卡塞满、对局永远 RUNNING。
func _build_deck(all_cards: Array, units_only: bool) -> Array:
	var deck: Array = []
	for c in all_cards:
		if units_only and c.type != "unit":
			continue
		deck.append(c)
	return deck
