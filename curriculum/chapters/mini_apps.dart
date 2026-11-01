import '../dart_lesson.dart';

/// Chapter `mini-apps` — independently executed lessons and paired examples.
const List<DartLesson> miniAppsLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-295',
    chapter: "mini-apps",
    level: "advanced",
    title: "离线分类记账本",
    summary: "录入整数分流水，计算分类净额和总余额，并检查流水守恒。",
    concepts: <String>["整数金额", "分类聚合", "守恒核对"],
    explain:
        "综合记账程序需要同时维护输入规则、分类统计和余额关系。示例把每条流水表示为分类与分单位变动，收入为正、支出为负，不经过浮点金额。处理时逐条输出余额，同时为每个分类累计净额。程序最后检查分类合计与最终余额是否一致。这里的分类净额允许为负，能直接表示支出类别。固定数据让程序无需输入、网络或外部文件即可运行。真实账本还需要日期、币种、撤销记录和持久化事务。本课先确保最基本的金额守恒与报告一致。程序再考虑界面与持久化，避免漂亮报表掩盖漏记或重复记账。",
    objective: "能将流水、分类汇总和余额检查组合成完整的小型账本。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["分类支出应保留负号，不能为了显示方便参与绝对值合计。", "余额和分类统计必须处理相同的一批流水。"],
    code: r'''
String money(int cents) {
  final n = cents.abs();
  return '${cents < 0 ? '-' : ''}${n ~/ 100}.${(n % 100).toString().padLeft(2, '0')}';
}
void main() {
  final ledger = [
    ['salary', 500000], ['food', -2500], ['travel', -600], ['food', -1800],
  ];
  final categories = <String, int>{};
  var balance = 0;
  for (var i = 0; i < ledger.length; i++) {
    final category = ledger[i][0] as String;
    final delta = ledger[i][1] as int;
    balance += delta;
    categories[category] = (categories[category] ?? 0) + delta;
    print('流水${i + 1} 余额${money(balance)}');
  }
  var check = 0;
  for (final entry in categories.entries) {
    print('${entry.key}:${money(entry.value)}');
    check += entry.value;
  }
  print('对账:${check == balance}');
}
''',
    output:
        "流水1 余额5000.00\n流水2 余额4975.00\n流水3 余额4969.00\n流水4 余额4951.00\nsalary:5000.00\nfood:-43.00\ntravel:-6.00\n对账:true\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "用反向流水撤销一笔支出。证明不必删除原始记录也能恢复余额。",
        hint: "撤销记录金额与原记录互为相反数，并保留两条记录。",
        answer: r'''
void main() {
  final changes = [10000, -2500, 2500];
  var balance = 0;
  for (final change in changes) balance += change;
  print('流水${changes.length}条 余额$balance分');
}
''',
      ),
    ],
    exampleTitle: "示例 295：离线分类记账本",
    exampleSummary: "录入整数分流水，计算分类净额和总余额，并检查流水守恒。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-296',
    chapter: "mini-apps",
    level: "advanced",
    title: "库存变更与低库存告警",
    summary: "统一验证库存变更，失败操作保持原状态，再生成低库存清单。",
    concepts: <String>["状态封装", "变更前校验", "告警筛选"],
    explain:
        "库存程序不能只把入库和出库分别打印出来，还必须保护不能出现负库存的不变量。示例把变更集中在 Inventory.change 中，先计算候选库存，验证通过后才写回，拒绝时保持原值。main 运行入库、出库和一次超额出库，再检查所有商品并输出低库存告警。固定数据显示完整状态变化，而不是伪造业务成功消息。这里的对象只保存单顺序调用的内存状态。真实多用户系统还需要并发控制和持久化事务。把规则集中到一个入口可以防止不同页面各自写出不一致的出库检查。",
    objective: "能封装有不变量的库存状态，并验证失败操作没有副作用。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "先减库存再抛错会留下负值，检查必须发生在写回前。",
      "告警阈值是业务参数，不能与是否允许出库混为同一规则。",
    ],
    code: r'''
class Inventory {
  final Map<String, int> stock = {'pen': 5, 'book': 2};
  void change(String sku, int delta) {
    if (!stock.containsKey(sku)) throw ArgumentError('未知商品');
    final next = stock[sku]! + delta;
    if (next < 0) throw StateError('库存不足');
    stock[sku] = next;
  }
  List<String> low(int threshold) => stock.keys.where((key) => stock[key]! < threshold).toList();
}
void main() {
  final inventory = Inventory();
  inventory.change('pen', 3);
  inventory.change('book', -2);
  try { inventory.change('pen', -9); } on StateError { print('拒绝超额出库'); }
  print(inventory.stock);
  print('低库存:${inventory.low(3)}');
}
''',
    output: "拒绝超额出库\n{pen: 8, book: 0}\n低库存:[book]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "为新商品注册库存，拒绝重复商品和负初始库存。",
        hint: "注册与普通库存变更分开。先检查。再写入 Map。",
        answer: r'''
void register(Map<String, int> stock, String sku, int initial) {
  if (stock.containsKey(sku) || initial < 0) throw ArgumentError('注册失败');
  stock[sku] = initial;
}
void main() {
  final stock = <String, int>{};
  register(stock, 'bag', 4);
  try { register(stock, 'bag', 1); } on ArgumentError { print('拒绝重复'); }
  print(stock);
}
''',
      ),
    ],
    exampleTitle: "示例 296：库存变更与低库存告警",
    exampleSummary: "统一验证库存变更，失败操作保持原状态，再生成低库存清单。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-297',
    chapter: "mini-apps",
    level: "advanced",
    title: "含并列名次的成绩单",
    summary: "排序后分配竞赛名次，同时生成等级分布并保留空等级。",
    concepts: <String>["并列排名", "等级函数", "分布报告"],
    explain:
        "成绩单把多条规则组合在一起。规则包括分数降序、同分按姓名排序和同分共享名次。它还要统计等级分布。程序先排序条目，再根据前一人的分数决定是否更新名次，形成一、二、二、四这种竞赛排名。等级函数独立定义阈值，分布表预先列出所有等级，因此无人获得的等级也显示零。示例特意包含两个同分者和一个不及格者，验证并列与边界分支。名次表示相对位置，等级表示绝对标准，两者不能互相替代。真实成绩输入还应先检查分数范围和学生标识唯一性。",
    objective: "能在同一份成绩数据上组合并列排名与固定等级分布。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["遇到同分时名次不增加，但下一位不同分数应使用位置加一。", "只遍历出现过的等级会漏掉数量为零的等级。"],
    code: r'''
String grade(int score) => score >= 90 ? 'A' : score >= 80 ? 'B' : score >= 60 ? 'C' : 'D';
void main() {
  final scores = {'Ada': 92, 'Bo': 85, 'Chen': 85, 'Dan': 58};
  final rows = scores.entries.toList()..sort((a, b) {
    final result = b.value.compareTo(a.value);
    return result == 0 ? a.key.compareTo(b.key) : result;
  });
  final distribution = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
  var rank = 0;
  int? previous;
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    if (previous != row.value) rank = i + 1;
    previous = row.value;
    final level = grade(row.value);
    distribution[level] = distribution[level]! + 1;
    print('$rank ${row.key} ${row.value} $level');
  }
  print(distribution);
}
''',
    output:
        "1 Ada 92 A\n2 Bo 85 B\n2 Chen 85 B\n4 Dan 58 D\n{A: 1, B: 2, C: 0, D: 1}\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把竞赛排名改成稠密排名，使一、二、二之后接三。",
        hint: "只有分数变化时才把 rank 加一，不使用当前位置。",
        answer: r'''
void main() {
  final scores = [92, 85, 85, 58];
  int? previous;
  var rank = 0;
  for (final score in scores) {
    if (score != previous) rank++;
    previous = score;
    print('$rank:$score');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 297：含并列名次的成绩单",
    exampleSummary: "排序后分配竞赛名次，同时生成等级分布并保留空等级。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-298',
    chapter: "mini-apps",
    level: "advanced",
    title: "从清洗到覆盖率的词频报告",
    summary: "统一大小写、统计词频、稳定排序，并计算 Top N 覆盖比例。",
    concepts: <String>["文本管线", "Top N", "覆盖率"],
    explain:
        "词频报告不仅是把单词计数，还应说明清洗规则与报告覆盖了多少原文。程序先转小写。程序再用只识别英文字母的正则提取词。程序累计频次后按次数降序、同次数按字母顺序排序。输出前三项，并把这几项频次之和除以总词数，得到覆盖率。示例有四种词，因此前三项不能覆盖全部文本，百分比有真实统计含义。清洗规则限定了本课适用范围。规则会拆分中文、缩写中的撇号和带数字的词。不能把结果称为通用自然语言分析。真实项目应根据语料定义分词策略，再复用后续统计管线。",
    objective: "能把文本清洗、词频排名和覆盖率检查连接成完整报告。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["分母应是全部词的出现次数，而不是不同词的数量。", "同频排序需要第二比较条件，确保输出稳定。"],
    code: r'''
