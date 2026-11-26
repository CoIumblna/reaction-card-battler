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
| 22 | `unit.gd`+`card.gd`+`battle.gd`（M3.1：行动经济/关键词/Blitz） | 3 | ★★★ | 80 | **4–6 h**（实际编码约 1.5 h） | keywords_test（17 项，已启用） | [x] |
| 23 | `battle.gd`（M3.2：Guard） | 3 | ★★★ | 70 | **2–3 h**（实际编码约 0.5–1 h） | guard_test（8 项，已启用） | [x] |
| 24 | `battle.gd`（M3.3：兵科基础 + 空军越线 + 炮兵/轰炸机无视 Guard） | 3 | ★★★ | 140 | **5–7 h**（实际编码约 1–1.5 h） | unit_class_test（21 项，已启用） | [x] |
| 25 | `battle.gd`（M3.3b：战斗机拦截轰炸机） | 1 | ★★ | 30 | **0.5–1 h**（实际编码约 20 min） | air_intercept_test（3 项，2026-11-26 已启用） | [x] |
| 26 | `data/tables/cards.json`（M3.4：卡池 20+） | 1 | ★★ | 0（数据） | **1–2 h**（创意为主，不含想点子） | data_test + validate_data | [~] 进行中（学员已加 2 张，13 种 / 49 张） |
| 26b | `battle.gd`（**M3.4 前置**：AI 选目标，清 M3.2 遗留） | 1 | ★★★ | 70 | **0.5–1 h** | `tests/pending/ai_guard_test.gd`（14 项） | [ ] 备课完成（§39），基线 14/6 红 |
| 27 | `data_loader.gd`（M3.5：卡组构筑 39+1） | 1 | ★★ | 65 | **0.5–1 h**（实际约 1 h） | `tests/deck_build_test.gd`（11 项） | [x] ✅ 完成（2026-11-26，commit `014ad88`，主套 485/485） |
| 28 | `element.gd`+`unit.gd`+`damage.gd`+`battle.gd`（M3.6：元素 v3 多槽） | 4 | ★★★★ | 300 | **6–10 h**（最大块；备课前粗估，风险最高） | aura_v3_test（24 项待写） | [ ] |
| 29 | `battle.gd`（M3.7：**通用 stat 系统** `stat_of(unit, stat)`） | 1 | ★★★ | 90 | **1–1.5 h**（实际约 1 h，含一轮两行修复） | stat_mod_test（7）+ stat_system_test（18），**已启用** | [x] |
| 30 | `battle.gd`（M3.8a：AI 打指令卡） | 2 | ★★★ | 80 | **1.5–2.5 h** | battle_m2_test 增补（测试待写） | [ ] |
| 31 | 平衡（M3.8：balance_sim 调参） | 3 | ★★★ | 60 | **2–3.5 h**（含反复跑模拟的时间） | docs/balance-report.md | [ ] |
| 32 | 文档与 tag（M3.9：tag v0.3） | 1 | ★ | 0 | **0.5 h** | README + HANDOFF | [ ] |
| 33 | **M4.0** 骨架 + 中文字体（§37.1） | 4 | ★ | 60 | **1–1.5 h** | 主场景能加载 + `[FONT OK]` | [ ] |
| 34 | **M4.1a** 只读快照 + 合法动作（§37.2） | 4 | ★★ | 100 | **1–1.5 h** | ui_snapshot_test（≥12 项） | [ ] |
| 35 | **M4.1b** AI 单步（§37.3） | 1 | ★★ | 40 | **1–1.5 h** | ui_ai_step_test + 10 seed 对比 | [ ] |
| 36 | **M4.2** 手牌 UI（§37.4） | 3 | ★★ | 120 | **1–2 h** | ui_hand_flow_test | [ ] |
| 37 | **M4.3** 出牌交互（§37.5） | 2 | ★★ | 120 | **1.5–2 h** | ui_play_flow_test | [ ] |
| 38 | **M4.4a** 战场只读（§37.6） | 2 | ★★ | 110 | **1.5–2 h** | ui_board_view_test（15 格映射） | [ ] |
| 39 | **M4.4b** 战场交互（§37.7） | 2 | ★★★ | 130 | **2–3 h** | ui_board_flow_test | [ ] |
| 40 | **M4.5** 回合流转与结算（§37.8） | 3 | ★★ | 110 | **1–1.5 h** | 收工三判据 + 人工走查 | [ ] |
| 41 | **M4.6** 动画与反馈（§37.9） | 1 | ★★ | 110 | **1.5–2 h** | 关掉动画后 turn 数不变 | [ ] |
| 42 | **M4.7** 主菜单 / 关卡选择（§37.10） | 2 | ★ | 90 | **0.5–1 h** | 关卡数 == enemies.json | [ ] |
| 43 | **M4.8** 设置（§37.11） | 1 | ★ | 70 | **0.5–1 h** | settings.cfg 可机器比对 | [ ] |
| 44 | **M4.9a** 存档读写（§37.12） | 1 | ★★ | 90 | **1–1.5 h** | save_test（≥10 项） | [ ] |
| 45 | **M4.9b** 存档迁移兜底（§37.13） | 1 | ★★ | 60 | **1–1.5 h** | save_migrate_test（≥8 项） | [ ] |

**列的含义**
- **预计行数** = 你要新写的代码行数量级（不含注释/测试）。实际多 50% 很正常。
- **预计用时** = 一个已经读过任务卡的学员，**从动手到 `run_tests.bat` 全绿**的净编码时间。
  不含：读文档、卡住求助、等教练 review、改数据、跑平衡模拟。
  经验倍率：★ ×1、★★ ×2、★★★ ×4、★★★★ ×8（相对 ★ 的 0.5 h 基准）。
  第一次做某类任务会偏慢（比如第一次用 typed array、第一次写洗牌），**做过的同类任务第二次起能省 30–40%**。
- **完成列**：`[x]` 已完成并提交 / `[~]` 进行中 / `[ ]` 未开始。

> ### 实测校准（2026-11-25，**重要**）
>
> **学员自报：11-25 全天完成 M3.1 收尾 + M3.2 + M3.3 三块，实际编码总共只有 3–4 h。**
> 当天绝大部分时间花在**等 agent 反馈**（写→跑测试→贴报错→等 review→再改）上，不是敲代码。
>
> 据此把原来的「★★★ = 4–7 h」下修：这三块的**真实净编码**分别是
> M3.1 ≈ 1.5 h、M3.2 ≈ 0.5–1 h、M3.3 ≈ 1–1.5 h，约为原估的 **1/3 ~ 1/4**。
> 原因很清楚：任务卡已经把 API 形状、调用点、坑都写死了，学员实际是在**照着图纸填空**，
> 而不是自己设计；加上 GDScript 改动量本来就小（这几块真实 diff 是 97 / 44 / 61 行）。
>
> **所以上表的「预计用时」现在读作「乐观上限」**；未完成的块已按这个倍率下调过。
> 真正决定进度的是**一次 round-trip 的延迟**，不是编码本身 —— 想让一天多出活儿，
> 该优化的是「少一轮返工」（任务卡写细、坑提前列出），而不是催快打字。

**M3 剩余总量估算**：约 **13–22 h** 净编码（2026-11-25 按实测倍率下修；其中 M3.6 元素 v3 独占 6–10 h）。
按每天 3–4 h 净编码算 ≈ **4–6 个工作日**。注意这是「纯打字时间」，实际日历时间由**返工轮数**决定。

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

> **M4（界面 + 存档）的任务卡见 §37 / §38**（2026-11-26 立项）。M3 全部完成并 tag `v0.3` 之后才开 M4。

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
> 难度 ★★★、约 70 行，**原估 2–3 h**；2026-11-25 实测**学员净编码约 0.5–1 h**（任务卡把方向写死了，只剩照抄）。

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

**难度 ★★★、原估 5–7 h（2026-11-25 实测学员净编码约 1–1.5 h）。这是 M3 唯一会动「攻击范围」的块**——现有 `attack_unit` 里那条
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

> **✅ 2026-11-26 已完成并启用**：`air_intercept_test` **3/3 PASS**、主套 **449/449 全绿 0 SCRIPT ERROR**（15 文件）、
> `validate_data` PASS、`balance_sim` 100 场 **48.0% / 13.0 回合 / RUNNING 0%**（真实卡池还没有空军卡，行为不变）。
>
> **学员最终实现**（只有两行有效改动，比参考实现更简洁）：
> - `src/core/battle.gd:347`（`_is_guarded` 之后、`_spend` 之前）
>   `if attacker.is_bomber() and board.has_fighter(tar[0]) and not target.is_fighter(): return false`
> - `src/core/board.gd:128` 的 `has_fighter()` 循环里加一句 `if u.is_hq: continue`（防御，非必需）
>
> 没有引入 `_bomber_target_ok()` 辅助函数、也没有给 `has_fighter()` 补 `owner` 参数 —— 两个都不需要，见坑 2。
> 参考 patch 留档在 `G:\constraction\_ref_m33b_pkg\M33b-impl.patch`（**不进 git**），只作对照。

