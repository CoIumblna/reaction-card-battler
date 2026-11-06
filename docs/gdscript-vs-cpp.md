# GDScript ↔ C++ 对照表（给会 C++ 的人）

> 用途：你 C++ 已经很熟，学 GDScript 不该从"变量是什么"学起，只该补**差异点**。
> 本文件按"语法 → 容器 → 常用算法 → 对象模型 → 坑"排列。
> 事实依据：Godot 4.7 官方文档 + 本项目代码。

---

## 0. 为什么它这么像 Python（但不是 Python）

| 像 Python 的地方 | 原因 |
|---|---|
| 用缩进划分代码块，没有 `{}` | 减少样板代码，游戏开发要快速迭代 |
| `func` / `if` / `for` / `in` 关键字 | Python 风味 |
| 列表 `[]`、字典 `{}` 字面量 | 同上 |
| `"%s" % a` 字符串格式化 | 直接借的 Python 语法 |
| `for x in array` 迭代 | 同上 |
| `True/False` 大小写？**不是** | GDScript 是 `true/false`（小写），这点像 C++ |
| `None`？**不是** | GDScript 是 `null` |

**但它不是 Python**：

| 维度 | Python | GDScript |
|---|---|---|
| 执行方式 | 解释器逐行 | **编译成字节码**，再跑在 Godot VM 上 |
| 类型 | 完全动态 | **可选静态类型**（`var x: int`、`-> int`），能提前报错 |
| 类模型 | 多继承、MRO | 单继承 + 内部类，类可注册全局名（`class_name`） |
| 与引擎关系 | 无 | 深度绑定：节点生命周期、信号、场景树、编辑器 |
| 性能 | 慢 | 比 Python 快，但仍远慢于 C++（关键路径用 GDExtension） |

一句话：**Python 的皮 + C#/Java 的类模型 + 引擎的回调机制。**

---

## 1. 基础语法对照

| C++ | GDScript |
|---|---|
| `int x = 3;` | `var x: int = 3` 或 `var x := 3`（`:=` 自动推断） |
| `const int N = 3;` | `const N := 3`（编译期常量，类级用 `const`） |
| `auto x = foo();` | `var x := foo()` |
| `void f(int a) {}` | `func f(a: int) -> void:` |
| `int f(int a) { return a; }` | `func f(a: int) -> int:` + `return a` |
| `f();` | `f()` —— **函数调用不写分号** |
| `if (x > 0) {...}` | `if x > 0:` + 缩进 |
| `else if` | `elif` |
| `for (int i=0;i<n;i++)` | `for i in range(n):` |
| `for (auto& x : v)` | `for x in v:` |
| `while (c) {}` | `while c:` |
| `break; continue;` | `break` / `continue` |
| `return;` | `return`（void 函数可省略） |
| `switch(x){case 1:...}` | `match x:` + `1:` + `_:`（默认） |
| `// 注释` `/* */` | `# 注释`（没有块注释，用多个 `#`） |
| `true/false` | `true/false`（相同） |
| `nullptr` | `null` |

> 注意：**行尾不加分号**，加了会报错（分号在 GDScript 里是语句分隔符，可写但强烈不建议）。

## 2. 类型

| C++ | GDScript |
|---|---|
| `int` `float` `bool` `char` | `int` `float` `bool`（**没有 char**，字符就是长度 1 的 String） |
| `std::string` | `String` |
| `double` | `float`（Godot 里 float 就是 64 位双精度） |
| `unsigned` | 没有无符号；用 `int` + 自己约束 |
| `size_t` | `int` |
| `void*` | 没有泛指针；用 `Variant` / `Object` |
| `std::optional<T>` | `null` + 类型检查 |
| `std::variant` | `Variant`（引擎内建，任何值都能装） |
| 类型转换 `(int)x` / `static_cast` | `int(x)` / `float(x)` / `str(x)` |
| `sizeof(T)` | 没有对应的（引擎式开发不关心） |
| `typedef` / `using` | 无（直接写类型） |

