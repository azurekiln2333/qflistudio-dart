import '../dart_lesson.dart';

/// Chapter `exceptions` — lessons 055-060. Owned by the first pi.
const List<DartLesson> exceptionsLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-055',
    chapter: 'exceptions',
    level: 'intermediate',
    title: 'try / catch / finally',
    summary: '捕获异常、读取错误信息，并用 finally 做清理。',
    concepts: <String>['try', 'catch', 'finally', '栈追踪'],
    explain:
        '用 try 包住可能出错的代码，catch 捕获异常。catch (e) 拿到异常对象，'
        'catch (e, s) 还能拿到栈追踪。finally 无论是否出错都会执行，适合释放资源。'
        'Dart 的异常都是非受检的，无需在签名里声明。',
    objective: '会用 try/catch/finally 处理错误并保证清理。',
    pitfalls: <String>[
      'finally 里 return 会吞掉 try 的返回值或异常，尽量避免。',
      '只写空的 catch 会静默吞错，至少记录或重新抛出。',
    ],
    code: "void main() {\n"
        "  try {\n"
        "    final result = int.parse('abc');\n"
        "    print(result);\n"
        "  } on FormatException catch (e) {\n"
        "    print('解析失败：\${e.message}');\n"
        "  } finally {\n"
        "    print('清理完成');\n"
        "  }\n"
        "  print('程序继续');\n"
        "}\n",
    output: '解析失败：Invalid radix-10 number\n清理完成\n程序继续\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: "用 try/catch 安全地对 '42' 和 'x' 做 int.parse。",
        hint: '循环里逐个 try。',
        answer: "for (final s in ['42', 'x']) {\n"
            "  try {\n"
            "    print(int.parse(s));\n"
            "  } on FormatException {\n"
            "    print('无效');\n"
            "  }\n"
            "}",
      ),
    ],
    exampleTitle: '示例 055：try / catch / finally',
    exampleSummary: '捕获 FormatException 并保证 finally 清理执行。',
  ),
  DartLesson(
    id: 'dart-lesson-056',
    chapter: 'exceptions',
    level: 'intermediate',
    title: '抛出与自定义异常',
    summary: '用 throw 抛出异常，定义自己的异常类。',
    concepts: <String>['throw', '自定义异常', 'Exception'],
    explain:
        '用 throw 抛出异常对象，通常抛出实现了 Exception 或 Error 的类型。自定义异常'
        '能携带业务上下文，例如余额不足时抛出 InsufficientFunds，让调用方区分处理。',
    objective: '会定义并抛出携带信息的自定义异常。',
    pitfalls: <String>[
      '不要用 Exception 当万能类型，具体异常更利于分类处理。',
      'Error 表示程序缺陷，通常不应被业务代码捕获，业务异常用 Exception。',
    ],
    code: "class ValidationException implements Exception {\n"
        "  const ValidationException(this.field, this.reason);\n"
        "  final String field;\n"
        "  final String reason;\n"
        "\n"
        "  @override\n"
        "  String toString() => 'ValidationException(\$field: \$reason)';\n"
        "}\n"
        "\n"
        "void validateAge(int age) {\n"
        "  if (age < 0) throw const ValidationException('age', '不能为负');\n"
        "  print('年龄合法：\$age');\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  validateAge(20);\n"
        "  try {\n"
        "    validateAge(-1);\n"
        "  } on ValidationException catch (e) {\n"
        "    print(e);\n"
        "  }\n"
        "}\n",
    output: '年龄合法：20\nValidationException(age: 不能为负)\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '定义 NotPositiveException，写函数要求参数 > 0，否则抛出。',
        hint: 'implements Exception。',
        answer: "class NotPositiveException implements Exception {}\n"
            "void check(int n) {\n"
            "  if (n <= 0) throw NotPositiveException();\n"
            "}",
      ),
    ],
    exampleTitle: '示例 056：抛出与自定义异常',
    exampleSummary: '自定义校验异常、throw 与按类型捕获。',
  ),
  DartLesson(
    id: 'dart-lesson-057',
    chapter: 'exceptions',
    level: 'intermediate',
    title: '多个 catch 与重新抛出',
    summary: '按类型分别捕获，必要时用 rethrow 传递。',
    concepts: <String>['多 catch', 'on', 'rethrow'],
    explain:
        '可以给 try 配多个 on 子句，按异常类型从具体到通用排列。有时需要记录后再把'
        '异常交给上层，用 rethrow 保留原始栈追踪，比 throw e 更准确。',
    objective: '会按类型分层捕获并用 rethrow 传递异常。',
    pitfalls: <String>[
      '把 on FormatException 放在 on Exception 之后会永远不命中。',
      'throw e 会重置栈追踪，应优先用 rethrow。',
    ],
    code: "int parsePositive(String s) {\n"
        "  final value = int.parse(s);\n"
        "  if (value <= 0) throw ArgumentError('必须为正');\n"
        "  return value;\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  for (final input in ['10', 'abc', '-3']) {\n"
        "    try {\n"
        "      print(parsePositive(input));\n"
        "    } on FormatException {\n"
        "      print('不是数字：\$input');\n"
        "    } on ArgumentError catch (e) {\n"
        "      print('非法值：\${e.message}');\n"
        "    } on Exception catch (e) {\n"
        "      print('其它错误：\$e');\n"
        "    }\n"
        "  }\n"
        "}\n",
    output: '10\n不是数字：abc\n非法值：必须为正\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '写 safeDivide(a, b)，b 为 0 时抛 ArgumentError 并在调用处捕获。',
        hint: 'throw ArgumentError 后 try/catch。',
        answer: "double safeDivide(int a, int b) {\n"
            "  if (b == 0) throw ArgumentError('除数不能为 0');\n"
            "  return a / b;\n"
            "}",
      ),
    ],
    exampleTitle: '示例 057：多个 catch 与重新抛出',
    exampleSummary: 'FormatException / ArgumentError / Exception 的分层捕获。',
  ),
  DartLesson(
    id: 'dart-lesson-058',
    chapter: 'exceptions',
    level: 'intermediate',
    title: '异常与错误语义',
    summary: '区分 Exception 与 Error，理解该捕获什么。',
    concepts: <String>['Exception', 'Error', '捕获边界'],
    explain:
        'Exception 表示可预期的运行时问题（参数非法、IO 失败），应该处理。Error 表示'
        '程序缺陷（越界、类型错误、栈溢出），通常不应被捕获，而应修复代码。把「可'
        '预期」和「缺陷」分开，能写出更健康的错误处理。',
    objective: '能区分 Exception 与 Error 并只在合适的地方捕获。',
    pitfalls: <String>[
      'catch (e) 会连 Error 一起吞掉，掩盖真正的程序缺陷。',
      '把业务异常定义成 Error 会被调用方忽略，应使用 Exception。',
    ],
    code: "void main() {\n"
        "  try {\n"
        "    final list = <int>[1, 2, 3];\n"
        "    print(list[5]);\n"
        "  } on RangeError catch (e) {\n"
        "    print('越界（这是缺陷，通常要修代码）：\${e.runtimeType}');\n"
        "  }\n"
        "\n"
        "  try {\n"
        "    throw const FormatException('业务层可预期的失败');\n"
        "  } on FormatException catch (e) {\n"
        "    print('可预期：\${e.message}');\n"
        "  }\n"
        "}\n",
    output: '越界（这是缺陷，通常要修代码）：RangeError\n可预期：业务层可预期的失败\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: "判断 int.parse('x') 抛出的 FormatException 属于 Exception 还是 Error。",
        hint: '它是 Exception 的子类，可预期。',
        answer: "try { int.parse('x'); } on Exception { print('Exception'); }",
      ),
    ],
    exampleTitle: '示例 058：异常与错误语义',
    exampleSummary: 'RangeError 与 FormatException 的语义区别。',
  ),
  DartLesson(
    id: 'dart-lesson-059',
    chapter: 'exceptions',
    level: 'intermediate',
    title: 'Result 模式代替异常',
    summary: '用密封结果类型表达「成功或失败」，避免异常控制流。',
    concepts: <String>['Result 模式', '成功/失败', '显式错误'],
    explain:
        '有些团队偏好把可预期的失败表达成返回值而不是异常。用一个带 ok/err 的'
        '结果类，让调用方必须显式处理失败分支，避免忘记 try/catch。异常适合真正的'
        '意外，返回值适合可预期的分支。本课用到 sealed 类与 switch 模式解构，'
        '属于 Dart 3 特性，需要官方 Dart SDK 引擎；dart_eval 子集不保证支持。',
    objective: '会用结果类型显式表达成功或失败。',
    pitfalls: <String>[
      '结果类型会让调用链变长，简单场景用异常更直接。',
      '既要显式处理又用了 Result，却忘了判 ok 就访问 value，会抛异常。',
    ],
    code: "sealed class Result<T> {\n"
        "  const Result();\n"
        "}\n"
        "\n"
        "class Ok<T> extends Result<T> {\n"
        "  const Ok(this.value);\n"
        "  final T value;\n"
        "}\n"
        "\n"
        "class Err<T> extends Result<T> {\n"
        "  const Err(this.message);\n"
        "  final String message;\n"
        "}\n"
        "\n"
        "Result<int> parseAge(String s) {\n"
        "  final value = int.tryParse(s);\n"
        "  if (value == null) return const Err('不是数字');\n"
        "  if (value < 0) return const Err('不能为负');\n"
        "  return Ok(value);\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  for (final s in ['20', 'x']) {\n"
        "    switch (parseAge(s)) {\n"
        "      case Ok(:final value):\n"
        "        print('成功：\$value');\n"
        "      case Err(:final message):\n"
        "        print('失败：\$message');\n"
        "    }\n"
        "  }\n"
        "}\n",
    output: '成功：20\n失败：不是数字\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '写 Result<double> divide(a, b)，b 为 0 返回 Err。',
        hint: '用 Ok/Err 包装。',
        answer: "Result<double> divide(double a, double b) =>\n"
            "    b == 0 ? const Err('除数为 0') : Ok(a / b);",
      ),
    ],
    exampleTitle: '示例 059：Result 模式',
    exampleSummary: '密封结果类型 + switch 模式匹配处理成败。',
  ),
  DartLesson(
    id: 'dart-lesson-060',
    chapter: 'exceptions',
    level: 'intermediate',
    title: '综合练习：健壮的配置解析',
    summary: '把异常、结果类型与集合组合成安全的配置解析器。',
    concepts: <String>['综合运用', '异常', '结果类型', '解析'],
    explain:
        '这一课把前面所有错误处理手段组合起来：逐行解析 key=value 配置，对格式错误的'
        '行收集错误而不是中断，对可预期的缺省给出默认值，最后输出解析结果和错误清单。',
    objective: '能写出对坏输入健壮、能报告所有错误的解析流程。',
    pitfalls: <String>[
      '遇到第一处错误就中断会丢失后续信息，收集错误更友好。',
      '静默跳过非法行会让用户以为配置生效了，应显式列出。',
    ],
    code: "class ConfigResult {\n"
        "  ConfigResult(this.values, this.errors);\n"
        "  final Map<String, String> values;\n"
        "  final List<String> errors;\n"
        "}\n"
        "\n"
        "ConfigResult parseConfig(String text) {\n"
        "  final values = <String, String>{};\n"
        "  final errors = <String>[];\n"
        "  for (final line in text.split('\\n')) {\n"
        "    final trimmed = line.trim();\n"
        "    if (trimmed.isEmpty) continue;\n"
        "    final index = trimmed.indexOf('=');\n"
        "    if (index <= 0) {\n"
        "      errors.add('非法行：\$trimmed');\n"
        "      continue;\n"
        "    }\n"
        "    final key = trimmed.substring(0, index).trim();\n"
        "    final value = trimmed.substring(index + 1).trim();\n"
        "    values[key] = value;\n"
        "  }\n"
        "  return ConfigResult(values, errors);\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  const text = 'host=localhost\\nport=8080\\n坏行\\nname = app';\n"
        "  final result = parseConfig(text);\n"
        "  print('host = \${result.values['host']}');\n"
        "  print('port = \${int.parse(result.values['port']!)}');\n"
        "  print('name = \${result.values['name']}');\n"
        "  print('错误数：\${result.errors.length}');\n"
        "  for (final error in result.errors) {\n"
        "    print(error);\n"
        "  }\n"
        "}\n",
    output: 'host = localhost\nport = 8080\nname = app\n错误数：1\n非法行：坏行\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '给解析器加一层校验：缺 port 时在 errors 里加一条提示。',
        hint: "解析后检查 values.containsKey('port')。",
        answer: "if (!values.containsKey('port')) {\n"
            "  errors.add('缺少必填项：port');\n"
            "}",
      ),
    ],
    exampleTitle: '示例 060：综合练习：健壮的配置解析',
    exampleSummary: '逐行解析、收集错误、输出键值配置。',
  ),
];
