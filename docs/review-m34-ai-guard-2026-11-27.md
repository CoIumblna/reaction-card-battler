# M3.4 前置块 · 第一轮评审（2026-11-27）

> 对象：学员未提交的 WIP（`data/tables/cards.json`、`src/core/battle.gd`，HEAD `49625c2`）
> 依据：`docs/brief-m34-ai-guard-2026-11-26.md`（作业单，只给思路）＋ `tests/pending/ai_guard_test.gd`（红基线 14 项 / 6 失败 / 1 SCRIPT ERROR）
> 原则：**这里只给诊断和方向，不给函数体**。函数签名可以照抄，函数体必须你自己写出来——M3.8a 要在这段代码上继续改。

---

## §0 一句话结论

**方向对了一半，实现有三处走偏，其中一处会把测试进程挂死（不是报错，是永远不返回）。**

| 你改的地方 | 状态 | 一句话 |
|---|---|---|
| `_is_guarded()` 两个守卫（S5） | ✅ 对 | 和参考实现逐字一致，那条 SCRIPT ERROR 已经消失 |
| `cards.json` 加两张卡 | ✅ 对 | `validate_data` PASS：15 种 / 57 张，两个 deck 各 39 张 |
| 「三个桶」的思路（`tmp[0..2]`） | 🟡 半对 | 骨架出来了，但**装错了、拼错了、返回错了** |
| `_ai()` 攻击段 | ❌ 错 | 第一分支是**死循环**，第二分支**根本没改** |
| `_ai_attack()` | ❌ 空壳 | `return false`，等于什么都没做（实测：红基线一模一样） |

---

## §1 先说你已经做对的三件事

这三件不要动，也不要在后面「顺手重构」掉：

1. **`_is_guarded()` 的两个守卫位置完全正确**
   `battle.gd:532` `if target == null: return false`、`battle.gd:535` `if tmp.is_empty(): return false`——
   都在取下标**之前**。这就是 S5，`ai_guard_test` [5] 现在绿了。
   注意 `tmp.is_empty()` 必须在 `tmp[1]` 之前，有别的写法（`if tmp.size() < 2`）也对，但你现在这版最不容易看错。

2. **`cards.json` 的两张卡数据合法，且没有把测试弄红**
   这是 §18.1 那个「加卡就红 9 项」修完之后才敢做的事——你现在加卡是**零成本**的，
   说明上一轮的「把写死数字改成从数据现算」起作用了（`tests/data_test.gd` 46 项仍然全绿）。

3. **你想到了用「三个桶」而不是「一层层 if」**
   这就是作业单 §2.2 要的形状：一次遍历、每个敌方单位恰好进一档。思路是对的，
   问题全部出在「桶怎么装、怎么拼、返回哪个」这三步的细节上。

---

## §2 三处必须改（按严重度排序）

### 2.1 【致命】`battle.gd:161-162` 是死循环 —— 测试不是红，是**永远不返回**

```gdscript
			while not attack_unit(u,_opposite_hq(owner)):
				continue;
```

`continue` 在 `while` 里 = 跳回条件判断，**参数一个都没变**，于是 `attack_unit` 返回同一个 `false`，永远循环。

实测症状（我这边跑过）：`--script res://tests/pending/ai_guard_test.gd` **120 秒不退出**，一个字符都不打印。
更麻烦的是 `run_tests.bat` PART1 会**卡在这个文件**上，看起来像「测试坏了」，实际是你的 AI 在转圈。

**为什么它不可能靠「再试一次」成功**：`attack_unit` 拒一次之后局面没有任何变化（被保护还是被保护、够不到还是够不到、
这个单位这一回合已经出手过还是出手过）——**决定成败的是「打谁」，不是「试几次」**。
所以循环变量必须是**目标**，不能是「同一个目标重试」。

正确形状（签名可照抄，body 自己写）：

```gdscript
func _ai_attack(attacker:Unit, owner:String) -> bool:
	# 拿清单，从第一个开始试，attack_unit 接受就 return true；全部不接受才 return false
```

顺带说清一件事：`attack_unit` 的返回值是**唯一的权威**——它内部会查 S3（`_is_guarded` 拒）、
查射程（`_line_span_to`）、查行动花费、查 `can_attack()`。**你在 AI 里不要再复述一遍这些规则**，
复述就等于同一套规则有两个副本，迟早分歧（`find_first_attackable` 就是那个已经被抛弃的副本）。

### 2.2 【根因】`battle.gd:163-169` 第二条分支**一行没改** —— [2] 红的正是它

```gdscript
	elif board.has_unit_of("front") == _opposite(owner):
		for u in board.units_in(_support_of(owner)):
			...
			var tgu = board.find_first_attackable("front",owner)
			if tgu == null: break
			attack_unit(u,tgu)
```

