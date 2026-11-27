# 数据格式规范（data/schema）

> 规则：**改字段之前，先改这个文件。**
> 这个文件是"数据契约"——写表的人（你）和读表的代码（`DataLoader`）都按它来。

## 目录约定

- `data/tables/` —— 实际的数据（游戏运行时会读）
- `data/schema/` —— 字段定义（只是文档，不参与运行）

## 1. cards.json

```json
{ "cards": [ { "id": "...", ... } ] }
```

| 字段 | 类型 | 必填 | 默认 | 说明 |
|---|---|---|---|---|
| `id` | string | ✅ | — | 唯一标识，蛇形命名，如 `fire_bolt` |
| `name` | string | ✅ | id | 显示名 |
| `type` | string | | `"order"` | `unit`（单位卡）/ `order`（指令卡） |
| `cost` | int | | 1 | 能量消耗，≥ 0 |
| `element` | string | | `"none"` | `none` / `fire` / `water` / `lightning` / `ice` / `wind` / `geo`。**v3 起复合元素 id 已删除，填了会报错** |
| `kind` | string | | `"damage"` | 指令卡用：`damage` / `shield` / `heal` |
| `power` | int | | 0 | 伤害/护盾/治疗数值 |
| `aura_amount` | float | | 1.0 | 这张卡打出去时挂多少元素量：1.0 普通（持续 2 回合）/ 2.0 强附着（3 回合） |
| `target` | string | | `"enemy"` | `enemy` / `self` |
| `count` | int | ✅ | — | **这张卡在牌库里一共几张**（必须 > 0 且 ≤ 自己的 `limit`） |
| `limit` | int | | 4 | **这张卡自己的上限**（per-card limit，2026-11-27 起）。写 `1` 就是"全局唯一一张"，不写吃默认 4；`< 1` 报错 |

> 单位卡额外字段：`attack` / `defense`（必填，≥ 0）/ `operation_cost`（默认 1）/
> `unit_class`（`infantry` `tank` `artillery` `fighter` `bomber`）/ `keywords`（`blitz` `guard`）。

> **per-card limit 是硬规则**：`data_loader.load_deck()` 与 `validate_data` 都按每张卡自己的
> `limit` 校验，不再有"所有卡统一 4 张"这种全局上限。改上限就改那张卡的 `limit` 字段。

## 2. enemies.json

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `id` | string | ✅ | 唯一标识 |
| `name` | string | ✅ | 显示名 |
| `hp` | int | ✅ | 最大生命，加载时当前 HP = 最大 HP |
| `attack` | int | | 每回合攻击力（M2 用，现在代码里写死 4） |
| `immunities` | string[] | | **静态免疫**的元素 id 列表：该元素伤害 0、**不触发反应**、不挂附着。岩傀儡 `golem` 免疫 `geo` 就是这种 |
| `auras` | object[] | | 初始元素附着槽（结构同「单位多槽附着」） |

### 2.1 `auras` 里的元素盾（`innate: true`）

> **元素的盾不是免疫。** 盾是一层独立的**吸收层**：有它的时候吸收全部伤害（不分元素），
> 破盾量 = 被吸收量 ÷ `SHIELD_HP_PER_U`(2.0) × **反应类型系数**，同属性/无反应元素的系数是 **0**，
> 所以「同属性打不破」；破盾后 3 回合重生。完整系数表见 `docs/implementation-tasks.md` §42.3。

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `element` | string | ✅ | 盾的元素，必须在 `elements.json` 里 |
| `amount` | float | ✅ | 盾量（U），必须 `> 0` 且 `<= 20`（`Unit.MAX_INNATE_AMOUNT`）。**盾量 × 2.0 = 能吸收的总伤害** |
| `duration` | int | ✅ | 护盾槽必须写 **`0`**（盾不随时间衰减，只被反应吃掉）。写别的会 warning |
| `innate` | bool | ✅ | 必须显式 `true`，否则会被当成普通附着、每回合掉 duration |

样本：水法师 `hydro_mage`（30 HP / 5 攻击 / `{"element":"water","amount":12.0,"duration":0,"innate":true}`）。
同一元素既写进 `immunities` 又挂护盾会 warning（语义冲突，静态免疫已经全挡了，盾是多余的）。

## 3. reactions.json

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| （键） | string | ✅ | `元素A+元素B`，**小写、按字母序**，如 `fire+water` |
| `name` | string | ✅ | 反应名，如 `蒸发` |
| `multiplier` | float | ✅ | 伤害倍率，1.0–2.0 |
| `status` | string | | 反应附加的状态（M2 接进 Buff，现在只存不用） |

> ⚠️ 键的顺序很关键：`pair_key()` 会先排序再拼，所以 `water+fire` 和 `fire+water` 都会查到 `fire+water`。
> 如果你改成"区分攻守方向"，这里的键要改成有序的，两处必须一起改。

## 4. elements.json

v3（2026-11-27）起 `schema_version = 3`：**只有 6 个基础元素**，原来那两个复合元素
（`electro_charged` 感电 / `frozen` 冻结）已删除 —— 感电、冻结改成「两个附着槽共存 +
挂状态」来表达，不再伪造一个元素 id。

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | string | 与 `element.gd` 里的常量一致（且必须能在 `Element.BASE_DURATION` 里查到） |
| `name` | string | 显示名 |
| `kind` | string | 基础元素固定写 `"base"` |
| `duration` | int | **v3 新增**：该元素附着后默认持续几回合（当前全为 2；1U 普通附着用它，2U 强附着固定 3 回合） |

`phase` / `components` 之类的字段 v3 起不再使用；`validate_data` 会强制要求每个元素都写
`duration` 且 > 0，漏写就报错（不是 warning）。

---

## 校验清单（M2 要写成 tools/validate_data.gd）

- [ ] 每个 `id` 唯一
- [ ] `kind` 只能是四个枚举值之一
- [ ] `element` 必须是已定义元素
- [ ] `reactions.json` 的键必须能在元素列表里找到
- [ ] `multiplier` 在合理区间（1.0–2.0）
- [ ] 缺字段时，报错要能指出「哪个文件、第几条、缺哪个字段」
