# 任务卡：docs/implementation-tasks.md 第 8 节（要写什么 / 用什么手段 / 怎么验收）
class_name Battle
extends RefCounted
## 【你的任务】战斗内核：回合流程、出牌、伤害结算、自动战斗
## 这是整个项目最核心的一个文件，也是 [6][7] 两组测试考的东西
##
## 建议实现顺序：
##   1. setup() / alive_enemies() / is_over() / outcome()
##   2. start_battle() / _draw() / _begin_turn() / end_turn()
##   3. compute_damage() / play_card()
##   4. run_auto() / _log()
## 每写完一步就跑一次测试，别一次写完再跑。

const MAX_HAND := 5

var player: Unit
var enemies: Array[Unit] = []
var deck: Array[Card] = []
var hand: Array[Card] = []
var reaction_table: ReactionTable

var energy: int = 3
var max_energy: int = 3
var turn: int = 0
var log_lines: Array[String] = []


func setup(p_player: Unit, p_enemies: Array, p_deck: Array, table: ReactionTable, seed_value: int = 1) -> void:
	# TODO：把参数存进成员变量；清空手牌；能量回满；回合数归零
	pass


func alive_enemies() -> Array[Unit]:
	# TODO：只返回 hp > 0 的敌人
	var out: Array[Unit] = []
	return out


func is_over() -> bool:
	# TODO：玩家死了 或 敌人全死
	return false


func outcome() -> String:
	# TODO：返回 "WIN" / "LOSE" / "RUNNING"
	return "RUNNING"


func get_log() -> String:
	# TODO：把 log_lines 用换行拼成一个字符串
	return ""


func start_battle() -> void:
	# TODO：打印开场、抽初始手牌、进入第 1 回合
	pass


func end_turn() -> void:
	# TODO：buff 结算 → 敌人行动 → 玩家死了就结束 → 否则进入下一回合
	pass


## 自动打完一整局（给测试和平衡模拟用）
func run_auto(max_turns: int = 30) -> String:
	# TODO：循环「玩家把能打的牌打完 → end_turn」，直到分出胜负或超回合
	return "RUNNING"


func play_card(card: Card, target: Unit) -> bool:
	# TODO：校验能量/目标；按 kind 分发（damage / shield / heal）；从手牌移除
	return false


## 伤害计算：**具体算法在 src/core/damage.gd，这里只做转接**
## 为什么这样拆：M2 加棋盘后，"单位 A 打单位 B"也要用同一套伤害公式，
## 如果把算法写死在 battle.gd 里，M2 就得复制一遍。
func compute_damage(base_power: int, element: String, target: Unit) -> Dictionary:
	# TODO：调用 Damage.compute(base_power, element, target.aura, reaction_table)
	return { "damage": 0, "reaction": "", "multiplier": 1.0 }


## 设计问题：反应发生后，附着该被消耗还是保留？见 docs/element-reactions.md
func _apply_aura(target: Unit, element: String) -> void:
	pass


func _draw(n: int) -> void:
	pass


func _enemy_names() -> String:
	return ""


func _log(line: String) -> void:
	pass
