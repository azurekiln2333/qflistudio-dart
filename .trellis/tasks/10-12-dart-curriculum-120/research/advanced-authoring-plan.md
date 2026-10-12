# 后 60 课（061–120）作者计划

范围：061–120，共 60 课。每课独立知识点、自包含程序、无外网、无真实 stdin、真实
Dart SDK 可编译可运行。IO 课用自建临时目录 + `finally` 清理。输出为实际 stdout。

统一约定
- id：`dart-lesson-0NN`；配对示例 id：`dart-example-0NN`，`sourceLessonId` 指向本课。
- 每课字段：chapter/level/title/summary/concepts/explain(中文独有散文)/objective/
  prerequisites/pitfalls/code/output/exercises(≥1)/exampleTitle/exampleSummary。
- 引擎要求写进 `explain`（Dart3/async/stream/isolate/IO → 注明需官方 SDK）。
- `code` 多行、含真实 `main`、与课程知识点强绑定；禁止同模板换数。
- `output` 必须与真实执行逐字符一致（含末尾换行）；无随机、无时钟、无网络依赖。
- level 与难度匹配：高级特性禁标 beginner。

## 章节 061–072 Dart 3 新模式（advanced，12 课）
- 061 记录 record：`(String, int)` 位置字段解构赋值，`print` 各字段与 typ。
- 062 命名记录：`({String name, int age})` 字段访问与整体相等性判断。
- 063 switch 模式解构：对 record `switch` 绑定变量，exhaustive 值。
- 064 列表模式：`[a, b, ...rest]` 提取首项与剩余长度。
- 065 映射模式：`{'k': v, ...}` 提取指定键并处理缺失分支。
- 066 对象模式：自定义类（无自定义 ==）用 `switch` 读取 getter 字段。
- 067 guard 子句 `when`：条件匹配下走 fallback 分支。
- 068 sealed 类 + exhaustive switch：子类穷尽，编译期闭合。
- 069 增强 enum：带字段/构造/方法的 enum，遍历 `values` 汇总。
- 070 类修饰符 sealed/base/final：演示 final 类不可被继承（注释说明编译期约束，
  运行期仅打印可实例化行为）。
- 071 pattern in if-case：`if (v case int n)` 类型细化的分支输出。
- 072 模式 + 集合实用：`switch` 解构列表求和安全路径，展示 `_` 通配。

风险：record 相等性、sealed 穷尽、增强 enum 需 Dart 3；`explain` 明确官方 SDK。
  类修饰符不可运行期断言继承禁令，只演示正向行为并文字说明。

## 章节 073–082 异步 async/await（advanced，10 课）
- 073 Future 基础：`Future.delayed(Duration.zero)` 后 `.then`，顺序输出。
- 074 async/await 顺序：多个 `await` 串行，打印时序。
- 075 Future.wait 并发：`Future.wait` 汇总定长结果列表。
- 076 Future.error / try-catch：捕获异步异常并打印错误信息。
- 077 超时与 `timeout`：`Future.delayed` + `timeout` 触发 TimeoutException。
- 078 async 函数返回校验：`async` 函数返回值与未 await 的差异演示。
- 079 Future 链与 `then` 变换：`then` 映射后接 `catchError`。
- 080 `unawaited` 与 fire-and-forget：`dart:async` `unawaited` 演示，退出前 await。
- 081 异步遍历 for-await 前置：`Stream.fromIterable().toList()` 汇总（引出 083）。
- 082 异步错误传播与资源：`try/finally` 中 await 清理（模拟句柄释放）。

风险：时序取决于事件循环但全部用 `Duration.zero`/定长，输出确定；禁用真实延时。

## 章节 083–090 Stream（advanced，8 课）
- 083 Stream 基础：`Stream.fromIterable` + `await for` 求和。
- 084 Stream 变换 map/where：过滤偶数并平方后收集。
- 085 StreamController 手动推送：add/close 后 `toList`。
- 086 广播流 broadcast：两订阅者各收相同事件计数。
- 087 Stream 错误处理：`handleError` / `onError` 捕获并续流。
- 088 `Stream.asyncMap` 异步变换：逐元素异步映射后收集。
- 089 `Stream.fold` 聚合：fold 计数与累积字符串。
- 090 `Stream` 与 `listen` 取消：`StreamSubscription.cancel` 后停止。

风险：broadcast 订阅时序、listen 取消时机；全部用同步 emit + await 收敛。

