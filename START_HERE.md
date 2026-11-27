# 从哪开始看（索引）

| 你想…… | 打开 |
|---|---|
| **接手 / 换人 / 想知道现在做到哪了** | [docs/HANDOFF-2026-11-23.md](docs/HANDOFF-2026-11-23.md) |
| **动手写代码**（每个脚本要实现什么、怎么验收） | [docs/implementation-tasks.md](docs/implementation-tasks.md) |
| **看当前这块的作业单 / 评审结论** | [docs/implementation-tasks.md](docs/implementation-tasks.md)（**下一块 = M3.6 元素 v3，规格在 §35**；刚完成的 M3.4 卡池作业单与落地记录在 §40 / §40.10，M3.4 前置块的评审在 §39.6、红绿指纹 §39.7、落地记录 §39.9） |
| **排优先级 / 定顺序**（85 项功能总清单） | [BACKLOG.md](BACKLOG.md) |
| 搞懂**玩什么** | [docs/game-design.md](docs/game-design.md) |
| 搞懂**元素反应规则**（附着量、免疫、复合元素） | [docs/element-reactions.md](docs/element-reactions.md) |
| 搞懂**目录为什么这样分** | [docs/architecture.md](docs/architecture.md) |
| **会 C++，想快速上手 GDScript** | [docs/gdscript-vs-cpp.md](docs/gdscript-vs-cpp.md) |
| 决定**先做什么后做什么**（为什么 M1 不做战线） | [docs/adr/](docs/adr/) |
| 跑测试 / 提交代码 | [README.md](README.md) |

## 三层信息在哪

1. **每个 `.gd` 文件第一行** → 指向 `docs/implementation-tasks.md` 的对应章节（就地提示）
2. **`docs/implementation-tasks.md`** → 每个文件的完整任务卡（函数表 + 手段 + 验收 + 坑）
3. **`tests/*.gd`** → 可执行的规格（测试红了 = 还没实现）

> 记住一句话：**测试是规格，任务卡是提示，`.gd` 里的 TODO 是清单**。三者说的是同一件事。
