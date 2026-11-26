# M4 任务规划（界面 + 存档）· 2026-11-26 定稿版

> **M4 只做一件事：让这个项目「能玩、能给人看」。**
> 能开窗口、能用手点着打完一局、中文不是方块、关掉再打开进度还在。
> **发布（导出 exe / 网页、商店页、演示 GIF）属于 M5，M4 不碰。**
>
> 前置：**M3 全部任务卡 ✅ 之后才开 M4**（当前还剩 M3.4 / M3.5 / M3.6 / M3.8a / M3.8 / M3.9）。
> 分工：`scenes/`、`src/ui/` 的脚本 = 学员写；规格 / 测试 / 数据 / 文档 / CI = 教练。
>
> **施工时看 `docs/implementation-tasks.md` §37 / §38** —— 那边是逐块任务卡（要改哪个文件、验收怎么打勾、坑），
> 本文是**规划与理由**（为什么这么拆、风险、排除项、BACKLOG 对照）。两份配合看：规划定方向，任务卡定动作。

---

## 0. M4 与 M3 的边界

| # | 边界 | 怎么守 |
|---|---|---|
| 1 | **M3 没做完不开 M4**。M3 剩余的 13–22 h 净编码干完、`run_tests.bat` 全绿并 tag `v0.3`，才动 M4 | `docs/m3-scope.md` §0 的 10 条 DoD 逐条打勾 |
| 2 | **M4 期间仍然不许为变绿改测试**。UI 阶段最容易出现的坏习惯是「测试碍事就把断言删了」 | 改测试必须同步 `EXPECTED_CHECKS`，且教练复核 |
| 3 | **`core` 只允许「为 UI 需要新增公开接口」，不许改已有语义** | 新增函数可以；`play_card` / `move_unit` / `attack_unit` / `stat_of` 的行为一行都不许变 |
| 4 | `core` 里出现 `Control` / `Node2D` / `Tween` / `signal` 就是违规 | 三条禁令见 `docs/architecture.md` §三 |

开工前的现状确认（三条，一次发完）：

```powershell
git status -sb                      # 工作区应当只有待提交的文档/工具
$env:NO_PAUSE=1; .\run_tests.bat    # 必须 ALL GREEN
"$env:GODOT" --headless --path . --quit-after 2   # 现在应当报「没有主场景」——这就是 M4.0 要修的
```

---

## 1. M4 的技术前置事实

这些是**已经确认过的现状**，不要再花时间去验证；每一行都直接决定了后面某一块的任务内容。

| # | 事实 | 对 M4 的影响 |
|---|---|---|
| 1 | 全仓**没有任何 `.tscn`**；`project.godot` 里**没有 `[application] run/main_scene`，也没有 `[autoload]`** | M4.0 的第一件事就是建第一个场景并注册主场景 |
| 2 | **没有任何字体资源**（无 `.ttf` / `.otf`），也**没有 `assets/` 目录** | M4.0 建目录 + 字体方案 + `assets/fonts/README.md` |
| 3 | Godot 默认字体（Open Sans SemiBold）**不含中日韩字形**，中文一律显示成方块 | 必须走 `SystemFont` + `font_names` 方案（已实测可用） |
| 4 | `src/ui/ui_theme.gd`（`class_name UiTheme`）**已交付并提交**（commit `1847bc3`）：中文字体 + 配色 + 常用控件样式 + `font_health()` 自检；`src/ui/card_view.gd`（单卡组件）同批交付 | M4.0 直接用它，不要再写一遍主题；`tools/unit_maker.bat` 是可运行样例 |
| 5 | 依赖方向固定为 **`UI/scenes → src/core → data`**；`core` 不许有界面代码、不许硬编码内容，UI 不许直接改数据文件 | UI 只能读 `data/*.json`（经 `DataLoader`），只能经 `core` 方法改状态 |
| 6 | 现有 core 公开 API 已经够拼界面：`Battle.setup/start_battle/begin_first_turn/end_turn/run_auto/play_card/move_unit/attack_unit/compute_damage/stat_of/is_over/outcome/get_log/mulligan`；`Board.LINES`/`HQ_SLOT := 0`/`SLOT_COUNT := 5`/`UNIT_SLOTS_PER_SUPPORT := 4`/`place/unit_at/units_in/capacity_of/position_of`；`Unit.buffs/keywords/unit_class/has_moved/has_attacked/is_hq`；`Element.display_name()` | UI 不需要自己实现任何规则；**只缺「查询合法动作」和「快照」两件事** |
| 7 | `Battle.run_auto()` 是「AI 对战 AI 跑完整局」，**没有「AI 只走一步」的接口** | 单人操作必须新增 `ai_step()`，否则 UI 只能要么每帧跑完整局、要么自己去调私有 `_ai()` |
| 8 | 现有 17 个测试文件**全部 `extends SceneTree`**，靠 `--script` 起，不进主循环 | UI 不能用同样方式测 → 必须「UI 逻辑与绘制分离」，逻辑层才可测（见 §4 坑 7） |
| 9 | 渲染器是 `gl_compatibility`；`project.godot` 里**没有窗口尺寸配置** | M4.0 要补 `display/window/size/viewport_width/height`，否则默认窗口放不下棋盘 |
| 10 | 牌的模板在 `data/tables/cards.json`，牌组在 `data/decks/*.json`（走 `DataLoader.load_cards` / 未来的 `load_deck`） | 关卡选择、牌组选择都从数据读，UI 里不许写死卡名 |

