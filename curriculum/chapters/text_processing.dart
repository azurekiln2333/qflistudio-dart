import '../dart_lesson.dart';

/// Chapter `text-processing` — independently executed lessons and paired examples.
const List<DartLesson> textProcessingLessons = <DartLesson>[
  DartLesson(
    id: "dart-lesson-133",
    chapter: "text-processing",
    level: "beginner",
    title: "双指针回文校验",
    summary: "忽略 ASCII 标点与大小写，用首尾索引逐对验证回文。",
    concepts: <String>["双指针", "文本归一化", "提前返回"],
    explain:
        "回文从左向右与从右向左读取相同，例如忽略空格后的英文短句。"
        "程序先统一大小写。再按本课规则仅保留英文字母和数字。再让两个指针从首尾向中间移动。"
        "每轮只比较一对位置，一旦不同就返回 false，全部配对完成才返回 true。"
        "这样不必生成一份反转后的字符串，归一化之外的额外空间为常数。"
        "空串和单字符没有冲突的字符对，因此自然视为回文。"
        "过滤规则决定问题的含义。"
        "本例会删除中文和其他符号。"
        "所以本例只适合给定的 ASCII 文本任务。"
        "它不能声称实现所有语言的通用回文校验。"
        "示例包含成功、失败和空串边界。",
    objective: "能描述双指针循环不变量，并按固定归一化规则判断回文。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "首尾索引必须在比较后同步推进，否则会重复比较或死循环。",
      "过滤字符集合是业务规则，不能无说明地删除其他语言文字。",
    ],
    code: r'''
bool isPalindrome(String input) {
  final text = input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  var left = 0;
  var right = text.length - 1;
  while (left < right) {
    if (text[left] != text[right]) return false;
    left++;
    right--;
  }
  return true;
}
void main() {
  for (final text in ['Never odd or even', 'Dart', '', 'A1a']) {
    print('$text => ${isPalindrome(text)}');
  }
}
''',
    output: "Never odd or even => true\nDart => false\n => true\nA1a => true\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "筛选一组标题中的回文：level、paper、noon、robot。结果保留原有顺序。",
        hint: "把 isPalindrome 当作筛选条件，输出原始文本而不是归一化后的中间值。",
        answer: r'''
bool isPalindrome(String input) {
  final text = input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  var left = 0;
  var right = text.length - 1;
  while (left < right) {
    if (text[left] != text[right]) return false;
    left++;
    right--;
  }
  return true;
}
void main() {
  final selected = ['level', 'paper', 'noon', 'robot'].where(isPalindrome).toList();
  print(selected);
}
''',
      ),
    ],
    exampleTitle: "示例 133：双指针回文校验",
    exampleSummary: "首尾同步收缩的回文判断与字符过滤契约。",
  ),
  DartLesson(
    id: "dart-lesson-134",
    chapter: "text-processing",
    level: "intermediate",
    title: "排序签名判断变位词",
    summary: "把单词转换为规范排序签名，比较字符及其出现次数。",
    concepts: <String>["排序签名", "字符多重集合", "字符串比较"],
    explain:
        "变位词要求使用完全相同数量的字母，但字母出现顺序可以不同。"
        "只比较字符集合并不足够，因为集合会丢掉重复次数。"
        "本例将文本转小写并保留英文字母。再排序所有字符，得到稳定的签名。"
        "两个签名相同才判定为变位词。"
        "排序把原本分散的同类字符放在一起，也把次数信息保留在字符串长度中。"
        "程序同时显示大小写和空格可忽略的成功例子，以及集合相同但次数不同的失败例子。"
        "该方法的时间开销主要来自排序，长度为 n 的输入通常需要 O(n log n) 比较。"
        "若字符范围固定且数据量大，可以进一步改用计数表，避免为每次判断排序。",
    objective: "能通过排序签名比较字符多重集合，并识别仅比较 Set 的错误。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "toSet 会丢失重复次数，不能用集合相等代替变位词判断。",
      "必须给两个输入使用相同的大小写与过滤规则。",
    ],
    code: r'''
String signature(String input) {
  final letters = input.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '').split('');
  letters.sort();
  return letters.join();
}
bool anagrams(String a, String b) => signature(a) == signature(b);
void main() {
  print(anagrams('Listen', 'Silent'));
  print(anagrams('Dormitory', 'Dirty room'));
  print(anagrams('aab', 'abb'));
  print(signature('Dart'));
}
''',
    output: "true\ntrue\nfalse\nadrt\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "在候选列表 silent、enlist、stone、tinsel 中找出与 listen 同签名的单词。",
        hint: "目标签名只计算一次。再对每个候选计算签名进行比较。",
        answer: r'''
String signature(String input) {
  final letters = input.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '').split('');
  letters.sort();
  return letters.join();
}
bool anagrams(String a, String b) => signature(a) == signature(b);
void main() {
  final target = signature('listen');
  final matches = ['silent', 'enlist', 'stone', 'tinsel'].where((word) => signature(word) == target);
  print(matches.toList());
}
''',
      ),
    ],
    exampleTitle: "示例 134：排序签名判断变位词",
    exampleSummary: "保留字母次数的排序签名和变位词筛选。",
  ),
  DartLesson(
    id: "dart-lesson-135",
    chapter: "text-processing",
    level: "intermediate",
    title: "带标点的词频统计",
    summary: "归一化英文段落并累加词频，按单词顺序生成确定性报告。",
    concepts: <String>["分词", "Map 计数", "确定性输出"],
    explain:
        "词频统计不仅是给 Map 加一，真正的起点是明确怎样把一段文本划分成词。"
        "程序先转小写。再把连续的非英文字母数字替换为空格。"
        "这样 Dart 后面的逗号与句号不会生成不同词条。"
        "分词后跳过空项，以已有次数或零为基础累加。"
        "统计表的插入顺序来自首次出现的位置。"
        "报告需要独立的字母排序。"
        "因此把键复制到列表后排序输出，不修改词频本身。"
        "该方法适用于本课的英文日志片段。"
        "带撇号的缩写也会拆开。"
        "真实语料应重新设计分词规则。"
        "示例输出总词数与每个词的次数，方便校验分词和累计是否同时正确。",
    objective: "能把分词规则、计数过程和报告排序分开实现。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "不统一大小写会把 Dart 和 dart 计为不同词。",
      "Map 的插入顺序不等于字母顺序，报告应显式排序键。",
    ],
    code: r'''
Map<String, int> wordCounts(String input) {
  final cleaned = input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  final counts = <String, int>{};
  for (final word in cleaned.split(' ')) {
    if (word.isNotEmpty) counts[word] = (counts[word] ?? 0) + 1;
  }
  return counts;
}
void main() {
  final counts = wordCounts('Dart, dart! Offline tools; offline Dart.');
  final keys = counts.keys.toList()..sort();
  print('总词数 ${counts.values.fold<int>(0, (sum, count) => sum + count)}');
  for (final word in keys) print('$word: ${counts[word]}');
}
''',
    output: "总词数 6\ndart: 3\noffline: 2\ntools: 1\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "统计“red blue red green blue red”，只输出至少出现两次的词及其次数。",
        hint: "先调用 wordCounts。再按排序后的键筛选次数，保证报告顺序稳定。",
        answer: r'''
Map<String, int> wordCounts(String input) {
  final cleaned = input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  final counts = <String, int>{};
  for (final word in cleaned.split(' ')) {
    if (word.isNotEmpty) counts[word] = (counts[word] ?? 0) + 1;
  }
  return counts;
}
void main() {
  final counts = wordCounts('red blue red green blue red');
  final keys = counts.keys.toList()..sort();
  for (final key in keys) {
    if (counts[key]! >= 2) print('$key=${counts[key]}');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 135：带标点的词频统计",
    exampleSummary: "英文日志的标点清理、词频累计与有序报告。",
  ),
  DartLesson(
    id: "dart-lesson-136",
    chapter: "text-processing",
    level: "intermediate",
    title: "按码点统计字符频率",
    summary: "遍历 Unicode 码点统计重复字符，让 emoji 保持完整键值。",
    concepts: <String>["runes", "Map<String,int>", "键排序"],
    explain:
        "文本的 length 以 UTF-16 代码单元计数，直接逐下标统计可能把一个 emoji 拆成两个代理单元。"
        "本例选择 runes 遍历码点。"
        "再用 String.fromCharCode 把每个码点还原成统计键。"
        "因此常见的单码点 emoji 和中文都能作为完整的键累计。"
        "频率表生成后复制并排序键，输出每个键及次数。"
        "同时校验所有次数之和等于输入的码点数量。"
        "这里的排序采用 Dart 字符串比较规则，并不是按拼音排列中文。"
        "码点统计也不等于完整字素统计。"
        "带组合音标或多个码点组成的图案仍可能拆开。"
        "选择计数单位时，应先明确产品希望用户理解的“字符”是什么。",
    objective: "能以码点为统计单位生成频率表，并校验累计总数。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "String 下标返回代码单元片段，不适合直接统计所有 emoji。",
      "字符串排序不是中文拼音排序，码点也不等于字素簇。",
    ],
    code: r'''
