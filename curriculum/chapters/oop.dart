import '../dart_lesson.dart';

/// Chapter `oop` — lessons 035-046. Owned by the first pi.
const List<DartLesson> oopLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-035',
    chapter: 'oop',
    level: 'intermediate',
    title: '类与对象',
    summary: '用类描述数据和行为的组合，创建对象。',
    concepts: <String>['class', '对象', '字段', '方法'],
    explain:
        '类把数据（字段）和行为（方法）封装在一起。用类名()创建对象，也叫实例。'
        '字段描述状态，方法描述能做什么。toString 决定对象被 print 时显示成什么样。',
    objective: '会定义类、创建对象并调用其方法。',
    pitfalls: <String>[
      '忘记给字段写类型会隐式变成 dynamic，应显式声明类型。',
      '修改对象的字段不需要重新创建对象，但要清楚这会改变共享状态。',
    ],
    code:
        "class Student {\n"
        "  String name;\n"
        "  int score;\n"
        "\n"
        "  Student(this.name, this.score);\n"
        "\n"
        "  bool isPass() => score >= 60;\n"
        "\n"
        "  @override\n"
        "  String toString() => '\$name：\$score 分';\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final s = Student('小明', 58);\n"
        "  print(s);\n"
        "  print('及格？\${s.isPass()}');\n"
        "}\n",
    output: '小明：58 分\n及格？false\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '定义一个 Point 类含 x, y 字段，方法 sum 返回两者之和。',
        hint: '构造用 Point(this.x, this.y)。',
        answer:
            "class Point {\n"
            "  Point(this.x, this.y);\n"
            "  final int x;\n"
            "  final int y;\n"
            "  int get sum => x + y;\n"
            "}\nprint(Point(2, 3).sum);",
      ),
    ],
    exampleTitle: '示例 035：类与对象',
    exampleSummary: '定义类、创建对象、调用方法并自定义 toString。',
  ),
  DartLesson(
    id: 'dart-lesson-036',
    chapter: 'oop',
    level: 'intermediate',
    title: '构造方法与 this',
    summary: '用 this 简写构造参数，区分字段与参数。',
    concepts: <String>['构造方法', 'this', '初始化列表'],
    explain:
        '构造方法 Student(this.name) 把参数自动赋给同名字段，省掉 this.x = x。'
        '当参数名与字段名不同时，用初始化列表 : field = param 赋值。构造函数不能'
        '有返回值类型。',
    objective: '会用 this 简写构造，并在需要时用初始化列表。',
    pitfalls: <String>['初始化列表在构造体之前执行，不能访问 this。', '多个构造方法用命名构造区分，名字不能重复。'],
    code:
        "class Temperature {\n"
        "  Temperature.celsius(this.celsius);\n"
        "  Temperature.fahrenheit(double fahrenheit) : celsius = (fahrenheit - 32) * 5 / 9;\n"
        "\n"
        "  final double celsius;\n"
        "\n"
        "  double get fahrenheit => celsius * 9 / 5 + 32;\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final a = Temperature.celsius(25);\n"
        "  print(a.fahrenheit.toStringAsFixed(1));\n"
        "  final b = Temperature.fahrenheit(77);\n"
        "  print(b.celsius.toStringAsFixed(1));\n"
        "}\n",
    output: '77.0\n25.0\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '给 Temperature 加一个命名构造 fromKelvin(k)，celsius = k - 273.15。',
        hint: '命名构造 + 初始化列表。',
        answer: "Temperature.fromKelvin(double k) : celsius = k - 273.15;",
      ),
    ],
    exampleTitle: '示例 036：构造方法与 this',
    exampleSummary: 'this 简写构造与带初始化列表的命名构造。',
  ),
  DartLesson(
    id: 'dart-lesson-037',
    chapter: 'oop',
    level: 'intermediate',
    title: '封装与 getter/setter',
    summary: '用私有字段和访问器保护内部状态。',
    concepts: <String>['封装', '私有字段', 'getter', 'setter'],
    explain:
        '下划线开头的成员是库私有的。把字段设为私有，用 getter 只读暴露、用 setter '
        '在赋值时校验，就能保护内部状态不被随意破坏。getter/setter 看起来像字段，'
        '但内部可以加逻辑。',
    objective: '会用私有字段加 getter/setter 实现受控访问。',
    pitfalls: <String>[
      '下划线私有是「库级」而非「类级」，同文件其他类仍可访问。',
      'setter 里做校验失败时应抛异常或忽略，不要静默写入非法值。',
    ],
    code:
        "class BankAccount {\n"
        "  double _balance = 0;\n"
        "\n"
        "  double get balance => _balance;\n"
        "\n"
        "  set balance(double value) {\n"
        "    if (value < 0) {\n"
        "      throw ArgumentError('余额不能为负');\n"
        "    }\n"
        "    _balance = value;\n"
        "  }\n"
        "\n"
        "  void deposit(double amount) {\n"
        "    if (amount <= 0) throw ArgumentError('存款必须为正');\n"
        "    _balance += amount;\n"
        "  }\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final account = BankAccount()..deposit(100);\n"
        "  print(account.balance);\n"
        "  account.balance = 250;\n"
        "  print(account.balance);\n"
        "}\n",
    output: '100.0\n250.0\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '给 BankAccount 加 withdraw(amount)，余额不足时抛异常。',
        hint: '先用 _balance 判断再减法。',
        answer:
            "void withdraw(double amount) {\n"
            "  if (amount > _balance) throw ArgumentError('余额不足');\n"
            "  _balance -= amount;\n"
            "}",
      ),
    ],
    exampleTitle: '示例 037：封装与 getter/setter',
    exampleSummary: '私有余额字段与带校验的 getter/setter。',
  ),
  DartLesson(
    id: 'dart-lesson-038',
    chapter: 'oop',
    level: 'intermediate',
    title: '静态成员',
    summary: '用 static 表示属于类而非实例的字段和方法。',
    concepts: <String>['static', '类变量', '静态方法', '工厂构造概念'],
    explain:
        'static 字段在类上共享一份，不随实例增加。static 方法不依赖实例，用类名直接'
        '调用。常见用法是计数器、常量表和工具方法。静态成员不能访问实例成员。',
    objective: '会用 static 字段做计数，用 static 方法写工具函数。',
    pitfalls: <String>[
      '在 static 方法里访问实例字段会编译报错。',
      '静态变量在程序运行期间一直存在，不要用它存会话级临时数据。',
    ],
    code:
        "class Counter {\n"
        "  static int total = 0;\n"
        "  final String label;\n"
        "\n"
        "  Counter(this.label) {\n"
        "    total++;\n"
        "  }\n"
        "\n"
        "  static String describe() => '共创建了 \$total 个计数器';\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  Counter('a');\n"
        "  Counter('b');\n"
        "  Counter('c');\n"
        "  print(Counter.total);\n"
        "  print(Counter.describe());\n"
        "}\n",
    output: '3\n共创建了 3 个计数器\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '给类加静态常量 pi 与静态方法 circleArea(r)。',
        hint: 'static const pi = 3.14159。',
        answer:
            "class Circle {\n"
            "  static const pi = 3.14159;\n"
            "  static double area(double r) => pi * r * r;\n"
            "}\nprint(Circle.area(2).toStringAsFixed(3));",
      ),
    ],
    exampleTitle: '示例 038：静态成员',
    exampleSummary: 'static 计数器和 static 工厂/工具方法。',
  ),
  DartLesson(
    id: 'dart-lesson-039',
    chapter: 'oop',
    level: 'intermediate',
    title: '继承与 super',
    summary: '用 extends 继承父类，用 super 调用父类构造和方法。',
    concepts: <String>['继承', 'extends', 'super', '方法覆盖'],
    explain:
        '子类用 extends 继承父类的字段和方法。子类构造通过 super(...) 把参数传给'
        '父类构造。子类可以覆盖父类方法（加 @override）改变行为，也能用 super.method() '
        '在覆盖中复用父类实现。',
    objective: '会写继承层次，用 super 复用父类构造与行为。',
    pitfalls: <String>[
      '覆盖方法时签名必须兼容，参数和返回类型不能随意改。',
      '父类构造有必填参数时，子类必须通过 super 传入。',
    ],
    code:
        "class Animal {\n"
        "  Animal(this.name);\n"
        "  final String name;\n"
        "  String speak() => '...';\n"
        "}\n"
        "\n"
        "class Dog extends Animal {\n"
        "  Dog(super.name);\n"
        "\n"
        "  @override\n"
        "  String speak() => '\$name 说：汪汪';\n"
        "}\n"
        "\n"
        "class Puppy extends Dog {\n"
        "  Puppy(super.name);\n"
        "\n"
        "  @override\n"
        "  String speak() => '\${super.speak()}（奶声奶气）';\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  print(Dog('旺财').speak());\n"
        "  print(Puppy('小旺').speak());\n"
        "}\n",
    output: '旺财 说：汪汪\n小旺 说：汪汪（奶声奶气）\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '定义 Cat extends Animal 并覆盖 speak 返回「喵」。',
        hint: '用 super.name。',
        answer:
            "class Cat extends Animal {\n"
            "  Cat(super.name);\n"
            "  @override\n"
            "  String speak() => '\$name 说：喵';\n"
            "}",
      ),
    ],
    exampleTitle: '示例 039：继承与 super',
    exampleSummary: 'extends 继承、super 调用与 @override 覆盖。',
  ),
  DartLesson(
    id: 'dart-lesson-040',
    chapter: 'oop',
    level: 'intermediate',
    title: '抽象类',
    summary: '用 abstract 定义不能实例化、强制子类实现的基类。',
    concepts: <String>['abstract', '抽象方法', '模板方法'],
    explain:
        '抽象类用 abstract 声明，不能直接 new，供子类继承。抽象方法只有签名没有实现，'
        '子类必须实现。抽象类常用来定义「模板」：把公共流程写好，把变化的部分留给'
        '子类实现。',
    objective: '会写抽象类并在子类中实现抽象方法。',
    pitfalls: <String>['试图直接实例化抽象类会编译报错。', '子类未实现全部抽象方法也会编译报错。'],
    code:
        "abstract class Shape {\n"
        "  double area();\n"
        "\n"
        "  String describe() => '面积是 \${area().toStringAsFixed(2)}';\n"
        "}\n"
        "\n"
        "class Circle extends Shape {\n"
        "  Circle(this.radius);\n"
        "  final double radius;\n"
        "\n"
        "  @override\n"
        "  double area() => 3.14159 * radius * radius;\n"
        "}\n"
        "\n"
        "class Square extends Shape {\n"
        "  Square(this.side);\n"
        "  final double side;\n"
        "\n"
        "  @override\n"
        "  double area() => side * side;\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  for (final shape in [Circle(2), Square(3)]) {\n"
        "    print(shape.describe());\n"
        "  }\n"
        "}\n",
    output: '面积是 12.57\n面积是 9.00\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '加一个 Triangle 子类，面积 = 底 * 高 / 2。',
        hint: '继承 Shape 并实现 area。',
        answer:
            "class Triangle extends Shape {\n"
            "  Triangle(this.base, this.height);\n"
            "  final double base;\n"
            "  final double height;\n"
            "  @override\n"
            "  double area() => base * height / 2;\n"
            "}",
      ),
    ],
    exampleTitle: '示例 040：抽象类',
    exampleSummary: 'abstract 基类定义模板，子类实现具体面积。',
  ),
  DartLesson(
    id: 'dart-lesson-041',
    chapter: 'oop',
    level: 'intermediate',
    title: '接口与 implements',
    summary: '用接口定义能力契约，类通过 implements 承诺实现。',
    concepts: <String>['接口', 'implements', '契约'],
    explain:
        'Dart 里任何类都能当作接口。用 implements 表示「我承诺实现这些方法」，与'
        '继承不同，implements 不继承实现，必须自己写全部成员。用 abstract class 或 '
        'abstract interface class 定义纯契约更清晰。',
    objective: '会用接口定义契约并让多个类实现。',
    pitfalls: <String>[
      'implements 一个具体类时必须实现它的所有方法，包括 getter/setter。',
      '一个类可以 implements 多个接口，用逗号分隔。',
    ],
    code:
        "abstract interface class Printable {\n"
        "  String pretty();\n"
        "}\n"
        "\n"
        "class Money implements Printable {\n"
        "  Money(this.amount);\n"
        "  final double amount;\n"
        "\n"
        "  @override\n"
        "  String pretty() => '￥\${amount.toStringAsFixed(2)}';\n"
        "}\n"
        "\n"
        "class Percent implements Printable {\n"
        "  Percent(this.value);\n"
        "  final int value;\n"
        "\n"
        "  @override\n"
        "  String pretty() => '\$value%';\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final items = <Printable>[Money(12.5), Percent(80)];\n"
        "  for (final item in items) {\n"
        "    print(item.pretty());\n"
        "  }\n"
        "}\n",
    output: '￥12.50\n80%\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '定义接口 Greeter { String greet(); } 并让两个类实现。',
        hint: 'implements Greeter。',
        answer:
            "abstract interface class Greeter { String greet(); }\n"
            "class En implements Greeter { @override String greet() => 'Hello'; }\n"
            "class Zh implements Greeter { @override String greet() => '你好'; }",
      ),
    ],
    exampleTitle: '示例 041：接口与 implements',
    exampleSummary: '接口作为契约，多种类型统一通过接口使用。',
  ),
  DartLesson(
    id: 'dart-lesson-042',
    chapter: 'oop',
    level: 'intermediate',
    title: 'mixin 复用行为',
    summary: '用 mixin 把可复用行为混入多个类。',
    concepts: <String>['mixin', 'with', '代码复用'],
    explain:
        'mixin 是一组可复用的方法集合，用 with 混入类。它解决了「多个不相关的类需要'
        '同一段行为」的问题，避免复制粘贴，也避免为了复用而强行继承。mixin 不能有'
        '构造方法。',
    objective: '会用 mixin 给多个类添加共享行为。',
    pitfalls: <String>[
      'mixin 里引用 this 上的成员时，要确保混入的类确实提供了这些成员。',
      '同名方法冲突时，后混入的或类自身的实现优先。',
    ],
    code:
        "mixin Swimmer {\n"
        "  String swim() => '\$name 在游泳';\n"
        "  String get name;\n"
        "}\n"
        "\n"
        "mixin Flyer {\n"
        "  String fly() => '\$name 在飞行';\n"
        "  String get name;\n"
        "}\n"
        "\n"
        "class Duck with Swimmer, Flyer {\n"
        "  Duck(this.name);\n"
        "\n"
        "  @override\n"
        "  final String name;\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final duck = Duck('唐老鸭');\n"
        "  print(duck.swim());\n"
        "  print(duck.fly());\n"
        "}\n",
    output: '唐老鸭 在游泳\n唐老鸭 在飞行\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '定义 mixin Walker 加 walk()，让 Duck 也具备走路能力。',
        hint: 'with Swimmer, Flyer, Walker。',
        answer:
            "mixin Walker {\n"
            "  String get name;\n"
            "  String walk() => '\$name 在走路';\n"
            "}",
      ),
    ],
    exampleTitle: '示例 042：mixin 复用行为',
    exampleSummary: '用 with 混入多个 mixin，让一个类具备多种行为。',
  ),
  DartLesson(
    id: 'dart-lesson-043',
    chapter: 'oop',
    level: 'intermediate',
    title: '多态与向上转型',
    summary: '父类引用指向子类对象，运行时选择实际实现。',
    concepts: <String>['多态', '向上转型', '运行时绑定'],
    explain:
        '把子类对象赋给父类类型的变量叫向上转型。调用被覆盖的方法时，实际执行的是'
        '子类版本，这叫运行时多态。多态让我们面向父类编程，把不同子类统一处理，'
        '新增子类时无需修改调用代码。',
    objective: '会用父类类型容纳不同子类并统一调用。',
    pitfalls: <String>[
      '向上转型后只能访问父类声明的成员，子类独有方法需要向下转型。',
      '用 is 判断类型比强行 as 更安全。',
    ],
    code:
        "class Notification {\n"
        "  String render() => '通知';\n"
        "}\n"
        "\n"
        "class Email extends Notification {\n"
        "  @override\n"
        "  String render() => '邮件通知';\n"
        "}\n"
        "\n"
        "class Sms extends Notification {\n"
        "  @override\n"
        "  String render() => '短信通知';\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final List<Notification> list = [Email(), Sms(), Notification()];\n"
        "  for (final n in list) {\n"
        "    print(n.render());\n"
        "  }\n"
        "}\n",
    output: '邮件通知\n短信通知\n通知\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '加一个 Push extends Notification 覆盖 render 返回「推送通知」。',
        hint: '放进列表即可统一处理。',
        answer:
            "class Push extends Notification {\n"
            "  @override\n"
            "  String render() => '推送通知';\n"
            "}",
      ),
    ],
    exampleTitle: '示例 043：多态与向上转型',
    exampleSummary: '父类类型列表统一调用被覆盖的方法。',
  ),
  DartLesson(
    id: 'dart-lesson-044',
    chapter: 'oop',
    level: 'intermediate',
    title: '运算符重载',
    summary: '用 operator 关键字让自定义类型支持 +、== 等运算。',
    concepts: <String>['operator', '==', 'hashCode', '比较'],
    explain:
        '用 operator 关键字可以重载算术和比较运算符。重载 == 时必须同步重写 hashCode，'
        '否则相同内容的对象在 Set/Map 里表现异常。相等应满足自反、对称、传递。',
    objective: '会为值类型重载 == 和 hashCode，并可重载算术运算符。',
    pitfalls: <String>[
      '只重写 == 不重写 hashCode，会让对象在哈希集合里查不到。',
      '在 == 中比较可变字段会让对象放进 Set 后行为不稳定。',
    ],
    code:
        "class Vec {\n"
        "  const Vec(this.x, this.y);\n"
        "  final int x;\n"
        "  final int y;\n"
        "\n"
        "  Vec operator +(Vec other) => Vec(x + other.x, y + other.y);\n"
        "\n"
        "  @override\n"
        "  bool operator ==(Object other) =>\n"
        "      other is Vec && other.x == x && other.y == y;\n"
        "\n"
        "  @override\n"
        "  int get hashCode => Object.hash(x, y);\n"
        "\n"
        "  @override\n"
        "  String toString() => '(\$x, \$y)';\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final a = const Vec(1, 2);\n"
        "  final b = const Vec(3, 4);\n"
        "  print(a + b);\n"
        "  print(a == const Vec(1, 2));\n"
        "  print({a, const Vec(1, 2)}.length);\n"
        "}\n",
    output: '(4, 6)\ntrue\n1\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '给 Vec 重载 - 运算符。',
        hint: 'operator -(Vec other) => Vec(x - other.x, y - other.y);',
        answer: "Vec operator -(Vec other) => Vec(x - other.x, y - other.y);",
      ),
    ],
    exampleTitle: '示例 044：运算符重载',
    exampleSummary: '重载 +、== 与 hashCode，让值对象正确去重。',
  ),
  DartLesson(
    id: 'dart-lesson-045',
    chapter: 'oop',
    level: 'intermediate',
    title: '枚举进阶',
    summary: '用 enum 表达固定选项，并携带字段与方法。',
    concepts: <String>['enum', '增强枚举', '字段', '方法'],
    explain:
        '枚举表示一组固定取值。Dart 的增强枚举可以带字段和构造方法，把「选项 + 附加'
        '信息」封在一起。values 拿到全部取值，name 是名字，index 是序号。',
    objective: '会定义带字段和方法的增强枚举并按需使用。',
    pitfalls: <String>[
      '枚举的构造是 const，字段必须是 final。',
      '用 index 做持久化存储很脆弱，枚举顺序一变数据就错，建议存 name。',
    ],
    code:
        "enum Priority {\n"
        "  low(1, '低'),\n"
        "  medium(2, '中'),\n"
        "  high(3, '高');\n"
        "\n"
        "  const Priority(this.level, this.label);\n"
        "  final int level;\n"
        "  final String label;\n"
        "\n"
        "  bool isUrgent() => level >= 3;\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  for (final p in Priority.values) {\n"
        "    print('\${p.name}: \${p.label} 紧急？\${p.isUrgent()}');\n"
        "  }\n"
        "  print(Priority.high.label);\n"
        "}\n",
    output: 'low: 低 紧急？false\nmedium: 中 紧急？false\nhigh: 高 紧急？true\n高\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '定义 enum Color { red, green, blue } 并打印每个名字。',
        hint: 'Color.values 加 name。',
        answer:
            "enum Color { red, green, blue }\n"
            "for (final c in Color.values) { print(c.name); }",
      ),
    ],
    exampleTitle: '示例 045：枚举进阶',
    exampleSummary: '带 level/label 字段与 isUrgent 方法的增强枚举。',
  ),
  DartLesson(
    id: 'dart-lesson-046',
    chapter: 'oop',
    level: 'intermediate',
    title: '综合练习：简易银行账户',
    summary: '把类、封装、枚举、异常组合成一个小系统。',
    concepts: <String>['综合运用', '封装', '枚举', '异常'],
    explain:
        '这一课把面向对象的知识点组合起来：用枚举表示交易类型，用类封装账户状态，'
        '用私有字段与受控方法保证不变量，用异常处理非法操作，最后打印账户流水。',
    objective: '能设计一个小型面向对象系统并保证其不变量。',
    pitfalls: <String>[
      '让外部直接修改内部列表会破坏封装，应提供受控的只读视图。',
      '业务错误用异常表达比返回 null 更清晰，但要在边界捕获。',
    ],
    code:
        "enum TxType { deposit, withdraw }\n"
        "\n"
        "class Transaction {\n"
        "  const Transaction(this.type, this.amount);\n"
        "  final TxType type;\n"
        "  final double amount;\n"
        "\n"
        "  @override\n"
        "  String toString() => '\${type.name}: \${amount.toStringAsFixed(2)}';\n"
        "}\n"
        "\n"
        "class Account {\n"
        "  double _balance = 0;\n"
        "  final List<Transaction> _history = [];\n"
        "\n"
        "  double get balance => _balance;\n"
        "  List<Transaction> get history => List.unmodifiable(_history);\n"
        "\n"
        "  void deposit(double amount) {\n"
        "    if (amount <= 0) throw ArgumentError('存款必须为正');\n"
        "    _balance += amount;\n"
        "    _history.add(Transaction(TxType.deposit, amount));\n"
        "  }\n"
        "\n"
        "  void withdraw(double amount) {\n"
        "    if (amount > _balance) throw StateError('余额不足');\n"
        "    _balance -= amount;\n"
        "    _history.add(Transaction(TxType.withdraw, amount));\n"
        "  }\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final account = Account()\n"
        "    ..deposit(100)\n"
        "    ..deposit(50)\n"
        "    ..withdraw(30);\n"
        "  for (final tx in account.history) {\n"
        "    print(tx);\n"
        "  }\n"
        "  print('余额 \${account.balance.toStringAsFixed(2)}');\n"
        "}\n",
    output: 'deposit: 100.00\ndeposit: 50.00\nwithdraw: 30.00\n余额 120.00\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '尝试取出 1000，捕获 StateError 并打印错误信息。',
        hint:
            'try { account.withdraw(1000); } on StateError catch (e) { print(e.message); }。',
        answer:
            "try {\n"
            "  account.withdraw(1000);\n"
            "} on StateError catch (e) {\n"
            "  print(e.message);\n"
            "}",
      ),
    ],
    exampleTitle: '示例 046：综合练习：简易银行账户',
    exampleSummary: '枚举、封装、不可变历史与异常组成的小系统。',
  ),
];
