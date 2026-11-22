# 实现任务卡（每个文件要你写什么、用什么手段、怎么验收）

> 用法：每次动手前先看对应那一节，写完回来打勾。
> **本文件只给"要什么"，不给代码。** 卡住了再去看 `..\_reference_battler\`（先自己写 20 分钟）。

## 进度总览

| # | 文件 | 任务数 | 难度 | 预计行数 | 验收（测试分组） | 完成 |
|---|---|---|---|---|---|---|
| 1 | `element.gd` | 3 | ★ | 15 | data_test[3] | [x] |
| 2 | `damage.gd` | 5 | ★★ | 40 | damage_test[D1–D6] | [x] |
| 3 | `card.gd` | 2 | ★ | 20 | data_test[1] | [x] |
| 4 | `buff.gd` | 2 | ★ | 10 | unit_test[5] | [x] |
| 5 | `unit.gd` | 7 | ★★ | 45 | unit_test[1–4] | [x] |
| 6 | `reaction_table.gd` | 4 | ★★ | 25 | data_test[4] | [x] |
| 7 | `data_loader.gd` | 3 | ★★ | 40 | data_test[1][2] | [x] |
| 8 | `battle.gd` | 13 | ★★★ | 150 | battle_m1_smoke_test[1–5] | [x] |
| 9 | `status_table.gd` | 4 | ★★ | 25 | data_test[5] | [x] |
| 10 | `unit.gd`（M2 扩展） | 3 | ★ | 15 | board_test[1] | [x] |
| 11 | `board.gd` | 6 | ★★★ | 80 | board_test[2][3] | [x] |
| 12 | `hq`（在 board / battle 内） | 3 | ★★ | 30 | board_test[2] | [x] |
| 13 | `battle.gd`（M2：Kredit / 部署 / 召唤失调） | 3 | ★★ | 60 | battle_m2_test[1–3] | [x] |
| 14 | `board.gd` + `battle.gd`（M2：移动 / 攻击 / 行动花费） | 5 | ★★★ | 90 | combat_test[1–3] | [x] |
| 15 | `unit.gd` + `battle.gd`（M2：owner / 前线独占） | 2 | ★★ | 40 | combat_test[2][5]、board_test[2] | [x] |
| 16 | `board.gd` + `battle.gd`（M2：死亡移除） | 2 | ★ | 20 | combat_test[6] | [x] |
| 17 | `battle.gd`（M2：胜负改 HQ）+ M1 测试退役 | 3 | ★★ | 40 | battle_m2_test[5] | [x] |
| 18 | `battle.gd`（M2：敌方 AI + run_auto） | 4 | ★★★ | 150 | battle_m2_test[3][6][7] | [x] |
| 19 | `battle.gd`（M2 收尾：状态效果 C8） | 4 | ★★★ | 120 | status_test[0–3] | [x] |
| 20 | `battle.gd`（E14：指令卡打在棋盘单位上） | 3 | ★★ | 40 | order_test[1–5] | [x] |
| 21 | `battle.gd`（E7：牌堆/弃牌/换牌） | 4 | ★★★ | 80 | deck_test[0–6] | [ ] |
| 22 | `card.gd`+`unit.gd`+`battle.gd`（M3.1：关键词 + 闪击） | 3 | ★★ | 60 | keywords_test | [ ] |
| 23 | `battle.gd`（M3.2：护卫 Guard，待拍板） | 3 | ★★★ | 50 | guard_test | [ ] |
| 24 | `unit.gd`+`battle.gd`（M3.1：行动经济/关键词/Blitz） | 3 | ★★★ | 80 | keywords_test | [ ] |
| 25 | `battle.gd`（M3.2：Guard） | 3 | ★★★ | 70 | guard_test | [ ] |
| 26 | `battle.gd`（M3.3：兵科基础 + 空军越线） | 2 | ★★★ | 120 | combat_test 增补 | [ ] |
| 27 | `data/cards.json`（M3.4：卡池 20+） | 1 | ★★ | 0（数据） | data_test + validate_data | [ ] |
| 28 | `battle.gd`+`data_loader.gd`（M3.5：卡组构筑 39+1） | 2 | ★★★ | 60 | deck_build_test | [ ] |
| 29 | `element.gd`+`unit.gd`+`damage.gd`+`battle.gd`（M3.6：元素 v3 多槽） | 4 | ★★★★ | 300 | aura_v3_test | [ ] |
| 30 | `unit.gd`+`battle.gd`（M3.7：stat_mod 数值系统） | 1 | ★★ | 40 | status_test 增补 | [ ] |
| 31 | 平衡（M3.8：balance_sim 调参） | 3 | ★★★ | 60 | docs/balance-report.md | [ ] |

**建议顺序**：1 → 3 → 7 → 6 → 2 → 5 → 4 → 8（先打通数据链路，再写伤害算法，最后拼战斗流程）

---

## 1. `src/core/element.gd` —— 元素常量与配对键

**职责**：给元素起名字、把两个元素变成一个查表的键。纯函数，没有状态。

| 函数 | 输入 → 输出 | 用什么手段 | 达成效果 | 验收 |
|---|---|---|---|---|
| `all()` | 无 → `Array[String]` | 先 `var out: Array[String] = []` 再 append，或直接把字面量赋给带类型的变量 | 别处能遍历所有元素（比如以后做 UI 下拉框） | 无直接测试 |
| `display_name(e)` | 元素 id → 中文名 | `match` 或查字典 | 日志里显示"火"而不是"fire" | 间接 |
| `pair_key(a, b)` | 两个元素 → `"fire+water"` | `Array[String]` + `sort()` + `"%s+%s" % [...]` | 让"火打水"和"水打火"查到同一条反应 | data_test[3] |

**坑**
- 任一参数是 `NONE` 或 `""` 时必须返回 `""`，否则会查到不存在的键
- `sort()` 是字典序排序，`fire` < `lightning` < `water`，所以结果一定是 `fire+water` 这种顺序

**不要做**：不要在这里存反应倍率（那是 `reactions.json` 的事）。

---

## 2. `src/core/damage.gd` —— 伤害与元素反应（全项目最核心的一段）

**职责**：纯函数。给定「基础值 + 攻击元素 + 目标（附着量/免疫）+ 反应表」，算出这次攻击造成什么。
**它不知道战斗、不知道卡牌、不知道 UI**——M2 的"单位打单位"原样复用它。

返回字典：

| 键 | 类型 | 含义 |
|---|---|---|
| `damage` | int | 最终伤害，**一律向下取整** |
| `reaction` | String | 反应名，无反应为 `""` |
| `multiplier` | float | 倍率，无反应/非增幅为 `1.0` |
| `consume` | float | 本次消耗的附着量 |
| `effects` | Array | 反应附带效果（damage/status/aura/shield/heal） |
| `immune` | bool | 是否被免疫 |

**实现要点（6 步）**
1. 先查免疫：`target.is_immune(element)` → 伤害 0、`reaction` 空、`consume` 0、`immune` true
2. 表为 null 或目标无附着 → 按基础伤害
3. 用 `table.get_reaction(element, target.aura_element)` 查表
4. 增幅类：从 `multiplier_by_attacker` 按攻击元素取倍率；其它类型倍率 1.0
5. `damage = int(floor(base_power * multiplier))`（**floor 不是 round**）
6. `consume` / `effects` 原样放进返回值，交给 Battle 去执行

**坑**
- 是 floor 不是四舍五入：`5 × 1.5 = 7.5 → 7`
- 免疫**优先于**反应：免疫时不能触发反应、不能消耗附着
- 无反应时 `reaction` 是 `""`，`consume` 是 `0.0`

**不要做**：不要改目标状态（那是 Battle 的事）、不要打日志、不要读文件。

---
## 3. `src/core/card.gd` —— 一张卡的数据

**职责**：把一条 JSON 变成对象；把对象变成人能读的一行字。**不负责任何战斗计算。**

| 函数 | 输入 → 输出 | 用什么手段 | 达成效果 | 验收 |
|---|---|---|---|---|
| `from_dict(d)` | 字典 → `Card` | 逐字段 `str()` / `int()` 转换 + `d.get("key", 默认值)` | 改 JSON 就能加卡，不用改代码 | data_test[1] |
| `describe()` | 无 → 一行文字 | `"%s（%s｜费 %d｜%s %d）" % [...]` 格式化 | 战斗日志可读 | 间接 |

**坑**
- 中文 JSON 字段是 `name`，你的变量叫 `display_name`，注意映射
- `get()` 的默认值要合理：`cost` 默认 1，`kind` 默认 `"damage"`

**不要做**：不要写"这张卡造成多少伤害"——那是 `battle.gd` + `compute_damage()` 的事。

---

## 4. `src/core/buff.gd` —— 状态效果

**职责**：只装数据（类型/层数/剩余回合），**不负责触发效果**。

| 函数 | 输入 → 输出 | 用什么手段 | 达成效果 | 验收 |
|---|---|---|---|---|
| `make(kind, duration, stacks)` | 三个参数 → `Buff` | `Buff.new()` 后赋值 | 别处能一行造一个 buff | 间接 |
| `describe()` | 无 → `"燃烧×2（3 回合）"` | 字符串格式化 | 日志里能看出敌人身上有什么 | 间接 |

**注意**：M1 阶段没人调用它，这是正常的——它是为 M2 的"反应附加状态"准备的。写完后在 devlog 记一句"留了个未使用的类"，这叫**有意为之的预留**。

---

## 5. `src/core/unit.gd` —— 战斗单位的数值结算

**职责**：管好自己的血、盾、附着量、免疫、buff。**不问回合，不问卡牌。**

**三个概念要分开**：`element`（自带攻击元素，M2 用）/ `aura_element` + `aura_amount`（附着，会被反应消耗）/ `immunities`（免疫元素列表）。

| 函数 | 输入 → 输出 | 用什么手段 | 达成效果 | 验收 |
|---|---|---|---|---|
| `from_dict(d)` | 字典 → `Unit` | 读 `id/name/hp`，然后 `hp = max_hp` | 敌人从 JSON 生成 | data_test[1] |
| `is_alive()` | 无 → bool | `hp > 0` | 战斗循环判断胜负 | unit_test[3] |
| `take_damage(amount)` | 伤害 → **实际掉血** | `mini(shield, amount)` 算吸收；`maxi(0, hp - 剩余)` 保底 | 护盾先扛、血不出现负数、返回值给日志用 | unit_test[2] |
| `heal(amount)` | 治疗量 → 无 | `mini(max_hp, hp + amount)` | 治疗不会超上限 | unit_test[4] |
| `add_buff(b)` | Buff → 无 | `buffs.append(b)` | 挂状态 | 间接 |
| `tick_buffs()` | 无 | 先全部 `duration -= 1`，再把 `duration > 0` 的放进新数组赋回去 | buff 到期自动消失 | 间接 |
| `describe()` | 无 → 一行 | 格式化 HP + 护盾 + 附着 | 日志形如 `史莱姆 HP 11/24 附着火` | 间接 |

**坑**
- `take_damage` 的返回值是**实际掉血**（护盾吸收掉的不算），`unit_test`[2] 就考这个
- `tick_buffs` 不要在遍历时 `erase`（会跳元素），用"新建数组再赋值"
- `buffs` 是带类型的 `Array[Buff]`，`filter()` 返回的是普通 Array，**直接赋值会类型不匹配**——这也是上面让你手写循环的原因

**不要做**：不要在这里判断"该谁行动"，也不要读全局状态。

---

## 6. `src/core/reaction_table.gd` —— 反应表

**职责**：把 `reactions.json` 读进内存，提供"给我两个元素，我给你反应"的能力。

| 函数 | 输入 → 输出 | 用什么手段 | 达成效果 | 验收 |
|---|---|---|---|---|
| `load_from_file(path)` | 路径 → bool | 复用 `DataLoader.load_json()`；取 `data["reactions"]`；失败返回 false | 反应表可替换（改 JSON 不改代码） | data_test[4] |
| `get_reaction(a, b)` | 两元素 → 字典 | `Element.pair_key(a,b)` 得到键，再 `reactions.get(key, {})` | 查不到时返回 `{}` 而不是 null | data_test[4] |
| `has_reaction(a, b)` | 两元素 → bool | `not get_reaction(...).is_empty()` | 给"是否触发反应"判断用 | data_test[4] |
| `reaction_count()` | 无 → int | `reactions.size()` | 加载后能自检"有没有读到 3 条" | data_test[4] |

**坑**
- `dict.get(key, {})` 返回的是 `Variant`，先判 `typeof(r) == TYPE_DICTIONARY` 再返回，否则后面 `r.get("name")` 会炸
- 这里是**唯一**允许"知道反应表长什么样"的地方；`battle.gd` 只调用它，不自己解析 JSON

---

## 7. `src/core/data_loader.gd` —— 数据入口

**职责**：全项目唯一读文件的地方。任何"从磁盘拿数据"的代码都只能在这。

| 函数 | 输入 → 输出 | 用什么手段 | 达成效果 | 验收 |
|---|---|---|---|---|
| `load_json(path)` | 路径 → 字典 | `FileAccess.file_exists()` → `FileAccess.get_file_as_string()` → `JSON.parse_string()` → `typeof() == TYPE_DICTIONARY` 判断 | 任何数据文件都能安全读取，坏文件不崩溃 | data_test[1] |
| `load_cards(path)` | 路径 → `Array[Card]` | 取 `data["cards"]` 遍历，`Card.from_dict()` | JSON → 对象列表 | data_test[1][2] |
| `load_enemies(path)` | 路径 → `Array[Unit]` | 同上，用 `Unit.from_dict()` | 同上 | data_test[2] |

**坑**
- `JSON.parse_string` 解析失败**不抛异常，返回 null**，必须显式判断
- 数组元素可能不是字典（手写 JSON 容易漏括号），要 `typeof(item) == TYPE_DICTIONARY` 跳过
- 报错用 `push_error()`，消息里带上路径——M2 会要求更精确（哪个文件第几条缺哪个字段）

**不要做**：不要在这里做字段的业务校验（比如"cost 不能为负"），那是 `tools/validate_data.gd` 的事。

---

## 8. `src/core/battle.gd` —— 战斗内核（最大的一块）

**职责**：回合流程 + 出牌 + 伤害结算 + 自动战斗。**不碰界面，不读文件（数据由外部传进来）。**

### 8.1 状态与初始化

| 函数 | 输入 → 输出 | 用什么手段 | 达成效果 | 验收 |
|---|---|---|---|---|
| `setup(player, enemies, deck, table, seed)` | 五个参数 | 逐个存进成员变量；`hand.clear()`；`energy = max_energy`；`turn = 0`；`log_lines.clear()`；`rng.seed = seed` | 一局战斗的可控起点（固定种子=可复现） | battle_test[1] |
| `alive_enemies()` | 无 → `Array[Unit]` | 遍历过滤 `is_alive()` | 给"还有没有敌人"用 | battle_test[6] |
| `is_over()` | 无 → bool | 玩家死 **或** 敌人全死 | 循环退出条件 | battle_test[6] |
| `outcome()` | 无 → 字符串 | 三分支返回 `"WIN"`/`"LOSE"`/`"RUNNING"` | 结算结果 | battle_test[6] |
| `get_log()` | 无 → 字符串 | `"\n".join(log_lines)` | 一次拿到完整战斗记录 | battle_test[7] |

### 8.2 回合流程

| 函数 | 输入 → 输出 | 用什么手段 | 达成效果 | 验收 |
|---|---|---|---|---|
| `start_battle()` | 无 | 打日志 → 抽起手 5 张 → `_begin_turn()`（第 1 回合也抽 1 张） | 战斗开始（手牌 5+1=6 张） | battle_test[2] |
| `_begin_turn()` | 无 | `turn += 1`；能量回满；抽 **1** 张（`_draw(1)`）；打日志 | 每回合资源重置，**不是补满** | battle_test[2] |
| `_draw(n)` | 张数 | 从 `deck` 头部 `pop_front()` 抽 n 张；**手牌满 `MAX_HAND` 时抽到的牌直接丢弃、牌库照扣**；牌库空就停 | 发牌 | battle_test[2] |
| `end_turn()` | 无 | buff 结算 → 敌人攻击（先写死 4 点）→ 玩家死则结束 → 否则 `_begin_turn()` | 敌方回合 | battle_test[2] |

> **手牌规则（2026-11-08 改，M1）**：`MAX_HAND = 9`；起手固定 5 张（与 `MAX_HAND` 无关）。
> `start_battle()` 抽起手 5 张后进第 1 回合，第 1 回合也抽 1 张 → 开局手牌 6 张。
> 之后每回合只抽 1 张，**不补满**。手牌已满 9 张仍要抽：牌堆顶那张弹出后直接丢弃，牌库照扣。
> 先后手起手差异（KARDS 先手 4 / 后手 5 + mulligan）留到 M2，M1 统一 5 张。

### 8.3 出牌与伤害（本项目的心脏）

| 函数 | 输入 → 输出 | 用什么手段 | 达成效果 | 验收 |
|---|---|---|---|---|
| `play_card(card, target)` | 卡 + 目标 → bool | **先校验**（null / 能量够 / 目标活着）→ 扣能量 → `match kind` 分发 → `hand.erase(card)` → true | 一张卡真正生效 | battle_test[3] |
| `compute_damage(base, element, target)` | 基础值 + 元素 + 目标 → 字典 | 查 `reaction_table.get_reaction(element, target.aura)`；有反应就乘 `multiplier`；`int(round(...))` 取整 | 火打水附着 = 10 × 1.5 = 15 | battle_test[5] |
| `_apply_aura(target, element)` | 目标 + 元素 | 附着 / 叠加（上限 2U）/ 反应消耗；**wind 和 geo 不产生附着，直接 return** | 让第二次同元素攻击能触发反应（或不能） | battle_test[4] |

**`play_card` 的分发逻辑（三种 kind）**
- `damage`：`compute_damage()` → `target.take_damage()` → 打日志（含反应名和倍率）
- `shield`：给自己加护盾
- `heal`：给自己回血
- 其它：打一行"未知类型"日志，不要崩

**坑（这一块最容易翻车）**
- **先校验再扣能量**，否则出牌失败也扣能量（`battle_test`[3] 就考这个）
- `compute_damage` 返回字典的键名必须是 `damage` / `reaction` / `multiplier`（测试按名字取值）
- 无反应时 `reaction` 返回空串 `""`，不是 `null`
- `hand.erase()` 要用**同一个对象引用**（JSON 加载出来的 Card 对象是同一份）

### 8.4 自动战斗

| 函数 | 输入 → 输出 | 用什么手段 | 达成效果 | 验收 |
|---|---|---|---|---|
| `run_auto(max_turns)` | 回合上限 → `"WIN"/"LOSE"` | `start_battle()` 后循环：能打的牌打完 → `end_turn()`，直到 `is_over()` 或超回合 | 一条命令验证整局规则 | battle_test[7] |
| `_log(line)` | 一行文字 | `log_lines.append()` + `print()` | 同时给人看和给程序用 | battle_test[7] |
| `_enemy_names()` | 无 → 字符串 | 遍历拼 `、` | 开场日志 | 间接 |

**坑**
- 遍历 `hand` 时 `play_card` 会 `erase` 元素 → 必须 `hand.duplicate()` 再遍历
- 加"安全计数器"（比如最多循环 20 次），防止 0 费卡导致死循环
- `end_turn()` 里不要再调 `start_battle()`，否则回合数会失控

---

## 9. `src/core/status_table.gd` —— 状态表

**职责**：读 `data/tables/statuses.json`，回答"这个状态什么效果"。
M1 只实现两种时机：`turn_start`（dot 掉血）和 `action`（无法行动）；`passive`（减防）到 M2。

| 函数 | 输入 → 输出 | 用什么手段 | 验收 |
|---|---|---|---|
| `load_from_file(path)` | 路径 → bool | 复用 `DataLoader.load_json()`，取 `statuses` 字段 | data_test[5] |
| `get_status(id)` | id → 字典 | `statuses.get(id, {})` + 类型判断 | data_test[5] |
| `has_status(id)` | id → bool | `not get_status(id).is_empty()` | data_test[5] |
| `status_count()` | 无 → int | `statuses.size()` | data_test[5] |

**注意**：这里只存"状态定义"，**不负责触发**。触发在 `Battle` 的回合开始/结束时做。

---

## 10. `src/core/unit.gd`（M2 扩展 / E1）—— 单位上战场要的字段

M1 的 Unit 是"血条 + 附着"，M2 要能站上棋盘、攻击、被打。只加三个字段：

| 字段 | 类型 | 含义 | 默认 |
|---|---|---|---|
| `attack` | int | 单位攻击力，部署时取 `card.attack` | 0 |
| `has_acted` | bool | 本回合是否已行动（移动或攻击，二选一） | false |
| `is_hq` | bool | 是不是 HQ（不能移动/攻击） | false |

`from_dict()` 要能读 `attack` / `is_hq`；`hp` 继续当"当前防御"，`max_hp` 当"最大防御"。

**不要加 `line` / `position`** —— 位置只在 `Board` 里存。Unit 也存一份必然不同步，
这是 M2 最容易埋的雷（见 `docs/adr/003-m2-board.md`）。

验收：`board_test[1]`

## 11. `src/core/board.gd` —— 棋盘（M2 / E2）

**职责**：三条战线 × 每线 5 格；支援线 0 号格是 HQ。**位置只在这里。**

| 函数 | 输入 → 输出 | 实现要点 | 验收 |
|---|---|---|---|
| `setup()` | 无 | 每条线建 5 个空格（null）；支援线 `HQ_SLOT` 放 HQ（`is_hq`、20 防） | board_test[2] |
| `unit_at(line, index)` | → `Unit` | 空位 / 非法线 / 越界 → `null`，**不许崩** | board_test[2][3] |
| `place(unit, line, index)` | → bool | 线合法 + 下标在界内 + 该格为 `null` 才放 | board_test[3] |
| `first_empty_unit_slot(line)` | → int | 支援线从 `HQ_SLOT + 1` 开始；满返回 -1 | board_test[3] |
| `units_in(line)` | → `Array[Unit]` | 该线所有非空单位（**含 HQ**）；非法线返回空数组 | board_test[3] |
| `capacity_of(line)` | → int | `front` = 5；支援线 = 4；非法线 = 0 | board_test[3] |

**坑**
- 支援线是 5 格但只有 4 个单位位（0 号被 HQ 占）—— 算容量别直接拿 `SLOT_COUNT`
- 空位用 `null`，**不要缩短数组**：下标就是格子
- `slots` 用 `Dictionary`（线名 → 长度 5 的数组）；下标越界要返回 `null`，别让测试脚本崩

## 12. HQ（M2 / E3）

- HQ **就是一个 `Unit`**：`is_hq = true`、`max_hp = 20`、`attack = 0`、不许移动/攻击
- 双方各一个，放在己方支援线 0 号格（由 `Board.setup()` 创建）
- 胜负（E13 才接到 `Battle`）：敌方 HQ 被破坏 → `WIN`；我方 HQ 被破坏 → `LOSE`

**为什么不用单独的 `HQ` 类**：HQ 要挨伤害、要被当攻击目标，复用 `Unit.take_damage()` / `is_alive()`
最省事；单独一个类会让 `Damage.compute()` 多一条分支，违背"伤害只有一份算法"。

验收：`board_test[2]`；接入胜负在 `battle_test`（M2 版，E13）

---

## 13. Kredit 成长（M2 / E6）

M1 是固定 3 点。M2 改成 KARDS 式成长：

| 项 | 值 |
|---|---|
| 开局（`setup`） | `max_energy = 0`、`energy = 0` |
| 每个回合开始 | `max_energy = min(max_energy + 1, KREDIT_CAP)`，**然后** `energy = max_energy` |
| 上限 | `const KREDIT_CAP := 12`（KARDS 原版数值，一个常量改全局） |

出牌 / 部署照旧只扣 `energy`。

**坑**
- 别再写死 3；`max_energy` 是变量，M1 那句 `energy = max_energy` 继续用
- 顺序：**先涨上限，再回满** —— 写反了第 1 回合会少 1 点
- 第 1 回合是 **1 点**（setup 0 → 第 1 回合 +1）

验收：`battle_m2_test[1]`

## 14. 单位部署（M2 / E4）

`Battle` 加 `var board: Board`，`setup()` 里 `board = Board.new()` + `board.setup()`。

`play_card()` 先按 `card.type` 分流：

| `card.type` | 走哪 |
|---|---|
| `"order"` | 原逻辑（`match kind` → damage / shield / heal） |
| `"unit"` | 部署（下表） |
| 其它 | 打一行"未知类型"日志，不崩 |

**部署六步**

| # | 做什么 |
|---|---|
| 1 校验 | 能量够 **且** `board.first_empty_unit_slot("player_support") != -1` |
| 2 扣能量 | `energy -= card.cost` |
| 3 造单位 | `Unit.from_dict({ id, name, hp: card.defense, attack: card.attack, element: card.element })` |
| 4 上场 | `board.place(unit, "player_support", 空位下标)` |
| 5 召唤失调 | `unit.has_acted = true` |
| 6 移出手牌 | `hand.erase(card)` |

单位卡数据形态（用 `tools/add_unit_card.gd` 生成）：
`type: "unit"` / `cost` / `attack` / `defense` / `element` / `count`

**样例数值**（E4 写完再往牌库里加，现在加会污染 M1 的 battle_test）：

| id | 名称 | 费 | 攻 | 防 | 元素 |
|---|---|---|---|---|---|
| footman | 步兵 | 1 | 1 | 2 | none |
| archer | 弓手 | 2 | 2 | 1 | none |
| fire_mage | 火法师 | 3 | 2 | 3 | fire |
| tank | 坦克 | 4 | 4 | 5 | none |
| water_priest | 水祭司 | 3 | 1 | 3 | water |

**坑**
- `hp` 取 `card.defense`，**卡牌上没有 `hp` 字段**
- 支援线只有 4 个空位，满了要**先校验再扣能量**（`battle_m2_test[2]` 专门考这个）
- 部署不是"打伤害"，别让它掉进 damage 分支
- 过渡期：`player` / `enemies` 字段保留（M1 流程还在跑），E13 把胜负改成看 HQ 之后再删

验收：`battle_m2_test[2]`

## 15. 召唤失调（M2 / E5）

- 单位**部署的瞬间** `has_acted = true` → 当回合不能移动/攻击
- 每个回合开始时，**己方所有单位**（支援线 + 前线）`has_acted = false`
- HQ 不参与（HQ 永远不行动）

实现位置：`_begin_turn()` 里遍历**三条线**，把 `owner == "player"` 且**非 HQ** 的单位的 `has_acted` 清零。

> ⚠️ **M2 遗留 bug（E15 必须先修）**：现在只清了 `board.units_in("player_support")`，
> 于是推进到 `front` 的单位永远 `has_acted = true` → **永远不能攻击**；敌方单位更是没有任何地方清零。
> 修法见 §23「回合开始清 `has_acted` 的范围」。`battle_m2_test[3]` 有一条专门卡前线这条。

验收：`battle_m2_test[3]`

## 16. 移动（M2 / E8）

**铁律：每回合只能「移动」或「攻击」二选一**（落地就是 `has_acted`）。

| 项 | 规则 |
|---|---|
| 允许的方向 | **己方支援线 → 前线**（单向前进）。**不能后退**，不能跳线，两条支援线之间不互通 |
| 目标格 | 必须是空的 |
| 谁能动 | 在棋盘上、且 `has_acted == false`（召唤失调的单位也算 true） |
| 前线独占 | 敌方占着前线时不能进 —— **这条 E11 再做**，E8 先不判 |

> **为什么是单向**：KARDS 里"退回支援线"是 `Retreat` 关键词（卡牌效果，见 M3 的 E17），
> 不是常规行动。所以普通移动只有前进一种。同理，你不能移动敌方单位 —— 只有
> `player_support → front` 这条对玩家开放（敌方 AI 走 `enemy_support → front`）。

**先给 `Board` 加两个方法**

| 函数 | 输入 → 输出 | 实现要点 |
|---|---|---|
| `position_of(unit)` | → `Array` | 返回 `[line, index]`；不在棋盘上返回 `[]` |
| `move(from_line, from_index, to_line, to_index)` | → bool | 两边坐标合法 + 目标格为空 → 挪过去（原格置 null） |

**再给 `Battle` 加**

| 函数 | 输入 → 输出 | 顺序 |
|---|---|---|
| `move_unit(unit, to_line, to_index)` | → bool | 校验（在棋盘 / 未行动 / 目标空 / 相邻 / 能量够）→ 扣**作战费** → `board.move()` → `has_acted = true` |

验收：`combat_test[1]`

## 17. 攻击（M2 / E9）

| 项 | 规则 |
|---|---|
| 能把谁当目标 | **相邻线**上的敌方单位，或敌方 HQ |
| 敌我判定 | 同阵营不能互打：`attacker.owner == target.owner` → 拒绝（见 §19） |
| 相邻关系 | `player_support` ↔ `front` ↔ `enemy_support`；同侧不相邻；两条支援线不互通 |
| 反击 | 目标是普通单位 → **双方各走一次伤害结算**；目标是 HQ → **不反击**，只掉 HQ 防 |
| 伤害来源 | **一律走 `compute_damage()`**（带元素 / 反应 / 免疫 / 附着），不是 `take_damage(attack)` |
| 伤害永久 | 掉的血不会自己回来 |
| 每回合 | 攻击完 `has_acted = true` |
| 死亡 | `hp <= 0` 的离场 —— **这条 E12 做**，本片只负责扣血 |

`attack_unit(attacker, target) -> bool` 顺序：
校验（攻击者在棋盘且未行动 / 目标在棋盘 / 线相邻 / 能量够）→ 扣**作战费** →

```
主伤害：var hit := compute_damage(attacker.attack, attacker.element, target)
        target.take_damage(hit["damage"])
        若 not hit["immune"] → _apply_aura(target, attacker.element, 1.0)
