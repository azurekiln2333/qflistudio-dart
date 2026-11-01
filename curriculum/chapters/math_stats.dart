import '../dart_lesson.dart';

/// Independent, offline programs for chapter `math-stats`.
const List<DartLesson> mathStatsLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-181',
    chapter: 'math-stats',
    level: 'intermediate',
    title: "最大公约数与最小公倍数",
    summary: "用欧几里得算法安排两个周期的共同节拍。",
    concepts: <String>["欧几里得算法", "整数取余", "零值边界"],
    explain:
        "两个周期何时再次同时发生，可以转化为最小公倍数问题。先求最大公约数。再用除法缩小乘数，能避免直接把两个大整数相乘。欧几里得算法不断把较大问题换成余数更小的问题，直到余数为零。因此不需要枚举所有因子。本例把负数先取绝对值。同时约定任一输入为零时最小公倍数为零。观察连续几次调度间隔，能把公式和实际周期对应起来。程序只用确定性整数运算，离线运行即可验证。",
    objective: "能处理负数和零，并用最大公约数计算共同周期。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["不要先乘再除，较大的中间乘积没有必要。", "最大公约数非负。两个输入都为零时本例返回零。"],
    code: r'''
int gcd(int a, int b) {
  a = a.abs();
  b = b.abs();
  while (b != 0) {
    final remainder = a % b;
    a = b;
    b = remainder;
  }
  return a;
}
int lcm(int a, int b) => a == 0 || b == 0 ? 0 : (a ~/ gcd(a, b) * b).abs();
void main() {
  print('公约数 ${gcd(84, 30)}');
  final interval = lcm(12, 18);
  print('共同周期 $interval');
  print([for (var i = 1; i <= 3; i++) interval * i]);
  print('零边界 ${lcm(0, 18)}');
}
''',
    output: "公约数 6\n共同周期 36\n[36, 72, 108]\n零边界 0\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "写一个函数约分分数，要求分母为正且拒绝零分母。",
        hint: "先处理分母符号。再把分子分母同时除以 gcd。",
        answer: r'''
int gcd(int a, int b) {
  a = a.abs();
  b = b.abs();
  while (b != 0) {
    final remainder = a % b;
    a = b;
    b = remainder;
  }
  return a;
}
int lcm(int a, int b) => a == 0 || b == 0 ? 0 : (a ~/ gcd(a, b) * b).abs();

List<int> simplify(int numerator, int denominator) {
  if (denominator == 0) throw ArgumentError('分母不能为零');
  if (denominator < 0) { numerator = -numerator; denominator = -denominator; }
  final divisor = gcd(numerator, denominator);
  return [numerator ~/ divisor, denominator ~/ divisor];
}
void main() {
  print(simplify(8, -12));
  print(simplify(0, 5));
  try { simplify(1, 0); } on ArgumentError { print('拒绝零分母'); }
}
''',
      ),
    ],
    exampleTitle: "示例 181：最大公约数与最小公倍数",
    exampleSummary: "运行示例。观察用欧几里得算法安排两个周期的共同节拍。",
  ),
  DartLesson(
    id: 'dart-lesson-182',
    chapter: 'math-stats',
    level: 'intermediate',
    title: "试除法判断质数",
    summary: "利用因子成对出现，把质数检测缩短到平方根范围。",
    concepts: <String>["质数", "循环边界", "试除优化"],
    explain:
        "质数只有一和自身两个正因子。合数的因子成对出现，其中至少一个不大于平方根。所以试除无需一直进行到待测数前一位。本例先排除小于二的数和大于二的偶数。再只检查奇数因子。循环条件用除法比较来表达平方根边界，不依赖浮点近似。输出同时显示零、一、平方数和普通质数，帮助检查最容易漏掉的边界。它适合中等规模整数的教学检测，离线程序中不需要任何外部服务。",
    objective: "能解释平方根边界，并正确判断一、二和完全平方数。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["一不是质数，必须在进入试除循环前排除。", "边界要包含平方根，否则程序会误判四十九。"],
    code: r'''
bool isPrime(int number) {
  if (number < 2) return false;
  if (number == 2) return true;
  if (number.isEven) return false;
  for (var divisor = 3; divisor <= number ~/ divisor; divisor += 2) {
    if (number % divisor == 0) return false;
  }
  return true;
}
void main() {
  for (final number in [0, 1, 2, 29, 49, 97]) {
    print('$number: ${isPrime(number)}');
  }
}
''',
    output: "0: false\n1: false\n2: true\n29: true\n49: false\n97: true\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "用 isPrime 找出闭区间三十到五十内的所有质数。",
        hint: "遍历区间并只保留判断为真的整数。",
        answer: r'''
bool isPrime(int number) {
  if (number < 2) return false;
  if (number == 2) return true;
  if (number.isEven) return false;
  for (var divisor = 3; divisor <= number ~/ divisor; divisor += 2) {
    if (number % divisor == 0) return false;
  }
  return true;
}

void main() {
  final primes = <int>[];
  for (var n = 30; n <= 50; n++) { if (isPrime(n)) primes.add(n); }
  print(primes);
}
''',
      ),
    ],
    exampleTitle: "示例 182：试除法判断质数",
    exampleSummary: "运行示例。观察利用因子成对出现，把质数检测缩短到平方根范围。",
  ),
  DartLesson(
    id: 'dart-lesson-183',
    chapter: 'math-stats',
    level: 'intermediate',
    title: "筛法批量生成质数",
    summary: "用共享的合数标记一次筛出整个区间的质数。",
    concepts: <String>["埃拉托斯特尼筛", "布尔标记", "时间与空间"],
    explain:
        "如果要列出一段连续区间的全部质数，逐个试除会重复检查相同因子。筛法生成一个布尔表。程序每遇到尚未标记的整数，就把它的倍数标为合数。从该整数的平方开始标记，因为较小因子已处理过更小的倍数。本例明确把零和一标为非质数。再从表中收集结果。读者可以比较标记工作与最终输出，理解用一段连续内存换取重复查询速度的思路。表的大小由上限决定，离线运行时应给上限合理边界。",
    objective: "能说明为何从平方开始筛，并正确生成含上界的质数表。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["标记表长度需要是上限加一，才能访问上界。", "筛法适合区间批量查询，不适合为单个巨大整数分配整张表。"],
    code: r'''
List<int> sieve(int limit) {
  if (limit < 2) return [];
  final prime = List<bool>.filled(limit + 1, true);
  prime[0] = false;
  prime[1] = false;
  for (var factor = 2; factor * factor <= limit; factor++) {
    if (!prime[factor]) continue;
    for (var multiple = factor * factor; multiple <= limit; multiple += factor) {
      prime[multiple] = false;
    }
  }
  return [for (var n = 2; n <= limit; n++) if (prime[n]) n];
}
void main() {
  final primes = sieve(30);
  print(primes);
  print('数量 ${primes.length}');
  print(sieve(1));
}
''',
    output: "[2, 3, 5, 7, 11, 13, 17, 19, 23, 29]\n数量 10\n[]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "用筛法生成一百以内的质数。再统计最后一个十位区间的数量。",
        hint: "筛出的列表可以继续用 where 过滤大于等于九十的值。",
        answer: r'''
List<int> sieve(int limit) {
  if (limit < 2) return [];
  final prime = List<bool>.filled(limit + 1, true);
  prime[0] = false;
  prime[1] = false;
  for (var factor = 2; factor * factor <= limit; factor++) {
    if (!prime[factor]) continue;
    for (var multiple = factor * factor; multiple <= limit; multiple += factor) {
      prime[multiple] = false;
    }
  }
  return [for (var n = 2; n <= limit; n++) if (prime[n]) n];
}

void main() {
  final values = sieve(100);
  final lastDecade = values.where((n) => n >= 90).toList();
  print(lastDecade);
  print('数量 ${lastDecade.length}');
}
''',
      ),
    ],
    exampleTitle: "示例 183：筛法批量生成质数",
    exampleSummary: "运行示例。观察用共享的合数标记一次筛出整个区间的质数。",
  ),
  DartLesson(
    id: 'dart-lesson-184',
    chapter: 'math-stats',
    level: 'intermediate',
    title: "质因数分解与指数计数",
    summary: "反复除尽当前因子，把合数表示为质因子的幂。",
    concepts: <String>["质因数", "循环不变量", "因子计数"],
    explain:
        "质因数分解回答一个整数由哪些质数相乘构成。发现一个可整除的因子后，要持续除到不能整除，才能得到它的指数。只除一次会漏掉重复因子。每次缩小剩余数，又使后续搜索范围收缩。当试除结束而剩余数仍大于一时，它自身就是最后一个质因子。本例用有序插入的映射记录因子和指数，既保留计算结构，也能生成可读分解式。输入限定为正整数，边界一对应空分解。全部计算在本地确定性完成。",
    objective: "能处理重复质因子与末尾剩余质数。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["结束循环后的剩余数不能丢弃。", "一的分解为空。零没有有限的质因数分解。"],
    code: r'''
Map<int, int> factorize(int value) {
  if (value < 1) throw ArgumentError('需要正整数');
  final factors = <int, int>{};
  for (var factor = 2; factor <= value ~/ factor; factor++) {
    while (value % factor == 0) {
      factors[factor] = (factors[factor] ?? 0) + 1;
      value ~/= factor;
    }
  }
  if (value > 1) factors[value] = (factors[value] ?? 0) + 1;
  return factors;
}
void main() {
  final factors = factorize(360);
  print(factors);
  print(factors.entries.map((e) => '${e.key}^${e.value}').join(' × '));
  print(factorize(1));
}
''',
    output: "{2: 3, 3: 2, 5: 1}\n2^3 × 3^2 × 5^1\n{}\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "根据因子指数求正整数的约数总数。",
        hint: "每个质因子的指数可以在零到原指数之间独立选择。",
        answer: r'''
Map<int, int> factorize(int value) {
  if (value < 1) throw ArgumentError('需要正整数');
  final factors = <int, int>{};
  for (var factor = 2; factor <= value ~/ factor; factor++) {
    while (value % factor == 0) {
      factors[factor] = (factors[factor] ?? 0) + 1;
      value ~/= factor;
    }
  }
  if (value > 1) factors[value] = (factors[value] ?? 0) + 1;
  return factors;
}

int divisorCount(int value) {
  var count = 1;
  for (final exponent in factorize(value).values) { count *= exponent + 1; }
  return count;
}
void main() {
  print(divisorCount(360));
  print(divisorCount(1));
}
''',
      ),
    ],
    exampleTitle: "示例 184：质因数分解与指数计数",
    exampleSummary: "运行示例。观察反复除尽当前因子，把合数表示为质因子的幂。",
  ),
  DartLesson(
    id: 'dart-lesson-185',
    chapter: 'math-stats',
    level: 'intermediate',
    title: "逐行构造杨辉三角",
    summary: "从上一行相邻两项计算新行，并验证行和规律。",
    concepts: <String>["杨辉三角", "递推", "独立列表"],
    explain:
        "杨辉三角每行的两端为一，中间的数等于上一行相邻两项之和。这种只依赖前一层的结构，是理解动态规划的直观入口。本例每轮生成一张新列表。程序先填边界。接着填中间。最后把整行加入结果。不能反复修改同一列表后存多次引用，否则早先各行也会一起变化。输出除了三角形，还计算最后一行的和，让组合数与二的幂这一关系变得可观察。程序不使用随机数据或外部输入，适合在离线编辑器中逐行跟踪状态。",
    objective: "能根据上一行生成独立的新行，并检查行和。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["不要让结果中的多行共享同一个可变列表。", "内部循环只填写中间位置，两端保持一。"],
    code: r'''
List<List<int>> pascal(int rows) {
  final triangle = <List<int>>[];
  for (var row = 0; row < rows; row++) {
    final next = List<int>.filled(row + 1, 1);
    for (var column = 1; column < row; column++) {
      next[column] = triangle[row - 1][column - 1] + triangle[row - 1][column];
    }
    triangle.add(next);
  }
  return triangle;
}
void main() {
  final triangle = pascal(5);
  for (final row in triangle) { print(row.join(' ')); }
  print('末行和 ${triangle.last.fold<int>(0, (sum, n) => sum + n)}');
}
''',
    output: "1\n1 1\n1 2 1\n1 3 3 1\n1 4 6 4 1\n末行和 16\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "取出第六行的第三个组合数，约定第一行为行号零。",
        hint: "先生成七行。再按零起点访问行和列。",
        answer: r'''
List<List<int>> pascal(int rows) {
  final triangle = <List<int>>[];
  for (var row = 0; row < rows; row++) {
    final next = List<int>.filled(row + 1, 1);
    for (var column = 1; column < row; column++) {
      next[column] = triangle[row - 1][column - 1] + triangle[row - 1][column];
    }
    triangle.add(next);
  }
  return triangle;
}

void main() {
  final triangle = pascal(7);
  print(triangle[6][2]);
}
''',
      ),
    ],
    exampleTitle: "示例 185：逐行构造杨辉三角",
    exampleSummary: "运行示例。观察从上一行相邻两项计算新行，并验证行和规律。",
  ),
  DartLesson(
    id: 'dart-lesson-186',
    chapter: 'math-stats',
    level: 'intermediate',
    title: "矩阵转置与形状检查",
    summary: "交换行列坐标，把二维表从按行读取变成按列读取。",
    concepts: <String>["矩阵转置", "二维索引", "矩形约束"],
    explain:
        "转置不是把每一行倒序，而是交换每个元素的行号和列号。一个两行三列的矩阵转置后，会得到三行两列。本例先确认各行长度一致。再根据列数生成新矩阵。程序通过两层循环复制元素。新矩阵的行必须分别生成，才能独立修改。最后把转置结果再转置一次，观察形状和数值回到原样。空矩阵也有明确返回值，避免直接读取第一行造成越界。这个本地二维表操作同样适用于离线成绩表或传感器数据整理。",
    objective: "能写出坐标交换关系，并拒绝不规则二维列表。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["List.filled 复用同一个内部列表会造成整列一起变化。", "要先检查空矩阵。再访问第一行。"],
    code: r'''
List<List<int>> transpose(List<List<int>> matrix) {
  if (matrix.isEmpty) return [];
  final columns = matrix.first.length;
  if (matrix.any((row) => row.length != columns)) {
    throw ArgumentError('矩阵必须等宽');
  }
  return List<List<int>>.generate(columns,
    (column) => [for (final row in matrix) row[column]]);
}
void main() {
  final original = [[1, 2, 3], [4, 5, 6]];
  final result = transpose(original);
  for (final row in result) { print(row); }
  print(transpose(result));
  print(transpose([]));
}
''',
    output: "[1, 4]\n[2, 5]\n[3, 6]\n[[1, 2, 3], [4, 5, 6]]\n[]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "写出二维矩阵按列求和的函数，并复用转置函数。",
        hint: "转置后的每一行正好是原来的某一列。",
        answer: r'''
List<List<int>> transpose(List<List<int>> matrix) {
  if (matrix.isEmpty) return [];
  final columns = matrix.first.length;
  if (matrix.any((row) => row.length != columns)) {
    throw ArgumentError('矩阵必须等宽');
  }
  return List<List<int>>.generate(columns,
    (column) => [for (final row in matrix) row[column]]);
}

List<int> columnSums(List<List<int>> matrix) => transpose(matrix)
    .map((row) => row.fold<int>(0, (sum, value) => sum + value)).toList();
void main() {
  print(columnSums([[1, 2], [3, 4]]));
  print(columnSums([]));
}
''',
      ),
    ],
    exampleTitle: "示例 186：矩阵转置与形状检查",
    exampleSummary: "运行示例。观察交换行列坐标，把二维表从按行读取变成按列读取。",
  ),
  DartLesson(
    id: 'dart-lesson-187',
    chapter: 'math-stats',
    level: 'intermediate',
    title: "矩阵乘法与维度契约",
    summary: "用行列点积计算多个原料配方的总消耗。",
    concepts: <String>["矩阵乘法", "点积", "维度校验"],
    explain:
        "矩阵乘法把左矩阵的一行与右矩阵的一列对应相乘后求和。因此左侧列数必须等于右侧行数。它不是同位置逐项相乘，运算顺序通常也不能交换。本例把订单数量和单位原料用量分别放在两个矩阵中，结果直接得到每组订单的原料总量。三个循环分别选择结果行、结果列和共享维度，明确显示每个累加项的来源。入口对维度不兼容作出拒绝，避免得到看似合理的错值。所有输入固定，离线可复现完整计算过程。",
    objective: "能从维度推导输出形状，并实现三重循环点积。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["只有中间维度相等才允许相乘。", "每个结果单元要从零开始独立累加。"],
    code: r'''
List<List<int>> multiply(List<List<int>> a, List<List<int>> b) {
  if (a.isEmpty || b.isEmpty || b.first.isEmpty) throw ArgumentError('矩阵不能为空');
  final shared = a.first.length;
  final columns = b.first.length;
  if (a.any((row) => row.length != shared) ||
      b.length != shared || b.any((row) => row.length != columns)) {
    throw ArgumentError('维度不兼容');
  }
  return List<List<int>>.generate(a.length, (row) =>
    List<int>.generate(columns, (column) {
      var sum = 0;
      for (var k = 0; k < shared; k++) { sum += a[row][k] * b[k][column]; }
      return sum;
    }));
}
void main() {
  final orders = [[2, 1], [0, 3]];
  final recipes = [[3, 1, 2], [1, 4, 0]];
  for (final row in multiply(orders, recipes)) { print(row); }
}
''',
    output: "[7, 6, 4]\n[3, 12, 0]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "构造二阶单位矩阵，验证左乘不会改变任意两行矩阵。",
        hint: "单位矩阵对角线为一，其余位置为零。",
        answer: r'''
List<List<int>> multiply(List<List<int>> a, List<List<int>> b) {
  if (a.isEmpty || b.isEmpty || b.first.isEmpty) throw ArgumentError('矩阵不能为空');
  final shared = a.first.length;
  final columns = b.first.length;
  if (a.any((row) => row.length != shared) ||
      b.length != shared || b.any((row) => row.length != columns)) {
    throw ArgumentError('维度不兼容');
  }
  return List<List<int>>.generate(a.length, (row) =>
    List<int>.generate(columns, (column) {
      var sum = 0;
      for (var k = 0; k < shared; k++) { sum += a[row][k] * b[k][column]; }
      return sum;
    }));
}

void main() {
  final identity = [[1, 0], [0, 1]];
  print(multiply(identity, [[5, 6, 7], [8, 9, 10]]));
}
''',
      ),
    ],
    exampleTitle: "示例 187：矩阵乘法与维度契约",
    exampleSummary: "运行示例。观察用行列点积计算多个原料配方的总消耗。",
  ),
  DartLesson(
    id: 'dart-lesson-188',
    chapter: 'math-stats',
    level: 'beginner',
    title: "均值、中位数与众数",
    summary: "比较三种中心位置指标如何响应极端观测值。",
    concepts: <String>["算术平均", "排序中位数", "频数分布"],
    explain:
        "一组数据的典型大小并非只有一种说法。均值使用所有数值，容易受极端值影响。中位数查看排序后的中间位置。众数则强调出现最频繁的值。本例选取含有重复项和较大离群值的等待时间，并同时计算三项指标。三项指标回答的问题不同。求中位数前先复制列表。再对副本排序。这样避免改变调用方数据。众数并列时采用较小值的明确规则。空数据直接拒绝，偶数项取中间两项平均。程序只处理本地固定样本，离线输出稳定。",
    objective: "能按数据特点选择中心指标，并处理偶数中位数。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["排序原列表会改变调用者的观测顺序。", "众数可能并列，需要在契约中规定取值策略。"],
    code: r'''
double median(List<int> values) {
  if (values.isEmpty) throw ArgumentError('样本不能为空');
  final sorted = List<int>.of(values)..sort();
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd ? sorted[middle].toDouble()
      : (sorted[middle - 1] + sorted[middle]) / 2;
}
void main() {
  final waits = [2, 3, 3, 4, 18];
  final counts = <int, int>{};
  for (final wait in waits) { counts[wait] = (counts[wait] ?? 0) + 1; }
  final ranked = counts.keys.toList()..sort((a, b) {
    final frequency = counts[b]!.compareTo(counts[a]!);
    return frequency != 0 ? frequency : a.compareTo(b);
  });
  print('均值 ${(waits.reduce((a, b) => a + b) / waits.length).toStringAsFixed(1)}');
  print('中位数 ${median(waits)}');
  print('众数 ${ranked.first}');
  print('偶数样本 ${median([2, 8, 4, 6])}');
}
''',
    output: "均值 6.0\n中位数 3.0\n众数 3\n偶数样本 5.0\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "去掉本例的最大等待时间。再比较均值与中位数。",
        hint: "复制数据、移除最大值，复用 median 并重新求和。",
        answer: r'''
double median(List<int> values) {
  if (values.isEmpty) throw ArgumentError('样本不能为空');
  final sorted = List<int>.of(values)..sort();
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd ? sorted[middle].toDouble()
      : (sorted[middle - 1] + sorted[middle]) / 2;
}

void main() {
  final trimmed = [2, 3, 3, 4, 18]..sort();
  trimmed.removeLast();
  print(trimmed.reduce((a, b) => a + b) / trimmed.length);
  print(median(trimmed));
}
''',
      ),
    ],
    exampleTitle: "示例 188：均值、中位数与众数",
    exampleSummary: "运行示例。观察比较三种中心位置指标如何响应极端观测值。",
  ),
  DartLesson(
    id: 'dart-lesson-189',
    chapter: 'math-stats',
    level: 'intermediate',
    title: "总体方差与标准差",
    summary: "在均值相同的样本中比较波动程度。",
    concepts: <String>["平方偏差", "总体方差", "标准差"],
    explain:
        "均值相同的两组测量结果，稳定性可能完全不同。方差把各观测与均值的差平方后求平均，避免正负偏差抵消。标准差再开平方，把单位还原到原观测量。本例比较两组平均温度相同的读数，并输出标准差。程序直观显示哪组波动更大。公式使用总体方差的分母数量，而不是样本估计常用的数量减一，二者不能混用。输出格式固定小数位便于阅读，计算本身仍保留浮点精度。整个统计过程可在离线运行时直接完成。",
    objective: "能区分中心位置和离散程度，并说明总体方差的分母。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["不要先把均值取整，否则平方偏差会系统性偏离。", "总体方差与无偏样本方差使用不同分母。"],
    code: r'''
import 'dart:math';
double variance(List<double> values) {
  if (values.isEmpty) throw ArgumentError('样本不能为空');
  final mean = values.reduce((a, b) => a + b) / values.length;
  var squared = 0.0;
  for (final value in values) { squared += pow(value - mean, 2); }
  return squared / values.length;
}
void main() {
  for (final readings in [[9.0, 10.0, 11.0], [0.0, 10.0, 20.0]]) {
    final value = variance(readings);
    print('方差 ${value.toStringAsFixed(2)}，标准差 ${sqrt(value).toStringAsFixed(2)}');
  }
}
''',
    output: "方差 0.67，标准差 0.82\n方差 66.67，标准差 8.16\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "实现至少需要两个观测值的样本方差。",
        hint: "复用总体方差乘以 n/(n-1)，并在入口检查长度。",
        answer: r'''
import 'dart:math';
double variance(List<double> values) {
  if (values.isEmpty) throw ArgumentError('样本不能为空');
  final mean = values.reduce((a, b) => a + b) / values.length;
  var squared = 0.0;
  for (final value in values) { squared += pow(value - mean, 2); }
  return squared / values.length;
}

double sampleVariance(List<double> values) {
  if (values.length < 2) throw ArgumentError('至少两个观测值');
  return variance(values) * values.length / (values.length - 1);
}
void main() {
  print(sampleVariance([1.0, 2.0, 3.0]));
  try { sampleVariance([1.0]); } on ArgumentError { print('拒绝单项样本'); }
}
''',
      ),
    ],
    exampleTitle: "示例 189：总体方差与标准差",
    exampleSummary: "运行示例。观察在均值相同的样本中比较波动程度。",
  ),
  DartLesson(
    id: 'dart-lesson-190',
    chapter: 'math-stats',
    level: 'intermediate',
    title: "滑动窗口移动平均",
    summary: "只更新移出和移入的元素，平滑连续观测序列。",
    concepts: <String>["滑动窗口", "增量求和", "序列平滑"],
    explain:
        "移动平均每次只查看最近固定数量的观测，可以减弱偶然尖峰对趋势的影响。若每个窗口重新求和，窗口越宽重复工作越多。保存当前窗口总和后，只需减去离开的值并加上新值。本例采用满窗口才输出的约定，因此结果长度比原始序列短。入口拒绝零宽和超过序列长度的窗口，并输出原始数据与平滑结果便于对照。窗口越大响应通常越慢，这也是平滑程度与时效之间的取舍。固定样本使离线结果可重复验证。",
    objective: "能维护窗口总和并解释输出长度。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["新窗口先减去旧元素。再加入新元素。索引不要错一位。", "移动平均会延迟对突变的响应，不能当作原始观测。"],
    code: r'''
List<double> movingAverage(List<int> values, int width) {
  if (width < 1 || width > values.length) throw ArgumentError('窗口宽度无效');
  var sum = 0;
  for (var i = 0; i < width; i++) { sum += values[i]; }
  final result = <double>[sum / width];
  for (var end = width; end < values.length; end++) {
    sum += values[end] - values[end - width];
    result.add(sum / width);
  }
  return result;
}
void main() {
  final samples = [2, 4, 12, 4, 3, 5];
  print(samples);
  print(movingAverage(samples, 3).map((n) => n.toStringAsFixed(2)).join(', '));
  print(movingAverage(samples, 1));
}
''',
    output:
        "[2, 4, 12, 4, 3, 5]\n6.00, 6.67, 6.33, 4.00\n[2.0, 4.0, 12.0, 4.0, 3.0, 5.0]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "给结果加上原序列的结束索引。让每个均值对应到准确时刻。",
        hint: "第一个满窗口的结束索引是 width-1。",
        answer: r'''
List<double> movingAverage(List<int> values, int width) {
  if (width < 1 || width > values.length) throw ArgumentError('窗口宽度无效');
  var sum = 0;
  for (var i = 0; i < width; i++) { sum += values[i]; }
  final result = <double>[sum / width];
  for (var end = width; end < values.length; end++) {
    sum += values[end] - values[end - width];
    result.add(sum / width);
  }
  return result;
}

void main() {
  final means = movingAverage([2, 4, 12, 4, 3, 5], 3);
  for (var i = 0; i < means.length; i++) {
    print('结束索引 ${i + 2}: ${means[i].toStringAsFixed(2)}');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 190：滑动窗口移动平均",
    exampleSummary: "运行示例。观察只更新移出和移入的元素，平滑连续观测序列。",
  ),
  DartLesson(
    id: 'dart-lesson-191',
    chapter: 'math-stats',
    level: 'advanced',
    title: "最小二乘直线拟合",
    summary: "从成对观测计算斜率、截距和预测残差。",
    concepts: <String>["最小二乘", "协方差分子", "退化输入"],
    explain:
        "线性回归用一条直线概括两个数值变量之间的关系。先计算横纵坐标均值。再把同一观测的中心化乘积求和。除以横坐标平方偏差和即可得到斜率。截距保证直线经过均值点。本例使用工时和产量的固定观测，输出拟合参数、一个预测值及残差平方和。横坐标全相同时分母为零，程序必须拒绝这种无法确定斜率的输入。回归描述变量间的关联，不自动证明因果关系，也不保证区间外预测准确。离线即可复现这些数值步骤。",
    objective: "能从中心化数据推导斜率，并拒绝零横向方差。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["横纵列表必须等长且至少包含两组观测。", "外推远离观测范围时，线性关系可能不再成立。"],
    code: r'''
List<double> fit(List<double> xs, List<double> ys) {
  if (xs.length != ys.length || xs.length < 2) throw ArgumentError('观测数量不匹配');
  final xMean = xs.reduce((a, b) => a + b) / xs.length;
  final yMean = ys.reduce((a, b) => a + b) / ys.length;
  var numerator = 0.0;
  var denominator = 0.0;
  for (var i = 0; i < xs.length; i++) {
    numerator += (xs[i] - xMean) * (ys[i] - yMean);
    denominator += (xs[i] - xMean) * (xs[i] - xMean);
  }
  if (denominator == 0) throw ArgumentError('横坐标不能全部相同');
  final slope = numerator / denominator;
  return [slope, yMean - slope * xMean];
}
void main() {
  final xs = [1.0, 2.0, 3.0, 4.0];
  final ys = [3.0, 5.0, 7.0, 9.0];
  final model = fit(xs, ys);
  print('斜率 ${model[0].toStringAsFixed(2)}，截距 ${model[1].toStringAsFixed(2)}');
  print('五小时预测 ${(model[0] * 5 + model[1]).toStringAsFixed(1)}');
  var error = 0.0;
  for (var i = 0; i < xs.length; i++) {
    final residual = ys[i] - (model[0] * xs[i] + model[1]);
    error += residual * residual;
  }
  print('残差平方和 ${error.toStringAsFixed(2)}');
}
''',
    output: "斜率 2.00，截距 1.00\n五小时预测 11.0\n残差平方和 0.00\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把最后一个产量改为十，观察模型与残差如何变化。",
        hint: "沿用 fit。然后重新逐项计算预测误差平方。",
        answer: r'''
List<double> fit(List<double> xs, List<double> ys) {
  if (xs.length != ys.length || xs.length < 2) throw ArgumentError('观测数量不匹配');
  final xMean = xs.reduce((a, b) => a + b) / xs.length;
  final yMean = ys.reduce((a, b) => a + b) / ys.length;
  var numerator = 0.0;
  var denominator = 0.0;
  for (var i = 0; i < xs.length; i++) {
    numerator += (xs[i] - xMean) * (ys[i] - yMean);
    denominator += (xs[i] - xMean) * (xs[i] - xMean);
  }
  if (denominator == 0) throw ArgumentError('横坐标不能全部相同');
  final slope = numerator / denominator;
  return [slope, yMean - slope * xMean];
}

void main() {
  final xs = [1.0, 2.0, 3.0, 4.0];
  final ys = [3.0, 5.0, 7.0, 10.0];
  final model = fit(xs, ys);
  print(model.map((v) => v.toStringAsFixed(2)).join(', '));
  var squaredError = 0.0;
  for (var i = 0; i < xs.length; i++) {
    final residual = ys[i] - (model[0] * xs[i] + model[1]);
    squaredError += residual * residual;
  }
  print(squaredError.toStringAsFixed(2));
}
''',
      ),
    ],
    exampleTitle: "示例 191：最小二乘直线拟合",
    exampleSummary: "运行示例。观察从成对观测计算斜率、截距和预测残差。",
  ),
  DartLesson(
    id: 'dart-lesson-192',
    chapter: 'math-stats',
    level: 'intermediate',
    title: "角度、弧度与二维旋转",
    summary: "把角度转换成弧度。再用三角函数旋转平面坐标。",
    concepts: <String>["弧度制", "旋转矩阵", "浮点误差"],
    explain:
        "界面和题目常使用角度，而标准三角函数接收弧度。两者之间通过圆周率换算：一百八十度等于圆周率弧度。本例先把九十度转换成弧度。再对平面中的点应用旋转公式。程序分别计算新的横纵坐标。最后计算旋转前后的距离，验证旋转保持到原点距离这一性质。浮点三角函数可能产生非常接近零的小数。因此用固定小数位显示。但不要据此要求内部结果精确等于零。程序只依赖本地数学库，离线即可运行和修改旋转角度。",
    objective: "能用弧度调用三角函数，并验证旋转保持距离。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["sin 和 cos 的参数单位是弧度。", "浮点误差适合用容差比较，不能普遍用精确相等。"],
    code: r'''
import 'dart:math';
List<double> rotate(double x, double y, double degrees) {
  final radians = degrees * pi / 180;
  return [x * cos(radians) - y * sin(radians),
          x * sin(radians) + y * cos(radians)];
}
void main() {
  final point = rotate(3, 4, 90);
  print('弧度 ${(90 * pi / 180).toStringAsFixed(4)}');
  print('旋转点 ${point.map((n) => n.toStringAsFixed(2)).join(', ')}');
  print('距离 ${sqrt(point[0] * point[0] + point[1] * point[1]).toStringAsFixed(2)}');
}
''',
    output: "弧度 1.5708\n旋转点 -4.00, 3.00\n距离 5.00\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "将点旋转三百六十度，使用容差验证回到原点。",
        hint: "分别检查横纵坐标误差的绝对值是否小于很小的阈值。",
        answer: r'''
import 'dart:math';
List<double> rotate(double x, double y, double degrees) {
  final radians = degrees * pi / 180;
  return [x * cos(radians) - y * sin(radians),
          x * sin(radians) + y * cos(radians)];
}

void main() {
  final point = rotate(3, 4, 360);
  print((point[0] - 3).abs() < 1e-9 && (point[1] - 4).abs() < 1e-9);
}
''',
      ),
    ],
    exampleTitle: "示例 192：角度、弧度与二维旋转",
    exampleSummary: "运行示例。观察把角度转换成弧度。再用三角函数旋转平面坐标。",
  ),
];
