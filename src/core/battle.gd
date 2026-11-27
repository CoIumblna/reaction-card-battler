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
const FIRST_HAND := 4
const SECOND_HAND := 5
const KREDIT_CAP := 12
const DATA_PATH := "res://data/tables/statuses.json"

var player: Unit
var enemies: Array[Unit] = []
var deck: Array[Card] = []
var hand: Array[Card] = []
var reaction_table: ReactionTable 
var board = Board.new()
var status_table: StatusTable = StatusTable.new()
var first_move:String = ""
var opening_phase = false

var energy: int = 0
var max_energy: int = 0
var turn: int = 0
var log_lines: Array[String] = []
var discard : Array[Card] = []
var fatigue_cnt: int = 0
var mulligan_used: bool = false


var enemy_energy: int = 0
var enemy_max_energy: int = 0
var enemy_hand: Array[Card] = []
var enemy_deck: Array[Card] = []
var enemy_discard : Array[Card] = []
var enemy_fatigue_cnt: int = 0
var enemy_turns_taken:int = 0
var enemy_mulligan_used: bool = false


var rng = RandomNumberGenerator.new()

func setup(p_player: Unit, p_enemies: Array, p_deck: Array, table: ReactionTable, seed_value: int = 1) -> void:
	status_table.load_from_file(DATA_PATH)
	board.setup()
	rng.seed = seed_value
	opening_phase = false
	turn = 0
	max_energy = 0
	hand.clear()
	energy = max_energy
	fatigue_cnt = 0
	discard.clear()
	log_lines.clear()
	mulligan_used = false
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
	enemy_discard.clear()
	enemy_fatigue_cnt = 0
	enemy_turns_taken = 0
	enemy_mulligan_used = false


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
	#_log("START enemies:%s" % _enemy_names())
	if first_move == "":
		first_move = "enemy" if rng.randi_range(0,1) else "player"
	_draw_into(first_move,FIRST_HAND)
	_draw_into(_opposite(first_move),SECOND_HAND)
	opening_phase = true


func begin_first_turn() -> void:
	opening_phase = false
	if first_move == "enemy":
		_enemy_turn()
		if is_over():
			return
	_begin_turn()


func _begin_turn() -> void:
	for i in Board.LINES:
		for u in board.units_in(i):
			if u.owner != "player" || u.is_hq:
				continue
			u.reset_actions()
	_settle_status("player")
	max_energy = min(max_energy+1,KREDIT_CAP)
	turn += 1
	energy = max_energy
	if turn == 1 && first_move == "player":
		return
	_draw_into("player",1)

func _ai(owner:String) -> void:#这是初版ai,后续会加入各种流派卡组专用的ai
	var utmp: Card = null
	for u in _hand_of(owner):
		if u.type == "order":
			continue
		if u.cost > _energy_of(owner): continue
		if utmp == null || utmp.cost <= u.cost:
			utmp = u
	if utmp != null:
		_deploy_unit(utmp,owner)
	
	if board.has_unit_of("front") != _opposite(owner):
		for u in board.units_in(_support_of(owner)):
			if u.is_hq || not u.can_move() || u.operation_cost > _energy_of(owner):
				continue
			move_unit(u,"front",board.first_empty_unit_slot("front"))
			
	for l in Board.LINES:
		for u in board.units_in(l):
			if u.owner != owner or u.is_hq:
				continue
			_ai_attack(u,owner)
			if is_over():
				return
	




func _enemy_turn() -> void:
	for i in Board.LINES:
		for u in board.units_in(i):
			if u.owner != "enemy" || u.is_hq:
				continue
			u.reset_actions()
	_settle_status("enemy")
	enemy_turns_taken += 1
	enemy_max_energy = min(enemy_max_energy + 1, KREDIT_CAP)
	enemy_energy = enemy_max_energy
	if enemy_turns_taken != 1 || first_move != "enemy":
		_draw_into("enemy", 1)
	_ai("enemy")


func end_turn() -> void:
	_enemy_turn()
	if is_over():return
	_begin_turn()


## 自动打完一整局（给测试和平衡模拟用）
func run_auto(max_turns: int = 200) -> String:
	start_battle()
	begin_first_turn()
	var guard:int = 0
	while not is_over() and turn < max_turns and guard < max_turns:
		_ai("player")
		end_turn()
		guard += 1
	return outcome()


