# Dart 内容扩容研究：+180 组离线可执行教程/示例（目标 300 组）

状态：研究完成，**未写任何产品代码**。本文件是唯一交付物。
作者：Dart 新内容负责人。日期：2026-10-22。
前置事实：主协调者已实跑 240 单元（120 课 + 120 例），结果在
`research/portable-baseline.json`：**86 pass / 154 fail**，其中 43 个 id 双单元通过。
本报告不重复那次全量跑，只补齐"旧内容之外还能安全写什么"的证据。

> 明确排期约束（用户指示）：**先修完旧 120 组基线，再开始这 180 组作者工作**。
> 本报告只做可行性证明、语法白名单、章节/字段设计、文件边界与主题清单。

---

## 0. 结论摘要

1. dart_eval 0.8.5 的实际可用子集**远窄于**"Dart 语言基础"，且失败模式有三类：
   编译期不支持（好）、运行期异常（好）、**静默输出错误（危险）**。
2. 按真实探针（本轮 278 个独立程序，179 pass / 99 fail）归纳出一份
   **可写白名单 + 三类禁区**（§2）。180 个主题（§5）**全部只使用白名单构造**。
3. 有 5 个旧章节的知识点在新引擎上**根本无法表达**：`streams`（8）、`isolates`（6）、
   大部分 `generics`（8）、`dart3`（12）的 record/pattern、`async` 的并发类。
   因此 180 组新内容**不新增这些主题**，改由 16 个新章节承担（§4）。
4. 新增内容一律 `dart-lesson-121..300`，独立章节文件 + 独立"便携已验证集合"，
   与旧内容修复的改动面**零重叠**（§6 给出精确边界）。

---

## 1. 探针方法与可复现证据

### 1.1 方法

- 探针脚本置于系统临时目录（`%TEMP%\qfli_probe`），**不进仓库**。
- 执行器 `probe.dart` 逐字复刻产品路径：`Compiler()..entrypoints.add('package:demo/main.dart')`
  → `compiler.compile({'demo': {'main.dart': src}})` → `Runtime.ofProgram` →
  `runZoned(print 捕获)`；每个程序独立 isolate + 8s 超时（同步死循环也能中断）。
  与 `tool/portable_content_runner.dart` 完全同构，因此结论可直接迁移。
- 用 `dart --packages=<repo>/.dart_tool/package_config.json` 复用仓库锁定的
  `dart_eval 0.8.5`，不引入新依赖。
- 每个 case = 一个完整 `main()` 程序 + 期望 stdout；`ok` 判定 =
  `error == null && 归一化后 stdout 完全相等`。

### 1.2 规模

| 轮次 | 文件 | 程序数 | pass | fail |
| --- | --- | ---: | ---: | ---: |
| 1 | `results.json` | 84 | 45 | 39 |
| 2 | `results2.json` | 69 | 49 | 20 |
| 3 | `results3.json` | 57 | 29 | 28 |
| 4 | `results4.json` | 37 | 27 | 10 |
| 5 | `results5.json` | 31 | 29 | 2 |
| 合计 | — | **278** | **179** | **99** |

第 4、5 轮已包含 39 个**真实候选课程程序**（冒泡/选择排序、二分查找、回文、
词频、RLE、罗马数字、GCD/LCM、素数筛、杨辉三角、矩阵转置、栈、凯撒密码、
JSON 配置、零钱 DP、BFS、年龄计算、Luhn 校验、CSV 解析、Top-N、分块等），
**全部 pass**（除研究自身算错期望值的 1 例）。这是"180 条能真跑"的核心证据。

---

## 2. 便携引擎能力矩阵（全部来自真实探针）

### 2.1 白名单 — 可以放心写（已实测 pass）

| 域 | 可用 |
| --- | --- |
| 输出 | `print`；`print` 会按 Dart 语义格式化 `int/double/bool/null/String`、`List`、`Map`、`Set`、嵌套 `List`；对象默认 `toString` 可自定义 |
| 数值 | `+ - * / ~/ %`、`abs`、`round/floor/ceil/truncate/toInt/toDouble`、`toStringAsFixed`、`toStringAsPrecision`、`clamp`、`remainder`、`toRadixString`、`int.parse/tryParse`（含 `radix:`）、`double.parse/tryParse`、`num.parse`、`isEven/isOdd/isNegative`、数值比较 |
| `dart:math` | `sqrt`、`pow`、`pi`、`cos`、`sin`、`tan`、`exp`、`log`、`Random(seed)`（种子固定即可复现） |
| 字符串（变量接收） | `length`、`isEmpty`、`toUpperCase/toLowerCase`、`trim/trimLeft/trimRight`、`padLeft/padRight`、`substring`、`indexOf/lastIndexOf`、`contains`、`startsWith/endsWith`、`replaceAll/replaceFirst`、`split`（含 `split('')`）、`join`、`compareTo`、`codeUnitAt`、`String.fromCharCode(s)`、`[i]` 下标、插值 `$x` / `${expr}`、多行 `"""`、raw `r''`、相邻字面量拼接 |
| 控制流 | `if / else if / else`、三元、`for(;;)`、`for-in`、`while`、`do-while`、经典 `switch`（`case`+`break`+`default`、字符串/int/枚举 case、case 分组穿透）、**单层** `break`、`assert`（仅在 assert 通过时；失败会真抛 `AssertionError`） |
| 函数 | 必选位置参数、可选位置 `[]`、命名可选（含默认值）、箭头函数、局部函数、递归、顶层函数 tear-off、**赋值给变量的闭包**、高阶函数接收/返回**赋值过的**函数 |
| 集合 List | 字面量、`add/addAll/insert/insertAll/remove/removeAt/removeLast/removeWhere/clear`、`sort()`、`sort(表达式体比较器)`（**仅基础类型**）、`sublist`、`reversed`、`join`、`contains`、`indexOf/lastIndexOf`、`asMap`、`List.generate`、`List.filled`、`List.from`、`List.of`、展开 `...`、collection-`if`/collection-`for`（**仅 List 字面量内**）、`where/map/any/every/firstWhere(orElse)/take/skip/takeWhile/skipWhile/toSet`、`fold<T>`（**显式类型实参 + 显式参数类型**）、`first/last/length/isEmpty/isNotEmpty/[]` 写入 |
| 集合 Map | 字面量（含嵌套、`const` 局部）、`[]`/`[]=`、`containsKey`、`keys/values/entries`（可 `for-in`）、`remove`、`length`、`Map.from`、`Map<K,V>` 作字段 |
| 集合 Set | 字面量（字符串/int/枚举）、`add`、`contains`、`union/intersection/difference`、`toList`、`length` |
| 类 | 字段、构造、命名构造、`factory`、`getter/setter`（**double 运算要对齐 double 字面量**）、`static const` 标量 + `static` 方法、`toString`、`==`/`hashCode`、`implements` 接口（含多接口）、cascade `..`（**只对自己的方法链**）、`const` 构造 + `const` 实例、自定义可变字段 + 方法内自增 |
| 枚举 | 声明、`switch` 分派、`.index`、作为 Map key |
| 异常 | `throw`、`try/catch`、`on 类型`、`finally`（不 return）、自定义 `implements Exception` 且带字段与 `toString`、嵌套 try、循环内 try、`StateError/ArgumentError/FormatException` 捕获 |
| 空安全 | `T?`、`?.`、`!`、`??`、`??=`、可空形参、`required`/默认值组合 |
| 异步（有限） | `async` 函数返回 `Future<T>`、`await`、`Future<void>.delayed`、多个 await 串行、`.then`（在 `Future.delayed` 上）、`main` 为 `Future<void> main() async` |
| `dart:convert` | `jsonEncode`、`jsonDecode`、嵌套对象/数组、`as Map<String, dynamic>`、`.cast<String>()`、转义 |
| `DateTime` | `DateTime(y,m,d,h,min)` 固定构造、`year/month/day/hour/minute/weekday`、`difference().inDays`、`add(Duration)`、`isBefore`、`Duration.inSeconds/inMinutes/inMilliseconds` |
| 顶层 | 顶层 `var/final/const`、顶层函数、顶层可变状态 |