**难度 ★★、预计 0.5–1 h（原估 1.5–2 h，参考实现实际 ~20 min）。这是 M3 里最小的一块**，只加一条「目标合法性」规则，不动已有任何判定。

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
2. **只需要「这条线上有没有战斗机」，不需要判归属**。2026-11-26 验证过：部署唯一入口 `battle.gd:225`
   `board.place(nu, _line_of(owner), ...)`、移动唯一入口 `move_unit()`（还额外要求前线无敌军），
   加上全仓 `board.place(` 只有这一处调用 —— **每条线在任意时刻都只属于一方**，
   所以 `has_fighter(line)` 单参数不会被别人的战斗机误判，**不要给它加 `owner` 参数**。
   ⚠️ 曾经有教练在这里加了一项「己方战斗机不该拦住轰炸机」的用例（第 4 项），并用 `board.place` 手工拼出
   「敌我同线」，**那是规则上不可能出现的局面**，该用例与「必须判 owner」的结论均已作废（详见 HANDOFF §13.5）。
3. **`to_line` 要用 `tar[0]`（目标所在线），不是 `at[0]`（攻击者所在线）**。轰炸机是从 `front` 打 `enemy_support` 的，两线不同。用 `at[0]` 会去查攻击者自己那条线（一般是空的），于是**判定恒放行**。实测这个错法的红绿指纹是 **`[1]` `[2]` 红、`[3]` 绿（3 项红 2 项）**：`[1]` 因为没拒绝而红，`[2]` 是级联红（`[1]` 已经把轰炸机的 `has_attacked` 用掉了，所以 `[2]` 的「去打战斗机」也被拒）。**别被 `[3]` 的绿骗了**——它跟 `to_line` 对不对无关。
4. **`has_fighter()` 里 `u.is_hq` 必须跳过**。HQ 的 `unit_class` 是 `""` 不会命中，但 HQ 的 `owner` 语义与普通单位不同，跟着 `owner` 过滤时容易误判；`u == null` 也必须判（`units_in()` 会返回 null 空位）。
5. **不要动 `_line_span_to()` 和 `no_counter()`**。M3.3 刚验证过 21 项，本块只加「能不能选中这个目标」，不碰「能不能打到这条线」和「挨不挨反击」。轰炸机打战斗机**仍然会挨反击**（`no_counter` 只在目标是战斗机时返回 false）——这是 M3.3 就定好的，别顺手改。
6. **插在 `_spend()` 之前**。放后面就成了「先扣能量再拒绝」，`attack_unit` 返回 false 但能量没了，`order_test` / `battle_m2_test` 里连续攻击的用例会莫名能量不足。

---

## 34. M3.5 卡组构筑（39 张 + 1 HQ）

> **✅ 2026-11-26 已完成并启用（commit `014ad88`，主套 18 文件 485/485）**。以下为备课时的复验数据：：参考实现只改 `src/core/data_loader.gd` 一个文件（+65 行，`tests/`、`data/`、`tools/` **零改动**），
> patch 在 `G:\constraction\_ref_m35_pkg\M35-impl.patch`（**不进 git**）。
> 实测（worktree `_wt_m35` detached @ `56b0b85` + 测试假绿修复后）：`deck_build_test` **11/11 PASS**、
> `data_test` **46/46**、`validate_data` PASS、`balance_sim` 100 场 48.0% / 13.0 回合 / RUNNING 0%。
> 五条反假绿探针 ①②③④⑤ 全部按预期变红（详见验收后的补记）。

**难度 ★★、预计 0.5–1 h（原估 2–3 h，参考实现实际 ~25 min）。这是 M3 里「数据早已备好、只差一个加载函数」的块**，改动量只有 65 行。

### 规则

| 项 | 值 |
|---|---|
| 牌组总张数 | **39**（`DECK_SIZE`，HQ 不进牌库） |
| 同名上限 | **4**（`MAX_SAME_CARD`）。**同一 id 写成多行要合并算**：`[{footman,2},{footman,3}]` 合计 5 张 → 非法 |
| HQ | **不表示为 Card、不进牌库**。HQ 是 `Board.setup()` 建的 `Unit.from_dict({...,"is_hq":true})`，`load_deck` 只管 39 张 |
| 数据形状 | `{ "name": "...", "cards": [{"id": "...", "count": N}, ...] }` |

非法情形（统一 `push_error` + 返回**空数组**，不崩、不 `assert`、不 `return null`）：
未知 id / `cards` 不是数组或缺失 / `count <= 0` / 同名合计 > 4 / 总数 ≠ 39。

### 要改哪里

| 位置 | 要做 |
|---|---|
| `data_loader.gd` | 加 `const DECK_SIZE := 39` + `const MAX_SAME_CARD := 4`（**与 `tools/validate_data.gd:236-237` 的同名常量对齐**，两处必须一致） |
| `data_loader.gd` | 新增 `static func load_deck(path: String) -> Array[Card]` |
| `data_loader.gd` | 建议再抽一个 `static func _card_catalog(path := DATA_DIR + "cards.json") -> Dictionary`（id → 模板字典），展开时复用 |
| `data/decks/*.json` | **不用改**，现有 `player_deck.json` / `enemy_deck.json` 已经是 4+4+4+4+4+4+4+4+3+2+2 = 39 张、同名 ≤ 4、id 全在 `cards.json` 里 |
| `tools/validate_data.gd` | **不用改**，牌组校验早就写好了 |
| `Battle.setup` | **不改签名**，仍接收展开好的 `p_deck` |

### 参考写法（已验证 11/11，可以照这个形状写）

```gdscript
static func _card_catalog(path: String = DATA_DIR + "cards.json") -> Dictionary:
	var out := {}
	var data := load_json(path)
	for item in data.get("cards", []):
		if typeof(item) == TYPE_DICTIONARY and str(item.get("id", "")) != "":
			out[str(item["id"])] = item
	return out


static func load_deck(path: String) -> Array[Card]:
	var out: Array[Card] = []
	var data := load_json(path)
	if data.is_empty():
		return out                       # load_json 里已经 push_error
	if not data.has("cards"):
		push_error("牌组缺少 cards 数组：" + path)
		return out
	var entries = data["cards"]
	if typeof(entries) != TYPE_ARRAY:
		push_error("牌组的 cards 不是数组：" + path)
		return out

	var catalog := _card_catalog()
	var total := 0
	var seen := {}                       # id -> 已计入的张数（同一 id 写多行也要合并算）
	for item in entries:
		if typeof(item) != TYPE_DICTIONARY:
			push_error("牌组里有一条不是对象：" + path)
			return out
		var id := str(item.get("id", ""))
		var count := int(item.get("count", 0))
		if not catalog.has(id):
			push_error("牌组里有未知卡牌 id `%s`：%s" % [id, path])
			return out
		if count <= 0:
			push_error("卡 `%s` 的 count 必须 > 0（实际 %d）：%s" % [id, count, path])
			return out
		seen[id] = int(seen.get(id, 0)) + count
		if int(seen[id]) > MAX_SAME_CARD:
			push_error("同名卡 `%s` 超过上限 %d（%d 张）：%s" % [id, MAX_SAME_CARD, int(seen[id]), path])
			return out
		total += count
	if total != DECK_SIZE:
		push_error("牌组张数必须 = %d（实际 %d）：%s" % [DECK_SIZE, total, path])
		return out

	# 校验全部通过后才展开。每份都从 cards.json 的模板重新 from_dict，
	# 保证同一张卡的多份是互不共享状态的独立对象（Battle 会 erase/修改它们）。
	for item in entries:
		var template: Dictionary = catalog[str(item["id"])]
		for i in range(int(item["count"])):
			out.append(Card.from_dict(template))
	return out
```

### 验收：`tests/deck_build_test.gd` **11 项**（✅ 2026-11-26 已启用，commit `014ad88`）

| # | 内容 | 项数 |
|---|---|---|
| [1] | API 存在：`DataLoader` 有 `load_deck(path)` 方法 | 1 |
| [2] | 加载玩家牌组：39 张 / `footman` 4 张 / `guard` 3 张 | 3 |
| [3] | 敌方牌组也是 39 张 / 两次加载不是同一数组引用 / 展开的 Card 也不共享引用 | 3 |
| [4] | 非法牌组四种：未知 id / 总数不对 / `count<=0` / 同名超上限 | 4 |

全绿后 `git mv tests/pending/deck_build_test.gd tests/`，主套 17 → **18 文件、474 → 485 项**。