Map<String, int> characterCounts(String text) {
  final result = <String, int>{};
  for (final rune in text.runes) {
    final key = String.fromCharCode(rune);
    result[key] = (result[key] ?? 0) + 1;
  }
  return result;
}
void main() {
  final text = 'Dart好好😀D😀';
  final counts = characterCounts(text);
  final keys = counts.keys.toList()..sort();
  for (final key in keys) print('$key:${counts[key]}');
  print('码点总数 ${counts.values.fold<int>(0, (a, b) => a + b)}');
}
''',
    output: "D:2\na:1\nr:1\nt:1\n好:2\n😀:2\n码点总数 9\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "找出“离线好好学😀😀😀”中频率最高的码点及次数。若有并列，取排序后的首次项。",
        hint: "复用 characterCounts，遍历排好序的键并且只在次数严格更大时更新。",
        answer: r'''
Map<String, int> characterCounts(String text) {
  final result = <String, int>{};
  for (final rune in text.runes) {
    final key = String.fromCharCode(rune);
    result[key] = (result[key] ?? 0) + 1;
  }
  return result;
}
void main() {
  final counts = characterCounts('离线好好学😀😀😀');
  final keys = counts.keys.toList()..sort();
  var winner = '';
  var maximum = 0;
  for (final key in keys) {
    if (counts[key]! > maximum) { winner = key; maximum = counts[key]!; }
  }
  print('$winner=$maximum');
}
''',
      ),
    ],
    exampleTitle: "示例 136：按码点统计字符频率",
    exampleSummary: "中文与单码点 emoji 的频率统计和总数校验。",
  ),
  DartLesson(
    id: "dart-lesson-137",
    chapter: "text-processing",
    level: "intermediate",
    title: "连续片段的行程编码",
    summary: "把相邻重复的大写字母编码为字母与次数，理解压缩适用条件。",
    concepts: <String>["游程编码", "相邻分组", "StringBuffer"],
    explain:
        "行程长度编码把连续相同的字符归为一个片段，例如三个 A 记作 A3。"
        "它保留顺序，因此不同位置出现的同一个字母不能像词频表那样合并。"
        "程序固定输入字母表为大写 ASCII 字母。"
        "外层索引指向当前片段起点。"
        "内层索引寻找第一个不同字符。"
        "两个索引之差就是次数。"
        "写入结果后直接跳到下一片段，保证每个输入位置只参与常数次比较。"
        "次数可能有多位，解码时不能只读取一个数字。"
        "编码并不保证缩短文本。"
        "所有字符都不相同时，附加的次数会使结果变长。"
        "是否采用压缩应该比较编码前后的大小。"
        "本例也明确让空输入得到空编码。",
    objective: "能按相邻片段实现线性游程编码，并判断何时压缩没有收益。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "不能把非相邻的相同字符合并，否则会丢失原始顺序。",
      "本格式限制字母表，若允许数字字符就需要转义或额外分隔符。",
    ],
    code: r'''
