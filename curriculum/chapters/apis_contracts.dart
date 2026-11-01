import '../dart_lesson.dart';

/// Chapter `apis-contracts` — independently executed lessons and paired examples.
const List<DartLesson> apisContractsLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-284',
    chapter: "apis-contracts",
    level: "intermediate",
    title: "可组合的检查规则链",
    summary: "把规则存储为函数列表。程序按顺序运行规则，遇到首次失败就停止。",
    concepts: <String>["函数类型", "规则链", "短路"],
    explain:
        "检查逻辑常常由多个独立条件组成，写成一大段条件表达式会让错误原因难以定位。程序把每条规则定义为接收字符串、返回可空错误消息的函数，null 表示通过。检查器按列表顺序调用，遇到第一个错误就返回，因此规则顺序也决定用户先看到哪条提示。示例先检查非空，再检查长度，避免空值同时触发多种不必要消息。这种接口可以在不修改检查器的情况下增加新规则。短路链只适合希望逐个引导修正的场景。如果界面需要一次显示所有问题，应使用聚合策略。它不应偷偷改变这里的返回契约。",
    objective: "能用统一函数签名组合检查，并清楚区分短路与聚合策略。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "规则返回 null 才表示通过，不要把空字符串当成功标记。",
      "调整规则顺序会改变首次失败消息，属于可见行为。",
    ],
    code: r'''
typedef Rule = String? Function(String value);
String? required(String value) => value.trim().isEmpty ? '不能为空' : null;
String? longEnough(String value) => value.trim().length < 3 ? '至少三字符' : null;
String? validate(String value, List<Rule> rules) {
  for (final rule in rules) {
    final error = rule(value);
    if (error != null) return error;
  }
  return null;
}
void main() {
  final rules = <Rule>[required, longEnough];
  for (final text in ['', 'ab', 'dart']) print(validate(text, rules) ?? '通过');
}
''',
    output: "不能为空\n至少三字符\n通过\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "增加一条只允许小写英文字母的规则。验证长度合格但含数字仍会失败。",
        hint: "使用完整匹配的正则，并把新规则放在长度检查之后。",
        answer: r'''
String? letters(String value) => RegExp(r'^[a-z]+$').hasMatch(value) ? null : '仅限小写字母';
void main() {
  for (final value in ['dart', 'dart3']) print(letters(value) ?? '通过');
}
''',
      ),
    ],
    exampleTitle: "示例 284：可组合的检查规则链",
    exampleSummary: "把规则存储为函数列表。程序按顺序运行规则，遇到首次失败就停止。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-285',
    chapter: "apis-contracts",
    level: "intermediate",
    title: "区分缺失、长度与数值范围",
    summary: "按字段类型验证资料，拒绝把解析失败当作零。",
    concepts: <String>["字段校验", "tryParse", "错误归属"],
    explain:
        "资料表单里的必填、文本长度和数值范围是不同种类的约束。程序分别读取姓名和年龄文本。姓名先 trim 再检查长度。年龄先尝试解析，解析成功后才判断合法范围。这样程序不会把“不是数字”和“数字越界”混成同一个问题。程序也不会把失败结果默认成零。示例故意让姓名过短、年龄超限，再用合法资料验证通过路径。每条消息都带字段名，方便界面定位。这里按字符串长度检查 ASCII 示例姓名。真实用户姓名不能随意套用相同限制。应按产品规则和 Unicode 字符边界另外定义。",
    objective: "能把字段缺失、解析失败与范围失败分开报告。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "int.tryParse 返回 null 时不能直接使用 ?? 0 掩盖失败。",
      "先 trim 再检查必填，避免全空格通过检查。",
    ],
    code: r'''
List<String> validateProfile(String name, String ageText) {
  final errors = <String>[];
  final clean = name.trim();
  if (clean.isEmpty) { errors.add('name:必填'); }
  else if (clean.length < 2 || clean.length > 12) { errors.add('name:长度2到12'); }
  final age = int.tryParse(ageText.trim());
  if (age == null) { errors.add('age:必须为整数'); }
  else if (age < 0 || age > 130) { errors.add('age:范围0到130'); }
  return errors;
}
void main() {
  print(validateProfile(' A ', '131'));
  print(validateProfile('Ada', '27'));
  print(validateProfile('   ', 'unknown'));
}
''',
    output: "[name:长度2到12, age:范围0到130]\n[]\n[name:必填, age:必须为整数]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "对商品数量区分未填写、不是整数和小于一三种错误。",
        hint: "按信息缺失、解析、业务范围的顺序判断。",
        answer: r'''
String quantityError(String text) {
  if (text.trim().isEmpty) return '必填';
  final value = int.tryParse(text);
  if (value == null) return '必须为整数';
  return value < 1 ? '至少一件' : '通过';
}
void main() { for (final value in ['', 'x', '0', '2']) print(quantityError(value)); }
''',
      ),
    ],
    exampleTitle: "示例 285：区分缺失、长度与数值范围",
    exampleSummary: "按字段类型验证资料，拒绝把解析失败当作零。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-286',
    chapter: "apis-contracts",
    level: "intermediate",
    title: "聚合错误并保留记录位置",
    summary: "遍历所有记录与字段，把错误组织为可定位的列表。",
    concepts: <String>["错误聚合", "记录索引", "结构化消息"],
    explain:
        "批量导入时逐条修完一个错误再重新运行会很低效，聚合检查可以一次收集全部问题。程序对每条商品记录分别检查编号和数量，把行号、字段名、原因组成明确消息后加入列表。它不会因为第一条记录失败就停止，因此程序也能发现第二条记录的问题。示例用从一开始的行号方便读者定位，并把同一行的不同问题分别报告。这个阶段只做验证，不修改数据，也不导入部分记录。实际导入是否允许部分成功，应在后续流程单独定义。否则用户可能看到错误消息，却不知道哪些数据已经写入。",
    objective: "能收集批量数据的所有可定位错误。能保持验证阶段没有副作用。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["错误集合要在整批开始时生成，不能每行重新覆盖。", "聚合错误不等于自动跳过坏记录并继续写入。"],
    code: r'''
void main() {
  final rows = [
    {'sku': '', 'qty': '-2'}, {'sku': 'A1', 'qty': 'x'}, {'sku': 'B2', 'qty': '3'},
  ];
  final errors = <String>[];
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    if (row['sku']!.isEmpty) errors.add('行${i + 1}.sku:必填');
    final qty = int.tryParse(row['qty']!);
    if (qty == null || qty < 1) errors.add('行${i + 1}.qty:正整数');
  }
  for (final error in errors) print(error);
  print('错误数:${errors.length}');
}
''',
    output: "行1.sku:必填\n行1.qty:正整数\n行2.qty:正整数\n错误数:3\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "按行统计错误数量，输出哪些行可以直接通过验证。",
        hint: "每行开始时记录错误列表长度。结束后比较增量。",
        answer: r'''
void main() {
  final values = ['', 'ok', ''];
  final errors = <String>[];
  for (var i = 0; i < values.length; i++) {
    final before = errors.length;
    if (values[i].isEmpty) errors.add('必填');
    print('行${i + 1}:${errors.length == before ? '通过' : '失败'}');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 286：聚合错误并保留记录位置",
    exampleSummary: "遍历所有记录与字段，把错误组织为可定位的列表。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-287',
    chapter: "apis-contracts",
    level: "intermediate",
    title: "三段版本号数值比较",
    summary: "逐段解析并比较版本号，避免文本排序把十排在二之前。",
    concepts: <String>["版本元组", "逐段比较", "输入契约"],
    explain:
        "版本号不是普通小数，也不能按整段字符串排序。程序只接受主版本、次版本、修订号三段非负整数。程序先用完整正则验证格式。程序再把每一段解析成整数，按从左到右的顺序比较。找到第一处不同时即可返回大小关系，其后段落不再影响结果。示例包含二和十的次版本比较，以及修订号的增量。这里明确不支持预发布标签、构建元数据和省略段落，是一个受限三段版本协议。若要完整语义化版本排序，应扩展解析模型和规则。而不是在现有函数里随意剥掉后缀。",
    objective: "能实现三段版本号的数值顺序，并明确支持的输入范围。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "字符串比较会把 1.10.0 错排在 1.2.0 之前。",
      "版本号不能通过 double.parse 转成普通小数。",
    ],
    code: r'''