> **[3][4] 的断言是 2026-11-25 修正的**（原来 10 项，两处假绿）：
> ① 原来写 `_check(p != e or p.size() == e.size(), ...)` —— `or` 后半句在正常实现下**恒真**，整条断言永远通过；
> 一个「返回同一个共享数组」的错误实现照样绿。改成 `_check(not is_same(p, e), ...)`，
> 并补一条 `_check(not is_same(p[0], e[0]), ...)` 查展开后的 Card 也是独立对象。
> ② 「总张数不对」用例原来写 `[{footman,10}]`，它**同时**违反同名上限（4），而已知实现里同名检查在前、
> 总数检查在后 → `push_error` 打的是「同名超上限」，**总数分支从未被执行**。
> 改成 37 张、每个 id 合法、同名都不超 4 的牌组，日志确认命中 `牌组张数必须 = 39（实际 37）`。
> `EXPECTED_CHECKS` 同时 10 → 11。
>
> **[4] 里另外两条用例是 2026-11-26 再修的**（同一类缺陷，反假绿探针 ② 暴露）：
> - `bad_dup` 原来写 `[{footman,5},{archer,34}]` —— footman 超上限、archer **34 也超上限**，两条同时违规。
>   把 `MAX_SAME_CARD` 从 4 放宽到 5 后，archer 仍然触发拦截，断言照样通过 → **测不到「同名上限」这条规则**。
>   改成 `footman 5 + 其余 8 种各 4 + guard 4 + mend 2 = 39 张`，只违反同名上限。
> - `bad_count` 原来写 `[{footman,0}]` —— count 0 让总数变成 0，**同时**违反「总数必须 39」。
>   改成 `footman 0 + 其余 9 种各 4 + fire_burst 3 = 39 张`，只违反 `count > 0`。
> - 项数不变，仍 11。修后复验：探针 ② 红「同名超过 4 张 → 空数组（期望 0，实际 39）」、
>   `count < -100` 探针红「count <= 0 → 空数组（期望 0，实际 39）」。
>
> **通用教训：每个非法用例必须「只违反一条规则」**，否则断言会因为别的原因通过，
> 你把那条检查删掉测试都不会红。验证手段只有一个 —— **故意把实现改坏，看测试会不会红**。

### 6 条坑

1. **typed array 必须逐项 `append`**。`Array[Card]` 不接受 `out = out.filter(...)`、也不接受直接赋 `entries.map()` 的结果
   （untyped → typed 赋值会运行时报错）。展开时用 `for i in range(count): out.append(Card.from_dict(tpl))`。
2. **必须两遍循环：第一遍只校验，第二遍才展开**。边校验边 `append` 的话，非法牌组会返回「部分展开」的非空数组，
   测试的 `.size() == 0` 立刻红——而错误信息却写着「牌组非法」，很容易怀疑到错误的地方。
3. **同一 id 写多行要累计判定**。只判单行 `count > 4` 会让 `[{footman:2},{footman:3}]`（合计 5）漏过。
   用 `seen[id] = int(seen.get(id, 0)) + count` 累加后再比 `MAX_SAME_CARD`。
4. **每份 Card 必须是独立对象**。若复用同一个模板引用（或把 `cards.json` 里的字典直接塞给多个 Card），
   Battle 的 `hand.erase(card)` / 修改 `cost` 会串状态。每份都调一次 `Card.from_dict(template)` ——
   `from_dict` 内部自己 `new()`，所以天然独立（测试 [3] 的第三条断言在查这个）。
5. **静态入口和实例 call 都要能走**。测试用 `DataLoader.new().call("load_deck", path)`（`has_method` + `call`），
   是因为方法还没实现时直接静态调用会**编译报错**，整个测试文件跑不起来。你写成 `static func` 后，
   静态调用和实例 `call` **两种方式都能通**，不用为测试特殊处理。
6. **`push_error` 输出的是 `ERROR:`，不是 `SCRIPT ERROR:`**。脚本判定「假绿」看的是 `SCRIPT ERROR` 计数，
   所以非法牌组用例正常走 `push_error` **不会**污染判定。别为了让日志干净把 `push_error` 去掉 ——
   那等于吞掉错误。

---

## 35. M3.6 元素 v3（多槽附着）

规格见 `docs/adr/005-element-auras-v3.md` + `docs/element-reactions-v3.md`（数据 schema/算法/迁移清单/测试用例清单）。实现前还需：数据迁移（elements/reactions v3）+ `tests/pending/aura_v3_test.gd`（按 v3 文档 §7 的 24 项）。这轮不动现有数据/测试（迁移与代码同批提交）。

---

## 36. M3.7 通用 stat 系统（stat_of / stat_mod）

**难度 ★★★、预计 1–1.5 h（参考实现实际 ~35 min）。改动约 90 行，只动 `src/core/battle.gd` 一个文件（推荐）。**

（2026-11-25 建节；2026-11-26 学员拍板「做通用 stat 系统」后整节重写。
上一版「推荐只处理 `defense_down`」的方案已作废 —— 那是通用层没拍板时的建议，现在约束反过来了。）

**施工思路见 `docs/brief-stat-system-2026-11-26.md`（只给思路不给代码）。本节是规格与验收，冲突以 brief 为准。**

### 规则

| 项 | 值 |
|---|---|
| 属性生效值 | 基础值 + 身上所有 `stat_mod` 效果按 `stacks` 的加总 |
| 基础值来源 | `attack` → `Unit.attack`；`defense` → **0**（单位没有基础防御字段） |
| 生效范围 | **单位攻击**和**指令卡伤害都生效**（两者共用 `compute_damage`，属性加算放这一层） |
| 计算顺序 | 生效值在攻击发起前算好喂给 `compute_damage`；最终伤害 `max(0, ...)` 钳位 |
| `immune` 时 | **不加减防**（伤害本就无效，别算出「免疫还掉血」） |
| 失效 | 走 `Buff.tick_buffs()`，`duration` 到 0 移除，效果随之消失 |
| 叠层 | `Unit.add_buff()` 同 `kind` 只 `stacks += 1`，**不新增 Buff 对象** |

对照 `data/tables/statuses.json` 里目前唯一的 `stat_mod` 状态：

```json
"defense_down": {
  "name": "减防",
  "effects": [ { "kind": "stat_mod", "stat": "defense", "value": -1.0, "timing": "passive" } ]
}
```

### 通用层的定义（本块的验收核心）

> **系统里出现任何一条新的 `stat_mod` 效果，不改代码就该生效。**

这条约束直接排除「认 `b.kind == "defense_down"`」的写法。
判定一条效果是否计入，**只看状态定义里的字段，不看状态 id、不列属性名白名单**：

| 字段 | 你的系统该怎么用 |
|---|---|
| `kind` | 只处理 `"stat_mod"`（`dot` / `disable` / `aura` 各有归属） |
| `stat` | **与查询的 `stat` 相等就计入** —— 不列白名单 |
| `value` | 乘 `stacks`，四舍五入取整 |
| `timing` | **缺省按 `passive` 处理**；写了别的值（如 `turn_start`）就不计入属性 |

`timing` 缺省这条容易漏：`tools/validate_data.gd:166-168` 对 `stat_mod` **只强制 `stat` / `value`**，
`timing` 可缺省。写成「必须 `== "passive"` 才算」会让缺省的效果被静默丢掉 —— `stat_system_test` [6] 专抓这条。

### 两条路线（都实测全绿），学员自选

先看清三个对象各自能拿到什么 —— 这是本块唯一的设计决定点：

| 对象 | 有 | 没有 |
|---|---|---|
| `Buff`（`src/core/buff.gd`） | `kind` / `stacks` / `duration` | `stat`、`value`（在 `statuses.json`） |
| `Unit` | `buffs` 数组 | `StatusTable`（不持有） |
| `Battle` | `status_table` 成员（`battle.gd:26`） | — |

→ 「`value` 是多少」只有 `Battle` 能顺手问到。由此两条路：

- **路线 1（推荐）**：属性查询整个留在 `Battle`，新增公开方法
  `func stat_of(unit: Unit, stat: String) -> int`；`unit.gd` 一行不动。
  `compute_damage()` 里写成 `compute_damage(stat_of(target, "attack"), ...)` 的形式。
- **路线 2**：下放到 `Unit`，则 `Unit` 必须多收一个 `StatusTable` 参数
  （`stat_mod(stat: String, table: StatusTable) -> int`，**两个参数**），`Battle` 调它时递进去。
  代价：每个调用点都要传 table。

参考实现走路线 1（verbatim，仅供我复验对照，**不发给学员**）：

```gdscript
func compute_damage(base_power: int, element: String, target: Unit) -> Dictionary:
	var d := Damage.compute(base_power,element,target,reaction_table)
	if not d.get("immune", false):
		d["damage"] = max(0, int(d["damage"]) - stat_of(target, "defense"))
	return d

func stat_of(unit: Unit, stat: String) -> int:
	var total: int = 0
	match stat:
		"attack":
			total = unit.attack
		"defense":
			total = 0
	for b in unit.buffs:
		var status: Dictionary = status_table.get_status(b.kind)
		for e in status.get("effects",[]):
			if str(e.get("kind","")) != "stat_mod":
				continue
			if str(e.get("stat","")) != stat:
				continue
			var timing := str(e.get("timing",""))
			if timing != "" and timing != "passive":
				continue
			total += int(round(float(e.get("value",0.0)))) * b.stacks
	return total
```

另有两处调用点同样要换成生效值：`attack_unit` 里攻击方
`compute_damage(stat_of(attacker,"attack"),attacker.element,target)`，
以及反击侧 `compute_damage(stat_of(target,"attack"),target.element,attacker)`。

### 加在哪、四条约束

`Battle.compute_damage()` 是**单位攻击**（`attack_unit`）和**指令卡伤害**（`play_card`）共用的出口，
属性加算放这一层，两处都生效。

1. **`immune` 时不要加** —— `Damage.compute()` 返回的字典带 `immune` 标记，此时伤害本就无效。
2. **别改 `damage.gd`** —— `Damage.compute()` 是 `static`（摸不到 `status_table`），
   且 `combat_test` / `damage_test` / `status_test` 有大量 `hit["damage"]` 断言。