### 1.1 M4 结束时的目录结构（目标形态）

```
reaction-card-battler/
├─ project.godot           # + run/main_scene + display/window/size/*
├─ scenes/                 # 新增：只放「根节点 + script」的最小场景
│   ├─ main.tscn           #   启动场景（Boot → 主菜单）
│   ├─ battle.tscn         #   战斗场景
│   └─ menu.tscn           #   主菜单 / 关卡选择
├─ src/
│   ├─ core/               # 不动（只允许新增 snapshot/legal_*/ai_step + save_system.gd）
│   └─ ui/                 # 新增：*_view.gd（绘制）+ *_controller.gd（逻辑，可测）
│       ├─ ui_theme.gd     #   已备：中文字体 + 配色 + 控件样式
│       ├─ main_screen.gd
│       ├─ hand_view.gd / card_view.gd / hand_controller.gd
│       ├─ board_view.gd / unit_view.gd / board_controller.gd
│       ├─ play_controller.gd / turn_controller.gd
│       ├─ turn_bar.gd / result_panel.gd
│       ├─ fx.gd / main_menu.gd / level_select.gd / settings.gd
│       └─ battle_screen.gd
├─ assets/
│   └─ fonts/README.md     # 字体来源/许可/跨平台风险（M4 不内嵌字体文件）
└─ tools/
    └─ check_font.gd       # 字体自检（M4.0 验收用）
```

两条约束：**`scenes/` 里不放逻辑**（场景文件只是入口），**`src/ui/` 里不放规则**（合法性判断一律来自 `legal_*`）。

---

## 2. 里程碑拆分表（M4.0 – M4.9）

★ 基准按 0.5 h 计：★0.5h / ★★1–3h / ★★★4–7h / ★★★★12–16h。
**本表的「预计用时」已按 M3 实测倍率（原估 ÷3~4）校准**，读作「净编码时间的乐观上限」。