List<int> parts(String text) {
  if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(text)) throw FormatException('三段版本号');
  return text.split('.').map(int.parse).toList();
}
int compareVersion(String a, String b) {
  final left = parts(a);
  final right = parts(b);
  for (var i = 0; i < 3; i++) {
    final result = left[i].compareTo(right[i]);
    if (result != 0) return result;
  }
  return 0;
}
void main() {
  print(compareVersion('1.10.0', '1.2.9'));
  print(compareVersion('2.0.0', '2.0.1'));
  print(compareVersion('1.2.3', '1.2.3'));
}
''',
    output: "1\n-1\n0\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把一组版本号按数值顺序排序，验证 1.9.0 在 1.10.0 前。",
        hint: "排序比较器中逐段比较整数。",
        answer: r'''
int compare(String a, String b) {
  final x = a.split('.').map(int.parse).toList();
  final y = b.split('.').map(int.parse).toList();
  for (var i = 0; i < 3; i++) { final c = x[i].compareTo(y[i]); if (c != 0) return c; }
  return 0;
}
void main() { final versions = ['1.10.0', '1.2.0', '1.9.0']..sort(compare); print(versions); }
''',
      ),
    ],
    exampleTitle: "示例 287：三段版本号数值比较",
    exampleSummary: "逐段解析并比较版本号，避免文本排序把十排在二之前。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-288',
    chapter: "apis-contracts",
    level: "intermediate",
    title: "受限 caret 与 tilde 版本范围",
    summary: "从基线推导排除上界，正确处理零主版本的 caret。",
    concepts: <String>["版本范围", "半开区间", "兼容边界"],
    explain:
        "依赖范围可以理解为包含最低版本、排除某个上界的区间。程序限定输入为完整三段数字。caret 在主版本非零时允许到下一个主版本之前。主版本为零时，caret 把边界收紧到首个非零段。tilde 则允许到下一个次版本之前。示例覆盖常规主版本和零主版本，验证区间排除边界版本。这里是明确受限的范围计算练习，不解析预发布、逻辑或、通配符或多个约束，也不接入任何包下载。真实包管理器的完整协议不能只凭这几个分支代替，应采用其正式解析库并测试更多边界。",
    objective: "能把受限版本约束转换成明确上下界。能识别零版本的特殊规则。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["^0.2.3 不能放宽到所有 0.x 版本。", "上界是排除的，等于上界的版本不能匹配。"],
    code: r'''