3. **伤害必须钳到 0** —— 防御可能高过攻击（`stat_system_test` [3] 就是 2 点攻击打 3 点防御）。
   不钳位时负伤害会流进 `take_damage()` 的「护盾够扣」分支变成 `shield -= 负数`，
   **白送护盾、血量不掉**，看着像「挡住了」，其实是数据被写坏。[3] 有一条专门断言 `shield == 0`。
4. **攻击方和反击方都要用生效值** —— `attack_unit` 里两次 `compute_damage`：攻击方一次、
   反击方一次（`no_counter()` 为 false 的分支）。只改前一处的红绿指纹是 **[2][4] 红**、其余绿。

### 验收一：`tests/pending/stat_mod_test.gd` **7 项**（规则）

| # | 内容 | 项数 |
|---|---|---|
| [1] | 没有 buff：3 点攻击 → 10 - 3 = 7 | 1 |
| [2] | 1 层 `defense_down`（duration 2）：伤害 4 → 10 - 4 = 6 | 1 |
| [3] | 叠 2 层：+2 伤害 → 10 - 5 = 5 | 1 |
| [4] | **指令卡伤害**同样吃 `defense_down`：5 点 + 减防 1 → 6（10 - 6 = 4） | 1 |
| [5] | duration 1 的减防在回合开始后移除（`buffs.size() == 0`）| 1 |
| [6] | buff 失效后攻击成立（防空跑；2026-11-25 补） | 1 |
| [7] | buff 失效后伤害恢复：10 - 3 = 7 | 1 |

### 验收二：`tests/pending/stat_system_test.gd` **18 项**（通用性）

这个文件用的 `attack_up` / `defense_up` / `luck` / 无 `timing` 四种状态定义**都不在**
`data/tables/statuses.json` 里，而是运行时注入 `b.status_table.statuses[id] = d`
（故意不改数据文件 —— `tests/data_test.gd:157` 有 `_check_eq(st.status_count(), 4, "状态数量")`）。
**写死状态 id 或属性名白名单必红。**

| # | 内容 | 项数 |
|---|---|---|
| [1] | 基线：无 buff 时 `stat_of(atk,"attack") == attack`、`stat_of(atk,"defense") == 0`、伤害不变 | 3 |
| [2] | `attack_up`（+2）注入后 `stat_of(atk,"attack") == attack + 2`，伤害跟着 +2 | 3 |
| [3] | `defense_up`（+3）注入后伤害被吃掉，且**钳到 0**：`shield == 0`、血量不掉 | 4 |
| [4] | 双属性互不串台：同时带 attack/defense 两条 stat_mod，各自只算自己的 | 3 |
| [5] | `timing: "turn_start"` 的 stat_mod **不计入**属性 | 1 |
| [6] | **缺 `timing` 的 stat_mod 按常驻计入**（等价 `passive`） | 1 |
| [7] | 未知属性：查 `"luck"` 返回那条的加总，且不影响 `attack` / 伤害 | 3 |

未实现时的基线：**18 项 / 18 失败**（文件开头有 `has_method("stat_of")` 守卫，
未实现时打满 18 条失败再 `_finish()` 早退，**显示 18 项全红而不是 0 项**）。

### 反假绿探针（四条，全部实测过红绿指纹）

| # | 把什么改坏 | 期望指纹 |
|---|---|---|
| ① | `stat_of` 改成只认 `defense_down` / `defense` | `stat_mod_test` 仍 **7/7 绿**，`stat_system_test` **红 9 项** |
| ② | 攻击侧改回 `compute_damage(attacker.attack, ...)` | `stat_system_test` 红 **[2][4]** |
| ③ | 去掉 `max(0, ...)` 钳位 | 红 [3] 的 `shield == 0` 断言 |
| ④ | `timing` 写成严格 `== "passive"` | 红 [6]（缺 timing 的被静默丢掉） |

另有数据跟随性判据：把 JSON 里 `-1.0` 改成 `-2.0`，`stat_mod_test` [2] 期望值应变 5；
不变 = 数值写死在代码里。

### 全绿之后

`git mv tests/pending/stat_mod_test.gd tests/` 与 `git mv tests/pending/stat_system_test.gd tests/`，
主套 15 → **17 文件、449 → 474 项**（449 + 7 + 18）。
（`deck_build_test` 是 M3.5 的活，不在这里。）

> **✅ 2026-11-26 完成（commit `8343343`）**：学员按路线 1 实现，`src/core/battle.gd` **+22/−2**，
> `unit.gd` 未动。`stat_mod_test` **7/7**、`stat_system_test` **18/18**，
> 主套 **17 文件 474/474** 全绿 0 SCRIPT ERROR、`validate_data` PASS、
> `balance_sim` 100 场 48.0% / 13.0 回合 / RUNNING 0%。
> 独立 worktree 检出 `8343343` 逐文件复验，17 个测试全部 fail=0 serr=0。
> 学员本轮两处错：①`if d.get("immune",false):` 语义反了（应 `not`）；
> ②`str(e.get("stat","")) != "stat"` 拿字符串字面量当形参比较，效果全被 continue 跳过。
> 用学员实现实测四条探针：只认 `defense_down` → 规则测试仍 7/7 绿但通用性测试红 9 项；
> 攻击侧改回 `attacker.attack` → 红 2 项；去掉 `max(0,...)` → 红 1 项；`timing` 严格 `== "passive"` → 红 1 项。

### 四条坑

1. **叠层要用 `b.stacks`**。`add_buff()` 同 `kind` 只做 `b.stacks += 1`，不新增对象 —— 数 `buffs.size()` 永远算 1 倍。
2. **加在目标侧，不是攻击侧**。是「目标受到的伤害 +1」，不是「攻击者攻击力 +1」；加错到攻击者，[1]（无 buff）也会变，红得莫名其妙。
3. **`Buff` 上没有 `stat` / `value`**。别指望 `b.value`，数值必须经 `status_table.get_status(b.kind)` 问出来。
4. **别给 `Unit` 加 `status_table` 成员**。用参数传（路线 2）。加成员会让单位脱离数据表就不能单测，
   `unit_test` 里那些直接 `Unit.from_dict(...)` 造的单位会崩。

---

## 37. M4 任务卡总览（界面 + 存档）· 2026-11-26 立项

> **M4 只做一件事：让这个项目「能玩、能给人看」。**
> 能开窗口、能用手点着打完一局、中文不是方块、关掉再打开进度还在。
> **发布（导出 exe / 网页、商店页、演示 GIF）属于 M5，M4 不碰。**
>
> 完整规划（拆块理由、风险、排除项、BACKLOG 对照）见 **`docs/m4-plan.md`**。
> 本节是**施工用的任务卡**：每一块照着 §37.N 做，做完回来打勾。
>
> **前置**：M3 全部完成、`run_tests.bat` 全绿并 tag `v0.3` 之后才开 M4。
> 当前 M3 还剩 M3.4 / M3.5 / M3.6 / M3.8a / M3.8 / M3.9。
>
> **分工**：`scenes/*.tscn`、`src/ui/*.gd` = 学员写；规格 / 测试 / 数据 / 文档 / CI = 教练。
> `src/core/` 只允许**新增** UI 需要的公开接口，已有的 `play_card` / `move_unit` / `attack_unit` / `stat_of`
> 行为一行都不许变（M4 期间「顺手重构 core」是明确禁止的）。

### 37.0 M4 进度表

