import '../dart_lesson.dart';

/// Chapter `streams` — lessons 083-090. Owned by the second pi.
///
/// Export name: `streamsLessons`. Keep lessons sorted by id.
///
/// All programs use `dart:async` streams and require the official Dart SDK
/// engine. Emissions are synchronous or pinned to `Duration.zero`, so the
/// collected output is deterministic.
const List<DartLesson> streamsLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-083',
    chapter: 'streams',
    level: 'advanced',
    title: 'Stream 与 await for',
    summary: '用 await for 逐个消费流中的值，边到达边处理。',
    concepts: <String>['Stream', 'await for', '逐个消费'],
    explain:
        'Stream 表示"一串将来陆续到达的值"。await for 是消费流最直观的方式：'
        '每来一个元素，循环体执行一次，直到流关闭。它像普通 for-in，但每个元素可能'
        '来自异步。与 toList 一次性收集不同，await for 适合边到达边处理（累加、'
        '写日志、更新界面）。注意 await for 会一直消费到流结束，遇到无限流要主动'
        'break。本课需要官方 Dart SDK 引擎。',
    objective: '能用 await for 遍历流并累积结果。',
    prerequisites: <String>['已掌握 Future 与 await', '官方 Dart SDK'],
    pitfalls: <String>[
      'await for 会一直消费到流关闭，对无限流必须用 break 退出。',
      '在 await for 里 await 别的异步操作会短暂暂停消费，注意背压。',
      '忘记 await for 前加 await 关键字会语法错误，它是 await 加 for。',
    ],
    code: "import 'dart:async';\n"
        "\n"
        "Future<void> main() async {\n"
        "  final stream = Stream<int>.fromIterable(<int>[1, 2, 3, 4, 5]);\n"
        "  var sum = 0;\n"
        "  await for (final value in stream) {\n"
        "    sum += value;\n"
        "  }\n"
        "  print('总和 \$sum');\n"
        "}\n",
    output: '总和 15\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用 await for 统计 [2, 4, 6, 7] 中偶数的个数。',
        hint: '循环体内 if (v.isEven) count++。',
        answer: "import 'dart:async';\n"
            "\n"
            "Future<void> main() async {\n"
            "  var count = 0;\n"
            "  await for (final v in Stream<int>.fromIterable(<int>[2, 4, 6, 7])) {\n"
            "    if (v.isEven) count++;\n"
            "  }\n"
            "  print(count);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 083：await for 求和',
    exampleSummary: '用 await for 逐个消费流元素并累加。',
  ),
  DartLesson(
    id: 'dart-lesson-084',
    chapter: 'streams',
    level: 'advanced',
    title: '流的 map 与 where',
    summary: '对流做过滤和映射，先筛再变，最后收集。',
    concepts: <String>['Stream.map', 'Stream.where', '链式'],
    explain:
        '流支持与 Iterable 类似的变换操作：where 只放行满足条件的元素，map 把每个'
        '元素变成新值，二者可链式组合。它们都是惰性的——只有被消费（toList、await for）'
        '时才真正驱动。本课先 where 取出偶数，再 map 求平方，得到与原列表不同的结果。'
        '注意流的变换顺序影响结果：先筛后算更省事。本课需要官方 Dart SDK 引擎。',
    objective: '能组合 where 与 map 对流做过滤和变换。',
    prerequisites: <String>['已掌握 Stream 与 await for', '官方 Dart SDK'],
    pitfalls: <String>[
      '变换是惰性的，不消费则不会执行任何回调。',
      'map 返回的新流元素类型可不同，注意泛型推断。',
      '把 where 写在 map 之后会多算一些最终被丢弃的值。',
    ],
    code: "import 'dart:async';\n"
        "\n"
        "Future<void> main() async {\n"
        "  final result = await Stream<int>.fromIterable(<int>[1, 2, 3, 4, 5, 6])\n"
        "      .where((v) => v.isEven)\n"
        "      .map((v) => v * v)\n"
        "      .toList();\n"
        "  print(result);\n"
        "}\n",
    output: '[4, 16, 36]\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '把 [1..6] 里的奇数加 10，收集结果。',
        hint: 'where((v) => v.isOdd).map((v) => v + 10)。',
        answer: "import 'dart:async';\n"
            "\n"
            "Future<void> main() async {\n"
            "  final r = await Stream<int>.fromIterable(<int>[1, 2, 3, 4, 5, 6])\n"
            "      .where((v) => v.isOdd)\n"
            "      .map((v) => v + 10)\n"
            "      .toList();\n"
            "  print(r);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 084：流的 map 与 where',
    exampleSummary: '用 where 过滤偶数再 map 求平方。',
  ),
  DartLesson(
    id: 'dart-lesson-085',
    chapter: 'streams',
    level: 'advanced',
    title: 'StreamController 手动推送',
    summary: '用 StreamController 手动 add 数据、close 结束，并收集结果。',
    concepts: <String>['StreamController', 'add', 'close', '单订阅'],
    explain:
        '有时数据来源不是现成集合，而是你自己产生的（用户事件、定时器、回调）。'
        'StreamController 让你手动往流里 add 元素，处理完后 close 关闭流。'
        'controller.stream 是供消费的一端。切记：close 之后不能再 add，否则报错；'
        '单订阅流只能被消费一次。本课先启动收集，再推送三个值并关闭。'
        '需要官方 Dart SDK 引擎。',
    objective: '能用 StreamController 手动生产数据并正确关闭。',
    prerequisites: <String>['已掌握 Stream 消费', '官方 Dart SDK'],
    pitfalls: <String>[
      'close 之后再 add 会抛 StateError。',
      '单订阅流被消费一次后再 listen 会报 "already listened"。',
      '忘记 close 会让 toList/await for 永远等待。',
    ],
    code: "import 'dart:async';\n"
        "\n"
        "Future<void> main() async {\n"
        "  final controller = StreamController<int>();\n"
        "  final collected = controller.stream.toList();\n"
        "  controller.add(10);\n"
        "  controller.add(20);\n"
        "  controller.add(30);\n"
        "  await controller.close();\n"
        "  print(await collected);\n"
        "}\n",
    output: '[10, 20, 30]\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用 StreamController 推送 "a"、"b" 并 close，收集后打印。',
        hint: '把类型换成 String，其余结构不变。',
        answer: "import 'dart:async';\n"
            "\n"
            "Future<void> main() async {\n"
            "  final c = StreamController<String>();\n"
            "  final f = c.stream.toList();\n"
            "  c.add('a');\n"
            "  c.add('b');\n"
            "  await c.close();\n"
            "  print(await f);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 085：StreamController',
    exampleSummary: '手动 add 三个值并 close，收集成列表。',
  ),
  DartLesson(
    id: 'dart-lesson-086',
    chapter: 'streams',
    level: 'advanced',
    title: '广播流 broadcast',
    summary: '用 broadcast 让多个订阅者同时收到同一批事件。',
    concepts: <String>['broadcast', '多订阅者', '事件广播'],
    explain:
        '默认的流是单订阅：只能有一个消费者。broadcast 流则允许多个订阅者，'
        '每个事件会被分发给所有当前订阅者，常用于"一处产生、多处观察"的场景'
        '（如同一个状态同时驱动界面和数据统计）。注意广播流不缓存历史事件：'
        '订阅之前发出的事件收不到；本课先订阅再推送，保证两个订阅者都能收到。'
        '需要官方 Dart SDK 引擎。',
    objective: '能创建广播流并让两个订阅者接收到相同事件。',
    prerequisites: <String>['已掌握 StreamController', '官方 Dart SDK'],
    pitfalls: <String>[
      '广播流不重放历史事件，订阅晚就收不到早期数据。',
      '没有订阅者时广播的事件会被直接丢弃。',
      'await controller.close 后要再等一拍，确保订阅回调已执行。',
    ],
    code: "import 'dart:async';\n"
        "\n"
        "Future<void> main() async {\n"
        "  final controller = StreamController<int>.broadcast();\n"
        "  final first = <int>[];\n"
        "  final second = <int>[];\n"
        "  controller.stream.listen(first.add);\n"
        "  controller.stream.listen(second.add);\n"
        "  controller.add(1);\n"
        "  controller.add(2);\n"
        "  await controller.close();\n"
        "  await Future<void>.delayed(Duration.zero);\n"
        "  print('第一个订阅者: \$first');\n"
        "  print('第二个订阅者: \$second');\n"
        "}\n",
    output: '第一个订阅者: [1, 2]\n第二个订阅者: [1, 2]\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '给广播流加第三个订阅者，验证它也收到 [1, 2]。',
        hint: '再写一行 controller.stream.listen(third.add)。',
        answer: "import 'dart:async';\n"
            "\n"
            "Future<void> main() async {\n"
            "  final c = StreamController<int>.broadcast();\n"
            "  final third = <int>[];\n"
            "  c.stream.listen(third.add);\n"
            "  c.add(1);\n"
            "  c.add(2);\n"
            "  await c.close();\n"
            "  await Future<void>.delayed(Duration.zero);\n"
            "  print(third);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 086：广播流',
    exampleSummary: 'broadcast 流下两个订阅者收到相同事件序列。',
  ),
  DartLesson(
    id: 'dart-lesson-087',
    chapter: 'streams',
    level: 'advanced',
    title: '流中的错误处理',
    summary: '用 handleError 捕获流内错误，流继续处理后续元素。',
    concepts: <String>['handleError', '流内错误', 'asyncExpand'],
    explain:
        '流不仅能发出数据，也能发出错误。默认情况下，流中一旦出错会中断该订阅。'
        'handleError 注册一个错误回调，把错误接住并继续消费后面的元素，'
        '非常适合"部分失败仍要处理其余数据"的场景。本课用 asyncExpand 把一个元素'
        '展开成"值流"或"错误流"，再 handleError 捕获坏值，最终按顺序记录值 1、'
        '错误、值 3。需要官方 Dart SDK 引擎。',
    objective: '能用 handleError 捕获流内错误并让流继续。',
    prerequisites: <String>['已掌握流变换与异常', '官方 Dart SDK'],
    pitfalls: <String>[
      'handleError 的回调返回类型要与流元素兼容（或为 void）。',
      '不注册 handleError 时，错误会走订阅的 onError 或变成未捕获异常。',
      '错误后的元素是否继续取决于错误处理方式，默认单订阅流会终止。',
    ],
    code: "import 'dart:async';\n"
        "\n"
        "Future<void> main() async {\n"
        "  final events = <String>[];\n"
        "  final stream = Stream<int>.fromIterable(<int>[1, 2, 3]).asyncExpand(\n"
        "    (v) => v == 2\n"
        "        ? Stream<int>.error(StateError('坏值 \$v'))\n"
        "        : Stream<int>.value(v),\n"
        "  );\n"
        "  await stream.handleError((Object error) {\n"
        "    events.add('错误：\${(error as StateError).message}');\n"
        "  }).forEach((v) => events.add('值 \$v'));\n"
        "  print(events);\n"
        "}\n",
    output: '[值 1, 错误：坏值 2, 值 3]\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '把坏值换成 3，观察错误在哪个位置被记录。',
        hint: '条件改为 v == 3，其余不变。',
        answer: "import 'dart:async';\n"
            "\n"
            "Future<void> main() async {\n"
            "  final events = <String>[];\n"
            "  final s = Stream<int>.fromIterable(<int>[1, 2, 3]).asyncExpand(\n"
            "    (v) => v == 3 ? Stream<int>.error(StateError('坏 \$v')) : Stream<int>.value(v),\n"
            "  );\n"
            "  await s.handleError((Object e) {\n"
            "    events.add((e as StateError).message);\n"
            "  }).forEach((v) => events.add('\$v'));\n"
            "  print(events);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 087：流内错误处理',
    exampleSummary: 'handleError 捕获流中间的错误并继续处理后续元素。',
  ),
  DartLesson(
    id: 'dart-lesson-088',
    chapter: 'streams',
    level: 'advanced',
    title: 'asyncMap 异步变换',
    summary: '用 asyncMap 对每个元素执行一个异步函数并按序收集结果。',
    concepts: <String>['asyncMap', '异步变换', '顺序保持'],
    explain:
        'map 的变换是同步的；当每个元素都要"异步处理"（查库、请求、读文件）时，'
        '用 asyncMap。它接收一个返回 Future 的函数，逐个等待完成，并保持元素顺序。'
        '注意 asyncMap 默认是串行的：一个元素处理完才处理下一个，这保证了顺序，'
        '但也意味着总耗时是各段之和。本课把每个值异步翻倍后收集为 [2, 4, 6]。'
        '需要官方 Dart SDK 引擎。',
    objective: '能用 asyncMap 对流元素做异步变换并保序收集。',
    prerequisites: <String>['已掌握 map 与异步函数', '官方 Dart SDK'],
    pitfalls: <String>[
      'asyncMap 逐个等待，天然串行；要并发需另用 Future.wait。',
      '变换函数必须返回 Future，否则用 map 即可。',
      '某个元素异步失败会中断整个流，需要错误处理兜底。',
    ],
    code: "import 'dart:async';\n"
        "\n"
        "Future<int> doubleIt(int v) async {\n"
        "  await Future<void>.delayed(Duration.zero);\n"
        "  return v * 2;\n"
        "}\n"
        "\n"
        "Future<void> main() async {\n"
        "  final result = await Stream<int>.fromIterable(<int>[1, 2, 3])\n"
        "      .asyncMap(doubleIt)\n"
        "      .toList();\n"
        "  print(result);\n"
        "}\n",
    output: '[2, 4, 6]\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用 asyncMap 给每个元素异步加前缀 "n="，收集字符串列表。',
        hint: "返回 Future<String>，如 async => 'n=\$v'。",
        answer: "import 'dart:async';\n"
            "\n"
            "Future<void> main() async {\n"
            "  final r = await Stream<int>.fromIterable(<int>[1, 2])\n"
            "      .asyncMap((v) async => 'n=\$v')\n"
            "      .toList();\n"
            "  print(r);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 088：asyncMap',
    exampleSummary: '对每个流元素执行异步变换并按原顺序收集。',
  ),
  DartLesson(
    id: 'dart-lesson-089',
    chapter: 'streams',
    level: 'advanced',
    title: '流聚合 fold',
    summary: '用 fold 把整条流归约成一个累积结果。',
    concepts: <String>['fold', '归约', '累积器'],
    explain:
        'fold 接收一个初始值和一个"累积器"函数 (acc, element)，把流中每个元素依次'
        '并入累积值，最终返回单个结果。它适合求和、计数、拼接字符串等"把一串值压成'
        '一个值"的需求。与 reduce 不同，fold 允许显式给出初始值，因此空流也能安全返回'
        '初始值，类型也更灵活。本课分别用 fold 对整数求和、对字符串拼接。'
        '需要官方 Dart SDK 引擎。',
    objective: '能用 fold 对流做求和与字符串拼接两种归约。',
    prerequisites: <String>['已掌握流消费与闭包', '官方 Dart SDK'],
    pitfalls: <String>[
      'fold 的初始值类型决定结果类型，泛型写错会编译失败。',
      '累积器每次都要返回新值，返回 null 会导致后续计算失败。',
      'reduce 无初始值，空流会抛错；要处理空流请用 fold。',
    ],
    code: "import 'dart:async';\n"
        "\n"
        "Future<void> main() async {\n"
        "  final total = await Stream<int>.fromIterable(<int>[1, 2, 3, 4]).fold(\n"
        "    0,\n"
        "    (sum, v) => sum + v,\n"
        "  );\n"
        "  print('fold 求和 \$total');\n"
        "  final joined = await Stream<String>.fromIterable(<String>['a', 'b', 'c'])\n"
        "      .fold<String>('', (acc, v) => acc + v);\n"
        "  print('拼接 \$joined');\n"
        "}\n",
    output: 'fold 求和 10\n拼接 abc\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用 fold 计算 [2, 3, 4] 的乘积。',
        hint: '初始值 1，累积器用 *。',
        answer: "import 'dart:async';\n"
            "\n"
            "Future<void> main() async {\n"
            "  final p = await Stream<int>.fromIterable(<int>[2, 3, 4])\n"
            "      .fold(1, (a, b) => a * b);\n"
            "  print(p);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 089：fold 归约',
    exampleSummary: '用 fold 对整数求和、对字符串拼接。',
  ),
  DartLesson(
    id: 'dart-lesson-090',
    chapter: 'streams',
    level: 'advanced',
    title: '订阅取消 cancel',
    summary: '用 StreamSubscription.cancel 停止接收事件。',
    concepts: <String>['listen', 'StreamSubscription', 'cancel'],
    explain:
        'listen 返回一个 StreamSubscription，代表这次订阅。调用它的 cancel() 就能'
        '停止接收后续事件，这对"满足条件后不再关心"或"页面销毁时取消"至关重要，'
        '否则可能造成内存泄漏或对已销毁对象操作。本课订阅后收到 1、2，'
        '在推送 3 之前取消订阅，因此 3 不会被接收。取消是异步的，'
        '等它完成后再推送更稳妥。需要官方 Dart SDK 引擎。',
    objective: '能用 StreamSubscription 取消订阅并验证后续事件不再到达。',
    prerequisites: <String>['已掌握 listen 与 StreamController', '官方 Dart SDK'],
    pitfalls: <String>[
      'cancel 是异步的，取消前已排队的事件可能仍会到达。',
      '不取消长期订阅会导致监听器泄漏。',
      '取消后 controller 仍可 add，但该订阅不再收到。',
    ],
    code: "import 'dart:async';\n"
        "\n"
        "Future<void> main() async {\n"
        "  final controller = StreamController<int>();\n"
        "  final received = <int>[];\n"
        "  final sub = controller.stream.listen(received.add);\n"
        "  controller.add(1);\n"
        "  controller.add(2);\n"
        "  await Future<void>.delayed(Duration.zero);\n"
        "  await sub.cancel();\n"
        "  controller.add(3);\n"
        "  await controller.close();\n"
        "  print('收到 \$received');\n"
        "}\n",
    output: '收到 [1, 2]\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '在收到第一个元素后立即取消订阅，验证只收到 [1]。',
        hint: 'listen 回调里判断 received.length == 1 时 sub.cancel()。',
        answer: "import 'dart:async';\n"
            "\n"
            "Future<void> main() async {\n"
            "  final c = StreamController<int>();\n"
            "  final got = <int>[];\n"
            "  late StreamSubscription<int> sub;\n"
            "  sub = c.stream.listen((v) {\n"
            "    got.add(v);\n"
            "    if (got.length == 1) sub.cancel();\n"
            "  });\n"
            "  c.add(1);\n"
            "  c.add(2);\n"
            "  await c.close();\n"
            "  await Future<void>.delayed(Duration.zero);\n"
            "  print(got);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 090：取消订阅',
    exampleSummary: '收到两个事件后取消订阅，后续事件不再到达。',
  ),
];