### 2.2 硬禁区 — 编译期不支持（写了一定失败）

| 特性 | 真实报错 |
| --- | --- |
| `continue` | `Unknown statement type ContinueStatementImpl` |
| 标签语句 / 带标签 break | `Unknown statement type LabeledStatementImpl` |
| 泛型类 `class S<T>`、泛型函数 `<T>` | `Unknown type T at "<T>"` / `at "T v"` |
| 泛型 typedef | `No support for GenericTypeAliasImpl`（**任何 typedef 别名都挂**） |
| `mixin` | `No support for MixinDeclarationImpl` |
| `extension` | `type 'ExtensionDeclarationImpl' is not a subtype of 'NamedCompilationUnitMember'` |
| 记录 `(1,'a')` / `.$1` | `Cannot box @record<int,int>` |
| 模式 `switch (v) { 1 => ... }`、`if (x case ...)` | `Unknown expression type SwitchExpressionImpl` / `Conditions must have a static type of 'bool'` |
| `super.method()` / `super.getter` | `Null check operator used on a null value` |
| `abstract class` + `extends`（含抽象方法/抽象 getter） | `Null check operator used on a null value` |
| `late var` / `late final` | `Null check operator used on a null value` |
| `import 'dart:isolate'` | `Cannot find import` |
| `Map.forEach` / `Map.containsValue` / `Map.update` / `Map.putIfAbsent` / `Map.fromEntries` | `Unknown method ...` |
| `Iterable.indexWhere/lastIndexWhere` | `Cannot assign argument of type Function to parameter of type bool` |
| `Iterable.reduce` | 运行期 `type '(dynamic,dynamic)=>$Value?' is not a subtype of '($Value,$Value)=>$Value' of 'combine'` |
| `List.expand` | `Cannot assign argument of type Function to parameter of type Iterable` |
| `Future.value` / `Future.wait` / `Future.timeout` / `.catchError` | `Cannot find static method Future.value` 等 |
| `Stream` 全族（`StreamController`、`Stream.fromIterable`、`Stream.value`、`Stream.fromFuture`、`.toStream()`、`await for` over Stream） | `UnimplementedError: 缺少 registerBridgeFunc` / 隔离崩 |
| `unawaited`、`sub.cancel()` | `Could not find declaration "unawaited"` |
| `StringBuffer` | `Class 'List<$Value>' has no instance getter '$reified'`（且 `List.addAll` 在此路径连带失效） |
| `base64Encode` / `utf8.decode` / `base64Decode` | `Could not find declaration "base64Encode"` |
| `JsonEncoder.withIndent` | `Cannot find static method JsonEncoder.withIndent` |
| `Map` 推导式 `{for (...) k: v}` | `Unknown set or map collection element ForElementImpl`（**List 推导式可以**） |
| `static int` 可变静态字段 / `static const List|Map` | `Could not find declaration "count"` / `type 'List<dynamic>' is not a subtype of type '$Instance'` |
| `dart:io`（`File`/`Directory`/`Platform`/`stdout`） | `Cannot find external getter or field: systemTemp` 等 |

### 2.3 静默错误区 — **编译通过但输出错**（最危险，必须禁止）

