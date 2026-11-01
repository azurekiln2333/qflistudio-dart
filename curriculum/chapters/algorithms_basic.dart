import '../dart_lesson.dart';

/// Chapter `algorithms-basic` — independently executed lessons and paired examples.
const List<DartLesson> algorithmsBasicLessons = <DartLesson>[
  DartLesson(
    id: "dart-lesson-145",
    chapter: "algorithms-basic",
    level: "beginner",
    title: "线性查找的首末位置",
    summary: "一次遍历同时记录目标第一次与最后一次出现的索引。",
    concepts: <String>["线性扫描", "索引哨兵", "循环不变量"],
    explain:
        "当数据没有排序时，逐项检查是最直接也最可靠的查找方法。"
        "本例同时寻找目标的首次和末次位置。"
        "首次位置只在尚未找到时写入。"
        "末次位置在每次命中后更新。"
        "扫描到任意下标时，两个变量只描述此前检查过的前缀。"
        "这就是理解算法正确性的循环不变量。"
        "未找到用负一表示，因为合法列表索引从零开始。"
        "空列表不进入循环，自然返回两个负一。"
        "一次扫描的时间与列表长度成正比，额外只需要两个整数。"
        "返回值是位置，不是目标值。"
        "调用者先确认它不为负一。再访问列表。"
        "这样可避免把失败哨兵误当索引。",
    objective: "能一次扫描取得首末命中位置，并安全处理未命中和空列表。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "每次命中都覆盖首次位置，会让首末结果退化为同一个末次位置。",
      "查找失败的负一不能直接作为 List 下标使用。",
    ],
    code: r'''
List<int> positions(List<int> values, int target) {
  var first = -1;
  var last = -1;
  for (var i = 0; i < values.length; i++) {
    if (values[i] == target) {
      if (first == -1) first = i;
      last = i;
    }
  }
  return [first, last];
}
void main() {
  final values = <int>[4, 2, 7, 2, 8, 2];
  print(positions(values, 2));
  print(positions(values, 9));
  print(positions([], 2));
}
''',
    output: "[1, 5]\n[-1, -1]\n[-1, -1]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "为目标 3 输出所有命中索引。数据为 [3, 1, 3, 3, 2]。",
        hint: "保留索引循环，命中时把当前 i 添加到一个独立结果列表。",
        answer: r'''
List<int> positions(List<int> values, int target) {
  var first = -1;
  var last = -1;
  for (var i = 0; i < values.length; i++) {
    if (values[i] == target) {
      if (first == -1) first = i;
      last = i;
    }
  }
  return [first, last];
}
void main() {
  final values = <int>[3, 1, 3, 3, 2];
  final indices = <int>[];
  for (var i = 0; i < values.length; i++) {
    if (values[i] == 3) indices.add(i);
  }
  print(indices);
}
''',
      ),
    ],
    exampleTitle: "示例 145：线性查找的首末位置",
    exampleSummary: "无序数据中首末命中位置与失败哨兵的处理。",
  ),
  DartLesson(
    id: "dart-lesson-146",
    chapter: "algorithms-basic",
    level: "intermediate",
    title: "带提前退出的冒泡排序",
    summary: "比较相邻元素逐轮归位，并在一轮没有交换时停止。",
    concepts: <String>["相邻交换", "有序后缀", "提前退出"],
    explain:
        "冒泡排序在每轮中比较相邻元素，把较大值不断推向右侧。"
        "第一轮结束后，最大元素已经位于末尾，因此下一轮可以少检查一个位置，逐步形成有序后缀。"
        "本例先复制输入，避免排序函数意外改动调用者的数据。"
        "每轮使用 changed 标记记录是否发生过交换。"
        "如果整轮没有交换，说明剩余前缀也已经有序，可以提前退出。"
        "最坏情况下仍需要平方级比较，但已排序输入只需一次线性扫描。"
        "严格使用大于号触发交换可以保留相等元素的先后次序。"
        "学习重点是每轮保证了什么，以及标记应在每一轮开始时重置，而不仅是最后得到一个排序列表。",
    objective: "能实现有序后缀收缩和提前退出，并验证排序不修改原列表。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "changed 若不在每轮重置，提前退出可能永远不会生效。",
      "内层比较 i 与 i+1，循环上界必须保证后者仍在列表内。",
    ],
    code: r'''
List<int> bubbleSort(List<int> input) {
  final values = List<int>.of(input);
  for (var end = values.length - 1; end > 0; end--) {
    var changed = false;
    for (var i = 0; i < end; i++) {
      if (values[i] > values[i + 1]) {
        final temp = values[i]; values[i] = values[i + 1]; values[i + 1] = temp;
        changed = true;
      }
    }
    if (!changed) break;
  }
  return values;
}
void main() {
  final input = <int>[5, 1, 4, 2, 2];
  print(bubbleSort(input));
  print('原列表 $input');
  print(bubbleSort([1, 2, 3]));
}
''',
    output: "[1, 2, 2, 4, 5]\n原列表 [5, 1, 4, 2, 2]\n[1, 2, 3]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "验证排序的两个属性。第一，输入列表不变。第二，再次排序结果相同。",
        hint: "保存原列表的文本快照。再用第二次 bubbleSort 的结果与第一次比较。",
        answer: r'''
List<int> bubbleSort(List<int> input) {
  final values = List<int>.of(input);
  for (var end = values.length - 1; end > 0; end--) {
    var changed = false;
    for (var i = 0; i < end; i++) {
      if (values[i] > values[i + 1]) {
        final temp = values[i]; values[i] = values[i + 1]; values[i + 1] = temp;
        changed = true;
      }
    }
    if (!changed) break;
  }
  return values;
}
void main() {
  final input = <int>[9, 4, 9, 1];
  final snapshot = input.join(',');
  final once = bubbleSort(input);
  print('输入未变 ${input.join(',') == snapshot}');
  print('重复排序一致 ${bubbleSort(once).join(',') == once.join(',')}');
}
''',
      ),
    ],
    exampleTitle: "示例 146：带提前退出的冒泡排序",
    exampleSummary: "有序后缀逐轮增长并可提前结束的冒泡排序。",
  ),
  DartLesson(
    id: "dart-lesson-147",
    chapter: "algorithms-basic",
    level: "intermediate",
    title: "选择排序与最小位置",
    summary: "每轮寻找未排序区间的最小索引，只在边界交换一次。",
    concepts: <String>["选择排序", "最小索引", "原地交换"],
    explain:
        "选择排序把列表分成已排序前缀与尚待处理的后缀。"
        "每轮先假设后缀第一个元素最小。再扫描剩余位置更新最小索引。最后将该元素交换到前缀边界。"
        "记录索引而不是只记录最小值，才能知道应该和哪个位置交换。"
        "程序在副本上操作，既显示一次交换完成一轮归位，也保留原始输入用于检查。"
        "无论输入是否已经有序，这种写法都需要扫描各个后缀，所以比较次数仍是平方级。"
        "交换次数较少并不代表整体时间复杂度变成线性。"
        "普通选择排序还可能改变相等键元素的相对顺序。"
        "所以处理带标签的记录时，不能把它自动当成稳定排序。",
    objective: "能通过扫描最小索引扩大有序前缀。能区分比较次数与交换次数。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "只保存最小值而忘记其索引，无法正确执行归位交换。",
      "一次远距离交换可能改变相等元素的先后关系，算法通常不稳定。",
    ],
    code: r'''
List<int> selectionSort(List<int> input) {
  final values = List<int>.of(input);
  for (var start = 0; start < values.length - 1; start++) {
    var minimum = start;
    for (var i = start + 1; i < values.length; i++) {
      if (values[i] < values[minimum]) minimum = i;
    }
    if (minimum != start) {
      final temp = values[start]; values[start] = values[minimum]; values[minimum] = temp;
    }
  }
  return values;
}
void main() {
  print(selectionSort([29, 10, 14, 37, 14]));
  print(selectionSort([]));
  print(selectionSort([7]));
}
''',
    output: "[10, 14, 14, 29, 37]\n[]\n[7]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "列表为 [3, 1, 2, 4]。用选择排序结果计算有多少个位置的值发生变化。",
        hint: "先排序副本。再按相同索引比较原值和结果值。最后一个元素可能原本就在正确位置。",
        answer: r'''
List<int> selectionSort(List<int> input) {
  final values = List<int>.of(input);
  for (var start = 0; start < values.length - 1; start++) {
    var minimum = start;
    for (var i = start + 1; i < values.length; i++) {
      if (values[i] < values[minimum]) minimum = i;
    }
    if (minimum != start) {
      final temp = values[start]; values[start] = values[minimum]; values[minimum] = temp;
    }
  }
  return values;
}
void main() {
  final input = <int>[3, 1, 2, 4];
  final sorted = selectionSort(input);
  var changed = 0;
  for (var i = 0; i < input.length; i++) if (input[i] != sorted[i]) changed++;
  print(sorted);
  print('变化位置 $changed');
}
''',
      ),
    ],
    exampleTitle: "示例 147：选择排序与最小位置",
    exampleSummary: "保存最小索引、每轮一次归位交换的选择排序。",
  ),
  DartLesson(
    id: "dart-lesson-148",
    chapter: "algorithms-basic",
    level: "intermediate",
    title: "插入排序的有序前缀",
    summary: "暂存待插元素，移动更大元素，为它在有序前缀中腾出位置。",
    concepts: <String>["插入排序", "元素右移", "稳定性"],
    explain:
        "插入排序模拟整理手中纸牌：左侧始终保持有序，下一张牌需要插入到合适的位置。"
        "程序先暂存当前值。"
        "程序再从已排序前缀的右端向左比较。"
        "程序把更大的值依次右移。"
        "最后把暂存值写入空位。"
        "暂存步骤非常重要，否则移动过程中可能覆盖还未保存的数据。"
        "比较条件使用严格大于，相等值不会越过彼此，因此这种实现保持稳定。"
        "已经基本有序的数据只需很少移动，完全逆序时则可能执行平方级操作。"
        "示例包含重复值和负数。"
        "它显示算法不依赖数值范围。"
        "读者也能观察前缀如何逐步成为整个有序列表。"
        "函数仍在副本上操作，便于独立复用。",
    objective: "能实现元素右移式插入排序。能解释暂存值和严格比较的作用。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "先移动再保存当前值，可能覆盖需要插入的元素。",
      "若把大于改成大于等于，相等记录会反复移动，稳定性会改变。",
    ],
    code: r'''
List<int> insertionSort(List<int> input) {
  final values = List<int>.of(input);
  for (var i = 1; i < values.length; i++) {
    final current = values[i];
    var position = i - 1;
    while (position >= 0 && values[position] > current) {
      values[position + 1] = values[position]; position--;
    }
    values[position + 1] = current;
  }
  return values;
}
void main() {
  print(insertionSort([7, -1, 4, 4, 2]));
  print(insertionSort([1, 2, 3]));
}
''',
    output: "[-1, 2, 4, 4, 7]\n[1, 2, 3]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "依次输出 [4, 2, 5, 1] 长度 1 到 4 的前缀排序结果。观察有序集合如何增长。",
        hint: "用 sublist 取得当前前缀。再调用 insertionSort，注意结束索引不包含在范围内。",
        answer: r'''
List<int> insertionSort(List<int> input) {
  final values = List<int>.of(input);
  for (var i = 1; i < values.length; i++) {
    final current = values[i];
    var position = i - 1;
    while (position >= 0 && values[position] > current) {
      values[position + 1] = values[position]; position--;
    }
    values[position + 1] = current;
  }
  return values;
}
void main() {
  final input = <int>[4, 2, 5, 1];
  for (var length = 1; length <= input.length; length++) {
    print(insertionSort(input.sublist(0, length)));
  }
}
''',
      ),
    ],
    exampleTitle: "示例 148：插入排序的有序前缀",
    exampleSummary: "通过暂存和右移为新元素腾出位置的插入排序。",
  ),
  DartLesson(
    id: "dart-lesson-149",
    chapter: "algorithms-basic",
    level: "intermediate",
    title: "二分查找的闭区间",
    summary: "在有序列表中反复排除一半候选，并正确收缩闭区间边界。",
    concepts: <String>["二分查找", "闭区间", "有序前提"],
    explain:
        "二分查找依赖输入已经按同一比较规则排序，每次比较中点后才能排除一整半候选。"
        "本课使用包含左右端点的闭区间，循环条件是左边界不大于右边界。"
        "目标更大时将左边界移到中点后一位，目标更小时将右边界移到中点前一位。"
        "这样每轮都严格减少候选数量，不会卡在同一中点。"
        "中点通过左边界加区间长度的一半计算，表达方式也能避免某些整数系统中的两端相加溢出。"
        "找到时返回索引，失败返回负一。"
        "本函数不保证重复值命中位置最左。"
        "若业务要求首次位置，需要继续缩小到左半区。"
        "找到后不能立即返回。",
    objective: "能维护闭区间边界并说明排序前提与重复值命中契约。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "对未排序数据使用二分查找，即使偶尔找到也不具备正确性保证。",
      "边界更新必须跨过已检查中点，不能只写 left = middle。",
    ],
    code: r'''
int binaryFind(List<int> sorted, int target) {
  var left = 0;
  var right = sorted.length - 1;
  while (left <= right) {
    final middle = left + (right - left) ~/ 2;
    if (sorted[middle] == target) return middle;
    if (sorted[middle] < target) { left = middle + 1; }
    else { right = middle - 1; }
  }
  return -1;
}
void main() {
  final sorted = <int>[2, 5, 8, 12, 16, 23];
  print(binaryFind(sorted, 12));
  print(binaryFind(sorted, 3));
  print(binaryFind([], 12));
}
''',
    output: "3\n-1\n-1\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "对有序列表 [1, 4, 7, 9] 查询 1、5、9。输出每次命中状态并统计命中总数。",
        hint: "查询函数返回索引。先判断是否非负再累计。不要把目标值和索引混淆。",
        answer: r'''
int binaryFind(List<int> sorted, int target) {
  var left = 0;
  var right = sorted.length - 1;
  while (left <= right) {
    final middle = left + (right - left) ~/ 2;
    if (sorted[middle] == target) return middle;
    if (sorted[middle] < target) { left = middle + 1; }
    else { right = middle - 1; }
  }
  return -1;
}
void main() {
  final sorted = <int>[1, 4, 7, 9];
  var hits = 0;
  for (final target in [1, 5, 9]) {
    final index = binaryFind(sorted, target);
    if (index >= 0) hits++;
    print('$target 命中=${index >= 0}');
  }
  print('命中 $hits');
}
''',
      ),
    ],
    exampleTitle: "示例 149：二分查找的闭区间",
    exampleSummary: "每轮严格排除中点的有序闭区间二分查找。",
  ),
  DartLesson(
    id: "dart-lesson-150",
    chapter: "algorithms-basic",
    level: "intermediate",
    title: "支持负数的计数排序",
    summary: "用最小值偏移构建频率桶，在小数值范围内恢复有序结果。",
    concepts: <String>["计数桶", "偏移量", "范围复杂度"],
    explain:
        "计数排序不通过元素之间的比较决定顺序，而是统计每个可能数值出现多少次。"
        "为了支持负数，程序先扫描最小值和最大值。"
        "程序用值减最小值作为桶索引。"
        "恢复时再把索引加回最小值。"
        "每个桶的次数决定该值向结果列表添加多少次，因此重复数据不会丢失。"
        "空输入直接返回空列表。"
        "范围过大则拒绝分配，以免少量但相差巨大的数值消耗大量内存。"
        "时间和空间既取决于元素数量，也取决于最大最小值之间的范围。"
        "通常写作 O(n+k)。"
        "因此它适合成绩、少量离散等级等紧凑整数域，不适合直接处理任意稀疏的大整数编号。",
    objective: "能通过偏移量支持负数计数。能判断计数排序的资源适用范围。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "直接把负数当桶索引会越界，必须减去统一的最小值。",
      "数值范围很大时桶数组会浪费内存，元素少也不代表适用。",
    ],
    code: r'''
List<int> countingSort(List<int> input) {
  if (input.isEmpty) return [];
  var low = input[0]; var high = input[0];
  for (final value in input) { if (value < low) low = value; if (value > high) high = value; }
  if (high - low > 10000) throw ArgumentError('范围过大');
  final counts = List<int>.filled(high - low + 1, 0);
  for (final value in input) {
    final bucket = value - low;
    counts[bucket] = counts[bucket] + 1;
  }
  final result = <int>[];
  for (var bucket = 0; bucket < counts.length; bucket++) {
    for (var repeat = 0; repeat < counts[bucket]; repeat++) result.add(bucket + low);
  }
  return result;
}
void main() {
  print(countingSort([3, -2, 1, 3, 0, -2]));
  print(countingSort([]));
}
''',
    output: "[-2, -2, 0, 1, 3, 3]\n[]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把等级 [2, 1, 2, 0, 1, 2] 排序后统计各等级次数。结果按等级升序。",
        hint: "排序结果相同值相邻。也可以再次累计到保持插入顺序的 Map。",
        answer: r'''
List<int> countingSort(List<int> input) {
  if (input.isEmpty) return [];
  var low = input[0]; var high = input[0];
  for (final value in input) { if (value < low) low = value; if (value > high) high = value; }
  if (high - low > 10000) throw ArgumentError('范围过大');
  final counts = List<int>.filled(high - low + 1, 0);
  for (final value in input) {
    final bucket = value - low;
    counts[bucket] = counts[bucket] + 1;
  }
  final result = <int>[];
  for (var bucket = 0; bucket < counts.length; bucket++) {
    for (var repeat = 0; repeat < counts[bucket]; repeat++) result.add(bucket + low);
  }
  return result;
}
void main() {
  final counts = <int, int>{};
  for (final value in countingSort([2, 1, 2, 0, 1, 2])) counts[value] = (counts[value] ?? 0) + 1;
  print(counts);
}
''',
      ),
    ],
    exampleTitle: "示例 150：支持负数的计数排序",
    exampleSummary: "负数偏移桶与小范围整数频率恢复。",
  ),
  DartLesson(
    id: "dart-lesson-151",
    chapter: "algorithms-basic",
    level: "intermediate",
    title: "归并两个有序序列",
    summary: "用两个独立游标线性合并数据，保留重复元素与输入顺序。",
    concepts: <String>["双游标", "归并", "剩余尾部"],
    explain:
        "两个已经升序排列的列表合并时，不必重新把所有元素放在一起排序。"
        "程序分别保存左右游标。"
        "每次取当前较小的一项加入结果。"
        "程序只推进取值的一侧，结果前缀始终有序。"
        "任意一侧用完后，另一侧剩余尾部本来已经有序，可以整体附加。"
        "每个元素只移动一次，时间与两侧总长度成正比。"
        "程序在相等时优先取左侧，为将来合并带相同键的记录保留稳定性。"
        "输入列表保持不变，结果则新分配空间。"
        "本函数的正确性来自两个输入都已排序这一前提。"
        "若任意输入内部无序，仅比较两个当前元素无法修复更后面的逆序。",
    objective: "能维护两个游标完成稳定归并，并处理一侧为空或提前耗尽。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>["取了左侧元素却推进右游标，会漏项或造成重复。", "循环结束后忘记附加剩余尾部，会使结果长度小于输入总和。"],
    code: r'''
List<int> mergeSorted(List<int> left, List<int> right) {
  var i = 0; var j = 0;
  final result = <int>[];
  while (i < left.length && j < right.length) {
    if (left[i] <= right[j]) { result.add(left[i++]); }
    else { result.add(right[j++]); }
  }
  result.addAll(left.sublist(i));
  result.addAll(right.sublist(j));
  return result;
}
void main() {
  print(mergeSorted([1, 4, 4, 9], [2, 4, 7]));
  print(mergeSorted([], [3, 5]));
}
''',
    output: "[1, 2, 4, 4, 4, 7, 9]\n[3, 5]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "把三批有序数据 [1, 8]、[2, 5]、[3, 9] 合并。再检查总长度不变。",
        hint: "两次调用 mergeSorted，第二次把前两批的结果与第三批合并。",
        answer: r'''
List<int> mergeSorted(List<int> left, List<int> right) {
  var i = 0; var j = 0;
  final result = <int>[];
  while (i < left.length && j < right.length) {
    if (left[i] <= right[j]) { result.add(left[i++]); }
    else { result.add(right[j++]); }
  }
  result.addAll(left.sublist(i));
  result.addAll(right.sublist(j));
  return result;
}
void main() {
  final first = <int>[1, 8]; final second = <int>[2, 5]; final third = <int>[3, 9];
  final merged = mergeSorted(mergeSorted(first, second), third);
  print(merged);
  print(merged.length == first.length + second.length + third.length);
}
''',
      ),
    ],
    exampleTitle: "示例 151：归并两个有序序列",
    exampleSummary: "不重新排序即可线性合并两个已排序列表。",
  ),
  DartLesson(
    id: "dart-lesson-152",
    chapter: "algorithms-basic",
    level: "intermediate",
    title: "保留首次顺序的去重",
    summary: "用集合记录已见值，用列表保留首次出现的显示顺序。",
    concepts: <String>["稳定去重", "Set.add", "结果列表"],
    explain:
        "去重有两个不同要求：判断一个值以前是否出现过，以及决定保留项的输出顺序。"
        "本例用 Set 负责快速成员判断，用独立 List 记录第一次遇到的值。"
        "当 seen.add 返回 true 时，说明集合确实新增了该值，才把它加入结果。"
        "这样结果顺序由原列表的首次出现顺序决定，而不是由数值大小决定。"
        "额外空间与不同值的数量成正比，通常比每次在结果列表中线性查找更高效。"
        "对自定义对象应用同一策略时，正确性还依赖相等运算和 hashCode 的一致契约。"
        "本课使用整数以集中讨论顺序。"
        "去重会丢失重复次数，若次数本身有意义，应另外保存频率表。",
    objective: "能分别维护成员状态与结果顺序，并区分去重和频率统计。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "先排序再去重会改变原始首次出现顺序。",
      "自定义对象的 == 与 hashCode 不一致时，哈希集合不能可靠识别重复。",
    ],
    code: r'''
List<int> stableUnique(List<int> input) {
  final seen = <int>{};
  final result = <int>[];
  for (final value in input) {
    if (seen.add(value)) result.add(value);
  }
  return result;
}
void main() {
  print(stableUnique([4, 1, 4, 2, 1, 3, 2]));
  print(stableUnique([]));
}
''',
    output: "[4, 1, 2, 3]\n[]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "找出至少重复一次的值。每个重复值只输出一次。顺序按首次发现重复的时刻决定。",
        hint: "用 seen 判断曾出现，用 reported 防止同一个重复值输出多次。",
        answer: r'''
List<int> stableUnique(List<int> input) {
  final seen = <int>{};
  final result = <int>[];
  for (final value in input) {
    if (seen.add(value)) result.add(value);
  }
  return result;
}
void main() {
  final seen = <int>{}; final reported = <int>{}; final duplicates = <int>[];
  for (final value in [4, 1, 4, 2, 1, 4, 2]) {
    if (!seen.add(value) && reported.add(value)) duplicates.add(value);
  }
  print(duplicates);
}
''',
      ),
    ],
    exampleTitle: "示例 152：保留首次顺序的去重",
    exampleSummary: "成员集合与独立列表组合实现稳定去重。",
  ),
  DartLesson(
    id: "dart-lesson-153",
    chapter: "algorithms-basic",
    level: "intermediate",
    title: "一次扫描求值域",
    summary: "从首元素取得真实初值。同时计算最小值、最大值和极差。",
    concepts: <String>["聚合扫描", "初值选择", "极差"],
    explain:
        "一组测量值的值域由最小值和最大值共同决定，极差则是二者之差。"
        "程序只扫描列表一次。"
        "每个新元素同时与当前最小值和最大值比较。"
        "因此无需排序就能获得三项结果。"
        "两个聚合变量从首元素开始初始化，避免把零错误地当成所有数据都能比较的默认边界。"
        "这对于全负数列表尤其重要。"
        "空列表没有可定义的最小和最大值，函数明确抛出 ArgumentError，让调用者选择提示或其他业务策略。"
        "结果 Map 为每项指标给出名称，比依靠无说明的下标更易读。"
        "算法只使用常数额外空间，适合只关心范围而不需要完整排序结果的场景。",
    objective: "能选择正确聚合初值，一次遍历计算值域并拒绝空数据。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "把最大值初始化成零会让全负数输入得到不存在的最大值。",
      "空数据不存在自然的最值，不能随意返回零冒充真实测量结果。",
    ],
    code: r'''
Map<String, int> rangeOf(List<int> values) {
  if (values.isEmpty) throw ArgumentError('至少需要一个数');
  var low = values[0]; var high = values[0];
  for (final value in values.skip(1)) {
    if (value < low) low = value;
    if (value > high) high = value;
  }
  return {'min': low, 'max': high, 'spread': high - low};
}
void main() {
  print(rangeOf([-8, -3, -12, -6]));
  print(rangeOf([5]));
  try { rangeOf([]); } on ArgumentError { print('空数据已拒绝'); }
}
''',
    output:
        "{min: -12, max: -3, spread: 9}\n{min: 5, max: 5, spread: 0}\n空数据已拒绝\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "比较两批温度的波动：[-2, 3, 1] 与 [5, 6, 7]，输出极差更大的一批。",
        hint: "分别调用 rangeOf，比较 spread 指标，不需要合并或排序原数据。",
        answer: r'''
Map<String, int> rangeOf(List<int> values) {
  if (values.isEmpty) throw ArgumentError('至少需要一个数');
  var low = values[0]; var high = values[0];
  for (final value in values.skip(1)) {
    if (value < low) low = value;
    if (value > high) high = value;
  }
  return {'min': low, 'max': high, 'spread': high - low};
}
void main() {
  final first = rangeOf([-2, 3, 1]); final second = rangeOf([5, 6, 7]);
  print('第一批 ${first['spread']}，第二批 ${second['spread']}');
  print(first['spread']! > second['spread']! ? '第一批波动更大' : '第二批波动更大或相同');
}
''',
      ),
    ],
    exampleTitle: "示例 153：一次扫描求值域",
    exampleSummary: "无需排序的一次遍历最值与极差聚合。",
  ),
  DartLesson(
    id: "dart-lesson-154",
    chapter: "algorithms-basic",
    level: "advanced",
    title: "有序两数之和",
    summary: "根据当前和的大小移动首尾指针，寻找两个不同位置的目标和。",
    concepts: <String>["双指针", "单调性", "不同索引"],
    explain:
        "在升序列表中寻找两数之和，可以利用单调性避免枚举所有配对。"
        "左指针先取最小值，右指针先取最大值。"
        "当前和太小时，保持左端只会让其他更小右端得到更小结果，因此可以安全抛弃当前左端并右移。"
        "当前和太大时同理左移右端。"
        "每轮至少移动一个指针，总时间是线性级，额外空间为常数。"
        "循环使用 left 小于 right，保证不会把同一个位置重复使用，即使目标正好等于某个值的两倍也一样。"
        "程序返回两个索引而非数值。同时用 null 表示无解。"
        "本方法依赖排序，若原始位置必须保留，应先设计带索引的排序副本或使用其他查找策略。",
    objective: "能利用有序性排除不可能端点，并保证两个命中位置不同。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "left <= right 会允许同一元素使用两次，不符合两数配对契约。",
      "排序后的索引不再等于原始索引，返回位置的含义必须明确。",
    ],
    code: r'''
List<int>? pairFor(List<int> sorted, int target) {
  var left = 0; var right = sorted.length - 1;
  while (left < right) {
    final sum = sorted[left] + sorted[right];
    if (sum == target) return [left, right];
    if (sum < target) { left++; } else { right--; }
  }
  return null;
}
void main() {
  final values = <int>[1, 2, 4, 6, 9];
  final pair = pairFor(values, 10);
  print(pair);
  if (pair != null) print('${values[pair[0]]}+${values[pair[1]]}=10');
  print(pairFor([5], 10));
}
''',
    output: "[0, 4]\n1+9=10\nnull\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "对有序列表 [2, 2, 3, 7] 查询目标 4 和 20。输出找到的数值对或“无解”。",
        hint: "相同数值位于不同索引时可以配对。null 仍代表没有两个合法位置。",
        answer: r'''
List<int>? pairFor(List<int> sorted, int target) {
  var left = 0; var right = sorted.length - 1;
  while (left < right) {
    final sum = sorted[left] + sorted[right];
    if (sum == target) return [left, right];
    if (sum < target) { left++; } else { right--; }
  }
  return null;
}
void main() {
  final values = <int>[2, 2, 3, 7];
  for (final target in [4, 20]) {
    final pair = pairFor(values, target);
    print(pair == null ? '无解' : '${values[pair[0]]},${values[pair[1]]}');
  }
}
''',
      ),
    ],
    exampleTitle: "示例 154：有序两数之和",
    exampleSummary: "依赖单调性收缩候选区间的有序两数配对。",
  ),
  DartLesson(
    id: "dart-lesson-155",
    chapter: "algorithms-basic",
    level: "advanced",
    title: "最大连续子段与边界",
    summary: "每个位置选择重新开始或延续子段。同时保存最佳半开区间。",
    concepts: <String>["Kadane", "状态转移", "半开区间"],
    explain:
        "最大连续子段要求选择相邻的一段元素，使它们的和最大，不能随意跳过段内负数。"
        "算法在每个位置维护以这里结尾的最佳和：要么从当前元素重新开始，要么把它接到上一段之后。"
        "若旧段的和已经为负，保留它只会拖低新段，因此重新开始更优。"
        "程序同时记录当前起点和全局最佳的结束边界，用半开区间直接配合 sublist 取出结果。"
        "初值来自首元素，保证全负数输入也会选中一个真实元素，而不是错误地返回空段的零。"
        "相等时不更新全局结果，使较早出现的最佳段得到保留。"
        "整个过程一次扫描即可完成，是状态压缩动态规划的一种典型应用。",
    objective: "能求出非空最大连续子段的和及边界，并正确处理全负数。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "把最佳和初始化为零会让全负数输入错误地选择空段。",
      "sublist 的结束索引不包含该位置，保存边界时要加一。",
    ],
    code: r'''
Map<String, int> bestSegment(List<int> values) {
  if (values.isEmpty) throw ArgumentError('必须非空');
  var current = values[0]; var best = values[0];
  var start = 0; var bestStart = 0; var bestEnd = 1;
  for (var i = 1; i < values.length; i++) {
    if (current < 0) { current = values[i]; start = i; }
    else { current += values[i]; }
    if (current > best) { best = current; bestStart = start; bestEnd = i + 1; }
  }
  return {'sum': best, 'start': bestStart, 'end': bestEnd};
}
void main() {
  final values = <int>[-2, 1, -3, 4, -1, 2, 1, -5, 4];
  final best = bestSegment(values);
  print(best);
  print(values.sublist(best['start']!, best['end']!));
}
''',
    output: "{sum: 6, start: 3, end: 7}\n[4, -1, 2, 1]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "用全负数 [-5, -2, -9] 验证不能返回空段。输出最佳和与实际选中的元素。",
        hint: "复用 bestSegment，用保存的半开边界取回子列表，结果应包含真实元素。",
        answer: r'''
Map<String, int> bestSegment(List<int> values) {
  if (values.isEmpty) throw ArgumentError('必须非空');
  var current = values[0]; var best = values[0];
  var start = 0; var bestStart = 0; var bestEnd = 1;
  for (var i = 1; i < values.length; i++) {
    if (current < 0) { current = values[i]; start = i; }
    else { current += values[i]; }
    if (current > best) { best = current; bestStart = start; bestEnd = i + 1; }
  }
  return {'sum': best, 'start': bestStart, 'end': bestEnd};
}
void main() {
  final values = <int>[-5, -2, -9];
  final result = bestSegment(values);
  print(result['sum']);
  print(values.sublist(result['start']!, result['end']!));
}
''',
      ),
    ],
    exampleTitle: "示例 155：最大连续子段与边界",
    exampleSummary: "一次扫描同时求最大连续子段和与可还原边界。",
  ),
  DartLesson(
    id: "dart-lesson-156",
    chapter: "algorithms-basic",
    level: "advanced",
    title: "三路分治快速排序",
    summary: "围绕基准拆成小于、等于、大于三段，递归合并有序结果。",
    concepts: <String>["分治", "三路划分", "递归终止"],
    explain:
        "快速排序先选择一个基准。"
        "程序把问题拆成两个规模更小的排序任务。"
        "再把结果组合起来。"
        "本例额外保留等于基准的一段，避免大量重复值反复进入递归。"
        "小于和大于两段各自递归排序，中间的相等段已经无需处理。"
        "长度不足二时返回副本，这既是递归终止条件，也确保函数不会把原列表直接暴露为可修改结果。"
        "示例选中间位置的值作基准，但这不保证每次都均衡。"
        "平均时间通常为 O(n log n)，极端划分仍可能退化。"
        "本实现强调清晰的分段与组合，会分配额外列表，并不是节省空间的原地快速排序。"
        "大规模数据还要考虑递归深度和内存成本。",
    objective: "能实现带重复值分区的递归排序。能解释平均、最坏与空间成本。",
    prerequisites: <String>["已掌握 Dart 变量、条件、循环与函数。"],
    pitfalls: <String>[
      "忘记把等于基准的元素移出递归，会在重复数据上失去规模缩小保证。",
      "创建分区列表的写法不是原地排序，不能声称只占常数空间。",
    ],
    code: r'''
List<int> quickSort(List<int> values) {
  if (values.length < 2) return List<int>.of(values);
  final pivot = values[values.length ~/ 2];
  final less = <int>[]; final equal = <int>[]; final greater = <int>[];
  for (final value in values) {
    if (value < pivot) { less.add(value); }
    else if (value > pivot) { greater.add(value); }
    else { equal.add(value); }
  }
  return [...quickSort(less), ...equal, ...quickSort(greater)];
}
void main() {
  final input = <int>[8, 3, 8, 1, 6, 3, -2];
  print(quickSort(input));
  print('输入 $input');
  print(quickSort([4, 4, 4]));
}
''',
    output: "[-2, 1, 3, 3, 6, 8, 8]\n输入 [8, 3, 8, 1, 6, 3, -2]\n[4, 4, 4]\n",
    exercises: <DartExercise>[
      DartExercise(
        prompt: "用 Dart 自带 sort 作为独立参照。验证快速排序对逆序、重复值和空列表都给出相同结果。",
        hint: "参照与待测算法都复制输入。程序比较排序后的完整序列，不只比较首尾。",
        answer: r'''
List<int> quickSort(List<int> values) {
  if (values.length < 2) return List<int>.of(values);
  final pivot = values[values.length ~/ 2];
  final less = <int>[]; final equal = <int>[]; final greater = <int>[];
  for (final value in values) {
    if (value < pivot) { less.add(value); }
    else if (value > pivot) { greater.add(value); }
    else { equal.add(value); }
  }
  return [...quickSort(less), ...equal, ...quickSort(greater)];
}
void main() {
  for (final input in <List<int>>[[5, 4, 3, 2], [2, 1, 2], []]) {
    final expected = List<int>.of(input)..sort();
    print(quickSort(input).join(',') == expected.join(','));
  }
}
''',
      ),
    ],
    exampleTitle: "示例 156：三路分治快速排序",
    exampleSummary: "小于、相等与大于三段组合的递归分治排序。",
  ),
];
