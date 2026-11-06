# 任务卡：docs/implementation-tasks.md 第 7 节（要写什么 / 用什么手段 / 怎么验收）
class_name DataLoader
extends RefCounted
## 【你的任务】读 JSON，并转成 Card / Unit 对象
## M2 再加校验：字段缺失或类型不对时，报错要说清是哪个文件哪一条
##
## 目录约定（模仿大厂工程）：内容数据放 data/tables/，格式规范放 data/schema/
## 资源（图片/音效）以后放 assets/，与数据分开——见 docs/architecture.md

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