| # | 块 | 交付物 | 难度 | **预计用时** | 验收（测试 / 判据） | 完成 |
|---|---|---|---|---|---|---|
| 37.1 | **M4.0** 骨架 + 中文字体 | `project.godot`（主场景 + 窗口尺寸）、`scenes/main.tscn`、`src/ui/main_screen.gd`、`assets/fonts/README.md` | ★ | **1–1.5 h** | 退出码 0 无 `Failed to load main scene`；`[FONT OK]`；截图中文非方块 | [ ] |
| 37.2 | **M4.1a** 只读快照 + 合法动作 | `battle.gd`：`snapshot()` / `legal_targets` / `legal_moves` / `legal_attacks`；`tests/ui_snapshot_test.gd` | ★★ | **1–1.5 h** | 快照纯读（调 100 次状态不变）；`legal_*` 与 `play_card` 拒绝条件一致 | [ ] |
| 37.3 | **M4.1b** AI 单步 | `battle.gd`：`ai_step() -> bool`；`tests/ui_ai_step_test.gd` | ★★ | **1–1.5 h** | 循环调完能走完一个 AI 回合；`run_auto` 10 个固定 seed 终局逐一致 | [ ] |
| 37.4 | **M4.2** 手牌 UI | `src/ui/hand_view.gd` / `card_view.gd`（已交付）/ `hand_controller.gd`；`tests/ui_hand_flow_test.gd` | ★★ | **1–2 h** | 注入 1/4/9 张假快照断言卡宽与可见张数；9 张不溢出；换牌可用 | [ ] |
| 37.5 | **M4.3** 出牌交互 | `src/ui/play_controller.gd`、`battle_screen.gd`；`tests/ui_play_flow_test.gd` | ★★ | **1.5–2 h** | 状态机 4 步；非法目标不调 `play_card`；ESC 回 idle | [ ] |
| 37.6 | **M4.4a** 战场只读 | `src/ui/board_view.gd` / `unit_view.gd`；`tests/ui_board_view_test.gd` | ★★ | **1.5–2 h** | 3×5=15 格映射无错位；HQ 在 `HQ_SLOT`；`has_moved`/`has_attacked` 有标记 | [ ] |
| 37.7 | **M4.4b** 战场交互 | `src/ui/board_controller.gd`；`tests/ui_board_flow_test.gd` | ★★★ | **2–3 h** | 高亮集合 == `legal_moves` / `legal_attacks`；点格调 `move_unit` 一次且参数对 | [ ] |
| 37.8 | **M4.5** 回合流转与结算 | `src/ui/turn_bar.gd` / `result_panel.gd` / `turn_controller.gd` | ★★ | **1–1.5 h** | 结束回合 → `ai_step` 循环 → 回到玩家；AI 期间遮罩；胜负面板取 `outcome()` | [ ] |
| 37.9 | **M4.6** 动画与反馈（可关） | `src/ui/fx.gd`；设置项 `fx_enabled` | ★★ | **1.5–2 h** | 关掉动画后对局 turn 数不变；动画期间数据已落地；连点不重入 | [ ] |
| 37.10 | **M4.7** 主菜单 / 关卡选择 | `scenes/main_menu.tscn`、`src/ui/main_menu.gd` / `level_select.gd` | ★ | **0.5–1 h** | 关卡条目数 == `enemies.json` 条数；三场景来回切 3 次无报错 | [ ] |
| 37.11 | **M4.8** 设置 | `src/ui/settings.gd`、`user://settings.cfg` | ★ | **0.5–1 h** | 改完即写即生效；重启读回；音量走 `AudioServer`；语言占位不崩 | [ ] |
| 37.12 | **M4.9a** 存档读写 | `src/core/save_system.gd`；`tests/save_test.gd` | ★★ | **1–1.5 h** | 存读深比较一致；版本号正确；缺字段被拒；落盘在 `user://` | [ ] |
| 37.13 | **M4.9b** 存档迁移与兜底 | `src/core/save_system.gd` 的 `_migrate`；`tests/save_migrate_test.gd` | ★★ | **1–1.5 h** | v0 假档能升 v1；未知高版本被拒；坏档自动备份 `*.bad` 并重置 | [ ] |

**合计 ≈ 15–22 h 净编码**（对照 `BACKLOG.md` G 组 42h + H 组 9h = 51h，按 M3 实测倍率 ÷2.5）。
按每天 3–4 h 净编码 ≈ **5–7 个工作日**；实际日历进度由**返工轮数**决定，不是打字速度。

**关键路径**：`37.1 → 37.2 → 37.6 → 37.7 → 37.9`。这条链上任何一块延期，后面全部顺延。
**可以挪到后面**的：`37.10 / 37.11 / 37.12 / 37.13`（不阻塞「能玩」，只阻塞「能存」）。

### 37.1 M4.0 骨架 + 中文字体

#### 规则（一句话）

建出项目的**第一个场景**并注册成主场景，给所有界面装一个**能显示中文的全局主题**。

#### 要改哪里

| 文件 | 改什么 |
|---|---|
| `project.godot` | 加 `[application] run/main_scene="res://scenes/main.tscn"`；加 `[display] window/size/viewport_width=1280` / `viewport_height=800`（现在啥都没有，默认窗口放不下棋盘） |
| `scenes/main.tscn` | **手写最小结构**：一个根 `Control` + 挂 `src/ui/main_screen.gd`，节点十几行 |
| `src/ui/main_screen.gd` | `_ready()` 里 `theme = UiTheme.make_theme()`，然后用代码建控件（标题 Label + 当前块占位） |
| `assets/fonts/README.md` | 写清「当前走系统字体 `SystemFont`、依赖 Microsoft YaHei、发布前要决定是否内嵌 Noto Sans SC（SIL OFL，约 10MB）」 |

`src/ui/ui_theme.gd` 与 `src/ui/card_view.gd` **已交付**（commit `1847bc3`），不要重写。

#### 验收（4 条，逐条打勾）

| # | 判据 | 怎么验 |
|---|---|---|
| 1 | 主场景能加载 | `& $g --headless --path . --quit-after 3` 退出码 0，且**不出现** `Failed to load main scene` |
| 2 | 中文字形可用 | `& $g --headless --path . --script res://tools/check_font.gd` 打印 `[FONT OK] <字体名>` 且退出 0 |
| 3 | 中文真的是字 | 开窗口截一张图，标题的字不是方块 |
| 4 | 没弄红主套 | `run_tests.bat` 仍 `ALL GREEN`（加上场景与脚本后不许多出 `SCRIPT ERROR`） |

#### 坑（4 条）

1. **默认字体没有中文字形，且不报错**。Godot 内置 Open Sans SemiBold 完全没有 CJK 字形，中文一律显示成
   `□□□□`。这不是 bug，是字体缺字形。必须用 `SystemFont` + `font_names`，`UiTheme.make_font()` 已经做好。
2. **`Font.has_char()` 的入参是 int 码位，不是字符串**。写 `f.has_char("中")` 会静默永远 false。
   正确写法 `"中".unicode_at(0)`。`tools/check_font.gd` 里已经踩过并修好，照抄那行。
3. **`.tscn` 手写，不要用编辑器拖**。编辑器生成的场景几百行、带 `uid://` 与 `ext_resource`，
   **几乎无法 review diff**，两人改同一场景必冲突。约定：`scenes/` 只放「根节点 + script」，控件全在脚本里建。
   副作用是「在编辑器里打开场景是空的」——这是刻意换来的可维护性。
4. **改 `project.godot` 后必须 `--import`，否则新场景不注册**。而且 `run_tests.bat` 的 PART 1 不会因此报错
   （它跑的是 `--script`），只有第 1 条验收命令能发现——所以这条必须手工验。

### 37.2 M4.1a 只读快照 + 合法动作查询

#### 规则（一句话）

给 UI 一个**只能看、不能改**的数据入口，以及「这张卡能打谁」「这个单位能去哪」的权威答案。

#### 要改哪里

| 方法 | 签名 | 语义 |
|---|---|---|
| `snapshot` | `() -> Dictionary` | 纯读地打包当前局面：手牌 / 三条线每格单位 / 双方 HQ 血量 / 能量 / 回合数 / `opening_phase` / `is_over` / `outcome` / 最近 N 条日志 |
| `legal_targets` | `(card: Card) -> Array[Unit]` | 这张卡现在能打哪些单位（必须与 `play_card` 的拒绝条件完全一致） |
| `legal_moves` | `(unit: Unit) -> Array` | 这个单位能移到哪些 `(line, index)` |
| `legal_attacks` | `(unit: Unit) -> Array[Unit]` | 这个单位能打哪些单位 |

`legal_*` 的判据只有一条：**同样的输入，`play_card` / `move_unit` / `attack_unit` 会拒绝的，这里就不能返回**。
两份实现必然对不上，所以这些函数应该**内部复用**已有的校验逻辑，不要另写一套规则。

#### 验收：`tests/pending/ui_snapshot_test.gd`（≥12 项）

| # | 断言 |
|---|---|
| 1 | 快照里手牌张数 == `hand.size()` |
| 2 | 快照里三条线每格单位与 `board.unit_at()` 一致（3×5 全查） |
| 3 | 双方 HQ 血量正确 |
| 4 | `energy` / `turn` / `opening_phase` / `is_over` / `outcome` 都在 |
| 5 | **纯读**：连续调 `snapshot()` 100 次后，`get_log()`、手牌数、场上单位数完全不变 |
| 6 | `legal_targets` 返回的每个目标，`play_card` 都成功（或至少不被「非法目标」拒） |
| 7 | `play_card` 会拒的目标不在 `legal_targets` 里 |
| 8 | `legal_moves` 不含该单位当前格 |
| 9 | `legal_attacks` 与 `attack_unit` 的接受集合一致 |

#### 坑（4 条）

1. **`snapshot()` 里绝对不能有副作用**。UI 每次刷新都会调它，任何「顺手 tick buff」「顺手抽牌」
   都会变成「看一眼就改变游戏」。测试第 5 项就是抓这个的。
2. **不要在 UI 里重写规则**。`legal_targets` 内部应该调 core 已有的判定；写第二份规则，M3.6 改元素规则时必然漏。
3. **别把 `Card` / `Unit` 对象直接塞进快照的深层结构**。快照里给 `Unit` 的地方给 `Unit` 是允许的
   （UI 要读 `hp` / `attack`），但**不要给 UI 一份能改回去的引用链**（比如直接暴露 `buffs` 数组本体，要 `.duplicate()`）。
4. **`Array[Card]` 类型化数组不能直接赋 `filter()` 的结果**，要逐项 `append`。

### 37.3 M4.1b AI 单步

#### 规则（一句话）

把「AI 跑完整局」拆成「AI 走一步」，让 UI 能一步一步放动画。

#### 要改哪里

`src/core/battle.gd` 新增 `func ai_step() -> bool`：让**当前行动方**的 AI 走一步，返回「是否还有后续步」。
`run_auto()` 内部改成循环调 `ai_step()` —— 这是必须的，否则两条 AI 路径会分叉。

#### 验收：`tests/pending/ui_ai_step_test.gd`

