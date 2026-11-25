# M3.1 作业单 · 行动经济 + 关键词 + 闪击（2026-11-25）

> 学员：本次改 `src/core/unit.gd`、`src/core/card.gd`、`src/core/battle.gd` 三个文件。
> 规格：`docs/adr/004-m3-keywords.md` 决定 1 + `docs/implementation-tasks.md` §31。
> 验收：`tests/pending/keywords_test.gd` **17 项全绿**，同时主套 **400/400** 不许掉。

---

## 0. 先说结论：验收包已验通

教练已在临时 worktree 写了一份参考实现并跑通，证明这份 pending 测试**是可通行的红基线**，
不是写坏了的测试：

```
keywords_test.gd     17 项 / 0 失败 / 0 SCRIPT ERROR   ← 本块验收目标
主套 11 个文件        400 项 / 0 失败 / 0 SCRIPT ERROR
tools/validate_data   PASS（0 错 0 警）
```

参考实现留在 `G:\constraction\_ref_m31\`（**不进 git**），补丁在 `G:\constraction\_ref_m31_pkg\`：
`M31-impl.patch`（实现）/ `M31-tests.patch`（教练的测试迁移）/ `M31-tools.patch`。
**不要去看/抄它**——它只是证明"能做到"。抄了这关过了，M3.2 Guard 和 M3.3 兵科你还是得自己想，
而那两块逻辑是叠在这一块的字段语义上的。

---

## 1. 要改成什么样（规格摘要）

### 1.1 `Unit`：`has_acted` → `has_moved` + `has_attacked`

| 项 | 规则 |
|---|---|
| 字段 | 删 `has_acted`，加 `has_moved` / `has_attacked`（都 `bool`，默认 false） |
| 回合开始 | 己方**非 HQ** 单位两个标志都清 false（支援线+前线都要清） |
| 普通单位 | 移动**或**攻击二选一：先移动→不能再攻击；先攻击→不能再移动 |
| 坦克 `unit_class=="tank"` | 移动 + 攻击**都能做**（各一次） |
| 召唤失调 | 部署当回合两个标志都 **true** |
| 闪击 `blitz` | 部署当回合两个标志都 **false** |
| 闪击 + 坦克 | 当回合可以「先移动再攻击」 |

新增字段（`Unit` 也要有，`_deploy_unit` 负责从 `Card` 拷过来）：
- `unit_class: String`（`infantry/tank/artillery/fighter/bomber`，本块只用到 `tank`）
- `keywords: Array[String]`（本块只用到 `blitz`）

### 1.2 `Card.from_dict`：解析 `keywords` / `abilities`

`Card` 早就有 `keywords: Array[String]` 字段，但 `from_dict` **从来没赋值**——这是本块第一个要修的点。
坑：`Array[String]` 是 **typed array**，不能 `c.keywords = d.get("keywords", [])` 直接赋
（untyped 赋给 typed 会报错），必须**逐项 append**。

### 1.3 `Battle`

- `_deploy_unit`：建 `Unit` 时把 `unit_class` / `keywords` 一起带进去；然后
  **闪击 → 两个标志 false；否则两个标志 true**。
- `_begin_turn` / `_enemy_turn`：清标志（原来那行 `u.has_acted = false` 要换掉）。
- `move_unit`：原来 `if unit.has_acted: return false` 要看"能不能移动"；成功后置 `has_moved = true`。
- `attack_unit`：同理，成功后置 `has_attacked = true`。
- `_ai`：原来 `u.has_acted` 的过滤条件要换成"能不能移动/能不能攻击"。
  **注意原来 `_ai` 里有 `attack_unit(...)` 之后手动 `u.has_acted = true` 的两行**——`attack_unit`
  自己会置标志，这两行现在是多余的，删掉（留着也没错，但容易掩盖失败：攻击被拒时会误标）。
- `_settle_status` 的 `disable` 分支（冻结）：改为**两个标志都置 true**。

---

## 2. 已踩过的坑（教练参考实现里真的踩到了）

**① typed array 不能直接赋值**
```gdscript
c.keywords = d.get("keywords", [])        # ❌ 类型不匹配 / 运行时报错
for k in d.get("keywords", []):           # ✅
	c.keywords.append(str(k))