反击（目标不是 HQ 时，反过来同样一套）：
        var back := compute_damage(target.attack, target.element, attacker)
        attacker.take_damage(back["damage"])
        若 not back["immune"] → _apply_aura(attacker, target.element, 1.0)
```

→ `attacker.has_acted = true` → 日志

> **为什么必须走 `compute_damage` 而不是 `take_damage(attacker.attack)`**
> ① 元素反应是本项目的原创玩法，单位对撞不查表 = 只有指令卡能触发反应，单位全是白板；
> ② `Unit.immunities` 直接失效（火史莱姆免疫火，单位打它照样掉血）；
> ③ ADR-002 抽 `Damage.compute()` 的唯一理由，就是"M2 单位对撞原样复用"。

**坑**
- 单位攻击的附着量按 **1U** 传（`Unit` 上没有 `aura_amount`，别去读 `Card` 的）
- 打 HQ 时 `HQ.attack == 0`，统一写"互相 `take_damage`"会让攻击者挨 0 点 ——
  数值没事，但日志多一行"反击 0"，而且 E12 判死亡时会拧。显式判 `target.is_hq`
- `attack` 是单位攻击力，**不是**卡牌的 `power`（`power` 是指令卡的）
- `take_damage()` 返回真实掉血（护盾吸收后），日志用返回值，别用 `attacker.attack`

验收：`combat_test[2]`、`combat_test[4]`（单位对撞触发反应）

## 18. 行动花费（M2 / E10）

- `Unit` 加 `operation_cost: int = 1`，`from_dict` 读 `operation_cost`（缺省 1）
- **`Card.from_dict` 的 `operation_cost` 缺省值也必须是 1（不是 0）**，这样"没写"和"显式写 0"才分得开：

  | 卡牌数据 | `card.operation_cost` | 含义 |
  |---|---|---|
  | 没写 `operation_cost` | `1` | 缺省：正常收费 |
  | 显式写 `"operation_cost": 0` | `0` | **合法值**：移动/攻击免费（M3 的内容卡会用，比如侦察兵） |
  | 显式写 `"operation_cost": 2` | `2` | 重装单位，行动更贵 |

- 部署时：`unit.operation_cost = card.operation_cost`，**不要在部署里再对 0 做归一化**（0 是合法值，不是漏写）
- 移动、攻击都要付；**先校验能量再扣**
- 能量不足：返回 `false`，不扣费、不移位、不标记已行动

验收：`combat_test[3]`

## 19. 单位归属：`owner`（M2 / E11 前置）

`Unit` 加 `var owner: String = ""`，取值 `"player"` / `"enemy"`。

| 谁负责设置 | 值 |
|---|---|
| `Battle` 部署单位时 | `"player"` |
| `Board.setup()` 建的两个 HQ | 我方 `"player"`、敌方 `"enemy"` |
| `Unit.from_dict()` | 从字典读 `owner`（测试要用） |

**为什么必须加**：`front` 是双方**共享**的一条线，光看位置分不出敌我。没有 `owner`：

- `attack_unit` 会放行"打友军"（`front` ↔ `player_support` 相邻，差值也是 1）
- E11 判不了"前线被谁占着"
- 敌方 AI（E15）也没法知道哪些单位是自己的

**改动点**
- `attack_unit`：目标校验里加 `if attacker.owner == target.owner: return false`
- `move_unit`：E11 的前线独占判定要用（见 §20）

验收：`combat_test[2]`（不能打友军 / 不能打己方 HQ）

## 20. 前线独占（M2 / E11）

| 项 | 规则 |
|---|---|
| 进前线的前提 | 前线**没有敌方单位** |
| 己方已占前线 | 可以继续往剩余空位推进 |
| 敌方占着前线 | 必须先清掉（打掉 / 移走）才能进 —— 这就是 KARDS 的"抢线" |

实现：`move_unit` 里当 `to_line == "front"` 时，遍历 `board.units_in("front")`，
只要有一个 `owner != "player"` 就 `return false`，**放在扣费之前**。

> E12（死亡移除）之前，"清掉敌方前线单位"在测试里用 `board.move()` 直接挪走代替。

验收：`combat_test[5]`

## 21. 死亡与移除（M2 / E12）

| 项 | 规则 |
|---|---|
| 谁会被移除 | `hp <= 0` 的**普通单位**（被攻击的目标、反击中的攻击者，都可能死） |
| 谁不会被移除 | **HQ** —— HQ 血量归零是 E13 的胜负判定，不是离场 |
| 移除时机 | 一次攻击**全部结算完之后**再扫 |

`Board.remove(unit) -> bool`：找到位置 → 置 `null`；找不到返回 `false`。

`attack_unit` 结束处（`has_acted = true` 之后也行）：

```
if target.hp <= 0 and not target.is_hq: board.remove(target)
if attacker.hp <= 0: board.remove(attacker)
```

**坑**
- **先算完反击再判死亡**。先移除目标会让 `position_of(target)` 断掉，反击那一步就崩
- 攻击者也要判 —— 你打死了目标、但被反击打死，两个都得清
- HQ 的 `hp <= 0` **不能移除**，否则 E13 判胜负时找不到 HQ

验收：`combat_test[6]`

## 22. 胜负改为打掉 HQ（M2 / E13）

**已决定：方案 B** —— M1 的 `battle_test.gd` 保留为冒烟测试，改名 `battle_m1_smoke_test.gd`，只留不依赖胜负的断言。

| # | 做什么 |
|---|---|
| 1 | `is_over()` 改为：任一方 HQ 的 `hp <= 0` |
| 2 | `outcome()` 改为：敌方 HQ 死 → `WIN`；我方 HQ 死 → `LOSE`；否则 `RUNNING` |
| 3 | `run_auto()` 的退出条件已经走 `is_over()`，不用改 |
| 4 | `battle_test.gd` 改名 `battle_m1_smoke_test.gd`，**删掉 `[6]` 胜负判定 + `[7]` 完整自动战斗** |
| 5 | `run_tests.bat` / `ci.yml` 同步改名 |
| 6 | `battle_m2_test` 补 `[5] 胜负看 HQ` |

`player` / `enemies` 字段**保留**（M1 的指令卡、附着、抽牌还在用它们），但**不再决定胜负**。
E14（指令卡改造）做完再评估要不要退役。

验收：`battle_m2_test[5]`

## 23. 敌方 AI 与 run_auto（M2 / E15）

目标：**一局能自己打完**。

### 敌方资源与手牌（与玩家对称，省得写两套规则）

| 字段 | 说明 |
|---|---|
| `enemy_energy` / `enemy_max_energy` | 与玩家同一套 Kredit 规则（开局 0，每回合 +1，封顶 12，回合开始回满到上限） |
| `enemy_hand: Array[Card]` | 敌方手牌：开局抽 5、每回合抽 1（同玩家规则），上限同 `MAX_HAND` |
| `enemy_deck: Array[Card]` | 从 `p_deck` 复制一份（`duplicate()`），**别和玩家的 deck 共用引用** |

`setup()` 里初始化 `enemy_deck`（只复制，不抽牌）；`start_battle()` 里给敌方发 5 张起手。

验收会检查：敌方牌库张数 = 玩家牌库、起手 5 张、每回合再抽 1 张、双方牌库各自扣牌。

### 回合顺序（改 `end_turn()`）

```
end_turn():
    玩家 buff 结算 → 敌方 buff 结算（tick 棋盘上的单位；M1 的 enemies 数组不再是战场）
    _enemy_turn()             # 敌方回合：Kredit+1、抽 1、清零敌方 has_acted、AI 行动
    if is_over(): return      # 敌方把玩家 HQ 打爆了
    _begin_turn()             # 玩家新回合