int compare(List<int> a, List<int> b) {
  for (var i = 0; i < 3; i++) { final c = a[i].compareTo(b[i]); if (c != 0) return c; }
  return 0;
}
List<int> version(String value) {
  if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(value)) throw FormatException('版本');
  return value.split('.').map(int.parse).toList();
}
bool matches(String value, String constraint) {
  if (!constraint.startsWith('^') && !constraint.startsWith('~')) throw FormatException('约束');
  final base = version(constraint.substring(1));
  final current = version(value);
  final upper = constraint.startsWith('~') ? [base[0], base[1] + 1, 0]
    : base[0] > 0 ? [base[0] + 1, 0, 0]
    : base[1] > 0 ? [0, base[1] + 1, 0] : [0, 0, base[2] + 1];
  return compare(current, base) >= 0 && compare(current, upper) < 0;
}
void main() {
  print(matches('1.9.0', '^1.2.3'));
  print(matches('2.0.0', '^1.2.3'));
  print(matches('0.3.0', '^0.2.3'));
  print(matches('1.3.0', '~1.2.3'));
}
''',
    output: "true\nfalse\nfalse\nfalse\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "验证 ^0.0.3 允许 0.0.3 但拒绝 0.0.4。",
        hint: "首个非零段落是修订号时，上界只增加修订号。",
        answer: r'''
