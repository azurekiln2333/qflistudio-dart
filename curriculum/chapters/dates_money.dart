import '../dart_lesson.dart';

/// Chapter `dates-money` — independently executed lessons and paired examples.
const List<DartLesson> datesMoneyLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-239',
    chapter: "dates-money",
    level: "beginner",
    title: "按周年边界计算年龄",
    summary: "比较生日是否已过，避免仅用年份差计算周岁。",
    concepts: <String>["DateTime.utc", "日期边界", "纯函数"],
    explain:
        "周岁表示完整的周年数量，不能直接用当前年份减出生年份。程序先得到年份差。若当前月日早于生日，就把年龄减一。所有输入都使用固定 UTC 日期，使测试不依赖运行当天、时区或夏令时。本例把二月二十九日出生者在非闰年的周年边界约定为三月一日。因此二月二十八日仍未增加周岁。实际业务可以选择另一条规则，但必须先明确。函数拒绝未来生日，让无效资料不会悄悄变成负年龄。两个相邻日期的输出专门验证生日边界。",
    objective: "能写出可重复测试的年龄函数，并明确闰日生日的业务规则。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "不要依赖 DateTime.now，否则相同示例每天可能产生不同结果。",
      "年龄属于日历规则，不能把天数除以 365 后取整。",
    ],
    code: r'''
int ageOn(DateTime born, DateTime day) {
  if (born.isAfter(day)) throw ArgumentError('未来生日');
  var age = day.year - born.year;
  if (day.month < born.month ||
      (day.month == born.month && day.day < born.day)) age--;
  return age;
}
void main() {
  final born = DateTime.utc(2000, 10, 22);
  print(ageOn(born, DateTime.utc(2026, 10, 21)));
  print(ageOn(born, DateTime.utc(2026, 10, 22)));
  print(ageOn(DateTime.utc(2004, 2, 29), DateTime.utc(2025, 2, 28)));
}
''',
    output: "25\n26\n20\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "补上闰日生日在三月一日的边界验证。同时打印前后两天的年龄。",
        hint: "复用月份与日期比较，不要按固定天数换算。",
        answer: r'''
int ageOn(DateTime born, DateTime day) {
  var age = day.year - born.year;
  if (day.month < born.month ||
      (day.month == born.month && day.day < born.day)) age--;
  return age;
}
void main() {
  final born = DateTime.utc(2004, 2, 29);
  print(ageOn(born, DateTime.utc(2025, 2, 28)));
  print(ageOn(born, DateTime.utc(2025, 3, 1)));
}
''',
      ),
    ],
    exampleTitle: "示例 239：按周年边界计算年龄",
    exampleSummary: "比较生日是否已过，避免仅用年份差计算周岁。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-240',
    chapter: "dates-money",
    level: "beginner",
    title: "固定宽度日期标签",
    summary: "按年、月、日分别补零，生成可排序的日期标签。",
    concepts: <String>["padLeft", "UTC 日期", "字符串排序"],
    explain:
        "文件归档和日报标题经常需要统一的年月日标签。把月份直接插入字符串会得到一位和两位混杂的形式。按文本排序时也容易让十月排到二月前面。程序分别提取 UTC 日期的年、月、日，再补足规定宽度，用短横线连接成固定格式。补零只改变显示文本，不会修改 DateTime 中的数值。示例先打乱三个日期再按标签排序，验证这种格式在同一年范围内保持日历顺序。它不是任意日期文本的解析器，也没有引入地区语言库。需要时间和时区时应另外定义完整格式。",
    objective: "能生成稳定的日期键，并解释固定宽度对文本排序的作用。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["padLeft 不会截断超过宽度的年份。", "不要混合本地时间与 UTC 时间后直接比较标签。"],
    code: r'''
String dateLabel(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';
void main() {
  final days = [DateTime.utc(2026, 10, 2), DateTime.utc(2026, 2, 9),
    DateTime.utc(2026, 1, 31)];
  final labels = days.map(dateLabel).toList()..sort();
  for (final label in labels) print(label);
}
''',
    output: "2026-01-31\n2026-02-09\n2026-10-02\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "为日期标签增加不带分隔符的归档键，例如 20260209。",
        hint: "对月和日各补两位。再直接连接。",
        answer: r'''
String archiveKey(DateTime d) => '${d.year}'
    '${d.month.toString().padLeft(2, '0')}'
    '${d.day.toString().padLeft(2, '0')}';
void main() { print(archiveKey(DateTime.utc(2026, 2, 9))); }
''',
      ),
    ],
    exampleTitle: "示例 240：固定宽度日期标签",
    exampleSummary: "按年、月、日分别补零，生成可排序的日期标签。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-241',
    chapter: "dates-money",
    level: "intermediate",
    title: "UTC 日历天数差",
    summary: "统一到 UTC 午夜再计算两个日期之间的整日跨度。",
    concepts: <String>["difference", "Duration.inDays", "日历与时刻"],
    explain:
        "订单有效期通常讨论的是日历日期，而计时器讨论的是两个时刻的持续时间，这两件事需要分开。程序把输入限定为 UTC 午夜，利用 difference 得到 Duration，再读取完整天数。这样跨月底、跨年以及闰年的二月都由日期库处理，不需要自己维护每个月的天数表。示例特意覆盖闰日和年末，并反向计算一次，说明日期差可以为负。若业务输入包含本地时分秒，应先明确要比较本地日历天还是绝对经过时间。不能简单取 inDays 就假定已经满足日历规则。",
    objective: "能正确计算可重复的 UTC 日期跨度，并识别带时刻输入的差别。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["inDays 会舍弃不足一天的部分。", "本地夏令时切换的一天不一定等于 24 小时。"],
    code: r'''
int daysBetween(DateTime a, DateTime b) => b.difference(a).inDays;
void main() {
  final leapStart = DateTime.utc(2024, 2, 28);
  final leapEnd = DateTime.utc(2024, 3, 1);
  print(daysBetween(leapStart, leapEnd));
  print(daysBetween(DateTime.utc(2025, 12, 30), DateTime.utc(2026, 1, 2)));
  print(daysBetween(leapEnd, leapStart));
}
''',
    output: "2\n3\n-2\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "判断两个 UTC 日期是否落在七天有效期内。区间包含起点，不包含终点。",
        hint: "分别比较目标不早于起点、早于起点加七天。",
        answer: r'''
bool validOn(DateTime start, DateTime target) =>
  !target.isBefore(start) && target.isBefore(start.add(const Duration(days: 7)));
void main() {
  final start = DateTime.utc(2026, 1, 1);
  print(validOn(start, DateTime.utc(2026, 1, 7)));
  print(validOn(start, DateTime.utc(2026, 1, 8)));
}
''',
      ),
    ],
    exampleTitle: "示例 241：UTC 日历天数差",
    exampleSummary: "统一到 UTC 午夜再计算两个日期之间的整日跨度。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-242',
    chapter: "dates-money",
    level: "intermediate",
    title: "按周生成复习日程",
    summary: "通过日期加法生成跨月复习节点，不手工调整月份。",
    concepts: <String>["Duration", "DateTime.add", "日程生成"],
    explain:
        "学习计划中的间隔复习适合表示为起始日期加上间隔天数。程序把复习间隔保存在列表里。每次都从同一个起始日期计算目标。它不在上一次结果上重复叠加。这样可以避免把累计间隔误当成增量。DateTime.add 负责跨月和跨年进位，输出只保留年月日。示例从年末开始，显示一周后已经进入下一年。这里使用 UTC 日程以获得稳定结果。如果日程要求本地每天固定九点，应按当地日历构造下一次时间。不能默认增加二十四小时始终落在相同钟点。",
    objective: "能区分累计偏移与相邻间隔，并生成跨年的复习计划。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["不要同时累加已累计的间隔，否则后面的日期会越来越晚。", "月并不是固定的三十天，按月计划需要独立规则。"],
    code: r'''
void main() {
  final start = DateTime.utc(2026, 12, 28);
  final offsets = [1, 3, 7, 14];
  for (final days in offsets) {
    final next = start.add(Duration(days: days));
    final label = next.toIso8601String().substring(0, 10);
    print('第${days}天 $label');
  }
}
''',
    output: "第1天 2026-12-29\n第3天 2026-12-31\n第7天 2027-01-04\n第14天 2027-01-11\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "由一个截止日期倒推三天、一天的提醒日期。",
        hint: "subtract 与 add 使用同一种 Duration。",
        answer: r'''
void main() {
  final due = DateTime.utc(2027, 1, 2);
  for (final days in [3, 1]) {
    print(due.subtract(Duration(days: days)).toIso8601String().substring(0, 10));
  }
}
''',
      ),
    ],
    exampleTitle: "示例 242：按周生成复习日程",
    exampleSummary: "通过日期加法生成跨月复习节点，不手工调整月份。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-243',
    chapter: "dates-money",
    level: "intermediate",
    title: "星期映射与循环排班",
    summary: "按 weekday 的一到七索引映射名称，生成一周值班表。",
    concepts: <String>["weekday", "列表索引", "取模轮换"],
    explain:
        "Dart 的 weekday 从星期一的一开始计数，而列表索引从零开始，两者衔接时必须减一。程序用固定名称表显示星期。程序再用日期序号对值班人员数量取模，形成循环轮班。两种索引各自有明确来源：星期来自日期库，人员位置来自排班序号，不要混在一起。示例跨越周末到下周一，验证名称映射和轮班都能继续工作。排班只演示机械轮转，没有自动处理节假日、请假或劳动时长约束。真正项目应把这些限制作为额外输入，而不是藏在星期名称函数中。",
    objective: "能安全映射星期名称，并将日期显示与人员轮转规则分离。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["weekday 为七时必须访问名称表的第六号索引。", "轮班计数若每天重置，所有日期都会安排同一个人。"],
    code: r'''
void main() {
  const names = ['一', '二', '三', '四', '五', '六', '日'];
  const people = ['安', '白', '陈'];
  final start = DateTime.utc(2026, 10, 23);
  for (var i = 0; i < 4; i++) {
    final day = start.add(Duration(days: i));
    print('星期${names[day.weekday - 1]} ${people[i % people.length]}');
  }
}
''',
    output: "星期五 安\n星期六 白\n星期日 陈\n星期一 安\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "周末显示休息。工作日仍按人员序列轮换。轮换不消耗周末名额。",
        hint: "只在工作日打印人员。每次打印后递增独立的排班计数。",
        answer: r'''
void main() {
  final start = DateTime.utc(2026, 10, 23);
  final people = ['安', '白'];
  var turn = 0;
  for (var i = 0; i < 4; i++) {
    final day = start.add(Duration(days: i));
    if (day.weekday > 5) { print('休息'); } else {
      print(people[turn % people.length]);
      turn++;
    }
  }
}
''',
      ),
    ],
    exampleTitle: "示例 243：星期映射与循环排班",
    exampleSummary: "按 weekday 的一到七索引映射名称，生成一周值班表。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-244',
    chapter: "dates-money",
    level: "intermediate",
    title: "半开区间工作日计数",
    summary: "逐日遍历起止区间，显式排除周末和指定休息日。",
    concepts: <String>["半开区间", "Set 日期键", "业务日历"],
    explain:
        "统计交付周期前，应先约定结束日是否计入。本例采用包含开始日、不包含结束日的半开区间，使连续两个区间拼接时不会重复计算边界。每轮先查看星期，再查询人工提供的休息日集合，两个条件都满足才累计。假日键统一为 UTC 日期的年月日形式，避免时分秒影响相等判断。程序显示周末和一个额外休息日同时存在时的结果。示例中的休息日是固定教学数据，并不代表任何地区的官方日历。调休上班日、不同地区周末规则应由更完整的业务日历显式描述。",
    objective: "能实现边界明确、支持额外排除日期的工作日计数。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["不要在计数和循环条件里各自决定一次结束日是否包含。", "仅跳过星期六日不能代表所有真实工作日历。"],
    code: r'''
int workdays(DateTime start, DateTime end, Set<String> off) {
  var count = 0;
  for (var day = start; day.isBefore(end);
      day = day.add(const Duration(days: 1))) {
    final key = day.toIso8601String().substring(0, 10);
    if (day.weekday <= 5 && !off.contains(key)) count++;
  }
  return count;
}
void main() {
  final start = DateTime.utc(2026, 10, 19);
  final end = DateTime.utc(2026, 10, 27);
  print(workdays(start, end, <String>{}));
  print(workdays(start, end, {'2026-10-22'}));
}
''',
    output: "6\n5\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "计算从星期五开始再经过三个工作日的日期。周末不消耗名额。",
        hint: "每天先向后移动一天。只有星期一至五才减少剩余数量。",
        answer: r'''
DateTime afterWorkdays(DateTime day, int count) {
  while (count > 0) {
    day = day.add(const Duration(days: 1));
    if (day.weekday <= 5) count--;
  }
  return day;
}
void main() {
  print(afterWorkdays(DateTime.utc(2026, 10, 23), 3).toIso8601String().substring(0, 10));
}
''',
      ),
    ],
    exampleTitle: "示例 244：半开区间工作日计数",
    exampleSummary: "逐日遍历起止区间，显式排除周末和指定休息日。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-245',
    chapter: "dates-money",
    level: "intermediate",
    title: "整数本金分期计划",
    summary: "把不能整除的本金分配给最后一期，并按剩余本金计算利息。",
    concepts: <String>["整数分单位", "余数结清", "剩余本金"],
    explain:
        "分期表必须保证所有期次归还的本金恰好等于原始本金。程序把金额保存在分单位整数中。程序先求每期基础本金。最后一期归还全部剩余数。这样可以避免整除余数遗失。每期利息按本期开始前的剩余本金乘固定示例费率计算，并在分单位舍入。程序随后再扣减本金。输出逐期显示本金、利息和剩余金额，末尾验证本金合计与余额。这里是等额本金算法练习，费率和舍入时点均为明确的教学约定。它不构成真实借贷方案。若合同采用其他计息规则，应重新定义计算函数与边界测试。",
    objective: "能用整数构建本金守恒的分期表，并说明利息计算的时点。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["利息应按扣本金之前还是之后计算，必须预先约定。", "简单整除后重复相同本金会漏掉余数。"],
    code: r'''
void main() {
  const principal = 10001;
  const months = 3;
  final base = principal ~/ months;
  var balance = principal;
  var paid = 0;
  for (var month = 1; month <= months; month++) {
    final capital = month == months ? balance : base;
    final interest = (balance * 1 / 100).round();
    balance -= capital;
    paid += capital;
    print('$month 本金$capital 利息$interest 剩余$balance');
  }
  print('本金合计$paid');
}
''',
    output:
        "1 本金3333 利息100 剩余6668\n2 本金3333 利息67 剩余3335\n3 本金3335 利息33 剩余0\n本金合计10001\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把 10001 分平均分成三份，让前面的份额优先多分一分。",
        hint: "先计算商和余数。索引小于余数的份额加一。",
        answer: r'''
void main() {
  const total = 10001;
  const parts = 3;
  final values = <int>[];
  for (var i = 0; i < parts; i++) {
    values.add(total ~/ parts + (i < total % parts ? 1 : 0));
  }
  print(values);
  print(values.reduce((a, b) => a + b));
}
''',
      ),
    ],
    exampleTitle: "示例 245：整数本金分期计划",
    exampleSummary: "把不能整除的本金分配给最后一期，并按剩余本金计算利息。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-246',
    chapter: "dates-money",
    level: "intermediate",
    title: "复利公式与逐期迭代",
    summary: "用幂公式和循环计算相同增长过程，比较两种表达。",
    concepts: <String>["pow", "指数增长", "浮点展示"],
    explain:
        "固定比例连续增长时，每一期的基数是上一期的余额，因此多期结果包含乘方。程序用 pow 计算闭式公式。程序也在循环里逐年乘增长系数。程序打印每年余额并比较最终显示值。两条路径有助于理解公式来自反复相乘，而不是把同一利息简单乘年数。计算过程保留浮点值，只在输出时保留两位小数。这与每年把余额舍入到分是不同策略。本课采用固定示例参数讲解指数模型，不引入现实市场回报预测。需要精确金额结算时仍应另行定义分单位和舍入规则。",
    objective: "能把重复比例增长写成公式与循环。能区分计算精度与输出精度。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["百分之五应写成 0.05，而不是 5。", "逐期舍入与最后舍入可能得到不同结果。"],
    code: r'''
import 'dart:math';
void main() {
  const initial = 1000.0;
  const rate = 0.05;
  var balance = initial;
  for (var year = 1; year <= 3; year++) {
    balance *= 1 + rate;
    print('第$year年 ${balance.toStringAsFixed(2)}');
  }
  final formula = initial * pow(1 + rate, 3);
  print('公式 ${formula.toStringAsFixed(2)}');
}
''',
    output: "第1年 1050.00\n第2年 1102.50\n第3年 1157.63\n公式 1157.63\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "比较三年单利与复利，输出二者保留两位小数的差额。",
        hint: "单利只对初始本金计息，复利使用幂公式。",
        answer: r'''
import 'dart:math';
void main() {
  const capital = 1000.0;
  const rate = 0.05;
  final simple = capital * (1 + rate * 3);
  final compound = capital * pow(1 + rate, 3);
  print((compound - simple).toStringAsFixed(2));
}
''',
      ),
    ],
    exampleTitle: "示例 246：复利公式与逐期迭代",
    exampleSummary: "用幂公式和循环计算相同增长过程，比较两种表达。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-247',
    chapter: "dates-money",
    level: "advanced",
    title: "逐段计算阶梯费用",
    summary: "只对落入每个区间的增量收费，避免整笔套用最高档位。",
    concepts: <String>["分段函数", "区间裁剪", "累计计算"],
    explain:
        "阶梯计费把总量划分为几个互不重叠的区间，每一档只处理属于本档的增量。程序依次计算前一百、接下来一百和超过两百的数量，分别乘上整数单价后累计。这样在跨档时只会增加新档费用，不会重新提高旧档单价。边界数据特意覆盖零、刚好一百以及二百五十，便于检查区间连接处。这里的档位和单价仅是教学模型，也可以用于积分或资源费用。它不是任何地区的法定税率表。遇到真实税费业务时，先从正式规则定义基数、免征额及舍入时点，再复用分段思想。",
    objective: "能实现连续的阶梯计算，并通过临界输入发现整笔套档错误。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["不可把总量直接乘最高档单价。", "负数输入应明确拒绝，不能当作零悄悄吞掉。"],
    code: r'''
int fee(int units) {
  if (units < 0) throw ArgumentError('数量不能为负');
  final first = units < 100 ? units : 100;
  final rest = units - first;
  final second = rest < 100 ? rest : 100;
  final third = rest - second;
  return first * 2 + second * 3 + third * 5;
}
void main() {
  for (final units in [0, 100, 101, 250]) {
    print('$units -> ${fee(units)}');
  }
}
''',
    output: "0 -> 0\n100 -> 200\n101 -> 203\n250 -> 750\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "输出 99、100、101 三个数量的费用，验证跨档时增量从二变成三。",
        hint: "打印相邻费用的差，重点查看一百的左右边界。",
        answer: r'''
int fee(int n) => n <= 100 ? n * 2 : 200 + (n - 100) * 3;
void main() {
  for (final n in [99, 100, 101]) print('$n:${fee(n)}');
  print('跨档增量 ${fee(101) - fee(100)}');
}
''',
      ),
    ],
    exampleTitle: "示例 247：逐段计算阶梯费用",
    exampleSummary: "只对落入每个区间的增量收费，避免整笔套用最高档位。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-248',
    chapter: "dates-money",
    level: "advanced",
    title: "严格解析分单位金额",
    summary: "验证十进制文本再转整数分，格式化时正确处理负数。",
    concepts: <String>["正则校验", "整数金额", "符号分离"],
    explain:
        "精确累加账目时，先把金额文本转换成分单位整数，可以避免二进制小数累加误差。程序只接受带可选负号和最多两位小数的十进制格式。程序拆出整数部分与小数部分，再补足两位转换。输出函数先分离符号，对绝对值做整除和取余，因此负五分也能显示成负零点零五。超出两位的小数直接拒绝，避免隐藏的舍入决策。示例把两笔小额收入和一笔支出相加。整数金额仍需要明确币种与范围。本课不处理千分位、指数形式或不同币种的小数位规则。",
    objective: "能在不经过 double 的情况下解析、累计和显示两位小数金额。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "不要先 double.parse 再乘一百来宣称精确解析。",
      "负数整除前应先分离符号，否则小额负值容易丢失符号。",
    ],
    code: r'''
int cents(String text) {
  if (!RegExp(r'^-?\d+(\.\d{1,2})?$').hasMatch(text)) {
    throw FormatException('金额格式');
  }
  final negative = text.startsWith('-');
  final body = negative ? text.substring(1) : text;
  final parts = body.split('.');
  final fraction = parts.length == 1 ? '00' : parts[1].padRight(2, '0');
  final value = int.parse(parts[0]) * 100 + int.parse(fraction);
  return negative ? -value : value;
}
String money(int value) {
  final absolute = value.abs();
  return '${value < 0 ? '-' : ''}${absolute ~/ 100}.'
      '${(absolute % 100).toString().padLeft(2, '0')}';
}
void main() {
  final total = cents('0.10') + cents('0.20') + cents('-0.05');
  print(total);
  print(money(total));
  print(money(cents('-0.05')));
}
''',
    output: "25\n0.25\n-0.05\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "写一个拒绝三位小数的检查，并验证 12、12.3、12.345 三种输入。",
        hint: "使用完整匹配，不能只检查开头一段。",
        answer: r'''
void main() {
  final pattern = RegExp(r'^-?\d+(\.\d{1,2})?$');
  for (final text in ['12', '12.3', '12.345']) {
    print('$text:${pattern.hasMatch(text)}');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 248：严格解析分单位金额",
    exampleSummary: "验证十进制文本再转整数分，格式化时正确处理负数。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-249',
    chapter: "dates-money",
    level: "advanced",
    title: "账期归属和到期提醒",
    summary: "用日期区间归属账单，再按固定参考日判断提醒状态。",
    concepts: <String>["DateTime 构造进位", "账期分组", "到期差值"],
    explain:
        "账期通常不一定从每月第一天开始。本例约定每月二十日开始新账期，十九日及之前属于上一个开始月份。程序根据日期选择当前月或前一月。程序再利用 DateTime.utc 对月份零自动归一化。这样可以正确处理一月账单归属上一年十二月。到期日约定为账期开始后的下个月五日，参考日期由调用者传入，因此提醒结果可重现。输出覆盖边界当天和一月跨年情形。真实账单的节假日顺延和交易时区属于额外规则。这里把归属、到期和提醒分成明确步骤。这样便于逐项修改和测试。",
    objective: "能计算非自然月账期，并在跨年边界生成可测试的到期提醒。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["不能仅凭交易月份决定账期。", "不要把“下个月五日”替换成固定三十天后。"],
    code: r'''
