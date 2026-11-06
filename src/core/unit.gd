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
	var newu := Unit.new()
	newu.id = str(d.get("id",""))
	newu.display_name = str(d.get("name",newu.id))
	newu.max_hp = int(d.get("hp",0))
	newu.hp = newu.max_hp
	
	newu.shield = int(d.get("shield",0))
	newu.element = str(d.get("element",Element.NONE))
	newu.aura_element = str(d.get("aura_element",Element.NONE))
	newu.aura_amount = float(d.get("aura_amount",0.0))
	newu.immunities.clear()
	for e in d.get("immunities", []):
		newu.immunities.append(str(e))
	newu.buffs.clear()
	for b in d.get("buffs", []):
		newu.buffs.append(str(b))
	return newu


func is_alive() -> bool:
	return hp>0


func is_immune(element_id: String) -> bool:
	for i in immunities:
		if i == element_id:
			return true
	return false


## 返回实际掉的血（被护盾吸收的不算）
func take_damage(amount: int) -> int:
	if shield >= amount:
		shield -= amount
		return 0
	else:
		amount -=shield
		shield = 0
		hp -= amount
		hp = max(0,hp)
		return amount


func heal(amount: int) -> void:
	hp += amount
	hp = min(max_hp,hp)


func add_buff(b: Buff) -> void:
	buffs.append(b)


## 每回合结束：duration - 1，到期的移除
func tick_buffs() -> void:
	var next_buffs:Array[Buff] = []
	for i in range(0,buffs.size()):
		buffs[i].duration -= 1
		if buffs[i].duration > 0:
			next_buffs.append(buffs[i])
	buffs = next_buffs


func describe() -> String:
	return "%s HP: %d/%d 元素附着: %s 元素量: %dU 护盾: %d" % [
		display_name,
		hp,
		max_hp,
		Element.display_name(aura_element),
		aura_amount,
		shield
	]
