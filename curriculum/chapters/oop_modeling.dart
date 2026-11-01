import '../dart_lesson.dart';

/// Independent, offline programs for chapter `oop-modeling`.
const List<DartLesson> oopModelingLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-193',
    chapter: 'oop-modeling',
    level: 'beginner',
    title: "网格位置的值相等",
    summary: "把坐标建模为不可变值对象，并保持相等与哈希一致。",
    concepts: <String>["值对象", "operator ==", "hashCode"],
    explain:
        "两个位置对象只要行列相同，就应代表同一个网格位置，而不必是同一次构造的对象。值对象把这种业务相等性写进相等运算符，并用参与比较的同一组字段算出哈希值。本例使用不可变坐标，分别比较同坐标、异坐标和不同类型的值。程序再验证相等对象拥有相等哈希。哈希相同不反过来保证对象相等，因此不能只比较哈希。字段保持不可变，也避免对象作为查找键时位置失效。代码只用语言本地能力，离线运行即可观察完整比较。",
    objective: "能实现类型安全的值相等，并维护哈希契约。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["相等对象必须有相同哈希，反向推论不成立。", "参与相等比较的字段若可变，会破坏哈希集合的查找。"],
    code: r'''
class GridCell {
  const GridCell(this.row, this.column);
  final int row;
  final int column;
  @override
  bool operator ==(Object other) =>
      other is GridCell && row == other.row && column == other.column;
  @override
  int get hashCode => Object.hash(row, column);
}
void main() {
  final first = GridCell(2, 5);
  final same = GridCell(2, 5);
  final next = GridCell(2, 6);
  print(first == same);
  print(first == next);
  print(first == '2,5');
  print(first.hashCode == same.hashCode);
}
''',
    output: "true\nfalse\nfalse\ntrue\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "为 GridCell 增加平移方法，返回新对象而不修改原位置。",
        hint: "用两个偏移量构造新的行列值。",
        answer: r'''
class GridCell {
  const GridCell(this.row, this.column);
  final int row;
  final int column;
  @override
  bool operator ==(Object other) =>
      other is GridCell && row == other.row && column == other.column;
  @override
  int get hashCode => Object.hash(row, column);
}

GridCell translated(GridCell cell, int rows, int columns) =>
    GridCell(cell.row + rows, cell.column + columns);
void main() {
  final original = GridCell(2, 5);
  print(translated(original, -1, 3) == GridCell(1, 8));
  print(original == GridCell(2, 5));
}
''',
      ),
    ],
    exampleTitle: "示例 193：网格位置的值相等",
    exampleSummary: "运行示例。观察把坐标建模为不可变值对象，并保持相等与哈希一致。",
  ),
  DartLesson(
    id: 'dart-lesson-194',
    chapter: 'oop-modeling',
    level: 'intermediate',
    title: "让领域对象输出可读日志",
    summary: "用结构化的 toString 显示库存快照，而不依赖默认实例名称。",
    concepts: <String>["toString", "组合对象", "日志可读性"],
    explain:
        "默认的对象输出只能说明它属于哪个类，往往不足以定位业务数据问题。重写字符串表示时，可以选择少量最有意义的字段，形成稳定且容易辨认的调试描述。本例把库存数量和预留数量封装为快照。对象额外提供可用数量计算属性。日志因此同时显示原始数据与派生结果。字符串表示用于帮助读者理解状态，不作为持久化协议，也不应放入密码等敏感信息。通过一组快照输出能直接校验预留变化的影响。程序无外部依赖，离线可复现日志内容。",
    objective: "能设计包含关键业务状态的字符串表示。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "不要把 toString 当成可长期解析的数据格式。",
      "日志字段要经过选择，避免泄露敏感信息或输出巨大对象图。",
    ],
    code: r'''
class StockSnapshot {
  const StockSnapshot(this.sku, this.onHand, this.reserved);
  final String sku;
  final int onHand;
  final int reserved;
  int get available => onHand - reserved;
  @override
  String toString() => 'Stock($sku: 库存=$onHand, 预留=$reserved, 可用=$available)';
}
void main() {
  final snapshots = [StockSnapshot('PEN', 20, 3), StockSnapshot('BOOK', 8, 8)];
  for (final snapshot in snapshots) { print(snapshot); }
  print('可发货 ${snapshots.where((s) => s.available > 0).length} 类');
}
''',
    output:
        "Stock(PEN: 库存=20, 预留=3, 可用=17)\nStock(BOOK: 库存=8, 预留=8, 可用=0)\n可发货 1 类\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "增加缺货标记，要求可用数量为零或负数时输出 true。",
        hint: "标记应由 available 计算，避免保存重复状态。",
        answer: r'''
class StockSnapshot {
  const StockSnapshot(this.sku, this.onHand, this.reserved);
  final String sku;
  final int onHand;
  final int reserved;
  int get available => onHand - reserved;
  @override
  String toString() => 'Stock($sku: 库存=$onHand, 预留=$reserved, 可用=$available)';
}

bool isUnavailable(StockSnapshot snapshot) => snapshot.available <= 0;
void main() {
  print(isUnavailable(StockSnapshot('BOOK', 8, 8)));
  print(isUnavailable(StockSnapshot('PEN', 20, 3)));
}
''',
      ),
    ],
    exampleTitle: "示例 194：让领域对象输出可读日志",
    exampleSummary: "运行示例。观察用结构化的 toString 显示库存快照，而不依赖默认实例名称。",
  ),
  DartLesson(
    id: 'dart-lesson-195',
    chapter: 'oop-modeling',
    level: 'intermediate',
    title: "工厂构造统一校验编号",
    summary: "把规格化和拒绝非法输入放在对象创建边界。",
    concepts: <String>["factory", "输入规格化", "构造不变量"],
    explain:
        "如果每个调用点都自行清理编号，某处漏做一步就可能创建非法对象。工厂构造提供统一入口。先去掉外侧空格并转换大小写。再校验完整格式。最后调用私有构造器保存合法值。本例要求商品编号由三个大写字母、连字符和三位数字组成，成功对象始终满足这一约束。调用方只需处理一次明确的格式异常，不必在使用对象时反复验证。规格化策略属于业务规则，不能随意把内部字符也删除。程序使用固定输入，离线可验证接受和拒绝两条路径。",
    objective: "能创建只允许合法实例通过的构造入口。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "校验必须覆盖整个字符串，正则两端都要有边界。",
      "私有构造器用于保持不变量，不应再提供绕过校验的公开入口。",
    ],
    code: r'''
class ProductCode {
  ProductCode._(this.value);
  final String value;
  factory ProductCode(String raw) {
    final normalized = raw.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{3}-[0-9]{3}$').hasMatch(normalized)) {
      throw FormatException('编号格式无效');
    }
    return ProductCode._(normalized);
  }
}
void main() {
  for (final raw in [' pen-042 ', 'ABC-7', 'ABC-007x']) {
    try { print(ProductCode(raw).value); }
    on FormatException { print('拒绝 $raw'); }
  }
}
''',
    output: "PEN-042\n拒绝 ABC-7\n拒绝 ABC-007x\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "实现订单号构造器，只允许 ORD- 后接六位数字。",
        hint: "保留私有构造和规格化入口，替换完整匹配规则。",
        answer: r'''
class ProductCode {
  ProductCode._(this.value);
  final String value;
  factory ProductCode(String raw) {
    final normalized = raw.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{3}-[0-9]{3}$').hasMatch(normalized)) {
      throw FormatException('编号格式无效');
    }
    return ProductCode._(normalized);
  }
}

class OrderCode {
  OrderCode._(this.value);
  final String value;
  factory OrderCode(String raw) {
    final text = raw.trim().toUpperCase();
    if (!RegExp(r'^ORD-[0-9]{6}$').hasMatch(text)) {
      throw FormatException('订单号格式无效');
    }
    return OrderCode._(text);
  }
}
void main() {
  print(OrderCode(' ord-000042 ').value);
  try { OrderCode('ORD-42'); } on FormatException { print('拒绝错误订单号'); }
}
''',
      ),
    ],
    exampleTitle: "示例 195：工厂构造统一校验编号",
    exampleSummary: "运行示例。观察把规格化和拒绝非法输入放在对象创建边界。",
  ),
  DartLesson(
    id: 'dart-lesson-196',
    chapter: 'oop-modeling',
    level: 'intermediate',
    title: "命名构造统一计量单位",
    summary: "为米和厘米提供清楚的入口，并在对象内部只存一种单位。",
    concepts: <String>["命名构造", "单位转换", "重定向构造"],
    explain:
        "裸数字不能说明计量单位，构造入口的名字可以把单位写进调用代码。本例提供米和厘米两种命名构造，并让厘米入口重定向到以米保存的标准入口。内部只保存一种单位，后续相加不需要猜测来源，也避免同时维护两份可能矛盾的数据。计算属性在需要时转换回厘米，输出显示不同入口创建的值仍能一起计算。浮点数用于这里的近似长度，不能直接推广到精确金额。程序中的量值全部固定，离线运行时可以安全修改单位并观察结果。",
    objective: "能通过命名构造表达单位，并保持统一的内部表示。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["构造名应明确单位，避免把厘米数字当作米。", "同一信息不必同时保存两份字段，否则更新容易不一致。"],
    code: r'''
class Length {
  const Length.meters(this.meters);
  const Length.centimeters(double value) : this.meters(value / 100);
  final double meters;
  double get centimeters => meters * 100;
  Length plus(Length other) => Length.meters(meters + other.meters);
}
void main() {
  final desk = Length.centimeters(125);
  final gap = Length.meters(0.35);
  final total = desk.plus(gap);
  print('桌长 ${desk.meters.toStringAsFixed(2)} 米');
  print('总长 ${total.centimeters.toStringAsFixed(0)} 厘米');
}
''',
    output: "桌长 1.25 米\n总长 160 厘米\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "增加毫米入口，仍然只保存米字段。",
        hint: "一千毫米等于一米，新入口重定向到 meters。",
        answer: r'''
class Length {
  const Length.meters(this.meters);
  const Length.centimeters(double value) : this.meters(value / 100);
  const Length.millimeters(double value) : this.meters(value / 1000);
  final double meters;
  double get centimeters => meters * 100;
  Length plus(Length other) => Length.meters(meters + other.meters);
}

void main() {
  print(Length.millimeters(250).meters);
  print(Length.millimeters(250).centimeters);
}
''',
      ),
    ],
    exampleTitle: "示例 196：命名构造统一计量单位",
    exampleSummary: "运行示例。观察为米和厘米提供清楚的入口，并在对象内部只存一种单位。",
  ),
  DartLesson(
    id: 'dart-lesson-197',
    chapter: 'oop-modeling',
    level: 'intermediate',
    title: "购物篮的计算属性",
    summary: "用明细推导总价，让 getter 始终反映当前集合内容。",
    concepts: <String>["getter", "组合建模", "fold 聚合"],
    explain:
        "总价是由明细决定的数据，若另存一个总价字段，每次增删明细都必须同步维护。计算属性把求和逻辑集中起来，读取时根据当前明细得到结果，减少状态不同步的机会。本例先让每条明细计算数量乘以单价。再由购物篮对小计求和。程序显示职责如何分层。价格使用整数分，格式化时才换算为元。新增明细后再次读取总价，可以直接观察 getter 的动态结果。集合规模很大时可另行评估缓存，但教学程序无需额外状态，离线即可复现。",
    objective: "能用 getter 表达派生数据，避免重复保存总价。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["金额优先使用整数分，避免反复浮点相加。", "计算属性应避免修改明细，读取操作不应偷偷改变业务状态。"],
    code: r'''
class BasketLine {
  BasketLine(this.name, this.unitCents, this.quantity);
  final String name;
  final int unitCents;
  final int quantity;
  int get subtotal => unitCents * quantity;
}
class Basket {
  final lines = <BasketLine>[];
  int get totalCents => lines.fold<int>(0, (sum, line) => sum + line.subtotal);
}
void main() {
  final basket = Basket();
  basket.lines.add(BasketLine('笔记本', 650, 2));
  basket.lines.add(BasketLine('铅笔', 120, 3));
  print('合计 ${(basket.totalCents / 100).toStringAsFixed(2)} 元');
  basket.lines.add(BasketLine('橡皮', 80, 1));
  print('增加后 ${basket.totalCents} 分');
}
''',
    output: "合计 16.60 元\n增加后 1740 分\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "添加总件数 getter，并说明为什么不能直接使用明细行数。",
        hint: "同一行可能包含多件商品，应该聚合 quantity。",
        answer: r'''
class BasketLine {
  BasketLine(this.name, this.unitCents, this.quantity);
  final String name;
  final int unitCents;
  final int quantity;
  int get subtotal => unitCents * quantity;
}
class Basket {
  final lines = <BasketLine>[];
  int get itemCount => lines.fold<int>(0, (sum, line) => sum + line.quantity);
  int get totalCents => lines.fold<int>(0, (sum, line) => sum + line.subtotal);
}

void main() {
  final basket = Basket();
  basket.lines.addAll([BasketLine('笔记本', 650, 2),
    BasketLine('铅笔', 120, 3), BasketLine('橡皮', 80, 1)]);
  print('件数 ${basket.itemCount}');
  print('明细行数 ${basket.lines.length}');
}
''',
      ),
    ],
    exampleTitle: "示例 197：购物篮的计算属性",
    exampleSummary: "运行示例。观察用明细推导总价，让 getter 始终反映当前集合内容。",
  ),
  DartLesson(
    id: 'dart-lesson-198',
    chapter: 'oop-modeling',
    level: 'intermediate',
    title: "setter 守卫保持合法状态",
    summary: "在赋值前校验温度设定值，失败时保留原状态。",
    concepts: <String>["setter", "封装", "原子校验"],
    explain:
        "公开字段允许调用方绕过所有业务规则，而受控的 setter 可以在真正写入前完成校验。本例把温控器的设定值保存为私有字段，只允许十六到三十度之间的值。合法赋值成功后读取新状态。非法赋值抛出参数错误。捕获后再读取，可确认原值没有受到影响。关键顺序是先验证再提交，不能先写入后发现错误。构造阶段也应遵守同一约束，因此入口复用 setter。程序无硬件访问，离线运行的是明确的状态模型。",
    objective: "能把校验放在写入前，并证明失败没有改变对象。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["不要先写字段再抛错，否则对象已进入非法状态。", "构造器也必须校验初始值，不能只保护后续赋值。"],
    code: r'''
class Thermostat {
  Thermostat(int initial) { target = initial; }
  int _target = 20;
  int get target => _target;
  set target(int value) {
    if (value < 16 || value > 30) throw ArgumentError('温度超出范围');
    _target = value;
  }
}
void main() {
  final thermostat = Thermostat(22);
  thermostat.target = 25;
  print('当前 ${thermostat.target}');
  try { thermostat.target = 40; }
  on ArgumentError { print('拒绝超范围设定'); }
  print('仍为 ${thermostat.target}');
}
''',
    output: "当前 25\n拒绝超范围设定\n仍为 25\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "写出音量类，只允许零到一百。验证负数赋值后状态不变。",
        hint: "沿用先校验、后写入的 setter 顺序。",
        answer: r'''
class Thermostat {
  Thermostat(int initial) { target = initial; }
  int _target = 20;
  int get target => _target;
  set target(int value) {
    if (value < 16 || value > 30) throw ArgumentError('温度超出范围');
    _target = value;
  }
}

class Volume {
  int _level = 50;
  int get level => _level;
  set level(int value) {
    if (value < 0 || value > 100) throw ArgumentError('音量越界');
    _level = value;
  }
}
void main() {
  final volume = Volume()..level = 75;
  try { volume.level = -1; } on ArgumentError { print('拒绝负音量'); }
  print(volume.level);
}
''',
      ),
    ],
    exampleTitle: "示例 198：setter 守卫保持合法状态",
    exampleSummary: "运行示例。观察在赋值前校验温度设定值，失败时保留原状态。",
  ),
  DartLesson(
    id: 'dart-lesson-199',
    chapter: 'oop-modeling',
    level: 'intermediate',
    title: "同一运费接口的不同实现",
    summary: "让结算流程依赖报价能力，替换按次和按距离计费策略。",
    concepts: <String>["接口", "implements", "多态调用"],
    explain:
        "结算流程只需要知道如何取得运费，不应关心每一种计价细节。抽象接口声明报价能力。两个实现分别提供固定运费和按距离运费。调用者通过接口类型统一使用它们。本例把两个实现放入同一列表，对相同距离进行报价。程序显示动态派发如何选择实际对象的方法。新增策略时可以继续实现接口，而无需修改结算函数中的条件分支。接口只表达能力，参数单位和负距离规则仍需共同约定。代码使用真实对象调用，离线运行可以直接比较两种收费结果。",
    objective: "能通过接口参数替换实现，并保持调用代码稳定。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "implements 要完整实现接口的所有成员。",
      "同名方法还要遵守相同单位和边界契约，不能只有签名一致。",
    ],
    code: r'''
abstract class DeliveryFee {
  int quote(int kilometers);
}
class FlatDelivery implements DeliveryFee {
  @override
  int quote(int kilometers) => 800;
}
class DistanceDelivery implements DeliveryFee {
  @override
  int quote(int kilometers) => 300 + kilometers * 120;
}
String checkout(DeliveryFee policy, int kilometers) => '${policy.quote(kilometers)} 分';
void main() {
  final policies = <DeliveryFee>[FlatDelivery(), DistanceDelivery()];
  for (final policy in policies) { print(checkout(policy, 6)); }
}
''',
    output: "800 分\n1020 分\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "增加免运费策略，并直接复用 checkout 函数。",
        hint: "实现 DeliveryFee，报价返回零。",
        answer: r'''
abstract class DeliveryFee {
  int quote(int kilometers);
}
class FlatDelivery implements DeliveryFee {
  @override
  int quote(int kilometers) => 800;
}
class DistanceDelivery implements DeliveryFee {
  @override
  int quote(int kilometers) => 300 + kilometers * 120;
}
String checkout(DeliveryFee policy, int kilometers) => '${policy.quote(kilometers)} 分';

class FreeDelivery implements DeliveryFee {
  @override
  int quote(int kilometers) => 0;
}
void main() { print(checkout(FreeDelivery(), 6)); }
''',
      ),
    ],
    exampleTitle: "示例 199：同一运费接口的不同实现",
    exampleSummary: "运行示例。观察让结算流程依赖报价能力，替换按次和按距离计费策略。",
  ),
  DartLesson(
    id: 'dart-lesson-200',
    chapter: 'oop-modeling',
    level: 'intermediate',
    title: "以小接口组合读写能力",
    summary: "让同一内存便笺同时提供读取与追加能力。",
    concepts: <String>["接口隔离", "多接口实现", "能力组合"],
    explain:
        "把所有操作塞进一个大接口，会迫使只需要读取的代码依赖写入能力。拆成较小的读取接口和追加接口后，一个对象可以同时实现两者。不同函数只接收自己真正需要的能力。本例的内存便笺实现读和写两个接口。填充函数只依赖追加能力。显示函数只依赖读取能力。这样能减少不必要的耦合，也方便以后为只读来源提供独立实现。小接口需要围绕实际使用场景划分，不能为了数量过度拆碎。全部数据保存在本地内存，离线运行无文件或网络依赖。",
    objective: "能以接口限制函数需要的能力，并组合多个实现契约。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "小接口应对应实际职责，过度拆分会增加理解成本。",
      "同一个实现若有同名但含义冲突的成员，需要重新设计接口。",
    ],
    code: r'''
abstract class NoteReader { String read(); }
abstract class NoteAppender { void append(String text); }
class MemoryNote implements NoteReader, NoteAppender {
  String _text = '';
  @override
  String read() => _text;
  @override
  void append(String text) { _text += text; }
}
void fill(NoteAppender writer) {
  writer.append('离线');
  writer.append('便笺');
}
void show(NoteReader reader) { print(reader.read()); }
void main() {
  final note = MemoryNote();
  fill(note);
  show(note);
  note.append('已保存');
  show(note);
}
''',
    output: "离线便笺\n离线便笺已保存\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "为固定文字实现只读便笺，交给 show 使用。",
        hint: "只实现 NoteReader，不需要提供 append。",
        answer: r'''
abstract class NoteReader { String read(); }
abstract class NoteAppender { void append(String text); }
class MemoryNote implements NoteReader, NoteAppender {
  String _text = '';
  @override
  String read() => _text;
  @override
  void append(String text) { _text += text; }
}
void fill(NoteAppender writer) {
  writer.append('离线');
  writer.append('便笺');
}
void show(NoteReader reader) { print(reader.read()); }

class FixedNote implements NoteReader {
  FixedNote(this.text);
  final String text;
  @override
  String read() => text;
}
void main() { show(FixedNote('使用说明')); }
''',
      ),
    ],
    exampleTitle: "示例 200：以小接口组合读写能力",
    exampleSummary: "运行示例。观察让同一内存便笺同时提供读取与追加能力。",
  ),
  DartLesson(
    id: 'dart-lesson-201',
    chapter: 'oop-modeling',
    level: 'advanced',
    title: "DTO 的防御性复制",
    summary: "把外部映射转换为只读快照，阻止调用方修改内部状态。",
    concepts: <String>["DTO", "防御性复制", "只读映射"],
    explain:
        "数据传输对象常在边界处接收一张映射。如果保存原映射引用，外部代码会继续修改对象内容。防御性复制先创建自己的副本。再通过只读视图暴露它。这样快照语义更可靠。本例封装用户偏好，只把需要的字符串键值纳入对象。程序在输入映射修改后校验快照仍保持原值。导出方法返回新的可变副本，调用者修改导出值也不影响内部状态。这是一层浅复制，嵌套的可变对象仍需单独处理。示例数据完全在内存中流转，离线可观察两个方向的隔离。",
    objective: "能识别引用泄漏，并在输入和输出边界分别复制数据。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "unmodifiable 只保护这一层，嵌套列表不会自动深复制。",
      "只给字段加 final 不能阻止代码修改其引用的 Map。",
    ],
    code: r'''
class PreferencesDto {
  PreferencesDto(Map<String, String> source)
      : values = Map<String, String>.unmodifiable(Map<String, String>.of(source));
  final Map<String, String> values;
  Map<String, String> toMap() => Map<String, String>.of(values);
}
void main() {
  final raw = <String, String>{'theme': 'light', 'locale': 'zh'};
  final dto = PreferencesDto(raw);
  raw['theme'] = 'dark';
  final exported = dto.toMap();
  exported['locale'] = 'en';
  print(dto.values);
  print(exported);
  try { dto.values['theme'] = 'system'; }
  on UnsupportedError { print('内部映射只读'); }
}
''',
    output: "{theme: light, locale: zh}\n{theme: light, locale: en}\n内部映射只读\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "为 Map<String,List<String>> 做到第二层防御性复制。",
        hint: "每个列表也要创建并包装为只读。再包装外层 Map。",
        answer: r'''
class PreferencesDto {
  PreferencesDto(Map<String, String> source)
      : values = Map<String, String>.unmodifiable(Map<String, String>.of(source));
  final Map<String, String> values;
  Map<String, String> toMap() => Map<String, String>.of(values);
}

Map<String, List<String>> freezeTags(Map<String, List<String>> source) =>
    Map<String, List<String>>.unmodifiable({
      for (final entry in source.entries)
        entry.key: List<String>.unmodifiable(entry.value),
    });
void main() {
  final original = <String, List<String>>{'note': ['dart']};
  final frozen = freezeTags(original);
  original['note']!.add('flutter');
  print(frozen);
  try { frozen['note']!.add('new'); }
  on UnsupportedError { print('内层列表只读'); }
}
''',
      ),
    ],
    exampleTitle: "示例 201：DTO 的防御性复制",
    exampleSummary: "运行示例。观察把外部映射转换为只读快照，阻止调用方修改内部状态。",
  ),
  DartLesson(
    id: 'dart-lesson-202',
    chapter: 'oop-modeling',
    level: 'advanced',
    title: "聚合根保护订单明细",
    summary: "把增删规则集中到订单对象，并对外提供只读明细快照。",
    concepts: <String>["聚合根", "集合封装", "不变量"],
    explain:
        "订单不是一张任意可改的列表，还包含重复商品合并、数量合法和总量一致等规则。聚合根把这些操作收拢到一个对象中，外部只能通过受控方法修改内部状态。本例增加同一商品时合并数量。程序拒绝非正数量。对外返回不可修改的列表快照。读者可以尝试修改快照并观察拒绝，同时确认订单内部数量未变。快照与实时视图的语义不同，后续订单变化不会更新已取出的快照。程序使用整数数量和本地集合，离线即可验证封装边界。",
    objective: "能让集合修改经过业务方法，并区分快照与实时视图。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["只读集合不能代替元素自身不可变。可变元素仍会泄漏状态。", "快照每次复制有成本，应根据真实读取规模选择。"],
    code: r'''
class OrderItem {
  const OrderItem(this.sku, this.quantity);
  final String sku;
  final int quantity;
  @override
  String toString() => '$sku:$quantity';
}
class Order {
  final _items = <OrderItem>[];
  List<OrderItem> get items => List<OrderItem>.unmodifiable(_items);
  void add(String sku, int quantity) {
    if (quantity <= 0) throw ArgumentError('数量必须为正');
    final index = _items.indexWhere((item) => item.sku == sku);
    if (index < 0) { _items.add(OrderItem(sku, quantity)); }
    else { _items[index] = OrderItem(sku, _items[index].quantity + quantity); }
  }
}
void main() {
  final order = Order()..add('PEN', 2);
  final snapshot = order.items;
  order.add('PEN', 3);
  print('订单 ${order.items}');
  print('旧快照 $snapshot');
  try { snapshot.clear(); }
  on UnsupportedError { print('外部不能清空明细'); }
}
''',
    output: "订单 [PEN:5]\n旧快照 [PEN:2]\n外部不能清空明细\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "增加删除指定商品的方法，返回是否真的删除了明细。",
        hint: "先记录长度。再调用 removeWhere。最后比较长度。",
        answer: r'''
class OrderItem {
  const OrderItem(this.sku, this.quantity);
  final String sku;
  final int quantity;
  @override
  String toString() => '$sku:$quantity';
}
class Order {
  final _items = <OrderItem>[];
  List<OrderItem> get items => List<OrderItem>.unmodifiable(_items);
  bool remove(String sku) {
    final before = _items.length;
    _items.removeWhere((item) => item.sku == sku);
    return before != _items.length;
  }
  void add(String sku, int quantity) {
    if (quantity <= 0) throw ArgumentError('数量必须为正');
    final index = _items.indexWhere((item) => item.sku == sku);
    if (index < 0) { _items.add(OrderItem(sku, quantity)); }
    else { _items[index] = OrderItem(sku, _items[index].quantity + quantity); }
  }
}

void main() {
  final order = Order()..add('PEN', 2)..add('BOOK', 1);
  print(order.remove('PEN'));
  print(order.remove('MISSING'));
  print(order.items);
}
''',
      ),
    ],
    exampleTitle: "示例 202：聚合根保护订单明细",
    exampleSummary: "运行示例。观察把增删规则集中到订单对象，并对外提供只读明细快照。",
  ),
  DartLesson(
    id: 'dart-lesson-203',
    chapter: 'oop-modeling',
    level: 'advanced',
    title: "用函数字段注入价格策略",
    summary: "同一个报价器接收不同计算函数，并让闭包保存折扣参数。",
    concepts: <String>["函数类型", "策略注入", "闭包捕获"],
    explain:
        "只有一个计算动作的策略，不一定需要为每种变体创建新类。把函数保存为字段，可以让对象保留统一的调用入口，同时由外部注入不同算法。本例报价器接收一个以整数分为单位的计算函数。它分别使用原价策略和捕获折扣比例的闭包策略。闭包保存的是构造策略时传入的配置，计算函数本身不需要读取全局变量。策略应保持清楚的输入输出契约，避免一部分返回分、一部分返回元。所有计算固定且无外部输入，离线运行即可比较实际报价。",
    objective: "能用明确的函数类型表达策略，并通过闭包绑定配置。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>[
      "函数字段要写清参数和返回类型，避免 dynamic 隐藏单位错误。",
      "折扣策略不要修改调用方数据，纯计算更容易复用。",
    ],
    code: r'''
typedef PriceRule = int Function(int cents);
class Quoter {
  Quoter(this.rule);
  final PriceRule rule;
  int quote(int cents) => rule(cents);
}
PriceRule discount(int percent) {
  if (percent < 0 || percent > 100) throw ArgumentError('折扣范围无效');
  return (int cents) => (cents * percent / 100).round();
}
void main() {
  final original = Quoter((cents) => cents);
  final promotion = Quoter(discount(85));
  for (final price in [1990, 3500]) {
    print('原价 ${original.quote(price)}，活动 ${promotion.quote(price)}');
  }
}
''',
    output: "原价 1990，活动 1692\n原价 3500，活动 2975\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "创建满额减固定金额的策略，保证结果不为负数。",
        hint: "返回闭包并捕获门槛与减免金额。最后用条件保护下界。",
        answer: r'''
typedef PriceRule = int Function(int cents);
class Quoter {
  Quoter(this.rule);
  final PriceRule rule;
  int quote(int cents) => rule(cents);
}
PriceRule discount(int percent) {
  if (percent < 0 || percent > 100) throw ArgumentError('折扣范围无效');
  return (int cents) => (cents * percent / 100).round();
}

PriceRule reduction(int threshold, int amount) => (int cents) {
  final result = cents >= threshold ? cents - amount : cents;
  return result < 0 ? 0 : result;
};
void main() {
  print(Quoter(reduction(3000, 500)).quote(3500));
  print(Quoter(reduction(1000, 2000)).quote(1000));
  print(Quoter(reduction(3000, 500)).quote(2500));
}
''',
      ),
    ],
    exampleTitle: "示例 203：用函数字段注入价格策略",
    exampleSummary: "运行示例。观察同一个报价器接收不同计算函数，并让闭包保存折扣参数。",
  ),
  DartLesson(
    id: 'dart-lesson-204',
    chapter: 'oop-modeling',
    level: 'advanced',
    title: "对象式与函数式对拍",
    summary: "用同一组订单数据验证两种计算组织方式的结果一致。",
    concepts: <String>["纯函数", "对象职责", "行为对照"],
    explain:
        "对象式和函数式组织并非互斥选择，关键是状态和规则放在哪里。对象方法可以把数据和操作封装在一起。纯函数则把全部输入显式放在参数中，方便独立组合。本例为按重量收费提供一个计价对象和一个独立函数，并对多组重量逐一比较结果。对拍能发现实现之间的分歧。但如果二者复制了同一个错误公式，仍需要明确的业务例子作锚点。示例包含零重量和跨整公斤的边界，帮助读者从行为而非风格判断设计。离线运行能直接复现两条计算路径。",
    objective: "能用输入集合对照两种设计，并识别对拍验证的局限。",
    prerequisites: <String>['已掌握函数、集合与基础类型'],
    pitfalls: <String>["两种实现都错时，对拍仍可能通过，需要已知业务样例。", "纯函数应只依赖参数，避免偷偷读取可变全局配置。"],
    code: r'''
class ShippingCalculator {
  const ShippingCalculator(this.base, this.perKilogram);
  final int base;
  final int perKilogram;
  int calculate(int grams) => grams == 0 ? 0 : base + ((grams + 999) ~/ 1000) * perKilogram;
}
int shipping(int grams, int base, int unit) =>
    grams == 0 ? 0 : base + ((grams + 999) ~/ 1000) * unit;
void main() {
  final calculator = ShippingCalculator(300, 150);
  for (final grams in [0, 250, 1000, 1001, 2500]) {
    final objectResult = calculator.calculate(grams);
    final functionResult = shipping(grams, 300, 150);
    print('$grams 克: $objectResult，匹配 ${objectResult == functionResult}');
  }
}
''',
    output:
        "0 克: 0，匹配 true\n250 克: 450，匹配 true\n1000 克: 450，匹配 true\n1001 克: 600，匹配 true\n2500 克: 750，匹配 true\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "在两个入口都拒绝负重量，并增加一项失败路径对照。",
        hint: "校验应放在计算前，两个入口都抛 ArgumentError。",
        answer: r'''
class ShippingCalculator {
  const ShippingCalculator(this.base, this.perKilogram);
  final int base;
  final int perKilogram;
  int calculate(int grams) {
    if (grams < 0) throw ArgumentError('重量不能为负');
    return grams == 0 ? 0 : base + ((grams + 999) ~/ 1000) * perKilogram;
  }
}
int shipping(int grams, int base, int unit) {
  if (grams < 0) throw ArgumentError('重量不能为负');
  return grams == 0 ? 0 : base + ((grams + 999) ~/ 1000) * unit;
}

void main() {
  final paths = <int Function()>[
    () => ShippingCalculator(300, 150).calculate(-1),
    () => shipping(-1, 300, 150),
  ];
  for (final path in paths) {
    try { print(path()); }
    on ArgumentError { print('拒绝负重量'); }
  }
  print(ShippingCalculator(300, 150).calculate(1001) == shipping(1001, 300, 150));
}
''',
      ),
    ],
    exampleTitle: "示例 204：对象式与函数式对拍",
    exampleSummary: "运行示例。观察用同一组订单数据验证两种计算组织方式的结果一致。",
  ),
];
