# ADR-005（已确认）：元素附着 v3 —— 多槽位 + 持续时间

> 状态：**核心已确认（2026-11-22 学员拍板）**：多槽位、持续时间、删除复合元素、dot 不反应。
> 具体数值/反应算法在 M3.6 实现前细化，并同步重写 `docs/element-reactions.md`（v3）。
> 关联：`docs/m3-scope.md` §M3.6、`tests/pending/aura_v3_test.gd`（待写）。

## 背景

- 原神的"复合元素"（冻结/感电）**不是新元素，是共存状态**，而且**会继续反应**：
  冻结可被火融化、被岩/大剑碎冰；感电是水雷共存时的持续反应。
- 当前 v2 规格用"单附着槽 + 复合元素 id（electro_charged/frozen）"是简化：
  一旦加入草（燃烧/绽放）等共存组合，单槽 + 复合 id 会爆炸式补丁。
- 学员确认：**dot 只造成元素伤害，不挂元素、不触发反应**；附着**不做量衰减**，改成**每元素有持续时间**，到时间移除。

## 决定

### 1. 数据结构

```gdscript
Unit.auras: Array   # 每项 { "element": String, "amount": float, "duration": int }
const MAX_AURAS := 3   # 常量，配置化；加新元素后若出现 3 元素共存，再评估改 4
```

- 每槽：元素 id、附着量（U，封顶 2U）、剩余回合数；
- **槽上限 3**：槽满时新元素无法入槽 → **替换最旧的槽**（先删最旧，再按规则入槽）；
- 删除 `Unit.aura_element` / `aura_amount` 两个单值字段（改由 `auras` 派生；旧代码兼容期可用辅助函数）。

### 2. 附着与叠加（新元素进入时）

| 情况 | 行为 |
|---|---|
| 已有**相同**元素槽 | 量相加（封顶 2U），`duration` 刷新为 `max(旧, 新)` |
| 已有**不同**元素槽 | 按槽创建顺序，找**第一个**能与新元素反应的槽（`reactions.json` 双向匹配）→ 按下表结算 |
| 无反应 | 作为新槽加入；槽满则替换最旧槽 |
| 反应后 | 旧槽扣 `consume`：扣到 ≤0 移除；新元素残留 = `本次附着量 − consume`，>0 才作为新槽加入 |
| wind / geo | 不产生附着（与 v2 相同），但反应照常结算 consume |

### 3. 复合元素处理（删除复合 id）

从 `elements.json` 删除 `electro_charged` / `frozen`；`reactions.json` 的对应条目改为**状态/共存**表达：

| 反应 | v3 表达 |
|---|---|
| `lightning+water` 感电 | 两槽保留（consume 0）+ 状态 `shock` 2 回合；dot 每回合掉血（C8 已有） |
| `ice+water` 冻结 | 两槽保留（consume 0）+ 状态 `immobilized` 1 回合 |
| `ice+lightning` 超导 | 照旧：状态 `defense_down` + 额外伤害 |

> 具体 consume/倍率在 M3.6 用 `reactions.json` v3 定，原则：**共存型反应默认不消耗元素**（只挂状态），蒸发/融化/超载等仍按原规则消耗。

### 4. 持续时间

- `elements.json` 每个元素加 `duration`（回合数）：普通附着 **2**、强附着 **3**（先统一这样，数值可调）；
- 回合开始结算时：`duration -= 1`，到 0 移除该槽；
- **顺序**：与状态结算同一阶段——dot 掉血 → 死亡移除 → disable 标记 → `tick_buffs()` + **aura duration tick**（都放最后）；
- 附着不再有"量衰减"（原 `decay_rate` 概念废弃）。

### 5. dot

保持 C8 行为：dot 只 `take_damage`，**不挂元素、不触发反应**。

### 6. 免疫

攻击元素在目标免疫列表 → 伤害 0、不触发反应、**不附着**（v2 规则不变）。

## 影响面

| 文件 | 改动 |
|---|---|
| `src/core/element.gd` | 删复合元素常量（或标记 deprecated） |
| `src/core/unit.gd` | `auras` 字段 + 辅助方法（add_aura/consume/get_aura/describe） |
| `src/core/damage.gd` | 反应判定改为"多槽匹配"，返回 effects/consume |
| `src/core/battle.gd` `_apply_aura` | 按 §2 规则重写 |
| `data/tables/elements.json` | 删复合 id + 每元素加 duration |
| `data/tables/reactions.json` | schema v3（感电/冻结改为 status-only） |
| 测试 | `data_test` / `damage_test` / `combat_test` / `battle_m1_smoke_test` 里所有 `aura_element/aura_amount` 断言要改；新增 `aura_v3_test` |

**估时**：学员实现 **12–16h**；教练规格+数据+测试 **6–8h**。放 M3.6。

## 实现前还需细化的点（M3.6 开始时定，先给建议）

1. **反应优先级**：多槽同时可反应时 → 建议"槽创建顺序最早优先"；
2. **槽满替换**：建议替换**最旧**槽（并写日志）；
3. **duration 数值表**：普通/强附着先 2/3 回合，按元素可调；
4. **感电/冻结 consume**：建议 0（共存），冻结算"状态"不消耗元素；
5. **UI**（M4）：需要显示多槽图标 + 剩余回合数，数据结构要留好。

## 测试计划（M3.6，教练写 `tests/pending/aura_v3_test.gd`，预计 20–26 项）

- 同元素叠加（封顶 2U、duration 刷新）
- 不同元素共存（2 槽 / 3 槽）
- 反应消耗（旧槽扣 consume、新元素残留入槽）
- 槽满替换最旧
- 持续时间到点移除 / 刷新
- 感电/冻结：共存 + 状态（不再有复合元素 id）
- dot 不挂元素、不触发反应
- 免疫不附着
- 战斗/M1 回归（旧断言改完）
