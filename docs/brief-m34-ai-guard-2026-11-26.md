# M3.4 前置：AI 选目标（Guard 遗留）施工思路 · 2026-11-26

> 这块是 **M3.2 登记在案的遗留缺陷**，`docs/implementation-tasks.md` §32 末尾写着
> 「M3.4 上真实 guard 卡前必须处理」。现在 M3.4 正在加真实 guard 卡，所以先把它清掉。
>
> 本文件**只给思路，不给函数体**。函数名/签名可以给（那是接口约定），
> 里面的逻辑你自己写。写不出来先问「为什么」，不要问「代码是什么」。

---

## §0 现状：缺陷是真的，不是猜的

我写了一个验收测试 `tests/pending/ai_guard_test.gd`（14 项），当前基线：

```
共 14 项检查，失败 6 项
FAIL
```

失败的 6 项全部指向同一个病灶：**AI 挑了一个打不了的目标，然后什么也不做就结束了**。
另外还顺带暴露出 1 条 **SCRIPT ERROR**：

```
SCRIPT ERROR: Invalid access of index '1' on a base object of type: 'Array'.
    at: Battle._is_guarded (res://src/core/battle.gd:534)
```

这条错误不是「测试写错了」，是 `_is_guarded()` 对**不在场上的单位**会崩。两件事一起修。

---

## §1 病灶定位（自己去看代码，位置已给）

`src/core/battle.gd` 的 `_ai(owner)` 里，攻击段落现在是**两个互斥分支**：

| 分支条件 | 现在的做法 | 病灶 |
|---|---|---|
| `board.has_unit_of("front") == owner` | 循环前线单位，**一律** `attack_unit(u, _opposite_hq(owner))` | HQ 被 Guard 保护 → `attack_unit` 返回 false，**返回值没人接**，这个单位就白过了。既不换目标，也不报错，连日志都没有 |
| `board.has_unit_of("front") == _opposite(owner)` | `find_first_attackable("front", owner)`；为 null 就 `break` | `find_first_attackable` 的筛法是「**不是 Guard**」。对方前线只有 Guard 时返回 null → 直接 `break`，全队白过 |

对比 `tests/guard_test.gd` 第 8 项（已绿）：`attack_unit` 拒绝被保护目标是**正确行为**。
问题在 **AI 侧的选目标策略**，不在 `attack_unit`。

---

## §2 规则（要做到什么）

| 编号 | 规则 |
|---|---|
| S1 | AI 的单位**只要还有合法目标，就必须真的打出去**，不允许空过一整个回合 |
| S2 | 选目标优先级：**敌方 HQ（可达且没被保护）> 没被保护的非 Guard 单位 > Guard 本身** |
| S3 | 被 Guard 保护的友军**永远不该被 AI 选成目标**（打了必被拒 = 白扔） |
| S4 | Guard 本身**永远是合法目标**（`guard_test` 第 4 项已定：Guard 之间互不保护） |
| S5 | `_is_guarded()` 对不在场上的单位返回 `false`，**不能崩** |

---

## §3 三个对象的能力边界（决定这段代码该长在哪）

| 对象 | 有什么 | 没有什么 |
|---|---|---|
| `Board` | `LINES = ["enemy_support","front","player_support"]`、`units_in(line)`、`position_of(unit) -> Array`（**不在场上返回空数组**）、`unit_at`、`find_first_attackable(line, owner)`（筛法=不是 Guard，**不符合 S2 的优先级**） | 不知道怎么算「被保护」——那是 Guard 词条的规则，属于战斗层 |
| `Battle` | `_is_guarded(target) -> bool`（已经是权威判据）、`_opposite_hq(owner) -> Unit`、`_energy_of(owner)`、`attack_unit(attacker, target) -> bool`（**返回真假**，这是关键） | 没有现成的「合法目标清单」 |
| `Unit` | `can_attack()`、`operation_cost`、`is_guard()`、`owner`、`is_hq` | 不知道自己被不被保护 |

两句话结论：

1. **「这个目标能不能打」的权威判据是 `attack_unit` 的返回值**，不是你在外面猜。
   外面猜的每一条规则都可能和它对不上（够不着、被保护、能量不够、同主……）。
2. **`find_first_attackable()` 现在没用**——它的筛法是「不是 Guard」，和 S2 的
   「Guard 是**最后**的候选」冲突。你可以不用它（保留不动，别删，`guard_test` 没断言它）。

---

## §4 两条可选路线（自己选，各自代价写清）

### 路线 A：给攻击手排一张目标清单，依次试到成功

- 形状：一个私有函数返回「按 S2 排好序的敌方目标数组」，另一个私有函数拿着攻击手遍历这张表，
  第一个 `attack_unit` 返回 true 的就停。
- 优点：**失败的原因完全交给 `attack_unit` 判**，你不用在外面复刻规则 → 以后加新规则（比如 M3.6 的、
  M3.8a 的）这里不用改。
- 代价：每个攻击手都会重建一次目标清单（`units_in` × 3 条线）。棋盘最多 15 格，**这个开销可以忽略**，
  不要为它做缓存。
- 这是参考实现的路线。**推荐**。

