# 任务卡：docs/implementation-tasks.md 第 2 节（要写什么 / 用什么手段 / 怎么验收）
class_name Damage
extends RefCounted
## 【你的任务】伤害与元素反应的结算 —— 全项目最核心的一段
##
## 纯函数：不改任何状态。它只读 target 的附着/免疫，返回"这次攻击造成什么"。
## M2 的"单位打单位"会原样复用它。

## 返回字典：
## {
##   "damage": int,       最终伤害（**一律向下取整**）
##   "reaction": String,  反应名（无反应为 ""）
##   "multiplier": float, 倍率（无反应/非增幅为 1.0）
##   "consume": float,    本次消耗的附着量（无反应为 0.0）
##   "effects": Array,    反应附带的效果列表（damage/status/aura/shield/heal）
##   "immune": bool       是否被免疫
## }
static func compute(base_power: int, element: String, target: Unit, table: ReactionTable) -> Dictionary:
	var damage:int = 0
	var immune:bool = false
	var reaction:String = ""
	var multiplier:float = 1.0
	var consume:float = 0.0
	var effects:Array = []
	if target.is_immune(element):
		immune = true
	elif table == null or target.aura_element == Element.NONE or (not table.has_reaction(element,target.aura_element)):
		damage = base_power
	else:
		var act = table.get_reaction(element,target.aura_element)
		if not act.get("multiplier_by_attacker",{}).is_empty():
			multiplier = float(act["multiplier_by_attacker"].get(element,1.0))
		damage = int(floor(multiplier * base_power))
		reaction = act.get("name","")
		consume = float(act.get("consume",0.0))
		for i in act.get("effects",[]):
			effects.append(i)
	return {
		"damage": damage,
		"reaction": reaction,
		"multiplier": multiplier,
		"consume": consume,
		"effects": effects,
		"immune": immune,
	}
