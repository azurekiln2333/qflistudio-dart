# Expansion A: independently authored and executed lessons 121–180

Verified on October 22, 2026, Windows x64; installed Dart SDK 3.11.5 stable.

## Result and owned files

60 substantive lessons, 60 paired examples and 60 complete exercise answers are ready for root integration. Every final program passed actual SDK execution and the production portable content runner, with exact LF-normalized stdout equality. The final accepted matrix contains **180/180 program slots per engine (360 successful executions)**. No programs are skipped, mocked or replaced with expected-output prints.

| File under `curriculum/chapters/` | Export | IDs | Lessons | SDK programs | Product portable programs |
| --- | --- | --- | ---: | ---: | ---: |
| `numbers_strings.dart` | `numbersStringsLessons` | 121–132 | 12 | 36/36 | 36/36 |
| `text_processing.dart` | `textProcessingLessons` | 133–144 | 12 | 36/36 | 36/36 |
| `algorithms_basic.dart` | `algorithmsBasicLessons` | 145–156 | 12 | 36/36 | 36/36 |
| `algorithms_advanced.dart` | `algorithmsAdvancedLessons` | 157–168 | 12 | 36/36 | 36/36 |
| `data_structures.dart` | `dataStructuresLessons` | 169–180 | 12 | 36/36 | 36/36 |

Each topic has its own Chinese teaching prose, objective, three or more concepts, two or more concrete pitfalls, self-contained runnable code, a specific exercise with a full runnable answer, and a unique paired-example summary. Explanations are 221–310 characters before the integration generator appends its engine note. Lesson/example code sharing is only within an allowed pair.

The chapters retain the intended algorithms: negative-offset counting sort, stable merging, actual Kadane boundaries, recursive three-way quicksort, multiple DP families, pointer-based linked lists, identity-based Floyd detection, ordered-list stable priority queue, size-weighted path-compressed union-find, and visited-aware DFS/BFS. Resource and domain limits are explained in the relevant prose.

## Execution and source/output linkage

Private audit harness: `.dart_tool/expansion-a/verify.dart`. Each selected lesson produces three separate executions: lesson, paired example, exercise answer. The SDK process uses `Platform.resolvedExecutable --enable-asserts <source.dart>` with a 12-second kill timeout. Portable execution calls the real `runPortableContent(source)` exported by `tool/portable_content_runner.dart`; normal `.dart_tool/package_config.json` resolves `tom_d4rt` to `vendor/tom_d4rt`. This exercises the product supervisor and policy path, rather than an author-local interpreter.

A pass requires SDK exit 0, no portable error, identical nonempty LF-normalized stdout and no `Instance of` or `UnimplementedError` output. Emission copies SDK stdout from the accepted result; the emitter refuses a report whose saved source differs from current authoring. The post-emission structural checker imports the actual Dart const lists and checks their program text and stored output against the accepted execution report.

Commands executed (chapter filtering selects all 12 records):

```powershell
python .dart_tool/expansion-a/author.py
dart --packages=.dart_tool/package_config.json .dart_tool/expansion-a/verify.dart numbers-strings
dart --packages=.dart_tool/package_config.json .dart_tool/expansion-a/verify.dart text-processing
dart --packages=.dart_tool/package_config.json .dart_tool/expansion-a/verify.dart algorithms-basic
dart --packages=.dart_tool/package_config.json .dart_tool/expansion-a/verify.dart algorithms-basic dart-lesson-150
dart --packages=.dart_tool/package_config.json .dart_tool/expansion-a/verify.dart algorithms-advanced
dart --packages=.dart_tool/package_config.json .dart_tool/expansion-a/verify.dart data-structures
python .dart_tool/expansion-a/emit.py
dart format curriculum/chapters/numbers_strings.dart curriculum/chapters/text_processing.dart curriculum/chapters/algorithms_basic.dart curriculum/chapters/algorithms_advanced.dart curriculum/chapters/data_structures.dart
flutter analyze --no-pub curriculum/chapters/numbers_strings.dart curriculum/chapters/text_processing.dart curriculum/chapters/algorithms_basic.dart curriculum/chapters/algorithms_advanced.dart curriculum/chapters/data_structures.dart
python .dart_tool/expansion-a/make_structure.py
dart --packages=.dart_tool/package_config.json .dart_tool/expansion-a/structure.dart
```

Focused Flutter analysis: **No issues found**. Structural result: exactly 60 contiguous unique IDs 121–180, five chapters of 12, 180 source/output proofs. Direct imports of the 26 chapter files then present checked code, explanation, summary and paired-summary uniqueness across **260 current lessons**. This is a snapshot; the root owns the final 300-lesson integration gate.

Raw local proof files (under ignored `.dart_tool/`, retained in this workspace):

