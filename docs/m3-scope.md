# M3 任务排期（内容与平衡）· 2026-11-22 定稿版

> 状态：**规则已拍板**（ADR-004 / ADR-005），按本文件排期执行。
> 前置：**P1 E7a（弃牌堆+疲劳）→ P2 E7b（起手/换牌）** 先做完（M2 收尾）。
> 分工：规格/数据/测试/文档/CI = 教练；`src/core/*.gd` 实现 = 学员。

---

## 0. M3 完成判据（DoD）

| # | 判据 | 怎么验 |
|---|---|---|
| 1 | 双方 **39 张构筑牌 + 1 HQ**，自动对局稳定分出胜负（含抽干疲劳） | `run_auto` 100 seed 全 WIN/LOSE；`deck_build_test` |
| 2 | 卡池 **≥ 20 种**，带兵科/关键词字段 | `data_test` 更新 + `validate_data` |
| 3 | **行动经济**：`has_moved`/`has_attacked`、坦克移动+攻击、闪击、闪击+坦克 | `keywords_test`（重写） |
| 4 | **Guard**：同线相邻保护、不护 Guard、HQ 可保护、指令卡默认无视 | `guard_test`（重写） |
| 5 | **兵科 5 类**：步兵/坦克/炮兵/战斗机/轰炸机 | `combat_test` 增补 |
| 6 | **元素 v3**：多槽（MAX_AURAS=3）+ 持续时间 + 删复合 id + dot 不反应 | `aura_v3_test`（新写） |
| 7 | 数值系统：`stat_mod/passive`（`defense_down` 生效） | `status_test` 增补 |
| 8 | 平衡：`balance_sim` 1 万场，胜率 **45–60%**、超时 <1%、平均 8–20 回合 | `docs/balance-report.md` |
| 9 | **AI 会打指令卡**（平衡模拟需要） | `run_auto` 用构筑牌组跑 1 万场无卡死 |
| 10 | 全套测试全绿，CI < 10 分钟，tag `v0.3` | CI + `run_tests.bat` |

---

## 1. 任务表（按顺序）

| # | 任务 | 内容 | 估时 | 验收 | 状态 |
|---|---|---|---|---|---|
| P1 | **E7a 弃牌堆 + 疲劳** | `discard`/`enemy_discard`、出牌入弃牌、burn、抽干按 1,2,3… 扣自己 HQ | 1.5h | `deck_test` 20/20 → 375 | ✅ 规格+测试已备 |
| P2 | **E7b 起手/换牌** | **先手随机**；先手起手4+首回合不抽；后手起手5+首回合抽1；mulligan ✅（每方一次，独立开局阶段） | 1.5h | `opening_test`（25 项，已写） | ✅ 规格+测试已备 |
| M3.0 | **规则定稿** | ADR-004（行动经济/Guard/兵科）、ADR-005（元素 v3） | ✅ | 文档 | ✅ 完成 |
| M3.1 | **行动经济 + 关键词 + Blitz** | 拆 `has_moved`/`has_attacked`；`Card/Unit.keywords` 解析传递；Blitz；Blitz+Tank | 3h | `keywords_test` 12–14 全绿 | 测试待重写 |
| M3.2 | **Guard** | 同线相邻保护、不护 Guard、HQ 可保护、AI 遵守、指令卡默认无视 | 3h | `guard_test` 9–11 全绿 | 测试待重写 |
| M3.3 | **兵科（基础）** | 数据标签 + 炮兵无反击 + 坦克移动+攻击 | 4h | `combat_test` 增补（+6） | 待做 |
| M3.3b | **兵科（空军）** | 战斗机/轰炸机越线规则（改 §17） | 4h | `combat_test` 增补（+4） | 待做 |
| M3.4 | **卡池 20+** | 内容设计（学员 🎨）+ `cards.json` + 兵科/关键词字段 | 6h | `data_test` 更新 + `validate_data` | 待做 |
| M3.5 | **卡组构筑 39+1** | `data/decks/*.json`、同名上限、`DataLoader.load_deck`、39 张校验 | 4h | `deck_build_test` 10 项 | ✅ 数据/校验/测试已备 |
| M3.6 | **元素系统 v3** | 多槽 `auras` + duration + 删复合 id + reactions/elements 数据 v3 + 全测试迁移 | 6–10h（原估 12–16h） | `aura_v3_test` 20–26 | 规格 ✅（ADR-005 + element-reactions-v3.md）；数据/测试待写 |
| M3.7 | **数值 stat_mod** | `defense_down` 等 passive 效果生效 | 3h | `stat_mod_test` 6 项 | ✅ 测试已写 |
| M3.8a | **AI 出牌** | 玩家/敌方 AI 会打指令卡（含目标选择），否则构筑牌组里的指令卡会卡手牌 | 3h | `run_auto` 可用构筑牌组跑完 | 待做（平衡前置） |
| M3.8 | **平衡调参** | 先手补偿/敌方 AI 加强 → `balance_sim` 1 万场 → 报告 → 调数值 | 6h | `docs/balance-report.md` 胜率 45–60% | 工具 ✅ / 待调 |
| M3.9 | **收尾** | 全套绿、CI 时间、README/devlog、tag `v0.3` | 0.5h | — | 待做 |

