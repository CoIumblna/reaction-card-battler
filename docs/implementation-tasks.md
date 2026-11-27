# 实现任务卡（每个文件要你写什么、用什么手段、怎么验收）

> **▶ 现在只看这一节：搜索 `## 42.` 跳到末尾 —— 魔物元素盾。**
> 施工步骤 = **§42.13 九步**，第一步是「第 0 步：先清掉上一版错误代码」；判据 §42.10；
> 踩坑 §42.11；上一轮评审 §42.15；全部数值与破盾系数 §42.3。
>
> **本文件怎么读**（按顺序，读完前一站再往下）：
>
> | 站 | 内容 | 什么时候读 |
> |---|---|---|
> | 1 | 开头到 `## 37.` 之前：当前状态 / 进度总览 / 已完成块索引 / **跨块硬规矩 14 条** | 每次开工前 |
> | 2 | **§42**：当前块全部细节（这是唯一要你现在读的正文） | 现在 |
> | 3 | §37–§38：M4 总览与通用规矩 | M4 开工时 |
> | 4 | §43–§44：M3 收尾与 M4 的预留规格 | 到那一步再读 |
>
> §39–§41 是刚完成的三个块，只留结论（细节在 git 历史与 `docs/HANDOFF-2026-11-23.md`）。
> §1–§36 是已完成块，已折叠成索引表。
>
> **纪律**：只给「要什么」，不给代码（m00629）。所有任务指引一律写进本文件，
> 不新建 `docs/brief-*.md` / `docs/review-*.md`（m00779）。
> `src/` 生产代码**绝不派给子 agent**（HANDOFF §2.1 硬规则，2026-11-27 翻车记录）；
> 子 agent 只能写 `tools/` 与 `tests/` 的辅助代码。

## 当前状态（一眼看完）

| | |
|---|---|
| 主套 | **20 个测试文件 / 560 项全绿**（`run_tests.bat`，PART 1 + PART 1.5 + PART 2） |
| 已完成 | M1 · M2 · P1 · P2 · M3.1 · M3.2 · M3.3 · M3.3b · M3.4（前置 + 卡池）· M3.5 · M3.6 · M3.7 |
| **当前块** | **魔物元素盾（§42）** —— 独立吸收层，不是免疫；被反应按系数削、物理少量削、同属性不削、破盾 3 回合重生 |
| 之后 | M3.8a（§43.A）→ M3.8 平衡（§43.B）→ M3.9 tag v0.3（§43.C）→ M4 十三块（§37 + §44） |
| 卡池 | 20 种 / 展开 68 张；每张卡有独立 `limit`（缺省 4） |

## 进度总览

| # | 文件 | 任务数 | 难度 | 验收（测试分组） | 完成 |
|---|---|---|---|---|---|
| 1–9 | M1：`element` / `damage` / `card` / `buff` / `unit` / `reaction_table` / `data_loader` / `battle` / `status_table` | 41 | ★–★★★ | data / damage / unit / battle_m1_smoke | [x] |
| 10–22 | M2：`unit` 扩展 / `board` / HQ / Kredit / 部署 / 召唤失调 / 移动 / 攻击 / 行动花费 / owner / 前线独占 / 死亡移除 / 胜负 HQ / 敌方 AI / 状态效果 / 指令卡 / 牌堆弃牌 / 起手换牌 | 60 | ★★★ | board / combat / battle_m2 / status / order / deck / opening | [x] |
| 22–25 | M3.1 行动经济 + 关键词 + 闪击 · M3.2 Guard · M3.3 兵科/空军/炮兵 · M3.3b 战斗机拦截 | 10 | ★★★ | keywords 17 · guard 8 · unit_class 21 · air_intercept 3 | [x] |
| 26 | **M3.4 卡池 20+ 种**（任务卡 §40） | 1 | ★★ | data_test + validate_data | [x] 20 种 / 68 张，见 §40.10 |
| 26b | **M3.4 前置：AI 选目标**（任务卡 §39） | 1 | ★★★ | `ai_guard_test` 14 项 | [x] 499/499，见 §39.9 |
| 27 | M3.5 卡组构筑（39+1） | 1 | ★★ | `deck_build_test` 13 项 | [x] |
| 28 | **M3.6 元素 v3 多槽 + 每卡独立 limit**（任务卡 §41） | 4 | ★★★★ | `aura_v3_test` 59 项 | [x] 560/560，见 §41.7 |
| **28b** | **魔物元素盾（§42）** | 4 | ★★★ | `tests/pending/elemental_shield_test.gd`（约 32 项，待写） | **[ ] ← 当前块** |
| 29 | M3.7 通用 stat 系统 | 1 | ★★★ | stat_mod 7 + stat_system 18 | [x] |
| 30 | M3.8a AI 打指令卡（§43.A） | 2 | ★★★ | `tests/pending/ai_order_test.gd` 约 14 项 + 10 seed 对照 | [ ] |
| 31 | M3.8 平衡（§43.B，前置是先手补偿） | 3 | ★★★ | `docs/balance-report.md` + 胜率 45–55% 且先手两侧达标 | [ ] |
| 32 | M3.9 收尾 tag v0.3（§43.C） | 1 | ★ | README + HANDOFF + issue 全关 + tag 已推 | [ ] |
| 33–45 | **M4.0–M4.9b 十三块**（§37，验收补全见 §44） | 30 | ★–★★★ | 各自 `ui_*_test.gd` + `tools/ui_check.ps1` | [ ] |

**完成列**：`[x]` 已完成并提交 / `[~]` 进行中 / `[ ]` 未开始。
**预计用时**：★★★★ ≈ 8×、★★★ ≈ 4×、★★ ≈ 2×、★ ≈ 0.5 h 基准。历史实测显示净编码约为乐观估值的 **1/3 ~ 1/4**
（任务卡把 API 形状与坑都写死了，实际是「照图纸填空」）——真正决定进度的是**返工轮数**，不是打字速度。

## §1–§36 已完成块索引（细节看 git / HANDOFF，这里只留一行结论）

| 节 | 文件 | 做了什么 | 验收 |
|---|---|---|---|
| 1 | `element.gd` | 元素常量、`pair_key`、`display_name` | data_test[3] |
| 2 | `damage.gd` | `compute()` 伤害与反应倍率、免疫短路 | damage_test D1–D7 |
| 3 | `card.gd` | 卡牌数据 + `from_dict` | data_test[1] |
| 4 | `buff.gd` | 状态实例（kind/stacks/duration） | unit_test[5] |
| 5 | `unit.gd` | 单位数值、护盾先行、buff tick、描述 | unit_test[1–4] |
| 6 | `reaction_table.gd` | 反应表加载与查询 | data_test[4] |
| 7 | `data_loader.gd` | JSON 入口、按 count 展开、deck 校验 | data_test[1][2] |
| 8 | `battle.gd` | 战斗内核骨架（M1） | battle_m1_smoke 全段 |
| 9 | `status_table.gd` | 状态表加载 | data_test[5] |
| 10 | `unit.gd`（M2） | 上战场要的字段 | board_test[1] |
| 11 | `board.gd` | 三条线 × 5 格、`units_in` / `position_of` | board_test[2][3] |
| 12 | HQ | HQ 占支援线 0 号格（`HQ_SLOT := 0`） | board_test[2] |
| 13 | `battle.gd`（M2） | Kredit 成长、部署、召唤失调 | battle_m2_test[1–3] |
| 14 | `board` + `battle` | 移动、攻击、行动花费 | combat_test[1–3] |
| 15 | `unit` + `battle` | `owner`、前线独占 | combat_test[2][5] |
| 16 | `board` + `battle` | 死亡与移除 | combat_test[6] |
| 17 | `battle.gd` | 胜负改为打掉 HQ | battle_m2_test[5] |
| 18 | `battle.gd` | 敌方 AI + `run_auto` | battle_m2_test[3][6][7] |
| 19 | `battle.gd` | 状态效果生效（dot / disable / stat_mod） | status_test |
| 20 | `battle.gd` | 指令卡打在棋盘单位上 | order_test |
| 21 | `battle.gd` | 牌堆 / 弃牌 / 抽干疲劳 / 起手换牌 | deck_test + opening_test |
| 22–25 | `battle.gd` | M3.1 行动经济+关键词+闪击 · M3.2 Guard · M3.3 兵科 · M3.3b 战斗机拦截 | keywords / guard / unit_class / air_intercept |
| 27 | `data_loader.gd` | M3.5 卡组构筑 39+1 | deck_build_test 13 |
| 29 | `battle.gd` | M3.7 `stat_of(unit, stat)` | stat_mod 7 + stat_system 18 |
| 33b | `battle.gd` | 轰炸机打「有敌方战斗机驻守的线」只能打战斗机 | air_intercept_test 3 |

**已归档的过时评审/背景**：§28「Guard 待拍板」、§29「M3 任务索引」、§35「M3.6 stub」都已被 §32 / §39–§41 取代。
M3.4/M3.5/M3.6 的详细评审与红绿指纹分别在 §39.6–§39.9 / §40.10 / §41.5–§41.9。

## 已完成块留下的硬规矩与坑（跨块通用，务必先读）

1. **`.gd` / `.md` 只能用编辑器或定点替换改**。PowerShell 整篇重写会带 BOM + CRLF + 中文乱码 → `Parse Error: Could not parse global class`。
2. **`.bat` 必须 CRLF + 纯 ASCII + 无 BOM；`.ps1` 必须 UTF-8 **带** BOM**（PS 5.1 否则按 936 解码炸出成片假语法错）；`.gd` / `.md` 无 BOM + LF。
3. **类型化数组就真类型化**：`func f() -> Array[Unit]` 里返回无类型 `Array` 会报 `SCRIPT ERROR` **并同时丢内容**（返回空数组）。
4. **`sort_custom` 不稳定**（实测 n≥17 起乱序）→ 多档排序用「多个桶 + `append_array`」，别依赖排序稳定性。
5. **`attack_unit()` 返回 bool 是唯一权威**。AI 侧不要复述一遍选目标规则，会分叉（`find_first_attackable` 就是被抛弃的那个副本）。
6. **`battle.gd` 的 `setup()` 双方同一副牌**，`first_move` 由 RNG 决定 → `balance_sim` 胜负 100% 由先手决定，**对卡池零敏感**（详见 §40.4）。
7. **`Board.HQ_SLOT := 0`**（支援线 0 号格是 HQ）。测试摆单位用 `index >= 1`，否则 `_settle_status` 判 `is_hq` 跳过、dot 不掉血。
8. **`_settle_status()` 每回合末会 `tick_buffs()` + `tick_auras()`**，所以结算完 `duration` 已经少了 1 —— 断言别写「一点没变」。
9. **`tests/pending/` 不在 git 里**，启用测试用 `Move-Item`（`git mv` 会报 `fatal: not under version control`）。
10. **`[详细自检]` 项数看工作区脏不脏**：干净 = **14 项**，有未提交改动 = 13 项（第 [7] 节走 `Say-Info` 不计数）。
11. **提交信息写文件 + `git commit -F`**；别用 `Out-File -Encoding utf8`（会加 BOM，subject 变 `\ufefffeat(core): ???`）。
12. **所有跑 Godot 的入口都有 90 s 墙钟超时**（`run_tests.bat` / `check.bat` / CI）。`[HUNG]` = 没跑完无裁决，`[PENDING]` = 跑完了但有 N 红，两者别混。
13. **每个测试文件末尾自校验 `EXPECTED_CHECKS`**：漏跑几条也会「全绿」，项数校验是唯一防线。改断言必须同步改这个数。
14. **`deck_build_test` 的 `.log.err` 非空是正常的**（它故意造非法输入触发 `push_error`）。判红只看 `[FAIL]` / `SCRIPT ERROR` / 退出码。

---

## 37. M4 任务卡总览（界面 + 存档）· 2026-11-26 立项

> **M4 只做一件事：让这个项目「能玩、能给人看」。**
> 能开窗口、能用手点着打完一局、中文不是方块、关掉再打开进度还在。
> **发布（导出 exe / 网页、商店页、演示 GIF）属于 M5，M4 不碰。**
>
> 完整规划（拆块理由、风险、排除项、BACKLOG 对照）见 **`docs/m4-plan.md`**。
> 本节是**施工用的任务卡**：每一块照着 §37.N 做，做完回来打勾。
>
> **前置**：M3 全部完成、`run_tests.bat` 全绿并 tag `v0.3` 之后才开 M4。
> 当前 M3 还剩 魔物元素盾（§42）/ M3.8a / M3.8 / M3.9（后三块的细化规格见 **§43**）。
>
> **分工**：`scenes/*.tscn`、`src/ui/*.gd` = 学员写；规格 / 测试 / 数据 / 文档 / CI = 教练。
> `src/core/` 只允许**新增** UI 需要的公开接口，已有的 `play_card` / `move_unit` / `attack_unit` / `stat_of`
> 行为一行都不许变（M4 期间「顺手重构 core」是明确禁止的）。

### 37.0 M4 进度表

> **验收脚本（2026-11-27 交付，用法见 §44.0）**：`tools/ui_smoke.bat`（跑全部 `ui_*_test`）与
> `tools/ui_check.ps1`（场景/字体/中文字面量/core 纯净度/pending 五项体检）。每块收工 = 本表判据 + 对应脚本退出码 0。
> **跨块接口签名已钉死，见 §44.1**（快照 / legal_* / ai_step / 状态签名 / fx / 存档六组）。

