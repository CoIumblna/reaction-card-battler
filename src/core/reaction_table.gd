# 任务卡：docs/implementation-tasks.md 第 6 节（要写什么 / 用什么手段 / 怎么验收）
class_name ReactionTable
extends RefCounted
## 【你的任务】加载 data/reactions.json 并支持查表
## 设计问题先想清楚：查表时"火打水"和"水打火"算不算同一个？（见 docs/element-reactions.md）

var reactions: Dictionary = {}


func load_from_file(path: String) -> bool:
	# TODO：读 JSON，把 reactions 字段取出来；失败返回 false
	return false


func get_reaction(a: String, b: String) -> Dictionary:
	# TODO：用 Element.pair_key(a, b) 查表；查不到返回 {}
	return {}


func has_reaction(a: String, b: String) -> bool:
	# TODO：get_reaction 非空即为 true
	return false


func reaction_count() -> int:
	return 0