**学员实现 ≈ 45–50h；教练规格/数据/测试 ≈ 20h。按每周 9h ≈ 6 周。**

---

## 2. 测试计划（教练产出）

| 文件 | 覆盖 | 项数（估） | 状态 |
|---|---|---|---|
| `tests/pending/keywords_test.gd` | 关键词解析/传递、Blitz、行动经济、Blitz+Tank | 17 | ✅ 已写（按 ADR-004 重写） |
| `tests/pending/guard_test.gd` | 同线相邻保护、不护 Guard、HQ、指令卡无视 | 8 | ✅ 已写（按 ADR-004 重写） |
| `tests/pending/unit_class_test.gd` | 炮兵无反击、坦克移动+攻击、战斗机/轰炸机越线/无反击 | 11 | ✅ 已写（M3.3b 拦截规则再补） |
| `tests/pending/deck_build_test.gd` | 39+1 展开、同名上限、非法 id、双方独立 | 10 | ✅ 已写 |
| `tests/pending/aura_v3_test.gd` | 多槽/叠加/反应/槽满/持续时间/感电冻结/dot/免疫 | 20–26 | M3.6 时写 |
| `tests/pending/stat_mod_test.gd` | `defense_down` 生效/叠层/指令伤害/到期 | 6 | ✅ 已写 |
| `tests/pending/air_intercept_test.gd` | 战斗机拦截轰炸机 | 3 | ✅ 已写 |
| `tests/pending/opening_test.gd` | E7b 随机先手、起手 4/5、首回合抽牌、mulligan | 25 | ✅ 已写（2026-11-23 改随机先手） |

> 规则：`EXPECTED_CHECKS` 同步；`tests/pending/` 不进 CI；教练给测试前先用临时副本参考实现验证可通行。

---

## 3. 排期（每周约 9h）

| 周 | 学员 | 教练 |
|---|---|---|
| W47 剩余 | P1 E7a（弃牌堆+疲劳） | 改 `deck_test` 已备；E7a 收尾 |
| W48 | P2 E7b 起手/换牌 → M3.1 行动经济+Blitz | 写 `opening_test`；重写 `keywords_test` |
| W49 | M3.2 Guard → M3.3 兵科基础 | 重写 `guard_test`；`combat_test` 增补 |
| W50 | M3.3b 空军 → M3.4 卡池 20+ | `data_test` 同步；数据校验 |
| W51 | M3.5 卡组构筑 39+1 | 写 `deck_build_test`；数据 decks |
| W52 | M3.6 元素 v3（上） | `element-reactions.md` v3 + 数据 + `aura_v3_test` |
| W53 | M3.6 元素 v3（下）→ M3.7 stat_mod | 测试迁移（aura 相关旧断言） |
| W54 | M3.8 平衡调参 → M3.9 收尾 | 报告/调参建议、tag v0.3 |

（E7b 的 mulligan 若确认要做，P2 从 1h → 2h，W48 顺延半天。）

---

## 4. 依赖与风险

- **依赖**：P1/P2 完成前不开 M3（元素/构筑都依赖抽牌与弃牌规则）；M3.5 依赖 M3.4 卡池；M3.6 依赖 M3.1–M3.3（关卡战斗要用新规则验证）。
- **风险 1**：`has_acted` → `has_moved`/`has_attacked` 会改大量现有断言（`battle_m2_test`、`status_test`、`battle_m1_smoke_test` 部分）→ 教练先改测试，再让学员改实现。
- **风险 2**：Guard + AI 目标选择复杂；先写测试再实现。
- **风险 3**：元素 v3 改动面最大（数据 schema + 所有 aura 断言），放最后并单独一轮。
- **风险 4**：平衡基线显示先手 100% 胜（10000 场），M3.8 要处理先后手补偿/敌方 AI，否则平衡目标不可达。
- **风险 5**：卡池内容设计（🎨）是学员的活，教练不代写卡牌创意。

---

## 5. 已拍板（2026-11-22）

- ④ 元素：复合元素**会继续反应**（原神事实）→ 改多槽 v3；dot 不挂元素不反应；不做量衰减、改持续时间；**MAX_AURAS=3（常量可调）**。
- ③ Blitz：部署当回合可行动；**闪击 + 坦克 = 移动 + 攻击**；行动经济拆双标志。
- ② 兵科：KARDS 5 类（步兵/坦克/炮兵/战斗机/轰炸机）。
- ① Guard：保护同线左右相邻格；被保护单位不能被单位攻击选中；Guard 不护 Guard；HQ 可被保护；**指令卡默认无视 Guard**（特殊卡再加字段）。

## 6. 仍需在 M3.6 前细化的点

1. 感电/冻结的 consume 值（建议 0，共存不改元素）；
2. 反应优先级（建议槽创建顺序最早优先）；
3. 槽满替换策略（建议替换最旧）；
4. duration 数值表（普通 2 / 强附着 3 回合起步）；
5. E7b 的 mulligan 做不做（❓）。
