class_name DataLoader
extends RefCounted

const DATA_DIR := "res://data/tables/"


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
