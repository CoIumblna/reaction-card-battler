# M3 规格草案（内容与平衡）

> 状态：**教练起草（2026-11-21），待学员拍板**。M3 依赖 E14/E7 收尾完成（M2 收尾任务，见 `implementation-tasks.md` §25/§26）。
> 本文件只给"要什么 / 怎么验收 / 待定项"，不给实现。数据 + 测试由教练出，`src/` 由学员写。

---

## 0. M3 完成判据（Definition of Done）

| # | 判据 | 怎么验 |
|---|---|---|
| 1 | 双方用 **30 张构筑牌组**打完整局，自动对局稳定分出胜负（不再靠固定牌库顺序） | `run_auto` 100 个 seed 全部 WIN/LOSE，回合数分布合理（8–30） |
| 2 | **卡池 ≥ 20 种**（含单位/指令，带关键词与兵科字段） | `data_test` 牌库断言更新 + 数据校验通过 |
| 3 | **关键词框架** + 首批关键词（**闪击 Blitz**、**护卫 Guard**）生效，AI 遵守 | 新测试 `tests/keywords_test.gd`（先写 Blitz，Guard 待语义确认后补） |
| 4 | **兵科**至少最小实现（数据标签 + 1 条规则差异，范围待拍板 ❓1） | `combat_test` 增补或新测试 |
| 5 | **平衡模拟器**：1 万场输出 CSV + 报告 | `tools/balance_sim.gd` 跑通，`docs/balance-report.md` 有结论 |
| 6 | 胜率调到 **45%–60%** 区间（双方同策略 AI） | balance report |
| 7 | 全套测试（M1–M3）全绿，CI < 10 分钟 | CI + `run_tests.bat` |

> 元素扩展（复合元素再反应 / dot 参与反应 / 附着衰减）**不建议首发进 M3**，见 §5 ❓5：先让 M3.1–M3.5 落地，再决定是否加。

---

## 1. 任务分解

### M3.1 关键词框架 + 闪击（Blitz）（E17 / F3）

**现状缺口**：`Card.keywords` / `Unit.keywords` 字段存在（Card 有 `keywords: Array[String]`，Unit 没有），但 `Card.from_dict` **没有解析 keywords**、`DataLoader` 不传、`_deploy_unit` 不带到 Unit、`Unit` 没有 `keywords` 字段、也没有任何地方消费关键词。

| 要做的 | 说明 |
|---|---|
| 数据层 | `Card.from_dict` 解析 `keywords`（字符串数组）；`DataLoader.load_cards` 对未知关键词给 `push_error` 但不崩 |
| 单位层 | `Unit` 加 `keywords: Array[String]`，`Unit.from_dict` 解析；`_deploy_unit` 从 Card 拷到 Unit |
| 消费点 | **Blitz（闪击）：带该关键词的单位部署当回合可行动**——`_deploy_unit` 里 `has_acted = false`（否则为 `true`） |
| 日志 | 部署时标注关键词（如 `步兵(闪击)上场`） |

**验收**：`tests/pending/keywords_test.gd`（教练已写，先覆盖 Blitz，7 项）。
- Blitz 单位部署当回合 `has_acted == false`、能移动/攻击；普通单位仍 `true`。
- 全绿后移到 `tests/`。

### M3.2 护卫（Guard）（E17 / F3，**语义待拍板 ❓2**）

**候选语义**（KARDS：Guard 保护相邻/同线单位）：

- A. 敌方**相邻线**存在 Guard 单位时，攻击目标**必须是 Guard 单位**（打不到 HQ 和非 Guard 单位）；
- B. Guard 只保护**同线**单位（不影响 HQ）；
- C. Guard 是"嘲讽"：AI 和玩家选目标时优先打 Guard，但不强制。

实现要点：`attack_unit` 目标合法性校验 + **AI 选目标必须遵守**（`_ai` 的攻击段）；测试要覆盖"玩家/AI 都不能越过 Guard"。
**拍板后再补 `keywords_test.gd` 的 Guard 段**（预计 8–10 条）。

### M3.3 兵科（E16，**范围待拍板 ❓1**）

`Card.unit_class` 字段已有（`""` 缺省）。候选范围：

| 选项 | 规则 | 影响面 |
|---|---|---|
| 最小版 ✅推荐 | 只做数据标签（步兵/坦克/炮兵/空军），无规则差异 | 只改数据 + 校验 |
| +炮兵 | 炮兵攻击时**不受反击伤害** | `attack_unit` 反击段 |
| +空军 | 空军可**越线**攻击（不受相邻线限制） | `§17` 攻击范围 + AI 选目标 |

建议 M3 先做"标签 + 炮兵"，空军越线留给 M3 后半段或 M4（会动 §17 这条固化规则，牵一发动全身）。

### M3.4 卡池扩到 20+（F1 / A7）

- `data/tables/cards.json` 从 11 种扩到 ≥20 种；新增卡尽量覆盖：关键词（blitz/guard）、兵科、元素组合、≥1 张 0 作战费单位；
- 牌组 `count` 总和 30 张（M3 构筑规则待拍板 ❓4）；
- **注意**：`data_test` 有牌库张数/内容断言（现在按 11 种 × count 校验），加卡要同步改断言与 `EXPECTED_CHECKS`（教练做）。
- 数据校验：`tools/validate_data.gd`（BACKLOG A5，M3 工具）或人工 `ConvertFrom-Json`。

