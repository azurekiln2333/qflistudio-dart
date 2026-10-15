import '../dart_lesson.dart';

/// Chapter `async` — lessons 073-082. Owned by the second pi.
///
/// Export name: `asyncLessons`. Keep lessons sorted by id.
///
/// Every program here uses `Future`/`async`/`await` and requires the official
/// Dart SDK engine; `dart_eval` only implements a reduced subset. Timing is
/// pinned to `Duration.zero` so stdout is deterministic.
const List<DartLesson> asyncLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-073',
    chapter: 'async',
    level: 'advanced',
    title: 'Future 与 await 基础',
    summary: '用 await 等待一个 Future，理解异步函数里语句的先后顺序。',
    concepts: <String>['Future', 'await', 'async', 'then'],
    explain:
        'Future 代表"一个将来才会有结果的操作"。await 会暂停当前 async 函数，'
        '直到 Future 完成并取出它的值，然后再继续往下执行。注意 await 只暂停所在函数，'
        '不会阻塞整个程序。也可以用 .then 注册回调，但 await 让异步代码看起来像同步代码，'
        '更易读。本课把延时设成 Duration.zero，让输出顺序完全确定。'
        'async/await 需要官方 Dart SDK 引擎，dart_eval 只支持有限子集。',
    objective: '能声明 async 函数，用 await 取 Future 的值，并预测输出顺序。',
    prerequisites: <String>['了解函数与返回值', '运行环境为官方 Dart SDK'],
    pitfalls: <String>[
      '忘记 await 会拿到 Future 对象本身，而不是它的值。',
      'await 只能在 async 函数内使用，且 main 也要声明 async。',
      'await 不会阻塞其它任务，不要把"等待"理解为"卡住整个程序"。',
    ],
    code:
        "import 'dart:async';\n"
        "\n"
        "Future<void> main() async {\n"
        "  print('开始');\n"
        "  final value = await Future<int>.delayed(Duration.zero, () => 42);\n"
        "  print('收到 \$value');\n"
        "  Future<String>.delayed(Duration.zero, () => '完成').then(print);\n"
        "  await Future<void>.delayed(Duration.zero);\n"
        "  print('结束');\n"
        "}\n",
    output: '开始\n收到 42\n完成\n结束\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '写一个 async 函数返回 7，await 后打印它的两倍。',
        hint: '函数体用 return 7; 调用处 await。',
        answer:
            "Future<int> seven() async => 7;\n"
            "\n"
            "Future<void> main() async {\n"
            "  print(await seven() * 2);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 073：Future 与 await',
    exampleSummary: 'await 一个 Future.delayed，并用 then 注册回调。',
  ),
  DartLesson(
    id: 'dart-lesson-074',
    chapter: 'async',
    level: 'advanced',
    title: '多个 await 的串行执行',
    summary: '连续 await 两个异步函数，观察它们按书写顺序依次完成。',
    concepts: <String>['顺序 await', 'async 返回值', '串行'],
    explain:
        '当多个 await 按顺序书写时，它们会串行执行：前一个 Future 完成后，才轮到'
        '下一个。这种写法简单直观，适合有先后依赖的操作（先取名字再取年龄）。'
        '异步函数的返回类型是 Future<T>，return 的值会被自动包装进 Future；'
        '调用方 await 时就拿到 T。要记住串行意味着总耗时是各段之和，'
        '若无依赖关系应改用并发。异步串行是 Dart 常见的现代写法。',
    objective: '能让两个异步函数串行执行，并正确取出各自的返回值。',
    prerequisites: <String>['已掌握 Future 与 await'],
    pitfalls: <String>[
      '无关的两个 Future 用串行 await 会白白变慢，可考虑 Future.wait。',
      'async 函数里 return Future 不会自动 flatten 的直觉要小心，直接 return 值即可。',
      '忘记 await 第二个调用会得到 Future 而非数值。',
    ],
    code:
        "Future<String> fetchName() async {\n"
        "  await Future<void>.delayed(Duration.zero);\n"
        "  return '小明';\n"
        "}\n"
        "\n"
        "Future<int> fetchAge() async {\n"
        "  await Future<void>.delayed(Duration.zero);\n"
        "  return 18;\n"
        "}\n"
        "\n"
        "Future<void> main() async {\n"
        "  final name = await fetchName();\n"
        "  final age = await fetchAge();\n"
        "  print('\$name \$age');\n"
        "  print('姓名长度 \${name.length}');\n"
        "}\n",
    output: '小明 18\n姓名长度 2\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '再加一个异步函数返回城市名，串行 await 后打印"姓名 城市"。',
        hint: '照抄 fetchName 的结构，改返回值即可。',
        answer:
            "Future<String> fetchCity() async => '杭州';\n"
            "\n"
            "Future<void> main() async {\n"
            "  final name = '小明';\n"
            "  final city = await fetchCity();\n"
            "  print('\$name \$city');\n"
            "}",
      ),
    ],
    exampleTitle: '示例 074：串行 await',
    exampleSummary: '两个异步函数按顺序 await，取出并组合它们的返回值。',
  ),
  DartLesson(
    id: 'dart-lesson-075',
    chapter: 'async',
    level: 'advanced',
    title: 'Future.wait 并发聚合',
    summary: '用 Future.wait 并发跑多个 Future，等全部完成后拿到结果列表。',
    concepts: <String>['Future.wait', '并发', '结果列表'],
    explain:
        'Future.wait 接收一组 Future，并发启动它们，等所有 Future 都完成后返回一个'
        '结果列表，顺序与传入顺序一致（不是完成顺序）。它适合彼此独立的操作：'
        '三个任务各算一个平方，最后一次性收集。与串行 await 相比，并发能显著缩短'
        '总耗时。若其中任一 Future 出错，Future.wait 默认会以该错误失败，'
        '除非设置 eagerError: false。本课需要官方 Dart SDK。',
    objective: '能用 Future.wait 并发执行多个 Future 并汇总结果。',
    prerequisites: <String>['已掌握 Future 与 await', '官方 Dart SDK'],
    pitfalls: <String>[
      'Future.wait 的结果顺序是传入顺序，不是完成先后。',
      '列表中任一 Future 抛错都会让整组失败，需按需自行捕获。',
      '传入空列表会立即返回空结果列表。',
    ],
    code:
        "Future<int> task(int n) async {\n"
        "  await Future<void>.delayed(Duration.zero);\n"
        "  return n * n;\n"
        "}\n"
        "\n"
        "Future<void> main() async {\n"
        "  final results = await Future.wait(<Future<int>>[task(2), task(3), task(4)]);\n"
        "  print(results);\n"
        "  print(results.reduce((a, b) => a + b));\n"
        "}\n",
    output: '[4, 9, 16]\n29\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用 Future.wait 并发计算 1..5 的平方，并打印总和。',
        hint: '生成 Future 列表再 wait，用 reduce 求和。',
        answer:
            "Future<int> sq(int n) async => n * n;\n"
            "\n"
            "Future<void> main() async {\n"
            "  final xs = await Future.wait(<Future<int>>[\n"
            "    for (final n in <int>[1, 2, 3, 4, 5]) sq(n),\n"
            "  ]);\n"
            "  print(xs.reduce((a, b) => a + b));\n"
            "}",
      ),
    ],
    exampleTitle: '示例 075：Future.wait',
    exampleSummary: '并发执行三个 Future 并按传入顺序收集结果。',
  ),
  DartLesson(
    id: 'dart-lesson-076',
    chapter: 'async',
    level: 'advanced',
    title: '异步异常与 try-catch',
    summary: '用 try/catch 捕获异步抛出的错误，让流程继续。',
    concepts: <String>['异步异常', 'try-catch', 'StateError'],
    explain:
        'await 一个失败的 Future 时，错误会以普通异常的形式从 await 处抛出，'
        '所以 try/catch 同样适用。这让异步错误处理和同步代码保持一致的心智模型：'
        '把可能失败的 await 放进 try，用 on 指定异常类型并读取它的信息。'
        '捕获后流程继续，后面的 await 不受影响。这是最推荐的异步错误处理方式。'
        '本课需要官方 Dart SDK。',
    objective: '能用 try/catch 捕获并处理异步操作抛出的异常。',
    prerequisites: <String>['已掌握 await 与异常基础', '官方 Dart SDK'],
    pitfalls: <String>[
      '只对 Future 用 .catchError 而漏掉 await，错误可能逃逸到未捕获区。',
      'on 子句写错类型会导致不匹配，落到通用 catch 或直接抛出。',
      'catch 里若再 await，仍要保证该错误被捕获，避免二次逃逸。',
    ],
    code:
        "Future<int> risky(bool fail) async {\n"
        "  await Future<void>.delayed(Duration.zero);\n"
        "  if (fail) {\n"
        "    throw StateError('计算失败');\n"
        "  }\n"
        "  return 1;\n"
        "}\n"
        "\n"
        "Future<void> main() async {\n"
        "  try {\n"
        "    final value = await risky(true);\n"
        "    print('不会到这里 \$value');\n"
        "  } on StateError catch (error) {\n"
        "    print('捕获到：\${error.message}');\n"
        "  }\n"
        "  print(await risky(false));\n"
        "}\n",
    output: '捕获到：计算失败\n1\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '把抛出类型换成 FormatException，并捕获后打印其 message。',
        hint: 'on FormatException catch (e) => print(e.message)。',
        answer:
            "Future<void> main() async {\n"
            "  try {\n"
            "    await Future<void>.error(FormatException('格式错误'));\n"
            "  } on FormatException catch (e) {\n"
            "    print(e.message);\n"
            "  }\n"
            "}",
      ),
    ],
    exampleTitle: '示例 076：异步异常捕获',
    exampleSummary: 'await 失败的 Future 并用 try/catch 捕获 StateError。',
  ),
  DartLesson(
    id: 'dart-lesson-077',
    chapter: 'async',
    level: 'advanced',
    title: '超时控制 timeout',
    summary: '给 Future 加超时上限，超时抛出 TimeoutException。',
    concepts: <String>['timeout', 'TimeoutException', '超时上限'],
    explain:
        'Future.timeout 给一个操作设定最长等待时间：在时限内完成就正常返回，'
        '超过时限则抛 TimeoutException。它的用处是避免无限等待——例如某个慢任务'
        '卡住时及时失败并提示用户。注意超时并不自动取消底层操作，只是让等待方提前'
        '放弃。合理设置时限，并把 await ... .timeout(...) 放进 try/catch。'
        '本课需要官方 Dart SDK。',
    objective: '能用 timeout 限制 Future 的等待时间并处理超时异常。',
    prerequisites: <String>['已掌握 await 与 try/catch', '官方 Dart SDK'],
    pitfalls: <String>[
      'timeout 不会取消原 Future，后台操作可能仍在进行。',
      '时限过短会频繁误报超时，需结合实际场景设置。',
      'timeout 抛出的 TimeoutException 必须被捕获，否则流程中断。',
    ],
    code:
        "import 'dart:async';\n"
        "\n"
        "Future<void> main() async {\n"
        "  try {\n"
        "    await Future<int>.delayed(\n"
        "      const Duration(milliseconds: 50),\n"
        "      () => 1,\n"
        "    ).timeout(const Duration(milliseconds: 1));\n"
        "  } on TimeoutException {\n"
        "    print('超时了');\n"
        "  }\n"
        "  final fast = await Future<int>.delayed(\n"
        "    Duration.zero,\n"
        "    () => 2,\n"
        "  ).timeout(const Duration(seconds: 1));\n"
        "  print('按时返回 \$fast');\n"
        "}\n",
    output: '超时了\n按时返回 2\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '给一个 Duration.zero 完成的 Future 设置 1 秒超时，打印结果。',
        hint: '时限远大于完成时间，会正常返回。',
        answer:
            "import 'dart:async';\n"
            "\n"
            "Future<void> main() async {\n"
            "  final r = await Future<int>.delayed(\n"
            "    Duration.zero,\n"
            "    () => 99,\n"
            "  ).timeout(const Duration(seconds: 1));\n"
            "  print(r);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 077：Future 超时',
    exampleSummary: '用 timeout 触发 TimeoutException，及正常完成的对照。',
  ),
  DartLesson(
    id: 'dart-lesson-078',
    chapter: 'async',
    level: 'advanced',
    title: 'async 返回值与 then 变换',
    summary: 'async 函数总是返回 Future，用 then 链式变换其中的值。',
    concepts: <String>['Future<T>', 'then 变换', '链式'],
    explain:
        '一个 async 函数无论 return 什么，对外都是 Future<T>：调用它不会立刻得到值，'
        '而是拿到一个 Future 对象。要取得里面的值可以 await，也可以用 .then 注册'
        '"值到了之后做什么"，并在回调里做变换、返回新值。then 适合简单的一次性映射，'
        '复杂逻辑用 await 更清晰。理解"函数返回 Future，而不是值"是异步入门的关键。'
        '本课需要官方 Dart SDK。',
    objective: '能区分 async 函数返回的 Future 与其内部值，并用 then 变换。',
    prerequisites: <String>['已掌握 await 与 async', '官方 Dart SDK'],
    pitfalls: <String>[
      'async 函数里 return 10 实际返回 Future<int>，不是 int。',
      'then 回调里返回新值会形成新的 Future，层层叠加要留意。',
      '把 Future 当值传给需要 int 的地方会类型报错。',
    ],
    code:
        "Future<int> value() async => 10;\n"
        "\n"
        "Future<void> main() async {\n"
        "  final future = value();\n"
        "  print(future.runtimeType);\n"
        "  final resolved = await future;\n"
        "  print(resolved);\n"
        "  final doubled = await value().then((v) => v * 2);\n"
        "  print(doubled);\n"
        "}\n",
    output: 'Future<int>\n10\n20\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '写 async 函数返回字符串 "dart"，用 then 把它转成大写再打印。',
        hint: "then((s) => s.toUpperCase())。",
        answer:
            "Future<String> word() async => 'dart';\n"
            "\n"
            "Future<void> main() async {\n"
            "  final upper = await word().then((s) => s.toUpperCase());\n"
            "  print(upper);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 078：async 返回值与 then',
    exampleSummary: '观察 async 返回的 Future 类型，并用 then 做值变换。',
  ),
  DartLesson(
    id: 'dart-lesson-079',
    chapter: 'async',
    level: 'advanced',
    title: 'then 链与 catchError',
    summary: '用 then 串联变换，用 catchError 兜住链路上的错误。',
    concepts: <String>['then 链', 'catchError', '错误兜底'],
    explain:
        'then 可以像流水线一样串联：每一步拿上一步的返回值继续处理。当链中任一步'
        '抛出错误，错误会沿着链条传递，直到遇到 catchError 被兜住并给出替代值。'
        '这形成了"正常路径用 then、异常路径用 catchError"的组合。相比 try/catch，'
        'catchError 更贴近 Future 的组合风格，但要注意它返回的仍是 Future，'
        '需要 await 才能取值。本课需要官方 Dart SDK。',
    objective: '能组合 then 与 catchError，在失败时提供兜底结果。',
    prerequisites: <String>['已掌握 then 与异步异常', '官方 Dart SDK'],
    pitfalls: <String>[
      'catchError 的回调必须返回与链类型兼容的值，否则类型不匹配。',
      '把 catchError 放错位置可能漏掉后半段的错误。',
      'catchError 不 rethrow 时错误就被"吞掉"，需确认这是预期行为。',
    ],
    code:
        "Future<int> parse(String text) async => int.parse(text);\n"
        "\n"
        "Future<void> main() async {\n"
        "  final result = await parse('21').then((v) => v + 1);\n"
        "  print(result);\n"
        "  final recovered = await parse('oops').catchError(\n"
        "    (Object error) => -1,\n"
        "  );\n"
        "  print(recovered);\n"
        "}\n",
    output: '22\n-1\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '对 parse("abc") 用 catchError 兜底为 0，并打印。',
        hint: '回调返回 0，类型与 Future<int> 一致。',
        answer:
            "Future<int> parse(String t) async => int.parse(t);\n"
            "\n"
            "Future<void> main() async {\n"
            "  print(await parse('abc').catchError((Object _) => 0));\n"
            "}",
      ),
    ],
    exampleTitle: '示例 079：then 链与 catchError',
    exampleSummary: 'then 变换成功路径，catchError 为失败路径提供兜底值。',
  ),
  DartLesson(
    id: 'dart-lesson-080',
    chapter: 'async',
    level: 'advanced',
    title: 'unawaited 与后台任务',
    summary: '用 unawaited 明确表示"不等待这个 Future"，避免误报未处理。',
    concepts: <String>['unawaited', 'fire-and-forget', 'dart:async'],
    explain:
        '有时我们故意不等某个 Future（如打日志、预热缓存），但又不想让分析器'
        '提示"unawaited_futures"。unawaited(future) 就是显式声明"我知道它没被 await，'
        '这是有意的"。它不是魔法：后台任务仍会执行，但主流程不会等它；若后台任务'
        '抛错且无人处理，仍可能变成未捕获异常。演示时用一次 await 收尾，'
        '保证后台任务有机会打印。本课需要官方 Dart SDK。',
    objective: '能用 unawaited 表达有意的即发即忘，并说明其风险。',
    prerequisites: <String>['已掌握 Future 与事件循环', '官方 Dart SDK'],
    pitfalls: <String>[
      'unawaited 只是抑制提示，不改变"不等待"的事实。',
      '后台任务抛错可能无人捕获，导致进程级未处理异常。',
      '程序若在后台任务完成前退出，任务可能来不及执行。',
    ],
    code:
        "import 'dart:async';\n"
        "\n"
        "void fireAndForget() {\n"
        "  unawaited(\n"
        "    Future<void>.delayed(Duration.zero, () => print('后台任务完成')),\n"
        "  );\n"
        "}\n"
        "\n"
        "Future<void> main() async {\n"
        "  fireAndForget();\n"
        "  print('主流程继续');\n"
        "  await Future<void>.delayed(Duration.zero);\n"
        "}\n",
    output: '主流程继续\n后台任务完成\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用 unawaited 启动一个打印"已记录"的 Future，主流程先打印"开始"。',
        hint: '先 unawaited(...)，再 print("开始")，结尾 await 一次。',
        answer:
            "import 'dart:async';\n"
            "\n"
            "Future<void> main() async {\n"
            "  unawaited(Future<void>.delayed(Duration.zero, () => print('已记录')));\n"
            "  print('开始');\n"
            "  await Future<void>.delayed(Duration.zero);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 080：unawaited 即发即忘',
    exampleSummary: '用 unawaited 启动后台任务，主流程继续执行。',
  ),
  DartLesson(
    id: 'dart-lesson-081',
    chapter: 'async',
    level: 'advanced',
    title: 'Stream 初探与 toList',
    summary: '用 Stream.fromIterable 把多个值汇成列表，为下一章铺垫。',
    concepts: <String>['Stream', 'fromIterable', 'toList'],
    explain:
        '如果说 Future 代表"将来一个值"，那么 Stream 代表"将来一串值"。'
        'Stream.fromIterable 把一个可迭代对象变成流，元素按顺序逐个发出。'
        'toList() 会收集流里所有元素，并返回一个 Future<List<T>>，所以要用 await。'
        '这一课是异步到流的过渡：先体会"多个异步值"的样子，下一章再展开 map、where、'
        '监听与取消。本课需要官方 Dart SDK。',
    objective: '能把 Iterable 转成 Stream 并收集成一个列表。',
    prerequisites: <String>['已掌握 Future 与 await', '官方 Dart SDK'],
    pitfalls: <String>[
      'toList() 返回 Future，忘记 await 会拿到 Future 而非列表。',
      '单订阅流只能被消费一次，重复 toList 会报错。',
      '流是惰性的：不消费就不产生元素。',
    ],
    code:
        "import 'dart:async';\n"
        "\n"
        "Future<void> main() async {\n"
        "  final stream = Stream<int>.fromIterable(<int>[1, 2, 3, 4]);\n"
        "  final list = await stream.toList();\n"
        "  print(list);\n"
        "  print(list.length);\n"
        "}\n",
    output: '[1, 2, 3, 4]\n4\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把 ['a', 'b', 'c'] 变成流，收集后打印首元素。",
        hint: 'fromIterable 后 toList，取 first。',
        answer:
            "import 'dart:async';\n"
            "\n"
            "Future<void> main() async {\n"
            "  final list = await Stream<String>.fromIterable(\n"
            "    <String>['a', 'b', 'c'],\n"
            "  ).toList();\n"
            "  print(list.first);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 081：Stream 转列表',
    exampleSummary: 'fromIterable 构造流并用 toList 收集全部元素。',
  ),
  DartLesson(
    id: 'dart-lesson-082',
    chapter: 'async',
    level: 'advanced',
    title: '异步资源与 finally 清理',
    summary: '在 async 函数里用 try/finally 保证资源一定被释放。',
    concepts: <String>['try/finally', '异步清理', '资源释放'],
    explain:
        '异步代码同样需要可靠的资源清理：文件句柄、连接、锁都应在结束时释放。'
        'try/finally 保证无论 try 块是正常返回还是抛错，finally 都会执行；'
        '当 finally 里也涉及 await 时，请确保 finally 本身在 async 函数内。'
        '本课模拟"打开资源—处理出错—关闭资源"，外层再捕获错误，'
        '清晰看到清理先于错误外传。本课需要官方 Dart SDK。',
    objective: '能用 try/finally 在异步流程中保证清理逻辑必然执行。',
    prerequisites: <String>['已掌握异步异常与 finally', '官方 Dart SDK'],
    pitfalls: <String>[
      '把清理写在 try 末尾而非 finally，出错时会漏掉。',
      'finally 里再抛错会覆盖原异常，需谨慎处理。',
      'finally 中的 await 会延迟错误外传，行为仍正确但要心里有数。',
    ],
    code:
        "Future<void> withResource() async {\n"
        "  print('打开资源');\n"
        "  try {\n"
        "    await Future<void>.delayed(Duration.zero);\n"
        "    throw StateError('处理中出错');\n"
        "  } finally {\n"
        "    print('关闭资源');\n"
        "  }\n"
        "}\n"
        "\n"
        "Future<void> main() async {\n"
        "  try {\n"
        "    await withResource();\n"
        "  } on StateError catch (error) {\n"
        "    print('外层捕获：\${error.message}');\n"
        "  }\n"
        "}\n",
    output: '打开资源\n关闭资源\n外层捕获：处理中出错\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '改写为正常返回（不抛错），验证 finally 仍打印"关闭资源"。',
        hint: '删掉 throw，finally 依旧执行。',
        answer:
            "Future<void> main() async {\n"
            "  print('打开资源');\n"
            "  try {\n"
            "    await Future<void>.delayed(Duration.zero);\n"
            "    print('处理完成');\n"
            "  } finally {\n"
            "    print('关闭资源');\n"
            "  }\n"
            "}",
      ),
    ],
    exampleTitle: '示例 082：异步 finally 清理',
    exampleSummary: '异步流程抛错时，finally 仍保证资源被关闭。',
  ),
];
