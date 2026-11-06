extends SceneTree
## 手动跑一局，把战斗日志打印出来（不带界面，最适合调规则）
##
##   Godot_v4.x-stable_win64_console.exe --headless --path . --script res://tests/run_battle.gd

func _initialize() -> void:
	var raw := DataLoader.load_json("res://data/tables/elements.json")
	print(raw.keys())      # 应该打印 ["schema_version", "_note", "elements"]
	print(raw["elements"][0])   # {"id": "fire", ...}
	
	var table := ReactionTable.new()
	table.load_from_file("res://data/tables/reactions.json")

	var cards := DataLoader.load_cards()
	var enemies := DataLoader.load_enemies()

	var player := Unit.from_dict({ "id": "player", "name": "旅行者", "hp": 60 })
	var battle := Battle.new()
	battle.setup(player, [enemies[0]], cards, table, 20261102)

	print("")
	var result := battle.run_auto(30)
	print("")
	print("结果：%s（第 %d 回合）" % [result, battle.turn])
	quit(0)
