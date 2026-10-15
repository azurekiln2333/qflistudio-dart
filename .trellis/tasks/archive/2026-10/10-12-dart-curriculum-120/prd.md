# Dart 课程 120 课：真实可运行从入门到精通

## Goal

Replace the machine-generated Dart filler with **120 independent Dart knowledge
points** (120 lessons + 120 paired examples) that are substantive, Chinese-taught,
complete, runnable, and machine-verified. Every lesson ships real prose, complete
code, exact expected output, exercises, and common-mistake notes. Content is
delivered through the existing catalog/detail/import/run pipeline with **only two
additive core edits** (a repository-factory injection seam). No template
copy-paste counts as a lesson.

User value: the Dart app's Tutorials and Examples tabs show a genuine Dart
curriculum from first program to Dart 3 / async / streams / isolates / IO / JSON /
testing / capstone, and each lesson runs on the real engine the editor uses.

## Background

- Dart app is offline; its Tutorials/Examples tabs render the core's
  `assets/content/{tutorials,examples}.json` filtered to `type:"dart"`
  (`core/lib/pages/home_page.dart:217-233`, `core/lib/content/local_content_adapter.dart`).
- Current Dart content is 100+100 generated stubs: all 100 tutorial lessons share
  **one** `explain`; code is one weighted-sum template varied only by three int
  literals; topics are generic software-engineering labels, not Dart; levels are
  wrong; no `objective`/`pitfalls`; example `inputFixtures` are fabricated. See
  `research/audit-current-dart-content-and-wiring.md` §2.
- The rewritten Java set (100 real lessons + `test/java_content_test.dart`) is the
  quality precedent. See research §2.3, §7.
- Real Dart engine: `DartProgramRunner` → `NativeDartToolchain` (official SDK VM:
  full Dart 3/async/isolate/IO) on native; else `dart_eval` 0.8.5 (subset). Core
  `DemoRunService` is Java-oriented and is **not** the Dart path. See research §4.
- Content has no injection seam today; the app hardcodes the tabs (research §5).

## Requirements

### R1 — 120 lessons + 120 examples, 120 distinct knowledge points per type

- Exactly **120** Dart tutorial entries and exactly **120** Dart example entries.
- Each type must contain **120 distinct knowledge points** (120 distinct lessons;
  120 distinct examples). A lesson and its own paired example MAY share the same
  code — the 120-uniqueness bar applies **within** each type, not across the two,
  so we do not force 240 separate programs.
- Lessons are organized into chapters with concrete per-chapter counts (§ R1.1).
- Each lesson: `title`, `summary`, `concepts`, `explain` (real Chinese prose,
  unique), `code` (complete, multi-line), `output` (exact stdout), `objective`,
  `prerequisites`, `pitfalls`, and `exercises` (≥1 prompt/hint/answer).
- `explain` must be unique per lesson; normalized `code` bodies must be unique
  across the 120 lessons and (separately) across the 120 examples.
- Level labels (`beginner`/`intermediate`/`advanced`) must match real difficulty.
- Every field authored must be **renderable by the existing detail pages**. The
  page renders `objective`, `prerequisites`, `explain`, `code`, `output`,
  `pitfalls`, `tasks`
  (`core/lib/pages/local_content_pages.dart:454-516`). No JSON field may exist
  that the user cannot see.

### R1.1 — Chapter allocation (120 lessons)
| Chapter | Count |
| --- | --- |
| 入门与基础（main/print/注释/变量/类型/运算符/字符串/插值） | 10 |
| 流程控制与函数（if/switch/循环/函数/参数/闭包基础） | 8 |
| 集合与迭代（List/Set/Map/spread/高阶方法/排序/迭代器） | 10 |
| 空安全（nullable/`?`/`!`/`??`/`?.`/late/空安全设计） | 6 |
| 面向对象（类/构造/字段/方法/getter/setter/静态/继承/抽象/接口/mixin） | 12 |
| 泛型与类型系统（泛型类/方法/约束/typedef/类型别名） | 8 |
| 异常与错误处理（try/catch/finally/自定义异常/Result 模式） | 6 |
| Dart 3（patterns/records/sealed/exhaustive switch/enhanced enums/class modifiers） | 12 |
| 异步编程（Future/async-await/错误传播/并发原语） | 10 |
| 流（Stream/StreamController/变换/监听/背压） | 8 |
| 隔离与并发（Isolate/消息传递/compute） | 6 |
| IO 与文件（dart:io/文件/目录/进程/stdin） | 8 |
| JSON 与序列化（jsonEncode/Decode/fromJson/toJson/嵌套建模） | 6 |
| 测试与工程（单元测试/夹具/包与工具/性能/分层与综合项目） | 10 |
| **Total** | **120** |

