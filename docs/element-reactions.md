# 元素反应 · 设计规格（v3）

> **v3 = 多槽附着 + 持续时间**（2026-11-27，M3.6 落地）。决策依据：`docs/adr/005-element-auras-v3.md`；
> 施工清单：`docs/element-reactions-v3.md`；落地记录：`docs/implementation-tasks.md` §41。
>
> **本文件是规格**：`data/tables/elements.json`、`data/tables/reactions.json` 按它填，`tests/` 按它断言。
>
> v2 → v3 变了什么（一句话）：**不再有"复合元素 id"**。感电、冻结改成"两个附着槽共存 + 挂一个状态"，
> 于是 `Unit` 上从"一个元素 + 一个量"变成"最多 3 个槽，每槽记 element / amount / duration"。

## 0. 四条已定原则

1. **倍率只有 1.5 / 2.0 两档**，计算结果**一律向下取整**（floor）。不做偶数基数约束。
2. **附着有量（U）也有时间（回合）**：普通附着 1U / 2 回合，强附着 2U / 3 回合，单槽上限 2U，最多 3 槽。
3. **反应 = 一串带类型的效果**（`effects` 数组），代码按效果类型分发，不按反应名写死 → 以后加新反应只改 JSON。
4. **共存型反应默认不消耗元素**（`consume = 0`）。感电/冻结是这套设计的第一个用例：雷打水、冰打水之后，
   水和雷/冰**都还在身上**，额外挂一个状态。

## 1. 元素（只有 6 个基础元素）

| id | 名称 | `kind` | `duration`（默认附着回合数） |
|---|---|---|---|
| `fire` | 火 | base | 2 |
| `water` | 水 | base | 2 |
| `lightning` | 雷 | base | 2 |
| `ice` | 冰 | base | 2 |
| `wind` | 风 | base | 2 |
| `geo` | 岩 | base | 2 |

**v3 删掉了 `electro_charged`（感电）和 `frozen`（冻结）这两个复合元素 id。**
它们在 v2 里是用来"简化多槽"的假元素：触发共存反应时清空原附着、换成这个复合 id。
代价是「身上到底挂着什么元素」被一个伪造的 id 骗过去了 —— 既不能再反应，也没法显示真实成分。
v3 直接用两个真槽表示共存，`Element.ELECTRO_CHARGED` / `Element.FROZEN` 常量一并删除。

`elements.json` 的每个元素都必须写 `duration` 且 > 0，`validate_data` 会强制检查（漏写直接报错，不是 warning）。

## 2. 附着规则（多槽）

`Unit` 上的数据结构：

```gdscript
var auras: Array = []      # 每项 { "element": String, "amount": float, "duration": int }，按创建顺序
const MAX_AURAS := 3       # 最多 3 个槽
const MAX_AMOUNT := 2.0    # 单槽元素量上限
```

| 情况 | 行为 |
|---|---|
| 目标无附着 | 建一个新槽，量 = 本次附着量（封顶 2U），duration = `Element.aura_duration(元素, 量)` |
| 已有**相同**元素 | 量相加（封顶 2U）；`duration` 取新旧**较大值**（刷新，不缩短） |
| 已有**不同**元素，且能反应 | 见下节"反应结算" |
| 已有**不同**元素，不能反应 | 建新槽；**槽已满 3 个时先挤掉最旧的那个**（`auras.pop_front()`），再入新槽 |
| 无元素攻击（`none`） | 不改变附着 |
| **wind / geo 作为攻击元素** | **不产生附着**；但反应照常结算 `consume` |
| 目标免疫该元素 | 伤害 0、不反应、**不附着**、不消耗已有附着 |

**为什么"槽满替换最旧"而不是"拒绝新元素"**：拒绝会让后期战斗变成"谁先上元素谁锁死"，
而替换最旧能保证"每次攻击都留下痕迹"，且与"附着会自己过期"配合后不会积压。

## 3. 反应结算（按槽创建顺序找第一个可反应的槽）

1. 遍历目标 `auras`，**按创建顺序**（数组下标从小到大）；
2. 跳过 `none` 和**与攻击元素相同**的槽；
3. 第一个 `reaction_table.has_reaction(攻击元素, 槽元素)` 为真的槽就是命中的槽（`Damage.find_reaction_slot()` 返回它的下标，没有则 `-1`）；
4. 用该槽元素与攻击元素查表，拿倍率 / `consume` / `effects`；
5. **旧槽扣 `consume`**：`剩余 = 槽量 − consume`，`<= 0` 就把这个槽整个移除，否则写回剩余量；
6. **攻击方残留** `= 本次附着量 − consume`：`> 0` 且攻击元素不是 wind/geo → 入槽（走 §2 的新槽/叠加规则）；`<= 0` → 不附着。

> 优先级为什么是"最早创建的槽"：它是最稳定的确定性规则 —— 同一次攻击不会因为槽的遍历顺序抖动而
> 在不同帧里打出不同反应。`tests/aura_v3_test.gd` 的 `[7]` 用"身上先火后水、雷打过来"钉死这一条
> （必须命中火槽打出超载，而不是水槽打出感电）。

**回合开始时的 duration 结算**：`_settle_status()` 末尾 `tick_auras()`，每槽 `duration -= 1`，
减到 0 就移除（并写一条「X 的 Y 附着结束」日志）。普通附着 2 回合、强附着 3 回合。
**不在回合结束时衰减**：跟 dot 同阶段、都在回合开始，避免"上一个回合刚挂上、下一个阶段就掉一层"。

## 4. 免疫