| 写法 | 实际行为 |
| --- | --- |
| `print(x.runtimeType)` | 打印 `Instance of 'Type'` 而非 `int` |
| `print(FormatException('x').message)` | `UnimplementedError: $Object.message`；`.x` 等自定义 getter 同理 |
| `'abc'.length` / `''.isEmpty`（**字面量直接取 getter**） | `type 'String' is not a subtype of type '$Instance'`；更糟：`'x'.trim().isEmpty` **返回 false（错值）** |
| `List<String>.of(words).sort((a,b)=>a.length.compareTo(b.length))` 与 `final ws=<String>[...]; ws.sort(...)` | **行为不一致**：同一代码一处生效一处静默不排序 |
| 对**自定义对象**列表 `sort(比较器)` | 静默不排序（结果保持原序），或 `UnimplementedError` |
| 比较器里捕获 `Map`（`scores[y]!.compareTo(...)`） | `type 'int' is not a subtype of type 'Map<dynamic,dynamic>'` |
| `print(<Custom>[a,b])` | `UnimplementedError`（List\<对象\> 的 toString 未实现） |
| `Set<Custom>` / `{a, P(1)}` | `type '_Set<Object?>' is not a subtype of type '$Instance'` |
| 枚举 `print(Color.red)` / `Color.red.name` / `Color.values` | 打印 `object Object`、`EvalUnknownPropertyException (name)`、`Cannot resolve type of "Level.values"` |
| 从函数**返回**闭包再调用 | `Cannot call c1 as it is not a valid method` |
| 基类类型变量持有子类 + 虚方法派发 `final Base b = Child(); b.hi()` | `Null check operator used on a null value` |
| 子类访问**继承来的字段**（`x` 在父类声明） | `type '$int' is not a subtype of type 'int'` |
| 嵌套 `for` 内 `break` | 只跑一次后 `type 'Null' is not a subtype of type 'num'` |
| `finally` 里 `return` | `type 'Null' is not a subtype of type 'int'` |
| `on RangeError` 捕获 | `type 'RangeError' is not a subtype of type '$Value'` |
| async 函数内 `throw` + 外部 `await` 捕获 | 未捕获穿出：`Instance of '$StateError'` |
| `final mx = xs.first;`（把 `.first` 赋给变量） | `type 'int' is not a subtype of type '$Value'` |
| `lines.first.split(',')`（`.first` 直接接方法） | 得到 `[, ]`（空串数组，静默错值） |
| 整数盒化重赋值 `final t = y; y = x % y; x = t;` | `type '$int' is not a subtype of type 'int'`（改成先算 `final int r = x % y; x = y; y = r;` 即 pass） |
| `List<int>.filled(3,0)` 后 `a[1]=5` | `RangeError ... Valid value range is empty: 0`（**先 `add` 成长/或用字面量**） |
| `..items.addAll(...)`（cascade 接 addAll） | `Unknown method Bag.addAll` |
| `parent: 子类()` 里 `super.x` | `type '$int' is not a subtype of type 'int'` |

### 2.4 作者铁律（180 组必须逐条遵守）

R1 一切字符串/数值先落到**有类型的变量**，再取 getter（禁止 `'abc'.length`）。
R2 禁止 `continue`、标签、`expand`、`reduce`、`indexWhere`、`Map.forEach/containsValue/update/putIfAbsent/fromEntries`。
R3 求和聚合统一 `fold<T>(init, (T a, T b) => ...)`，或显式 for 循环累加。
R4 禁止泛型声明、mixin、extension、typedef、记录、模式匹配、`late`。
R5 OOP 只用：单类 / `implements` 接口 / `const` 构造 / `factory` / `static const` 标量。
   **禁止** `super.*`、抽象类 `extends`、基类类型变量虚派发、子类读父类字段。
   （继承可用时仅限"子类只覆盖方法、不碰父类字段、不 super、不通过父类型变量调用"）
R6 排序：只对 `int/double/String` 列表排序，比较器用**表达式体**；禁止对自定义对象排序、禁止比较器捕获 Map。
   `List.of/List.of(literal)` 拷贝后再 sort 更稳。
R7 禁止在输出里出现 `runtimeType`、枚举 `toString/name`、异常 `message`、`List<自定义类>` 的 `toString`。
   枚举只用 `switch` 与 `.index`，输出用自己写的 `label()`。
R8 数组初始化统一用**字面量或 `add` 增长**，禁止 `List.filled` 后下标赋值。
R9 `.first/.last` 只允许出现在插值或算术表达式里，禁止赋给变量、禁止直接接方法。
R10 数值交换/辗转相除等"变量互相赋值"要**先算中间量到新 `int`**，不要写 `t=y; y=x%y; x=t`。
R11 异常：只捕获 `StateError/ArgumentError/FormatException/自定义 Exception/on Object`；禁止 `on RangeError`、禁止 `finally{return}`。
R12 异步：只 `await` 正常返回的 `Future`；禁止 async 内 throw、禁止 Future.value/wait/timeout/catchError、禁止 Stream 与 Isolate。
R13 每个程序**禁止 stdin / 网络 / dart:io**；时间用固定 `DateTime(...)`，随机用固定 `Random(seed)`。
R14 每个程序必须**实测**：`dart run tool/verify_portable_content.dart --chapter <key>` 与
    `dart run tool/verify_dart_content.dart --chapter <key>` 双绿，期望输出**从真实运行结果抄**，不手算。

---

## 3. 与旧内容的关系（避免"凑数"与重复）

### 3.1 不新增的主题（引擎不支持，写出来就是凑数/假课）

`Streams` 全章知识、`Isolate` 全章知识、`Future.wait`/`timeout`/`catchError`/`unawaited` 并发类、
泛型类/泛型函数/泛型 typedef、`mixin`、`extension`、record、pattern/`switch` 表达式、
`dart:io`（文件/进程/标准输入）、文件系统相关一切、`base64`/UTF-8 编解码、
`JsonEncoder.withIndent` 美观输出、`late`、抽象类继承体系、`super` 调用。

> 这 5 类正是旧 154 个 fail 单元的主体（见 `portable-baseline.json` 的错误分布：
> `SwitchExpressionImpl` 14、`dart:isolate` 12、`Directory.systemTemp` 16、
> 泛型 `Unknown type T` 10、`registerBridgeFunc` 10、`Null check` 6 …）。
> 旧内容要靠 **runtime 桥接增强** 才能真正变绿；新内容不能靠同一条路"过"。

### 3.2 与旧 120 的不重复策略

- 旧 120 是"语言特性导向"（变量、集合 API、类、异步…）。新 180 改为
  **"任务/算法/工程模式导向"**，且每个主题的**代码骨架与数据域**都与旧课不同。
- 生成器的唯一性门槛已存在且必须继续成立：`explain` 唯一、lesson code 归一化唯一、
  example code 归一化唯一（`_checkCurriculum`）。新 180 必须全部首跑通过，不得靠改文案绕过。
- 新章节**不宣布旧章节已覆盖的知识**（例如不再写 "List.map 是什么"），
  而是写 "用 map 做一次字段投影并解释为什么这里不能 reduce"。

