# ADR-004（草案）：M3 关键词与兵科规则

> 状态：**提议中（2026-11-21 教练起草），待学员拍板**。
> 关联：`docs/m3-scope.md` §M3.1–§M3.3、`BACKLOG.md` E16/E17/F3。
> 拍板后把"待定"改成"决定"，并删除未选方案的细节；实现按本 ADR 走。

## 背景

M2 的固化规则（`§17` 攻击只能打相邻线、`§15` 召唤失调、前线独占）没有"阻挡/护卫/兵科差异"。
M3 要加关键词与兵科，**其中 Guard 和空军越线会动到 §17 这条固化规则**，所以先写 ADR 再实现。

## 决定 1：闪击 Blitz

| 选项 | 语义 | 影响 |
|---|---|---|
| **A（推荐）** | 部署当回合 `has_acted = false`（可移动**或**攻击一次，行动后照常标 true） | 只改 `_deploy_unit` |
| B | 只允许"部署当回合攻击"，不允许移动 | 需要额外状态位，复杂 |
| C | 部署当回合可行动，且免作战费 | 改 `_move/_attack` 费用逻辑，数值风险 |

**建议 A**。测试：`tests/pending/keywords_test.gd`（已写 9 项：解析 / 传递 / 不失调 / 可移动 / 可攻击 / 普通单位对照）。

## 决定 2：护卫 Guard（**待拍板**）

| 选项 | 语义 | 影响面 |
|---|---|---|
| **A（KARDS 风格，推荐）** | 相邻线有敌方 Guard 时，攻击**必须**打 Guard（打不到 HQ / 非 Guard 单位） | `attack_unit` 合法性 + `_ai` 选目标；改 §17 行为（但 §17 只写"相邻线"，Guard 是叠加限制，不算推翻） |
| B | Guard 只保护**同线**单位，HQ 仍可被打 | 实现简单，但"护卫"价值低 |
| C | 只影响 AI 目标优先级，不强制 | 玩家仍可绕，规则不对称 |

**若选 A**，需要补：
- `attack_unit` 开头：目标不是 Guard、且目标相邻线上有敌方 Guard → `return false`；
- `_ai` 攻击段：先找相邻线的 Guard，再按"够得着 HQ 先打 HQ"（HQ 被 Guard 挡住时改打 Guard）；
- 测试：玩家不能绕过 Guard、AI 自动打 Guard、Guard 阵亡后恢复原目标规则。

## 决定 3：兵科 range（**待拍板**）

| 选项 | 规则 | 影响 |
|---|---|---|
| **A（推荐）** | 只做数据标签（`unit_class`），无规则差异 | 数据 + 校验；零规则风险 |
| B | +炮兵：攻击时**不受反击伤害** | `attack_unit` 反击段 + 测试 |
| C | +空军：可越线攻击 | 改 §17 攻击范围 + AI 目标；**风险最高，建议 M4 或单独 ADR** |

**建议 M3 = A + B**。

## 决定 4：关键词数据与校验

- `Card.from_dict` 解析 `keywords: Array[String]`；
- `Unit` 加 `keywords: Array[String]`，`_deploy_unit` 从 Card 拷贝；
- 未知关键词：`push_error` 警告，不崩（数据先行，机制后补）；
- `tools/validate_data.gd`（M3 工具）校验关键词/兵科枚举。

## 后果

- 正面：卡池有策略深度；Guard 让"换线/抢前线"有意义；balance_sim 有调参空间。
- 负面：Guard 让 AI 目标选择变复杂，`_ai` 的攻击段要重写；空军越线会破坏"前线独占"的直觉，需谨慎。
- 测试：`keywords_test` 从 9 项扩到 ~17 项（Blitz + Guard）；`combat_test` 若加炮兵再 +4。

## 待办（拍板后）

1. 把"决定 2/3"改成最终选项，删掉未选方案。
2. 教练补 Guard 测试 + 数据（`cards.json` 加带关键词的卡）。
3. 学员实现 `Unit.keywords` / Blitz / Guard（按 `m3-scope.md` §M3.1–M3.2）。
4. 更新 `implementation-tasks.md`（新增 §27 关键词）与 `BACKLOG` 状态。