```

**同时删掉 M1 的两处残留**（都在 `battle.gd`）：

- `ENEMY_ATTACK` 常量
- `end_turn()` 里"每个敌人打玩家 4 点"的循环 + `if player.hp <= 0: return`

为什么必须删：玩家血量不再决定胜负（ADR-003），而且那个 `return` 会**卡住回合推进** ——
`_begin_turn()` 不执行 → `turn` 冻结 → `run_auto` 跑满安全计数器也只会返回 RUNNING。
`battle_m1_smoke_test.gd` 的断言已经同步改成「`end_turn()` 不再扣玩家血」，删掉不会变红；
反过来，**不删它这条就会红**。

### 回合开始清 `has_acted` 的范围（**M2 遗留 bug，E15 必须先修**）

§15 说"己方所有单位"，但现在的 `_begin_turn()` 只清了 `player_support`：

- 推进到 **front** 的玩家单位永远 `has_acted = true` → **永远不能攻击**（自动对局的第二个死因）
- **敌方单位没有任何地方清零** → 敌方一辈子只能动一次

要改成：`_begin_turn()` 遍历三条线，清 `owner == "player"` 且非 HQ 的单位的 `has_acted`；
`_enemy_turn()` 开头对 `owner == "enemy"` 的做同样的事。

验收里两条专门卡这个：`battle_m2_test[3]`「前线单位新回合也解除已行动」、`[6]`「敌方单位下一回合能再次攻击」。

### `_enemy_ai()` 三段：部署最多 1 张；推进/攻击按「每个单位每回合行动一次」

| 顺序 | 动作 | 条件 |
|---|---|---|
| 1 部署 | 从 `enemy_hand` 挑**最贵的、付得起的**单位卡，放到 `enemy_support` 空位；扣 `enemy_energy`；`owner = "enemy"`；新单位 `has_acted = true`（召唤失调同玩家）。**每回合最多部署 1 张** | 能量够 + 有空位 + 手里有单位卡 |
| 2 推进 | `front` 里没有玩家单位时，把 `enemy_support` 里**每个非 HQ、未行动**的单位各推到 `front` 一次（能量够就继续）；付作战费、`has_acted = true` | 能量够 + 有空位 + 有候选 |
| 3 攻击 | **每个未行动**的敌方单位各攻击一次：在**相邻线**里挑目标：**优先打能打到的玩家 HQ**；打不到 HQ（HQ 不在相邻线）才打玩家单位；付作战费 | 能量够 + 有合法目标 |

> 推进/攻击是"遍历自己的单位、每个行动一次"，不是"整回合只许动一个"——
> `has_acted` 保证同一个单位不会动两次，所以遍历不会死循环；
> 但仍要配安全计数器兜底，别写成"只要 move 成功就再找一个单位"的无限 while。

**⚠️ 攻击范围必须按 §17 的相邻线来，别自己发明：**

- 敌方**前线**单位的相邻线是 `player_support` → 它能打玩家**支援线单位**和**玩家 HQ**，
  **打不到"玩家前线单位"**。原因有二：① 前线独占（§20）→ 双方不可能同时占前线；
  ② 同一条线不算相邻线（`abs(LINES.find(a) - LINES.find(b)) == 1`，同线差 0）。
  **别为了让测试好过就把校验放宽成 `<= 1`** —— `combat_test` 会因此漏掉一个真规则。
- 敌方**支援线**单位的相邻线是 `front` → 玩家推进到前线的单位是它们的目标。
  **少了这一段，玩家一占前线敌方就永远抢不回来**（那局只能赢不能输）。
- `attack_unit(attacker, null)` 会崩（`position_of(null)` 会命中空格、返回非空数组，然后读 `target.owner`）→ **选目标前先判空**。
- HQ 不能移动/攻击：`units_in()` 会把 HQ 一起返回，挑候选时 `if u.is_hq: continue`。

**为什么是"够得着 HQ 就先打 HQ"（这条是实测定的，别改成先清场）**

同一套规则、同一副 16 张单位牌，两种打法的实测结果：

| 打法 | 结果 |
|---|---|
| 先清场（先打敌方单位，没有才打 HQ） | 双方在 `front` 互相换单位，**30 回合两个 HQ 一点血没掉** → 永远 RUNNING |
| 先打 HQ（够得着 HQ 就打） | **12 回合分出胜负** |

原因：这套规则里没有 Guard / 阻挡，敌方支援线单位跟前线单位是等价交换，
谁都不先走脸就永远僵持。这条**只改 AI 的选目标策略**，不动任何核心规则；
M3 加了 Guard 关键词之后，再改成"Guard 单位挡路"。

### `run_auto()` 重写

玩家侧也自动决策：**部署 → 推进 → 攻击 → end_turn**，循环到
`is_over()` / `turn >= max_turns` / 安全计数器耗尽，返回 `outcome()`。

**坑**
- 敌方攻击玩家单位也走同一个 `attack_unit()`（`owner` 已经能分敌我，别再写一份伤害逻辑）
- 敌方部署时 `owner = "enemy"`，忘了就会"自己打自己"
- AI 的"能打就打"必须配安全计数器（比如最多 200 次循环），否则死循环
- `play_card` 返回 false 就跳过这张，别重试同一张
- **玩家侧不打指令卡**（指令卡改造是 E14 的事）：手牌里没单位卡就跳过部署段
- **玩家侧的攻击策略和敌方一样**：够得着敌方 HQ 就先打 HQ（不然自动对局会僵持到 30 回合）
- **玩家侧的部署策略也和敌方一样**：每回合挑**最贵的、付得起的**单位卡。实测换成"打出手里第一张付得起的"，
  自动对局 30 回合仍然打不完（双方 HQ 还有 3 / 8 点）→ `[7]` 会红。这条和敌方对称，别各写一套。
- 别写成"每回合把能量全花在部署上"：支援线只有 4 个位，满了要推进，否则一辈子不出前线

### `[7]` 为什么用一副专用牌库

`cards.json` 前 7 种全是**指令卡**（28 张），单位卡排在后面；起手 6 张 + 每回合 1 张 + 手牌上限 9
→ 第 4 回合手牌就满、之后抽到的全被丢弃 → **整局摸不到一张单位卡**。玩家侧又规定不打指令卡，
于是双方都无牌可出，30 回合后 RUNNING。所以 `[7]` 用 `_make_unit_deck()`（16 张单位卡在前）
验证回合循环，和真牌库内容解耦。**别为了让它绿去改真牌库顺序。**
按上面的打法，这副牌应该在 30 回合内分出胜负（实测约 12 回合）。

**⚠️ 复用前要先把"玩家侧写死"的地方参数化**

| 写死的 | 应该改成 |
|---|---|
| `move_unit` 里 `"player_support"` 作为出发点 | 按 `unit.owner` 选：`player` → `player_support`，`enemy` → `enemy_support` |
| `move_unit` / `attack_unit` 里的 `energy` 扣费池 | 按 `unit.owner` 选：玩家扣 `energy`，敌方扣 `enemy_energy` |
| `play_card` 单位分支的 `player_support` / `energy` / `owner="player"` | 抽成 `_deploy_unit(card, owner)`：敌方扣 `enemy_energy`、落 `enemy_support`、`owner="enemy"` |
| `_draw()` 固定抽玩家的 `deck` → `hand` | `_draw_into(target_hand, target_deck, n)`，玩家和敌方各调一次 |

不参数化的话，敌方 AI 只能把攻击/移动逻辑复制一遍 —— 那 `attack_unit` 里"走 `compute_damage` + 反击 + 死亡移除"的二十行就会有两份，以后改规则必漏一处。

验收：`battle_m2_test[6]`（17 条）+ `[7]`（6 条）+ `[3]` 的前线那一条
→ 全套 **308/308**（7 个测试文件，每个文件末尾还会校验"应执行项数"，少执行一条也算红）

## 24. 状态效果生效（M2 收尾 / C8）

目标：反应挂上去的状态**真的产生效果**（燃烧/感电每回合掉血、冻结本回合不能行动），
而且效果完全由 `data/tables/statuses.json` 驱动（ADR-001：不按状态名写死）。

### 数据与模型

- 状态实例 = **`Buff`**：`kind` 存状态 id（`burn` / `shock` / `immobilized` / `defense_down`），
  `duration` 存剩余回合，`stacks` 默认 1。
- `Battle` 加字段 `var status_table: StatusTable`，**`setup()` 里自己加载**
  `res://data/tables/statuses.json`（和 `reaction_table` 一样是 Battle 的字段，测试会直接读它）。
