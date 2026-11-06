# tools/ —— 工具链

> 为什么工具要单独放：它们**不是游戏的一部分**，不打包进发行版，但每天都要用。
> 大厂里这块叫「构建管线 / 工具链」，是策划和程序交界的核心区域。

## 计划中的工具

| 文件 | 什么时候做 | 作用 | 输入 → 输出 |
|---|---|---|---|
| `validate_data.gd` | M2 | 校验 `data/tables/*.json` 的字段、枚举、引用是否存在 | JSON → 终端报错列表 |
| `balance_sim.gd` | M3 | 批量跑战斗（1 万场），统计胜率/回合数/卡牌使用率 | 数据表 → CSV 报告 |
| `export_report.gd` | M3 | 把模拟结果生成 Markdown 表格 | CSV → `docs/balance-report.md` |

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
