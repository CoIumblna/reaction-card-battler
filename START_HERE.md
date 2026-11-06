# 从哪开始看（索引）

| 你想…… | 打开 |
|---|---|
| **动手写代码**（每个脚本要实现什么、怎么验收） | [docs/implementation-tasks.md](docs/implementation-tasks.md) |
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
