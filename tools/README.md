# tools/ —— 工具链

> 为什么工具要单独放：它们**不是游戏的一部分**，不打包进发行版，但每天都要用。
> 大厂里这块叫「构建管线 / 工具链」，是策划和程序交界的核心区域。

## 计划中的工具

| 文件 | 什么时候做 | 作用 | 输入 → 输出 |
|---|---|---|---|
| `add_unit_card.gd` | ✅ M2 | 生成一张单位卡并写回 `cards.json`（校验 id / 数值 / 元素 / 重复） | 命令行参数 → 追加一行 JSON |
| `validate_data.gd` | M2 | 校验 `data/tables/*.json` 的字段、枚举、引用是否存在 | JSON → 终端报错列表 |
| `balance_sim.gd` | M3 | 批量跑战斗（1 万场），统计胜率/回合数/卡牌使用率 | 数据表 → CSV 报告 |
| `export_report.gd` | M3 | 把模拟结果生成 Markdown 表格 | CSV → `docs/balance-report.md` |

### M4 期新增（图形化 / 界面基座）

| 文件 | 作用 | 备注 |
|---|---|---|
| `unit_maker.bat` + `unit_maker.tscn` + `unit_maker.gd` | **单位卡图形制作工具**（双击 `unit_maker.bat`）：左栏选卡 → 中栏预览卡面 → 右栏改数值 → `Ctrl+S` 写回 `cards.json` | 预览用的是 `src/ui/card_view.gd`，**和 M4 手牌区是同一个组件** |
| `card_lib.gd` | 卡牌数据的唯一格式入口：读 / 校验 / 序列化 / **行级手术**写回 | `add_unit_card.gd` 与图形工具共用它，格式只维护一份 |
| `test_card_lib.gd` | `card_lib.gd` 的自检（55 项）：读、插入、覆盖、删除、组合手术、校验、数值格式、**元素可选清单** | `run_tests.bat` 的 preflight 第 10 项会自动跑 |
| `test_card_view.gd` | `card_view.gd` 的回归（7 项）：主题共享 stylebox、**同屏多卡串色**、卡图路径约定 | preflight 第 12 项；防的是「单卡预览看不出来、一显示 5 张手牌全变一个色」 |
| `check_font.gd` | 中文字体体检：确认界面能把中文画成字而不是方块 | preflight 第 8 项；M4 所有界面都依赖它 |
| `src/ui/ui_theme.gd` | 全局主题（中文字体 / 配色 / 控件样式） | M4 每个场景 `theme = UiTheme.make_theme()` |
| `src/ui/card_view.gd` | 一张卡的外观组件（可复用） | 单位制作工具与 M4 手牌区共用 |

## add_unit_card.gd 用法

```bash
# 加一张 3 费 3/4 的火系单位
Godot_v4.x-stable_win64_console.exe --headless --path . --script res://tools/add_unit_card.gd -- \
    --id fire_tank --name 火焰坦克 --cost 3 --attack 3 --defense 4 --element fire --count 4

# 看用法
... --script res://tools/add_unit_card.gd -- --help
```

| 参数 | 必填 | 说明 |
|---|---|---|
| `--id` | ✅ | 全小写 + 下划线，不可与已有卡重复 |
| `--name` | ✅ | 中文名 |
| `--cost` | ✅ | ≥ 1 |
| `--attack` | ✅ | ≥ 0 |
| `--defense` | ✅ | ≥ 1（防御 ≤ 0 的单位一上场就死） |
| `--element` | | 默认 `none`；可选基础 6 元素 + 2 复合元素 |
| `--count` | | 牌组里放几份，默认 4 |
| `--unit-class` | | 兵科，默认 `infantry`；可选 `infantry` / `tank` / `artillery` / `fighter` / `bomber` |
| `--opcost` | | 行动费 `operation_cost`，默认 1 |
| `--keywords` | | 关键词，逗号分隔，如 `blitz,guard`；默认空 |

工具会自己 `type: "unit"` 写进去。**指令卡必须是 `type: "order"`** —— 漏写时 `Card.from_dict()`
默认成 `"unit"`，M2 的部署逻辑会把火球当成能上场的单位。`data_test[1]` 有一条断言盯着这个。

写回格式跟手写的一致（2 空格缩进、每张卡一行、UTF-8 无 BOM），写完会重新解析一遍自检；
万一手滑写坏了，`git checkout -- data/tables/cards.json` 一条命令回滚。

**校验逻辑现在只有一份**：`tools/card_lib.gd`。这个 CLI 工具和图形工具都调它，
所以两边加出来的卡字节格式必然一致，不会出现「命令行加的卡和界面加的卡长得不一样」。

## unit_maker.bat —— 单位卡图形制作工具（M4 界面基座）

双击 `tools\unit_maker.bat` 就开窗口，不需要命令行。

```
┌──────────┬────────────────┬─────────────┐
│ 单位卡列表 │   卡面预览      │  字段表单    │
│ 步兵      │ ┌────────────┐ │  id / 名字   │
│ 弓手      │ │  名字条     │ │  费用 / 攻击 │
│ 火法师    │ │  ① 卡图区   │ │  防御 / 行动费│
│ 坦克      │ │ 元素·兵科   │ │  兵科 / 关键词│
│ 新建/复制/删除│ │ 攻2  御3  │ │             │
└──────────┴────────────────┴─────────────┘
            [保存到 cards.json]   Ctrl+S
```

**卡面版式（照 KARDS 的结构，2026-11-26 改版）**：顶部名字条 → **中间卡图区**（占最大面积）
→ 元素·兵科 → 关键词带 → 细分隔线 → 底部「左攻 / 右御」大数字 → 页脚 `id ×count`。
费用徽标压在卡图左上角，颜色随元素。

**卡图怎么来**：把图片按 `assets/cards/<卡id>.png` 命名丢进目录即可（如 `assets/cards/footman.png`），
卡里有 `"image"` 字段时优先用它。没有图就显示占位框，框里写文件名。
细节与版权提醒见 `assets/cards/README.md`。

> ⚠️ **新加的图片必须先跑一次 `--import`**，否则 `ResourceLoader.exists()` 看不到它，卡面还是占位框：
> `& $g --headless --path . --import`