- 一律 `status_table.get_status(buff.kind)` 拿到 `effects` 再按 `kind` 分发。

### 回合开始的结算：每个己方单位（**跳过 HQ**），四步顺序不能换

| # | 做什么 | 怎么判 |
|---|---|---|
| 1 **dot 掉血** | 遍历这个单位的 `buffs`，查 `effects` 里 `kind == "dot"` 且 `timing == "turn_start"` → `take_damage(int(floor(value * stacks)))`（走护盾） | 掉血走 `take_damage`，所以护盾先吸收 |
| 2 **死亡移除** | 掉血后 `hp <= 0` 的**普通单位** `board.remove()`；HQ 不移除（§21） | 死单位不能再行动 |
| 3 **disable 标记** | `effects` 里 `kind == "disable"` 且 `timing == "action"` 的状态还在 → 本回合不能移动/攻击（`has_acted = true`） | 注意这是"冻结"，日志要能区分 |
| 4 **buff 计时** | `tick_buffs()`：duration −1，到期的移除（C6 已有） | **放在最后**，否则 duration 1 的冻结会在生效前就过期 |

顺序为什么是这样：先掉血再减 duration → **燃烧 duration 2 = 两个回合各掉 1 血**；
disable 判定在 tick 之前 → **冻结 duration 1 能正好冻住 1 个回合**。