| # | 块 | 交付物 | 难度 | **预计用时** | 验收（测试 / 判据） | 完成 |
|---|---|---|---|---|---|---|
| 37.1 | **M4.0** 骨架 + 中文字体 | `project.godot`（主场景 + 窗口尺寸）、`scenes/main.tscn`、`src/ui/main_screen.gd`、`assets/fonts/README.md` | ★ | **1–1.5 h** | 退出码 0 无 `Failed to load main scene`；`[FONT OK]`；截图中文非方块 | [ ] |
| 37.2 | **M4.1a** 只读快照 + 合法动作 | `battle.gd`：`snapshot()` / `legal_targets` / `legal_moves` / `legal_attacks`；`tests/ui_snapshot_test.gd` | ★★ | **1–1.5 h** | 快照纯读（调 100 次状态不变）；`legal_*` 与 `play_card` 拒绝条件一致 | [ ] |
| 37.3 | **M4.1b** AI 单步 | `battle.gd`：`ai_step() -> bool`；`tests/ui_ai_step_test.gd` | ★★ | **1–1.5 h** | 循环调完能走完一个 AI 回合；`run_auto` 10 个固定 seed 终局逐一致 | [ ] |
| 37.4 | **M4.2** 手牌 UI | `src/ui/hand_view.gd` / `card_view.gd`（已交付）/ `hand_controller.gd`；`tests/ui_hand_flow_test.gd` | ★★ | **1–2 h** | 注入 1/4/9 张假快照断言卡宽与可见张数；9 张不溢出；换牌可用 | [ ] |
| 37.5 | **M4.3** 出牌交互 | `src/ui/play_controller.gd`、`battle_screen.gd`；`tests/ui_play_flow_test.gd` | ★★ | **1.5–2 h** | 状态机 4 步；非法目标不调 `play_card`；ESC 回 idle | [ ] |
| 37.6 | **M4.4a** 战场只读 | `src/ui/board_view.gd` / `unit_view.gd`；`tests/ui_board_view_test.gd` | ★★ | **1.5–2 h** | 3×5=15 格映射无错位；HQ 在 `HQ_SLOT`；`has_moved`/`has_attacked` 有标记 | [ ] |
| 37.7 | **M4.4b** 战场交互 | `src/ui/board_controller.gd`；`tests/ui_board_flow_test.gd` | ★★★ | **2–3 h** | 高亮集合 == `legal_moves` / `legal_attacks`；点格调 `move_unit` 一次且参数对 | [ ] |
| 37.8 | **M4.5** 回合流转与结算 | `src/ui/turn_bar.gd` / `result_panel.gd` / `turn_controller.gd` | ★★ | **1–1.5 h** | 结束回合 → `ai_step` 循环 → 回到玩家；AI 期间遮罩；胜负面板取 `outcome()` | [ ] |
| 37.9 | **M4.6** 动画与反馈（可关） | `src/ui/fx.gd`；设置项 `fx_enabled` | ★★ | **1.5–2 h** | 关掉动画后对局 turn 数不变；动画期间数据已落地；连点不重入 | [ ] |
| 37.10 | **M4.7** 主菜单 / 关卡选择 | `scenes/main_menu.tscn`、`src/ui/main_menu.gd` / `level_select.gd` | ★ | **0.5–1 h** | 关卡条目数 == `enemies.json` 条数；三场景来回切 3 次无报错 | [ ] |
| 37.11 | **M4.8** 设置 | `src/ui/settings.gd`、`user://settings.cfg` | ★ | **0.5–1 h** | 改完即写即生效；重启读回；音量走 `AudioServer`；语言占位不崩 | [ ] |
| 37.12 | **M4.9a** 存档读写 | `src/core/save_system.gd`；`tests/save_test.gd` | ★★ | **1–1.5 h** | 存读深比较一致；版本号正确；缺字段被拒；落盘在 `user://` | [ ] |
| 37.13 | **M4.9b** 存档迁移与兜底 | `src/core/save_system.gd` 的 `_migrate`；`tests/save_migrate_test.gd` | ★★ | **1–1.5 h** | v0 假档能升 v1；未知高版本被拒；坏档自动备份 `*.bad` 并重置 | [ ] |

**合计 ≈ 15–22 h 净编码**（对照 `BACKLOG.md` G 组 42h + H 组 9h = 51h，按 M3 实测倍率 ÷2.5）。
按每天 3–4 h 净编码 ≈ **5–7 个工作日**；实际日历进度由**返工轮数**决定，不是打字速度。

**关键路径**：`37.1 → 37.2 → 37.6 → 37.7 → 37.9`。这条链上任何一块延期，后面全部顺延。
**可以挪到后面**的：`37.10 / 37.11 / 37.12 / 37.13`（不阻塞「能玩」，只阻塞「能存」）。

### 37.1 M4.0 骨架 + 中文字体

#### 规则（一句话）

建出项目的**第一个场景**并注册成主场景，给所有界面装一个**能显示中文的全局主题**。

#### 要改哪里

| 文件 | 改什么 |
|---|---|
| `project.godot` | 加 `[application] run/main_scene="res://scenes/main.tscn"`；加 `[display] window/size/viewport_width=1280` / `viewport_height=800`（现在啥都没有，默认窗口放不下棋盘） |
| `scenes/main.tscn` | **手写最小结构**：一个根 `Control` + 挂 `src/ui/main_screen.gd`，节点十几行 |
| `src/ui/main_screen.gd` | `_ready()` 里 `theme = UiTheme.make_theme()`，然后用代码建控件（标题 Label + 当前块占位） |
| `assets/fonts/README.md` | 写清「当前走系统字体 `SystemFont`、依赖 Microsoft YaHei、发布前要决定是否内嵌 Noto Sans SC（SIL OFL，约 10MB）」 |

`src/ui/ui_theme.gd` 与 `src/ui/card_view.gd` **已交付**（commit `1847bc3`），不要重写。

#### 验收（4 条，逐条打勾）

| # | 判据 | 怎么验 |
|---|---|---|
| 1 | 主场景能加载 | `& $g --headless --path . --quit-after 3` 退出码 0，且**不出现** `Failed to load main scene` |
| 2 | 中文字形可用 | `& $g --headless --path . --script res://tools/check_font.gd` 打印 `[FONT OK] <字体名>` 且退出 0 |
| 3 | 中文真的是字 | 开窗口截一张图，标题的字不是方块 |
| 4 | 没弄红主套 | `run_tests.bat` 仍 `ALL GREEN`（加上场景与脚本后不许多出 `SCRIPT ERROR`） |

#### 坑（4 条）

1. **默认字体没有中文字形，且不报错**。Godot 内置 Open Sans SemiBold 完全没有 CJK 字形，中文一律显示成
   `□□□□`。这不是 bug，是字体缺字形。必须用 `SystemFont` + `font_names`，`UiTheme.make_font()` 已经做好。
2. **`Font.has_char()` 的入参是 int 码位，不是字符串**。写 `f.has_char("中")` 会静默永远 false。
   正确写法 `"中".unicode_at(0)`。`tools/check_font.gd` 里已经踩过并修好，照抄那行。
3. **`.tscn` 手写，不要用编辑器拖**。编辑器生成的场景几百行、带 `uid://` 与 `ext_resource`，
   **几乎无法 review diff**，两人改同一场景必冲突。约定：`scenes/` 只放「根节点 + script」，控件全在脚本里建。
   副作用是「在编辑器里打开场景是空的」——这是刻意换来的可维护性。
4. **改 `project.godot` 后必须 `--import`，否则新场景不注册**。而且 `run_tests.bat` 的 PART 1 不会因此报错
   （它跑的是 `--script`），只有第 1 条验收命令能发现——所以这条必须手工验。

### 37.2 M4.1a 只读快照 + 合法动作查询

#### 规则（一句话）

给 UI 一个**只能看、不能改**的数据入口，以及「这张卡能打谁」「这个单位能去哪」的权威答案。

#### 要改哪里

| 方法 | 签名 | 语义 |
|---|---|---|
| `snapshot` | `() -> Dictionary` | 纯读地打包当前局面：手牌 / 三条线每格单位 / 双方 HQ 血量 / 能量 / 回合数 / `opening_phase` / `is_over` / `outcome` / 最近 N 条日志 |
| `legal_targets` | `(card: Card) -> Array[Unit]` | 这张卡现在能打哪些单位（必须与 `play_card` 的拒绝条件完全一致） |
| `legal_moves` | `(unit: Unit) -> Array` | 这个单位能移到哪些 `(line, index)` |
| `legal_attacks` | `(unit: Unit) -> Array[Unit]` | 这个单位能打哪些单位 |

`legal_*` 的判据只有一条：**同样的输入，`play_card` / `move_unit` / `attack_unit` 会拒绝的，这里就不能返回**。
两份实现必然对不上，所以这些函数应该**内部复用**已有的校验逻辑，不要另写一套规则。

#### 验收：`tests/pending/ui_snapshot_test.gd`（≥12 项）

| # | 断言 |
|---|---|
| 1 | 快照里手牌张数 == `hand.size()` |
| 2 | 快照里三条线每格单位与 `board.unit_at()` 一致（3×5 全查） |
| 3 | 双方 HQ 血量正确 |
| 4 | `energy` / `turn` / `opening_phase` / `is_over` / `outcome` 都在 |
| 5 | **纯读**：连续调 `snapshot()` 100 次后，`get_log()`、手牌数、场上单位数完全不变 |
| 6 | `legal_targets` 返回的每个目标，`play_card` 都成功（或至少不被「非法目标」拒） |
| 7 | `play_card` 会拒的目标不在 `legal_targets` 里 |
| 8 | `legal_moves` 不含该单位当前格 |
| 9 | `legal_attacks` 与 `attack_unit` 的接受集合一致 |

#### 坑（4 条）

1. **`snapshot()` 里绝对不能有副作用**。UI 每次刷新都会调它，任何「顺手 tick buff」「顺手抽牌」
   都会变成「看一眼就改变游戏」。测试第 5 项就是抓这个的。
2. **不要在 UI 里重写规则**。`legal_targets` 内部应该调 core 已有的判定；写第二份规则，M3.6 改元素规则时必然漏。
3. **别把 `Card` / `Unit` 对象直接塞进快照的深层结构**。快照里给 `Unit` 的地方给 `Unit` 是允许的
   （UI 要读 `hp` / `attack`），但**不要给 UI 一份能改回去的引用链**（比如直接暴露 `buffs` 数组本体，要 `.duplicate()`）。
4. **`Array[Card]` 类型化数组不能直接赋 `filter()` 的结果**，要逐项 `append`。

### 37.3 M4.1b AI 单步

#### 规则（一句话）

把「AI 跑完整局」拆成「AI 走一步」，让 UI 能一步一步放动画。

#### 要改哪里

`src/core/battle.gd` 新增 `func ai_step() -> bool`：让**当前行动方**的 AI 走一步，返回「是否还有后续步」。
`run_auto()` 内部改成循环调 `ai_step()` —— 这是必须的，否则两条 AI 路径会分叉。

#### 验收：`tests/pending/ui_ai_step_test.gd`

| # | 断言 |
|---|---|
| 1 | 循环 `while b.ai_step(): pass` 能走完敌方一个回合，不卡死、无 `SCRIPT ERROR` |
| 2 | **`run_auto()` 语义不变**：取 10 个固定 seed，改动前后的终局 `turn` / `outcome` 逐一致 |
| 3 | 对局已结束时再调 `ai_step()` 返回 `false` 且不报错 |
| 4 | 玩家回合期间调 `ai_step()` 是明确的 no-op（返回 `false`），不会替玩家出牌 |

#### 坑（3 条）

1. **第 2 条是这块唯一真正重要的验收**。把 `run_auto` 改走 `ai_step` 却没跑 seed 对比，
   等于在没人看守的情况下换了 AI 的全部行为 —— 平衡基线（48.0% / 13.0 回合）会悄悄漂移。
2. **`ai_step()` 必须在「无事可做」时返回 `false`**，否则 UI 的循环会死转。
3. 别把 `_ai()` 里的逻辑复制一份到 `ai_step()`。`ai_step` 应该只是把 `_ai()` 里「做一件事」拆出来。

### 37.4 M4.2 手牌 UI

#### 规则（一句话）

把玩家手牌画出来，能选中、能换牌。**卡面用已交付的 `src/ui/card_view.gd`，不要重画。**

#### 要改哪里

| 文件 | 职责 |
|---|---|
| `src/ui/hand_view.gd`（`Control`） | 只负责把 controller 算好的位置画出来（卡宽、间距、选中态） |
| `src/ui/hand_controller.gd`（**继承 `RefCounted`，不继承 `Control`**） | 全部逻辑：给定「快照 + 手牌张数 + 一次点击」→ 返回「要做什么」。**只有它需要被测试覆盖** |
| `tests/pending/ui_hand_flow_test.gd` | 覆盖 controller |

`src/ui/card_view.gd` 已交付（`set_card(dict)` 换卡、`CARD_W=168` / `CARD_H=228`）。

#### 验收

| # | 判据 |
|---|---|
| 1 | 注入 1 / 4 / 9 张假快照，`hand_controller` 返回的「每张卡宽度 / 可见张数」断言正确 |
| 2 | 窗口里 4–9 张不重叠、不溢出屏（9 张 = `Battle.MAX_HAND` 满手牌不挤压） |
| 3 | `opening_phase` 为真时出现「换牌」按钮，点选 ≤N 张 → 调 `mulligan("player", 选中)` → 手牌刷新 |
| 4 | 选中切换的返回值正确（同一次点击两次 = 取消） |

#### 坑（3 条）

1. **逻辑必须在不继承 `Control` 的类里**。现有 17 个测试都是 `extends SceneTree`，主循环不跑，
   `Control._ready()` / 布局完全不执行 → 对 `Control` 写断言必然测不到东西（要么全空，要么 `is_inside_tree()` 假）。
2. **不要在 `_process` 里每帧重建卡面**。回合制本来不该有逐帧逻辑；只在状态签名变化时重建。
   签名可以是 `turn + energy + hand.size() + 存活单位数 + 双方 HQ 血量`。
3. **9 张是硬上限**（`Battle.MAX_HAND`）。手牌区要按「最坏情况 9 张」算卡宽，别按 4 张算。

### 37.5 M4.3 出牌交互

#### 规则（一句话）

点牌 → 高亮合法目标 → 点目标 → 调 `play_card` → 刷新；中途可取消。

#### 要改哪里

`src/ui/play_controller.gd`：一个三态状态机 `idle / card_selected / target_selected`，
入参是「快照 + 点击事件」，返回值是「要调 `play_card` 还是什么都不做」。合法目标集一律来自 `legal_targets`。

#### 验收：`tests/pending/ui_play_flow_test.gd`

| # | 断言 |
|---|---|
| 1 | 合法路径 4 步（点牌 → 点目标 → 出牌成功 → 回 idle） |
| 2 | 非法目标被拒，且 **`play_card` 一次都没被调用** |
| 3 | 右键 / ESC 回 idle 且选中态清空 |
| 4 | 出牌成功后手牌 −1、能量下降、日志新增 ≥1 行（对照 `snapshot()`） |
| 5 | 能量不够的牌点不动（不能进入 `card_selected`） |

#### 坑（3 条）

1. **「调了几次 `play_card`」必须能断言**。测试里用一个假 `Battle` 或计数器，别真的去打真对局 ——
   否则「非法目标被拒」和「合法目标成功」看起来一样。
2. 别在 UI 里判断「能量够不够」。那是 core 的规则，`legal_targets` 已经隐含了它。
3. 取消路径要清干净所有中间态，否则下一次点牌会带着脏状态。

### 37.6 M4.4a 战场只读

#### 规则（一句话）

把三条线 × 5 格画出来，HQ 单独样式，单位带攻防血与已行动标记。**先只读，不做交互。**

#### 要改哪里

`src/ui/board_view.gd` + `src/ui/unit_view.gd`。线顺序严格 `Board.LINES`
（`["enemy_support", "front", "player_support"]`），HQ 落在支持线的 `HQ_SLOT == 0`，其余 4 格。

#### 验收：`tests/pending/ui_board_view_test.gd`

| # | 断言 |
|---|---|
| 1 | 用构造快照断言「哪个 `(line, index)` 渲染到哪个格」的映射表，**3×5=15 个位置无错位** |
| 2 | HQ 只出现在两条支持线的 0 号格，不占 `UNIT_SLOTS_PER_SUPPORT` 的 4 格 |
| 3 | `has_moved` / `has_attacked` 为真时单位有可见标记（灰化或角标）——截图对比开/关两态 |

#### 坑（3 条）

1. **`HQ_SLOT == 0`，支援线 0 号格是 HQ，不是单位格**。画成「5 个平级格子」是这块最常见的错。
   参考 `tests/` 里那个老坑：`board.place(unit, "player_support", 0)` 会**静默返回 false**（格子被 HQ 占着）。
2. **线顺序不能按「上中下舒服」排**，必须按 `Board.LINES` 的顺序来，否则敌方/我方上下颠倒。
3. **只读块不要顺手加点击**。带着交互一起调，出错时分不清是「画错了」还是「点错了」——
   这就是为什么 M4.4 要拆成 a / b 两半。

