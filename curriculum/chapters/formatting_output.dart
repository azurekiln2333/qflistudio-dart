import '../dart_lesson.dart';

/// Chapter `formatting-output` — independently executed lessons and paired examples.
const List<DartLesson> formattingOutputLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-262',
    chapter: "formatting-output",
    level: "beginner",
    title: "定宽表格与溢出策略",
    summary: "统一表头和数据列宽，对超长文本做明确截断。",
    concepts: <String>["padRight", "substring", "列宽契约"],
    explain:
        "定宽表格需要所有行使用相同的列宽规则，不能为某一行临时多补几个空格。程序把单元格格式化封装成函数。文本较短时右侧补空格。超过宽度时截取前面部分并添加省略标记。表头、分隔线和每条数据都复用同一宽度。示例故意放入超长名称，验证它不会把后面的分数列挤歪。为了让截断位置与终端列宽一致，本例只处理 ASCII 文本。对中文和表情应采用理解显示宽度与字符边界的方案。不能把 UTF-16 代码单元截断当作通用字符排版。",
    objective: "能给固定宽度列定义一致的填充与超长处理规则。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "padRight 只补齐，不会自动截断超长字符串。",
      "直接 substring 可能截断表情代理对，本例限定 ASCII。",
    ],
    code: r'''
String cell(String value, int width) {
  if (width < 1) throw ArgumentError('列宽');
  return value.length <= width ? value.padRight(width) : '${value.substring(0, width - 1)}~';
}
void main() {
  print('${cell('Name', 6)}|Score');
  print('------|-----');
  for (final row in [['Ada', '95'], ['LongName', '88']]) {
    print('${cell(row[0], 6)}|${row[1].padLeft(5)}');
  }
}
''',
    output: "Name  |Score\n------|-----\nAda   |   95\nLongN~|   88\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "写一个右对齐数字单元格，若数字超过宽度则输出同宽星号。",
        hint: "先比较文本长度。再选择 padLeft 或星号列表。",
        answer: r'''
String numberCell(int value, int width) {
  final text = value.toString();
  return text.length > width ? List.filled(width, '*').join() : text.padLeft(width);
}
void main() { print(numberCell(27, 4)); print(numberCell(12345, 4)); }
''',
      ),
    ],
    exampleTitle: "示例 262：定宽表格与溢出策略",
    exampleSummary: "统一表头和数据列宽，对超长文本做明确截断。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-263',
    chapter: "formatting-output",
    level: "beginner",
    title: "宽度自适应编号列表",
    summary: "依据最后一个编号确定数字宽度，保持两位编号处仍然对齐。",
    concepts: <String>["编号偏移", "动态宽度", "列表渲染"],
    explain:
        "编号列表跨过九到十时，若简单连接数字和文本，内容起点会向右移动。程序先根据最后一个编号计算所需宽度，再给所有编号左侧补空格，保证正文从同一列开始。起始编号作为独立输入，因此可以连续显示某一页中的局部条目，而不必每页从一重来。示例从九开始，直接覆盖位数变化的边界。空列表先返回，避免计算一个没有意义的末尾编号。这个排版函数只负责输出顺序与编号。它不对内容排序，也不会修改原始列表。这样调用者可以先完成筛选再显示。",
    objective: "能在任意起始编号下生成正文对齐的有序列表。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["用条目数量的位数代替最大编号位数，会在非一开头时出错。", "空列表应单独处理，不能假定总有最后一项。"],
    code: r'''
void numbered(List<String> items, int start) {
  if (start < 1) throw ArgumentError('起始编号');
  if (items.isEmpty) return;
  final width = (start + items.length - 1).toString().length;
  for (var i = 0; i < items.length; i++) {
    print('${(start + i).toString().padLeft(width)}. ${items[i]}');
  }
}
void main() { numbered(['read', 'edit', 'run'], 9); }
''',
    output: " 9. read\n10. edit\n11. run\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "让编号从二十七开始。在每条内容前显示方括号编号。",
        hint: "最大编号决定宽度，括号放在补齐后的编号外面。",
        answer: r'''
void main() {
  final items = ['alpha', 'beta'];
  const start = 27;
  final width = (start + items.length - 1).toString().length;
  for (var i = 0; i < items.length; i++) {
    print('[${(start + i).toString().padLeft(width)}] ${items[i]}');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 263：宽度自适应编号列表",
    exampleSummary: "依据最后一个编号确定数字宽度，保持两位编号处仍然对齐。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-264',
    chapter: "formatting-output",
    level: "intermediate",
    title: "递归输出目录树",
    summary: "在递归参数中传递深度，以缩进表达父子关系。",
    concepts: <String>["递归遍历", "深度参数", "前序输出"],
    explain:
        "树形数据显示不仅要列出节点。它还要把层级关系显示出来。程序用名称到子节点列表的映射表示一棵小树。访问节点时先打印自己，再递归访问孩子。这就是前序遍历。缩进宽度由递归深度决定，根节点深度为零，子节点每下降一级增加两格。没有出现在映射中的名称视为叶节点。示例不访问真实文件系统，因此不受机器目录内容影响。输入必须是一棵无环树。若来自用户的任意图结构，应增加路径访问集合或深度限制。不能假定递归一定会自然结束。",
    objective: "能把递归深度转换为视觉缩进，并区分树输入与一般图输入。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["不要用全局深度只增不减，否则相邻分支缩进会漂移。", "循环引用会导致无限递归，真实输入需要环检测。"],
    code: r'''
