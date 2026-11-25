# 任务卡：docs/implementation-tasks.md 第 5 节（要写什么 / 用什么手段 / 怎么验收）
class_name Unit
extends RefCounted
## 【你的任务】伤害/护盾/治疗/附着量/buff 结算
##
## 注意三个概念要分开：
##   element       —— 单位自带的攻击元素（来自卡牌数据，M2 才用到）
##   aura_element  —— 身上附着的元素（会随反应消耗/清空）
##   immunities    —— 免疫的元素列表（伤害为 0、不触发反应、不消耗附着）

const MAX_AMOUNT := 2.0

var id: String = ""
var display_name: String = ""
var max_hp: int = 30
var hp: int = 30
var shield: int = 0
var attack: int = 0
var has_moved: bool = false
var has_attacked: bool = 0
var is_hq: bool =false
var operation_cost: int = 1
var owner: String = ""
var unit_class: String = ""


var element: String = Element.NONE          # 自身攻击元素（M2 用）
var aura_element: String = Element.NONE     # 附着元素
var aura_amount: float = 0.0                # 附着量，上限 2.0；复合元素上限 1.0
var immunities: Array[String] = []
var keywords: Array[String] = []

var buffs: Array[Buff] = []


static func from_dict(d: Dictionary) -> Unit:
	var newu := Unit.new()
	newu.id = str(d.get("id",""))
	newu.display_name = str(d.get("name",newu.id))
	newu.max_hp = int(d.get("hp",0))
	newu.attack = int(d.get("attack",0))
	newu.is_hq = bool(d.get("is_hq",false))
	newu.hp = newu.max_hp
	newu.owner = str(d.get("owner",""))
	newu.unit_class = str(d.get("unit_class",""))
	newu.shield = int(d.get("shield",0))
	newu.element = str(d.get("element",Element.NONE))
	newu.aura_element = str(d.get("aura_element",Element.NONE))
	newu.aura_amount = float(d.get("aura_amount",0.0))
	newu.immunities.clear()
	newu.operation_cost = int(d.get("operation_cost",1))
	for e in d.get("immunities", []):
		newu.immunities.append(str(e))
	newu.buffs.clear()
	for b in d.get("buffs", []):
		newu.buffs.append(str(b))
	newu.keywords.clear()
	for k in d.get("keywords",[]):
		newu.keywords.append(str(k))
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


func add_buff(buff: Buff) -> void:
	for b in buffs:
		if b.kind == buff.kind:
			b.stacks += 1
			b.duration = max(b.duration,buff.duration)
			return
	buffs.append(buff)


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


func has_keyword(kw:String) -> bool:
	return kw in keywords


func is_tank() -> bool:
	return unit_class == "tank"


func is_blitz() -> bool:
	return "blitz" in keywords


func is_guard() -> bool:
	return "guard" in keywords


func reset_actions() -> void:
	has_attacked = false
	has_moved = false


func block_actions() -> void:
	has_attacked = true
	has_moved = true


func can_move() -> bool:
	if has_moved:
		return false
	if has_attacked and not is_tank():
		return false
	return true

func can_attack() -> bool:
	if has_attacked:
		return false
	if has_moved and not is_tank():
		return false
	return true