func _deploy_unit(card: Card, owner: String) -> bool:
	if _energy_of(owner) < card.cost or board.first_empty_unit_slot(_line_of(owner)) == -1:
		return false
	_spend(owner,card.cost)
	var nu := Unit.new()
	nu = Unit.from_dict({
		"id":card.id,
		"name":card.display_name,
		"hp":card.defense,
		"attack":card.attack,
		"element":card.element,
		"owner":owner,
		"operation_cost":card.operation_cost,
		"keywords":card.keywords,
		"abilities":card.abilities,
		"unit_class":card.unit_class
		})
	if nu.is_blitz():nu.reset_actions()
	else:nu.block_actions()
	board.place(nu,_line_of(owner),board.first_empty_unit_slot(_line_of(owner)))
	_hand_of(owner).erase(card)
	return true


func play_card(card: Card, target: Unit) -> bool:
	if card == null or target == null or card.cost > energy:
		return false
	if card.type == "unit":
		return _deploy_unit(card,"player")
	elif card.type == "order":
		var on_board = board.position_of(target) != []
		var legacy = enemies.has(target) or target == player
		if not on_board and not legacy: return false
		if on_board:
			if card.target == "enemy" and target.owner != "enemy":return false
			if card.target == "self" and target.owner != "player":return false
		match card.kind:
			"damage":
				var hit := compute_damage(card.power,card.element,target)
				var disc:int = target.take_damage(hit["damage"])
				if not hit.get("immune",false):
					_apply_aura(target,card.element,card.aura_amount)
				_log("%s对%s造成%d伤害" % [card.display_name,target.display_name,disc])
				if target.hp <= 0 && not target.is_hq:
					_log("%s退场"%target.display_name)
					board.remove(target)
			"shield":
				target.shield += card.power
				_log("%s对%s添加%d护盾" % [card.display_name,target.display_name,card.power])
			"heal":
				target.heal(card.power)
				_log("%s对%s治疗%d点生命" % [card.display_name,target.display_name,card.power])
			_:
				_log("未知卡牌类型:%s"%card.kind)
		energy -= card.cost
		hand.erase(card)
		_discard_of("player").append(card)
		return true
	else:
		_log("未知类型%s"%card.type)
		return true


## 伤害计算：**具体算法在 src/core/damage.gd，这里只做转接**
## 为什么这样拆：M2 加棋盘后，"单位 A 打单位 B"也要用同一套伤害公式，
## 如果把算法写死在 battle.gd 里，M2 就得复制一遍。
func compute_damage(base_power: int, element: String, target: Unit) -> Dictionary:
	var d := Damage.compute(base_power,element,target,reaction_table)
	if not d.get("immune",false):
		d["damage"] = max(0,int(d["damage"]-stat_of(target,"defense")))
	return d


func stat_of(unit:Unit, stat:String) -> int:
	var res:int = 0
	if stat == "attack":
		res = unit.attack
	elif stat == "defense":
		res = 0 
	for b in unit.buffs:
		var status:Dictionary = status_table.get_status(b.kind)
		for e in status.get("effects",[]):
			if str(e.get("kind","")) != "stat_mod" || str(e.get("stat","")) != stat:
				continue
			var timing := str(e.get("timing",""))
			if timing != "" and timing !="passive":
				continue
			res += int(round(float(e.get("value",0.0)))) * b.stacks
	return res