**为什么不直接抠 KARDS 的图**：那是商业游戏的素材，直接搬进仓库有版权风险（尤其将来要发布）。
版式结构（名字在上、卡图中部、数值在下）属于设计思路，不构成侵权；所以**只借版式，不搬素材**。


**为什么这个工具算 M4 的一部分，而不是"顺手写的脚本"**：

- 中栏预览用的就是 `src/ui/card_view.gd` —— **M4 手牌区将来显示的是同一个组件**。
  在这里调好的卡面，M4 不用重做；M4 改了卡面，这里自动跟着变。
- 配色和字体来自 `src/ui/ui_theme.gd`，全局只有一份。
- 所以它同时是「卡牌编辑器」和「M4 界面基座的可运行样例」。

**验证手段（两条，都不靠肉眼）**：

```powershell
# 1. 卡牌读写/校验逻辑（55 项）
& $g --headless --path . --script res://tools/test_card_lib.gd

# 2. 真界面端到端：用代码驱动这个窗口走「选卡→改字段→保存→新建→删除→还原」（30 项）
& $g --path . --headless tools/unit_maker.tscn -- --selftest

# 3. 只要截图（验证中文渲染与排版）；--card=<id> 指定先选中哪张卡
& $g --path . tools/unit_maker.tscn --resolution 1240x800 -- --shot=G:\tmp\maker.png --card=fighter
```

第 2 条是关键：**截图只能证明"画出来了"，证明不了"点得动"**。
`--selftest` 走的是真实控件的信号连接与真实写盘，跑完会把 `cards.json` 还原，
preflight 第 11 项会额外检查「自检跑完 data/ 干净」。

**这个工具不做什么**：不参战、不校验平衡、不碰 `data/decks/*.json`。

## launch_editor.bat —— 带 user-data 重定向启动编辑器（**历史 workaround，现已不需要**）

> **2026-11-24 更新：根因已定位并修复，直接用编辑器正常启动即可，本脚本仅在修复失效时作后备。**
>
> **根因**：`G:\constraction` 整棵树带 NTFS 完整性标签
> `Mandatory Label\Low Mandatory Level:(OI)(CI)(NW)`，Godot 可执行文件继承该标签，
> 于是 **Godot 进程以 Low IL（`S-1-16-4096`）运行**。Low IL 只能写同属 Low IL 的对象 ——
> 所以它写 C:/D:/G 盘根全返回 `ERR_FILE_CANT_WRITE (12)`，读系统根证书库（需 Medium+）
> 返回空串并打印 `ERROR: Failed to read the root certificate store.`，
> 连它派生的 `cmd.exe` 子进程（继承 Low IL）写 C 盘也被拒。
> 对照 bash/PowerShell 是 `High Mandatory Level (S-1-16-12288)`，写同一路径成功 —— 这就解释了
> 为什么"权限全开却写不进去"。已排除：ACL、目录缺失、杀毒/CFA、AppContainer、IFEO、WDAC/AppLocker、
> DSH 沙箱（用 WMI 脱离 bash 进程树启动 Godot 结果相同）。
>
> **修复命令**（已执行，重启 Godot 生效）：
> ```bat
> icacls "G:\constraction\Godot_v4.7.2-stable_win64.exe" /setintegritylevel Medium
> ```
> 验证：`WRITE_C=OK`、`CA_LEN=116191`（原为 0）、`--editor --quit` 下四条 ERROR 全消失、
> `resthumb-*.png/.txt` 与 `logs/godot.log` 正常落回 C 盘默认目录、`board_test` 38/38、主套 375/375。
> 若把引擎拷到 `G:\constraction\**` 的其他位置，新副本会重新继承 Low 标签，需再跑一次上面的命令。

本脚本原来的作用：把 `LOCALAPPDATA` / `APPDATA` 指到 `G:\constraction\_gduser\`，再启动 Godot 编辑器，
使当时刷屏的这三条报错消失：

```
ERROR: Can't save PNG at path: '...\AppData\Local\Godot\resthumb-<hash>.png'.
ERROR: Cannot create file '...\AppData\Local\Godot\resthumb-<hash>.txt'. Check user write permissions.
ERROR: Failed to open log file for writing: user://logs/godot.log
```

> 这从来**不是项目 bug**。`check.bat` / `run_tests.bat` / CI 走 `--headless --script`，
> 判定不看这些 ERROR —— 不开 GUI 时本来就可以完全不管。

## run_tests.bat / preflight.ps1 —— 两段式验收（**唯一的验收入口**）

仓库根目录的 `run_tests.bat` 现在分两段跑，两段都过才打印 `===== ALL GREEN =====`、退出码 0：

**输出原则：通过的东西不刷屏，失败的东西全给你。**

| 情况 | 输出 |
|---|---|
| 某个测试文件全绿 | **一行** `[PASS] board_test` |
| 某个测试文件有红 | 打印**该文件的完整日志**（每一条 `[ok]` / `[FAIL]` / `SCRIPT ERROR`），前后有 `<< FAILED` / `end of XXX` 包夹 |
| PART 2 的某项检查通过 | 不打印（只有 `-Verbose` 才显示 `[ok]`） |
| PART 1.5 的待启用测试 | 每个文件一行 `[READY]`/`[PENDING]`，永不判失败 |
| PART 2 的某项检查失败/提醒 | 打印该节标题 + 失败原因 + 修法提示 |
| 结尾 | `===== ALL GREEN =====  11 file(s) passed` 或 `===== SOME TESTS FAILED =====  1 file(s) failed, 10 passed` |

所以**全绿时整份输出约 20 行**，一眼能扫完；一旦有红，红的那部分会是完整日志，不用再去翻文件。
每个文件的完整日志始终留在 `%TEMP%\whk_tests\` 里（结尾那行会打印路径）。

| 段 | 内容 | 谁定的 |
|---|---|---|
| **PART 1 主套** | 自动发现 `tests\*_test.gd`；每个文件判 `退出码 0` + `有 PASS` + `无 [FAIL]` + `无 SCRIPT ERROR` | `run_tests.bat` 本体 |
| **PART 1.5 待启用基线** | 自动发现 `tests\pending\*_test.gd`，每个文件打一行 `[READY]` 或 `[PENDING]`（项数/红/SCRIPT ERROR）。**只报告，永不判失败** | `run_tests.bat` 本体 |
| **PART 2 详细自检** | 7 项：数据校验 / `has_acted` 残留 / `EXPECTED_CHECKS` / 兵科覆盖 / 平衡冒烟 / 脚本编码 / 工作区噪音 | `tools/preflight.ps1` |

PART 1.5 的输出（跟主套结果在同一个终端里，不用去别的报告里找）：

```
############ PART 1.5  pending baseline (tests\pending\*_test.gd) ############
  [READY  ] deck_build_test  11 checks  --> git mv tests/pending/deck_build_test.gd tests/
  [PENDING] some_test  8 checks / 4 failed / 0 script errors
    ---- failed checks: 4 ----
  [FAIL] 第一条红掉的断言
  [FAIL] 第二条红掉的断言（期望 2，实际 1）
    ---- full log: C:\Users\...\Temp\whk_tests\pending_some_test.log
