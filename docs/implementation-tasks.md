# 实现任务卡（每个文件要你写什么、用什么手段、怎么验收）

> 用法：每次动手前先看对应那一节，写完回来打勾。
> **本文件只给"要什么"，不给代码。** 卡住了再去看 `..\_reference_battler\`（先自己写 20 分钟）。

## 进度总览

| # | 文件 | 任务数 | 难度 | 预计行数 | 验收（测试分组） | 完成 |
|---|---|---|---|---|---|---|
| 1 | `element.gd` | 3 | ★ | 15 | data_test[3] | [ ] |
| 2 | `damage.gd` | 5 | ★★ | 40 | damage_test[D1–D6] | [ ] |
| 3 | `card.gd` | 2 | ★ | 20 | data_test[1] | [ ] |
| 4 | `buff.gd` | 2 | ★ | 10 | unit_test[5] | [ ] |
| 5 | `unit.gd` | 7 | ★★ | 45 | unit_test[1–4] | [ ] |
| 6 | `reaction_table.gd` | 4 | ★★ | 25 | data_test[4] | [ ] |
| 7 | `data_loader.gd` | 3 | ★★ | 40 | data_test[1][2] | [ ] |
| 8 | `battle.gd` | 13 | ★★★ | 150 | battle_test[1–7] | [ ] |
| 9 | `status_table.gd` | 4 | ★★ | 25 | data_test[5] | [ ] |
| 10 | `unit.gd`（M2 扩展） | 3 | ★ | 15 | board_test[1] | [ ] |
| 11 | `board.gd` | 6 | ★★★ | 80 | board_test[2][3] | [ ] |
| 12 | `hq`（在 board / battle 内） | 3 | ★★ | 30 | board_test[2] | [ ] |
| 13 | `battle.gd`（M2：Kredit / 部署 / 召唤失调） | 3 | ★★ | 60 | battle_m2_test[1–3] | [ ] |
| 14 | `board.gd` + `battle.gd`（M2：移动 / 攻击 / 行动花费） | 5 | ★★★ | 90 | combat_test[1–3] | [ ] |
| 15 | `unit.gd` + `battle.gd`（M2：owner / 前线独占） | 2 | ★★ | 40 | combat_test[2][5]、board_test[2] | [ ] |

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
- 每个回合开始时，**己方所有单位** `has_acted = false`
- HQ 不参与（HQ 永远不行动）

实现位置：`_begin_turn()` 里遍历 `board.units_in("player_support")` 把 `has_acted` 清零。

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

- `Unit` 加 `operation_cost: int = 1`，`from_dict` 读 `operation_cost`
- 部署时：`unit.operation_cost = card.operation_cost`，**卡上没写（0）就按 1 处理**
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

---

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
# 只跑测试，看失败数有没有变少
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/battle_test.gd
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/board_test.gd

# 想手动看一局（battle.gd 写完后才用得上）
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/run_battle.gd
```

**失败数从 19 减到多少，就是你的进度条。**

---