---

## 4. 章节规划（16 新章 × 11～12 = 180）

`dart-lesson-121 .. 300`，`dart-example-121 .. 300`（1:1 配对，沿用现有模型）。
level 分布：beginner 17 / intermediate 102 / advanced 61（逐条已在 §5 表中标注，合计 180）。

| # | key | 章节标题 | 课数 | id 区间 | 主题定位 |
| --- | --- | --- | ---: | --- | --- |
| 15 | `numbers-strings` | 第十五章 数值与字符串实战 | 12 | 121–132 | 格式化、解析、编码、文本清洗（全部在变量上操作） |
| 16 | `text-processing` | 第十六章 文本处理与校验 | 12 | 133–144 | 回文/变位词/RLE/凯撒/Luhn/ISBN/大小写规范 |
| 17 | `algorithms-basic` | 第十七章 基础算法与排序 | 12 | 145–156 | 冒泡/选择/插入/二分/线性/计数排序、去重、合并 |
| 18 | `algorithms-advanced` | 第十八章 递推与动态规划 | 12 | 157–168 | 斐波那契族、爬楼梯、零钱、LCS、LIS、背包、走格 |
| 19 | `data-structures` | 第十九章 手写数据结构 | 12 | 169–180 | 栈/队列/环形缓冲/链表/二叉树遍历/优先队列(数组)/并查集 |
| 20 | `math-stats` | 第二十章 数学与统计 | 12 | 181–192 | GCD/LCM/质数/杨辉/矩阵/均值中位数众数/方差/移动平均 |
| 21 | `oop-modeling` | 第二十一章 面向对象建模实战 | 12 | 193–204 | 值对象、不可变类、`==`/`hashCode`、接口实现、`factory` 校验、DTO |
| 22 | `enum-states` | 第二十二章 枚举与状态机 | 11 | 205–215 | 枚举分派、状态迁移表、计分/关卡、订单状态、权限矩阵 |
| 23 | `errors-resilience` | 第二十三章 错误处理与容错 | 11 | 216–226 | 结果对象、失败重试（同步）、降级、批量容错、错误聚合、断言 |
| 24 | `json-modeling` | 第二十四章 JSON 与数据映射 | 12 | 227–238 | 解析→模型、默认值、数组聚合、嵌套拍平、编码复现 |
| 25 | `dates-money` | 第二十五章 日期与金额计算 | 11 | 239–249 | 年龄/账期/工作日、分期、复利、税费、四舍五入与分单位 |
| 26 | `collection-reporting` | 第二十六章 集合统计与报表 | 12 | 250–261 | 分组计数、Top-N、直方图、透视、分页、去重合并、diff |
| 27 | `formatting-output` | 第二十七章 文本排版与表格输出 | 11 | 262–272 | 对齐/表格/进度条/树形缩进/折行/编号列表/ASCII 图 |
| 28 | `async-patterns` | 第二十八章 可移植异步模式 | 11 | 273–283 | 串行 await、流水线、分批处理、重试循环、超时模拟（计步） |
| 29 | `apis-contracts` | 第二十九章 接口契约与校验 | 11 | 284–294 | 校验规则链、契约测试式断言、版本比较、配置合并、限流计数 |
| 30 | `mini-apps` | 第三十章 综合小项目 | 6 | 295–300 | 记账本/库存/成绩单/词频报告/迷宫寻路/简易解释器 |

总计 **12+12+12+12+12+12+12+11+11+12+11+12+11+11+11+6 = 180**。

> 章节数与每章课数都写进 `DartCurriculum.chapters` / `DartCurriculum.counts`，
> 使 `counts` 总和 = 300，并让现有 `_checkCurriculum` 的"按章校验"自动生效。

---

## 5. 180 个具体主题清单（每个都是独立知识点 + 独立程序）

标注：`B/I/A` = beginner / intermediate / advanced。所有程序只用 §2.1 白名单。

### 15 数值与字符串实战（121–132）

| id | Lv | 主题 | 程序要点（已探针验证的构造） |
| --- | --- | --- | --- |
| 121 | B | 数字格式化输出 | `toStringAsFixed(2)`、`padLeft`、金额两位对齐 |
| 122 | B | 安全的数字解析 | `int.tryParse`/`double.tryParse` + 失败分支，绝不抛 |
| 123 | I | 进制转换工具 | `toRadixString` / `parse(radix:)`，二/八/十六互转 |
| 124 | I | 百分比与比率 | `~/`、`%`、`/` 三者区别的实战输出 |
| 125 | I | 字符串清洗管线 | `trim` → `replaceAll` → `split` → `join` 多步 |
| 126 | I | 大小写规范（标题化） | 逐词 `toUpperCase`+`substring` 拼接 |
| 127 | I | 定长对齐填充 | `padLeft/padRight` 做等宽列 |
| 128 | I | 截断与省略号 | `substring` + `length` 守卫（变量形式） |
| 129 | A | 字符码与字符构造 | `codeUnitAt` + `String.fromCharCode` |
| 130 | I | 数值区间映射 | `clamp` + 线性映射（0..100 → 0..5 星） |
| 131 | I | 四舍五入策略对比 | `round/floor/ceil/truncate` 在负数上的差异 |
| 132 | A | 浮点误差与两位小数账本 | `toStringAsFixed` 收敛，解释 `0.1+0.2` |

### 16 文本处理与校验（133–144）

| id | Lv | 主题 | 要点 |
| --- | --- | --- | --- |
| 133 | B | 回文判定（双指针） | `[i]` + `length`（变量接收） |
| 134 | I | 变位词判定 | 双 `split('')`+`sort`+`join` 比较（String 列表可比） |
| 135 | I | 词频统计 | `Map` 计数 `(m[k] ?? 0) + 1` |
| 136 | I | 字符频率 + 排序输出 | `keys.toList()..sort()` |
| 137 | I | 行程长度编码 RLE | while 双指针压缩（探针 pass） |
| 138 | I | RLE 解码 | 数字/字符交替解析 |
| 139 | I | 凯撒密码 | `codeUnitAt` 取模移位的经典实现 |
| 140 | A | 简单替换密码表 | `Map<String,String>` 查表 + 未命中按原样 |
| 141 | A | Luhn 银行卡校验 | 逆序 + 双倍 -9（探针 pass） |
| 142 | A | 括号/引号配对校验 | 用 `List<String>` 当栈，非法输入报错 |
| 143 | I | 首字母缩写与驼峰拆分 | 逐字符大小写判定 |
| 144 | A | 简易模板占位符替换 | `{name}` 占位 + Map 替换，缺失保底 `-` |

