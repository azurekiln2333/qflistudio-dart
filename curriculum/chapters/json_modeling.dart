import '../dart_lesson.dart';

/// Independent, offline programs for chapter `json-modeling`.
const List<DartLesson> jsonModelingLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-227',
    chapter: 'json-modeling',
    level: 'beginner',
    title: "读取项目清单摘要",
    summary: "把预置的 JSON 项目清单转换为可用的类型并提取摘要。",
    concepts: <String>["jsonDecode", "映射转型", "边界取值"],
    explain:
        "JSON 文本只保存通用的数据结构，读取后还需要确认每个字段在业务中的含义。本例把离线项目清单解码为字符串键映射。再分别取得名称、修订号、启用标记和功能列表。最后输出一行摘要。类型转换放在边界处，让后续代码使用明确的字符串、整数和布尔值。转换并不等于完整检查，字段缺失或类型不符仍会失败，后续课程再建立容错策略。这里的 JSON 是程序内的固定文本，并不发起任何请求，离线运行即可检查解码后的实际数据。",
    objective: "能在解码边界取得具体类型，并据此建立业务摘要。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "jsonDecode 返回 dynamic，不应让它无限传播到内部逻辑。",
      "JSON 的键必须用双引号，不能直接复制 Dart Map 字面量语法。",
    ],
    code: r'''
import 'dart:convert';
void main() {
  const text = '{"name":"离线画板","revision":3,"enabled":true,"features":["draw","export"]}';
  final manifest = jsonDecode(text) as Map<String, dynamic>;
  final name = manifest['name'] as String;
  final revision = manifest['revision'] as int;
  final enabled = manifest['enabled'] as bool;
  final features = (manifest['features'] as List<dynamic>).cast<String>();
  print('$name r$revision: ${enabled ? '启用' : '停用'}');
  print('功能 ${features.join(' / ')}');
  print('功能数 ${features.length}');
}
''',
    output: "离线画板 r3: 启用\n功能 draw / export\n功能数 2\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "增加 schema 字段读取，缺失时拒绝清单而不是默认接受。",
        hint: "先检查字段是否为整数。再继续业务处理。",
        answer: r'''
import 'dart:convert';

int readSchema(Map<String, dynamic> manifest) {
  final schema = manifest['schema'];
  if (schema is! int) throw FormatException('缺少整数 schema');
  return schema;
}
void main() {
  print(readSchema(jsonDecode('{"schema":2}') as Map<String, dynamic>));
  try { readSchema(jsonDecode('{}') as Map<String, dynamic>); }
  on FormatException { print('拒绝缺失 schema'); }
}
''',
      ),
    ],
    exampleTitle: "示例 227：读取项目清单摘要",
    exampleSummary: "运行示例。观察把预置的 JSON 项目清单转换为可用的类型并提取摘要。",
  ),
  DartLesson(
    id: 'dart-lesson-228',
    chapter: 'json-modeling',
    level: 'beginner',
    title: "编码增量修改文档",
    summary: "比较前后标量字段，只把真正变化的字段编码成紧凑 JSON。",
    concepts: <String>["jsonEncode", "增量文档", "转义字符"],
    explain:
        "序列化并不一定要把整个对象重新输出，修改文档可以只保留变化字段。本例比较任务修改前后的标量映射。程序收集值不同的键。再编码为紧凑 JSON。文本中的换行会编码为转义序列，而不会破坏 JSON 结构。空值则作为明确的字段值保留下来。这个示例约定空值代表清空字段，未出现的键代表未修改，两者含义不同。比较只适用于这里的标量值，嵌套集合需要另行定义深比较。整个修改过程使用本地数据，离线即可观察编码结果和转义行为。",
    objective: "能构造标量字段的增量文档，并区分缺失与显式空值。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["Map 的浅比较不能直接识别嵌套集合的内容相等。", "空值和没有这个键的修改语义要由协议明确规定。"],
    code: r'''
import 'dart:convert';
Map<String, Object?> patch(Map<String, Object?> before, Map<String, Object?> after) {
  final changes = <String, Object?>{};
  for (final entry in after.entries) {
    if (!before.containsKey(entry.key) || before[entry.key] != entry.value) {
      changes[entry.key] = entry.value;
    }
  }
  return changes;
}
void main() {
  final before = <String, Object?>{'title': '草稿', 'done': false, 'tag': '待办', 'owner': '小林'};
  final after = <String, Object?>{'title': '发布\n说明', 'done': true, 'tag': null, 'owner': '小林'};
  final changes = patch(before, after);
  final encoded = jsonEncode(changes);
  print(encoded);
  print('修改字段 ${changes.keys.join(', ')}');
  print('换行已转义 ${encoded.contains(r'\n')}');
}
''',
    output:
        "{\"title\":\"发布\\n说明\",\"done\":true,\"tag\":null}\n修改字段 title, done, tag\n换行已转义 true\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "增加删除键列表，列出修改前存在但修改后缺失的字段。",
        hint: "遍历 before.keys，筛选 after 不包含的键。不要与显式 null 混淆。",
        answer: r'''
import 'dart:convert';
Map<String, Object?> patch(Map<String, Object?> before, Map<String, Object?> after) {
  final changes = <String, Object?>{};
  for (final entry in after.entries) {
    if (!before.containsKey(entry.key) || before[entry.key] != entry.value) {
      changes[entry.key] = entry.value;
    }
  }
  return changes;
}

List<String> removedKeys(Map<String, Object?> before, Map<String, Object?> after) =>
    before.keys.where((key) => !after.containsKey(key)).toList();
void main() {
  print(removedKeys({'a': 1, 'b': 2}, {'a': null}));
  print(jsonEncode(patch({'a': 1, 'b': 2}, {'a': null})));
}
''',
      ),
    ],
    exampleTitle: "示例 228：编码增量修改文档",
    exampleSummary: "运行示例。观察比较前后标量字段，只把真正变化的字段编码成紧凑 JSON。",
  ),
  DartLesson(
    id: 'dart-lesson-229',
    chapter: 'json-modeling',
    level: 'intermediate',
    title: "标签数组的规范化",
    summary: "将 JSON 数组检查为字符串序列。再清理、去重并排序。",
    concepts: <String>["List.cast", "文本规范化", "去重排序"],
    explain:
        "标签输入经常包含外侧空格、大小写差异和重复项，直接保存会让后续筛选变复杂。本例先把解码后的数组转为字符串视图。再做去空格、转小写、去空项、去重和排序。每一步对应一个独立规则，最终列表既可用于显示，也能重新编码保存。cast 是按访问检查元素的视图，不会自动把数字转成字符串，因此混入错误类型时仍应拒绝。排序让输出不依赖原始标签顺序，方便比较和缓存。固定 JSON 数组可在离线运行中完整复现清洗流水线。",
    objective: "能把数组类型检查与业务清洗分成清楚的步骤。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "cast 不会自动转换元素内容，错误类型在访问时可能抛错。",
      "去重前先规范化，否则程序会把 Dart 和 dart 当成不同标签。",
    ],
    code: r'''
import 'dart:convert';
void main() {
  final decoded = jsonDecode('[" Dart ","flutter","dart","","OFFLINE"," flutter "]') as List<dynamic>;
  final strings = decoded.cast<String>();
  final tags = strings.map((value) => value.trim().toLowerCase())
      .where((value) => value.isNotEmpty).toSet().toList()..sort();
  print(tags);
  print('原始 ${strings.length}，有效唯一 ${tags.length}');
  print(jsonEncode(tags));
}
''',
    output:
        "[dart, flutter, offline]\n原始 6，有效唯一 3\n[\"dart\",\"flutter\",\"offline\"]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把长度大于十的标签单独列为拒绝项，而不是直接截断。",
        hint: "先规范化。再分别过滤合法长度和超长项。",
        answer: r'''
import 'dart:convert';

void main() {
  final normalized = [' short ', 'very-long-label'].map((s) => s.trim().toLowerCase()).toList();
  final valid = normalized.where((s) => s.isNotEmpty && s.length <= 10).toList();
  final rejected = normalized.where((s) => s.length > 10).toList();
  print(valid);
  print(rejected);
}
''',
      ),
    ],
    exampleTitle: "示例 229：标签数组的规范化",
    exampleSummary: "运行示例。观察将 JSON 数组检查为字符串序列。再清理、去重并排序。",
  ),
  DartLesson(
    id: 'dart-lesson-230',
    chapter: 'json-modeling',
    level: 'intermediate',
    title: "缺失字段与默认配置",
    summary: "用空合并补全配置，同时保留显式的 false 和零。",
    concepts: <String>["空合并", "可空转型", "默认配置"],
    explain:
        "配置字段缺失并不总是错误，协议可以为可选项定义默认值。空合并只在左值为空时使用默认值，所以能够正确保留用户明确配置的 false 或零。本例读取几份不同完整度的显示配置。它分别补全主题、动画和重试次数，显示缺失、显式空值与正常值的区别。可空类型转换仍会拒绝错误类型，默认值不是把任意脏数据都当成缺失。默认策略应集中在输入边界，内部使用完整配置。所有文本都预置在程序中，离线即可比较最终行为。",
    objective: "能正确补全可选字段，并保留 false 和零等合法值。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "不要用真假判断代替 ??，否则会覆盖 false 和零。",
      "字段类型错误和字段缺失应区分处理，不能无条件降级。",
    ],
    code: r'''
import 'dart:convert';
void main() {
  for (final text in ['{}', '{"theme":"dark","animations":false,"retries":0}',
      '{"theme":null,"retries":2}']) {
    final map = jsonDecode(text) as Map<String, dynamic>;
    final theme = map['theme'] as String? ?? 'light';
    final animations = map['animations'] as bool? ?? true;
    final retries = map['retries'] as int? ?? 3;
    print('主题=$theme，动画=$animations，重试=$retries');
  }
}
''',
    output:
        "主题=light，动画=true，重试=3\n主题=dark，动画=false，重试=0\n主题=light，动画=true，重试=2\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "区分键缺失和键存在但值为 null，输出两种来源。",
        hint: "containsKey 用于判断存在性，不能只比较取到的值。",
        answer: r'''
import 'dart:convert';

String sourceOf(Map<String, dynamic> map, String key) {
  if (!map.containsKey(key)) return '缺失';
  return map[key] == null ? '显式空值' : '有值';
}
void main() {
  for (final text in ['{}', '{"theme":null}', '{"theme":"dark"}']) {
    print(sourceOf(jsonDecode(text) as Map<String, dynamic>, 'theme'));
  }
}
''',
      ),
    ],
    exampleTitle: "示例 230：缺失字段与默认配置",
    exampleSummary: "运行示例。观察用空合并补全配置，同时保留显式的 false 和零。",
  ),
  DartLesson(
    id: 'dart-lesson-231',
    chapter: 'json-modeling',
    level: 'intermediate',
    title: "逐层读取课程进度",
    summary: "在嵌套对象边界逐层转型。再计算完成比例。",
    concepts: <String>["嵌套映射", "逐层转型", "分母守卫"],
    explain:
        "嵌套 JSON 的每一层都可能是不同结构，不能因为顶层是映射，就假定更深字段也符合预期。本例从课程对象进入进度对象。程序逐层取得映射。再读取已完成与总课数。最后计算百分比。变量名保留所在层级，使访问路径比一串动态下标更清楚。总课数为零时给出明确的零比例，避免产生无穷或非数值。这里假定字段类型遵守协议，若需要导入不可信数据，应为每层增加结构检查。程序只读取预置文本，离线可以观察数据到显示指标的完整转换。",
    objective: "能按层次建立类型边界，并保护比例计算的分母。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["不要把多层动态下标连写到业务深处，错误难以定位。", "总数为零时必须明确比例含义，不能直接相除。"],
    code: r'''
import 'dart:convert';
void main() {
  const text = '{"course":{"title":"离线 Dart","progress":{"completed":3,"total":8}}}';
  final root = jsonDecode(text) as Map<String, dynamic>;
  final course = root['course'] as Map<String, dynamic>;
  final progress = course['progress'] as Map<String, dynamic>;
  final completed = progress['completed'] as int;
  final total = progress['total'] as int;
  if (completed < 0 || total < completed) throw FormatException('进度范围无效');
  final percent = total == 0 ? 0.0 : completed * 100 / total;
  print(course['title']);
  print('$completed / $total');
  print('${percent.toStringAsFixed(1)}%');
}
''',
    output: "离线 Dart\n3 / 8\n37.5%\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "写一个读取嵌套映射的辅助函数。让缺失层抛出带路径的格式错误。",
        hint: "检查取到的值是否为 Map<String,dynamic>，失败时带上路径。",
        answer: r'''
import 'dart:convert';

Map<String, dynamic> requireObject(Map<String, dynamic> parent, String key, String path) {
  final value = parent[key];
  if (value is! Map<String, dynamic>) throw FormatException('$path.$key 需要对象');
  return value;
}
void main() {
  final root = jsonDecode('{"course":{"progress":{"completed":3}}}') as Map<String, dynamic>;
  final course = requireObject(root, 'course', 'root');
  print(requireObject(course, 'progress', 'root.course')['completed']);
  try { requireObject(course, 'settings', 'root.course'); }
  on FormatException catch (error) { print(error.message); }
}
''',
      ),
    ],
    exampleTitle: "示例 231：逐层读取课程进度",
    exampleSummary: "运行示例。观察在嵌套对象边界逐层转型。再计算完成比例。",
  ),
  DartLesson(
    id: 'dart-lesson-232',
    chapter: 'json-modeling',
    level: 'intermediate',
    title: "把配送清单映射为领域对象",
    summary: "让 JSON 数组只在入口解析一次，内部使用包裹对象计算运费。",
    concepts: <String>["数组映射", "工厂构造", "领域行为"],
    explain:
        "如果每次计算都从动态映射取字段，键名和类型检查就会散落在业务代码中。把边界数据映射成领域对象后，内部可以使用明确字段和计算属性。本例让包裹工厂读取编号与重量，把 JSON 数值统一转换为 double。再由对象按向上取整的重量计算费用。数组映射完成后，遍历和合计都不再需要了解 JSON 键名。入口还拒绝非正重量，保证后续计算不必重复防守。清单为本地固定文本，离线即可运行实际转换和费用聚合。",
    objective: "能将解码数组转换为类型明确的对象列表。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "JSON 整数和小数可能分别解码为 int 与 double，通用数值先按 num 处理。",
      "工厂构造应建立领域不变量，不要把非法值直接交给业务方法。",
    ],
    code: r'''
import 'dart:convert';
class Parcel {
  Parcel(this.id, this.kilograms);
  final String id;
  final double kilograms;
  factory Parcel.fromJson(Map<String, dynamic> map) {
    final weight = (map['kg'] as num).toDouble();
    if (weight <= 0) throw FormatException('重量必须为正');
    return Parcel(map['id'] as String, weight);
  }
  int get feeCents => 400 + kilograms.ceil() * 150;
}
void main() {
  final raw = jsonDecode('[{"id":"A","kg":1},{"id":"B","kg":1.2},{"id":"C","kg":2.5}]') as List<dynamic>;
  final parcels = raw.map((row) => Parcel.fromJson(row as Map<String, dynamic>)).toList();
  for (final parcel in parcels) { print('${parcel.id}: ${parcel.feeCents} 分'); }
  print('合计 ${parcels.fold<int>(0, (sum, parcel) => sum + parcel.feeCents)} 分');
}
''',
    output: "A: 550 分\nB: 700 分\nC: 850 分\n合计 2100 分\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "增加免费重量上限。低于或等于一公斤时不收额外重量费。",
        hint: "将额外计费重量定义为 ceil 后减一。再保护零下界。",
        answer: r'''
import 'dart:convert';
class Parcel {
  Parcel(this.id, this.kilograms);
  final String id;
  final double kilograms;
  factory Parcel.fromJson(Map<String, dynamic> map) {
    final weight = (map['kg'] as num).toDouble();
    if (weight <= 0) throw FormatException('重量必须为正');
    return Parcel(map['id'] as String, weight);
  }
  int get feeCents => 400 + kilograms.ceil() * 150;
}

int revisedFee(Parcel parcel) {
  final additional = parcel.kilograms.ceil() - 1;
  return 400 + (additional > 0 ? additional : 0) * 150;
}
void main() {
  for (final weight in [0.5, 1.0, 1.2, 2.5]) { print(revisedFee(Parcel('A', weight))); }
}
''',
      ),
    ],
    exampleTitle: "示例 232：把配送清单映射为领域对象",
    exampleSummary: "运行示例。观察让 JSON 数组只在入口解析一次，内部使用包裹对象计算运费。",
  ),
  DartLesson(
    id: 'dart-lesson-233',
    chapter: 'json-modeling',
    level: 'intermediate',
    title: "对象列表的 JSON 往返",
    summary: "显式定义对象与映射的双向转换，逐字段验证保存后可还原。",
    concepts: <String>["toJson", "fromJson", "往返契约"],
    explain:
        "保存领域对象时，应明确哪些字段进入格式以及如何还原，而不是依赖调试字符串。本例为便笺条目定义映射导出和工厂导入。程序把对象列表编码成 JSON。再解码回新的对象列表。往返检查逐项比较编号、文字和完成标记。检查不使用对象引用相等，也不把 JSON 键顺序当作语义。这样的契约可以在格式修改时提供基础回归证据。新增字段时要同时考虑默认值和旧数据迁移。所有编码文本都由程序本地写出，离线运行能验证实际保存与还原。",
    objective: "能建立双向映射，并按字段验证往返不丢信息。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "两个对象即使内容相同，引用通常也不相等，不能直接比较两个列表。",
      "只写导出而不设计导入，格式很容易随着内部类变化而失控。",
    ],
    code: r'''
import 'dart:convert';
class NoteItem {
  const NoteItem(this.id, this.text, this.done);
  final int id;
  final String text;
  final bool done;
  Map<String, Object> toJson() => {'id': id, 'text': text, 'done': done};
  factory NoteItem.fromJson(Map<String, dynamic> map) =>
      NoteItem(map['id'] as int, map['text'] as String, map['done'] as bool);
}
void main() {
  final notes = [NoteItem(1, '读书', false), NoteItem(2, '整理笔记', true)];
  final encoded = jsonEncode(notes.map((note) => note.toJson()).toList());
  final raw = jsonDecode(encoded) as List<dynamic>;
  final restored = raw.map((row) => NoteItem.fromJson(row as Map<String, dynamic>)).toList();
  var same = restored.length == notes.length;
  for (var i = 0; same && i < notes.length; i++) {
    same = notes[i].id == restored[i].id && notes[i].text == restored[i].text &&
        notes[i].done == restored[i].done;
  }
  print(encoded);
  print('往返字段一致 $same');
  print('待办 ${restored.where((note) => !note.done).length} 项');
}
''',
    output:
        "[{\"id\":1,\"text\":\"读书\",\"done\":false},{\"id\":2,\"text\":\"整理笔记\",\"done\":true}]\n往返字段一致 true\n待办 1 项\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "兼容旧条目缺少 done 字段，按未完成处理。",
        hint: "工厂导入使用可空布尔转换和默认值。导出仍始终写出 done。",
        answer: r'''
import 'dart:convert';
class NoteItem {
  const NoteItem(this.id, this.text, this.done);
  final int id;
  final String text;
  final bool done;
  Map<String, Object> toJson() => {'id': id, 'text': text, 'done': done};
  factory NoteItem.fromJson(Map<String, dynamic> map) =>
      NoteItem(map['id'] as int, map['text'] as String, map['done'] as bool);
}

NoteItem readLegacyNote(Map<String, dynamic> map) =>
    NoteItem(map['id'] as int, map['text'] as String, map['done'] as bool? ?? false);
void main() {
  final map = jsonDecode('{"id":3,"text":"旧便笺"}') as Map<String, dynamic>;
  final note = readLegacyNote(map);
  print(note.done);
  print(jsonEncode(note.toJson()));
}
''',
      ),
    ],
    exampleTitle: "示例 233：对象列表的 JSON 往返",
    exampleSummary: "运行示例。观察显式定义对象与映射的双向转换，逐字段验证保存后可还原。",
  ),
  DartLesson(
    id: 'dart-lesson-234',
    chapter: 'json-modeling',
    level: 'intermediate',
    title: "数字字段与数字字符串",
    summary: "对比严格转型和明确的兼容解析，拒绝悄悄截断小数。",
    concepts: <String>["类型断言", "兼容解析", "数据契约"],
    explain:
        "JSON 中的数字四和字符串形式的四是不同类型，类型断言不会替你解析文本。本例先尝试严格读取整数，观察字符串、小数和空值的失败。随后使用显式兼容函数。它只接受整数或可解析的整数字符串。程序仍拒绝小数，避免偷偷截断造成数量损失。兼容规则应由协议决定，而不是遇到任何值都调用 toString 再解析。两轮结果让读者直接看出断言与转换的区别。全部输入写在本地 JSON 数组中，离线运行即可检查每种类型的处理。",
    objective: "能区分 as 转型和内容解析，并设计明确的数值兼容范围。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "as int 不会把字符串变成整数。",
      "把小数 toInt 会截断信息，数量字段应先明确是否允许这种行为。",
    ],
    code: r'''
import 'dart:convert';
int readQuantity(Object? value) {
  if (value is int) return value;
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('需要整数或整数字符串');
}
void main() {
  final rows = jsonDecode('[{"qty":3},{"qty":"4"},{"qty":2.5},{"qty":null}]') as List<dynamic>;
  for (final row in rows) {
    final value = (row as Map<String, dynamic>)['qty'];
    try { print('严格 ${value as int}'); }
    on TypeError { print('严格拒绝'); }
    try { print('兼容 ${readQuantity(value)}'); }
    on FormatException { print('兼容拒绝'); }
  }
}
''',
    output: "严格 3\n兼容 3\n严格拒绝\n兼容 4\n严格拒绝\n兼容拒绝\n严格拒绝\n兼容拒绝\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "让兼容函数拒绝负数量，同时仍接受字符串零。",
        hint: "成功解析后统一检查下界，不要只检查一种输入类型。",
        answer: r'''
import 'dart:convert';
int readQuantity(Object? value) {
  if (value is int) return value;
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('需要整数或整数字符串');
}

int nonNegativeQuantity(Object? raw) {
  final value = readQuantity(raw);
  if (value < 0) throw FormatException('数量不能为负');
  return value;
}
void main() {
  print(nonNegativeQuantity('0'));
  try { nonNegativeQuantity(-1); }
  on FormatException { print('拒绝负数量'); }
}
''',
      ),
    ],
    exampleTitle: "示例 234：数字字段与数字字符串",
    exampleSummary: "运行示例。观察对比严格转型和明确的兼容解析，拒绝悄悄截断小数。",
  ),
  DartLesson(
    id: 'dart-lesson-235',
    chapter: 'json-modeling',
    level: 'advanced',
    title: "递归拍平嵌套 JSON",
    summary: "用点号与数组索引构造路径，保留叶子值和空容器。",
    concepts: <String>["递归遍历", "路径编码", "空容器"],
    explain:
        "排查深层配置时，路径到值的平面表比反复展开嵌套对象更容易搜索。本例递归遍历映射和列表。它把对象层级写成点号路径，把数组位置写成方括号索引。普通值则成为叶子。空对象和空数组没有子项，也需要显式保留，否则拍平会悄悄丢失它们存在过的信息。示例的键不含点号或方括号，真实通用格式还需要定义转义以免路径碰撞。递归深度也应受输入约束。固定树结构只在内存中处理，离线即可复现路径结构。",
    objective: "能递归处理对象和数组，并保留空结构。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["不处理空容器会丢失数据结构信息。", "路径分隔符若也出现在原键名中，需要定义转义规则。"],
    code: r'''
import 'dart:convert';
void flatten(Object? value, String path, Map<String, Object?> output) {
  if (value is Map<String, dynamic>) {
    if (value.isEmpty) output[path] = value;
    for (final entry in value.entries) {
      flatten(entry.value, path.isEmpty ? entry.key : '$path.${entry.key}', output);
    }
  } else if (value is List<dynamic>) {
    if (value.isEmpty) output[path] = value;
    for (var i = 0; i < value.length; i++) { flatten(value[i], '$path[$i]', output); }
  } else { output[path] = value; }
}
void main() {
  final data = jsonDecode('{"app":{"name":"工具","flags":{"debug":false}},"servers":[{"host":"a"},{"host":"b"}],"empty":{}}');
  final output = <String, Object?>{};
  flatten(data, '', output);
  for (final entry in output.entries) { print('${entry.key}=${jsonEncode(entry.value)}'); }
}
''',
    output:
        "app.name=\"工具\"\napp.flags.debug=false\nservers[0].host=\"a\"\nservers[1].host=\"b\"\nempty={}\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "增加最大递归深度，超过时抛出格式异常。",
        hint: "递归函数加入 depth 参数。每深入一层加一，在入口比较上限。",
        answer: r'''
import 'dart:convert';
void flatten(Object? value, String path, Map<String, Object?> output) {
  if (value is Map<String, dynamic>) {
    if (value.isEmpty) output[path] = value;
    for (final entry in value.entries) {
      flatten(entry.value, path.isEmpty ? entry.key : '$path.${entry.key}', output);
    }
  } else if (value is List<dynamic>) {
    if (value.isEmpty) output[path] = value;
    for (var i = 0; i < value.length; i++) { flatten(value[i], '$path[$i]', output); }
  } else { output[path] = value; }
}

void checkDepth(Object? value, int depth, int maximum) {
  if (depth > maximum) throw FormatException('嵌套过深');
  if (value is Map<String, dynamic>) {
    for (final child in value.values) { checkDepth(child, depth + 1, maximum); }
  } else if (value is List<dynamic>) {
    for (final child in value) { checkDepth(child, depth + 1, maximum); }
  }
}
void main() {
  final value = jsonDecode('{"a":{"b":1}}');
  checkDepth(value, 0, 2);
  print('允许两层');
  try { checkDepth(value, 0, 1); }
  on FormatException { print('拒绝超过一层'); }
}
''',
      ),
    ],
    exampleTitle: "示例 235：递归拍平嵌套 JSON",
    exampleSummary: "运行示例。观察用点号与数组索引构造路径，保留叶子值和空容器。",
  ),
  DartLesson(
    id: 'dart-lesson-236',
    chapter: 'json-modeling',
    level: 'advanced',
    title: "按事件类型聚合导入日志",
    summary: "从 JSON 记录流计算每类事件的次数、总时长与均值。",
    concepts: <String>["数组记录", "分组累加", "派生指标"],
    explain:
        "结构化日志的价值不仅在于逐条查看，也在于从多条记录中提取统计。本例把本地 JSON 事件数组按类型分组。程序同时累计次数和秒数。最后计算各组平均时长。解码字段只在循环入口读取，聚合表保存明确的整数指标，显示阶段再计算小数均值。均值不应把不同类别混在一起，也不能拿总时长除以全部事件数来代替某一组均值。输出顺序沿首次出现顺序，便于检查固定输入。程序没有采集真实用户日志，离线运行即可复现全部分组计算。",
    objective: "能从 JSON 记录建立分组指标，并为每组使用正确分母。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["组内均值的分母必须是该组次数。", "日志时间单位要统一，秒与毫秒不能直接相加。"],
    code: r'''
import 'dart:convert';
void main() {
  final events = jsonDecode('[{"kind":"read","seconds":12},{"kind":"edit","seconds":30},'
      '{"kind":"read","seconds":18},{"kind":"export","seconds":6},{"kind":"edit","seconds":10}]') as List<dynamic>;
  final stats = <String, Map<String, int>>{};
  for (final raw in events) {
    final event = raw as Map<String, dynamic>;
    final kind = event['kind'] as String;
    final seconds = event['seconds'] as int;
    final group = stats.putIfAbsent(kind, () => <String, int>{'count': 0, 'seconds': 0});
    group['count'] = group['count']! + 1;
    group['seconds'] = group['seconds']! + seconds;
  }
  for (final entry in stats.entries) {
    final count = entry.value['count']!;
    final total = entry.value['seconds']!;
    print('${entry.key}: $count 次，合计 $total 秒，均值 ${(total / count).toStringAsFixed(1)} 秒');
  }
}
''',
    output:
        "read: 2 次，合计 30 秒，均值 15.0 秒\nedit: 2 次，合计 40 秒，均值 20.0 秒\nexport: 1 次，合计 6 秒，均值 6.0 秒\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "每组增加最长单次时长，并与平均时长一同输出。",
        hint: "聚合表增加 max 字段，每条事件更新较大值。",
        answer: r'''
import 'dart:convert';
void accumulate(Map<String, int> group, int seconds) {
  group['count'] = (group['count'] ?? 0) + 1;
  group['seconds'] = (group['seconds'] ?? 0) + seconds;
  final previous = group['max'] ?? 0;
  group['max'] = seconds > previous ? seconds : previous;
}
void main() {
  final events = jsonDecode('[{"kind":"read","seconds":12},{"kind":"edit","seconds":30},'
    '{"kind":"read","seconds":18},{"kind":"edit","seconds":10}]') as List<dynamic>;
  final stats = <String, Map<String, int>>{};
  for (final raw in events) {
    final row = raw as Map<String, dynamic>;
    final group = stats.putIfAbsent(row['kind'] as String, () => <String, int>{});
    accumulate(group, row['seconds'] as int);
  }
  for (final entry in stats.entries) {
    print('${entry.key}: 最长 ${entry.value['max']} 秒，均值 ${(entry.value['seconds']! / entry.value['count']!).toStringAsFixed(1)} 秒');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 236：按事件类型聚合导入日志",
    exampleSummary: "运行示例。观察从 JSON 记录流计算每类事件的次数、总时长与均值。",
  ),
  DartLesson(
    id: 'dart-lesson-237',
    chapter: 'json-modeling',
    level: 'advanced',
    title: "深层配置合并",
    summary: "递归合并对象、整体替换数组，并保持默认配置不变。",
    concepts: <String>["递归合并", "深复制", "覆盖策略"],
    explain:
        "简单的外层映射覆盖会把整个嵌套配置替换掉，连未修改的默认字段也一起丢失。本例规定对象递归合并、数组整体替换、标量和空值直接覆盖。它再通过深复制避免结果与默认配置共享可变容器。输入分别来自两段 JSON，输出显示嵌套端口更新后主机名仍保留。随后修改合并结果的数组，确认默认数组没有变化。合并规则不是唯一标准，必须先写清楚空值、数组和类型冲突的含义。所有配置都保存在本地固定文本中，离线可检查规则。",
    objective: "能实现明确的深层覆盖规则，并避免修改原始配置。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["浅复制只保护外层，嵌套容器仍可能共享。", "数组追加与整体替换属于不同协议，不能模糊处理。"],
    code: r'''
import 'dart:convert';
Object? clone(Object? value) {
  if (value is Map<String, dynamic>) {
    return <String, dynamic>{for (final entry in value.entries) entry.key: clone(entry.value)};
  }
  if (value is List<dynamic>) return value.map(clone).toList();
  return value;
}
Map<String, dynamic> merge(Map<String, dynamic> base, Map<String, dynamic> override) {
  final result = clone(base) as Map<String, dynamic>;
  for (final entry in override.entries) {
    final previous = result[entry.key];
    final next = entry.value;
    result[entry.key] = previous is Map<String, dynamic> && next is Map<String, dynamic>
        ? merge(previous, next) : clone(next);
  }
  return result;
}
void main() {
  final base = jsonDecode('{"server":{"host":"local","port":3000},"tags":["base"],"theme":"light"}') as Map<String, dynamic>;
  final override = jsonDecode('{"server":{"port":4000},"tags":["custom"],"theme":null}') as Map<String, dynamic>;
  final result = merge(base, override);
  print(jsonEncode(result));
  (result['tags'] as List<dynamic>).add('extra');
  print('默认标签 ${base['tags']}');
  print('默认端口 ${(base['server'] as Map<String, dynamic>)['port']}');
}
''',
    output:
        "{\"server\":{\"host\":\"local\",\"port\":4000},\"tags\":[\"custom\"],\"theme\":null}\n默认标签 [base]\n默认端口 3000\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把空值规则改为删除键，且不影响其他覆盖策略。",
        hint: "处理 entry.value 为 null 时 remove 并 continue。再走原分支。",
        answer: r'''
import 'dart:convert';
Object? clone(Object? value) {
  if (value is Map<String, dynamic>) {
    return <String, dynamic>{for (final entry in value.entries) entry.key: clone(entry.value)};
  }
  if (value is List<dynamic>) return value.map(clone).toList();
  return value;
}
Map<String, dynamic> merge(Map<String, dynamic> base, Map<String, dynamic> override) {
  final result = clone(base) as Map<String, dynamic>;
  for (final entry in override.entries) {
    if (entry.value == null) {
      result.remove(entry.key);
      continue;
    }
    final previous = result[entry.key];
    final next = entry.value;
    result[entry.key] = previous is Map<String, dynamic> && next is Map<String, dynamic>
        ? merge(previous, next) : clone(next);
  }
  return result;
}
void main() {
  final base = jsonDecode('{"server":{"host":"local","port":3000},"tags":["base"],"theme":"light"}') as Map<String, dynamic>;
  final override = jsonDecode('{"server":{"port":4000},"tags":["custom"],"theme":null}') as Map<String, dynamic>;
  final result = merge(base, override);
  print(jsonEncode(result));
  (result['tags'] as List<dynamic>).add('extra');
  print('默认标签 ${base['tags']}');
  print('默认端口 ${(base['server'] as Map<String, dynamic>)['port']}');
}
''',
      ),
    ],
    exampleTitle: "示例 237：深层配置合并",
    exampleSummary: "运行示例。观察递归合并对象、整体替换数组，并保持默认配置不变。",
  ),
  DartLesson(
    id: 'dart-lesson-238',
    chapter: 'json-modeling',
    level: 'advanced',
    title: "脏数据清洗与拒绝报告",
    summary: "按明确顺序检查导入记录，保留规范化数据并统计拒绝原因。",
    concepts: <String>["结构校验", "规范化", "拒绝统计"],
    explain:
        "导入不可信 JSON 时，清洗规则必须同时说明接受什么、如何规范化以及拒绝什么。本例先检查记录结构。程序再处理商品编号和数量。最后识别规范化后的重复编号。程序明确解析合法整数字符串。它拒绝负数、空编号和重复记录。每条记录只计第一个失败原因，报表因此不会重复计数。接受项重新编码成统一格式，读者可以检查原始数量与最终条数是否守恒。清洗不会静默修复任意类型，也不覆盖先前的同编号记录。输入为本地固定数组，离线可复现完整报告。",
    objective: "能建立有序的清洗规则，让接受数与拒绝数对应原始记录。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "重复检测要在编号规范化之后进行。",
      "一条记录多个问题时，应明确计首个原因还是全部原因，避免统计含义不清。",
    ],
    code: r'''
import 'dart:convert';
void main() {
  final raw = jsonDecode('[{"sku":" pen ","qty":2},{"sku":"","qty":3},'
      '{"sku":"BOOK","qty":"4"},null,{"sku":"PEN","qty":1},{"sku":"INK","qty":-1}]') as List<dynamic>;
  final accepted = <Map<String, Object>>[];
  final rejected = <String, int>{};
  final seen = <String>{};
  void reject(String reason) { rejected[reason] = (rejected[reason] ?? 0) + 1; }
  for (final row in raw) {
    if (row is! Map<String, dynamic>) { reject('结构错误'); continue; }
    final sku = row['sku'];
    if (sku is! String || sku.trim().isEmpty) { reject('空编号'); continue; }
    final normalized = sku.trim().toUpperCase();
    final quantity = row['qty'] is int ? row['qty'] as int : int.tryParse('${row['qty']}');
    if (quantity == null || quantity < 0) { reject('数量无效'); continue; }
    if (!seen.add(normalized)) { reject('编号重复'); continue; }
    accepted.add({'sku': normalized, 'qty': quantity});
  }
  print(jsonEncode(accepted));
  for (final entry in rejected.entries) { print('${entry.key}: ${entry.value}'); }
  final dropped = rejected.values.fold<int>(0, (sum, count) => sum + count);
  print('接受 ${accepted.length}，拒绝 $dropped，原始 ${raw.length}');
}
''',
    output:
        "[{\"sku\":\"PEN\",\"qty\":2},{\"sku\":\"BOOK\",\"qty\":4}]\n空编号: 1\n结构错误: 1\n编号重复: 1\n数量无效: 1\n接受 2，拒绝 4，原始 6\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "给清洗报告保留每个拒绝项的原始行号。",
        hint: "循环改成索引遍历。reject 接收行号，并把详情加入另一张列表。",
        answer: r'''
import 'dart:convert';
void main() {
  final raw = jsonDecode('[{"sku":" pen ","qty":2},{"sku":"","qty":3},'
      '{"sku":"BOOK","qty":"4"},null,{"sku":"PEN","qty":1},{"sku":"INK","qty":-1}]') as List<dynamic>;
  final accepted = <Map<String, Object>>[];
  final rejected = <String, int>{};
  final seen = <String>{};
  var rowIndex = 0;
  final details = <String>[];
  void reject(String reason) {
    rejected[reason] = (rejected[reason] ?? 0) + 1;
    details.add('第 ${rowIndex + 1} 行: $reason');
  }
  for (rowIndex = 0; rowIndex < raw.length; rowIndex++) {
    final row = raw[rowIndex];
    if (row is! Map<String, dynamic>) { reject('结构错误'); continue; }
    final sku = row['sku'];
    if (sku is! String || sku.trim().isEmpty) { reject('空编号'); continue; }
    final normalized = sku.trim().toUpperCase();
    final quantity = row['qty'] is int ? row['qty'] as int : int.tryParse('${row['qty']}');
    if (quantity == null || quantity < 0) { reject('数量无效'); continue; }
    if (!seen.add(normalized)) { reject('编号重复'); continue; }
    accepted.add({'sku': normalized, 'qty': quantity});
  }
  print(jsonEncode(accepted));
  for (final entry in rejected.entries) { print('${entry.key}: ${entry.value}'); }
  final dropped = rejected.values.fold<int>(0, (sum, count) => sum + count);
  print('接受 ${accepted.length}，拒绝 $dropped，原始 ${raw.length}');
  for (final detail in details) { print(detail); }
}
''',
      ),
    ],
    exampleTitle: "示例 238：脏数据清洗与拒绝报告",
    exampleSummary: "运行示例。观察按明确顺序检查导入记录，保留规范化数据并统计拒绝原因。",
  ),
];
