# 元素反应卡牌战斗（reaction-card-battler）

> **先看 [START_HERE.md](START_HERE.md)（索引）；接手/换人先看 [docs/HANDOFF-2026-11-23.md](docs/HANDOFF-2026-11-23.md)（现状 + 纪律 + 每块的备课与落地记录）。**

**元素反应 + KARDS 式战线卡牌战斗** · Godot 4.7 + GDScript —— 一个用作**工程练习**的回合制卡牌项目：规则内核可测试、内容数据驱动、界面最后才做。

> 这不是"做一个游戏"，是"用一个游戏练工程"。
> 项目计划见 [项目计划_知识储备与行动大纲.md](项目计划_知识储备与行动大纲.md)。

当前状态：**M1 / M2 / P1（E7a）/ P2（E7b）/ M3.1 / M3.2 / M3.3 / M3.3b / M3.5 / M3.7 全部已完成**，
主套 **18 个测试文件 485 项全绿**；`tests/pending/` 只剩 **1 份红基线**：`ai_guard_test`（14 项）。
**它现在的状态是 `[HUNG]` 而不是「6 红」**——学员 WIP 里有个死循环，跑不完（见 [HANDOFF §22](docs/HANDOFF-2026-11-23.md)）。
当前任务：**M3.4 前置块 · AI 选目标**（清 M3.2 遗留的「AI 遇 Guard 白扔回合」）——
任务卡、施工思路、第一轮评审全在 [docs/implementation-tasks.md §39](docs/implementation-tasks.md)（§39.6 是评审，§39.7 是红绿指纹）；
做完它主套变成 **19 文件 499 项**。
之后的活已经在 GitHub 上开成 issue（milestone **M3**）：[#2](https://github.com/CoIumblna/reaction-card-battler/issues/2) 卡池 20+ 种 · [#3](https://github.com/CoIumblna/reaction-card-battler/issues/3) 元素 v3 · [#4](https://github.com/CoIumblna/reaction-card-battler/issues/4) AI 打指令卡 · [#5](https://github.com/CoIumblna/reaction-card-battler/issues/5) 平衡调参 · [#6](https://github.com/CoIumblna/reaction-card-battler/issues/6) 收尾打 tag；当前块是 [#1](https://github.com/CoIumblna/reaction-card-battler/issues/1)。
每完成一块关一个 issue，仓库首页的进度条自动走。详见 [HANDOFF §21.3](docs/HANDOFF-2026-11-23.md)。
跑 `tools\check.bat` 看进度表 + 检查点 + pending 验收基线（它还会告诉你下一步做什么）。

### 测试文件怎么分（按"被测单元"，不是按功能点）

> 每个测试文件末尾会**硬校验"应执行的检查项数"**，对不上直接判红 —— 防止"少跑了几条却全绿"。

| 文件 | 测谁 | 项数 | 现在红 |
|---|---|---|---|
| `tests/data_test.gd` | 数据链路：JSON 加载、元素工具、反应表、状态表、牌库内容 | 46 | 0 |
| `tests/unit_test.gd` | 单位数值：护盾、致死、治疗、附着量、buff 生命周期 | 21 | 0 |
| `tests/damage_test.gd` | 纯算法：倍率、floor、免疫、effects、触发方向 | 23 | 0 |
| `tests/board_test.gd` | 棋盘：三条线、HQ、容量、位置查询 | 38 | 0 |
| `tests/combat_test.gd` | 移动 / 攻击与反击 / 行动花费 / 前线独占 / 死亡移除 | 59 | 0 |
| `tests/battle_m1_smoke_test.gd` | M1 流程：回合推进、能量、附着、伤害转接 | 58 | 0 |
| `tests/battle_m2_test.gd` | M2 流程：Kredit / 部署 / 召唤失调 / HQ 胜负 / 敌方 AI / 自动对局 | 63 | 0 |
| `tests/status_test.gd` | C8：dot / disable / 反应挂状态 | 12 | 0 |
| `tests/order_test.gd` | E14：指令卡目标（数据驱动 target）+ 死亡移除 | 35 | 0 |
| `tests/deck_test.gd` | E7a：弃牌堆 / 抽干疲劳 | 20 | 0 |
| `tests/opening_test.gd` | P2：起手 4/5 + 首回合抽牌 + mulligan | 25 | 0 |
| `tests/keywords_test.gd` | M3.1：行动经济 + 关键词 + 闪击 | 17 | 0 |
| `tests/guard_test.gd` | M3.2：Guard 相邻保护 | 8 | 0 |
| `tests/unit_class_test.gd` | M3.3：兵科 / 空军越线 / 炮兵与轰炸机无视 Guard | 21 | 0 |
| `tests/air_intercept_test.gd` | M3.3b：战斗机拦截轰炸机 | 3 | 0 |
| `tests/deck_build_test.gd` | M3.5：卡组构筑 39+1 | 11 | 0 |
| `tests/stat_mod_test.gd` | M3.7：defense_down 数值 | 7 | 0 |
| `tests/stat_system_test.gd` | M3.7：通用 stat 系统 | 18 | 0 |
| `tests/pending/ai_guard_test.gd` | **M3.4 前置块待启用**：AI 选目标的 Guard 规则（S1–S6） | 14 | `[HUNG]` |
| `tests/run_battle.gd` | 不是测试：手动跑一局看日志 | — | — |

> 主套合计 **485 项 / 18 文件**；`ai_guard_test` 启用后 **499 项 / 19 文件**。

> `run_tests.bat` 和 CI 都是**自动发现** `tests/*_test.gd`（`tests/pending/` 不算），加测试文件不用改脚本。

> **每个单文件跑都带 90 s 硬性超时**：超时杀掉进程并在日志尾部写 `[HUNG]`，该文件判红。
> 以前死循环会让整场测试永远卡住、看起来像环境坏了；现在它是一条明确的失败。
> `run_tests.bat`、`tools\check.bat`、CI 三个入口都有这个超时——只要有一个入口没有，整条工具链就还是会被死循环挂死。
> 详见 [HANDOFF §22](docs/HANDOFF-2026-11-23.md)。

## 玩法（三行版，详细设计见 docs/game-design.md）

> 参考 **KARDS** 路线：回合制卡牌战斗，费用每回合增长，单位上场后对撞，用**元素反应**打出额外伤害。
> **M1 阶段不做战线**，只验证「出牌 → 伤害 → 元素反应」这条管线；M2 才加部署、战线、移动。

- 详细玩法规格：**[docs/game-design.md](docs/game-design.md)**
- KARDS 规则底稿：**[docs/kards-rules-reference.md](docs/kards-rules-reference.md)**
- 元素反应数值：**[docs/element-reactions.md](docs/element-reactions.md)**（v3 待做，见 [docs/element-reactions-v3.md](docs/element-reactions-v3.md)）
- 为什么 M1 不做战线：**[docs/adr/002-m1-scope.md](docs/adr/002-m1-scope.md)**
- 代码怎么实现：**[docs/implementation-tasks.md](docs/implementation-tasks.md)**
- M3 规格（关键词/兵科/卡池/平衡模拟）：**[docs/m3-scope.md](docs/m3-scope.md)**
- M4 规划（界面 + 存档）：**[docs/m4-plan.md](docs/m4-plan.md)**
- **接手/换人先读：**[docs/HANDOFF-2026-11-23.md](docs/HANDOFF-2026-11-23.md)**（现状 / 纪律 / 每个块的备课与落地记录）

---

## ⚠️ 这个仓库是 kata：测试是规格，实现你来写

规则只有一条：**先自己写 20 分钟，卡住了再看参考实现。看完把窗口关掉，凭记忆重写一遍。**

### 实现顺序（M1–M3 大部分已完成，当前任务）

| 任务 | 你要实现 | 验收 |
|---|---|---|
| ✅ M3.1 关键词/闪击 | 行动经济拆双标志、`blitz`、`guard`、兵科传递 | `keywords_test` 17/17（已完成） |
| ✅ M3.2 Guard | 相邻保护、被保护者不可被选、Guard 互不保护 | `guard_test` 8/8（已完成） |
| ✅ M3.3 兵科 | 空军越线、炮兵/轰炸机无视 Guard、无反击规则 | `unit_class_test` 21/21（已完成） |
| ✅ M3.3b 拦截 | 战斗机拦截轰炸机 | `air_intercept_test` 3/3（已完成） |
| ✅ M3.5 卡组构筑 | `DataLoader.load_deck()` 39+1 | `deck_build_test` 11/11（已完成） |
| ✅ M3.7 通用 stat | `Battle.stat_of(unit, stat)` | `stat_system_test` 18/18（已完成） |
| **M3.4 前置：AI 选目标** | `_ai_attack_targets()` / `_ai_attack()` + `_is_guarded()` 两个守卫 | `ai_guard_test` 14/14，主套 499/499 |

作业单、施工思路、第一轮评审都在 [docs/implementation-tasks.md §39](docs/implementation-tasks.md)：
§39.1a 三档判定表 · §39.5 十条坑 · §39.6 评审（三处必改 + 行号）· §39.7 五条红绿指纹 · §39.8 自查判据。

> M1/M2 的参考实现在 `..\_reference_battler\src\core\`（7 个文件，没有 `damage.gd`——那个要你自己从零想）；M3.4 这份在 `..\_ref_ai_guard`（detached worktree，已验过 499/499）。
> 参考实现都在仓库外，因为它就在那儿，你会在第 3 分钟就去看。

---

## 快速开始

```powershell
# 在项目根目录执行；脚本里的 Godot 路径是"相对仓库"的，仓库整体移动后不用改
$g = "..\..\..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
# 1. 导入项目（第一次必须做，会生成 .godot/ 缓存）
& $g --headless --path . --import

# 2. 跑测试（唯一验收入口：主套 + pending 基线 + 详细自检三段式）
#    严格版：run_tests.bat —— 每个文件要求 PASS + 无 [FAIL] + 无 SCRIPT ERROR + 无 [HUNG]
#    看进度：tools\check.bat —— 进度表 + 检查点 + 下一步建议（同样带 90s 超时）
run_tests.bat

# 2b. 只跑某一个文件（调试时用）
& $g --headless --path . --script res://tests/guard_test.gd

# 2c. 数据校验 + 平衡模拟（加过卡、改过数值之后必须跑）
& $g --headless --path . --script res://tools/validate_data.gd
& $g --headless --path . --script res://tools/balance_sim.gd -- --games 200 --seed 1

# 3. 看一场自动战斗的完整日志
& $g --headless --path . --script res://tests/run_battle.gd
```

> 改过 `.gd` 之后如果出现「改了没反应」，先重跑一次 `--import`：`--script` 会吃旧的类缓存。

图形界面也能打开：Godot → Import → 选 `project.godot`（目前没有主场景，只能看文件树，M4 才做界面）。

### 第一次提交到 GitHub

```bash
git init
git add .
git commit -m "feat: 项目骨架 + 战斗内核 + 24 项冒烟测试"
git branch -M main
git remote add origin https://github.com/<你的用户名>/reaction-card-battler.git
git push -u origin main
```

> 如果 git 报 `Please tell me who you are`，先配置身份：
> `git config --global user.name "你的名字"` / `git config --global user.email "你的邮箱"`
>
> 本仓库 remote 走 `ssh://git@ssh.github.com:443`（22 端口不通时用 443）。首次 push 若报 `Host key verification failed`，
> 先 `ssh-keyscan -p 443 ssh.github.com >> %USERPROFILE%\.ssh\known_hosts`，并在 `~/.ssh/config` 为 `ssh.github.com` 补 `Port 443` + `IdentityFile`。
> 细节见 [HANDOFF §21.2](docs/HANDOFF-2026-11-23.md)。

---

## 目录结构

```
reaction-card-battler/
├── project.godot            # Godot 项目
├── run_tests.bat            # ★ 唯一验收入口（主套 + pending 基线 + 详细自检）
├── run_battle.bat           # 手动跑一局看日志
├── devlog.md                # 每周 3 行开发日志
├── START_HERE.md            # 第一次进来从这读
├── data/                    # 所有"内容"（改这里不用改代码）
│   ├── tables/              # 实际数据（elements / reactions / cards / statuses / enemies）
│   │   └── cards.json       # ← 加卡只改这里（15 种 / 展开 57 张）
│   └── schema/README.md     # 字段规范（数据契约）
├── tools/                   # 工具链（详见 tools/README.md）
│   ├── check.bat            # 进度表 + 检查点 + 下一步建议
│   ├── preflight.bat        # 详细自检 13 项（EXPECTED_CHECKS / 工具自检 / 数据干净）
│   ├── validate_data.gd     # 数据校验器（加卡后必跑）
│   ├── balance_sim.gd       # 平衡模拟器（--games 200 --seed 1）
│   ├── card_lib.gd          # 卡牌读写 / 校验 / 行级手术（55 项自检）
│   ├── unit_maker.bat       # 单位卡图形制作工具（中栏 = 将来的手牌组件）
│   ├── test_card_view.gd    # 卡面组件回归（7 项）
│   └── check_font.gd        # 中文字体体检
├── docs/
│   ├── HANDOFF-2026-11-23.md    # ★ 接手必读：现状 / 纪律 / 每块的备课与落地
│   ├── implementation-tasks.md  # ★ 每个文件要做啥、用什么手段、怎么验收（作业单与评审也在这里，§39 = M3.4）
│   ├── brief-*.md               # 早期历史作业单（M3.5 / M3.7 / stat 系统；M3.4 已并入 implementation-tasks §39）
│   ├── review-*.md              # 早期历史评审（M3.1 / E7b；M3.4 已并入 implementation-tasks §39.6）
│   ├── game-design.md           # 玩法规格
│   ├── kards-rules-reference.md # KARDS 原版规则（事实底稿）
│   ├── element-reactions*.md    # 元素反应设计（v3 待做）
│   ├── m3-scope.md / m4-plan.md # M3 / M4 规划
│   ├── architecture.md          # 项目结构说明书
│   └── adr/                     # 架构决策记录（001 数据驱动 / 002 M1 范围 / 004 ADR 系列）
├── src/core/                # 纯逻辑，不碰 UI（学员写这里）
│   ├── element.gd           # 元素常量 + 配对键
│   ├── damage.gd            # 伤害与元素反应（纯函数）
│   ├── card.gd              # 卡牌数据模型
│   ├── buff.gd              # 状态效果
│   ├── unit.gd              # 战斗单位（HP/护盾/附着/buff/兵科/关键词）
│   ├── board.gd             # 棋盘（三条线 / HQ / 格位）
│   ├── reaction_table.gd    # 反应表查表
│   ├── status_table.gd      # 状态表（dot/冻结）
│   ├── data_loader.gd       # JSON 加载 + 卡组构筑 load_deck()
│   └── battle.gd            # 战斗流程（回合、出牌、伤害、自动战斗 AI）
├── src/ui/                  # 界面基座（M4 沿用）
│   ├── ui_theme.gd          # 全局主题（中文字体 / 配色）
│   └── card_view.gd         # 卡面组件（unit_maker 与 M4 手牌区共用）
└── tests/                   # 18 个文件 485 项（pending/ 是待启用的红基线）
    ├── data_test / unit_test / damage_test / board_test / combat_test
    ├── battle_m1_smoke_test / battle_m2_test / status_test / order_test
    ├── deck_test / opening_test / keywords_test / guard_test / unit_class_test
    ├── air_intercept_test / deck_build_test / stat_mod_test / stat_system_test
    ├── pending/ai_guard_test.gd   # M3.4 前置块待启用（14 项 / 6 红）
    └── run_battle.gd              # 手动跑一局看日志
```

---

## 工程规矩（不是建议，是要求）

1. `main` 永远能跑：跑一遍测试再提交
2. 一个功能一个分支，自己 review diff
3. 提交信息用 `feat: / fix: / test: / docs:`
4. 核心规则**先写测试再写实现**
5. 内容不进代码，全部进 `data/`
6. 每个里程碑打 tag（`v0.1`、`v0.2`…）
7. 每周日写 `devlog.md` 三行
8. 性能数据记进 README（M5 开始记）

---

## 第 1 周清单（Phase 0，已完成，留作历史）

- [ ] fork/建仓库，第一次 push 成功
- [ ] 跑四个测试文件，确认是红的（共 86 项 / 64 失败）
- [ ] 实现 `Element` 三个函数 → `data_test` [3] 全绿
- [ ] 填 `docs/element-reactions.md`：反应表 + 附着规则 + 3 个手算例子
- [ ] 把设计写进 `data/tables/reactions.json`
- [ ] 实现 `Card` + `DataLoader` → `data_test` [1][2] 全绿
- [ ] 实现 `Damage.compute` → `damage_test` [D1–D6] 全绿
- [ ] 写 `docs/adr/001-data-driven.md`
- [ ] 写第一行 devlog

---

## 路线图

| 里程碑 | 目标 | 状态 |
|---|---|---|
| M1 | **无战线**：跑通「出牌 → 伤害 → 元素反应」+ 两套测试 | ✅ 完成（155 项） |
| M2 | **加部署 + 战线（支援/前线）+ 移动 + 行动花费 + 敌方 AI + 状态效果**，变成 KARDS-lite | ✅ 完成（320 项） |
| M3 | **关键词（闪击/Guard）+ 兵科 + 卡组构筑 + 通用 stat + 卡池 + 平衡** | 🚧 进行中（485 项，剩 M3.4 前置 / M3.6 元素 v3 / M3.8a / M3.8 / M3.9） |
| M4 | 可玩 UI + 存档迁移 | 前置已交付（中文字体 / 卡面组件 / 单位卡工具），未开工 |
| M5 | 发布 itch.io + 3 篇博客 | 未开始 |

详细周计划见 [项目计划_知识储备与行动大纲.md](项目计划_知识储备与行动大纲.md)。