## 章节 091–096 Isolate 并发（advanced，6 课）
- 091 Isolate.run 单次计算：`Isolate.run` 返回求和结果。
- 092 传参与返回：向 `Isolate.run` 传 record/Map 并返回。
- 093 Isolate.spawn + SendPort：worker 回发消息，主 isolate 接收后打印。
- 094 多 isolate 并行：`Future.wait` 并发跑 N 个 `Isolate.run` 求和。
- 095 isolate 内异常传播：`Isolate.run` 抛错被主 isolate 捕获。
- 096 分离工作量与聚合：两 isolate 分别算 sum/max 再合并。

风险：isolate 必须 `await`/监听关端口，避免挂起测试；禁止共享可变状态。
  官方 SDK 必须（dart_eval 不支持）。

## 章节 097–104 dart:io 文件（advanced，8 课）
- 097 临时文件写入/读取：建临时目录写文件再读回，`finally` 递归删除。
- 098 追加与逐行读取：写多行后 `readAsLines`，打印行数与首末行。
- 099 目录列举与过滤：建两个文件，`listSync` 按扩展名过滤计数。
- 100 文件复制与存在性：`copy` 到新路径，`existsSync` 验证，清理。
- 101 重命名与删除：`rename` 后确认旧路径不存在，清理。
- 102 JSON 落盘往返：写 JSON 字符串再读回 decode（与 105 呼应但落盘）。
- 103 目录递归统计：建嵌套子目录，递归统计文件数。
- 104 文件元数据：`length()`/`lastModifiedSync` 存在性（不打印时间值，只打印
  布尔/length 稳定性）。

风险：临时目录用 `Directory.systemTemp.createTemp`；`finally` 递归删除；
  不打印时间戳（不确定）；行尾用 `\n` 固定（Windows 读取避免 `\r` 污染）。

## 章节 105–110 JSON 与序列化（intermediate/advanced，6 课）
- 105 jsonEncode/Decode 基础：Map→String→Map 往返相等打印。
- 106 嵌套结构：对象数组 encode 后取 length 与首元素字段。
- 107 手动 fromJson：类构造自 Map，打印还原字段。
- 108 手动 toJson：对象转 Map 再 encode，打印字符串。
- 109 列表综合：对 JSON 数组 map 求字段和。
- 110 错误处理：decode 非法 JSON 抛 FormatException 并捕获打印。

风险：Map 打印顺序在 Dart 保持插入序，可确定；避免依赖非插入序。
  不引入外部 codegen 包（自包含）。

## 章节 111–120 测试/包/工程实战（intermediate/advanced，10 课）
> 全部仍是单文件 `main()` 可运行程序（packages 需更复杂工程，用「模拟」保持在
> 单文件内），讲解真实机制。
- 111 expect 风格断言模拟：手写 `_expect` 辅助，若干断言通过并打印计数。
- 112 分组测试结构：用函数数组模拟 group，统计通过数。
- 113 边界用例设计：对整数解析器测空格/负号/非法三类输入结果。
- 114 异常断言：用 try/catch 验证抛错类型匹配。
- 115 不可变数据建模：`final` 字段 + 拷贝构造（copyWith 手写）打印新值。
- 116 相等性与 hashCode：重写 `==`/`hashCode`，验证 Set 去重。
- 117 分层架构模拟：repository/服务/入口三层函数，打印调用链结果。
- 118 配置与环境隔离：读入 Map 配置，缺失键用默认值，打印合并结果。
- 119 性能测量（确定性）：对固定循环计数统计操作次数（不打印耗时）。
- 120 综合实战：命令行风格参数解析（用内存 List<String> 模拟 args），
  汇总输出，覆盖前述多知识点。

风险：111–114「测试」是教学模拟而非引入 test 包；须在 `explain` 说明真机项目
  用 `package:test`。119 禁打印时长（不确定）；改为计数。

## 待接口确认项（等主 pi 稳定接口后再写内容）
- `curriculum/dart_lesson.dart` 字段签名与 `Exercise` 命名。
- 章节/文件切分（chapters/ 目录结构）与 id/标题前缀。
- generator 期望的输入形态（是否要我导出 `List<DartLesson>` getter）。
- 冲突文件约定：我仅写 061–120 对应文件，避免与 001–060 作者同名。

## 高风险统一注意
- engine 说明只能进 `explain`（无语义 engine 字段）。
- 不使用 `inputFixtures`（死字段）；本 60 课全部自包含无 stdin。
- 输出不确定源：时间、随机、HashSet 迭代序、目录列举序 → 一律排序或只打印计数。
- IO 一律 `finally` 清理，禁止遗留文件。
