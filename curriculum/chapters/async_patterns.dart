import '../dart_lesson.dart';

/// Chapter `async-patterns` — independently executed lessons and paired examples.
const List<DartLesson> asyncPatternsLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-273',
    chapter: "async-patterns",
    level: "intermediate",
    title: "await 保证阶段顺序",
    summary: "用真实延迟 Future 观察开始、等待和完成三个阶段。",
    concepts: <String>["Future.delayed", "await", "事件循环"],
    explain:
        "异步函数遇到 await 时会把后续步骤挂起。它一直等到目标 Future 完成。其他可运行工作仍可以继续。程序先启动一个带延迟的阶段，再在调用处记录已启动，最后等待该阶段完成。输出中的顺序来自真正的 Future 和事件调度，而不是预先打印一张模拟日志。延迟只用于提供明确的等待点，示例不比较实际毫秒数，避免机器负载影响教学结果。异步不等于创建新线程，耗时同步计算仍会阻塞当前 isolate。需要并行 CPU 任务时应考虑真实 isolate，而不是简单给函数添加 async。",
    objective: "能从真实运行顺序理解 async 函数在第一个 await 前后的行为。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "调用异步函数会先运行到第一个等待点，并非整个函数都延后运行。",
      "Future.delayed 不会把同步计算自动搬到后台线程。",
    ],
    code: r'''
import 'dart:async';
Future<void> stage() async {
  print('阶段开始');
  await Future<void>.delayed(const Duration(milliseconds: 2));
  print('阶段结束');
}
Future<void> main() async {
  final running = stage();
  print('调用方继续');
  await running;
  print('全部完成');
}
''',
    output: "阶段开始\n调用方继续\n阶段结束\n全部完成\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把两个异步阶段串行运行。验证第二阶段只能在第一阶段完成后开始。",
        hint: "每次调用后都 await，不要只保存两个 Future 再一起等待。",
        answer: r'''
import 'dart:async';
Future<void> stage(String name) async {
  print('$name 开始');
  await Future<void>.delayed(Duration.zero);
  print('$name 结束');
}
Future<void> main() async { await stage('A'); await stage('B'); }
''',
      ),
    ],
    exampleTitle: "示例 273：await 保证阶段顺序",
    exampleSummary: "用真实延迟 Future 观察开始、等待和完成三个阶段。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-274',
    chapter: "async-patterns",
    level: "intermediate",
    title: "异步数据转换流水线",
    summary: "每一步等待前一步结果，把解析、计算与格式化组合为一条管线。",
    concepts: <String>["Future 返回值", "依赖顺序", "函数组合"],
    explain:
        "数据流水线中的步骤往往存在依赖：没有解析结果就不能计算，没有计算结果就不能格式化。程序把三个阶段分别写成返回 Future 的函数，在 main 中逐步 await，并把得到的值传给下一阶段。每个阶段都包含真实异步等待点，使失败也会沿着等待链向上传播。局部变量保留中间结果，便于定位问题，而不是把整个处理塞进一条很长的表达式。示例使用固定文本和纯计算，不依赖网络或文件。若两个步骤互不依赖，可以另外考虑并发。依赖关系明确的步骤不能为了看起来更快而盲目同时启动。",
    objective: "能把有依赖关系的异步步骤连接起来，并保留清楚的数据流。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["把 Future 当成已完成的值传递，会丢失等待关系。", "只有互不依赖的阶段才适合同时启动。"],
    code: r'''
import 'dart:async';
Future<int> parseQuantity(String text) async {
  await Future<void>.delayed(Duration.zero);
  return int.parse(text);
}
Future<int> subtotal(int quantity) async {
  await Future<void>.delayed(Duration.zero);
  return quantity * 125;
}
Future<String> receipt(int cents) async {
  await Future<void>.delayed(Duration.zero);
  return '合计$cents分';
}
Future<void> main() async {
  final quantity = await parseQuantity('4');
  final amount = await subtotal(quantity);
  print(await receipt(amount));
}
''',
    output: "合计500分\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "增加数量非负检查，让无效数据在计算阶段之前失败。",
        hint: "解析后立即检查范围。使用 try/await/catch 验证错误。",
        answer: r'''
import 'dart:async';
Future<int> checked(String text) async {
  await Future<void>.delayed(Duration.zero);
  final value = int.parse(text);
  if (value < 0) throw FormatException('数量不能为负');
  return value;
}
Future<void> main() async {
  try { print(await checked('-2')); } on FormatException { print('数量无效'); }
}
''',
      ),
    ],
    exampleTitle: "示例 274：异步数据转换流水线",
    exampleSummary: "每一步等待前一步结果，把解析、计算与格式化组合为一条管线。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-275',
    chapter: "async-patterns",
    level: "intermediate",
    title: "异步循环保持逐项依赖",
    summary: "在 for 循环中等待每次读取，依次更新累计结果。",
    concepts: <String>["for 与 await", "累积状态", "串行语义"],
    explain:
        "有些任务必须按顺序处理，例如前一笔余额影响后一笔是否允许运行。程序在普通 for 循环里 await 每次异步读取，拿到数值后立即更新合计并输出中间状态。下一轮只有在这一轮完成之后才会开始，因此日志顺序稳定。示例的读取函数用零时长延迟创建真正的异步边界，不是返回预先打印的结果。不要用 Iterable.forEach 配合 async 回调来代替这种循环，因为 forEach 不会收集并等待回调返回的 Future。若任务之间没有依赖，可以选择批量并发，但那会改变运行和错误传播规则。",
    objective: "能在需要顺序和中间状态时选择普通 for/await 循环。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "forEach 的 async 回调不会让外层函数自动等待。",
      "把所有读取先启动再逐个 await，会改变启动顺序。",
    ],
    code: r'''
import 'dart:async';
Future<int> readValue(int id) async {
  await Future<void>.delayed(Duration.zero);
  return id * id;
}
Future<void> main() async {
  var sum = 0;
  for (final id in [1, 2, 3]) {
    sum += await readValue(id);
    print('处理$id 累计$sum');
  }
  print('最终$sum');
}
''',
    output: "处理1 累计1\n处理2 累计5\n处理3 累计14\n最终14\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "遇到读取值超过五时停止循环。再打印已经累计的总数。",
        hint: "await 得到值后先判断是否 break。再更新总数。",
        answer: r'''
import 'dart:async';
Future<int> load(int id) async { await Future<void>.delayed(Duration.zero); return id * id; }
Future<void> main() async {
  var sum = 0;
  for (final id in [1, 2, 3, 4]) {
    final value = await load(id);
    if (value > 5) break;
    sum += value;
  }
  print(sum);
}
''',
      ),
    ],
    exampleTitle: "示例 275：异步循环保持逐项依赖",
    exampleSummary: "在 for 循环中等待每次读取，依次更新累计结果。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-276',
    chapter: "async-patterns",
    level: "intermediate",
    title: "批内并发与批间等待",
    summary: "使用 Future.wait 并发处理有限批次，等待一批完成后再启动下一批。",
    concepts: <String>["Future.wait", "批量边界", "并发上限"],
    explain:
        "一次启动所有异步任务可能占用过多资源，而完全串行又不能利用独立任务的等待时间。程序把任务编号分成大小为二的批次。程序在批内构造多个 Future。程序用 Future.wait 等待全部完成，再处理下一批。返回列表保持输入 Future 的顺序，不要求任务按同样顺序完成。打印发生在整批结束之后，因此结果可重复，也不会用日志顺序冒充完成顺序。该结构把同时运行的任务数限制在批大小以内。但它不是持续填补空位的工作池。某个批内慢任务仍会让下一批等待。",
    objective: "能实现真实有限批次并发，并说明批处理与工作池的差异。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "必须在进入下一批之前 await 当前 Future.wait。",
      "Future.wait 的结果顺序与完成先后没有必然关系。",
    ],
    code: r'''
import 'dart:async';
Future<int> square(int value) async {
  await Future<void>.delayed(const Duration(milliseconds: 1));
  return value * value;
}
Future<void> main() async {
  final ids = [1, 2, 3, 4, 5];
  const size = 2;
  for (var start = 0; start < ids.length; start += size) {
    final end = start + size < ids.length ? start + size : ids.length;
    final jobs = <Future<int>>[];
    for (final id in ids.sublist(start, end)) jobs.add(square(id));
    final values = await Future.wait(jobs);
    print('批${start ~/ size + 1}:$values');
  }
}
''',
    output: "批1:[1, 4]\n批2:[9, 16]\n批3:[25]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "将批大小改为三。再输出每批处理的编号列表。",
        hint: "尾批结束位置仍需裁剪到总长度。",
        answer: r'''
import 'dart:async';
Future<int> work(int n) async { await Future<void>.delayed(Duration.zero); return n; }
Future<void> main() async {
  final ids = [1, 2, 3, 4, 5];
  for (var start = 0; start < ids.length; start += 3) {
    final end = start + 3 < ids.length ? start + 3 : ids.length;
    print(await Future.wait(ids.sublist(start, end).map(work)));
  }
}
''',
      ),
    ],
    exampleTitle: "示例 276：批内并发与批间等待",
    exampleSummary: "使用 Future.wait 并发处理有限批次，等待一批完成后再启动下一批。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-277',
    chapter: "async-patterns",
    level: "intermediate",
    title: "跨 await 的有界重试",
    summary: "真实捕获异步失败，等待后重试并限制最大尝试次数。",
    concepts: <String>["异步异常", "重试上限", "rethrow"],
    explain:
        "重试必须发生在真实失败之后，而不是用同步计数打印一串重试标签。程序的任务先经过异步等待，前两次实际抛出异常，第三次才返回成功。重试函数在 try 中 await 任务，catch 中检查是否达到上限，未达到时等待一个异步间隔再继续。达到上限使用 rethrow 保留最后一次失败，让调用者知道最终没有完成。示例固定失败次数以获得可重复输出，不联网也不访问外部服务。实际业务只应重试明确可恢复且具有幂等保障的操作。参数错误或重复扣款等情况不能盲目自动重试。",
    objective: "能捕获等待点之后的错误，并运行有上限的真实异步重试。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "忘记 await 会让 try/catch 错过稍后发生的失败。",
      "所有异常都重试可能放大不可恢复错误或重复副作用。",
    ],
    code: r'''
import 'dart:async';
var calls = 0;
Future<String> flaky() async {
  await Future<void>.delayed(Duration.zero);
  calls++;
  if (calls < 3) throw StateError('暂未准备好');
  return 'ready';
}
Future<String> retry(Future<String> Function() task, int maximum) async {
  if (maximum < 1) throw ArgumentError('尝试次数');
  for (var attempt = 1; attempt <= maximum; attempt++) {
    try { return await task(); } catch (error) {
      print('失败$attempt');
      if (attempt == maximum) rethrow;
      await Future<void>.delayed(Duration.zero);
    }
  }
  throw StateError('不可到达');
}
Future<void> main() async { print(await retry(flaky, 3)); print('调用$calls次'); }
''',
    output: "失败1\n失败2\nready\n调用3次\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "让任务始终失败，验证达到两次上限后把错误交给外层处理。",
        hint: "每次必须 await 真实任务。最后一次失败不要继续循环。",
        answer: r'''
import 'dart:async';
Future<void> fail() async { await Future<void>.delayed(Duration.zero); throw StateError('失败'); }
Future<void> main() async {
  var attempts = 0;
  try {
    while (true) {
      attempts++;
      try { await fail(); break; } catch (e) { if (attempts >= 2) rethrow; }
    }
  } on StateError { print('最终失败:$attempts'); }
}
''',
      ),
    ],
    exampleTitle: "示例 277：跨 await 的有界重试",
    exampleSummary: "真实捕获异步失败，等待后重试并限制最大尝试次数。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-278',
    chapter: "async-patterns",
    level: "advanced",
    title: "真正超时与原任务生命周期",
    summary: "用 Future.timeout 限制等待，并证明超时不会自动取消原 Future。",
    concepts: <String>["Future.timeout", "TimeoutException", "任务生命周期"],
    explain:
        "等待超时与任务取消是两件不同的事。程序启动一个真实延迟完成的操作，对它应用较短的 timeout，并捕获实际的 TimeoutException。随后再次等待原始 Future，得到正常结果，证明超时包装没有把底层操作中断。示例不通过计数阈值假装经过了时间。它也不比较精确耗时。长短等待间隔拉开，以降低调度负载对演示的影响。实际项目若超时后需要停止文件读取或子任务，必须使用该资源提供的取消机制。同时必须确保清理完成。仅仅忽略超时后的结果可能仍然留下后台副作用。",
    objective: "能区分等待期限与取消，并正确观察超时后的原任务。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "Future.timeout 只改变返回的等待结果，不自动停止底层工作。",
      "不要通过输出预期错误文本冒充真正触发的超时。",
    ],
    code: r'''
import 'dart:async';
Future<String> slow() async {
  await Future<void>.delayed(const Duration(milliseconds: 200));
  return '原任务完成';
}
Future<void> main() async {
  final original = slow();
  try {
    print(await original.timeout(const Duration(milliseconds: 5)));
  } on TimeoutException { print('等待已超时'); }
  print(await original);
}
''',
    output: "等待已超时\n原任务完成\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "为超时包装提供 onTimeout 默认值。再等待原 Future。验证它仍可完成。",
        hint: "保留 original 引用，分别等待包装与原对象。",
        answer: r'''
import 'dart:async';
Future<void> main() async {
  final original = Future<String>.delayed(const Duration(milliseconds: 200), () => '真实结果');
  final value = await original.timeout(const Duration(milliseconds: 5), onTimeout: () => '默认结果');
  print(value);
  print(await original);
}
''',
      ),
    ],
    exampleTitle: "示例 278：真正超时与原任务生命周期",
    exampleSummary: "用 Future.timeout 限制等待，并证明超时不会自动取消原 Future。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-279',
    chapter: "async-patterns",
    level: "advanced",
    title: "异步聚合保持结果形状",
    summary: "并发读取多项数值后构造具名 Map，分离等待与汇总。",
    concepts: <String>["Future.wait", "结果聚合", "Map 返回值"],
    explain:
        "聚合函数可以把多个异步结果组织成稳定的数据结构。它不用让调用者猜列表中的每个位置代表什么。程序并发读取三个固定离线项目。等 Future.wait 全部完成后才求总和与最大值。最终用带明确键名的 Map 返回。main 只读取汇总字段，显示层不需要知道内部调度细节。本课把空输入约定为 count 和 sum 为零，maximum 为零。真实业务如果需要区分没有最大值，应把字段改成可空类型。Future.wait 中任何一个读取失败都会使聚合失败，本课没有静默跳过失败项目，以免报表看似完整。",
    objective: "能把多项异步读取收束为清楚的汇总接口。能定义空输入行为。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["不能在 Future 完成前就对结果列表做数值计算。", "忽略失败项会改变总量含义，需要显式报告。"],
    code: r'''
import 'dart:async';
Future<int> load(int id) async {
  await Future<void>.delayed(Duration.zero);
  return id * 10;
}
Future<Map<String, int>> summarize(List<int> ids) async {
  final values = await Future.wait(ids.map(load));
  var sum = 0;
  var maximum = 0;
  for (final value in values) {
    sum += value;
    if (value > maximum) maximum = value;
  }
  return {'count': values.length, 'sum': sum, 'maximum': maximum};
}
Future<void> main() async {
  final result = await summarize([2, 5, 3]);
  print('数量${result['count']} 合计${result['sum']} 最大${result['maximum']}');
  print(await summarize(<int>[]));
}
''',
    output: "数量3 合计100 最大50\n{count: 0, sum: 0, maximum: 0}\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把最大值改为可空值，让空输入返回 null 而不是零。",
        hint: "初值用 null，读取第一项时确定真实最大值。",
        answer: r'''
import 'dart:async';
Future<int?> maximum(List<int> values) async {
  await Future<void>.delayed(Duration.zero);
  int? result;
  for (final value in values) if (result == null || value > result) result = value;
  return result;
}
Future<void> main() async { print(await maximum(<int>[])); print(await maximum([-8, -3])); }
''',
      ),
    ],
    exampleTitle: "示例 279：异步聚合保持结果形状",
    exampleSummary: "并发读取多项数值后构造具名 Map，分离等待与汇总。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-280',
    chapter: "async-patterns",
    level: "advanced",
    title: "then 链中的异步展平",
    summary: "返回下一阶段的 Future，让链等待它而不是形成嵌套 Future。",
    concepts: <String>["Future.then", "展平", "返回链"],
    explain:
        "除了 async/await，Future.then 也能表达数据依赖。回调可以直接返回普通值。回调也可以返回另一个 Future。链会自动展平后一个 Future。后续回调等待它完成。程序先取得整数，在第一层回调中返回带延迟的倍增结果，再把最终值转换成带前缀的文本。程序把整个链保存在变量中，并让 main 等待它。这样程序不会在结果尚未处理时就结束。两种写法表达同一类依赖。不要为了显示链式语法而把错误处理藏得过深。当分支和清理较多时，async/await 往往更易阅读。",
    objective: "能在 then 回调中正确返回后续 Future，并说明展平的作用。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "回调里启动异步工作却忘记 return，会使链提前完成。",
      "then 不会自动把捕获错误转换为成功，异常仍沿链传播。",
    ],
    code: r'''
import 'dart:async';
Future<void> main() async {
  final result = Future<int>.value(6)
      .then((value) => Future<int>.delayed(Duration.zero, () => value * 2))
      .then((value) => '结果:$value');
  print(await result);
}
''',
    output: "结果:12\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把同一条链改写成 async/await，并保持计算顺序和结果。",
        hint: "先等待初值。再等待延迟变换。最后格式化。",
        answer: r'''
import 'dart:async';
Future<void> main() async {
  final initial = await Future<int>.value(6);
  final doubled = await Future<int>.delayed(Duration.zero, () => initial * 2);
  print('结果:$doubled');
}
''',
      ),
    ],
    exampleTitle: "示例 280：then 链中的异步展平",
    exampleSummary: "返回下一阶段的 Future，让链等待它而不是形成嵌套 Future。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-281',
    chapter: "async-patterns",
    level: "advanced",
    title: "异步领域异常与缓存降级",
    summary: "等待后抛出自定义异常，只对可恢复错误返回缓存结果。",
    concepts: <String>["自定义 Exception", "on/catch", "降级策略"],
    explain:
        "降级逻辑应该针对明确的失败类型，而不是把所有异常都掩盖成成功。程序的本地数据提供器在 await 之后抛出自定义 DataUnavailable，包装函数只捕获这个领域异常并返回缓存值。程序仍会打印异常中的原因，方便知道结果来自降级路径。若出现其他编程错误，它会继续向上传播，程序不会把它误当成普通不可用。整个示例使用离线固定数据，不发起网络请求。真实应用的缓存还需定义有效期、数据版本和是否允许过期使用。本课重点是演示跨异步边界的类型化错误与有条件恢复。",
    objective: "能跨 await 捕获特定领域错误，并保留其他错误的失败语义。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["catch 所有错误后返回默认值会隐藏程序缺陷。", "缓存结果应能与实时结果区分，不能悄悄改变来源含义。"],
    code: r'''
import 'dart:async';
class DataUnavailable implements Exception {
  DataUnavailable(this.reason);
  final String reason;
}
Future<String> readLocal() async {
  await Future<void>.delayed(Duration.zero);
  throw DataUnavailable('索引尚未生成');
}
Future<String> withCache() async {
  try { return await readLocal(); }
  on DataUnavailable catch (error) {
    print('降级原因:${error.reason}');
    return '缓存:v1';
  }
}
Future<void> main() async { print(await withCache()); }
''',
    output: "降级原因:索引尚未生成\n缓存:v1\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "让正常路径成功返回新值，验证不会打印降级原因。",
        hint: "把成功值放在等待后返回，仍保留特定异常分支。",
        answer: r'''
import 'dart:async';
Future<String> readLocal() async { await Future<void>.delayed(Duration.zero); return '新数据'; }
Future<void> main() async {
  try { print(await readLocal()); }
  on FormatException { print('缓存'); }
}
''',
      ),
    ],
    exampleTitle: "示例 281：异步领域异常与缓存降级",
    exampleSummary: "等待后抛出自定义异常，只对可恢复错误返回缓存结果。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-282',
    chapter: "async-patterns",
    level: "advanced",
    title: "并发任务显式传递追踪上下文",
    summary: "每个任务保留自己的 trace id 和日志，再按请求顺序输出。",
    concepts: <String>["上下文传递", "并发隔离", "结构化日志"],
    explain:
        "并发任务共用一个可变的当前编号容易让日志串线。程序把 trace id 作为参数传入每个任务。任务内部创建独立日志列表。日志分别记录开始和完成，再随 Future 返回。main 并发启动两个任务，等待全部结束后按输入顺序输出各自日志。这样追踪归属不依赖某个全局变量，也不依赖谁先结束。示例为了稳定显示按请求顺序汇总。真实实时日志仍可能交错。但每条记录只要携带追踪编号就能重新关联。这里不使用打印顺序证明任务先后，只验证上下文在真正的异步等待后仍然正确。",
    objective: "能在异步调用链中显式传递上下文，避免全局状态污染日志。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["全局 currentId 在并发任务间会相互覆盖。", "汇总后的输出顺序不能当作真实完成时间线。"],
    code: r'''
import 'dart:async';
Future<List<String>> task(String trace, int value) async {
  final logs = <String>['$trace:start'];
  await Future<void>.delayed(Duration.zero);
  logs.add('$trace:result=${value * 2}');
  return logs;
}
Future<void> main() async {
  final logs = await Future.wait([task('A', 3), task('B', 7)]);
  for (final group in logs) for (final line in group) print(line);
}
''',
    output: "A:start\nA:result=6\nB:start\nB:result=14\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "为每个追踪组增加结束标记，并检查两个组的编号始终独立。",
        hint: "所有日志行都从函数参数 trace 构造。",
        answer: r'''
import 'dart:async';
Future<List<String>> traceTask(String id) async {
  final lines = <String>['$id:start'];
  await Future<void>.delayed(Duration.zero);
  lines.add('$id:end');
  return lines;
}
Future<void> main() async {
  for (final lines in await Future.wait([traceTask('X'), traceTask('Y')])) print(lines.join(','));
}
''',
      ),
    ],
    exampleTitle: "示例 282：并发任务显式传递追踪上下文",
    exampleSummary: "每个任务保留自己的 trace id 和日志，再按请求顺序输出。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-283',
    chapter: "async-patterns",
    level: "advanced",
    title: "协作取消与 finally 清理",
    summary: "用共享取消令牌通知任务在等待边界退出，始终完成资源清理。",
    concepts: <String>["取消令牌", "Completer", "try/finally"],
    explain:
        "普通 Future 没有通用的强制取消方法，可以由任务主动在安全边界检查取消令牌。程序用 Completer 通知调用者任务已进入等待阶段，调用者收到通知后设置令牌，再等待任务自行停止。任务在 finally 中打印清理信息，因此正常退出或异常传播都会经过同一清理路径。示例不通过固定睡眠猜测任务是否启动，启动通知提供明确的同步点。协作取消不能中断当前正在运行的同步死循环。它也不会自动关闭底层资源。真实产品应把令牌检查与文件、订阅或 isolate 的实际取消接口一起设计。",
    objective: "能实现可预测的协作取消握手，并保证退出时完成清理。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "设置令牌不会立即中断任意同步代码，需要任务主动检查。",
      "调用者应等待取消完成，不能发出请求后就假定资源已经释放。",
    ],
    code: r'''
import 'dart:async';
class CancelToken { bool cancelled = false; }
Future<void> worker(CancelToken token, Completer<void> started) async {
  try {
    print('资源打开');
    started.complete();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    if (token.cancelled) { print('收到取消'); return; }
    print('继续工作');
  } finally { print('资源关闭'); }
}
Future<void> main() async {
  final token = CancelToken();
  final started = Completer<void>();
  final running = worker(token, started);
  await started.future;
  token.cancelled = true;
  await running;
  print('取消完成');
}
''',
    output: "资源打开\n收到取消\n资源关闭\n取消完成\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "验证正常路径也会清理。不设置取消令牌，等待任务打印成功和关闭。",
        hint: "finally 与是否发生异常无关。",
        answer: r'''
import 'dart:async';
Future<void> work() async {
  try { await Future<void>.delayed(Duration.zero); print('成功'); }
  finally { print('关闭'); }
}
Future<void> main() async { await work(); }
''',
      ),
    ],
    exampleTitle: "示例 283：协作取消与 finally 清理",
    exampleSummary: "用共享取消令牌通知任务在等待边界退出，始终完成资源清理。完整运行演示。",
  ),
];