| Artifact | SHA-256 |
| --- | --- |
| `.dart_tool/expansion-a/lessons.json` | `b3ed82fcbdbd49d6c439c233d49b38ba5a44aefba2dd568635bcd57338596958` |
| `.dart_tool/expansion-a/results.json` | `671d0233195ea188baef75d5c0d7ff368bd729e8eb89679559b5a43118118c69` |
| `.dart_tool/expansion-a/structure-result.json` | `5c6dc326b3432d18fa570bded3a17718a9a8a7a71c703e6a74d194f90b4d0b8f` |
| `.dart_tool/expansion-a/postfix-result.json` | `b79d3b9506670d2fdd73726226d35c0d97946e3551bcaca328a4cc479f96822f` |

## Indexed postfix defect reported to runtime owner

The original counting-sort lesson used indexed postfix increment. Its lesson, example and answer passed SDK execution but failed the product portable runtime. This minimal reproduction was separately executed:

```dart
void main() {
  final counts = List<int>.filled(3, 0);
  counts[1]++;
  print(counts);
}
```

SDK exit 0 produced `[0, 1, 0]`. Product portable execution returned empty stdout and `Portable program exited 1` / `Runtime Error: Cannot apply postfix '++' to index of type 'BridgedInstance<Object>'.`. Source/probe/result are `.dart_tool/expansion-a/postfix-{source,probe}.dart` and `postfix-result.json`. Root has the exact evidence and owns the vendor correction.

The shipped counting-sort code currently uses the equivalent `final bucket = value - low; counts[bucket] = counts[bucket] + 1;`; it keeps genuine counting-sort computation and identical output. The three affected final program slots were re-executed successfully. No vendor/runtime/dependency files were changed by this authoring batch.

## Boundaries

This batch changes only the five owned new chapter files and this report; authoring/audit helpers stay under `.dart_tool/expansion-a/`. Aggregator exports, counts, generated assets, tests, legacy chapters and runtime integration belong to the root. No commits were made. SDK and product portable evidence is host-only: it does not establish an OHOS package build or device execution. The root still needs the complete integrated SDK/portable/Flutter content gates.

## Accepted program manifest

The hash is SHA-256 of the exact lesson source (also used by its separately executed paired example). Every row also has one distinct full exercise program in the raw report.