### 17 基础算法与排序（145–156）

| id | Lv | 主题 |
| --- | --- | --- |
| 145 | B | 线性查找 + 首次/末次位置 |
| 146 | I | 冒泡排序（含提前退出标志） |
| 147 | I | 选择排序 |
| 148 | I | 插入排序 |
| 149 | I | 二分查找（循环版） |
| 150 | I | 计数排序（小范围整数） |
| 151 | I | 合并两个有序数组 |
| 152 | I | 去重（保持首次出现顺序） |
| 153 | I | 最大/最小/极差一次遍历 |
| 154 | A | 双指针求两数之和（有序数组） |
| 155 | A | 滑动窗口最大子段和（Kadane） |
| 156 | A | 快排分治（递归 + `sublist`） |

### 18 递推与动态规划（157–168）

| id | Lv | 主题 |
| --- | --- | --- |
| 157 | B | 阶乘（递归 + 迭代对拍） |
| 158 | B | 斐波那契三写法（递归/迭代/记忆化 Map） |
| 159 | I | 爬楼梯方案数 |
| 160 | I | 零钱兑换最少硬币（DP 数组，`add` 增长） |
| 161 | I | 零钱兑换方案数 |
| 162 | I | 最长公共子序列长度（二维 `List<List<int>>` 字面量） |
| 163 | I | 最长递增子序列（O(n²)） |
| 164 | I | 0/1 背包（一维倒序 DP） |
| 165 | A | 网格最小路径和 |
| 166 | A | 编辑距离 |
| 167 | A | 不同路径数（含障碍） |
| 168 | A | 记忆化搜索统一模板对比 |

### 19 手写数据结构（169–180）

| id | Lv | 主题 |
| --- | --- | --- |
| 169 | I | 用 `List` 实现栈（push/pop/peek/isEmpty） |
| 170 | I | 用 `List` 实现队列（缺点与 `removeAt(0)`） |
| 171 | I | 环形缓冲（固定容量 + 覆盖） |
| 172 | I | 单链表（节点类 + 遍历/插入） |
| 173 | I | 链表反转 |
| 174 | A | 链表环检测（快慢指针） |
| 175 | I | 二叉树（左右子节点类）+ 前序/中序/后序 |
| 176 | I | 二叉搜索树插入与查找 |
| 177 | A | 层序遍历（队列） |
| 178 | A | 用有序 `List` 实现优先队列（取最小） |
| 179 | A | 并查集（父数组 + 路径压缩） |
| 180 | A | `Map<String,List<String>>` 邻接表 + DFS/BFS 对比 |

### 20 数学与统计（181–192）

| id | Lv | 主题 |
| --- | --- | --- |
| 181 | I | GCD（欧几里得，R10 安全写法）与 LCM |
| 182 | I | 质数判定与试除优化 |
| 183 | I | 埃拉托斯特尼筛（字面量数组） |
| 184 | I | 质因数分解 |
| 185 | I | 杨辉三角前 n 行 |
| 186 | I | 矩阵转置 |
| 187 | I | 矩阵乘法 |
| 188 | B | 平均值/中位数/众数 |
| 189 | I | 方差与标准差（`sqrt`） |
| 190 | I | 移动平均（窗口） |
| 191 | A | 线性回归斜率截距 |
| 192 | I | 角度与弧度换算（`pi`、`cos`） |

### 21 面向对象建模实战（193–204）

| id | Lv | 主题 |
| --- | --- | --- |
| 193 | B | 不可变值对象 + `==`/`hashCode` |
| 194 | I | 值对象 + `toString` 调试输出 |
| 195 | I | `factory` 构造做入参校验 |
| 196 | I | 命名构造的多种构造入口 |
| 197 | I | getter 计算属性（`fold` 求和） |
| 198 | I | setter 守卫 + 非法值拒绝 |
| 199 | I | `implements` 抽象接口 + 两个实现 |
| 200 | I | 多接口组合（`implements A, B`） |
| 201 | A | 值对象封装 Map 的 DTO |
| 202 | A | 聚合根：内部 List + 只读视图 |
| 203 | A | 策略对象用"函数字段"实现（可赋值闭包） |
| 204 | A | 面向对象 vs 函数式：同一任务两种写法对拍 |

### 22 枚举与状态机（205–215）

| id | Lv | 主题 |
| --- | --- | --- |
| 205 | B | 枚举 + `switch` 生成中文标签 |
| 206 | B | 枚举 `.index` 做优先级/权重 |
| 207 | I | 枚举作 `Map` key 计数 |
| 208 | I | 订单状态迁移表（允许/拒绝） |
| 209 | I | 交通灯循环状态机 |
| 210 | I | 简易词法状态机（数字/字母/符号） |
| 211 | I | 游戏关卡推进（通关/重试/结束） |
| 212 | A | 工作流状态 + 非法迁移抛 `StateError` |
| 213 | A | 权限矩阵（角色 × 动作 枚举二维判定） |
| 214 | A | 状态机 + 事件计数报表 |
| 215 | A | 用枚举替代魔法字符串（重构对拍） |

### 23 错误处理与容错（216–226）

| id | Lv | 主题 |
| --- | --- | --- |
| 216 | B | 自定义 `Exception`（带 code/detail） |
| 217 | I | 批量处理中的逐条容错（循环 try） |
| 218 | I | 结果对象代替抛错（成功/失败封装） |
| 219 | I | 断言式校验 + `ArgumentError` |
| 220 | I | 错误聚合报告（收集所有错误再输出） |
| 221 | I | 降级策略（解析失败回退默认值） |
| 222 | I | 同步重试（最大次数 + 计步） |
| 223 | I | 嵌套 try 的资源清理（`finally` 只打印） |
| 224 | A | 错误分类：可重试 vs 永久失败 |
| 225 | A | 契约校验 + 缺陷清单输出 |
| 226 | A | 用 `on Object` 兜底并保持程序不死 |

