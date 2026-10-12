import '../dart_lesson.dart';

/// Chapter `control` — lessons 011-018. Owned by the first pi.
const List<DartLesson> controlLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-011',
    chapter: 'control',
    level: 'beginner',
    title: '条件判断 if / else',
    summary: '用 if、else if、else 处理分支，理解 Dart 只接受 bool 条件。',
    concepts: <String>['if', 'else if', 'else', 'bool 条件'],
    explain:
        'Dart 的 if 条件必须是 bool 类型，不像 JavaScript 会把 0、空字符串当成假，'
        '写 if (count) 会直接编译不过，必须写成 if (count > 0)。分支从上往下匹配，'
        '第一个成立的分支执行后就跳出整个 if 链。',
    objective: '会用 if/else if/else 写出互斥的多分支逻辑。',
    pitfalls: <String>[
      '把数字或字符串直接当条件使用会编译报错，要显式比较。',
      '多个 else if 顺序错误会掩盖后面的分支，例如把 >60 放在 >80 前面。',
    ],
    code: "void main() {\n"
        "  const score = 85;\n"
        "  if (score >= 90) {\n"
        "    print('优秀');\n"
        "  } else if (score >= 80) {\n"
        "    print('良好');\n"
        "  } else if (score >= 60) {\n"
        "    print('及格');\n"
        "  } else {\n"
        "    print('不及格');\n"
        "  }\n"
        "}\n",
    output: '良好\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '给 59 分打印等级。',
        hint: '沿用同一段 if 链。',
        answer: "const score = 59;\n"
            "if (score >= 90) { print('优秀'); }\n"
            "else if (score >= 80) { print('良好'); }\n"
            "else if (score >= 60) { print('及格'); }\n"
            "else { print('不及格'); }",
      ),
    ],
    exampleTitle: '示例 011：条件判断',
    exampleSummary: '四档成绩等级判断，演示 else if 的从上往下匹配。',
  ),
  DartLesson(
    id: 'dart-lesson-012',
    chapter: 'control',
    level: 'beginner',
    title: '三元运算符与??',
    summary: '用条件 ? 甲 : 乙 简写二选一，用 ?? 提供默认值。',
    concepts: <String>['三元运算符', '??', '??=', '默认值'],
    explain:
        '简单的二选一可以用「条件 ? 甲 : 乙」，比完整的 if/else 更紧凑。?? 用来在值'
        '为 null 时给出默认值；??= 仅在变量为 null 时赋值。它们让「可能缺失的值」'
        '处理起来更顺畅。',
    objective: '会用三元和 ?? 写出简洁的条件取值。',
    pitfalls: <String>[
      '把复杂的多分支硬塞进三元表达式会难以阅读，多分支还是用 if 链。',
      '?? 只处理 null，不处理空字符串或 0，别把两者混淆。',
    ],
    code: "void main() {\n"
        "  const age = 17;\n"
        "  final label = age >= 18 ? '成年' : '未成年';\n"
        "  print(label);\n"
        "\n"
        "  const String? nickname = null;\n"
        "  print(nickname ?? '匿名用户');\n"
        "\n"
        "  int? bonus;\n"
        "  bonus ??= 10;\n"
        "  print(bonus);\n"
        "}\n",
    output: '未成年\n匿名用户\n10\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: "用三元判断一个数是否偶数并打印 '偶数'/'奇数'。",
        hint: '用 % 2 == 0 作条件。',
        answer: "const n = 7;\nprint(n % 2 == 0 ? '偶数' : '奇数');",
      ),
    ],
    exampleTitle: '示例 012：三元运算符与 ??',
    exampleSummary: '三元二选一、?? 默认值、??= 条件赋值。',
  ),
  DartLesson(
    id: 'dart-lesson-013',
    chapter: 'control',
    level: 'beginner',
    title: 'switch 与模式匹配分支',
    summary: '用 switch 处理多值选择，含 Dart 3 的箭头语法。',
    concepts: <String>['switch', 'case', '箭头语法', 'default'],
    explain:
        'switch 适合对同一个值做多路等值判断。Dart 3 支持 case 后直接跟 => 表达式，'
        '不需要手写 break，也不会意外穿透。default 处理其余情况。相比长串 else if，'
        'switch 的意图更清楚。switch 表达式是 Dart 3 语法，需要官方 Dart SDK 引擎；'
        'dart_eval 子集对它的支持有限，未能保证运行。',
    objective: '会用 switch 箭头语法处理多分支并给出默认分支。',
    pitfalls: <String>[
      '传统 case 忘了 break 会穿透到下一个 case；箭头语法没有这个问题。',
      'switch 的每个分支返回类型要一致，否则编译报错。',
    ],
    code: "String describe(int code) {\n"
        "  return switch (code) {\n"
        "    200 => '成功',\n"
        "    301 => '永久重定向',\n"
        "    404 => '未找到',\n"
        "    500 => '服务器错误',\n"
        "    _ => '未知状态码',\n"
        "  };\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  for (final code in [200, 404, 999]) {\n"
        "    print('\$code: \${describe(code)}');\n"
        "  }\n"
        "}\n",
    output: '200: 成功\n404: 未找到\n999: 未知状态码\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: "用 switch 表达式把星期数字 1-7 转成中文，其余返回 '非法'。",
        hint: "case 1 => '周一' … _ => '非法'。",
        answer: "String week(int d) => switch (d) {\n"
            "  1 => '周一', 2 => '周二', 3 => '周三', 4 => '周四',\n"
            "  5 => '周五', 6 => '周六', 7 => '周日', _ => '非法',\n"
            "};\nprint(week(3));",
      ),
    ],
    exampleTitle: '示例 013：switch 表达式',
    exampleSummary: '用 switch 表达式把 HTTP 状态码映射成中文描述。',
  ),
  DartLesson(
    id: 'dart-lesson-014',
    chapter: 'control',
    level: 'beginner',
    title: 'for 循环',
    summary: '传统三段式 for 与区间累加。',
    concepts: <String>['for', '循环变量', '累加'],
    explain:
        'for (初始化; 条件; 步进) 是最常用的计数循环。循环变量通常用 var 声明，'
        '作用域只在循环内。用循环把一组数字累加求和是最典型的练习。',
    objective: '会用 for 循环完成计数和累加。',
    pitfalls: <String>[
      '条件写成 i <= n 还是 i < n 决定循环次数，边界错一位结果就错。',
      '累加变量必须在循环外初始化，写在循环内会被重置。',
    ],
    code: "void main() {\n"
        "  var sum = 0;\n"
        "  for (var i = 1; i <= 100; i++) {\n"
        "    sum += i;\n"
        "  }\n"
        "  print('1 到 100 的和是 \$sum');\n"
        "\n"
        "  final squares = <int>[];\n"
        "  for (var i = 1; i <= 5; i++) {\n"
        "    squares.add(i * i);\n"
        "  }\n"
        "  print(squares);\n"
        "}\n",
    output: '1 到 100 的和是 5050\n[1, 4, 9, 16, 25]\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用 for 计算 5 的阶乘（1*2*3*4*5）。',
        hint: '累乘变量从 1 开始。',
        answer: "var product = 1;\nfor (var i = 1; i <= 5; i++) {\n  product *= i;\n}\nprint(product);",
      ),
    ],
    exampleTitle: '示例 014：for 循环',
    exampleSummary: '累加求和与收集平方数的计数循环。',
  ),
  DartLesson(
    id: 'dart-lesson-015',
    chapter: 'control',
    level: 'beginner',
    title: 'while 与 do-while',
    summary: '条件循环，以及至少执行一次的 do-while。',
    concepts: <String>['while', 'do-while', '循环控制'],
    explain:
        'while 在每次迭代前检查条件，条件一开始为假就一次也不执行。do-while 先执行'
        '一次再检查条件，适合「至少要做一次」的场景，比如菜单交互。用循环时一定要'
        '确保条件最终会变假，否则会死循环。',
    objective: '能根据是否需要至少执行一次来选择 while 或 do-while。',
    pitfalls: <String>[
      '忘记在循环体内改变条件变量会导致死循环。',
      'do-while 的条件后面有分号，漏写会编译报错。',
    ],
    code: "void main() {\n"
        "  var n = 3;\n"
        "  while (n > 0) {\n"
        "    print('倒计时 \$n');\n"
        "    n--;\n"
        "  }\n"
        "  print('发射！');\n"
        "\n"
        "  var attempts = 0;\n"
        "  do {\n"
        "    attempts++;\n"
        "  } while (attempts < 1);\n"
        "  print('至少执行了一次，attempts=\$attempts');\n"
        "}\n",
    output: '倒计时 3\n倒计时 2\n倒计时 1\n发射！\n至少执行了一次，attempts=1\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用 while 求 1+2+…+n 首次超过 50 时的 n。',
        hint: '循环累加，超过 50 就 break。',
        answer: "var sum = 0, n = 0;\nwhile (sum <= 50) {\n  n++;\n  sum += n;\n}\nprint(n);",
      ),
    ],
    exampleTitle: '示例 015：while 与 do-while',
    exampleSummary: '倒计时循环与至少执行一次的 do-while。',
  ),
  DartLesson(
    id: 'dart-lesson-016',
    chapter: 'control',
    level: 'beginner',
    title: 'break 与 continue',
    summary: '提前结束循环、跳过本次迭代。',
    concepts: <String>['break', 'continue', '循环控制'],
    explain:
        'break 立即结束整个循环，continue 跳过本次迭代直接进入下一次。它们让循环'
        '体里的条件判断更清晰，避免用复杂条件硬凑。嵌套循环里 break 只跳出最内层。',
    objective: '会用 break 和 continue 精确控制循环流程。',
    pitfalls: <String>[
      '嵌套循环里的 break 不会跳出外层，需要标记或改写逻辑。',
      'continue 写在更新语句前可能跳过步进造成死循环（for 循环里一般安全）。',
    ],
    code: "void main() {\n"
        "  for (var i = 1; i <= 10; i++) {\n"
        "    if (i % 3 == 0) continue;\n"
        "    if (i > 8) break;\n"
        "    print(i);\n"
        "  }\n"
        "\n"
        "  var found = -1;\n"
        "  for (var i = 2; i < 20; i++) {\n"
        "    if (i % 7 == 0) {\n"
        "      found = i;\n"
        "      break;\n"
        "    }\n"
        "  }\n"
        "  print('第一个 7 的倍数是 \$found');\n"
        "}\n",
    output: '1\n2\n4\n5\n7\n8\n第一个 7 的倍数是 7\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '找出 1 到 100 里第一个能被 13 整除的数。',
        hint: '循环加 break。',
        answer: "for (var i = 1; i <= 100; i++) {\n  if (i % 13 == 0) { print(i); break; }\n}",
      ),
    ],
    exampleTitle: '示例 016：break 与 continue',
    exampleSummary: '跳过 3 的倍数、提前结束，以及查找第一个符合条件的值。',
  ),
  DartLesson(
    id: 'dart-lesson-017',
    chapter: 'control',
    level: 'beginner',
    title: '函数定义与调用',
    summary: '定义带参数和返回值的函数，用 => 简写。',
    concepts: <String>['函数', '参数', '返回值', '箭头函数'],
    explain:
        '函数把一段逻辑封装起来复用。返回类型写在函数名前，参数写在括号里。函数体'
        '只有一条表达式时可以用 => 简写。没有返回值用 void。',
    objective: '会定义和调用带参数的函数，并写出箭头函数。',
    pitfalls: <String>[
      '声明了返回类型却没写 return，或 return 了错误类型。',
      '箭头函数不能包含语句块，只能是单个表达式。',
    ],
    code: "int add(int a, int b) => a + b;\n"
        "\n"
        "int maxOf(int a, int b) {\n"
        "  return a > b ? a : b;\n"
        "}\n"
        "\n"
        "void greet(String name) {\n"
        "  print('你好，\$name！');\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  print(add(3, 5));\n"
        "  print(maxOf(12, 7));\n"
        "  greet('小明');\n"
        "}\n",
    output: '8\n12\n你好，小明！\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '写一个函数 area(w, h) 返回矩形面积并调用。',
        hint: '箭头函数一行搞定。',
        answer: "int area(int w, int h) => w * h;\nprint(area(4, 5));",
      ),
    ],
    exampleTitle: '示例 017：函数定义与调用',
    exampleSummary: '箭头函数、带 return 的函数和 void 函数的差别。',
  ),
  DartLesson(
    id: 'dart-lesson-018',
    chapter: 'control',
    level: 'beginner',
    title: '命名参数与默认值',
    summary: '用 {} 包参数变成命名参数，并设置默认值。',
    concepts: <String>['命名参数', '默认值', 'required'],
    explain:
        '参数用 {} 包起来就是命名参数，调用时要写名字，好处是意图清楚、顺序随意。'
        '用 required 标记必填的命名参数。默认值让调用方可以省略有合理默认的参数。',
    objective: '会用命名参数和默认值写出易读的函数签名。',
    pitfalls: <String>[
      '命名参数默认可选，想强制传入要加 required。',
      '默认值必须是编译期常量，不能是运行时才确定的值。',
    ],
    code: "String greet({required String name, String greeting = '你好'}) {\n"
        "  return '\$greeting，\$name！';\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  print(greet(name: '小明'));\n"
        "  print(greet(name: '小红', greeting: '早上好'));\n"
        "  print(greet(greeting: '晚上好', name: '小刚'));\n"
        "}\n",
    output: '你好，小明！\n早上好，小红！\n晚上好，小刚！\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '写 order({required String item, int count = 1}) 返回订单描述。',
        hint: '命名参数 + 默认值。',
        answer: "String order({required String item, int count = 1}) => '\$item x\$count';\n"
            "print(order(item: '咖啡'));\nprint(order(item: '茶', count: 3));",
      ),
    ],
    exampleTitle: '示例 018：命名参数与默认值',
    exampleSummary: 'required 命名参数与可省略的默认参数。',
  ),
];