| 编号 | 任务 | 交付物 | 依赖 | 难度 | 预计用时 | 验收判据 |
|---|---|---|---|---|---|---|
| **M4.0** | **骨架 + 中文字体**：建三个目录、第一个场景、注册主场景、窗口尺寸、字体自检 | `project.godot`（加 `run/main_scene`、`display/window/size/*`）<br>`scenes/main.tscn`（最小结构：一个根 `Control` + 挂脚本）<br>`src/ui/main_screen.gd`<br>`src/ui/ui_theme.gd`（已备，提交）<br>`assets/fonts/README.md`<br>`tools/check_font.gd` | — | ★ | **1–1.5h** | ①`godot --headless --path . --quit-after 3` 退出码 0、不出现 `Failed to load main scene`<br>②`godot --headless --path . --script res://tools/check_font.gd` 打印 `[FONT OK] <字体名>` 并以 0 退出<br>③截图里窗口标题与初始 Label 的中文是字、不是方块<br>④`run_tests.bat` 仍 ALL GREEN（加上工具脚本后不许多报错） |
| **M4.1a** | **UI 只读快照 + 合法动作查询**（core 侧，带测试） | `src/core/battle.gd`：新增 `snapshot() -> Dictionary`、`legal_targets(card: Card) -> Array[Unit]`、`legal_moves(unit: Unit) -> Array`、`legal_attacks(unit: Unit) -> Array[Unit]`<br>`tests/ui_snapshot_test.gd` | M4.0 无硬依赖，但与 M4.1b 同批做 | ★★ | **1–1.5h** | ①`--script res://tests/ui_snapshot_test.gd` 全绿（≥12 项）<br>②快照**只读**：调 100 次 `snapshot()` 后 `get_log()` / 手牌数 / 场上单位数完全不变<br>③快照内容覆盖：手牌 / 三条线每格单位 / 双方 HQ 血量 / 能量 / 回合数 / 是否结束 / 结局 / 最近 N 条日志 / `opening_phase`<br>④`legal_targets` 与 `play_card` 的拒绝条件一致（同一张卡，被判合法就能出、判非法出了必 `false`） |
| **M4.1b** | **AI 单步接口**（core 侧，带测试） | `src/core/battle.gd`：新增 `ai_step() -> bool`（让当前行动方 AI 走**一步**，返回是否还有后续步）<br>`tests/ui_ai_step_test.gd` | M4.1a | ★★ | **1–1.5h** | ①循环调 `ai_step()` 直到 `false`，能完整走完 AI 的一个回合（不卡死、无 `SCRIPT ERROR`）<br>②`run_auto()` 结果与改动前逐 seed 一致（`run_auto` 内部改走 `ai_step`，语义不许变）——取 10 个固定 seed 对比终局 turn / outcome<br>③对局结束后再调 `ai_step()` 返回 `false` 且不报错 |
| **M4.2** | **手牌 UI**：卡面（名/费用/元素/兵科/关键词）、手牌区自适应、选中态、起手换牌 | `src/ui/hand_view.gd`（`Control`）<br>`src/ui/card_view.gd`（单张卡）<br>`src/ui/hand_controller.gd`（**不继承 Control** 的纯逻辑）<br>`tests/ui_hand_flow_test.gd` | M4.1a | ★★ | **1–2h** | ①`hand_flow` 测试全绿：注入假快照（1/4/9 张）→ 断言卡宽、可见张数、选中切换的返回值正确<br>②窗口里手牌 4–9 张不重叠、不溢出屏（9 张 = `Battle.MAX_HAND` 的满手牌不挤压）<br>③`opening_phase` 为真时出现「换牌」按钮，点选 ≤N 张 → 调 `mulligan("player", 选中)` → 手牌刷新 |
| **M4.3** | **出牌交互**：点牌 → 高亮合法目标 → 点目标 → `play_card` → 刷新 → 可取消 | `src/ui/play_controller.gd`（状态机：idle / card_selected / target_selected）<br>`src/ui/battle_screen.gd`（接线）<br>`tests/ui_play_flow_test.gd` | M4.2、M4.1a | ★★ | **1.5–2h** | ①状态机测试：合法路径 4 步、非法目标被拒（`play_card` 未被调用）、右键/ESC 回到 idle 且选中态清空<br>②人工走查：能量够的牌点亮、不够的置灰、拖到非法位置弹回<br>③出牌成功后手牌数 −1、能量下降、日志新增 ≥1 行（对照 `snapshot()`） |
| **M4.4a** | **战场 UI（只读）**：三条线 × 5 格、HQ 独立样式、单位卡（攻/防/血/元素槽/关键词/已行动标记） | `src/ui/board_view.gd`<br>`src/ui/unit_view.gd`<br>`tests/ui_board_view_test.gd` | M4.1a | ★★ | **1.5–2h** | ①线顺序严格 `Board.LINES`（`enemy_support` / `front` / `player_support`），HQ 落在支持线 `HQ_SLOT == 0`，其余 4 格<br>②测试：用构造快照断言「哪个 (line, index) 渲染到哪个格」的映射表，共 3×5=15 个位置无错位<br>③`has_moved` / `has_attacked` 为真时单位有可见标记（灰化或角标）——截图对比开/关两种状态 |
| **M4.4b** | **战场交互**：选中、移动、攻击 | `src/ui/board_controller.gd`（状态机）<br>`src/ui/battle_screen.gd`（接线）<br>`tests/ui_board_flow_test.gd` | M4.4a、M4.1a | ★★★ | **2–3h** | ①测试：选中己方单位 → 高亮格 = `legal_moves` 的集合（不多不少）；点格 → `move_unit` 被调用一次且参数是 `(unit, to_line, to_index)`<br>②攻击路径同理，目标集 = `legal_attacks`；打 HQ 也要能选中<br>③召唤失调的单位能选中但不可行动（无高亮），点空白处取消 |
| **M4.5** | **回合流转与提示**：能量条 / 回合数 / 结束回合按钮 / AI 回合遮罩 / 胜负结算面板 | `src/ui/turn_bar.gd`<br>`src/ui/result_panel.gd`<br>`src/ui/turn_controller.gd` + `tests/ui_turn_flow_test.gd` | M4.3、M4.1b | ★★ | **1–1.5h** | ①点「结束回合」→ `end_turn()` → 循环 `ai_step()` 直到对方回合结束 → 回到玩家回合，全程 UI 不卡死<br>②AI 行动期间输入被遮罩（点牌无效）<br>③`is_over()` 为真时弹结算面板，文字取 `outcome()`（WIN/LOSE 都要能显示），按钮「再来一局 / 回主菜单」可用 |
| **M4.6** | **动画与反馈**（Tween，可整体关闭） | `src/ui/fx.gd`（`play_damage / play_attack / play_card_fly / play_turn_banner`，全部可 `await` 也可跳过）<br>设置项 `fx_enabled` | M4.3、M4.4b、M4.5 | ★★ | **1.5–2h** | ①`fx_enabled = false` 时所有动画函数立即返回、对局手感与无动画一致（自动化：跑一局 turn 数不变）<br>②动画期间数据已落地（先改数据后播动画），关掉动画不改变任何结算结果<br>③连续快速点两次出牌不会重复触发动画（防重入） |
| **M4.7** | **主菜单 / 关卡选择** | `scenes/main_menu.tscn`（或代码构建）<br>`src/ui/main_menu.gd`<br>`src/ui/level_select.gd`（读 `DataLoader.load_enemies()`） | M4.0、M4.9a | ★ | **0.5–1h** | ①启动进主菜单，按钮：新游戏 / 继续（有存档才亮）/ 设置 / 退出<br>②关卡列表从 `data/tables/enemies.json` 生成，条目数 == 数据条数（改 JSON 后重启界面跟着变）<br>③选关 → 进场 → 打完 → 回主菜单，全流程无报错（3 个场景来回切 3 次 `is_instance_valid` 检查通过） |
| **M4.8** | **设置**：音量、动画开关、语言（v1 只有中文，占位） | `src/ui/settings.gd`<br>`user://settings.cfg`（`ConfigFile`） | M4.6 | ★ | **0.5–1h** | ①改动后立即生效并写入 `user://settings.cfg`；重启程序后读回（重启是人工步骤，配置文件内容可机器比对）<br>②音量走 `AudioServer.set_bus_volume_db`，静音时 `0` 不报错<br>③语言下拉只有「简体中文」且不崩溃；选其它值不会写坏配置 |
| **M4.9a** | **存档：结构 + 读写 + 校验** | `src/core/save_system.gd`：`SAVE_VERSION := 1`、`save_game(state: Dictionary, slot: int) -> bool`、`load_game(slot: int) -> Dictionary`、`has_save(slot) -> bool`<br>`tests/save_test.gd` | M4.1a（存档内容来自 `snapshot()`） | ★★ | **1–1.5h** | ①`save_test` 全绿（≥10 项）：存→读内容一致（深比较）、版本号写入正确、缺字段被拒、写 `user://` 而非 `res://`<br>②存档路径打印出来是 `user://saves/slot1.json` 实际落在 `%APPDATA%\Godot\app_userdata\...`（`res://` 打包后只读，写必失败）<br>③core 里不出现任何 `Control`（`grep`/人工确认） |
| **M4.9b** | **存档：版本迁移 + 损坏兜底** | `src/core/save_system.gd`：`_migrate(from: int, data: Dictionary) -> Dictionary`、坏档备份 + 重置<br>`tests/save_migrate_test.gd` | M4.9a | ★★ | **1–1.5h** | ①`save_migrate_test` 全绿（≥8 项）：v0 假档能升到 v1、未知高版本被拒（不是崩溃）<br>②手工把存档改成乱码 → 游戏不崩、自动备份成 `*.bad`、提示「存档损坏已重置」<br>③迁移用**测试内构造的旧档**，不依赖仓库里留旧文件 |