String encodeRuns(String text) {
  if (!RegExp(r'^[A-Z]*$').hasMatch(text)) throw FormatException('只接受大写字母');
  final result = StringBuffer();
  var start = 0;
  while (start < text.length) {
    var end = start + 1;
    while (end < text.length && text[end] == text[start]) end++;
    result.write('${text[start]}${end - start}');
    start = end;
  }
  return result.toString();
}
void main() {
  print(encodeRuns('AAABBCCCCDAA'));
  print(encodeRuns('XYZ'));
  print('[${encodeRuns('')}]');
}
''',
    output: "A3B2C4D1A2\nX1Y1Z1\n[]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "对 AAAAABBBBBCCCC 和 ABCD 分别编码。输出编码是否比原文更短。长度相等也算没有收益。",
        hint: "先获取编码文本。再将编码 length 与原文 length 进行严格小于比较。",
        answer: r'''
String encodeRuns(String text) {
  if (!RegExp(r'^[A-Z]*$').hasMatch(text)) throw FormatException('只接受大写字母');
  final result = StringBuffer();
  var start = 0;
  while (start < text.length) {
    var end = start + 1;
    while (end < text.length && text[end] == text[start]) end++;
    result.write('${text[start]}${end - start}');
    start = end;
  }
  return result.toString();
}
void main() {
  for (final text in ['AAAAABBBBBCCCC', 'ABCD']) {
    final packed = encodeRuns(text);
    print('$packed 有收益=${packed.length < text.length}');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 137：连续片段的行程编码",
    exampleSummary: "按连续片段扫描的大写文本 RLE 编码。",
  ),
  DartLesson(
    id: "dart-lesson-138",
    chapter: "text-processing",
    level: "intermediate",
    title: "带校验的行程解码",
    summary: "解析多位重复次数，拒绝缺失次数和零次片段，恢复原始文本。",
    concepts: <String>["格式解析", "多位数字", "FormatException"],
    explain:
        "一个可用的解码器不仅要处理正确输入，还要在格式损坏时拒绝继续猜测。"
        "本课约定每个片段由一个大写字母和一段正整数次数组成。"
        "解码时先读取字母。再连续读取所有数字。"
        "最后把次数解析为 int。"
        "这样 A12 与 A1B2 能清楚地区分。"
        "没有数字、次数为零或出现非法字母都会抛出 FormatException，调用者可把损坏记录隔离。"
        "程序给次数设置上限，防止很短的编码要求分配巨量输出内存。"
        "实际系统还需要限制全部片段的累计解压大小。"
        "StringBuffer 汇集片段，避免循环中不断复制整段结果，空编码则恢复为空文本。",
    objective: "能编写带边界与格式校验的 RLE 解码器，并解释解压资源限制。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "只读一个数字会把 A12 错解为一个 A 再遇到非法字符。",
      "压缩文本很短不代表解压结果很小，必须限制输出规模。",
    ],
    code: r'''
String decodeRuns(String packed) {
  final out = StringBuffer();
  var index = 0;
  while (index < packed.length) {
    final letter = packed[index++];
    if (!RegExp(r'^[A-Z]$').hasMatch(letter)) throw FormatException('非法字母');
    final start = index;
    while (index < packed.length && packed.codeUnitAt(index) >= 48 && packed.codeUnitAt(index) <= 57) index++;
    if (start == index) throw FormatException('缺少次数');
    final count = int.parse(packed.substring(start, index));
    if (count < 1 || count > 1000) throw FormatException('次数越界');
    out.write(letter * count);
  }
  return out.toString();
}
void main() {
  print(decodeRuns('A3B2C1'));
  print('多位次数长度 ${decodeRuns('Z12').length}');
  for (final text in ['A', 'B0']) {
    try { decodeRuns(text); } on FormatException { print('$text 无效'); }
  }
}
''',
    output: "AAABBC\n多位次数长度 12\nA 无效\nB0 无效\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把 X2Y3X1 解码后重新统计每个字母的出现次数。输出 X 和 Y 的总数。",
        hint: "解码后遍历字符累计 Map。两个非相邻的 X 片段在频率表中应相加。",
        answer: r'''
String decodeRuns(String packed) {
  final out = StringBuffer();
  var index = 0;
  while (index < packed.length) {
    final letter = packed[index++];
    if (!RegExp(r'^[A-Z]$').hasMatch(letter)) throw FormatException('非法字母');
    final start = index;
    while (index < packed.length && packed.codeUnitAt(index) >= 48 && packed.codeUnitAt(index) <= 57) index++;
    if (start == index) throw FormatException('缺少次数');
    final count = int.parse(packed.substring(start, index));
    if (count < 1 || count > 1000) throw FormatException('次数越界');
    out.write(letter * count);
  }
  return out.toString();
}
void main() {
  final counts = <String, int>{};
  for (final letter in decodeRuns('X2Y3X1').split('')) counts[letter] = (counts[letter] ?? 0) + 1;
  print(counts);
}
''',
      ),
    ],
    exampleTitle: "示例 138：带校验的行程解码",
    exampleSummary: "可拒绝损坏格式的多位次数 RLE 解码器。",
  ),
  DartLesson(
    id: "dart-lesson-139",
    chapter: "text-processing",
    level: "intermediate",
    title: "保持标点的凯撒移位",
    summary: "分别移动大小写字母，用模运算支持回绕和负向还原。",
    concepts: <String>["模运算", "字符区间", "可逆变换"],
    explain:
        "凯撒移位把字母在字母表上向前移动指定位置。"
        "越过 Z 时从 A 重新开始。"
        "本例分别识别大小写 ASCII 字母的区间。"
        "程序把字母换成零到二十五的偏移。"
        "累加位移后对二十六取模。再转回字符。"
        "数字和标点原样保留，因此文本结构保持完整。"
        "Dart 的取模结果适合用正模数做环形索引，负位移也能自然表示反向还原。"
        "程序显示加密以及用相反位移恢复原文，往返相等是检验实现的一项有效属性。"
        "这种变换只有极少的密钥选择，轻易就能枚举破解。"
        "它是字符算术练习，不适合保护密码、个人信息或其他真实秘密。",
    objective: "能实现保留非字母的环形移位，并用往返属性验证可逆性。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>["大小写要使用各自区间的起点，否则会跨到标点码值。", "凯撒移位不是现代加密，不能用于保护真实敏感数据。"],
    code: r'''
String caesar(String text, int shift) {
  final out = StringBuffer();
  for (final code in text.codeUnits) {
    final base = code >= 65 && code <= 90 ? 65 : code >= 97 && code <= 122 ? 97 : -1;
    out.writeCharCode(base < 0 ? code : base + (code - base + shift) % 26);
  }
  return out.toString();
}
void main() {
  final text = 'Zoo, Dart 3!';
  final encoded = caesar(text, 3);
  print(encoded);
  print(caesar(encoded, -3));
  print(caesar(encoded, -3) == text);
}
''',
    output: "Crr, Gduw 3!\nZoo, Dart 3!\ntrue\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "验证 ROT13 的性质：对 Hello, Zebra! 连续做两次位移 13，应恢复原文。",
        hint: "二十六字母表移动二十六位回到起点，用两次函数调用检验。",
        answer: r'''
String caesar(String text, int shift) {
  final out = StringBuffer();
  for (final code in text.codeUnits) {
    final base = code >= 65 && code <= 90 ? 65 : code >= 97 && code <= 122 ? 97 : -1;
    out.writeCharCode(base < 0 ? code : base + (code - base + shift) % 26);
  }
  return out.toString();
}
void main() {
  const text = 'Hello, Zebra!';
  final once = caesar(text, 13);
  print(once);
  print(caesar(once, 13) == text);
}
''',
      ),
    ],
    exampleTitle: "示例 139：保持标点的凯撒移位",
    exampleSummary: "区分大小写、保留标点的可逆字母环形移位。",
  ),
  DartLesson(
    id: "dart-lesson-140",
    chapter: "text-processing",
    level: "advanced",
    title: "可逆替换表与冲突校验",
    summary: "用查表进行文本替换，构造逆表时显式检测目标字符冲突。",
    concepts: <String>["Map 查表", "逆映射", "一一对应"],
    explain:
        "替换表可以把任意指定字符映射成另一种表示，比固定的字母位移更灵活。"
        "程序逐字符查 Map，命中时使用替换值。"
        "未命中则原样保留。"
        "再用一张逆表恢复只由指定字母和空格组成的示例。"
        "逆表能够正确生成的前提是每个目标字符都唯一。"
        "否则两个原字符会竞争同一个反向键。"
        "恢复时无法知道原来是哪一个。"
        "函数在发现这种冲突时立即拒绝，而不是让后写入的数据静默覆盖。"
        "即使替换表自身没有重复，原样保留的字符也可能与目标字符重合。"
        "因此往返保证还依赖输入字符域。"
        "本课明确显示这个限制，查表替换也只用于编码练习，不承担真实信息安全功能。",
    objective: "能生成经过冲突校验的逆映射。能说明可逆性对输入域的要求。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>["逆表直接覆盖重复目标键会悄悄丢失原字符。", "原样透传字符若与编码字符重合，也会造成解码歧义。"],
    code: r'''
String substitute(String text, Map<String, String> table) =>
    text.split('').map((letter) => table[letter] ?? letter).join();
Map<String, String> inverse(Map<String, String> table) {
  final result = <String, String>{};
  for (final entry in table.entries) {
    if (result.containsKey(entry.value)) throw ArgumentError('目标字符重复');
    result[entry.value] = entry.key;
  }
  return result;
}
void main() {
  final table = <String, String>{'a': '4', 'b': '8', 'e': '3'};
  final encoded = substitute('be a bee', table);
  print(encoded);
  print(substitute(encoded, inverse(table)));
  try { inverse({'a': '1', 'b': '1'}); } on ArgumentError { print('冲突已拒绝'); }
}
''',
    output: "83 4 833\nbe a bee\n冲突已拒绝\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "使用表 x→1、y→2、z→3 编码“xyz zyx”。再用自动构造的逆表恢复并比较。",
        hint: "输入只含表中的字母与空格，避免透传字符和目标字符重合。",
        answer: r'''
String substitute(String text, Map<String, String> table) =>
    text.split('').map((letter) => table[letter] ?? letter).join();
Map<String, String> inverse(Map<String, String> table) {
  final result = <String, String>{};
  for (final entry in table.entries) {
    if (result.containsKey(entry.value)) throw ArgumentError('目标字符重复');
    result[entry.value] = entry.key;
  }
  return result;
}
void main() {
  final table = <String, String>{'x': '1', 'y': '2', 'z': '3'};
  const text = 'xyz zyx';
  final packed = substitute(text, table);
  print(packed);
  print(substitute(packed, inverse(table)) == text);
}
''',
      ),
    ],
    exampleTitle: "示例 140：可逆替换表与冲突校验",
    exampleSummary: "替换字典、逆表生成与目标冲突的显式拒绝。",
  ),
  DartLesson(
    id: "dart-lesson-141",
    chapter: "text-processing",
    level: "advanced",
    title: "Luhn 校验与校验位",
    summary: "从右向左交替加倍数字，用模十校验识别输入差错。",
    concepts: <String>["Luhn", "校验位", "逆序遍历"],
    explain:
        "Luhn 是用于发现部分录入错误的校验算法，并不能证明号码真实存在或属于某个人。"
        "算法从最右边的校验位开始向左扫描。"
        "每隔一位将数字加倍，若结果超过九则减九。"
        "最后把所有贡献相加。"
        "十能整除总和时，校验通过。"
        "程序先去除允许的空格并拒绝其他非数字。"
        "这样字符码减四十八得到的是合法数字。"
        "最右位不加倍，之后通过布尔标记交替处理。"
        "案例包含同一号码的正确校验位与错误校验位，也说明短输入需要先满足最小长度约定。"
        "运算直接遍历字符串，可以保留前导零并避免将长号码当作整数造成表示范围问题。",
    objective: "能实现 Luhn 校验并解释其只能发现部分录入差错的边界。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "从右边开始的第一个数字不加倍，交替位置错了会得到不同校验。",
      "校验通过不代表号码真实有效，也不能用它验证身份或资金状态。",
    ],
    code: r'''
bool luhn(String input) {
  final digits = input.replaceAll(' ', '');
  if (digits.length < 2 || !RegExp(r'^\d+$').hasMatch(digits)) return false;
  var sum = 0;
  var doubled = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var value = digits.codeUnitAt(i) - 48;
    if (doubled) { value *= 2; if (value > 9) value -= 9; }
    sum += value;
    doubled = !doubled;
  }
  return sum % 10 == 0;
}
void main() {
  print(luhn('79927398713'));
  print(luhn('79927398714'));
  print(luhn('7992 7398 713'));
  print(luhn('12x3'));
}
''',
    output: "true\nfalse\ntrue\nfalse\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "为前缀 7992739871 找出一个校验位，拼成完整号码后再次运行 luhn 验证。",
        hint: "枚举零到九作为最后一位，找到通过校验的候选后停止。",
        answer: r'''
bool luhn(String input) {
  final digits = input.replaceAll(' ', '');
  if (digits.length < 2 || !RegExp(r'^\d+$').hasMatch(digits)) return false;
  var sum = 0;
  var doubled = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var value = digits.codeUnitAt(i) - 48;
    if (doubled) { value *= 2; if (value > 9) value -= 9; }
    sum += value;
    doubled = !doubled;
  }
  return sum % 10 == 0;
}
void main() {
  const prefix = '7992739871';
  for (var digit = 0; digit <= 9; digit++) {
    final number = '$prefix$digit';
    if (luhn(number)) { print('校验位 $digit'); print(luhn(number)); break; }
  }
}
''',
      ),
    ],
    exampleTitle: "示例 141：Luhn 校验与校验位",
    exampleSummary: "逆序交替加倍的 Luhn 录入校验和校验位搜索。",
  ),
  DartLesson(
    id: "dart-lesson-142",
    chapter: "text-processing",
    level: "advanced",
    title: "忽略引号的括号配对",
    summary: "借助栈与引号状态，区分结构括号和字符串内容中的括号。",
    concepts: <String>["栈", "词法状态", "转义字符"],
    explain:
        "校验括号配对时，只计数左右括号数量并不够。"
        "交叉嵌套也可能让数量相等。"
        "栈保存尚未匹配的左括号，遇到右括号时必须与栈顶类型对应，才能维持嵌套结构。"
        "文本里的引号又引入第二种状态：引号内部的括号只是内容，不应影响栈。"
        "本例记录当前引号与反斜杠转义，直到遇到未转义的同类引号才回到结构扫描。"
        "结束时既要求栈为空，也要求引号已经闭合。"
        "该校验器不理解注释、原始字符串或完整 Dart 语法。"
        "它只用来学习小型扫描器如何组合状态和栈。"
        "编辑器真正的语法诊断仍应交给解析器。",
    objective: "能用栈和引号状态识别错误嵌套。能说明简易校验器的语法边界。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>["只比较左右括号数量不能识别 ([)] 这样的交叉结构。", "引号内转义的引号不能提前结束字符串状态。"],
    code: r'''
bool balanced(String text) {
  final stack = <String>[];
  final pairs = <String, String>{')': '(', ']': '[', '}': '{'};
  String? quote;
  var escaped = false;
  for (final char in text.split('')) {
    if (quote != null) {
      if (escaped) { escaped = false; }
      else if (char.codeUnitAt(0) == 92) { escaped = true; }
      else if (char == quote) { quote = null; }
    } else if (char == '"' || char.codeUnitAt(0) == 39) { quote = char; }
    else if ('([{'.contains(char)) { stack.add(char); }
    else if (pairs.containsKey(char)) {
      if (stack.isEmpty || stack.removeLast() != pairs[char]) return false;
    }
  }
  return quote == null && stack.isEmpty;
}
void main() {
  print(balanced('call("[)]", [1, 2])'));
  print(balanced('([)]'));
  print(balanced('("unfinished)'));
}
''',
    output: "true\nfalse\nfalse\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "批量验证“{[()]}”、“{[}]”、“()[]{}”并统计通过数量，不因一条失败中断。",
        hint: "balanced 返回 bool，逐项打印结果后累计 true 即可。",
        answer: r'''
bool balanced(String text) {
  final stack = <String>[];
  final pairs = <String, String>{')': '(', ']': '[', '}': '{'};
  String? quote;
  var escaped = false;
  for (final char in text.split('')) {
    if (quote != null) {
      if (escaped) { escaped = false; }
      else if (char.codeUnitAt(0) == 92) { escaped = true; }
      else if (char == quote) { quote = null; }
    } else if (char == '"' || char.codeUnitAt(0) == 39) { quote = char; }
    else if ('([{'.contains(char)) { stack.add(char); }
    else if (pairs.containsKey(char)) {
      if (stack.isEmpty || stack.removeLast() != pairs[char]) return false;
    }
  }
  return quote == null && stack.isEmpty;
}
void main() {
  var accepted = 0;
  for (final text in ['{[()]}', '{[}]', '()[]{}']) {
    final ok = balanced(text);
    if (ok) accepted++;
    print('$text => $ok');
  }
  print('通过 $accepted');
}
''',
      ),
    ],
    exampleTitle: "示例 142：忽略引号的括号配对",
    exampleSummary: "结构括号栈与字符串引号状态的组合校验。",
  ),
  DartLesson(
    id: "dart-lesson-143",
    chapter: "text-processing",
    level: "intermediate",
    title: "缩写与驼峰标识拆分",
    summary: "从词组提取首字母。再把简单驼峰标识转换为可读单词。",
    concepts: <String>["首字母缩写", "字符分类", "命名转换"],
    explain:
        "缩写生成和驼峰拆分是两种方向不同的命名转换。"
        "前者从多个单词提取首字母。"
        "后者根据大写字母恢复单词边界。"
        "本例先为词组统一多余空格。再取每个词的第一个字母并转大写。"
        "另一函数从左到右扫描标识，遇到非首位的大写字母就在结果中添加空格。"
        "程序用普通英文单词构成的 loadUserProfile 演示拆分，随后转小写生成便于显示的标签。"
        "这里没有把连续大写缩写作为整体识别。"
        "因此 HTTP 会分成多个字母。"
        "这正是规则适用范围的一部分。"
        "真实命名工具应先规定缩写、数字与 Unicode 字母的边界。再扩展扫描条件。",
    objective: "能实现两种命名转换。能明确简单驼峰规则对连续大写缩写的限制。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "对空词直接取下标零会越界，提取缩写前必须过滤空项。",
      "简单的大写边界规则会拆开 HTTP 等连续大写缩写。",
    ],
    code: r'''
String initials(String text) => text.trim().split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty).map((word) => word[0].toUpperCase()).join();
String splitCamel(String name) {
  final result = StringBuffer();
  for (var i = 0; i < name.length; i++) {
    final code = name.codeUnitAt(i);
    if (i > 0 && code >= 65 && code <= 90) result.write(' ');
    result.write(name[i]);
  }
  return result.toString();
}
void main() {
  print(initials('  central   processing unit '));
  print(splitCamel('loadUserProfile'));
  print(splitCamel('loadUserProfile').toLowerCase());
}
''',
    output: "CPU\nload User Profile\nload user profile\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把 readUserProfile 转为 snake_case。再为 display name 生成首字母缩写。",
        hint: "先复用 splitCamel，统一小写后把单词间空格替换为下划线。",
        answer: r'''
String initials(String text) => text.trim().split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty).map((word) => word[0].toUpperCase()).join();
String splitCamel(String name) {
  final result = StringBuffer();
  for (var i = 0; i < name.length; i++) {
    final code = name.codeUnitAt(i);
    if (i > 0 && code >= 65 && code <= 90) result.write(' ');
    result.write(name[i]);
  }
  return result.toString();
}
void main() {
  print(splitCamel('readUserProfile').toLowerCase().replaceAll(' ', '_'));
  print(initials('display name'));
}
''',
      ),
    ],
    exampleTitle: "示例 143：缩写与驼峰标识拆分",
    exampleSummary: "英文词组缩写和简单驼峰标识的可读化。",
  ),
  DartLesson(
    id: "dart-lesson-144",
    chapter: "text-processing",
    level: "advanced",
    title: "逐段扫描模板占位符",
    summary: "按花括号边界替换字段，为缺失字段和未闭合标记指定稳定行为。",
    concepts: <String>["占位符", "游标扫描", "缺失值策略"],
    explain:
        "简单通知模板可以把固定文本与动态字段组合起来，但连续调用 replaceAll 容易让替换顺序影响结果。"
        "本例用游标逐段扫描左花括号与对应的右花括号。"
        "程序把中间内容当作字段名。"
        "它仅替换原模板中出现的占位符。"
        "缺失字段输出短横线，未闭合的左花括号则保留原文，二者是不同的错误容忍策略。"
        "新插入的字段值不会再次扫描，因此字段值里即使含有花括号，也不会意外触发第二轮替换。"
        "StringBuffer 汇集每段文本，游标每次移动到已消费区域之后，避免重复处理。"
        "这个函数不支持嵌套标记和转义语法，复杂模板需要更正式的词法与语法定义。",
    objective: "能实现不递归展开字段值的模板扫描。能区分缺失字段与残缺标记。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "反复 replaceAll 可能重新处理刚插入的字段内容，造成顺序依赖。",
      "游标没有推进到右花括号之后会重复匹配甚至无限循环。",
    ],
    code: r'''
String render(String template, Map<String, String> values) {
  final out = StringBuffer();
  var cursor = 0;
  while (cursor < template.length) {
    final open = template.indexOf('{', cursor);
    if (open < 0) { out.write(template.substring(cursor)); break; }
    final close = template.indexOf('}', open + 1);
    if (close < 0) { out.write(template.substring(cursor)); break; }
    out.write(template.substring(cursor, open));
    out.write(values[template.substring(open + 1, close)] ?? '-');
    cursor = close + 1;
  }
  return out.toString();
}
void main() {
  print(render('你好，{name}，任务 {task}，截止 {date}', {'name': '小林', 'task': '整理笔记'}));
  print(render('原样 {unfinished', {}));
  print(render('{value}', {'value': '{name}', 'name': '不会展开'}));
}
''',
    output: "你好，小林，任务 整理笔记，截止 -\n原样 {unfinished\n{name}\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "用同一模板为两个用户分别生成问候语。其中一个用户缺少城市字段。输出默认短横线。",
        hint: "循环内分别提供 Map。模板本身保持不变。缺失值交给 render 统一处理。",
        answer: r'''
String render(String template, Map<String, String> values) {
  final out = StringBuffer();
  var cursor = 0;
  while (cursor < template.length) {
    final open = template.indexOf('{', cursor);
    if (open < 0) { out.write(template.substring(cursor)); break; }
    final close = template.indexOf('}', open + 1);
    if (close < 0) { out.write(template.substring(cursor)); break; }
    out.write(template.substring(cursor, open));
    out.write(values[template.substring(open + 1, close)] ?? '-');
    cursor = close + 1;
  }
  return out.toString();
}
void main() {
  for (final user in <Map<String, String>>[{'name': '阿青', 'city': '杭州'}, {'name': '小周'}]) {
    print(render('{name} 来自 {city}', user));
  }
}
''',
      ),
    ],
    exampleTitle: "示例 144：逐段扫描模板占位符",
    exampleSummary: "带缺失值约定和残缺标记保留的通知模板。",
  ),
];
