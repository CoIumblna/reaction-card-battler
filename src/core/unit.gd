# 任务卡：docs/implementation-tasks.md 第 5 节（要写什么 / 用什么手段 / 怎么验收）
class_name Unit
extends RefCounted
## 【你的任务】伤害/护盾/治疗/附着量/buff 结算
##
## 注意三个概念要分开：
##   element       —— 单位自带的攻击元素（来自卡牌数据，M2 才用到）
##   immunities    —— 免疫的元素列表（伤害为 0、不触发反应、不消耗附着）

const MAX_AMOUNT := 2.0
const MAX_AURAS := 3        # 最多同时存在几槽附着；槽满时替换最旧的一槽（`innate` 护盾槽不参与替换）
const INNATE_REGEN_TURNS := 3   # 固有护盾被打破后，几个回合重新凝聚

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
var auras: Array = []       # 附着槽：[{ "element": String, "amount": float, "duration": int, "innate": bool }]，按创建顺序
var innate_template: Array = []   # from_dict 时深拷贝一份 innate 槽模板，供重生恢复
var innate_timer: int = INNATE_REGEN_TURNS   # 距离重生还有几回合；满盾时恒等于 INNATE_REGEN_TURNS
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
	newu.auras.clear()
	for a in d.get("auras", []):
		if typeof(a) != TYPE_DICTIONARY:
			continue
		var slot := {
			"element": str(a.get("element", Element.NONE)),
			"amount": float(a.get("amount", 0.0)),
			"duration": int(a.get("duration", 0)),
			"innate": bool(a.get("innate", false)),
		}
		newu.auras.append(slot)
		if bool(slot["innate"]):
			newu.innate_template.append(slot.duplicate(true))
	newu.innate_timer = INNATE_REGEN_TURNS
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


## 只查静态免疫名单（immunities）。旧语义：该元素伤害为 0、不反应、不挂槽。
func is_static_immune(element_id: String) -> bool:
	for i in immunities:
		if i == element_id:
			return true
	return false


## 该元素上是否有 innate 护盾槽（自带元素附着、免疫该元素伤害、但能被反应吃掉）。
func has_innate_shield(element_id: String) -> bool:
	for a in auras:
		if bool(a.get("innate", false)) and str(a.get("element", "")) == element_id:
			return true
	return false


## 当前所有 innate 护盾槽的元素 id（给日志/UI 用，按入槽顺序）。
func active_innate_elements() -> Array[String]:
	var out: Array[String] = []
	for a in auras:
		if bool(a.get("innate", false)):
			out.append(str(a.get("element", "")))
	return out


## 免疫 = 静态名单 ∪ innate 护盾槽。
func is_immune(element_id: String) -> bool:
	return is_static_immune(element_id) or has_innate_shield(element_id)


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


## 取某个元素的附着槽（返回的是数组里的那个字典本身，改它就是改状态）；没有返回 {}。
func get_aura(element_id: String) -> Dictionary:
	for a in auras:
		if str(a.get("element", "")) == element_id:
			return a
	return {}


## 加一槽或刷新已有槽：同元素 → 量相加封顶 MAX_AMOUNT、duration 取两者最大值；
## 不同元素 → 新槽（槽满先删最旧那一槽）。
## `innate` 护盾槽不参与叠加与挤占（满槽优先挤非 innate 的最旧槽）。
## 这里只做机械的记账，不判断元素能不能附着（风/岩不附着由调用方决定）。
func add_or_refresh_aura(element_id: String, amount: float, duration: int) -> void:
	if element_id == Element.NONE:
		return
	if has_innate_shield(element_id):
		return      # 护盾槽代表这个元素，普通附着不再叠加进去
	var cur: Dictionary = {}
	for a in auras:
		if bool(a.get("innate", false)):
			continue
		if str(a.get("element", "")) == element_id:
			cur = a
			break
	if not cur.is_empty():
		cur["amount"] = min(MAX_AMOUNT, float(cur.get("amount", 0.0)) + amount)
		cur["duration"] = max(int(cur.get("duration", 0)), duration)
		return
	if auras.size() >= MAX_AURAS:
		var victim: int = -1
		for i in range(auras.size()):
			if not bool(auras[i].get("innate", false)):
				victim = i
				break
		if victim < 0:
			return      # 3 槽全是护盾，普通元素挂不上（护盾优先）
		auras.remove_at(victim)
	auras.append({
		"element": element_id,
		"amount": min(MAX_AMOUNT, amount),
		"duration": max(1, duration),
		"innate": false,
	})


