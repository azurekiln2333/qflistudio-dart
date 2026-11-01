import '../dart_lesson.dart';

/// Independent, offline programs for chapter `errors-resilience`.
const List<DartLesson> errorsResilienceLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-216',
    chapter: 'errors-resilience',
    level: 'beginner',
    title: "携带业务上下文的异常",
    summary: "为库存扣减失败提供稳定错误码与可读详情。",
    concepts: <String>["自定义异常", "错误码", "失败原子性"],
    explain:
        "业务失败往往需要比一段文字更多的信息。自定义异常可以把稳定的错误码和面向人的详情分别保存。调用方根据代码分类处理。显示层再使用详情。本例在库存不足时抛出异常，异常包含商品编号、请求数量和剩余数量。成功扣减则返回新库存。校验发生在状态改变之前，因此失败不会把库存扣成负数。错误码应保持稳定，不能依赖完整中文文字来判断业务分支。示例只操作内存中的库存数值，离线即可分别运行成功和失败路径并校验结果。",
    objective: "能定义携带字段的业务异常，并在失败前保护状态。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["不要通过匹配整段错误文案实现分类。", "抛错前若已修改状态，需要显式回滚或重新安排提交顺序。"],
    code: r'''
class StockFailure implements Exception {
  StockFailure(this.code, this.detail);
  final String code;
  final String detail;
  @override
  String toString() => '$code: $detail';
}
int reserve(String sku, int available, int requested) {
  if (requested <= 0) throw ArgumentError('数量必须为正');
  if (requested > available) {
    throw StockFailure('INSUFFICIENT', '$sku 请求 $requested，剩余 $available');
  }
  return available - requested;
}
void main() {
  var stock = 5;
  stock = reserve('PEN', stock, 2);
  print('预留后 $stock');
  try { stock = reserve('PEN', stock, 4); }
  on StockFailure catch (error) { print('${error.code}: ${error.detail}'); }
  print('失败后 $stock');
}
''',
    output: "预留后 3\nINSUFFICIENT: PEN 请求 4，剩余 3\n失败后 3\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "增加商品不存在的错误码。调用者根据 code 给出不同处理。",
        hint: "保持同一个异常类型。先校验编号。再校验数量。",
        answer: r'''
class StockFailure implements Exception {
  StockFailure(this.code, this.detail);
  final String code;
  final String detail;
  @override
  String toString() => '$code: $detail';
}
int reserve(String sku, int available, int requested) {
  if (requested <= 0) throw ArgumentError('数量必须为正');
  if (requested > available) {
    throw StockFailure('INSUFFICIENT', '$sku 请求 $requested，剩余 $available');
  }
  return available - requested;
}

void explainFailure(StockFailure error) {
  switch (error.code) {
    case 'NOT_FOUND': print('请检查商品编号'); break;
    case 'INSUFFICIENT': print('请减少预留数量'); break;
    default: print(error.detail);
  }
}
void reserveKnown(Map<String, int> inventory, String sku, int quantity) {
  if (!inventory.containsKey(sku)) throw StockFailure('NOT_FOUND', '未知商品 $sku');
  inventory[sku] = reserve(sku, inventory[sku]!, quantity);
}
void main() {
  final inventory = <String, int>{'PEN': 2};
  for (final sku in ['BOOK', 'PEN']) {
    try { reserveKnown(inventory, sku, 3); }
    on StockFailure catch (error) { explainFailure(error); }
  }
  print(inventory);
}
''',
      ),
    ],
    exampleTitle: "示例 216：携带业务上下文的异常",
    exampleSummary: "运行示例。观察为库存扣减失败提供稳定错误码与可读详情。",
  ),
  DartLesson(
    id: 'dart-lesson-217',
    chapter: 'errors-resilience',
    level: 'intermediate',
    title: "逐条导入的批量容错",
    summary: "把异常边界放在单条记录内，保留成功项并报告失败位置。",
    concepts: <String>["批处理", "局部 try", "部分成功"],
    explain:
        "批量导入常常包含少数坏记录。如果把整个循环包在一个异常处理块中，第一条失败就会阻止后面所有记录。本例把解析和范围校验放在每一轮 try 中。成功数量累加，失败则记录行号和原因。随后继续下一条。这样部分成功是明确的产品行为，而不是默默丢弃数据。格式错误和负数数量分别处理，报表还能显示接受记录的数量。输入数据固定在内存中。离线运行能够验证失败后循环确实继续，总量只来自合法记录。",
    objective: "能在循环中隔离单条失败，并保留定位信息。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["把 try 放在整个循环外会提前结束批次。", "继续处理时仍要报告失败项，不能空 catch 静默丢失。"],
    code: r'''
void main() {
  final rows = ['12', 'bad', '-3', '8', '0'];
  var total = 0;
  var accepted = 0;
  final failures = <String>[];
  for (var index = 0; index < rows.length; index++) {
    try {
      final quantity = int.parse(rows[index]);
      if (quantity < 0) throw ArgumentError('数量不能为负');
      total += quantity;
      accepted++;
    } on FormatException {
      failures.add('第 ${index + 1} 行: 不是整数');
    } on ArgumentError {
      failures.add('第 ${index + 1} 行: 负数量');
    }
  }
  print('接受 $accepted/${rows.length}，数量合计 $total');
  for (final failure in failures) { print(failure); }
}
''',
    output: "接受 3/5，数量合计 20\n第 2 行: 不是整数\n第 3 行: 负数量\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "让空白行记为跳过，而不是失败。同时单独统计跳过数。",
        hint: "解析之前判断 trim().isEmpty，增加 skipped 后 continue。",
        answer: r'''
void main() {
  var skipped = 0;
  var total = 0;
  var failures = 0;
  for (final row in ['', '12', '  ', 'bad', '8']) {
    if (row.trim().isEmpty) { skipped++; continue; }
    try { total += int.parse(row); }
    on FormatException { failures++; }
  }
  print('合计 $total，跳过 $skipped，失败 $failures');
}
''',
      ),
    ],
    exampleTitle: "示例 217：逐条导入的批量容错",
    exampleSummary: "运行示例。观察把异常边界放在单条记录内，保留成功项并报告失败位置。",
  ),
  DartLesson(
    id: 'dart-lesson-218',
    chapter: 'errors-resilience',
    level: 'intermediate',
    title: "结果对象表达预期失败",
    summary: "用成功值或错误原因返回端口解析结果，而不把常见无效输入当作异常。",
    concepts: <String>["结果对象", "可空字段", "预期失败"],
    explain:
        "用户输入不符合格式是常见情况，调用者往往只想显示原因并继续。结果对象把成功值和失败原因作为返回数据，让函数签名体现两种可能。本例为端口输入定义两个命名构造，保证成功时有值、失败时有原因。程序再统一渲染一组解析结果。调用方必须先校验成功标记，才能安全读取值。结果对象适合预期的校验失败，程序缺陷或无法恢复的资源错误仍不应随意转成普通成功。所有输入都在本地给出，离线运行即可校验格式和范围两类失败。",
    objective: "能以结果对象返回预期失败，并在读取值前校验状态。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["成功和错误字段不应同时有值，也不应同时缺失。", "不要把所有异常都转成无上下文的失败，避免掩盖程序缺陷。"],
    code: r'''
class PortResult {
  const PortResult.ok(this.value) : error = null;
  const PortResult.fail(this.error) : value = null;
  final int? value;
  final String? error;
  bool get isSuccess => error == null;
}
PortResult parsePort(String text) {
  final value = int.tryParse(text);
  if (value == null) return PortResult.fail('需要整数');
  if (value < 1 || value > 65535) return PortResult.fail('端口超出范围');
  return PortResult.ok(value);
}
void main() {
  for (final text in ['8080', 'zero', '70000']) {
    final result = parsePort(text);
    print(result.isSuccess ? '端口 ${result.value}' : '失败 ${result.error}');
  }
}
''',
    output: "端口 8080\n失败 需要整数\n失败 端口超出范围\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "写一个只在成功时做变换的函数，把端口转成显示文字。",
        hint: "失败结果直接沿用错误原因。成功时再调用传入函数。",
        answer: r'''
class PortResult {
  const PortResult.ok(this.value) : error = null;
  const PortResult.fail(this.error) : value = null;
  final int? value;
  final String? error;
  bool get isSuccess => error == null;
}
PortResult parsePort(String text) {
  final value = int.tryParse(text);
  if (value == null) return PortResult.fail('需要整数');
  if (value < 1 || value > 65535) return PortResult.fail('端口超出范围');
  return PortResult.ok(value);
}

String renderPort(PortResult result, String Function(int) format) =>
    result.isSuccess ? format(result.value!) : '错误: ${result.error}';
void main() {
  print(renderPort(parsePort('8080'), (value) => '监听 $value'));
  print(renderPort(parsePort('0'), (value) => '监听 $value'));
}
''',
      ),
    ],
    exampleTitle: "示例 218：结果对象表达预期失败",
    exampleSummary: "运行示例。观察用成功值或错误原因返回端口解析结果，而不把常见无效输入当作异常。",
  ),
  DartLesson(
    id: 'dart-lesson-219',
    chapter: 'errors-resilience',
    level: 'intermediate',
    title: "业务校验与开发断言",
    summary: "用运行期守卫保护输入。再用 assert 表达内部已成立的条件。",
    concepts: <String>["ArgumentError", "assert", "运行模式"],
    explain:
        "断言适合帮助开发者发现内部假设失效。但断言不能成为用户输入的唯一校验。因为发布模式可以关闭断言。本例的分页函数先用参数错误拒绝非法页码和页大小。函数再用断言说明通过校验后的内部条件。合法请求计算区间起点，非法请求在所有运行模式下都会失败。通过同时显示两种机制，读者能够区分面向调用方的契约与面向开发期的校验。程序输出不依赖断言是否启用，因此普通 SDK 和离线便携运行路径都能复现同样的业务结果。",
    objective: "能区分不可省略的运行期校验与可关闭的开发断言。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "发布模式可能关闭 assert，不能用它独自验证不可信输入。",
      "断言表达式不要放副作用，否则不同运行模式会产生不同状态。",
    ],
    code: r'''
int pageOffset(int page, int pageSize) {
  if (page < 1) throw ArgumentError('页码至少为一');
  if (pageSize < 1 || pageSize > 100) throw ArgumentError('页大小必须在一到一百');
  assert(page > 0 && pageSize > 0);
  return (page - 1) * pageSize;
}
void main() {
  print('第三页起点 ${pageOffset(3, 20)}');
  for (final page in [0, -2]) {
    try { print(pageOffset(page, 20)); }
    on ArgumentError { print('拒绝页码 $page'); }
  }
}
''',
    output: "第三页起点 40\n拒绝页码 0\n拒绝页码 -2\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "增加总条数参数。同时校验页码是否超过最后一页。",
        hint: "先处理空数据。再用向上取整计算页数。业务校验仍使用显式 if。",
        answer: r'''
int pageOffset(int page, int pageSize) {
  if (page < 1) throw ArgumentError('页码至少为一');
  if (pageSize < 1 || pageSize > 100) throw ArgumentError('页大小必须在一到一百');
  assert(page > 0 && pageSize > 0);
  return (page - 1) * pageSize;
}

int checkedPageOffset(int page, int size, int count) {
  final offset = pageOffset(page, size);
  if (count < 0) throw ArgumentError('条数不能为负');
  if (count == 0 ? page != 1 : offset >= count) throw ArgumentError('页码超出数据');
  return offset;
}
void main() {
  print(checkedPageOffset(3, 20, 45));
  print(checkedPageOffset(1, 20, 0));
  try { checkedPageOffset(4, 20, 45); }
  on ArgumentError { print('拒绝不存在的页'); }
}
''',
      ),
    ],
    exampleTitle: "示例 219：业务校验与开发断言",
    exampleSummary: "运行示例。观察用运行期守卫保护输入。再用 assert 表达内部已成立的条件。",
  ),
  DartLesson(
    id: 'dart-lesson-220',
    chapter: 'errors-resilience',
    level: 'intermediate',
    title: "一次报告全部字段错误",
    summary: "把各字段的独立校验收集为列表，让用户一次修复多项问题。",
    concepts: <String>["错误聚合", "字段定位", "独立规则"],
    explain:
        "表单校验若遇到第一项错误就退出，用户只能反复提交才能看到下一个问题。对彼此独立的字段，可以先运行所有规则。再一次性返回完整问题列表。本例同时校验昵称、联系地址和年龄，每个问题都带字段名，合法资料返回空列表。聚合并不意味着忽略依赖关系：某字段解析失败后，不能继续把无效值用于后续计算。结果顺序按规则书写顺序固定，方便界面显示与测试校验。所有校验只依赖传入数据，离线运行可直接观察完整反馈。",
    objective: "能收集独立字段问题，并用空列表表示校验通过。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "聚合错误时仍要尊重解析依赖，不能对 null 继续范围判断。",
      "问题需要保留字段名，只有笼统失败文字难以定位。",
    ],
    code: r'''
List<String> validateProfile(Map<String, Object?> profile) {
  final errors = <String>[];
  final name = profile['name'];
  if (name is! String || name.trim().length < 2) errors.add('name: 至少两个字符');
  final email = profile['email'];
  if (email is! String || !email.contains('@')) errors.add('email: 缺少 @');
  final age = profile['age'];
  if (age is! int) { errors.add('age: 需要整数'); }
  else if (age < 0 || age > 130) { errors.add('age: 超出范围'); }
  return errors;
}
void main() {
  final issues = validateProfile({'name': ' ', 'email': 'invalid', 'age': 150});
  for (final issue in issues) { print(issue); }
  print('共 ${issues.length} 项');
  print(validateProfile({'name': '小林', 'email': 'lin@example.test', 'age': 24}));
}
''',
    output: "name: 至少两个字符\nemail: 缺少 @\nage: 超出范围\n共 3 项\n[]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "给昵称增加最大二十个字符的独立校验。",
        hint: "先确认输入是字符串。再把长度不足和过长分别加入问题列表。",
        answer: r'''
List<String> validateProfile(Map<String, Object?> profile) {
  final errors = <String>[];
  final name = profile['name'];
  if (name is! String || name.trim().length < 2) errors.add('name: 至少两个字符');
  if (name is String && name.trim().length > 20) errors.add('name: 最多二十个字符');
  final email = profile['email'];
  if (email is! String || !email.contains('@')) errors.add('email: 缺少 @');
  final age = profile['age'];
  if (age is! int) { errors.add('age: 需要整数'); }
  else if (age < 0 || age > 130) { errors.add('age: 超出范围'); }
  return errors;
}

void main() {
  print(validateProfile({'name': '非常非常非常非常非常非常非常非常非常非常长的昵称',
    'email': 'lin@example.test', 'age': 24}));
  print(validateProfile({'name': '小林', 'email': 'lin@example.test', 'age': 24}));
}
''',
      ),
    ],
    exampleTitle: "示例 220：一次报告全部字段错误",
    exampleSummary: "运行示例。观察把各字段的独立校验收集为列表，让用户一次修复多项问题。",
  ),
  DartLesson(
    id: 'dart-lesson-221',
    chapter: 'errors-resilience',
    level: 'intermediate',
    title: "带来源标记的配置降级",
    summary: "解析失败时使用安全默认值，同时让调用者知道发生过回退。",
    concepts: <String>["降级策略", "默认值", "结果来源"],
    explain:
        "配置读取失败时采用默认值，可以让程序继续。但如果完全不记录回退，维护者很难解释实际行为。本例把解析结果和来源一起返回：合法正整数来自输入，格式错误或非正值来自默认配置。默认值本身也必须先验证，避免用另一个非法值掩盖错误。异常处理只捕获预期的格式问题，调用者提供错误默认值时仍明确失败。输出既显示最终数值，也显示来源，形成可观察的降级过程。整个例子只解析固定字符串，离线可复现成功与回退两条路径。",
    objective: "能实施可观察的默认值回退，并校验回退值本身。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["降级不等于静默吞错，应该保留来源或原因。", "不要捕获所有错误后都回退，否则会隐藏调用代码的缺陷。"],
    code: r'''
class TimeoutConfig {
  TimeoutConfig(this.seconds, this.source);
  final int seconds;
  final String source;
}
TimeoutConfig readTimeout(String raw, {int fallback = 30}) {
  if (fallback < 1) throw ArgumentError('默认值必须为正');
  try {
    final value = int.parse(raw.trim());
    if (value < 1) throw FormatException('需要正整数');
    return TimeoutConfig(value, '输入');
  } on FormatException {
    return TimeoutConfig(fallback, '默认');
  }
}
void main() {
  for (final text in [' 12 ', 'broken', '0']) {
    final config = readTimeout(text);
    print('${config.seconds} 秒，来源=${config.source}');
  }
}
''',
    output: "12 秒，来源=输入\n30 秒，来源=默认\n30 秒，来源=默认\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "给配置增加上限三百秒。超过上限也降级，并保留明确原因。",
        hint: "将失败原因作为第三个字段。字段分别记录格式、下限和上限问题。",
        answer: r'''
class TimeoutConfig {
  TimeoutConfig(this.seconds, this.source);
  final int seconds;
  final String source;
}
TimeoutConfig readTimeout(String raw, {int fallback = 30}) {
  if (fallback < 1) throw ArgumentError('默认值必须为正');
  try {
    final value = int.parse(raw.trim());
    if (value < 1) throw FormatException('需要正整数');
    return TimeoutConfig(value, '输入');
  } on FormatException {
    return TimeoutConfig(fallback, '默认');
  }
}

class BoundedConfig {
  BoundedConfig(this.seconds, this.reason);
  final int seconds;
  final String reason;
}
BoundedConfig boundedTimeout(String text, int fallback) {
  if (fallback < 1 || fallback > 300) throw ArgumentError('默认值越界');
  final parsed = int.tryParse(text.trim());
  if (parsed == null) return BoundedConfig(fallback, '格式错误');
  if (parsed < 1) return BoundedConfig(fallback, '低于下限');
  if (parsed > 300) return BoundedConfig(fallback, '超过上限');
  return BoundedConfig(parsed, '输入有效');
}
void main() {
  for (final raw in ['15', 'bad', '0', '500']) {
    final config = boundedTimeout(raw, 30);
    print('${config.seconds}: ${config.reason}');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 221：带来源标记的配置降级",
    exampleSummary: "运行示例。观察解析失败时使用安全默认值，同时让调用者知道发生过回退。",
  ),
  DartLesson(
    id: 'dart-lesson-222',
    chapter: 'errors-resilience',
    level: 'intermediate',
    title: "有次数上限的同步重试",
    summary: "只重试明确的临时失败。成功即返回。耗尽次数后保留失败。",
    concepts: <String>["有界重试", "临时错误", "重新抛出"],
    explain:
        "重试可以应对临时失败，但无上限循环会让程序永远无法结束。本例定义一种明确可重试的异常。重试函数最多调用指定次数。成功立即返回。最后一次失败则重新抛出。测试操作用本地计数器在前两次调用失败，第三次返回数据。因此不需要网络也能验证控制流程。尝试次数统计的是实际调用总数，不是额外重试次数，命名和输出必须保持一致。重试还应考虑操作是否幂等，真实业务不能重复扣款。离线程序只演示无副作用的读取模型。",
    objective: "能实现有界重试，并区分尝试总数与重试次数。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["重试只应针对明确可恢复的失败。", "有副作用且不幂等的操作不能盲目重复运行。"],
    code: r'''
class TemporaryFailure implements Exception {}
String retry(String Function() operation, int maxAttempts) {
  if (maxAttempts < 1) throw ArgumentError('至少尝试一次');
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    print('尝试 $attempt');
    try { return operation(); }
    on TemporaryFailure {
      if (attempt == maxAttempts) rethrow;
    }
  }
  throw StateError('不可达');
}
void main() {
  var calls = 0;
  final value = retry(() {
    calls++;
    if (calls < 3) throw TemporaryFailure();
    return '本地索引读取成功';
  }, 3);
  print(value);
  print('实际调用 $calls 次');
}
''',
    output: "尝试 1\n尝试 2\n尝试 3\n本地索引读取成功\n实际调用 3 次\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "验证一直失败的操作只运行两次。在外层捕获最终异常。",
        hint: "最大尝试数设为二，操作每次抛 TemporaryFailure。",
        answer: r'''
