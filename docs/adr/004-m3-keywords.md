# ADR-004（已确认）：M3 行动经济 / 关键词 / 兵科

> 状态：**已确认（2026-11-22 学员拍板）**，实现按本 ADR。
> 关联：`docs/m3-scope.md` §M3.1–§M3.3、`tests/pending/keywords_test.gd`、`tests/pending/guard_test.gd`。

## 决定 1：行动经济（拆 `has_acted`）

**为什么**：单一 `has_acted` 表达不了"坦克移动+攻击"和"闪击+坦克叠加"。

| 项 | 规则 |
|---|---|
| 字段 | `Unit.has_moved` / `Unit.has_attacked`（替代 `has_acted`） |
| 回合开始 | 己方非 HQ 单位两个标志都清 false |
| 普通单位 | 每回合**移动或攻击二选一**：先移动 → `has_moved=true`，不能再攻击；先攻击 → `has_attacked=true`，不能再移动 |
| 坦克（兵科） | **移动 + 攻击都能做**（各一次） |
| 召唤失调 | 部署当回合默认 `has_moved=true`、`has_attacked=true`（不能行动） |
| 闪击 Blitz | 部署当回合两个标志都为 **false**（可行动） |
| 闪击 + 坦克 | 部署当回合可 **移动 + 攻击**（先移动再攻击） |
| 作战费 / 能量 | 规则不变（移动/攻击各自扣 `operation_cost`） |

**影响**：`_deploy_unit`、`_begin_turn`、`_enemy_turn`、`move_unit`、`attack_unit`、`_ai`、以及现有测试里所有 `has_acted` 断言（`battle_m2_test`、`status_test` 等）都要同步改——**测试由教练改**。

## 决定 2：Guard（护卫）

| 项 | 规则 |
|---|---|
| 保护范围 | Guard 保护**同线左右相邻格**（slot ±1）的友军；**跨线不保护** |
| 目标限制 | 被保护的友军**不能被敌方单位攻击选中**：`attack_unit` 返回 false；AI 选目标跳过 |
| 不护 Guard | 带 `guard` 词条的单位**不受 Guard 保护**（Guard 之间互不保护） |
| HQ | **HQ 可被保护**（默认；HQ 在支援线 0 格，1 格有 Guard 时单位攻击不能打 HQ） |
| 指令卡 | **默认无视 Guard**（Order 直接选目标）。以后要"尊重守护"的指令卡，在卡牌数据加字段（如 `respects_guard: true`，默认 false） |
| 炮兵 / 轰炸机 | **无视 Guard**（2026-11-25 学员补充）：这两种兵科选目标时不受 `_is_guarded()` 限制，可以直接打被保护的单位 |
| 双方 | 玩家与 AI 完全对称 |

**实现点**：`attack_unit` 目标合法性校验 + `_ai` 攻击段选目标 + `play_card` 里 `respects_guard`（先不做字段，默认无视）。

## 决定 3：兵科（KARDS 5 类）

| 兵科 (`unit_class`) | 规则 |
|---|---|
| `infantry` 步兵 | 无特殊 |
| `tank` 坦克 | 一回合可以「移动 + 攻击」都做（见决定 1） |
| `artillery` 炮兵 | 攻击时**不受反击伤害**；**无视 Guard** |
| `fighter` 战斗机 | 可从自己支援线**直接打对方支援线**；敌方轰炸机攻击有战斗机的线时只能打战斗机 |
| `bomber` 轰炸机 | 可**越线**打支援线；攻击非战斗机不受反击；**自己被打时也不能反击**；**无视 Guard** |

**注意**：战斗机/轰炸机的越线攻击会改变 §17「只能打相邻线」的固化规则 → §17 需加"空军例外"说明并更新 `combat_test`；**这是 M3 唯一会动攻击范围的地方**。

## 决定 4：数据与校验

- `Card.unit_class ∈ {infantry, tank, artillery, fighter, bomber}`（现在字段全是 `""`，M3.4 给 20+ 张卡补上）；
- 关键词枚举 `{blitz, guard}`（`tools/validate_data.gd` 已把未知关键词记为 warning，改成 M3 后可选报错）；
- 未知兵科/关键词不能崩（warning）。

## 测试计划（教练出）

| 文件 | 覆盖 | 项数（估） |
|---|---|---|
| `tests/pending/keywords_test.gd` | 关键词解析/传递、Blitz、行动经济、Blitz+Tank 叠加 | 12–14（重写） |
| `tests/pending/guard_test.gd` | 同线相邻保护、不护 Guard、HQ 可保护、指令卡无视 Guard | 9–11（重写） |
| `tests/combat_test.gd` 增补 | 兵科：炮兵无反击、坦克移动+攻击、战斗机/轰炸机越线 | +10 |
| 数据 | `data_test` 的牌库断言随卡池更新 | 同步改 |

## 后果

- 正面：行动选择有深度（坦克/闪击组合）、站位有意义（Guard）、兵科区分。
- 负面：`has_acted` 全面改 → 现有测试要改一轮；Guard + AI 目标逻辑变复杂；空军越线要单独测。
- 风险：兵科规则多，**分批做**：M3.3 先做"数据标签 + 炮兵无反击 + 坦克移动+攻击"，空军越线放 M3.3b（单独测试）。