void main() {
  const base = 3;
  for (final patch in [2, 3, 4]) {
    print('0.0.$patch:${patch >= base && patch < base + 1}');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 288：受限 caret 与 tilde 版本范围",
    exampleSummary: "从基线推导排除上界，正确处理零主版本的 caret。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-289',
    chapter: "apis-contracts",
    level: "intermediate",
    title: "带允许键清单的配置覆盖",
    summary: "复制默认值后应用合法覆盖项，对未知键立即抛出错误。",
    concepts: <String>["默认值", "白名单", "浅合并"],
    explain:
        "配置覆盖不仅是把两张 Map 展开，还要决定哪些字段允许修改。程序先复制默认配置。程序再逐项检查覆盖键是否存在于默认表。遇到未知键就直接抛出格式错误，以便尽早发现拼写失误。合法字段才会写入结果，默认值对象保持不变。示例覆盖重试次数并保留离线模式，再验证未知字段的失败路径。这里采用一层平面配置，值都必须非空。嵌套映射不会自动递归合并。空值也没有表示删除的特殊意义。如果需要这些能力，应写出明确契约。契约应包含合并深度、类型检查和删除语义。",
    objective: "能在不修改默认对象的情况下应用受控配置，并拒绝未知键。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["简单展开会静默接受拼错字段。", "浅合并不会自动合并嵌套 Map 内部的键。"],
    code: r'''
Map<String, Object> configure(Map<String, Object> defaults, Map<String, Object> overrides) {
  final result = Map<String, Object>.from(defaults);
  for (final entry in overrides.entries) {
    if (!defaults.containsKey(entry.key)) throw FormatException('未知配置:${entry.key}');
    result[entry.key] = entry.value;
  }
  return result;
}
void main() {
  final defaults = <String, Object>{'mode': 'offline', 'retries': 2};
  print(configure(defaults, {'retries': 4}));
  print(defaults);
  try { configure(defaults, {'retry': 4}); }
  on FormatException { print('拒绝未知配置'); }
}
''',
    output:
        "{mode: offline, retries: 4}\n{mode: offline, retries: 2}\n拒绝未知配置\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "为 retries 增加整数且非负的检查，拒绝字符串和负数。",
        hint: "键检查后还需要值类型与范围检查。",
        answer: r'''
void main() {
  for (final value in <Object>[3, '3', -1]) {
    final valid = value is int && value >= 0;
    print('$value:$valid');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 289：带允许键清单的配置覆盖",
    exampleSummary: "复制默认值后应用合法覆盖项，对未知键立即抛出错误。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-290',
    chapter: "apis-contracts",
    level: "advanced",
    title: "可测试的固定窗口限流",
    summary: "注入事件时间戳，按窗口编号限制每个窗口的成功次数。",
    concepts: <String>["固定窗口", "注入时钟", "计数策略"],
    explain:
        "限流逻辑不必依赖真实等待才能测试，可以把当前时间作为显式参数传入。程序用毫秒时间戳整除窗口长度得到窗口编号。每个窗口最多允许两次请求，只在允许时增加计数。示例输入跨越两个窗口。程序验证窗口拒绝第三次请求，而新窗口重新获得额度。它实现真实的窗口判定算法，并不是通过打印计数模拟超时。固定窗口在边界附近可能短时放行两倍额度。这是算法本身的特点。历史窗口清理和多客户端分组在真实服务中还需单独实现。本例只显示单客户端离线事件序列。",
    objective: "能用可注入时间编写确定性的固定窗口限流。能说明边界突发特点。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["不要把拒绝的请求也算成成功消费额度，除非契约如此规定。", "窗口编号是时间除以窗口长度，不是请求序号。"],
    code: r'''
class WindowLimiter {
  WindowLimiter(this.limit, this.windowMs);
  final int limit;
  final int windowMs;
  final Map<int, int> counts = {};
  bool allow(int nowMs) {
    final window = nowMs ~/ windowMs;
    final used = counts[window] ?? 0;
    if (used >= limit) return false;
    counts[window] = used + 1;
    return true;
  }
}
void main() {
  final limiter = WindowLimiter(2, 1000);
  for (final time in [0, 100, 300, 1000, 1100, 1900]) {
    print('$time:${limiter.allow(time)}');
  }
}
''',
    output: "0:true\n100:true\n300:false\n1000:true\n1100:true\n1900:false\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "用 999 和 1000 两个边界时间说明窗口会重置。",
        hint: "对两个时间分别求整除一千后的编号。",
        answer: r'''
void main() {
  final counts = <int, int>{};
  for (final time in [999, 999, 1000, 1000]) {
    final window = time ~/ 1000;
    final used = counts[window] ?? 0;
    final allowed = used < 1;
    if (allowed) counts[window] = used + 1;
    print('$time:$allowed');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 290：可测试的固定窗口限流",
    exampleSummary: "注入事件时间戳，按窗口编号限制每个窗口的成功次数。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-291',
    chapter: "apis-contracts",
    level: "advanced",
    title: "保留余量的整数令牌桶",
    summary: "按注入时间补充令牌，容量封顶并保留不足补充周期的余时。",
    concepts: <String>["令牌桶", "时间余数", "容量限制"],
    explain:
        "令牌桶允许在积累额度后短时突发，又按固定速率补充额度。程序从满桶开始。程序根据当前时间与上次补充时间的差求出完整周期。程序只补充完整周期对应的令牌。程序把记录时间推进这些周期。因此不足一个周期的余时不会丢失。令牌数不能超过容量，每次成功请求消耗一个。时间作为输入传入，示例可直接验证连续请求、等待补充和满桶封顶。它是确定性的时钟驱动算法，不使用真实睡眠或联网。真实并发环境还需要原子更新。本课对象只适合顺序调用，并拒绝时间倒退。",
    objective: "能实现有容量和余时保护的令牌桶，并使用确定性时间测试。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["每次调用都把补充时间设成 now，会丢失不足周期的余时。", "补充必须封顶，否则长时间空闲后会无限积累。"],
    code: r'''
class TokenBucket {
  TokenBucket(this.capacity, this.intervalMs) : tokens = capacity;
  final int capacity;
  final int intervalMs;
  int tokens;
  int lastRefill = 0;
  int lastSeen = 0;
  bool allow(int now) {
    if (now < lastSeen) throw ArgumentError('时间倒退');
    lastSeen = now;
    final periods = (now - lastRefill) ~/ intervalMs;
    final available = tokens + periods;
    tokens = available > capacity ? capacity : available;
    lastRefill += periods * intervalMs;
    if (tokens == 0) return false;
    tokens--;
    return true;
  }
}
void main() {
  final bucket = TokenBucket(2, 100);
  for (final time in [0, 0, 50, 100, 100, 350, 350, 350]) {
    print('$time:${bucket.allow(time)} 剩余${bucket.tokens}');
  }
}
''',
    output:
        "0:true 剩余1\n0:true 剩余0\n50:false 剩余0\n100:true 剩余0\n100:false 剩余0\n350:true 剩余1\n350:true 剩余0\n350:false 剩余0\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "验证容量一、周期一百时的行为。五十毫秒的拒绝不会把下一次补充推迟到一百五十。",
        hint: "只按完整补充周期推进 lastRefill，拒绝不重置它。",
        answer: r'''
void main() {
  var tokens = 0;
  var lastRefill = 0;
  for (final now in [50, 100]) {
    final periods = (now - lastRefill) ~/ 100;
    if (periods > 0) tokens = 1;
    lastRefill += periods * 100;
    final allowed = tokens > 0;
    if (allowed) tokens--;
    print('$now:$allowed');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 291：保留余量的整数令牌桶",
    exampleSummary: "按注入时间补充令牌，容量封顶并保留不足补充周期的余时。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-292',
    chapter: "apis-contracts",
    level: "advanced",
    title: "两种实现共享接口契约",
    summary: "对 Map 和列表两种存储运行同一组读写契约检查。",
    concepts: <String>["抽象接口", "替换原则", "契约测试"],
    explain:
        "接口一致不仅指方法名字相同，还要求可观察行为遵守同一契约。程序定义简单整数存储接口，分别用 Map 和平行列表实现。统一检查函数验证缺失键返回 null。函数还验证写入后可读与同名键覆盖。不同键必须互不干扰，任何一项不符都抛出失败。示例没有依赖可能在发布模式关闭的 assert，因此检查始终运行。两种内部结构不同，却向调用者提供同样行为，说明替换实现时应该保护外部语义。这里只验证核心读写约定。性能、并发与持久化并未纳入接口。不能由这几项通过就宣称两个实现完全等价。",
    objective: "能以同一组可运行契约验证不同实现，而不依赖内部结构。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "只比较两个实现的一次输出，可能让相同错误同时通过。",
      "发布模式可能关闭 assert，关键契约检查不能仅依赖它。",
    ],
    code: r'''
abstract class IntStore { void put(String key, int value); int? get(String key); }
class MapStore implements IntStore {
  final Map<String, int> data = {};
  void put(String key, int value) { data[key] = value; }
  int? get(String key) => data[key];
}
class ListStore implements IntStore {
  final List<String> keys = [];
  final List<int> values = [];
  void put(String key, int value) {
    final index = keys.indexOf(key);
    if (index < 0) { keys.add(key); values.add(value); }
    else { values[index] = value; }
  }
  int? get(String key) { final i = keys.indexOf(key); return i < 0 ? null : values[i]; }
}
void verify(IntStore store, String name) {
  if (store.get('missing') != null) throw StateError('缺失契约');
  store.put('a', 1); store.put('a', 2); store.put('b', 3);
  if (store.get('a') != 2 || store.get('b') != 3) throw StateError('读写契约');
  print('$name:通过');
}
void main() { verify(MapStore(), 'Map'); verify(ListStore(), 'List'); }
''',
    output: "Map:通过\nList:通过\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "补充空字符串键的契约：允许写入并读取，不应与缺失键混淆。",
        hint: "先明确空键合法。再对每个实现运行相同检查。",
        answer: r'''
void verify(Map<String, int> store) {
  store[''] = 7;
  if (store[''] != 7 || store['missing'] != null) throw StateError('契约失败');
  print('空键通过');
}
void main() { verify(<String, int>{}); }
''',
      ),
    ],
    exampleTitle: "示例 292：两种实现共享接口契约",
    exampleSummary: "对 Map 和列表两种存储运行同一组读写契约检查。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-293',
    chapter: "apis-contracts",
    level: "advanced",
    title: "数据迁移与明确拒绝报告",
    summary: "验证旧字段后生成新结构，记录成功和拒绝的条数。",
    concepts: <String>["schemaVersion", "迁移管线", "输入不变"],
    explain:
        "数据迁移应先验证旧记录，再生成新结构，不能仅改字段名就假定数据可用。程序读取旧的姓名和年龄文本，清理姓名并解析年龄，通过后生成带 schemaVersion 的新 Map。程序不会把无效记录偷偷修成零岁，而是增加拒绝数量。输出既显示成功数据，也报告成功与失败的总数，方便检查输入是否完整处理。程序不修改原记录，调用者可以保留备份或重新尝试。示例不写入磁盘，因此不涉及事务提交。真实迁移还需要备份、幂等与失败恢复策略。它还要确保计数报告与实际持久化结果一致。",
    objective: "能编写先验证后转换的迁移流程，并保留完整处理计数。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["把解析失败默认成零会制造看似合法的坏数据。", "迁移时原地改旧 Map，失败后可能无法恢复原始输入。"],
    code: r'''
void main() {
  final oldRows = [
    {'name': ' Ada ', 'age': '27'}, {'name': '', 'age': 'x'}, {'name': 'Bo', 'age': '30'},
  ];
  final migrated = <Map<String, Object>>[];
  var rejected = 0;
  for (final row in oldRows) {
    final name = row['name']!.trim();
    final age = int.tryParse(row['age']!);
    if (name.isEmpty || age == null || age < 0) { rejected++; continue; }
    migrated.add({'schemaVersion': 2, 'displayName': name, 'ageYears': age});
  }
  for (final row in migrated) print(row);
  print('成功${migrated.length} 拒绝$rejected 输入${oldRows.length}');
}
''',
    output:
        "{schemaVersion: 2, displayName: Ada, ageYears: 27}\n{schemaVersion: 2, displayName: Bo, ageYears: 30}\n成功2 拒绝1 输入3\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "增加年龄上限一百三十。再报告拒绝记录的原始行号。",
        hint: "验证条件中加入上限，错误报告保留输入位置。",
        answer: r'''
void main() {
  final ages = ['20', '131', 'bad'];
  for (var i = 0; i < ages.length; i++) {
    final age = int.tryParse(ages[i]);
    if (age == null || age < 0 || age > 130) print('拒绝行${i + 1}');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 293：数据迁移与明确拒绝报告",
    exampleSummary: "验证旧字段后生成新结构，记录成功和拒绝的条数。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-294',
    chapter: "apis-contracts",
    level: "advanced",
    title: "新旧字段兼容与冲突检测",
    summary: "同时支持旧字段和新字段，二者不一致时明确拒绝。",
    concepts: <String>["兼容层", "字段优先级", "冲突检测"],
    explain:
        "接口升级期间可能同时遇到旧字段 name 和新字段 displayName。程序接受任意一种形式。程序先验证存在字段的类型。程序再处理两者同时出现的情况。若清理后值不同就抛出冲突错误，而不是随意选择一个。两者相同则返回统一的内部名称，后续业务只需处理一种结构。示例覆盖旧版、新版、一致双字段和冲突双字段，显示兼容策略的完整边界。兼容层不应无限保留。实际产品还应记录旧字段使用情况并规划弃用时间。这里仅解决离线对象的字段适配，不声称完成所有版本协议转换。",
    objective: "能把多版本字段统一成内部模型，并拒绝含糊的冲突输入。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "无条件优先新字段可能掩盖上游同时发送的不一致数据。",
      "类型错误不应通过 toString 悄悄变成可接受文本。",
    ],
    code: r'''
String readName(Map<String, Object?> row) {
  final old = row['name'];
  final current = row['displayName'];
  if ((old != null && old is! String) || (current != null && current is! String)) {
    throw FormatException('名称类型');
  }
  final a = old == null ? null : (old as String).trim();
  final b = current == null ? null : (current as String).trim();
  if (a != null && b != null && a != b) throw FormatException('名称冲突');
  final name = b ?? a;
  if (name == null || name.isEmpty) throw FormatException('名称必填');
  return name;
}
void main() {
  print(readName({'name': 'Ada'}));
  print(readName({'displayName': 'Bo'}));
  print(readName({'name': 'Chen', 'displayName': ' Chen '}));
  try { readName({'name': 'old', 'displayName': 'new'}); }
  on FormatException { print('拒绝冲突'); }
}
''',
    output: "Ada\nBo\nChen\n拒绝冲突\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "让仅有空白的新字段不能覆盖有效旧字段。契约要求此时抛出错误。",
        hint: "先验证每个已提供字段非空。再决定是否兼容合并。",
        answer: r'''
void main() {
  final row = {'name': 'Ada', 'displayName': '   '};
  final value = row['displayName'];
  if (value != null && value.trim().isEmpty) { print('新字段不能为空'); }
  else { print(value ?? row['name']); }
}
''',
      ),
    ],
    exampleTitle: "示例 294：新旧字段兼容与冲突检测",
    exampleSummary: "同时支持旧字段和新字段，二者不一致时明确拒绝。完整运行演示。",
  ),
];
