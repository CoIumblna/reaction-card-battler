# 实现任务卡（每个文件要你写什么、用什么手段、怎么验收）

> 用法：每次动手前先看对应那一节，写完回来打勾。
> **本文件只给"要什么"，不给代码。** 卡住了再去看 `..\_reference_battler\`（先自己写 20 分钟）。

## 进度总览

| # | 文件 | 任务数 | 难度 | 预计行数 | **预计用时** | 验收（测试分组） | 完成 |
|---|---|---|---|---|---|---|---|
| 1 | `element.gd` | 3 | ★ | 15 | 0.5–1 h | data_test[3] | [x] |
| 2 | `damage.gd` | 5 | ★★ | 40 | 2–3 h | damage_test[D1–D6] | [x] |
| 3 | `card.gd` | 2 | ★ | 20 | 0.5–1 h | data_test[1] | [x] |
| 4 | `buff.gd` | 2 | ★ | 10 | 0.5 h | unit_test[5] | [x] |
| 5 | `unit.gd` | 7 | ★★ | 45 | 2–3 h | unit_test[1–4] | [x] |
| 6 | `reaction_table.gd` | 4 | ★★ | 25 | 1.5–2 h | data_test[4] | [x] |
| 7 | `data_loader.gd` | 3 | ★★ | 40 | 2–3 h | data_test[1][2] | [x] |
| 8 | `battle.gd` | 13 | ★★★ | 150 | 6–8 h | battle_m1_smoke_test[1–5] | [x] |
| 9 | `status_table.gd` | 4 | ★★ | 25 | 1.5–2 h | data_test[5] | [x] |
| 10 | `unit.gd`（M2 扩展） | 3 | ★ | 15 | 1 h | board_test[1] | [x] |
| 11 | `board.gd` | 6 | ★★★ | 80 | 4–5 h | board_test[2][3] | [x] |
| 12 | `hq`（在 board / battle 内） | 3 | ★★ | 30 | 1.5–2 h | board_test[2] | [x] |
| 13 | `battle.gd`（M2：Kredit / 部署 / 召唤失调） | 3 | ★★ | 60 | 3–4 h | battle_m2_test[1–3] | [x] |
| 14 | `board.gd` + `battle.gd`（M2：移动 / 攻击 / 行动花费） | 5 | ★★★ | 90 | 4–6 h | combat_test[1–3] | [x] |
| 15 | `unit.gd` + `battle.gd`（M2：owner / 前线独占） | 2 | ★★ | 40 | 2–3 h | combat_test[2][5]、board_test[2] | [x] |
| 16 | `board.gd` + `battle.gd`（M2：死亡移除） | 2 | ★ | 20 | 1 h | combat_test[6] | [x] |
| 17 | `battle.gd`（M2：胜负改 HQ）+ M1 测试退役 | 3 | ★★ | 40 | 2–3 h | battle_m2_test[5] | [x] |
| 18 | `battle.gd`（M2：敌方 AI + run_auto） | 4 | ★★★ | 150 | 6–8 h | battle_m2_test[3][6][7] | [x] |
| 19 | `battle.gd`（M2 收尾：状态效果 C8） | 4 | ★★★ | 120 | 5–6 h | status_test[0–3] | [x] |
| 20 | `battle.gd`（E14：指令卡打在棋盘单位上） | 3 | ★★ | 40 | 2–3 h | order_test[1–5] | [x] |
| 21 | `battle.gd`（E7a+E7b：牌堆/弃牌/起手/换牌） | 4 | ★★★ | 80 | 5–7 h | deck_test + opening_test | [x] |
| 22 | `unit.gd`+`card.gd`+`battle.gd`（M3.1：行动经济/关键词/Blitz） | 3 | ★★★ | 80 | **4–6 h**（实际约 4.5 h） | keywords_test（17 项，已启用） | [x] |
| 23 | `battle.gd`（M3.2：Guard） | 3 | ★★★ | 70 | **2–3 h**（实际约 2 h） | guard_test（8 项，已启用） | [x] |
| 24 | `battle.gd`（M3.3：兵科基础 + 空军越线 + 炮兵/轰炸机无视 Guard） | 3 | ★★★ | 140 | **5–7 h**（实际约 3 h） | unit_class_test（21 项，已启用） | [x] |
| 25 | `battle.gd`（M3.3b：战斗机拦截轰炸机） | 1 | ★★ | 30 | **1.5–2 h**（参考实现实际 ~20 min） | air_intercept_test（3 项已写，验收包已验证） | [ ] 备课完成 → 待学员实现 |
| 26 | `data/tables/cards.json`（M3.4：卡池 20+） | 1 | ★★ | 0（数据） | **2–3 h**（创意为主） | data_test + validate_data | [ ] |
| 27 | `battle.gd`+`data_loader.gd`（M3.5：卡组构筑 39+1） | 2 | ★★★ | 60 | **2–3 h** | deck_build_test（10 项已写） | [ ] |
| 28 | `element.gd`+`unit.gd`+`damage.gd`+`battle.gd`（M3.6：元素 v3 多槽） | 4 | ★★★★ | 300 | **12–16 h**（最大块） | aura_v3_test（24 项待写） | [ ] |
| 29 | `unit.gd`+`battle.gd`（M3.7：stat_mod 数值系统） | 1 | ★★ | 40 | **2–3 h** | stat_mod_test（6 项已写） | [ ] |
| 30 | `battle.gd`（M3.8a：AI 打指令卡） | 2 | ★★★ | 80 | **3–4 h** | battle_m2_test 增补（测试待写） | [ ] |
| 31 | 平衡（M3.8：balance_sim 调参） | 3 | ★★★ | 60 | **3–5 h** | docs/balance-report.md | [ ] |
| 32 | 文档与 tag（M3.9：tag v0.3） | 1 | ★ | 0 | **1 h** | README + HANDOFF | [ ] |

**列的含义**
- **预计行数** = 你要新写的代码行数量级（不含注释/测试）。实际多 50% 很正常。
- **预计用时** = 一个已经读过任务卡的学员，**从动手到 `run_tests.bat` 全绿**的净编码时间。
  不含：读文档、卡住求助、等教练 review、改数据、跑平衡模拟。
  经验倍率：★ ×1、★★ ×2、★★★ ×4、★★★★ ×8（相对 ★ 的 0.5 h 基准）。
  第一次做某类任务会偏慢（比如第一次用 typed array、第一次写洗牌），**做过的同类任务第二次起能省 30–40%**。
- **完成列**：`[x]` 已完成并提交 / `[~]` 进行中 / `[ ]` 未开始。

**M3 剩余总量估算**：约 **36–52 h** 净编码（其中 M3.6 元素 v3 独占 12–16 h）。按每天 4 h 有效编码算 ≈ 9–13 个工作日。

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

### E7a：弃牌堆 + 抽干疲劳 —— ✅ 已完成（2026-11-23，`tests/deck_test.gd` 20/20，全套 375/375）

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

> **规格已定稿，见本文件后面的「## 30. E7b 起手与换牌（P2）」——那里才是任务卡。**
> 本节旧稿里「mulligan 是否做、换几张待定 ❓」已作废：2026-11-22 拍板为
> **先手随机**（2026-11-23 改）4 张且首回合不抽、后手 5 张且首回合照常抽 1、双方各一次 mulligan。
> 验收：`tests/pending/opening_test.gd`（25 项）。

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
## 30. E7b 起手与换牌（P2）

> 2026-11-23 修改：**先手随机**（原来固定玩家先手），mulligan 提成独立阶段。

**规则（KARDS）**：
- 开局用 `rng.randi_range(0, 1)` 随机决定**先手方**，存 `Battle.first_move`（`"player"` / `"enemy"`）；不固定玩家先手。
- 先手方：起手 **4** 张，**自己第一个回合不抽牌**；
- 后手方：起手 **5** 张，**自己第一个回合照常抽 1 张**；
- 之后双方每回合抽 1。
- **mulligan 是独立阶段**：`start_battle()` 发完牌、`begin_first_turn()` 之前，双方各可换一次——把指定手牌洗回牌库、再抽等量。

**API 约定**

| 方法 | 语义 |
|---|---|
| `setup(...)` | 除现有清理外，置 `first_move = ""`、`turn = 0`（开局阶段未定） |
| `start_battle()` | `first_move` 为 `""` 时随机；按身份发牌（先手 4 / 后手 5）；**不开始任何回合**（`turn` 仍 0、`energy` 仍 0）；进入开局阶段 |
| `begin_first_turn()` | 开始先手方第 1 回合：先手是玩家 → `_begin_turn()`；先手是敌方 → 先 `_enemy_turn()` 再 `_begin_turn()`；退出开局阶段 |
| `mulligan(owner: String, cards: Array) -> bool` | 只在开局阶段、每方一次；成功 true；空列表 / 不是自己手牌 / 已用过 / 已过开局阶段 → false |

- **可注入**：`start_battle()` 只在 `first_move == ""` 时随机。测试要确定性就在 `start_battle()` 前设 `b.first_move = "player"`。
- 形参写弱类型 `cards: Array`（不是 `Array[Card]`）：`opening_test` 传的是 `var give_back: Array = b.hand.duplicate()`，
  无类型 `Array` 实参传给 typed array 形参会在运行时抛
  `Invalid type in function 'mulligan' ... does not have the same element type as the expected typed array argument`。
- 抽牌差异：`_begin_turn()` 里 `if not (first_move == "player" and turn == 1): _draw_into("player", 1)`；`_enemy_turn()` 用计数 `enemy_turns_taken`，`if not (first_move == "enemy" and enemy_turns_taken == 1): _draw_into("enemy", 1)`。
- 常量：`FIRST_OPENING_HAND = 4`、`SECOND_OPENING_HAND = 5`（原 `OPENING_HAND` 拆成这两个）。
- 洗回用 `Battle.rng`（可复现）；字段建议 `mulligan_used` / `enemy_mulligan_used`。
- `end_turn()` 不变：玩家回合结束 → 敌方回合 → 玩家下回合。

**改哪里**：`battle.gd` 的 `start_battle()` / 新 `begin_first_turn()` / `_begin_turn()` / `_enemy_turn()` / 新 `mulligan()`。

**连带改（教练做）**：`tests/battle_m1_smoke_test.gd`、`battle_m2_test.gd`、`combat_test.gd`、`deck_test.gd`、`order_test.gd`、`status_test.gd`、`tools/run_battle.gd` 的建局辅助函数——在 `start_battle()` 前固定 `first_move = "player"`，之后补 `begin_first_turn()`，使旧断言仍是"玩家先手"语义。

**验收**：`tests/pending/opening_test.gd` **25 项**（随机/可复现/两种先手各验 4/5 起手/首回合不抽与抽/mulligan 成功·一次·非法·对称·阶段外/可复现）。
全绿后移到 `tests/`。验收包已用参考实现验证可通行：`G:\constraction\_ref_e7b\`（含 `E7b-reference.patch`，**不进 git**），opening_test 25/25 + 主套 375/375。

**坑（都是本轮踩到的）**
1. **`RandomNumberGenerator` 没有 `shuffle()`**，`Array.shuffle()` 用的是全局 RNG、不可复现 → 自己写 Fisher-Yates（`for i in range(n-1, 0, -1): j = rng.randi_range(0, i)`）。
2. **`_ai` 攻击前必须判空**：前线可能在同一个循环里被前面的攻击打空，`find_first_unit("front")` 返回 null。而 `Board.position_of(null)` 会返回**假坐标**（`slots[l].find(null)` 命中空格子，实测 `["enemy_support", 1]`），一路穿过空值检查，最后在 `attack_unit` 的 `target.owner` 处 **Nil 崩**。必须先 `var tgt: Unit = board.find_first_unit("front"); if tgt == null: break`。
   - 这个 bug 原来被"玩家先手"的顺序挡住，改成敌方先手后就会冒出来；**单独一个 `fix(battle):` 提交**，别混进 E7b。
3. 敌方先手时 `begin_first_turn()` 会真的跑 `_enemy_turn()`（含 AI 行动），所以第一条日志来自敌方——测试里不要假设"开局第一件事是玩家"。

---

## 31. M3.1 行动经济 + 关键词 + 闪击

见 `docs/adr/004-m3-keywords.md` 决定 1。

> **✅ 已完成（2026-11-25）**：`keywords_test` 17/17 已启用，主套 417/417 全绿。
> commit `6edd3ea`（数据/白名单）+ `71b0ded`（实现 + 测试迁移 + 启用）。
> 下面保留任务卡原文，作为「同类任务怎么备课」的模板；本轮踩到的坑见 `docs/review-m31-2026-11-25.md` §4。
>
> 2026-11-25：本任务卡细化完毕，验收包已用参考实现验证可通行
> （`G:\constraction\_ref_m31\`，含 `M31-impl.patch` / `M31-tests.patch` / `M31-tools.patch`，**不进 git**）。

**规则（KARDS）**

| 项 | 规则 |
|---|---|
| 字段 | `Unit.has_acted` 拆成 `has_moved` / `has_attacked`（都 `bool`，默认 false） |
| 回合开始 | 己方**非 HQ** 单位两个标志都清 false（支援线 **和** 前线都要清） |
| 普通单位 | 移动**或**攻击二选一：先移动 → `has_moved=true`，不能再攻击；先攻击 → `has_attacked=true`，不能再移动 |
| 坦克 `unit_class == "tank"` | 移动 + 攻击**都能做**（各一次；移动两次/攻击两次仍不行） |
| 召唤失调 | 部署当回合两个标志都 **true** |
| 闪击 `blitz` | 部署当回合两个标志都 **false**（只免疫召唤失调，**不免疫冻结**） |
| 闪击 + 坦克 | 部署当回合可以「先移动再攻击」 |
| 作战费 / 能量 | 不变（移动/攻击各自扣 `operation_cost`） |

**API 约定**

| 位置 | 要做 |
|---|---|
| `unit.gd` | 删 `has_acted`；加 `has_moved` / `has_attacked` / `unit_class: String` / `keywords: Array[String]`；`Unit.from_dict` 解析 `unit_class` 与 `keywords`（**逐项 append**）；新辅助方法 `is_blitz()` / `is_tank()` / `has_keyword(kw)` / `reset_actions()` / `block_actions()` / `can_move()` / `can_attack()` |
| `card.gd` | 字段早就有，但 `Card.from_dict` **从没赋值** → 解析 `keywords` 与 `abilities`（同样逐项 append） |
| `battle.gd` `_deploy_unit` | 建 `Unit` 时把 `unit_class` / `keywords` 一起塞进 `from_dict` 的字典；**闪击 → `reset_actions()`，否则 → `block_actions()`** |
| `battle.gd` `_begin_turn` / `_enemy_turn` | 清标志：原来那行 `u.has_acted = false` → `u.reset_actions()` |
| `battle.gd` `move_unit` | 前置判断 `if unit.has_acted` → `if not unit.can_move()`；成功后 `unit.has_moved = true` |
| `battle.gd` `attack_unit` | 前置判断 → `if not attacker.can_attack()`；成功后 `attacker.has_attacked = true` |
| `battle.gd` `_ai` | 三处 `u.has_acted` 过滤 → `not u.can_move()` / `not u.can_attack()`；**删掉攻击后手动置标志的两行**（见坑 2） |
| `battle.gd` `_settle_status` | `disable` 分支（冻结）→ `u.block_actions()`（两个标志都置 true） |

- `can_move()` / `can_attack()` 放 `Unit` 上，不放 `Battle`：二选一是单位自身语义，坦克例外也只看 `unit_class`。
  `can_attack()` 不能只判 `not has_attacked`，还要 `not has_moved or is_tank()`（见坑 3）。写法：

```gdscript
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
```

- ~~本块**不动数据**：`data/cards.json` 里 `blitz` / `tank` 可以继续没有，测试自己造卡；
  `unit_class` 的真实数据由 M3.4 补。~~

> **2026-11-25 更正（教练已改数据）**：`unit_class` 不只是测试字段——M3.3 的兵科规则要靠它才生效，
> 所以真实卡池必须先有值。已由教练在**本块**顺手补上（元素/数值/张数一个没动）：
>
> - `data/tables/cards.json`：4 张单位卡补 `unit_class` —— 步兵 / 弓手 / 火法师 = `"infantry"`，坦克 = `"tank"`；牌库仍 44 张。
> - `tools/validate_data.gd:18`：`KNOWN_UNIT_CLASSES` 由 `["", "infantry", "tank", "artillery", "air"]`
>   改成 `["", "infantry", "tank", "artillery", "fighter", "bomber"]`。
>   **原来的 `"air"` 是错的**：ADR-004 决定 3 与 `unit_class_test` / `air_intercept_test` 用的都是
>   `fighter`（战斗机）/ `bomber`（轰炸机）两个独立兵科，不修的话以后写空军卡会被校验器误判非法。
> - `blitz` 仍**没有**真实卡（`add_unit_card.gd` 还没有 `--keywords` 参数），`keywords_test` 自己造卡，
>   真实卡池里的闪击卡留给 M3.4 卡池扩充。
>
> 补数据后复核：11 个主套文件 + `keywords_test` 全绿、`validate_data` PASS、
> `balance_sim` 100 场 **48/52（胜率 48.0%）、平均 13.0 回合** —— 仍在 45–60% / 8–20 区间。
> 平均回合 16.0 → 13.0 是**预期内**的：坦克成为真正的 `tank` 兵科后能「移动 + 攻击」，节奏变快；**本块不动平衡数值**，调参归 M3.8。

**改哪里**：`src/core/unit.gd`、`src/core/card.gd`、`src/core/battle.gd`。

**连带改（教练做）**：4 个测试文件共 15 处 `has_acted` 断言——等学员实现落地时一起提交：

| 文件 | 处数 | 改成 |
|---|---|---|
| `tests/board_test.gd` | 1 | `u.get("has_moved") == false and u.get("has_attacked") == false` |
| `tests/combat_test.gd` | 7 | 移动成功断 `has_moved`；攻击成功断 `has_attacked`；失败/被拒断两个都 false |
| `tests/battle_m2_test.gd` | 5 | 召唤失调断两个都 true；下回合/前线清断两个都 false；攻击后断 `has_attacked` |
| `tests/status_test.gd` | 2 | 冻结断两个都 true；解冻断两个都 false |

**项数不变**：58 / 63 / 38 / 59 / 23 / 46 / 20 / 25 / 35 / 12 / 21 全部照旧，`EXPECTED_CHECKS` 不用动。
另 `tools/check.ps1` 有一条提示文案写着 `敌方 has_acted 每个敌方回合清零`，一并改词。
**注意**：`tests/battle_m1_smoke_test.gd` 里**没有** `has_acted` 断言（早期任务卡写错了）。

**验收**：`tests/pending/keywords_test.gd` **17 项**（解析/召唤失调/闪击/二选一/坦克/闪击+坦克/回合清标志）。
全绿后移到 `tests/`。验收包已用参考实现验证可通行：`_ref_m31` 跑出 keywords_test **17/17** + 主套 **400/400**
+ `validate_data` PASS，且 `balance_sim` 100 场 **48/52、平均 16.0 回合**（未补兵科数据时）。
**补完 `cards.json` 兵科后复测：胜率 48.0%、平均 13.0 回合**，仍全部在区间内。

验收命令只有一条：**`run_tests.bat`**（仓库根）。它分三段 —— PART 1 跑主套判四重条件；
PART 1.5 把 `tests/pending/*_test.gd` 每个文件打一行 `[READY]`（0 红可启用）或 `[PENDING]`（还红着，只报告不判失败）；
PART 2 跑 `tools/preflight.ps1` 做详细自检（数据校验 / `has_acted` 残留 / `EXPECTED_CHECKS` /
兵科覆盖 / **平衡冒烟 100 场** / 脚本编码 / 工作区噪音）。
**本块的验收要看到**：PART 1 `===== ALL GREEN =====`（400 项）+ PART 1.5 `[READY  ] keywords_test 17 checks`
+ PART 2 `[详细自检] PASS`。

> **✅ 2026-11-25 实际验收结果**：`keywords_test` **17/17 PASS**，主套 **417/417**（12 个文件）、
> 0 `[FAIL]`、0 `SCRIPT ERROR`，`validate_data` PASS，PART 2 `[详细自检] PASS（7 项通过、0 条提醒）`，
> pending 剩 5 份 38 项。`keywords_test` 已由 `tests/pending/` 移入 `tests/`。

**坑（都是本轮参考实现真的踩到的）**

1. **typed array 不能整体赋值**
   ```gdscript
   c.keywords = d.get("keywords", [])     # ❌ untyped 赋给 Array[String]
   for k in d.get("keywords", []):        # ✅ 逐项 append
   	c.keywords.append(str(k))
   ```
   对 `abilities` 同理。

2. **`_ai` 里「攻击后手动置标志」两行必须删**
   旧代码是"先调 `attack_unit(...)`，再无条件 `u.has_acted = true`"。改成双标志后这个错误更明显：
   攻击被拒（能量不够 / 不相邻 / 目标非法）时会被误标成"已攻击"，等于骗过后续过滤。
   正确做法：**`attack_unit` 自己置标志，`_ai` 只管"能不能打"的前置过滤**。

3. **「二选一」不是「两个都想一次」**
   `has_moved = true` 之后 `has_attacked` 仍是 false，但**不能再攻击**。
   只写 `if has_attacked: return false` 会红——`keywords_test [5] 非坦克：移动后不能再攻击` 就是专抓这个。

4. **召唤失调 ≠ 冻结 ≠ 部署**
   三个都要"两个标志 true"但语义不同；别在 `_deploy_unit` 里偷懒去调 `_settle_status`。
   另注意**闪击只免疫召唤失调，不免疫冻结**：先部署闪击单位、再给它挂 `immobilized`，它还是不能动。

5. **坦克的例外只解除「互斥」，不解除「各一次」**
   坦克移动两次仍不行（`has_moved` 已 true）；攻击两次也不行。

6. **旧 `has_acted` 别留残影**
   改完 `grep -rn "has_acted" src/ tests/ tools/` 应只剩注释里的历史说明。留一个未改的
   `.has_acted = true` 不会报错（GDScript 动态属性），但会静默失效——主套红的时候很难查。
   **`run_tests.bat` 的 PART 2 [2] 会自动数这个**：`tests/keywords_test.gd` 一旦启用，
   `src/` 里还有 `has_acted` 就直接报 `[FAIL]`，不用自己 grep。

---

## 32. M3.2 Guard

见 `docs/adr/004-m3-keywords.md` 决定 2。

> **✅ 已完成（2026-11-25）**：`guard_test` 8/8 已启用，主套 **425/425** 全绿。
> commit `d3bf911` `feat(battle):` Guard 相邻保护。下面保留任务卡原文作为备课模板。
>
> 2026-11-25：任务卡细化完毕，验收包已用参考实现验证**可通行**
> （补丁 `G:\constraction\_ref_m32_pkg\M32-impl.patch`，**不进 git**）。
>
> **遗留（登记在案，M3.4 上真实 guard 卡前必须处理）**：学生版 `_ai` 选目标的标准是
> 「不是 guard」，而不是「没被保护」。真实卡池有 guard 卡后，AI 会挑「被保护的单位」去打
> → `attack_unit` 返回 false → **白扔一个 AI 回合**。正确做法：在 `battle.gd` 里用
> `_is_guarded()` 挑目标（先找没被保护的敌人，找不到就打 Guard 本身），并补一条 AI 断言。
> 现在测不出来是因为真实卡池里还没有 guard 卡。
> 参考实现只改了 `src/core/battle.gd` 一个文件（+44/-2），核心是**一个 15 行的小函数 + 三处调用**。
> 难度 ★★★、约 70 行，**预计 2–3 h**（顺利的话 1.5 h：核心逻辑不难，难在把「谁保护谁」的方向想清楚）。

**规则（KARDS 护卫）**

| 项 | 规则 |
|---|---|
| 保护范围 | Guard 保护**同线左右相邻格**（slot ±1）的**友军**；跨线不保护 |
| 谁能保护 | 只有带 `guard` 词条的单位保护别人 |
| 谁不能被选中 | 被保护的友军**不能被敌方单位攻击**：`attack_unit` 返回 false |
| Guard 自己 | **Guard 之间互不保护** —— 带 `guard` 的单位永远可以被直接攻击 |
| HQ | **HQ 可被保护**（HQ 在支援线 0 格，1 格有 Guard 时单位打不到 HQ） |
| 指令卡 | **默认无视 Guard**（Order 直接选目标，不改 `play_card`）。以后要"尊重守护"的卡再加 `respects_guard` 字段 |
| 双方 | 玩家与 AI 完全对称 |
| AI | 选目标时跳过被保护的目标；**有 Guard 时退而打 Guard 本身**（别浪费一个回合空挥） |

**API 约定**

| 位置 | 要做 |
|---|---|
| `battle.gd` 新函数 | `_is_guarded(target: Unit) -> bool`：目标是否受保护（见下参考写法） |
| `battle.gd` 新函数 | `_first_attackable(line: String, owner: String) -> Unit`：某线上第一个「打得中」的敌方单位（跳过被保护的），没有返回 null |
| `battle.gd` `attack_unit` | **在相邻线校验之后、扣能量之前**插一句 `if _is_guarded(target): return false` |
| `battle.gd` `_ai` 攻击段 | 原来直接 `attack_unit(u, _opposite_hq(owner))` / `find_first_unit("front")` → 改成先挑「没被保护的」目标，挑不到才 `break` |
| `battle.gd` `play_card` | **不用改**（Order 默认无视 Guard），但要加注释说明这是刻意的 |

**参考写法（照这个思路写，别照抄命名）**

```gdscript
## 目标是否被 Guard 保护：同线左右相邻格有**目标友方**的 guard 单位
func _is_guarded(target: Unit) -> bool:
	if target == null or target.has_keyword("guard"):
		return false                       # Guard 之间互不保护
	var tar := board.position_of(target)
	if tar.is_empty():
		return false
	var line: String = tar[0]
	var idx: int = tar[1]
	for d in [-1, 1]:
		var u: Unit = board.unit_at(line, idx + d)
		if u != null and u.owner == target.owner and u.has_keyword("guard"):
			return true
	return false
```

**改哪里**：`src/core/battle.gd`（**只这一个文件**；`unit.gd` 的 `has_keyword()` 在 M3.1 已经写好了，直接用）。

**连带改（教练做）**：**没有**。`guard_test.gd` 原样可跑（它不依赖 `begin_first_turn()`，
`attack_unit` / `play_card` 都没有阶段校验），教练只需 `git mv` 启用 + 提交。
主套 12 个文件 417 项**一项都不用改**（真实卡池里还没有 `guard` 卡，行为不变）。

**验收**：`tests/pending/guard_test.gd` **8 项**

```
[1] Guard 在 slot1 时，同线相邻 slot2 的单位不能被攻击
[2] 可以直接攻击 Guard 本身
[3] 支援线 1 格有 Guard 时，单位不能攻击相邻的敌方 HQ
[4] 相邻的另一个 Guard 不受保护，可以直接打
[5] 距离 Guard 2 格（slot3）的单位不受保护
[6] Guard 在敌方支援线，不保护前线的单位（跨线）
[7] 被 Guard 保护的敌人仍可被指令卡选中
[8] 指令卡伤害正常结算（10 → 5）
```

参考实现实测（`_ref_m32`）：**guard_test 8/8 PASS**、主套 **417/417**、`validate_data` PASS、
`balance_sim` 100 场 **48.0% / 13.0 回合 / RUNNING 0%**（与改动前完全一致 —— 本块不动平衡）。

**坑（参考实现真踩到的，按严重度排）**

1. **「谁保护谁」的方向最容易写反**（参考实现第一版就是这么错的，红了 [1][3] 两项）
   ```gdscript
   if u != null and u.owner != target.owner and u.has_keyword("guard"):  # ❌ 反了
   if u != null and u.owner == target.owner and u.has_keyword("guard"):  # ✅
   ```
   想清楚：保护者是**目标的友军**，不是攻方的友军。写反了 `[1] 相邻保护` 和 `[3] HQ 保护` 会同时红，
   而 `[2][4][5][6][7]` 全绿 —— 这个红绿组合本身就是「方向写反」的指纹。

2. **Guard 自己不受保护**：`_is_guarded` 第一行必须挡掉 `target.has_keyword("guard")`。
   漏了的直接后果：`[4] 相邻的另一个 Guard 不受保护` 红，而且两个 Guard 并排时会变成"都打不到"的死局。

3. **`attack_unit` 里插判断的位置**：必须在**相邻线校验之后**（跨线本来就不允许）、
   **扣能量之前**（打不中就不该花钱）。放在 `_spend()` 之后会出现"没打到但能量没了"。
   顺序：位置合法 → 相邻线 → **`_is_guarded`** → 能量/同owner → `_spend`。

4. **AI 不能只判空就 break**：`attack_unit` 现在是"可能失败"的（被 Guard 挡住），
   旧写法 `if tgu == null: break` 在"有敌人但全被保护"时不会退出，会白打一整轮。
   要么用 `_first_attackable()` 挑，要么在 `attack_unit` 返回 false 时 `break`。

5. **不要改 `play_card`**：指令卡默认无视 Guard 是 ADR-004 的明确规定（`[7]` 就是验这个）。
   顺手"补上保护"会让 `[7]` 红，也会让 `[8]` 的伤害结算失败。

6. **别动 `tests/`**：8 项断言是验收标准。红了说明实现没对，不是断言写错了。

---

## 33. M3.3 兵科

见 `docs/adr/004-m3-keywords.md` 决定 3。

> **✅ 已完成（2026-11-25）**：`unit_class_test` **21/21** 已启用，主套 **446/446**（14 文件）全绿。
> commit `ea92a38` `feat(battle):` 兵科基础 + 空军越线 + 炮兵/轰炸机无视 Guard。
> 下面保留任务卡原文作为备课模板；学员实际写法和参考实现的差异见 §33.2。
>
> **✅ 验收包已验证可通行**：参考实现只动 `src/core/{unit,battle}.gd` 两个文件
> （+52/−8，**测试一个字没改**），patch 在 `G:\constraction\_ref_m33_pkg\M33-impl.patch`（**不进 git**）。
> 实测：`unit_class_test` **21/21 PASS**、主套 **446/446** 全绿 0 SCRIPT ERROR、
> `validate_data` PASS、`preflight` PASS（7 项）。
> 参考 worktree：`G:\constraction\_ref_m33`（detached @ `8c95536`）。

**难度 ★★★、预计 5–7 h。这是 M3 唯一会动「攻击范围」的块**——现有 `attack_unit` 里那条
`abs(Board.LINES.find(at[0]) - Board.LINES.find(tar[0])) != 1 → return false` 是**所有单位共用**的相邻限制，
空军要开例外，但**不能把普通单位一起放开**。

| 位置 | 要做 |
|---|---|
| `unit.gd` | `unit_class: String` + `Unit.from_dict` 解析；**已经做完了**（M3.1），本块只需读它 |
| `unit.gd` | 新增 5 个谓词（照 `is_tank()` 的写法，集中放，别在 battle.gd 里散着写 `unit_class == "x"`）：`is_artillery()` / `is_fighter()` / `is_bomber()` / `is_air()` = fighter or bomber / `ignores_guard()` = artillery or bomber |
| `battle.gd` 攻击范围 | 新增 `_line_span_ok(attacker, from, to)`：跨度 1 一律放行；跨度 2 **仅空军**放行；其余 false。然后**替换** `attack_unit` 里那行相邻判断，别就地改条件。**不需要**再判线名——三线棋盘上跨度 2 只可能是两条支援线对穿 |
| `battle.gd` 反伤 | 用 `no_counter` 标志，**两个方向分开判**：① 攻击者不受反击 = `attacker.is_artillery() or (attacker.is_bomber() and not target.is_fighter())` ② 目标不反击 = `target.is_bomber()` |
| `battle.gd` Guard | `if not attacker.ignores_guard() and _is_guarded(target): return false`（`_is_guarded()` 本身**不要改**） |
| 数据 | ~~`cards.json` 补 `unit_class`~~ → **M3.1 已补**（步兵/弓手/火法师 = infantry、坦克 = tank）。M3.3 只需**新增**战斗机/轰炸机卡（归 M3.4） |

**兵科规则速查**

| 兵科 | 移动+攻击 | 越线 | 攻击时受反击 | 被打时反击 | 无视 Guard |
|---|---|---|---|---|---|
| `infantry` 步兵 | ✗ 二选一 | ✗ | 是 | 是 | ✗ |
| `tank` 坦克 | ✓ | ✗ | 是 | 是 | ✗ |
| `artillery` 炮兵 | ✗ 二选一 | ✗ | **否** | 是 | **✓** |
| `fighter` 战斗机 | ✗ 二选一 | **✓**（支援线→支援线） | 是 | 是 | ✗ |
| `bomber` 轰炸机 | ✗ 二选一 | **✓** | **否** | **否** | **✓** |

**验收**：`tests/pending/unit_class_test.gd` **21 项**：

| # | 内容 | 项数 |
|---|---|---|
| [1] | 炮兵攻击不受反击 + 目标正常掉血 | 2 |
| [2] | 步兵对照组：正常受反击 | 1 |
| [3] | 坦克先移动再攻击 | 2 |
| [4] | 战斗机跨两条线成功 + 步兵不能跨线 | 2 |
| [5] | 轰炸机跨线成功 | 1 |
| [6] | 轰炸机攻击非战斗机不受反击（含"攻击成立"+"目标掉血"两个防空跑断言） | 3 |
| [7] | 轰炸机被打时不能反击（含"攻击成立"+"轰炸机挨打"两个防空跑断言） | 3 |
| [8] | **对照组**：步兵打不动被 Guard 保护的目标 | 1 + 2 自检 |
| [9] | 炮兵无视 Guard | 1 + 2 自检 |
| [10] | 轰炸机无视 Guard | 1 + 2 自检 |

> **[6][7] 的"防空跑"断言是 2026-11-25 补的**：原来这两项只写 `_check_eq(bomber.hp, 5, ...)`，
> 但 `_new_battle()` 只给玩家侧 `energy = 10`、**敌方 `enemy_energy` 还是 0**，
> 所以在 [7] 里 `b.attack_unit(foe, bomber)` 因为能量不足**直接返回 false**，
> 断言 `foe.hp == 10` 就"空跑变绿"——即无论轰炸机是否真的不反击，这项都是绿的。
> 现在先断言 `attack_unit(...) == true`，再断言血量，并补 `bomber.hp == 3` 证明轰炸机确实挨了打。

**M3.3b**（另一块）：战斗机拦截轰炸机（「轰炸机攻击有战斗机的线只能打战斗机」）单独补 2–4 条。

**改哪里**：`src/core/unit.gd`（小谓词）+ `src/core/battle.gd`（攻击范围 / 反伤 / Guard 三处）。

**7 条坑**

1. **越线判定要单独写函数再替换**。直接把 `!= 1` 改成 `> 2` 或者 `not in [1,2]`，步兵就也能越线了，`[4]` 的第二项会立刻红。
2. **反伤是两条路**：攻击者「不被反伤」（炮兵/轰炸机打非战斗机）≠ 攻击者「不反击」（轰炸机被打）。`attack_unit` 后半段那段 `compute_damage(target.attack, ...)` 要按「谁不能打回去」判断，不是按「谁不能被打」。
3. **Guard 判定和兵科判定要放在一起看**。`_is_guarded(target)` 只回答「目标被保护」，炮兵/轰炸机要绕开它——在 `attack_unit` 里写成 `if not attacker.ignores_guard() and _is_guarded(target): return false`（`ignores_guard()` 放 `Unit`，`_is_guarded()` **本身不要改**，否则 guard_test 那 8 项会一起变味）。
4. **`Board.place()` 的返回值必须检查**。`player_support` / `enemy_support` 的 **0 号格是 HQ**（`const HQ_SLOT := 0`），单位只能放 1–4 格；往 0 格放**静默返回 false**，你不检查就会以为放下了，然后 `_is_guarded()` 查到的是 HQ（`is_guard()=false`），测试莫名其妙地红。（2026-11-25 教练自己踩了这个坑，见 §33.1）
5. **查场上对象用 `board.unit_at(line, i)`**，别用你本地那个 `var u = Unit.from_dict(...)`。正常 `RefCounted` 引用是同一个，但一旦 `place()` 返回 false（比如落进 HQ 格），本地变量和棋盘完全没有关系。
6. **`unit_class` 已经在 M3.1 打通了卡→场链路**（`_deploy_unit` 传 `unit_class`）。别再去改 `_deploy_unit` 加一遍，重复拷贝不会出错但会让 diff 变脏。
7. **别给 `_line_span_ok` 加多余的线名判断**。三线棋盘上「跨度 2」已经等价于「两条支援线对穿」，再写 `_is_support_line()` 是同义反复（教练第一版就这么写了，验证后删掉）。同理**别担心它限制空军上前线**：任何单位站 front 攻击都是 span==1，走第一个分支，跟兵科完全无关。

**参考写法（已验证 17/17，可以直接照这个形状写）**

`src/core/unit.gd`（放在 `is_tank()` 之后）：

```gdscript
func is_artillery() -> bool:
	return unit_class == "artillery"

func is_fighter() -> bool:
	return unit_class == "fighter"

func is_bomber() -> bool:
	return unit_class == "bomber"

## 空军：可以越线（自己支援线 ↔ 对方支援线），见 Battle._line_span_ok()
func is_air() -> bool:
	return is_fighter() or is_bomber()

## 攻击时无视 Guard：炮兵与轰炸机
func ignores_guard() -> bool:
	return is_artillery() or is_bomber()
```

`src/core/battle.gd`（`move_unit` 之后、`attack_unit` 之前）：

```gdscript
## 线跨度判定：常规单位只能打相邻线（跨度 1）；
## 空军额外可以「自己支援线 → 对方支援线」直打（跨度 2）。
## 单独一个函数的原因见坑 1 —— 直接改 attack_unit 那行会把所有兵科一起放开。
##
## 为什么 span==2 只看 is_air()、不用再判线名：棋盘只有三条线
## （Board.LINES = enemy_support / front / player_support），跨度 2 只可能是
## 「两条支援线对穿」这一种形状，不可能出现「支援线 ↔ 前线」跨 2 格。
## 判线名是同义反复（教练第一版写了个 _is_support_line()，验证后删掉了）。
##
## 另：任何单位站在 front 攻击都是 span==1，走第一个分支，**跟兵科无关** ——
## 所以炮兵/飞机上前线打仗完全正常，这个函数只在「支援线打支援线」时才看兵科。
func _line_span_ok(attacker: Unit, from_line: String, to_line: String) -> bool:
	var span: int = abs(Board.LINES.find(from_line) - Board.LINES.find(to_line))
	if span == 1:
		return true
	if span != 2:
		return false
	return attacker.is_air()
```

`attack_unit` 里三处改动：

```gdscript
	if not _line_span_ok(attacker, at[0], tar[0]):        # 替换掉原来的 abs(...) != 1
		return false
	if _energy_of(attacker.owner) < attacker.operation_cost or attacker.owner == target.owner:
		return false
	if not attacker.ignores_guard() and _is_guarded(target):   # 炮兵/轰炸机无视 Guard
		return false
```

反伤段（`if target.is_hq: return true` 之后）：**两个方向分开判**，用一个 `no_counter` 收口：

```gdscript
	# 1) 攻击者不受反击 —— 炮兵；轰炸机打「非战斗机」
	# 2) 目标不反击      —— 轰炸机被打时永远不还手
	var no_counter: bool = false
	if attacker.is_artillery() or target.is_bomber():
		no_counter = true
	elif attacker.is_bomber() and not target.is_fighter():
		no_counter = true
	if not no_counter:
		var hurt: Dictionary = compute_damage(target.attack, target.element, attacker)
		var rdisc: int = attacker.take_damage(hurt["damage"])
		if not hurt["immune"]:
			_apply_aura(attacker, target.element, 1.0)
			_log("%s攻击%s,造成%d%s元素伤害" % [target.display_name, attacker.display_name, rdisc, Element.display_name(target.element)])
		else:
			_log("%s攻击%s,伤害被免疫" % [target.display_name, attacker.display_name])
```

> **注意**：`attacker.is_bomber() and not target.is_fighter()` 是唯一带「非战斗机」条件的项 ——
> **轰炸机打战斗机仍然会挨反击**。这正是 M3.3b「战斗机拦截轰炸机」的接口预留点，别提前改死。

### 33.1 教练侧踩坑记录（2026-11-25，给后面的人省时间）

给本块加 [8][9][10] 三条 Guard 相关测试时，教练第一版写成了

```gdscript
_place(b, g, "player_support", 0)     # ← 0 号格是 HQ，place 静默返回 false
```

看到的现象是「场上那个单位 keywords 变成了 `[]`」，误判成 **`Board.place()` 会丢 keywords**。
实际原因与 `place()` 毫无关系：

```
PROBE place(slot0) returned = false
PROBE slot0 里坐的是 HQ：is_hq=true  kw=[]
PROBE g 自己没被改坏：kw=["guard"]  is_guard=true
PROBE place(slot2) returned = true    → same=true, kw=["guard"]
```

`Board.place()` 只是 `slots[line][index] = unit`，不拷贝、不改单位。**根因是往 HQ 格放单位 + 没看返回值。**
教训：**测试辅助函数里 `place()` 的返回值必须断言**，否则会得到「测试假红 → 怀疑引擎 → 浪费半小时」的路径。

### 33.2 学员实现与参考实现的差异（2026-11-25 落地后记录）

结论先说：**行为等价，21 项全绿，参考实现可以放心丢**。差异只有三处，都是「可接受但值得知道」：

| 差异 | 参考实现 | 学员实现 | 评价 |
|---|---|---|---|
| 越线判定函数名 | `_line_span_ok(attacker, from, to)` | `_line_span_to(attacker, from, to)` | 名字更贴调用处（`if not _line_span_to(...)`），语义相同，**不用改** |
| 反伤判定收口 | 在 `attack_unit` 里用局部 `var no_counter: bool` + `if/elif` | 抽成类方法 `no_counter(attacker, target) -> bool`，三个 `if` 依次 `return true` | **形态更好**：抽成方法后三个判据各占一行，比内联 `if/elif` 更好读。缺点是缺前缀 `_`（项目里私有方法都带 `_`），属风格 nit |
| 攻击方退场位置 | 在反伤段 `if not no_counter: ...` 之后 | 放进 `if not no_counter:` 块内部末尾（`if attacker.hp <= 0: board.remove(attacker)`） | **更正确**：不反击时攻击方根本不会掉血，退场判断放块外要多跑一次无用判断。参考实现当初放块外只是为了少缩进一层 |

另有一处 **死代码**（已记在 commit message 里）：`src/core/board.gd:128 has_fighter(line)` 是 M3.3 为 M3.3b 预留的，**本块无任何调用方**。M3.3b 会正式用起来（并补 `owner` 参数），所以**不要删**。

---

## 33b. M3.3b 战斗机拦截轰炸机

见 `docs/adr/004-m3-keywords.md` 决定 3：`fighter` 战斗机「敌方轰炸机攻击有战斗机的线时只能打战斗机」。

> **✅ 2026-11-25 验收包已验证可通行**：参考实现只动 `src/core/{battle,board}.gd` 两个文件（**+24/−4，测试一个字没改**），
> patch 在 `G:\constraction\_ref_m33b_pkg\M33b-impl.patch`（**不进 git**）。
> 实测：`air_intercept_test` **3/3 PASS**、主套 **449/449 全绿 0 SCRIPT ERROR**（15 文件）、
> `validate_data` PASS、`balance_sim` 100 场 **48.0% / 13.0 回合 / RUNNING 0%**（真实卡池还没有空军卡，行为不变）。
> 所以下面这 3 项是**可以跑通的红基线**，不是画饼。参考 worktree：`G:\constraction\_ref_m33b`（detached @ `ea92a38` + 未提交改动）。

**难度 ★★、预计 1.5–2 h。这是 M3 里最小的一块**，只加一条「目标合法性」规则，不动已有任何判定。

### 规则（一句话）

> 轰炸机攻击某条线时，如果**那条线上有该目标的敌方战斗机**，就只能打战斗机，不能打非战斗机。
> 线上没有战斗机（或战斗机是自己人的）→ 一切照旧。

三线棋盘上「一条线」= `enemy_support` / `front` / `player_support` 三个之一。
所以这条规则只在**轰炸机 vs 支援线**时才有意义：轰炸机站 `front` 可以越线打 `enemy_support`，
如果 `enemy_support` 上有敌方战斗机，那它只能挑战斗机打。

### 要改哪里

| 位置 | 要做 |
|---|---|
| `src/core/board.gd` | `has_fighter(line: String)` **已经存在**（M3.3 预留，`board.gd:128`），但它只判 `u.unit_class == "fighter"`。**给 `owner` 补一个默认参数** `has_fighter(line: String, owner: String = "")`：`owner` 非空时只算该方；顺手修掉两个隐患——`u == null` 会崩、`u.is_hq` 的 `unit_class` 是 `""` 要跳过 |
| `src/core/battle.gd` | 新增 `_bomber_target_ok(attacker, target, to_line) -> bool`，`attack_unit` 里**在 `_is_guarded` 之后、`_spend` 之前**插一行 `if not _bomber_target_ok(attacker, target, tar[0]): return false` |
| ~~`src/core/unit.gd`~~ | **不用动**。`is_bomber()` / `is_fighter()` M3.3 已经有了 |

### 参考写法（已验证 3/3，可以直接照这个形状写）

`src/core/battle.gd`（加在 `_line_span_to` 之后）：

```gdscript
## M3.3b：轰炸机攻击「有敌方战斗机驻守的线」时，只能打那一线的战斗机。
## 判定只在「攻击者是轰炸机、且目标不是战斗机」时生效；其余情况一律放行。
func _bomber_target_ok(attacker:Unit, target:Unit, to_line:String) -> bool:
	if not attacker.is_bomber():
		return true
	if target.is_fighter():
		return true
	return not board.has_fighter(to_line, target.owner)
```

`src/core/board.gd`：

```gdscript
## 该线上是否有战斗机（owner 非空时只算该方的战斗机）
func has_fighter(line:String, owner:String = "") -> bool:
	for u in units_in(line):
		if u == null or u.is_hq:
			continue
		if owner != "" and u.owner != owner:
			continue
		if u.is_fighter():
			return true
	return false
```

### 验收：`tests/pending/air_intercept_test.gd` **3 项**

| # | 内容 | 项数 |
|---|---|---|
| [1] | 目标线有敌方战斗机时，轰炸机不能打该线非战斗机 | 1 |
| [2] | 轰炸机可以打该线的战斗机 | 1 |
| [3] | 目标线没有战斗机时，轰炸机照常打非战斗机 | 1 |

全绿后 `git mv tests/pending/air_intercept_test.gd tests/`，主套 14 → **15 文件、446 → 449 项**。

### 6 条坑

1. **判定必须「只在攻击者是轰炸机时生效」**。写成「目标线有战斗机就拒」，战斗机/步兵之间的正常互殴会一起被拒——`combat_test`(59) / `guard_test`(8) / `unit_class_test`(21) 会同时红一片。
2. **必须判「敌方」战斗机，不能判「有战斗机」**。己方战斗机不该保护敌方单位；虽然正常战局里敌我不会同线，但 `air_intercept_test` 用 `board.place` 手工造局面，写错方向立刻红。
3. **`to_line` 要用 `tar[0]`（目标所在线），不是 `at[0]`（攻击者所在线）**。轰炸机是从 `front` 打 `enemy_support` 的，两线不同。用 `at[0]` 会去查攻击者自己那条线（一般是空的），于是**判定恒放行**。实测这个错法的红绿指纹是 **`[1]` `[2]` 红、`[3]` 绿（3 项红 2 项）**：`[1]` 因为没拒绝而红，`[2]` 是级联红（`[1]` 已经把轰炸机的 `has_attacked` 用掉了，所以 `[2]` 的「去打战斗机」也被拒）。**别被 `[3]` 的绿骗了**——它跟 `to_line` 对不对无关。
4. **`has_fighter()` 里 `u.is_hq` 必须跳过**。HQ 的 `unit_class` 是 `""` 不会命中，但 HQ 的 `owner` 语义与普通单位不同，跟着 `owner` 过滤时容易误判；`u == null` 也必须判（`units_in()` 会返回 null 空位）。
5. **不要动 `_line_span_to()` 和 `no_counter()`**。M3.3 刚验证过 21 项，本块只加「能不能选中这个目标」，不碰「能不能打到这条线」和「挨不挨反击」。轰炸机打战斗机**仍然会挨反击**（`no_counter` 只在目标是战斗机时返回 false）——这是 M3.3 就定好的，别顺手改。
6. **插在 `_spend()` 之前**。放后面就成了「先扣能量再拒绝」，`attack_unit` 返回 false 但能量没了，`order_test` / `battle_m2_test` 里连续攻击的用例会莫名能量不足。

---

## 34. M3.5 卡组构筑（39 张 + 1 HQ）

- 数据：`data/decks/player_deck.json` / `enemy_deck.json`：`{ "name": ..., "cards": [{"id": ..., "count": N}] }`；总张数 **39**（HQ 不进牌库）；同名上限待定（建议 4）。
- `DataLoader.load_deck(path) -> Array[Card]`：校验 id 存在、count>0、总数 39、同名 ≤ 上限；非法 → `push_error` + 返回空（不崩）。
- `Battle.setup` 仍接收展开好的 `p_deck`，不改签名。
- 验收测试 `tests/pending/deck_build_test.gd`（**10 项**：展开张数/非法 id/超上限/总数不对/双方独立）。`data/decks/` 示例 + `validate_data` 牌组校验已备。

---

## 35. M3.6 元素 v3（多槽附着）

规格见 `docs/adr/005-element-auras-v3.md` + `docs/element-reactions-v3.md`（数据 schema/算法/迁移清单/测试用例清单）。实现前还需：数据迁移（elements/reactions v3）+ `tests/pending/aura_v3_test.gd`（按 v3 文档 §7 的 24 项）。这轮不动现有数据/测试（迁移与代码同批提交）。

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

**只跑一条命令：`run_tests.bat`（在仓库根目录）。** 它现在是**三段式**，一次跑完教练手工验证的全部内容：

```
################ PART 1  main suite (tests\*_test.gd) ################
  —— 自动发现 tests\*_test.gd；每文件判 退出码 + 有 PASS + 无 [FAIL] + 无 SCRIPT ERROR
  —— 全绿时每个文件只打一行 [PASS]；有红就 dump 该文件完整日志

############ PART 1.5  pending baseline (tests\pending\*_test.gd) ############
  —— 每个待启用文件一行：[READY  ] name  N checks --> git mv ...   /  [PENDING] name  N checks / M failed
  —— 只报告，永不判失败

################ PART 2  detailed preflight (tools\preflight) ################
  [1] 数据校验               validate_data.gd 必须 PASS
  [2] 旧字段残留             src/ 里 has_acted 命中数（M3.1 启用后必须 0）
  [3] EXPECTED_CHECKS       每个测试文件都必须声明，否则少跑会假绿
  [4] 兵科覆盖               cards.json 单位卡的 unit_class 覆盖率
  [5] 平衡冒烟               balance_sim 100 场：胜率 45–60% / 8–20 回合 / RUNNING < 1%
  [6] 脚本编码               *.bat 必须 CRLF + 纯 ASCII；*.ps1 有中文必须带 UTF-8 BOM
  [7] 工作区噪音             data/tables/*.json 的行尾换行假 diff + 未提交改动清单
  —— 末行 ===== ALL GREEN ===== 才算过（PART 2 退出码非 0 也会把总结果拉成失败）
```

三段都过才是 `===== ALL GREEN =====`，退出码 0。**别只看单个文件的退出码**：

```bash
# 只想跑某一个文件、看失败数有没有变少（调试用，不算验收）
& $g --headless --path . --script res://tests/battle_m2_test.gd

# 只想跑 PART 2（比如刚补完数据、想确认真实卡池的 unit_class 齐不齐）
tools\preflight.bat

# 想手动看一局（battle.gd 写完后才用得上）
& $g --headless --path . --script res://tests/run_battle.gd
```

**全绿 = 失败 0 项 + 退出码 0 + 输出里没有 `SCRIPT ERROR` + PART 2 全通过。**
前者可能"少跑了几条也全绿"（所以每个测试文件末尾会校验应执行的项数），第二个是"报错被吞"。

改工具时注意：`preflight.ps1` 有中文，**必须存成 UTF-8 with BOM**（PowerShell 5.1 否则乱码）；
`preflight.bat` / `run_tests.bat` 必须 **CRLF + 纯 ASCII**（`.gitattributes` 已固定 `.bat → eol=crlf`）。

---