**合计 ≈ 15–22 h 净编码**（对照 BACKLOG 的 G 42h + H 9h = 51h，校准后约 ÷2.5）。
按每天 3–4 h 净编码 ≈ **5–7 个工作日**；实际日历时间由**返工轮数**决定，不由打字速度决定。

### 2.1 三处必须写死的实现约束

- **M4.0 的 `.tscn` 用手写最小结构**：只有一个根节点 + 一个 `script` 引用，控件全部在 `main_screen.gd` 的 `_ready()` 里用代码建。理由见 §4 坑 2。不要为了让编辑器好看而把 200 个节点写进场景文件。
- **M4.1a 的 `snapshot()` 必须是纯读**：不允许在建快照时顺手 tick buff、顺手抽牌。UI 会高频调用它（每次刷新一次），任何副作用都会变成「看一眼就改变游戏」。
- **M4.9a 的存档内容 = `snapshot()` 的子集 + 关卡/牌组 id**：存档只存「重建一局所需的最小信息」，不要把整个 `Battle` 序列化。理由：`Battle` 里有 `Card`/`Unit`/`Board` 三层引用，直接序列化等于把 core 的内部结构钉死成文件格式，以后改字段就要写迁移。

### 2.2 每一块的统一开工 / 收工动作

M4 的每一块都按同一个模板走，不要临时发明流程。这一节的目的是把「返工轮数」压到 1 轮以内——M3 的实测已经证明，日历进度的瓶颈是 round-trip 次数，不是打字速度。