void printTree(String node, Map<String, List<String>> tree, int depth) {
  final indent = List.filled(depth * 2, ' ').join();
  print('$indent- $node');
  for (final child in tree[node] ?? <String>[]) printTree(child, tree, depth + 1);
}
void main() {
  final tree = <String, List<String>>{
    'app': ['lib', 'test'], 'lib': ['main.dart', 'model.dart'], 'test': ['model_test.dart'],
  };
  printTree('app', tree, 0);
}
''',
    output:
        "- app\n  - lib\n    - main.dart\n    - model.dart\n  - test\n    - model_test.dart\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "给目录树打印增加最大深度，到达限制后不再访问孩子。",
        hint: "在打印当前节点后检查 depth 是否已经达到上限。",
        answer: r'''
void walk(String node, Map<String, List<String>> tree, int depth, int limit) {
  print('${List.filled(depth * 2, ' ').join()}$node');
  if (depth >= limit) return;
  for (final child in tree[node] ?? <String>[]) walk(child, tree, depth + 1, limit);
}
void main() { walk('root', {'root': ['a'], 'a': ['hidden']}, 0, 1); }
''',
      ),
    ],
    exampleTitle: "示例 264：递归输出目录树",
    exampleSummary: "在递归参数中传递深度，以缩进表达父子关系。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-265',
    chapter: "formatting-output",
    level: "intermediate",
    title: "有界文本进度条",
    summary: "裁剪进度到合法范围，分别计算填充格数与百分比。",
    concepts: <String>["比例换算", "边界裁剪", "展示函数"],
    explain:
        "进度条的格数和百分比来自同一份完成量，但两者的取整策略可以不同。程序先要求总量为正，再把完成量裁剪到零和总量之间，防止负数或重复回调造成超出边框。格数用整除向下取整，百分比使用四舍五入，最后把已完成符号和未完成符号拼接成固定宽度。示例包含零进度、部分进度、完成和超额输入，验证边界保护确实生效。这里只渲染传入的状态，不用等待时间伪造任务进展。实际应用应从真实已完成工作量更新状态，而不是用定时器让图形自行走满。",
    objective: "能写出长度固定且不会越界的进度显示函数。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["总量为零时不能计算百分比，应定义单独的未知进度状态。", "进度条走满并不证明任务已成功完成。"],
    code: r'''
String progress(int done, int total, int width) {
  if (total <= 0 || width <= 0) throw ArgumentError('总量与宽度必须为正');
  final bounded = done < 0 ? 0 : (done > total ? total : done);
  final filled = bounded * width ~/ total;
  final percent = (bounded * 100 / total).round();
  return '[${List.filled(filled, '#').join()}${List.filled(width - filled, '.').join()}] $percent%';
}
void main() {
  for (final done in [0, 3, 10, 12]) print(progress(done, 10, 10));
}
''',
    output:
        "[..........] 0%\n[###.......] 30%\n[##########] 100%\n[##########] 100%\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "用五格进度条显示三个任务中完成一个的状态。",
        hint: "格数向下取整，百分比四舍五入，两者不必同值。",
        answer: r'''
