# 任务卡：docs/implementation-tasks.md 第 4 节（要写什么 / 用什么手段 / 怎么验收）
class_name Buff
extends RefCounted
## 【你的任务】实现 make() 和 describe()

var kind: String = ""
var stacks: int = 1
var duration: int = 1          # 剩余回合数


static func make(p_kind: String, p_duration: int = 2, p_stacks: int = 1) -> Buff:
	# TODO：返回一个填好字段的 Buff
	return Buff.new()


func describe() -> String:
	# TODO：例如 "燃烧×2（3 回合）"
	return ""