## 给目标挂上 incoming 元素。规则见 docs/element-reactions-v3.md §3：
##   1. NONE 不处理；2. 免疫该元素不处理；3. 按槽创建顺序找第一个能反应的槽；
##   4. 有反应 → 结算 status 效果 + 旧槽扣 consume（≤0 移除）+ 残留量入新槽；
##   5. 无反应 → 同元素叠加 / 否则新槽；6. 风、岩只参与反应、自身不附着。
## 反应里的 damage / shield / heal 三种效果目前**故意不实现**（历史遗留的死数据，
## 补上会改变平衡基线，留给单独一块做）。
func _apply_aura(target: Unit, element: String, amount: float) -> void:
	if target == null or element == Element.NONE:
		return
	if target.is_immune(element):
		return
	var idx := Damage.find_reaction_slot(element, target, reaction_table)
	var residual: float = amount
	if idx >= 0:
		var other := str(target.auras[idx].get("element", Element.NONE))
		var act := reaction_table.get_reaction(element, other)
		for e in act.get("effects", []):
			match str(e.get("kind", "")):
				"status":
					target.add_buff(Buff.make(str(e.get("id", "")), int(e.get("duration", 0))))
				_:
					pass
		var consume := float(act.get("consume", 0.0))
		var left := float(target.auras[idx].get("amount", 0.0)) - consume
		if left <= 0.0:
			target.auras.remove_at(idx)
		else:
			target.auras[idx]["amount"] = left
		residual = amount - consume
	if residual <= 0.0:
		return
	if element == Element.WIND or element == Element.GEO:
		return
	target.add_or_refresh_aura(element, residual, Element.aura_duration(element, residual))


func move_unit(unit: Unit, to_line: String, to_index: int) -> bool:
	var pos := board.position_of(unit)
	if pos.is_empty() or pos[0] != _line_of(unit.owner) or to_line != "front":
		return false
	if not unit.can_move():
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
	unit.has_moved = true                              # ← 只有真成功了才标记
	_log("%s移动到%s %d"%[unit.display_name,to_line,to_index])
	return true


func attack_unit(attacker: Unit, target: Unit) -> bool:
	var at = board.position_of(attacker)
	var tar = board.position_of(target)
	if at.is_empty() or tar.is_empty() or not attacker.can_attack():
		return false
	if not _line_span_to(attacker,at[0],tar[0]):
		return false
	if _energy_of(attacker.owner) < attacker.operation_cost or attacker.owner == target.owner:
		return false
	if _is_guarded(target) and not attacker.ignores_guard(): return false
	if attacker.is_bomber() and board.has_fighter(tar[0]) and not target.is_fighter(): return false
	_spend(attacker.owner,attacker.operation_cost)
	attacker.has_attacked = true
	var dam:Dictionary = compute_damage(stat_of(attacker,"attack"),attacker.element,target)
	var disc:int = target.take_damage(dam["damage"])
	if not dam["immune"]:
		_apply_aura(target,attacker.element,1.0)
		_log("%s攻击%s,造成%d%s元素伤害"%[attacker.display_name,target.display_name,disc,Element.display_name(attacker.element)])
	else : _log("%s攻击%s,伤害被免疫"%[attacker.display_name,target.display_name])
	if target.is_hq:
		return true
	if not no_counter(attacker,target):
		var hurt:Dictionary = compute_damage(stat_of(target,"attack"),target.element,attacker)
		var rdisc:int = attacker.take_damage(hurt["damage"])
		if not hurt["immune"]:
			_apply_aura(attacker,target.element,1.0)
			_log("%s攻击%s,造成%d%s元素伤害"%[target.display_name,attacker.display_name,rdisc,Element.display_name(target.element)])
		else : _log("%s攻击%s,伤害被免疫"%[target.display_name,attacker.display_name])
		if attacker.hp <= 0:
			board.remove(attacker)
			_log("%s退场"%attacker.display_name)
	if target.hp <= 0:
		board.remove(target)
		_log("%s退场"%target.display_name)
	return true


func _draw_into(owner:String, n: int) -> void:
	if _turn_of(owner) == 1 && first_move == owner:
		return
	for i in range(n):
		if _deck_of(owner).is_empty():
			_hq_of(owner).hp = max(0,_hq_of(owner).hp-_fatigue_add(owner))
			continue
		if _hand_of(owner).size() < MAX_HAND:
			_hand_of(owner).append(_deck_of(owner).front())
		else :_discard_of(owner).append(_deck_of(owner).front())
		_deck_of(owner).pop_front()


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


func _discard_of(owner:String) -> Array[Card]:
	return discard if owner == "player" else enemy_discard


func _deck_of(owner:String) -> Array[Card]:
	return deck if owner == "player" else enemy_deck


func _support_of(owner:String) -> String:
	return "enemy_support" if owner == "enemy" else "player_support"


func _opposite(owner:String) -> String:
	return "player" if owner == "enemy" else "enemy"


func _opposite_hq(owner:String) -> Unit:
	return board.PLAYER_HQ if owner == "enemy" else board.ENEMY_HQ


