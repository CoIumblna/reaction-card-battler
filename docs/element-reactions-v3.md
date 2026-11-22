# 元素反应 v3 · 规格（多槽附着 + 持续时间）

> 状态：**待实施（M3.6）**。本文是 v3 的实现规格；`docs/element-reactions.md`（v2，单槽）在迁移完成前仍是运行依据。
> 决策见 `docs/adr/005-element-auras-v3.md`；实施时按本文 + ADR 一起改数据与测试。

## 0. 与 v2 的差异总览

| 项 | v2（现状） | v3（目标） |
|---|---|---|
| 附着存储 | `aura_element` + `aura_amount`（单槽） | `Unit.auras: Array`（**最多 3 槽**，每槽 element/amount/duration） |
| 复合元素 | `electro_charged` / `frozen` 作为元素 id | **删除复合 id**；共存 + 状态表达（感电=`shock`，冻结=`immobilized`） |
| 附着衰减 | 预留 `decay_rate`，未实现 | 不做量衰减；**每槽 duration（回合数）** 到点移除 |
| 反应判定 | 单槽 vs 新元素 | 新元素 vs 按创建顺序的第一个可反应槽 |
| dot | 纯掉血（C8） | 不变：不挂元素、不触发反应 |
| 免疫 | 按元素 id | 不变 |

## 1. 数据 schema

### 1.1 `data/tables/elements.json` v3

```json
{
  "schema_version": 3,
  "elements": [
    { "id": "fire", "name": "火", "kind": "base", "duration": 2 },
    { "id": "water", "name": "水", "kind": "base", "duration": 2 },
    { "id": "lightning", "name": "雷", "kind": "base", "duration": 2 },
    { "id": "ice", "name": "冰", "kind": "base", "duration": 2 },
    { "id": "wind", "name": "风", "kind": "base", "duration": 2 },
    { "id": "geo", "name": "岩", "kind": "base", "duration": 2 },
    { "id": "dendro", "name": "草", "kind": "base", "duration": 2 }
  ]
}
```

- 删除 `electro_charged` / `frozen`；
- 每元素 `duration`（回合数）：普通附着 2；强附着（卡牌 `aura_amount=2`）用 **3**（实现时：`duration = 2 if amount <= 1 else 3`，或数据里加 `duration_strong`）；
- `none` 仍是内置占位，不进表。

### 1.2 `data/tables/reactions.json` v3

- 键仍是 `"a+b"`（排序拼接），不变；
- **感电/冻结改为共存型反应**（不改变元素，只挂状态）：

```json
"lightning+water": { "name": "感电", "type": "transformative", "consume": 0.0,
  "effects": [ { "kind": "status", "id": "shock", "duration": 2 } ] },
"ice+water": { "name": "冻结", "type": "transformative", "consume": 0.0,
  "effects": [ { "kind": "status", "id": "immobilized", "duration": 1 } ] }
```

- 蒸发/融化/超载/超导/扩散/结晶：规则不变（`consume` 照旧；`aura` 效果里不再出现复合元素 id）；
- 新增草系反应（燃烧/绽放等）在 M3.4 内容设计时扩充，格式同上。

## 2. `Unit.auras` 数据结构

```gdscript
var auras: Array = []   # [{ "element": String, "amount": float, "duration": int }]
const MAX_AURAS := 3    # 常量（放 Unit 或 Battle 均可）；加新元素后再评估
```

辅助方法（建议放 `Unit`）：
- `get_aura(element) -> Dictionary`（没有返回 `{}`）
- `add_or_refresh_aura(element, amount, duration)`：同元素叠加/封顶 2U、duration 取 max；否则新槽（槽满替换最旧 + 日志）
- `remove_aura(element)`
- `describe_auras() -> String`（日志/测试用，如 `火1U(2) 水2U(1)`）
- v2 兼容：`aura_element` / `aura_amount` 可保留为只读派生属性一段时间（`auras` 第一个槽），迁移完成后删除。

## 3. 上元素 / 反应的算法（`_apply_aura` 重写）