## 移除某个元素的槽，返回是否真的移除了。
func remove_aura(element_id: String) -> bool:
	for i in range(auras.size()):
		if str(auras[i].get("element", "")) == element_id:
			auras.remove_at(i)
			return true
	return false


## 回合开始结算：每槽 duration -= 1，归零的移除。返回被移除的元素 id（给战斗日志用，按入槽顺序）。
func tick_auras() -> Array[String]:
	var expired: Array[String] = []
	for i in range(auras.size() - 1, -1, -1):
		if bool(auras[i].get("innate", false)):
			continue      # 护盾槽不随时间衰减，由 tick_innate_shield 负责重生
		var a: Dictionary = auras[i]
		a["duration"] = int(a.get("duration", 0)) - 1
		if int(a["duration"]) <= 0:
			expired.append(str(a.get("element", "")))
			auras.remove_at(i)
	expired.reverse()
	return expired


## 回合开始结算固有护盾：破盾后第 INNATE_REGEN_TURNS 个回合按模板补回。
## 返回 true 表示这一回合重生了（给战斗日志用）。
## 满盾时不倒计时（破盾那一刻才开始数）。
func tick_innate_shield() -> bool:
	if innate_template.is_empty():
		return false
	if auras.filter(func(a): return bool(a.get("innate", false))).size() >= innate_template.size():
		innate_timer = INNATE_REGEN_TURNS
		return false
	innate_timer -= 1
	if innate_timer > 0:
		return false
	for t in innate_template:
		var el := str(t.get("element", Element.NONE))
		if has_innate_shield(el):
			continue
		if auras.size() >= MAX_AURAS:
			# 和 add_or_refresh_aura 一致：只挤最旧的非 innate 槽，护盾不让位
			var victim: int = -1
			for i in range(auras.size()):
				if not bool(auras[i].get("innate", false)):
					victim = i
					break
			if victim >= 0:
				auras.remove_at(victim)
		auras.append({
			"element": el,
			"amount": float(t.get("amount", 0.0)),
			"duration": 0,
			"innate": true,
		})
	innate_timer = INNATE_REGEN_TURNS
	return true


## 给日志/测试看的人类可读形式，例如 `火1U(2) 水2U(1)`；没有附着返回 `无`。
func describe_auras() -> String:
	if auras.is_empty():
		return "无"
	var parts: Array[String] = []
	for a in auras:
		if bool(a.get("innate", false)):
			parts.append("%s%dU(盾)" % [
				Element.display_name(str(a.get("element", ""))),
				int(a.get("amount", 0.0)),
			])
		else:
			parts.append("%s%dU(%d)" % [
				Element.display_name(str(a.get("element", ""))),
				int(a.get("amount", 0.0)),
				int(a.get("duration", 0)),
			])
	return " ".join(parts)


func describe() -> String:
	return "%s HP: %d/%d 元素附着: %s 护盾: %d" % [
		display_name,
		hp,
		max_hp,
		describe_auras(),
		shield
	]


func has_keyword(kw:String) -> bool:
	return kw in keywords


func is_tank() -> bool:
	return unit_class == "tank"


func is_artillery() -> bool:
	return unit_class == "artillery"


func is_fighter() -> bool:
	return unit_class == "fighter"


func is_bomber() -> bool:
	return unit_class == "bomber"


func is_air() -> bool:
	return unit_class == "bomber" || unit_class == "fighter"


func ignores_guard() -> bool:
	return unit_class == "artillery" || unit_class == "bomber"

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