**类型转换是重点**：GDScript 里 `"3" + 1` 会报错，必须 `int("3") + 1`。JSON 读出来的数字是 `float`，所以本项目里到处是 `int(...)`、`float(...)`、`str(...)`。

## 3. 容器

| C++ | GDScript | 说明 |
|---|---|---|
| `std::vector<T>` | `Array` / `Array[T]` | 动态数组，**引用语义** |
| `std::array<T,N>` | 无固定长度数组，也用 `Array` | |
| `std::map<K,V>` | `Dictionary` / `Dictionary[K,V]` | 哈希表（**无序**） |
| `std::unordered_set<T>` | `Dictionary` 的键当集合用 | 没有 Set 类型 |
| `std::pair` | `Array` / `Dictionary` | 没有专用类型 |
| `std::queue/deque` | `Array` 的 `pop_front()` | 性能一般，够用 |
| `std::stack` | `Array` 的 `pop_back()` | |
| `std::priority_queue` | 自己实现（`Array` + `sort`） | M2 的 AI 可能用到 |

### 常用操作对照

| 想做的事 | C++ | GDScript |
|---|---|---|
| 追加 | `v.push_back(x)` | `a.append(x)` |
| 尾部删除 | `v.pop_back()` | `a.pop_back()` |
| 头部删除 | `v.erase(v.begin())` | `a.pop_front()` |
| 长度 | `v.size()` | `a.size()` |
| 判空 | `v.empty()` | `a.is_empty()` |
| 清空 | `v.clear()` | `a.clear()` |
| 按下标取 | `v[i]` | `a[i]`（越界会**报错**，不是 UB） |
| 查找值 | `std::find` | `a.has(x)` / `a.find(x)` 返回下标或 -1 |
| 删除某值 | `v.erase(std::remove(...))` | `a.erase(x)`（删第一个） |
| 排序 | `std::sort(v.begin(), v.end())` | `a.sort()` |
| 自定义排序 | `std::sort(..., cmp)` | `a.sort_custom(func(x, y): return x < y)` |
| 反转 | `std::reverse` | `a.reverse()` |
| 拷贝 | `auto b = v;` | `var b := a.duplicate()`（**必须显式**） |
| 拼接数组 | 循环 insert | `a.append_array(b)` |

### 字典操作

| 想做的事 | GDScript |
|---|---|
| 声明 | `var d := {"fire": "火"}` |
| 取值（键不存在→报错） | `d["fire"]` |
| 安全取值 | `d.get("fire", "无")` ← **推荐** |
| 判断键 | `d.has("fire")` |
| 写入/修改 | `d["ice"] = "冰"` |
| 删除 | `d.erase("ice")` |
| 大小 | `d.size()` |
| 所有键 | `d.keys()`（返回 Array，可 `.sort()`） |
| 所有值 | `d.values()` |
| 遍历 | `for k in d:` |

> **和 C++ 最大的区别**：`d["不存在"]` 会**运行时崩溃**，C++ 的 `map::operator[]` 会插入默认值。所以项目里一律用 `.get(键, 默认值)`。

## 4. 常用算法 / 数学

| C++ | GDScript |
|---|---|
| `std::max(a,b)` | `max(a,b)`（返回 Variant）或 `maxi/maxf`（带类型） |
| `std::min(a,b)` | `min/mini/minf` |
| `std::abs(x)` | `abs(x)` / `absi` / `absf` |
| `std::floor/ceil/round` | `floor/ceil/round`（返回 float） |
| `std::pow/sqrt` | `pow/sqrt` |
| `std::clamp` | `clamp(v, lo, hi)` |
| 取整（截断） | `int(x)` |
| 四舍五入到 int | `int(round(x))` |
| 向下取整到 int | `int(floor(x))` ← **本项目伤害用这个** |
| 随机整数 | `randi_range(a, b)` / `RandomNumberGenerator` |
| `std::swap(a,b)` | `var t := a; a = b; b = t`（没有 swap） |
| 数组求和 | 循环 |
| 数组最大值 | `a.max()`（Array 有内建方法） |