### 37.7 M4.4b 战场交互

#### 规则（一句话）

选中己方单位 → 高亮可移动 / 可攻击的格 → 点下去 → 调 core 的方法。

#### 要改哪里

`src/ui/board_controller.gd`（状态机），高亮集合**必须**来自 `legal_moves` / `legal_attacks`。

#### 验收：`tests/pending/ui_board_flow_test.gd`

| # | 断言 |
|---|---|
| 1 | 选中己方单位 → 高亮格集合 **== `legal_moves` 集合**（不多不少） |
| 2 | 点格 → `move_unit` 被调用一次，参数是 `(unit, to_line, to_index)` |
| 3 | 攻击路径同理，目标集 == `legal_attacks`；打 HQ 也能选中 |
| 4 | 召唤失调的单位能选中但无高亮，点空白处取消 |

#### 坑（3 条）

1. **「不多不少」是双向断言**。只断言「`legal_moves` 里每个都高亮了」会漏掉「多高亮了非法格」，
   而那才是真 bug（玩家点了被打回来）。
2. **召唤失调 ≠ 不能选中**。要能选中看信息，只是不能行动。
3. 攻击 HQ 走的是 `legal_attacks` 里返回的那条路径，别在 UI 里特判「打 HQ」。

### 37.8 M4.5 回合流转与结算

#### 规则（一句话）

能量条 / 回合数 / 结束回合按钮 / AI 回合遮罩 / 胜负结算面板。

#### 要改哪里

`src/ui/turn_bar.gd`、`src/ui/result_panel.gd`、`src/ui/turn_controller.gd`。

#### 验收

| # | 判据 |
|---|---|
| 1 | 点「结束回合」→ `end_turn()` → 循环 `ai_step()` 直到对方回合结束 → 回到玩家回合，**全程 UI 不卡死** |
| 2 | AI 行动期间输入被遮罩（点牌无效） |
| 3 | `is_over()` 为真时弹结算面板，文字取 `outcome()`（WIN / LOSE 都要能显示），按钮「再来一局 / 回主菜单」可用 |

#### 坑（2 条）

1. **AI 回合要真的把控制权交还主循环**。用 `await` 或分帧，别在一个 `_on_pressed` 里同步跑完整个 AI 回合 ——
   那样窗口会假死，玩家看不到任何 AI 动作。
2. 结算面板出现后要**停掉输入**，否则玩家能继续点棋盘。

### 37.9 M4.6 动画与反馈（可整体关闭）

#### 规则（一句话）

伤害跳字、攻击位移、出牌飞入、回合横幅 —— **全部可 `await` 也可跳过**，且关掉不影响任何结算。

#### 要改哪里

`src/ui/fx.gd`：`play_damage / play_attack / play_card_fly / play_turn_banner`，
全部先看 `fx_enabled`，为 false 立即 return；为 true 时用 `Tween`。

#### 验收

| # | 判据 |
|---|---|
| 1 | `fx_enabled = false` 时所有动画函数立即返回；跑一局 `turn` 数与无动画版本一致 |
| 2 | **动画期间数据已落地**：先改数据再播动画，所以关掉动画不改变任何结算结果 |
| 3 | 连续快速点两次出牌不会重复触发动画（防重入） |

#### 坑（2 条）

1. **顺序反了是这块的经典 bug**：先播动画再改数据，一旦动画被打断（关掉、切场景），
   数据就停在半路 —— 出现「血条不动但单位死了」。
2. Tween 是最容易随布局改动反复重做的一层，所以放在功能稳定之后（M4.3/4.4b/4.5 之后）。

### 37.10 M4.7 主菜单 / 关卡选择

#### 规则（一句话）

启动进主菜单：新游戏 / 继续（有存档才亮）/ 设置 / 退出；关卡列表从 `data/tables/enemies.json` 生成。

#### 验收

| # | 判据 |
|---|---|
| 1 | 启动进主菜单；四个按钮状态正确 |
| 2 | 关卡条目数 == `enemies.json` 数据条数（**改 JSON 后重启界面跟着变**，不许写死） |
| 3 | 选关 → 进场 → 打完 → 回主菜单，三场景来回切 3 次 `is_instance_valid` 检查通过 |

#### 坑（2 条）

1. **UI 里不许出现中文卡名 / 关卡名字面量**。全部从 `data/` 读，这是 `docs/architecture.md` 的禁令之一，
   `preflight` 第 `[9]` 项会查 `src/ui/` 里的裸字段读取，但中文字面量要人工看一眼。
2. 场景切换要 `queue_free()` 干净，否则旧场景的 `Tween` 还在跑。

### 37.11 M4.8 设置

#### 规则（一句话）

音量、动画开关、语言（v1 只有中文，占位），存 `user://settings.cfg`。

#### 验收

| # | 判据 |
|---|---|
| 1 | 改动后立即生效并写入 `user://settings.cfg`；重启后读回（配置文件内容可机器比对） |
| 2 | 音量走 `AudioServer.set_bus_volume_db`，静音时 `0` 不报错 |
| 3 | 语言下拉只有「简体中文」且不崩溃；选其它值不会写坏配置 |

#### 坑（1 条）

**`res://` 打包后只读**。`FileAccess.open("res://settings.cfg", WRITE)` 在编辑器里能过、导出后必失败
（而且是在玩家机器上失败）。一律 `user://`，落在 `%APPDATA%\Godot\app_userdata\<项目名>\`。

### 37.12 M4.9a 存档：结构 + 读写 + 校验

#### 规则（一句话）

存「重建一局所需的最小信息」，不存整个 `Battle`。

#### 要改哪里

`src/core/save_system.gd`：`SAVE_VERSION := 1`、`save_game(state: Dictionary, slot: int) -> bool`、
`load_game(slot: int) -> Dictionary`、`has_save(slot: int) -> bool`。存档内容 = `snapshot()` 的子集 + 关卡/牌组 id。

#### 验收：`tests/pending/save_test.gd`（≥10 项）

| # | 断言 |
|---|---|
| 1 | 存 → 读，内容深比较一致 |
| 2 | 版本号写入正确 |
| 3 | 缺字段被拒（返回空字典 / false，不崩） |
| 4 | 落盘路径是 `user://saves/slot1.json`（打印实际路径人工看一眼） |
| 5 | `core/` 里不出现任何 `Control`（`preflight` `[9]` 会查） |

#### 坑（2 条）

1. **不要序列化整个 `Battle`**。里面有 `Card` / `Unit` / `Board` 三层引用，直接序列化等于把 core 的内部
   结构钉死成文件格式，以后改字段就要写迁移。
2. **`user://` 不是 `res://`**。见 37.11 坑 1。

### 37.13 M4.9b 存档：版本迁移 + 损坏兜底

#### 规则（一句话）

旧版本存档能升上来，坏存档不崩、备份、重置。

#### 要改哪里

`src/core/save_system.gd` 加 `_migrate(from: int, data: Dictionary) -> Dictionary`，
以及「读失败 → 备份成 `*.bad` → 返回空 → 界面提示」这条兜底链路。

#### 验收：`tests/pending/save_migrate_test.gd`（≥8 项）

| # | 断言 |
|---|---|
| 1 | v0 假档能升到 v1 |
| 2 | 未知**高**版本被拒（返回空，不是崩溃） |
| 3 | 手工把存档改成乱码 → 不崩、自动备份 `*.bad`、提示「存档损坏已重置」 |
| 4 | 迁移用的是**测试内构造的旧档**，不依赖仓库里留旧文件 |

#### 坑（1 条）

**迁移测试要在测试里构造旧档**，不要往仓库里提交一份 `slot1.v0.json` 当夹具 —— 那份文件会过时，
而且没人知道它对应哪个字段版本。

---

## 38. M4 全阶段通用规矩（每块都适用）

### 38.1 统一开工 / 收工动作

M4 每一块都按同一个模板走，不要临时发明流程。目的是把「返工轮数」压到 1 轮以内 ——
M3 的实测已经证明，日历进度的瓶颈是 round-trip 次数，不是打字速度。

| 阶段 | 动作 | 判据 |
|---|---|---|
| 开工前 | 报预计用时：`预计 X–Y h（依据：§37.N 难度 ★★ + 交付物 N 个文件）` | 与 §37.0 表对得上；对不上先说清为什么 |
| 开工前 | 跑一次 `run_tests.bat`，确认基线全绿 | 拿到「改动前」的绿，否则以后分不清是谁弄红的 |
| 写代码 | 只碰本块「交付物」列出的文件；**想改别的文件先停下来说明** | `git status` 里不出现计划外文件 |
| 自测 | 本块的 `tests/ui_*_test.gd` / `save_*_test.gd` 绿；无 `[FAIL]`、无 `SCRIPT ERROR` | **退出码 0 不等于通过**，必须看终端输出 |
| 收工 | `run_tests.bat` 全绿 + 三条验收判据逐条打勾 + 截一张图 | 三项都齐才算 done |
| 收工 | 记录实际用时；偏差 >2 倍时写一句原因 | 便于下一块继续校准 |

**测试落位沿用 M3**：新测试先写进 `tests/pending/`，主套全绿后 `git mv` 到 `tests/` 才启用；
启用时同步文件末尾的 `EXPECTED_CHECKS`。不要让 UI 阶段出现「测试写在 pending 里躺了三块」。

### 38.2 M4 完成判据（8 条，全部同时成立）

| # | 判据 | 怎么验 |
|---|---|---|
| 1 | 能开窗口用手打完一整局：主菜单 → 选关 → 打完 → 结算 → 回主菜单，不报错不卡死 | 人工 3 局（赢 1 / 输 1 / 中途退出 1） |
| 2 | 中文全部正常 | `tools/check_font.gd` 退出 0 + 3 张截图 |
| 3 | 能存能读：关掉重开，「继续」回到存档点 | 存档在 `user://`，读回后 turn / 血量 / 手牌一致 |
| 4 | 坏档不崩：提示 + 备份 + 重置，游戏能继续 | 人工 1 次（出现 `*.bad`） |
| 5 | `run_tests.bat` 仍 ALL GREEN，新增测试已从 pending 迁出 | `===== ALL GREEN =====` |
| 6 | core 里没有界面代码，UI 无裸字段读取 | `preflight` 第 `[9]` 项 PASS |
| 7 | 数据全部来自 `data/`：`src/ui/` 里没有中文卡名 / 关卡名字面量 | 人工 `grep` 一眼 |
| 8 | 文档同步：本节进度表打勾、`HANDOFF` 更新、`README.md` 写明「怎么开窗口玩」 | 人工读一遍 |

### 38.3 M4 明确不做（防止范围膨胀）

多语言全量翻译、联网 / 对战、美术资源（卡面图 / 立绘）、关卡编辑器、平衡调参、
音效、新手引导、导出打包 / 商店页 / 演示 GIF（M5）、重构 core。

### 38.4 三条「看着更快的错路」

| 错路 | 为什么看着快 | 实际后果 |
|---|---|---|
| 先做交互再做布局（跳过 37.6 直接做 37.7） | 「反正最后都要点」 | 布局改 3 次 → 坐标硬编码的点击判定跟着改 3 次 → 每轮都要人工点一遍，返工量比先做只读大得多 |
| UI 直接读 `battle.hand` / 直接调 `_ai()`（跳过 37.2/37.3） | 省 2–3 h | core 从此被 UI 钉死：改手牌容器、给 AI 加流派，每次都要连带改 UI。M3.6 元素 v3 就是因为早期结构没抽象才改那么久 |
| 一次把 11 个界面全搭出来再统一调 | 「先把架子搭完」 | 字体 / 主题 / 刷新策略任何一个定晚了，5 个界面一起返工；而且没有一块是可验收的 |

**一条反向判据**：如果某一块做完，你**没法用一条命令或一个截图证明它成了**，说明这块切大了 —— 回去拆。

---


## 39. M3.4 前置：AI 选目标（清 M3.2 遗留）· ✅ 已完成 2026-11-27

> **结论：已完成。** 主套 19 文件 **499/499**，`ai_guard_test` **14 项**已启用。落地数据见 §39.9。
> 开工原文（教训细节）已归档：git 历史 + `docs/HANDOFF-2026-11-23.md` §23。

### 39.0 为什么做这一块

M3.2 的 AI 选目标标准是「**不是 guard**」而不是「**没被保护**」。真实卡池出现 guard 卡后，
AI 会为了打一个被保护的 victim 白扔整个回合。M3.4 正在往卡池里加真实 guard 卡，
所以必须先清掉 —— 否则加完 guard 卡，平衡模拟会跑出一堆「敌方整回合不动」的局，读数全是废的。

### 39.1 规则（S1–S6，跨块复用）

| 编号 | 规则 |
|---|---|
| S1 | AI 的单位只要还有合法目标，就必须真的打出去，**不允许空过一整个回合** |
| S2 | 优先级：**敌方 HQ（可达且未保护）> 未保护的非 Guard 单位 > Guard 本身** |
| S3 | 被 Guard 保护的友军**永远不该被选成目标**（打了必被拒 = 白扔） |
| S4 | Guard 本身**永远是合法目标**（Guard 之间互不保护） |
| S5 | `_is_guarded()` 对不在场上的单位返回 `false`，**不能崩** |
| S6 | 目标清单扫**全部三条线**（`Board.LINES`），不能只扫 `front` |

### 39.1a S2 的三档定义（判定顺序不能乱）

| 档 | 装什么 | 怎么写 |
|---|---|---|
| 0 | 敌方 **HQ** | 先 `out.append(_opposite_hq(owner))`；**HQ 被保护也照样进档 0**，让 `attack_unit` 去拒，拒了自动落档 1/2 —— 这就是 S1 的实现方式 |
| 1 | 不受保护的**非 Guard** | `if u.is_guard(): guards.append(u)  elif not _is_guarded(u): out.append(u)` |
| 2 | 敌方 **Guard** | 同一个 `guards` 数组，最后 `out.append_array(guards)` |

排除项：己方、`null`、`u.is_hq`、**被保护的非 Guard**。**必须先判 `is_guard()` 再判 `_is_guarded()`**。
档内不排序（按 `units_in()` 的格子下标升序，稳定可复现）。

### 39.1b 实现路线：三个桶，不要堆

实测单次耗时：扫三条线收集 12.63 µs、复制 + `sort_custom` 排 15 项 36.08 µs、三桶 `append` 9.73 µs。
`sort_custom` **不稳定**（实测全同优先级输入 n≥17 起开始乱序），棋盘上限 14 碰不到，但那是运气不是保证。
清单**每次现算、不缓存**（`_is_guarded()` 依赖当前局面）。

### 39.2 病灶（`src/core/battle.gd` 原 157–168 行）

| 分支 | 病灶 |
|---|---|
| `has_unit_of("front") == owner` | 一律 `attack_unit(u, _opposite_hq(owner))`，**返回值没人接** → HQ 被保护时整个单位白过，不换目标、不报错、无日志 |
| `has_unit_of("front") == _opposite(owner)` | `find_first_attackable()` 筛的是「不是 Guard」，对方前线全是 Guard 时返回 null → **全队 `break`** |

结构性根因：`if/elif` 用「前线归谁」当总开关，**前线空 / 两边都有 → 一个都不打**。

### 39.3 要改哪里