| # | 断言 |
|---|---|
| 1 | 循环 `while b.ai_step(): pass` 能走完敌方一个回合，不卡死、无 `SCRIPT ERROR` |
| 2 | **`run_auto()` 语义不变**：取 10 个固定 seed，改动前后的终局 `turn` / `outcome` 逐一致 |
| 3 | 对局已结束时再调 `ai_step()` 返回 `false` 且不报错 |
| 4 | 玩家回合期间调 `ai_step()` 是明确的 no-op（返回 `false`），不会替玩家出牌 |

#### 坑（3 条）

1. **第 2 条是这块唯一真正重要的验收**。把 `run_auto` 改走 `ai_step` 却没跑 seed 对比，
   等于在没人看守的情况下换了 AI 的全部行为 —— 平衡基线（48.0% / 13.0 回合）会悄悄漂移。
2. **`ai_step()` 必须在「无事可做」时返回 `false`**，否则 UI 的循环会死转。
3. 别把 `_ai()` 里的逻辑复制一份到 `ai_step()`。`ai_step` 应该只是把 `_ai()` 里「做一件事」拆出来。

### 37.4 M4.2 手牌 UI

#### 规则（一句话）

把玩家手牌画出来，能选中、能换牌。**卡面用已交付的 `src/ui/card_view.gd`，不要重画。**

#### 要改哪里

| 文件 | 职责 |
|---|---|
| `src/ui/hand_view.gd`（`Control`） | 只负责把 controller 算好的位置画出来（卡宽、间距、选中态） |
| `src/ui/hand_controller.gd`（**继承 `RefCounted`，不继承 `Control`**） | 全部逻辑：给定「快照 + 手牌张数 + 一次点击」→ 返回「要做什么」。**只有它需要被测试覆盖** |
| `tests/pending/ui_hand_flow_test.gd` | 覆盖 controller |

`src/ui/card_view.gd` 已交付（`set_card(dict)` 换卡、`CARD_W=168` / `CARD_H=228`）。

#### 验收

| # | 判据 |
|---|---|
| 1 | 注入 1 / 4 / 9 张假快照，`hand_controller` 返回的「每张卡宽度 / 可见张数」断言正确 |
| 2 | 窗口里 4–9 张不重叠、不溢出屏（9 张 = `Battle.MAX_HAND` 满手牌不挤压） |
| 3 | `opening_phase` 为真时出现「换牌」按钮，点选 ≤N 张 → 调 `mulligan("player", 选中)` → 手牌刷新 |
| 4 | 选中切换的返回值正确（同一次点击两次 = 取消） |

#### 坑（3 条）

1. **逻辑必须在不继承 `Control` 的类里**。现有 17 个测试都是 `extends SceneTree`，主循环不跑，
   `Control._ready()` / 布局完全不执行 → 对 `Control` 写断言必然测不到东西（要么全空，要么 `is_inside_tree()` 假）。
2. **不要在 `_process` 里每帧重建卡面**。回合制本来不该有逐帧逻辑；只在状态签名变化时重建。
   签名可以是 `turn + energy + hand.size() + 存活单位数 + 双方 HQ 血量`。
3. **9 张是硬上限**（`Battle.MAX_HAND`）。手牌区要按「最坏情况 9 张」算卡宽，别按 4 张算。

### 37.5 M4.3 出牌交互

#### 规则（一句话）

点牌 → 高亮合法目标 → 点目标 → 调 `play_card` → 刷新；中途可取消。

#### 要改哪里

`src/ui/play_controller.gd`：一个三态状态机 `idle / card_selected / target_selected`，
入参是「快照 + 点击事件」，返回值是「要调 `play_card` 还是什么都不做」。合法目标集一律来自 `legal_targets`。

#### 验收：`tests/pending/ui_play_flow_test.gd`

| # | 断言 |
|---|---|
| 1 | 合法路径 4 步（点牌 → 点目标 → 出牌成功 → 回 idle） |
| 2 | 非法目标被拒，且 **`play_card` 一次都没被调用** |
| 3 | 右键 / ESC 回 idle 且选中态清空 |
| 4 | 出牌成功后手牌 −1、能量下降、日志新增 ≥1 行（对照 `snapshot()`） |
| 5 | 能量不够的牌点不动（不能进入 `card_selected`） |

#### 坑（3 条）

1. **「调了几次 `play_card`」必须能断言**。测试里用一个假 `Battle` 或计数器，别真的去打真对局 ——
   否则「非法目标被拒」和「合法目标成功」看起来一样。
2. 别在 UI 里判断「能量够不够」。那是 core 的规则，`legal_targets` 已经隐含了它。
3. 取消路径要清干净所有中间态，否则下一次点牌会带着脏状态。

### 37.6 M4.4a 战场只读

#### 规则（一句话）

把三条线 × 5 格画出来，HQ 单独样式，单位带攻防血与已行动标记。**先只读，不做交互。**

#### 要改哪里

`src/ui/board_view.gd` + `src/ui/unit_view.gd`。线顺序严格 `Board.LINES`
（`["enemy_support", "front", "player_support"]`），HQ 落在支持线的 `HQ_SLOT == 0`，其余 4 格。

#### 验收：`tests/pending/ui_board_view_test.gd`

| # | 断言 |
|---|---|
| 1 | 用构造快照断言「哪个 `(line, index)` 渲染到哪个格」的映射表，**3×5=15 个位置无错位** |
| 2 | HQ 只出现在两条支持线的 0 号格，不占 `UNIT_SLOTS_PER_SUPPORT` 的 4 格 |
| 3 | `has_moved` / `has_attacked` 为真时单位有可见标记（灰化或角标）——截图对比开/关两态 |

#### 坑（3 条）

1. **`HQ_SLOT == 0`，支援线 0 号格是 HQ，不是单位格**。画成「5 个平级格子」是这块最常见的错。
   参考 `tests/` 里那个老坑：`board.place(unit, "player_support", 0)` 会**静默返回 false**（格子被 HQ 占着）。
2. **线顺序不能按「上中下舒服」排**，必须按 `Board.LINES` 的顺序来，否则敌方/我方上下颠倒。
3. **只读块不要顺手加点击**。带着交互一起调，出错时分不清是「画错了」还是「点错了」——
   这就是为什么 M4.4 要拆成 a / b 两半。

### 37.7 M4.4b 战场交互

#### 规则（一句话）

选中己方单位 → 高亮可移动 / 可攻击的格 → 点下去 → 调 core 的方法。

#### 要改哪里

`src/ui/board_controller.gd`（状态机），高亮集合**必须**来自 `legal_moves` / `legal_attacks`。

#### 验收：`tests/pending/ui_board_flow_test.gd`

| # | 断言 |
|---|---|
| 1 | 选中己方单位 → 高亮格集合 **== `legal_moves` 集合**（不多不少） |
| 2 | 点格 → `move_unit` 被调用一次，参数是 `(unit, to_line, to_index)` |
| 3 | 攻击路径同理，目标集 == `legal_attacks`；打 HQ 也能选中 |
| 4 | 召唤失调的单位能选中但无高亮，点空白处取消 |

#### 坑（3 条）

1. **「不多不少」是双向断言**。只断言「`legal_moves` 里每个都高亮了」会漏掉「多高亮了非法格」，
   而那才是真 bug（玩家点了被打回来）。
2. **召唤失调 ≠ 不能选中**。要能选中看信息，只是不能行动。
3. 攻击 HQ 走的是 `legal_attacks` 里返回的那条路径，别在 UI 里特判「打 HQ」。

### 37.8 M4.5 回合流转与结算

#### 规则（一句话）

能量条 / 回合数 / 结束回合按钮 / AI 回合遮罩 / 胜负结算面板。

#### 要改哪里

`src/ui/turn_bar.gd`、`src/ui/result_panel.gd`、`src/ui/turn_controller.gd`。

#### 验收

| # | 判据 |
|---|---|
| 1 | 点「结束回合」→ `end_turn()` → 循环 `ai_step()` 直到对方回合结束 → 回到玩家回合，**全程 UI 不卡死** |
| 2 | AI 行动期间输入被遮罩（点牌无效） |
| 3 | `is_over()` 为真时弹结算面板，文字取 `outcome()`（WIN / LOSE 都要能显示），按钮「再来一局 / 回主菜单」可用 |

#### 坑（2 条）

1. **AI 回合要真的把控制权交还主循环**。用 `await` 或分帧，别在一个 `_on_pressed` 里同步跑完整个 AI 回合 ——
   那样窗口会假死，玩家看不到任何 AI 动作。
2. 结算面板出现后要**停掉输入**，否则玩家能继续点棋盘。

### 37.9 M4.6 动画与反馈（可整体关闭）

#### 规则（一句话）

伤害跳字、攻击位移、出牌飞入、回合横幅 —— **全部可 `await` 也可跳过**，且关掉不影响任何结算。

#### 要改哪里

`src/ui/fx.gd`：`play_damage / play_attack / play_card_fly / play_turn_banner`，
全部先看 `fx_enabled`，为 false 立即 return；为 true 时用 `Tween`。

#### 验收

| # | 判据 |
|---|---|
| 1 | `fx_enabled = false` 时所有动画函数立即返回；跑一局 `turn` 数与无动画版本一致 |
| 2 | **动画期间数据已落地**：先改数据再播动画，所以关掉动画不改变任何结算结果 |
| 3 | 连续快速点两次出牌不会重复触发动画（防重入） |

