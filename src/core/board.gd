# 任务卡：docs/implementation-tasks.md 第 11 节（要写什么 / 用什么手段 / 怎么验收）
class_name Board
extends RefCounted
## 【你的任务】棋盘：三条战线、每线 5 格、支援线 0 号格是 HQ
##
## 位置只存在这里（单一真相源），Unit 不存 line —— 存两份状态必然不同步。
##
## 实现顺序：
##   1. setup()        —— 建空格 + 放双方 HQ
##   2. unit_at()      —— 读格子（越界要返回 null，不能崩）
##   3. place()        —— 占格（线合法 + 下标合法 + 该格为空）
##   4. capacity_of() / first_empty_unit_slot() / units_in()
## 每写完一步跑一次：--script res://tests/board_test.gd

const LINES := ["enemy_support", "front", "player_support"]
const SLOT_COUNT := 5
const HQ_SLOT := 0                    # 支援线 0 号格是 HQ
const UNIT_SLOTS_PER_SUPPORT := 4     # 5 格 - 1 个 HQ
const HQ_DEFENSE := 20

## 线名 -> Array（长度 SLOT_COUNT，空位为 null）
var slots: Dictionary = {}
var ENEMY_HQ := Unit.new()
var PLAYER_HQ := Unit.new()
 
func setup() -> void:
	ENEMY_HQ = Unit.from_dict({"id":"e_hq","name":"敌方总部","hp":HQ_DEFENSE,"is_hq":true})
	PLAYER_HQ = Unit.from_dict({"id":"p_hq","name":"友方总部","hp":HQ_DEFENSE,"is_hq":true})
	for ids in LINES:
		slots[ids] = []
		for i in range(5):
			slots[ids].append(null)
		if ids == "enemy_support":
			slots[ids][HQ_SLOT] = ENEMY_HQ
		elif ids == "player_support":
			slots[ids][HQ_SLOT] = PLAYER_HQ


func in_board(x: int) -> bool:
	return x>=0 and x<SLOT_COUNT


func unit_at(line: String, index: int) -> Unit:
	if LINES.find(line) == -1 or not in_board(index):
		return null
	return slots[line][index]


func place(unit: Unit, line: String, index: int) -> bool:
	if LINES.find(line) == -1 or not in_board(index) or unit_at(line,index) != null:
		return false
	slots[line][index] = unit
	return true


func first_empty_unit_slot(line: String) -> int:
	if LINES.find(line) == -1:
		return -1
	for i in range(SLOT_COUNT):
		if slots[line][i] == null:
			return i
	return -1


func units_in(line: String) -> Array[Unit]:
	var out: Array[Unit] = []
	if LINES.find(line) == -1: 
		return out
	for u in slots[line]:
		if u != null: 
			out.append(u)
	return out


func capacity_of(line: String) -> int:
	if LINES.find(line) == -1:
		return 0
	elif line == "front":
		return SLOT_COUNT
	else :
		return UNIT_SLOTS_PER_SUPPORT


func position_of(unit: Unit) -> Array:
	for l in LINES:
		var index = slots[l].find(unit) 
		if index != -1:
			return [l,index]
	return []


func move(from_line: String,from_index: int,to_line: String,to_index: int) -> bool:
	if LINES.find(from_line) == -1 or LINES.find(to_line) == -1 or not in_board(from_index) or not in_board(to_index) or slots[from_line][from_index] == null or slots[to_line][to_index] != null:
		return false 
	slots[to_line][to_index] = slots[from_line][from_index]
	slots[from_line][from_index] = null
	return true
