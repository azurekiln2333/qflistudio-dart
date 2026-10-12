import '../dart_lesson.dart';

/// Chapter `nullsafety` — lessons 029-034. Owned by the first pi.
const List<DartLesson> nullSafetyLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-029',
    chapter: 'nullsafety',
    level: 'intermediate',
    title: '可空类型与 null',
    summary: '用 ? 声明可空类型，区分「有值」和「空」。',
    concepts: <String>['可空类型', '?', 'null', '非空默认'],
    explain:
        'Dart 默认变量非空，声明 String name 就不能赋 null。要允许为空，类型后加 ?，'
        '写成 String? name。可空类型让「可能没有值」变成类型系统的一部分，编译器会'
        '提醒你在使用前处理空的情况。',
    objective: '会声明可空类型并理解非空默认带来的安全。',
    pitfalls: <String>[
      '把可空值当非空用（例如直接调用方法）会编译报错。',
      '给非空变量赋 null 会编译报错，这是有意设计，不是麻烦。',
    ],
    code: "void main() {\n"
        "  String name = '小明';\n"
        "  String? nickname;\n"
        "  print(name);\n"
        "  print(nickname);\n"
        "  nickname = '阿明';\n"
        "  print(nickname);\n"
        "  nickname = null;\n"
        "  print(nickname == null);\n"
        "}\n",
    output: '小明\nnull\n阿明\ntrue\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '声明一个 int? 变量，先打印它的值，再赋 5 并打印。',
        hint: '声明时不给初始值即为 null。',
        answer: "int? n;\nprint(n);\nn = 5;\nprint(n);",
      ),
    ],
    exampleTitle: '示例 029：可空类型与 null',
    exampleSummary: '非空变量与可空变量的声明、赋值和判空。',
  ),
  DartLesson(
    id: 'dart-lesson-030',
    chapter: 'nullsafety',
    level: 'intermediate',
    title: '??、??= 与 ?.',
    summary: '空合并、空赋值与空安全调用。',
    concepts: <String>['??', '??=', '?.', '空合并'],
    explain:
        'a ?? b 在 a 为 null 时取 b；a ??= b 仅在 a 为 null 时赋值；a?.b 在 a 非空时'
        '才访问成员，否则整个表达式为 null。三者组合起来能优雅处理链式可空访问，'
        '避免层层判空。',
    objective: '会用 ??、??= 和 ?. 处理可空值的读取与赋值。',
    pitfalls: <String>[
      '?? 只在左值为 null 时生效，空字符串或 0 不会触发右值。',
      '?. 返回的仍是可空值，继续取值要接着用 ?. 或做判空。',
    ],
    code: "void main() {\n"
        "  String? input;\n"
        "  print(input ?? '默认值');\n"
        "  input ??= '填入了';\n"
        "  print(input);\n"
        "  print(input.length);\n"
        "\n"
        "  String? city;\n"
        "  print(city?.toUpperCase());\n"
        "  city = 'hangzhou';\n"
        "  print(city?.toUpperCase());\n"
        "}\n",
    output: '默认值\n填入了\n3\nnull\nHANGZHOU\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '可空列表 nums，用 ?. 打印长度，为 null 时打印「无数据」。',
        hint: "nums?.length ?? '无数据'。",
        answer: "List<int>? nums;\nprint(nums?.length ?? '无数据');",
      ),
    ],
    exampleTitle: '示例 030：?? 与空安全调用',
    exampleSummary: '空合并、空赋值和 ?. 链式安全访问。',
  ),
  DartLesson(
    id: 'dart-lesson-031',
    chapter: 'nullsafety',
    level: 'intermediate',
    title: '非空断言与类型提升',
    summary: '用 ! 断言非空，以及编译器自动的类型提升。',
    concepts: <String>['!', '类型提升', 'null 检查'],
    explain:
        '当你确定一个可空值此刻非空时，用 ! 断言，否则会编译错误。更安全的做法是先'
        '做 null 检查：if (name != null) 之后，编译器会把 name 提升为非空类型，'
        '块内可直接当非空用，无需 !。',
    objective: '会在必要时用 ! 断言，并优先依赖类型提升。',
    pitfalls: <String>[
      '对确实为 null 的值用 ! 会抛运行时异常，! 只是把编译期检查推迟到运行期。',
      '对字段（而非局部变量）做 null 检查后，编译器可能不提升，因为字段可被并发修改。',
    ],
    code: "void main() {\n"
        "  String? name = '小明';\n"
        "  if (name != null) {\n"
        "    print(name.length);\n"
        "  }\n"
        "  print(name!.toUpperCase());\n"
        "\n"
        "  String? maybe;\n"
        "  print(maybe == null ? '没有值' : maybe.length);\n"
        "}\n",
    output: '2\n小明\n没有值\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '可空字符串 s，若非空则打印反转，否则打印「空」。',
        hint: '用 if (s != null) 做类型提升。',
        answer: "String? s = 'dart';\n"
            "if (s != null) {\n"
            "  print(s.split('').reversed.join());\n"
            "} else {\n"
            "  print('空');\n"
            "}",
      ),
    ],
    exampleTitle: '示例 031：非空断言与类型提升',
    exampleSummary: '! 断言、null 检查后的类型提升与安全兜底。',
  ),
  DartLesson(
    id: 'dart-lesson-032',
    chapter: 'nullsafety',
    level: 'intermediate',
    title: 'late 延迟初始化',
    summary: '用 late 声明稍后初始化的非空变量。',
    concepts: <String>['late', '延迟初始化', '初始化顺序'],
    explain:
        'late 让非空变量可以稍后初始化，适合「构造时还拿不到值」或「用到时才计算」'
        '的场景。late final 表示只初始化一次的延迟字段。若在初始化前访问 late 变量，'
        '会抛 LateInitializationError。',
    objective: '会用 late 处理必须先声明、后赋值的非空场景。',
    pitfalls: <String>[
      '访问未初始化的 late 变量会运行时报错，要保证使用前已赋值。',
      '能用普通判空解决时不要滥用 late，它把检查推迟到了运行期。',
    ],
    code: "class Config {\n"
        "  late String appName;\n"
        "  late final int buildNumber = 42;\n"
        "\n"
        "  void setup() {\n"
        "    appName = 'QFLIDartWing';\n"
        "  }\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final config = Config()..setup();\n"
        "  print(config.appName);\n"
        "  print(config.buildNumber);\n"
        "}\n",
    output: 'QFLIDartWing\n42\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用 late 声明一个字符串，在 main 里赋值后打印长度。',
        hint: "late String s; 然后 s = 'abc'。",
        answer: "late String s;\ns = 'abc';\nprint(s.length);",
      ),
    ],
    exampleTitle: '示例 032：late 延迟初始化',
    exampleSummary: 'late 字段、late final 与使用时才初始化。',
  ),
  DartLesson(
    id: 'dart-lesson-033',
    chapter: 'nullsafety',
    level: 'intermediate',
    title: '空安全集合',
    summary: '可空元素、可空列表与安全处理。',
    concepts: <String>['List<int?>', 'List<int>?', '元素可空', '集合可空'],
    explain:
        '要区分「列表本身可空」List<int>? 和「元素可空」List<int?>。前者列表可能不'
        '存在，后者列表一定存在但元素可能是 null。处理元素可空的列表时，用 whereType '
        '过滤掉 null，或先判空再使用。',
    objective: '会区分列表可空与元素可空，并安全处理。',
    pitfalls: <String>[
      '对 List<int?> 求和时直接相加会因 null 编译报错，要先过滤或设默认值。',
      '把 List<int?> 当成 List<int> 传递会类型不匹配。',
    ],
    code: "void main() {\n"
        "  final List<int?> maybeNums = [1, null, 3, null, 5];\n"
        "  final nums = maybeNums.whereType<int>().toList();\n"
        "  print(nums);\n"
        "  print(nums.fold<int>(0, (a, b) => a + b));\n"
        "\n"
        "  List<String>? maybeList;\n"
        "  print(maybeList?.length ?? 0);\n"
        "  maybeList = ['a', 'b'];\n"
        "  print(maybeList.length);\n"
        "}\n",
    output: '[1, 3, 5]\n9\n0\n2\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '把 [null, 2, null, 4] 的 null 去掉后求平均。',
        hint: 'whereType<int>() 后 fold。',
        answer: "final nums = [null, 2, null, 4].whereType<int>().toList();\n"
            "print(nums.fold<int>(0, (a, b) => a + b) / nums.length);",
      ),
    ],
    exampleTitle: '示例 033：空安全集合',
    exampleSummary: '元素可空列表的过滤与列表可空的访问。',
  ),
  DartLesson(
    id: 'dart-lesson-034',
    chapter: 'nullsafety',
    level: 'intermediate',
    title: '综合练习：用户资料安全读取',
    summary: '把可空字段、?? 与类型提升组合成安全的数据读取。',
    concepts: <String>['综合运用', '可空字段', '??', '类型提升'],
    explain:
        '真实数据常带缺失字段。这一课用一个带可空字段的资料对象演示如何安全读取：'
        '用 ?? 提供默认值，用类型提升访问非空字段，用 ?. 安全调用方法，最后输出'
        '格式化结果。',
    objective: '能把空安全机制组合成健壮的数据读取逻辑。',
    pitfalls: <String>[
      '对同一可空字段反复判空显得啰嗦，可以用局部变量或 ?? 降噪。',
      '把缺失值显示成 null 不友好，应统一转成可读文案。',
    ],
    code: "class Profile {\n"
        "  Profile({this.name, this.city, this.age});\n"
        "  final String? name;\n"
        "  final String? city;\n"
        "  final int? age;\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final profile = Profile(name: '小明');\n"
        "  final name = profile.name ?? '匿名';\n"
        "  final city = profile.city?.toUpperCase() ?? '未知城市';\n"
        "  final age = profile.age ?? 0;\n"
        "  print('姓名：\$name');\n"
        "  print('城市：\$city');\n"
        "  print('年龄：\${age == 0 ? '未填写' : age}');\n"
        "}\n",
    output: '姓名：小明\n城市：未知城市\n年龄：未填写\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: "给 profile 的 city 赋值 'hangzhou' 后重新打印。",
        hint: '传入 city 参数。',
        answer: "final p = Profile(city: 'hangzhou');\n"
            "print(p.city?.toUpperCase() ?? '未知城市');",
      ),
    ],
    exampleTitle: '示例 034：综合练习：用户资料安全读取',
    exampleSummary: '用可空字段、??、?. 与类型提升安全读取资料。',
  ),
];
