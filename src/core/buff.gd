class_name Buff
extends RefCounted

var kind: String = ""
var stacks: int = 1
var duration: int = 1          # 剩余回合数


static func make(p_kind: String, p_duration: int = 2, p_stacks: int = 1) -> Buff:
	var newb := Buff.new()
	newb.kind = p_kind
	newb.duration = p_duration
	newb.stacks = p_stacks
	return newb


func describe() -> String:
	return "%s×%d(%d回合)" % [
		kind,
		stacks,
		duration
	]