玩家单位在 `_begin_turn()` 里结算；敌方单位在 `_enemy_turn()` 里结算（E15 第 5 步写的位置）。
`_enemy_turn()` 里"清 has_acted"和"disable 标记"的先后：**先清，再按 disable 标记**。

### 挂状态（反应附带）

反应结算的那一层（`_apply_aura()` 或 `compute_damage()` 返回的 `effects`，**只挑一处，别两处都挂**）
遍历 `effects`，`kind == "status"` → 目标 `add_buff(Buff.make(id, int(duration)))`：

| 反应 | 状态 | 数据里的 duration |
|---|---|---|
| `lightning+water` 感电 | `shock` | 2 |
| `ice+water` 冻结 | `immobilized` | 1 |
| `ice+lightning` 超导 | `defense_down` | 2 |

- 免疫 / 没触发反应 → **不挂**任何状态。
- 同一状态重复挂：`stacks + 1`、`duration` 取较大值（别叠成两个 Buff，否则 dot 会翻倍）。

### 时机的迁移（M1 残留）

现在 `end_turn()` 里 tick 的是 M1 的 `player` 和 `alive_enemies()`（都不在棋盘上）。
C8 开始要改成**棋盘单位**：玩家 → `_begin_turn()`，敌方 → `_enemy_turn()`。
M1 那两行 tick 可以删掉（`player` / `enemies` 字段本身留给 E14 处理）。