| 阶段 | 动作 | 判据 |
|---|---|---|
| 开工前 | 报预计用时：`预计 X–Y h（依据：§M4.N 难度 ★★ + 交付物 N 个文件）` | 与上表区间对得上；对不上先说清为什么 |
| 开工前 | 跑一次 `$env:NO_PAUSE=1; .\run_tests.bat`，确认基线全绿 | 拿到「改动前」的绿，否则以后分不清是谁弄红的 |
| 写代码 | 只碰本块「交付物」列出的文件；**想改别的文件先停下来说明** | `git status` 里不出现计划外文件 |
| 自测 | 本块的 `tests/ui_*_test.gd` 或 `tests/save_*_test.gd` 绿；无 `[FAIL]`、无 `SCRIPT ERROR` | 退出码 0 **不等于**通过，必须看终端输出 |
| 收工 | 跑 `run_tests.bat` 全绿 + 本块三条验收判据逐条打勾 + 截一张图 | 三项都齐才算 done |
| 收工 | 记录实际用时；偏差 >2 倍时写一句原因 | 便于下一块的估时继续校准 |

**测试文件的落位规则沿用 M3**：新测试先写进 `tests/pending/`，主套全绿后 `git mv` 到 `tests/` 才启用；启用时同步文件末尾的 `EXPECTED_CHECKS`。不要让 UI 阶段出现「测试写在 pending 里躺了三块」的情况——UI 的坑就是靠这些断言提前暴露的。

### 2.3 依赖图（关键路径）

```
M4.0 骨架+字体
  └─ 所有场景都继承它的 Theme（不做则后面全部返工）

M4.1a 快照/合法动作
  ├─ M4.2 手牌 UI ─┬─ M4.3 出牌交互
  ├─ M4.4a 战场只读 ── M4.4b 战场交互 ──┐
  └─ M4.9a 存档读写 ── M4.9b 迁移兜底    │
                                          │
M4.1b AI 单步 ── M4.5 回合流转与结算 ──────┴─ M4.6 动画（可关）
                                                  ├─ M4.8 设置
M4.9a ── M4.7 主菜单（「继续」按钮依赖存档）
```

**关键路径**：`M4.0 → M4.1a → M4.4a → M4.4b → M4.6`。这条链上任何一块延期，后面全部顺延。
**可并行/可跳过**：`M4.8 设置`、`M4.9a/b 存档`、`M4.7 主菜单` 都不在任何 UI 交互的必经路上——实在卡住时可以先做「一开局直接进战斗」的可玩版本，把这三块挪到后面，M4 的验收口径照样能过（只有第 3 条「能存能读」需要 M4.9）。

---

## 3. 建议施工顺序与理由

线性路线（一条，别并行开两条 UI 线）：

```
M4.0 骨架+字体
  → M4.1a 快照/合法动作   → M4.1b AI 单步
  → M4.2 手牌 UI          → M4.4a 战场只读
  → M4.3 出牌交互         → M4.4b 战场交互
  → M4.5 回合流转与结算
  → M4.6 动画（可关）
  → M4.7 主菜单 / 关卡选择
  → M4.8 设置
  → M4.9a 存档读写        → M4.9b 迁移与兜底
```

为什么这么排：

1. **骨架和字体必须是第一步**。字体是**全局 Theme**，后面每一张界面都继承它；如果先做手牌再发现中文是方块，所有卡面尺寸、行高、按钮内边距都要重排一遍——等于把已经做完的界面全部返工。同理 `assets/` 和窗口尺寸也要一次定死。
2. **core 适配层（M4.1a/1b）排在所有 UI 之前**。UI 拿不到快照和合法动作，就只有两条路：直接读 `battle.hand` / `battle.board.slots`（等于把 core 的内部结构变成 UI 的依赖，以后重构 core 就全崩），或者自己在 UI 里重写一遍「哪些目标合法」（等于规则有两份实现，必然对不上）。这两条都是烂尾的开始。
3. **先「看得见」再「点得动」**（M4.4a 在 M4.3/M4.4b 之前）。只读战场能先把布局、格子坐标、缩放这些问题暴露出来；带着交互一起调，出错时你分不清是「画错了」还是「点错了」。
4. **动画放在功能稳定之后**（M4.6 在 M4.3/4.4b/4.5 之后）。Tween 是最容易随布局改动而反复重做的一层，先做动画等于每改一次格子尺寸就重调一次位移曲线。设成「可关」也是为了这条：动画出问题时能一键退化成无动画版本继续验收。
5. **存档放最后**（M4.9）。它是唯一一块**不阻塞「能玩」**的活：界面先能打通一整局，再来解决「关掉还在」。反过来先做存档，会遇到「存什么字段」还没定（因为快照还没定型）的问题。