#### 坑（2 条）

1. **顺序反了是这块的经典 bug**：先播动画再改数据，一旦动画被打断（关掉、切场景），
   数据就停在半路 —— 出现「血条不动但单位死了」。
2. Tween 是最容易随布局改动反复重做的一层，所以放在功能稳定之后（M4.3/4.4b/4.5 之后）。

### 37.10 M4.7 主菜单 / 关卡选择

#### 规则（一句话）

启动进主菜单：新游戏 / 继续（有存档才亮）/ 设置 / 退出；关卡列表从 `data/tables/enemies.json` 生成。

#### 验收

| # | 判据 |
|---|---|
| 1 | 启动进主菜单；四个按钮状态正确 |
| 2 | 关卡条目数 == `enemies.json` 数据条数（**改 JSON 后重启界面跟着变**，不许写死） |
| 3 | 选关 → 进场 → 打完 → 回主菜单，三场景来回切 3 次 `is_instance_valid` 检查通过 |

#### 坑（2 条）

1. **UI 里不许出现中文卡名 / 关卡名字面量**。全部从 `data/` 读，这是 `docs/architecture.md` 的禁令之一，
   `preflight` 第 `[9]` 项会查 `src/ui/` 里的裸字段读取，但中文字面量要人工看一眼。
2. 场景切换要 `queue_free()` 干净，否则旧场景的 `Tween` 还在跑。

### 37.11 M4.8 设置

#### 规则（一句话）

音量、动画开关、语言（v1 只有中文，占位），存 `user://settings.cfg`。

#### 验收

| # | 判据 |
|---|---|
| 1 | 改动后立即生效并写入 `user://settings.cfg`；重启后读回（配置文件内容可机器比对） |
| 2 | 音量走 `AudioServer.set_bus_volume_db`，静音时 `0` 不报错 |
| 3 | 语言下拉只有「简体中文」且不崩溃；选其它值不会写坏配置 |

#### 坑（1 条）

**`res://` 打包后只读**。`FileAccess.open("res://settings.cfg", WRITE)` 在编辑器里能过、导出后必失败
（而且是在玩家机器上失败）。一律 `user://`，落在 `%APPDATA%\Godot\app_userdata\<项目名>\`。

### 37.12 M4.9a 存档：结构 + 读写 + 校验

#### 规则（一句话）

存「重建一局所需的最小信息」，不存整个 `Battle`。

#### 要改哪里

`src/core/save_system.gd`：`SAVE_VERSION := 1`、`save_game(state: Dictionary, slot: int) -> bool`、
`load_game(slot: int) -> Dictionary`、`has_save(slot: int) -> bool`。存档内容 = `snapshot()` 的子集 + 关卡/牌组 id。

#### 验收：`tests/pending/save_test.gd`（≥10 项）

| # | 断言 |
|---|---|
| 1 | 存 → 读，内容深比较一致 |
| 2 | 版本号写入正确 |
| 3 | 缺字段被拒（返回空字典 / false，不崩） |
| 4 | 落盘路径是 `user://saves/slot1.json`（打印实际路径人工看一眼） |
| 5 | `core/` 里不出现任何 `Control`（`preflight` `[9]` 会查） |

#### 坑（2 条）

1. **不要序列化整个 `Battle`**。里面有 `Card` / `Unit` / `Board` 三层引用，直接序列化等于把 core 的内部
   结构钉死成文件格式，以后改字段就要写迁移。
2. **`user://` 不是 `res://`**。见 37.11 坑 1。

### 37.13 M4.9b 存档：版本迁移 + 损坏兜底

#### 规则（一句话）

旧版本存档能升上来，坏存档不崩、备份、重置。

#### 要改哪里

`src/core/save_system.gd` 加 `_migrate(from: int, data: Dictionary) -> Dictionary`，
以及「读失败 → 备份成 `*.bad` → 返回空 → 界面提示」这条兜底链路。

#### 验收：`tests/pending/save_migrate_test.gd`（≥8 项）

| # | 断言 |
|---|---|
| 1 | v0 假档能升到 v1 |
| 2 | 未知**高**版本被拒（返回空，不是崩溃） |
| 3 | 手工把存档改成乱码 → 不崩、自动备份 `*.bad`、提示「存档损坏已重置」 |
| 4 | 迁移用的是**测试内构造的旧档**，不依赖仓库里留旧文件 |

#### 坑（1 条）

**迁移测试要在测试里构造旧档**，不要往仓库里提交一份 `slot1.v0.json` 当夹具 —— 那份文件会过时，
而且没人知道它对应哪个字段版本。

---

## 38. M4 全阶段通用规矩（每块都适用）

### 38.1 统一开工 / 收工动作

M4 每一块都按同一个模板走，不要临时发明流程。目的是把「返工轮数」压到 1 轮以内 ——
M3 的实测已经证明，日历进度的瓶颈是 round-trip 次数，不是打字速度。

| 阶段 | 动作 | 判据 |
|---|---|---|
| 开工前 | 报预计用时：`预计 X–Y h（依据：§37.N 难度 ★★ + 交付物 N 个文件）` | 与 §37.0 表对得上；对不上先说清为什么 |
| 开工前 | 跑一次 `run_tests.bat`，确认基线全绿 | 拿到「改动前」的绿，否则以后分不清是谁弄红的 |
| 写代码 | 只碰本块「交付物」列出的文件；**想改别的文件先停下来说明** | `git status` 里不出现计划外文件 |
| 自测 | 本块的 `tests/ui_*_test.gd` / `save_*_test.gd` 绿；无 `[FAIL]`、无 `SCRIPT ERROR` | **退出码 0 不等于通过**，必须看终端输出 |
| 收工 | `run_tests.bat` 全绿 + 三条验收判据逐条打勾 + 截一张图 | 三项都齐才算 done |
| 收工 | 记录实际用时；偏差 >2 倍时写一句原因 | 便于下一块继续校准 |

**测试落位沿用 M3**：新测试先写进 `tests/pending/`，主套全绿后 `git mv` 到 `tests/` 才启用；
启用时同步文件末尾的 `EXPECTED_CHECKS`。不要让 UI 阶段出现「测试写在 pending 里躺了三块」。

### 38.2 M4 完成判据（8 条，全部同时成立）

| # | 判据 | 怎么验 |
|---|---|---|
| 1 | 能开窗口用手打完一整局：主菜单 → 选关 → 打完 → 结算 → 回主菜单，不报错不卡死 | 人工 3 局（赢 1 / 输 1 / 中途退出 1） |
| 2 | 中文全部正常 | `tools/check_font.gd` 退出 0 + 3 张截图 |
| 3 | 能存能读：关掉重开，「继续」回到存档点 | 存档在 `user://`，读回后 turn / 血量 / 手牌一致 |
| 4 | 坏档不崩：提示 + 备份 + 重置，游戏能继续 | 人工 1 次（出现 `*.bad`） |
| 5 | `run_tests.bat` 仍 ALL GREEN，新增测试已从 pending 迁出 | `===== ALL GREEN =====` |
| 6 | core 里没有界面代码，UI 无裸字段读取 | `preflight` 第 `[9]` 项 PASS |
| 7 | 数据全部来自 `data/`：`src/ui/` 里没有中文卡名 / 关卡名字面量 | 人工 `grep` 一眼 |
| 8 | 文档同步：本节进度表打勾、`HANDOFF` 更新、`README.md` 写明「怎么开窗口玩」 | 人工读一遍 |

### 38.3 M4 明确不做（防止范围膨胀）

多语言全量翻译、联网 / 对战、美术资源（卡面图 / 立绘）、关卡编辑器、平衡调参、
音效、新手引导、导出打包 / 商店页 / 演示 GIF（M5）、重构 core。

### 38.4 三条「看着更快的错路」

| 错路 | 为什么看着快 | 实际后果 |
|---|---|---|
| 先做交互再做布局（跳过 37.6 直接做 37.7） | 「反正最后都要点」 | 布局改 3 次 → 坐标硬编码的点击判定跟着改 3 次 → 每轮都要人工点一遍，返工量比先做只读大得多 |
| UI 直接读 `battle.hand` / 直接调 `_ai()`（跳过 37.2/37.3） | 省 2–3 h | core 从此被 UI 钉死：改手牌容器、给 AI 加流派，每次都要连带改 UI。M3.6 元素 v3 就是因为早期结构没抽象才改那么久 |
| 一次把 11 个界面全搭出来再统一调 | 「先把架子搭完」 | 字体 / 主题 / 刷新策略任何一个定晚了，5 个界面一起返工；而且没有一块是可验收的 |

**一条反向判据**：如果某一块做完，你**没法用一条命令或一个截图证明它成了**，说明这块切大了 —— 回去拆。

---

## 39. M3.4 前置：AI 选目标（清 M3.2 遗留）· 2026-11-26 备课

> **✅ 验收包已验证可通行**（2026-11-26）：参考实现补丁
> `G:\constraction\_ref_ai_guard_pkg\AiGuard-impl.patch`（2611 字节，**不进 git**）
> 在干净 worktree 上 `git apply` OK → `ai_guard_test` **14/14 PASS**、
> 主套 **19 文件 499/499**、`validate_data` PASS、`balance_sim --games 200 --seed 1`
> **45.0% / 13.0 回合 / RUNNING 0%**（与改动前逐位相同 → 不影响平衡）。
>
> 开工单：`docs/brief-m34-ai-guard-2026-11-26.md`（只给思路不给函数体）。
> 参考实现：`battle.gd` +33/−22，**只改一个文件**。