```

**② `_ai` 里攻击后手动置标志会让"攻击失败"也变成"已攻击"**
旧代码是"先调 attack_unit，再无条件 `u.has_acted = true`"。改成双标志后这个错误更明显：
攻击被拒（能量不够/不相邻/目标非法）时不该标 `has_attacked`。正确做法是**让 `attack_unit` 自己标**，
`_ai` 只管"能不能打"的前置过滤。

**③ "二选一"不是"两个都想一次"**
普通单位：`has_moved = true` 之后 `has_attacked` 必须还是 false，但**不能再攻击**。
也就是说 `can_attack()` 判断的不能只是 `not has_attacked`，还要 `not has_moved or is_tank()`。
`keywords_test` 的 `[5] 非坦克：移动后不能再攻击` 就是专门抓这个的——只写 `if has_attacked: return false` 会红。

**④ 召唤失调 ≠ 冻结 ≠ 部署**
三个都要"两个标志 true"，但语义不同；别为了省事在 `_deploy_unit` 里调用 `_settle_status` 之类的东西。
另注意**闪击只免疫召唤失调，不免疫冻结**。

**⑤ 坦克的例外只影响"互斥"，不影响"各一次"**
坦克移动两次仍然不行（`has_moved` 已经是 true）；坦克攻击两次也不行。坦克只是"移动后还能攻击、攻击后还能移动"。

---

## 3. 教练已经做完的部分（你别动）

测试里所有 `has_acted` 断言的重写已由教练完成，**等你实现落地时一起提交**（现在还没进主仓库，
避免主套在实现前就红）。共 4 个文件：

| 文件 | 改动 |
|---|---|
| `tests/board_test.gd` | 1 处：`u.get("has_acted") == false` → 两个标志都为 false |
| `tests/combat_test.gd` | 7 处：移动/攻击/失败不标记，改成分别断言 `has_moved` / `has_attacked` |
| `tests/battle_m2_test.gd` | 5 处：召唤失调、下一回合解除、前线也清、攻击后标记 |
| `tests/status_test.gd` | 2 处：冻结 = 两个标志都 true；解冻 = 都 false |

`tools/check.ps1` 里有一条提示文案写着 `敌方 has_acted 每个敌方回合清零`，也已一并改词。

**项数不会变**：58 / 63 / 38 / 59 / 23 / 46 / 20 / 25 / 35 / 12 / 21 全不变，`EXPECTED_CHECKS` 不用动。

---

## 4. 你自己的操作顺序（每步都跑测试）

```powershell
$g = $env:GODOT
cd "G:\constraction\reaction-card-battler"

# 1) 先只改 Unit 的字段（has_acted → has_moved/has_attacked）+ 加 unit_class/keywords
#    此时主套会红（因为 battle.gd 还在用 has_acted）→ 正常，继续往下改到能编译
# 2) 改 Card.from_dict 解析 keywords/abilities
# 3) 改 Battle 的 _deploy_unit / _begin_turn / _enemy_turn / move_unit / attack_unit / _ai / _settle_status
# 4) 跑主套
tools\check.bat
#    期望：400/400、0 FAIL、0 SCRIPT ERROR
#    （注意：教练的 4 个测试文件此时还没进主仓库，所以主套会因 has_acted 断言而红——
#      这一步实际上是"你改完告诉我，我同步测试迁移，然后一起验"）
# 5) 跑本块验收
& $g --headless --path . --script res://tests/pending/keywords_test.gd
#    期望：共 17 项检查，失败 0 项 → PASS
```

> 因为测试迁移要和你的一起提交，**你改完后先跑 `keywords_test`（它不依赖旧断言），
> 绿了再喊我**。我同步迁移后会一次跑完整套。

---

## 5. 完成判据

- `keywords_test.gd`：**17/17 PASS**，0 SCRIPT ERROR
- 主套（含教练的 4 个测试迁移）：**400/400**，0 `[FAIL]`，0 SCRIPT ERROR
- `validate_data`：PASS
- 数据文件不用动（`data/cards.json` 里 `blitz`/`tank` 可以继续没有——本块测试自己造卡）

**不算通过的情况**：退出码 0 但有 `SCRIPT ERROR`（假绿）；或者把 `keywords_test` 里的断言改松。
