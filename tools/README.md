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

工具会自己 `type: "unit"` 写进去。**指令卡必须是 `type: "order"`** —— 漏写时 `Card.from_dict()`
默认成 `"unit"`，M2 的部署逻辑会把火球当成能上场的单位。`data_test[1]` 有一条断言盯着这个。

写回格式跟手写的一致（2 空格缩进、每张卡一行、UTF-8 无 BOM），写完会重新解析一遍自检；
万一手滑写坏了，`git checkout -- data/tables/cards.json` 一条命令回滚。

## check.bat —— 验收 / 进度工具（每天用）

双击，或命令行 `tools\check.bat`。它做四件事：

1. `--import` 一次
2. 自动跑 `tests\*_test.gd`（`tests\pending\` 不算）
3. 打印每个文件的 **项数 / 失败 / SCRIPT ERROR** + 合计
4. 打印 **E15、C8 的检查点**（哪些已经绿了）+ 下一步建议

底层是 `check.ps1`（PowerShell；中文输出要求文件是 **UTF-8 带 BOM**，改它的时候别把 BOM 丢了，
否则 PowerShell 5.1 会把中文读成乱码）。Godot 路径变了就改 `check.ps1` 顶部的 `-Godot` 参数。

当前目标：308/308（7 个测试文件）；把 `tests/pending/status_test.gd` 移到 `tests\` 后目标 320/320。

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