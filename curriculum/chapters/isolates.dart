import '../dart_lesson.dart';

/// Chapter `isolates` — lessons 091-096. Owned by the second pi.
///
/// Export name: `isolateLessons`. Keep lessons sorted by id.
///
/// Every program here requires the official Dart SDK engine: `dart_eval` does
/// not implement `dart:isolate`. All computations are deterministic.
const List<DartLesson> isolateLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-091',
    chapter: 'isolates',
    level: 'advanced',
    title: 'Isolate.run 单次计算',
    summary: '把一段计算丢到独立隔离区执行，await 取回结果。',
    concepts: <String>['Isolate.run', '隔离区', '并行计算'],
    explain:
        'Dart 是单线程事件循环，密集计算会卡住界面。Isolate 是独立的执行单元，'
        '有自己的内存，不与主隔离区共享可变状态，因此能真正并行。Isolate.run 是'
        '最简单的入口：传入一个函数，它在新的隔离区里执行，返回一个 Future，'
        'await 即可拿到返回值。本课在隔离区里求 1 到 100 的和。'
        '注意隔离区不共享内存，参数和返回值必须可跨隔离区传递（可发送对象）。'
        '需要官方 Dart SDK 引擎，dart_eval 不支持 isolate。',
    objective: '能用 Isolate.run 在独立隔离区里完成一次计算并取回结果。',
    prerequisites: <String>['已掌握 Future 与 await', '官方 Dart SDK'],
    pitfalls: <String>[
      '隔离区不能访问主隔离区的全局/可变状态，闭包捕获的变量会被复制。',
      '闭包必须能发送，捕获不可发送对象（如打开的 Socket）会报错。',
      '启动隔离区有开销，超小任务不必用 isolate。',
    ],
    code: "import 'dart:isolate';\n"
        "\n"
        "Future<void> main() async {\n"
        "  final result = await Isolate.run(() {\n"
        "    var sum = 0;\n"
        "    for (var i = 1; i <= 100; i++) {\n"
        "      sum += i;\n"
        "    }\n"
        "    return sum;\n"
        "  });\n"
        "  print('1 到 100 的和 = \$result');\n"
        "}\n",
    output: '1 到 100 的和 = 5050\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用 Isolate.run 计算 1 到 10 的乘积并打印。',
        hint: '返回 product，初值 1。',
        answer: "import 'dart:isolate';\n"
            "\n"
            "Future<void> main() async {\n"
            "  final p = await Isolate.run(() {\n"
            "    var product = 1;\n"
            "    for (var i = 1; i <= 10; i++) {\n"
            "      product *= i;\n"
            "    }\n"
            "    return product;\n"
            "  });\n"
            "  print(p);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 091：Isolate.run 求和',
    exampleSummary: '在独立隔离区里求 1 到 100 的和并取回结果。',
  ),
  DartLesson(
    id: 'dart-lesson-092',
    chapter: 'isolates',
    level: 'advanced',
    title: '向隔离区传参与返回',
    summary: '把数据传进隔离区，并让它返回 Map 或记录。',
    concepts: <String>['跨隔离传参', '可发送对象', 'record 返回'],
    explain:
        'Isolate.run 的闭包可以直接捕获外部变量：这些值会被复制到新隔离区，'
        '所以隔离区里看到的是副本，改动不会影响主隔离区。返回值同样会被复制回来。'
        '可以返回 Map、List、String、数字，甚至 Dart 3 的记录。本课把配置 Map 传进去'
        '算乘积，再返回一个记录 (name, year) 并在主隔离区解构访问字段。'
        '这种"传数据进去、取结果回来"是最常见、最安全的并发模式。'
        '需要官方 Dart SDK 引擎。',
    objective: '能把数据传入隔离区并返回 Map/记录，从中取出结果。',
    prerequisites: <String>['已掌握 Isolate.run', '官方 Dart SDK'],
    pitfalls: <String>[
      '捕获的变量是副本，隔离区内的修改不会同步回主隔离区。',
      '不可发送对象（打开的文件、端口等）不能作为参数或返回值。',
      '返回的记录字段在接收端用命名访问，类型要保持一致。',
    ],
    code: "import 'dart:isolate';\n"
        "\n"
        "Future<void> main() async {\n"
        "  final config = <String, int>{'a': 2, 'b': 3};\n"
        "  final product = await Isolate.run(() {\n"
        "    return config['a']! * config['b']!;\n"
        "  });\n"
        "  print('乘积 \$product');\n"
        "\n"
        "  final record = await Isolate.run(() => (name: 'dart', year: 2011));\n"
        "  print('\${record.name} 诞生于 \${record.year}');\n"
        "}\n",
    output: '乘积 6\ndart 诞生于 2011\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '传一个 List<int> 进隔离区，返回它的元素个数。',
        hint: '捕获列表并在隔离区里 return values.length。',
        answer: "import 'dart:isolate';\n"
            "\n"
            "Future<void> main() async {\n"
            "  final values = <int>[5, 6, 7, 8];\n"
            "  final count = await Isolate.run(() => values.length);\n"
            "  print(count);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 092：传参与返回',
    exampleSummary: '把 Map 传入隔离区算乘积，并返回记录取字段。',
  ),
  DartLesson(
    id: 'dart-lesson-093',
    chapter: 'isolates',
    level: 'advanced',
    title: 'Isolate.spawn 与端口通信',
    summary: '用 SendPort/ReceivePort 让隔离区主动回发消息。',
    concepts: <String>['Isolate.spawn', 'SendPort', 'ReceivePort', 'send'],
    explain:
        'Isolate.run 适合一次性计算，但它内部替你管好了通信。要更灵活地控制'
        '隔离区的生命周期和消息流，用 Isolate.spawn：它启动一个长期运行的隔离区，'
        '入口函数接收一个 SendPort，用来把结果回发。主隔离区用 ReceivePort 接收。'
        '本课 spawn 一个 worker，worker 求和后通过端口 send 回来，主隔离区用 '
        'receive.first 拿到第一个消息。收完记得 close 端口。'
        '需要官方 Dart SDK 引擎。',
    objective: '能用 spawn + SendPort/ReceivePort 与隔离区双向通信。',
    prerequisites: <String>['已掌握 Isolate.run', '官方 Dart SDK'],
    pitfalls: <String>[
      'ReceivePort 不 close 会一直挂起，导致程序不退出。',
      'worker 入口函数必须是顶层或静态函数，不能是捕获了状态的实例方法。',
      '端口消息是异步的，first/await 之前不要遗漏 await。',
    ],
    code: "import 'dart:isolate';\n"
        "\n"
        "void worker(SendPort reply) {\n"
        "  var total = 0;\n"
        "  for (var i = 1; i <= 5; i++) {\n"
        "    total += i;\n"
        "  }\n"
        "  reply.send(total);\n"
        "}\n"
        "\n"
        "Future<void> main() async {\n"
        "  final receive = ReceivePort();\n"
        "  await Isolate.spawn(worker, receive.sendPort);\n"
        "  final value = await receive.first;\n"
        "  print('worker 返回 \$value');\n"
        "  receive.close();\n"
        "}\n",
    output: 'worker 返回 15\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '让 worker 回发两个消息（和与元素个数），主隔离区各取一个。',
        hint: 'reply.send(sum); reply.send(count); 再 await receive.first 两次。',
        answer: "import 'dart:isolate';\n"
            "\n"
            "void worker(SendPort reply) {\n"
            "  reply.send(1 + 2 + 3);\n"
            "  reply.send(3);\n"
            "}\n"
            "\n"
            "Future<void> main() async {\n"
            "  final rp = ReceivePort();\n"
            "  await Isolate.spawn(worker, rp.sendPort);\n"
            "  final it = StreamIterator<Object?>(rp);\n"
            "  await it.moveNext();\n"
            "  final sum = it.current;\n"
            "  await it.moveNext();\n"
            "  final count = it.current;\n"
            "  print('\$sum \$count');\n"
            "  await it.cancel();\n"
            "}",
      ),
    ],
    exampleTitle: '示例 093：spawn 与端口',
    exampleSummary: '用 Isolate.spawn 启动 worker，经 SendPort 回发结果。',
  ),
  DartLesson(
    id: 'dart-lesson-094',
    chapter: 'isolates',
    level: 'advanced',
    title: '多隔离区并行',
    summary: '用 Future.wait 同时跑多个 Isolate.run，聚合各自结果。',
    concepts: <String>['并行多个 isolate', 'Future.wait', '聚合'],
    explain:
        '多个隔离区可以同时工作。把每个 Isolate.run 的 Future 收集起来交给 '
        'Future.wait，就能并行执行并等全部完成。本课同时对 10、100、1000 求和，'
        '三条计算在不同隔离区里并行，结果按传入顺序返回 [55, 5050, 500500]，'
        '再求和验证。注意并行不是免费：隔离区创建有成本，任务足够大才划算。'
        '需要官方 Dart SDK 引擎。',
    objective: '能并发调度多个隔离区并聚合它们的结果。',
    prerequisites: <String>['已掌握 Isolate.run 与 Future.wait', '官方 Dart SDK'],
    pitfalls: <String>[
      '结果顺序是传入顺序，不是完成先后。',
      '任何一路失败都会让 Future.wait 整体失败。',
      '过度并行（远超 CPU 核数）反而因调度开销变慢。',
    ],
    code: "import 'dart:isolate';\n"
        "\n"
        "Future<int> sumTo(int n) {\n"
        "  return Isolate.run(() {\n"
        "    var sum = 0;\n"
        "    for (var i = 1; i <= n; i++) {\n"
        "      sum += i;\n"
        "    }\n"
        "    return sum;\n"
        "  });\n"
        "}\n"
        "\n"
        "Future<void> main() async {\n"
        "  final results = await Future.wait(<Future<int>>[sumTo(10), sumTo(100), sumTo(1000)]);\n"
        "  print(results);\n"
        "  print(results.reduce((a, b) => a + b));\n"
        "}\n",
    output: '[55, 5050, 500500]\n505605\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '并行计算 1 到 5 与 1 到 6 两段和，打印两项结果。',
        hint: 'Future.wait([sumTo(5), sumTo(6)])。',
        answer: "import 'dart:isolate';\n"
            "\n"
            "Future<int> sumTo(int n) => Isolate.run(() {\n"
            "  var s = 0;\n"
            "  for (var i = 1; i <= n; i++) {\n"
            "    s += i;\n"
            "  }\n"
            "  return s;\n"
            "});\n"
            "\n"
            "Future<void> main() async {\n"
            "  print(await Future.wait(<Future<int>>[sumTo(5), sumTo(6)]));\n"
            "}",
      ),
    ],
    exampleTitle: '示例 094：多隔离区并行',
    exampleSummary: '并发跑三个隔离区求和并按传入顺序聚合结果。',
  ),
  DartLesson(
    id: 'dart-lesson-095',
    chapter: 'isolates',
    level: 'advanced',
    title: '隔离区内的异常传播',
    summary: '隔离区里抛出的错误会经由 Isolate.run 的 Future 传给主隔离区。',
    concepts: <String>['异常传播', 'Isolate.run', 'try-catch'],
    explain:
        '隔离区里未捕获的错误不会让整个程序崩溃，而是变成 Isolate.run 返回 Future 的'
        '错误，主隔离区用 try/catch 就能捕获——错误信息也会一起传回来。这让你能'
        '像处理普通异步错误一样处理隔离区内的失败。本课先在隔离区抛 StateError 并'
        '捕获，再跑一个正常任务验证后续流程不受影响。'
        '需要官方 Dart SDK 引擎。',
    objective: '能捕获隔离区内传播出来的异常，并继续执行后续任务。',
    prerequisites: <String>['已掌握 Isolate.run 与异步异常', '官方 Dart SDK'],
    pitfalls: <String>[
      '错误对象也要能跨隔离区发送，自定义异常需满足可发送条件。',
      '未捕获的隔离区错误若没人 await，可能成为未处理异常。',
      '异常传播后隔离区即结束，不会继续执行剩余代码。',
    ],
    code: "import 'dart:isolate';\n"
        "\n"
        "Future<void> main() async {\n"
        "  try {\n"
        "    await Isolate.run(() => throw StateError('隔离区里出错'));\n"
        "  } on StateError catch (error) {\n"
        "    print('主隔离区捕获：\${error.message}');\n"
        "  }\n"
        "  final ok = await Isolate.run(() => '一切正常');\n"
        "  print(ok);\n"
        "}\n",
    output: '主隔离区捕获：隔离区里出错\n一切正常\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '在隔离区里对 int.parse("x") 触发 FormatException 并在主隔离区捕获 message。',
        hint: 'on FormatException catch (e) => print(e.message)。',
        answer: "import 'dart:isolate';\n"
            "\n"
            "Future<void> main() async {\n"
            "  try {\n"
            "    await Isolate.run(() => int.parse('x'));\n"
            "  } on FormatException catch (e) {\n"
            "    print(e.message);\n"
            "  }\n"
            "}",
      ),
    ],
    exampleTitle: '示例 095：隔离区异常传播',
    exampleSummary: '隔离区抛错被主隔离区捕获，之后正常任务继续。',
  ),
  DartLesson(
    id: 'dart-lesson-096',
    chapter: 'isolates',
    level: 'advanced',
    title: '分工计算与结果合并',
    summary: '把不同计算分派到不同隔离区，再合并它们的结果。',
    concepts: <String>['任务分工', '并行合并', 'reduce'],
    explain:
        '真实场景常把一个大任务拆成互相独立的小任务并行处理（分治）。本课把'
        '"求和"和"求最大值"分派到两个隔离区，各自独立计算，再用 Future.wait 收集、'
        '合并成一句结论。这种"分工—并行—合并"模式适合统计、图像处理等可拆分的工作。'
        '要点是子任务之间不共享状态，因此天然避免竞态。'
        '需要官方 Dart SDK 引擎。',
    objective: '能把独立子任务分派到不同隔离区并合并结果。',
    prerequisites: <String>['已掌握多隔离区并行', '官方 Dart SDK'],
    pitfalls: <String>[
      '子任务若有依赖关系就不能盲目并行，需按序执行。',
      '合并时注意各结果在列表中的固定位置，别错位。',
      '每个隔离区各自复制数据，大对象会带来内存开销。',
    ],
    code: "import 'dart:isolate';\n"
        "\n"
        "Future<void> main() async {\n"
        "  final sum = Isolate.run(() {\n"
        "    var s = 0;\n"
        "    for (final v in <int>[4, 8, 15, 16]) {\n"
        "      s += v;\n"
        "    }\n"
        "    return s;\n"
        "  });\n"
        "  final max = Isolate.run(() {\n"
        "    final values = <int>[4, 8, 15, 16];\n"
        "    return values.reduce((a, b) => a > b ? a : b);\n"
        "  });\n"
        "  final results = await Future.wait(<Future<int>>[sum, max]);\n"
        "  print('和 \${results[0]}，最大值 \${results[1]}');\n"
        "}\n",
    output: '和 43，最大值 16\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '再加一个隔离区求这段数据的平均值（取整），合并打印三项。',
        hint: '返回 sum ~/ length，追加到 Future.wait 列表。',
        answer: "import 'dart:isolate';\n"
            "\n"
            "Future<void> main() async {\n"
            "  final values = <int>[4, 8, 15, 16];\n"
            "  final avg = Isolate.run(() =>\n"
            "      values.reduce((a, b) => a + b) ~/ values.length);\n"
            "  print(await avg);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 096：分工与合并',
    exampleSummary: '两个隔离区分别求和与求最大值，再合并输出。',
  ),
];