### 坑

- `statuses.json` 的 `value` 是浮点（`1.0`），伤害用 `int(floor(value * stacks))`，和伤害公式一致（§0）
- `buff.kind` 在 `statuses.json` 里查不到时 → 当"没有效果"，**不要崩**
- 第一次 `_begin_turn()` 在 `start_battle()` 里就发生了，那时棋盘上可能已经摆了单位（测试会摆）
- 状态挂在**活着**的单位上；死了以后已经移除，不用管 buff
- `defense_down`（`stat_mod` / `passive`）这版**先不做**，结构留好（M3 的数值系统）

### 验收

新测试文件 `tests/status_test.gd`（`[0]` 数据接线 / `[1]` dot / `[2]` disable / `[3]` 反应挂状态，共 12 条）
→ 全套 **320/320**（8 个测试文件）

---

## 25. 指令卡改造（E14）：Order 打到棋盘单位上

目标：指令卡不再只作用于 M1 的 `player` / `enemies`，而是**打在棋盘上的单位 / HQ**。

**已经能用的（2026-11-21 实测，`tests/pending/order_test.gd` 27 条里 21 条已绿）**：
伤害指令卡打敌方棋盘单位、护盾/治疗打己方棋盘单位、打 HQ、免疫、元素倍率/附着、反应挂状态（C8）。
所以 E14 只剩三件事：