### R2 — Machine-verifiable correctness (host SDK required)

- When the host Dart SDK is available, **every** lesson and example code must be
  compiled and **actually executed**, and stdout must equal the declared
  `output`/`expectedOutput`. Host execution is mandatory; it may not be replaced
  by skips to declare completion.
- **All 120 counted programs must be self-contained and non-interactive: no real
  stdin dependency and no network.** IO lessons use program-created temporary
  files with fixed content and `finally` cleanup.
- `inputFixtures` is **dead data** today: the parser reads it
  (`content_repository.dart:498-516`) but nothing writes an `input.txt` from it,
  so importing a lesson never creates stdin. Therefore:
  - Do **not** create `inputFixtures` to fake automatic stdin import.
  - Reading from stdin may be *explained* as a topic with an injectable input
    source; such a lesson must state the real step of preparing a project-root
    `input.txt` (the runner feeds it to stdin), and its verification must supply
    the input through the real mechanism, not a fabricated fixture field.
  - Do not expand core changes to wire `inputFixtures` into project import.
- Code bodies are genuinely multi-line with a real `main` structure.
- Normalized code bodies unique within each type.
- Tests load the **real bundled assets** and run code through the **real Dart
  runner** (`DartProgramRunner`/`NativeDartToolchain`), not mocks and not the Java
  `DemoRunService`.
- If (and only if) the host SDK is genuinely absent, record the run gate as an
  explicit environment skip and report it — never count it as passed.

### R3 — Runtime compatibility labeling without deleting advanced Dart

- Lessons using Dart 3 / async / streams / isolates / dart:io require the official
  SDK engine. These must NOT be deleted or downgraded for `dart_eval`.
- Compatibility is surfaced to the user through **rendered fields** — the detail
  page renders `objective`, `prerequisites`, `explain`, `code`, `output`,
  `pitfalls`, `tasks` (`core/lib/pages/local_content_pages.dart:454-516`). There is
  **no `engine` field in the parser**; an `engine` JSON key would be silently
  dropped and invisible. Therefore the official-SDK requirement must be stated
  **in `explain`** (and may be echoed in `prerequisites`/`pitfalls`), never as a
  raw `engine` field.
- Must not regress live `StudioProfile.runtimeKind`/`runtimeStatus`
  (`qfli_dart/lib/main.dart:33-46`) or the adapter runtime projection
  (`local_content_adapter.dart:79-87`).

### R4 — Reuse existing navigation, model, import, and run pipeline

- Reuse existing models, MD3 catalog/detail pages, `CodeSnippet`,
  `CodeImportService`, and the editor run path. **No new detail-page Run button.**
- **CodeSnippet's inline Run is Java-only**: it is gated by
  `CodeImportService.isJavaType(example.type)` (`core/lib/widgets/code_snippet.dart:107`),
  and `DemoRunService` is Java-specific. Dart examples therefore have **no**
  inline Run. The Dart acceptance path is explicitly:
  **catalog → detail → Import to editor / Import to project → Editor Run**
  (`editor_page` `_runProject`/`_runActiveFile` → `DartProgramRunner`).
- Imported lesson/example code must run on the declared engine via that path.

### R5 — Delivery: one additive 2-file core seam (approved direction)

- The 120 lessons and 120 examples are stored **in this repository**
  (`qfli_dart`), so no shared content JSON is edited and no other language is
  touched.
- The only shared-core change is an **additive repository factory injection** in
  exactly two files: `qfli_studio_core/lib/services/studio_profile.dart` and
  `qfli_studio_core/lib/pages/home_page.dart` (design §7).
- Both edits are null-safe: when unset, every other product's behavior is
  unchanged.
- **External-write authorization for these two files is pending final approval.**
  No product code is modified until that approval is granted.
- The legacy `core/assets/tutorials/dart.json` (`runtime.status:"planned"`) is
  **outside the authorized two files and must not be modified.** It is simply not
  on the active render path (the adapter reads the aggregate assets), so its stale
  copy does not surface to users. This is stated, not fixed, in this task.

### R6 — Licensing

