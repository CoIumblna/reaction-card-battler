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

const MAX_HAND := 9
const OPENING_HAND := 5
const KREDIT_CAP := 12

var player: Unit
var enemies: Array[Unit] = []
var deck: Array[Card] = []
var hand: Array[Card] = []
var reaction_table: ReactionTable
var board = Board.new()

var energy: int = 0
var max_energy: int = 0
var turn: int = 0
var log_lines: Array[String] = []

var enemy_energy: int = 0
var enemy_max_energy: int = 0
var enemy_hand: Array[Card] = []
var enemy_deck: Array[Card] = []


var rng = RandomNumberGenerator.new()

func setup(p_player: Unit, p_enemies: Array, p_deck: Array, table: ReactionTable, seed_value: int = 1) -> void:
	board.setup()
	rng.seed = seed_value
	turn = 0
	max_energy = 0
	hand.clear()
	energy = max_energy
	log_lines.clear()
	player = p_player
	enemies = p_enemies
	deck.clear()
	for i in p_deck:
		deck.append(i)
	enemy_max_energy = 0
	enemy_energy = 0
	enemy_deck.clear()
	for i in p_deck:
		enemy_deck.append(i)
	reaction_table = table
	pass


func alive_enemies() -> Array[Unit]:
	var out: Array[Unit] = []
	for i in enemies:
		if i.hp > 0:
			out.append(i)
	return out


func _hq_dead(line: String) -> bool:
	var hq := board.unit_at(line, Board.HQ_SLOT)
	return hq != null and hq.hp <= 0

func is_over() -> bool:
	return _hq_dead("enemy_support") or _hq_dead("player_support")

func outcome() -> String:
	if _hq_dead("enemy_support"):
		return "WIN"
	if _hq_dead("player_support"):
		return "LOSE"
	return "RUNNING"


func get_log() -> String:
	return "\n".join(log_lines)


func start_battle() -> void:
	_log("START enemies:%s" % _enemy_names())
	_draw_into(deck,hand,OPENING_HAND)
	_draw_into(enemy_deck,enemy_hand,OPENING_HAND)
	_begin_turn()
	

func _begin_turn() -> void:
	for i in Board.LINES:
		for u in board.units_in(i):
			if u.owner != "player" || u.is_hq:
				continue
			u.has_acted = false
	max_energy = min(max_energy+1,KREDIT_CAP)
	turn += 1
	energy = max_energy
	_draw_into(deck,hand,1)


func _enemy_ai() -> void:
	pass


func _enemy_turn() -> void:
	enemy_max_energy = min(enemy_max_energy + 1, KREDIT_CAP)
	enemy_energy = enemy_max_energy
	_draw_into(enemy_deck, enemy_hand, 1)
	for i in Board.LINES:
		for u in board.units_in(i):
			if u.owner != "enemy" || u.is_hq:
				continue
			u.has_acted = false
	_enemy_ai()


func end_turn() -> void:
	player.tick_buffs()
	for e in alive_enemies():
		e.tick_buffs()
	_enemy_turn()
	if is_over():return
	_begin_turn()


## 自动打完一整局（给测试和平衡模拟用）
func run_auto(max_turns: int = 30) -> String:
	start_battle()
	var guard:int = 0
	while not is_over() and turn < max_turns and guard < 200:
		for c in hand.duplicate():
			var foes := alive_enemies()
			if c.kind == "damage" and not foes.is_empty():
				play_card(c,foes[0])
			elif c.kind != "damage":
				play_card(c,player)
		end_turn()
		guard += 1
	return outcome()


func _deploy_unit(card: Card, owner: String) -> bool:
	if _energy_of(owner) < card.cost or board.first_empty_unit_slot(_line_of(owner)) == -1:
		return false
	_spend(owner,card.cost)
	var nu := Unit.new()
	nu = Unit.from_dict({"id":card.id,"name":card.display_name,"hp":card.defense,"attack":card.attack,"element":card.element,"owner":owner,"operation_cost":card.operation_cost})
	board.place(nu,_line_of(owner),board.first_empty_unit_slot(_line_of(owner)))
	nu.has_acted = true
	_hand_of(owner).erase(card)
	return true


func play_card(card: Card, target: Unit) -> bool:
	if card == null or target == null or card.cost > energy:
		return false
	if card.type == "unit":
		return _deploy_unit(card,"player")
	elif card.type == "order":
		energy -= card.cost
		match card.kind:
			"damage":
				var hit := compute_damage(card.power,card.element,target)
				var disc:int = target.take_damage(hit["damage"])
				if not hit.get("immune",false):
					_apply_aura(target,card.element,card.aura_amount)
				_log("%s对%s造成%d伤害" % [card.display_name,target.display_name,disc])
			"shield":
				target.shield += card.power
				_log("%s对%s添加%d护盾" % [card.display_name,target.display_name,card.power])
			"heal":
				target.heal(card.power)
				_log("%s对%s治疗%d点生命" % [card.display_name,target.display_name,card.power])
			_:
				_log("未知卡牌类型:%s"%card.kind)
		hand.erase(card)
		return true
	else:
		_log("未知类型%s"%card.type)
		return true


