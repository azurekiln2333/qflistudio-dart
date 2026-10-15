import '../dart_lesson.dart';

/// Chapter `dart3` — lessons 061-072. Owned by the second pi.
///
/// Export name: `dart3Lessons`. Keep lessons sorted by id.
///
/// Most programs here require the official Dart SDK engine. The generated
/// lesson entry appends the per-lesson engine requirement to `explain` from
/// `DartCurriculum.dartEvalVerifiedIds`; records (lesson 061) are verified to
/// run on dart_eval 0.8.5, sealed/patterns are not.
const List<DartLesson> dart3Lessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-061',
    chapter: 'dart3',
    level: 'advanced',
    title: '记录（Record）与解构',
    summary: '用一个值承载多个字段：位置记录、命名记录与解构赋值。',
    concepts: <String>['record', '位置字段 \$1', '命名字段', '解构赋值'],
    explain:
        '记录（Record）是 Dart 3 引入的轻量聚合类型：它把若干个值打包成一个整体，'
        '却不需要为此定义一个类。位置记录写成 (3, 7)，字段用 \$1、\$2 访问；'
        '命名记录写成 (x: 3, y: 7)，用 .x、.y 访问。记录最大的价值是解构：'
        'final (a, b) = point; 一行就把两个字段拆到变量里；也能写带类型注解的 (int, int)。'
        '记录是不可变的，字段在创建后就固定。记录是 Dart 3 引入的现代语法。',
    objective: '能创建位置记录与命名记录，访问字段，并用解构赋值取值。',
    prerequisites: <String>['已掌握变量与 final'],
    pitfalls: <String>[
      '位置记录只能用 \$1、\$2 访问，没有名字；命名记录才能用 .name。',
      '记录是结构类型：字段顺序和名字都是类型的一部分，(int, int) 与 (x: int, y: int) 不是同一类型。',
      '记录是 Dart 3 语法，部分旧的 dart_eval 版本支持有限；本课代码已在官方 SDK 与 dart_eval 0.8.5 上实测通过。',
    ],
    code:
        "void main() {\n"
        "  final point = (3, 7);\n"
        "  final named = (x: 3, y: 7);\n"
        "  print(point.\$1);\n"
        "  print(point.\$2);\n"
        "  print(named.x);\n"
        "  final (a, b) = point;\n"
        "  print(a + b);\n"
        "  final (int, int) typed = (1, 2);\n"
        "  print(typed.\$1 * typed.\$2);\n"
        "}\n",
    output: '3\n7\n3\n10\n2\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '创建一个命名记录 (width: 4, height: 5)，解构后打印面积。',
        hint: '用 final (width: w, height: h) = ... 解构，再相乘。',
        answer:
            "void main() {\n"
            "  final rect = (width: 4, height: 5);\n"
            "  final (width: w, height: h) = rect;\n"
            "  print(w * h);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 061：记录与解构',
    exampleSummary: '位置记录、命名记录、字段访问与解构赋值的最小示例。',
  ),
  DartLesson(
    id: 'dart-lesson-062',
    chapter: 'dart3',
    level: 'advanced',
    title: '命名记录与相等性',
    summary: '命名记录按字段名取值，并按字段逐项比较是否相等。',
    concepts: <String>['命名记录', '结构相等', 'toString 表示'],
    explain:
        '命名记录用 (name: value, ...) 构造，读起来比位置记录清楚，适合"一组有含义'
        '的返回值"。记录之间用 == 比较时，Dart 会逐字段比较：字段全部相等，两个记录就'
        '相等，这称为结构相等（structural equality）。例如 (name: \'小明\', age: 18) 与'
        '另一个同样内容的记录相等，而 age 变成 19 就不相等。toString() 会把命名记录'
        '排成 (age: 18, name: 小明) 的样子，字段按名字排序。记录是官方 SDK 特性。',
    objective: '能比较两个命名记录是否相等，并解释结构相等的含义。',
    prerequisites: <String>['已完成记录与解构一课', '官方 Dart SDK'],
    pitfalls: <String>[
      '记录相等是逐字段比较，不是比较引用；这与默认的类实例行为不同。',
      'toString 里命名记录字段按名字字母序排列，不要依赖构造时的书写顺序。',
      '记录内若有可变对象，相等性只看该对象的 ==，不递归深比较。',
    ],
    code:
        "void main() {\n"
        "  final user = (name: '小明', age: 18);\n"
        "  print(user.name);\n"
        "  print(user.age);\n"
        "  final same = (name: '小明', age: 18);\n"
        "  print(user == same);\n"
        "  final other = (name: '小明', age: 19);\n"
        "  print(user == other);\n"
        "  print(user.toString());\n"
        "}\n",
    output: '小明\n18\ntrue\nfalse\n(age: 18, name: 小明)\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '判断 (x: 1, y: 2) == (y: 2, x: 1) 的结果，并说明原因。',
        hint: '命名记录的相等性只看字段名和值，与书写顺序无关。',
        answer:
            "void main() {\n"
            "  final a = (x: 1, y: 2);\n"
            "  final b = (y: 2, x: 1);\n"
            "  print(a == b); // true，字段名与值完全一致\n"
            "}",
      ),
    ],
    exampleTitle: '示例 062：命名记录相等性',
    exampleSummary: '命名记录字段访问、结构相等与 toString 的表现。',
  ),
  DartLesson(
    id: 'dart-lesson-063',
    chapter: 'dart3',
    level: 'advanced',
    title: 'switch 模式解构',
    summary: '用 switch 表达式对记录做模式匹配，按内容分支并绑定变量。',
    concepts: <String>['switch 表达式', '元组模式', '常量模式', '通配绑定'],
    explain:
        'switch 从 Dart 3 起支持"模式"：不只是比较常量，还能拆开记录的字段。'
        '(0, 0) => ... 是常量模式，专门匹配原点；(final x, 0) 匹配第二个字段为 0 的'
        '记录，同时把第一个字段绑到 x；(final x, final y) 兜底并绑定两个字段。'
        'switch 表达式直接返回值，比传统 switch 语句更紧凑。分支从上到下匹配，'
        '第一个命中的生效。记录模式需要官方 Dart SDK。',
    objective: '能用记录模式对坐标分类，并在分支里绑定字段值。',
    prerequisites: <String>['已掌握记录与解构', '官方 Dart SDK'],
    pitfalls: <String>[
      '分支顺序决定结果：(0, 0) 必须在 (final x, 0) 之前，否则原点会被后者吃掉。',
      'final 绑定只读取值；要重新赋值需用 var 绑定，但模式里很少这么做。',
      'switch 表达式各分支的返回类型要能统一，否则编译报错。',
    ],
    code:
        "void main() {\n"
        "  for (final point in <(int, int)>[(0, 0), (1, 2), (3, 4)]) {\n"
        "    final message = switch (point) {\n"
        "      (0, 0) => '原点',\n"
        "      (final x, 0) => '在 x 轴上，x=\$x',\n"
        "      (0, final y) => '在 y 轴上，y=\$y',\n"
        "      (final x, final y) => '普通点 (\$x, \$y)',\n"
        "    };\n"
        "    print(message);\n"
        "  }\n"
        "}\n",
    output: '原点\n普通点 (1, 2)\n普通点 (3, 4)\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '对上例中的 (1, 2) 单独执行，输出会是什么？',
        hint: '它不匹配 (0,0)、(x,0)、(0,y)，落到最后一个分支。',
        answer:
            "void main() {\n"
            "  final point = (1, 2);\n"
            "  print(switch (point) {\n"
            "    (0, 0) => '原点',\n"
            "    (final x, 0) => 'x 轴',\n"
            "    (0, final y) => 'y 轴',\n"
            "    (final x, final y) => '普通点 (\$x, \$y)',\n"
            "  });\n"
            "}",
      ),
    ],
    exampleTitle: '示例 063：switch 记录模式',
    exampleSummary: '用记录模式给坐标分类，演示分支顺序与字段绑定。',
  ),
  DartLesson(
    id: 'dart-lesson-064',
    chapter: 'dart3',
    level: 'advanced',
    title: '列表模式',
    summary: '用 [] 模式匹配列表长度与元素，rest 收集剩余项。',
    concepts: <String>['列表模式', 'rest 模式', '长度匹配'],
    explain:
        '列表模式让你按"形状"匹配一个 List：[] 匹配空列表；[final only] 匹配恰好一个'
        '元素的列表并绑定它；[final first, ...final rest] 匹配至少一个元素，first 是'
        '首项，rest 是其余项组成的新列表（可能为空）。这比手动检查 length 再索引更安全，'
        '也不会越界。列表模式在匹配时会看长度，因此是非常精确的结构匹配。'
        '本课为官方 SDK 特性。',
    objective: '能用列表模式安全地拆出首项与剩余项。',
    prerequisites: <String>['已掌握 List 基础', '官方 Dart SDK'],
    pitfalls: <String>[
      '[] 只匹配空列表，不会匹配"非空但元素为空"的情况。',
      'rest 是一个新的 List，修改它不影响原列表。',
      '列表模式区分长度：[a, b] 只匹配恰好两个元素，多于两个不会命中。',
    ],
    code:
        "void main() {\n"
        "  for (final list in <List<int>>[\n"
        "    <int>[],\n"
        "    <int>[42],\n"
        "    <int>[1, 2, 3, 4],\n"
        "  ]) {\n"
        "    final label = switch (list) {\n"
        "      [] => '空列表',\n"
        "      [final only] => '只有一个元素：\$only',\n"
        "      [final first, ...final rest] => '首项 \$first，其余 \${rest.length} 个',\n"
        "    };\n"
        "    print(label);\n"
        "  }\n"
        "}\n",
    output: '空列表\n只有一个元素：42\n首项 1，其余 3 个\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '写一个函数，用列表模式返回列表的前两个元素之和（不足两个返回 0）。',
        hint: '用 [final a, final b, ...] 匹配并计算。',
        answer:
            "int firstTwoSum(List<int> xs) => switch (xs) {\n"
            "  [final a, final b, ...] => a + b,\n"
            "  _ => 0,\n"
            "};\n"
            "\n"
            "void main() => print(firstTwoSum(<int>[3, 4, 9]));",
      ),
    ],
    exampleTitle: '示例 064：列表模式',
    exampleSummary: '空列表、单元素与多元素三种形状的列表模式匹配。',
  ),
  DartLesson(
    id: 'dart-lesson-065',
    chapter: 'dart3',
    level: 'advanced',
    title: '映射模式',
    summary: '用 {…} 模式检查 Map 是否含有指定键，并绑定对应值。',
    concepts: <String>['映射模式', '键匹配', '类型模式', '缺省分支'],
    explain:
        '映射模式 {…} 用来匹配 Map 的结构：{\'name\': final String name} 要求 Map 里'
        '存在 name 键，且其值是 String，匹配时把值绑到 name。可以在一个模式里要求多个键：'
        '{\'name\': final String name, \'age\': final int age} 要求两个键都存在且类型正确。'
        '不满足就尝试下一个分支。整套分支用 _ 兜底最稳妥，避免出现"无匹配"的崩溃。'
        '映射模式是官方 SDK 特性。',
    objective: '能用映射模式按键存在性与类型分流处理数据。',
    prerequisites: <String>['已掌握 Map 基础', '官方 Dart SDK'],
    pitfalls: <String>[
      '映射模式默认不要求穷尽所有键，只检查你写出的键。',
      '键的类型与值的类型都要匹配：值不是 String 时该分支不会命中。',
      '缺少兜底 _ 分支时，若所有模式都不匹配，switch 会抛错。',
    ],
    code:
        "void main() {\n"
        "  final configs = <Map<String, Object?>>[\n"
        "    <String, Object?>{'name': '小明', 'age': 18},\n"
        "    <String, Object?>{'name': '小红'},\n"
        "    <String, Object?>{'age': 20},\n"
        "  ];\n"
        "  for (final config in configs) {\n"
        "    final label = switch (config) {\n"
        "      {'name': final String name, 'age': final int age} => '\$name（\$age 岁）',\n"
        "      {'name': final String name} => '\$name（年龄未知）',\n"
        "      _ => '数据不完整',\n"
        "    };\n"
        "    print(label);\n"
        "  }\n"
        "}\n",
    output: '小明（18 岁）\n小红（年龄未知）\n数据不完整\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: "为 {'score': 90} 增加一个分支，输出\"得分 90\"。",
        hint: "用 {'score': final int s} => '得分 \$s'。",
        answer:
            "void main() {\n"
            "  final data = <String, Object?>{'score': 90};\n"
            "  print(switch (data) {\n"
            "    {'score': final int s} => '得分 \$s',\n"
            "    _ => '未知',\n"
            "  });\n"
            "}",
      ),
    ],
    exampleTitle: '示例 065：映射模式',
    exampleSummary: '按 Map 的键与值类型做模式分流，并演示兜底分支。',
  ),
  DartLesson(
    id: 'dart-lesson-066',
    chapter: 'dart3',
    level: 'advanced',
    title: '对象模式',
    summary: '用 类名(getter: 模式) 直接从对象里取字段，无需手动解引用。',
    concepts: <String>['对象模式', 'getter 解构', '类型即模式'],
    explain:
        '对象模式写成 类名(属性: 模式)：它先检查对象是不是该类实例，再把你点名的 getter'
        '取出来匹配。Circle(radius: final r) 的含义是"如果是 Circle，就把 radius 取出来'
        '绑到 r"。这比自己写 if (shape is Circle) 再读 shape.radius 更紧凑，还能在同一个'
        'switch 里处理多种类型。对象模式是官方 SDK 特性。',
    objective: '能用对象模式从不同类实例中提取字段并分支处理。',
    prerequisites: <String>['已掌握类与 getter', '官方 Dart SDK'],
    pitfalls: <String>[
      '对象模式里的名字必须是该类真实存在的 getter/字段，写错名字编译报错。',
      '分支要覆盖所有可能的类型，否则需要 _ 兜底。',
      '对象模式不会调用自定义 ==，只做类型判断和字段读取。',
    ],
    code:
        "class Circle {\n"
        "  const Circle(this.radius);\n"
        "  final double radius;\n"
        "}\n"
        "\n"
        "class Square {\n"
        "  const Square(this.side);\n"
        "  final double side;\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final shapes = <Object>[const Circle(2), const Square(3)];\n"
        "  for (final shape in shapes) {\n"
        "    final text = switch (shape) {\n"
        "      Circle(radius: final r) => '圆半径 \$r',\n"
        "      Square(side: final s) => '正方形边长 \$s',\n"
        "      _ => '未知形状',\n"
        "    };\n"
        "    print(text);\n"
        "  }\n"
        "}\n",
    output: '圆半径 2.0\n正方形边长 3.0\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '新增一个 Triangle 类（有 base、height），在 switch 里输出底和高。',
        hint: '加一个 Triangle(base: final b, height: final h) => ... 分支。',
        answer:
            "class Triangle {\n"
            "  const Triangle(this.base, this.height);\n"
            "  final double base;\n"
            "  final double height;\n"
            "}\n"
            "\n"
            "void main() {\n"
            "  final shape = Triangle(6, 4);\n"
            "  print(switch (shape) {\n"
            "    Triangle(base: final b, height: final h) => '底 \$b 高 \$h',\n"
            "    _ => '未知',\n"
            "  });\n"
            "}",
      ),
    ],
    exampleTitle: '示例 066：对象模式',
    exampleSummary: '用对象模式从 Circle/Square 实例里解构字段并分流。',
  ),
  DartLesson(
    id: 'dart-lesson-067',
    chapter: 'dart3',
    level: 'advanced',
    title: 'guard 子句（when）',
    summary: '在模式后追加 when 布尔条件，只有条件成立才选中该分支。',
    concepts: <String>['guard 子句', 'when', '条件匹配'],
    explain:
        '模式负责"形状对不对"，when 负责"条件满不满足"。写成 (final int n) when n < 0'
        '表示：先匹配它是 int 并绑定 n，再用 when 判断 n < 0，成立才走这个分支。'
        'when 让模式匹配带上任意布尔逻辑，避免在分支体里再写 if。多个带 when 的分支'
        '按顺序尝试，第一个"形状与条件都成立"的生效。when 是官方 SDK 特性。',
    objective: '能用 when 给模式附加条件，实现带条件的分类。',
    prerequisites: <String>['已掌握 switch 模式', '官方 Dart SDK'],
    pitfalls: <String>[
      'when 里的表达式必须返回 bool，且通常依赖模式绑定的变量。',
      '条件分支顺序依然重要：更具体的条件要写在前面。',
      'when 不成立时不是报错，而是继续尝试下一个分支。',
    ],
    code:
        "void main() {\n"
        "  for (final value in <int>[3, 8, 15, -4]) {\n"
        "    final label = switch (value) {\n"
        "      final int n when n < 0 => '负数 \$n',\n"
        "      final int n when n.isEven => '偶数 \$n',\n"
        "      _ => '奇数 \$value',\n"
        "    };\n"
        "    print(label);\n"
        "  }\n"
        "}\n",
    output: '奇数 3\n偶数 8\n奇数 15\n负数 -4\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '为 100 以内的数增加规则：能被 5 整除的输出"5 的倍数"，优先于偶数判断。',
        hint: '把 when n % 5 == 0 的分支放在 isEven 之前。',
        answer:
            "void main() {\n"
            "  final n = 20;\n"
            "  print(switch (n) {\n"
            "    final int v when v % 5 == 0 => '5 的倍数',\n"
            "    final int v when v.isEven => '偶数',\n"
            "    _ => '其它',\n"
            "  });\n"
            "}",
      ),
    ],
    exampleTitle: '示例 067：when 守卫条件',
    exampleSummary: '在模式后追加 when 条件，按顺序命中第一个成立的分支。',
  ),
  DartLesson(
    id: 'dart-lesson-068',
    chapter: 'dart3',
    level: 'advanced',
    title: 'sealed 类与穷尽 switch',
    summary: 'sealed 限定子类集合，switch 因此可穷尽，编译器帮你查漏。',
    concepts: <String>['sealed', '穷尽性检查', '代数数据类型'],
    explain:
        'sealed 类表示"子类只能是同一库里的这些"。它带来的好处是：对 sealed 类做 switch 时，'
        '只要覆盖全部直接子类，编译器就认为你已经穷尽，不再要求 _ 兜底；反之漏掉一个子类会'
        '直接编译报错。这让"类型即状态"的建模既安全又好维护。area 函数对 Shape 做 switch，'
        'Circle 与 Rectangle 两个子类都被覆盖，所以没有默认分支。本课为官方 SDK 特性，'
        '且 dart_eval 不支持 sealed。',
    objective: '能定义 sealed 类族，并写出不需要兜底的穷尽 switch。',
    prerequisites: <String>['已掌握继承与抽象类', '官方 Dart SDK'],
    pitfalls: <String>[
      'sealed 的子类必须与父类在同一个库（同一文件或 part）中声明。',
      '新增子类后，所有穷尽 switch 会立刻编译报错——这正是它的价值，不是 bug。',
      'sealed 只约束直接子类关系，不表示实例不可变。',
    ],
    code:
        "sealed class Shape {\n"
        "  const Shape();\n"
        "}\n"
        "\n"
        "class Circle extends Shape {\n"
        "  const Circle(this.radius);\n"
        "  final double radius;\n"
        "}\n"
        "\n"
        "class Rectangle extends Shape {\n"
        "  const Rectangle(this.width, this.height);\n"
        "  final double width;\n"
        "  final double height;\n"
        "}\n"
        "\n"
        "double area(Shape shape) => switch (shape) {\n"
        "  Circle(radius: final r) => 3.14159 * r * r,\n"
        "  Rectangle(width: final w, height: final h) => w * h,\n"
        "};\n"
        "\n"
        "void main() {\n"
        "  print(area(const Circle(1)).toStringAsFixed(2));\n"
        "  print(area(const Rectangle(3, 4)));\n"
        "}\n",
    output: '3.14\n12.0\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '给 Shape 增加 Triangle 子类并补全 area，使其仍可穷尽。',
        hint: '新增 class Triangle extends Shape，并在 switch 添加对应分支。',
        answer:
            "sealed class Shape { const Shape(); }\n"
            "class Circle extends Shape {\n"
            "  const Circle(this.r); final double r;\n"
            "}\n"
            "class Triangle extends Shape {\n"
            "  const Triangle(this.b, this.h); final double b, h;\n"
            "}\n"
            "double area(Shape s) => switch (s) {\n"
            "  Circle(r: final r) => 3.14159 * r * r,\n"
            "  Triangle(b: final b, h: final h) => b * h / 2,\n"
            "};\n"
            "void main() => print(area(const Triangle(6, 4)));",
      ),
    ],
    exampleTitle: '示例 068：sealed 类穷尽匹配',
    exampleSummary: 'sealed Shape 的穷尽 switch 计算面积，无需默认分支。',
  ),
  DartLesson(
    id: 'dart-lesson-069',
    chapter: 'dart3',
    level: 'advanced',
    title: '增强 enum',
    summary: '给 enum 挂字段、构造与 getter，让每个枚举值携带数据和行为。',
    concepts: <String>['enhanced enum', '枚举构造', '枚举 getter', 'values'],
    explain:
        'Dart 3 的枚举不只是名字列表：它可以像类一样声明 final 字段、const 构造、'
        'getter 甚至方法。写法是每个枚举值后跟构造实参，例如 earth(5.97e24, 6371)。'
        '于是 Planet.values 里每一项都带着自己的质量与半径，surfaceGravity 直接算出'
        '表面重力。重写 toString 能让 print 输出更可读。增强 enum 是官方 SDK 特性。',
    objective: '能定义带字段与计算属性的增强枚举，并遍历它的所有值。',
    prerequisites: <String>['已掌握 class 与 getter', '官方 Dart SDK'],
    pitfalls: <String>[
      '枚举构造必须是 const，字段也必须是 final。',
      '枚举值之间不能互相引用构造实参以外的实例状态。',
      'enum 也不能被继承或实现（除非作为 interface 被其它类型实现）。',
    ],
    code:
        "enum Planet {\n"
        "  mercury(3.3e23, 2440),\n"
        "  earth(5.97e24, 6371),\n"
        "  mars(6.42e23, 3390);\n"
        "\n"
        "  const Planet(this.mass, this.radius);\n"
        "\n"
        "  final double mass;\n"
        "  final int radius;\n"
        "\n"
        "  double get surfaceGravity => 6.674e-11 * mass / (radius * radius * 1e6);\n"
        "\n"
        "  @override\n"
        "  String toString() => '\$name: g=\${surfaceGravity.toStringAsFixed(2)}';\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  for (final planet in Planet.values) {\n"
        "    print(planet);\n"
        "  }\n"
        "  print(Planet.values.length);\n"
        "}\n",
    output: 'mercury: g=3.70\nearth: g=9.82\nmars: g=3.73\n3\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '给 Planet 增加 moonCount 字段并在 toString 中一并打印月球数量。',
        hint: '在构造里加一个 int 参数，更新各枚举值实参与 toString。',
        answer:
            "enum Planet {\n"
            "  earth(1), mars(2);\n"
            "  const Planet(this.moonCount);\n"
            "  final int moonCount;\n"
            "  @override\n"
            "  String toString() => '\$name 有 \$moonCount 颗卫星';\n"
            "}\n"
            "void main() => print(Planet.earth);",
      ),
    ],
    exampleTitle: '示例 069：增强枚举',
    exampleSummary: '带质量与半径字段、计算 getter 与自定义 toString 的枚举。',
  ),
  DartLesson(
    id: 'dart-lesson-070',
    chapter: 'dart3',
    level: 'advanced',
    title: '类修饰符 final 与 base',
    summary: '用 final 禁止继承、用 base 要求子类继续 base/final/sealed。',
    concepts: <String>['final class', 'base class', '类修饰符'],
    explain:
        '类修饰符控制"谁能扩展谁"。final class 表示这个类不能被任何地方继承；'
        'base class 表示它可以被继承，但子类也必须声明 base、final 或 sealed。'
        '这两者把库作者的意图写进类型系统：Temperature 用 final 表明"我就该被直接使用"，'
        'Animal 用 base 允许 Dog 继承，而 Dog 自己也用 final 收口。注意这些是编译期约束，'
        '不能在运行时用代码"测试"继承禁令，本课演示的是合法用法。属于官方 SDK 特性。',
    objective: '能用 final/base 修饰符表达继承策略，并写出合法子类。',
    prerequisites: <String>['已掌握继承与 override', '官方 Dart SDK'],
    pitfalls: <String>[
      '继承 final class 会在编译期报错，不是运行时错误。',
      'base 类跨库被继承时，子类也必须标 base/final/sealed。',
      'final 类仍可实现接口（implements），只是不能被 extends。',
    ],
    code:
        "final class Temperature {\n"
        "  const Temperature(this.celsius);\n"
        "  final double celsius;\n"
        "  double get fahrenheit => celsius * 9 / 5 + 32;\n"
        "}\n"
        "\n"
        "base class Animal {\n"
        "  const Animal(this.name);\n"
        "  final String name;\n"
        "  String speak() => '\$name 发出声音';\n"
        "}\n"
        "\n"
        "final class Dog extends Animal {\n"
        "  const Dog(super.name);\n"
        "  @override\n"
        "  String speak() => '\$name 汪汪叫';\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  const t = Temperature(25);\n"
        "  print(t.fahrenheit);\n"
        "  const dog = Dog('旺财');\n"
        "  print(dog.speak());\n"
        "}\n",
    output: '77.0\n旺财 汪汪叫\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt:
            '写一个 base class Vehicle（有 brand），派生 final class Car 覆盖 describe。',
        hint: '父类标 base，子类标 final，子类用 super 传参。',
        answer:
            "base class Vehicle {\n"
            "  const Vehicle(this.brand);\n"
            "  final String brand;\n"
            "  String describe() => '车辆 \$brand';\n"
            "}\n"
            "final class Car extends Vehicle {\n"
            "  const Car(super.brand);\n"
            "  @override\n"
            "  String describe() => '汽车 \$brand';\n"
            "}\n"
            "void main() => print(const Car('BYD').describe());",
      ),
    ],
    exampleTitle: '示例 070：类修饰符',
    exampleSummary: 'final 类不可继承、base 类允许受控继承的合法用法演示。',
  ),
  DartLesson(
    id: 'dart-lesson-071',
    chapter: 'dart3',
    level: 'advanced',
    title: 'if-case 模式匹配',
    summary: '在 if 里直接用模式判断并绑定，替代一连串类型检查。',
    concepts: <String>['if-case', '类型模式', '对象模式 length', 'when'],
    explain:
        'if (value case 模式) 让你把一个模式当成条件：匹配成功就进入分支，同时把模式里'
        '绑定的变量带进作用域。例如 if (value case int n when n > 0) 只对正整数成立；'
        'if (value case String s) 对字符串成立并绑定 s；甚至能用 List(length: final len) '
        '这种对象模式读取集合长度。它比 is + 强制转换更省事，也更难写错。if-case 是'
        '官方 SDK 特性。',
    objective: '能用 if-case 对不同类型和形状的值做分流与绑定。',
    prerequisites: <String>['已掌握 switch 模式与对象模式', '官方 Dart SDK'],
    pitfalls: <String>[
      'case 里绑定的变量只在对应分支可见，出了分支就失效。',
      'when 条件不满足时会走 else，而不是报错。',
      'List(length: final len) 用的是 length getter，空列表 length 为 0。',
    ],
    code:
        "void describe(Object value) {\n"
        "  if (value case int n when n > 0) {\n"
        "    print('正整数 \$n');\n"
        "  } else if (value case String s) {\n"
        "    print('字符串 \"\$s\"，长度 \${s.length}');\n"
        "  } else if (value case List(length: final len) when len > 0) {\n"
        "    print('非空列表，长度 \$len');\n"
        "  } else {\n"
        "    print('其它：\$value');\n"
        "  }\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  describe(7);\n"
        "  describe('dart');\n"
        "  describe(<int>[1, 2, 3]);\n"
        "  describe(-1);\n"
        "}\n",
    output: '正整数 7\n字符串 "dart"，长度 4\n非空列表，长度 3\n其它：-1\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用 if-case 判断一个 num 是否为 double，是则打印它的小数部分形式。',
        hint: 'if (value case double d) 匹配 double。',
        answer:
            "void check(num value) {\n"
            "  if (value case double d) {\n"
            "    print('double: \$d');\n"
            "  } else {\n"
            "    print('int: \$value');\n"
            "  }\n"
            "}\n"
            "void main() {\n"
            "  check(3.5);\n"
            "  check(3);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 071：if-case 匹配',
    exampleSummary: '用 if-case 依次匹配正整数、字符串、非空列表与兜底。',
  ),
  DartLesson(
    id: 'dart-lesson-072',
    chapter: 'dart3',
    level: 'advanced',
    title: '模式与递归',
    summary: '用列表模式配合递归，写出简洁且不会越界的求和函数。',
    concepts: <String>['列表模式', '递归', 'rest 模式', '基准情形'],
    explain:
        '模式与递归是天生一对。sum 用三个分支描述列表的形状：[] 是空列表，返回 0（基准'
        '情形）；[final single] 只有一个元素，直接返回它；[final first, ...final rest] '
        '取出首项，把 rest 再交给 sum。因为没有索引操作，永远不会越界；分支把"形状"'
        '说清楚，递归就自然收敛。这体现了模式匹配"按结构思考"的风格。官方 SDK 特性。',
    objective: '能用列表模式写出带基准情形的递归函数。',
    prerequisites: <String>['已掌握列表模式与函数递归', '官方 Dart SDK'],
    pitfalls: <String>[
      '递归必须有基准情形（这里是 [] 与单元素分支），否则无限递归。',
      'rest 每次是新列表，递归总和复杂度是 O(n)；超长列表考虑迭代写法。',
      '分支顺序：单元素分支要在"首项 + rest"之前，逻辑才清晰。',
    ],
    code:
        "int sum(List<int> values) => switch (values) {\n"
        "  [] => 0,\n"
        "  [final single] => single,\n"
        "  [final first, ...final rest] => first + sum(rest),\n"
        "};\n"
        "\n"
        "void main() {\n"
        "  print(sum(<int>[]));\n"
        "  print(sum(<int>[5]));\n"
        "  print(sum(<int>[1, 2, 3, 4]));\n"
        "}\n",
    output: '0\n5\n10\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用列表模式写一个递归的 count，统计列表中元素个数。',
        hint: '[] 返回 0，[final _, ...final rest] 返回 1 + count(rest)。',
        answer:
            "int count(List<int> xs) => switch (xs) {\n"
            "  [] => 0,\n"
            "  [final _, ...final rest] => 1 + count(rest),\n"
            "};\n"
            "void main() => print(count(<int>[9, 8, 7]));",
      ),
    ],
    exampleTitle: '示例 072：模式与递归',
    exampleSummary: '用列表模式与递归实现对整数列表求和。',
  ),
];