## 5. 字符串

| C++ | GDScript |
|---|---|
| `std::to_string(x)` | `str(x)` |
| `std::stoi(s)` | `int(s)` |
| `s.size()` | `s.length()` |
| `s.substr(i, n)` | `s.substr(i, n)`（同名） |
| `s.find(t)` | `s.find(t)`（返回 -1 表示没找到） |
| `s.replace` | `s.replace(old, new)` |
| `s + t` | `s + t`（同名） |
| `std::string::npos` | `-1` |
| `printf("%d %s", a, b)` | `print(a, " ", b)` 或 `"%d %s" % [a, b]` |
| `sprintf` | `"%d" % x` / `"%s+%s" % [a, b]` |
| 字符串拼接 | 同上，或 `str1 + str2` |

> `%` 在 GDScript 里：**对 String 是格式化，对 int 是取模**。和 Python 一致。

**常用格式符**：`%d` 整数、`%f` 浮点、`%s` 字符串、`%.2f` 两位小数、`%x` 十六进制、`%%` 百分号本身。

## 6. 类与对象（差异最大的一块）

| C++ | GDScript |
|---|---|
| `class Foo { ... };` | `class_name Foo` + `extends RefCounted`（或 Node） |
| 头文件 + 源文件 | **只有一个 `.gd` 文件**，没有声明/实现分离 |
| `#include` | 不需要（`class_name` 全局可见，或 `preload("res://...")`） |
| 构造函数 `Foo()` | `func _init():` |
| 析构函数 `~Foo()` | `func _notification(what)`（很少用） |
| `virtual void f()` | 直接写同名函数即可重写（`func f():`），没有 virtual 关键字 |
| 纯虚函数 / 接口 | 没有接口；用"约定"或基类 + `push_error` |
| 多重继承 | **不支持**（单继承） |
| 模板 `template<T>` | **不支持**；用 `Variant` / 类型化数组 |
| 命名空间 `namespace` | 没有；靠 `class_name` 唯一名 |
| `static` 成员函数 | `static func`（**不能访问实例成员**） |
| `static` 成员变量 | `static var`（Godot 4.1+） |
| `const` 成员 | `const`（类级常量） |
| `public/protected/private` | 没有访问控制（约定 `_` 前缀表示"内部"） |
| 运算符重载 | **不支持** |
| 枚举 `enum class` | `enum { A, B }`（值是 int） |
| 函数重载 | **不支持**（同名函数只能有一个，参数个数用默认值模拟） |
| 默认参数 | 支持：`func f(a, b := 3):` |
| 可变参数 | 不支持，用 `Array` |
| 引用 `T&` | 没有；对象天然是引用，基础类型是值 |
| 指针 `T*` | 没有；用 `null` 表示"没有对象" |

### 内存模型（C++ 人必须搞清楚）

| C++ | GDScript |
|---|---|
| 栈上对象 | 所有变量都在堆上（由引擎管理） |
| `new/delete` | **不需要手动释放** |
| `std::shared_ptr` | `RefCounted` 子类：引用计数自动回收（**本项目的 Unit/Card/Battle 都是**） |
| `std::unique_ptr` | 无对应 |
| 裸指针 + 手动 delete | `Node` 用 `queue_free()` 手动释放（场景树管理） |
| 值拷贝 | `int/float/bool/String` 是值；`Array/Dictionary/对象` 是**引用**（`=` 不拷贝，要 `duplicate()`） |
| 悬垂指针 | `is_instance_valid(obj)` 检查对象是否已释放 |

**关键**：本项目里 `Card`、`Unit`、`Battle`、`Buff` 都继承 `RefCounted`，你 new 出来不用 delete。

## 7. 错误处理与断言