```

- `[PENDING]` = 还红着，继续实现就行，不影响 `ALL GREEN`；
- **红的时候下面会逐条列出 `[FAIL]` 断言**（有 `SCRIPT ERROR` 也会逐条列出），不用自己去翻日志；
- `[READY  ]` = 0 失败 0 SCRIPT ERROR，**这时教练才把它 `git mv` 进 `tests/` 变成常驻回归**；
- 全绿但仍有 pending 红时，结尾 SUMMARY 会补一行 note 提示。

PART 2 的 7 项明细：

| # | 检查 | 判定 |
|---|---|---|
| 1 | `validate_data.gd` | 必须 PASS，否则 `[FAIL]` 并打印全部 `[ERROR]` 行 |
| 2 | `has_acted` 残留 | `tests/keywords_test.gd` 启用后 `src/` 里仍有残留 → `[FAIL]`；未启用时只提示 |
| 3 | `EXPECTED_CHECKS` | `tests/*_test.gd` 每个文件都必须声明，缺了 → `[FAIL]`（漏跑会假绿） |
| 4 | 兵科覆盖 | `cards.json` 单位卡没标 `unit_class` → 提醒（M3.3/M3.4 前应清零） |
| 5 | 平衡冒烟 | `balance_sim` 100 场：胜率 45–60%、平均 8–20 回合、RUNNING < 1%；出界只提醒（调参归 M3.8） |
| 6 | 脚本编码 | `*.bat` 必须 CRLF + 纯 ASCII；`*.ps1` 含中文必须 UTF-8 BOM；违规只提醒 |
| 7 | 工作区噪音 | `data/tables/*.json` 行尾换行假 diff 提醒还原；未提交改动只在 `-Verbose` 下列出 |

```bat
REM 平时验收（两段一起跑）
run_tests.bat

REM 只跑 PART 2（刚补完数据想确认兵科齐不齐、平衡有没有出界）
tools\preflight.bat

REM 想看 PART 2 每一项的 [ok] 明细（排查"到底是哪项在报"时用）
powershell -NoProfile -ExecutionPolicy Bypass -File tools\preflight.ps1 -Verbose

REM 只跑 PART 2 且少跑点平衡场次（默认 100）
powershell -NoProfile -ExecutionPolicy Bypass -File tools\preflight.ps1 -BalanceGames 30
```

编码：`preflight.ps1` 有中文 → **必须存成 UTF-8 with BOM**；`preflight.bat` → **CRLF + 纯 ASCII**。
`.gitattributes` 已固定 `*.bat text eol=crlf`，`git ls-files --eol` 可复查。

## 辅助方法一览（每个函数/脚本参数干什么用的）

> 这一节是全量索引。改脚本前先在这里找到那个方法，再回代码看实现。
> 「谁调用」一列说明它在哪条链路上，**没被调用的就是死代码，可以删**。

### A. `run_tests.bat` 里的 label 与变量

批处理没有"函数"，用 `call :label` + `%~1` 传参，靠 `set` 全局变量共享状态。

| 名字 | 类型 | 功能 | 谁调用 |
|---|---|---|---|
| `GODOT` | 变量 | Godot 控制台 exe 的绝对路径。先看环境变量 `GODOT`，没有就用 `%~dp0..\..\..\Godot_...\..._console.exe` 相对默认值 | 顶部初始化；每次 `--headless` 都引用 |
| `PROJ` | 变量 | 仓库根目录（`%~dp0`，末尾自带 `\`）。**带反斜杠**，所以后面写 `"%PROJ%tests\..."` 而不是 `"%PROJ%\tests\..."` | 全部命令 |
| `OUTDIR` | 变量 | 单文件测试日志目录。优先 `%TEMP%\whk_tests`，建不出来退回 `%PROJ%_test_logs` | 每个测试的 `>` 重定向 |
| `FAILED` | 变量 | 汇总失败标志，`0` 全绿 / `1` 有任何失败。PART 1、PART 2 都往它上面 `set` | `:summary`；`exit /b %FAILED%` |
| `PASSED_FILES` / `FAILED_FILES` | 变量 | 通过 / 失败的**文件数**，只用于结尾那行汇总 | `:run_one` 里 `set /a`；`:summary` |
| `:pending` | label | PART 1.5 入口：数 `tests\pending\*_test.gd`，没有就跳过整段；**只报告，不碰 `FAILED`** | 主套循环结束后 `goto :pending` |
| `:pending_one` | label | 跑**单个**待启用测试，按 `[ok]` / `[FAIL]` / `SCRIPT ERROR` 行数算出「项数 / 红 / 错误」，打一行 `[READY  ]`（0 红 0 错误，可以 `git mv` 了）或 `[PENDING]` | `for %%f in ("%PROJ%tests\pending\*_test.gd")` 循环 |
| `:run_one` | label | 跑**单个**测试文件并四重判定。入参 `%~1` = 不含扩展名的文件名（如 `board_test`）。依次检查：退出码 0 / 输出含 `PASS` / 输出不含 `[FAIL]` / 输出不含 `SCRIPT ERROR`，任一不满足就 `set FAILED=1` | `for %%f in (...)` 循环，每个 `*_test.gd` 一次 |
| `:preflight` | label | PART 2 入口：`powershell -File tools\preflight.ps1` 传 `-Godot` / `-ProjectRoot`，`errorlevel 1` → `FAILED=1` | PART 1.5（`:pending`）结束后 `goto :preflight` |
| `:summary` | label | 打印 `===== ALL GREEN =====` 或 `===== SOME TESTS FAILED =====` + 日志目录，然后 `pause` + `exit /b %FAILED%` | `goto :summary` 与 fall-through |

### B. `tools/preflight.ps1` 的函数与参数

| 名字 | 签名 | 功能 |
|---|---|---|
| `-Godot` | `[string]` 参数 | Godot 控制台 exe 路径。空 → 读环境变量 `GODOT` → 再空就用相对默认值。文件不存在时打印红字并 `exit 2` |
| `-ProjectRoot` | `[string]` 参数 | 项目根。空 → 取脚本所在目录的上一级（`Resolve-Path ..`） |
| `-BalanceGames` | `[int]` 参数，默认 100 | 平衡冒烟跑多少场。想快就传 `-BalanceGames 30` |
| `-Verbose` | `[switch]` 开关 | 把每一节的 `[ok]` / `[info]` 全部打印出来。不加时只输出「失败/提醒」的节 + 结论行 |
| `$fails` / `$warns` | 脚本级计数器 | `fails` 决定退出码（0 = 无 FAIL）；`warns` 只影响结尾括注，**不影响退出码** |
| `Say-Fail` | `([string]$Msg)` | 打印红色 `[FAIL]` 并 `$script:fails++`。**只有它会把退出码拉成非 0** |
| `Say-Warn` | `([string]$Msg)` | 打印黄色 `[warn]` 并 `$script:warns++`。只提醒，不阻塞提交（如平衡出界、兵科没标、编码不合规） |
| `Say-Ok` | `([string]$Msg)` | 计一次通过（`$oks++`）。**默认不打印**，只有加 `-Verbose` 才显示绿色 `[ok]` —— 一屏几十条绿行会把真正的问题刷没 |
| `Say-Info` | `([string]$Msg)` | 深灰缩进解释行（修法建议、清单）。**默认不打印**，只在 `-Verbose` 下显示；不计入任何计数 |
| `Show-Section` | `()` | 延迟打印小节标题：只有该节真的要输出内容（有 FAIL/warn，或 `-Verbose`）时才打印标题 + 空行，避免"标题一堆但下面全是空的" |

> `tests/pending` 的待启用基线**不在这里**了（2026-11-25 挪到 `run_tests.bat` 的 PART 1.5，`[READY]`/`[PENDING]` 直接打在主套结果下面）。

> 为什么用 `$script:` 前缀：这些函数在脚本作用域执行，直接写 `$fails++` 会新建**函数局部**变量，
> 调用方的计数器不动 → 退出码永远是 0（假绿）。`$script:` 才是改脚本级那一个。

十二项检查用注释分隔（`# ---- N. 标题`），每段内部都是「取数据 → 判 → Say-Xxx」，无独立函数。
**加第十三项检查的模板**：复制一段，改标题行、判定、`Say-Ok`/`Say-Fail` 分工即可。

当前 12 项：`[1]` 数据校验 / `[2]` has_acted 残留 / `[3]` EXPECTED_CHECKS / `[4]` 兵科覆盖 /
`[5]` 平衡冒烟 / `[6]` 脚本编码 / `[7]` 工作区噪音 / `[8]` 中文字体 / `[9]` 分层边界 /
`[10]` `test_card_lib.gd` / `[11]` 图形工具端到端自检 / `[12]` `test_card_view.gd`（多卡串色）。

### C. `tools/validate_data.gd` 的方法

| 名字 | 签名 | 功能 |
|---|---|---|
| `_initialize` | `() -> void` | 入口。依次加载四张表 → 跑五项检查 → 打印 `[ERROR]` 列表 → 有错 `quit(1)`，无误 `print("PASS")` + `quit(0)` |
| `_read_json` | `(path: String) -> Variant` | 读文件并 `JSON.parse_string`。**文件不存在 / 解析失败都会 `_error`** 并返回 null，不抛异常 |
| `_load_array` | `(path: String, key: String) -> Array` | 取 JSON 顶层的数组字段（`cards` / `reactions` 等）。不是字典或缺字段 → `_error` + 返回空数组 |
| `_load_dict` | `(path: String, key: String) -> Dictionary` | 取顶层字典字段（`statuses` / `elements`）。同上 |
| `_check_statuses` | `(statuses: Dictionary) -> void` | 查每个状态有没有 `name`、`kind` 是否在 `KNOWN_EFFECT_KINDS` 里、`dot`/`disable` 的数值字段齐不齐 |
| `_check_reactions` | `(reactions, statuses, element_ids: Array[String]) -> void` | 查配对键格式（两个元素 `a+b` 且**字母序**）、引用的元素 id 存在、`effect` 递归合法 |
| `_check_effect` | `(where: String, e: Variant, status_ids: Array, element_ids: Array[String]) -> void` | 递归校验单个 effect 对象：`kind` 合法、`damage` 有 `multiplier`、`status` 引用的 id 存在、`aura` 元素合法 |
| `_check_cards` | `(cards: Array, statuses: Dictionary, element_ids: Array[String]) -> void` | 查 id 唯一、`type` ∈ unit/order、`kind` 合法、单位卡 `attack`/`defense` 为正、`unit_class` ∈ `KNOWN_UNIT_CLASSES`、`keywords` ⊆ `KNOWN_KEYWORDS`、`count` 为正 |
| `_check_decks` | `(cards: Array) -> void` | 查 `data/decks/*.json`：总张数 = `DECK_SIZE`(39)、同名卡 ≤ `MAX_SAME_CARD`(4)、id 都在 cards 里 |
| `_as_array` | `(v: Variant) -> Array` | 类型安全转换：是数组就原样返回，否则返回空数组（避免后续 `.size()` 崩） |
| `_error` | `(where: String, msg: String) -> void` | 往 `errors` 追加 `"位置：原因"`。**只记账不打印**，最后统一打印 |
| 常量 `KNOWN_EFFECT_KINDS` | `["damage","status","aura","shield","heal","dot","disable","stat_mod"]` | 合法的 effect 类型白名单 |
| 常量 `KNOWN_KEYWORDS` | `["blitz","guard"]` | 合法关键词白名单。**加新关键词必须同步这里** |
| 常量 `KNOWN_UNIT_CLASSES` | `["","infantry","tank","artillery","fighter","bomber"]` | 合法兵科白名单。`""` 表示未标注（M3.4 前允许） |

### D. `tools/add_unit_card.gd` 的方法（M4 起：格式逻辑已下沉到 `card_lib.gd`）

| 名字 | 签名 | 功能 |
|---|---|---|
| `_initialize` | `() -> void` | 入口：`_parse_args` → `_add_unit` → 成功 `quit(0)` / 失败 `quit(1)` |
| `_add_unit` | `(args: Dictionary) -> String` | 核心。先 `CardLib.read()` 取现有卡用于查重 → `CardLib.blank_unit()` 起底 → 填参 → **`CardLib.validate_unit()` 统一校验** → `CardLib.save_card(..., "insert")` 写回。返回 `""` = 成功，否则是人话错误 |
| `_parse_args` | `(raw: Array) -> Dictionary` | 解析 `--key value` / `--key`（无值 → `"true"`）。值不能以 `--` 开头，否则当成下一个 key |
| `_to_int` | `(v) -> int` | 安全转整数：`is_valid_int()` 不过就返回 **`-999`**（故意给一个必被 `validate_unit` 判死的值，让错误信息统一由 CardLib 产出，不在这里重复写一套判断） |
| `_usage` | `() -> void` | 打印用法。必填 `--id --name --cost --attack --defense`；选填 `--element` `--count` `--unit-class` `--opcost` `--keywords` |

### D2. `tools/card_lib.gd` 的方法（**卡牌格式的唯一入口**）

`add_unit_card.gd`（命令行）和 `unit_maker.gd`（图形）都调它，所以两边写出来的字节格式必然一致。

| 名字 | 签名 | 功能 |
|---|---|---|
| `read` | `static (path := CARDS_PATH) -> Dictionary` | 读 cards.json。返回 `{ok, error, text, data, cards}`。**`text` 是原文**，行级手术要用它；任何一步失败都填 `error` 而非抛异常 |
| `find_card` | `static (cards: Array, id: String) -> Dictionary` | 按 id 找卡，找不到返回**空字典**（不是 null，方便 `is_empty()` 判断） |
| `collect_ids` | `static (cards: Array) -> Array[String]` | 取所有 id，供查重用 |
| `validate_unit` | `static (card: Dictionary, taken_ids: Array = []) -> Array[String]` | 校验一张单位卡，返回问题列表（空 = 合法）。查 id 格式/唯一/名字/type/cost 1–12/attack≥0/defense≥1/opcost≥0/**元素只能取 `ELEMENTS` 的 7 项**/兵科白名单/count 1–4/关键词白名单 |
| `blank_unit` | `static (id := "new_unit") -> Dictionary` | 造一张字段齐全的空白单位卡，供图形界面直接绑控件 |
| `dump` | `static (data: Dictionary) -> String` | 把**整份** cards.json 字典序列化成文本（每卡一行）。注意：**写回时不用它**，用它会把没动过的卡重排、造 diff |
| `card_line` | `static (card: Dictionary) -> String` | 单张卡 → 一行 JSON。先按 `KEY_ORDER` 输出，再补未知字段（保证不丢字段） |
| `value_of` | `static (v) -> String` | 值 → JSON 文本。整数值的 float 写成 `3` 而不是 `3.0`（否则每次保存都假 diff） |
| `deck_total` | `static (cards: Array) -> int` | 累加 count，打印"牌库共 N 张" |
| `save_card` | `static (path, card, mode) -> String` | **行级手术**写回。`mode` = `"insert"` / `"replace"` / `"delete"`。返回 `""` = 成功 |
| `delete_card` | `static (path, id) -> String` | 删一行；若删的是最后一张，会去掉前一张的行尾逗号（否则 JSON 坏） |
| `write_text` | `static (path, text) -> String` | 落盘。返回 `""` = 成功 |
| `self_check` | `static (path, must_have, expect_count, must_be_gone) -> String` | 写完重新解析自检：条数对、该有的在、该没的没了。失败时提示 `git checkout --` 回滚 |
| `surgical_insert` / `surgical_replace` / `surgical_delete` | `static (text: String, ...) -> String` | 在**文本行**上做手术，其它行字节不变。拼不出来时返回 `""`（表示格式不是「一张卡一行」） |
| `_cards_close_index` / `_last_card_index` / `_card_index_of` / `_id_of_line` | 私有 | 定位 `]` 行 / 最后一张卡行 / 某 id 的行 / 从行文本里取 id |

