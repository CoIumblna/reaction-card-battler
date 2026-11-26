# M3.7 作业单：通用 stat 系统（stat_mod 通用层 + defense_down）

> 学员拍板（2026-11-26）：**做通用 stat 系统**，不是只给 `defense_down` 写死分支。
> **难度 ★★★（比纯 M3.7 高半档）、预计 1–1.5 h。**
> 任务卡：`docs/implementation-tasks.md` §36。验收：
> `tests/pending/stat_mod_test.gd` **7 项**（规则）+ `tests/pending/stat_system_test.gd` **18 项**（通用性）。
>
> 本文件只给**思路和决策点**，不贴成品代码 —— 代码你来写。

---

## 0. 现状

```powershell
$g = $env:GODOT
cd "G:\constraction\reaction-card-battler"
git status -sb
"$g" --headless --path . --script res://tests/pending/stat_mod_test.gd
"$g" --headless --path . --script res://tests/pending/stat_system_test.gd
```

现在：`stat_mod_test` **7 项 / 3 失败**（`[2][3][4]` 红）、
`stat_system_test` **18 项 / 18 失败**（整个通用层还没影）。

两个文件的分工，别混：

| 文件 | 测什么 | 项数 |
|---|---|---|
| `stat_mod_test.gd` | **规则**：`defense_down` 每层让受到的伤害 +1，单位攻击和指令卡都吃 | 7 |
| `stat_system_test.gd` | **通用性**：属性查询是一层可复用的东西，不是为某一状态写死的分支 | 18 |

---

## 1. 这一版和上一版的区别

上一版我说「只有一个 `stat_mod` 状态，提前做通用层是空的，推荐只认 `kind`」。
你选了做通用层。**那约束就变了**，不再是「能算对 `defense_down` 就行」，而是：

> **系统里出现任何一条新的 `stat_mod` 效果，不改代码就该生效。**

这条约束把「认 `b.kind == "defense_down"`」这条路直接排除掉了 —— 它正是被否掉的写法。

`stat_system_test` 就是照这条约束设计的：它用的 `attack_up` / `defense_up` / `luck` **都不在**
`data/tables/statuses.json` 里，是**运行时注入**到 `b.status_table.statuses` 的。
只要你写死了状态 id 或属性名白名单，这些用例必红。

---

## 2. 规则（两个文件共同的规格）

| 项 | 值 |
|---|---|
| 属性生效值 | 基础值 + 身上所有 `stat_mod` 效果按 `stacks` 的加总 |
| 基础值来源 | `attack` → `Unit.attack`；`defense` → **0**（单位没有基础防御字段） |
| 计算顺序 | 生效值在**攻击发起前**算好，喂给 `compute_damage`；最终伤害 `max(0, ...)` 钳位 |
| `immune` 时 | **不加减防**（伤害本来就无效，别算出「免疫还掉血」） |
| 失效 | 走已有的 `Buff.tick_buffs()`，`duration` 到 0 就移除，效果随之消失 |
| 叠层 | `Unit.add_buff()` 同 `kind` 只 `stacks += 1`，**不新增 Buff 对象** |

---

## 3. 三个对象各自能拿到什么（设计决定点就在这里）

| 对象 | 有 | 没有 |
|---|---|---|
| `Buff`（`src/core/buff.gd`） | `kind` / `stacks` / `duration` | `stat`、`value`（在 JSON 里） |
| `Unit` | `buffs` 数组 | `StatusTable`（不持有） |
| `Battle` | `status_table` 成员（`battle.gd:26`） | — |

「`value` 是多少」「`stat` 是什么」只有 `Battle` 能顺手问到。由此两条路线，**任选**：

- **路线 1（推荐）**：属性查询整个留在 `Battle` 里（它是 `compute_damage` 的宿主）。
  `unit.gd` 一行不动，`Battle` 加一个公开方法 `stat_of(unit, stat) -> int`。
- **路线 2**：下放到 `Unit`，那 `Unit` 必须多收一个 `StatusTable` 参数
  （`stat_mod(stat: String, table: StatusTable) -> int`，**两个参数**），`Battle` 调它时递进去。
  代价：每个调用点都要传 table。

**两条路线都能全绿（我实测过）**，差别只在「多一个参数」还是「逻辑集中在一个文件」。
`stat_system_test` 第 [1] 项按**路线 1 的签名**写（`b.stat_of(atk, "attack")`）；
若你走路线 2，告诉我，我改测试 —— **不要为了迁就测试而选路线**，先选你觉得对的。

---

## 4. 判断「哪条 buff 该算」：只认数据，不认 id，不认白名单

这是通用层和写死分支的分水岭。需要读的是**状态定义里的三个字段**，不是状态名：

| 字段 | 意思 | 你的系统该怎么用 |
|---|---|---|
| `kind` | 效果类型 | 只处理 `"stat_mod"`（别的 kind 是 dot / disable / aura，各有归属） |
| `stat` | 改哪个属性 | **和查询的 `stat` 相等就计入** —— 不要列白名单（`attack`/`defense`/`hp`…） |
| `value` | 加多少 | 乘 `stacks`，四舍五入取整 |
| `timing` | 什么时候生效 | **缺省按 `passive` 处理**；写了别的值（如 `turn_start`）就不计入属性 |

