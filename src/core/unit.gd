# 任务卡：docs/implementation-tasks.md 第 5 节（要写什么 / 用什么手段 / 怎么验收）
class_name Unit
extends RefCounted
## 【你的任务】伤害/护盾/治疗/附着量/buff 结算
##
## 注意三个概念要分开：
##   element       —— 单位自带的攻击元素（来自卡牌数据，M2 才用到）
##   aura_element  —— 身上附着的元素（会随反应消耗/清空）
##   immunities    —— 免疫的元素列表（伤害为 0、不触发反应、不消耗附着）

var id: String = ""
var display_name: String = ""
var max_hp: int = 30
var hp: int = 30
var shield: int = 0

var element: String = Element.NONE          # 自身攻击元素（M2 用）
var aura_element: String = Element.NONE     # 附着元素
var aura_amount: float = 0.0                # 附着量，上限 2.0；复合元素上限 1.0
var immunities: Array[String] = []

var buffs: Array[Buff] = []


static func from_dict(d: Dictionary) -> Unit:
	# TODO：id / name / hp / immunities；hp = max_hp
	return Unit.new()


func is_alive() -> bool:
	return false


func is_immune(element_id: String) -> bool:
	# TODO：element_id 是否在 immunities 里
	return false


## 返回实际掉的血（被护盾吸收的不算）
func take_damage(amount: int) -> int:
	return 0


func heal(amount: int) -> void:
	pass


func add_buff(b: Buff) -> void:
	pass


## 每回合结束：duration - 1，到期的移除
func tick_buffs() -> void:
	pass


func describe() -> String:
	# TODO：例如 "史莱姆 HP 11/24 附着火 1.0U 盾3"
	return ""