- `src/core/battle.gd`：① `_is_guarded()` 开头补 `target == null`、`position_of` 之后补 `tmp.is_empty()`（取下标**之前**）；② `_ai()` 攻击段换成「遍历三条线所有己方攻击手 → 每人拿同一份清单依次试」；③ 新增 `_ai_attack_targets(owner) -> Array[Unit]` 与 `_ai_attack(u, owner) -> bool`。
- `src/core/board.gd`：**不动**。`find_first_attackable()` 保留（它已是「被抛弃的旧副本」，但 `guard_test` 没断言它，删了没好处）。

### 39.4 验收（`tests/ai_guard_test.gd`，14 项，2026-11-27 已启用）

| # | 断言 | 项数 |
|---|---|---|
| [1] | 玩家 HQ 被 Guard 保护 → AI 改打 **Guard 本身**，且 `has_attacked == true` | 4 |
| [2] | 玩家前线只有 Guard → 敌方支援线单位打这个 Guard，HQ 不掉血 | 3 |
| [3] | 被保护的 victim 一点血不掉，Guard 掉血 | 3 |
| [4] | 同线「Guard + 普通单位」→ 优先打普通单位，Guard 不挨打 | 3 |
| [5] | 不在场上的单位 `_is_guarded()` 返回 false，无 `SCRIPT ERROR` | 1 |

`validate_data` PASS；`balance_sim --games 200 --seed 1` → 45.0% / 13.4 / 0%（**与改动前逐位相同**；13.0 是历史笔误）。

### 39.5 三条跨块通用的坑

1. **`attack_unit()` 的返回值必须接**。GDScript 不报「你没用返回值」，只有测试能抓 —— 整个缺陷的根。
2. **别写 `while not attack_unit(u, 同一目标)`**。参数没变返回值就不会变，那是死循环（实测挂死 30 s）。
3. **类型化数组会「假红」**：`-> Array[Unit]` 里返回无类型 `Array` 报 `SCRIPT ERROR`，**而且内容一起丢**（返回空数组），看起来像「一个目标都没有」。

（另有 7 条已并入本文 §「已完成块留下的硬规矩与坑」，原文见 git 历史 §39.5。）

### 39.6 第一轮评审（2026-11-27，针对当时学员 WIP）

| 学员改的地方 | 状态 | 一句话 |
|---|---|---|
| `_is_guarded()` 两个守卫（S5） | ✅ 对 | 那条 SCRIPT ERROR 已经消失 |
| `cards.json` 加两张卡 | ✅ 对 | 15 种 / 57 张 |
| 「三个桶」思路 | 🟡 半对 | 骨架出来了，但装错了、拼错了、返回错了 |
| `_ai()` 攻击段 | ❌ 错 | 第一分支死循环、第二分支根本没改 |
| `_ai_attack()` | ❌ 空壳 | 直接 `return false`，红基线与原始一模一样 |

**`_ai_attack(attacker, owner)` 的正确职责（一句话）**：向目标清单要一份按优先级排好的敌方目标列表，
从前往后依次 `attack_unit`，**第一个成功就 `return true`**，全失败 `return false`。
**AI 里不要再复述一遍选目标规则**，复述 = 同一套规则两个副本，迟早分歧（`find_first_attackable` 就是那个被抛弃的副本）。

**为什么「再试一次」永远不可能成功**：`attack_unit` 拒一次之后局面没有任何变化 —— 被保护还是被保护、
够不着还是够不着。要换的是**目标**，不是重试次数。

### 39.7 五条实测红绿指纹（改完自己对照）

| # | 故意改成 | `ai_guard_test` 结果 |
|---|---|---|
| A | `_ai_attack` 直接 `return false` | **6 红**，与原始基线逐条相同 |
| A' | 只试清单第一个目标 | **6 红**，同上（「不换目标」=「不实现」） |
| B | 判定顺序写反（先判保护再判 Guard） | **[4] 红 2 项**：`优先打普通单位（5 → 2）（期望 2，实际 5）` + `Guard 这一回合没被打（期望 6，实际 3）` |
| C | 档 0 先过滤「HQ 被保护就不入列」 | **14/14 全绿** —— 测试区分不出这两种写法；选「不过滤」只因让 `attack_unit` 当唯一权威 |
| D | `_is_guarded` 恒 `return true` | **[1][3][4] 红** —— 证明测试真的在判保护，不是自证 |

### 39.8 施工背景（三个对象的能力边界）

| 对象 | 有什么 | 没有什么 |
|---|---|---|
| `Board` | `LINES`、`units_in`、`position_of`（不在场上返回 `[]`）、`unit_at`、`find_first_attackable`（**筛法不符合 S2**） | 不知道怎么算「被保护」（那是战斗层） |
| `Battle` | `_is_guarded()`（权威判据）、`_opposite_hq()`、`_energy_of()`、`attack_unit() -> bool` | 没有现成的「合法目标清单」 |
| `Unit` | `can_attack()`、`operation_cost`、`is_guard()`、`owner`、`is_hq` | 不知道自己被不被保护 |

**选路线 A**（一个函数出清单 + 一个函数依次试），没选「每个分支各写一遍兜底」—— 后者的第一分支打完 HQ 要接返回值换目标、
第二分支要把 `find_first_attackable` 换成三档筛选，等于同一套规则写两遍。

### 39.9 落地记录（2026-11-27 完成，学员实现 + 教练核验）

| 项 | 结果 |
|---|---|
| `run_tests.bat` | **ALL GREEN 19 file(s)**、`[详细自检] PASS（14 项）`、退出码 0 |
| 主套 | **499 项 / 0 红** |
| `validate_data` | PASS（15 种 / 57 张，两 deck 各 39） |
| `balance_sim --games 200 --seed 1` | 45.0% / 13.4 / RUNNING 0% —— 与改动前**逐位相同** |
| 反假绿 B（判定顺序写反） | **2 红**，与 §39.7 指纹完全对上 |
| 反假绿 D（`_is_guarded` 恒 true） | **8 红**（[1]–[5] 全炸；比参考实现多 3 项，因为学员版也用它做前置筛选，方向正确） |

---

## 40. M3.4 卡池 20+ 种（数据块 · 创意归学员）· ✅ 已完成 2026-11-27

> **结论：已完成。** 卡池 **15 种 / 57 张 → 20 种 / 68 张**，`validate_data` 0 错 0 警，主套全绿。

### 40.0 这块和其他块不一样在哪

**测试不会因为你加卡而变红，也不会因为卡设计得好而变绿**（见 §40.4 实测）。
创意是学员的活（BACKLOG A7 🎨）；教练侧只负责三件事：数据规则不被破、测试断言动态推导（§40.3）、
balance 判据写清（§40.4）。**教练不代写卡牌创意，也不给「你就做成这样」的成品条目。**

### 40.1 目标（开工时 → 完成时）

| 项 | 开工（15 种 / 57 张） | 完成（20 种 / 68 张） |
|---|---|---|
| 卡牌种类 | 15 | **20** ✅ |
| 展开张数 | 57 | **68**（单位 40 + 指令 28） |
| 指令 / 单位 | 7 / 8 | 7 / **13** |
| 兵科 | infantry 4 / tank 1 / artillery 1 / fighter 1 / bomber 1 | infantry 7 / tank 2 / artillery 2 / fighter 1 / bomber 1 ✅ |
| 关键词 | `blitz` 2 / `guard` 1 | `blitz` **4** / `guard` 1（Guard 仍只 guarder 一种） |
| 元素 | fire 3 / water 1 / lightning 2 / ice 1 / geo 1 / **wind 0** / none 7 | fire 4/13、geo 2/5、ice 1/2、lightning 3/9、**wind 1/3**、water 2/8、none 7/28 ✅ |

### 40.2 数据硬规则（`tools/validate_data.gd`，一条都不能破）

- `type` ∈ `unit` / `order`（漏写会被 `Card.from_dict` 默认成 `order`）。
- `cost >= 0`；`count > 0` 且 **`count <= limit`**（per-card，缺省 4）。
- `element` ∈ `none / fire / water / lightning / ice / wind / geo`（**复合元素 v3 起已删除，写就报错**）。
- 单位卡必须有 `attack >= 0`、`defense >= 0`、`unit_class` ∈ `["", infantry, tank, artillery, fighter, bomber]`。
- 指令卡 `kind` ∈ `damage / shield / heal`。
- `keywords` 只认 `blitz` / `guard`；未知词只 warning —— **拼错 `blitzz` 不会红，只会静默变成一张没关键词的卡**。
- `data/decks/*.json` 不用动（新卡不进 deck 完全合法）；decks 只校验 39 张 + 每卡 ≤ 自己的 `limit`。

### 40.3 教练侧已经证明：加卡不会弄红任何测试

- `tests/data_test.gd` 的牌库断言**动态推导**（自己读 `cards.json` 按 `count` 累加算 expect），`EXPECTED_CHECKS` 与卡数无关。
- 全仓库搜「57 / 49 / 15」搭配「张 / 种」**零命中**，没有硬编码卡数。
- 实证：连加 7 张 → 22 种 83 张，`run_tests.bat` **19 文件全绿**。
- 一个副作用：17 个测试用 `DataLoader.load_cards()` 当牌堆，加卡后牌序会变，但断言不依赖牌序（已实证）。

### 40.4 一条必须先知道的实测结论：`balance_sim` 对卡池**零敏感**

| 卡池 | `deck=` | 结果（`--games 200 --seed 1`） |
|---|---|---|
| 15 种 57 张（开工时） | 29 张 | `WIN 90 / LOSE 110` · 45.0% · 13.4 回合 · 0% |
| 22 种 83 张（+7 张正常卡） | 55 张 | **一模一样** |
| 再 +3 张明显破坏平衡的卡（atk9/def9、atk99/def99 带 blitz、atk20/def20） | 59 / 63 张 | **还是一模一样** |
| **20 种 68 张（实际交付）** | **40 张** | **还是一模一样** ✅ |

根因（已定位到行）：
- `src/core/battle.gd:51-54` `setup()` 把 `p_deck` 复制进 `deck` 和 `enemy_deck` —— **双方同一副牌**。
- `src/core/battle.gd:110-111` `first_move = "enemy" if rng.randi_range(0,1) else "player"`。
- 探针实测 seed 1..200：**玩家先手 90 次 / 敌方先手 110 次**，恰好等于 `WIN 90 / LOSE 110`；40 局比对 `first_move` 与实际结果 **match=40 / mismatch=0**。

**即胜负 100% 由「谁先手」决定，卡池组成对结果零影响。**
所以加完卡 balance **应该**还是 45.0% / 13.4 / 0%，**它不变是正常的，变了才说明你动了别的东西**。
别为了「让 balance 好看」去调卡数值 —— 平衡归 M3.8（issue #5），而 M3.8 的前置是 M3.8a + 先手补偿。

### 40.5 缺口盘点（当时给学员的思路，已完成的部分打勾）

1. ✅ **wind 元素是 0** —— 已补 1 种（`wind` 风法师）。
2. 部分 —— 稀有度/费用曲线没铺开（cost 集中在 1–4，cost 5–8 只有 2 张）。
3. ❌ **Guard 只有 guarder 一种** —— 仍然只有 1 张，加卡时没补。
4. ❌ **指令卡仍是 7 种** —— 没有新增指令卡。
5. 部分 —— 兵科分布不均（infantry 7 种，fighter / bomber 各 1）。

### 40.6 加卡的两种手段

| 手段 | 适用 | 注意 |
|---|---|---|
| `tools/add_unit_card.gd`（CLI） | 加单位卡 | `--id --name --cost --attack --defense` 必填，`--element --count --unit-class --opcost --keywords --limit` 选填；**只插一行、尾逗号自动处理** |
| 手写 `data/tables/cards.json` | 加指令卡 / 想手工排版 | **必须无 BOM + LF**；写完跑一次 `validate_data` |

编码：20 种 / 68 张时文件 **3819 B / 无 BOM / 25 LF**（学员后来重排成多行缩进格式也合法，`card_lib` 已按卡块定位）。

### 40.7 验收（四条，必须同时成立）

1. `validate_data` **PASS**（0 错 0 警）。
2. `run_tests.bat` **全绿**，`[详细自检]` 项数 **13 或 14**（干净工作区 14，有未提交改动 13）。
3. `balance_sim --games 200 --seed 1` 仍是 **45.0% / 13.4 / RUNNING 0%**（见 §40.4，不变才是对的）。
4. `cards.json` **无 BOM + 全 LF**。

### 40.8 坑

1. 忘了写 `type: "unit"` → 被默认成 `order`，`load_cards` 不会报错，但战斗里当不了单位。
2. `count` 写超过该卡的 `limit` → `validate_data` 报错（不再是统一的 4）。
3. 元素写成 `electro_charged` / `frozen` → **v3 起直接报错**（复合元素已删除）。
4. `unit_class` 空串合法但 `preflight` 会 warn（要求全部单位卡都有兵科）。
5. 多行缩进的 `cards.json` 曾让 `tools/card_lib.gd` 的写回坏掉（已修，见 git 历史 `3668d2e`）。
6. `deck` 里放新卡要自己算 39 张，`_check_decks` 只校验张数不比你要不要用新卡。
7. 加卡后 `ai_guard_test` 等用真实牌堆的测试牌序会变，但断言不依赖牌序（§40.3）。

### 40.9 收工动作（✅ 学员已于 2026-11-27 完成）

跑四条验收 → 报告结果 → 教练侧更新进度表与 README/HANDOFF → 提交 `feat(data):` → 关 issue #2。

### 40.10 落地记录（2026-11-27）

5 张新卡：`wind` 风法师（cost3 / wind / atk2 / def5 / infantry / count3）、
`water` 水之幻形（cost1 / water / atk1 / def2 / infantry / blitz / count4）、
`fire_tree` 爆炎树（cost9 / fire / atk6 / def8 / artillery / count1 / **limit 1**）、
`ret` 若陀龙王（cost9 / geo / atk7 / def9 / tank / count1 / **limit 1**）、
`dog` 忍犬（cost4 / lightning / atk5 / def2 / infantry / blitz / count2 / **limit 2**）。

四条验收全过：`validate_data` PASS（0 错 0 警 / 20 种 / 68 张）、`run_tests.bat` ALL GREEN 19 文件、
`balance_sim` 仍是 45.0% / 13.4 / 0%、`cards.json` 3819 B / 无 BOM / 25 LF。
commit `6d97374`，issue #2 已回帖并关闭。

---

## 41. M3.6 元素 v3（多槽附着）+ 每张卡独立上限 · ✅ 已完成 2026-11-27

> **结论：已完成。** 主套 **20 文件 560/560**，`aura_v3_test` **59 项**已启用。落地记录见 §41.7。

### 41.0 这一块和以往不一样在哪

**这是唯一一块把 `src/` 交给子 agent 写的**（用户 m02281 当时明确授权）。事后（2026-11-27）用户指出
「你造 tools 或测试用途的代码可以让子 agent 实现，而不是直接用子 agent 帮我写代码」，
于是 `src/` 派活被定为**硬规则禁止**（HANDOFF §2.1）。M3.6b 起 `src/` 全部由学员本人写。

### 41.1 两条已拍板的设计决策

1. **多槽（≤3）而不是单槽**：单槽无法表达「水火共存 → 再打雷」这类局面，也是感电/冻结只能靠复合 id 糊弄的根因。
2. **感电 / 冻结改共存型**：`consume 0`，只挂状态（`shock` / `immobilized`），**两个槽都保留**，`electro_charged` / `frozen` 两个复合 id 删除。

