# 任务卡：docs/implementation-tasks.md 第 6 节（要写什么 / 用什么手段 / 怎么验收）
class_name ReactionTable
extends RefCounted
## 【你的任务】加载 data/reactions.json 并支持查表
## 设计问题先想清楚：查表时"火打水"和"水打火"算不算同一个？（见 docs/element-reactions.md）

var reactions: Dictionary = {}


func load_from_file(path: String) -> bool:
	var d = DataLoader.load_json(path)
	if typeof(d) != TYPE_DICTIONARY:
		return false
	var getr = d.get("reactions",{})
	if typeof(getr) != TYPE_DICTIONARY or getr.is_empty():
		return false
	reactions = getr
	return true


func get_reaction(a: String, b: String) -> Dictionary:
	var key:String = Element.pair_key(a,b)
	return reactions.get(key,{})


func has_reaction(a: String, b: String) -> bool:
	return not get_reaction(a,b).is_empty()


func reaction_count() -> int:
	return reactions.size()