| ID | Topic | Lesson source SHA-256 | Lesson / example / answer |
| --- | --- | --- | --- |
| dart-lesson-121 | 金额与票号格式化 | `d1b625e72d76f87fafda3a7ad571b9caa5ec215684fc7a293bb53bad215c9900` | pass / pass / pass |
| dart-lesson-122 | 批量安全解析数字 | `f1a8f434b7e4666fbe4a649f1b7768e89ea0e7873aed3859c797c9d6da03f9f6` | pass / pass / pass |
| dart-lesson-123 | 进制转换与字节标识 | `b9822ac872e2bd7afffb5aa48e63099dfbed1eff6c94892f3f5e82d9ff538b85` | pass / pass / pass |
| dart-lesson-124 | 分组余数与完成比例 | `95f37146f0babebbc43af0435578eb3f8ed81e151a6282c030007f71c532caeb` | pass / pass / pass |
| dart-lesson-125 | 分隔文本清洗管线 | `0af26eeafba7e6de8ae31cb9886cd4cd317e1bad06de01af8b2c4a91becfee25` | pass / pass / pass |
| dart-lesson-126 | 英文标题大小写规范 | `6826979d380325f659d88e00f18ecd7867e75ab7253f9cb1d221ff176035bb2a` | pass / pass / pass |
| dart-lesson-127 | 等宽清单的列对齐 | `4f088dcf931c933f26cdcc11785df1be22020d3f434b8d2f0fb8fd22cf422434` | pass / pass / pass |
| dart-lesson-128 | 带预算的文本省略 | `64d62c42cec12e0f55bd4210c6af661a6edee0ce0135217d6ae31b7d3e50a19c` | pass / pass / pass |
| dart-lesson-129 | 字符码与标识生成 | `d179fc3e0d79b8d17398e1b0e882b6a7e1c708c08bc383870489bd25f1082c34` | pass / pass / pass |
| dart-lesson-130 | 传感器区间映射 | `e547e667487b032414714afd0c86b76ce672d9c3d2c8a73bdfd2591dbd6eb8d5` | pass / pass / pass |
| dart-lesson-131 | 负数的舍入方向 | `976469d137f74e1bf8105e52997b6b5be01f9a0840b3a933d03d5802b23993c0` | pass / pass / pass |
| dart-lesson-132 | 浮点展示与分单位账本 | `ed5fafc46ca7bc585f2bd696c30ad5014bec05e5ffc7bc1610fb5c54ba1f78d8` | pass / pass / pass |
| dart-lesson-133 | 双指针回文检查 | `63f7799e48059957cc55d436c8366da5854f1fbc6355a425668d03344d9e3c5e` | pass / pass / pass |
| dart-lesson-134 | 排序签名判断变位词 | `fad46e9bec6d129469648bf6852db88a9604e0ed119859103d737c583103d91a` | pass / pass / pass |
| dart-lesson-135 | 带标点的词频统计 | `3bb7fd62378fd1d318820dcff8a2be5c9821e9917b6144818ced3fed49c83fca` | pass / pass / pass |
| dart-lesson-136 | 按码点统计字符频率 | `adb7a927dd25bbd32258c392c2f91302ddc799bdcf3c6404b3da4d100df75623` | pass / pass / pass |
| dart-lesson-137 | 连续片段的行程编码 | `e3c237aa8d877751cc0a8ba25449c884153757f0e0a39b015ea9b65a2229164d` | pass / pass / pass |
| dart-lesson-138 | 带校验的行程解码 | `2351b7f167b72bab69357a4c65456acebe12bc06c4cff052ac99185011a1e5d2` | pass / pass / pass |
| dart-lesson-139 | 保持标点的凯撒移位 | `b7974d03ae6615c2885a663dde1cd37efe3ff528ca87c65c8064bedc977b6a2f` | pass / pass / pass |
| dart-lesson-140 | 可逆替换表与冲突检查 | `4fcaf43ca0582ab91f0ee9370154ec054791ce745c02bef3ab146fecdd69423d` | pass / pass / pass |
| dart-lesson-141 | Luhn 校验与校验位 | `fd5a9a1da621c59ddecf7b8e21c688f0273cb1142c9d92e33330cab7fa92bcff` | pass / pass / pass |
| dart-lesson-142 | 忽略引号的括号配对 | `c7a72627c878765c9e57042dd3f4a726fa5859d1c6a810abb36fe961ec44eb51` | pass / pass / pass |
| dart-lesson-143 | 缩写与驼峰标识拆分 | `946eb65339637ef6d297cbecb035a796d3ca0cdc3fda796bea269113d93d5ddf` | pass / pass / pass |
| dart-lesson-144 | 逐段扫描模板占位符 | `bba3bdf1f1c4bdbc604b422fd31484ac9fb59220cd3c6dbe1293d0e0668ce33b` | pass / pass / pass |
| dart-lesson-145 | 线性查找的首末位置 | `ef42ecf955c5086392d1dc2666eea56bc97060916f0b7495d87aa6ea03158f71` | pass / pass / pass |
| dart-lesson-146 | 带提前退出的冒泡排序 | `cc9c43a410ffd5154fd3b5f8d85bf8ceaa9e835e25175508b7c53f7e5491cae6` | pass / pass / pass |
| dart-lesson-147 | 选择排序与最小位置 | `d8ca280150c03a9b9cf157067dcc00e271c2d70fa521a77fbc4d75166c7b11aa` | pass / pass / pass |
| dart-lesson-148 | 插入排序的有序前缀 | `bb857da16b727d6549d33d8b8202974fa6e8b5bb0044a212775a1c4535765186` | pass / pass / pass |
| dart-lesson-149 | 二分查找的闭区间 | `f9d9be172df5e36b468cc0b9a9ab354f934d95fce8888a65100c66b77a5da128` | pass / pass / pass |
| dart-lesson-150 | 支持负数的计数排序 | `689c2c076883037b3b000da43c09b849802ad28d1a92a9f2b87ad8257688f304` | pass / pass / pass |
| dart-lesson-151 | 归并两个有序序列 | `e6a8c2084296fbf95c05e7541d3aa20f351893835e1a9db760805bf50328920b` | pass / pass / pass |
| dart-lesson-152 | 保留首次顺序的去重 | `3fea9e3362d04184c25926cc737d69c2fcb42ece004b3b6cec0372a591db6ba4` | pass / pass / pass |
| dart-lesson-153 | 一次扫描求值域 | `4abf1a6271988aba9f1f63ed797e091b62a38a1a9cf7fbbcfde3913d91e5c55c` | pass / pass / pass |
| dart-lesson-154 | 有序两数之和 | `569ac90aed836b76cb11e6be3b758ec5fdd765737f006091cf1b4f689182ab5d` | pass / pass / pass |
| dart-lesson-155 | 最大连续子段与边界 | `7efce9aeccff8e77cdeae1d5554a0eb9131adb424833ea546552aa7f3c3a42b8` | pass / pass / pass |
| dart-lesson-156 | 三路分治快速排序 | `46c8e022b9636566433b0a81cd042636da084e0c440c38d3e8b273dd3bae5190` | pass / pass / pass |
| dart-lesson-157 | 阶乘的递归与迭代 | `0a388863ceb7f4033c941dc45bc31e784569fd3faa3066a9bcb812688d262dc0` | pass / pass / pass |
| dart-lesson-158 | 斐波那契的三种求值 | `0a7f1bc03525b08793db1ddb380e95d1ab60de49ac6a662d5a446fa8b3c1ebb3` | pass / pass / pass |
| dart-lesson-159 | 爬楼梯的状态与基例 | `a467cda6977ee995fc013be0f18deeec020fa5a2f1a9ab95bcc52f6eae8603eb` | pass / pass / pass |
| dart-lesson-160 | 零钱兑换的最少枚数 | `cd272dbe89668b68e77cd7690548e4026cf5305e39c8c37966f4e0068d1f703f` | pass / pass / pass |
| dart-lesson-161 | 零钱组合数与循环顺序 | `4b4a1616aac9d48313cd90500759ed15bab6600642d978e7c69bc36f5ffd69ab` | pass / pass / pass |
| dart-lesson-162 | 最长公共子序列长度 | `239d9a37f2a7e15a25d7dcb81976a408178f0fb88d8c5aa5fd8b941d0fa46440` | pass / pass / pass |
| dart-lesson-163 | 最长递增子序列 | `75d92ba4d633c28091be993fba07c12dcb02590feda6bb4d49f751b60d74fdaf` | pass / pass / pass |
| dart-lesson-164 | 零一背包的倒序更新 | `ceb659094cab4ba97689777e30900f8c18d4a7dd7f5d3b42b57645ebf800896c` | pass / pass / pass |
| dart-lesson-165 | 网格最小路径和 | `8be943bf86de2f34d2a1f4e36d85617c50f3119ee48eaf291638e1ea39b2d828` | pass / pass / pass |
| dart-lesson-166 | 编辑距离的三种操作 | `87d23050d6676dd290563afd18b4e4532e1845199981f452f05492be25dae724` | pass / pass / pass |
| dart-lesson-167 | 障碍网格的路径计数 | `0f7e1e9efeb47c87ee76dd1d0c0c0d2d552f9a359053101cd9337ae5ae4372b6` | pass / pass / pass |
| dart-lesson-168 | 有向无环图的记忆化 | `6bfd6cca9b6975adb6475cabdb2cca078ce9789aa554d1a9912f65cd2f448c52` | pass / pass / pass |
| dart-lesson-169 | 用列表封装后进先出栈 | `637f31ff281c16d236e3e9caa7e6cd7cf366eb470a7b65e2d543bf5affa947da` | pass / pass / pass |
| dart-lesson-170 | 先进先出的简单队列 | `f584705d0ea7024e4480f5ac899f83b56d3c596905684143f74d28932f9903a5` | pass / pass / pass |
| dart-lesson-171 | 固定容量的环形记录 | `98e8c2d7569975b849ece5a71a05181688b11234e11012177fc742c6c66e0724` | pass / pass / pass |
| dart-lesson-172 | 单链表节点与插入 | `b6bc22b3ea7358627a2dbd859df463f681e354dfbd1d228a7f621f830f5e8170` | pass / pass / pass |
| dart-lesson-173 | 原地反转单链表 | `aaf84f0600a09fdc7914c9b2558bbc76976352878adbb8ecacb20cb821ed5d74` | pass / pass / pass |
| dart-lesson-174 | 快慢指针检测链表环 | `830315f9c546341a6603f811705d03ab9967c54692e51e7fe5d630fcfba0b1a8` | pass / pass / pass |
| dart-lesson-175 | 二叉树的三种深度遍历 | `b064361e3483a3a647eaa357b94eeb115c082c5ff549b84dda89ff564c1a5303` | pass / pass / pass |
| dart-lesson-176 | 二叉搜索树插入与查找 | `040c173f72075e4eaa125c8ee92e4b255ef3fe57d7d42ef7c792886afd588805` | pass / pass / pass |
| dart-lesson-177 | 用队列按层遍历二叉树 | `9ce571d2655deb105192e19ad0fc48d618e9b16da3ba877a02c8e1783f0bb371` | pass / pass / pass |
| dart-lesson-178 | 有序列表实现最小优先队列 | `b637c8ce5f084c780e63b3f38897e64700f53cb14bd3b824c6221cb19c48b565` | pass / pass / pass |
| dart-lesson-179 | 并查集与路径压缩 | `416a88aba04be5d0546a4ee5061af2647a371e031b82e370bb959d996315c972` | pass / pass / pass |
| dart-lesson-180 | 邻接表上的深度与广度搜索 | `45b7424ce086aec83efbe4a31781c05aa1e2e3dab73dc32e0f91459b55bc880f` | pass / pass / pass |