| # | 要做的事 | 规则 |
|---|---|---|
| 1 | **目标合法性校验（数据驱动）** | 由卡牌数据 `Card.target` 决定：`enemy` → 只能打敌方单位/敌方 HQ；`self` → 只能打己方单位/己方 HQ。数据没写 `target` 时按 kind 推断默认：**damage → enemy，shield/heal → self**。目标还必须在棋盘上（`board.position_of(target)` 非空）。**非法目标 → `play_card` 返回 false，不扣费、卡留手里**。`target: "any"` 留给 M3 |
| 2 | **指令卡伤害后的死亡移除** | `hp <= 0` 的**普通单位** `board.remove()`；**HQ 不移除**（§21）。放在 `_apply_aura` 结算**之后**（死亡单位不该再挂附着/状态） |
| 3 | 收尾 | `target == null` 先判空（`play_card` 开头已有 `target == null` 检查，确认别绕开）；日志补攻击者/卡名 |

> **2026-11-22 修订**：原方案"规则按 kind 写死"已改为**数据驱动**——因为伤害指令也可以打自己（自残/配合）、治疗/护盾也可以给对方（怪卡/组合技）。`Card.from_dict` 的 `target` 缺省改为按 kind 推断（damage→enemy，shield/heal→self），显式 `target` 覆盖；`cards.json` 的伤害卡已补 `"target": "enemy"`。

**不做的**：`run_auto()` 玩家侧 AI 仍然**不打指令卡**（E14 不扩 AI 出牌；以后想让 AI 打指令卡时另开任务）。

**验收**：`tests/pending/order_test.gd` → **35/35**（含"显式 target 覆盖"用例：伤害打自己、治疗/护盾给对方）。
已启用：文件在 `tests/order_test.gd`，全套 **355/355**（2026-11-22 完成）。

> ⚠️ **兼容 M1 旧测试（必踩）**：`battle_m1_smoke_test` 里 `play_card(c, enemy)` 的 `enemy` 是 M1 `enemies` 数组里的对象、**不在棋盘上**，另外还有 `play_card(c, player)`。所以校验要放行"棋盘外但属于 `enemies` 或就是 `player`"的目标，**棋盘内的目标才按 owner/kind 校验**：
>
> ```text
> on_board = board.position_of(target) 非空
> legacy   = enemies.has(target) or target == player
> if not on_board and not legacy: return false
> if on_board: 再按 card.target / owner 校验
> ```
>
> 不加这条兼容分支，`battle_m1_smoke_test` 会红（E14 不该动 M1 的伤害管线测试）。
>
> ✅ **验收包已验证可通行**（2026-11-21，我在临时副本里按上面 3 条 + 兼容分支写了一份实现）：`order_test` **27/27**，全套 **347/347**、0 SCRIPT ERROR，`battle_m1_smoke_test` 58/58 无回归。（E14 + E7 一起做完时，在同一个临时副本里实测全套 **365/365**，两份验收包互不冲突。）

**提交**：`feat(battle): 指令卡目标校验与死亡移除（E14）`

## 26. 牌堆 / 弃牌堆 / 抽干疲劳（E7，KARDS 式定稿 2026-11-22）

