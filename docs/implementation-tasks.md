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
| 8 | `battle.gd` | 13 | ★★★ | 150 | battle_test[1–7] | [ ] |`n| 9 | `status_table.gd` | 4 | ★★ | 25 | data_test[5] | [ ] |

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
| `start_battle()` | 无 | 打日志 → 抽满手牌 → 进第 1 回合 | 战斗开始 | battle_test[2] |
| `_begin_turn()` | 无 | `turn += 1`；能量回满；补抽到 5 张；打日志 | 每回合资源重置 | battle_test[2] |
| `_draw(n)` | 张数 | 从 `deck` 头部 `pop_front()`，牌库空就停 | 发牌 | battle_test[2] |
| `end_turn()` | 无 | buff 结算 → 敌人攻击（先写死 4 点）→ 玩家死则结束 → 否则 `_begin_turn()` | 敌方回合 | battle_test[2] |

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
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/battle_smoke_test.gd

# 想手动看一局（battle.gd 写完后才用得上）
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/run_battle.gd
```

**失败数从 19 减到多少，就是你的进度条。**

---