**为什么必须行级手术**：现有 `cards.json` 里指令卡的键顺序并不统一（`guard` 是 `power` 在前，`fire_bolt` 是 `target` 在前）。整份重新序列化会把没动过的 10 张卡全部重排，git diff 里冒出几十行无关改动。

### D3. `tools/test_card_lib.gd` 与 `tools/unit_maker.gd` 的验证方法

`test_card_lib.gd`（55 项，`--script` 跑）：`_reset_tmp`/`_tmp_text`/`_line_count`/`_card_ids` 把 `cards.json` 复制到 `user://` 上反复手术，断言「其余行字节不变」「删最后一张后 JSON 仍合法」等。`EXPECTED_CHECKS := 55`（第 [9] 组 `_test_element_choices` 专门守「卡牌只能选 6 基础元素，复合元素禁止」）。

`unit_maker.gd`（图形工具，`Control`）：

| 名字 | 签名 | 功能 |
|---|---|---|
| `_ready` | `() -> void` | 装主题 → 建界面 → `_reload` → 分流到 `--selftest` 或 `--shot` 模式 |
| `_build_ui` / `_build_header` / `_build_left` / `_build_center` / `_build_right` / `_build_footer` | | 分区构建。**所有控件都在代码里建**（`.tscn` 只有根节点 + script），保证 diff 干净 |
| `_reload` | `() -> void` | 重新读 cards.json → 刷新列表 → 首张单位卡自动选中 |
| `_refresh_list` | `() -> void` | 只挑 `type == "unit"` 的卡进列表，支持按 id/名字筛选 |
| `_form_to_card` / `_card_to_form` | | 表单 ⇄ 卡字典双向转换。`_card_to_form` 里用 `_saving` 标志挡住信号回调 |
| `_refresh_preview` | `() -> void` | 把当前表单喂给 `CardView.set_card()`，卡面立刻跟着变 |
| `_current_errors` | `() -> Array[String]` | 调 `CardLib.validate_unit`，**查重时把自己排除掉**（否则改自己也会报重名） |
| `_on_field_changed` / `_refresh_validation` | | 任一字段变动 → 重画预览 + 重跑校验 + 更新标题的 `*` 脏标记 |
| `_on_list_selected` / `_on_new_pressed` / `_on_duplicate_pressed` / `_on_delete_pressed` / `_on_reload_pressed` | | 列表与按钮回调。改名保存 = 先删旧卡再插新卡 |
| `_on_save_pressed` / `_save` | | 按 `_is_new` / 改过 id / 覆盖 三种情况选 `insert` / `replace`；`Ctrl+S` 走 `_input` |
| `_handle_shot_mode` / `_do_shot` | | `--shot=PATH --shot-frames=N`：等 N 帧后 `get_viewport().get_texture().get_image().save_png()`，退出码 0/1 |
| `_handle_selftest` / `_run_selftest` / `_st` | | `--selftest`：用代码驱动**真实界面**走「选卡→改字段→保存→新建→删除→还原」，30 项断言，跑完把 cards.json 还原 |
| `SELFTEST_CHECKS` | 常量 `30` | 自检项数。**加断言必须同步改它**，否则会报「覆盖不完整」 |

