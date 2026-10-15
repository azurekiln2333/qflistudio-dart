import '../dart_lesson.dart';

/// Chapter `basics` — lessons 001-010. Owned by the first pi.
///
/// Export name: `basicsLessons`. Keep lessons sorted by id.
const List<DartLesson> basicsLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-001',
    chapter: 'basics',
    level: 'beginner',
    title: '第一个 Dart 程序',
    summary: '认识 main 函数、print 输出和语句分号，让程序跑起来。',
    concepts: <String>['main', 'print', '语句分号', '顶层函数'],
    explain:
        '每个 Dart 程序都从 main 函数开始执行，一个可执行文件里只能有一个 main。'
        'print 负责把内容输出到终端，它会自动把任何类型的值转成文字。'
        'Dart 的每条语句必须以分号结尾，漏写分号会直接编译报错，而不是运行时才出错。'
        '本课代码是标准 Dart 核心语法，可直接运行。',
    objective: '能写出带 main 的最小程序，并用 print 输出多行文本。',
    pitfalls: <String>[
      '漏写行尾分号会编译报错，报错位置常在下一行开头。',
      '一个文件里写两个 main 会报 "main is already declared"。',
    ],
    code:
        "void main() {\n"
        "  print('Hello, Dart!');\n"
        "  print('这是我的第一个程序');\n"
        "  print(1 + 2);\n"
        "}\n",
    output: 'Hello, Dart!\n这是我的第一个程序\n3\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '打印三行：你的姓名、年龄、所在城市。',
        hint: '写三个 print，每行一个字符串。',
        answer:
            "void main() {\n"
            "  print('小明');\n"
            "  print(18);\n"
            "  print('杭州');\n"
            "}",
      ),
    ],
    exampleTitle: '示例 001：第一个 Dart 程序',
    exampleSummary: '最小可运行程序：main 函数加三行 print 输出。',
  ),
  DartLesson(
    id: 'dart-lesson-002',
    chapter: 'basics',
    level: 'beginner',
    title: '变量与类型',
    summary: '用 var 推断类型，用 final 和 const 表达不可变。',
    concepts: <String>[
      'var',
      'final',
      'const',
      'int',
      'double',
      'String',
      'bool',
    ],
    explain:
        'var 让编译器根据初始值推断静态类型，写出的是确定类型而不是动态类型。'
        'final 表示变量只能赋值一次，const 更严格，要求编译期就能确定值。'
        'Dart 的除法运算符 / 永远返回 double，想要整数除法要用 ~/，取余用 %。'
        '本课代码是标准 Dart 核心语法，可直接运行，不需要标准输入或网络。',
    objective: '会选择合适的变量声明方式，并区分整数除法与取余。',
    pitfalls: <String>[
      '想整除却用了 /，结果拿到 8.5 这样的 double。',
      '对 const 变量赋新值会编译报错，需要改值时应使用 var 或 final。',
    ],
    code:
        "void main() {\n"
        "  var age = 20;\n"
        "  final name = '小明';\n"
        "  const pi = 3.14159;\n"
        "  double height = 1.75;\n"
        "  bool isStudent = true;\n"
        "\n"
        "  print('\$name 今年 \$age 岁');\n"
        "  print('身高 \$height，圆周率 \$pi');\n"
        "  print('是学生吗？\$isStudent');\n"
        "  print(age.runtimeType);\n"
        "  print(age / 2);\n"
        "  print(age ~/ 2);\n"
        "}\n",
    output: '小明 今年 20 岁\n身高 1.75，圆周率 3.14159\n是学生吗？true\nint\n10.0\n10\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '把 100 秒换算成「几分几秒」并打印。',
        hint: '整除用 ~/，取余用 %。',
        answer:
            "const total = 100;\n"
            "print('\${total ~/ 60} 分 \${total % 60} 秒');",
      ),
    ],
    exampleTitle: '示例 002：变量与类型',
    exampleSummary: '五种常用类型的声明，以及整数除法与浮点除法的区别。',
  ),
  DartLesson(
    id: 'dart-lesson-003',
    chapter: 'basics',
    level: 'beginner',
    title: '字符串插值',
    summary: '用 \$ 把变量和表达式嵌进字符串，写多行字符串。',
    concepts: <String>['字符串插值', '多行字符串', 'length'],
    explain:
        '单引号和双引号都可以表示字符串。\$变量 直接插值；\${表达式} 可以插入更复'
        '杂的表达式，例如运算或方法调用。三个引号包裹的是多行字符串，会原样保留'
        '换行。字符串的 length 是字符个数，对中文同样按字符计。',
    objective: '会用插值拼接文本，并计算字符串长度。',
    pitfalls: <String>[
      '在插值里写复数表达式时忘了花括号，例如写成 \$a + b 会得到「a 的值再拼上 + b」。',
      '多行字符串首行若不是紧跟三引号，前面会多出一行空行。',
    ],
    code:
        "void main() {\n"
        "  const name = '小明';\n"
        "  const score = 88;\n"
        "\n"
        "  print('\$name 考了 \$score 分');\n"
        "  print('\${name}的平均分是 \${(score + 92) / 2}');\n"
        "  print('名字长度：\${name.length}');\n"
        "\n"
        "  const poem = '''第一行\n第二行''';\n"
        "  print(poem);\n"
        "}\n",
    output: '小明 考了 88 分\n小明的平均分是 90.0\n名字长度：2\n第一行\n第二行\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '打印「商品：苹果 单价 5.5 数量 3 合计 16.5」。',
        hint: '合计用 \${price * count} 直接算。',
        answer:
            "const price = 5.5;\n"
            "const count = 3;\n"
            "print('商品：苹果 单价 \$price 数量 \$count 合计 \${price * count}');",
      ),
    ],
    exampleTitle: '示例 003：字符串插值',
    exampleSummary: '变量插值、表达式插值和多行字符串的实际写法。',
  ),
  DartLesson(
    id: 'dart-lesson-004',
    chapter: 'basics',
    level: 'beginner',
    title: '运算符与优先级',
    summary: '算术、比较、逻辑运算符，以及括号改变求值顺序。',
    concepts: <String>['算术运算符', '比较运算符', '逻辑运算符', '优先级'],
    explain:
        '算术运算符有 + - * / ~/ %，比较运算符返回 bool，逻辑运算用 && || !。'
        '乘除和取余的优先级高于加减，比较又低一层，逻辑运算最低。'
        '不确定顺序时就用括号，既避免出错也让代码更好读。',
    objective: '能正确组合运算符并用括号控制求值顺序。',
    pitfalls: <String>[
      '逻辑运算没有短路预期待：&& 和 || 本身就短路，但把赋值写进条件容易出错。',
      '把 == 误写成 =，在 Dart 里是编译错误，能及早发现。',
    ],
    code:
        "void main() {\n"
        "  const a = 7;\n"
        "  const b = 2;\n"
        "  print(a + b);\n"
        "  print(a - b);\n"
        "  print(a * b);\n"
        "  print(a / b);\n"
        "  print(a ~/ b);\n"
        "  print(a % b);\n"
        "  print((a + b) * 2);\n"
        "  print(a > b && b > 0);\n"
        "  print(a < b || a == 7);\n"
        "  print(!(a == b));\n"
        "}\n",
    output: '9\n5\n14\n3.5\n3\n1\n18\ntrue\ntrue\ntrue\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '判断 2024 是否闰年并打印结果。',
        hint: '闰年：能被 4 整除且不能被 100 整除，或能被 400 整除。',
        answer:
            "const year = 2024;\n"
            "final leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);\n"
            "print('\$year 是闰年：\$leap');",
      ),
    ],
    exampleTitle: '示例 004：运算符与优先级',
    exampleSummary: '七种算术结果、比较结果与括号改变优先级的演示。',
  ),
  DartLesson(
    id: 'dart-lesson-005',
    chapter: 'basics',
    level: 'beginner',
    title: '类型转换',
    summary: '字符串转数字、数字转字符串，以及安全的解析方式。',
    concepts: <String>['int.parse', 'double.parse', 'toString', 'tryParse'],
    explain:
        '从文本读到的数字要先解析：int.parse 和 double.parse 能转成功，遇到非数字'
        '会抛异常；tryParse 转失败返回 null 更安全。数字转字符串用 toString，'
        '格式化小数用 toStringAsFixed。',
    objective: '会在字符串与数字之间安全转换，并格式化小数。',
    pitfalls: <String>[
      '对可能非法的输入直接用 int.parse，程序会因异常中断，优先用 tryParse。',
      'double.parse(\'3\') 可以成功，但 int.parse(\'3.0\') 会失败，整数解析不接受小数点。',
    ],
    code:
        "void main() {\n"
        "  const text = '42';\n"
        "  final number = int.parse(text);\n"
        "  print(number + 1);\n"
        "\n"
        "  const price = '19.9';\n"
        "  print(double.parse(price) * 2);\n"
        "\n"
        "  print((1 / 3).toStringAsFixed(3));\n"
        "  print(255.toString());\n"
        "\n"
        "  final bad = int.tryParse('abc');\n"
        "  print(bad == null ? '解析失败' : bad);\n"
        "}\n",
    output: '43\n39.8\n0.333\n255\n解析失败\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '把字符串 \'3.14159\' 转成 double，保留两位小数打印。',
        hint: '先 double.parse，再 toStringAsFixed(2)。',
        answer:
            "final value = double.parse('3.14159');\nprint(value.toStringAsFixed(2));",
      ),
    ],
    exampleTitle: '示例 005：类型转换',
    exampleSummary: '字符串与数字互转、小数格式化与安全解析。',
  ),
  DartLesson(
    id: 'dart-lesson-006',
    chapter: 'basics',
    level: 'beginner',
    title: '常量与命名规范',
    summary: '下划线开头、camelCase、常量的写法与命名习惯。',
    concepts: <String>['命名规范', 'camelCase', '常量', '顶层常量'],
    explain:
        'Dart 的变量和方法用小驼峰（lowerCamelCase），类名用大驼峰（UpperCamelCase），'
        '常量习惯全小写加下划线。顶层 const 可以放在 main 外面共享。符合规范的命名'
        '让分析器不再报 lint，也让协作者一眼分清资源类型。',
    objective: '能按 Dart 惯例给变量、类和常量命名。',
    pitfalls: <String>[
      '把变量写成 studentName 之外的大写或下划线风格，会触发 lint 警告。',
      '把常量定义在函数内部却想被外部引用，作用域不允许，应提到顶层。',
    ],
    code:
        "const double taxRate = 0.06;\n"
        "const String appName = 'QFLIDartWing';\n"
        "\n"
        "class OrderItem {\n"
        "  const OrderItem(this.name, this.price);\n"
        "  final String name;\n"
        "  final double price;\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  const item = OrderItem('键盘', 199.0);\n"
        "  final total = item.price * (1 + taxRate);\n"
        "  print('应用：\$appName');\n"
        "  print('商品：\${item.name}');\n"
        "  print('含税：\${total.toStringAsFixed(2)}');\n"
        "}\n",
    output: '应用：QFLIDartWing\n商品：键盘\n含税：210.94\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '定义一个顶层常量 maxScore = 100，并在 main 里用它计算百分比。',
        hint: '百分比 = 得分 / maxScore * 100。',
        answer:
            "const maxScore = 100;\n"
            "void main() {\n"
            "  print(85 / maxScore * 100);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 006：常量与命名规范',
    exampleSummary: '顶层常量、类名大驼峰、变量小驼峰的规范写法。',
  ),
  DartLesson(
    id: 'dart-lesson-007',
    chapter: 'basics',
    level: 'beginner',
    title: '注释与文档注释',
    summary: '行注释、块注释与 /// 文档注释的用途。',
    concepts: <String>['注释', '文档注释', '可读性'],
    explain:
        '// 写单行注释，/* */ 写块注释，/// 写文档注释。文档注释会被分析工具收集，'
        '可以给类和方法加上说明。注释应该解释「为什么」，而不是重复代码在做什么。',
    objective: '会使用三种注释，并给公开 API 写文档注释。',
    pitfalls: <String>[
      '用注释把过期代码注释掉而不是删除，容易误导后来者。',
      '文档注释写成语法错误的 Markdown 方括号，会导致 dart doc 报警告。',
    ],
    code:
        "// 这是一个单行注释。\n"
        "/* 这是一个\n   块注释。 */\n"
        "\n"
        "/// 把整数转成带单位的字符串。\n"
        "///\n"
        "/// 传入 [bytes] 表示字节数，返回可读文本。\n"
        "String formatBytes(int bytes) {\n"
        "  if (bytes < 1024) return '\$bytes B';\n"
        "  return '\${(bytes / 1024).toStringAsFixed(1)} KB';\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  print(formatBytes(512));\n"
        "  print(formatBytes(2048));\n"
        "}\n",
    output: '512 B\n2.0 KB\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '给上面 formatBytes 增加 MB 分支（>= 1024*1024）。',
        hint: '再加一个 if，返回除以 1024*1024 的结果。',
        answer:
            "if (bytes < 1024 * 1024) return '\${(bytes / 1024).toStringAsFixed(1)} KB';\n"
            "return '\${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';",
      ),
    ],
    exampleTitle: '示例 007：注释与文档注释',
    exampleSummary: '单行、块注释与带方括号引用的文档注释。',
  ),
  DartLesson(
    id: 'dart-lesson-008',
    chapter: 'basics',
    level: 'beginner',
    title: '常量表达式与编译期计算',
    summary: 'const 构造、常量列表与编译期就能算出的值。',
    concepts: <String>['const 构造', 'const 列表', '编译期常量'],
    explain:
        '只要表达式里的所有值都是编译期常量，就能用 const 整体声明，包括 const 列表、'
        'const 映射和带 const 构造的对象。编译期常量不会在运行时重复创建，能让程序'
        '更轻也更快。',
    objective: '会用 const 声明常量集合与常量对象。',
    pitfalls: <String>[
      'const 列表不可修改，add 会抛异常；需要可变集合应使用 final 加 []。',
      'const 构造要求所有字段都是 final。',
    ],
    code:
        "const weekdays = ['周一', '周二', '周三'];\n"
        "const scores = {'math': 90, 'english': 85};\n"
        "\n"
        "class Point {\n"
        "  const Point(this.x, this.y);\n"
        "  final int x;\n"
        "  final int y;\n"
        "  int get sum => x + y;\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  print(weekdays.length);\n"
        "  print(weekdays[0]);\n"
        "  print(scores['math']);\n"
        "  const origin = Point(2, 3);\n"
        "  print(origin.sum);\n"
        "}\n",
    output: '3\n周一\n90\n5\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用 const 列表存三天温度，打印最大值。',
        hint: 'const 列表可用 reduce 或直接比较。',
        answer:
            "const temps = [21, 25, 19];\n"
            "print(temps.reduce((a, b) => a > b ? a : b));",
      ),
    ],
    exampleTitle: '示例 008：常量表达式',
    exampleSummary: 'const 列表、const 映射与 const 构造对象。',
  ),
  DartLesson(
    id: 'dart-lesson-009',
    chapter: 'basics',
    level: 'beginner',
    title: '字符串常用方法',
    summary: '大小写、包含、分割、替换与去空白。',
    concepts: <String>[
      'toUpperCase',
      'contains',
      'split',
      'replaceAll',
      'trim',
    ],
    explain:
        '字符串有一批常用方法：toUpperCase/toLowerCase 改大小写，contains 判断包含，'
        'startsWith/endsWith 判断首尾，split 拆分成列表，replaceAll 替换，trim 去掉'
        '首尾空白。字符串是不可变的，这些方法都返回新字符串。',
    objective: '会用常用字符串方法处理文本。',
    pitfalls: <String>[
      '误以为 replaceAll 会改原字符串；它返回新值，需重新赋值。',
      'split 传空字符串会按每个字符拆分，传逗号等分隔符才是按段拆分。',
    ],
    code:
        "void main() {\n"
        "  const raw = '  Dart Language  ';\n"
        "  final trimmed = raw.trim();\n"
        "  print(trimmed);\n"
        "  print(trimmed.toUpperCase());\n"
        "  print(trimmed.toLowerCase());\n"
        "  print(trimmed.contains('Lang'));\n"
        "  print(trimmed.startsWith('Dart'));\n"
        "\n"
        "  const csv = 'apple,banana,cherry';\n"
        "  final parts = csv.split(',');\n"
        "  print(parts);\n"
        "  print(csv.replaceAll(',', ' | '));\n"
        "}\n",
    output:
        'Dart Language\nDART LANGUAGE\ndart language\ntrue\ntrue\n'
        '[apple, banana, cherry]\napple | banana | cherry\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '把 \'a-b-c\' 拆开再用 + 重新拼成 \'a+b+c\'。',
        hint: 'split(\'-\') 后用 join(\'+\')。',
        answer: "print('a-b-c'.split('-').join('+'));",
      ),
    ],
    exampleTitle: '示例 009：字符串常用方法',
    exampleSummary: '去空白、大小写、查找、拆分与替换的实战。',
  ),
  DartLesson(
    id: 'dart-lesson-010',
    chapter: 'basics',
    level: 'beginner',
    title: '综合练习：个人信息卡片',
    summary: '把变量、插值、类型转换与字符串方法串成一个小程序。',
    concepts: <String>['综合运用', '插值', '类型转换', '字符串方法'],
    explain:
        '这一课把前面学的变量、字符串插值、类型转换和字符串方法组合起来：接收一段'
        '原始文本，解析成结构化信息，再格式化输出。综合练习的目的不是引入新语法，'
        '而是把分散的知识点连成可用的流程。',
    objective: '能把多种基础语法组合成完整的小程序。',
    pitfalls: <String>['解析固定格式文本时没有处理多余空格，应先用 trim。', '拼接时忘记转义引号导致语法错误。'],
    code:
        "void main() {\n"
        "  const raw = '小明,20,杭州';\n"
        "  final parts = raw.split(',');\n"
        "  final name = parts[0].trim();\n"
        "  final age = int.parse(parts[1].trim());\n"
        "  final city = parts[2].trim();\n"
        "\n"
        "  print('姓名：\$name');\n"
        "  print('年龄：\$age（\${age >= 18 ? '成年' : '未成年'}）');\n"
        "  print('城市：\$city');\n"
        "  print('卡片长度：\${name.length + city.length} 字');\n"
        "}\n",
    output: '姓名：小明\n年龄：20（成年）\n城市：杭州\n卡片长度：4 字\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '对 \'  小红 , 18 , 上海  \' 做同样处理，验证 trim 生效。',
        hint: '先整体 trim，再逐段 trim。',
        answer:
            "final raw = '  小红 , 18 , 上海  '.trim();\n"
            "final parts = raw.split(',').map((s) => s.trim()).toList();\n"
            "print('\${parts[0]} \${parts[1]} \${parts[2]}');",
      ),
    ],
    exampleTitle: '示例 010：综合练习：个人信息卡片',
    exampleSummary: '把一段 CSV 文本解析成结构化的个人信息卡片。',
  ),
];