### 路线 B：每个分支各写一遍兜底

- 形状：第一分支打完 HQ 检查返回值，false 就换下一个目标；第二分支把 `find_first_attackable`
  换成「自己扫一遍找没被保护的」。
- 优点：改动行数少一点，贴着现有结构。
- 代价：**同样的优先级逻辑写两遍**，两处容易走偏（比如第一分支漏了「Guard 是最后候选」）。
  以后再加兵科/关键词规则要改两个地方。

> 选哪条都行，但**在提交信息里写清楚你选了哪条、为什么**。

---

## §5 三条自查判据（不改测试就能证明你写对了）

1. **把 Guard 从场上拿掉**，AI 应该恢复成「打 HQ」——如果拿掉后行为不变，说明你根本没在判保护。
2. **把 `_is_guarded()` 临时改成永远返回 `true`**，AI 应该**改成打 Guard 本身而不是空过**
   → 这说明你走的是「换目标」路径，不是「换个地方继续白扔」。
3. 跑 `tools/balance_sim.gd --games 200 --seed 1`：**胜率必须还是 45.0%、平均 13.0 回合**。
   真实卡池现在**没有** guard 卡，所以这个改动**不该影响平衡**。数字变了 = 你顺手改坏了别的东西。

---

## §6 六条坑（每条都有人踩过）

1. **`attack_unit` 的返回值必须接。** 现在是 `attack_unit(u, ...)` 单独一行——
   这是整个缺陷的根。GDScript 不报「你没用返回值」，所以只有测试能抓。
2. **`board.has_unit_of("front")` 返回的是 owner 字符串**（空线返回 `"empty"`），
   不是数组、不是 bool。别拿它和 `true` 比。
3. **`position_of()` 对不在场上的单位返回空数组 `[]`**，`tmp[1]` 直接抛
   `Invalid access of index '1'`。`_is_guarded()` 的 `tmp.is_empty()` 守卫必须**在取下标之前**。
   （`_is_guarded(null)` 也要能活，顺手加 `target == null`。）
4. **别把 `_ai_attack_targets()` 写成「只给前线」或「只给支援线」**。
   空军能从支援线打支援线（M3.3 的 `_line_span_to`），所以候选要扫**全部三条线**。
5. **别用 `board.units_in()` 的遍历顺序当优先级**。`units_in` 是按格子下标从小到大，
   跟「谁该先被打」没关系。优先级只能靠 S2 那三条显式排。
6. **改完先 `--import` 再跑测试**。新增函数后不 import，`--script` 跑起来会拿旧缓存，
   症状是「改了没反应」。

---

## §7 顺序（照着做，每步跑一次测试）

1. 先修 `_is_guarded()` 的两个守卫（S5）→ 重跑，**那条 SCRIPT ERROR 应该消失**，
   失败数从 6 降到 6（这个 bug 单独不改变断言结果，但 `run_tests.bat` 会因为
   `SCRIPT ERROR` 判红，所以必须先修）。
2. 再改 `_ai()` 的攻击段（S1–S4）→ `ai_guard_test` 应该到 14/14。
3. 跑主套 18 个文件 + `validate_data` + `balance_sim` → 全绿且平衡数字不变。

---

## §8 验收表

| 项 | 判据 |
|---|---|
| [1] | HQ 被 Guard 保护 → 改打 Guard 本身，AI 单位 `has_attacked == true` |
| [2] | 玩家前线只有 Guard → 敌方支援线单位打这个 Guard（`find_first_attackable` 不再直接 break） |
| [3] | 被保护的 victim 一点血不掉，Guard 掉血 |
| [4] | 同线「Guard + 两格外普通单位」→ 优先打普通单位，Guard 不掉血 |
| [5] | 不在场上的单位 `_is_guarded()` 返回 false，无 `SCRIPT ERROR` |
| 全绿 | `ai_guard_test` **14/14 PASS**；主套 **19 文件 499/499**（485 + 14） |
| 数据 | `validate_data` PASS（0 错 0 警） |
| 平衡 | `balance_sim --games 200 --seed 1` → **45.0% / 13.0 回合 / RUNNING 0%**（与改动前完全一致） |
| 无假绿 | 全绿后你把 `_is_guarded` 改成永远 true，[1][3][4] 必须变红 |

**红绿指纹**（改错方向时一眼能认）：
- 只接返回值但**不换目标** → 只剩 [1][2][3] 红（还是空过，只是不崩了）。
- 换目标但把 Guard 排在最前 → [1] 绿、[3][4] 红（打了 Guard，但被保护的 victim 优先被打）。
- 只在一条线上找目标 → [2] 或 [4] 单独红。

---

## 附：参考实现

`G:\constraction\_ref_ai_guard_pkg\AiGuard-impl.patch`（**不进 git**，`git diff -- src/`，2611 字节）
已在干净 worktree 上验证 `git apply` OK、`ai_guard_test` 14/14、主套 19 文件全绿、平衡不变。
另一个文件 `battle.gd` 是打完补丁后的完整版本，卡住时可以对照**思路**，但别整段抄——
抄了你过不了「自查判据」，而且 M3.8a 要在这段基础上继续改。
