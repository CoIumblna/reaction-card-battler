# 元素反应卡牌战斗（reaction-card-battler）

> **先看 [START_HERE.md](START_HERE.md)** ——

一个用作**工程练习**的回合制卡牌战斗项目：规则内核可测试、内容数据驱动、界面最后才做。

> 这不是"做一个游戏"，是"用一个游戏练工程"。
> 项目计划见 [项目计划_知识储备与行动大纲.md](项目计划_知识储备与行动大纲.md)。

当前状态：**M1、M2 均已完成（8 个测试文件 320/320 全绿）**。测试（规格）和文档写好了，实现由你来写。
跑 `tools\check.bat` 看进度表 + 检查点 + pending 验收基线（它还会告诉你下一步做什么）。
下一块任务：**E14 指令卡（§25）→ E7 弃牌堆/洗回（§26）**，两份验收测试已放在 `tests/pending/`（`order_test` 27 项 / `deck_test` 18 项），做完后移到 `tests\` 启用，全套会到 **365 项**。
离线作业清单见 `docs/离线工作包-E14-E7-2026-11-22.md`。

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
| `tests/pending/order_test.gd` | **E14 待启用**：指令卡打棋盘单位（规格 §25） | 27 | 6 |
| `tests/pending/deck_test.gd` | **E7 待启用**：弃牌堆 / 牌库洗回（规格 §26） | 18 | 待实现 |`n| `tests/pending/keywords_test.gd` | **M3 待启用**：关键词框架 + 闪击 Blitz（规格 m3-scope §M3.1） | 9 | 6 |`n| `tests/pending/guard_test.gd` | **M3 待启用**：护卫 Guard（选项 A 暂定，ADR-004） | 6 | 2 |
| `tests/run_battle.gd` | 不是测试：手动跑一局看日志 | — | — |

> `run_tests.bat` 和 CI 都是**自动发现** `tests/*_test.gd`（`tests/pending/` 不算），加测试文件不用改脚本。

## 玩法（三行版，详细设计见 docs/game-design.md）

> 参考 **KARDS** 路线：回合制卡牌战斗，费用每回合增长，单位上场后对撞，用**元素反应**打出额外伤害。
> **M1 阶段不做战线**，只验证「出牌 → 伤害 → 元素反应」这条管线；M2 才加部署、战线、移动。

- 详细玩法规格：**[docs/game-design.md](docs/game-design.md)**（M1 范围已定，数值待你填）
- KARDS 规则底稿：**[docs/kards-rules-reference.md](docs/kards-rules-reference.md)**
- 元素反应数值：**[docs/element-reactions.md](docs/element-reactions.md)** ← 要你自己写
- 为什么 M1 不做战线：**[docs/adr/002-m1-scope.md](docs/adr/002-m1-scope.md)**
- 代码怎么实现：**[docs/implementation-tasks.md](docs/implementation-tasks.md)**`n- M3 规格草案（关键词/兵科/卡池/平衡模拟）：**[docs/m3-scope.md](docs/m3-scope.md)**

---

## ⚠️ 这个仓库是 kata：测试是规格，实现你来写

规则只有一条：**先自己写 20 分钟，卡住了再看参考实现。看完把窗口关掉，凭记忆重写一遍。**

参考实现放在仓库外：`..\_reference_battler\src\core\`（7 个文件，注意：没有 `damage.gd`，那个要你自己从零想）。
为什么放外面：因为它就在那儿，你会在第 3 分钟就去看。

### 实现顺序（M1/M2 已完成，当前任务）

| 任务 | 你要实现 | 验收 |
|---|---|---|
| **E14 指令卡** | `play_card`：棋盘目标校验（damage→敌方 / shield·heal→己方）+ 伤害后死亡移除 | `order_test` 27/27（规格 §25） |
| **E7 弃牌堆** | `discard` / `enemy_discard`、出牌入弃牌堆、满手抽牌进弃牌堆、牌库空洗回 | `deck_test` 18/18（规格 §26） |
---

## 快速开始

```powershell
# 在项目根目录执行；脚本里的 Godot 路径是"相对仓库"的，仓库整体移动后不用改
$g = "..\..\..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
# 1. 导入项目（第一次必须做，会生成 .godot/ 缓存）
& $g --headless --path . --import

# 2. 跑测试（8 个文件；退出码 0 = 该文件全绿，还要确认输出里没有 SCRIPT ERROR）
#    推荐：双击 tools\check.bat —— 跑全套 + 进度表 + E15/C8 检查点 + 下一步建议
#    严格版：run_tests.bat —— 每个文件要求 PASS + 无 [FAIL] + 无 SCRIPT ERROR
& $g --headless --path . --script res://tests/data_test.gd
& $g --headless --path . --script res://tests/unit_test.gd
& $g --headless --path . --script res://tests/damage_test.gd
& $g --headless --path . --script res://tests/board_test.gd
& $g --headless --path . --script res://tests/battle_m1_smoke_test.gd
& $g --headless --path . --script res://tests/battle_m2_test.gd
& $g --headless --path . --script res://tests/status_test.gd
& $g --headless --path . --script res://tests/combat_test.gd

# 3. 看一场自动战斗的完整日志
& $g --headless --path . --script res://tests/run_battle.gd
```

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

---

## 目录结构

```
reaction-card-battler/
├── project.godot            # Godot 项目
├── devlog.md                # 每周 3 行开发日志
├── data/                    # 所有"内容"（改这里不用改代码）
│   ├── tables/              # 实际数据
│   │   ├── elements.json
│   │   ├── reactions.json   # ← 第 1 周：换成你自己设计的反应表
│   │   ├── cards.json
│   │   └── enemies.json
│   └── schema/README.md     # 字段规范（数据契约）
├── tools/README.md          # 工具链说明（校验器/平衡模拟器，M2-M3）
├── docs/
│   ├── implementation-tasks.md  # ★ 每个文件要做啥、用什么手段、怎么验收
│   ├── game-design.md       # ★ 玩法规格（M1 已定，数值待你填）
│   ├── kards-rules-reference.md # KARDS 原版规则（事实底稿）
│   ├── architecture.md      # 项目结构说明书
│   ├── from-genshin-install.md  # 从原神安装包学到的结构（含"能抄/不能抄"）
│   ├── element-reactions.md # ← 第 1 周：要你亲手填的设计文档
│   └── adr/
│       ├── 001-data-driven.md   # ← 第 1 周：写你的架构决策
│       └── 002-m1-scope.md      # 为什么 M1 不做战线
├── src/core/                # 纯逻辑，不碰 UI
│   ├── element.gd           # 元素常量 + 配对键
│   ├── damage.gd            # 伤害与元素反应（纯函数，M1/M2 共用）
│   ├── card.gd              # 卡牌数据模型
│   ├── buff.gd              # 状态效果
│   ├── unit.gd              # 战斗单位（HP/护盾/附着/buff）
│   ├── reaction_table.gd    # 反应表查表
│   ├── status_table.gd      # 状态表（dot/冻结，M1）`n│   ├── data_loader.gd       # JSON 加载（TODO：加校验）
│   └── battle.gd            # 战斗流程（回合、出牌、自动战斗）
└── tests/
    ├── data_test.gd         # 数据链路（JSON 加载 / 元素工具 / 反应表）
    ├── unit_test.gd         # 单位数值（护盾/治疗/buff）
    ├── damage_test.gd       # 伤害算法（纯函数）
    ├── battle_m1_smoke_test.gd  # M1 流程（回合交换/能量/附着）
    ├── battle_m2_test.gd        # M2 流程（部署/召唤失调/HQ 胜负/敌方 AI）
    ├── board_test.gd            # 棋盘（三条线 / HQ / 位置）
    ├── combat_test.gd           # 移动 / 攻击与反击 / 前线独占 / 死亡移除
    ├── status_test.gd           # C8：dot / disable / 反应挂状态
    ├── pending/order_test.gd    # E14 待启用：指令卡（规格 §25）
    ├── pending/deck_test.gd     # E7 待启用：弃牌堆/洗回（规格 §26）
    └── run_battle.gd            # 手动跑一局看日志
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
| M2 | **加部署 + 战线（支援/前线）+ 移动 + 行动花费 + 敌方 AI + 状态效果**，变成 KARDS-lite | ✅ 完成（320 项；E14/E7 收尾任务见 §25/§26） |
| M3 | 关键词（闪击等）+ 卡组构筑 + 平衡模拟 | 未开始 |
| M4 | 可玩 UI + 存档迁移 | 未开始 |
| M5 | 发布 itch.io + 3 篇博客 | 未开始 |

详细周计划见 [项目计划_知识储备与行动大纲.md](项目计划_知识储备与行动大纲.md)。