void main() {
  const text = 'Dart, dart! Offline tools; tools help Dart.';
  final words = RegExp(r'[a-z]+').allMatches(text.toLowerCase()).map((m) => m.group(0)!).toList();
  final counts = <String, int>{};
  for (final word in words) counts[word] = (counts[word] ?? 0) + 1;
  final ranking = counts.entries.toList()..sort((a, b) {
    final count = b.value.compareTo(a.value);
    return count != 0 ? count : a.key.compareTo(b.key);
  });
  var covered = 0;
  for (final entry in ranking.take(3)) {
    print('${entry.key}:${entry.value}');
    covered += entry.value;
  }
  final coverage = words.isEmpty ? 0.0 : covered * 100 / words.length;
  print('词数${words.length} 种类${counts.length} 覆盖${coverage.toStringAsFixed(1)}%');
}
''',
    output: "dart:3\ntools:2\nhelp:1\n词数7 种类4 覆盖85.7%\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "添加停用词集合。过滤 help。再重新计算有效词数。",
        hint: "停用词过滤应在总词数和词频统计之前完成。",
        answer: r'''
void main() {
  final stop = {'help'};
  final words = RegExp(r'[a-z]+').allMatches('tools help dart tools')
      .map((m) => m.group(0)!).where((word) => !stop.contains(word)).toList();
  final counts = <String, int>{};
  for (final word in words) counts[word] = (counts[word] ?? 0) + 1;
  print('有效词数${words.length}');
  print(counts);
}
''',
      ),
    ],
    exampleTitle: "示例 298：从清洗到覆盖率的词频报告",
    exampleSummary: "统一大小写、统计词频、稳定排序，并计算 Top N 覆盖比例。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-299',
    chapter: "mini-apps",
    level: "advanced",
    title: "迷宫最短路与路径回溯",
    summary: "用 BFS 搜索可达格子，记录前驱并把最短路径画回地图。",
    concepts: <String>["BFS", "前驱映射", "路径重建"],
    explain:
        "迷宫寻路把二维格子看成图：可通行相邻格子之间有一条等长边。程序用队列进行广度优先搜索，第一次发现某格子时记录它的前驱，防止重复入队。到达终点后沿前驱反向走回起点，再把结果反转成正常路径，并在原地图副本上用星号标注。所有边权相同，因此 BFS 找到的是步数最少的路线。若移动代价不同，则需要其他算法。示例保留起点和终点字符，输出步数和地图，两个结果都来自真实搜索。无路可达时明确报告失败，不会打印事先准备的路线。",
    objective: "能把队列搜索、访问标记和路径回溯组合成寻路程序。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["应在入队时记录已访问，出队时才记录会导致重复入队。", "前驱链接方向朝向起点，显示前需要反转。"],
    code: r'''
