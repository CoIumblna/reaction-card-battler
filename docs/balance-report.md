# 平衡报告（模板，待 M3.6 填）

> 状态：**模板（2026-11-21 教练起草）**。M3.6 写完 `tools/balance_sim.gd` 后按此结构填。
> 目的：用数据回答"这套卡池/数值平不平衡"，并把调参过程留痕，而不是凭感觉改数字。

## 1. 方法与参数

| 项 | 值 |
|---|---|
| 模拟器 | `tools/balance_sim.gd`（M3.6） |
| 对局数 | 10000（本地）；CI smoke 只跑 100 |
| 牌组 | `data/decks/player_deck.json` vs `data/decks/enemy_deck.json` |
| 随机种子 | `--seed 42`，同 seed 可复现 |
| 双方 AI | 同一套 `_ai(owner)` 策略（先打 HQ，Guard 例外按 ADR-004） |
| 指标 | 玩家胜率、平均回合、超时(RUNNING)比例、双方 HQ 剩余血量分布 |

跑法：

```powershell
$g = "C:\Users\LD\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
cd "C:\Users\LD\Desktop\资料\whk\reaction-card-battler"
& $g --headless --path . --script res://tools/balance_sim.gd -- --games 10000 --seed 42 --out res://balance.csv
```

## 2. 结果（待填）

| 版本/提交 | 胜率 | 平均回合 | 超时局 | 备注 |
|---|---|---|---|---|
| （初始，未调参） | — | — | — | — |
| v0.3-a | — | — | — | — |
| v0.3-b | — | — | — | — |

> 目标：**胜率 45%–60%**；超时（RUNNING）**< 1%**；平均回合 **8–20**。

## 3. 结论与下一步（待填）

- 哪些卡过强/过弱（按使用率与胜率贡献）：
- 下一轮要改的数值（一次只改 1–2 个变量）：
- 是否需要在 M3.5 引入"兵科/关键词"再平衡：

## 4. 复现说明

- CSV 文件不进 git（大）；报告里贴汇总表与 seed。
- 调参提交信息示例：`balance(cards): 坦克 4/5 -> 4/4，胜率 62% -> 57%`
