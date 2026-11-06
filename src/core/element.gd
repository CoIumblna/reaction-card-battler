# 任务卡：docs/implementation-tasks.md 第 1 节（要写什么 / 用什么手段 / 怎么验收）
class_name Element
extends RefCounted
## 【你的任务】把 3 个 TODO 写完。测试就是规格：tests/data_test.gd [3]
## 元素表：data/tables/elements.json（基础 6 个 + 复合 2 个）
##
## ⚠️ 常量的值必须和数据表里的 id 完全一致（小写、下划线）。
##    改这里 = 改全项目契约 → 必须同步改 elements/reactions/cards/enemies + tests。

const NONE := "none"

# 基础元素（6 个）
const FIRE := "fire"
const WATER := "water"
const LIGHTNING := "lightning"
const ICE := "ice"
const WIND := "wind"
const GEO := "geo"

# 复合元素（共存状态的简化表示，上限 1U）
const ELECTRO_CHARGED := "electro_charged"
const FROZEN := "frozen"

# 类顶部：数据只定义一次
const ELEMENT_NAMES := {
	"fire": "火",
	"water": "水",
	"wind": "风",
	"lightning": "雷",
	"ice": "冰",
	"geo": "岩",
	"electro_charged": "感电",   # 复合元素也要有中文名
	"frozen": "冻结",
}


static func display_name(element: String) -> String:
	return ELEMENT_NAMES.get(element, "无")

## 只返回基础元素（复合元素不参与常规遍历/UI）
static func all() -> Array[String]:
	# TODO：返回 6 个基础元素
	var out: Array[String] = [FIRE, WATER, WIND, LIGHTNING, ICE, GEO]
	return out


## 反应查表的键：与顺序无关，例如 火+水 => "fire+water"
## 方向性不在这里解决，而是交给 reactions.json 的 multiplier_by_attacker
static func pair_key(a: String, b: String) -> String:
	# TODO：任一为 NONE/空 → ""；否则排序后 "a+b"
	if a == Element.NONE or b == Element.NONE or a=="" or b=="":
		return ""
	if a<b:
		return a+"+"+b
	return b+"+"+a