void main() {
  final grid = ['S...#', '##..#', '...##', '#...E'];
  final height = grid.length;
  final width = grid[0].length;
  const start = 0;
  final goal = height * width - 1;
  final queue = <int>[start];
  final previous = <int, int>{start: -1};
  final directions = [[0, 1], [1, 0], [0, -1], [-1, 0]];
  var head = 0;
  while (head < queue.length) {
    final current = queue[head++];
    if (current == goal) break;
    final row = current ~/ width;
    final col = current % width;
    for (final direction in directions) {
      final nr = row + direction[0];
      final nc = col + direction[1];
      if (nr < 0 || nr >= height || nc < 0 || nc >= width || grid[nr][nc] == '#') continue;
      final next = nr * width + nc;
      if (previous.containsKey(next)) continue;
      previous[next] = current;
      queue.add(next);
    }
  }
  if (!previous.containsKey(goal)) { print('无法到达'); return; }
  final path = <int>[];
  for (var at = goal; at != -1; at = previous[at]!) path.add(at);
  final route = path.reversed.toList();
  print('最短步数:${route.length - 1}');
  final picture = grid.map((line) => line.split('')).toList();
  for (final at in route) {
    if (at != start && at != goal) picture[at ~/ width][at % width] = '*';
  }
  for (final row in picture) print(row.join());
}
''',
    output: "最短步数:7\nS**.#\n##*.#\n..*##\n#.**E\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "给一个起点与终点相同的图返回零步路径。验证回溯停止条件。",
        hint: "起点前驱为 -1，路径应包含起点一次。",
        answer: r'''