> `--shot` 证明「画出来了」，`--selftest` 证明「点得动」。两者都跑才算这个工具验完。
>
> 截图模式还有一个 `--card=<id>` 参数（2026-11-26 加）：截图前先把指定 id 的卡选中，
> 用来单独看某一张卡的卡面（比如验证「雷是不是紫色」）。例：`-- --shot=G:\tmp\x.png --card=fighter`

### D4. `tools/test_card_view.gd` 的回归方法（2026-11-26 新增）

`extends SceneTree`，`const EXPECTED_CHECKS := 7`。三组：

| 组 | 函数 | 守什么 |
|---|---|---|
| [1] | `_test_shared_stylebox_hazard` | 先证明**隐患前提成立**：`Theme` 分给两个 `PanelContainer` 的 `panel` stylebox 是 `is_same` 的同一对象。哪天 Godot 改了行为，这条会红，提示我们那套私有 `StyleBoxFlat` 可以简化 |
| [2] | `_test_multi_card_independence` | 同屏 5 张不同元素的 `CardView`，底色必须**各自不同**、**不是同一对象**、**改最后一张不影响第一张** |
| [3] | `_test_art_path_lookup` | `CardView.art_path_of()`：有 `image` 字段用它，否则按 `assets/cards/<id>.png` 推导 |

