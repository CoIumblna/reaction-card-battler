# 元素反应 · 设计规格（v2）

> 参照原神 3.0 之前的反应，按"简化但可扩展"实现。
> **本文件是规格**：`data/tables/reactions.json` 按它填，`tests/` 按它断言。

## 0. 三个已定原则

1. **倍率只有 1.5 / 2.0 两档**，计算结果**一律向下取整**（floor）。不做偶数基数约束。
2. **元素附着有量**（单位 U）：普通附着 1U、强附着 2U，上限 2U；**复合元素上限 1U**。
3. **反应 = 一串带类型的效果**（`effects` 数组），代码按效果类型分发，不按反应名写死 →
   以后加新反应，只改 JSON。

## 1. 元素（8 个 id）

| id | 名称 | 类型 |
|---|---|---|
| `fire` | 火 | 基础 |
| `water` | 水 | 基础 |
| `lightning` | 雷 | 基础 |
| `ice` | 冰 | 基础 |
| `wind` | 风 | 基础 |
| `geo` | 岩 | 基础 |
| `electro_charged` | 感电（复合） | **复合元素** |
| `frozen` | 冻结（复合） | **复合元素** |

**复合元素 = 共存状态的简化表示**：不引入"多附着槽"，而是触发共存反应时
**清空原有附着 → 附加一个复合元素（1U）**。这样任何时刻身上最多只有 1 个附着。

## 2. 附着规则（B8）

`Unit` 上三个字段：`aura_element` / `aura_amount` / `immunities`。

| 情况 | 行为 |
|---|---|
| 目标无附着 | 附着该元素，量 = 本次附着量 |
| 已有**相同**元素 | 量相加，**封顶 2U** |
| 已有**不同**元素 | 先结算反应 → 扣 `consume` → 剩余 > 0 则保留原元素、量变剩余；≤ 0 清空 |
| 反应产生复合元素 | 清空原附着 → 附加复合元素，量固定 1U（不受 2U 上限影响，也不叠加） |
| 无元素攻击 | 不改变附着 |

**附着量随时间衰减：M1 不做**，字段先留（`decay_rate`），M3 再接。

## 3. 免疫（补上，之前漏了）

`Unit.immunities`：元素 id 数组。规则：

- 攻击元素在免疫列表里 → **伤害 0、不触发反应、不消耗附着**，日志写「免疫」
- 与原神的对应关系：火史莱姆免疫火；深渊法师的"固定元素护盾"由两条组合实现：
  1. 护盾期间免疫该元素
  2. **每次被攻击后重新附着该元素**（用 `effects: [{kind:"aura", element:"fire", amount:1}]` 实现）

> 你说的"每回合自己给自己打一张火"就是这个思路：**天生元素 = 定时重新附着**，
> 不需要给单位加"天生附着"这种特殊逻辑。数据里用状态/词条配置即可。

## 4. 反应清单（14 条，3.0 前）

| 组合（排序键） | 名称 | 类型 | 倍率/效果 | 消耗 |
|---|---|---|---|---|
| `fire+water` | 蒸发 | 增幅 | 火打水 1.5 ／ 水打火 2.0 | 1U |
| `fire+ice` | 融化 | 增幅 | 火打冰 2.0 ／ 冰打火 1.5 | 1U |
| `fire+lightning` | 超载 | 剧变 | 额外伤害 2 | 1U |
| `lightning+water` | 感电 | 剧变 | 附着改 `electro_charged` 1U + 状态 `shock` 2 回合 | 1U |
| `ice+water` | 冻结 | 剧变 | 附着改 `frozen` 1U + 状态 `immobilized` 1 回合 | 1U |
| `ice+lightning` | 超导 | 剧变 | 状态 `defense_down` 2 回合 + 额外伤害 1 | 1U |
| `wind+fire/water/lightning/ice` | 扩散 | 剧变 | 额外伤害 1（**只有风攻击时触发**） | 1U |
| `geo+fire/water/lightning/ice` | 结晶 | 结晶 | 获得护盾 2（**只有岩攻击时触发**） | 1U |

**"只有某元素攻击时触发"** 用 `trigger_attacker` 字段表达（风/岩当被攻击方时不触发）。

## 5. 反应数据结构

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
  "trigger_attacker": "",
  "consume": 1.0,
  "effects": [
    { "kind": "status", "id": "shock", "duration": 2 },
    { "kind": "aura", "element": "electro_charged", "amount": 1.0, "clear_first": true }
  ]
}
```

**效果类型（初始 5 种，可扩展）**

| kind | 字段 | 含义 |
|---|---|---|
| `damage` | `value` | 额外固定伤害 |
| `status` | `id`、`duration` | 施加状态（见 `statuses.json`） |
| `aura` | `element`、`amount`、`clear_first` | 改变附着（含复合元素） |
| `shield` | `value` | 获得护盾 |
| `heal` | `value` | 回复生命 |

**类型（type）只是为了分类和文档**：代码按 `effects` 分发，未知 type 退化为"无效果"，不会崩。
以后加"草系反应"或新类型，只要效果能拆进上表，就只改数据。

## 6. 状态（statuses.json，C8）

| id | 名称 | 效果 | 时机 |
|---|---|---|---|
| `burn` | 燃烧 | 每回合开始掉 1 血 | `turn_start` |
| `shock` | 感电 | 每回合开始掉 1 血 | `turn_start` |
| `immobilized` | 冻结 | 本回合无法行动 | `action` |
| `defense_down` | 减防 | 防御 -1 | `passive` |

M1 只实现 `turn_start`（dot）和 `action`（无法行动）两种时机；`passive` 到 M2（棋盘上才有防御）。

## 7. 待确认 / 后续

- [ ] 复合元素在 M3 是否需要"再反应"（比如火打感电复合 → 蒸发）？现在**没有**反应条目，等价于"复合附着不参与反应"，等 M3 再定。
- [ ] 附着量衰减（`decay_rate`）M3 做。
- [ ] 免疫与"元素护盾"的完整实现放 M2（需要单位/棋盘）。
