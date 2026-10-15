import '../dart_lesson.dart';

/// Chapter `collections` — lessons 019-028. Owned by the first pi.
const List<DartLesson> collectionsLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-019',
    chapter: 'collections',
    level: 'intermediate',
    title: '列表 List 基础',
    summary: '有序可重复的列表、下标访问与常用方法。',
    concepts: <String>['List', '下标', 'add', 'length', 'contains'],
    explain:
        'List 是最常用的集合，元素有序、可重复，下标从 0 开始。Dart 里没有 Python '
        '那样的负下标，-1 不是最后一个。常用方法有 add、remove、length、contains。',
    objective: '会用 List 增删查改并遍历。',
    pitfalls: <String>[
      '用 fruits[-1] 取最后一个元素会运行时报错，应该用 fruits.last。',
      '越界访问会抛 RangeError，遍历时用 length 做边界。',
    ],
    code:
        "void main() {\n"
        "  final fruits = ['苹果', '香蕉', '橙子'];\n"
        "  fruits.add('葡萄');\n"
        "  print(fruits);\n"
        "  print(fruits[0]);\n"
        "  print(fruits.last);\n"
        "  print('共 \${fruits.length} 种');\n"
        "  print('含香蕉？\${fruits.contains('香蕉')}');\n"
        "  fruits.remove('香蕉');\n"
        "  print(fruits);\n"
        "}\n",
    output: '[苹果, 香蕉, 橙子, 葡萄]\n苹果\n葡萄\n共 4 种\n含香蕉？true\n[苹果, 橙子, 葡萄]\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '创建一个装 3 个数字的列表，把第一个元素改成 99 并打印。',
        hint: '用 nums[0] = 99。',
        answer: "final nums = [1, 2, 3];\nnums[0] = 99;\nprint(nums);",
      ),
    ],
    exampleTitle: '示例 019：列表基础',
    exampleSummary: '增删查改、下标访问与 contains 判断。',
  ),
  DartLesson(
    id: 'dart-lesson-020',
    chapter: 'collections',
    level: 'intermediate',
    title: '列表遍历与范围',
    summary: 'for 下标遍历、for-in 遍历与 sublist 取子段。',
    concepts: <String>['for-in', '下标遍历', 'sublist', 'reversed'],
    explain:
        '遍历列表有两种常用方式：用下标 for (var i = 0; i < list.length; i++) 可以同时'
        '拿到索引；for (final x in list) 只关心元素更简洁。sublist 取一段，reversed '
        '反向查看，注意这些都是返回新列表，不改原列表。',
    objective: '能按需选择下标遍历或 for-in，并切片和反转。',
    pitfalls: <String>[
      'sublist 的结束下标是开区间，不含该位置。',
      'reversed 返回的是可迭代对象，要 toList 才是列表。',
    ],
    code:
        "void main() {\n"
        "  final scores = [88, 92, 79, 95];\n"
        "  for (var i = 0; i < scores.length; i++) {\n"
        "    print('第 \${i + 1} 名：\${scores[i]}');\n"
        "  }\n"
        "  for (final s in scores) {\n"
        "    if (s >= 90) print('优秀分：\$s');\n"
        "  }\n"
        "  print(scores.sublist(1, 3));\n"
        "  print(scores.reversed.toList());\n"
        "}\n",
    output:
        '第 1 名：88\n第 2 名：92\n第 3 名：79\n第 4 名：95\n'
        '优秀分：92\n优秀分：95\n[92, 79]\n[95, 79, 92, 88]\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '打印列表 [10, 20, 30, 40] 的后两个元素。',
        hint: 'sublist(2)。',
        answer: "print([10, 20, 30, 40].sublist(2));",
      ),
    ],
    exampleTitle: '示例 020：列表遍历与切片',
    exampleSummary: '下标遍历、for-in 筛选、sublist 与 reversed。',
  ),
  DartLesson(
    id: 'dart-lesson-021',
    chapter: 'collections',
    level: 'intermediate',
    title: '列表排序与查找',
    summary: 'sort、indexOf、every 与 any。',
    concepts: <String>['sort', 'indexOf', 'every', 'any'],
    explain:
        'sort 会就地排序（默认升序），可以用自定义比较器排降序。indexOf 找元素下标，'
        '找不到返回 -1。every 判断是否全部满足条件，any 判断是否存在满足条件的元素。',
    objective: '会排序列表并判断整体是否满足条件。',
    pitfalls: <String>[
      'sort 是就地排序，会修改原列表；想保留原序应先复制。',
      'indexOf 返回 -1 代表不存在，别把它当成有效下标使用。',
    ],
    code:
        "void main() {\n"
        "  final nums = [88, 92, 79, 95, 67];\n"
        "  nums.sort();\n"
        "  print(nums);\n"
        "  nums.sort((a, b) => b - a);\n"
        "  print(nums);\n"
        "  print(nums.indexOf(88));\n"
        "  print(nums.indexOf(100));\n"
        "  print(nums.every((n) => n >= 60));\n"
        "  print(nums.any((n) => n > 90));\n"
        "}\n",
    output: '[67, 79, 88, 92, 95]\n[95, 92, 88, 79, 67]\n2\n-1\ntrue\ntrue\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '把 [3, 1, 2] 排序并判断是否所有元素都大于 0。',
        hint: 'sort 后 every。',
        answer:
            "final nums = [3, 1, 2]..sort();\nprint(nums);\nprint(nums.every((n) => n > 0));",
      ),
    ],
    exampleTitle: '示例 021：列表排序与查找',
    exampleSummary: '升序降序排序、indexOf 查找与 every/any 判断。',
  ),
  DartLesson(
    id: 'dart-lesson-022',
    chapter: 'collections',
    level: 'intermediate',
    title: '映射 Map 基础',
    summary: '键值对存取、containsKey 与 entries 遍历。',
    concepts: <String>['Map', '键值对', 'containsKey', 'entries'],
    explain:
        'Map 用键查值：map[key] 取值，取不存在的键返回 null。为避免把 null 当成'
        '「值就是 null」，可以先 containsKey 判断，或用 ?? 给默认值。遍历用 entries，'
        '每个 entry 有 key 和 value。',
    objective: '会用 Map 存取数据并安全处理缺失键。',
    pitfalls: <String>[
      '对不存在的键直接取再当非空用，会拿到 null 引发错误。',
      'Map 的键要能稳定哈希，用可变对象做键容易出问题。',
    ],
    code:
        "void main() {\n"
        "  final student = <String, Object>{\n"
        "    'name': '小明',\n"
        "    'age': 18,\n"
        "    'score': 88,\n"
        "  };\n"
        "  print(student['name']);\n"
        "  print(student['city'] ?? '未填写');\n"
        "  print(student.containsKey('city'));\n"
        "  student['city'] = '杭州';\n"
        "  for (final entry in student.entries) {\n"
        "    print('\${entry.key} = \${entry.value}');\n"
        "  }\n"
        "}\n",
    output: '小明\n未填写\nfalse\nname = 小明\nage = 18\nscore = 88\ncity = 杭州\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用 Map 存三种水果的价格，打印苹果价格（缺失时打印「未知」）。',
        hint: '用 ?? 兜底。',
        answer:
            "final prices = {'apple': 5.5, 'banana': 3.0, 'cherry': 12.0};\n"
            "print(prices['apple'] ?? '未知');",
      ),
    ],
    exampleTitle: '示例 022：Map 基础',
    exampleSummary: '键值对存取、缺失键处理与 entries 遍历。',
  ),
  DartLesson(
    id: 'dart-lesson-023',
    chapter: 'collections',
    level: 'intermediate',
    title: '集合 Set 去重',
    summary: '用 Set 保存不重复元素，做交并差运算。',
    concepts: <String>['Set', '去重', '交集', '并集', '差集'],
    explain:
        'Set 是一组不重复的元素。把列表交给 Set 就能去重：{...list} 或 list.toSet()。'
        'Set 支持 intersection（交集）、union（并集）、difference（差集），在统计场景'
        '很有用。',
    objective: '会用 Set 去重并做集合运算。',
    pitfalls: <String>['Set 无序，不要依赖它的遍历顺序。', '用 Set 去重会丢失重复次数，需要计数时应改用 Map。'],
    code:
        "void main() {\n"
        "  final nums = [1, 2, 2, 3, 3, 3];\n"
        "  final unique = nums.toSet();\n"
        "  print(unique);\n"
        "  print(unique.length);\n"
        "\n"
        "  final a = {1, 2, 3};\n"
        "  final b = {2, 3, 4};\n"
        "  print(a.intersection(b));\n"
        "  print(a.union(b));\n"
        "  print(a.difference(b));\n"
        "}\n",
    output: '{1, 2, 3}\n3\n{2, 3}\n{1, 2, 3, 4}\n{1}\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用 Set 判断两个列表是否有公共元素。',
        hint: 'intersection 非空即有。',
        answer:
            "final x = [1, 2, 3].toSet();\n"
            "final y = [3, 4, 5].toSet();\n"
            "print(x.intersection(y).isNotEmpty);",
      ),
    ],
    exampleTitle: '示例 023：Set 去重与集合运算',
    exampleSummary: '列表去重、交集、并集与差集。',
  ),
  DartLesson(
    id: 'dart-lesson-024',
    chapter: 'collections',
    level: 'intermediate',
    title: '高阶方法 map 与 where',
    summary: '把列表变换成新列表、按条件过滤。',
    concepts: <String>['map', 'where', 'toList', '链式调用'],
    explain:
        'map 把每个元素变换成一个新值，where 按条件保留元素。它们返回惰性的可迭代'
        '对象，需要时再 toList 变成列表。链式组合 where 和 map 能写出「先筛选再变换」'
        '的清晰逻辑。',
    objective: '会用 map/where 链式处理列表。',
    pitfalls: <String>[
      '忘记 toList 会得到 lazy 的 Iterable，多次遍历可能重复计算。',
      'map 里尽量保持纯函数，不要在变换过程中修改外部状态。',
    ],
    code:
        "void main() {\n"
        "  final nums = [1, 2, 3, 4, 5, 6];\n"
        "  final doubled = nums.map((n) => n * 2).toList();\n"
        "  print(doubled);\n"
        "  final evens = nums.where((n) => n.isEven).toList();\n"
        "  print(evens);\n"
        "  final names = ['a', 'bb', 'ccc'];\n"
        "  final lengths = names.map((s) => s.length).toList();\n"
        "  print(lengths);\n"
        "}\n",
    output: '[2, 4, 6, 8, 10, 12]\n[2, 4, 6]\n[1, 2, 3]\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '把 [1,2,3,4,5] 里的奇数平方后收集成列表。',
        hint: 'where 奇数再 map 平方。',
        answer:
            "final result = [1, 2, 3, 4, 5]\n"
            "    .where((n) => n.isOdd)\n"
            "    .map((n) => n * n)\n"
            "    .toList();\nprint(result);",
      ),
    ],
    exampleTitle: '示例 024：map 与 where',
    exampleSummary: '变换、过滤与链式组合成新列表。',
  ),
  DartLesson(
    id: 'dart-lesson-025',
    chapter: 'collections',
    level: 'intermediate',
    title: '聚合 fold 与 reduce',
    summary: '用 fold/reduce 把列表归约成单个值。',
    concepts: <String>['fold', 'reduce', '求和', '求最值'],
    explain:
        'fold 带一个初始值，把列表归约成一个结果，类型可以和元素类型不同。reduce '
        '用第一个元素当初始值，要求列表非空。求和常用 fold(0, (a, b) => a + b)。',
    objective: '会用 fold 求聚合结果，并知道 reduce 的空列表限制。',
    pitfalls: <String>[
      '对空列表调用 reduce 会抛 StateError，先用 fold 或判空。',
      'fold 的初始值类型决定了结果类型，写 fold<int>(...) 可以避免类型推断歧义。',
    ],
    code:
        "void main() {\n"
        "  final nums = [3, 1, 4, 1, 5, 9, 2, 6];\n"
        "  final total = nums.fold<int>(0, (a, b) => a + b);\n"
        "  print('总和 \$total');\n"
        "  final max = nums.fold<int>(nums.first, (a, b) => a > b ? a : b);\n"
        "  print('最大 \$max');\n"
        "  final words = ['a', 'b', 'c'];\n"
        "  print(words.fold<String>('', (acc, w) => acc + w));\n"
        "}\n",
    output: '总和 31\n最大 9\nabc\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用 fold 求 [2,4,6] 的乘积。',
        hint: '初始值 1。',
        answer: "print([2, 4, 6].fold<int>(1, (a, b) => a * b));",
      ),
    ],
    exampleTitle: '示例 025：fold 与 reduce',
    exampleSummary: '求和、求最大值与字符串拼接的归约。',
  ),
  DartLesson(
    id: 'dart-lesson-026',
    chapter: 'collections',
    level: 'intermediate',
    title: '扩展运算符与集合字面量',
    summary: '用 ... 展开集合、if/for 在字面量里构造。',
    concepts: <String>['spread', '...?', 'collection-if', 'collection-for'],
    explain:
        '在字面量里用 ... 展开另一个集合，用 ...? 展开可能为 null 的集合。还能在'
        '字面量里写 if 和 for：需要条件性地加入元素时非常方便。这些写法让集合的'
        '构造即声明，无需先建空列表再 add。',
    objective: '会用展开运算符和集合 if/for 构造集合。',
    pitfalls: <String>[
      '对可能为 null 的集合用 ... 会报错，应改用 ...?。',
      '展开只是浅拷贝，嵌套的子集合仍是共享引用。',
    ],
    code:
        "void main() {\n"
        "  final base = [1, 2, 3];\n"
        "  final extended = [0, ...base, 4];\n"
        "  print(extended);\n"
        "\n"
        "  const includeBonus = true;\n"
        "  final rewards = ['基础奖励', if (includeBonus) '额外奖励'];\n"
        "  print(rewards);\n"
        "\n"
        "  final squares = [for (var i = 1; i <= 4; i++) i * i];\n"
        "  print(squares);\n"
        "\n"
        "  final List<int>? maybe = null;\n"
        "  final safe = [...?maybe, 9];\n"
        "  print(safe);\n"
        "}\n",
    output: '[0, 1, 2, 3, 4]\n[基础奖励, 额外奖励]\n[1, 4, 9, 16]\n[9]\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用 collection-for 生成 [1,2,3] 的立方列表。',
        hint: '[for (var i = 1; i <= 3; i++) i*i*i]。',
        answer: "print([for (var i = 1; i <= 3; i++) i * i * i]);",
      ),
    ],
    exampleTitle: '示例 026：展开运算符与集合字面量',
    exampleSummary: 'spread、...?、collection-if 与 collection-for。',
  ),
  DartLesson(
    id: 'dart-lesson-027',
    chapter: 'collections',
    level: 'intermediate',
    title: 'Map 的变换与更新',
    summary: 'map 转 List、更新值、合并 Map。',
    concepts: <String>['Map.map', 'update', 'putIfAbsent', '合并'],
    explain:
        'Map 可以 map 成新的 Map，entries 可以转成 List。update 在键存在时更新、'
        '不存在时用 ifAbsent 计算默认值，putIfAbsent 只在缺失时插入。合并两个 Map '
        '用 addAll，冲突时后者覆盖前者。',
    objective: '会更新、合并和变换 Map。',
    pitfalls: <String>[
      'update 不带 ifAbsent 时，键不存在会抛异常。',
      'addAll 会覆盖同名键，合并前要确认这是期望行为。',
    ],
    code:
        "void main() {\n"
        "  final counts = {'a': 1, 'b': 2};\n"
        "  counts.update('a', (v) => v + 10);\n"
        "  counts.update('c', (v) => v + 1, ifAbsent: () => 5);\n"
        "  print(counts);\n"
        "\n"
        "  final upper = counts.map((k, v) => MapEntry(k.toUpperCase(), v * 2));\n"
        "  print(upper);\n"
        "\n"
        "  final extra = {'d': 4};\n"
        "  counts.addAll(extra);\n"
        "  print(counts.keys.toList());\n"
        "}\n",
    output: '{a: 11, b: 2, c: 5}\n{A: 22, B: 4, C: 10}\n[a, b, c, d]\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '给 Map 的每个值加 1 并返回新 Map。',
        hint: '用 map + MapEntry。',
        answer:
            "final m = {'x': 1, 'y': 2};\n"
            "print(m.map((k, v) => MapEntry(k, v + 1)));",
      ),
    ],
    exampleTitle: '示例 027：Map 变换与更新',
    exampleSummary: 'update、putIfAbsent 风格、Map.map 与 addAll 合并。',
  ),
  DartLesson(
    id: 'dart-lesson-028',
    chapter: 'collections',
    level: 'intermediate',
    title: '综合练习：词频统计',
    summary: '用 split、Map 与排序统计一段文本的词频。',
    concepts: <String>['综合运用', 'Map', 'split', '排序'],
    explain:
        '这一课把字符串拆分、Map 计数、排序和高阶方法串起来：把句子按空格拆成单词，'
        '用 Map 统计每个单词出现次数，再按次数排序输出。这是集合与字符串配合的'
        '典型实战。',
    objective: '能把字符串处理和集合统计组合成完整流程。',
    pitfalls: <String>['没做大小写归一化会把 The 和 the 分成两个词。', '排序比较器写反会导致结果顺序相反。'],
    code:
        "void main() {\n"
        "  const text = 'the cat the dog the bird';\n"
        "  final words = text.toLowerCase().split(' ');\n"
        "  final counts = <String, int>{};\n"
        "  for (final w in words) {\n"
        "    counts[w] = (counts[w] ?? 0) + 1;\n"
        "  }\n"
        "  final sorted = counts.entries.toList()\n"
        "    ..sort((a, b) => b.value.compareTo(a.value));\n"
        "  for (final e in sorted) {\n"
        "    print('\${e.key}: \${e.value}');\n"
        "  }\n"
        "}\n",
    output: 'the: 3\ncat: 1\ndog: 1\nbird: 1\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: "统计 'a b a c a' 里出现最多的单词。",
        hint: 'Map 计数后取最大 value 的 key。',
        answer:
            "final words = 'a b a c a'.split(' ');\n"
            "final counts = <String, int>{};\n"
            "for (final w in words) { counts[w] = (counts[w] ?? 0) + 1; }\n"
            "final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);\n"
            "print(top.key);",
      ),
    ],
    exampleTitle: '示例 028：综合练习：词频统计',
    exampleSummary: '拆分、计数、排序输出一段文本的词频。',
  ),
];
