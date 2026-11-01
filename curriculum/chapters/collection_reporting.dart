import '../dart_lesson.dart';

/// Chapter `collection-reporting` — independently executed lessons and paired examples.
const List<DartLesson> collectionReportingLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-250',
    chapter: "collection-reporting",
    level: "intermediate",
    title: "分组计数与首次出现顺序",
    summary: "用 Map 累加分类数量，保留输入中分类首次出现的顺序。",
    concepts: <String>["Map 累加", "默认值", "插入顺序"],
    explain:
        "一批工单可能包含重复分类，报表需要先把相同分类汇总成数量。程序逐条读取分类，用 Map 中已有数量或零作为基础加一，不需要为每个分类预先声明变量。默认 Map 保留键首次插入的顺序。因此输出按照分类第一次出现的位置排列。它不是自动按名称或数量排序。这个细节决定报表是否可预测。示例还对不存在的分类读取默认零，显示“没有记录”与“键存在但数量为零”的区别。若业务要求固定分类全集，应先初始化那张分类表。若要排名，应在统计完成后单独排序。",
    objective: "能用一个通用累加器统计任意分类，并解释输出顺序来源。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["不要每轮生成新的 Map，否则前面的统计会丢失。", "Map 的插入顺序并不等于按数量排序。"],
    code: r'''
void main() {
  final labels = ['bug', 'docs', 'bug', 'feature', 'docs', 'bug'];
  final counts = <String, int>{};
  for (final label in labels) counts[label] = (counts[label] ?? 0) + 1;
  for (final entry in counts.entries) print('${entry.key}:${entry.value}');
  print('test:${counts['test'] ?? 0}');
}
''',
    output: "bug:3\ndocs:2\nfeature:1\ntest:0\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "忽略空白分类。把大小写不同的同名分类归在一起。",
        hint: "先 trim。再转小写。最后判断是否为空。",
        answer: r'''
void main() {
  final counts = <String, int>{};
  for (final raw in [' Bug ', '', 'BUG', 'Docs']) {
    final key = raw.trim().toLowerCase();
    if (key.isNotEmpty) counts[key] = (counts[key] ?? 0) + 1;
  }
  print(counts);
}
''',
      ),
    ],
    exampleTitle: "示例 250：分组计数与首次出现顺序",
    exampleSummary: "用 Map 累加分类数量，保留输入中分类首次出现的顺序。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-251',
    chapter: "collection-reporting",
    level: "intermediate",
    title: "可重现的 Top N 排名",
    summary: "按数值降序并用名称打破并列，截取有限排名。",
    concepts: <String>["Comparator", "并列规则", "take"],
    explain:
        "排行榜不仅需要找出最大值，还要定义分数相同时谁先出现。程序把 Map 的条目复制为列表。程序先按数值降序比较。相同分数再按名称升序比较。这样形成完整且可重现的排序规则。随后只取前 N 项，并在显示时添加从一开始的名次。示例故意包含同分者，使第二比较条件不是摆设。这里显示的是位置排名，不是同分同名次的竞赛排名。如果产品需要同分共享名次，应另写名次分配规则。排序操作作用于复制出的条目列表，不会改变原始 Map 的插入顺序。",
    objective: "能编写有明确并列规则的排名。能安全处理 N 超过数据量的情况。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["只比较分数可能让并列结果依赖原始输入顺序。", "take 返回可迭代对象，不会自动生成名次。"],
    code: r'''
void main() {
  final points = {'Cora': 88, 'Bo': 95, 'Ada': 95, 'Dan': 72};
  final ranking = points.entries.toList();
  ranking.sort((a, b) {
    final score = b.value.compareTo(a.value);
    return score != 0 ? score : a.key.compareTo(b.key);
  });
  var rank = 1;
  for (final entry in ranking.take(3)) {
    print('${rank++}. ${entry.key} ${entry.value}');
  }
}
''',
    output: "1. Ada 95\n2. Bo 95\n3. Cora 88\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "过滤不足八十分的记录。再输出全部合格者排名。",
        hint: "过滤应发生在排序之前。名次来自过滤后的列表。",
        answer: r'''
void main() {
  final scores = {'安': 79, '白': 91, '陈': 84};
  final rows = scores.entries.where((e) => e.value >= 80).toList();
  rows.sort((a, b) => b.value.compareTo(a.value));
  for (var i = 0; i < rows.length; i++) print('${i + 1}:${rows[i].key}');
}
''',
      ),
    ],
    exampleTitle: "示例 251：可重现的 Top N 排名",
    exampleSummary: "按数值降序并用名称打破并列，截取有限排名。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-252',
    chapter: "collection-reporting",
    level: "intermediate",
    title: "固定区间直方图",
    summary: "把分数映射到互斥分箱，再用星号显示频数。",
    concepts: <String>["分箱", "边界归属", "文本图表"],
    explain:
        "直方图先把连续数值放入区间，再统计各区间频数。程序用整除得到十分一档的索引，并把满分一百单独归入最后一档，避免生成不存在的第十一档。输入先验证为零到一百，非法分数不能因为索引计算而误进某个箱子。输出固定十个箱，即使数量为零也保留一行，使不同数据集的报表能够直接比较。星号表示人数而不是分数本身。这里的区间左端包含、右端排除，最后一档例外地包含一百。这些边界比漂亮的图形更重要。",
    objective: "能实现覆盖完整范围且没有重叠的分箱统计。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["一百分除以十会得到索引十，需要明确处理。", "空箱不能直接省略，否则图表区间会发生视觉位移。"],
    code: r'''
void main() {
  final bins = List<int>.filled(10, 0);
  for (final score in [4, 18, 19, 55, 91, 100]) {
    if (score < 0 || score > 100) throw RangeError('分数范围');
    final index = score == 100 ? 9 : score ~/ 10;
    bins[index]++;
  }
  for (var i = 0; i < bins.length; i++) {
    final high = i == 9 ? 100 : i * 10 + 9;
    print('${i * 10}-$high:${List.filled(bins[i], '*').join()}');
  }
}
''',
    output:
        "0-9:*\n10-19:**\n20-29:\n30-39:\n40-49:\n50-59:*\n60-69:\n70-79:\n80-89:\n90-100:**\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "将分箱改为及格和不及格两组，并验证六十分属于及格组。",
        hint: "先判断 score >= 60。再累加对应计数。",
        answer: r'''
void main() {
  final counts = {'及格': 0, '不及格': 0};
  for (final score in [59, 60, 100]) {
    final key = score >= 60 ? '及格' : '不及格';
    counts[key] = counts[key]! + 1;
  }
  print(counts);
}
''',
      ),
    ],
    exampleTitle: "示例 252：固定区间直方图",
    exampleSummary: "把分数映射到互斥分箱，再用星号显示频数。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-253',
    chapter: "collection-reporting",
    level: "intermediate",
    title: "二维分类透视表",
    summary: "以地区和产品为两个维度累计数量，缺失组合补零。",
    concepts: <String>["嵌套 Map", "二维聚合", "缺失补零"],
    explain:
        "单维分组只能回答每个地区有多少，透视表还要区分地区内部的产品。程序把地区映射到另一张产品数量表，读取一条记录时先获得地区行，再更新产品列。显示阶段使用明确的地区和产品清单，对没有出现过的组合补零，让每行具有相同结构。输入中的重复组合会累计而不是互相覆盖。这个实现把“统计哪些维度”与“按什么顺序输出”分开，便于增加合计列或更换排列方式。若数据量很大，应关注组合数量带来的内存开销。本例使用固定离线记录显示核心数据流。",
    objective: "能生成二维聚合结构，并输出包含空组合的规则表格。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["行 Map 必须每个地区独立生成，不能共享同一对象。", "缺失组合是零值显示，不等于丢弃整个地区。"],
    code: r'''
void main() {
  final rows = [
    ['北', '茶', 2], ['南', '咖啡', 3], ['北', '茶', 4], ['南', '茶', 1],
  ];
  final table = <String, Map<String, int>>{};
  for (final row in rows) {
    final region = row[0] as String;
    final product = row[1] as String;
    final counts = table.putIfAbsent(region, () => <String, int>{});
    counts[product] = (counts[product] ?? 0) + (row[2] as int);
  }
  for (final region in ['北', '南']) {
    final counts = table[region]!;
    print('$region 茶=${counts['茶'] ?? 0} 咖啡=${counts['咖啡'] ?? 0}');
  }
}
''',
    output: "北 茶=6 咖啡=0\n南 茶=1 咖啡=3\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "为每个地区增加合计列。再输出全表总数。",
        hint: "遍历行内 values 求和。再累计每一行合计。",
        answer: r'''
void main() {
  final table = {'北': {'茶': 6}, '南': {'茶': 1, '咖啡': 3}};
  var grand = 0;
  for (final entry in table.entries) {
    var total = 0;
    for (final value in entry.value.values) total += value;
    grand += total;
    print('${entry.key}:$total');
  }
  print('总数:$grand');
}
''',
      ),
    ],
    exampleTitle: "示例 253：二维分类透视表",
    exampleSummary: "以地区和产品为两个维度累计数量，缺失组合补零。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-254',
    chapter: "collection-reporting",
    level: "intermediate",
    title: "带边界保护的分页",
    summary: "用页码和页大小计算切片，越界页返回空列表。",
    concepts: <String>["sublist", "范围保护", "页码转换"],
    explain:
        "分页接口常用从一开始的页码，而列表索引从零开始，因此开始位置应是页码减一再乘页大小。程序先拒绝非正参数，再判断开始位置是否越过数据尾部，最后把结束位置裁剪到实际长度。这样最后一页可以不足整页，后面的页返回空列表，而不会触发 sublist 越界。输出连续显示完整页、尾页和空页，覆盖三个不同分支。函数返回的是切片副本，修改它不会改变原列表。如果需要实时窗口视图，应另行定义所有权和更新规则。不能把两种行为混为一谈。",
    objective: "能实现页码明确、尾页安全的内存分页函数。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["先调用 sublist 再检查边界已经太晚。", "页码零不是第一页，非法参数不能悄悄修正。"],
    code: r'''
List<int> pageOf(List<int> items, int page, int size) {
  if (page < 1 || size < 1) throw ArgumentError('页码和大小必须为正');
  final start = (page - 1) * size;
  if (start >= items.length) return <int>[];
  final end = start + size < items.length ? start + size : items.length;
  return items.sublist(start, end);
}
void main() {
  final items = [10, 20, 30, 40, 50];
  print(pageOf(items, 1, 2));
  print(pageOf(items, 3, 2));
  print(pageOf(items, 4, 2));
}
''',
    output: "[10, 20]\n[50]\n[]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "计算空列表与五条记录在页大小二时各有多少页。",
        hint: "非空时可以用 (长度 + 大小 - 1) 整除大小。",
        answer: r'''
int pageCount(int length, int size) {
  if (size <= 0) throw ArgumentError('大小必须为正');
  return (length + size - 1) ~/ size;
}
void main() { print(pageCount(0, 2)); print(pageCount(5, 2)); }
''',
      ),
    ],
    exampleTitle: "示例 254：带边界保护的分页",
    exampleSummary: "用页码和页大小计算切片，越界页返回空列表。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-255',
    chapter: "collection-reporting",
    level: "intermediate",
    title: "集合差异分类",
    summary: "同时求新增、移除和保留项，把两个版本的数据变化分开。",
    concepts: <String>["Set.difference", "intersection", "版本对照"],
    explain:
        "同步两个成员列表时，单看最终数量无法知道哪些人加入、哪些人离开。程序先把输入转换为集合去除重复，再用方向相反的差集得到新增和移除项，用交集得到保留项。差集有方向，因此 old.difference(new) 与 new.difference(old) 的意义正好相反。显示前将结果转为列表并排序，避免让报告依赖来源的插入顺序。示例包含重复姓名，说明集合运算关注成员是否存在而不是出现次数。如果业务需要库存数量变化，应改用计数映射，而不是直接去重。",
    objective: "能把两个集合的变化划分为互不混淆的三类。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["差集交换参数后含义会反转。", "集合会丢弃重复次数，不能用于需要多重集语义的统计。"],
    code: r'''
String show(Set<String> values) => (values.toList()..sort()).join(',');
void main() {
  final before = ['Ada', 'Bo', 'Ada', 'Chen'].toSet();
  final after = ['Bo', 'Chen', 'Dan'].toSet();
  print('新增:${show(after.difference(before))}');
  print('移除:${show(before.difference(after))}');
  print('保留:${show(before.intersection(after))}');
}
''',
    output: "新增:Dan\n移除:Ada\n保留:Bo,Chen\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "求只出现在任意一边的成员，即对称差集。",
        hint: "把两个方向的差集合并，而不是取并集后直接输出。",
        answer: r'''
void main() {
  final a = {'a', 'b', 'c'};
  final b = {'b', 'd'};
  final changed = a.difference(b).union(b.difference(a)).toList()..sort();
  print(changed);
}
''',
      ),
    ],
    exampleTitle: "示例 255：集合差异分类",
    exampleSummary: "同时求新增、移除和保留项，把两个版本的数据变化分开。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-256',
    chapter: "collection-reporting",
    level: "intermediate",
    title: "按键累加合并报表",
    summary: "合并两个库存快照时为重复键求和，而不是覆盖。",
    concepts: <String>["Map 合并", "冲突策略", "输入不变"],
    explain:
        "Map 的展开语法默认让后面的同名键覆盖前面的值，但两家仓库合并库存时通常需要相加。程序先复制第一份映射，再遍历第二份，对已有键累加、对新键从零开始。这样冲突处理策略明确写在一行中，原始两份输入也保持不变。输出同时检查重复商品、新商品和原表未改变。这证明函数既计算了正确结果，也没有意外修改调用者数据。不同领域可能需要最大值、较新记录或错误提示。不要把某一种合并策略封装后偷偷用于所有 Map。应该由函数名称或参数清楚表达。",
    objective: "能为相同键定义明确的累加策略，并保持原始输入集合不变。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "直接 {...a, ...b} 会覆盖同名键而不是相加。",
      "把 result 指向 a 后更新会连带修改调用者数据。",
    ],
    code: r'''
Map<String, int> sumMaps(Map<String, int> a, Map<String, int> b) {
  final result = Map<String, int>.from(a);
  for (final entry in b.entries) {
    result[entry.key] = (result[entry.key] ?? 0) + entry.value;
  }
  return result;
}
void main() {
  final north = {'pen': 4, 'book': 2};
  final south = {'pen': 3, 'bag': 1};
  print(sumMaps(north, south));
  print(north);
}
''',
    output: "{pen: 7, book: 2, bag: 1}\n{pen: 4, book: 2}\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把冲突策略改为保留较大库存，并验证新键仍能加入。",
        hint: "取已有值与新值的较大者，不要在原始 Map 上修改。",
        answer: r'''
void main() {
  final result = <String, int>{'pen': 4, 'book': 2};
  for (final e in {'pen': 3, 'bag': 1}.entries) {
    final old = result[e.key];
    if (old == null || e.value > old) result[e.key] = e.value;
  }
  print(result);
}
''',
      ),
    ],
    exampleTitle: "示例 256：按键累加合并报表",
    exampleSummary: "合并两个库存快照时为重复键求和，而不是覆盖。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-257',
    chapter: "collection-reporting",
    level: "intermediate",
    title: "按首次出现顺序去重合并",
    summary: "借助 Set 判断是否见过，使用 List 保留合并结果的顺序。",
    concepts: <String>["Set.add", "顺序去重", "双集合职责"],
    explain:
        "合并推荐标签时，重复项只需出现一次，但输出顺序通常要保留第一次出现的位置。程序让 Set 专门判断某个值是否出现过，利用 add 的布尔返回值决定是否把它加入结果列表。列表负责顺序，集合负责快速查重，两个容器承担不同职责。示例包含同一组内部和不同组之间的重复项，验证去重是跨整个合并过程进行的。比较键就是原字符串，大小写和空白不会自动归一化。若要忽略这些差异，应先生成统一键。同时保留想显示的原始文本，而不是事后随意移除。",
    objective: "能合并多组数据并保留稳定的首次出现顺序。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["每处理一个子列表就清空 seen 会漏掉跨组重复。", "先排序再去重会改变首次出现的顺序语义。"],
    code: r'''
List<String> mergeUnique(List<List<String>> groups) {
  final seen = <String>{};
  final result = <String>[];
  for (final group in groups) {
    for (final value in group) {
      if (seen.add(value)) result.add(value);
    }
  }
  return result;
}
void main() {
  print(mergeUnique([['dart', 'cli', 'dart'], ['cli', 'test'], ['ui', 'dart']]));
}
''',
    output: "[dart, cli, test, ui]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "忽略大小写去重，同时保留首次出现的原始拼写。",
        hint: "seen 存小写键，result 存原始值。",
        answer: r'''
void main() {
  final seen = <String>{};
  final result = <String>[];
  for (final tag in ['Dart', 'CLI', 'dart', 'Test']) {
    if (seen.add(tag.toLowerCase())) result.add(tag);
  }
  print(result);
}
''',
      ),
    ],
    exampleTitle: "示例 257：按首次出现顺序去重合并",
    exampleSummary: "借助 Set 判断是否见过，使用 List 保留合并结果的顺序。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-258',
    chapter: "collection-reporting",
    level: "advanced",
    title: "分组均值保留分母",
    summary: "分别累加总分和人数，再计算每组均值。",
    concepts: <String>["sum/count", "分组聚合", "加权含义"],
    explain:
        "计算每组均值时，最可靠的中间状态是总和与数量，而不是不断平均已经算出的平均值。程序为每个班级保存两张映射，一张记录总分，另一张记录人数，最后统一做除法并格式化显示。这样无论输入顺序如何变化，结果都一致，也方便后续合并多个批次的统计。示例包含人数不同的班级，提醒读者不能把两个班级均值直接平均就当作全年级均值。程序不会对不存在的组做除法。如果要显示预先定义的空组，应该明确输出暂无数据，而不是伪造零分均值。",
    objective: "能维护可合并的均值中间状态，避免平均值再次平均的错误。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["平均两个均值时若人数不同，必须按人数加权。", "空组的均值没有定义，不能直接用零除以零。"],
    code: r'''
void main() {
  final records = [['A', 80], ['B', 90], ['A', 100], ['B', 60], ['B', 90]];
  final sums = <String, int>{};
  final counts = <String, int>{};
  for (final row in records) {
    final key = row[0] as String;
    sums[key] = (sums[key] ?? 0) + (row[1] as int);
    counts[key] = (counts[key] ?? 0) + 1;
  }
  for (final key in sums.keys) {
    print('$key 均分${(sums[key]! / counts[key]!).toStringAsFixed(1)} 人数${counts[key]}');
  }
}
''',
    output: "A 均分90.0 人数2\nB 均分80.0 人数3\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "根据两组的总分与人数计算整体均分。验证它不同于简单平均两组均分。",
        hint: "先分别合并总分和人数。再做一次除法。",
        answer: r'''
void main() {
  final totals = [180, 240];
  final counts = [2, 3];
  final average = totals.reduce((a, b) => a + b) / counts.reduce((a, b) => a + b);
  print(average.toStringAsFixed(1));
}
''',
      ),
    ],
    exampleTitle: "示例 258：分组均值保留分母",
    exampleSummary: "分别累加总分和人数，再计算每组均值。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-259',
    chapter: "collection-reporting",
    level: "advanced",
    title: "流水余额与累计检查",
    summary: "按事件顺序生成运行余额，并独立检查期末余额。",
    concepts: <String>["running total", "事件顺序", "守恒校验"],
    explain:
        "流水报表需要知道每一笔之后剩余多少，而不只是最终合计。程序从期初余额出发，依次把正收入和负支出加到余额中，打印每个事件的编号与结果。循环结束后再独立求所有变动的总和，验证期初加变动等于期末。这个检查能够发现漏处理一笔或重复处理一笔的问题，但不能证明原始业务数据本身正确。流水顺序会影响中途是否出现负余额，即使最终合计相同也不能随意重排。示例金额采用整数单位，避免显示过程的舍入影响累计，真实账目还应明确货币单位。",
    objective: "能生成逐笔累计状态，并用守恒关系检查处理完整性。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["累计变量应在循环外初始化。", "最终余额相同并不表示每一步的余额轨迹相同。"],
    code: r'''
void main() {
  const opening = 100;
  final changes = [50, -30, -80, 20];
  var balance = opening;
  for (var i = 0; i < changes.length; i++) {
    balance += changes[i];
    print('${i + 1}:$balance');
  }
  final totalChange = changes.fold<int>(0, (sum, item) => sum + item);
  print('校验:${opening + totalChange == balance}');
}
''',
    output: "1:150\n2:120\n3:40\n4:60\n校验:true\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "记录整个流水中的最低余额。再打印它首次出现的事件编号。",
        hint: "每次更新余额后与已知最低值比较。",
        answer: r'''
void main() {
  var balance = 100;
  var minimum = balance;
  var position = 0;
  final changes = [-30, -90, 50];
  for (var i = 0; i < changes.length; i++) {
    balance += changes[i];
    if (balance < minimum) { minimum = balance; position = i + 1; }
  }
  print('最低$minimum 第$position笔');
}
''',
      ),
    ],
    exampleTitle: "示例 259：流水余额与累计检查",
    exampleSummary: "按事件顺序生成运行余额，并独立检查期末余额。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-260',
    chapter: "collection-reporting",
    level: "advanced",
    title: "变化率的零基线处理",
    summary: "比较本期与上一期及去年同期，明确零基线没有普通增长率。",
    concepts: <String>["相对变化率", "nullable", "零分母"],
    explain:
        "增长率的分母是对照期数值，不是本期数值。程序把变化率封装成返回可空结果的函数。当基线为零时返回 null。此时显示层输出无基线，而不是给出无穷大。它也不会把结果伪装成百分之百。非零基线则计算差值除以基线，再乘一百并保留一位小数。示例分别显示环比增长、同比下降和从零起步三种情况。函数把负基线视为不适用。因为负利润的增长率往往需要额外业务解释。如果领域允许负基线，应先确定分母和符号的约定。不能直接照搬销售额规则。",
    objective: "能正确选择变化率分母，并把无法定义的结果传递给显示层。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["不要使用当前值作为增长率分母。", "零基线时返回零会误导读者以为没有变化。"],
    code: r'''
double? growth(int current, int baseline) {
  if (baseline <= 0) return null;
  return (current - baseline) * 100 / baseline;
}
String label(double? value) => value == null ? '无基线' : '${value.toStringAsFixed(1)}%';
void main() {
  const current = 120;
  print('环比 ${label(growth(current, 100))}');
  print('同比 ${label(growth(current, 150))}');
  print('新品 ${label(growth(20, 0))}');
}
''',
    output: "环比 20.0%\n同比 -20.0%\n新品 无基线\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "同时输出绝对增量和相对变化率。基线为零时仍保留绝对增量。",
        hint: "先算 current - baseline。再独立判断百分比是否有定义。",
        answer: r'''
void main() {
  for (final pair in [[120, 100], [20, 0]]) {
    final delta = pair[0] - pair[1];
    final rate = pair[1] == 0 ? '无基线' : '${(delta * 100 / pair[1]).toStringAsFixed(1)}%';
    print('增量$delta 变化$rate');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 260：变化率的零基线处理",
    exampleSummary: "比较本期与上一期及去年同期，明确零基线没有普通增长率。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-261',
    chapter: "collection-reporting",
    level: "advanced",
    title: "聚合后输出对齐报表",
    summary: "先计算商品小计与总额，再依据内容宽度统一输出。",
    concepts: <String>["报表管线", "动态列宽", "汇总行"],
    explain:
        "一个清晰的报表应先完成业务计算，再决定每列怎样对齐。程序把商品数量与单价相乘得到小计，累计总额，同时根据商品名和小计文本计算列宽。输出阶段只读取这些已确定的数据，名称左对齐，数值右对齐，并在末尾给出总计。这样新增更长商品名或更大金额时，不需要手工修改固定空格。为让字符宽度规则明确，示例名称使用 ASCII。中文、组合字符和终端宽字符需要额外的终端宽度算法。String.length 只能计算代码单元，不能保证终端列宽。",
    objective: "能将统计和排版分成两个阶段，生成适应内容长度的汇总表。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "不要边打印边修改列宽，否则早先行无法重新对齐。",
      "String.length 不等于任意 Unicode 文本的终端宽度。",
    ],
    code: r'''