func _hq_of(owner:String) -> Unit:
	return board.PLAYER_HQ if owner == "player" else board.ENEMY_HQ


func _fatigue_add(owner:String) -> int:
	if owner == "player":
		fatigue_cnt+=1
		return fatigue_cnt
	else: 
		enemy_fatigue_cnt+=1
		return enemy_fatigue_cnt


func _settle_status(owner:String) -> void:
	for l in Board.LINES:
		for u in board.units_in(l):
			if u.owner != owner || u.is_hq:
				continue
			for b in u.buffs:
				var status = status_table.get_status(b.kind)
				for e in status.get("effects",[]):
					match e["kind"]:
						"dot":
							if e.get("timing","") == "turn_start":
								var dot := u.take_damage(int(floor(e.get("value",0.0) * b.stacks)))
								_log("%s受到%d点dot伤害"%[u.display_name,dot])
								if u.hp <= 0 && not u.is_hq:
									board.remove(u)
						"disable":
							if e.get("timing","") == "action":
								u.block_actions()
								_log("%s冻结"%u.display_name)
						_:
							pass
			u.tick_buffs()
			if u.is_alive():
				var expired := u.tick_auras()
				for el in expired:
					_log("%s的%s附着结束" % [u.display_name, Element.display_name(el)])


func _mulligan_of(owner:String) -> bool:
	return mulligan_used if owner == "player" else enemy_mulligan_used


func _turn_of(owner:String) -> int:
	return turn if owner == "player" else enemy_turns_taken


func mulligan(owner: String, cards: Array) -> bool:
	if opening_phase == false || _mulligan_of(owner) == true || cards.is_empty():
		return false
	for c in cards:
		if not c in _hand_of(owner):
			return false
	var siz:int = cards.size()
	for c in cards: 
		_hand_of(owner).erase(c)
		_deck_of(owner).append(c)
	shuffle(_deck_of(owner))
	_draw_into(owner,siz)
	if owner == "player": mulligan_used = true
	else: enemy_mulligan_used = true
	return true


func shuffle(dck:Array[Card]) -> void:
	for i in range(dck.size()-1,0,-1):
		var j:int =rng.randi_range(0,i)
		var tmp = dck[i]
		dck[i] = dck[j]
		dck[j] = tmp


func _is_guarded(target:Unit) -> bool:
	if target == null: return false
	if target.is_guard(): return false
	var tmp = board.position_of(target)
	if tmp.is_empty(): return false
	for i in range(Board.SLOT_COUNT):
		if abs(i-tmp[1]) == 1:
			if board.slots[tmp[0]][i] != null && board.slots[tmp[0]][i].is_guard():
				return true
	return false


func no_counter(attacker:Unit, target:Unit) -> bool:
	if attacker.is_bomber() and not target.is_fighter():
		return true
	if attacker.is_artillery():
		return true
	if target.is_bomber():
		return true
	return false


func _line_span_to(attacker:Unit, from:String, to:String) -> bool:
	if abs(Board.LINES.find(from)-Board.LINES.find(to)) == 1:
		return true
	elif attacker.is_air():
		return true
	return false


func _ai_attack_targets(owner:String) -> Array[Unit]:
	var out:Array[Unit] = []
	var fst:Array[Unit] = []
	var sec:Array[Unit] = []
	out.append(_opposite_hq(owner))
	for l in Board.LINES:
		for u in board.units_in(l):
			if u == _opposite_hq(owner):continue
			if u.owner == _opposite(owner):
				if u.is_guard():
					sec.append(u)
				elif not _is_guarded(u):
					fst.append(u)
	for u in fst:out.append(u)
	for u in sec:out.append(u)
	return out


func _ai_attack(unit:Unit, owner:String) -> bool:
	if unit == null: return false
	if unit.owner != owner: return false
	if _energy_of(owner) < unit.operation_cost: return false
	if unit.has_attacked: return false
	var at:Array = board.position_of(unit)
	var avai:Array[Unit] = _ai_attack_targets(owner)
	if avai.is_empty(): return false
	for u in avai:
		var to:Array = board.position_of(u)
		if _line_span_to(unit,at[0],to[0]):
			if attack_unit(unit,u):
				return true
	return false