### 24 JSON 与数据映射（227–238）

| id | Lv | 主题 |
| --- | --- | --- |
| 227 | B | `jsonDecode` → `Map<String,dynamic>` 取字段 |
| 228 | B | `jsonEncode` 输出紧凑 JSON |
| 229 | I | 数组解析 + `cast<String>()` |
| 230 | I | 缺字段的默认值填充（`??`） |
| 231 | I | 嵌套对象取值（两层 `as`） |
| 232 | I | JSON 数组 → 域对象列表（手工映射） |
| 233 | I | 域对象列表 → JSON 编码复现（往返一致） |
| 234 | I | 数值 vs 字符串类型陷阱（`as int` 失败处理） |
| 235 | A | 嵌套 JSON 拍平为 `a.b.c` 键（手工递归） |
| 236 | A | 多记录聚合统计（分组计数） |
| 237 | A | JSON 配置合并（默认 + 覆盖） |
| 238 | A | 脏数据清洗报告（丢弃并计数） |

### 25 日期与金额计算（239–249）

| id | Lv | 主题 |
| --- | --- | --- |
| 239 | B | 年龄计算（生日是否已过） |
| 240 | B | 日期格式化 `YYYY-MM-DD`（`padLeft`） |
| 241 | I | 两个日期相差天数 |
| 242 | I | 日期加 N 天/周 |
| 243 | I | 星期几名称映射（`weekday`） |
| 244 | I | 工作日计数（跳过周末） |
| 245 | I | 分期还款计划表（等额本金） |
| 246 | I | 复利计算（`pow`） |
| 247 | I | 税费阶梯计算（多档位） |
| 248 | A | 金额以"分"为整数存储，避免浮点（转换与格式化） |
| 249 | A | 账单账期切分与到期提醒 |

### 26 集合统计与报表（250–261）

| id | Lv | 主题 |
| --- | --- | --- |
| 250 | I | 分组计数（手工 `Map` 累积） |
| 251 | I | Top-N 排名（双重扫描，R 系安全写法） |
| 252 | I | 直方图文本输出 |
| 253 | I | 透视表（行/列二维 Map 嵌套） |
| 254 | I | 分页切片（`sublist` 边界守卫） |
| 255 | I | 两个列表的差集/交集（`Set`） |
| 256 | I | 按 key 合并两个 Map |
| 257 | I | 去重合并多列表 |
| 258 | A | 分组后求每组均值 |
| 259 | A | 累计求和（running total） |
| 260 | A | 环比/同比变化率（避免除零） |
| 261 | A | 报表对齐打印（`padLeft/padRight` 表格） |

### 27 文本排版与表格输出（262–272）

| id | Lv | 主题 |
| --- | --- | --- |
| 262 | B | 简易表格（定宽列 + 分隔线） |
| 263 | B | 编号列表渲染 |
| 264 | I | 树形缩进输出（`-- ` 前缀，递归） |
| 265 | I | 进度条（字符填充 + 百分比） |
| 266 | I | 折行（按宽度切词） |
| 267 | I | ASCII 分隔线/标题框（宽度自适应） |
| 268 | I | 键值对齐配置打印 |
| 269 | A | 简易 Markdown 标题/列表渲染 |
| 270 | A | CSV 输出（含字段转义判断） |
| 271 | A | 数字千分位格式化（手工分段） |
| 272 | A | 多列瀑布布局（列宽计算） |

### 28 可移植异步模式（273–283）

| id | Lv | 主题 | 约束 |
| --- | --- | --- | --- |
| 273 | I | `Future<void>.delayed` + `await` 顺序性 | 输出顺序即证据 |
| 274 | I | 串行 await 流水线（3 步变换） | 无 `Future.value` |
| 275 | I | 异步循环累加 | 探针 pass |
| 276 | I | 分批处理（每批 await 一次） | — |
| 277 | I | 带计步的"重试"（同步 + 1 次 await） | 不用 `catchError` |
| 278 | A | 模拟超时：计步比较阈值（不做真 timeout） | 说明真实 `timeout` 需 SDK |
| 279 | A | 异步函数返回 `List`/`Map` 聚合 | — |
| 280 | A | `then` 链式表达（`Future.delayed` 上） | 探针 pass |
| 281 | A | 异步 + 自定义 `Exception` 的**同步**降级 | 不 throw across await |
| 282 | A | 异步任务的顺序日志（trace id） | — |
| 283 | A | 可移植异步 vs SDK 异步能力对照说明 | 教学性对照，非凑数 |

### 29 接口契约与校验（284–294）

| id | Lv | 主题 |
| --- | --- | --- |
| 284 | I | 校验规则链（函数列表逐个执行） |
| 285 | I | 必填/长度/范围三类校验 |
| 286 | I | 校验错误消息聚合 |
| 287 | I | 版本号比较（主.次.修订） |
| 288 | I | 语义化版本约束匹配（^、~ 手工判定） |
| 289 | I | 配置默认值与覆盖合并 |
| 290 | A | 固定窗口限流计数（Map 计数） |
| 291 | A | 令牌桶模拟（整数计步） |
| 292 | A | 接口契约实现体对照（同接口两实现行为一致） |
| 293 | A | 数据迁移脚本（旧格式→新格式 + 报告） |
| 294 | A | 兼容层：新旧字段同时支持 |

### 30 综合小项目（295–300）

| id | Lv | 主题 |
| --- | --- | --- |
| 295 | A | 记账本：录入/分类汇总/报表 |
| 296 | A | 库存管理：入库/出库/低库存告警 |
| 297 | A | 成绩单：等级/排名/分布 |
| 298 | A | 词频报告：清洗/统计/Top-N/格式化 |
| 299 | A | 迷宫寻路（BFS + 路径回溯） |
| 300 | A | 简易表达式求值器（词法 + 双栈） |

**合计 180 条，逐条唯一主题，无"改数字凑数"，全部限定在 §2.1 白名单。**

