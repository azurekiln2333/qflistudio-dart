import '../dart_lesson.dart';

/// Chapter `generics` — lessons 047-054. Owned by the first pi.
const List<DartLesson> genericsLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-047',
    chapter: 'generics',
    level: 'intermediate',
    title: '泛型方法',
    summary: '用类型参数编写可复用的类型安全函数。',
    concepts: <String>['泛型方法', '类型参数', '类型安全'],
    explain:
        '泛型方法用 <T> 声明类型参数，调用时编译器会推断具体类型。泛型让同一段逻辑'
        '适用于多种类型，同时保留静态类型检查：firstOf<int>([1,2]) 返回 int，'
        'firstOf<String>(...) 返回 String。',
    objective: '会写泛型方法并在调用处获得类型安全。',
    pitfalls: <String>[
      '泛型不是动态：T 在编译期确定，不能在一个泛型方法里随意改变类型。',
      '从空列表推断泛型会失败，需要显式写出类型参数。',
    ],
    code:
        "T firstOf<T>(List<T> items) => items.first;\n"
        "\n"
        "T? lastOrNull<T>(List<T> items) => items.isEmpty ? null : items.last;\n"
        "\n"
        "void main() {\n"
        "  print(firstOf([1, 2, 3]));\n"
        "  print(firstOf(['a', 'b']));\n"
        "  print(lastOrNull(<int>[]));\n"
        "  print(lastOrNull([10, 20]));\n"
        "  final value = firstOf([3.14, 2.0]);\n"
        "  print(value.runtimeType);\n"
        "}\n",
    output: '1\na\nnull\n20\ndouble\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '写泛型方法 second<T>(List<T>) 返回第二个元素。',
        hint: '返回 items[1]。',
        answer:
            "T second<T>(List<T> items) => items[1];\nprint(second([1, 2, 3]));",
      ),
    ],
    exampleTitle: '示例 047：泛型方法',
    exampleSummary: 'firstOf/lastOrNull 泛型方法在多种类型上的复用。',
  ),
  DartLesson(
    id: 'dart-lesson-048',
    chapter: 'generics',
    level: 'intermediate',
    title: '泛型类',
    summary: '把类型参数用在类上，构建类型安全的容器。',
    concepts: <String>['泛型类', '容器', '类型参数'],
    explain:
        '泛型类把类型参数声明在类名后，如 Box<T>。实例化时指定类型，让容器只接受'
        '该类型。标准库的 List<E>、Map<K,V>、Future<T> 都是泛型类。写自己的容器'
        '能体会泛型带来的类型安全。',
    objective: '会定义泛型类并实例化出特定类型的容器。',
    pitfalls: <String>[
      '泛型类内部不能 new T()，因为不知道 T 是否有无参构造。',
      '同一泛型类的不同类型参数实例是不同类型，不能互相赋值。',
    ],
    code:
        "class Box<T> {\n"
        "  Box(this.value);\n"
        "  T value;\n"
        "\n"
        "  @override\n"
        "  String toString() => 'Box<\${T.toString()}>(\${value})';\n"
        "}\n"
        "\n"
        "class Pair<K, V> {\n"
        "  const Pair(this.key, this.value);\n"
        "  final K key;\n"
        "  final V value;\n"
        "\n"
        "  Pair<V, K> swap() => Pair(value, key);\n"
        "\n"
        "  @override\n"
        "  String toString() => 'Pair<\${K.toString()}, \${V.toString()}>(\$key, \$value)';\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final b = Box<int>(42);\n"
        "  print(b);\n"
        "  final p = const Pair<String, int>('age', 18);\n"
        "  print(p.swap());\n"
        "}\n",
    output: 'Box<int>(42)\nPair<int, String>(18, age)\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用 Box<String> 存一个名字并打印 value 的长度。',
        hint: "Box<String>('小明').value.length。",
        answer: "final box = Box<String>('小明');\nprint(box.value.length);",
      ),
    ],
    exampleTitle: '示例 048：泛型类',
    exampleSummary: 'Box<T> 容器与 Pair<K,V> 的泛型定义和互换。',
  ),
  DartLesson(
    id: 'dart-lesson-049',
    chapter: 'generics',
    level: 'intermediate',
    title: '泛型约束 extends',
    summary: '用 extends 限制类型参数必须是某类型的子类型。',
    concepts: <String>['泛型约束', 'extends', 'Comparable'],
    explain:
        '泛型参数可以加约束：<T extends num> 表示 T 必须是 num 或其子类，于是方法体里'
        '可以放心用 num 的运算。约束既扩大了能做的事，也缩小了能传的类型，让类型更'
        '精确。',
    objective: '会用 extends 给泛型参数加约束并使用约束类型的成员。',
    pitfalls: <String>[
      '约束写成 T extends Comparable 后，传入非 Comparable 类型会编译报错。',
      '多个约束用 & 组合（类型别名场景），普通参数只写一个 extends。',
    ],
    code:
        "T maxOf<T extends Comparable<T>>(List<T> items) {\n"
        "  var best = items.first;\n"
        "  for (final item in items) {\n"
        "    if (item.compareTo(best) > 0) best = item;\n"
        "  }\n"
        "  return best;\n"
        "}\n"
        "\n"
        "num sumAll<T extends num>(List<T> items) =>\n"
        "    items.fold<num>(0, (a, b) => a + b);\n"
        "\n"
        "void main() {\n"
        "  print(maxOf([3, 7, 2]));\n"
        "  print(maxOf(['apple', 'pear']));\n"
        "  print(sumAll([1, 2, 3]));\n"
        "  print(sumAll([1.5, 2.5]));\n"
        "}\n",
    output: '7\npear\n6\n4.0\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '写泛型方法 minOf<T extends Comparable<T>>(List<T>)。',
        hint: '比较用 compareTo < 0。',
        answer:
            "T minOf<T extends Comparable<T>>(List<T> items) {\n"
            "  var best = items.first;\n"
            "  for (final item in items) {\n"
            "    if (item.compareTo(best) < 0) best = item;\n"
            "  }\n"
            "  return best;\n"
            "}",
      ),
    ],
    exampleTitle: '示例 049：泛型约束',
    exampleSummary: 'Comparable 约束求最值与 num 约束求和。',
  ),
  DartLesson(
    id: 'dart-lesson-050',
    chapter: 'generics',
    level: 'intermediate',
    title: 'typedef 类型别名',
    summary: '用 typedef 给函数类型和复杂类型起名。',
    concepts: <String>['typedef', '函数类型', '类型别名'],
    explain:
        'typedef 给类型起别名，最常用于函数类型：typedef Mapper = int Function(int)。'
        '别名让签名更易读，也方便集中修改。函数类型本身可以作为参数和返回值，是'
        '高阶函数的基础。',
    objective: '会用 typedef 定义函数类型并在参数中使用。',
    pitfalls: <String>[
      'typedef 只是别名，不产生新类型，不会带来额外的类型安全。',
      '函数类型参数要写全参数和返回类型，否则容易不匹配。',
    ],
    code:
        "typedef IntOp = int Function(int a, int b);\n"
        "typedef Mapper<T> = T Function(T value);\n"
        "\n"
        "int apply(IntOp op, int a, int b) => op(a, b);\n"
        "\n"
        "List<T> transform<T>(List<T> items, Mapper<T> mapper) =>\n"
        "    items.map(mapper).toList();\n"
        "\n"
        "void main() {\n"
        "  print(apply((a, b) => a + b, 3, 4));\n"
        "  print(apply((a, b) => a * b, 3, 4));\n"
        "  print(transform([1, 2, 3], (n) => n * 10));\n"
        "}\n",
    output: '7\n12\n[10, 20, 30]\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用 typedef Predicate<T> = bool Function(T) 过滤出偶数。',
        hint: 'where 接受 bool Function(T)。',
        answer:
            "typedef Predicate<T> = bool Function(T value);\n"
            "List<T> filter<T>(List<T> items, Predicate<T> test) =>\n"
            "    items.where(test).toList();\n"
            "print(filter([1, 2, 3, 4], (n) => n.isEven));",
      ),
    ],
    exampleTitle: '示例 050：typedef 类型别名',
    exampleSummary: '函数类型别名用于高阶函数的参数与泛型变换。',
  ),
  DartLesson(
    id: 'dart-lesson-051',
    chapter: 'generics',
    level: 'intermediate',
    title: '泛型与集合的配合',
    summary: '用泛型方法处理任意类型的列表并保持类型。',
    concepts: <String>['泛型集合', 'groupBy', '类型保持'],
    explain:
        '标准集合都是泛型的，自己写的工具方法也应尽量泛型，避免退化成 dynamic。'
        '例如把列表按某个键分组返回 Map<K, List<T>>，或去重后仍返回 List<T>，'
        '这样调用方无需再转型。',
    objective: '会写返回泛型集合的工具方法并保持元素类型。',
    pitfalls: <String>[
      '返回值写成 List<dynamic> 会丢失类型，调用方每次都要强转。',
      '用 whereType 可以在混合集合里安全地取指定类型。',
    ],
    code:
        "Map<K, List<T>> groupBy<T, K>(List<T> items, K Function(T) keyOf) {\n"
        "  final result = <K, List<T>>{};\n"
        "  for (final item in items) {\n"
        "    result.putIfAbsent(keyOf(item), () => <T>[]).add(item);\n"
        "  }\n"
        "  return result;\n"
        "}\n"
        "\n"
        "List<T> distinct<T>(List<T> items) {\n"
        "  final seen = <T>{};\n"
        "  final result = <T>[];\n"
        "  for (final item in items) {\n"
        "    if (seen.add(item)) result.add(item);\n"
        "  }\n"
        "  return result;\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final words = ['apple', 'banana', 'avocado', 'berry'];\n"
        "  final grouped = groupBy(words, (w) => w[0]);\n"
        "  print(grouped['a']);\n"
        "  print(grouped['b']);\n"
        "  print(distinct([1, 2, 2, 3, 1]));\n"
        "}\n",
    output: '[apple, avocado]\n[banana, berry]\n[1, 2, 3]\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用 groupBy 把 [1,2,3,4,5,6] 按奇偶分组。',
        hint: 'keyOf 返回 n % 2。',
        answer:
            "final g = groupBy([1, 2, 3, 4, 5, 6], (n) => n % 2);\n"
            "print(g[0]);\nprint(g[1]);",
      ),
    ],
    exampleTitle: '示例 051：泛型与集合的配合',
    exampleSummary: 'groupBy 与 distinct 泛型工具方法的类型保持。',
  ),
  DartLesson(
    id: 'dart-lesson-052',
    chapter: 'generics',
    level: 'intermediate',
    title: '协变与类型边界',
    summary: '理解 List<int> 是 List<num> 的子类型，以及读写的限制。',
    concepts: <String>['协变', '子类型', '运行时检查'],
    explain:
        'Dart 的泛型是协变的：List<int> 可以当作 List<num> 使用，因为每个 int 也是'
        'num。但写入时仍受运行时检查约束：把 List<int> 当 List<num> 后写入 double '
        '会在运行时报错。理解这点能避免「看起来能编译、运行才炸」的坑。',
    objective: '理解泛型协变规则，并知道何时该复制列表避免运行期错误。',
    pitfalls: <String>[
      '把 List<int> 向上转型成 List<num> 后写入 double 会抛类型错误。',
      '需要读写混合时应显式复制成目标类型的新列表。',
    ],
    code:
        "void main() {\n"
        "  List<int> ints = [1, 2, 3];\n"
        "  List<num> nums = ints;\n"
        "  print(nums.fold<num>(0, (a, b) => a + b));\n"
        "  try {\n"
        "    nums.add(1.5);\n"
        "  } on Object catch (e) {\n"
        "    print('写入失败：\${e.runtimeType}');\n"
        "  }\n"
        "  final safe = List<num>.of(ints);\n"
        "  safe.add(1.5);\n"
        "  print(safe);\n"
        "}\n",
    output: '6\n写入失败：_TypeError\n[1, 2, 3, 1.5]\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '把 List<num> 里的整数元素用 whereType<int> 取出。',
        hint: '混合列表用 whereType 过滤。',
        answer:
            "final nums = <num>[1, 2.5, 3];\nprint(nums.whereType<int>().toList());",
      ),
    ],
    exampleTitle: '示例 052：协变与类型边界',
    exampleSummary: 'List<int> 到 List<num> 的协变与运行时写入检查。',
  ),
  DartLesson(
    id: 'dart-lesson-053',
    chapter: 'generics',
    level: 'intermediate',
    title: '可空泛型与默认类型',
    summary: 'T 可以为空、T? 的差别，以及泛型方法的空值返回。',
    concepts: <String>['可空泛型', 'T?', '类型推断'],
    explain:
        '类型参数 T 本身可以为空（如果实参是可空类型），T? 则明确允许返回 null。'
        '写 firstOrNull<T> 返回 T?，即使 T 是非空类型，也能表达「可能没有」。理解这'
        '一点能写出既泛型又空安全的 API。',
    objective: '会写返回可空的泛型方法并安全使用结果。',
    pitfalls: <String>[
      'T 和 T? 不等价：T 由调用方决定，T? 一定允许空。',
      '对返回 T? 的结果直接用要判空或用 ??。',
    ],
    code:
        "T? firstOrNull<T>(List<T> items) => items.isEmpty ? null : items.first;\n"
        "\n"
        "void main() {\n"
        "  print(firstOrNull([1, 2, 3]));\n"
        "  print(firstOrNull(<int>[]));\n"
        "  final first = firstOrNull(['a', 'b']);\n"
        "  print(first?.toUpperCase());\n"
        "  final missing = firstOrNull(<String>[]);\n"
        "  print(missing ?? '没有元素');\n"
        "}\n",
    output: '1\nnull\nA\n没有元素\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '写 lastOrNull<T>(List<T>) 并对空列表返回 null。',
        hint: 'items.isEmpty ? null : items.last。',
        answer:
            "T? lastOrNull<T>(List<T> items) => items.isEmpty ? null : items.last;",
      ),
    ],
    exampleTitle: '示例 053：可空泛型与默认类型',
    exampleSummary: '返回 T? 的泛型方法及空安全地使用结果。',
  ),
  DartLesson(
    id: 'dart-lesson-054',
    chapter: 'generics',
    level: 'intermediate',
    title: '综合练习：泛型缓存',
    summary: '用泛型类实现类型安全的缓存。',
    concepts: <String>['综合运用', '泛型类', '缓存', '可空'],
    explain:
        '这一课实现一个泛型缓存 Cache<K, V>：用 Map 存储，提供 put/get/containsKey，'
        'get 返回可空值。它把泛型类、Map、空安全组合起来，是泛型在真实工具中的典型'
        '应用。',
    objective: '能用泛型类封装一个类型安全的缓存并正确返回可空结果。',
    pitfalls: <String>[
      'get 不存在的键返回 null，与「值本身就是 null」无法区分，必要时用 containsKey 判断。',
      '缓存容量无限增长会占内存，真实场景要加淘汰策略。',
    ],
    code:
        "class Cache<K, V> {\n"
        "  final _store = <K, V>{};\n"
        "  int hits = 0;\n"
        "  int misses = 0;\n"
        "\n"
        "  void put(K key, V value) => _store[key] = value;\n"
        "\n"
        "  V? get(K key) {\n"
        "    if (_store.containsKey(key)) {\n"
        "      hits++;\n"
        "      return _store[key];\n"
        "    }\n"
        "    misses++;\n"
        "    return null;\n"
        "  }\n"
        "\n"
        "  bool containsKey(K key) => _store.containsKey(key);\n"
        "  int get size => _store.length;\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final cache = Cache<String, int>();\n"
        "  cache.put('a', 1);\n"
        "  cache.put('b', 2);\n"
        "  print(cache.get('a'));\n"
        "  print(cache.get('z') ?? -1);\n"
        "  print('命中 \${cache.hits} 未命中 \${cache.misses}');\n"
        "  print(cache.size);\n"
        "}\n",
    output: '1\n-1\n命中 1 未命中 1\n2\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '用缓存存字符串到列表的映射，并取回一个键。',
        hint: 'Cache<String, List<int>>。',
        answer:
            "final c = Cache<String, List<int>>();\n"
            "c.put('nums', [1, 2, 3]);\n"
            "print(c.get('nums'));",
      ),
    ],
    exampleTitle: '示例 054：综合练习：泛型缓存',
    exampleSummary: 'Cache<K,V> 泛型类、命中统计与可空 get。',
  ),
];