class TemporaryFailure implements Exception {}
String retry(String Function() operation, int maxAttempts) {
  if (maxAttempts < 1) throw ArgumentError('至少尝试一次');
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    print('尝试 $attempt');
    try { return operation(); }
    on TemporaryFailure {
      if (attempt == maxAttempts) rethrow;
    }
  }
  throw StateError('不可达');
}

void main() {
  var calls = 0;
  try {
    retry(() { calls++; throw TemporaryFailure(); }, 2);
  } on TemporaryFailure { print('耗尽，调用 $calls 次'); }
}
''',
      ),
    ],
    exampleTitle: "示例 222：有次数上限的同步重试",
    exampleSummary: "运行示例。观察只重试明确的临时失败。成功即返回。耗尽次数后保留失败。",
  ),
  DartLesson(
    id: 'dart-lesson-223',
    chapter: 'errors-resilience',
    level: 'intermediate',
    title: "异常路径也关闭真实文件",
    summary: "用嵌套 finally 按相反顺序释放文件句柄和临时目录。",
    concepts: <String>["资源生命周期", "finally", "真实文件 IO"],
    explain:
        "资源清理应覆盖成功和失败两条路径，并按取得资源的相反顺序处理。本例先创建临时目录。程序再打开文件句柄写入真实内容。随后触发一个格式解析错误。内层 finally 关闭文件。外层捕获业务错误。最外层 finally 删除临时目录。输出校验写入结果和删除后的存在状态，证明发生的是实际文件操作。清理代码不使用 return，避免覆盖原本的异常或返回值。它也不把句柄留给垃圾回收时机决定。程序的文件全部由自身创建并删除，离线运行不会依赖现有项目文件。",
    objective: "能为多层资源安排逆序清理，并在异常时保留原错误。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "先删目录再关句柄在某些平台会失败。",
      "finally 中的 return 或新异常可能遮住原失败，应保持清理简单。",
    ],
    code: r'''