---

## 6. 文件边界（与旧内容修复零冲突）

### 6.1 新增文件（本批独占，旧修复不碰）

```
curriculum/chapters/numbers_strings.dart        → numbersStringsLessons  (121-132)
curriculum/chapters/text_processing.dart        → textProcessingLessons  (133-144)
curriculum/chapters/algorithms_basic.dart       → algorithmsBasicLessons (145-156)
curriculum/chapters/algorithms_advanced.dart    → algorithmsAdvancedLessons (157-168)
curriculum/chapters/data_structures.dart        → dataStructuresLessons  (169-180)
curriculum/chapters/math_stats.dart             → mathStatsLessons       (181-192)
curriculum/chapters/oop_modeling.dart           → oopModelingLessons     (193-204)
curriculum/chapters/enum_states.dart            → enumStatesLessons      (205-215)
curriculum/chapters/errors_resilience.dart      → errorsResilienceLessons(216-226)
curriculum/chapters/json_modeling.dart          → jsonModelingLessons    (227-238)
curriculum/chapters/dates_money.dart            → datesMoneyLessons      (239-249)
curriculum/chapters/collection_reporting.dart   → collectionReportingLessons (250-261)
curriculum/chapters/formatting_output.dart      → formattingOutputLessons(262-272)
curriculum/chapters/async_patterns.dart         → asyncPatternsLessons   (273-283)
curriculum/chapters/apis_contracts.dart         → apisContractsLessons   (284-294)
curriculum/chapters/mini_apps.dart              → miniAppsLessons        (295-300)
curriculum/dart_expansion.dart                  → 新章节注册 + 便携已验证 id 集合
tool/verify_expansion_portable.dart             → 仅跑 121-300 的便携门（复用 runner）
```

`curriculum/dart_expansion.dart` 内容（避免污染旧 whitelist）：
- `const List<DartChapter> expansionChapters`
- `const Map<String,int> expansionCounts`
- `const Set<String> expansionPortableIds` —— **全部 180 个都要在里面**
  （因为每条都实测通过），旧 120 的集合仍由 `DartCurriculum.dartEvalVerifiedIds` 单管。

### 6.2 必须触碰的既有文件（最小、单行级、需与旧修复协调）

| 文件 | 改动 | 冲突风险 |
| --- | --- | --- |
| `curriculum/dart_curriculum.dart` | 末尾追加 16 个 `...xxxLessons`（纯追加） | 低（旧修复不改此文件） |
| `curriculum/dart_chapters.dart` | ①`chapters` 追加 16 条；②`counts` 追加 16 项；③`engineTag/engineNote` 的判定改为 `dartEvalVerifiedIds.contains(id) \|\| expansionPortableIds.contains(id)` | **中**：旧修复会改 `dartEvalVerifiedIds`。约定：**该集合的成员增删只属于旧修复**；本批只做上面 ③ 的**只读并集** |
| `tool/build_dart_content.dart` | `120` 常量改为 `DartCurriculum.totalLessons`（= 300），并按章校验用合并后的 counts | 低（旧修复不改生成器逻辑） |
| `tool/audit_compat.dart` | 无（读 JSON 自动覆盖） | 无 |
| `test/dart_content_test.dart` | 120 → 300 的计数/序号/唯一性 | 低 |
| `test/dart_content_run_test.dart` | 文案 120 → 300（逻辑已是全遍历） | 低 |
| `test/dart_content_import_test.dart` | `checked 120` → 300；`hasLength(120)` → 300 | 低 |
| `test/dart_content_widget_test.dart` | `>=120` → `>=300` | 低 |
| `test/dart_content_dart_eval_test.dart` | 白名单改成"旧集合 ∪ 新集合"，并分别报告两段计数 | **中**：与旧修复同文件。约定：旧修复只维护旧集合的断言，本批只加新集合的断言块 |
| `tool/verify_portable_content.dart` | 无需改（遍历 `dartCurriculum`） | 低 |

### 6.3 明确不碰（硬边界）

- `lib/main.dart`、`lib/dart_content_repository.dart`、`lib/dart_tools*.dart`、任何平台目录
  （`ohos/ ios/ android/ macos/ linux/ windows/ web/`）、`pubspec.yaml`、签名/启动文件。
- 共享核心 `../qfli_studio_core/**`（C 协调者所有权）。
- 旧 14 个 `curriculum/chapters/*.dart` 的**内容**（属旧修复批次）、
  `DartCurriculum.dartEvalVerifiedIds` 的成员。

### 6.4 生成物

`assets/content/dart_tutorials.json` / `dart_examples.json` 由 `tool/build_dart_content.dart`
重新生成，**只由生成器产**，不手改。生成前后 `updatedAt` 保持固定常量，保证 diff 稳定。

---

## 7. 内容字段设计（沿用现有模型，零新字段）

`DartLesson` / `DartExercise` / `DartChapter` 现有字段已足够，**不新增字段**，理由：
详情页只渲染 `explain / objective / prerequisites / pitfalls / code / output / exercises`，
新增 `engine` 之类字段解析器会丢（spec §6 已明确这是 Wrong）。

| 字段 | 180 条的填写规则 |
| --- | --- |
| `id` | `dart-lesson-121..300`，示例 `dart-example-121..300` |
| `chapter` | 上表 16 个 key 之一 |
| `level` | beginner 17 / intermediate 102 / advanced 61（与 §5 逐条标注一致） |
| `title` | 中文，≤ 20 字，全库唯一 |
| `summary` | 一句话说清"做什么 + 学到什么"，归一化后唯一 |
| `concepts` | 3–5 个具体 API/概念名（可含中文），不复用旧课的概念组合 |
| `explain` | 150–320 字：①这是什么问题 ②Dart 里怎么做 ③为什么这样写 ④引擎适用性说明。**必须唯一** |
| `objective` | 一句话可检验目标 |
| `prerequisites` | 指向同章前序课 id 的中文描述；可空 |
| `pitfalls` | 2–3 条真实坑（须来自本轮探针的禁区，如"不要用 reduce"） |
| `code` | 完整 `main()`；多行；无 stdin/网络/IO；归一化后唯一；遵守 R1–R14 |
| `output` | **从真实运行结果复制**（LF），末行换行 |
| `exercises` | ≥1，且建议 2 条：`prompt/hint/answer` 全非空；`answer` 是可运行片段 |
| `exampleTitle` | `示例 NNN：<主题>` |
| `exampleSummary` | 与 lesson 不同角度的表述 + 引擎标签由生成器追加 |
| `exampleCode` | 默认 `null`（与 lesson 同代码）；若给则必须与 lesson code 不同且**独立通过便携门** |