```text
apply_aura(target, incoming_element, incoming_amount):
  1. incoming_element == NONE → 不处理
  2. 免疫 incoming_element → 不处理（伤害已在 Damage.compute 置 0）
  3. 按 auras 创建顺序找第一个"能反应"的槽（ReactionTable.has_reaction(incoming, slot.element)）
  4. 有反应：
       act = get_reaction(incoming, slot.element)
       伤害倍率/额外效果按 act（effects 分发：damage/status/shield/heal/aura）
       旧槽 amount -= act.consume；<=0 移除
       新元素残留 = incoming_amount - act.consume
       残留 > 0 → add_or_refresh_aura(incoming, 残留, duration)
  5. 无反应：
       同元素槽 → 叠加（封顶 2U）+ duration 刷新
       否则 add_or_refresh_aura(incoming, incoming_amount, duration)
  6. wind / geo 作为 incoming → 照常反应、但不产生附着（残留丢弃）
```

**反应优先级**：槽创建顺序最早优先（后续可加"反应表优先级"字段）。

## 4. 持续时间结算

- 与 C8 的回合开始四步同一阶段：dot → 死亡移除 → disable → **`tick_buffs()` + tick auras**；
- 每个槽 `duration -= 1`，到 0 移除（日志）；
- 刷新：同元素再次附着时 `duration = max(旧, 新)`。

## 5. dot / 免疫（不变）

- dot 只 `take_damage`，不挂元素、不触发反应；
- 免疫元素：伤害 0、不触发反应、**不附着**（v3 下即不进槽）。

## 6. 迁移清单（实现时一次提交）

1. `element.gd`：删复合常量（或标 deprecated 并保留字符串常量避免旧数据崩）；
2. `unit.gd`：`auras` + 辅助方法 + `describe` 更新；
3. `damage.gd`：反应判定改为"多槽匹配"，返回 `reaction/consume/effects`（额外处理：第 2 个可反应槽？先只反应一个，M3 后再说）；
4. `battle.gd`：`_apply_aura` 按 §3 重写；`_settle_status` 加入 aura tick；
5. 数据：`elements.json` v3、`reactions.json` v3；
6. 旧测试迁移（所有 `aura_element/aura_amount` 断言）：
   - `data_test`（元素数量 8 → 7、反应条目字段）
   - `damage_test` / `combat_test` / `battle_m1_smoke_test`（附着/反应断言）
   - `status_test`（感电/冻结挂状态路径）
7. 新增 `tests/pending/aura_v3_test.gd`（见 §7）；
8. `docs/element-reactions.md` 重写为 v3（本文件内容并入）。

## 7. `aura_v3_test` 用例清单（预计 24 项）

1. 初始无槽；上 1U 火 → 1 槽
2. 同元素叠加 → 2U 封顶
3. 上水 → 2 槽共存
4. 火打水 → 蒸发 1.5 / 水打火 2.0 + consume
5. consume 后旧槽剩余 >0 保留；≤0 移除
6. 新元素残留 = amount - consume 入槽
7. 槽上限 3：第 4 个元素替换最旧槽
8. duration 刷新（同元素再上）
9. duration 到 0 移除
10. 强附着（2U）duration 3
11. 感电：水雷共存 + shock 状态（无 `electro_charged`）
12. 冻结：冰水共存 + immobilized 状态（无 `frozen`）
13. 超导：状态 + 额外伤害
14. 扩散/结晶：风岩不附着但结算 consume
15. 免疫元素：不附着、不反应、伤害 0
16. dot 不挂元素、不触发反应（跳伤后目标 auras 不变）
17. 槽满 + 反应后残留入槽的边界
18. 反应优先级：最早槽优先（构造两槽都可反应的场景）
19. 死亡单位不结算 aura tick
20. 日志/describe 能看出多槽（可读性）
21–24. 旧 M1/M2 回归（迁移后的等价断言）

## 8. 数值待定（M3.6 开始前确认）

- 感电/冻结 consume = 0（共存）是否合适；
- 各元素 duration：2（普通）/3（强附着）起步；
- 多槽同时可反应时的优先级；
- 草系反应数据（M3.4 内容设计时补）。