### 41.2 给子 agent 的规格（当时的写法，可复用）

要点：①只改指定文件、②只读指定文件、③不 grep 全项目、④不跑测试、⑤**只能用 `edit` 工具**（严禁 PowerShell 重写 `.gd`）、
⑥产出必须无 BOM + LF + Tab + UTF-8。两个子 agent 分别是 `core-aura`（`element` / `unit` / `damage`）与 `battle-aura`（`battle.gd`）。
**收尾永远是教练的活**：子 agent 自报的 4 处疑点里 3 处是真 bug（死分支、`immune_source` 被覆盖、裸 `pop_front`），必须逐条核。

### 41.3 数据迁移

`elements.json` → `schema_version: 3`，只剩 6 个 base，每条加 `"duration": 2`，删 `electro_charged` / `frozen`；
`reactions.json` → `schema_version: 3.0`，`lightning+water` 与 `ice+water` 都改 `consume: 0.0` 并删掉 `aura` 效果，其余 12 条不动。

### 41.4 每张卡独立上限（per-card limit）

`Card.limit`（缺省 4，`Card.DEFAULT_LIMIT`）取代全局 `MAX_SAME_CARD = 4`。六处改动：
`card.gd`（字段 + `from_dict`）· `data_loader.load_deck()`（按 `catalog[id].get("limit", 4)` 比对）·
`validate_data._check_cards()` / `_check_decks()` · `card_lib.validate_unit()` / `blank_unit()` / `add_unit_card.gd --limit`。
**`count` 与 `limit` 语义不同**：`count` 是这张卡在卡池里的展开张数（`load_cards` 用），`limit` 是一副 deck 最多带几张。

### 41.5 迁移测试时踩到的四条真实行为（别再当 bug 修）

1. `tick_auras()` 只返回**本回合到期被移除**的元素，未到期的不在列表里 → 断言写 `not expired.has(FIRE)`。
2. **2U 火打 2U 水：水剩 1U，火残留 `2 − consume(1) = 1U` 也入槽**（v2 是「残留丢弃」，v3 变了）。
3. `_settle_status()` 每回合顺手 `tick_auras()` → dot 结算后 `duration` 已经少了 1。
4. `Board.HQ_SLOT := 0`（支援线 0 号格是 HQ），测试摆单位必须 `index >= 1`，否则 `is_hq` 跳过、dot 不掉血。

### 41.6 验收实测（干净工作区，2026-11-27）

| 项 | 结果 |
|---|---|
| `run_tests.bat` | **ALL GREEN 20 file(s)**、`[详细自检] PASS（14 项）`、退出码 0 |
| 主套 | **560 项 / 0 红** |
| 项数算式 | `499 − 4（battle_m1）+ 1（order）+ 3（status）+ 2（deck_build）+ 59（aura_v3）= 560` |
| `validate_data` | PASS（20 种 / 68 张） |
| `balance_sim` | 45.0% / 13.4 / 0%（逐位不变） |
| `tools/test_card_lib.gd` | 61 项 0 失败 |

### 41.7 落地记录

21 个文件（`src/core` 6 个 / `data` 4 个 / `tests` 9 个 / `tools` 5 个）分三批提交：
`96de50e feat(core)` · `1ad7268 feat(data)` · `0771099 test(m36)` · `2bc1c5f docs(m36)`。
`tests/pending/aura_v3_test.gd` 十段（槽基础 / 叠加封顶 / 槽溢出 / duration / 反应消耗 / 共存型 / 优先级 / 风岩 / 免疫与 dot / describe），
用 `Move-Item` 搬进主套（`tests/pending/` 不在 git 里）。

### 41.8 已知缺口（诚实记录，别当已实现）

1. 反应里的 `damage` / `shield` / `heal` 三种 effects **代码至今未接**（数据里有，是历史死数据；补上会改平衡基线）。
2. `_apply_aura` 里 `Duration` 只按 `amount > 1 → 3 回合` 粗分，没有数据驱动的「强附着」字段。
3. `MAX_AURAS = 3` 是硬编码常量，数据里没有可配项。
4. 附着到期只在回合末日志里体现，UI 侧还没有可视化（M4 的活）。

### 41.9 坑（这一块踩到的新坑）

1. **子 agent 会自己「顺手优化」**：给 `tick_innate_shield` 用裸 `pop_front()`、把并列 `if` 写成恒真的 `elif` —— 必须逐行读它的 diff。
2. **`get_aura()` 返回 `{}` 不是 `null`**：断言写 `not x.is_empty()`，别写 `x != null`。
3. **`tests/pending/` 不在 git 里**，`git mv` 会报 `fatal: not under version control`，要用 `Move-Item`。
4. **`.gd.uid` 要跟着一起搬**，否则留孤儿。
5. **PowerShell 整篇重写 `.gd` 会毁文件**（BOM + CRLF + 中文乱码 → `Parse Error`）。

### 41.10 下一步

M3 剩下：**魔物元素盾（§42，当前块）** → **M3.8a（AI 打指令卡，#4）** → **M3.8 平衡调参（#5）** → **M3.9 收尾 tag v0.3（#6）**。
注意 §40.4 的结论：平衡调参的前置是**先手补偿**，否则怎么调都是 45%（先手 90/200 的随机结果）。

---

## 42. 魔物元素盾：自带元素吸收层（**不是免疫**）· 2026-11-27

> **本节是这一块的唯一文档。** 不再新建 `brief-*.md` / `review-*.md`（见文件头「文档纪律」）。
>
> **2026-11-27 19:0x 重大修正**：本节初版把元素盾写成了「免疫的变体」（新增 `immune_source = "shield"`、
> 改 `is_immune()` 语义）。**用户指出这是错的**，原话：
>
> > 「疑问：魔物的护盾确实不会被同属性元素破坏，这并不是静态免疫」
>
> 已按「独立吸收层」重写：§42.1 说明原方案错在哪，§42.2–§42.13 全部替换。
> **此前按旧版写的代码（`is_static_immune` / `immune_source` / `is_immune` 改语义）要按 §42.13 第 1 步回退。**

### 42.0 需求与已拍板决策

用户在 M3.6 完成汇报后提问：

> 「自己给自己挂元素例如深渊法师护盾、史莱姆等应当具有免疫，同时也会反应，这一点如何做到？」

**第一轮拍板（m03202）**：① 按讨论方案定规格；② 护盾 **3 回合重生**。

