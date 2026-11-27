class_name DataLoader
extends RefCounted

const DATA_DIR := "res://data/tables/"
const DECK_SIZE := 39
## 每张卡各自的上限写在 cards.json 的 "limit" 字段里，没写就用 Card.DEFAULT_LIMIT（4）。
## 这里保留常量只为兼容老调用点（tools / 测试里还会引用），实际校验走 per-card limit。
const MAX_SAME_CARD := Card.DEFAULT_LIMIT


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
		# 每张卡各自的上限：cards.json 里写 "limit": N 就按 N 算，不写按默认 4。
		# 缺省值一定是 4 而不是「不限」—— 数据漏写字段不应该变成无限制。
		var limit:int = int(catalog[id].get("limit", Card.DEFAULT_LIMIT))
		if limit < 1:
			push_error("卡牌上限不合法 id:%s limit:%d"%[id,limit])
			return out
		if cnt[id] > limit:
			push_error("卡牌「%s」超出上限（%d 张，上限 %d）id:%s"%[
				str(catalog[id].get("name", id)), int(cnt[id]), limit, id])
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