第 4 条容易被忽略：`tools/validate_data.gd` 对 `stat_mod` **只强制 `stat` / `value`**，
`timing` 是可以缺省的。要是你写成「必须 `== "passive"` 才算」，缺省的效果会被静默丢掉 ——
`stat_system_test` [6] 专门抓这条。

---

## 5. 通用层必须满足的三条判据

1. **注入一个数据表里不存在的状态，它必须生效。** 这是通用性的唯一证明。
   你可以在编辑器里临时往 `b.status_table.statuses` 塞一条 `stat_mod` 试。
2. **改 JSON 里的 `value`，代码行为必须跟着变。** 不变 = 数值写死在代码里了。
   试：把 `defense_down` 的 `-1.0` 改成 `-2.0`，`stat_mod_test` [2] 的期望值应变成 5。
3. **未知属性名不崩、不串台。** 查 `"luck"` 返回那条 `luck` 的加总；
   查 `"attack"` 不受影响、伤害不变。

---

## 6. 加在哪里、四条约束

`Battle.compute_damage()` 是**单位攻击**（`attack_unit`）和**指令卡伤害**（`play_card`）共用的出口，
属性加算放这一层，两处都生效。

1. **`immune` 时不要加** —— `Damage.compute()` 返回的字典带 `immune` 标记，此时伤害本就无效。
2. **别改 `damage.gd`** —— `Damage.compute()` 是 `static`（摸不到 `status_table`），
   且 `combat_test` / `damage_test` / `status_test` 有大量 `hit["damage"]` 断言。
3. **伤害钳到 0** —— 防御可能高过攻击（`stat_system_test` [3] 就是 2 点攻击打 3 点防御）。
   不钳位的话负伤害流进 `take_damage()` 会走「护盾够扣」分支变成 `shield -= 负数`，
   **白送护盾、血量却不掉** —— 看着像"挡住了"，其实是数据被写坏。[3] 有一条专门断言 `shield == 0`。
4. **攻击方和反击方都要用生效值** —— `attack_unit` 里有两次 `compute_damage`：
   攻击方一次、反击方一次（在 `no_counter()` 为 false 的分支里）。只改前一处的红绿指纹是
   `[2][4]` 红、其余绿。

---

## 7. 四条坑

1. **叠层要用 `b.stacks`**。`add_buff()` 同 `kind` 只做 `b.stacks += 1`，不新增对象。
   数 `buffs.size()` 永远算 1 倍。
2. **加在目标侧，不是攻击侧**。是「目标受到的伤害 +1」，不是「攻击者攻击力 +1」。
3. **`Buff` 上没有 `stat` / `value`**。别指望 `b.value`，数值必须经
   `status_table.get_status(b.kind)` 问出来。
4. **别给 `Unit` 加 `status_table` 成员**。用参数传。加成员会让单位脱离数据表就不能单测，
   `unit_test` 里那些直接 `Unit.from_dict(...)` 造的单位会崩。

---

## 8. 顺序

1. 定路线（`Battle.stat_of` 还是 `Unit.stat_mod(stat, table)`），先跑通 `stat_mod_test` 7/7
2. 再跑 `stat_system_test`，按红的那几条反推通用性缺哪一环
3. `run_tests.bat`：PART 1 **15 file(s) 全绿**、PART 1.5 里 `stat_mod_test` / `stat_system_test`
   都变成 `[READY  ]`（`deck_build_test` 仍是红基线，正常）
4. 报 done

---

## 9. 我会怎么验收

| 项 | 期望 |
|---|---|
| `stat_mod_test` | **7/7 PASS**，0 SCRIPT ERROR |
| `stat_system_test` | **18/18 PASS**，0 SCRIPT ERROR |
| 主套 | **17 文件 474/474**（449 + 7 + 18） |
| `validate_data` | PASS，0 错 0 警 |
| `balance_sim` | 48.0% / 13.0 回合 / RUNNING 0%（真实卡池没有减防卡，行为应不变） |
| 独立 worktree 复验 | 单独检出这个 commit 也是 474 全绿 |
| **反假绿探针 ①** | 把属性查询改成「只认 `defense_down`」→ `stat_mod_test` 仍 7/7，但 `stat_system_test` 必红 9 项 |
| **反假绿探针 ②** | 把 attack 侧的 `compute_damage` 改回 `attacker.attack` → `stat_system_test` 红 [2][4] |
| **反假绿探针 ③** | 去掉 `max(0, ...)` 钳位 → `stat_system_test` 红 [3] 的护盾断言 |
| **反假绿探针 ④** | 去掉 `timing` 缺省处理 → `stat_system_test` 红 [6] |
| 数据跟随性 | JSON 里 `-1.0` → `-2.0`，`stat_mod_test` [2] 期望值变 5 |

四条探针我都跑过，红绿指纹如上 —— 这说明这些断言真的在测东西，不是摆设。

---

## 附：和 §36 的关系

§36 是任务卡（规则 + 历史 + 坑），本文件是**施工思路**，冲突以本文件为准。
§36 里「推荐只处理 `defense_down`」那段已作废（那是通用层没拍板时的建议）。