**为什么值得单独建一个测试文件**（而不是跑完删掉的临时探针）：
旧实现 `get_theme_stylebox("panel")` 后原地改 `bg_color`，**单张卡预览完全看不出问题**，
只有「一次显示多张」才暴露成「所有卡都变成最后一张的颜色」。M4 手牌区必然是 5 张同屏，
所以这是一个会真实复发的高危回归点，必须固化成断言而不是靠人眼。
反向验证过：把实现改回旧写法 → [2] 组 3 项全红；改回新写法 → 7/7 绿。

### E. `tools/balance_sim.gd` 的方法

| 名字 | 签名 | 功能 |
|---|---|---|
| `_initialize` | `() -> void` | 入口：解析参数 → 加载全部卡 → `_build_deck` → 跑 N 局 `run_auto` → 统计 WIN/LOSE/RUNNING、玩家胜率、平均回合 → 可选写 CSV → `quit(0)`（注意**即使有 RUNNING 也退出 0**，只打警告） |
| `_parse_args` | `(raw: Array) -> Dictionary` | 支持三种形态：`--units-only` / `--all-cards`（布尔开关，不带值）、`--key value`、其他忽略。`--units-only` 实际写成 `out["all-cards"] = false` |
| `_build_deck` | `(all_cards: Array, units_only: bool) -> Array` | 造牌库。`units_only=true` 时**只留 `type == "unit"` 的卡** —— 因为 E14 前 AI 不打指令卡，混进去手牌会塞满导致永远 RUNNING |
| 参数 `--games N` | 默认 100 | 对局数 |
| 参数 `--seed S` | 默认 42 | 起始种子；第 i 局种子 = `S + i`，**可复现** |
| 参数 `--max-turns N` | 默认 30 | 单局回合上限，超了算 RUNNING |
| 参数 `--out PATH` | 可选 | CSV 输出路径。**用 `res://` 或 `G:/` 开头的路径**（本机 C 盘写不了，见 §launch_editor） |

### F. `tools/check.ps1` 的函数

| 名字 | 签名 | 功能 |
|---|---|---|
| `Show-Checkpoints` | `([string]$Title, [string]$File, $Points)` | 打印「里程碑检查点」：对 `$Points` 里每个 `(标签, 特征串)` 二元组，去 `$File` 的输出里找**同时含 `[ok]` 和该特征串**的行；找到 = `[完成]`，没找到 = `[ 待做]`。文件没启用时只提示"测试文件未启用" |
| `$e15` / `$c8` | 数组 | 检查点清单。`$e15` = 敌方 AI 七项（起手 5 张 / Kredit / 部署 / 推进前线 / 攻击 / 行动标志清零 / 能分胜负）；`$c8` = 状态效果四项（加载 statuses / 燃烧掉血 / 冻结不能动 / 感电挂 shock） |

