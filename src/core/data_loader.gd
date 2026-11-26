class_name DataLoader
extends RefCounted

const DATA_DIR := "res://data/tables/"
const DECK_SIZE := 39
const MAX_SAME_CARD := 4


static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("找不到数据文件:"+path)
		return {} 
	var text = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("数据文件为空："+path)
		return {}
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("JSON格式错误(顶层应是对象)："+path)
		return {}
	return data


static func load_cards(path: String = DATA_DIR + "cards.json") -> Array[Card]:
	var out: Array[Card] = []
	var data := load_json(path)
	if data.is_empty():
		return out
	for item in data.get("cards",[]):
		if typeof(item) != TYPE_DICTIONARY:
			push_error("cards.json里面有一条不是对象: "+path)
			continue
		# count = 这套牌组里放几份（缺省 1）。每份生成独立的 Card 对象，
		# 避免同一引用在多处被 erase/修改时互相影响。
		var copies: int = int(item.get("count", 1))
		if copies < 1:
			copies = 1
		for i in range(copies):
			out.append(Card.from_dict(item))
	return out


static func load_enemies(path: String = DATA_DIR + "enemies.json") -> Array[Unit]:
	var out: Array[Unit] = []
	var data := load_json(path)
	if data.is_empty():
		return out
	for item in data.get("enemies",[]):
		if typeof(item) != TYPE_DICTIONARY:
			push_error("enemies.json里面有一条不是对象: "+path)
			continue
		out.append(Unit.from_dict(item))
	return out


static func _card_catalog(path:String = DATA_DIR +"cards.json") -> Dictionary:
	var out:Dictionary = {}
	var data = load_json(path)
	for c in data.get("cards",[]):
		if typeof(c) != TYPE_DICTIONARY:
			push_error("cards.json里有一条不是对象："+path)
			continue
		out[str(c["id"])] = c
	return out


static func load_deck(path:String) -> Array[Card]:
	var out:Array[Card] = []
	var data := load_json(path)
	if data.is_empty():return out
	if not data.has("cards"):
		push_error("未找到cards数组："+ path)
		return out
	var deck = data["cards"]
	if typeof(deck) != TYPE_ARRAY:
		push_error("cards不是数组："+ path)
		return out
	
	var catalog := _card_catalog()
	var sum:int = 0
	var cnt:Dictionary = {}
	
	for c in deck:
		if typeof(c) != TYPE_DICTIONARY:
			push_error("deck里面有一条不是对象"+path)
			return out
		var id:String = str(c["id"])
		var count:int = int(c["count"])
		if not catalog.has(id):
			push_error("加载到未知卡牌 id:%s path:%s"%[id,path])
			return out
		if count <= 0:
			push_error("卡牌数不合法 id:%s"%id)
			return out
		if cnt.get(id,"") == "":
			cnt[id] = count
		else: cnt[id] += count
		sum += count
		if cnt[id] > MAX_SAME_CARD:
			push_error("同类型卡牌超出上限 id:%s"%id)
			return out
		if sum > DECK_SIZE:
			push_error("卡组牌数超出上限")
			return out
	if sum != DECK_SIZE:
		push_error("牌库不足: 当前%d张"%sum)
		return out
	for c in deck:
		var count:int = int(c["count"])
		var id:String = str(c["id"])
		for i in range(count):
			out.append(Card.from_dict(catalog[id]))
	return out
