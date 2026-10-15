import '../dart_lesson.dart';

/// Chapter `json` — lessons 105-110. Owned by the second pi.
///
/// Export name: `jsonLessons`. Keep lessons sorted by id.
///
/// All programs are self-contained, deterministic, and use only `dart:convert`.
const List<DartLesson> jsonLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-105',
    chapter: 'json',
    level: 'intermediate',
    title: 'JSON 编码与解码',
    summary: '用 jsonEncode 把 Map 变字符串，用 jsonDecode 再还原。',
    concepts: <String>['jsonEncode', 'jsonDecode', 'dart:convert'],
    explain:
        'JSON 是跨语言的数据交换格式。dart:convert 提供两个核心函数：jsonEncode 把'
        'Map、List、字符串、数字、布尔、null 编成 JSON 字符串；jsonDecode 把字符串'
        '解析回这些结构。注意一个常见陷阱：解码后的 Map 与原始 Map 用 == 比较是 false，'
        '因为 Dart 的 Map 相等是"引用相等"，不是逐键比较。要判断内容一致，'
        '应逐字段比较或先编码成字符串再比。',
    objective: '能对 Map 做编码与解码，并解释为什么 == 比较可能为 false。',
    prerequisites: <String>['已掌握 Map 与 List', '了解字符串'],
    pitfalls: <String>[
      'Map/List 的 == 是引用相等，解码得到的是新对象，直接比较为 false。',
      'jsonDecode 返回 dynamic，取字段前需 as 成具体类型。',
      '只有可 JSON 化的类型能编码，自定义对象需先转成 Map。',
    ],
    code:
        "import 'dart:convert';\n"
        "\n"
        "void main() {\n"
        "  final map = <String, Object>{'name': '小明', 'age': 18};\n"
        "  final text = jsonEncode(map);\n"
        "  print(text);\n"
        "  final back = jsonDecode(text) as Map<String, Object?>;\n"
        "  print(back['name']);\n"
        "  print(back['age']);\n"
        "  print(back == map);\n"
        "}\n",
    output: '{"name":"小明","age":18}\n小明\n18\nfalse\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '编码 [1, 2, 3] 并打印得到的 JSON 字符串。',
        hint: 'jsonEncode(<int>[1, 2, 3])。',
        answer:
            "import 'dart:convert';\n"
            "\n"
            "void main() {\n"
            "  print(jsonEncode(<int>[1, 2, 3]));\n"
            "}",
      ),
    ],
    exampleTitle: '示例 105：JSON 编解码',
    exampleSummary: 'Map 编码成字符串再解码还原，并观察 == 的结果。',
  ),
  DartLesson(
    id: 'dart-lesson-106',
    chapter: 'json',
    level: 'intermediate',
    title: '嵌套 JSON 结构',
    summary: '处理对象里嵌数组、数组里嵌对象的层级数据。',
    concepts: <String>['嵌套', 'List<Object?>', '类型转换'],
    explain:
        '真实数据往往是嵌套的：一个班级对象里有学生数组，每个学生又是对象。'
        'jsonDecode 会把它还原成 Map 套 List 套 Map 的结构。逐层取值时要逐层 as：'
        '先把顶层转 Map，取出的 students 是 List<Object?>，其中每个元素再 as 成 '
        'Map 才能访问字段。虽然有点啰嗦，但这正是静态类型下的安全做法。',
    objective: '能解析多层嵌套的 JSON，并逐层安全取出字段。',
    prerequisites: <String>['已掌握 JSON 编解码与类型转换'],
    pitfalls: <String>[
      'List 元素是 Object?，直接当 Map 用会编译/运行错误，必须 as。',
      '某一层缺失会让 as 或 ! 抛错，生产代码应做空值判断。',
      '索引与键名拼写错误会导致 null 或异常。',
    ],
    code:
        "import 'dart:convert';\n"
        "\n"
        "void main() {\n"
        "  final data = <String, Object>{\n"
        "    'class': '一班',\n"
        "    'students': <Object>[\n"
        "      <String, Object>{'name': '小明', 'score': 90},\n"
        "      <String, Object>{'name': '小红', 'score': 85},\n"
        "    ],\n"
        "  };\n"
        "  final text = jsonEncode(data);\n"
        "  final decoded = jsonDecode(text) as Map<String, Object?>;\n"
        "  final students = decoded['students'] as List<Object?>;\n"
        "  print('班级 \${decoded['class']}');\n"
        "  print('人数 \${students.length}');\n"
        "  final first = students.first as Map<String, Object?>;\n"
        "  print('第一名 \${first['name']}');\n"
        "}\n",
    output: '班级 一班\n人数 2\n第一名 小明\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '打印上面第二个学生的 score。',
        hint: 'students[1] as Map 后取 score。',
        answer:
            "import 'dart:convert';\n"
            "\n"
            "void main() {\n"
            "  final data = jsonDecode(\n"
            "    '[{\"name\":\"小明\",\"score\":90},{\"name\":\"小红\",\"score\":85}]',\n"
            "  ) as List<Object?>;\n"
            "  final second = data[1] as Map<String, Object?>;\n"
            "  print(second['score']);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 106：嵌套 JSON',
    exampleSummary: '解析对象套数组套对象，逐层取值访问字段。',
  ),
  DartLesson(
    id: 'dart-lesson-107',
    chapter: 'json',
    level: 'intermediate',
    title: '手写 fromJson',
    summary: '为类写一个 fromJson 工厂，从 Map 构造对象。',
    concepts: <String>['factory', 'fromJson', '反序列化'],
    explain:
        '把 JSON 还原成强类型对象，标准做法是给类写一个工厂构造 User.fromJson(Map)，'
        '在里面把每个字段从 Map 里取出来并转成正确类型。这样"解析"这一步被集中封装，'
        '调用方只拿对象、不碰裸 Map，代码更安全也更好维护。工厂构造用 factory 关键字，'
        '可以返回实例而不必先调用别的构造函数。',
    objective: '能为类实现 fromJson 工厂，从 Map 构造出对象。',
    prerequisites: <String>['已掌握类、构造函数与 JSON 解码'],
    pitfalls: <String>[
      '字段类型不符时要显式 as，否则 dynamic 会带来运行时错误。',
      '缺字段用 json[key]! 会在 null 上抛错，需考虑默认值。',
      '工厂构造不能访问 this，必须先凑齐参数再调用主构造。',
    ],
    code:
        "class User {\n"
        "  User(this.name, this.age);\n"
        "\n"
        "  factory User.fromJson(Map<String, Object?> json) {\n"
        "    return User(json['name']! as String, json['age']! as int);\n"
        "  }\n"
        "\n"
        "  final String name;\n"
        "  final int age;\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final user = User.fromJson(<String, Object?>{'name': '小明', 'age': 18});\n"
        "  print('\${user.name} \${user.age}');\n"
        "}\n",
    output: '小明 18\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '为 Point 类写 fromJson，读取 x、y 并打印它们。',
        hint: '工厂里 as int 取 x、y。',
        answer:
            "class Point {\n"
            "  Point(this.x, this.y);\n"
            "  factory Point.fromJson(Map<String, Object?> j) =>\n"
            "      Point(j['x']! as int, j['y']! as int);\n"
            "  final int x;\n"
            "  final int y;\n"
            "}\n"
            "\n"
            "void main() {\n"
            "  final p = Point.fromJson(<String, Object?>{'x': 3, 'y': 4});\n"
            "  print('\${p.x} \${p.y}');\n"
            "}",
      ),
    ],
    exampleTitle: '示例 107：fromJson 工厂',
    exampleSummary: '用工厂构造从 Map 还原强类型对象。',
  ),
  DartLesson(
    id: 'dart-lesson-108',
    chapter: 'json',
    level: 'intermediate',
    title: '手写 toJson',
    summary: '为类写 toJson，把对象转成 Map 再编码成 JSON。',
    concepts: <String>['toJson', '序列化', 'Map 转换'],
    explain:
        '序列化方向相反：类需要提供 toJson()，把自身字段整理成一个 Map，'
        '再由 jsonEncode 编成字符串。这样对象的"对外表示"就与内部字段解耦——'
        '可以只暴露需要的字段、统一命名。当你既要存盘又要发接口时，'
        'toJson + jsonEncode 是最小可用的方案，无需引入代码生成。'
        '配合 fromJson 就能实现完整的往返。',
    objective: '能为类实现 toJson 并编码成 JSON 字符串。',
    prerequisites: <String>['已掌握 fromJson 与 JSON 编码'],
    pitfalls: <String>[
      'toJson 返回的必须是可 JSON 化的类型，嵌套对象要递归转 Map。',
      '键名要与读取端约定一致，改名字会破坏往返。',
      '别把内部临时字段也塞进 toJson，按需要裁剪。',
    ],
    code:
        "import 'dart:convert';\n"
        "\n"
        "class Point {\n"
        "  Point(this.x, this.y);\n"
        "\n"
        "  final int x;\n"
        "  final int y;\n"
        "\n"
        "  Map<String, Object> toJson() => <String, Object>{'x': x, 'y': y};\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final point = Point(3, 4);\n"
        "  final text = jsonEncode(point.toJson());\n"
        "  print(text);\n"
        "}\n",
    output: '{"x":3,"y":4}\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '给 User(name, age) 写 toJson 并编码打印。',
        hint: '返回 {"name": name, "age": age}。',
        answer:
            "import 'dart:convert';\n"
            "\n"
            "class User {\n"
            "  User(this.name, this.age);\n"
            "  final String name;\n"
            "  final int age;\n"
            "  Map<String, Object> toJson() => <String, Object>{\n"
            "    'name': name,\n"
            "    'age': age,\n"
            "  };\n"
            "}\n"
            "\n"
            "void main() {\n"
            "  print(jsonEncode(User('小明', 18).toJson()));\n"
            "}",
      ),
    ],
    exampleTitle: '示例 108：toJson 序列化',
    exampleSummary: '对象转 Map 再编码成 JSON 字符串。',
  ),
  DartLesson(
    id: 'dart-lesson-109',
    chapter: 'json',
    level: 'intermediate',
    title: 'JSON 数组聚合',
    summary: '解析 JSON 数组并对其中字段做求和等聚合。',
    concepts: <String>['List 解析', 'map', 'reduce'],
    explain:
        '接口常返回对象数组，处理步骤是：jsonDecode 得到 List，把每个元素 as 成 '
        'Map，取出需要的字段，再做 map/reduce 聚合。本课解析三个商品对象，'
        '提取价格求和。这类"解析—取值—聚合"是数据处理的日常。'
        '注意每个元素都可能是不同结构，稳妥做法是逐元素类型判断后再取字段。',
    objective: '能解析 JSON 对象数组并对某字段做聚合运算。',
    prerequisites: <String>['已掌握嵌套 JSON 与集合方法'],
    pitfalls: <String>[
      '元素是 Object?，取字段前必须 as Map<String, Object?>。',
      '字段可能是 null 或类型不符，直接用 ! 有风险。',
      '数组为空时 reduce 会抛错，注意空集合处理。',
    ],
    code:
        "import 'dart:convert';\n"
        "\n"
        "void main() {\n"
        "  const text = '[{\"price\": 5}, {\"price\": 8}, {\"price\": 12}]';\n"
        "  final items = jsonDecode(text) as List<Object?>;\n"
        "  final total = items\n"
        "      .map((item) => (item as Map<String, Object?>)['price']! as int)\n"
        "      .reduce((a, b) => a + b);\n"
        "  print('商品数 \${items.length}');\n"
        "  print('总价 \$total');\n"
        "}\n",
    output: '商品数 3\n总价 25\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: "对 [{\"n\":1},{\"n\":2},{\"n\":3}] 求 n 的最大值。",
        hint: 'map 取 n 后用 reduce 取较大者。',
        answer:
            "import 'dart:convert';\n"
            "\n"
            "void main() {\n"
            "  final items = jsonDecode('[{\"n\":1},{\"n\":2},{\"n\":3}]') as List<Object?>;\n"
            "  final max = items\n"
            "      .map((e) => (e as Map<String, Object?>)['n']! as int)\n"
            "      .reduce((a, b) => a > b ? a : b);\n"
            "  print(max);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 109：JSON 数组聚合',
    exampleSummary: '解析对象数组并对 price 字段求和。',
  ),
  DartLesson(
    id: 'dart-lesson-110',
    chapter: 'json',
    level: 'intermediate',
    title: '非法 JSON 的错误处理',
    summary: '捕获 jsonDecode 抛出的 FormatException，避免程序崩溃。',
    concepts: <String>['FormatException', 'try-catch', '健壮解析'],
    explain:
        '输入来自外部（文件、网络、用户），不一定合法。jsonDecode 遇到非法 JSON 会抛'
        'FormatException。直接用异常会中断流程，正确做法是用 try/on FormatException '
        '捕获并给出友好提示，然后继续处理其它数据。本课先解析一段坏数据并捕获，'
        '再解析一段合法数据验证流程照常进行。健壮的程序永远假设输入可能是坏的。',
    objective: '能捕获 JSON 解析错误并让程序继续运行。',
    prerequisites: <String>['已掌握 JSON 解码与异常处理'],
    pitfalls: <String>[
      'FormatException 的 message 是英文短描述，不可当作稳定接口依赖。',
      '只捕获 Exception 会漏掉部分错误类型，尽量捕获具体类型。',
      '捕获后要给出替代路径，否则等于静默失败。',
    ],
    code:
        "import 'dart:convert';\n"
        "\n"
        "void main() {\n"
        "  try {\n"
        "    jsonDecode('{不是合法 JSON}');\n"
        "    print('不会到这里');\n"
        "  } on FormatException catch (error) {\n"
        "    print('解析失败：\${error.message}');\n"
        "  }\n"
        "  final ok = jsonDecode('{\"valid\": true}') as Map<String, Object?>;\n"
        "  print('valid=\${ok['valid']}');\n"
        "}\n",
    output: '解析失败：Unexpected character\nvalid=true\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '写一个安全解析函数，输入非法时返回 null，合法时返回 Map。',
        hint: 'try 里 return jsonDecode(...) as Map，catch 里 return null。',
        answer:
            "import 'dart:convert';\n"
            "\n"
            "Map<String, Object?>? safeParse(String t) {\n"
            "  try {\n"
            "    return jsonDecode(t) as Map<String, Object?>;\n"
            "  } on FormatException {\n"
            "    return null;\n"
            "  }\n"
            "}\n"
            "\n"
            "void main() {\n"
            "  print(safeParse('坏数据') == null);\n"
            "  print(safeParse('{\"a\":1}'));\n"
            "}",
      ),
    ],
    exampleTitle: '示例 110：非法 JSON 处理',
    exampleSummary: '捕获 FormatException 后继续解析合法数据。',
  ),
];
