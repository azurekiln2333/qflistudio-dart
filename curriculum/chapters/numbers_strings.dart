import '../dart_lesson.dart';

/// Chapter `numbers-strings` — independently executed lessons and paired examples.
const List<DartLesson> numbersStringsLessons = <DartLesson>[
  DartLesson(
    id: "dart-lesson-121",
    chapter: "numbers-strings",
    level: "beginner",
    title: "金额与票号格式化",
    summary: "把计算值转换为显示文本，区分金额小数位和票号位宽。",
    concepts: <String>["toStringAsFixed", "padLeft", "展示格式"],
    explain:
        "收银小票把金额显示成两位小数，订单编号则需要补足固定宽度。"
        "这是两种不同的格式约束。"
        "toStringAsFixed 返回带指定小数位的字符串。"
        "padLeft 只在左侧补字符，不改变数值。"
        "程序先计算单价乘数量。再格式化合计。"
        "最后程序生成带前导零的票号。"
        "分开计算与显示，可以避免把货币文本再次相加。"
        "这里的小数格式只用于界面显示。"
        "它不承诺十进制金额运算完全精确。"
        "需要累计账本时，应改用分单位整数。"
        "示例使用固定商品数据，本例无需输入和联网。",
    objective: "能分别控制金额小数位与编号宽度。能保留原始数值用于计算。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "补零后的票号是字符串，不能当作整数参与编号运算。",
      "toStringAsFixed 只舍入显示值，不决定金额怎么存。",
    ],
    code: r'''
void main() {
  final unitPrice = 12.5;
  final quantity = 3;
  final ticket = 27;
  print('单价 ${unitPrice.toStringAsFixed(2)}');
  print('合计 ${(unitPrice * quantity).toStringAsFixed(2)}');
  print('票号 ${ticket.toString().padLeft(5, '0')}');
}
''',
    output: "单价 12.50\n合计 37.50\n票号 00027\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "输出两件商品的小票。单价为 8.75 和 3.20。打印两行金额及总额，两数都保留两位小数。",
        hint: "先保存两个 double 并求和。再对每个显示值调用 toStringAsFixed。",
        answer: r'''
void main() {
  final prices = <double>[8.75, 3.20];
  var total = 0.0;
  for (final price in prices) {
    total += price;
    print(price.toStringAsFixed(2));
  }
  print('总额 ${total.toStringAsFixed(2)}');
}
''',
      ),
    ],
    exampleTitle: "示例 121：金额与票号格式化",
    exampleSummary: "小票中的数量计算、两位金额与前导零票号。",
  ),
  DartLesson(
    id: "dart-lesson-122",
    chapter: "numbers-strings",
    level: "beginner",
    title: "批量安全解析数字",
    summary: "清理文本后解析库存与单价，把无效输入保留为明确的失败。",
    concepts: <String>["int.tryParse", "double.tryParse", "可空结果"],
    explain:
        "导入库存数据时，空白、单位后缀和拼写错误都可能让数字解析失败。"
        "tryParse 把失败表示为 null。"
        "调用者先验证再计算，不必靠抛错控制正常分支。"
        "程序对数量先 trim。再要求结果非负。"
        "单价改用 double.tryParse。同时排除 NaN 和无穷大。"
        "这两种值能解析出来，却不适合进入账目。"
        "有效数量乘单价后才产生金额。"
        "失败记录保留原文本，便于修正。"
        "不要把所有失败直接替换为零，否则无法区分真正的零库存与损坏的数据。"
        "本例只使用内置文本，整个过程都能离线重复。",
    objective: "能区分解析失败、负数和非有限数值。能阻止无效记录参与计算。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "tryParse 成功不等于业务合法，负数仍须单独检查。",
      "NaN 和 Infinity 需要 isFinite 验证，不能只判断 null。",
    ],
    code: r'''
double? lineTotal(String countText, String priceText) {
  final count = int.tryParse(countText.trim());
  final price = double.tryParse(priceText.trim());
  if (count == null || count < 0 || price == null || !price.isFinite || price < 0) {
    return null;
  }
  return count * price;
}
void main() {
  for (final count in [' 4 ', '两件', '-2']) {
    final total = lineTotal(count, '2.50');
    print('$count => ${total?.toStringAsFixed(2) ?? '无效记录'}');
  }
  print(lineTotal('1', 'NaN') == null);
}
''',
    output: " 4  => 10.00\n两件 => 无效记录\n-2 => 无效记录\ntrue\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "统计三条记录中可计价的条数。三条数量分别是 2、空字符串、0。单价都为 1.5，零数量也算有效。",
        hint: "使用 lineTotal，按结果是否为 null 判断有效，不要把零金额误判为失败。",
        answer: r'''
double? lineTotal(String countText, String priceText) {
  final count = int.tryParse(countText.trim());
  final price = double.tryParse(priceText.trim());
  if (count == null || count < 0 || price == null || !price.isFinite || price < 0) {
    return null;
  }
  return count * price;
}
void main() {
  var accepted = 0;
  for (final text in ['2', '', '0']) {
    if (lineTotal(text, '1.5') != null) accepted++;
  }
  print('有效 $accepted 条');
}
''',
      ),
    ],
    exampleTitle: "示例 122：批量安全解析数字",
    exampleSummary: "导入行的清理、数字解析、有限值检查与失败保留。",
  ),
  DartLesson(
    id: "dart-lesson-123",
    chapter: "numbers-strings",
    level: "intermediate",
    title: "进制转换与字节标识",
    summary: "把颜色通道转换为二进制与十六进制。再验证可逆解析。",
    concepts: <String>["toRadixString", "int.parse", "进制与位宽"],
    explain:
        "二进制适合观察位，十六进制适合紧凑表示字节，它们只是同一个整数的不同写法。"
        "程序以颜色通道为例，把零到二百五十五的值转成八位二进制。"
        "程序再把同一数值转成两位十六进制。"
        "最后程序按 radix 十六把文本解析回来。"
        "补位发生在转换之后，因此不会改变数值。"
        "大写转换也只影响显示。"
        "输入前应检查字节范围，超出范围的整数虽然仍可转换，却不再代表单个通道。"
        "十进制文本里的十与十六进制文本里的十含义不同。"
        "解析时显式指定基数，编码和解码的契约才能一致。"
        "本程序不依赖平台字节序。",
    objective: "能为受限整数生成固定宽度进制文本。再通过反向解析验证一致性。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "int.parse 不会根据普通数字字符串自动猜测你想要的基数。",
      "padLeft 不会截掉超宽数值，转换前必须验证字节范围。",
    ],
    code: r'''
String hexByte(int value) {
  if (value < 0 || value > 255) throw ArgumentError('不是字节');
  return value.toRadixString(16).padLeft(2, '0').toUpperCase();
}
void main() {
  for (final channel in [0, 15, 170, 255]) {
    final hex = hexByte(channel);
    print('${channel.toString().padLeft(3)} ${channel.toRadixString(2).padLeft(8, '0')} $hex');
    print(int.parse(hex, radix: 16) == channel);
  }
}
''',
    output:
        "  0 00000000 00\ntrue\n 15 00001111 0F\ntrue\n170 10101010 AA\ntrue\n255 11111111 FF\ntrue\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把 RGB 通道 12、128、240 拼成以 # 开头的六位颜色码。再验证第二个通道能还原。",
        hint: "每个通道都调用 hexByte，合并后按已知两位边界取出绿色通道。",
        answer: r'''
String hexByte(int value) {
  if (value < 0 || value > 255) throw ArgumentError('不是字节');
  return value.toRadixString(16).padLeft(2, '0').toUpperCase();
}
void main() {
  final color = '#${hexByte(12)}${hexByte(128)}${hexByte(240)}';
  print(color);
  print(int.parse(color.substring(3, 5), radix: 16));
}
''',
      ),
    ],
    exampleTitle: "示例 123：进制转换与字节标识",
    exampleSummary: "颜色字节的定宽二进制、十六进制和往返检查。",
  ),
  DartLesson(
    id: "dart-lesson-124",
    chapter: "numbers-strings",
    level: "intermediate",
    title: "分组余数与完成比例",
    summary: "同一份任务数据分别计算整组数量、尾组余量和完成百分比。",
    concepts: <String>["整数除法", "取余", "比例分母"],
    explain:
        "装箱和进度显示看似都在做除法，结果含义却不同。"
        "整数除法给出能装满的组数，取余给出尚未组成整组的数量，而普通除法保留比例中的小数。"
        "程序把十七件货物按每箱五件分组。再计算已完成任务占全部任务的百分比。"
        "需要额外一箱时，应由余数是否为零决定，不能简单地给所有整除结果加一。"
        "进度函数先处理总量为零的情况，明确约定无任务时返回零，避免无穷大或 NaN 进入界面。"
        "把组数、余量和比率分别命名，单位和业务含义才清楚。"
        "这样能减少数值正确却解释错误的结果。",
    objective: "能根据任务含义选用整除、取余或普通除法，并处理零分母。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>["把 ~/ 用于百分比会丢失未达到整倍数的进度。", "是否补一箱取决于余数，整除时不应多分配一箱。"],
    code: r'''
double percent(int done, int total) => total == 0 ? 0 : done / total * 100;
void main() {
  final items = 17;
  final size = 5;
  final full = items ~/ size;
  final tail = items % size;
  print('整箱 $full，余量 $tail');
  print('所需箱数 ${full + (tail == 0 ? 0 : 1)}');
  print('进度 ${percent(7, 12).toStringAsFixed(1)}%');
  print('空任务 ${percent(0, 0).toStringAsFixed(1)}%');
}
''',
    output: "整箱 3，余量 2\n所需箱数 4\n进度 58.3%\n空任务 0.0%\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "分页大小为 4。分别计算 0、8、9 条记录的页数。空列表要得到零页。",
        hint: "整除得到完整页，只有余数非零才额外加一页。",
        answer: r'''
double percent(int done, int total) => total == 0 ? 0 : done / total * 100;
void main() {
  const pageSize = 4;
  for (final count in [0, 8, 9]) {
    final pages = count ~/ pageSize + (count % pageSize == 0 ? 0 : 1);
    print('$count 条 => $pages 页');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 124：分组余数与完成比例",
    exampleSummary: "装箱数量与任务进度中三种除法语义的对照。",
  ),
  DartLesson(
    id: "dart-lesson-125",
    chapter: "numbers-strings",
    level: "intermediate",
    title: "分隔文本清洗管线",
    summary: "按明确规则清洗重复分隔符与空白，输出可复用的标签列表。",
    concepts: <String>["trim", "split", "where", "join"],
    explain:
        "复制来的标签文本常同时包含中文逗号、英文逗号和多余空格。"
        "清洗的第一步不是盲目删除所有空格，而是先明确哪些符号属于分隔符，哪些字符属于标签内容。"
        "程序将中文逗号统一成英文逗号。拆分后逐项 trim。同时过滤空项。最后用统一分隔符重新组合。"
        "程序保留标签内部的空格，两个词组成的名词仍算一项。"
        "各步骤产生明确的中间结果，方便定位是哪条规则改变了数据。"
        "这里不做自动去重，因为去重是另一项业务决定。"
        "若直接用 Set，可能在不知情时丢掉重复出现次数。"
        "本例处理固定文本，可以离线检查清洗前后的差异。",
    objective: "能把多种分隔符统一为结构化列表，同时保留项内合法内容。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>["删除所有空格会破坏标签内部的有效词间空格。", "过滤空项和去重不是同一件事，应分别决定是否需要。"],
    code: r'''
List<String> cleanTags(String raw) => raw.replaceAll('，', ',').split(',')
    .map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
void main() {
  final raw = '  Dart， Flutter, , offline tools ,Dart  ';
  final tags = cleanTags(raw);
  print(tags);
  print(tags.join(' | '));
  print('保留 ${tags.length} 项');
}
''',
    output:
        "[Dart, Flutter, offline tools, Dart]\nDart | Flutter | offline tools | Dart\n保留 4 项\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "在清洗后增加按首次出现顺序去重，处理“ api， ui,api, ,ui ”。",
        hint: "先复用 cleanTags。再维护 seen 集合和结果列表，避免改变首次出现顺序。",
        answer: r'''
List<String> cleanTags(String raw) => raw.replaceAll('，', ',').split(',')
    .map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
void main() {
  final seen = <String>{};
  final unique = <String>[];
  for (final tag in cleanTags(' api， ui,api, ,ui ')) {
    if (seen.add(tag)) unique.add(tag);
  }
  print(unique.join('/'));
}
''',
      ),
    ],
    exampleTitle: "示例 125：分隔文本清洗管线",
    exampleSummary: "标签导入的分隔符归一、空项过滤与稳定重组。",
  ),
  DartLesson(
    id: "dart-lesson-126",
    chapter: "numbers-strings",
    level: "intermediate",
    title: "英文标题大小写规范",
    summary: "将空格分隔的英文单词规范为首字母大写，其余字母小写。",
    concepts: <String>["toLowerCase", "substring", "单词边界"],
    explain:
        "英文栏目标题常需要统一外观，但直接把整句转大写会丢掉词内层次。"
        "本例先以空白拆成单词。再把每个词转小写。"
        "程序单独提升第一个字母。最后用一个空格连接。"
        "先过滤空词可以避免重复空格触发越界访问。"
        "单字母词也能正常处理。"
        "这里规定所有词都标题化，不引入冠词或缩写的特殊规则。"
        "因此输入 API 会得到 Api，这是规则选择，不是语言保证。"
        "示例只面向由普通英文词构成的标题。"
        "真实多语言排版还要处理字素簇、连字符和专有名称。"
        "本课函数不能当作完整的语言学标题转换器。",
    objective: "能按明确的英文单词规则标题化。能处理空输入和重复空格。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "空字符串没有下标零，必须在取首字母前过滤空词。",
      "自动标题化会改变 API 等缩写，品牌名称应另设保留规则。",
    ],
    code: r'''
String titleCase(String text) {
  final words = text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
  return words.map((word) {
    final lower = word.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }).join(' ');
}
void main() {
  print(titleCase('  dART   OFFLINE tools '));
  print(titleCase('a guide'));
  print('空标题=${titleCase('   ')}');
}
''',
    output: "Dart Offline Tools\nA Guide\n空标题=\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "给标题转换增加缩写保留。api 和 ui 始终输出 API 和 UI。其他词仍调用 titleCase。",
        hint: "拆词后先判断小写词是否属于缩写集合。再选择输出策略。",
        answer: r'''
String titleCase(String text) {
  final words = text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
  return words.map((word) {
    final lower = word.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }).join(' ');
}
void main() {
  final acronyms = <String>{'api', 'ui'};
  final result = 'api and ui guide'.split(' ').map((word) =>
      acronyms.contains(word.toLowerCase()) ? word.toUpperCase() : titleCase(word));
  print(result.join(' '));
}
''',
      ),
    ],
    exampleTitle: "示例 126：英文标题大小写规范",
    exampleSummary: "英文栏目标题的空白规范和首字母转换。",
  ),
  DartLesson(
    id: "dart-lesson-127",
    chapter: "numbers-strings",
    level: "intermediate",
    title: "等宽清单的列对齐",
    summary: "用左右填充把名称、数量和金额排成可读的纯文本清单。",
    concepts: <String>["padRight", "padLeft", "列宽与溢出"],
    explain:
        "日志和纯文本报表没有表格控件，仍可以用明确的列宽表达行列关系。"
        "名称通常左对齐，数量与金额通常右对齐，读者便能沿着个位和小数点比较大小。"
        "程序分别格式化三个字段。再用竖线标出列边界，显示短文本如何补空格。"
        "padLeft 与 padRight 只保证最小长度，超长内容不会自动截断，因此需要单独决定溢出时换行还是裁剪。"
        "本例使用 ASCII 名称，一个字符正好占一列。"
        "中文、组合字符和 emoji 的可见宽度并不能直接由 length 推导。"
        "把这个前提写清楚，比在任意语言文本上假定对齐更可靠。",
    objective: "能为纯文本报表设置最小列宽。能说明字符长度与可见宽度的区别。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "padRight 不会截断过长名称，溢出策略必须另外实现。",
      "中文和 emoji 的可见宽度不一定等于 String.length。",
    ],
    code: r'''
String row(String name, int count, double amount) =>
    '|${name.padRight(8)}|${count.toString().padLeft(3)}|${amount.toStringAsFixed(2).padLeft(7)}|';
void main() {
  print('|NAME    |QTY| AMOUNT|');
  print(row('Book', 2, 15.5));
  print(row('Pen', 12, 9.0));
  print(row('Notebook', 1, 23.75));
}
''',
    output:
        "|NAME    |QTY| AMOUNT|\n|Book    |  2|  15.50|\n|Pen     | 12|   9.00|\n|Notebook|  1|  23.75|\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "生成两列的库存表。物品名称左对齐到 6 位。库存右对齐到 4 位。每行还要增加序号。",
        hint: "序号是额外字段，名称和数量分别使用 padRight 与 padLeft。",
        answer: r'''
String row(String name, int count, double amount) =>
    '|${name.padRight(8)}|${count.toString().padLeft(3)}|${amount.toStringAsFixed(2).padLeft(7)}|';
void main() {
  final stock = <String, int>{'Cable': 7, 'Mouse': 21};
  var number = 1;
  for (final entry in stock.entries) {
    print('${number++}. ${entry.key.padRight(6)}${entry.value.toString().padLeft(4)}');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 127：等宽清单的列对齐",
    exampleSummary: "ASCII 商品清单的列边界、数量和金额对齐。",
  ),
  DartLesson(
    id: "dart-lesson-128",
    chapter: "numbers-strings",
    level: "intermediate",
    title: "带预算的文本省略",
    summary: "把省略号计入总长度限制，处理空预算和刚好达到边界的文本。",
    concepts: <String>["substring", "边界检查", "长度预算"],
    explain:
        "列表摘要通常只能占据有限空间，截断函数必须先说清楚限制是否包含省略号。"
        "本例把三个点也算进总预算。"
        "原文不超长时直接返回原文。"
        "预算不大于三个字符时，只输出相应数量的点。"
        "其余情况预留三个位置。再截取正文。"
        "先处理小预算可以避免负下标，也让空预算自然返回空字符串。"
        "程序同时检查短文本、超长文本和极小预算，帮助读者从输出理解边界契约。"
        "这里按 UTF-16 代码单元计长度，只用于 ASCII 摘要。"
        "真实界面若含 emoji，截断位置可能落在代理对中间。"
        "这时应改用字素簇感知工具。"
        "substring 的索引不能当作可见字符数。",
    objective: "能实现包含省略标记的长度预算，并覆盖预算为零等边界。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "忘记给省略号预留位置会使最终结果超过最大长度。",
      "substring 以 UTF-16 索引工作，不能保证不拆开 emoji。",
    ],
    code: r'''
String abbreviate(String text, int limit) {
  if (limit < 0) throw ArgumentError('预算不能为负');
  if (text.length <= limit) return text;
  if (limit <= 3) return '.' * limit;
  return '${text.substring(0, limit - 3)}...';
}
void main() {
  print(abbreviate('offline handbook', 10));
  print(abbreviate('Dart', 4));
  print('[${abbreviate('abcdef', 2)}]');
  print('[${abbreviate('abcdef', 0)}]');
}
''',
    output: "offline...\nDart\n[..]\n[]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "为多个标题生成最长 8 位的摘要。再验证每个结果都不超预算。",
        hint: "复用 abbreviate，输出摘要后用 every 检查统一的长度契约。",
        answer: r'''
String abbreviate(String text, int limit) {
  if (limit < 0) throw ArgumentError('预算不能为负');
  if (text.length <= limit) return text;
  if (limit <= 3) return '.' * limit;
  return '${text.substring(0, limit - 3)}...';
}
void main() {
  final previews = ['short', 'longer title', ''].map((text) => abbreviate(text, 8)).toList();
  print(previews);
  print(previews.every((text) => text.length <= 8));
}
''',
      ),
    ],
    exampleTitle: "示例 128：带预算的文本省略",
    exampleSummary: "摘要正文与省略标记共同占用长度预算。",
  ),
  DartLesson(
    id: "dart-lesson-129",
    chapter: "numbers-strings",
    level: "advanced",
    title: "字符码与标识生成",
    summary: "从 ASCII 字符码生成连续标识。再区分代码单元和 Unicode 码点。",
    concepts: <String>["codeUnitAt", "String.fromCharCode", "runes"],
    explain:
        "字符在内存中有数值表示，字母表范围内的编号可以借助连续的 ASCII 字符码生成。"
        "程序以大写 A 的代码单元为起点，逐次加偏移得到列号。"
        "程序再把小写字母转成同范围内的大写字母。"
        "这样的算术只适用于事先限定的字母区间，不能推广为所有文字的大小写规则。"
        "随后用一个 emoji 对比 length 与 runes.length：前者数 UTF-16 代码单元，后者数 Unicode 码点。"
        "它们仍不等同于用户看到的完整字符，例如带修饰符的图案可能包含多个码点。"
        "理解这些层次有助于选择合适的文本遍历方式，也能避免把字符码练习写成错误的通用编码器。",
    objective: "能在明确的 ASCII 范围内构造标识，并辨别代码单元与码点。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "字符码加减只适用于指定连续区间，不适合通用大小写转换。",
      "runes.length 数码点，仍不是所有文本的可见字素数量。",
    ],
    code: r'''
String shelfColumn(int offset) {
  if (offset < 0 || offset >= 26) throw ArgumentError('列号越界');
  return String.fromCharCode('A'.codeUnitAt(0) + offset);
}
void main() {
  print(List.generate(4, shelfColumn).join(','));
  final letter = 'd';
  print(String.fromCharCode(letter.codeUnitAt(0) - 32));
  final symbol = '😀';
  print('代码单元 ${symbol.length}，码点 ${symbol.runes.length}');
}
''',
    output: "A,B,C,D\nD\n代码单元 2，码点 1\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把仅由小写 ASCII 字母构成的编号转成字母序号。例如“cab”变成 [3, 1, 2]。",
        hint: "逐个读取 codeUnits。减去 a 的码值后加一。先检查区间。",
        answer: r'''
String shelfColumn(int offset) {
  if (offset < 0 || offset >= 26) throw ArgumentError('列号越界');
  return String.fromCharCode('A'.codeUnitAt(0) + offset);
}
void main() {
  final positions = <int>[];
  for (final code in 'cab'.codeUnits) {
    if (code < 97 || code > 122) throw ArgumentError('只接受小写字母');
    positions.add(code - 97 + 1);
  }
  print(positions);
}
''',
      ),
    ],
    exampleTitle: "示例 129：字符码与标识生成",
    exampleSummary: "货架字母编号与 UTF-16、Unicode 码点的区别。",
  ),
  DartLesson(
    id: "dart-lesson-130",
    chapter: "numbers-strings",
    level: "intermediate",
    title: "传感器区间映射",
    summary: "把可能越界的读数限制在量程内。再转换为五级刻度。",
    concepts: <String>["clamp", "线性插值", "输入区间"],
    explain:
        "传感器读数与仪表刻度常使用不同的单位。"
        "例如百分制测量值要映射到零到五的仪表。"
        "线性映射先减去输入下界。再除以区间长度，得到零到一的比例。"
        "最后程序乘输出范围并加输出下界。"
        "程序先用 clamp 限制超量程读数。"
        "这样表盘不会出现负刻度，也不会超过最大值。"
        "区间宽度为零则直接拒绝，因为这时不存在唯一的映射比例。"
        "clamp 的返回类型是 num，函数用 toDouble 明确后续浮点运算。"
        "映射与舍入是两个步骤。"
        "本例保留连续刻度，只在最后显示时控制小数位。"
        "这样不会在中途损失精度。",
    objective: "能实现带输入限幅的线性映射，并拒绝零宽度量程。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "输入上界等于下界时会出现除零，必须先检查量程。",
      "映射后立刻取整会损失分辨率，应等显示或业务要求时再舍入。",
    ],
    code: r'''
double gauge(double value, double low, double high) {
  if (high <= low) throw ArgumentError('量程必须递增');
  final bounded = value.clamp(low, high).toDouble();
  return (bounded - low) / (high - low) * 5;
}
void main() {
  for (final reading in <double>[-10, 0, 25, 80, 120]) {
    print('${reading.toStringAsFixed(0)} => ${gauge(reading, 0, 100).toStringAsFixed(2)}');
  }
}
''',
    output: "-10 => 0.00\n0 => 0.00\n25 => 1.25\n80 => 4.00\n120 => 5.00\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把摄氏 -20 到 40 映射成五级表盘。测试 -30、10、50 三个读数。",
        hint: "复用 gauge，让越界值分别钳制到两端，中点应映射到 2.5。",
        answer: r'''
double gauge(double value, double low, double high) {
  if (high <= low) throw ArgumentError('量程必须递增');
  final bounded = value.clamp(low, high).toDouble();
  return (bounded - low) / (high - low) * 5;
}
void main() {
  for (final temperature in <double>[-30, 10, 50]) {
    print(gauge(temperature, -20, 40).toStringAsFixed(1));
  }
}
''',
      ),
    ],
    exampleTitle: "示例 130：传感器区间映射",
    exampleSummary: "超量程读数的限幅和连续仪表刻度转换。",
  ),
  DartLesson(
    id: "dart-lesson-131",
    chapter: "numbers-strings",
    level: "intermediate",
    title: "负数的舍入方向",
    summary: "对同一组正负测量值比较就近舍入、向下、向上和截断。",
    concepts: <String>["round", "floor", "ceil", "truncate"],
    explain:
        "整数化并不只有四舍五入一种选择。"
        "floor 朝负无穷方向取整，ceil 朝正无穷方向取整。truncate 朝零丢掉小数部分。"
        "因此对于负数，floor 与 truncate 往往不同。"
        "round 选择最近的整数，恰好位于两个整数中间时向远离零的方向处理。"
        "程序把正数、负数和半整数放在一起，按固定列输出四种结果。"
        "读者可以据此区分数轴方向与口语里的舍去。"
        "实际业务先确定要求。"
        "预算上限可能需要 ceil，完整时段计费可能需要 floor。"
        "但退款或负余额未必沿用正数规则。"
        "示例只演示有限数值，避免将 NaN 等特殊值误当普通测量。",
    objective: "能解释负数在四种取整方法下的差异，并按业务选择方向。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "负数的 floor 比原数更小，不是简单删除小数部分。",
      "round 的半整数规则不是银行家舍入，财务契约应另行确认。",
    ],
    code: r'''
void main() {
  print('值 round floor ceil truncate');
  for (final value in <double>[2.7, -2.7, 2.5, -2.5]) {
    print('$value ${value.round()} ${value.floor()} ${value.ceil()} ${value.truncate()}');
  }
}
''',
    output:
        "值 round floor ceil truncate\n2.7 3 2 3 2\n-2.7 -3 -3 -2 -2\n2.5 3 2 3 2\n-2.5 -3 -3 -2 -2\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "每小时分配一个名额。把 1.2、2.0、2.1 小时的需求向上取整。再比较按完整小时计数的结果。",
        hint: "同一需求分别调用 ceil 和 floor，标签说明两个结果的业务含义。",
        answer: r'''
void main() {
  for (final hours in <double>[1.2, 2.0, 2.1]) {
    print('$hours 小时：预留 ${hours.ceil()}，完整 ${hours.floor()}');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 131：负数的舍入方向",
    exampleSummary: "数轴方向下正负小数的四类整数化结果。",
  ),
  DartLesson(
    id: "dart-lesson-132",
    chapter: "numbers-strings",
    level: "advanced",
    title: "浮点显示与分单位账本",
    summary: "观察二进制小数误差。再用整数分记录同一笔账。",
    concepts: <String>["浮点误差", "toStringAsFixed", "最小货币单位"],
    explain:
        "计算机用二进制浮点表示小数。"
        "二进制浮点无法精确表示零点一。"
        "因此两笔小数相加可能带有很小的尾差。"
        "程序先输出这个现象。再分别显示格式化文本和整数分账本。"
        "固定两位小数只改变读者看到的字符串，不会让底层 double 变成精确十进制数。"
        "若金额规则限定到分，数据进入系统时就定成整数分。"
        "后续加减始终使用 int。"
        "最后把商和余数组合成显示值。"
        "本例只处理非负分值，符号规则因此保持清楚。"
        "折扣、税率和退款还要单独约定舍入时点与负号位置。"
        "最后一刻格式化补不回累计误差。",
    objective: "能区分浮点显示修饰与精确整数累计，并按分单位输出金额。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "toStringAsFixed 返回字符串，不会修复原 double 的表示误差。",
      "把已带误差的任意金额乘一百再截断可能丢分，应在输入边界定义转换。",
    ],
    code: r'''
String money(int cents) => '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
void main() {
  final approximate = 0.1 + 0.2;
  print(approximate);
  print(approximate.toStringAsFixed(2));
  final entries = <int>[10, 20, 199, 305];
  var cents = 0;
  for (final entry in entries) cents += entry;
  print('分账本 $cents');
  print('元 ${money(cents)}');
}
''',
    output: "0.30000000000000004\n0.30\n分账本 534\n元 5.34\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "账户有 1000 分。先支付 275 分。再支付 360 分。输出每次支付后的余额。再确认余额没有变成负数。",
        hint: "余额全过程使用 int，显示时复用 money，业务断言检查余额非负。",
        answer: r'''
String money(int cents) => '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
void main() {
  var balance = 1000;
  for (final payment in [275, 360]) {
    balance -= payment;
    if (balance < 0) throw StateError('余额不足');
    print(money(balance));
  }
}
''',
      ),
    ],
    exampleTitle: "示例 132：浮点显示与分单位账本",
    exampleSummary: "浮点尾差的直接观察与整数分账本对照。",
  ),
];
