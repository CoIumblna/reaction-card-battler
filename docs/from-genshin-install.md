# 从「原神安装目录」能读出的工程结构（观察笔记）

> 观察对象：`E:\miHoYo Launcher\game\Genshin Impact Game`（v7.1.0，137 GB）
> 方法：**只看目录、文件类型、清单内容**。不拆包、不反编译、不改动文件。
> 结论先行：这是**发行版**，不是源码工程。它能告诉我们"内容怎么被打包和分发"，不能告诉我们"他们内部代码怎么分层"。

---

## 一、观察到的事实

| 路径 / 文件 | 体量 | 说明 | 对应的工程概念 |
|---|---|---|---|
| `YuanShen.exe` + `YuanShen_Data/` | 424 MB | 标准 Unity 构建布局 | 引擎产物与资源分离 |
| `Managed/Metadata/global-metadata.dat` | 78.9 MB | IL2CPP 元数据 | C# 被 AOT 编译（逻辑不在 dll 里） |
| `StreamingAssets/AssetBundles/blocks/00…15` | 16 个分块 | 资源包按块切分 | **内容分块打包**，便于增量下载/校验 |
| `StreamingAssets/ctable_streaming.dat` | 26.9 MB | 二进制表（头部魔数 `0E F2 01 B5`） | **表格数据编译成二进制**，不是 JSON/CSV |
| `pkg_version`（顶层） | — | 每行一个 JSON：`remoteName / md5 / hash(xxhash) / fileSize` | 文件清单 + 完整性校验 |
| `Persistent/res_versions_persist` | 350 KB | 同样格式，额外有 `isPatch` 字段 | **热更清单 + 增量补丁** |
| `Persistent/PatchDone`、`*_revision` | — | 补丁状态与内容版本号 | 版本状态机 |
| `StreamingAssets/hdiff/` | — | hdiff 是一种二进制差分算法 | 差分更新（只下变化的部分） |
| `AudioAssets/Chinese/`、`Banks*.pck` | — | CRIWARE 音频库，按语言分目录 | **语音按语言分包**（所以有 `Audio_Chinese_pkg_version`） |
| `Plugins/*.dll`（gmesdk、HoYoChannel、AccountPlatNative、APM4webCrash、chrome_elf） | 49 个 | 平台 SDK、账号、崩溃上报、内嵌浏览器 | **平台层隔离**：引擎之外的东西都放插件层 |
| `StreamingAssets/kcp/` | — | KCP（可靠 UDP 协议） | 网络层选型 |
| `xlua/` | — | Lua 运行时 | **脚本热更**：部分逻辑用 Lua 以便线上修 bug |
| `HoYoKProtect.sys`、`mhypbase.dll` | 30 MB | 保护/反作弊 | 发行侧安全 |
| `config.ini` | — | `game_version=7.1.0`、渠道号 | 环境/渠道配置外置 |
| `BeyondAssets/BeyondAssistEditor/` | — | 含 `0Harmony.dll`、`miTools.*`、.NET 8 WPF、`BeyondEditor.exe` | ⚠️ **第三方工具**，不属于米哈游工程结构（Harmony 是运行时补丁库）。如非自己安装，建议排查；此类工具可能违反用户协议。 |

---

## 二、这些事实说明什么：大厂项目其实是"三层"

```
① 源码工程（看不到）      ② 构建管线（半可见）        ③ 发行包（你看到的）
   Unity 工程              Excel/表格 → ctable          exe + Data/ + blocks
   Assets/…                资源 → AssetBundle bundles    清单 + 补丁 + 语音包
   Scripts/…               代码 → IL2CPP + xLua
   Excel 表                多语言 → 分包
        └──────────────► 打包脚本 / CI ◄──────────────┘
```

- **①源码工程**：他们的 Unity 工程（`Assets/Art`、`Assets/Scripts`、`Assets/Scenes`、表格 Excel……）——**安装包里看不到**。
- **②构建管线**：表格编译成 `ctable.dat`、资源打成 blocks、按语言切语音包、生成 md5/xxhash 清单——**从产物能反推出来**。
- **③发行包**：exe + Data + 清单，按版本增量更新——**就是你看到的这些**。

**所以"研究原神项目结构"能学到的，主要是②和③：内容怎么组织、怎么校验、怎么增量更新。** 而①（代码分层）只能靠行业通识 + 自己的工程实践去学。

---

## 三、哪些能抄，哪些不能抄

| 原神的做法 | 你要不要抄 | 你的项目对应做法 |
|---|---|---|
| 表格数据独立于代码 | ✅ 抄 | `data/tables/*.json` + `data/schema/` |
| 内容分块、可增量 | ✅ 抄（缩小版） | 一张表一个文件，别搞成 10 MB 大 JSON |
| 文件清单 + 校验（md5/xxhash） | ✅ 抄（M2 起） | `tools/validate_data.gd` 校验 + 存档校验 |
| 工具链独立于游戏 | ✅ 抄 | `tools/` 放校验器、平衡模拟器 |
| 平台/SDK 隔离 | ✅ 抄（M4 起） | `src/platform/` 包住文件/时间/随机数 |
| 二进制表（ctable.dat） | ❌ 先不抄 | JSON 够用；数据量大了再考虑 |
| 热更 / 差分补丁（hdiff） | ❌ 不抄 | 单机小项目没有线上更新需求 |
| IL2CPP / 反作弊 / CRIWARE | ❌ 不抄 | 与学生项目无关 |
| 多语言语音分包 | 🔶 只留位置 | 以后要 i18n 再加 `data/i18n/` |

---

## 四、调整后的仓库结构

```
reaction-card-battler/
├── project.godot
├── data/
│   ├── tables/          ← 内容数据（卡牌/敌人/反应/元素）
│   └── schema/          ← 字段规范（数据契约）
├── src/core/            ← 规则（不碰界面）
├── tests/               ← 规格
├── tools/               ← 工具链（校验器/模拟器，M2-M3 出现）
├── docs/
│   ├── architecture.md
│   ├── from-genshin-install.md   ← 本文件
│   ├── element-reactions.md
│   └── adr/
└── .github/workflows/ci.yml
```

来源标注：全部为本地安装目录的**目录结构与清单文本**观察，未做任何解包或反编译。