### 3.1 三条「看着更快的错路」

这三条在别的项目里都真实发生过，写下来是为了别重复：

| 错路 | 为什么看着快 | 实际后果 |
|---|---|---|
| **先做交互再做布局**（直接上手 M4.3，跳过 M4.4a） | 「反正最后都要点，边做边看布局」 | 布局改了 3 次 → 坐标硬编码的点击判定跟着改 3 次 → 每轮都要人工点一遍验证，返工量比先做只读布局大得多 |
| **UI 直接调 `_ai()` / 直接读 `battle.hand`**（跳过 M4.1a/1b） | 省 2–3 h，「这些字段反正是 public 的」 | core 从此被 UI 钉死：想改手牌容器、想给 AI 加流派，每一次都要连带改 UI。M3.6 元素 v3 就是因为早期结构没抽象才改那么久 |
| **一次性把 11 个界面全搭出来再统一调**（一次开 5 条线） | 「先把架子搭完」 | 字体/主题/刷新策略任何一个定晚了，5 个界面一起返工；而且没有一块是「可验收」的，进度无法判断 |

**一条反向判据**：如果某一块做完，你**没法用一条命令或一个截图证明它成了**，说明这块切大了——回去拆。

---

## 4. M4 的风险与坑

### 坑 1：Godot 默认字体没有中文 → 满屏方块

- 现象：所有 Label 显示成 `□□□□`，日志里看不出来，只有截图能发现。
- 已知可行方案：`SystemFont.new()` + `font_names = PackedStringArray(["Microsoft YaHei", "SimHei", "Noto Sans CJK SC", ...])`，`allow_system_fallback = true`。`src/ui/ui_theme.gd` 已经实现（`UiTheme.make_font()` / `make_theme()` / `font_health()`）。
- **坑中坑**：`has_char()` 的入参是 **int 码位**，不是字符串。写成 `f.has_char("中")` 会静默永远返回 false（或直接报类型错），正确写法是 `"中".unicode_at(0)`。`UiTheme.font_health()` 里已经踩过这个坑，照抄那行即可。
- 兜底：把 `font_health()` 接到 `tools/check_font.gd`，M4.0 的验收就有一条**机器可验证**的判据，不依赖人眼看截图。

### 坑 2：`.tscn` 手写 vs 编辑器生成

| 做法 | 好处 | 代价 |
|---|---|---|
| 编辑器拖出来的 `.tscn` | 所见即所得，节点树清楚 | 文件几百行、带 `uid://` 与 `ext_resource`、**几乎无法 review diff**、两个人改同一场景必冲突 |
| **手写最小 `.tscn`**（推荐） | 文件 10–20 行，diff 干净，改布局就是改一个脚本 | 编辑器里看不到节点树（但 M4 的布局本来就该由代码算，见坑 4） |

**结论**：`scenes/*.tscn` 只放「根节点 + 一个 script」，所有控件在脚本里建。副作用是要接受「在编辑器里打开场景是空的」——这是刻意换来的可维护性。真需要可视化调的场景（M5 之后的美术向界面）再单独开编辑器模式。

### 坑 3：UI 直接摸 `Battle` 的内部字段，core 就再也改不动了

- 典型写法：`battle.hand.size()`、`battle.board.slots["front"][1]`、`battle.energy`。这些字段名一旦被 UI 依赖，以后想改 `hand` 的容器类型、想给能量加个「临时能量」，就要改一圈 UI。
- 对策：**UI 只吃 `snapshot()` 返回的 Dictionary**，结构由 core 定义、随 core 演进；字段名变化只改 `snapshot()` 和 UI 的读取处，不动 UI 的布局逻辑。
- 自查命令（M4 期间任何一块做完都跑一次，**两条都应为空**）：