### 39.0 为什么现在做

`docs/implementation-tasks.md` §32 末尾登记着：M3.2 的 AI 选目标标准是
「**不是 guard**」而不是「**没被保护**」。真实卡池出现 guard 卡后 AI 会白扔一回合。
M3.4 正在往卡池里加真实 guard 卡，所以必须先清掉 —— 否则 M3.4 加完 guard 卡，
平衡模拟会跑出一堆「敌方整回合不动」的局，读数全是废的。

### 39.1 规则

| 编号 | 规则 |
|---|---|
| S1 | AI 的单位只要还有合法目标，就必须真的打出去，**不允许空过一整个回合** |
| S2 | 选目标优先级：**敌方 HQ（可达且没被保护）> 没被保护的非 Guard 单位 > Guard 本身** |
| S3 | 被 Guard 保护的友军**永远不该被 AI 选成目标**（打了必被拒 = 白扔） |
| S4 | Guard 本身**永远是合法目标**（§32 已定：Guard 之间互不保护） |
| S5 | `_is_guarded()` 对不在场上的单位返回 `false`，**不能崩** |
| S6 | 目标清单要扫**全部三条线**（`Board.LINES`），不能只扫 `front` |

S5 不是顺手加的：`_is_guarded()` 里 `board.position_of(target)` 对不在场上的单位返回 `[]`，
紧接着 `tmp[1]` 会抛 `SCRIPT ERROR: Invalid access of index '1' on a base object of type: 'Array'`。
`run_tests.bat` 把任何 `SCRIPT ERROR` 判红，所以 S5 必须先修。

S6 也不是凑数：现有 `_ai()` 能选的目标只有「对方 HQ」和「对方 `front` 线上的单位」两种，
对方**支援线上的普通单位**从来没进过候选（实测 `attack_unit` 打得着、但 `_ai()` 完全不碰它）。
扫三条线顺手把这块可见性补上，也是「以后加空军越线攻击不用再改 `_ai()`」的前提。

### 39.1b 目标清单的实现路线：三个桶，**不要堆**

学员问过「Godot 有没有类似 C++ `priority_queue` 的结构」。**没有**（实测 `ClassDB.class_exists()`
对 `PriorityQueue` / `Heap` / `BinaryHeap` 全为 false，`ClassDB` 里名字含 heap/priority/queue 的类 0 个）。
但更重要的是**规模根本不到**：

| 操作 | 实测单次耗时 |
|---|---|
| 扫三条线收集敌方单位 | 12.63 µs |
| 复制 + `sort_custom` 排 15 项 | 36.08 µs |
| 三桶 `append`（不排序） | 9.73 µs |

S2 的优先级只有 3 档 → 一次遍历按档位分进三个桶、最后按顺序 `append_array`，O(n) 且**天然稳定**。

**`sort_custom` 不稳定，且不是只在理论上**：实测全同优先级输入，n=14/15/16 保持原序、
**n=17 起开始乱序**。棋盘目标上限 14 个，理论上碰不到，但这是运气不是保证。
所以要么三桶，要么显式写 tie-break 让比较函数成为全序。

**这张清单不要缓存**：`_is_guarded()` 是每次现算的（Guard 死了邻居立刻失去保护），
缓存一回合或挂到 `Battle` 成员上都会读到过期状态。每个攻击手开打前重建一次即可。

### 39.2 病灶（`src/core/battle.gd` 的 `_ai(owner)` 攻击段，原 157–168 行）

| 分支条件 | 现在的做法 | 病灶 |
|---|---|---|
| `board.has_unit_of("front") == owner` | 循环前线单位，**一律** `attack_unit(u, _opposite_hq(owner))` | HQ 被 Guard 保护 → `attack_unit` 返回 false，**返回值没人接** → 这个单位白过，不换目标、不报错、连日志都没有 |
| `board.has_unit_of("front") == _opposite(owner)` | `find_first_attackable("front", owner)`，为 null 就 `break` | `find_first_attackable()` 筛的是「**不是 Guard**」；对方前线只有 Guard 时返回 null → 全队 `break` |

**`attack_unit` 拒绝被保护目标是正确行为**（`guard_test` 第 8 项已锁死），
错的只是 AI 侧的选目标策略。

### 39.3 要改哪里

| 文件 | 改什么 |
|---|---|
| `src/core/battle.gd` | ① `_is_guarded()` 开头补 `target == null` 守卫、`position_of` 之后补 `tmp.is_empty()` 守卫（取下标**之前**）；② `_ai()` 的攻击段换成「按优先级排队目标 + 依次试到 `attack_unit` 返回 true」；③ 建议新增两个私有辅助 `_ai_attack_targets(owner) -> Array[Unit]` 与 `_ai_attack(u, owner) -> bool`（签名可自定） |
| `src/core/board.gd` | **不动**。`find_first_attackable()` 保留原样（`guard_test` 没断言它，删了也没好处） |

**为什么用「排队 + 依次试」而不是「挑一个」**：`attack_unit` 会因为够不着 / 被保护 /
能量不够 / 同主等一堆原因返回 false。在 AI 侧复刻这套规则 = 迟早和生产逻辑走偏。
「试到成功」把判定权完全留在 `attack_unit`，以后加规则（M3.6 元素、M3.8a 指令卡 AI）这里不用改。

**排序实现**：S2 只有 3 档 → 三个桶（`Array[Unit]`）一次遍历分档、最后 `append_array` 拼接。
不要用堆（Godot 没有，且 n ≤ 14 没意义），也不要裸用 `sort_custom`（不稳定，实测 17 项起乱序）。

### 39.4 验收（`tests/pending/ai_guard_test.gd`，14 项）

| # | 断言 | 项数 |
|---|---|---|
| [1] | 玩家 HQ 被 Guard 保护 → AI 前线单位改打 **Guard 本身**（6 → 3），且 `has_attacked == true` | 4 |
| [2] | 玩家前线只有 Guard → 敌方支援线单位打这个 Guard（6 → 4），HQ 不掉血 | 3 |
| [3] | 被保护的 victim 一点血不掉，Guard 掉血（AI 没拿 victim 当目标） | 3 |
| [4] | 同线「Guard(slot1) + 普通单位(slot3)」→ 优先打普通单位（5 → 2），Guard 不挨打 | 3 |
| [5] | 不在场上的单位 `_is_guarded()` 返回 false，无 `SCRIPT ERROR` | 1 |

- 全绿：`ai_guard_test` **14/14 PASS**；主套 **19 文件 499/499**（485 + 14 启用后）
- `validate_data` PASS（0 错 0 警）
- `balance_sim --games 200 --seed 1` → **45.0% / 13.0 回合 / RUNNING 0%**（真实卡池无 guard 卡，此改动不该影响平衡）
- 启用：全绿后 `git mv tests/pending/ai_guard_test.gd tests/`，header 改「已启用」

### 39.5 六条坑

1. **`attack_unit` 的返回值必须接**。GDScript 不报「你没用返回值」，只有测试能抓 —— 整个缺陷的根。
2. **`board.has_unit_of(line)` 返回 owner 字符串**（空线 `"empty"`），不是 bool、不是数组。
3. **`position_of()` 对不在场上的单位返回 `[]`**，`tmp[1]` 直接抛错。`tmp.is_empty()` 必须在取下标之前；`_is_guarded(null)` 也要能活。
4. **候选目标要扫全部三条线**，不能只扫 frontline：空军能从支援线打支援线（`_line_span_to`）。
5. **别拿 `units_in()` 的遍历顺序当优先级**（它按格子下标升序）。优先级只能靠 S2 显式排。
6. **改完先 `--import` 再跑测试**，否则 `--script` 用旧缓存，症状是「改了没反应」。
7. **同名单位不会互相冒充**（实测 `Unit ==` 比的是引用，`position_of` / `remove` / `attack_unit` 各认各的），
   但 **`place()` 允许同一个对象占两个格**（`remove()` 只清第一个，留下查不到位置的残影）——
   测试辅助必须 `assert(place(...))`，生产代码每次 `Unit.from_dict()` 新建对象即可。
8. **双方牌库共享同一批 `Card` 对象**（`setup()` 里 `for i in p_deck` 双向 append），
   现在不炸是因为 `Card` 是只读模板 + `erase` 按引用删。**别在本块给 `Card` 加可变字段**，
   需要时单开一块做 `Card.from_dict()` 深拷贝。

### 39.6 红绿指纹（改错方向时一眼能认）

| 写错的样子 | 哪些项红 |
|---|---|
| 只接返回值、不换目标 | [1][2][3]（还是不打架，只是不崩了） |
| 换目标但 Guard 排最前 | [3][4]（打了 Guard，但被保护的 victim 优先被打） |
| 只在一条线上找目标 | [2] 或 [4] 单独红 |
| 忘了 `tmp.is_empty()` 守卫 | [5] 红 + 1 条 `SCRIPT ERROR` |
| 主套其他文件变红 | 你把 `attack_unit` 的规则也改了 —— 那不是这块的活 |

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