void main() {
  const start = 0;
  const goal = 0;
  final previous = <int, int>{start: -1};
  final path = <int>[];
  for (var at = goal; at != -1; at = previous[at]!) path.add(at);
  print('步数:${path.length - 1}');
  print(path.reversed.toList());
}
''',
      ),
    ],
    exampleTitle: "示例 299：迷宫最短路与路径回溯",
    exampleSummary: "用 BFS 搜索可达格子，记录前驱并把最短路径画回地图。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-300',
    chapter: "mini-apps",
    level: "advanced",
    title: "带优先级的整数表达式求值器",
    summary: "词法验证后用数值栈和运算符栈求值，支持括号与左结合。",
    concepts: <String>["词法分析", "双栈", "运算符优先级"],
    explain:
        "表达式求值需要先区分数字、运算符和括号。程序再按优先级运算，不能简单从左到右相加。程序先提取词元，并检查是否覆盖全部非空白输入。程序拒绝未知字符。随后程序用数值栈保存操作数，用符号栈保存待计算运算。乘法优先于加减，同级运算先计算栈顶以保持左结合，括号则暂时阻隔外部运算。状态变量检查数字与运算符是否交替出现，末尾还验证括号与栈数量。语法限定为非负整数、二元加减乘和括号，不支持一元负号或除法，限制写清楚比悄悄误算更重要。",
    objective: "能实现带词法验证、括号和优先级的双栈求值器。能拒绝不完整表达式。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "出栈时先取右操作数再取左操作数，减法不能交换顺序。",
      "相同优先级也应先计算栈顶，否则减法会错误变成右结合。",
    ],
    code: r'''
int evaluate(String source) {
  final compact = source.replaceAll(RegExp(r'\s+'), '');
  final tokens = RegExp(r'\d+|[()+*\-]').allMatches(source).map((m) => m.group(0)!).toList();
  if (tokens.join() != compact || tokens.isEmpty) throw FormatException('非法词元');
  final values = <int>[];
  final operators = <String>[];
  const priority = {'+': 1, '-': 1, '*': 2};
  void apply() {
    if (operators.isEmpty || values.length < 2) throw FormatException('缺少操作数');
    final op = operators.removeLast();
    final right = values.removeLast();
    final left = values.removeLast();
    values.add(op == '+' ? left + right : op == '-' ? left - right : left * right);
  }
  var expectingValue = true;
  for (final token in tokens) {
    final number = int.tryParse(token);
    if (number != null) {
      if (!expectingValue) throw FormatException('缺少运算符');
      values.add(number);
      expectingValue = false;
    } else if (token == '(') {
      if (!expectingValue) throw FormatException('缺少运算符');
      operators.add(token);
    } else if (token == ')') {
      if (expectingValue) throw FormatException('空括号或缺值');
      while (operators.isNotEmpty && operators.last != '(') apply();
      if (operators.isEmpty) throw FormatException('括号不匹配');
      operators.removeLast();
      expectingValue = false;
    } else {
      if (expectingValue) throw FormatException('缺少操作数');
      while (operators.isNotEmpty && operators.last != '(' &&
          priority[operators.last]! >= priority[token]!) apply();
      operators.add(token);
      expectingValue = true;
    }
  }
  if (expectingValue) throw FormatException('末尾缺值');
  while (operators.isNotEmpty) {
    if (operators.last == '(') throw FormatException('括号不匹配');
    apply();
  }
  if (values.length != 1) throw FormatException('表达式结构');
  return values.single;
}
void main() {
  for (final expression in ['12 + 3 * (4 - 2)', '8-3-2', '2*(3+4)']) {
    print('$expression = ${evaluate(expression)}');
  }
  try { evaluate('2+'); } on FormatException { print('拒绝不完整表达式'); }
}
''',
    output: "12 + 3 * (4 - 2) = 18\n8-3-2 = 3\n2*(3+4) = 14\n拒绝不完整表达式\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "单独实现词法覆盖检查。验证 2+3 合法，而 2/3 和 a+1 不合法。",
        hint: "所有提取词元连接后必须等于去掉空白的原输入。",
        answer: r'''
bool validTokens(String source) {
  final compact = source.replaceAll(RegExp(r'\s+'), '');
  final tokens = RegExp(r'\d+|[()+*\-]').allMatches(source).map((m) => m.group(0)!).toList();
  return tokens.isNotEmpty && tokens.join() == compact;
}
void main() { for (final text in ['2+3', '2/3', 'a+1']) print('$text:${validTokens(text)}'); }
''',
      ),
    ],
    exampleTitle: "示例 300：带优先级的整数表达式求值器",
    exampleSummary: "词法验证后用数值栈和运算符栈求值，支持括号与左结合。完整运行演示。",
  ),
];