import 'dart:io';
void main() {
  final directory = Directory.systemTemp.createTempSync('cleanup_lesson_');
  try {
    final file = File('${directory.path}/note.txt');
    final handle = file.openSync(mode: FileMode.write);
    try {
      handle.writeStringSync('已经写入');
      handle.flushSync();
      print(file.readAsStringSync());
      int.parse('invalid');
    } finally {
      handle.closeSync();
      print('文件句柄已关闭');
    }
  } on FormatException {
    print('捕获解析错误');
  } finally {
    directory.deleteSync(recursive: true);
    print('临时目录存在 ${directory.existsSync()}');
  }
}
''',
    output: "已经写入\n文件句柄已关闭\n捕获解析错误\n临时目录存在 false\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把解析改成合法数字，校验 finally 是否仍会运行。",
        hint: "将 invalid 改为 42，捕获分支不再运行，两层清理仍保留。",
        answer: r'''
import 'dart:io';
void main() {
  final directory = Directory.systemTemp.createTempSync('cleanup_success_');
  try {
    final handle = File('${directory.path}/value.txt').openSync(mode: FileMode.write);
    try {
      handle.writeStringSync('42');
      print(int.parse('42'));
    } finally {
      handle.closeSync();
      print('文件句柄已关闭');
    }
  } finally {
    directory.deleteSync(recursive: true);
    print('临时目录存在 ${directory.existsSync()}');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 223：异常路径也关闭真实文件",
    exampleSummary: "运行示例。观察用嵌套 finally 按相反顺序释放文件句柄和临时目录。",
  ),
  DartLesson(
    id: 'dart-lesson-224',
    chapter: 'errors-resilience',
    level: 'advanced',
    title: "按错误类别决定重试",
    summary: "把临时故障和永久拒绝分开处理，避免无效重试。",
    concepts: <String>["错误分类", "策略决策", "快速失败"],
    explain:
        "并非所有失败都有重试价值。临时索引忙可能稍后恢复，参数无效则无论重复多少次都不会成功。本例用枚举给操作失败分类。重试策略只对临时类别继续尝试。遇到永久拒绝立即停止。两组本地脚本分别显示遇到永久问题和临时问题后成功的路径。日志能够校验真正调用了多少次。分类最好由了解原因的底层操作提供，而不是上层通过文字猜测。这里没有真实外部服务，固定故障序列用于离线验证策略本身。本例避免把演示说成网络可靠性保证。",
    objective: "能根据错误类别快速失败或有界重试。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["不能通过中文错误消息判断是否重试。", "永久错误应及时返回，不要消耗全部重试次数。"],
    code: r'''
enum FailureKind { temporary, invalidRequest }
class OperationFailure implements Exception {
  OperationFailure(this.kind);
  final FailureKind kind;
}
String execute(List<FailureKind> failures, int limit) {
  var calls = 0;
  String operation() {
    final index = calls++;
    if (index < failures.length) throw OperationFailure(failures[index]);
    return '完成';
  }
  for (var attempt = 1; attempt <= limit; attempt++) {
    try { return '${operation()}，调用 $calls 次'; }
    on OperationFailure catch (error) {
      print('第 $attempt 次: ${error.kind.name}');
      if (error.kind == FailureKind.invalidRequest) return '永久失败，停止';
    }
  }
  return '临时失败次数耗尽';
}
void main() {
  print(execute([FailureKind.temporary, FailureKind.invalidRequest], 4));
  print(execute([FailureKind.temporary, FailureKind.temporary], 4));
}
''',
    output:
        "第 1 次: temporary\n第 2 次: invalidRequest\n永久失败，停止\n第 1 次: temporary\n第 2 次: temporary\n完成，调用 3 次\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "让 execute 拒绝零或负的尝试上限。",
        hint: "校验应在定义和调用 operation 之前，保证没有任何实际调用。",
        answer: r'''
enum FailureKind { temporary, invalidRequest }
class OperationFailure implements Exception {
  OperationFailure(this.kind);
  final FailureKind kind;
}
String execute(List<FailureKind> failures, int limit) {
  if (limit < 1) throw ArgumentError('尝试上限至少为一');
  var calls = 0;
  String operation() {
    final index = calls++;
    if (index < failures.length) throw OperationFailure(failures[index]);
    return '完成';
  }
  for (var attempt = 1; attempt <= limit; attempt++) {
    try { return '${operation()}，调用 $calls 次'; }
    on OperationFailure catch (error) {
      print('第 $attempt 次: ${error.kind.name}');
      if (error.kind == FailureKind.invalidRequest) return '永久失败，停止';
    }
  }
  return '临时失败次数耗尽';
}

void main() {
  try { execute([], 0); }
  on ArgumentError { print('零上限在调用操作前被拒绝'); }
  print(execute([], 1));
}
''',
      ),
    ],
    exampleTitle: "示例 224：按错误类别决定重试",
    exampleSummary: "运行示例。观察把临时故障和永久拒绝分开处理，避免无效重试。",
  ),
  DartLesson(
    id: 'dart-lesson-225',
    chapter: 'errors-resilience',
    level: 'advanced',
    title: "批次契约与缺陷清单",
    summary: "同时验证单条记录和跨记录约束，给出可追踪的导入报告。",
    concepts: <String>["契约校验", "重复标识", "跨记录一致性"],
    explain:
        "单条记录字段正确，不代表整个批次满足契约。导入还可能要求标识唯一、声明总量与实际合计一致。本例先逐条校验编号和数量。程序再维护已见编号集合识别重复。最后比较批次声明的总量。所有发现都加入缺陷清单，让调用者一次看到局部与整体问题。合计按原始记录计算，不能因为发现重复就悄悄修改输入，否则报告与原始批次对不上。校验只返回问题，不写入部分数据。真正提交应在清单为空之后。固定批次可在离线运行时完整审查。",
    objective: "能区分单条规则与批次规则，并输出完整缺陷。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["发现问题时不要悄悄改写数据，否则很难解释报告。", "校验通过与实际提交应有明确边界，避免半批数据已写入。"],
    code: r'''
class ImportRow {
  const ImportRow(this.id, this.quantity);
  final String id;
  final int quantity;
}
List<String> audit(List<ImportRow> rows, int declaredTotal) {
  final issues = <String>[];
  final seen = <String>{};
  var total = 0;
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    if (row.id.isEmpty) issues.add('行 ${i + 1}: 编号为空');
    if (!seen.add(row.id)) issues.add('行 ${i + 1}: 编号重复 ${row.id}');
    if (row.quantity < 0) issues.add('行 ${i + 1}: 数量为负');
    total += row.quantity;
  }
  if (total != declaredTotal) issues.add('总量不符: 声明 $declaredTotal，实际 $total');
  return issues;
}
void main() {
  final rows = [ImportRow('A', 3), ImportRow('A', 2), ImportRow('', -1)];
  final issues = audit(rows, 8);
  for (final issue in issues) { print(issue); }
  print('可提交 ${issues.isEmpty}');
}
''',
    output: "行 2: 编号重复 A\n行 3: 编号为空\n行 3: 数量为负\n总量不符: 声明 8，实际 4\n可提交 false\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "增加记录按编号升序的契约，并指出第一处逆序行。",
        hint: "从第二条开始比较相邻编号，逆序时加入行号。",
        answer: r'''
class ImportRow {
  const ImportRow(this.id, this.quantity);
  final String id;
  final int quantity;
}
List<String> audit(List<ImportRow> rows, int declaredTotal) {
  final issues = <String>[];
  final seen = <String>{};
  var total = 0;
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    if (row.id.isEmpty) issues.add('行 ${i + 1}: 编号为空');
    if (!seen.add(row.id)) issues.add('行 ${i + 1}: 编号重复 ${row.id}');
    if (row.quantity < 0) issues.add('行 ${i + 1}: 数量为负');
    total += row.quantity;
  }
  if (total != declaredTotal) issues.add('总量不符: 声明 $declaredTotal，实际 $total');
  return issues;
}

List<String> orderIssues(List<ImportRow> rows) {
  for (var i = 1; i < rows.length; i++) {
    if (rows[i - 1].id.compareTo(rows[i].id) > 0) return ['行 ${i + 1}: 编号逆序'];
  }
  return [];
}
void main() {
  print(orderIssues([ImportRow('B', 1), ImportRow('A', 2), ImportRow('C', 1)]));
  print(orderIssues([ImportRow('A', 1), ImportRow('B', 2)]));
}
''',
      ),
    ],
    exampleTitle: "示例 225：批次契约与缺陷清单",
    exampleSummary: "运行示例。观察同时验证单条记录和跨记录约束，给出可追踪的导入报告。",
  ),
  DartLesson(
    id: 'dart-lesson-226',
    chapter: 'errors-resilience',
    level: 'advanced',
    title: "扩展边界的最终错误隔离",
    summary: "优先处理已知异常。再在批量扩展调用边界捕获其余对象。",
    concepts: <String>["on Object", "边界隔离", "错误分类"],
    explain:
        "可扩展程序运行第三方回调时，某个回调失败不应必然阻止整个批次。Dart 允许抛出任意非空对象，因此只捕获 Exception 不能覆盖 Error 或旧式字符串抛出。本例先为已知格式异常提供具体反馈。再在最外层回调边界用 Object 兜底。它区分程序错误和其他抛出值，并继续下一项。这个宽捕获只用于隔离边界，不能在内部业务代码中到处吞错。真实产品还应保存异常与堆栈以便修复，示例只输出稳定分类。全部回调在本地运行，离线可验证批次存活。",
    objective: "能在明确扩展边界捕获任意抛出值，并优先处理已知失败。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "on Exception 捕获不到 Error 或字符串抛出。",
      "宽捕获后必须保留诊断和失败计数，不能把失败伪装成成功。",
    ],
    code: r'''
void main() {
  final tasks = <int Function()>[
    () => 7,
    () => throw FormatException('格式错误'),
    () => throw StateError('扩展状态损坏'),
    () => throw '旧式错误',
    () => 9,
  ];
  var successes = 0;
  var failures = 0;
  for (var index = 0; index < tasks.length; index++) {
    try {
      print('任务 ${index + 1}: ${tasks[index]()}');
      successes++;
    } on FormatException {
      failures++;
      print('任务 ${index + 1}: 已知格式问题');
    } on Object catch (error) {
      failures++;
      print('任务 ${index + 1}: ${error is Error ? '程序错误' : '其他抛出值'}');
    }
  }
  print('成功 $successes，失败 $failures');
}
''',
    output:
        "任务 1: 7\n任务 2: 已知格式问题\n任务 3: 程序错误\n任务 4: 其他抛出值\n任务 5: 9\n成功 2，失败 3\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把兜底逻辑改为记录后重新抛出。适用于不允许部分成功的边界。",
        hint: "使用 catch(error, stack) 记录上下文。再使用 rethrow 保留原堆栈。",
        answer: r'''
int strictBoundary(int Function() task, List<Map<String, Object>> diagnostics) {
  try { return task(); }
  on Object catch (error, stack) {
    diagnostics.add({'error': error, 'stack': stack});
    rethrow;
  }
}
void main() {
  final diagnostics = <Map<String, Object>>[];
  try { strictBoundary(() => throw StateError('扩展失败'), diagnostics); }
  on StateError { print('外层仍收到原错误'); }
  print('保留诊断 ${diagnostics.length} 条');
  print('错误和堆栈字段 ${diagnostics.single.keys.join(', ')}');
}
''',
      ),
    ],
    exampleTitle: "示例 226：扩展边界的最终错误隔离",
    exampleSummary: "运行示例。观察优先处理已知异常。再在批量扩展调用边界捕获其余对象。",
  ),
];
