## 2026-W47（M2 收尾：E15 敌方 AI + C8 状态效果 + E14 指令卡）
- 做了什么：E15 敌方/玩家共用 `_ai(owner)`（部署最贵可支付 → 推进 → 攻击先打 HQ）+ `run_auto` 双方自动对局；C8 状态生效（`status_table` 加载 / 回合开始四步 dot→死亡→disable→tick / 反应挂状态 + 同 kind 叠层）；删掉 `front_controller` 缓存和 M1 的 buff tick；全套 320/320 全绿，E15 与 C8 检查点全完成
- 卡在哪：类型标注的字段不会自动 new（`var status_table: StatusTable` 是 null，调方法直接崩，连坐一屏错误）；`statuses.json` 的 `effects` 是数组不是字典；dot 必须在 tick **之前**结算（否则 duration 2 的燃烧只掉一次、duration 1 的冻结冻不住）
- 追加：E14 指令卡完成——目标规则改为**数据驱动**（`Card.target`：enemy/self，缺省按 kind 推断），补伤害后死亡移除（HQ 不移除）与 M1 兼容放行；`order_test` 35 项启用，全套 **355/355**。
- 卡在哪：目标校验一度写反（棋盘外/棋盘内两边互相拒绝），修好后 m1 回归消失；还要注意默认 target 要在 `kind` 赋值之后算。
- 下周：E7 弃牌堆/洗回（先定 §26 的三个 ❓）→ M3（关键词 Blitz/Guard、兵科、卡池、balance_sim 调参）

## 2026-W46（规格 v2：附着量 / 免疫 / 复合元素 / 状态表）
- 做了什么：元素扩到 6 基础 + 2 复合；反应表按 3.0 前原神填 14 条（增幅/剧变/结晶）；加入附着量 1U/2U 与反应消耗；补上免疫机制；新增状态表 statuses.json + StatusTable
- 卡在哪：`Damage.compute` 签名变了（传 target、返回 effects），实现时要注意 floor 不是 round
- 下周：按 B1 → B3 → A3 → B4 → B5 → B7 推进
# 开发日志 devlog

> 规则：每周日写 3 行 —— 做了什么 / 卡在哪 / 下周做什么。
> 别小看这个文件：三个月后你会忘记当时为什么这么设计，而它就在这。



## 2026-W46（M1）
- 做了什么：完成了element.gd脚本
- 卡在哪：不熟悉.gd脚本，感觉和python比较相似
- 下周：继续流程















## 模板（复制一份到最上面）

```
## 2026-W__（M_: 阶段名）
- 做了什么：
- 卡在哪：
- 下周：
```

---

## 2026-W45（Phase 0：换路线到 KARDS + 拆 damage + 测四件套）
- 做了什么：玩法定为 KARDS 路线（M1 不做战线，ADR-002）；伤害算法拆成 `damage.gd`；测试按"被测单元"拆成 4 个文件（data / unit / damage / battle，共 86 项检查）
- 卡在哪：元素反应数值还没设计；附着规则（反应后是否消耗）没定，`battle_test` [4] 里留了一个待补的断言
- 下周：实现 Element + Card + DataLoader，让 `data_test` 先绿一半

## 2026-W44（Phase 0：拿到 kata 起点）
- 做了什么：仓库骨架和测试（=规格）拿到了；`src/core/` 是空的，等我自己写
- 卡在哪：先从 Element 开始，测试 [2] 要先变绿
- 下周：实现 Element + Card + DataLoader