`Unit.immunities`：元素 id 数组。攻击元素在免疫列表里 → **伤害 0、不触发反应、不消耗附着、不附着新元素**，
日志写「免疫」。`Damage.compute()` 在这种情况下 `immune = true`、`reaction_slot = -1`。

## 5. 反应清单（14 条，v3）

| 组合（排序键） | 名称 | 类型 | 倍率/效果 | 消耗 |
|---|---|---|---|---|
| `fire+water` | 蒸发 | 增幅 | 火打水 1.5 ／ 水打火 2.0 | 1U |
| `fire+ice` | 融化 | 增幅 | 火打冰 2.0 ／ 冰打火 1.5 | 1U |
| `fire+lightning` | 超载 | 剧变 | 额外伤害 2 | 1U |
| `lightning+water` | 感电 | 共存型 | 状态 `shock` 2 回合（**两槽都保留**） | **0** |
| `ice+water` | 冻结 | 共存型 | 状态 `immobilized` 1 回合（**两槽都保留**） | **0** |
| `ice+lightning` | 超导 | 剧变 | 状态 `defense_down` 2 回合 + 额外伤害 1 | 1U |
| `wind+fire/water/lightning/ice` | 扩散 | 剧变 | 额外伤害 1（风不附着） | 1U |
| `geo+fire/water/lightning/ice` | 结晶 | 结晶 | 获得护盾 2（岩不附着） | 1U |

**风/岩不主动附着**，所以「谁打谁」不影响反应是否触发，不需要方向性字段。

## 6. 反应数据结构

```json
{
  "name": "蒸发",
  "type": "amplify",
  "multiplier_by_attacker": { "fire": 1.5, "water": 2.0 },
  "consume": 1.0,
  "effects": []
}
```

```json
{
  "name": "感电",
  "type": "transformative",
  "consume": 0.0,
  "effects": [
    { "kind": "status", "id": "shock", "duration": 2 }
  ]
}
```

**效果类型**

| kind | 字段 | 含义 | 当前是否实现 |
|---|---|---|---|
| `status` | `id`、`duration` | 施加状态（见 `statuses.json`） | ✅ `_apply_aura()` 里结算 |
| `damage` | `value` | 额外固定伤害 | ⚠️ **数据里有、代码未接**（见 §8） |
| `shield` | `value` | 获得护盾 | ⚠️ **数据里有、代码未接**（见 §8） |
| `heal` | `value` | 回复生命 | ⚠️ **数据里有、代码未接**（见 §8） |
| `aura` | `element`、`amount` | 改变附着 | ❌ v3 起**不再使用**（复合元素删了）；`validate_data` 仍认这个 kind，但元素必须在 `elements.json` 里 |

**类型（type）只是为了分类和文档**：代码按 `effects` 分发，未知 type 退化为"无效果"，不会崩。

## 7. 状态（statuses.json）

| id | 名称 | 效果 | 时机 |
|---|---|---|---|
| `burn` | 燃烧 | 每回合开始掉 1 血 | `turn_start` |
| `shock` | 感电 | 每回合开始掉 1 血 | `turn_start` |
| `immobilized` | 冻结 | 本回合无法行动 | `action` |
| `defense_down` | 减防 | 防御 -1 | `passive` |

dot（`turn_start` 的 `damage` 类效果）**只掉血，不挂元素、不触发反应**。这是刻意的：
dot 每回合都可能跳，让它触发反应会引入"链式反应"和大量难以调试的时序问题。

## 8. 已知缺口（诚实记录，别当成已实现）

1. **`damage` / `shield` / `heal` 三种反应效果没有代码在结算**。`Damage.compute()` 会把它们拷进返回值的
   `effects` 里，但 `Battle._apply_aura()` 只处理 `status`。也就是说超载的"额外伤害 2"、结晶的"护盾 2"
   目前是**死数据**。补上会改变 `balance_sim` 的基线，所以单独排期（M3.8 平衡调参时一起做，
   见 `docs/implementation-tasks.md` §40.4：当前 balance 的胜负 100% 由先手决定，卡池和效果都不影响结果）。
2. **`decay_rate`（附着量随时间衰减）没做**，只有 duration（回合数）会减少。
3. **附着量不随 duration 减少而减少** —— 只要没到期，1U 还是 1U。
4. **没有草系（`dendro`）**：`docs/element-reactions-v3.md` §1.1 的示例里写过它，但当前数据与代码都没有，
   也没有草系反应条目。要加就是"加元素 + 加元素对 + 加卡"，属于内容设计（M3.4 之后）。

## 9. 待确认 / 后续

- [ ] 复合元素"再反应"的需求消失了（v3 没有复合 id），但**多槽同时可反应时的优先级**值得再观察：
  现在是"最早槽优先"，如果实战里感觉手感僵，可以改成"消耗量最大的先命中"。
- [ ] 感受一下 3 槽够不够。若卡池里元素种类变多，"第 4 个元素挤掉最旧"会让玩家的布局变得难以预期，
  可能要提到 4 槽或加"由玩家选择替换哪个"。
- [ ] 感电/冻结 `consume = 0` 是否过强：两槽共存意味着后续再打一次雷能继续叠 shock。
  数值上要看 M3.8 的实测。
- [x] **dot 的叠加语义**（2026-11-21 定）：伤害值是状态定义的一部分（`statuses.json` 的 `value`），
  挂状态只决定 kind/duration/stacks。**同 kind** → 合并成一个 Buff：`stacks + 1`、`duration` 取大，
  每跳伤害 = `value × stacks`；**不同 kind** → 两个独立 Buff 各自结算（同回合伤害相加，这是预期，不是 bug）。
- [x] wind / geo 不主动附着：`Battle._apply_aura()` 里实现（wind/geo 不产生附着，但反应照常结算 `consume`）。