| C++ | GDScript |
|---|---|
| `throw` / `try` / `catch` | **没有异常** |
| 错误码返回 | 返回 `null` / `{}` / `false` + 日志 |
| 日志输出 | `print()` / `print_rich()` |
| 错误日志 | `push_error("...")`（编辑器里标红，不影响继续运行） |
| 警告日志 | `push_warning("...")` |
| 断言 | `assert(cond, "消息")`（仅 debug 构建生效） |
| `exit(1)` | `quit(1)`（`SceneTree` 脚本里） |

> 所以本项目的 `DataLoader.load_json()` 是"出错 → `push_error` + 返回 `{}`"，而不是抛异常。**这也是为什么测试要检查"空表不崩"**。

## 8. 引擎特有的东西（C++ 没有的）

| 概念 | 说明 | C++ 里类比 |
|---|---|---|
| `_ready()` | 节点进入场景树时调用一次 | 构造 + 初始化 |
| `_process(delta)` | 每帧调用 | 游戏主循环回调 |
| `_physics_process(delta)` | 固定步长每帧 | 物理循环 |
| `signal` + `emit_signal` | 观察者模式，解耦 | `std::function` 回调列表 |
| `@export` | 把变量暴露到编辑器面板 | 无 |
| `@onready` | 节点就绪后再赋值 | 延迟初始化 |
| `await` | 协程等待（B 站：`await get_tree().create_timer(1).timeout`） | `std::future` / 回调 |
| `class_name` | 注册全局类名 | 全局命名空间里的类 |
| `preload("res://...")` | 编译期加载资源 | `#include` + 实例 |
| `res://` / `user://` | 项目内 / 用户数据目录 | 相对路径 / `$HOME` |
| 场景 `.tscn` | 可复用的节点组合 | 预制体/组合模式 |

## 9. 本项目里实际用到的写法（对照看）

| 本项目代码 | C++ 等价 |
|---|---|
| `const ELEMENT_NAMES := {...}` | `const std::unordered_map<std::string,std::string>` |
| `ELEMENT_NAMES.get(element, "无")` | `m.count(k) ? m.at(k) : "无"` |
| `var out: Array[String] = []` | `std::vector<std::string> out;` |
| `if a == Element.NONE:` | `if (a == Element::NONE)` |
| `return "%s+%s" % [a, b]` | `return a + "+" + b` |
| `table.get_reaction(a, b)` | `table.getReaction(a, b)` |
| `int(floor(base * mult))` | `(int)std::floor(base * mult)` |
| `for e in enemies:` | `for (auto& e : enemies)` |
| `hand.erase(card)` | `hand.erase(std::find(...))` |
| `unit.take_damage(d)` | `unit.takeDamage(d)`（对象是引用，修改有效） |

## 10. C++ 程序员最容易踩的 8 个坑

1. **不要加分号**，不要写 `{}` 代码块 —— 用缩进（Tab）
2. **`/` 对两个 int 是整数除法**：`5 / 2 == 2`；要小数写 `5.0 / 2`
3. **数组/字典赋值是引用**：`var b := a` 后改 `b` 会改 `a`，要 `a.duplicate()`
4. **`d[k]` 键不存在会崩**，用 `d.get(k, 默认值)`
5. **没有异常**，错误靠返回值 + `push_error`
6. **没有模板/重载/运算符重载**，别按 C++ 的架构习惯设计
7. **`int()` 是截断**，向下取整用 `int(floor(x))`（正数两者相同，本项目伤害用 floor 更明确）
8. **`Array[Buff].filter()` 会类型不匹配**（filter 返回无类型 Array），要手写循环

---

## 附：如果你想深挖

- 官方文档：Godot 4 → Scripting → GDScript（有 "GDScript reference" 和 "GDScript style guide"）
- 性能：GDScript 比 C++ 慢 10–100 倍，**别在每帧循环里做字符串拼接**；真需要性能时用 GDExtension 写 C++
- 你的项目：M2 的棋盘每回合要遍历单位，注意别在循环里 `duplicate()` 数组