- Follow the repository's **existing** license text for Dart content. Do not
  invent or add a new license (e.g. do not introduce "CC BY 4.0" unless the repo
  already uses it for Dart content). Match the current value used by existing
  Dart entries.

## Out of Scope

- Editing other languages' content or the shared aggregate JSON.
- Editing the legacy `core/assets/tutorials/dart.json`.
- Changing editor run gestures / terminal presentation (owned by
  `10-09-dart-terminal-run`).
- New UI or new content-model fields.
- Target-device (HarmonyOS/Android hardware) execution evidence.

## Acceptance Criteria

- [x] AC1: Exactly 120 Dart tutorial entries and 120 Dart example entries in the
  repository-owned catalog, with unique ids and titles.
- [x] AC2: 120 distinct knowledge points per type; a lesson and its own paired
  example MAY share code, but no two lessons share a knowledge point, and no two
  examples share a knowledge point.
- [x] AC3: All 120 lessons have non-empty title/summary/explain/code/output/
  objective, non-empty pitfalls, non-empty concepts, ≥1 exercise.
- [x] AC4: All 120 `explain` values are distinct; normalized lesson code bodies are
  distinct; normalized example code bodies are distinct.
- [x] AC5: On a host with the Dart SDK, **all 120 lessons and all 120 examples**
  compile, execute, and match their declared output; no skip is counted as pass.
- [x] AC6: Exactly 120 examples pair 1:1 to the 120 lessons via `sourceLessonId`;
  exactly one introductory Hello-World topic exists.
- [x] AC7: Level labels span beginner/intermediate/advanced and match difficulty.
- [x] AC8: Dart 3 / async / streams / isolates / IO lessons are labeled as
  requiring the official SDK engine via rendered fields; none are deleted.
- [x] AC9: No placeholder/TODO/ellipsis markers; all 120 counted programs are
  self-contained (no real stdin, no network); IO lessons use program-created
  temporary files with `finally` cleanup; stdin is explained with the real
  `input.txt` preparation step, with no `inputFixtures` used to fake it.
- [x] AC10: Every authored field is displayed by the existing detail pages (no
  invisible field, no `engine` key); compatibility is visible in `explain`.
- [x] AC11: A `dart_content_test.dart`-style suite loads the real assets and runs
  the real `DartProgramRunner`; `flutter analyze --no-pub` and
  `flutter test --no-pub` pass in `qfli_dart`.
- [x] AC12: A widget/integration test proves **catalog → detail → import to
  editor/project → editor Run** through the existing pages, with no new detail
  Run button.
- [x] AC13: The delivered diff changes **only** the two authorized core files
  (after approval) plus `qfli_dart` files; the legacy
  `core/assets/tutorials/dart.json` and all other-language content are
  byte-identical; pre-existing dirty files are preserved.
- [x] AC14: Dart content uses the repository's existing license string, with no
  newly introduced license.

## Key Decisions

- **K1 — Delivery channel: K1a.** Store 120 lessons + 120 examples in `qfli_dart`;
  add one optional repository factory to `StudioProfile` and pass it at the two
  `HomePage` tab call sites. Null default preserves all current behavior.
- **K2 — Verification:** host Dart SDK full compile+execute+output-diff for all
  240 artifacts is mandatory; device SDK runs are a separate, reported gate.
- **K3 — Authoring format:** authored Dart source in `qfli_dart` (typed, unique-
  enforced) plus a deterministic Dart-side asset/repository; uniqueness and
  output parity are machine-enforced.

## Status

Completed and reverified on 2026-10-15. The local catalog, shared repository
factory seam, generation and all execution gates are implemented. The current
release request explicitly authorizes shared-core coordination. See the release
task research/content-audit.md for 120/120 integrity and 240-program execution
evidence; target-device execution is tracked separately by the release task.

## Release reconciliation — 2026-10-15

Verified against the current source and real assets in
`10-15-dart-store-release/research/content-audit.md`. Shared-core
`content_code_import_test.dart`, `home_content_repository_test.dart`,
`editor_run_test.dart` and `terminal_manager_delegate_test.dart` passed together
(55 tests). The import suite includes real file writes, exact editor navigation,
conflict/cancellation/error handling and 320px/1280px layouts at 2x text.
Existing core content edits owned by other language sessions were preserved.
All work was committed directly on main, without a PR branch; archive uses the
documented --skip-branch-validation option.
