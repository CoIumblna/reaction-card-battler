# 任务卡：docs/implementation-tasks.md 第 2 节（要写什么 / 用什么手段 / 怎么验收）
class_name Damage
extends RefCounted
## 【你的任务】伤害与元素反应的结算 —— 全项目最核心的一段
##
## 纯函数：不改任何状态。它只读 target 的附着/免疫，返回"这次攻击造成什么"。
## M2 的"单位打单位"会原样复用它。

## 找出第一个"能和 incoming 反应"的附着槽下标（按槽的创建顺序，最早优先）；没有返回 -1。
## 反应判定规则只在这里写一次 —— Damage.compute 用它算伤害，Battle._apply_aura 用它决定消耗哪一槽，
## 两处各写一份的话迟早会分叉。
## 同元素槽跳过（同元素是叠加，不是反应）。
static func find_reaction_slot(element: String, target: Unit, table: ReactionTable) -> int:
	if target == null or table == null:
		return -1
	if element == Element.NONE or element == "":
		return -1
	for i in range(target.auras.size()):
		var el := str(target.auras[i].get("element", Element.NONE))
		if el == Element.NONE or el == element:
			continue
		if table.has_reaction(element, el):
			return i
	return -1


## 返回字典：
## {
##   "damage": int,       最终伤害（**一律向下取整**）
##   "reaction": String,  反应名（无反应为 ""）
##   "multiplier": float, 倍率（无反应/非增幅为 1.0）
##   "consume": float,    本次消耗的附着量（无反应为 0.0）
##   "effects": Array,    反应附带的效果列表（damage/status/aura/shield/heal）
##   "immune": bool       是否被免疫
##   "reaction_slot": int 参与反应的是第几槽附着（没有反应为 -1）
## }
static func compute(base_power: int, element: String, target: Unit, table: ReactionTable) -> Dictionary:
	var damage:int = 0
	var immune:bool = false
	var reaction:String = ""
	var multiplier:float = 1.0
	var consume:float = 0.0
	var effects:Array = []
	var reaction_slot:int = find_reaction_slot(element, target, table)
	if target.is_immune(element):
		immune = true
		reaction_slot = -1
	elif reaction_slot < 0:
		damage = base_power
	else:
		var other := str(target.auras[reaction_slot].get("element", Element.NONE))
		var act = table.get_reaction(element, other)
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
		"reaction_slot": reaction_slot,
	}
