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
| `cost` | int | | 1 | 能量消耗，≥ 0 |
| `element` | string | | `"none"` | `fire` / `water` / `lightning` / `none` |
| `kind` | string | | `"damage"` | `damage` / `shield` / `heal` / `buff` |
| `power` | int | | 0 | 伤害/护盾/治疗数值 |
| `target` | string | | `"enemy"` | `enemy` / `self` |

## 2. enemies.json

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `id` | string | ✅ | 唯一标识 |
| `name` | string | ✅ | 显示名 |
| `hp` | int | ✅ | 最大生命，加载时当前 HP = 最大 HP |
| `attack` | int | | 每回合攻击力（M2 用，现在代码里写死 4） |

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

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | string | 与 `element.gd` 里的常量一致 |
| `name` | string | 显示名 |

---

## 校验清单（M2 要写成 tools/validate_data.gd）

- [ ] 每个 `id` 唯一
- [ ] `kind` 只能是四个枚举值之一
- [ ] `element` 必须是已定义元素
- [ ] `reactions.json` 的键必须能在元素列表里找到
- [ ] `multiplier` 在合理区间（1.0–2.0）
- [ ] 缺字段时，报错要能指出「哪个文件、第几条、缺哪个字段」