### M3.5 卡组构筑（F4）

- 新增 `data/decks/player_deck.json` / `enemy_deck.json`（30 张：`id` + `count`，同名上限待定 ❓4），或用参数传入 `Battle.setup`；
- `DataLoader.load_deck(path)`：展开成 `Array[Card]`；找不到卡/超上限 → 明确报错；
- 敌方牌组可配置（不同关卡/难度）；
- 测试：`tests/deck_build_test.gd`（展开张数、非法 id、上限校验、双方独立）。

### M3.6 平衡模拟器（F5 / F6 / F7）

- `tools/balance_sim.gd`（`--headless --script` 跑）：
  ```
  godot --headless --path . --script res://tools/balance_sim.gd -- --decks res://data/decks/player_deck.json,res://data/decks/enemy_deck.json --games 10000 --seed 42 --out res://balance.csv
  ```
  输出 CSV 列：`game, seed, winner, turns, player_hq_hp, enemy_hq_hp`；汇总：胜率、平均回合、平局/超时数（应接近 0）；
- 性能目标：**1 万场 < 3 分钟**（纯逻辑、`run_auto` 无 UI）；
- `docs/balance-report.md`：方法、参数、胜率表、结论、下次调参方向；
- 调参流程：改 `cards.json`/数值 → 跑 `balance_sim` → 记录 → 目标胜率 45%–60%。

### M3.7 收尾

- 新测试文件全部启用，`EXPECTED_CHECKS` 同步；CI 仍 <10 分钟（必要时把 balance_sim 排除在 CI 外，单独跑）；
- 更新 `docs/game-design.md` 的 M3 章节、`BACKLOG` 状态、README 测试表、devlog；
- 打 tag：`v0.3`。

---

## 2. 测试计划（教练出测试）

| 文件 | 覆盖 | 项数（估） |
|---|---|---|
| `tests/keywords_test.gd` | Blitz（已写 7 项）+ Guard（待补 8–10 项） | 7 → 15–17 |
| `tests/deck_build_test.gd` | 牌组 JSON 展开、上限、非法项、双方独立 | 12–15 |
| `tests/combat_test.gd` 增补 | 兵科（炮兵无反击等，待拍板） | +4–6 |
| `tests/balance_sim_smoke_test.gd` | 工具存在 + 100 场能跑完（不进 CI 或标记短跑） | 3–5 |

> 数据/测试改动遵循"文档 + 数据 + 测试三件套"，**不要为了变绿改测试**。

---

## 3. 需要拍板的问题（❓）

1. **兵科做到多深**：只标签 / +炮兵无反击（推荐）/ 再加空军越线？
2. **Guard 语义**：A 强制打 Guard / B 只保护同线 / C 只影响 AI 优先级？
3. **Blitz 范围**：只"部署当回合可攻击"，还是"可移动 + 攻击"（KARDS 原版是两者都可）？
4. **构筑规则**：30 张、同名上限 4？要不要先后手差异 / 起手 mulligan（与 E7 的"换牌"合并考虑）？
5. **元素扩展**（复合元素再反应 / dot 参与反应 / 附着衰减）放 M3 还是 M4？建议 M4 或 M3.5 之后看平衡结果再定。
6. **balance_sim 的"胜率"定义**：玩家 AI vs 敌方 AI（同策略）还是两套不同策略对打？建议先用同策略做基准。
7. **卡池数量**：≥20 种够用吗（KARDS 风格下 20 种 × 30 张构筑空间较小，建议 24–30 种）？

---

## 4. 建议排期（按每周约 9h）

| 周 | 内容 | 验收 |
|---|---|---|
| W48 | E14 + E7 收尾（离线包已备）；M3.1 关键词框架 + Blitz | `order_test`/`deck_test` 启用；`keywords_test` Blitz 全绿 |
| W49 | M3.2 Guard（拍板后）+ AI 目标策略 | `keywords_test` 全绿 |
| W50 | M3.3 兵科最小版 + M3.4 卡池 20+ | `data_test` 更新后全绿 |
| W51 | M3.5 卡组构筑 + M3.6 `balance_sim` | `deck_build_test` 全绿；1 万场跑通 |
| W52 | M3.6 调参 + balance report + M3.7 收尾 | 胜率 45–60%；全套全绿；tag `v0.3` |

---

## 5. 先决条件 / 风险

- **先决**：E14（指令卡打棋盘）+ E7（弃牌堆/洗回）必须先完成，否则 30 张构筑牌组长局会抽干、指令卡也没法作用于棋盘。
- **风险**：Guard/空军会改 §17 攻击范围这条固化规则 → 必须"文档 + 数据 + 测试"三件套，且先写 ADR（新增 `docs/adr/004-m3-keywords.md`）。
- **风险**：卡池扩充会让 `data_test` 的硬编码断言红——同步更新，不要放宽断言。
- **CI 时间**：balance_sim 不放进 CI（10 分钟上限），只做短跑 smoke 或本地工具。