> 决策来源：学员 2026-11-22 拍板 —— 按 KARDS：牌库 **39 张 + 1 张 HQ**（HQ 开局在场上，不进牌库/手牌）；
> **不洗回**；牌库抽空后每次该抽牌按**等差数列扣抽牌方自己的 HQ**（1、2、3…）。

### E7a（本轮）：弃牌堆 + 抽干疲劳

| 项 | 规则 |
|---|---|
| 字段 | `discard: Array[Card]`（玩家）、`enemy_discard: Array[Card]`（敌方）；`setup()` 清空 |
| 打出的指令卡 | **`hand.erase(card)` + `discard.append(card)`**（两件事都做；漏 erase 会让 m1 的"打出的卡从手牌移除"红） |
| 打出的单位卡 | 部署后离手，**不进弃牌堆** |
| 失败的出牌 | 不扣费、不移手牌、**不进弃牌堆** |
| 手牌满 9 时抽牌 | 牌库照扣，抽到的牌**进对应弃牌堆**（KARDS 的 burn） |
| 牌库抽空仍要抽牌 | **不再抽牌、不洗回**；抽牌方自己的 HQ 受递增伤害：第 1 次 **1**、第 2 次 **2**、第 3 次 **3**……（等差数列，双方独立计数）。**直接扣 hp**（`hp = max(0, hp - n)`），不走 `compute_damage`/护盾/元素反应 |
| HQ 归零 | 照常判负（`is_over()/outcome()` 已有逻辑） |
| 敌方 | 完全对称 |
| 构筑张数 | 39 + 1 HQ 的**构筑规则**属于 M3 的 F4（`data/decks/`），E7a 只实现抽干行为，不强制牌库张数 |

**验收**：`tests/pending/deck_test.gd` → **20/20**（字段 / 出牌入弃牌堆 / 单位卡不入 / 非法不入 / 满手 burn / 玩家疲劳 1→2 / 敌方疲劳 / 独立计数）。
全绿后移到 `tests/` → 全套 **355 + 20 = 375**。

### E7b（下一轮）：起手与换牌（KARDS）

学员 2026-11-22 确认：
- **先手（玩家）起手 4 张，自己第一个回合不抽牌**；
- **后手（敌方）起手 5 张，自己第一个回合照常抽 1 张**；
- mulligan（开局换牌一次）是否做、换几张，待定（❓）。

影响：会改 `battle_m2_test` 等现有断言（现在按"双方起手 5、每回合抽 1"写），所以单独一轮做。
测试文件届时新增 `tests/pending/opening_test.gd`。

### 坑

- **不洗回**：牌库空 → 立刻进疲劳，不要再 `append_array(discard)`。
- 疲劳伤害**别走 `take_damage` 的护盾逻辑**（HQ 没护盾，但语义上疲劳不是攻击）；用直接扣 hp 并 clamp 到 0。
- 疲劳**每个"该抽牌"事件计一次**（`_draw_into` 里 n>1 时要循环处理）；起手抽牌正常时不应触发。
- `discard` 与 `deck` 不能是同一个引用；burn 的牌从牌库拿走后才进弃牌堆。
- 敌方疲劳计数独立，别复用玩家计数器。

**提交**：`feat(battle): 弃牌堆与抽干疲劳（E7a）`


## 27. 关键词框架 + 闪击（M3.1）

> 前置：E14/E7 收尾完成。总览见 `docs/m3-scope.md` §M3.1；规则决策见 `docs/adr/004-m3-keywords.md`。

目标：`Card` / `Unit` 带 `keywords`，首批关键词 **Blitz（闪击）** 生效。Guard 见 §28（待拍板）。

| 位置 | 要做 |
|---|---|
| `card.gd` `Card.from_dict` | 解析 `keywords`（JSON 数组 → `Array[String]`） |
| `unit.gd` | 加 `var keywords: Array[String] = []`；`Unit.from_dict` 解析 |
| `battle.gd` `_deploy_unit` | 把 `card.keywords` 拷到 Unit；`nu.has_acted = not nu.keywords.has("blitz")`；日志标注关键词 |
| 数据 | `cards.json` 给 1–2 张卡加 `"keywords": ["blitz"]` |
| 校验 | `tools/validate_data.gd` 已把未知关键词记为 warning（不崩） |

**验收**：`tests/pending/keywords_test.gd` → **9/9**（解析 / 传递 / 不失调 / 可移动 / 可攻击 / 普通单位对照）。全绿后移到 `tests/`。
**坑**
- `Array[String]` 不能直接 `unit.keywords = d.get("keywords", [])`（untyped→typed 会报错）→ 逐项 `append` 或 `.assign()`；
- `keywords` 可能缺省 → 用 `get` + 默认空数组；
- Blitz 只影响"部署当回合"，下一回合照旧由 `_begin_turn` 清 `has_acted`；
- **Guard 别提前塞进 `attack_unit`**，等 §28 拍板。

**提交**：`feat(battle): 关键词框架与闪击（M3.1）`

## 28. 护卫 Guard（M3.2，待拍板）

`docs/adr/004-m3-keywords.md` 决定 2 拍板后把这里细化（语义 A/B/C、AI 目标策略、测试范围）。
验收测试 `tests/pending/guard_test.gd` **6 项**已按**选项 A（相邻线有敌方 Guard 必须打 Guard）**暂定；拍板不同则先改测试再实现。
**提交**：`feat(battle): 护卫 Guard（M3.2）`

---

## 29. M3 任务索引

M3 的**详细排期、任务分解、测试计划、依赖与风险**见 **`docs/m3-scope.md`**；
规则决策见 `docs/adr/004-m3-keywords.md`（行动经济/Guard/兵科）与 `docs/adr/005-element-auras-v3.md`（元素多槽）。

本文件 §27/§28 是 M3.1/M3.2 的初步任务卡；M3.1–M3.8 每块开工前，教练会把该块的详细任务卡补到本节下面（含函数表、验收、坑）。
## 附：常用 GDScript 手段速查

| 想做的事 | 用什么 |
|---|---|
| 数组追加/删除/查长度 | `append()` / `erase()` / `size()` |
| 复制数组（遍历时安全） | `array.duplicate()` |
| 排序 | `array.sort()` |
| 取小/取大 | `mini(a,b)` / `maxi(a,b)`（浮点用 `minf`/`maxf`） |
| 字典取值带默认 | `dict.get(key, 默认值)` |
| 判断类型 | `typeof(x) == TYPE_DICTIONARY` |
| JSON | `JSON.parse_string(text)`（失败返回 null） |
| 读文件 | `FileAccess.file_exists()` / `FileAccess.get_file_as_string()` |
| 格式化字符串 | `"%s 打了 %d 点" % [名字, 数值]` |
| 分支 | `match kind: "damage": ...` |
| 报错（不中断） | `push_error("消息")` |
| 带类型的数组 | `var a: Array[Card] = []`（**不要**直接赋 `filter()` 的结果） |

---

## 写完一个文件的验收动作

```bash
# 懒人版：跑全套 7 个文件 + 检查 PASS / [FAIL] / SCRIPT ERROR（推荐，别只看退出码）
run_tests.bat

# 只跑相关的那个文件，看失败数有没有变少
& $g --headless --path . --script res://tests/battle_m2_test.gd
& $g --headless --path . --script res://tests/combat_test.gd

# 想手动看一局（battle.gd 写完后才用得上）
& $g --headless --path . --script res://tests/run_battle.gd
```

**全绿 = 失败 0 项 + 退出码 0 + 输出里没有 `SCRIPT ERROR`。** 三个都要满足：
前者可能"少跑了几条也全绿"（所以每个测试文件末尾会校验应执行的项数），后者是"报错被吞"。
当前基线：`battle_m1_smoke_test` 1 红、`battle_m2_test` 5 红；E15 做完 → 全绿 307/307。

---