void main() {
  final names = ['Pen', 'Notebook'];
  final quantities = [3, 2];
  final prices = [120, 550];
  final subtotals = <int>[];
  var total = 0;
  var width = 4;
  for (var i = 0; i < names.length; i++) {
    if (names[i].length > width) width = names[i].length;
    final value = quantities[i] * prices[i];
    subtotals.add(value);
    total += value;
  }
  print('${'Item'.padRight(width)} | Cents');
  for (var i = 0; i < names.length; i++) {
    print('${names[i].padRight(width)} | ${subtotals[i].toString().padLeft(5)}');
  }
  print('${'TOTAL'.padRight(width)} | ${total.toString().padLeft(5)}');
}
''',
    output:
        "Item     | Cents\nPen      |   360\nNotebook |  1100\nTOTAL    |  1460\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "在报表中增加数量列，保证数量右对齐为三格。",
        hint: "数量是计算输入，显示时单独转为文本并 padLeft。",
        answer: r'''
void main() {
  final rows = {'Pen': 3, 'Notebook': 2};
  for (final e in rows.entries) {
    print('${e.key.padRight(8)} | ${e.value.toString().padLeft(3)}');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 261：聚合后输出对齐报表",
    exampleSummary: "先计算商品小计与总额，再依据内容宽度统一输出。完整运行演示。",
  ),
];
