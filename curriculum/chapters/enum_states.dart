import '../dart_lesson.dart';

/// Independent, offline programs for chapter `enum-states`.
const List<DartLesson> enumStatesLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-205',
    chapter: 'enum-states',
    level: 'beginner',
    title: "枚举状态的中文标签",
    summary: "集中转换配送状态的显示文字，保持业务值与界面文案分离。",
    concepts: <String>["枚举", "switch 分派", "展示映射"],
    explain:
        "业务状态应使用一组封闭的值，而界面需要面向读者的文字。枚举定义合法状态。标签函数再把每个状态映射为中文。这样避免在各处散落字符串比较。本例逐项显示配送状态和对应标签，说明状态本身不应随着界面文案变化而变化。使用完整分支可以让新增状态时的遗漏更容易发现。若随意给所有未知情况一个默认标签，可能掩盖业务扩展后的缺口。程序没有网络配送请求，只运行本地状态到文字的确定性转换，离线即可直接修改和观察。",
    objective: "能把封闭业务状态转换为独立的中文显示文字。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["不要将面向用户的标签保存为核心业务状态。", "新增枚举成员后，要同步审查所有状态分派。"],
    code: r'''
enum ParcelState { packed, inTransit, delivered }
String label(ParcelState state) {
  switch (state) {
    case ParcelState.packed: return '已打包';
    case ParcelState.inTransit: return '运输中';
    case ParcelState.delivered: return '已送达';
  }
}
void main() {
  for (final state in ParcelState.values) {
    print('${state.name}: ${label(state)}');
  }
}
''',
    output: "packed: 已打包\ninTransit: 运输中\ndelivered: 已送达\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "为每种配送状态增加是否允许取消的判定。",
        hint: "用枚举分支表达规则，只允许打包状态取消。",
        answer: r'''
enum ParcelState { packed, inTransit, delivered }
String label(ParcelState state) {
  switch (state) {
    case ParcelState.packed: return '已打包';
    case ParcelState.inTransit: return '运输中';
    case ParcelState.delivered: return '已送达';
  }
}

bool canCancel(ParcelState state) {
  switch (state) {
    case ParcelState.packed: return true;
    case ParcelState.inTransit:
    case ParcelState.delivered: return false;
  }
}
void main() {
  for (final state in ParcelState.values) { print('${state.name}: ${canCancel(state)}'); }
}
''',
      ),
    ],
    exampleTitle: "示例 205：枚举状态的中文标签",
    exampleSummary: "运行示例。观察集中转换配送状态的显示文字，保持业务值与界面文案分离。",
  ),
  DartLesson(
    id: 'dart-lesson-206',
    chapter: 'enum-states',
    level: 'beginner',
    title: "有顺序的优先级",
    summary: "在局部排序中使用枚举索引，并区分顺序与持久标识。",
    concepts: <String>["enum.index", "排序比较", "稳定标识"],
    explain:
        "当枚举声明顺序本身表达等级时，索引可以用于局部优先级比较。本例把普通、紧急和立即处理三个等级排成递增顺序。排序时反向比较索引，使最紧急的工单最先出现。相同等级再用编号排序，保证输出稳定。索引从零开始，并会随着声明顺序变化，因此不适合作为数据库或交换格式中的永久编码。若业务等级需要长期稳定，应显式定义权重或代码。示例只排序内存中的固定工单，离线即可验证主次排序规则。",
    objective: "能使用索引表达局部顺序，并为相同优先级规定稳定次序。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "调整枚举成员顺序会改变 index，不要直接持久化它。",
      "比较器还应处理同优先级，避免结果依赖原始输入顺序。",
    ],
    code: r'''
enum Priority { normal, urgent, immediate }
class Ticket {
  Ticket(this.id, this.priority);
  final String id;
  final Priority priority;
}
void main() {
  final tickets = [Ticket('B', Priority.urgent), Ticket('C', Priority.normal),
    Ticket('A', Priority.urgent), Ticket('D', Priority.immediate)];
  tickets.sort((a, b) {
    final order = b.priority.index.compareTo(a.priority.index);
    return order == 0 ? a.id.compareTo(b.id) : order;
  });
  for (final ticket in tickets) { print('${ticket.id}: ${ticket.priority.name}'); }
}
''',
    output: "D: immediate\nA: urgent\nB: urgent\nC: normal\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "改用显式权重函数，使紧急等级的权重不依赖声明顺序。",
        hint: "为三个成员分别返回十、一百和一千。再比较返回值。",
        answer: r'''
enum Priority { normal, urgent, immediate }
class Ticket {
  Ticket(this.id, this.priority);
  final String id;
  final Priority priority;
}

int weight(Priority value) {
  switch (value) {
    case Priority.normal: return 10;
    case Priority.urgent: return 100;
    case Priority.immediate: return 1000;
  }
}
void main() {
  final priorities = Priority.values.toList()..sort((a, b) => weight(b).compareTo(weight(a)));
  for (final priority in priorities) { print('${priority.name}: ${weight(priority)}'); }
}
''',
      ),
    ],
    exampleTitle: "示例 206：有顺序的优先级",
    exampleSummary: "运行示例。观察在局部排序中使用枚举索引，并区分顺序与持久标识。",
  ),
  DartLesson(
    id: 'dart-lesson-207',
    chapter: 'enum-states',
    level: 'intermediate',
    title: "枚举键统计反馈",
    summary: "用封闭类别建立频数表，并显示没有出现过的类别。",
    concepts: <String>["枚举键", "Map 累加", "零频类别"],
    explain:
        "问卷反馈只有有限几种合法类别时，枚举比任意字符串更容易约束输入。以枚举为映射键，统计代码不必担心同一类别出现不同拼写。本例先为所有反馈类别建立零计数。程序再逐项累加。最后按枚举顺序打印完整报表。因此即使某种反馈没有出现，也会明确显示零，而不会从结果中消失。这样的零频类别对于比较不同批次尤其重要。类别标签与统计逻辑分开处理，可以自由改变显示文案。所有反馈预置在程序内，离线运行没有外部依赖。",
    objective: "能用枚举构建完整频数表，并保留零计数类别。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["只在出现时建立键，会漏掉零频类别。", "显示顺序最好按枚举或业务规则明确指定。"],
    code: r'''
enum Feedback { useful, unclear, incorrect, skipped }
void main() {
  final votes = [Feedback.useful, Feedback.unclear, Feedback.useful,
    Feedback.incorrect, Feedback.useful, Feedback.unclear];
  final counts = <Feedback, int>{for (final value in Feedback.values) value: 0};
  for (final vote in votes) { counts[vote] = counts[vote]! + 1; }
  for (final value in Feedback.values) {
    print('${value.name}: ${counts[value]}');
  }
  print('总数 ${counts.values.reduce((a, b) => a + b)}');
}
''',
    output: "useful: 3\nunclear: 2\nincorrect: 1\nskipped: 0\n总数 6\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "给每一类反馈显示占比，保留一位小数。同时处理空问卷。",
        hint: "总数为零时占比定义为零，避免除零。",
        answer: r'''
enum Feedback { useful, unclear, incorrect, skipped }

String percentage(int count, int total) =>
    total == 0 ? '0.0%' : '${(count * 100 / total).toStringAsFixed(1)}%';
void main() {
  final votes = [Feedback.useful, Feedback.unclear, Feedback.useful,
    Feedback.incorrect, Feedback.useful, Feedback.unclear];
  final counts = <Feedback, int>{for (final value in Feedback.values) value: 0};
  for (final vote in votes) { counts[vote] = counts[vote]! + 1; }
  for (final value in Feedback.values) {
    print('${value.name}: ${percentage(counts[value]!, votes.length)}');
  }
  print('空问卷 ${percentage(0, 0)}');
}
''',
      ),
    ],
    exampleTitle: "示例 207：枚举键统计反馈",
    exampleSummary: "运行示例。观察用封闭类别建立频数表，并显示没有出现过的类别。",
  ),
  DartLesson(
    id: 'dart-lesson-208',
    chapter: 'enum-states',
    level: 'intermediate',
    title: "订单允许迁移表",
    summary: "用状态到后继状态的集合描述订单流程，并明确拒绝逆向操作。",
    concepts: <String>["状态迁移", "邻接表", "业务约束"],
    explain:
        "订单流程不是任意状态之间都能跳转。例如待支付可以取消，已经发货则不能重新变为待支付。迁移表把允许的后继状态集中列出。查询时只检查当前状态对应的集合。这样比在多个按钮里重复条件更容易审查。本例先运行一次合法付款。再尝试取消和倒退。只有允许的操作才更新当前状态。终态也在表中显式保留空集合，说明它们没有后继状态。表描述业务规则而非网络调用。固定请求序列能够在离线环境中完整复现接受与拒绝的过程。",
    objective: "能根据迁移表控制状态改变，并保持拒绝后的原状态。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["拒绝迁移时不要提前更新当前状态。", "终态的空集合与遗漏配置含义不同，应显式列出。"],
    code: r'''
enum OrderState { pending, paid, shipped, cancelled }
const transitions = <OrderState, Set<OrderState>>{
  OrderState.pending: {OrderState.paid, OrderState.cancelled},
  OrderState.paid: {OrderState.shipped},
  OrderState.shipped: <OrderState>{},
  OrderState.cancelled: <OrderState>{},
};
void main() {
  var current = OrderState.pending;
  for (final target in [OrderState.paid, OrderState.cancelled,
      OrderState.shipped, OrderState.pending]) {
    final allowed = transitions[current]!.contains(target);
    print('${current.name} -> ${target.name}: $allowed');
    if (allowed) current = target;
  }
  print('最终 ${current.name}');
}
''',
    output:
        "pending -> paid: true\npaid -> cancelled: false\npaid -> shipped: true\nshipped -> pending: false\n最终 shipped\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "增加退款终态，只允许已支付状态迁移到退款。",
        hint: "扩展枚举、paid 的后继集合和退款的空集合。",
        answer: r'''
enum OrderState { pending, paid, shipped, cancelled }
const transitions = <OrderState, Set<OrderState>>{
  OrderState.pending: {OrderState.paid, OrderState.cancelled},
  OrderState.paid: {OrderState.shipped},
  OrderState.shipped: <OrderState>{},
  OrderState.cancelled: <OrderState>{},
};

enum RefundState { pending, paid, shipped, cancelled, refunded }
const refundRoutes = <RefundState, Set<RefundState>>{
  RefundState.pending: {RefundState.paid, RefundState.cancelled},
  RefundState.paid: {RefundState.shipped, RefundState.refunded},
  RefundState.shipped: <RefundState>{},
  RefundState.cancelled: <RefundState>{},
  RefundState.refunded: <RefundState>{},
};
bool canMove(RefundState from, RefundState to) => refundRoutes[from]!.contains(to);
void main() {
  print(canMove(RefundState.paid, RefundState.refunded));
  print(canMove(RefundState.shipped, RefundState.refunded));
}
''',
      ),
    ],
    exampleTitle: "示例 208：订单允许迁移表",
    exampleSummary: "运行示例。观察用状态到后继状态的集合描述订单流程，并明确拒绝逆向操作。",
  ),
  DartLesson(
    id: 'dart-lesson-209',
    chapter: 'enum-states',
    level: 'intermediate',
    title: "交通灯的循环状态机",
    summary: "把循环状态变化与每个状态的持续时间放在独立规则中。",
    concepts: <String>["有限状态机", "循环迁移", "状态时长"],
    explain:
        "交通灯是一个容易观察的有限状态机。绿灯结束后进入黄灯，黄灯结束后进入红灯。红灯结束后再返回绿灯。本例把下一状态和持续秒数分别写为函数，主循环只负责记录当前时刻并推进状态。这样增加日志或修改时间配置时，不需要复制状态切换逻辑。示例使用累计秒数推进模型，没有真实等待，也不会把计算过程伪装为硬件控制。教学重点是离散状态和累计时间的关系。程序的每一步都由明确规则计算，因此离线运行可以快速观察多个完整周期。",
    objective: "能把状态迁移与时间配置分离，并跟踪循环中的累计时刻。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["红黄绿顺序要由规则定义，不要把枚举索引当作交通规则。", "此处计算模型时间，不代表真实计时器的调度精度。"],
    code: r'''
enum Light { green, yellow, red }
Light next(Light light) {
  switch (light) {
    case Light.green: return Light.yellow;
    case Light.yellow: return Light.red;
    case Light.red: return Light.green;
  }
}
int seconds(Light light) {
  switch (light) {
    case Light.green: return 20;
    case Light.yellow: return 3;
    case Light.red: return 17;
  }
}
void main() {
  var light = Light.green;
  var elapsed = 0;
  for (var step = 0; step < 7; step++) {
    print('$elapsed 秒: ${light.name}');
    elapsed += seconds(light);
    light = next(light);
  }
}
''',
    output:
        "0 秒: green\n20 秒: yellow\n23 秒: red\n40 秒: green\n60 秒: yellow\n63 秒: red\n80 秒: green\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "计算连续十个完整周期的总秒数。",
        hint: "先把每个状态的时长相加。再乘周期数。",
        answer: r'''
enum Light { green, yellow, red }
Light next(Light light) {
  switch (light) {
    case Light.green: return Light.yellow;
    case Light.yellow: return Light.red;
    case Light.red: return Light.green;
  }
}
int seconds(Light light) {
  switch (light) {
    case Light.green: return 20;
    case Light.yellow: return 3;
    case Light.red: return 17;
  }
}

void main() {
  final cycle = Light.values.fold<int>(0, (sum, light) => sum + seconds(light));
  print(cycle * 10);
}
''',
      ),
    ],
    exampleTitle: "示例 209：交通灯的循环状态机",
    exampleSummary: "运行示例。观察把循环状态变化与每个状态的持续时间放在独立规则中。",
  ),
  DartLesson(
    id: 'dart-lesson-210',
    chapter: 'enum-states',
    level: 'intermediate',
    title: "字符分类驱动的小词法器",
    summary: "按当前类别合并连续数字和字母，并独立输出符号。",
    concepts: <String>["词法状态", "缓冲区", "边界刷新"],
    explain:
        "把字符串切成有意义的单元，需要记住刚才正在读取哪一种内容。本例把字符分成字母、数字、符号和空白四类。同类的字母或数字继续累积。类别改变时先输出缓冲区。符号则单独成词。空白只负责分隔，不进入结果。循环结束后必须再刷新一次，否则最后一个词会丢失。枚举让状态集合明确，缓冲区保存当前词，两者分别承担控制和数据职责。这里刻意限定为英文字符和十进制数字，程序可在离线环境中复现基本词法分析过程。",
    objective: "能用状态和缓冲区完成分词，并处理结尾刷新。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "循环结束后仍可能有尚未输出的词。",
      "字符分类规则需明确，此例不把中文或小数点自动当成字母或数字的一部分。",
    ],
    code: r'''
enum TokenKind { none, word, number, symbol }
TokenKind classify(String character) {
  if (RegExp(r'^[A-Za-z]$').hasMatch(character)) return TokenKind.word;
  if (RegExp(r'^[0-9]$').hasMatch(character)) return TokenKind.number;
  if (character.trim().isEmpty) return TokenKind.none;
  return TokenKind.symbol;
}
List<String> tokenize(String text) {
  final result = <String>[];
  var state = TokenKind.none;
  var buffer = '';
  void flush() {
    if (buffer.isNotEmpty) result.add('${state.name}:$buffer');
    buffer = '';
  }
  for (final character in text.split('')) {
    final kind = classify(character);
    if (kind != state || kind == TokenKind.symbol) flush();
    state = kind;
    if (kind != TokenKind.none) buffer += character;
    if (kind == TokenKind.symbol) flush();
  }
  flush();
  return result;
}
void main() { print(tokenize('sum12 + 34*x')); }
''',
    output: "[word:sum, number:12, symbol:+, number:34, symbol:*, word:x]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "允许下划线出现在标识符中，并验证 user_name 保持一个词。",
        hint: "在字母类别的正则字符集合中加入下划线。",
        answer: r'''
enum TokenKind { none, word, number, symbol }
TokenKind classify(String character) {
  if (RegExp(r'^[A-Za-z_]$').hasMatch(character)) return TokenKind.word;
  if (RegExp(r'^[0-9]$').hasMatch(character)) return TokenKind.number;
  if (character.trim().isEmpty) return TokenKind.none;
  return TokenKind.symbol;
}
List<String> tokenize(String text) {
  final result = <String>[];
  var state = TokenKind.none;
  var buffer = '';
  void flush() {
    if (buffer.isNotEmpty) result.add('${state.name}:$buffer');
    buffer = '';
  }
  for (final character in text.split('')) {
    final kind = classify(character);
    if (kind != state || kind == TokenKind.symbol) flush();
    state = kind;
    if (kind != TokenKind.none) buffer += character;
    if (kind == TokenKind.symbol) flush();
  }
  flush();
  return result;
}

void main() { print(tokenize('user_name + 2')); }
''',
      ),
    ],
    exampleTitle: "示例 210：字符分类驱动的小词法器",
    exampleSummary: "运行示例。观察按当前类别合并连续数字和字母，并独立输出符号。",
  ),
  DartLesson(
    id: 'dart-lesson-211',
    chapter: 'enum-states',
    level: 'intermediate',
    title: "关卡推进与生命数",
    summary: "把通关、重试和游戏结束表示为明确状态，保护终态不再前进。",
    concepts: <String>["游戏状态", "边界条件", "终态保护"],
    explain:
        "关卡流程同时包含当前位置和剩余机会。若只保存一个字符串状态，通关后很容易继续扣生命或多推进一关。本例使用枚举表示进行中、全部完成和机会耗尽，关卡号与生命数保存具体进度。成功时推进关卡。失败时扣除机会。任何终态收到后续结果都保持不变。两条固定结果序列分别覆盖完整通关和连续失败。读者能够比较相同方法在不同状态下的行为。这里计算的是游戏规则模型，没有图形或实时输入，离线即可完整验证边界。",
    objective: "能同时维护状态与进度，并保证终态吸收后续事件。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "最后一关成功时应进入完成状态，而不是产生不存在的新关卡。",
      "终态之后的重复事件不能继续扣生命或推进关卡。",
    ],
    code: r'''
enum GameState { playing, completed, exhausted }
class LevelGame {
  int level = 1;
  int lives = 2;
  GameState state = GameState.playing;
  void result(bool passed) {
    if (state != GameState.playing) return;
    if (passed) {
      if (level == 3) { state = GameState.completed; }
      else { level++; }
    } else {
      lives--;
      if (lives == 0) state = GameState.exhausted;
    }
  }
  @override
  String toString() => '${state.name}: 关卡=$level, 机会=$lives';
}
void main() {
  final first = LevelGame();
  for (final passed in [false, true, true, true, false]) { first.result(passed); }
  print(first);
  final second = LevelGame()..result(false)..result(false)..result(true);
  print(second);
}
''',
    output: "completed: 关卡=3, 机会=1\nexhausted: 关卡=1, 机会=0\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "增加重开方法，恢复第一关、两次机会和进行中状态。",
        hint: "一次恢复全部进度字段，避免只修改枚举而保留旧进度。",
        answer: r'''
enum GameState { playing, completed, exhausted }
class LevelGame {
  int level = 1;
  int lives = 2;
  GameState state = GameState.playing;
  void restart() {
    level = 1;
    lives = 2;
    state = GameState.playing;
  }
  void result(bool passed) {
    if (state != GameState.playing) return;
    if (passed) {
      if (level == 3) { state = GameState.completed; }
      else { level++; }
    } else {
      lives--;
      if (lives == 0) state = GameState.exhausted;
    }
  }
  @override
  String toString() => '${state.name}: 关卡=$level, 机会=$lives';
}

void main() {
  final game = LevelGame()..result(false)..result(false);
  print(game);
  game.restart();
  print(game);
}
''',
      ),
    ],
    exampleTitle: "示例 211：关卡推进与生命数",
    exampleSummary: "运行示例。观察把通关、重试和游戏结束表示为明确状态，保护终态不再前进。",
  ),
  DartLesson(
    id: 'dart-lesson-212',
    chapter: 'enum-states',
    level: 'advanced',
    title: "拒绝非法工作流迁移",
    summary: "在状态改变前检查审核流程，并用异常向调用者报告拒绝。",
    concepts: <String>["状态不变量", "StateError", "迁移历史"],
    explain:
        "审核工作流需要防止从草稿直接发布，也需要保留已经发生的合法历史。本例把迁移检查封装进对象方法。对象只写入后继表允许的目标状态，并仅在成功后追加历史。非法操作抛出状态错误，调用者捕获后继续完成正确流程。这样错误可见，内部状态却保持完整。最后输出状态历史能够检查每个已接受的步骤。但它只是当前进程中的记录，不等于持久审计系统。所有迁移请求固定，离线运行可观察失败前后的一致性。",
    objective: "能在对象方法中守住迁移契约，并只记录成功步骤。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["先更新状态再检查会让拒绝失去意义。", "记录历史时不要把失败请求伪装成已完成迁移。"],
    code: r'''
enum ReviewState { draft, submitted, approved, published }
class ReviewFlow {
  ReviewState state = ReviewState.draft;
  final history = <ReviewState>[ReviewState.draft];
  static const allowed = <ReviewState, Set<ReviewState>>{
    ReviewState.draft: {ReviewState.submitted},
    ReviewState.submitted: {ReviewState.approved},
    ReviewState.approved: {ReviewState.published},
    ReviewState.published: <ReviewState>{},
  };
  void move(ReviewState target) {
    if (!allowed[state]!.contains(target)) throw StateError('非法迁移');
    state = target;
    history.add(target);
  }
}
void main() {
  final flow = ReviewFlow();
  try { flow.move(ReviewState.published); }
  on StateError { print('拒绝直接发布，仍为 ${flow.state.name}'); }
  flow.move(ReviewState.submitted);
  flow.move(ReviewState.approved);
  flow.move(ReviewState.published);
  print(flow.history.map((state) => state.name).join(' -> '));
}
''',
    output: "拒绝直接发布，仍为 draft\ndraft -> submitted -> approved -> published\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "增加审核退回草稿的路径，并说明是否删除历史。",
        hint: "允许 submitted 到 draft。保留原历史。再追加新的 draft。",
        answer: r'''
enum ReviewState { draft, submitted, approved, published }
class ReviewFlow {
  ReviewState state = ReviewState.draft;
  final history = <ReviewState>[ReviewState.draft];
  static const allowed = <ReviewState, Set<ReviewState>>{
    ReviewState.draft: {ReviewState.submitted},
    ReviewState.submitted: {ReviewState.approved, ReviewState.draft},
    ReviewState.approved: {ReviewState.published},
    ReviewState.published: <ReviewState>{},
  };
  void move(ReviewState target) {
    if (!allowed[state]!.contains(target)) throw StateError('非法迁移');
    state = target;
    history.add(target);
  }
}

void main() {
  final flow = ReviewFlow();
  flow.move(ReviewState.submitted);
  flow.move(ReviewState.draft);
  flow.move(ReviewState.submitted);
  flow.move(ReviewState.approved);
  print(flow.history.map((state) => state.name).join(' -> '));
}
''',
      ),
    ],
    exampleTitle: "示例 212：拒绝非法工作流迁移",
    exampleSummary: "运行示例。观察在状态改变前检查审核流程，并用异常向调用者报告拒绝。",
  ),
  DartLesson(
    id: 'dart-lesson-213',
    chapter: 'enum-states',
    level: 'advanced',
    title: "角色与动作的权限矩阵",
    summary: "把权限规则集中成角色到动作集合的映射，并默认拒绝未授权动作。",
    concepts: <String>["角色枚举", "动作枚举", "默认拒绝"],
    explain:
        "权限判断同时涉及角色和动作，散落在界面中的条件容易出现不一致。用两个枚举限定合法值。再通过角色到动作集合的映射集中表达允许关系。这样能让审查变成查看一张小表。本例为访客、编辑者和管理员分别列出读取、修改和删除权限，并建立完整矩阵。查询函数对缺失配置返回拒绝，避免无意扩大权限。这个模型说明授权规则的组织方式。真实系统还需要在动作边界实施规则，不能只隐藏按钮。示例完全在本地内存计算，离线即可验证所有组合。",
    objective: "能建立二维权限模型，并保持缺失规则默认拒绝。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["界面隐藏不能代替底层授权。", "不要用枚举大小比较推导权限，角色之间未必是简单包含关系。"],
    code: r'''
enum Role { guest, editor, admin }
enum Action { read, write, delete }
const permissions = <Role, Set<Action>>{
  Role.guest: {Action.read},
  Role.editor: {Action.read, Action.write},
  Role.admin: {Action.read, Action.write, Action.delete},
};
bool allowed(Role role, Action action) => permissions[role]?.contains(action) ?? false;
void main() {
  print('角色 read write delete');
  for (final role in Role.values) {
    final cells = Action.values.map((action) => allowed(role, action) ? 'Y' : '-');
    print('${role.name} ${cells.join(' ')}');
  }
}
''',
    output: "角色 read write delete\nguest Y - -\neditor Y Y -\nadmin Y Y Y\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "新增只能读取和删除、不能修改的清理角色。",
        hint: "显式配置动作集合，不能通过角色 index 比较来实现。",
        answer: r'''
enum Role { guest, editor, admin, cleaner }
enum Action { read, write, delete }
const permissions = <Role, Set<Action>>{
  Role.cleaner: {Action.read, Action.delete},
  Role.guest: {Action.read},
  Role.editor: {Action.read, Action.write},
  Role.admin: {Action.read, Action.write, Action.delete},
};
bool allowed(Role role, Action action) => permissions[role]?.contains(action) ?? false;

void main() {
  for (final action in Action.values) {
    print('cleaner ${action.name}: ${allowed(Role.cleaner, action)}');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 213：角色与动作的权限矩阵",
    exampleSummary: "运行示例。观察把权限规则集中成角色到动作集合的映射，并默认拒绝未授权动作。",
  ),
  DartLesson(
    id: 'dart-lesson-214',
    chapter: 'enum-states',
    level: 'advanced',
    title: "连接状态机与事件报表",
    summary: "区分收到的事件和接受的迁移，建立可解释的状态统计。",
    concepts: <String>["事件驱动", "迁移计数", "可观察性"],
    explain:
        "只看最终状态无法解释过程，统计所有请求又可能把非法事件算成成功。本例使用当前状态和事件共同查询下一状态，同时分别记录收到次数与成功迁移次数。连接建立、就绪和断开形成正常路径。在错误时机收到就绪事件时，程序会拒绝它。最终报表显示每种事件的总数以及成功数，使读者能够追踪为何某个计数没有增加。统计发生在明确的决策位置，避免日志与业务更新各算一遍。这里没有真实网络连接，离线运行的是事件驱动规则模型。",
    objective: "能分开统计尝试和成功，并从事件序列解释最终状态。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["接收计数与成功计数是不同指标，不能混用。", "只有确认迁移成功后才能更新状态和成功计数。"],
    code: r'''
enum Connection { idle, connecting, ready }
enum Event { connect, established, disconnect }
const routes = <Connection, Map<Event, Connection>>{
  Connection.idle: {Event.connect: Connection.connecting},
  Connection.connecting: {Event.established: Connection.ready, Event.disconnect: Connection.idle},
  Connection.ready: {Event.disconnect: Connection.idle},
};
void main() {
  var state = Connection.idle;
  final received = <Event, int>{};
  final accepted = <Event, int>{};
  for (final event in [Event.established, Event.connect, Event.established,
      Event.disconnect, Event.disconnect]) {
    received[event] = (received[event] ?? 0) + 1;
    final target = routes[state]?[event];
    if (target == null) { print('拒绝 ${event.name}'); continue; }
    accepted[event] = (accepted[event] ?? 0) + 1;
    state = target;
  }
  print('状态 ${state.name}');
  for (final event in Event.values) {
    print('${event.name}: 收到=${received[event] ?? 0}, 成功=${accepted[event] ?? 0}');
  }
}
''',
    output:
        "拒绝 established\n拒绝 disconnect\n状态 idle\nconnect: 收到=1, 成功=1\nestablished: 收到=2, 成功=1\ndisconnect: 收到=2, 成功=1\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "增加失败事件，使 connecting 可以回到 idle。同时纳入同一报表。",
        hint: "扩展枚举和路由表，计数循环可原样复用。",
        answer: r'''
enum Connection { idle, connecting, ready }
enum Event { connect, established, disconnect, failed }
const routes = <Connection, Map<Event, Connection>>{
  Connection.idle: {Event.connect: Connection.connecting},
  Connection.connecting: {Event.established: Connection.ready, Event.disconnect: Connection.idle, Event.failed: Connection.idle},
  Connection.ready: {Event.disconnect: Connection.idle},
};

void main() {
  var state = Connection.idle;
  final received = <Event, int>{};
  final accepted = <Event, int>{};
  for (final event in [Event.connect, Event.failed, Event.established,
      Event.connect, Event.established, Event.disconnect]) {
    received[event] = (received[event] ?? 0) + 1;
    final target = routes[state]?[event];
    if (target == null) continue;
    accepted[event] = (accepted[event] ?? 0) + 1;
    state = target;
  }
  print('状态 ${state.name}');
  for (final event in Event.values) {
    print('${event.name}: 收到=${received[event] ?? 0}, 成功=${accepted[event] ?? 0}');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 214：连接状态机与事件报表",
    exampleSummary: "运行示例。观察区分收到的事件和接受的迁移，建立可解释的状态统计。",
  ),
  DartLesson(
    id: 'dart-lesson-215',
    chapter: 'enum-states',
    level: 'advanced',
    title: "从魔法字符串迁移到枚举",
    summary: "只在输入边界解析旧字符串，内部用枚举计算并与旧规则对照。",
    concepts: <String>["边界适配", "封闭类型", "迁移对拍"],
    explain:
        "旧代码常用字符串表示服务等级，拼写错误却只能在运行时发现。迁移时不必一次改变所有输入格式。程序可以先在边界把字符串转换成枚举，内部只接收合法类型。本例保留旧计价函数作为对照，对三种已知等级比较新旧报价。未知拼写则在解析处明确失败。这样能够同时检查兼容输入与拒绝非法值，不会把未知值悄悄当成默认等级。对拍只覆盖列出的业务规则，仍应保留独立样例。整个迁移练习是本地纯计算，离线可复现。",
    objective: "能建立旧格式适配层，并让内部摆脱字符串分支。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["不要用默认分支吞掉所有未知输入。", "枚举名称若对外持久化，也需要考虑未来重命名兼容。"],
    code: r'''
enum Service { economy, standard, express }
Service parseService(String text) {
  switch (text) {
    case 'economy': return Service.economy;
    case 'standard': return Service.standard;
    case 'express': return Service.express;
    default: throw FormatException('未知服务等级');
  }
}
int oldFee(String text) => text == 'economy' ? 5 : text == 'standard' ? 10 : 20;
int fee(Service service) {
  switch (service) {
    case Service.economy: return 5;
    case Service.standard: return 10;
    case Service.express: return 20;
  }
}
void main() {
  for (final text in ['economy', 'standard', 'express']) {
    print('$text: ${fee(parseService(text)) == oldFee(text)}');
  }
  try { parseService('expres'); }
  on FormatException { print('拒绝拼写错误'); }
}
''',
    output: "economy: true\nstandard: true\nexpress: true\n拒绝拼写错误\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "兼容旧值 fast，使其明确映射到 express。内部计价函数保持不变。",
        hint: "只扩展 parseService 的边界分支。",
        answer: r'''
enum Service { economy, standard, express }
Service parseService(String text) {
  switch (text) {
    case 'economy': return Service.economy;
    case 'standard': return Service.standard;
    case 'fast':
    case 'express': return Service.express;
    default: throw FormatException('未知服务等级');
  }
}
int oldFee(String text) => text == 'economy' ? 5 : text == 'standard' ? 10 : 20;
int fee(Service service) {
  switch (service) {
    case Service.economy: return 5;
    case Service.standard: return 10;
    case Service.express: return 20;
  }
}

void main() {
  print(fee(parseService('fast')));
  print(parseService('fast') == parseService('express'));
  try { parseService('faster'); } on FormatException { print('未知值仍然拒绝'); }
}
''',
      ),
    ],
    exampleTitle: "示例 215：从魔法字符串迁移到枚举",
    exampleSummary: "运行示例。观察只在输入边界解析旧字符串，内部用枚举计算并与旧规则对照。",
  ),
];