**第二轮拍板（m03376，本块的定稿依据）** —— 用户给了参考文章
（[米游社《原神元素护盾机制》](https://www.miyoushe.com/ys/article/25366671)）并要求简化：

1. **只由反应破盾** —— 破盾量 = 「盾的元素量 × 系数」，系数参照元素反应类型设计；
2. **物理攻击是特殊的** —— 可以**少量**削盾；
3. **盾的元素量直接决定能挡多少伤害** —— 所以盾量上限要适当放大（普通附着 2U 的上限**不适用**于盾）；
4. 可以引入一般浮点数，**显示保留 2 位小数**；
5. 数据样本：**火史莱姆改回静态免疫**，另加一个**带水盾的法师**（冰/岩史莱姆的再生护盾以后再说）。

### 42.1 为什么「盾」不能当成「免疫」（初版方案的错，务必先读）

| | 静态免疫 | 元素盾 |
|---|---|---|
| 本质 | **属性**（有 / 没有） | **资源**（还剩多少） |
| 会不会变 | 永远不变 | 被消耗、破掉、重生 |
| 破了以后 | 不存在「破」 | 掉血，进入真空期 |
| 谁在挡 | 元素豁免（连反应都不算） | 吸收池（反应照算） |
| 判定位置 | `Damage.compute()` 最前面短路 | 伤害结算里、反应算完之后 |

初版把盾写成 `is_immune()` 的第二个来源，后果有三条：

1. **反应根本算不出来**：`reaction_slot` 被置 -1，`consume` 恒为 0 → 盾没有「被啃薄」的过程，只能一刀归零。
2. **破盾瞬间表现像开关**：盾在 = 免疫火，盾破 = 怕火。玩家看到的是「免疫消失」，而不是「盾碎了」。
3. **`is_immune()` 语义被污染**：`_apply_aura()` 的跳过判断、`is_immune` 的四处既有测试全被带偏，
   而它们本来都是「静态免疫」的意思。

**结论**：`immunities` / `is_immune()` **一个字都不改**；盾是一层独立吸收，判定落在「伤害结算」，不在「免疫豁免」。

### 42.2 三种「额外血条」的对照（原 §42.2b 合并进来）

三种盾机制不同，但**都不是免疫**：

| | ① 魔物元素盾（**本块实现**） | ② 结晶盾 | ③ 技能盾 |
|---|---|---|---|
| 原神对应 | 史莱姆/深渊法师的元素护盾 | 岩元素结晶生成的护盾 | 角色技能护盾 |
| 数据载体 | `auras` 槽 `innate: true`，槽的 `amount` **就是盾量** | `Unit.shield: int` | `Unit.shield: int` |
| 挡什么 | 盾在时**吸收全部伤害**（不分元素） | 全部直接伤害 | 全部直接伤害 |
| 怎么掉 | **反应**按系数削；**物理**少量削；同元素/无反应元素**不削** | 打空为止 | 打空为止 |
| 会不会重生 | **破盾后 3 回合重生** | 不重生 | 不重生 |
| 判定位置 | 伤害结算**最前面**（反应算完之后） | `take_damage` 内先扣盾后扣血 | 同左 |
| 引擎现状 | 全新，本块实现 | `shield` 字段与扣盾顺序已存在；缺的是 geo 反应的 `shield` 效果实装（现为死数据） | 缺 `kind: "shield"` 指令卡（有分支、缺卡） |

**吸收顺序**：元素盾 → 数值盾（`Unit.shield`）→ HP。三者互不干扰。

**②③ 的排期不变**：② 结晶盾 → M3.8 平衡块（激活 `reactions.json` 里 4 条结晶的 `shield 2.0` 死数据会改平衡基线）；
③ 技能盾 → M3.8a AI 打指令卡（先有卡和分支，AI 才有得选）。

### 42.3 数据结构与系数（**全部数值都在这张表，实现不许自己发明**）

**`Unit.auras` 每一项多一个可选键**：

```json
{ "element": "water", "amount": 12.0, "duration": 0, "innate": true }
```

| 键 | 说明 |
|---|---|
| `element` | 盾元素（决定「什么反应能削它」） |
| `amount` | **盾量**，单位 U，`float`，上限 `MAX_INNATE_AMOUNT := 20.0`（**不是** `MAX_AMOUNT` 的 2.0） |
| `duration` | 盾必须写 **0**（不按回合衰减，靠 §42.6 重生） |
| `innate` | `true`。缺省 `false`，所以现有卡牌/敌人数据与既有测试**一行都不用改** |

**`Unit` 新增常量**：

| 常量 | 值 | 含义 |
|---|---|---|
| `MAX_INNATE_AMOUNT` | `20.0` | 盾量上限（普通附着上限 `MAX_AMOUNT = 2.0` 不适用于盾） |
| `SHIELD_HP_PER_U` | `2.0` | 1U 盾量能挡 2 点伤害（即 12U 盾 = 24 点吸收量） |
| `INNATE_REGEN_TURNS` | `3` | 破盾后第 3 个回合开始重生 |

**`Unit` 新增字段**：

| 字段 | 类型 | 含义 |
|---|---|---|
| `innate_template` | `Array` | `from_dict()` 时把 innate 槽**深拷贝**存一份，重生照它恢复 |
| `innate_timer` | `int` | 距离重生还剩几回合；满盾时恒等于 `INNATE_REGEN_TURNS` |

**破盾系数表（`Unit.shield_break_rate()` 的唯一依据）**：

| 受击情况 | `k` | 说明 |
|---|---|---|
| 反应 `type == "amplify"`（蒸发 / 融化） | **3.0** | 克制元素，最快 |
| 反应 `type == "transformative"`（超载 / 超导 / 扩散） | **2.0** | |
| 反应 `type == "crystallize"`（结晶） | **1.5** | |
| 反应 `type == "coexist"`（感电 / 冻结，`consume == 0`） | **0.5** | 能磨，但很慢 |
| 物理：`element == Element.NONE` | **0.25** | 「物理少量削盾」 |
| 有元素但**没触发反应** | **0.0** | 包括**同元素**——这就是「同属性打不破」 |

> `type` 字段 `reactions.json` 里本来就有（`amplify` / `transformative` / `crystallize`），
> 感电/冻结目前写的是 `transformative` 但 `consume == 0` —— 判定顺序里**先看 `consume == 0` 判共存型**，
> 再按 `type` 查系数，否则感电会走 2.0 那一档，玩家拿雷一下就把水盾打没，克制关系就反了。

**一次受击的结算（`Unit.absorb_elemental_shield()`，签名写死）**：

```
func absorb_elemental_shield(damage: int, element_id: String, reaction_type: String) -> Dictionary
```

返回 `{ "absorbed": int, "hp_damage": int, "break_u": float, "broken": bool, "shield_element": String }`，行为：

1. 没有 innate 槽 → 原样返回 `absorbed = 0`、`hp_damage = damage`、`break_u = 0.0`、`broken = false`。
2. `absorbed = min(damage, ceil(shield_amount × SHIELD_HP_PER_U))`；`hp_damage = damage − absorbed`。
3. `break_u = (float(absorbed) / SHIELD_HP_PER_U) × shield_break_rate(element_id, reaction_type)`。
4. 盾量 `-= break_u`；`<= 0.0` → 移除该槽、`broken = true`（并把 `innate_timer` 复位为 `INNATE_REGEN_TURNS`）。
5. 盾量四舍五入到 **2 位小数**（`snappedf(x, 0.01)`），避免 `0.1+0.2` 那种尾巴。

**数值举例（写测试时照这个算，别凭感觉）**：水法师 12U 水盾（吸收量 24）

| 攻击 | 伤害 | 吸收 | `k` | 破盾量 | 盾量变化 |
|---|---|---|---|---|---|
| 火卡（蒸发 amplify） | 6 | 6 | 3.0 | `6/2×3.0 = 9.0` | 12.00 → 3.00（两发破） |
| 雷卡（感电 coexist） | 6 | 6 | 0.5 | `6/2×0.5 = 1.50` | 12.00 → 10.50 |
| 物理（element none） | 6 | 6 | 0.25 | `6/2×0.25 = 0.75` | 12.00 → 11.25 |
| 水卡（同元素、无反应） | 6 | 6 | 0.0 | `0.0` | 12.00 不变 |

### 42.4 结算顺序（`Damage` 几乎不动，改动全在 `Battle` 与 `Unit`）

**`src/core/damage.gd` 只加一个字段**：返回字典里补 `"reaction_type": String`（值 = `act.get("type","")`，
无反应时 `""`）。**初版加的 `immune_source`、`is_static_immune` 判断全部撤销**，免疫那段回到原样一行不动。

**顺序（不能反）**：

1. `Damage.compute()` 照常算反应、倍率、`consume`、`effects`、`damage`（**免疫逻辑零改动**）。
2. `Battle.compute_damage()` 照常扣防御。
3. **元素盾吸收**：调 `Unit.absorb_elemental_shield(d["damage"], 攻击元素, d["reaction_type"])`，
   把 `d["damage"]` 换成 `hp_damage`，日志记「吸收 X 点，盾量 → Y」。
4. `Unit.take_damage(hp_damage)` → 先扣 `Unit.shield`（数值盾）再扣 HP（**现有代码不动**）。
5. `_apply_aura()` 照常挂附着/结算反应效果，但**命中 innate 槽时不许扣它的 `consume`**
   （盾的消耗只由第 3 步管，否则一发反应会被算两遍）。

**`Battle` 里的三个伤害入口**（现在都是 `compute_damage` → `take_damage`，中间插一步）：

| 位置 | 攻击元素 |
|---|---|
| `src/core/battle.gd` `play_card()` 的 `"damage"` 分支 | `card.element` |
| `src/core/battle.gd` `attack_unit()` 主伤害 | `attacker.element` |
| `src/core/battle.gd` `attack_unit()` 反击 | `target.element`（反击方元素） |

三处**必须走同一个私有方法**（例如 `_absorb_by_shield(target, damage, element, reaction_type) -> int`），
不要写成三种样子。返回值 = 真正打到血上的伤害。

### 42.5 槽位与挤占规则（**不改会出 bug**）

`MAX_AURAS := 3`。现有 `add_or_refresh_aura()` 满槽时 `pop_front()` 挤掉最旧的一槽 —— 如果最旧的是 innate 盾槽，
**盾会被别人随手挂的元素凭空挤掉**。必须改成：

- 满槽时只挤**最旧的、`innate == false`** 的槽；
- 三槽全是 innate → **放弃这次附着**（盾优先），日志写「附着失败：盾占满槽位」；
- **同元素分支要分辨**：普通附着不能和 innate 槽合并（否则会出一个 `innate:false` 的合并槽，把盾变成附着）；
  同元素且命中的是 innate 槽 → 也走「新槽」路径（而不是量相加）；
- 新加的普通槽**显式写 `"innate": false`**，不依赖缺省。

`tick_auras()` 必须**跳过** innate 槽（`continue`，不是 `break`），否则 `duration: 0` 的盾第一回合就被删。

### 42.6 3 回合重生（`tick_innate_shield()`）

挂在**回合开始**，位置在 `src/core/battle.gd` 的 `_settle_status()` 里 `tick_auras()` 那段**之后**、
同一个 `for u` 循环体内（`tick_auras()` 的 `for el in expired` 之后）。

规则：

1. `innate_template` 为空（这单位本来没盾）→ `return false`。
2. 当前 innate 槽**齐全**（数量 == 模板数量）→ `innate_timer = INNATE_REGEN_TURNS`，`return false`
   （**满盾时不倒计时**，破盾那一刻才开始数）。
3. 否则 `innate_timer -= 1`；`> 0` → `return false`。
4. `innate_timer <= 0` → 按模板把缺的槽补回去（`amount` 用模板值、`duration` 用 0、`innate = true`），
   `innate_timer = INNATE_REGEN_TURNS`，`return true`（要让 `battle.gd` 记一条日志）。

**为什么「破盾后才数」**：读作「破盾后最多挨 3 个自己的回合」；也避免「一直没破盾、某回合莫名回满」。

**回合结算顺序**：dot 掉血 → 死亡移除 → disable → `tick_buffs()` → `tick_auras()` → `tick_innate_shield()`。
重生放最后，所以「这回合刚回来的盾」不会被同一回合的 dot 再打掉。

**重生时补齐槽位可能撞 `MAX_AURAS`**：若此时 3 槽被普通附着占满，重生**优先**——先挤掉最旧的普通槽。
这条容易漏，测试 `[6]` 里要有一个「槽满 + 破盾 + 3 回合后盾回来了且普通槽让位」的用例。

### 42.7 数据迁移（`data/tables/enemies.json`）

| 敌人 | 改前 | 改后 |
|---|---|---|
| `slime` 史莱姆 24hp/4atk | `immunities: []` | **不动** |
| `fire_slime` 火史莱姆 20hp/4atk | `immunities: ["fire"]` | **改回静态免疫**（就是现在这样，一行不动）。它就是「真·免疫」的样本：水打它也**永远**没有反应、没有伤害 |
| `golem` 岩傀儡 40hp/6atk | `immunities: ["geo"]` | **不动**（第二个静态免疫样本） |
| `hydro_mage` 水法师 **新增** | —— | `hp: 30, attack: 5, immunities: []`，`auras: [{ "element": "water", "amount": 12.0, "duration": 0, "innate": true }]` |

**为什么这样分**：火史莱姆与岩傀儡做「静态免疫」对照（怎么打都打不破），水法师做「元素盾」样本
（不拿火/冰这类能反应的元素，就打不动它；拿火两发破盾，之后正常掉血；3 回合后盾回来）。

`_note` 要补一句：「`immunities` = 静态免疫（永久、不反应）；`auras` 里 `innate: true` 的槽 = 元素盾
（吸收伤害、被反应按系数削、破后 3 回合重生）」。

**冰/岩史莱姆的「再生护盾」本次不做**：等元素盾这套跑通、平衡调过之后再加数据即可（数据层不需要新代码）。

### 42.8 校验器缺口（`tools/validate_data.gd`，本轮必须补）

`validate_data.gd` 目前**完全没读 `enemies.json`**（`_initialize()` 只校验 elements / statuses / reactions / cards / decks）。
新增 `_check_enemies(element_ids)`：

| 检查 | 等级 |
|---|---|
| `enemies` 是数组、每项是对象 | error |
| `id` 非空且不重复 | error |
| `name` 非空 | error |
| `hp` 为整数且 `> 0`；`attack` 为整数且 `>= 0` | error |
| `immunities` 是数组、每个元素 id 在 `elements.json` 里 | error |
| `auras` 是数组、每项是对象、`element` 在 `elements.json` 里 | error |
| `auras` 项 `amount` 是数字、`> 0`、`<= MAX_INNATE_AMOUNT (20.0)` | error |
| `auras` 项 `innate` 非 bool | error |
| `innate == true` 但 `duration != 0` | **warning**（提醒作者别写错） |
| 同一元素既在 `immunities` 又在 innate 盾里 | **warning**（语义冗余：静态免疫会先短路，盾永远咬不动） |
| 结尾打印 `[info] 敌人 N 种 ✓` | —— |

`_initialize()` 里插在 `_check_cards` 与 `_check_decks` 之间。

### 42.9 测试计划

**新增 `tests/pending/elemental_shield_test.gd`**（约 **30–34 项**，`EXPECTED_CHECKS` 先跑再对齐）：

| 段 | 覆盖什么 | 约条数 |
|---|---|---|
| `[1]` 数据与基本谓词 | `from_dict` 认 `innate` 与模板；`has_innate_shield(water)` 真；**`is_immune(water)` 假**（盾不是免疫，这条是本块的立身之本）；`immunities` 为空 | 5 |
| `[2]` 盾在时全挡 | 火/雷/物理/同元素打水法师 → `hp` 一点不掉、`absorbed == damage`、`hp_damage == 0`；盾量按 §42.3 表精确变化 | 6 |
| `[3]` 反应削盾最快 | 火打水盾两发破（12 → 3 → 破）；第三发火正常掉血；破盾后 `has_innate_shield` 假 | 5 |
| `[4]` 系数差异 | 同一伤害下，蒸发削减 > 超载 > 结晶 > 感电 > 物理 > 同元素(0)；**用 §42.3 的数值逐条断言** | 5 |
| `[5]` 同属性打不破 | 水打水盾：伤害 0、盾量**一分不变**、连跑 5 回合仍旧 | 3 |
| `[6]` 3 回合重生 | 破盾后第 1、2 回合不回、第 3 回合回且 `amount` == 模板值；满盾时不倒计时；**槽满时重生优先** | 5 |
| `[7]` 挤占规则 | 三槽全 innate 时普通元素挂不上；有普通槽时挤掉最旧**普通**槽、盾不动 | 3 |
| `[8]` 老契约不破 | 静态免疫（火史莱姆 / 岩傀儡）仍「伤害 0 + 不反应 + 不挂槽」；`is_immune` 语义与 560 基线完全一致 | 2 |

**必须同步迁移的既有测试**：`tests/data_test.gd` 的 `_test_enemies()` 断言 `enemies.size() == 3` → **4**；
补一条「水法师有 innate 水盾、`is_immune(water)` 为假」；`EXPECTED_CHECKS` 按实际数改。
其余免疫测试（`damage_test` D5、`battle_m1_smoke`、`aura_v3` `[9]`、`order_test`）**一行都不用改** ——
因为它们走的都是静态免疫，而本块不动静态免疫。

### 42.10 验收

| 项 | 期望 |
|---|---|
| `tests/pending/elemental_shield_test.gd` | 全绿，`[READY  ]` |
| 主套 | `run_tests.bat` 全绿，项数 = **560 − 46 + data_test 新数 + 新文件条数**（实测后写进 §42.14） |
| `validate_data` | PASS，**0 错 0 警**（含新增的 `敌人 N 种 ✓`） |
| `balance_sim --games 200 --seed 1` | **必须逐位相同**（45.0% / 13.4 / 0%）。`balance_sim` 不读 `enemies.json`，变了就是碰坏了共享路径 |
| 反假绿 | ①`shield_break_rate` 恒 `0.0` → `[3][4]` 必红；②`absorb_elemental_shield` 原样返回（不吸收）→ `[2]` 必红；③`tick_innate_shield` 恒 `return false` → `[6]` 必红；④同元素 `k` 从 0 改 3.0 → `[5]` 必红 |
| 编码 | `.gd` / `.md` / `.json` **无 BOM + LF** |

### 42.11 七个坑

1. **别再把盾做成免疫**：`is_immune()` / `immunities` / `Damage.compute` 的免疫短路**一个字不改**。
   上一版就是死在这里（用户当场指出）。
2. **`_apply_aura()` 命中 innate 槽时不许扣 `consume`**，否则一发反应算两遍（盾被扣两次）。
3. **`tick_auras()` 里 innate 用 `continue` 不是 `break`**，否则盾后面的槽永不衰减。
4. **满槽挤占只挤非 innate**，否则盾被普通元素挤掉；重生时相反——**要挤普通槽给盾让位**。
5. **系数判定先看 `consume == 0`（共存型）再看 `type`**，否则感电按 `transformative` 的 2.0 削盾，克制关系反了。
6. **盾量用 `float` 且 `snappedf(_, 0.01)`**，否则 `0.75` 一路减下去会出现 `10.499999` 这种脏值，测试断言挂掉。
7. **`balance_sim` 不受影响不代表 `battle_m2_test` 不受影响**：那 63 项里有 AI 打单位的完整路径，跑一遍确认。

### 42.12 明确不做的事

- **`reactions.json` 里的 `damage` / `shield` / `heal` 三种效果仍不实装**（超载额外伤害、结晶护盾都是死数据），
  留到 M3.8 平衡调参（会改基线，必须与先手补偿一起做）。
- **技能盾（`kind: "shield"` 指令卡）与结晶盾**不动（见 §42.2 排期）。
- **冰/岩史莱姆的再生护盾**不加（数据层以后直接加即可）。
- **`Unit.shield`（数值盾）的扣盾顺序不动**：`take_damage` 已先扣盾后扣血，本块只在它**之前**插一层元素盾。
- **玩家侧不给元素盾**：只有 `enemies.json` 里能配（玩家要的是技能盾，M3.8a 再做）。

### 42.13 施工指引（按顺序做，每步都有「怎么知道这一步对了」）

> 只给**思路与判据**，函数体自己写。签名在 §42.3 已写死，照抄签名不算抄实现。
> **顺序是要求不是建议**：每一步都要能单独验证，不要一口气改完再跑测试 —— 那时红了分不清是哪步。

#### 第 0 步：先把上一版的错误代码清掉（**必须先做**）

如果你已经按 42.13 的旧版（免疫变体那一版）动过手，先回退这几处，否则后面全是歪的：

| 文件 | 要回退的东西 |
|---|---|
| `src/core/unit.gd` | `is_immune()` 里那段「遍历 auras 看 innate」**删掉**；`is_static_immune()` **删掉**（不需要了）；`SHIELD_RESET` / `shield_reset_discount` / `innate_copy` 这类规格外命名一并清掉 |
| `src/core/damage.gd` | `immune_source` 相关全部**删掉**；`compute()` 回到原来的三段（静态免疫 → 无反应 → 有反应），只在返回字典里**加一个 `reaction_type`** |
| `src/core/unit.gd` | `tick_auras` 里读的是 `"immune"` 键、`describe_auras` 也读 `"immune"` —— 统一改成 **`"innate"`**。这个键名混用是本轮最容易漏的 bug |
| `src/core/unit.gd` | `from_dict` 里 `immunities` 被 append 了**两遍**（一遍 `e` 原样、一遍 `str(e)`）—— 删掉多余那遍 |
| `src/core/unit.gd` | `innate_template` 现在把**每一个非 NONE 的槽**都塞进模板（包括普通附着）—— 只许塞 `innate == true` 的 |

**判据**：改完 `git diff src/` 里不该再出现 `immune_source`、`is_static_immune` 这两个词。

#### 第 1 步：`src/core/unit.gd`（数据结构 + 三个新谓词 + 两个常量）

产出「数据 + 查询」，**先不碰战斗流程**：

1. 常量 `MAX_INNATE_AMOUNT := 20.0`、`SHIELD_HP_PER_U := 2.0`、`INNATE_REGEN_TURNS := 3`。
2. 字段 `innate_template`（只存 innate 槽的深拷贝）与 `innate_timer`。
3. `from_dict()` 的 `auras` 循环多认一个 `innate` 键；`true` 时**深拷贝**一份进模板（不能存引用 —— 槽被移除后模板会跟着失效）。
4. `has_innate_shield(element_id) -> bool`：只在 innate 槽里找同元素。
5. `active_innate_shields() -> Array`：返回当前 innate 槽的数组（给日志/UI/测试用）。
6. `get_innate_shield(element_id) -> Dictionary`：返回那**一个槽字典本身**（改它就是改盾量；没有返回 `{}`）。

**判据**：`project` 能解析；写个一次性探针（或在 `tests/pending` 里先写两条）确认 `from_dict` 传 `innate: true` 的敌人
能读到 `has_innate_shield`、且 `is_immune` 仍是**假**（这条最关键：盾不是免疫）。

#### 第 2 步：`src/core/unit.gd` 的三个改旧方法（最容易漏）

1. `add_or_refresh_aura()`：满槽只挤最旧的**非 innate** 槽；三槽全 innate → 放弃附着；同元素若命中 innate 槽 → 不走量相加，走新槽；新普通槽显式 `"innate": false`。
2. `tick_auras()`：倒序遍历，遇到 innate **`continue`**（不减、不删、不收集）。
3. `describe_auras()`：innate 槽输出 `水12.00U(盾)`（两位小数），普通槽维持 `火1U(2)` 原样。

**判据**：这三个改完，**既有测试仍应全绿**（还没有任何数据用 `innate`）。红了说明动坏了普通附着路径，先回滚。

#### 第 3 步：`src/core/unit.gd` 的两个新方法（本块的算法核心）

1. `shield_break_rate(element_id: String, reaction_type: String) -> float` —— **只做查表**，返回 §42.3 的 `k`。
   传入的 `reaction_type` 由调用方决定语义：`""` = 没反应；`"physical"` 由**元素**判断（`element_id == Element.NONE`）
   —— 建议这个函数自己先把「`element_id == NONE` → 0.25」判掉，再查反应表，避免调用方传两种口径。
   共存型判定：`reaction_type` 传进来的时候已经带上 `"coexist"`（见第 4 步），这里只查表，不做二次推断。
2. `absorb_elemental_shield(damage, element_id, reaction_type) -> Dictionary` —— 按 §42.3 的 5 步走：
   全挡 → 算 `break_u` → 扣盾量（`snappedf` 两位）→ `<= 0` 移除槽且复位 `innate_timer` → 返回五字段字典。

**判据**：写几个临时断言（或直接在 `tests/pending` 里起头 `[2]`），数字要**逐位对得上 §42.3 的举例表**：
12U 盾 + 火 6 伤害 → `absorbed 6 / break 9.0 / 剩 3.00`。对不上就是系数或单位搞错了。

#### 第 4 步：`src/core/damage.gd`（一行）

只加返回字段 `"reaction_type"`。取值的规则：

- 没反应 → `""`；
- 有反应且 `consume == 0.0` → **`"coexist"`**（感电/冻结用它，别让它冒充 `transformative`）；
- 否则 → `act.get("type","")`。

**判据**：`damage_test` 全绿（D5 免疫四项一点没变）。

#### 第 5 步：`src/core/battle.gd`（三个入口 + 一处重生 + 一处 `_apply_aura` 例外）

1. 新增一个私有方法（如 `_absorb_by_shield(target, damage, element, reaction_type) -> int`）：
   调 `Unit.absorb_elemental_shield`，把 `absorbed / break_u / 破盾` 打进日志，返回真正打到血上的伤害。
2. 三个伤害入口都改成 `compute_damage` → **过盾** → `take_damage`（见 §42.4 那张表）。
3. `_apply_aura()` 里：如果命中的反应槽是 innate 槽，**跳过扣 `consume` 那一步**（其余不动）。
   注意别顺手改它的免疫入口 —— 静态免疫就该挡。
4. `_settle_status()` 里 `tick_auras()` 之后加 `tick_innate_shield()` 的调用与日志。

**判据**：`battle_m2_test` 的 63 项仍全绿（AI 打无盾单位的路径没变），`balance_sim` 逐位不变。

#### 第 6 步：`data/tables/enemies.json` 与 `tools/validate_data.gd`

数据：火史莱姆**保持**静态免疫（一行不动），**新增** `hydro_mage` 水法师（30hp/5atk，12U 水盾），`_note` 补两种机制的说明。
校验器：按 §42.8 的表加 `_check_enemies()`。

**判据**：`validate_data` PASS，**0 错 0 警**，且输出里有 `敌人 4 种 ✓`。

#### 第 7 步：迁移 `tests/data_test.gd`

`_test_enemies()` 的 `enemies.size() == 3` → **4**；补一条「水法师：`has_innate_shield(water)` 真、`is_immune(water)` **假**」。
`EXPECTED_CHECKS` 先跑再对齐，别先改数字。

#### 第 8 步：写 `tests/pending/elemental_shield_test.gd`（八段，按 §42.9）

实战要点：

- 造带盾单位**走 `Unit.from_dict()`** 传 `auras`，别手改数组 —— 否则模板是空的，`[6]` 永远测不过，你会误怀疑重生代码。
- `[2][4]` 的数字**照抄 §42.3 举例表**，不要自己算个大概再对 —— 系数表就是契约。
- `[6]` 要测三个时间点（第 1、2 回合不回、第 3 回合回），只测「最后回来了」抓不到 off-by-one；再补「满盾倒计时不动」。
- `[5]` 同属性要**真的连跑 5 个回合**，不是连调五次 `tick_auras()`（重生也在回合结算里，顺序错只有完整回合才暴露）。
- `[8]` 老契约用火史莱姆/岩傀儡，验证静态免疫**没有**被本块污染。

#### 第 9 步：验收与反假绿

四件套 + 四组探针（§42.10）。**任何一组没变红 = 对应断言是假绿，回去补**，不要因为「全绿了」就收工。

#### 最后：自查这六条

| # | 自查 | 错的样子 |
|---|---|---|
| 1 | `is_immune()` / `immunities` / `compute()` 免疫短路**零改动** | 盾又变成免疫了 |
| 2 | 系数判定先 `consume == 0` 再看 `type` | 感电一下把水盾打没 |
| 3 | `_apply_aura` 命中 innate 槽不扣 `consume` | 反应被算两遍 |
| 4 | 满槽挤非 innate；重生时挤普通槽让位 | 盾被挤掉 / 盾回不来 |
| 5 | 盾量 `float` + `snappedf(0.01)` | 断言挂在 `10.499999` |
| 6 | `validate_data` warning 数为 0 | 新检查写太宽 |

### 42.14 落地记录

（实现并验收后在此回填：实测项数、提交、四组反假绿红了几项、水法师实测数值。）

### 42.15 第一轮评审（2026-11-27，学员 WIP，按旧规格写的）

> 结论：**当前 `src/core/{unit,damage}.gd` 的改动是上一版「盾 = 免疫变体」方案的产物，整体要按 §42.13 第 0 步回退重来。**
> 不要再在这份 diff 上往下加东西 —— 地基错了，加得越多拆得越久。
> `src/core/battle.gd` 还没动，这是好事：一块都还没接线，回退成本最低。

#### A. 已经做对的（回退时别一起删）

| 位置 | 做对了什么 |
|---|---|
| `src/core/unit.gd:57-62` | `from_dict` 的 auras 循环里读 `"innate"` 键并写进槽字典 —— 键名和规格一致 |
| `src/core/damage.gd:45-58` | 静态免疫**提前 return** 的思路对（静态免疫要短路，不能往下算反应） |
| `src/core/damage.gd:45` | 用 `immune_source` 三态区分来源，方向对（但本块不需要它了，见下） |

#### B. 必须改的（按严重程度）

| # | 位置 | 现象 | 为什么错 | 怎么改（思路） |
|---|---|---|---|---|
| 1 | `src/core/damage.gd:60-63` | `elif target.is_immune(element): immune = true; immune_source = "shield"; reaction_slot = -1` | **这是本块的核心错误**：把盾当成免疫 → 直接 `reaction_slot = -1` 把反应掐死。盾的整个存在意义就是「能挡伤害但**反应照算**」 | 这段整块删掉。盾不进 `Damage.compute`，判定挪到伤害结算之后（§42.13 第 5 步） |
| 2 | `src/core/unit.gd:94-101` | `is_immune()` 里多了一段「遍历 auras 看 innate」 | 污染了免疫语义；`_apply_aura` 等既有调用点会跟着误判，四处老测试（damage/battle_m1/aura_v3/order）全都建在「免疫 = 不反应」上 | 循环原样恢复成只扫 `immunities` |
| 3 | `src/core/unit.gd:87-92` | `is_static_immune()` | 本块不需要这个函数（`is_immune` 本来就只指静态免疫，没有第二种来源了） | 删掉 |
| 4 | `src/core/unit.gd:63-67` | `innate_template.append(...)` 的条件是 `element != NONE` | 把**每一个普通附着槽**都存成了模板 → 普通火附着被吃掉后也会「3 回合重生」，等于所有单位都有再生盾 | 条件换成 `innate == true`，且**深拷贝**（别存槽字典的引用） |
| 5 | `src/core/unit.gd:189` / `:205` | `tick_auras` 与 `describe_auras` 读的是 `"immune"` 键 | 与 `from_dict` 写的 `"innate"` 不是同一个键 → 护盾照样每回合掉 duration、显示也不带盾标 | 两处都改成 `"innate"`。**这是本轮最隐蔽的 bug，只有跑测试才会露头** |
| 6 | `src/core/unit.gd:68-73` | `immunities` 被 append 了**两遍**（一遍 `e` 原样、一遍 `str(e)`） | 同一个元素重复入表；虽然 `has()` 结果不变，但 `describe`/长度断言会歪 | 删掉多余那遍，只留原来就有的 `for e in d.get("immunities", []): append(str(e))` |
| 7 | `src/core/unit.gd:13` / `:28` | `const SHIELD_RESET := 3`、`var shield_reset_discount = 0` | 规格外的命名与字段（§42.3 只有 `INNATE_REGEN_TURNS`、`innate_timer`） | 删掉，重生用 `INNATE_REGEN_TURNS` + `innate_timer` 两个即可 |
| 8 | `src/core/unit.gd:104-108` | `has_innate_shield() -> bool` 缺 `element_id` 参数 | 规格签名是 `has_innate_shield(element_id: String) -> bool`；无参版本只能回答「有没有盾」不能回答「是不是这面盾」 | 按 §42.3 的签名表补齐 |
| 9 | 缺 | `MAX_INNATE_AMOUNT` / `SHIELD_HP_PER_U` / `innate_timer` / `get_innate_shield()` / `active_innate_shields()` / `shield_break_rate()` / `absorb_elemental_shield()` / `tick_innate_shield()` 全都没写 | 本块的双主体（盾量吸收 + 破盾系数）一个都还没有 | 按 §42.13 第 1、3 步补 |
| 10 | 缺 | `src/core/battle.gd` 完全没动 | 三个伤害入口与重生挂点都还没接线 | §42.13 第 5 步 |

#### C. 顺带提醒（不是错，但别在这轮顺手做）

- `src/core/damage.gd:45-58` 的静态免疫分支把整个返回字典抄了一遍，和末尾那份重复。回退时既然要删 `immune_source`，顺手把 `return` 去掉、让它继续走下面同一份返回字典即可 —— 但**先让测试绿**，其次再收拾。
- `data/tables/cards.json` 被重排成多行缩进格式（259 行）。格式本身没问题（`validate_data` 与 `test_card_lib` 现在都支持单行/多行两种），但**下轮别再做格式化重构**：一次提交里混「改数据」和「改格式」，评审时看不出哪个字段是真改的。
- 顺带修掉的教练侧 bug：`tools/card_lib.gd` 的写回逻辑原来假设「一张卡一行」，多行格式下会把逗号补到独立的 `\t\t{` 行、产成 `{,`。现已改成按**卡块（大括号配对）定位**，单行与多行两种格式各验过一次，61 项全绿。

#### D. 下一步（照 §42.13 走，别跳步）

1. 第 0 步：按上表 B 的 1–7 条清旧代码。**判据**：`git diff src/` 里搜不到 `immune_source`、`is_static_immune`、`SHIELD_RESET`、`shield_reset_discount`、`"immune"`。
2. 第 1 步：补常量/字段/三个谓词。**判据**：写个一次性探针，确认 `is_immune(water)` 对水法师是**假**、`has_innate_shield(water)` 是**真**。
3. 第 2 步：改 `add_or_refresh_aura` / `tick_auras` / `describe_auras`。**判据**：既有 560 项仍全绿（还没有数据用 `innate`）。
4. 第 3 步：写 `shield_break_rate` + `absorb_elemental_shield`。**判据**：数字逐位对上 §42.3 举例表（12U 水盾 + 火 6 伤害 → `absorbed 6` / `break 9.00` / 剩 `3.00`）。
5. 第 4 步：`damage.gd` 只加 `reaction_type`。**判据**：`damage_test` 23 项全绿、D5 四项一点没变。
6. 第 5 步：`battle.gd` 三入口 + 重生挂点 + `_apply_aura` 例外。
7. 第 6–9 步：数据（水法师）、`_check_enemies`、`data_test` 迁移、`elemental_shield_test` 八段、验收四件套 + 四组反假绿。

---


## 43. M3 后续块细化：M3.8a / M3.8 / M3.9 · 2026-11-27

> 本节是 M3 收尾三块的**唯一文档**。§29 M3 索引里那三行是粗粒度的，以本节为准。
> 老规矩：思路与判据全给，函数体学员自己写（m00629）；代码学员写、测试/文档/工具教练写（§2）。

### 43.A M3.8a AI 打指令卡（issue #4）

#### 43.A.0 现状与目标

现状 `_ai()`（`src/core/battle.gd:140`）：出兵 → 前压 → 攻击，**手牌里的指令卡一张都不打**。
目标：AI 在能量允许时打出有正收益的指令卡，顺序 = 出兵**前**评估（先加强再上兵）。

#### 43.A.1 设计决策（已定）

1. **打指令卡是「出兵前」的一步**：AI 每回合的出牌顺序 = ①指令卡（可多张，能量内）→ ②出兵 → ③前压 → ④攻击。
   理由：指令卡的收益（直伤/护盾/治疗）不占场面格子，先打能让后上的兵踩着更好的局面。
2. **评估函数 `score_order(card, target) -> int`**：≥ 阈值才打。初版阈值定 `1`（≥1 分就打），理由：
   AI 双方同副牌（§40.4），打牌只影响本回合交换，阈值高了 AI 永远不打、阈值低了乱打；
   平衡留给 M3.8 调，这里只保证「能打、有理由地打」。
3. **目标选择**：damage 卡选「能击杀的最便宜目标，否则血最少的目标」；heal / shield 卡选「自己血最少的非 HQ 单位，没有则跳过」；没目标 = 不打，**不许硬找**（坑 8 同源）。
4. **每张牌每回合至多打一次**；打完重算能量与手牌。**禁止 `while` 原地重试**（§39.5 坑 8 的教训）。

#### 43.A.2 要改哪里

| 位置 | 改什么 |
|---|---|
| `src/core/battle.gd` `_ai()` | 开头加一段「打指令卡」：遍历手牌（复制一份再遍历，打牌会改手牌），`kind == "order"`（`type == "order"`）的卡走 `score_order` 评估，达标则 `play_card(card, target)` 并记账 |
| `src/core/battle.gd` 新增 `_score_order(card: Card, target: Unit) -> int` | damage = 预期伤害（`compute_damage(power, element, target)` 的 damage）×（能击杀 ×2）− 浪费量；heal/shield = `min(power, 缺口) `；返回 ≤0 表示不该打 |
| `src/core/battle.gd` 新增 `_pick_order_target(card: Card) -> Unit` | 按上面 43.A.1-3 的规则选目标，返回 null = 不打 |

**不改**：`_ai_attack_targets` / `_ai_attack`（你的 M3.4 成果，M3.8a 与它正交）、`run_auto`、玩家侧一切。

#### 43.A.3 验收：`tests/pending/ai_order_test.gd`（约 14 项）

| 段 | 断言 | 条数 |
|---|---|---|
| [1] 能打 | 玩家 HQ 24 血、手上有 fire_bolt：AI 回合结束后该卡离手、HQ 掉血 ≥5 | 3 |
| [2] 评估 | `_score_order`：打 5 血目标返回 >0；打 1 血目标（过量 4）返回 < 打 5 血的；对满血 shield 卡在没人缺盾时返回 ≤0 | 4 |
| [3] 选目标 | 两目标一 8 血一 2 血 → 选 2 血（能击杀优先）；没有合法目标 → 不打、不报错、回合正常结束 | 3 |
| [4] 经济 | 能量 1、手卡 cost 2 → 不打；连打两张后能量正确扣减 | 2 |
| [5] 回归 | `run_auto` 10 个固定 seed，**只记录数字**（AI 行为变了，胜率/回合数**允许**变，但必须是同一个新值；M3.8 再要求它稳定） | 2 |

#### 43.A.4 验收脚本（教练侧已写好，跑法见 §43.C）

`tools/ai_order_report.ps1`：跑 `ai_order_test` + 10 seed 对照表 + 主套，输出「AI 打了几张指令卡 / 平均每回合几张」。
**判据**：主套全绿（battle_m2 的 63 项是行为契约，一张不许红）；10 seed 的 turn 数与改动前**允许漂移但必须可复现**（同 seed 两次跑结果逐位一致）。

#### 43.A.5 坑

1. 遍历手牌时打牌 → 手牌数组边遍历边变 → 漏牌或越界。**先 `duplicate()` 再遍历**。
2. `play_card` 对 order 卡的 target 是 `Unit`，heal/shield 目标可以是 HQ —— 但 HQ 不该吃 heal（规则让它 `operation_cost` 无意义），选目标时**排除 HQ**。
3. 打完牌立刻 `is_over()` 检查（直伤可能直接点死玩家 HQ），是就 `return`。
4. `score_order` 里**不要复算防御**：`compute_damage` 已经算过 defense 减免，再减一次就双重扣。

### 43.B M3.8 平衡调参（issue #5，依赖 43.A）

#### 43.B.0 前置事实（§40.4 / HANDOFF §24 的结论，不许忘）

**当前 `balance_sim` 胜负 100% 由先手决定**（seed 1..200 探针：玩家先手 90 / 敌方先手 110，恰等于 WIN 90 / LOSE 110；40 局对照 match=40）。**不做先手补偿，调什么卡都是白调。**

#### 43.B.1 施工顺序（四步，不许跳）

| 步 | 做什么 | 判据 |
|---|---|---|
| 1 | **先手补偿**：后手方首个回合多 1 能量（或首回合多抽 1 张，二选一，实现前定一个） | 补偿后 200 局胜率偏离 50% ≤ 8 个百分点；先手/后手两侧分开统计都要在 42%–58% |
| 2 | **AI 打指令卡生效后的再基线**：跑 `balance_sim --games 500 --seed 1` 与 `--games 100 --seed 42`（preflight 口径），记录数字进 `docs/balance-report.md` | 有数字、注明 seed 与局数 |
| 3 | **卡表微调**：一次只动一类（先动 opcost 最离谱的，再动白板身材），每动一次重跑 500 局 | 每次改动都有前后对照行 |
| 4 | **定稿**：胜率 45%–55% 且先手两侧都达标 → 写 `docs/balance-report.md`（结论 + 每轮调参对照表 + 未解决问题） | 报告提交 |

#### 43.B.2 验收

- `docs/balance-report.md` 存在且含四步的全部数字；
- `run_tests.bat` 全绿（调参只动 `cards.json` 数值，测试断言全部动态推导，不应红；红 = 动了不该动的结构）;
- `validate_data` 0 错 0 警。

#### 43.B.3 坑

1. **不要用 `balance_sim` 调 UI 手感问题**，它只看胜率/回合数。
2. 每轮只动**一个变量**，否则对照表没法归因。
3. 补偿实现别写成「enemy 永远 +1」——判据是**后手方**补偿，谁后手谁拿。
4. 调参期间 `tests/` 一个字不改（「为变绿改测试」是红线）。

### 43.C M3.9 收尾 + tag v0.3（issue #6）

| 步 | 做什么 | 判据 |
|---|---|---|
| 1 | 全量验收三件套：`run_tests.bat` ALL GREEN（20+ 文件）、`validate_data` PASS、`tools/check.bat` PASS | 退出码全 0 |
| 2 | `balance_sim --games 200 --seed 1` 与 `--games 100 --seed 42` 数字写进 README 状态段 | 与 balance-report 一致 |
| 3 | README「怎么开一局（命令行）」段落检查：`launch_editor.bat` / 直接跑 godot 的路径都对 | 人工照着跑一遍 |
| 4 | HANDOFF §0/§4/§7 收口到「M3 全部完成」；issue #4/#5/#6 全关（回帖带验收数字） | milestone M3 关闭率 100% |
| 5 | `git tag -a v0.3 -m "M3 完成：关键词/兵科/卡池20+/元素v3/per-card limit/AI选目标+指令卡/平衡"` + push tag | `git ls-remote --tags origin` 有 v0.3 |

**坑**：tag 之前 `git status` 必须干净（学生 WIP 不许混进 v0.3）；tag 打在**已 push 的 main HEAD** 上。

### 43.D M3 收尾总验收（M3.9 前跑一遍）

| 项 | 判据 |
|---|---|
| 主套 | `run_tests.bat` ALL GREEN，文件数 = 启用测试数（当前 20 + ai_order 1 = 21） |
| 主套项数 | 560 + ai_order_test 项数（约 14）≈ 574；以实测为准，公式写进提交信息 |
| 数据 | `validate_data` 0 错 0 警 |
| 平衡 | 45%–55% 且先手两侧达标（43.B 判据） |
| 反假绿 | M3.8a 用「评估函数恒返回 -1 → AI 一张卡都不打 → [1] 红」；「阈值改 0 → [2] 的过量惩罚断言红」两条探针 |


---
## 44. M4 任务卡细化补全（§37 的 13 块 → 每块补「教练侧验收脚本」）· 2026-11-27

> §37 已写完 13 块的规则/改动面/坑（37.1–37.13）。本节**只补三件事**：
> ①每个 UI 块的测试**骨架**怎么写（UI 测试和 core 测试写法不同，这是 M4 最大的新坑）；
> ②教练侧验收脚本（§44.0）；③块与块之间的**接口签名定稿**（§44.1，两块之间传什么，先钉死，避免 M4.2 写完 M4.3 对不上）。
> 块内规则仍以 §37.N 为准，两节冲突时 **§37 优先**。

### 44.0 教练侧验收脚本（已交付，跑法统一）

| 脚本 | 覆盖 | 跑法 |
|---|---|---|
| `tools/ui_smoke.bat` | 逐个跑 `tests/ui_*_test.gd`（`tests/pending/` 里也有则一起），汇总 `[PASS]/[FAIL]/[HUNG]`，任一红退出码 1 | 双击或 `cmd /c tools\ui_smoke.bat` |
| `tools/ui_check.ps1` | ①`--quit-after 3` 开窗冒烟；②`check_font.gd`；③全仓 `src/ui/` 中文字面量 grep；④`preflight.ps1` 第 [9] 项（core 无界面代码）；⑤输出汇总 verdict | `powershell -File tools\ui_check.ps1` |

**M4 每块收工 = §38.1 的动作 + 对应脚本退出码 0**。两个脚本都进 CI（M4 开工时往 `.github/workflows/ci.yml` 的矩阵里加一行， coach 侧操作）。

### 44.1 接口签名定稿（写代码前先读这节）

这些签名跨块共享，**定稿后改名要同时改两块**，所以先钉死：

| 接口 | 签名 | 生产者块 → 消费者块 |
|---|---|---|
| 快照 | `battle.snapshot() -> Dictionary`（键见 §37.2） | 37.2 → 全部 UI 块 |
| 合法动作 | `legal_targets(card) / legal_moves(unit) / legal_attacks(unit)` | 37.2 → 37.5 / 37.7 |
| AI 单步 | `ai_step() -> bool` | 37.3 → 37.8 |
| 状态签名 | `sig = "%d|%d|%d|%d|%d|%d" % [turn, energy, hand.size(), 单位数, p_hp, e_hp]` | 37.4 → 37.6 / 37.9（重建节流的依据） |
| fx 入口 | `Fx.play_damage(node, from_pos, to_pos, amount)` 等四个（§37.9） | 37.9 → 37.5 / 37.7 / 37.8 调用 |
| 存档 | `SaveSystem.save_game(state, slot) / load_game(slot) / has_save(slot)` | 37.12 → 37.10 的「继续」按钮 |

### 44.2 UI 测试骨架（每块的 `ui_*_test.gd` 都长这样）

**为什么 UI 测试不能像 core 测试那样写**：`extends SceneTree` 的脚本主循环不跑，
`Control` 不进树、`_ready()` 不执行、`await` 不会恢复。所以：

1. **逻辑全部放在 `RefCounted` 的 controller/view-model 类里**（§37.4 已定），测试只测这些类；
2. 测试里构造的是 `snapshot()` 风格的 **假快照 Dictionary**，不是真的 `Battle`（除了 37.2/37.3 这两个 core 块）；
3. 需要真节点的（字体、布局），用**冒烟脚本**（`--quit-after 3` + 截图）而不是断言。

骨架（每块测试都按这个形）：

```
extends SceneTree
## 【你的任务】<块名> —— 只测 controller（RefCounted），不测 Control 节点
const EXPECTED_CHECKS := N

var checks := 0
var fails := 0

func _check(cond: bool, msg: String) -> void: ...
func _check_eq(got, want, msg: String) -> void: ...

func _fake_snapshot(hand: int, p_hp: int = 20, e_hp: int = 20) -> Dictionary:
	# 造最小合法快照：hand 张假卡 + 双方 HQ + 空场
	...

func _initialize() -> void:
	_test_layout()
	...
	print("---------------------------------------")
	print("共 %d 项检查，失败 %d 项" % [checks, fails])
	if fails == 0: print("PASS")
	else: print("FAIL")
	quit(1 if fails > 0 else 0)
```

**断言的重心**：controller 的返回值（宽度/位置/该调哪个 core 方法/参数），不是节点树。

### 44.3 各块补充验收（与 §37.N 的判据合并使用）

| 块 | 额外判据（§37 没写的） |
|---|---|
| 37.4 手牌 | 卡宽公式：`min(CARD_W, (可用宽 - 间距×(n-1)) / n)`；9 张时每张 ≥ 96px（能看清费用角标） |
| 37.5 出牌 | 状态机**单测**：从 `idle` 起连续喂「点牌→点目标→点牌→ESC」四个事件，断言每步状态与返回动作；`play_card` 用计数器桩替代 |
| 37.6 战场只读 | 映射表测试用**全 15 格逐格断言**（不放 15 个单位摆不满的图片断言）；线顺序 = `Board.LINES` 原序 |
| 37.7 战场交互 | 高亮断言是**集合相等**（两边排序后逐项比）；`move_unit` 调用参数用记录桩捕获 |
| 37.8 回合流转 | `ai_step` 循环用**手动推进**测试（循环 N 次后 `turn` 增加），`await`/分帧只在真实 UI 里，测试里不碰 |
| 37.9 动画 | 关动画判据写成：`fx_enabled=false` 时四个函数**同步返回 false**（未播放），对局数据流与开动画逐位一致 |
| 37.10 菜单 | 关卡条目 = `DataLoader.load_enemies()` 条数；「继续」按钮 disabled 状态 = `not SaveSystem.has_save(1)` |
| 37.11 设置 | `settings.cfg` 读写用 `ConfigFile` 类；测试直接构造/读取该文件比对键值 |
| 37.12/13 存档 | `save_test` 全部走 `user://saves/` 真文件（测试名当文件名，测完删）；迁移测试**在测试内**构造 v0 假档 |

### 44.4 M4 期间的 RED LINE（三条，违反 = 当轮返工）

1. `src/core/` 只增不改：任何对 `play_card` / `move_unit` / `attack_unit` / `stat_of` 已有行为的改动都会打破 M3 的 560 项契约（§37 分工已写，这里给判据：`git diff main -- src/core/` 里**不允许出现已存在函数签名的改动**）。
2. UI 不许读 core 私有成员（`_hand` / `_ai` / `_energy` 等下划线开头）——`snapshot()` 就是为此而生。
3. 每块收工必须「一条命令能证明」：跑对应 `ui_*_test` + 截图。证明不了的块 = 切大了，回去拆。

## 附：常用 GDScript 手段速查

| 想做的事 | 用什么 |
|---|---|
| 数组追加/删除/查长度 | `append()` / `erase()` / `size()` |
| 复制数组（遍历时安全） | `array.duplicate()` |
| 排序 | `array.sort()` |
| 取小/取大 | `mini(a,b)` / `maxi(a,b)`（浮点用 `minf`/`maxf`） |
| 字典取值带默认 | `dict.get(key, 默认值)` |
| 判断类型 | `typeof(x) == TYPE_DICTIONARY` |
| JSON | `JSON.parse_string(text)`（失败返回 null） |
| 读文件 | `FileAccess.file_exists()` / `FileAccess.get_file_as_string()` |
| 格式化字符串 | `"%s 打了 %d 点" % [名字, 数值]` |
| 分支 | `match kind: "damage": ...` |
| 报错（不中断） | `push_error("消息")` |
| 带类型的数组 | `var a: Array[Card] = []`（**不要**直接赋 `filter()` 的结果） |

---

## 写完一个文件的验收动作

**只跑一条命令：`run_tests.bat`（在仓库根目录）。** 它现在是**三段式**，一次跑完教练手工验证的全部内容：

```
################ PART 1  main suite (tests\*_test.gd) ################
  —— 自动发现 tests\*_test.gd；每文件判 退出码 + 有 PASS + 无 [FAIL] + 无 SCRIPT ERROR
  —— 全绿时每个文件只打一行 [PASS]；有红就 dump 该文件完整日志

############ PART 1.5  pending baseline (tests\pending\*_test.gd) ############
  —— 每个待启用文件一行：[READY  ] name  N checks --> git mv ...   /  [PENDING] name  N checks / M failed
  —— 只报告，永不判失败

################ PART 2  detailed preflight (tools\preflight) ################
  [1] 数据校验               validate_data.gd 必须 PASS
  [2] 旧字段残留             src/ 里 has_acted 命中数（M3.1 启用后必须 0）
  [3] EXPECTED_CHECKS       每个测试文件都必须声明，否则少跑会假绿
  [4] 兵科覆盖               cards.json 单位卡的 unit_class 覆盖率
  [5] 平衡冒烟               balance_sim 100 场：胜率 45–60% / 8–20 回合 / RUNNING < 1%
  [6] 脚本编码               *.bat 必须 CRLF + 纯 ASCII；*.ps1 有中文必须带 UTF-8 BOM
  [7] 工作区噪音             data/tables/*.json 的行尾换行假 diff + 未提交改动清单
  —— 末行 ===== ALL GREEN ===== 才算过（PART 2 退出码非 0 也会把总结果拉成失败）
```

三段都过才是 `===== ALL GREEN =====`，退出码 0。**别只看单个文件的退出码**：

```bash
# 只想跑某一个文件、看失败数有没有变少（调试用，不算验收）
& $g --headless --path . --script res://tests/battle_m2_test.gd

# 只想跑 PART 2（比如刚补完数据、想确认真实卡池的 unit_class 齐不齐）
tools\preflight.bat

# 想手动看一局（battle.gd 写完后才用得上）
& $g --headless --path . --script res://tests/run_battle.gd
```

**全绿 = 失败 0 项 + 退出码 0 + 输出里没有 `SCRIPT ERROR` + PART 2 全通过。**
前者可能"少跑了几条也全绿"（所以每个测试文件末尾会校验应执行的项数），第二个是"报错被吞"。

改工具时注意：`preflight.ps1` 有中文，**必须存成 UTF-8 with BOM**（PowerShell 5.1 否则乱码）；
`preflight.bat` / `run_tests.bat` 必须 **CRLF + 纯 ASCII**（`.gitattributes` 已固定 `.bat → eol=crlf`）。

---

