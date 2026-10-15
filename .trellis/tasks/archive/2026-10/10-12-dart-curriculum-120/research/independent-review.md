# 独立审查：Dart 120 课（trellis-check 视角）

审查者：content-pi（独立审查线程）。审查对象：`qfli_dart` 课程源、生成器、
repository/main seam、测试，以及真实 assets 接入链路（含 core seam，只读）。
本文件为**最终树 120 课**快照（取代此前的 114 快照）。结论均附实测命令与数字。

## 0. 实测基线（最终树，命令与结果）

| 命令 | 结果 |
| --- | --- |
| authored 课程数（14 章合计） | **120**（exceptions 已补 6 课，055–060） |
| assets：`dart_tutorials.json` / `dart_examples.json` | entries **各 120**（304KB / 130KB） |
| `dart run tool/verify_dart_content.dart`（全量） | **checked=120 failures=0** |
| 逐章 verifier | dart3=12 async=10 streams=8 isolates=6 io=8 json=6 engineering=10 exceptions=6 ……均 failures=0 |
| `flutter analyze --no-pub` | **No issues found!**（0） |
| `flutter test --no-pub` | **+60: All tests passed!**（P1-1 已修复） |
| `flutter test --no-pub test/dart_content_widget_test.dart` | **+3: All tests passed!** |

后 60 课（本人负责）与 exceptions 章节均真实编译+执行+逐字节比对通过。

## 1. 已修复（原 P1）

- **[已修复] 原 P1-1 `dart_content_widget_test.dart` 两用例失败**：已由 content-pi
  独占修复。实测 `flutter test --no-pub test/dart_content_widget_test.dart` =
  **+3: All tests passed!**；全量 `flutter test --no-pub` = **+60: All tests passed!**。
  根因（经诊断确认，非弱化断言）：
  1. 点击目标错：`find.text('第一个 Dart 程序')` 在目录中匹配 2 处（重复渲染），
     对 `Text` 的 tap 未命中可点击的 `ListTile`，故 `Navigator.push` 未触发。改为
     `tester.tap(find.byType(ListTile).first)` 后详情页正常渲染。
  2. 断言时机错：详情页是惰性 `ListView`，`易错点`(pitfalls) 在视口外未被构建；
     需在断言前滚动到可见（有界 `drag` 循环直到 `find.text('易错点')` 非空）。
  3. 保留 integration 的 `_preloaded`（`runAsync` 预加载真实 assets + 同步完成包装）
     与 `_settle`（有界 pump）思路；仍使用**真实 assets**（`DartContentRepository`），
     未使用合成内容，未弱化断言。

## 2. P2（一致性/证据，可执行修复）

- **P2-1 前 60 课官方 SDK 可见说明**：课程详情页
  （`qfli_studio_core/lib/pages/local_content_pages.dart:450-505`）只渲染
  summary/objective/prerequisites/explain/code/output/pitfalls/tasks，**不渲染
  `runtime`**。故引擎要求只能写进 `explain`/`prerequisites` 才可见。实测关键词命中：
  `exceptions 0 / control 0 / collections 0 / nullsafety 0 / oop 0 / generics 0 /
  basics 2`。但 `control.dart:104` 使用 switch 表达式（Dart 3）、
  `exceptions.dart:205` 使用 `sealed class` + 对象模式（Dart 3）——这两处
  `dart_eval` 不支持，却未在 `explain`/`prerequisites` 标注需官方 SDK。
  后 60 课已写（SDK 关键词命中约 95 处），前 60 课需对使用 Dart 3 语法的课程补注。
  owner：主 pi。
- **P2-2 run 测试只覆盖宿主 SDK 分支**：`test/dart_content_run_test.dart` 经
  `DartProgramRunner`→宿主 `NativeDartToolchain` 真实进程执行（非 mock，良好），
  但未覆盖 `dart_eval` 分支，也非 Android 官方 SDK VM。R2“在声明引擎上执行”对
  `dart-eval` 标注课缺少证据。建议补一条 dart_eval 执行门或显式记为设备/skip。
  owner：integration。
- **P2-3 core 侧 widget 测试不覆盖 Dart seam**：`qfli_studio_core/test/
  content_code_import_test.dart:1154-1161` 构建 `LocalTutorialsTab/ExampleCodeTab`
  **未传 `repository:`**，用的是合成 `'lesson'/'example'` 内容，验证的是 Tab 机制而非
  Dart 120 目录注入。真正的 Dart seam widget 证据只有 P1-1 那份测试，需其转绿。

## 3. 通过项（已核实，最终树）