```powershell
#1) UI 里不许有裸字段读取（方法调用不受影响，因为模式要求紧跟 .字段名 且不带括号）
Select-String -Path src\ui\*.gd -Pattern 'battle\.(hand|deck|discard|board|energy|player|enemies)\b(?!\s*\()'
#2) core 里不许出现界面类型
Select-String -Path src\core\*.gd -Pattern '\b(Control|Node2D|Node|Tween|Theme)\b'
```

第一条空 = UI 只经方法与 `snapshot()` 取数据；第二条空 = core 没有倒挂依赖界面。两条都是**空结果即通过**，不需要人工判断。

### 坑 4：在 `_process` 里每帧重建控件 → 卡成 PPT

- 现象：一进战斗帧率掉到 20 以下，越打越卡（旧控件没 `queue_free` 干净）。
- 对策：**只在状态变化时刷新**。判断变化不一定要新增 core API，UI 侧自己算一个「签名」比较即可：`turn + energy + hand.size() + 场上存活单位数 + 双方 HQ 血量`，与上次不同才重建；日志只在 `log_lines.size()` 变化时追加文本（不重排整个日志）。
- 另一条：`_process` 只做「读签名 + 比较」，重建放到事件触发点（点出牌、`end_turn` 返回之后）。UI 是回合制的，本来就不该有逐帧逻辑。

### 坑 5：截图能证明「画出来了」，证明不了「点得动」

- 截图/录屏只能证明静态排版和中文字形，**证明不了**「拖到非法位置会弹回」「能量不够的牌点不动」「AI 回合输入被遮罩」。
- 对策：把交互逻辑抽成**不继承 `Control` 的 controller**（`hand_controller.gd` / `play_controller.gd` / `board_controller.gd` / `turn_controller.gd`），入参是「快照 + 一次点击事件」，返回值是「要调哪个 core 方法」。这样就能用现有的 `extends SceneTree` 测试直接 `new()` 出来断言，不需要开窗口。
- **绘制层**（`*_view.gd`）只负责「把 controller 算好的状态画出来」，它不被测试覆盖是可以接受的——前提是它不含任何判断逻辑。

### 坑 6：存档写在 `res://` 下，导出后必失败

- `res://` 在导出的 exe 里是**只读的打包资源**，`FileAccess.open("res://save.json", WRITE)` 在编辑器里能过、打包后直接失败（而且是在玩家机器上失败）。
- 对策：一律 `user://`（Windows 上落在 `%APPDATA%\Godot\app_userdata\<项目名>\`）。验收判据里要把「实际落盘路径」打出来人工看一眼，别只信 `open()` 没报错。
- 连带：设置文件同样走 `user://settings.cfg`，不要塞进 `res://data/`。

### 坑 7：现有测试都是 `extends SceneTree`，UI 没法照抄

- 现有 17 个测试文件都是 `--script` 起的 `SceneTree` 脚本，主循环都不跑，`Control` 的 `_ready()`、布局、Tween 一概不执行 → 对 `Control` 写断言必然测不到东西（要么全空，要么 `is_inside_tree()` 为假）。
- 对策（同坑 5）：**逻辑与绘制分离**。逻辑层是 `RefCounted`，测试覆盖它；绘制层薄到「只赋值」。
- 不要试图给 UI 引入 `GUT` 之类的测试框架：项目现在是零插件、`run_tests.bat` 三段式判定，引入插件会同时改动 CI、`preflight.ps1` 和学员的心智负担，收益远小于成本。

### 坑 8：字体依赖系统 → 换台机器就可能是方块

- `SystemFont` 是从**操作系统**里找字体，你自己的 Win 有微软雅黑，别人可能没有（尤其 Linux/Mac、精简版 Windows、未来导出的 Web 版）。
- M4 不解决（M4 的目标是「你自己能玩」），但**必须在 `assets/fonts/README.md` 里写清**：当前走系统字体、依赖 `Microsoft YaHei`、发布前要决定是否内嵌 `Noto Sans SC`（SIL OFL，可商用，约 10MB）。这条写进 README，M5 才不会漏。
- 顺带：`font_names` 列表要保留跨平台兜底项（`Noto Sans CJK SC` / `PingFang SC` / `sans-serif`），不要只写微软雅黑。

---

## 5. 验收口径（M4 完成 = 以下全部同时成立）