DateTime cycleStart(DateTime day) =>
  DateTime.utc(day.year, day.month - (day.day < 20 ? 1 : 0), 20);
void main() {
  final today = DateTime.utc(2026, 11, 2);
  for (final day in [DateTime.utc(2026, 10, 19), DateTime.utc(2026, 10, 20)]) {
    final start = cycleStart(day);
    final due = DateTime.utc(start.year, start.month + 1, 5);
    final remaining = due.difference(today).inDays;
    print('${start.month}月账期 ${remaining < 0 ? '已过期' : '剩余${remaining}天'}');
  }
  print(cycleStart(DateTime.utc(2027, 1, 2)).toIso8601String().substring(0, 10));
}
''',
    output: "9月账期 已过期\n10月账期 剩余3天\n2026-12-20\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "生成某账期到下一账期的半开区间。验证边界交易只归入后一账期。",
        hint: "开始日包含，结束日排除。",
        answer: r'''
void main() {
  final start = DateTime.utc(2026, 10, 20);
  final end = DateTime.utc(2026, 11, 20);
  for (final day in [DateTime.utc(2026, 11, 19), end]) {
    print(!day.isBefore(start) && day.isBefore(end));
  }
}
''',
      ),
    ],
    exampleTitle: "示例 249：账期归属和到期提醒",
    exampleSummary: "用日期区间归属账单，再按固定参考日判断提醒状态。完整运行演示。",
  ),
];
