import '../dart_lesson.dart';

/// Chapter `data-structures` — independently executed lessons and paired examples.
const List<DartLesson> dataStructuresLessons = <DartLesson>[
  DartLesson(
    id: "dart-lesson-169",
    chapter: "data-structures",
    level: "intermediate",
    title: "用列表封装后进先出栈",
    summary: "把栈顶操作集中在列表尾部。再用出栈顺序解释后进先出。",
    concepts: <String>["LIFO", "封装", "栈下溢"],
    explain:
        "撤销操作、表达式求值和函数调用都需要一种后加入先处理的顺序，这正是栈的核心约定。"
        "本课用整数列表封装 push、pop、peek 与 isEmpty。"
        "所有操作只在列表尾部添加和删除元素。"
        "内部的存放细节不会散落到调用处。"
        "peek 读取栈顶但不删除，pop 则同时返回并删除栈顶，两者在空栈时都明确抛出 StateError。"
        "示例压入三个数。先观察栈顶。再连续弹出，验证顺序与压入方向相反。"
        "练习进一步使用同一个栈计算逆波兰表达式，让运算符取走最近的两个操作数。"
        "栈的正确性取决于操作次序，减法或除法尤其要区分先弹出的右操作数与后弹出的左操作数。",
    objective: "能实现栈的四个基本操作，并用后进先出的顺序计算表达式。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "空栈 pop 或 peek 必须有明确约定，不能让调用者误读一个虚构数值。",
      "非交换运算需要先弹出右操作数。再弹出左操作数。",
    ],
    code: r'''
class IntStack {
  final List<int> _items = [];
  bool get isEmpty => _items.isEmpty;
  void push(int value) { _items.add(value); }
  int peek() {
    if (isEmpty) throw StateError('空栈');
    return _items.last;
  }
  int pop() {
    if (isEmpty) throw StateError('空栈');
    return _items.removeLast();
  }
}
void main() {
  final stack = IntStack();
  for (final value in [10, 20, 30]) stack.push(value);
  print('栈顶 ${stack.peek()}');
  final removed = <int>[];
  while (!stack.isEmpty) removed.add(stack.pop());
  print(removed);
  print(stack.isEmpty);
}
''',
    output: "栈顶 30\n[30, 20, 10]\ntrue\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "用 IntStack 计算逆波兰表达式 8 3 - 2 *。输出唯一结果并确认栈已清空。",
        hint: "遇到数字就压栈。遇到运算符先取 right。再取 left。再计算 left-right 或 left*right。",
        answer: r'''
class IntStack {
  final List<int> _items = [];
  bool get isEmpty => _items.isEmpty;
  void push(int value) { _items.add(value); }
  int peek() {
    if (isEmpty) throw StateError('空栈');
    return _items.last;
  }
  int pop() {
    if (isEmpty) throw StateError('空栈');
    return _items.removeLast();
  }
}
void main() {
  final stack = IntStack();
  for (final token in ['8', '3', '-', '2', '*']) {
    final value = int.tryParse(token);
    if (value != null) {
      stack.push(value);
    } else {
      final right = stack.pop(); final left = stack.pop();
      stack.push(token == '-' ? left - right : left * right);
    }
  }
  print(stack.pop());
  print(stack.isEmpty);
}
''',
      ),
    ],
    exampleTitle: "示例 169：用列表封装后进先出栈",
    exampleSummary: "从栈顶观察、逆序弹出到表达式操作数管理。",
  ),
  DartLesson(
    id: "dart-lesson-170",
    chapter: "data-structures",
    level: "intermediate",
    title: "先进先出的简单队列",
    summary: "用明确的入队和出队接口模拟服务顺序。再说明头部删除的代价。",
    concepts: <String>["FIFO", "队首", "元素移动"],
    explain:
        "排队服务要求先到的人先离开，队列因此把添加与删除安排在不同端。"
        "本例将字符串加入列表尾部。再用 removeAt(0) 从头部取走最早的元素。front 只观察下一项而不改变队列。"
        "封装后的调用代码可以专注于服务顺序，不必反复处理列表下标或空集合。"
        "示例先加入两张工单，处理第一张后再补入第三张，最终离开顺序仍遵循到达先后。"
        "这个实现适合解释语义。"
        "但每次删除头部都需要移动后续元素。"
        "单次出队是线性成本。"
        "长队列连续清空可能累计到平方级工作量。"
        "需要大量出队时，可以采用头指针、环形缓冲或专门的队列实现。",
    objective: "能区分队列与栈的服务顺序，并指出列表头部删除的复杂度。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "用 removeLast 会把队列变成后进先出的栈。",
      "removeAt(0) 会移动后续元素，不能把此实现的出队误称为常数时间。",
    ],
    code: r'''
class TicketQueue {
  final List<String> _items = [];
  bool get isEmpty => _items.isEmpty;
  int get length => _items.length;
  void enqueue(String ticket) { _items.add(ticket); }
  String front() {
    if (isEmpty) throw StateError('空队列');
    return _items.first;
  }
  String dequeue() {
    if (isEmpty) throw StateError('空队列');
    return _items.removeAt(0);
  }
}
void main() {
  final queue = TicketQueue();
  queue.enqueue('A01'); queue.enqueue('A02');
  print('下一张 ${queue.front()}');
  print('处理 ${queue.dequeue()}');
  queue.enqueue('A03');
  while (!queue.isEmpty) print('处理 ${queue.dequeue()}');
  print(queue.length);
}
''',
    output: "下一张 A01\n处理 A01\n处理 A02\n处理 A03\n0\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "将 A01、A02、A03、A04 入队。取消集合为 A02 与 A04。按到达顺序只服务未取消的工单。",
        hint: "每张工单都必须出队。再用 Set.contains 决定是否服务。避免取消项堵在队首。",
        answer: r'''
class TicketQueue {
  final List<String> _items = [];
  bool get isEmpty => _items.isEmpty;
  int get length => _items.length;
  void enqueue(String ticket) { _items.add(ticket); }
  String front() {
    if (isEmpty) throw StateError('空队列');
    return _items.first;
  }
  String dequeue() {
    if (isEmpty) throw StateError('空队列');
    return _items.removeAt(0);
  }
}
void main() {
  final queue = TicketQueue();
  for (final ticket in ['A01', 'A02', 'A03', 'A04']) queue.enqueue(ticket);
  final cancelled = <String>{'A02', 'A04'};
  final served = <String>[];
  while (!queue.isEmpty) {
    final ticket = queue.dequeue();
    if (!cancelled.contains(ticket)) served.add(ticket);
  }
  print(served);
  print(queue.isEmpty);
}
''',
      ),
    ],
    exampleTitle: "示例 170：先进先出的简单队列",
    exampleSummary: "保留到达次序的工单队列及其头部删除成本。",
  ),
  DartLesson(
    id: "dart-lesson-171",
    chapter: "data-structures",
    level: "intermediate",
    title: "固定容量的环形记录",
    summary: "用起点与有效长度解释回绕，在缓冲区满时覆盖最旧记录。",
    concepts: <String>["模运算", "环形下标", "覆盖策略"],
    explain:
        "传感器日志往往只需要保留最近几次读数，固定容量的环形缓冲可以限制内存占用。"
        "底层列表长度从创建后就不再变化，start 指向最旧的有效记录，length 表示已经写入的数量。"
        "未满时把新值写到起点加长度的位置。"
        "满后直接覆盖起点。再把起点向前移动。"
        "所有物理下标都通过取模回到容量范围内。"
        "snapshot 按逻辑顺序收集记录，因此调用者看到的始终是从旧到新的数据，而不是底层列表的物理排列。"
        "空槽使用零初始化。"
        "但是否有效只由 length 决定。"
        "真实的零读数不会误丢弃。"
        "容量必须为正，否则取模和覆盖规则都没有意义。",
    objective: "能维护环形缓冲的起点与长度。能在覆盖后恢复正确的时间顺序。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>["不能把零值当成空槽标志，零可能是合法读数。", "覆盖最旧值后必须推进起点，否则逻辑顺序会错乱。"],
    code: r'''
int positiveCapacity(int value) {
  if (value <= 0) throw ArgumentError('容量必须为正');
  return value;
}
class IntRingBuffer {
  final int capacity;
  final List<int> _storage;
  int _start = 0;
  int _length = 0;
  IntRingBuffer(int capacity)
      : capacity = positiveCapacity(capacity),
        _storage = List<int>.filled(positiveCapacity(capacity), 0);
  void add(int value) {
    if (_length < capacity) {
      _storage[(_start + _length) % capacity] = value;
      _length++;
    } else {
      _storage[_start] = value;
      _start = (_start + 1) % capacity;
    }
  }
  List<int> snapshot() {
    final result = <int>[];
    for (var i = 0; i < _length; i++) result.add(_storage[(_start + i) % capacity]);
    return result;
  }
}
void main() {
  final buffer = IntRingBuffer(3);
  for (final value in [10, 20, 30, 40, 0]) {
    buffer.add(value);
    print(buffer.snapshot());
  }
}
''',
    output: "[10]\n[10, 20]\n[10, 20, 30]\n[20, 30, 40]\n[30, 40, 0]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "用容量三保留读数 6、12、18、30。每次加入后输出当前窗口平均值。结果保留一位小数。",
        hint: "snapshot 返回实际有效记录。求和后除以它的长度。尚未写满时不能固定除以三。",
        answer: r'''
int positiveCapacity(int value) {
  if (value <= 0) throw ArgumentError('容量必须为正');
  return value;
}
class IntRingBuffer {
  final int capacity;
  final List<int> _storage;
  int _start = 0;
  int _length = 0;
  IntRingBuffer(int capacity)
      : capacity = positiveCapacity(capacity),
        _storage = List<int>.filled(positiveCapacity(capacity), 0);
  void add(int value) {
    if (_length < capacity) {
      _storage[(_start + _length) % capacity] = value;
      _length++;
    } else {
      _storage[_start] = value;
      _start = (_start + 1) % capacity;
    }
  }
  List<int> snapshot() {
    final result = <int>[];
    for (var i = 0; i < _length; i++) result.add(_storage[(_start + i) % capacity]);
    return result;
  }
}
void main() {
  final buffer = IntRingBuffer(3);
  for (final value in [6, 12, 18, 30]) {
    buffer.add(value);
    final values = buffer.snapshot();
    var sum = 0;
    for (final number in values) sum += number;
    print((sum / values.length).toStringAsFixed(1));
  }
}
''',
      ),
    ],
    exampleTitle: "示例 171：固定容量的环形记录",
    exampleSummary: "固定大小的空间内回绕写入并覆盖最旧的传感器记录。",
  ),
  DartLesson(
    id: "dart-lesson-172",
    chapter: "data-structures",
    level: "intermediate",
    title: "单链表节点与插入",
    summary: "沿 next 引用遍历节点，在目标节点之后保持原链路再插入新值。",
    concepts: <String>["节点引用", "单向链路", "插入次序"],
    explain:
        "列表把连续元素交给容器管理，单链表则把数据和下一节点引用放在独立节点中。"
        "本例用 head 保存入口，每个节点的 next 指向后继。最后一个节点以 null 结束。"
        "append 从入口向后寻找尾部。"
        "insertAfter 在第一个匹配值之后插入新节点。"
        "插入时先让新节点接住原来的后继。再把目标节点指向新节点，原链就不会丢失。"
        "遍历只读取值并沿 next 前进，最终收集成普通列表方便观察。"
        "没有尾指针时，每次追加都需要线性扫描。"
        "查找目标也同样如此。"
        "这里按值匹配只操作第一次出现的位置。"
        "若业务要精确选择重复值中的某个节点。"
        "这时应改为传递节点引用或额外标识。",
    objective: "能描述节点间引用的连接方式。能在不丢失后继的情况下插入节点。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "先覆盖目标的 next 再保存旧后继，会让剩余链路失去入口。",
      "按值插入只匹配第一处，重复值不能天然表示唯一节点。",
    ],
    code: r'''
class ChainNode {
  final int value;
  ChainNode? next;
  ChainNode(this.value, [this.next]);
}
class IntChain {
  ChainNode? head;
  void append(int value) {
    final node = ChainNode(value);
    if (head == null) { head = node; return; }
    var cursor = head!;
    while (cursor.next != null) cursor = cursor.next!;
    cursor.next = node;
  }
  bool insertAfter(int target, int value) {
    var cursor = head;
    while (cursor != null) {
      if (cursor.value == target) {
        cursor.next = ChainNode(value, cursor.next);
        return true;
      }
      cursor = cursor.next;
    }
    return false;
  }
  List<int> values() {
    final result = <int>[];
    var cursor = head;
    while (cursor != null) { result.add(cursor.value); cursor = cursor.next; }
    return result;
  }
}
void main() {
  final chain = IntChain();
  for (final value in [10, 30, 40]) chain.append(value);
  print(chain.insertAfter(10, 20));
  print(chain.values());
  print(chain.insertAfter(99, 50));
}
''',
    output: "true\n[10, 20, 30, 40]\nfalse\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "创建值为 2、2、3 的链表。在第一个 2 后插入 9。再验证找不到目标 8 时链表内容不变。",
        hint: "第一次命中后立即返回。最后两次 values 输出应相同。",
        answer: r'''
class ChainNode {
  final int value;
  ChainNode? next;
  ChainNode(this.value, [this.next]);
}
class IntChain {
  ChainNode? head;
  void append(int value) {
    final node = ChainNode(value);
    if (head == null) { head = node; return; }
    var cursor = head!;
    while (cursor.next != null) cursor = cursor.next!;
    cursor.next = node;
  }
  bool insertAfter(int target, int value) {
    var cursor = head;
    while (cursor != null) {
      if (cursor.value == target) {
        cursor.next = ChainNode(value, cursor.next);
        return true;
      }
      cursor = cursor.next;
    }
    return false;
  }
  List<int> values() {
    final result = <int>[];
    var cursor = head;
    while (cursor != null) { result.add(cursor.value); cursor = cursor.next; }
    return result;
  }
}
void main() {
  final chain = IntChain();
  for (final value in [2, 2, 3]) chain.append(value);
  print(chain.insertAfter(2, 9));
  print(chain.values());
  print(chain.insertAfter(8, 7));
  print(chain.values());
}
''',
      ),
    ],
    exampleTitle: "示例 172：单链表节点与插入",
    exampleSummary: "通过单向节点引用完成追加、首次匹配插入与遍历。",
  ),
  DartLesson(
    id: "dart-lesson-173",
    chapter: "data-structures",
    level: "intermediate",
    title: "原地反转单链表",
    summary: "保存后继再翻转 next，用三个引用把整条链的方向逐段调换。",
    concepts: <String>["引用重连", "循环不变量", "原地反转"],
    explain:
        "把链表转成数组再倒序只能改变观察结果，原地反转则真正修改每个节点的 next 方向。"
        "本课维护 previous、current 和 next 三个引用。"
        "previous 是已经反转完成的部分。"
        "current 是尚未处理的入口。"
        "next 临时保存原来的后继。"
        "每轮先保存 next。再把 current.next 指向 previous。最后让两个游标前进。"
        "结束时 current 为 null，previous 就是新链表的头节点。"
        "旧头节点的 next 已在第一轮置空，因此自然成为尾部。"
        "整个过程只使用固定数量的额外引用，时间随节点数线性增长。"
        "算法要求输入链没有环，否则遍历不会正常结束，环检测应作为另一项独立前提处理。",
    objective: "能解释反转时三个引用的角色，并处理空链和单节点链。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "未保存原后继就改写 next，会丢失尚未处理的节点。",
      "本算法假定无环，循环链需要先检测或解除环再反转。",
    ],
    code: r'''
class ReverseNode {
  final int value;
  ReverseNode? next;
  ReverseNode(this.value, [this.next]);
}
ReverseNode? reverseChain(ReverseNode? head) {
  ReverseNode? previous;
  var current = head;
  while (current != null) {
    final next = current.next;
    current.next = previous;
    previous = current;
    current = next;
  }
  return previous;
}
List<int> chainValues(ReverseNode? head) {
  final values = <int>[];
  var cursor = head;
  while (cursor != null) { values.add(cursor.value); cursor = cursor.next; }
  return values;
}
void main() {
  final head = ReverseNode(1, ReverseNode(2, ReverseNode(3, ReverseNode(4))));
  final reversed = reverseChain(head);
  print(chainValues(reversed));
  print(head.next == null);
  print(chainValues(reverseChain(null)));
}
''',
    output: "[4, 3, 2, 1]\ntrue\n[]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "对 5→8→13 连续反转两次。检查数值次序是否恢复。再确认返回的头节点是原来的同一对象。",
        hint: "保存第一次反转的返回值作为第二次输入。再用 identical 检查引用身份。",
        answer: r'''
class ReverseNode {
  final int value;
  ReverseNode? next;
  ReverseNode(this.value, [this.next]);
}
ReverseNode? reverseChain(ReverseNode? head) {
  ReverseNode? previous;
  var current = head;
  while (current != null) {
    final next = current.next;
    current.next = previous;
    previous = current;
    current = next;
  }
  return previous;
}
List<int> chainValues(ReverseNode? head) {
  final values = <int>[];
  var cursor = head;
  while (cursor != null) { values.add(cursor.value); cursor = cursor.next; }
  return values;
}
void main() {
  final original = ReverseNode(5, ReverseNode(8, ReverseNode(13)));
  final once = reverseChain(original);
  print(chainValues(once));
  final twice = reverseChain(once);
  print(chainValues(twice));
  print(identical(twice, original));
}
''',
      ),
    ],
    exampleTitle: "示例 173：原地反转单链表",
    exampleSummary: "保留后继、重连当前节点并推进游标的原地链表反转。",
  ),
  DartLesson(
    id: "dart-lesson-174",
    chapter: "data-structures",
    level: "advanced",
    title: "快慢指针检测链表环",
    summary: "让两个游标以不同速度前进，按节点身份判断是否在环中相遇。",
    concepts: <String>["Floyd 判环", "对象身份", "双指针"],
    explain:
        "链表出现环后，沿 next 查找 null 的普通遍历可能永远无法结束。"
        "Floyd 方法让慢指针每轮走一步，快指针走两步。"
        "无环时快指针会先到达尾部。"
        "有环时二者进入环后会在有限轮次内相遇。"
        "比较的是节点对象身份，而不是节点记录的数值，因为两个不同节点完全可能保存相同值。"
        "本例分别构造重复值的无环链、尾部连接到中间的环以及指向自身的单节点环，显示三种情况。"
        "算法只保存两个引用，额外空间为常数。"
        "它只能回答环是否存在，本课没有把相遇节点误当成环的入口。"
        "若需要寻找入口，还要在相遇之后增加一段步速相同的定位过程。",
    objective: "能按对象身份实现快慢指针判环，并区分相遇点与环入口。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>["比较节点值会把重复值的无环链误判为环。", "快指针移动两步前要同时确认当前节点与下一节点存在。"],
    code: r'''
class CycleNode {
  final int value;
  CycleNode? next;
  CycleNode(this.value, [this.next]);
}
bool hasCycle(CycleNode? head) {
  var slow = head;
  var fast = head;
  while (fast != null && fast.next != null) {
    slow = slow!.next;
    fast = fast.next!.next;
    if (identical(slow, fast)) return true;
  }
  return false;
}
void main() {
  final plain = CycleNode(7, CycleNode(7, CycleNode(7)));
  print(hasCycle(plain));
  final first = CycleNode(1); final second = CycleNode(2); final third = CycleNode(3);
  first.next = second; second.next = third; third.next = second;
  print(hasCycle(first));
  final self = CycleNode(9); self.next = self;
  print(hasCycle(self));
}
''',
    output: "false\ntrue\ntrue\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "创建 a→b→c→a。先检查存在环。再把 c.next 置空。再检查断环后的结果。同时检测空链。",
        hint: "保留末节点引用。断环只需把它的 next 改成 null。无需依赖普通遍历寻找尾部。",
        answer: r'''
class CycleNode {
  final int value;
  CycleNode? next;
  CycleNode(this.value, [this.next]);
}
bool hasCycle(CycleNode? head) {
  var slow = head;
  var fast = head;
  while (fast != null && fast.next != null) {
    slow = slow!.next;
    fast = fast.next!.next;
    if (identical(slow, fast)) return true;
  }
  return false;
}
void main() {
  final a = CycleNode(4); final b = CycleNode(5); final c = CycleNode(6);
  a.next = b; b.next = c; c.next = a;
  print(hasCycle(a));
  c.next = null;
  print(hasCycle(a));
  print(hasCycle(null));
}
''',
      ),
    ],
    exampleTitle: "示例 174：快慢指针检测链表环",
    exampleSummary: "用身份比较识别中间回环、自环与重复值的无环链。",
  ),
  DartLesson(
    id: "dart-lesson-175",
    chapter: "data-structures",
    level: "intermediate",
    title: "二叉树的三种深度遍历",
    summary: "固定左右子树的先后，只改变访问根节点的位置以得到三种顺序。",
    concepts: <String>["递归结构", "前中后序", "空子树"],
    explain:
        "二叉树的每个节点最多连接左右两个子树，同一种结构可以用不同访问顺序表达不同任务。"
        "前序先记录根。再遍历左和右。"
        "中序把根放在两个子树之间。"
        "后序先完成两个子树。最后记录根。"
        "三个函数都把 null 视为空子树并立即返回，因此叶节点无需额外写特殊分支。"
        "示例使用不对称的树。"
        "这样不会因为对称形状误以为三种遍历相同。"
        "输出列表也能看出每个节点只访问一次。"
        "递归所需空间由树高决定，极度偏斜的树会产生较深调用链。"
        "普通二叉树的中序结果并不保证有序。"
        "只有额外满足二叉搜索树的大小关系时才有这种保证。",
    objective: "能按根节点访问时机区分三种深度优先遍历。能说明中序有序的前提。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "中序遍历只有在树满足搜索树大小约束时才得到排序结果。",
      "递归输出容器应由调用处创建，避免多次遍历意外混合旧结果。",
    ],
    code: r'''
class BinaryNode {
  final int value;
  BinaryNode? left;
  BinaryNode? right;
  BinaryNode(this.value, [this.left, this.right]);
}
void preorder(BinaryNode? node, List<int> output) {
  if (node == null) return;
  output.add(node.value); preorder(node.left, output); preorder(node.right, output);
}
void inorder(BinaryNode? node, List<int> output) {
  if (node == null) return;
  inorder(node.left, output); output.add(node.value); inorder(node.right, output);
}
void postorder(BinaryNode? node, List<int> output) {
  if (node == null) return;
  postorder(node.left, output); postorder(node.right, output); output.add(node.value);
}
void main() {
  final root = BinaryNode(8, BinaryNode(3, null, BinaryNode(6)), BinaryNode(10));
  final pre = <int>[]; final middle = <int>[]; final post = <int>[];
  preorder(root, pre); inorder(root, middle); postorder(root, post);
  print(pre); print(middle); print(post);
}
''',
    output: "[8, 3, 6, 10]\n[3, 6, 8, 10]\n[6, 3, 10, 8]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "构造根为 1、左孩子 9、右孩子 2 的普通二叉树。输出中序结果并验证它不是升序。",
        hint: "遍历本身不改变树的约束。可以对相邻输出项检查是否存在逆序。",
        answer: r'''
class BinaryNode {
  final int value;
  BinaryNode? left;
  BinaryNode? right;
  BinaryNode(this.value, [this.left, this.right]);
}
void preorder(BinaryNode? node, List<int> output) {
  if (node == null) return;
  output.add(node.value); preorder(node.left, output); preorder(node.right, output);
}
void inorder(BinaryNode? node, List<int> output) {
  if (node == null) return;
  inorder(node.left, output); output.add(node.value); inorder(node.right, output);
}
void postorder(BinaryNode? node, List<int> output) {
  if (node == null) return;
  postorder(node.left, output); postorder(node.right, output); output.add(node.value);
}
void main() {
  final root = BinaryNode(1, BinaryNode(9), BinaryNode(2));
  final values = <int>[];
  inorder(root, values);
  var sorted = true;
  for (var i = 1; i < values.length; i++) {
    if (values[i] < values[i - 1]) sorted = false;
  }
  print(values); print(sorted);
  final empty = <int>[]; postorder(null, empty); print(empty);
}
''',
      ),
    ],
    exampleTitle: "示例 175：二叉树的三种深度遍历",
    exampleSummary: "在同一棵不对称二叉树上比较前序、中序与后序。",
  ),
  DartLesson(
    id: "dart-lesson-176",
    chapter: "data-structures",
    level: "intermediate",
    title: "二叉搜索树插入与查找",
    summary: "按大小关系走向左右子树，明确重复键忽略的集合语义。",
    concepts: <String>["搜索树约束", "递归插入", "重复键策略"],
    explain:
        "二叉搜索树在普通二叉树上增加大小约束：左子树的所有键小于根，右子树的所有键大于根。"
        "插入时沿比较结果递归下降。遇到空位置才创建节点。再把返回的子树根重新接回原节点。"
        "查找可以用循环，只沿可能包含目标的一条分支前进。"
        "本例把重复键视为已经存在，直接保留原树。"
        "因此实现的是整数集合而不是多重集合。"
        "中序遍历应得到严格递增序列。"
        "插入顺序会影响形状，连续有序输入可能使树退化成单链，查找的最坏成本因此仍为线性。"
        "这里没有平衡旋转，不应仅凭名称就承诺每次操作都是对数时间。",
    objective: "能维护搜索树大小约束。能说明重复键行为及非平衡树的最坏情况。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "递归插入返回的子树根必须接回 left 或 right，空位置的新节点才不会丢失。",
      "普通搜索树并不自动平衡，有序输入可能造成线性高度。",
    ],
    code: r'''
class SearchNode {
  final int key;
  SearchNode? left;
  SearchNode? right;
  SearchNode(this.key);
}
SearchNode insertKey(SearchNode? root, int key) {
  if (root == null) return SearchNode(key);
  if (key < root.key) { root.left = insertKey(root.left, key); }
  else if (key > root.key) { root.right = insertKey(root.right, key); }
  return root;
}
bool containsKey(SearchNode? root, int key) {
  var current = root;
  while (current != null) {
    if (key == current.key) return true;
    current = key < current.key ? current.left : current.right;
  }
  return false;
}
void sortedKeys(SearchNode? root, List<int> values) {
  if (root == null) return;
  sortedKeys(root.left, values); values.add(root.key); sortedKeys(root.right, values);
}
void main() {
  SearchNode? root;
  for (final key in [5, 3, 8, 1, 4, 8]) root = insertKey(root, key);
  final values = <int>[]; sortedKeys(root, values);
  print(values); print(containsKey(root, 4)); print(containsKey(root, 7));
}
''',
    output: "[1, 3, 4, 5, 8]\ntrue\nfalse\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "依次插入 4、2、6、1、3、5、7。查找 0 到 8 中的缺失键。输出所有已存键的和。",
        hint: "containsKey 判断缺失项。中序结果可用于遍历求和。但不要依赖节点对象的默认字符串。",
        answer: r'''
class SearchNode {
  final int key;
  SearchNode? left;
  SearchNode? right;
  SearchNode(this.key);
}
SearchNode insertKey(SearchNode? root, int key) {
  if (root == null) return SearchNode(key);
  if (key < root.key) { root.left = insertKey(root.left, key); }
  else if (key > root.key) { root.right = insertKey(root.right, key); }
  return root;
}
bool containsKey(SearchNode? root, int key) {
  var current = root;
  while (current != null) {
    if (key == current.key) return true;
    current = key < current.key ? current.left : current.right;
  }
  return false;
}
void sortedKeys(SearchNode? root, List<int> values) {
  if (root == null) return;
  sortedKeys(root.left, values); values.add(root.key); sortedKeys(root.right, values);
}
void main() {
  SearchNode? root;
  for (final key in [4, 2, 6, 1, 3, 5, 7]) root = insertKey(root, key);
  final missing = <int>[];
  for (var key = 0; key <= 8; key++) {
    if (!containsKey(root, key)) missing.add(key);
  }
  final values = <int>[]; sortedKeys(root, values);
  var sum = 0; for (final key in values) sum += key;
  print(missing); print(sum);
}
''',
      ),
    ],
    exampleTitle: "示例 176：二叉搜索树插入与查找",
    exampleSummary: "具有忽略重复键策略的整数搜索树及其单分支查找。",
  ),
  DartLesson(
    id: "dart-lesson-177",
    chapter: "data-structures",
    level: "advanced",
    title: "用队列按层遍历二叉树",
    summary: "保存每层的结束位置，让下一层节点追加后仍能保持层次边界。",
    concepts: <String>["广度优先", "队列游标", "层次边界"],
    explain:
        "深度遍历会先深入子树，层序遍历则按离根的距离逐层访问节点。"
        "本课使用列表作为只追加的队列。再用 head 游标读取下一个节点。避免每次 removeAt(0) 移动剩余元素。"
        "开始一层时记录当前队列长度作为 end。"
        "本层只处理 head 到 end 之间的节点。"
        "期间加入的孩子会留给下一轮。"
        "这样可以直接返回二维列表，每个子列表对应一层，而不是事后猜测哪些节点属于同一深度。"
        "左右孩子按固定次序入队，保证同层结果可重复。"
        "这个教学实现会保留处理过的引用直到函数结束。"
        "空间为节点总数。"
        "若要持续处理无限事件，应使用能够回收队首空间的真实队列。",
    objective: "能用队列游标实现分层输出。能解释为何必须先冻结本层结束位置。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "循环中直接用不断增长的 queue.length 作为本层终点，会把后续层混入当前层。",
      "列表游标避免头部移动，但已经读取的引用仍保留到局部队列释放。",
    ],
    code: r'''
class LevelNode {
  final String label;
  LevelNode? left;
  LevelNode? right;
  LevelNode(this.label, [this.left, this.right]);
}
List<List<String>> levels(LevelNode? root) {
  if (root == null) return [];
  final queue = <LevelNode>[root];
  final result = <List<String>>[];
  var head = 0;
  while (head < queue.length) {
    final end = queue.length;
    final layer = <String>[];
    while (head < end) {
      final node = queue[head]; head++;
      layer.add(node.label);
      if (node.left != null) queue.add(node.left!);
      if (node.right != null) queue.add(node.right!);
    }
    result.add(layer);
  }
  return result;
}
void main() {
  final root = LevelNode('A', LevelNode('B', LevelNode('D'), LevelNode('E')), LevelNode('C', null, LevelNode('F')));
  print(levels(root));
  print(levels(null));
}
''',
    output: "[[A], [B, C], [D, E, F]]\n[]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "构造 A 的左右孩子为 B、C。B 的左孩子为 D。根据层序结果计算树高与最大层宽。",
        hint: "非空树的高度按层数计，最大层宽取各层列表长度的最大值。",
        answer: r'''
class LevelNode {
  final String label;
  LevelNode? left;
  LevelNode? right;
  LevelNode(this.label, [this.left, this.right]);
}
List<List<String>> levels(LevelNode? root) {
  if (root == null) return [];
  final queue = <LevelNode>[root];
  final result = <List<String>>[];
  var head = 0;
  while (head < queue.length) {
    final end = queue.length;
    final layer = <String>[];
    while (head < end) {
      final node = queue[head]; head++;
      layer.add(node.label);
      if (node.left != null) queue.add(node.left!);
      if (node.right != null) queue.add(node.right!);
    }
    result.add(layer);
  }
  return result;
}
void main() {
  final root = LevelNode('A', LevelNode('B', LevelNode('D')), LevelNode('C'));
  final rows = levels(root);
  var width = 0;
  for (final row in rows) { if (row.length > width) width = row.length; }
  print(rows); print('高度 ${rows.length}，最大宽度 $width');
}
''',
      ),
    ],
    exampleTitle: "示例 177：用队列按层遍历二叉树",
    exampleSummary: "用固定层边界和单向游标输出二叉树的逐层标签。",
  ),
  DartLesson(
    id: "dart-lesson-178",
    chapter: "data-structures",
    level: "advanced",
    title: "有序列表实现最小优先队列",
    summary: "按优先级降序保存，让最小键位于尾部并保持同级任务的到达次序。",
    concepts: <String>["优先级", "有序插入", "稳定性"],
    explain:
        "优先队列按键值选择下一项，而不一定遵循整体到达顺序。"
        "本课约定较小数字更紧急，内部按优先级从大到小保存，使最小项位于列表尾部，出队可以直接 removeLast。"
        "插入时寻找第一个不大于新键的位置。"
        "并把新任务放在同级旧任务之前。"
        "因为取出方向相反，同级任务最终仍按先到先服务。"
        "示例加入两条同优先级任务，用输出顺序验证这种稳定性。"
        "这个结构使用有序列表，不是二叉堆。"
        "寻找插入点和移动元素都可能花线性时间。"
        "取最小项则为常数时间。"
        "选择数据结构应结合插入与取出的比例，不能把所有优先队列实现都套用堆的复杂度。",
    objective: "能实现稳定的最小优先队列。能分别分析有序列表的插入与删除成本。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "相同优先级的插入位置会影响稳定性，必须结合尾部取出的方向判断。",
      "有序列表实现不能直接宣称具有二叉堆的对数插入复杂度。",
    ],
    code: r'''
class ScheduledTask {
  final String name;
  final int priority;
  ScheduledTask(this.name, this.priority);
}
class MinTaskQueue {
  final List<ScheduledTask> _tasks = [];
  bool get isEmpty => _tasks.isEmpty;
  void add(ScheduledTask task) {
    var index = 0;
    while (index < _tasks.length && _tasks[index].priority > task.priority) index++;
    _tasks.insert(index, task);
  }
  ScheduledTask removeMin() {
    if (isEmpty) throw StateError('空优先队列');
    return _tasks.removeLast();
  }
}
void main() {
  final queue = MinTaskQueue();
  queue.add(ScheduledTask('备份', 5)); queue.add(ScheduledTask('修复', 1));
  queue.add(ScheduledTask('告警', 1)); queue.add(ScheduledTask('报表', 3));
  while (!queue.isEmpty) {
    final task = queue.removeMin(); print('${task.name}:${task.priority}');
  }
}
''',
    output: "修复:1\n告警:1\n报表:3\n备份:5\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "先加入优先级为二的甲与乙。取走甲后加入优先级为一的急件。再加入优先级为二的丙。输出剩余服务顺序。",
        hint: "新急件应先于乙。同级乙应先于后到的丙。动态插入也必须保持同级稳定性。",
        answer: r'''
class ScheduledTask {
  final String name;
  final int priority;
  ScheduledTask(this.name, this.priority);
}
class MinTaskQueue {
  final List<ScheduledTask> _tasks = [];
  bool get isEmpty => _tasks.isEmpty;
  void add(ScheduledTask task) {
    var index = 0;
    while (index < _tasks.length && _tasks[index].priority > task.priority) index++;
    _tasks.insert(index, task);
  }
  ScheduledTask removeMin() {
    if (isEmpty) throw StateError('空优先队列');
    return _tasks.removeLast();
  }
}
void main() {
  final queue = MinTaskQueue();
  queue.add(ScheduledTask('甲', 2)); queue.add(ScheduledTask('乙', 2));
  print(queue.removeMin().name);
  queue.add(ScheduledTask('急件', 1)); queue.add(ScheduledTask('丙', 2));
  while (!queue.isEmpty) print(queue.removeMin().name);
}
''',
      ),
    ],
    exampleTitle: "示例 178：有序列表实现最小优先队列",
    exampleSummary: "线性有序插入、尾部取最小值并保持同级先后次序。",
  ),
  DartLesson(
    id: "dart-lesson-179",
    chapter: "data-structures",
    level: "advanced",
    title: "并查集与路径压缩",
    summary: "用父节点表示集合归属，按规模合并并在查找时压缩访问路径。",
    concepts: <String>["不相交集合", "路径压缩", "按规模合并"],
    explain:
        "并查集用于反复合并分组并查询两个元素是否连通，不保存组内元素的顺序。"
        "开始时每个编号都是独立根，parent 指向自己，size 记录根所代表集合的规模。"
        "find 沿父引用找到根。再把沿途节点直接接到根上。这种路径压缩会让后续查询更短。"
        "union 先求两个根。两个根相同就返回 false。否则把较小集合接到较大集合。最后只更新新根的规模。"
        "示例把几个站点逐步连接。同时观察独立分量数量。重复连接不会再次减少计数。"
        "父数组下标必须处于合法范围，且只有根节点的 size 才有当前集合规模的含义。"
        "该结构适合追加连接，不能直接撤销边或回答连接路径的具体节点。",
    objective: "能实现带路径压缩和按规模合并的并查集。能正确统计连通分量。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "两个元素已同根时不能再次合并或减少分量数。",
      "非根位置的 size 可能保留旧值，集合规模必须通过 find 后的根读取。",
    ],
    code: r'''
class UnionFind {
  final List<int> _parent;
  final List<int> _size;
  int components;
  UnionFind(int count)
      : _parent = List.generate(count, (index) => index),
        _size = List<int>.filled(count, 1),
        components = count;
  int find(int item) {
    if (item < 0 || item >= _parent.length) throw RangeError('编号越界');
    if (_parent[item] != item) _parent[item] = find(_parent[item]);
    return _parent[item];
  }
  bool union(int a, int b) {
    var rootA = find(a); var rootB = find(b);
    if (rootA == rootB) return false;
    if (_size[rootA] < _size[rootB]) {
      final temporary = rootA; rootA = rootB; rootB = temporary;
    }
    _parent[rootB] = rootA;
    _size[rootA] = _size[rootA] + _size[rootB];
    components--;
    return true;
  }
  bool connected(int a, int b) => find(a) == find(b);
  int groupSize(int item) => _size[find(item)];
}
void main() {
  final groups = UnionFind(6);
  groups.union(0, 1); groups.union(2, 3); groups.union(1, 2);
  print(groups.connected(0, 3)); print(groups.connected(0, 5));
  print(groups.groupSize(2)); print(groups.components);
  print(groups.union(0, 3)); print(groups.components);
}
''',
    output: "true\nfalse\n4\n3\nfalse\n3\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "处理五个站点的连接 0-1、1-2、0-2、3-4。统计有多少条边连接了已连通的端点。再输出最终分量数。",
        hint: "union 返回 false 表示这条边没有改变分组。把这种返回值计入冗余边数量。",
        answer: r'''
class UnionFind {
  final List<int> _parent;
  final List<int> _size;
  int components;
  UnionFind(int count)
      : _parent = List.generate(count, (index) => index),
        _size = List<int>.filled(count, 1),
        components = count;
  int find(int item) {
    if (item < 0 || item >= _parent.length) throw RangeError('编号越界');
    if (_parent[item] != item) _parent[item] = find(_parent[item]);
    return _parent[item];
  }
  bool union(int a, int b) {
    var rootA = find(a); var rootB = find(b);
    if (rootA == rootB) return false;
    if (_size[rootA] < _size[rootB]) {
      final temporary = rootA; rootA = rootB; rootB = temporary;
    }
    _parent[rootB] = rootA;
    _size[rootA] = _size[rootA] + _size[rootB];
    components--;
    return true;
  }
  bool connected(int a, int b) => find(a) == find(b);
  int groupSize(int item) => _size[find(item)];
}
void main() {
  final groups = UnionFind(5);
  final edges = <List<int>>[[0, 1], [1, 2], [0, 2], [3, 4]];
  var redundant = 0;
  for (final edge in edges) { if (!groups.union(edge[0], edge[1])) redundant++; }
  print('冗余边 $redundant'); print('连通分量 ${groups.components}');
  print(groups.groupSize(4));
}
''',
      ),
    ],
    exampleTitle: "示例 179：并查集与路径压缩",
    exampleSummary: "按规模连接集合并压缩父链，识别重复连接和分量数量。",
  ),
  DartLesson(
    id: "dart-lesson-180",
    chapter: "data-structures",
    level: "advanced",
    title: "邻接表上的深度与广度搜索",
    summary: "在有共享后继和回边的图中比较 DFS 与 BFS。同时在发现时标记访问。",
    concepts: <String>["邻接表", "DFS 与 BFS", "访问集合"],
    explain:
        "图的节点可以有任意多个邻居，因此不能像树一样假定每个节点只从一个父节点到达。"
        "本课用字符串到邻居列表的映射保存有向边，以 visited 阻止共享后继和回边造成重复访问。"
        "递归 DFS 在进入节点时登记。"
        "然后立即深入第一个未访问邻居。"
        "BFS 在邻居入队时登记。"
        "这样多个前驱不会把同一节点重复加入队列。"
        "示例固定邻居列表的顺序，使两种输出都可重复，差异来自深入与逐层扩展的策略。"
        "未出现为映射键的节点视为没有出边，起点只能覆盖它可达的连通区域。"
        "这里的 BFS 顺序适合无权图按边数分层，若边带不同权重，不能直接把首次到达当作最小代价答案。",
    objective: "能在一般有向图中避免重复访问。能解释 DFS、BFS 的顺序与可达范围。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "BFS 出队时才标记可能导致共享后继多次入队，应在发现时登记。",
      "从单一起点搜索只覆盖可达节点，不会自动遍历所有断开的区域。",
    ],
    code: r'''
void visitDepth(String node, Map<String, List<String>> graph, Set<String> visited, List<String> output) {
  if (!visited.add(node)) return;
  output.add(node);
  for (final next in graph[node] ?? <String>[]) visitDepth(next, graph, visited, output);
}
List<String> depthFirst(String start, Map<String, List<String>> graph) {
  final output = <String>[];
  visitDepth(start, graph, <String>{}, output);
  return output;
}
List<String> breadthFirst(String start, Map<String, List<String>> graph) {
  final queue = <String>[start]; final visited = <String>{start};
  var head = 0;
  while (head < queue.length) {
    final node = queue[head]; head++;
    for (final next in graph[node] ?? <String>[]) {
      if (visited.add(next)) queue.add(next);
    }
  }
  return queue;
}
void main() {
  final graph = <String, List<String>>{
    'A': ['B', 'C'], 'B': ['D'], 'C': ['D', 'E'], 'D': ['A'], 'E': [], 'Z': []
  };
  print(depthFirst('A', graph)); print(breadthFirst('A', graph));
  print(breadthFirst('A', graph).contains('Z'));
}
''',
    output: "[A, B, D, C, E]\n[A, B, C, D, E]\nfalse\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "对含自环与重复边的图 a:[a,b,b]、b:[c]、c:[a] 搜索。确认 DFS 与 BFS 都只返回三个节点一次。",
        hint: "visited.add 的布尔返回值同时完成发现判断和登记。自环无需特殊删除。",
        answer: r'''
void visitDepth(String node, Map<String, List<String>> graph, Set<String> visited, List<String> output) {
  if (!visited.add(node)) return;
  output.add(node);
  for (final next in graph[node] ?? <String>[]) visitDepth(next, graph, visited, output);
}
List<String> depthFirst(String start, Map<String, List<String>> graph) {
  final output = <String>[];
  visitDepth(start, graph, <String>{}, output);
  return output;
}
List<String> breadthFirst(String start, Map<String, List<String>> graph) {
  final queue = <String>[start]; final visited = <String>{start};
  var head = 0;
  while (head < queue.length) {
    final node = queue[head]; head++;
    for (final next in graph[node] ?? <String>[]) {
      if (visited.add(next)) queue.add(next);
    }
  }
  return queue;
}
void main() {
  final graph = <String, List<String>>{'a': ['a', 'b', 'b'], 'b': ['c'], 'c': ['a']};
  final dfs = depthFirst('a', graph); final bfs = breadthFirst('a', graph);
  print(dfs); print(bfs);
  print(dfs.length == 3 && dfs.toSet().length == 3);
  print(bfs.length == 3 && bfs.toSet().length == 3);
}
''',
      ),
    ],
    exampleTitle: "示例 180：邻接表上的深度与广度搜索",
    exampleSummary: "固定邻居次序、发现时登记的图深搜与广搜对照。",
  ),
];