| # | 判据 | 怎么验 |
|---|---|---|
| 1 | **能开窗口用手打完一整局**：主菜单 → 选关 → 打完 → 结算 → 回主菜单，中间不报错、不卡死 | 人工走查 3 局（赢 1 / 输 1 / 中途退出 1），终端无 `SCRIPT ERROR` |
| 2 | **中文全部正常**：所有界面文字是字，不是方块 | `tools/check_font.gd` 退出码 0 + 3 张截图 |
| 3 | **能存能读**：关掉程序 → 重开 → 「继续」能回到存档点 | 存档文件落在 `user://`，读回后 turn / 血量 / 手牌数与存档前一致 |
| 4 | **坏档不崩**：手工改坏存档 → 提示 + 备份 + 重置，游戏能继续玩 | 人工 1 次（`*.bad` 文件出现） |
| 5 | **`run_tests.bat` 仍 ALL GREEN**，且新增测试已从 `tests/pending/` 迁到 `tests/`，`EXPECTED_CHECKS` 同步 | `$env:NO_PAUSE=1; .\run_tests.bat` → `===== ALL GREEN =====` |
| 6 | **core 里没有界面代码**：`src/core/` 无 `Control` / `Node` / `Tween` / `signal` / `theme`；UI 无裸字段读取 | §4 坑 3 的 `Select-String` 两条命令都为空 |
| 7 | **数据仍全部来自 `data/`**：关卡、卡牌名、元素名没有一处写死在 `src/ui/` | `Select-String -Path src\ui\*.gd -Pattern '步兵|火球|关卡一'` 应为空（中文卡名不应出现在 UI 脚本里） |
| 8 | 文档同步：`docs/implementation-tasks.md` 新增 M4 段、`devlog.md` 记一笔、`README.md` 写明「怎么开窗口玩」 | 人工读一遍 |

---

## 6. 不在 M4 范围（防止范围膨胀）

| 排除项 | 为什么不做 | 什么时候 |
|---|---|---|
| **多语言全量翻译**（BACKLOG G11） | 翻译是纯体力活，且要在文案定稿之后做；现在卡牌文案还在改（M3.4 还在扩池） | M5 之后，或永远不做（只留语言字段占位） |
| **联网 / 对战** | 需要服务端、需要状态同步协议，与「能给人看」无关 | 不做 |
| **美术资源**（卡面图、立绘、九宫格边框、图标集） | 需要美术产出；M4 的界面用纯色块 + 字体排版就够「能给人看」 | M5 或之后视情况 |
| **关卡编辑器** | 数据是 JSON，手改比做编辑器快 | 不做 |
| **平衡调参 / 数值优化** | 这是 M3.8 的活；M4 期间不许为了「界面里打赢太轻松」去改 `data/tables/*.json` 的数值 | M3.8 |
| **音效**（BACKLOG G9） | 需要音频素材；没有素材的「音效任务」只会变成找免费音源的时间黑洞 | M5 |
| **新手引导**（G10） | 需要先有稳定的界面结构；引导本质是「脚本化的点击序列」，界面一改就全废 | M5 |
| **导出打包 / 商店页 / 演示 GIF**（BACKLOG I 系列） | 明确属于 M5「发布」 | M5 |
| **重构 core** | M4 只允许新增接口，不允许顺手重构已有语义 | M5 之前禁止 |

---

## 附：与 BACKLOG G/H 的对应关系

| BACKLOG | 原估 | 本规划 | 校准后 | 说明 |
|---|---|---|---|---|
| G1 主场景 + UI 骨架 | 3h | M4.0 | 1–1.5h | 场景只有根节点 + 脚本，控件代码建 |
| G2 手牌 UI | 4h | M4.2 | 1–2h | 含换牌，逻辑抽成 controller 后可测 |
| G3 出牌交互 | 6h | M4.3 | 1.5–2h | 目标高亮靠 `legal_targets`，UI 不重写规则 |
| G4 战场 UI | 5h | M4.4a + M4.4b | 3.5–5h | 只有这一块拆成两半（只读 / 交互） |
| G5 动画 Tween | 6h | M4.6 | 1.5–2h | 一律可关，跳过即无动画 |
| G6 回合提示 | 2h | M4.5 | 1–1.5h | 合并了胜负结算面板 |
| G7 主菜单 / 关卡选择 | 3h | M4.7 | 0.5–1h | 关卡列表直接读 `enemies.json` |
| G8 设置 | 2h | M4.8 | 0.5–1h | 音量 / 动画开关 / 语言占位 |
| G9 音效 | 3h | — | — | 移出范围（无素材） |
| G10 新手引导 | 3h | — | — | 移出范围 |
| G11 多语言 | 5h | — | — | 移出范围（只留占位） |
| H1–H4 存档 | 9h | M4.9a + M4.9b | 2–3h | 只存「重建一局的最小信息」 |
| **新增（BACKLOG 没有）** | — | **M4.1a + M4.1b** | 2–3h | 快照/合法动作 + AI 单步，是 UI 的隐藏依赖 |
