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
	# TODO 1：target.is_immune(element) 为真 → 返回伤害 0、reaction ""、immune true
	# TODO 2：table 为 null 或 target 无附着 → 按基础伤害算
	# TODO 3：查表后检查 trigger_attacker（风/岩只有主动攻击时触发）
	# TODO 4：增幅类：从 multiplier_by_attacker 里按 element 取倍率；其它类倍率 1.0
	# TODO 5：最终伤害 = int(floor(base_power × multiplier))
	# TODO 6：把 reactions 里的 effects / consume 原样放进返回值
	return {
		"damage": 0,
		"reaction": "",
		"multiplier": 1.0,
		"consume": 0.0,
		"effects": [],
		"immune": false,
	}
