# 任务卡：docs/implementation-tasks.md 第 9 节（要写什么 / 用什么手段 / 怎么验收）
class_name StatusTable
extends RefCounted
## 【新增任务】状态表：读 data/tables/statuses.json，提供"这个状态什么效果"
##
## M1 只需实现 dot（回合开始掉血）和 disable（无法行动）；
## stat_mod 到 M2 再加（棋盘上才有防御概念）。

var statuses: Dictionary = {}


func load_from_file(path: String) -> bool:
	var d = DataLoader.load_json(path)
	if typeof(d) != TYPE_DICTIONARY:
		return false
	var gets = d.get("statuses",{})
	if typeof(gets) != TYPE_DICTIONARY or gets.is_empty():
		return false
	statuses = gets
	return true


func get_status(id: String) -> Dictionary:
	return statuses.get(id,{})


func has_status(id: String) -> bool:
	return not statuses.get(id,{}).is_empty()


func status_count() -> int:
	return statuses.size()