> `check.bat` 与 `run_tests.bat` 的分工：`check.bat` 面向「今天做到哪了」（进度/里程碑/下一步建议），
> `run_tests.bat` 面向「这次改动能不能提交」（四重判定 + 七项详细自检）。**提交前必须跑 `run_tests.bat`**。

### G. 测试文件里的辅助方法（`tests/*_test.gd` 每个文件自己定义的）

测试不用任何测试框架，每个文件都是 `extends SceneTree` 的独立脚本，自己数 `checks` / `failures`。
下面这些名字在**多个文件里重复出现**，含义一致。改测试时别改语义（项数会变）。

**G1. 断言三件套（每个文件都有，逐字相同）**

| 名字 | 签名 | 功能 |
|---|---|---|
| `_check` | `(condition: bool, message: String) -> void` | `checks += 1`；真 → 打印 `  [ok]   <msg>`；假 → `failures += 1` + `printerr("  [FAIL] <msg>")`。**所有断言最终都走这里** |
| `_check_eq` | `(actual, expected, message: String) -> void` | 转调 `_check(actual == expected, "<msg>（期望 X，实际 Y）")`。**只有三个参数**，别传第四个；想判不等/组合条件就直接用 `_check`（踩过这个坑：`Too few arguments for "_check_eq()" call.`） |
| `_initialize` | `() -> void` | 入口。依次调用各 `_test_xxx()`，然后**校验项数**：`if checks != EXPECTED_CHECKS:` → 记一条 `[FAIL] 覆盖不完整`。最后打印 `共 N 项检查，失败 M 项` + `PASS`/`FAIL` + `quit(0/1)` |

> `EXPECTED_CHECKS` 是每个文件顶部的常量。**它的作用是防假绿**：某段测试因为 SCRIPT ERROR 被中途打断，
> `checks` 数会少于它，于是报"覆盖不完整"。所以改测试增删断言时**必须同步改这个常量**，
> 否则 `run_tests.bat` 的 PART 2 [3] 或本文件的项数校验会红。

**G2. 建局 / 造数据（同名不同签名的要看清文件）**

| 名字 | 出现在 | 功能 |
|---|---|---|
| `_new_battle` | `battle_m1_smoke`(hp 60/30, fallback)、`battle_m2`(hp 60, 可传牌库)、`combat`(hp 999/9999)、`deck`、`order`、`status`、`opening`(可传种子)、`pending/*` | 造一个 `Battle` 并 `setup(player, enemies, 牌库, table, 种子)`。**各文件的 HP 和种子不同**（种子固定 = 可复现）。只有 `battle_m1` 带 `fallback` 参数：`setup()` 没实现时把 player/enemies/reaction_table 直接塞进去，让后续断言能跑而不是整个文件崩 |
| `_new_battle_first_player` | `opening_test` | 在 `_new_battle` 基础上把 `first_move = "player"` 钉死（E7b 之前的断言都假设玩家先手） |
| `_new_battle_first_enemy` | `opening_test` | 同上，钉 `first_move = "enemy"`，用于测敌方先手时 `begin_first_turn()` 的差异 |
| `_start` | `battle_m1_smoke`、`battle_m2`、`deck`、`order`、`status` | **E7b 之后必须用它建局**：`b.first_move = "player"` → `start_battle()` → `begin_first_turn()`。少了最后一行就只有起手牌、没开始回合，所有"第 1 回合"断言都会错。E7b 之前是直接调 `start_battle()` |
| `_new_board` | `board_test` | `Board.new()` + `setup()`，不涉及 Battle |
| `_make_deck` | `battle_m1_smoke` | 造 N 张指令卡（`deck_0..deck_N-1`，cost 1、power 3）。用来测抽牌/爆牌，**不受真实牌库张数影响** |
| `_make_unit_deck` | `battle_m2` | 造 16 张单位卡（4 张 × 4 种，含坦克）。**为什么不用真牌库**：`cards.json` 前 28 张是指令卡，而起手 5 + 每回合 1 会让手牌顶到上限 9，AI 又不打指令卡 → 整局摸不到单位卡，谁都没法上场 |
| `_unit_card` | `battle_m2`、`pending/keywords` | 造一张**单位** `Card`。`battle_m2` 版带 `operation_cost`（传 `-1` = 卡上不写这个字段，走 `from_dict` 缺省值 1）；`keywords` 版带 `keywords: Array` + `unit_class: String` |
| `_order` | `deck_test`、`order_test` | 造一张**指令** `Card`。两版差异：`deck_test` 的 `target` 默认 `"enemy"`；`order_test` 默认 `""`（不写这个字段）并多一个 `aura_amount` |
| `_unit` | `board_test`、`deck_test`、`order_test`、`pending/*` | 直接造 `Unit`。`board_test` 版按序号造（`u0`/`u1`）；其余版按 id 造并可指定 `owner` / `element` / `unit_class` |
| `_place` | `combat_test`、`status_test` | **绕开出牌直接往棋盘摆单位**（不花能量、不等召唤失调），专测移动/攻击/状态结算。`combat` 版参数序是 `(line, index, attack, hp, ...)`，`status` 版是 `(line, index, hp, attack, ...)` —— **顺序反的，别记混** |
| `_target` | `damage_test` | 造一个纯木桩 `Unit` 并直接写 `aura_element` / `aura_amount` / `immunities` 字段（不走 from_dict），专测伤害倍率 |
| `_atk` / `_target` | `pending/stat_mod` | 造攻击方 / 被打方，专测 stat_mod 数值修正 |
| `_attacker` / `_guard_unit` / `_other_unit` | `pending/guard` | 造攻击者 / 带 `guard` 关键词的单位 / 普通单位，专测相邻保护 |
| `_rookie` / `_placed` | `pending/keywords` | 造"刚部署的新兵"（用来验证召唤失调）/ 按行列摆单位（用来验证闪击与行动经济） |
| `_unit` | `pending/unit_class`、`pending/air_intercept` | 造带 `unit_class` 的单位（炮兵/坦克/战斗机/轰炸机） |

