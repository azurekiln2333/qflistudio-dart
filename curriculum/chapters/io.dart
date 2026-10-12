import '../dart_lesson.dart';

/// Chapter `io` — lessons 097-104. Owned by the second pi.
///
/// Export name: `ioLessons`. Keep lessons sorted by id.
///
/// Every program here uses `dart:io` file APIs and requires the official Dart
/// SDK engine. Each creates its own temporary directory and removes it in a
/// `finally` block, so no files are left behind and output is deterministic
/// (no timestamps are printed).
const List<DartLesson> ioLessons = <DartLesson>[
  DartLesson(
    id: 'dart-lesson-097',
    chapter: 'io',
    level: 'advanced',
    title: '临时文件：写入与读取',
    summary: '在临时目录里写文件再读回，finally 中确保清理。',
    concepts: <String>['File', 'writeAsStringSync', 'readAsStringSync', '临时目录'],
    explain:
        'dart:io 的 File 提供同步与异步两套读写 API，初学用同步版更直观。'
        '程序产出的中间文件不该散落在用户目录，正确做法是 Directory.systemTemp.'
        'createTempSync() 建一个专属临时目录，往里写、读，最后在 finally 里递归删除——'
        '无论中间是否出错都会清理。本课写一段中文再读回，并打印字节长度'
        '（UTF-8 下中文占 3 字节）。需要官方 Dart SDK 引擎，dart_eval 不支持 dart:io。',
    objective: '能创建临时目录，写文件、读文件，并在 finally 中清理。',
    prerequisites: <String>['已掌握 try/finally', '官方 Dart SDK'],
    pitfalls: <String>[
      '忘记在 finally 中清理会在系统临时目录留下垃圾。',
      'lengthSync 返回字节数，中文不是以字符数计。',
      '同步 I/O 会阻塞事件循环，大文件应改用异步 API。',
    ],
    code: "import 'dart:io';\n"
        "\n"
        "void main() {\n"
        "  final dir = Directory.systemTemp.createTempSync('qfli_io_097_');\n"
        "  try {\n"
        "    final file = File('\${dir.path}/note.txt');\n"
        "    file.writeAsStringSync('你好，Dart');\n"
        "    print(file.readAsStringSync());\n"
        "    print('长度 \${file.lengthSync()}');\n"
        "  } finally {\n"
        "    dir.deleteSync(recursive: true);\n"
        "  }\n"
        "}\n",
    output: '你好，Dart\n长度 13\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '写一个文件内容为 "abc"，打印它的长度。',
        hint: '"abc" 是 3 个 ASCII 字节。',
        answer: "import 'dart:io';\n"
            "\n"
            "void main() {\n"
            "  final dir = Directory.systemTemp.createTempSync('qfli_ex_');\n"
            "  try {\n"
            "    final f = File('\${dir.path}/x.txt')..writeAsStringSync('abc');\n"
            "    print(f.lengthSync());\n"
            "  } finally {\n"
            "    dir.deleteSync(recursive: true);\n"
            "  }\n"
            "}",
      ),
    ],
    exampleTitle: '示例 097：临时文件读写',
    exampleSummary: '写中文到临时文件、读回并打印字节长度，finally 清理。',
  ),
  DartLesson(
    id: 'dart-lesson-098',
    chapter: 'io',
    level: 'advanced',
    title: '多行写入与按行读取',
    summary: '写入多行文本后用 readAsLinesSync 逐行读取。',
    concepts: <String>['readAsLinesSync', '换行', '行列表'],
    explain:
        '处理文本文件时常用的单位是"行"而不是整个字符串。readAsLinesSync 会把内容'
        '按换行符切分成 List<String>，自动处理跨平台的换行约定，'
        '因此你可以直接用 lines.length 数行数、用 lines.first/lines.last 取首末行。'
        '写入时用 \\n 明确分行。注意末尾若有换行，通常不会额外产生一个空行。'
        '需要官方 Dart SDK 引擎。',
    objective: '能把多行文本写入文件并用 readAsLinesSync 按行读取。',
    prerequisites: <String>['已掌握文件读写', '官方 Dart SDK'],
    pitfalls: <String>[
      'readAsLinesSync 返回的是行列表，不是一段含 \\n 的字符串。',
      '不同平台原始换行不同，按行读取能屏蔽这个差异。',
      '空文件会返回空列表，取 first/last 前要判空。',
    ],
    code: "import 'dart:io';\n"
        "\n"
        "void main() {\n"
        "  final dir = Directory.systemTemp.createTempSync('qfli_io_098_');\n"
        "  try {\n"
        "    final file = File('\${dir.path}/lines.txt');\n"
        "    file.writeAsStringSync('第一行\\n第二行\\n第三行\\n');\n"
        "    final lines = file.readAsLinesSync();\n"
        "    print('行数 \${lines.length}');\n"
        "    print('第一行 \${lines.first}');\n"
        "    print('最后一行 \${lines.last}');\n"
        "  } finally {\n"
        "    dir.deleteSync(recursive: true);\n"
        "  }\n"
        "}\n",
    output: '行数 3\n第一行 第一行\n最后一行 第三行\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '写入两行并打印第二行。',
        hint: 'readAsLinesSync()[1]。',
        answer: "import 'dart:io';\n"
            "\n"
            "void main() {\n"
            "  final dir = Directory.systemTemp.createTempSync('qfli_ex_');\n"
            "  try {\n"
            "    final f = File('\${dir.path}/two.txt')\n"
            "      ..writeAsStringSync('one\\ntwo\\n');\n"
            "    print(f.readAsLinesSync()[1]);\n"
            "  } finally {\n"
            "    dir.deleteSync(recursive: true);\n"
            "  }\n"
            "}",
      ),
    ],
    exampleTitle: '示例 098：按行读取',
    exampleSummary: '写入三行文本，按行读取并打印行数与首末行。',
  ),
  DartLesson(
    id: 'dart-lesson-099',
    chapter: 'io',
    level: 'advanced',
    title: '目录列举与过滤',
    summary: '用 listSync 列举目录内容，按扩展名过滤并统计。',
    concepts: <String>['listSync', 'whereType', '扩展名过滤'],
    explain:
        'listSync 返回目录里的实体（文件和子目录）。用 whereType<File>() 筛选出文件，'
        '再用 expand 或直接 map 取文件名，按扩展名过滤即可得到需要的清单。'
        '本课写两个 .dart 和一个 .txt，统计 .dart 文件数量并打印名字。'
        '注意 listSync 的顺序不保证稳定，因此打印前要排序，输出才确定。'
        '需要官方 Dart SDK 引擎。',
    objective: '能列举目录内容、筛选文件并按扩展名过滤统计。',
    prerequisites: <String>['已掌握目录与文件基础', '官方 Dart SDK'],
    pitfalls: <String>[
      'listSync 顺序不保证，统计集合要排序后再输出。',
      'listSync 默认不递归，子目录内容需递归处理。',
      'whereType<File>() 会排除子目录，注意区分。',
    ],
    code: "import 'dart:io';\n"
        "\n"
        "void main() {\n"
        "  final dir = Directory.systemTemp.createTempSync('qfli_io_099_');\n"
        "  try {\n"
        "    File('\${dir.path}/a.dart').writeAsStringSync('void main() {}');\n"
        "    File('\${dir.path}/b.dart').writeAsStringSync('void main() {}');\n"
        "    File('\${dir.path}/c.txt').writeAsStringSync('文本');\n"
        "    final names = dir\n"
        "        .listSync()\n"
        "        .whereType<File>()\n"
        "        .map((f) => f.uri.pathSegments.last)\n"
        "        .where((n) => n.endsWith('.dart'))\n"
        "        .toList()\n"
        "      ..sort();\n"
        "    print('dart 文件数 \${names.length}');\n"
        "    print(names);\n"
        "  } finally {\n"
        "    dir.deleteSync(recursive: true);\n"
        "  }\n"
        "}\n",
    output: 'dart 文件数 2\n[a.dart, b.dart]\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '统计目录中 .txt 文件的数量。',
        hint: '把过滤条件改成 endsWith(".txt")。',
        answer: "import 'dart:io';\n"
            "\n"
            "void main() {\n"
            "  final dir = Directory.systemTemp.createTempSync('qfli_ex_');\n"
            "  try {\n"
            "    File('\${dir.path}/a.txt').writeAsStringSync('a');\n"
            "    File('\${dir.path}/b.txt').writeAsStringSync('b');\n"
            "    final n = dir.listSync().whereType<File>()\n"
            "        .where((f) => f.path.endsWith('.txt')).length;\n"
            "    print(n);\n"
            "  } finally {\n"
            "    dir.deleteSync(recursive: true);\n"
            "  }\n"
            "}",
      ),
    ],
    exampleTitle: '示例 099：目录列举过滤',
    exampleSummary: '列举目录并按 .dart 扩展名过滤，排序后输出。',
  ),
  DartLesson(
    id: 'dart-lesson-100',
    chapter: 'io',
    level: 'advanced',
    title: '文件复制与存在性检查',
    summary: '用 copySync 复制文件，并用 existsSync 确认目标已创建。',
    concepts: <String>['copySync', 'existsSync', '路径'],
    explain:
        'copySync 把源文件复制到目标路径，返回新的 File。复制前后用 existsSync 检查'
        '文件是否存在，是防御式编程的常见做法——尤其当目标可能已被占用或源不存在时。'
        '本课建源文件、复制到新路径，确认目标存在并读出其内容验证一致。'
        '所有文件都落在专属临时目录，finally 里整体删除。需要官方 Dart SDK 引擎。',
    objective: '能复制文件并用 existsSync 验证结果。',
    prerequisites: <String>['已掌握文件写入与读取', '官方 Dart SDK'],
    pitfalls: <String>[
      '目标路径所在目录不存在时复制会失败，先确保父目录存在。',
      '复制会覆盖同名目标，必要时先检查 existsSync。',
      '复制是字节级操作，不涉及编码转换。',
    ],
    code: "import 'dart:io';\n"
        "\n"
        "void main() {\n"
        "  final dir = Directory.systemTemp.createTempSync('qfli_io_100_');\n"
        "  try {\n"
        "    final src = File('\${dir.path}/src.txt')..writeAsStringSync('复制我');\n"
        "    final dst = File('\${dir.path}/dst.txt');\n"
        "    src.copySync(dst.path);\n"
        "    print('目标存在 \${dst.existsSync()}');\n"
        "    print('内容 \${dst.readAsStringSync()}');\n"
        "  } finally {\n"
        "    dir.deleteSync(recursive: true);\n"
        "  }\n"
        "}\n",
    output: '目标存在 true\n内容 复制我\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '复制一个文件后，用 existsSync 打印目标是否存在的布尔值。',
        hint: 'copySync 后用 existsSync。',
        answer: "import 'dart:io';\n"
            "\n"
            "void main() {\n"
            "  final dir = Directory.systemTemp.createTempSync('qfli_ex_');\n"
            "  try {\n"
            "    final a = File('\${dir.path}/a')..writeAsStringSync('x');\n"
            "    final b = File('\${dir.path}/b');\n"
            "    a.copySync(b.path);\n"
            "    print(b.existsSync());\n"
            "  } finally {\n"
            "    dir.deleteSync(recursive: true);\n"
            "  }\n"
            "}",
      ),
    ],
    exampleTitle: '示例 100：文件复制',
    exampleSummary: '复制文件到新路径并验证目标存在及内容一致。',
  ),
  DartLesson(
    id: 'dart-lesson-101',
    chapter: 'io',
    level: 'advanced',
    title: '重命名与删除',
    summary: '用 renameSync 移动/改名文件，并确认旧路径不再存在。',
    concepts: <String>['renameSync', 'deleteSync', '路径迁移'],
    explain:
        'renameSync 能重命名文件，也能把它移动到另一个路径（同一文件系统内是原子操作）。'
        '操作后旧路径不再存在、新路径存在，且内容不变。这是整理文件、改变扩展名的'
        '常用手段。删除用 deleteSync。本课把 old.txt 改名为 new.txt，验证旧文件消失、'
        '新文件保留内容。需要官方 Dart SDK 引擎。',
    objective: '能用 renameSync 改名文件并验证旧路径消失、内容保留。',
    prerequisites: <String>['已掌握文件读写与存在性检查', '官方 Dart SDK'],
    pitfalls: <String>[
      '跨文件系统的 rename 可能退化为复制+删除，非原子。',
      '目标已存在时行为依平台而异，稳妥做法是先删或先检查。',
      '对已 rename 的旧 File 对象调用方法会因路径不存在而失败。',
    ],
    code: "import 'dart:io';\n"
        "\n"
        "void main() {\n"
        "  final dir = Directory.systemTemp.createTempSync('qfli_io_101_');\n"
        "  try {\n"
        "    final oldFile = File('\${dir.path}/old.txt')..writeAsStringSync('数据');\n"
        "    final newFile = File('\${dir.path}/new.txt');\n"
        "    oldFile.renameSync(newFile.path);\n"
        "    print('旧文件存在 \${oldFile.existsSync()}');\n"
        "    print('新文件存在 \${newFile.existsSync()}');\n"
        "    print('新文件内容 \${newFile.readAsStringSync()}');\n"
        "  } finally {\n"
        "    dir.deleteSync(recursive: true);\n"
        "  }\n"
        "}\n",
    output: '旧文件存在 false\n新文件存在 true\n新文件内容 数据\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '把 a.txt 改名为 a.bak，打印新文件名。',
        hint: 'renameSync 后用 uri.pathSegments.last。',
        answer: "import 'dart:io';\n"
            "\n"
            "void main() {\n"
            "  final dir = Directory.systemTemp.createTempSync('qfli_ex_');\n"
            "  try {\n"
            "    final a = File('\${dir.path}/a.txt')..writeAsStringSync('x');\n"
            "    final b = File('\${dir.path}/a.bak');\n"
            "    a.renameSync(b.path);\n"
            "    print(b.uri.pathSegments.last);\n"
            "  } finally {\n"
            "    dir.deleteSync(recursive: true);\n"
            "  }\n"
            "}",
      ),
    ],
    exampleTitle: '示例 101：重命名文件',
    exampleSummary: '把文件改名后确认旧路径消失、新文件内容保留。',
  ),
  DartLesson(
    id: 'dart-lesson-102',
    chapter: 'io',
    level: 'advanced',
    title: 'JSON 落盘往返',
    summary: '把 Map 编码成 JSON 写入文件，再读回解码还原。',
    concepts: <String>['jsonEncode', 'jsonDecode', '持久化'],
    explain:
        '把结构化数据持久化到磁盘，JSON 是最通用的格式：先用 jsonEncode 把 Map/List '
        '转成字符串写入文件，之后再读出来用 jsonDecode 还原。注意 jsonDecode 返回的'
        '是 dynamic，通常需要 as 成具体类型才能安全取字段。本课把带姓名和分数列表的'
        'Map 写盘再读回，验证往返一致。需要官方 Dart SDK 引擎。',
    objective: '能把 Map 编码写盘并用 jsonDecode 还原取字段。',
    prerequisites: <String>['已掌握文件读写与 JSON 基础', '官方 Dart SDK'],
    pitfalls: <String>[
      'jsonDecode 返回 dynamic，不转类型直接取字段容易类型错误。',
      '文件不是合法 JSON 时 jsonDecode 抛 FormatException。',
      '中文写入用 UTF-8，读取时也要按 UTF-8 解（默认即是）。',
    ],
    code: "import 'dart:convert';\n"
        "import 'dart:io';\n"
        "\n"
        "void main() {\n"
        "  final dir = Directory.systemTemp.createTempSync('qfli_io_102_');\n"
        "  try {\n"
        "    final file = File('\${dir.path}/data.json');\n"
        "    final data = <String, Object>{\n"
        "      'name': '小明',\n"
        "      'scores': <int>[90, 85],\n"
        "    };\n"
        "    file.writeAsStringSync(jsonEncode(data));\n"
        "    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;\n"
        "    print('name=\${decoded['name']}');\n"
        "    print('scores=\${decoded['scores']}');\n"
        "  } finally {\n"
        "    dir.deleteSync(recursive: true);\n"
        "  }\n"
        "}\n",
    output: 'name=小明\nscores=[90, 85]\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '把 [1, 2, 3] 编码写入文件再读回，打印长度。',
        hint: 'jsonDecode 后 as List 取 length。',
        answer: "import 'dart:convert';\n"
            "import 'dart:io';\n"
            "\n"
            "void main() {\n"
            "  final dir = Directory.systemTemp.createTempSync('qfli_ex_');\n"
            "  try {\n"
            "    final f = File('\${dir.path}/l.json')\n"
            "      ..writeAsStringSync(jsonEncode(<int>[1, 2, 3]));\n"
            "    final list = jsonDecode(f.readAsStringSync()) as List<Object?>;\n"
            "    print(list.length);\n"
            "  } finally {\n"
            "    dir.deleteSync(recursive: true);\n"
            "  }\n"
            "}",
      ),
    ],
    exampleTitle: '示例 102：JSON 落盘往返',
    exampleSummary: 'JSON 编码写入文件再解码还原，打印字段值。',
  ),
  DartLesson(
    id: 'dart-lesson-103',
    chapter: 'io',
    level: 'advanced',
    title: '递归统计目录文件数',
    summary: '递归遍历子目录，统计整棵目录树里的文件总数。',
    concepts: <String>['递归遍历', 'Directory', '子目录'],
    explain:
        '目录可以嵌套，统计文件数常需要递归：遍历一项，若是文件计数加一，'
        '若是子目录则递归进去。本课在临时根目录下建一个 sub 子目录，'
        '共放 3 个文件（1 个在根、2 个在 sub），递归统计得到 3。'
        '递归时要留意符号链接可能造成环，生产代码可改用 followLinks: false。'
        '需要官方 Dart SDK 引擎。',
    objective: '能写递归函数遍历目录树并统计文件数量。',
    prerequisites: <String>['已掌握目录列举与递归', '官方 Dart SDK'],
    pitfalls: <String>[
      'listSync 默认不跟随符号链接，递归时注意避免环。',
      '统计时别把子目录本身也算成文件。',
      '深层目录递归可能栈开销大，超深树考虑显式栈。',
    ],
    code: "import 'dart:io';\n"
        "\n"
        "int countFiles(Directory dir) {\n"
        "  var count = 0;\n"
        "  for (final entity in dir.listSync()) {\n"
        "    if (entity is File) {\n"
        "      count++;\n"
        "    } else if (entity is Directory) {\n"
        "      count += countFiles(entity);\n"
        "    }\n"
        "  }\n"
        "  return count;\n"
        "}\n"
        "\n"
        "void main() {\n"
        "  final root = Directory.systemTemp.createTempSync('qfli_io_103_');\n"
        "  try {\n"
        "    final sub = Directory('\${root.path}/sub')..createSync();\n"
        "    File('\${root.path}/a.txt').writeAsStringSync('a');\n"
        "    File('\${root.path}/sub/b.txt').writeAsStringSync('b');\n"
        "    File('\${root.path}/sub/c.txt').writeAsStringSync('c');\n"
        "    print(sub.existsSync());\n"
        "    print('文件总数 \${countFiles(root)}');\n"
        "  } finally {\n"
        "    root.deleteSync(recursive: true);\n"
        "  }\n"
        "}\n",
    output: 'true\n文件总数 3\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '写递归函数统计目录树中 .txt 文件的数量。',
        hint: '在递归里对文件名判断 endsWith(".txt")。',
        answer: "import 'dart:io';\n"
            "\n"
            "int countTxt(Directory dir) {\n"
            "  var n = 0;\n"
            "  for (final e in dir.listSync()) {\n"
            "    if (e is File && e.path.endsWith('.txt')) n++;\n"
            "    if (e is Directory) n += countTxt(e);\n"
            "  }\n"
            "  return n;\n"
            "}\n"
            "\n"
            "void main() {\n"
            "  final d = Directory.systemTemp.createTempSync('qfli_ex_');\n"
            "  try {\n"
            "    File('\${d.path}/a.txt').writeAsStringSync('a');\n"
            "    print(countTxt(d));\n"
            "  } finally {\n"
            "    d.deleteSync(recursive: true);\n"
            "  }\n"
            "}",
      ),
    ],
    exampleTitle: '示例 103：递归统计',
    exampleSummary: '递归遍历含子目录的目录树，统计文件总数。',
  ),
  DartLesson(
    id: 'dart-lesson-104',
    chapter: 'io',
    level: 'advanced',
    title: '文件元数据',
    summary: '读取文件是否存在、长度与类型等元数据（不打印时间）。',
    concepts: <String>['lengthSync', 'statSync', 'FileSystemEntityType'],
    explain:
        '除了内容，文件还有元数据：是否存在、多大、是文件还是目录、以及修改时间等。'
        'existsSync 查询存在性，lengthSync 取字节长度，statSync() 返回 FileStat，'
        '其 type 可判断是文件还是目录。本课只打印长度与类型这类稳定信息，'
        '刻意不打印修改时间——时间戳不确定，会让输出每次不同。需要官方 Dart SDK 引擎。',
    objective: '能读取文件的长度与类型等元数据并做判断。',
    prerequisites: <String>['已掌握文件读写', '官方 Dart SDK'],
    pitfalls: <String>[
      '不要打印 lastModified 等时间戳，否则输出不确定、无法断言。',
      'lengthSync 是字节数；statSync 也不返回字符数。',
      '对不存在的文件调用 lengthSync 会抛错，先 existsSync 判断。',
    ],
    code: "import 'dart:convert';\n"
        "import 'dart:io';\n"
        "\n"
        "void main() {\n"
        "  final dir = Directory.systemTemp.createTempSync('qfli_io_104_');\n"
        "  try {\n"
        "    final file = File('\${dir.path}/meta.txt');\n"
        "    file.writeAsStringSync('hello', encoding: utf8);\n"
        "    print('存在 \${file.existsSync()}');\n"
        "    print('长度 \${file.lengthSync()}');\n"
        "    print('是文件 \${file.statSync().type == FileSystemEntityType.file}');\n"
        "  } finally {\n"
        "    dir.deleteSync(recursive: true);\n"
        "  }\n"
        "}\n",
    output: '存在 true\n长度 5\n是文件 true\n',
    exercises: <DartExercise>[
      DartExercise(
        prompt: '写一个空文件，打印它的 lengthSync()。',
        hint: '空文件长度为 0。',
        answer: "import 'dart:io';\n"
            "\n"
            "void main() {\n"
            "  final dir = Directory.systemTemp.createTempSync('qfli_ex_');\n"
            "  try {\n"
            "    final f = File('\${dir.path}/empty.txt')..writeAsStringSync('');\n"
            "    print(f.lengthSync());\n"
            "  } finally {\n"
            "    dir.deleteSync(recursive: true);\n"
            "  }\n"
            "}",
      ),
    ],
    exampleTitle: '示例 104：文件元数据',
    exampleSummary: '读取文件的存在性、字节长度与实体类型。',
  ),
];
