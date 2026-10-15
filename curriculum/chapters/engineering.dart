import '../dart_lesson.dart';

/// Chapter `engineering` — lessons 111-120. Owned by the second pi.
///
/// Export name: `engineeringLessons`. Keep lessons sorted by id.
///
/// These lessons teach testing/engineering mechanisms using self-contained,
/// single-file programs (no `package:test`, no external packages, no network),
/// so every sample is deterministic and runnable on the official Dart SDK.
/// The real project-level tooling is described in each `explain`.
const List<DartLesson> engineeringLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-111',
    chapter: 'engineering',
    level: 'intermediate',
    title: '手写断言与测试计数',
    summary: '用一个小断言函数体会"断言—通过计数"的测试核心机制。',
    concepts: <String>['断言', '测试计数', '失败即抛错'],
    explain:
        '测试框架的核心其实很小：一个能把"实际值"与"期望值"比较的函数，不相等就抛错。'
        '本课手写 expectEquals，并统计通过了多少条。真实项目里这一步由 package:test 的 '
        'expect 完成、由 test runner 汇总，但机制相同：断言失败就中断并报告。'
        '理解这个最小模型后，再看 test 包就不再神秘。程序自包含、不依赖外部包。',
    objective: '能写出最小断言函数并统计通过的用例数。',
    prerequisites: <String>['已掌握函数与异常'],
    pitfalls: <String>[
      '比较对象应用 ==（结构不同要自定义），否则引用比较会误判。',
      '断言失败应抛错而不是返回 false，否则容易被忽略。',
      '真实项目不要自己造轮子，直接用 package:test。',
    ],
    code:
        "void expectEquals(Object? actual, Object? expected, String label) {\n"
        "  if (actual != expected) {\n"
        "    throw StateError('\$label 失败：期望 \$expected，实际 \$actual');\n"
        "  }\n"
        "  print('通过 \$label');\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  var passed = 0;\n"
        "\n"
        "  void check(void Function() body) {\n"
        "    body();\n"
        "    passed++;\n"
        "  }\n"
        "\n"
        "  check(() => expectEquals(1 + 1, 2, '加法'));\n"
        "  check(() => expectEquals('ab'.length, 2, '字符串长度'));\n"
        "  check(() => expectEquals([1, 2, 3].last, 3, '末尾元素'));\n"
        "  print('通过数 \$passed');\n"
        "}\n",
    output: '通过 加法\n通过 字符串长度\n通过 末尾元素\n通过数 3\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '再加一条断言：检查 "hello".contains("ell") 为 true。',
        hint: 'check(() => expectEquals("hello".contains("ell"), true, "包含"))。',
        answer:
            "void expectEquals(Object? a, Object? b, String l) {\n"
            "  if (a != b) throw StateError(l);\n"
            "  print('通过 \$l');\n"
            "}\n"
            "\n"
            "void main() {\n"
            "  expectEquals('hello'.contains('ell'), true, '包含');\n"
            "}",
      ),
    ],
    exampleTitle: '示例 111：最小断言',
    exampleSummary: '手写断言函数并统计通过的用例数。',
  ),
  DartLesson(
    id: 'dart-lesson-112',
    chapter: 'engineering',
    level: 'intermediate',
    title: '分组测试结构',
    summary: '用 group 概念把用例按主题归类，并分别汇总通过数。',
    concepts: <String>['分组', '用例列表', '汇总'],
    explain:
        '用例一多就需要分组。测试框架用 group("标题", () { ... }) 把相关用例聚在一起，'
        '输出时按组统计。本课用 TestCase 列表和 runGroup 函数模拟这一机制：'
        '每组建一组用例，运行后打印该组的通过比例。分组让失败定位更快——'
        '一眼看出是哪一主题出问题。真实项目用 test 包的 group 实现同样效果。',
    objective: '能把测试用例按主题分组并统计每组的通过情况。',
    prerequisites: <String>['已掌握断言与函数式回调'],
    pitfalls: <String>[
      '组内某个用例抛错会中断该组，真实框架会单独隔离并继续。',
      '组名要能表达主题，避免"测试1/测试2"这类无信息命名。',
      '嵌套分组可表达层级，但过深会难以阅读。',
    ],
    code:
        "class TestCase {\n"
        "  TestCase(this.name, this.body);\n"
        "  final String name;\n"
        "  final void Function() body;\n"
        "}\n"
        "\n"
        "void runGroup(String title, List<TestCase> cases) {\n"
        "  print('分组：\$title');\n"
        "  var passed = 0;\n"
        "  for (final c in cases) {\n"
        "    c.body();\n"
        "    passed++;\n"
        "  }\n"
        "  print('  \$passed/\${cases.length} 通过');\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  runGroup('数学', <TestCase>[\n"
        "    TestCase('加法', () => expect(2 + 3 == 5)),\n"
        "    TestCase('乘法', () => expect(2 * 3 == 6)),\n"
        "  ]);\n"
        "  runGroup('字符串', <TestCase>[\n"
        "    TestCase('拼接', () => expect('a' + 'b' == 'ab')),\n"
        "  ]);\n"
        "}\n"
        "\n"
        "void expect(bool condition) {\n"
        "  if (!condition) throw StateError('断言失败');\n"
        "}\n",
    output: '分组：数学\n  2/2 通过\n分组：字符串\n  1/1 通过\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '新增一组"集合"，含一条用例检查 [1,2,3].length == 3。',
        hint: '再调一次 runGroup，传入一个 TestCase。',
        answer:
            "void expect(bool c) {\n"
            "  if (!c) throw StateError('断言失败');\n"
            "}\n"
            "\n"
            "void main() {\n"
            "  final cases = <void Function()>[() => expect(<int>[1, 2, 3].length == 3)];\n"
            "  for (final c in cases) {\n"
            "    c();\n"
            "  }\n"
            "  print('集合组 \${cases.length} 条通过');\n"
            "}",
      ),
    ],
    exampleTitle: '示例 112：分组测试',
    exampleSummary: '把用例按主题分组，分别汇总每组通过数。',
  ),
  DartLesson(
    id: 'dart-lesson-113',
    chapter: 'engineering',
    level: 'intermediate',
    title: '边界用例设计',
    summary: '对解析函数测正常、负数与非法三类输入，覆盖边界。',
    concepts: <String>['边界用例', '输入校验', 'FormatException'],
    explain:
        '好的测试不只测"正常值"，更测"边界与异常"。一个分数解析函数的边界包括：'
        '带空白、负数、非数字。本课实现 parseScore 并在三种输入下验证行为：'
        '正常输入返回数字，负数是合法数字，非法输入抛 FormatException。'
        '把异常路径也当作一条用例来测，能显著减少线上事故。',
    objective: '能为解析函数设计正常/边界/异常三类用例。',
    prerequisites: <String>['已掌握异常与断言'],
    pitfalls: <String>[
      '只测 happy path 会漏掉大量真实故障。',
      '空白字符串要 trim 后再判断，否则 int.parse 抛错信息不明确。',
      '异常用例要显式验证"确实抛了正确类型"，而不是笼统 catch。',
    ],
    code:
        "int parseScore(String text) {\n"
        "  final trimmed = text.trim();\n"
        "  if (trimmed.isEmpty) throw const FormatException('空输入');\n"
        "  return int.parse(trimmed);\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  print(parseScore(' 90 '));\n"
        "  print(parseScore('-5'));\n"
        "  try {\n"
        "    parseScore('abc');\n"
        "  } on FormatException {\n"
        "    print('非法输入被拒绝');\n"
        "  }\n"
        "}\n",
    output: '90\n-5\n非法输入被拒绝\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '为 parseScore 增加空字符串用例，验证抛出 FormatException。',
        hint: 'try { parseScore("") } on FormatException { print("空输入被拒"); }。',
        answer:
            "int parseScore(String t) {\n"
            "  final s = t.trim();\n"
            "  if (s.isEmpty) throw const FormatException('空输入');\n"
            "  return int.parse(s);\n"
            "}\n"
            "\n"
            "void main() {\n"
            "  try {\n"
            "    parseScore('   ');\n"
            "  } on FormatException {\n"
            "    print('空输入被拒');\n"
            "  }\n"
            "}",
      ),
    ],
    exampleTitle: '示例 113：边界用例',
    exampleSummary: '对解析函数覆盖正常、负数与非法输入三种情形。',
  ),
  DartLesson(
    id: 'dart-lesson-114',
    chapter: 'engineering',
    level: 'intermediate',
    title: '异常断言与自定义异常',
    summary: '定义专属异常类型，并验证校验函数在非法输入时抛出它。',
    concepts: <String>['自定义异常', 'implements Exception', '异常断言'],
    explain:
        '用内置异常（StateError、FormatException）表达业务校验不够精确。定义自己的'
        'ValidationError implements Exception，能让调用方精准捕获、也让日志更清晰。'
        '本课定义一个带 message 的 ValidationError，validateAge 对负数抛它，'
        '调用方 on ValidationError 捕获并打印。测试时验证"抛出了正确类型"比'
        '"是否抛错"更有价值。',
    objective: '能定义自定义异常并在校验失败时抛出、精确捕获。',
    prerequisites: <String>['已掌握类、异常与 toString 重写'],
    pitfalls: <String>[
      '自定义异常建议 implements Exception 并重写 toString 便于打印。',
      '抛错信息要包含可诊断的上下文，而不是空消息。',
      '捕获时应指定具体类型，避免吞掉其它异常。',
    ],
    code:
        "class ValidationError implements Exception {\n"
        "  ValidationError(this.message);\n"
        "  final String message;\n"
        "  @override\n"
        "  String toString() => 'ValidationError: \$message';\n"
        "}\n"
        "\n"
        "void validateAge(int age) {\n"
        "  if (age < 0) throw ValidationError('年龄不能为负');\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  try {\n"
        "    validateAge(-1);\n"
        "  } on ValidationError catch (error) {\n"
        "    print(error);\n"
        "  }\n"
        "  validateAge(18);\n"
        "  print('年龄合法');\n"
        "}\n",
    output: 'ValidationError: 年龄不能为负\n年龄合法\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '定义一个 ValidationError 并对空用户名抛出、捕获打印。',
        hint: 'if (name.isEmpty) throw ValidationError("用户名不能为空")。',
        answer:
            "class ValidationError implements Exception {\n"
            "  ValidationError(this.message);\n"
            "  final String message;\n"
            "  @override\n"
            "  String toString() => message;\n"
            "}\n"
            "\n"
            "void checkName(String name) {\n"
            "  if (name.isEmpty) throw ValidationError('用户名不能为空');\n"
            "}\n"
            "\n"
            "void main() {\n"
            "  try {\n"
            "    checkName('');\n"
            "  } on ValidationError catch (e) {\n"
            "    print(e);\n"
            "  }\n"
            "}",
      ),
    ],
    exampleTitle: '示例 114：自定义异常',
    exampleSummary: '定义 ValidationError，校验失败时抛出并精确捕获。',
  ),
  DartLesson(
    id: 'dart-lesson-115',
    chapter: 'engineering',
    level: 'intermediate',
    title: '不可变数据与 copyWith',
    summary: '用 final 字段加手写 copyWith 实现"改一个字段得到新对象"。',
    concepts: <String>['不可变', 'copyWith', '值对象'],
    explain:
        '不可变对象一经创建就不改变，好处是线程安全、易于推理、可安全共享。'
        '要"修改"时不是改字段，而是生成一个只替换目标字段的新实例，这就是 copyWith：'
        '参数用可空，未传就沿用原值（?? this.field）。本课给 Config 加 copyWith，'
        '把端口从 8080 改成 9090，原对象保持不变。真实项目常用 freezed 等生成，'
        '但手写几行就能理解原理。',
    objective: '能为不可变类实现 copyWith 并生成修改后的新对象。',
    prerequisites: <String>['已掌握类、const 构造与可空参数'],
    pitfalls: <String>[
      'copyWith 必须是"生成新对象"，别在内部改字段（final 也改不了）。',
      '可空字段的 copyWith 无法把值"改回 null"，需要额外哨兵或 Optional。',
      '忘记给新字段传默认值会导致字段丢失。',
    ],
    code:
        "class Config {\n"
        "  const Config(this.host, this.port);\n"
        "  final String host;\n"
        "  final int port;\n"
        "\n"
        "  Config copyWith({String? host, int? port}) {\n"
        "    return Config(host ?? this.host, port ?? this.port);\n"
        "  }\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  const base = Config('localhost', 8080);\n"
        "  final updated = base.copyWith(port: 9090);\n"
        "  print('原始 \${base.host}:\${base.port}');\n"
        "  print('更新 \${updated.host}:\${updated.port}');\n"
        "}\n",
    output: '原始 localhost:8080\n更新 localhost:9090\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '为 Config 加 name 字段并扩展 copyWith 支持改 name。',
        hint: '构造加 name，copyWith 加 {String? name}。',
        answer:
            "class Config {\n"
            "  const Config(this.name, this.port);\n"
            "  final String name;\n"
            "  final int port;\n"
            "  Config copyWith({String? name, int? port}) =>\n"
            "      Config(name ?? this.name, port ?? this.port);\n"
            "}\n"
            "\n"
            "void main() {\n"
            "  const c = Config('dev', 80);\n"
            "  print(c.copyWith(name: 'prod').name);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 115：copyWith 不可变更新',
    exampleSummary: '用 copyWith 生成只改一个字段的新对象，原对象不变。',
  ),
  DartLesson(
    id: 'dart-lesson-116',
    chapter: 'engineering',
    level: 'intermediate',
    title: '重写 == 与 hashCode',
    summary: '让值对象按内容判等，从而在 Set 中去重。',
    concepts: <String>['operator ==', 'hashCode', 'Object.hash', 'Set 去重'],
    explain:
        '默认的 == 比较的是对象身份，两个内容相同的 Point 也不相等，放进 Set 会各占一项。'
        '要让值相等，就重写 operator == 按字段比较，并同步重写 hashCode（用 Object.hash '
        '组合字段）。两者必须一致：相等的对象必须有相同 hashCode。本课给 Point 重写后，'
        '两个 Point(1,2) 在 Set 里只剩一项，contains 也返回 true。',
    objective: '能重写 == 与 hashCode，让值对象在集合中正确去重。',
    prerequisites: <String>['已掌握类、Set 与 Map 基础'],
    pitfalls: <String>[
      '重写了 == 却不重写 hashCode 会让 Set/Map 行为错乱。',
      'hashCode 必须只依赖参与 == 比较的字段。',
      '可变对象不要作为 Map 的键，字段变了哈希会失配。',
    ],
    code:
        "class Point {\n"
        "  const Point(this.x, this.y);\n"
        "  final int x;\n"
        "  final int y;\n"
        "\n"
        "  @override\n"
        "  bool operator ==(Object other) =>\n"
        "      other is Point && other.x == x && other.y == y;\n"
        "\n"
        "  @override\n"
        "  int get hashCode => Object.hash(x, y);\n"
        "\n"
        "  @override\n"
        "  String toString() => 'Point(\$x, \$y)';\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final set = <Point>{\n"
        "    const Point(1, 2),\n"
        "    const Point(1, 2),\n"
        "    const Point(3, 4),\n"
        "  };\n"
        "  print('集合大小 \${set.length}');\n"
        "  print(set.contains(const Point(1, 2)));\n"
        "}\n",
    output: '集合大小 2\ntrue\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '把 Point 用作 Map 的键，取值验证内容相等的键命中同一项。',
        hint: 'map[Point(1,2)] = "a"; 再读 map[Point(1,2)]。',
        answer:
            "class Point {\n"
            "  const Point(this.x, this.y);\n"
            "  final int x, y;\n"
            "  @override\n"
            "  bool operator ==(Object o) => o is Point && o.x == x && o.y == y;\n"
            "  @override\n"
            "  int get hashCode => Object.hash(x, y);\n"
            "}\n"
            "\n"
            "void main() {\n"
            "  final map = <Point, String>{};\n"
            "  map[const Point(1, 2)] = 'a';\n"
            "  print(map[const Point(1, 2)]);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 116：值相等与 hashCode',
    exampleSummary: '重写 ==/hashCode 后，内容相同的实例在 Set 中去重。',
  ),
  DartLesson(
    id: 'dart-lesson-117',
    chapter: 'engineering',
    level: 'advanced',
    title: '分层架构：仓储—服务—入口',
    summary: '用 repository/service/入口 三层组织代码，各司其职。',
    concepts: <String>['分层', '依赖注入', '职责分离'],
    explain:
        '可维护的程序按职责分层：仓储（Repository）只管数据存取，服务（Service）'
        '封装业务逻辑，入口（main）负责组装与调用。服务通过构造接收仓储，'
        '这叫依赖注入，便于替换与测试。本课 UserRepository 提供 findName，'
        'UserService 用它拼问候语，main 组装后调用。分层让"数据怎么存"与'
        '"业务怎么做"解耦。',
    objective: '能用仓储/服务/入口三层组织代码并通过构造注入依赖。',
    prerequisites: <String>['已掌握类、构造与 Map'],
    pitfalls: <String>[
      '把业务逻辑写进 main 会让代码难测难复用。',
      '服务直接 new 仓储会写死依赖，难以替换为假实现。',
      '层与层职责要清晰，仓储不要掺业务规则。',
    ],
    code:
        "class UserRepository {\n"
        "  final Map<int, String> _store = <int, String>{1: '小明', 2: '小红'};\n"
        "  String? findName(int id) => _store[id];\n"
        "}\n"
        "\n"
        "class UserService {\n"
        "  UserService(this.repository);\n"
        "  final UserRepository repository;\n"
        "  String greet(int id) {\n"
        "    final name = repository.findName(id);\n"
        "    return name == null ? '未知用户' : '你好，\$name';\n"
        "  }\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final service = UserService(UserRepository());\n"
        "  print(service.greet(1));\n"
        "  print(service.greet(99));\n"
        "}\n",
    output: '你好，小明\n未知用户\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '定义仓储接口 UserRepository（抽象），并写内存实现注入到 Service。',
        hint: 'abstract class UserRepository { String? findName(int id); }。',
        answer:
            "abstract class UserRepository {\n"
            "  String? findName(int id);\n"
            "}\n"
            "\n"
            "class InMemoryRepo implements UserRepository {\n"
            "  @override\n"
            "  String? findName(int id) => id == 1 ? '小明' : null;\n"
            "}\n"
            "\n"
            "void main() {\n"
            "  final UserRepository repo = InMemoryRepo();\n"
            "  print(repo.findName(1));\n"
            "}",
      ),
    ],
    exampleTitle: '示例 117：分层架构',
    exampleSummary: '仓储、服务、入口三层协作，服务经构造注入仓储。',
  ),
  DartLesson(
    id: 'dart-lesson-118',
    chapter: 'engineering',
    level: 'advanced',
    title: '配置与环境隔离',
    summary: '用默认值 + 覆盖值合并配置，缺失键不崩溃。',
    concepts: <String>['配置合并', '默认值', '环境隔离'],
    explain:
        '配置应支持"默认值兜底 + 环境覆盖"。AppConfig 持有默认 Map，取值时用 '
        'values[key] ?? defaults[key]：环境提供了就用环境值，没提供就回退默认。'
        '这样同一份代码在开发、测试、生产下可用不同配置，且缺键不会崩溃。'
        '本课模拟"只覆盖端口"和"完全空配置"两种情况，验证回退逻辑。',
    objective: '能实现带默认值的配置读取，正确处理缺失键。',
    prerequisites: <String>['已掌握 Map、可空与 ?? 运算符'],
    pitfalls: <String>[
      '直接 values[key]! 在缺键时会抛错，应该用 ?? 回退。',
      '默认值本身也不能为 null，否则 ?? 链末端仍为空。',
      '敏感配置不要写死在源码，应通过环境注入。',
    ],
    code:
        "class AppConfig {\n"
        "  AppConfig(this.values);\n"
        "\n"
        "  final Map<String, String> values;\n"
        "\n"
        "  static const Map<String, String> defaults = <String, String>{\n"
        "    'host': 'localhost',\n"
        "    'port': '80',\n"
        "  };\n"
        "\n"
        "  String get host => values['host'] ?? defaults['host']!;\n"
        "  String get port => values['port'] ?? defaults['port']!;\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final withOverride = AppConfig(<String, String>{'port': '8080'});\n"
        "  print('\${withOverride.host}:\${withOverride.port}');\n"
        "  final empty = AppConfig(<String, String>{});\n"
        "  print('\${empty.host}:\${empty.port}');\n"
        "}\n",
    output: 'localhost:8080\nlocalhost:80\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '给配置加 debug 开关（默认 false），覆盖为 true 时打印它。',
        hint: '用 values["debug"] ?? defaults["debug"]，再 == "true" 解析。',
        answer:
            "class AppConfig {\n"
            "  AppConfig(this.values);\n"
            "  final Map<String, String> values;\n"
            "  bool get debug => (values['debug'] ?? 'false') == 'true';\n"
            "}\n"
            "\n"
            "void main() {\n"
            "  print(AppConfig(<String, String>{'debug': 'true'}).debug);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 118：配置默认值',
    exampleSummary: '默认值加环境覆盖合并配置，缺失键安全回退。',
  ),
  DartLesson(
    id: 'dart-lesson-119',
    chapter: 'engineering',
    level: 'advanced',
    title: '确定性性能度量',
    summary: '用操作次数衡量算法成本，而不是打印不稳定的耗时。',
    concepts: <String>['操作计数', '复杂度', '确定性'],
    explain:
        '比较算法快慢时，直接测耗时往往不稳定（受机器、调度影响，测试无法断言）。'
        '更可靠的做法是统计"基本操作次数"，它只取决于输入规模，完全确定。'
        '本课对规模 10、100、1000 统计求和循环执行的加法次数，得到与 n 成正比的'
        '线性增长，直观体现 O(n)。这也是编写可断言的性能测试的关键思路。',
    objective: '能用操作计数确定性地度量算法随规模的增长。',
    prerequisites: <String>['已掌握循环与函数'],
    pitfalls: <String>[
      '不要打印 Stopwatch 耗时作为断言依据，结果不确定。',
      '计数要界定"什么算一次操作"，否则数字含义模糊。',
      '小规模差异可能被常数掩盖，观察趋势比绝对值更有意义。',
    ],
    code:
        "int countOperations(int n) {\n"
        "  var operations = 0;\n"
        "  var sum = 0;\n"
        "  for (var i = 1; i <= n; i++) {\n"
        "    sum += i;\n"
        "    operations++;\n"
        "  }\n"
        "  return operations;\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  for (final n in <int>[10, 100, 1000]) {\n"
        "    print('n=\$n 操作次数 \${countOperations(n)}');\n"
        "  }\n"
        "}\n",
    output: 'n=10 操作次数 10\nn=100 操作次数 100\nn=1000 操作次数 1000\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '统计嵌套循环（外层 n、内层 n）的操作次数，验证是 n²。',
        hint: '双重 for，内层 operations++。',
        answer:
            "int nestedOps(int n) {\n"
            "  var ops = 0;\n"
            "  for (var i = 0; i < n; i++) {\n"
            "    for (var j = 0; j < n; j++) {\n"
            "      ops++;\n"
            "    }\n"
            "  }\n"
            "  return ops;\n"
            "}\n"
            "\n"
            "void main() {\n"
            "  print(nestedOps(5));\n"
            "}",
      ),
    ],
    exampleTitle: '示例 119：操作计数度量',
    exampleSummary: '用基本操作次数确定性地展示线性增长。',
  ),
  DartLesson(
    id: 'dart-lesson-120',
    chapter: 'engineering',
    level: 'advanced',
    title: '综合实战：命令行参数解析',
    summary: '综合类、解析与错误处理，实现一个参数解析器。',
    concepts: <String>['参数解析', '静态工厂', '综合应用'],
    explain:
        '本课把前面所学综合起来：用类建模解析结果，用静态方法 parse 把字符串列表'
        '（模拟命令行参数）拆成命令与 --key value 形式的标志，缺失命令时抛 '
        'ArgumentError。它演示了真实 CLI 工具参数解析的核心逻辑，也串起类、循环、'
        'Map、异常与错误处理。main 里用一组模拟参数验证结果。'
        '真实项目可用 package:args，但手写一遍能理解其原理。',
    objective: '能实现一个把参数列表解析成命令与标志映射的解析器。',
    prerequisites: <String>['已掌握类、Map、循环与异常'],
    pitfalls: <String>[
      '--key 结尾却没有 value 时要决定行为（忽略或报错），需明确。',
      '把下标 i 与 ++i 混用要小心，确保跳到 value 后不重复处理。',
      '缺少命令属非法输入，应显式抛错而不是返回空对象。',
    ],
    code:
        "class Args {\n"
        "  Args(this.command, this.flags);\n"
        "  final String command;\n"
        "  final Map<String, String> flags;\n"
        "\n"
        "  static Args parse(List<String> input) {\n"
        "    if (input.isEmpty) {\n"
        "      throw ArgumentError('缺少命令');\n"
        "    }\n"
        "    final command = input.first;\n"
        "    final flags = <String, String>{};\n"
        "    for (var i = 1; i < input.length; i++) {\n"
        "      final token = input[i];\n"
        "      if (token.startsWith('--') && i + 1 < input.length) {\n"
        "        flags[token.substring(2)] = input[++i];\n"
        "      }\n"
        "    }\n"
        "    return Args(command, flags);\n"
        "  }\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final args = Args.parse(<String>['build', '--target', 'ohos', '--mode', 'release']);\n"
        "  print('命令 \${args.command}');\n"
        "  print('target=\${args.flags['target']}');\n"
        "  print('mode=\${args.flags['mode']}');\n"
        "  print('参数个数 \${args.flags.length}');\n"
        "}\n",
    output: '命令 build\ntarget=ohos\nmode=release\n参数个数 2\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '对空参数列表调用 Args.parse，验证抛出 ArgumentError。',
        hint:
            'try { Args.parse([]) } on ArgumentError catch (e) { print(e.message); }。',
        answer:
            "class Args {\n"
            "  Args(this.command);\n"
            "  final String command;\n"
            "  static Args parse(List<String> input) {\n"
            "    if (input.isEmpty) throw ArgumentError('缺少命令');\n"
            "    return Args(input.first);\n"
            "  }\n"
            "}\n"
            "\n"
            "void main() {\n"
            "  try {\n"
            "    Args.parse(<String>[]);\n"
            "  } on ArgumentError catch (e) {\n"
            "    print(e.message);\n"
            "  }\n"
            "}",
      ),
    ],
    exampleTitle: '示例 120：参数解析器',
    exampleSummary: '把参数列表解析为命令与标志映射，并处理缺失命令。',
  ),
];