**G3. 查询 / 断言辅助**

| 名字 | 出现在 | 功能 |
|---|---|---|
| `_find_buff` | `order_test`、`status_test` | 遍历 `u.buffs` 找指定 `kind` 的 `Buff`，**找不到返回 `null`**（所以断言要写 `_find_buff(u,"dot") == null`，别直接 `.amount`） |
| `_player_hq` / `_enemy_hq` | `deck_test` | 取双方 HQ —— 实际就是 `board.unit_at("player_support", 0)` / `("enemy_support", 0)`。HQ 固定占支援线 0 号格 |
| `_hand_ids` | `opening_test` | 把 `Array[Card]` 转成 `Array[String]` 的 id 列表，方便比对"换牌前后手牌是不是同一批" |
| `_has_flags` | `pending/keywords`（**旧版在 4 个主套文件里也用过**） | 判断单位有没有 `has_moved` / `has_attacked` 字段。M3.1 未实现时返回 false，这就是 keywords_test 头一批 11 红的原因 |
| `_flags_ok` | `pending/guard` | 判断行动标志是否都为 false（单位还没行动） |
| `_count_by_id` | `pending/deck_build` | 把 `Array[Card]` 数成 `{id: 张数}`，用来核对卡组构筑展开对不对 |
| `_has_load_deck` / `_load_deck` | `pending/deck_build` | 反射检测 `DataLoader` 有没有 `load_deck` 方法，再**用实例调用** `DataLoader.new().call("load_deck", path)`。**必须实例调用**：方法还没实现时静态调用会编译报错，整个文件 0 项 |
| `_write_user_deck` | `pending/deck_build` | 往 `user://` 写一个临时卡组 JSON，测非法卡组（超上限/未知 id/总数不对）而不污染 `data/decks/` |

## check.bat —— 验收 / 进度工具（每天用）

双击，或命令行 `tools\check.bat`。它做四件事：

1. `--import` 一次
2. 自动跑 `tests\*_test.gd`（`tests\pending\` 不算）
3. 打印每个文件的 **项数 / 失败 / SCRIPT ERROR** + 合计
4. 打印 **E15、C8 的检查点**（哪些已经绿了）+ 下一步建议

底层是 `check.ps1`（PowerShell；中文输出要求文件是 **UTF-8 带 BOM**，改它的时候别把 BOM 丢了，
`setup_git.ps1` 同理——**任何 .ps1 里只要有中文就必须带 BOM**，并且用编辑器/脚本改完要复查头 3 字节是不是 `EF BB BF`，
否则 PowerShell 5.1 会把中文读成乱码）。Godot 路径变了就改 `check.ps1` 顶部的 `-Godot` 参数。

当前目标：**485/485**（18 个测试文件）；`tests/pending/` 已清空（8 份红基线全部实现并启用）。

## 和 tests/ 的区别（重要）

| | `tests/` | `tools/` |
|---|---|---|
| 回答的问题 | "代码**对不对**" | "数据**合不合理**" |
| 通过标准 | 断言全绿 | 没有非法数据 / 数值是否平衡 |
| 何时跑 | 每次提交（CI） | 改数据后手动跑；M3 起可进 CI |
| 输出 | PASS / FAIL | 报表、CSV、图表 |

## 运行方式（约定）

```bash
# 本地（headless）
Godot_v4.x-stable_win64_console.exe --headless --path . --script res://tools/validate_data.gd
```

## 一个提醒

工具写出来是**给你自己用的**。所以丑一点没关系，但一定要：
- 一条命令能跑
- 输出能直接看出「哪一行错了」
- 不要依赖界面

## balance_sim.gd（M3.6 平衡模拟器）

批量跑自动对局并统计胜率 / 回合数 / 超时，输出 CSV。规格见 `docs/m3-scope.md` §M3.6。

```powershell
# 在项目根目录执行（Godot 路径是相对仓库的）
$g = "..\..\..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
# 100 场冒烟
& $g --headless --path . --script res://tools/balance_sim.gd -- --games 100
# 1 万场 + CSV（本地工具，不进 CI）
& $g --headless --path . --script res://tools/balance_sim.gd -- --games 10000 --seed 42 --out res://balance.csv
```

| 参数 | 含义 |
|---|---|
| `--games N` | 对局数（默认 100） |
| `--seed S` | 起始种子（默认 42；第 i 局 = S+i，可复现） |
| `--max-turns N` | 单局最大回合（默认 30） |
| `--out PATH` | CSV 路径（可选） |
| `--all-cards` | 用全牌库（E14 之前 AI 不打指令卡，会大量 RUNNING；默认只用单位卡） |

汇总输出：WIN/LOSE/RUNNING 局数、玩家胜率（目标 45%–60%）、平均回合（目标 8–20）、超时率（目标 <1%）。报告模板见 `docs/balance-report.md`。

## validate_data.gd（M3.5 数据校验器）

改完 `data/` 后手动跑，逐条列出非法项（退出码 0 = 合法）：

```powershell
& $g --headless --path . --script res://tools/validate_data.gd
```

检查：cards.json 字段/枚举/重复 id/count、reactions.json 元素配对与 effect 引用、statuses.json 效果字段、elements.json、**data/decks/*.json（39 张、同名 ≤4、未知 id）**。**不查数值平衡**（那是 `balance_sim.gd`）。

## setup_git.ps1（另一台机器 / 另一份 DSH 首次配置 git）

```powershell
powershell -ExecutionPolicy Bypass -File tools\setup_git.ps1              # 当前项目目录
powershell -ExecutionPolicy Bypass -File tools\setup_git.ps1 -CloneTo "D:\projects\reaction-card-battler"
powershell -ExecutionPolicy Bypass -File tools\setup_git.ps1 -DryRun      # 只看会改什么
```

做的事：git 检查 → init/clone → user.name/email（默认 CoIumblna / awmrzhdlyb2010@163.com，可 `-Name`/`-Email` 覆盖）→ remote origin → `core.autocrlf=false` / `core.quotepath=false` / `core.longpaths` / `pull.rebase=false` → `safe.directory` → 凭据管理器检测。`-Global` 可把身份同时写进全局配置。