**引擎说明文案（写进 `explain` 末尾由生成器追加，作者不手写）**：
新 180 条全部命中 `expansionPortableIds`，因此会得到
"本课已在官方 Dart SDK 与 dart_eval 便携引擎上实测通过"。这要求**每条真的双绿**，
不允许先标后验。

---

## 8. 验证门（每条都必须过，缺一不算完成）

按章/按批执行，最终全量：

```powershell
cd D:\MyNewProjects\qfli_dart

# 作者期：逐章双引擎
dart run tool/verify_dart_content.dart --chapter numbers-strings
dart run tool/verify_portable_content.dart --chapter numbers-strings --report .trellis/tasks/10-22-offline-ide-completeness/research/expansion-<key>.json

# 集成期：全量
dart run tool/build_dart_content.dart        # 必须输出 300 / 300
dart run tool/verify_dart_content.dart       # checked=300 failures=0
dart run tool/verify_portable_content.dart   # checked=600 failures=0
dart run tool/audit_compat.dart              # unlabeled: 0
flutter analyze --no-pub lib tool test curriculum
flutter test --no-pub
```

附加门（本批特有）：

1. **exampleCode 独立门**：只要 `exampleCode != null`，就必须单独跑便携引擎，
   不能靠 lesson 的 `output` 复用（现有 `verify_dart_content` 已做，便携门也需覆盖）。
2. **禁区静态扫描**：新增 `tool/check_portable_subset.dart`（或并入 verify）扫描
   121–300 号代码中的禁区词：`continue`、`reduce`、`expand`、`indexWhere`、
   `runtimeType`、`late `、`mixin `、`extension `、`typedef `、`super.`、
   `abstract class`、`Stream`、`Isolate`、`Future.value`、`Future.wait`、
   `catchError`、`List.filled(...)` 后下标赋值、`StringBuffer`、`dart:io`。
   命中即失败并给出 lesson id —— 这是防止后续维护者把"能编译"当"能跑"。
3. **静默错误抽查**：对每条新代码额外做一次"同一程序跑两遍输出一致"检查，
   并断言输出非空、不含 `Instance of`、不含 `object Object`、不含 `UnimplementedError`。

---

## 9. 执行顺序（等旧基线修复完成后）

1. **前置**：旧 120 修复批次完成，`verify_portable_content` 的旧 240 单元全绿
   （或明确记录"仅 SDK 可行"并给出 runtime 增强结论）。此步未完成**不启动**本批。
2. 建 `curriculum/dart_expansion.dart` + `tool/verify_expansion_portable.dart`，
   接上 `dart_curriculum.dart` / `dart_chapters.dart` 的追加（先空列表，保证测试仍绿）。
3. 按章节顺序（15→30）逐章写 12/11/6 条，每章写完立刻双引擎跑该章，
   期望输出直接从运行结果取值，`--report` 存档到 `research/expansion-<key>.json`。
4. 每章完成后跑一次 `flutter analyze --no-pub curriculum`，避免大爆炸。
5. 全 180 完成后：`build_dart_content` → 改测试计数 120→300 → 全量四门 → `flutter test`。
6. 内容规模核对：`tutorials=300`、`examples=300`、`explain` 唯一 300、
   lesson code 唯一 300、example code 唯一 300、按章 counts 之和 = 300。
7. 分批提交（Conventional Commits），每批一章或一个主题组，精确 `git add` 路径，
   不夹带旧修复与启动/签名改动。

## 10. 风险与回退

| 风险 | 处置 |
| --- | --- |
| 某条作者后发现引擎不通过 | 该条不计入；按 §2.2/2.3 改写或换主题；**禁止**把 `output` 改成错误值蒙混 |
| 与旧修复在同文件冲突 | 只在 `dart_chapters.dart` 的并集判定、`dart_content_dart_eval_test.dart` 的断言块交界；按 §6.2 约定分段提交 |
| 测试计数 120→300 变动大 | 一次性改 `DartCurriculum.totalLessons`，测试引用常量而非字面量 |
| 180 条中部分主题偏"练习化" | 已在 §5 用真实算法/工程任务保证每条的独立知识密度；不允许"模板换数字" |
| 旧 runtime 若被增强（桥接 `continue`/Stream/File） | 新内容仍保持白名单写法（双引擎都过 = 最稳），不因增强而放松 |

## 11. 可交付的 probe 证据索引

- 探针脚本（临时目录，未入库）：`%TEMP%\qfli_probe\{probe,cases,cases2,cases3,cases4,cases5}.dart`
- 探针结果（临时目录）：`%TEMP%\qfli_probe\results{,2,3,4,5}.json`
  （278 程序：179 pass / 99 fail，含每条的 `output`、`error`、`expect`）
- 旧基线（已入库）：`research/portable-baseline.json`（240 单元，86 pass / 154 fail）
- 如需入库归档探针结论，可另开小任务把 5 个 results 合并成
  `research/portable-subset-matrix.json`；本轮按要求不写产品代码，未入库。

## 12. 移交说明（给实现者）

- 读本文件 §2.4 的 14 条铁律，再读 §5 的 180 条主题表，逐章实现。
- 每写一条：先跑便携引擎拿到**真实输出**，再把输出写回 `output`，不手算。
- 任何一条无法在 dart_eval 上通过 → **换主题或改写**，不要调低门槛、
  不要把它挪进"仅 SDK"（新内容的目标就是 300 组全部离线可跑）。
- 旧 runtime 增强（桥接 `continue`、`StringBuffer`、`Directory`、`Stream`、泛型等）
  是**另一条线**，可以并行评估，但新内容不依赖它。
