# 任务卡：docs/implementation-tasks.md 第 3 节（要写什么 / 用什么手段 / 怎么验收）
class_name Card
extends RefCounted
## 【你的任务】把一条 JSON 变成 Card 对象
##
## 卡牌 = 四种互相独立的属性：
##   element      元素（决定打谁触发什么反应）
##   unit_class   兵种（M2：步兵/坦克/炮兵/战斗机/轰炸机；M1 不用）
##   keywords     词条（M2：blitz/guard…；M1 不用）
##   abilities    可释放技能（M2；M1 不用）
## 外加卡牌自身属性：type（unit/order）、cost、attack/defense（单位）、power（指令效果值）

var id: String = ""
var display_name: String = ""
var type: String = "unit"        # unit / order（M1 的卡都是 order，M2 才有 unit）
var cost: int = 1
var operation_cost: int = 0      # M2：移动/攻击的额外花费
var element: String = Element.NONE
var unit_class: String = ""      # M2
var keywords: Array[String] = [] # M2
var abilities: Array[String] = []# M2
var attack: int = 0              # M2（单位）
var defense: int = 0             # M2（单位）
var kind: String = "damage"      # M1：damage / shield / heal
var power: int = 0
var aura_amount: float = 1.0     # 本次攻击的附着量（1U 普通 / 2U 强附着）
var target: String = "enemy"     # enemy / self


static func from_dict(d: Dictionary) -> Card:
	var c := Card.new()
	
	return c


func describe() -> String:
	return ""
