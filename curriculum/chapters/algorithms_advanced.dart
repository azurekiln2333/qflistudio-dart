import '../dart_lesson.dart';

/// Chapter `algorithms-advanced` — independently executed lessons and paired examples.
const List<DartLesson> algorithmsAdvancedLessons = <DartLesson>[
  DartLesson(
    id: "dart-lesson-157",
    chapter: "algorithms-advanced",
    level: "beginner",
    title: "阶乘的递归与迭代",
    summary: "用相同的边界定义实现两种阶乘。再逐项对照实际计算结果。",
    concepts: <String>["递归基例", "迭代累乘", "输入契约"],
    explain:
        "阶乘把一个非负整数之前的所有正整数连乘起来，其中零的阶乘约定为一。"
        "这个边界既让递归能够停止，也让组合公式在空选择时保持一致。"
        "程序分别实现递归与迭代。"
        "递归把 n 的结果归约为 n 乘更小问题。"
        "迭代从一开始维护已处理前缀的乘积。"
        "两种实现使用相同的负数检查，因此不会让非法输入无限递归。"
        "示例只计算较小整数。再逐项比较输出，帮助识别基例或循环边界错误。"
        "递归会占用调用栈，迭代只保存累积值。"
        "两者都不能忽略普通 int 的表示范围。"
        "大规模精确阶乘需要选择 BigInt 等数据表示。"
        "不能假设乘积可以无限增长。",
    objective: "能统一递归与迭代的阶乘边界，并用对照执行检查结果。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>["把零阶乘写成零，会让所有递归乘积都变成零。", "没有拒绝负数会破坏递归规模持续接近基例的保证。"],
    code: r'''
int factorialRecursive(int n) {
  if (n < 0) throw ArgumentError('阶乘要求非负数');
  return n <= 1 ? 1 : n * factorialRecursive(n - 1);
}
int factorialIterative(int n) {
  if (n < 0) throw ArgumentError('阶乘要求非负数');
  var product = 1;
  for (var value = 2; value <= n; value++) product *= value;
  return product;
}
void main() {
  for (final n in [0, 1, 5, 8]) print('$n! = ${factorialRecursive(n)} / ${factorialIterative(n)}');
}
''',
    output: "0! = 1 / 1\n1! = 1 / 1\n5! = 120 / 120\n8! = 40320 / 40320\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "比较零到八的两种阶乘实现。再验证负数输入会明确拒绝。",
        hint: "every 可汇总对照结果。负数边界用 on ArgumentError 捕获。失败不能当作数值。",
        answer: r'''
int factorialRecursive(int n) {
  if (n < 0) throw ArgumentError('阶乘要求非负数');
  return n <= 1 ? 1 : n * factorialRecursive(n - 1);
}
int factorialIterative(int n) {
  if (n < 0) throw ArgumentError('阶乘要求非负数');
  var product = 1;
  for (var value = 2; value <= n; value++) product *= value;
  return product;
}
void main() {
  print(List.generate(9, (n) => factorialRecursive(n) == factorialIterative(n)).every((same) => same));
  try { factorialIterative(-1); } on ArgumentError { print('负数已拒绝'); }
}
''',
      ),
    ],
    exampleTitle: "示例 157：阶乘的递归与迭代",
    exampleSummary: "共享基例的阶乘递归与迭代对照。",
  ),
  DartLesson(
    id: "dart-lesson-158",
    chapter: "algorithms-advanced",
    level: "beginner",
    title: "斐波那契的三种求值",
    summary: "比较递归、滚动迭代与记忆化，把重复子问题转成可复用结果。",
    concepts: <String>["重复子问题", "滚动变量", "记忆化"],
    explain:
        "斐波那契数列的每一项依赖前两项，直接递归会反复计算同一批子问题。"
        "程序保留这种直观定义。"
        "程序再加入滚动迭代，只保存相邻两项。"
        "程序还加入记忆化版本，把已求结果存进 Map。"
        "记忆化不会改变数学递推式。"
        "它避免同一个 n 完整展开多次。"
        "迭代则按依赖顺序主动求值，通常不需要递归调用栈。"
        "三种函数共同约定前两项为零和一，并拒绝负数，便于对照。"
        "示例选择较小的 n，让朴素递归仍能快速结束。"
        "缓存只能用于定义和输入条件相同的问题。"
        "如果递推规则也可能变化，就要把条件纳入缓存键。"
        "否则复用的可能是另一个问题的答案。",
    objective: "能识别重复子问题，并区分滚动状态与记忆化缓存的成本。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "朴素递归会指数级重复求值，只应拿小输入作教学对照。",
      "缓存键若没有覆盖影响结果的全部条件，会复用错误状态。",
    ],
    code: r'''
int fibRecursive(int n) {
  if (n < 0) throw ArgumentError('要求非负数');
  return n < 2 ? n : fibRecursive(n - 1) + fibRecursive(n - 2);
}
int fibIterative(int n) {
  if (n < 0) throw ArgumentError('要求非负数');
  var previous = 0; var current = 1;
  for (var i = 0; i < n; i++) { final next = previous + current; previous = current; current = next; }
  return previous;
}
int fibMemo(int n, Map<int, int> cache) {
  if (n < 0) throw ArgumentError('要求非负数');
  if (n < 2) return n;
  if (cache.containsKey(n)) return cache[n]!;
  return cache[n] = fibMemo(n - 1, cache) + fibMemo(n - 2, cache);
}
void main() {
  final cache = <int, int>{};
  print(fibRecursive(10)); print(fibIterative(10)); print(fibMemo(10, cache));
  print('缓存子问题 ${cache.length}');
}
''',
    output: "55\n55\n55\n缓存子问题 9\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "共享一张缓存求零到十的全部项。再逐项验证记忆化结果与迭代结果相同。",
        hint: "缓存放在循环外。构造列表时记录求值结果。再用索引检查迭代版本。",
        answer: r'''
int fibRecursive(int n) {
  if (n < 0) throw ArgumentError('要求非负数');
  return n < 2 ? n : fibRecursive(n - 1) + fibRecursive(n - 2);
}
int fibIterative(int n) {
  if (n < 0) throw ArgumentError('要求非负数');
  var previous = 0; var current = 1;
  for (var i = 0; i < n; i++) { final next = previous + current; previous = current; current = next; }
  return previous;
}
int fibMemo(int n, Map<int, int> cache) {
  if (n < 0) throw ArgumentError('要求非负数');
  if (n < 2) return n;
  if (cache.containsKey(n)) return cache[n]!;
  return cache[n] = fibMemo(n - 1, cache) + fibMemo(n - 2, cache);
}
void main() {
  final cache = <int, int>{};
  final values = List.generate(11, (n) => fibMemo(n, cache));
  print(values);
  print(List.generate(11, (n) => values[n] == fibIterative(n)).every((same) => same));
}
''',
      ),
    ],
    exampleTitle: "示例 158：斐波那契的三种求值",
    exampleSummary: "同一递推定义的朴素、滚动和缓存三种实现。",
  ),
  DartLesson(
    id: "dart-lesson-159",
    chapter: "algorithms-advanced",
    level: "intermediate",
    title: "爬楼梯的状态与基例",
    summary: "把到达台阶的方案数定义为状态，解释零级台阶为什么有一种方案。",
    concepts: <String>["动态规划", "计数状态", "空方案"],
    explain:
        "每次可以上一阶或两阶时，到达第 n 阶的最后一步只能来自前一阶或前两阶。"
        "把到达每一级的方案数记作状态，就得到两个较小状态相加的递推关系。"
        "零级台阶应设为一种方案，表示什么都不做的空行动。"
        "这样从地面直接走两阶的情况才会正确计入。"
        "程序先建立这两个基例。再从小到大计算所有台阶，保证读到的依赖已经求出。"
        "虽然递推式和斐波那契相似，状态的业务含义与下标起点不同，不能仅凭公式外形抄结果。"
        "该建模还可扩展到禁用某一级台阶，或改变允许步长。"
        "但每种约束都要重新检查状态转移是否有效。",
    objective: "能从最后一步推导方案数。能为零级台阶设置有业务含义的基例。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "把 dp[0] 设成零，会漏算直接从地面出发的合法路径。",
      "允许步长或禁用台阶改变后，原递推式不一定仍然成立。",
    ],
    code: r'''
int stairWays(int n) {
  if (n < 0) throw ArgumentError('台阶数不能为负');
  final ways = List<int>.filled(n + 1, 0);
  ways[0] = 1;
  for (var step = 1; step <= n; step++) {
    ways[step] = ways[step - 1] + (step >= 2 ? ways[step - 2] : 0);
  }
  return ways[n];
}
void main() {
  for (final steps in [0, 1, 2, 5]) print('$steps 级：${stairWays(steps)} 种');
}
''',
    output: "0 级：1 种\n1 级：1 种\n2 级：2 种\n5 级：8 种\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "五级台阶中第三级禁止停留。仍允许每次一阶或两阶。计算到顶的方案数。",
        hint: "禁用级的方案数保持零。其余位置按相同前驱相加。零级仍为一。",
        answer: r'''
int stairWays(int n) {
  if (n < 0) throw ArgumentError('台阶数不能为负');
  final ways = List<int>.filled(n + 1, 0);
  ways[0] = 1;
  for (var step = 1; step <= n; step++) {
    ways[step] = ways[step - 1] + (step >= 2 ? ways[step - 2] : 0);
  }
  return ways[n];
}
void main() {
  final ways = List<int>.filled(6, 0); ways[0] = 1;
  for (var step = 1; step <= 5; step++) {
    if (step != 3) ways[step] = ways[step - 1] + (step > 1 ? ways[step - 2] : 0);
  }
  print(ways);
  print('到顶 ${ways[5]} 种');
}
''',
      ),
    ],
    exampleTitle: "示例 159：爬楼梯的状态与基例",
    exampleSummary: "从最后一步分类得到的楼梯方案动态规划。",
  ),
  DartLesson(
    id: "dart-lesson-160",
    chapter: "algorithms-advanced",
    level: "intermediate",
    title: "零钱兑换的最少枚数",
    summary: "为每个金额保存最小硬币数量，用不可达哨兵区分无解与零枚。",
    concepts: <String>["最优化 DP", "不可达状态", "非贪心选择"],
    explain:
        "零钱兑换的最少枚数不总能靠先拿最大硬币解决。"
        "例如面值一、三、四兑换六时，两枚三元更好。"
        "四元加两个一元则需要三枚。"
        "本例为每个金额保存目前所需的最少枚数。再枚举最后一枚硬币来自哪个面值。"
        "金额零需要零枚，其他金额先设置成不可能达到的上界，避免把尚未求出的状态误当成最优零枚。"
        "每次转移只接受足够大的当前金额。最后若目标仍不可达则返回负一。"
        "面值必须为正，金额必须非负，否则递推依赖可能不再朝较小状态移动。"
        "这个表既表达最优值，也清楚地区分空方案与无解，适合扩展记录前驱以还原具体硬币组合。",
    objective: "能建立最少枚数状态。能通过反例理解贪心不能普遍替代动态规划。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "未计算状态不能默认零，否则会把一枚硬币错误地兑换任意金额。",
      "零面值或负面值破坏依赖方向，必须在建立状态表之前拒绝。",
    ],
    code: r'''
int minimumCoins(List<int> coins, int amount) {
  if (amount < 0 || coins.any((coin) => coin <= 0)) throw ArgumentError('金额和面值无效');
  final dp = List<int>.filled(amount + 1, amount + 1); dp[0] = 0;
  for (var sum = 1; sum <= amount; sum++) {
    for (final coin in coins) {
      if (coin <= sum && dp[sum - coin] + 1 < dp[sum]) dp[sum] = dp[sum - coin] + 1;
    }
  }
  return dp[amount] > amount ? -1 : dp[amount];
}
void main() {
  print(minimumCoins([1, 3, 4], 6));
  print(minimumCoins([4, 6], 5));
  print(minimumCoins([2, 5], 0));
}
''',
    output: "2\n-1\n0\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "实现从大面值开始的贪心兑换。再与 minimumCoins 对 [4,3,1]、金额 6 的结果比较。",
        hint: "贪心用整除取出枚数并取余。最后仍要输出 DP 结果。再观察两种策略的差异。",
        answer: r'''
int minimumCoins(List<int> coins, int amount) {
  if (amount < 0 || coins.any((coin) => coin <= 0)) throw ArgumentError('金额和面值无效');
  final dp = List<int>.filled(amount + 1, amount + 1); dp[0] = 0;
  for (var sum = 1; sum <= amount; sum++) {
    for (final coin in coins) {
      if (coin <= sum && dp[sum - coin] + 1 < dp[sum]) dp[sum] = dp[sum - coin] + 1;
    }
  }
  return dp[amount] > amount ? -1 : dp[amount];
}
void main() {
  final coins = <int>[4, 3, 1]; var remaining = 6; var greedy = 0;
  for (final coin in coins) { greedy += remaining ~/ coin; remaining %= coin; }
  print('贪心 $greedy');
  print('最优 ${minimumCoins(coins, 6)}');
}
''',
      ),
    ],
    exampleTitle: "示例 160：零钱兑换的最少枚数",
    exampleSummary: "带不可达哨兵的最少硬币数和贪心反例。",
  ),
  DartLesson(
    id: "dart-lesson-161",
    chapter: "algorithms-advanced",
    level: "intermediate",
    title: "零钱组合数与循环顺序",
    summary: "先枚举面值再推进金额，避免把同一组硬币的排列重复计数。",
    concepts: <String>["组合计数", "循环顺序", "无限次使用"],
    explain:
        "求最少硬币和求兑换方案数是两个不同问题。"
        "本课把不考虑硬币拿取顺序的组合数作为目标，因此一元加两元与两元加一元只算一种。"
        "程序外层逐个引入面值。"
        "内层金额从小到大推进。"
        "当前状态只组合已经引入的面值。"
        "这样能避免按最后一步重复计算排列。"
        "金额零设为一种空组合，为后续恰好使用一枚硬币的情况提供起点。"
        "同一面值可以无限使用。"
        "所以内层允许读到当前面值更新过的较小金额。"
        "输入面值必须去除重复。"
        "否则相同面值会作为不同类别重复计数。"
        "改变内层方向会改变是否允许重复使用，循环顺序本身就是组合契约的一部分。",
    objective: "能说明面值优先与金额递增如何计组合，并验证空组合基例。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "外层按金额、内层按面值通常会把不同排列计为多种方案。",
      "重复面值会重复引入同一硬币类别，输入必须保持面值唯一。",
    ],
    code: r'''
int coinCombinations(List<int> coins, int amount) {
  if (amount < 0 || coins.any((coin) => coin <= 0) || coins.toSet().length != coins.length) throw ArgumentError('输入无效');
  final ways = List<int>.filled(amount + 1, 0); ways[0] = 1;
  for (final coin in coins) {
    for (var sum = coin; sum <= amount; sum++) ways[sum] += ways[sum - coin];
  }
  return ways[amount];
}
void main() {
  print(coinCombinations([1, 2, 5], 5));
  print(coinCombinations([2], 3));
  print(coinCombinations([1, 2], 0));
}
''',
    output: "4\n0\n1\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把面值 1、2、3 改成每枚只能使用一次。计算金额 4 的方案数。再与无限使用情况对照。",
        hint: "金额循环改为从目标向下走。这样每枚硬币只读到上一轮的状态。",
        answer: r'''
int coinCombinations(List<int> coins, int amount) {
  if (amount < 0 || coins.any((coin) => coin <= 0) || coins.toSet().length != coins.length) throw ArgumentError('输入无效');
  final ways = List<int>.filled(amount + 1, 0); ways[0] = 1;
  for (final coin in coins) {
    for (var sum = coin; sum <= amount; sum++) ways[sum] += ways[sum - coin];
  }
  return ways[amount];
}
void main() {
  final coins = <int>[1, 2, 3]; final ways = List<int>.filled(5, 0); ways[0] = 1;
  for (final coin in coins) {
    for (var sum = 4; sum >= coin; sum--) ways[sum] += ways[sum - coin];
  }
  print('每枚一次 ${ways[4]}');
  print('无限使用 ${coinCombinations(coins, 4)}');
}
''',
      ),
    ],
    exampleTitle: "示例 161：零钱组合数与循环顺序",
    exampleSummary: "利用面值优先和递增金额计算无序兑换组合。",
  ),
  DartLesson(
    id: "dart-lesson-162",
    chapter: "algorithms-advanced",
    level: "intermediate",
    title: "最长公共子序列长度",
    summary: "用两段前缀作为状态，在跳过字符与匹配字符之间选择最优值。",
    concepts: <String>["二维 DP", "前缀状态", "子序列"],
    explain:
        "子序列允许跳过原串中的字符，但不能改变保留下来的顺序，因此它不要求像子串那样连续。"
        "最长公共子序列把两个字符串各自的前缀长度作为二维状态。"
        "末尾字符相同时，可以在去掉双方末尾的最佳长度上加一。"
        "不同时，分别尝试跳过一侧末尾，取两者较大值。"
        "空前缀与任何文本的公共长度都是零，形成状态表的第一行和第一列。"
        "程序为每一行分配独立列表，防止多行共享同一个可变数组。"
        "填表顺序从短前缀向长前缀推进，依赖总在左、上或左上方。"
        "本例处理普通英文字符，输出长度而非具体序列。"
        "要恢复序列还需根据状态表反向选择路径。",
    objective: "能区分子序列与子串，并独立初始化二维状态的每一行。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "子序列不要求连续，不能用相邻公共片段长度代替。",
      "List.filled 重复放入同一个可变行会使多行互相影响，应逐行分配。",
    ],
    code: r'''
int lcsLength(String a, String b) {
  final dp = List.generate(a.length + 1, (_) => List<int>.filled(b.length + 1, 0));
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      if (a[i - 1] == b[j - 1]) { dp[i][j] = dp[i - 1][j - 1] + 1; }
      else { dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1]; }
    }
  }
  return dp[a.length][b.length];
}
void main() {
  print(lcsLength('ABCBDAB', 'BDCABA'));
  print(lcsLength('ABC', 'AC'));
  print(lcsLength('', 'AC'));
}
''',
    output: "4\n2\n0\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "验证公共子序列长度的对称性。再检查 A、AB、ABC、ABCD 与 ACD 的匹配长度。",
        hint: "同一对文本交换参数后结果相同。增加前缀长度不会使最优长度减少。",
        answer: r'''
int lcsLength(String a, String b) {
  final dp = List.generate(a.length + 1, (_) => List<int>.filled(b.length + 1, 0));
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      if (a[i - 1] == b[j - 1]) { dp[i][j] = dp[i - 1][j - 1] + 1; }
      else { dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1]; }
    }
  }
  return dp[a.length][b.length];
}
void main() {
  print(lcsLength('BANANA', 'ATANA') == lcsLength('ATANA', 'BANANA'));
  print(['A', 'AB', 'ABC', 'ABCD'].map((prefix) => lcsLength(prefix, 'ACD')).toList());
}
''',
      ),
    ],
    exampleTitle: "示例 162：最长公共子序列长度",
    exampleSummary: "按双前缀填表的最长公共子序列计算。",
  ),
  DartLesson(
    id: "dart-lesson-163",
    chapter: "algorithms-advanced",
    level: "intermediate",
    title: "最长递增子序列",
    summary: "以每个位置为结尾保存最佳长度，区分严格递增与相等延续。",
    concepts: <String>["LIS", "以当前位置结尾", "平方级 DP"],
    explain:
        "最长递增子序列可以跳过元素，却必须维持原有位置顺序。"
        "本例把状态定义为以某个位置结尾的最长严格递增长度。"
        "每个元素至少能独立形成长度一的序列。"
        "对当前位置，检查所有更早且数值更小的前驱。"
        "程序尝试把它们的长度加一。"
        "全局答案则是所有结尾状态的最大值。"
        "强调“以这里结尾”能避免把前缀内其他位置的最佳结果错误地直接延续。"
        "严格递增要求前驱值小于当前值，相等元素不能增长长度，因此重复值例子能有效检验比较条件。"
        "双重循环需要 O(n²) 时间，适合先理解状态含义。"
        "更快的二分优化使用另一套维护信息，不应在未解释不变量时直接替换。",
    objective: "能建立按结尾位置定义的 LIS 状态，并检验重复值的严格性。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "把小于写成小于等于会变成最长非递减子序列，问题含义改变。",
      "答案不一定在最后一个位置结束，必须比较全部结尾状态。",
    ],
    code: r'''
int lisLength(List<int> values) {
  if (values.isEmpty) return 0;
  final lengths = List<int>.filled(values.length, 1);
  var best = 1;
  for (var i = 0; i < values.length; i++) {
    for (var j = 0; j < i; j++) {
      if (values[j] < values[i] && lengths[j] + 1 > lengths[i]) lengths[i] = lengths[j] + 1;
    }
    if (lengths[i] > best) best = lengths[i];
  }
  return best;
}
void main() {
  print(lisLength([10, 9, 2, 5, 3, 7, 101, 18]));
  print(lisLength([2, 2, 2]));
  print(lisLength([]));
}
''',
    output: "4\n1\n0\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "对 [1,2,2,3] 另算最长非递减子序列。再与严格递增长度比较。",
        hint: "保持状态定义不变。只让相等值也可以作为合法前驱。再观察两种契约的区别。",
        answer: r'''
int lisLength(List<int> values) {
  if (values.isEmpty) return 0;
  final lengths = List<int>.filled(values.length, 1);
  var best = 1;
  for (var i = 0; i < values.length; i++) {
    for (var j = 0; j < i; j++) {
      if (values[j] < values[i] && lengths[j] + 1 > lengths[i]) lengths[i] = lengths[j] + 1;
    }
    if (lengths[i] > best) best = lengths[i];
  }
  return best;
}
void main() {
  final values = <int>[1, 2, 2, 3]; final dp = List<int>.filled(values.length, 1);
  var best = 1;
  for (var i = 0; i < values.length; i++) {
    for (var j = 0; j < i; j++) if (values[j] <= values[i] && dp[j] + 1 > dp[i]) dp[i] = dp[j] + 1;
    if (dp[i] > best) best = dp[i];
  }
  print('严格 ${lisLength(values)}'); print('非递减 $best');
}
''',
      ),
    ],
    exampleTitle: "示例 163：最长递增子序列",
    exampleSummary: "按结尾位置延伸的严格递增子序列状态。",
  ),
  DartLesson(
    id: "dart-lesson-164",
    chapter: "algorithms-advanced",
    level: "intermediate",
    title: "零一背包的倒序更新",
    summary: "每件物品最多选一次，用容量倒序保护上一轮状态。",
    concepts: <String>["0/1 背包", "倒序容量", "状态压缩"],
    explain:
        "零一背包要求每件物品要么选择一次，要么不选，在容量上限内获得最大价值。"
        "状态记录给定容量目前能达到的最佳价值。"
        "引入一件物品时，比较不选它的情况。"
        "还要比较为它腾出重量后的价值加成。"
        "一维压缩省去了物品维度。"
        "但更新方向因此变成正确性的关键。"
        "容量从大到小遍历时，读取的较小容量仍属于上一轮。"
        "这样当前物品就不会重复使用。"
        "若改为从小到大，后面的容量可能读到已经包含当前物品的值，问题会变成可重复选取。"
        "程序验证重量和价值长度一致、重量为正，输出最佳值而不强制恰好装满。"
        "若要求装满，还需要为不可达容量设置不同初值。",
    objective: "能解释倒序更新如何保持每件物品最多一次。能区分装满与不超容量。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "容量正序更新会允许当前物品重复参与，破坏零一约束。",
      "默认零初值表示可以留空，并不代表每个容量都能恰好装满。",
    ],
    code: r'''
int knapsack(List<int> weights, List<int> values, int capacity) {
  if (capacity < 0 || weights.length != values.length || weights.any((w) => w <= 0)) throw ArgumentError('物品输入无效');
  final dp = List<int>.filled(capacity + 1, 0);
  for (var item = 0; item < weights.length; item++) {
    for (var space = capacity; space >= weights[item]; space--) {
      final candidate = dp[space - weights[item]] + values[item];
      if (candidate > dp[space]) dp[space] = candidate;
    }
  }
  return dp[capacity];
}
void main() {
  print(knapsack([2, 3, 4], [3, 4, 5], 5));
  print(knapsack([2], [3], 4));
  print(knapsack([2, 3], [3, 4], 0));
}
''',
    output: "7\n3\n0\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "单件物品重量 2、价值 3、容量 4。分别计算只能选一次与可无限选择的结果。",
        hint: "无限选择版本把容量改为正序。两个结果能直接体现更新方向的含义。",
        answer: r'''
int knapsack(List<int> weights, List<int> values, int capacity) {
  if (capacity < 0 || weights.length != values.length || weights.any((w) => w <= 0)) throw ArgumentError('物品输入无效');
  final dp = List<int>.filled(capacity + 1, 0);
  for (var item = 0; item < weights.length; item++) {
    for (var space = capacity; space >= weights[item]; space--) {
      final candidate = dp[space - weights[item]] + values[item];
      if (candidate > dp[space]) dp[space] = candidate;
    }
  }
  return dp[capacity];
}
void main() {
  final unlimited = List<int>.filled(5, 0);
  for (var capacity = 2; capacity <= 4; capacity++) unlimited[capacity] = unlimited[capacity - 2] + 3;
  print('只能一次 ${knapsack([2], [3], 4)}');
  print('无限选择 ${unlimited[4]}');
}
''',
      ),
    ],
    exampleTitle: "示例 164：零一背包的倒序更新",
    exampleSummary: "通过倒序容量保证物品只选一次的压缩背包。",
  ),
  DartLesson(
    id: "dart-lesson-165",
    chapter: "algorithms-advanced",
    level: "advanced",
    title: "网格最小路径和",
    summary: "只允许向右或向下移动，用一行状态保存最小累计代价。",
    concepts: <String>["网格 DP", "滚动数组", "依赖覆盖"],
    explain:
        "在矩形网格中从左上走到右下，如果只能向右或向下，每个位置的最优代价只依赖上方与左方。"
        "程序用一行数组压缩二维状态。"
        "更新前的 dp[j] 是上一行同列的结果。"
        "更新后的 dp[j-1] 是本行左侧结果。"
        "程序取较小者再加当前格子代价。"
        "左上角、第一行和第一列分别处理，因为它们缺少某一方向的前驱。"
        "逐行逐列更新的顺序保证覆盖旧值之前已经使用完必要依赖。"
        "输入必须非空且每行等长，参差列表并不能代表这个矩形问题。"
        "示例输出累计代价，不保存具体路线。"
        "若还要还原路线，需额外记录前驱或保留更多状态。",
    objective: "能解释单行状态更新前后的含义，并处理矩形网格的边界。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "dp[j] 更新后不再代表上方状态，改变遍历方向会改变依赖含义。",
      "空网格或行宽不一致应先拒绝，不能直接访问第一格。",
    ],
    code: r'''
int minimumPath(List<List<int>> grid) {
  if (grid.isEmpty || grid[0].isEmpty || grid.any((row) => row.length != grid[0].length)) throw ArgumentError('要求非空矩形');
  final dp = List<int>.filled(grid[0].length, 0);
  for (var row = 0; row < grid.length; row++) {
    for (var column = 0; column < dp.length; column++) {
      final cost = grid[row][column];
      if (row == 0 && column == 0) { dp[column] = cost; }
      else if (row == 0) { dp[column] = dp[column - 1] + cost; }
      else if (column == 0) { dp[column] += cost; }
      else { dp[column] = (dp[column] < dp[column - 1] ? dp[column] : dp[column - 1]) + cost; }
    }
  }
  return dp.last;
}
void main() {
  print(minimumPath([[1, 3, 1], [1, 5, 1], [4, 2, 1]]));
  print(minimumPath([[2, 4, 1]]));
}
''',
    output: "7\n7\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "将一个网格转置后比较最小路径和：原网格为 [[1,4,2],[2,1,3]]。",
        hint: "转置会交换向右与向下这两个方向。允许的移动方向因此整体对称。所以最优代价应保持一致。",
        answer: r'''
int minimumPath(List<List<int>> grid) {
  if (grid.isEmpty || grid[0].isEmpty || grid.any((row) => row.length != grid[0].length)) throw ArgumentError('要求非空矩形');
  final dp = List<int>.filled(grid[0].length, 0);
  for (var row = 0; row < grid.length; row++) {
    for (var column = 0; column < dp.length; column++) {
      final cost = grid[row][column];
      if (row == 0 && column == 0) { dp[column] = cost; }
      else if (row == 0) { dp[column] = dp[column - 1] + cost; }
      else if (column == 0) { dp[column] += cost; }
      else { dp[column] = (dp[column] < dp[column - 1] ? dp[column] : dp[column - 1]) + cost; }
    }
  }
  return dp.last;
}
void main() {
  final grid = <List<int>>[[1, 4, 2], [2, 1, 3]];
  final transposed = List.generate(grid[0].length, (column) => List.generate(grid.length, (row) => grid[row][column]));
  print(transposed);
  print(minimumPath(grid));
  print(minimumPath(grid) == minimumPath(transposed));
}
''',
      ),
    ],
    exampleTitle: "示例 165：网格最小路径和",
    exampleSummary: "右下方向约束下的一行滚动最小代价状态。",
  ),
  DartLesson(
    id: "dart-lesson-166",
    chapter: "algorithms-advanced",
    level: "advanced",
    title: "编辑距离的三种操作",
    summary: "在插入、删除、替换之间取最小代价，量化两段文本的差异。",
    concepts: <String>["Levenshtein", "前缀 DP", "操作代价"],
    explain:
        "编辑距离衡量把一段文本变成另一段文本的最少操作次数。"
        "本课把插入、删除和替换都计为一。"
        "二维状态描述两个前缀之间的距离，空串转成长度为 j 的前缀需要 j 次插入，反向则需要删除。"
        "当前字符相同时沿用左上状态。"
        "不同时分别考虑删除、插入或替换。"
        "然后取最小代价加一。"
        "程序分配独立的二维行，按前缀长度顺序填表，避免依赖尚未计算的位置。"
        "这个距离对拼写建议有帮助，但它不理解语义，也不能把两个意思相近的词自动判为相近。"
        "示例使用 ASCII 单词，若要按用户看到的字素衡量多语言文本，必须先改变分词单位。",
    objective: "能推导插入、删除、替换的前缀转移。能解释编辑距离的适用范围。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "第一行和第一列不能全为零，空串转换需要真实的插入或删除次数。",
      "字符编辑距离只描述形式差异，并不衡量词语含义是否接近。",
    ],
    code: r'''
int minThree(int a, int b, int c) { final first = a < b ? a : b; return first < c ? first : c; }
int editDistance(String a, String b) {
  final dp = List.generate(a.length + 1, (_) => List<int>.filled(b.length + 1, 0));
  for (var i = 0; i <= a.length; i++) dp[i][0] = i;
  for (var j = 0; j <= b.length; j++) dp[0][j] = j;
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      dp[i][j] = a[i - 1] == b[j - 1] ? dp[i - 1][j - 1] : 1 + minThree(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]);
    }
  }
  return dp[a.length][b.length];
}
void main() {
  print(editDistance('kitten', 'sitting'));
  print(editDistance('', 'cat'));
  print(editDistance('dart', 'dart'));
}
''',
    output: "3\n3\n0\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "用 1 减距离除以较长文本长度定义简易相似度。比较 cat/cut 与空串/空串。",
        hint: "两段都为空时分母为零。这时应明确返回相似度一。其他情况才执行除法。",
        answer: r'''
int minThree(int a, int b, int c) { final first = a < b ? a : b; return first < c ? first : c; }
int editDistance(String a, String b) {
  final dp = List.generate(a.length + 1, (_) => List<int>.filled(b.length + 1, 0));
  for (var i = 0; i <= a.length; i++) dp[i][0] = i;
  for (var j = 0; j <= b.length; j++) dp[0][j] = j;
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      dp[i][j] = a[i - 1] == b[j - 1] ? dp[i - 1][j - 1] : 1 + minThree(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]);
    }
  }
  return dp[a.length][b.length];
}
void main() {
  for (final pair in <List<String>>[['cat', 'cut'], ['', '']]) {
    final a = pair[0]; final b = pair[1]; final width = a.length > b.length ? a.length : b.length;
    final similarity = width == 0 ? 1.0 : 1 - editDistance(a, b) / width;
    print(similarity.toStringAsFixed(2));
  }
}
''',
      ),
    ],
    exampleTitle: "示例 166：编辑距离的三种操作",
    exampleSummary: "明确三种单位代价的双前缀编辑距离。",
  ),
  DartLesson(
    id: "dart-lesson-167",
    chapter: "algorithms-advanced",
    level: "advanced",
    title: "障碍网格的路径计数",
    summary: "遇到障碍清零当前状态，让可达路径只从合法前驱累计。",
    concepts: <String>["可达性", "障碍清零", "路径计数"],
    explain:
        "最短代价与路径数量虽然都发生在网格上，状态含义却完全不同。"
        "本例只统计从左上到右下的合法路线数，允许向右或向下，数字一代表障碍、零代表可通行。"
        "滚动数组初始只给起点方向放入一种空路径。"
        "每个普通格子累计上方和左方的方案。"
        "遇到障碍就立即将该列状态清零。"
        "清零能阻止上一行路径穿过障碍继续向下传播。"
        "起点或终点封闭时也会自然得到零。"
        "边界列没有左方前驱，因此只保留上方值。"
        "计数依赖网格为矩形以及障碍约定一致。"
        "若允许回退或绕圈，简单的单向动态规划就不再描述同一个问题。",
    objective: "能将障碍转成不可达状态，并正确处理封闭的起点和终点。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "障碍格若不清零，旧行路径可能穿过阻塞点继续传播。",
      "这套递推只适用于单向移动，不能直接用于允许回退的路径问题。",
    ],
    code: r'''
int gridPaths(List<List<int>> grid) {
  if (grid.isEmpty || grid[0].isEmpty || grid.any((row) => row.length != grid[0].length)) throw ArgumentError('要求非空矩形');
  final ways = List<int>.filled(grid[0].length, 0); ways[0] = 1;
  for (final row in grid) {
    for (var column = 0; column < ways.length; column++) {
      if (row[column] == 1) { ways[column] = 0; }
      else if (column > 0) { ways[column] += ways[column - 1]; }
    }
  }
  return ways.last;
}
void main() {
  print(gridPaths([[0, 0, 0], [0, 1, 0], [0, 0, 0]]));
  print(gridPaths([[1, 0], [0, 0]]));
  print(gridPaths([[0]]));
}
''',
    output: "2\n0\n1\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "先计算无障碍 2×3 网格的路线数。再把终点封闭并确认路线数变为零。",
        hint: "修改终点后重新调用函数，局部滚动数组应每次重新初始化。",
        answer: r'''
int gridPaths(List<List<int>> grid) {
  if (grid.isEmpty || grid[0].isEmpty || grid.any((row) => row.length != grid[0].length)) throw ArgumentError('要求非空矩形');
  final ways = List<int>.filled(grid[0].length, 0); ways[0] = 1;
  for (final row in grid) {
    for (var column = 0; column < ways.length; column++) {
      if (row[column] == 1) { ways[column] = 0; }
      else if (column > 0) { ways[column] += ways[column - 1]; }
    }
  }
  return ways.last;
}
void main() {
  final grid = <List<int>>[[0, 0, 0], [0, 0, 0]];
  print(gridPaths(grid));
  grid[1][2] = 1;
  print(gridPaths(grid));
}
''',
      ),
    ],
    exampleTitle: "示例 167：障碍网格的路径计数",
    exampleSummary: "遇障碍立即清零的单向网格路线计数。",
  ),
  DartLesson(
    id: "dart-lesson-168",
    chapter: "algorithms-advanced",
    level: "advanced",
    title: "有向无环图的记忆化",
    summary: "以节点为缓存键统计到终点的路线。再与逆序填表结果比较。",
    concepts: <String>["DAG", "记忆化搜索", "递归栈检测"],
    explain:
        "动态规划并不只发生在连续数字下标上，任务依赖图中的节点同样可以作为状态。"
        "本例统计每个节点到终点的路线数。"
        "终点贡献一种完成路径。"
        "其他节点把后继的方案数相加。"
        "自顶向下版本只搜索实际可达的状态并缓存结果。"
        "active 集合单独记录当前递归链，用来识别循环依赖。"
        "它与已经完成的缓存不能混为一谈。"
        "另一个版本按给定拓扑序反向填表，使所有后继先完成，二者应得到相同答案。"
        "搜索分支出现循环依赖时，本函数会明确拒绝，而不是无限递归。"
        "缓存中的零也是有效答案，表示节点无法到达终点，必须和未计算状态区分。",
    objective: "能把节点作为 DP 状态。能区分缓存、当前递归链与拓扑依赖顺序。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "用同一个 visited 代替 active 和缓存，可能把共享后继误报为环。",
      "零路线是已计算结果，不能因为值为零就反复展开该节点。",
    ],
    code: r'''
int memoPaths(String node, String target, Map<String, List<String>> graph, Map<String, int> cache, Set<String> active) {
  if (node == target) return 1;
  if (cache.containsKey(node)) return cache[node]!;
  if (!active.add(node)) throw StateError('循环依赖');
  try {
    var total = 0;
    for (final next in graph[node] ?? <String>[]) total += memoPaths(next, target, graph, cache, active);
    cache[node] = total;
    return total;
  } finally { active.remove(node); }
}
int tablePaths(List<String> order, String target, Map<String, List<String>> graph) {
  final ways = <String, int>{target: 1};
  for (final node in order.reversed) {
    if (node != target) {
      var total = 0;
      for (final next in graph[node] ?? <String>[]) total += ways[next] ?? 0;
      ways[node] = total;
    }
  }
  return ways[order[0]] ?? 0;
}
void main() {
  final graph = <String, List<String>>{'start': ['left', 'right'], 'left': ['join'], 'right': ['join'], 'join': ['finish']};
  final memo = memoPaths('start', 'finish', graph, {}, {});
  final table = tablePaths(['start', 'left', 'right', 'join', 'finish'], 'finish', graph);
  print('搜索 $memo，填表 $table'); print(memo == table);
}
''',
    output: "搜索 2，填表 2\ntrue\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "构造 a→b、b→a 的循环依赖。调用记忆化搜索并确认抛出 StateError。不要等待无限递归。",
        hint: "目标节点取不在环中的 finish。active 会在再次进入 a 时发现递归链重复。",
        answer: r'''
int memoPaths(String node, String target, Map<String, List<String>> graph, Map<String, int> cache, Set<String> active) {
  if (node == target) return 1;
  if (cache.containsKey(node)) return cache[node]!;
  if (!active.add(node)) throw StateError('循环依赖');
  try {
    var total = 0;
    for (final next in graph[node] ?? <String>[]) total += memoPaths(next, target, graph, cache, active);
    cache[node] = total;
    return total;
  } finally { active.remove(node); }
}
int tablePaths(List<String> order, String target, Map<String, List<String>> graph) {
  final ways = <String, int>{target: 1};
  for (final node in order.reversed) {
    if (node != target) {
      var total = 0;
      for (final next in graph[node] ?? <String>[]) total += ways[next] ?? 0;
      ways[node] = total;
    }
  }
  return ways[order[0]] ?? 0;
}
void main() {
  final graph = <String, List<String>>{'a': ['b'], 'b': ['a']};
  try { memoPaths('a', 'finish', graph, {}, {}); }
  on StateError { print('循环依赖已拒绝'); }
}
''',
      ),
    ],
    exampleTitle: "示例 168：有向无环图的记忆化",
    exampleSummary: "节点缓存与拓扑逆序两种 DAG 路线计数。",
  ),
];