`find_first_attackable()` 里写死了「跳过 Guard」，所以「敌方前线只有 Guard」时它返回 `null`，
`break` 一跳 → **这个支援线单位整个回合什么也没做**。这就是作业单 §0 那个「白扔回合」的 bug 本体，
它不在第一分支里，在这条 `elif` 里。

更深一层：**这个 `if/elif` 的结构本身就是错的**。它用「前线归谁」当总开关：

- `board.has_unit_of("front") == owner` → 只会「打 HQ」
- `== _opposite(owner)` → 只会「在敌方前线上找一个能打的」
- 前线为空 / 两边都有 → **两个分支都不进，一个都不打**

而真实约束是「**这个攻击手，能打到谁**」。同一条前线，近战能打、空军能越线、炮兵不吃反击——
这些差异在 `_line_span_to` 和 `attack_unit` 里，不在「前线归谁」里。
所以 S6 才要求目标清单扫**全部三条线**（`Board.LINES`），而不是「按前线归属分两条路」。

**改法方向**：把「先分两个分支、每个分支各写一遍选目标」换成「**遍历所有己方攻击手，每个都拿同一份清单去试**」。
分支越少，漏掉的情况越少。这正是路线 A 相对路线 B 的全部价值。

### 2.3 【实现】`_ai_attack_targets()` 有三个独立缺陷（`battle.gd:561-577`）

**(a) 返回了错的桶 —— `return tmp[1]`**

你把档 0/1/2 拼进 `tmp[0]`（`battle.gd:575-576`），然后 `return tmp[1]`。
`tmp[1]` 只装「不受保护的非 Guard」，所以你现在**丢掉 HQ、也丢掉 Guard**。
要返回的是你辛苦拼好的那一桶。

**(b) HQ 会同时进档 0 和档 1 —— 两条并列 `if`，不是 `elif`**

```gdscript
			if u == _opposite_hq(owner):
				tmp[0].append(u)
			if u.owner == _opposite(owner):      # ← 不是 elif
				if u.is_guard(): ...
				elif not _is_guarded(u): tmp[1].append(u)
```

HQ 属于敌方、不是 Guard、通常也不被保护 → 它**又一次**被塞进 `tmp[1]`。
`u.is_hq` 这个排除项（作业单 §2.2 的排除表里写了）你没写。

**(c) `Array[Unit]` vs 无类型 `[]` —— 这是会报 `SCRIPT ERROR` 的，`run_tests.bat` 直接判红**

`var tmp:Dictionary = {}` 里掏出来的 `tmp[1]` 是**无类型 `Array`**，而函数声明 `-> Array[Unit]`。
实测（我在干净 worktree 用等价最小例子跑过）：

```
SCRIPT ERROR: Trying to return a value of type "Array" from a function whose return type is "Array[int]".
bad returned: [] type=Array          ← 内容也一起丢了，返回空数组
```

也就是说：**就算你把 (a) 改成 `return tmp[0]`，只要桶是从 Dictionary 里掏出来的，照样 SCRIPT ERROR。**
正解是别绕字典——直接 `var out: Array[Unit] = []`、`var guards: Array[Unit] = []` 两个**类型化**数组，
最后 `out.append_array(guards)`。类型化数组还有个副作用是好的：往里 `append` 一个非 `Unit` 会当场报错，
不用等到运行时才发现塞进了别的东西。

### 2.4 【空壳】`_ai_attack()` 还是 `return false`，而且没人调用

`battle.gd:580-581` 原样没动，`_ai()` 里也**没有任何地方调用它**（`battle.gd:161` 绕过了它直接 `attack_unit`）。

实测指纹（Probe A）：把参考实现的 `_ai_attack` 改成 `return false`，其他一概不动 →
`ai_guard_test` **14 项 / 6 失败**，和你的红基线**逐条相同**。结论：
**「只改 `_ai()` 不实现 `_ai_attack()`」等于什么都没改**，别指望它自己变绿。

---

## §3 五条实测指纹（我这边跑过，改完自己对照）

在干净 worktree 上用参考实现逐条「改坏 → 跑 → 还原」得到的指纹，用来区分「哪种错」：

| # | 故意改成的样子 | `ai_guard_test` 结果 | 说明 |
|---|---|---|---|
| A | `_ai_attack` 留 `return false`（=你现在的状态） | **6 红**，与原始基线逐条相同 | 空壳 = 没改 |
| A' | `_ai_attack` 只试清单第一个（`return attack_unit(a, ts[0])`） | **6 红**，同上 | 「不换目标」和「不实现」同指纹 |
| B | 判定顺序写反（先 `not _is_guarded(u)` 再 `elif u.is_guard()`） | **[4] 红 2 项**：`优先打普通单位（5 → 2）（期望 2，实际 5）` + `Guard 这一回合没被打（期望 6，实际 3）` | Guard 被错分进档 1 |
| C | 档 0 先过滤 `not _is_guarded(hq)` 再入列 | **14/14 全绿** | ⚠️ 见下方说明 |
| D | `_is_guarded` 临时改成 `return true` | **[1][3][4] 红** | 证明测试真的在判保护，不是自证 |

