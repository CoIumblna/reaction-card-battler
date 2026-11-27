class_name Element
extends RefCounted
const NONE := "none"

# 基础元素（6 个）
const FIRE := "fire"
const WATER := "water"
const LIGHTNING := "lightning"
const ICE := "ice"
const WIND := "wind"
const GEO := "geo"

## 附着持续时间（回合数）：普通附着用 BASE_DURATION，强附着（> 1U）用 STRONG_DURATION。
## 与 data/tables/elements.json 的 duration 字段一一对应，tools/validate_data.gd 会交叉校验。
const BASE_DURATION := {
	FIRE: 2,
	WATER: 2,
	LIGHTNING: 2,
	ICE: 2,
	WIND: 2,
	GEO: 2,
}
const STRONG_DURATION := 3

# 类顶部：数据只定义一次
const ELEMENT_NAMES := {
	"fire": "火",
	"water": "水",
	"wind": "风",
	"lightning": "雷",
	"ice": "冰",
	"geo": "岩",
	NONE: "无"
}


static func display_name(element: String) -> String:
	return ELEMENT_NAMES.get(element, "无")

## 只返回基础元素（v3 起没有复合元素了，遍历/UI 都只认这 6 个）
static func all() -> Array[String]:
	var out: Array[String] = [FIRE, WATER, WIND, LIGHTNING, ICE, GEO]
	return out


## 反应查表的键：与顺序无关，例如 火+水 => "fire+water"
## 方向性不在这里解决，而是交给 reactions.json 的 multiplier_by_attacker
static func pair_key(a: String, b: String) -> String:
	if a == Element.NONE or b == Element.NONE or a=="" or b=="":
		return ""
	if a<b:
		return a+"+"+b
	return b+"+"+a


## 这次附着应该给几个回合：强附着（amount > 1U）用 STRONG_DURATION，其余查 BASE_DURATION。
## 未知元素兜底 2 —— 宁可让它留 2 回合，也不要出现"0 回合立刻消失"的静默行为。
static func aura_duration(element_id: String, amount: float) -> int:
	if amount > 1.0:
		return STRONG_DURATION
	return int(BASE_DURATION.get(element_id, 2))