## 伤害计算：**具体算法在 src/core/damage.gd，这里只做转接**
## 为什么这样拆：M2 加棋盘后，"单位 A 打单位 B"也要用同一套伤害公式，
## 如果把算法写死在 battle.gd 里，M2 就得复制一遍。
func compute_damage(base_power: int, element: String, target: Unit) -> Dictionary:
	var d := Damage.compute(base_power,element,target,reaction_table)
	return d


## 设计问题：反应发生后，附着该被消耗还是保留？见 docs/element-reactions.md
func _apply_aura(target: Unit, element: String, amount: float) -> void:
	if element == Element.NONE:
		return
	if target.aura_element == Element.NONE and not element == Element.WIND and not element == Element.GEO:
		target.aura_amount = min(Unit.MAX_AMOUNT,amount)
		target.aura_element = element
	elif target.aura_element == element:
		target.aura_amount = min(Unit.MAX_AMOUNT,amount+target.aura_amount)
	else:
		var act = reaction_table.get_reaction(element,target.aura_element)
		var flag:bool = false
		for e in act.get("effects",[]):
			if e.get("kind","") == "aura":
				target.aura_element = e.get("element",Element.NONE)
				target.aura_amount = 1.0
				flag = true
		if not flag:
			var consume:float = float(act.get("consume",0.0))
			target.aura_amount -= consume
			amount -= consume
			if target.aura_amount <= 0 and amount > 0:
				if element == Element.WIND or element == Element.GEO:
					target.aura_element = Element.NONE
					return
				target.aura_element = element
				target.aura_amount = min(amount,Unit.MAX_AMOUNT)
			elif target.aura_amount <= 0 and amount <= 0:
				target.aura_element = Element.NONE
				target.aura_amount = 0.0


func move_unit(unit: Unit, to_line: String, to_index: int) -> bool:
	var pos := board.position_of(unit)
	if pos.is_empty() or pos[0] != _line_of(unit.owner) or to_line != "front":
		return false
	if unit.has_acted:
		return false
	if board.unit_at(to_line, to_index) != null:      # 目标格空，自己判
		return false
	var fee = unit.operation_cost
	if _energy_of(unit.owner) < fee:                                   # 能量够
		return false
	for u in board.units_in("front"):
		if u != null and u.owner != unit.owner:
			return false
	_spend(unit.owner,fee)
	if not board.move(_line_of(unit.owner), pos[1], "front", to_index):
		_gain(unit.owner,fee)                                  # 兜底回滚（理论上不会走到）
		return false
	unit.has_acted = true                              # ← 只有真成功了才标记
	_log("%s移动到%s %d"%[unit.display_name,to_line,to_index])
	return true


func attack_unit(attacker: Unit, target: Unit) -> bool:
	var at = board.position_of(attacker)
	var tar = board.position_of(target)
	if at.is_empty() or tar.is_empty() or attacker.has_acted:
		return false
	if abs(Board.LINES.find(at[0]) - Board.LINES.find(tar[0])) != 1:
		return false
	if _energy_of(attacker.owner) < attacker.operation_cost or attacker.owner == target.owner:
		return false
	_spend(attacker.owner,attacker.operation_cost)
	attacker.has_acted = true
	var dam:Dictionary = compute_damage(attacker.attack,attacker.element,target)
	var disc:int = target.take_damage(dam["damage"])
	if not dam["immune"]:
		_apply_aura(target,attacker.element,1.0)
		_log("%s攻击%s,造成%d%s元素伤害"%[attacker.display_name,target.display_name,disc,Element.display_name(attacker.element)])
	else : _log("%s攻击%s,伤害被免疫"%[attacker.display_name,target.display_name])
	if target.is_hq:
		return true
	var hurt:Dictionary = compute_damage(target.attack,target.element,attacker)
	var rdisc:int = attacker.take_damage(hurt["damage"])
	if not hurt["immune"]:
		_apply_aura(attacker,target.element,1.0)
		_log("%s攻击%s,造成%d%s元素伤害"%[target.display_name,attacker.display_name,rdisc,Element.display_name(target.element)])
	else : _log("%s攻击%s,伤害被免疫"%[target.display_name,attacker.display_name])
	if target.hp <= 0:
		board.remove(target)
		_log("%s退场"%target.display_name)
	if attacker.hp <= 0:
		board.remove(attacker)
		_log("%s退场"%attacker.display_name)
	return true


func _draw_into(target_deck: Array[Card],target_hand: Array[Card], n: int) -> void:
	for i in range(n):
		if target_deck.is_empty():
			break
		if target_hand.size() < MAX_HAND:
			target_hand.append(target_deck.front())
		target_deck.pop_front()


func _enemy_names() -> String:
	var names:Array[String] = []
	for e in enemies:
		names.append(e.display_name)
	return "、".join(names)


func _log(line: String) -> void:
	log_lines.append(line)
	print(line)
	
func _line_of(owner:String) -> String:
	return "player_support" if owner == "player" else "enemy_support"

func _energy_of(owner:String) -> int:
	return energy if owner == "player" else enemy_energy

func _spend(owner:String, n:int) -> void:
	if owner == "player":
		energy -= n
	else :
		enemy_energy -= n

func _gain(owner:String, n:int) -> void:
	if owner == "player":
		energy += n
	else :
		enemy_energy += n

func _hand_of(owner:String) -> Array[Card]:
	return hand if owner == "player" else enemy_hand