**关于 C 这条要诚实说清**：作业单 §2.2 说「HQ 被保护也照样进档 0，让 `attack_unit` 去拒」，
但**测试区分不出这两种写法**——先过滤也全绿，因为 HQ 被保护时 Guard 一定在场，落到的还是档 2。
所以两种写法都算对；选「不过滤」的理由只有一条：**让 `attack_unit` 当唯一权威，AI 里少一处规则副本**。
这不是「必须这样写」，是「这样写以后改规则只改一处」。别为了它纠结。

---

## §4 改的顺序（每步跑一次，别一次写完再跑）

1. **先把死循环拆掉**（`battle.gd:161-162`）→ 跑 `ai_guard_test`，确认它现在**能跑完并打印**
   （哪怕还是 6 红）。这一步的验收物是「它不挂了」，不是「它绿了」。
2. **`_ai_attack_targets()` 推倒重写**：两个类型化数组、一次遍历、`is_guard()` 先判、`is_hq` 排除、
   末尾 `append_array(guards)`。→ 这一步跑 `ai_guard_test` 会红在「AI 没出手」上，正常。
3. **`_ai_attack()` 按清单依次试** → `ai_guard_test` 应该到 **14/14**。
   没到就对照 §3 的指纹表看是哪一条。
4. **`_ai()` 攻击段改成「遍历全部三条线的己方攻击手，各自 `_ai_attack`」**，并保留
   `is_over()` 提前退出（打掉 HQ 就别继续打了）和原有的 `can_attack()` / `operation_cost > 能量` 两个前置过滤。
   → 重跑 14/14（这一步通常不会变红，但会让 [2] 从「碰巧过」变成「结构上必然过」）。
5. **跑全套**：`run_tests.bat`（主套 18 文件）+ `ai_guard_test` + `validate_data` + `balance_sim`。
6. 三道自查（作业单 §5）：拿掉 Guard / `_is_guarded` 恒 true / 平衡数字不变。

**改 `.gd` 请用编辑器（或 agent 的定点替换工具）**。别用 PowerShell 正则整篇重写：
我自己这一轮踩过——`Set-Content -Encoding utf8` 会把中文变成乱码、顺手把 LF 改成 CRLF 再塞个 BOM，
Godot 的反应是 `Parse Error: Could not parse global class "Battle"`，看起来像「代码写错了」，实际是文件坏了。

---

## §5 我要验的三样东西（你报 done 的时候一起给）

| 项 | 判据 | 参考实现的实测值 |
|---|---|---|
| `ai_guard_test` | **14/14 PASS**，无 SCRIPT ERROR | 14/14 |
| 主套 | `run_tests.bat` **19 文件 499/499**（485 + 14），preflight PASS | 19 文件 / 499 项 / preflight PASS（13 项） |
| 数据 | `validate_data` PASS，0 错 0 警 | 15 种 / 57 张 / 两个 deck 各 39 张 |
| 平衡 | `balance_sim --games 200 --seed 1` | **45.0% 胜 / 13.4 回合 / RUNNING 0%**（与改动前逐位相同） |

> 顺带修正一处文档数字：作业单 §5.3 和 §8 写的「平均 13.0 回合」是笔误，实测是 **13.4**。
> 判据仍然是「和改动前逐位相同」，具体是 13.4 还是 13.0 不重要，**变了才是问题**。

---

## §6 参考实现已验证（但先别抄）

| 交付物 | 位置 | 验证结果 |
|---|---|---|
| 参考实现 worktree | `G:\constraction\_ref_ai_guard`（detached，**不进 git**） | 14/14、19 文件 499/499、preflight PASS、validate PASS、balance 45.0%/13.4/0% |
| 补丁 | `G:\constraction\_ref_ai_guard_pkg\AiGuard-impl.patch` | 同上（在干净 worktree 上 `git apply` 过） |

**先别抄的理由不是「怕你偷懒」，是三条具体的**：

1. 抄完你过不了 §5 的自查（拿掉 Guard 会怎样、恒 true 会怎样），下一块 M3.8a 要在同一段代码上继续改，
   所有权不在你手里的时候改起来会一直在猜。
2. 这个块真正的考点是 **2.2 那个结构问题**——「用局面归属当开关」vs「用能力清单当开关」。
   抄下来的代码能过测试，但你会以为自己学到的是「三个桶」，实际学到的是「一个循环」。
3. 参考实现的形状和你的差得不多（`+36/−10` 行，2026-11-27 重新落盘测过），真正值钱的是**你那三处错为什么错**，
   而不是最终那 46 行；作业单附录里那个 `+33/−22` 是更早一版的数字。