void main() {
  const done = 1;
  const total = 3;
  const width = 5;
  final filled = done * width ~/ total;
  print('[${List.filled(filled, '#').join()}${List.filled(width - filled, '.').join()}] ${(done * 100 / total).round()}%');
}
''',
      ),
    ],
    exampleTitle: "示例 265：有界文本进度条",
    exampleSummary: "裁剪进度到合法范围，分别计算填充格数与百分比。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-266',
    chapter: "formatting-output",
    level: "intermediate",
    title: "按单词边界自动折行",
    summary: "逐词尝试加入当前行，超宽时先提交已有行。",
    concepts: <String>["贪心排版", "split", "边界策略"],
    explain:
        "按固定位置切字符串可能把一个单词拆开，因此本例采用逐词贪心折行。程序先把连续空白归一化为单词序列。程序再尝试将下一个单词接到当前行。如果候选长度超过宽度且当前行不为空，就先提交当前行并另起一行。循环结束后不要忘记最后一行。示例的长单词独占一行，允许超过指定宽度，这是明确选择的策略，而不是暗中截断内容。该算法适用于以空格分词的 ASCII 文本。中文换行、连字符和 Unicode 显示宽度需要额外的分词与排版规则。",
    objective: "能用贪心算法保留单词边界，并明确定义超长词的处理方式。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["只在遇到超宽时输出，会遗漏最后一行。", "空字符串 trim 后仍需单独处理，避免产生一个空词。"],
    code: r'''
List<String> wrap(String text, int width) {
  if (width <= 0) throw ArgumentError('宽度');
  if (text.trim().isEmpty) return <String>[];
  final lines = <String>[];
  var line = '';
  for (final word in text.trim().split(RegExp(r'\s+'))) {
    final candidate = line.isEmpty ? word : '$line $word';
    if (line.isNotEmpty && candidate.length > width) {
      lines.add(line);
      line = word;
    } else { line = candidate; }
  }
  if (line.isNotEmpty) lines.add(line);
  return lines;
}
void main() {
  for (final line in wrap('Dart makes small offline tools practical', 12)) print(line);
}
''',
    output: "Dart makes\nsmall\noffline\ntools\npractical\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把每行宽度改为十五。验证全部单词仍按原顺序出现，没有丢失。",
        hint: "可把输出行重新用空格连接。再与归一化后的输入比较。",
        answer: r'''
void main() {
  final words = 'one two three four five'.split(' ');
  final lines = <String>[];
  var line = '';
  for (final word in words) {
    if (line.isNotEmpty && line.length + 1 + word.length > 15) {
      lines.add(line); line = word;
    } else { line = line.isEmpty ? word : '$line $word'; }
  }
  if (line.isNotEmpty) lines.add(line);
  print(lines);
  print(lines.join(' ') == words.join(' '));
}
''',
      ),
    ],
    exampleTitle: "示例 266：按单词边界自动折行",
    exampleSummary: "逐词尝试加入当前行，超宽时先提交已有行。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-267',
    chapter: "formatting-output",
    level: "intermediate",
    title: "随标题扩展的文本框",
    summary: "从最长内容推导边框宽度，所有行共享相同内宽。",
    concepts: <String>["最大长度", "StringBuffer", "统一边框"],
    explain:
        "文本框的边框应该由内容决定，而不是依靠人工数横线。程序先扫描所有行，得到最大长度，再生成上下边框，并把每行补到相同内宽。左右各留一格空白，使文字不会紧贴竖线。示例包含标题和较短的状态行，验证短行仍能与右边框对齐。输入列表为空时依然可以生成合法的空框，但不会擅自添加内容。为了让长度等于终端占用列数，这里使用 ASCII 字符。若内容包含中文或表情，需要先计算实际显示宽度。再决定补多少空格，不能简单按代码单元数量猜测。",
    objective: "能从输入数据推导统一边框，并保持短行和长行对齐。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["上下边框必须包含左右边距所占的宽度。", "每行自己生成边框会导致框体宽度不一致。"],
    code: r'''
String box(List<String> lines) {
  var width = 0;
  for (final line in lines) if (line.length > width) width = line.length;
  final edge = '+${List.filled(width + 2, '-').join()}+';
  final out = StringBuffer()..writeln(edge);
  for (final line in lines) out.writeln('| ${line.padRight(width)} |');
  out.writeln(edge);
  return out.toString();
}
void main() { print(box(['OFFLINE', 'ready']).trimRight()); }
''',
    output: "+---------+\n| OFFLINE |\n| ready   |\n+---------+\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "给标题框增加居中标题。奇数个空格时把多出的一格放在右侧。",
        hint: "左侧空格取差值整除二，右侧承担剩余部分。",
        answer: r'''
void main() {
  const width = 10;
  const title = 'DART';
  final left = (width - title.length) ~/ 2;
  final right = width - title.length - left;
  print('|${List.filled(left, ' ').join()}$title${List.filled(right, ' ').join()}|');
}
''',
      ),
    ],
    exampleTitle: "示例 267：随标题扩展的文本框",
    exampleSummary: "从最长内容推导边框宽度，所有行共享相同内宽。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-268',
    chapter: "formatting-output",
    level: "intermediate",
    title: "键值配置对齐显示",
    summary: "先对键名排序并计算最大宽度，再输出稳定的配置摘要。",
    concepts: <String>["键排序", "最大宽度", "敏感值遮盖"],
    explain:
        "配置摘要既要便于阅读，也要避免无意打印敏感字段。程序先把键名复制出来排序，计算最长键名的宽度，再按键名逐行输出值。显示层针对名称为 token 的字段使用遮盖文本，原始配置值保持不变。排序让相同配置无论如何插入都能得到稳定摘要，适合日志比较。示例只包含固定离线字符串，不访问真实环境变量或密钥。敏感字段识别在这里只是显式示范，不是完整安全方案。实际项目应维护明确的可公开字段清单。不能认为所有不叫 token 的字段都可以直接写入日志。",
    objective: "能生成稳定对齐的配置摘要，并在显示层遮盖指定敏感字段。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["不要为了打印遮盖值而修改原配置。", "仅凭一个字段名无法识别真实系统中的全部敏感信息。"],
    code: r'''
void main() {
  final config = {'mode': 'offline', 'retries': '3', 'token': 'demo-secret'};
  final keys = config.keys.toList()..sort();
  var width = 0;
  for (final key in keys) if (key.length > width) width = key.length;
  for (final key in keys) {
    final value = key == 'token' ? '***' : config[key]!;
    print('${key.padRight(width)} = $value');
  }
  print('原值保留:${config['token'] == 'demo-secret'}');
}
''',
    output: "mode    = offline\nretries = 3\ntoken   = ***\n原值保留:true\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "只打印 mode 和 retries 两个允许公开的字段，忽略其他字段。",
        hint: "遍历显式允许列表，而不是遍历全部配置再猜测敏感性。",
        answer: r'''
void main() {
  final config = {'mode': 'offline', 'token': 'secret', 'retries': '3'};
  for (final key in ['mode', 'retries']) {
    if (config.containsKey(key)) print('$key=${config[key]}');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 268：键值配置对齐显示",
    exampleSummary: "先对键名排序并计算最大宽度，再输出稳定的配置摘要。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-269',
    chapter: "formatting-output",
    level: "advanced",
    title: "渲染受限 Markdown 子集",
    summary: "识别一级标题和无序列表，将结构转换为终端文本。",
    concepts: <String>["前缀识别", "逐行转换", "子集契约"],
    explain:
        "一个小型文本渲染器应先声明支持的语法，而不是把少量替换包装成完整 Markdown。程序逐行识别井号加空格开头的一级标题、短横线加空格开头的列表项，其余行原样保留。标题转成大写并追加同宽下划线，列表项改为星号前缀，从而保留基本结构。示例同时包含普通段落，验证渲染器不会把普通内容当作标题。本课不解析内联强调、代码围栏、链接或嵌套列表，也不生成 HTML。明确子集可以让调用者知道何时应选择专业解析器，避免把未知语法静默解释成错误结构。",
    objective: "能按行识别明确的文本语法子集，并保留不支持的普通内容。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "startsWith 的前缀必须包含空格，否则缺少空格的 #tag 也会当成标题。",
      "连续 replaceAll 无法处理 Markdown 的嵌套结构。",
    ],
    code: r'''
List<String> render(String markdown) {
  final output = <String>[];
  for (final line in markdown.split('\n')) {
    if (line.startsWith('# ')) {
      final heading = line.substring(2).toUpperCase();
      output.add(heading);
      output.add(List.filled(heading.length, '=').join());
    } else if (line.startsWith('- ')) {
      output.add('* ${line.substring(2)}');
    } else { output.add(line); }
  }
  return output;
}
void main() {
  print(render('# tools\nRun locally.\n- format\n- analyze').join('\n'));
}
''',
    output: "TOOLS\n=====\nRun locally.\n* format\n* analyze\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "增加二级标题支持，用短横线作为二级标题下划线。",
        hint: "先识别 ## 加空格。再识别 # 加空格。",
        answer: r'''
void main() {
  for (final line in ['## Usage', '# Tools', '#tag']) {
    if (line.startsWith('## ')) {
      final title = line.substring(3);
      print(title); print(List.filled(title.length, '-').join());
    } else if (line.startsWith('# ')) {
      print(line.substring(2).toUpperCase());
    } else { print(line); }
  }
}
''',
      ),
    ],
    exampleTitle: "示例 269：渲染受限 Markdown 子集",
    exampleSummary: "识别一级标题和无序列表，将结构转换为终端文本。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-270',
    chapter: "formatting-output",
    level: "advanced",
    title: "包含引号与换行的 CSV 输出",
    summary: "按字段判断是否引用，并把内部双引号重复转义。",
    concepts: <String>["CSV quoting", "replaceAll", "记录与行"],
    explain:
        "CSV 不能简单地把字段用逗号连接，因为字段本身可能包含逗号、双引号或换行。程序先检查这些特殊字符。若字段含特殊字符，就把字段放进双引号。程序再把内部每个双引号写成两个双引号。然后再连接已经转义的字段。示例同时包含普通姓名、带逗号的商品、带引号的说明及跨行备注。真实输出因此可以一条记录占据多行。这里只负责 CSV 序列化，不负责电子表格的公式解释策略。若目标软件会把等号开头的字段当公式，导出层还需要独立定义防护规则。它还需要定义数据保真规则。",
    objective: "能正确序列化需要引用的 CSV 字段，并解释物理行不等于记录。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>[
      "先 join 再整体加引号，会把多个字段错误合并为一个字段。",
      "字段内部双引号必须重复，而不是用反斜杠转义。",
    ],
    code: r'''
String csvField(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
void main() {
  final rows = [
    ['name', 'note'], ['Ada', 'tea, milk'], ['Bo', 'said "hi"'], ['Chen', 'line1\nline2'],
  ];
  for (final row in rows) print(row.map(csvField).join(','));
}
''',
    output:
        "name,note\nAda,\"tea, milk\"\nBo,\"said \"\"hi\"\"\"\nChen,\"line1\nline2\"\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "编写始终引用每个字段的版本。验证空字符串和带双引号文本。",
        hint: "先重复内部引号。再包围外部引号。",
        answer: r'''
String quote(String value) => '"${value.replaceAll('"', '""')}"';
void main() { print(['', 'a"b', 'plain'].map(quote).join(',')); }
''',
      ),
    ],
    exampleTitle: "示例 270：包含引号与换行的 CSV 输出",
    exampleSummary: "按字段判断是否引用，并把内部双引号重复转义。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-271',
    chapter: "formatting-output",
    level: "advanced",
    title: "整数千分位格式化",
    summary: "从右向左按三位分组，负号独立处理。",
    concepts: <String>["字符串分段", "余数", "符号处理"],
    explain:
        "千分位分隔符是一种显示规则，不应该污染用于计算的整数。程序先记录符号，对绝对值转换为十进制文本，再从右侧每次取三位加入分组列表。最后把分组反转后用逗号连接，并恢复负号。这个方向保证左侧不足三位的组自然保留，不需要为不同位数写多个分支。示例覆盖零、三位数、四位数和负数。实现只处理整数，并采用逗号作为明确的示例分隔符。不同地区可能使用空格或句点。小数金额还需要另行处理小数部分。不能把字符串每三位全局插入逗号。",
    objective: "能手工实现整数分组，并保持负号和最左侧短组正确。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["从左开始固定每三位分组，会在总位数不整除三时出错。", "不要把负号也算进数字分组。"],
    code: r'''
String grouped(int value) {
  final digits = value.abs().toString();
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = end - 3 < 0 ? 0 : end - 3;
    groups.add(digits.substring(start, end));
  }
  return '${value < 0 ? '-' : ''}${groups.reversed.join(',')}';
}
void main() {
  for (final value in [0, 999, 1000, -1234567]) print(grouped(value));
}
''',
    output: "0\n999\n1,000\n-1,234,567\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "将千分位分隔符作为参数。再输出用下划线分组的 123456789。",
        hint: "分组列表保持不变，只替换最后 join 的分隔符。",
        answer: r'''
String grouped(int value, String separator) {
  final digits = value.toString();
  final parts = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    parts.add(digits.substring(end - 3 < 0 ? 0 : end - 3, end));
  }
  return parts.reversed.join(separator);
}
void main() { print(grouped(123456789, '_')); }
''',
      ),
    ],
    exampleTitle: "示例 271：整数千分位格式化",
    exampleSummary: "从右向左按三位分组，负号独立处理。完整运行演示。",
  ),
  DartLesson(
    id: 'dart-lesson-272',
    chapter: "formatting-output",
    level: "advanced",
    title: "按列填充的多栏目录",
    summary: "先确定行数与各栏宽度，再以列优先索引输出菜单。",
    concepts: <String>["列优先索引", "动态列宽", "二维布局"],
    explain:
        "把一长串目录分成多栏时，要先决定阅读方向。本例按列从上到下填充。第一栏读完再读第二栏。因此索引是列号乘行数再加行号。程序先按条目总数和栏数向上取整得到行数。程序再分别计算每栏最长文本。最后逐行输出并给栏间留两个空格。最后一栏不足时用空文本填充，不会访问越界索引。示例有五个条目和两栏，能够覆盖不满矩形的情况。这里的布局针对 ASCII 名称。自动终端换行和宽字符测量不在此函数内。应由调用者提供合适的栏数或显示宽度策略。",
    objective: "能把一维条目列表转换为按列阅读的稳定多栏输出。",
    prerequisites: <String>["已掌握 Dart 函数、循环和集合基础。"],
    pitfalls: <String>["行优先与列优先的索引公式不同，不能混用。", "最后一栏可能不足行数，访问前必须判断是否越界。"],
    code: r'''
void columns(List<String> items, int count) {
  if (count < 1) throw ArgumentError('栏数');
  final rows = (items.length + count - 1) ~/ count;
  final widths = List<int>.filled(count, 0);
  for (var col = 0; col < count; col++) {
    for (var row = 0; row < rows; row++) {
      final index = col * rows + row;
      if (index < items.length && items[index].length > widths[col]) widths[col] = items[index].length;
    }
  }
  for (var row = 0; row < rows; row++) {
    final cells = <String>[];
    for (var col = 0; col < count; col++) {
      final index = col * rows + row;
      final text = index < items.length ? items[index] : '';
      cells.add(text.padRight(widths[col]));
    }
    print(cells.join('  ').trimRight());
  }
}
void main() { columns(['alpha', 'b', 'charlie', 'delta', 'echo'], 2); }
''',
    output: "alpha    delta\nb        echo\ncharlie\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把六个条目按行优先分成三栏。验证阅读顺序与本课列优先不同。",
        hint: "行优先索引是 row * count + col。",
        answer: r'''
void main() {
  final items = ['a', 'b', 'c', 'd', 'e', 'f'];
  const count = 3;
  for (var row = 0; row < 2; row++) {
    final cells = <String>[];
    for (var col = 0; col < count; col++) cells.add(items[row * count + col]);
    print(cells.join(' | '));
  }
}
''',
      ),
    ],
    exampleTitle: "示例 272：按列填充的多栏目录",
    exampleSummary: "先确定行数与各栏宽度，再以列优先索引输出菜单。完整运行演示。",
  ),
];