- **120/120 真实运行**：`verify_dart_content.dart` 全量 checked=120 failures=0。
- **标题↔知识点一致**：抽查各章 title 与 concepts/code 对应（如 dart3 记录/sealed、
  async Future、isolates Isolate.run、io 临时文件、json 编解码、engineering 参数解析），
  无同标题不同内容。
- **讲解/练习具体、答案可运行**：生成器强制 explain 唯一；每课 exercises≥1 含
  prompt/hint/answer；抽查 answer 自包含可执行。
- **章节递进**：basics→control→collections→nullsafety→oop→generics→exceptions→
  dart3→async→streams→isolates→io→json→engineering，由基础到工程，生成器按 id 稳定排序。
- **真实 assets 已接入首页链路**：核心 seam 已落地——`qfli_studio_core/lib/pages/
  home_page.dart:222,233` 将 `StudioProfile.current?.contentRepositoryFactory?.call()`
  传入两个 Tab；`qfli_dart/lib/main.dart` 以
  `contentRepositoryFactory: DartContentRepository.new` 注入；
  `lib/dart_content_repository.dart` 读 `packages/qfli_dart/assets/content/
  dart_{tutorials,examples}.json` 并经 `ContentCatalog.fromJson` 复用 core 解析。
  assets 实测各 120 entries。
- **测试测的是真实 assets 而非仅源**：`test/dart_content_test.dart` 经
  `DartContentRepository().load()` 读真实打包 assets 再经 adapter 投影断言；
  `dart_content_import_test.dart` 经 `CodeImportService.importIntoProject` 写真实
  项目文件并 `DartProgramRunner` 真跑。
- **导入/runner 链路**：detail 无内联 Run（`CodeSnippet` 内联 Run 仅 Java），
  正确路径 catalog→detail→import→编辑器 Run，由 import 测试覆盖。
- **静态分析**：`flutter analyze --no-pub` 0 issues（含本人后 60 课）。

## 4. 未过门槛（明确列出）

1. `flutter test --no-pub` 未全绿：`+58 −2`，2 个失败在
   `dart_content_widget_test.dart`（P1-1）。
2. widget 级“首页目录真实接入”证据存在但红（P1-1）。
3. 前 60 课 Dart 3 语法处引擎需求未在页面可见（P2-1）。
4. dart_eval 分支与 Android 官方 SDK VM 执行证据缺失（P2-2，记为已知门）。

## 5. 给 owner 的处置建议（不改变产品范围）

- 主 pi：修 `dart_content_widget_test.dart` 的 `pumpAndSettle` 超时（P1-1，用
  `runAsync`+显式 pump 注入 store/bundle）；对前 60 课 Dart 3 语法处补 `explain`
  SDK 说明（P2-1）。修复后复跑 `flutter test --no-pub` 应全绿。
- integration：补 dart_eval/设备执行门或显式 skip 记录（P2-2）。
- 本审查只读，未修改任何产品文件；仅更新本报告。

## 6. 最终树交叉复核（w7:p2 请求，只读，收束）

结论：**通过**，无阻断项。

- 一致性：authored 120、assets 120/120、generator 重跑字节一致（确定性）、
  `flutter analyze --no-pub` 0、`flutter test --no-pub` **+61 All tests passed**。
- 无权属重叠：前60课（first pi，001-060）与本人 7 章（second pi，061-120）头注释与
  区间严格对应；core seam 仅 `studio_profile.dart`+`home_page.dart`（4 行），无重复写入。
- dart_eval 子集 43/120：独立复跑 `dart_eval: ran=43 of 120; 77 SDK-required`，为真实
  执行白名单（非正则猜测），未过度声称。
- 引擎标注：`tool/audit_compat.dart` unlabeled=0；前60课仅 control.dart:105（switch 表达式）
  与 exceptions.dart:206（sealed+模式）用 Dart 3，两处 explain 均已标官方 SDK。
- P1 清零；P2 清零（渲染/证据类均已达成）。

实测限制（非阻断）：dart_eval 分支仅验证宿主 dart_eval 0.8.5，未在 Android/OHOS 官方
SDK VM 跑设备门（记为已知门）。

遗留 P2（本人在 dart3.dart 的内容准确性，**不阻断**，本次未改）：lesson-061 的
`explain`/`pitfalls` 写“dart_eval 不支持记录语法，编译会报错”，但实测 dart_eval 0.8.5
能正确运行 061 的记录代码（输出 3/7/3/10/2 与声明一致）。该句为旧断言，建议主 pi
后续顺手修正；不影响验收。
