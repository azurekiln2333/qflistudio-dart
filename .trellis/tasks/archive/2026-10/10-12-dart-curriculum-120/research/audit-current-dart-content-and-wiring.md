# Audit: Current Dart Content, Runtime, and Delivery Wiring

Date: 2026-10-12
Scope: read-only inspection of `D:/MyNewProjects/qfli_dart` (writable) and
`D:/MyNewProjects/qfli_studio_core` (read-only, sibling, shared).

This file records the evidence that drives `prd.md` / `design.md` /
`implement.md`. Every claim below has a file:line-level anchor.

---

## 1. What the Dart app actually renders

The Dart app is offline (`isOffline: true`) and shows four tabs
(`qfli_studio_core/lib/pages/home_page.dart:127-149`, `_buildPage` at
`:202-240`):

- index 2 → `LocalTutorialsTab(language: profile!.id, ...)`
- index 3 → `ExampleCodeTab(language: profile!.id, ..., examples: _examples)`

`profile.id` for Dart is `'dart'` (`qfli_dart/lib/main.dart:26`).

Both tabs default to `AssetContentRepository()` and are **not** given a
repository argument (`home_page.dart:217-233`). `AssetContentRepository`
reads two package assets (`content/asset_content_repository.dart:10-11`):

- `assets/content/tutorials.json`
- `assets/content/examples.json`

`LocalTutorialsTab` → `LocalContentAdapter.loadTutorial`
(`content/local_content_adapter.dart:15-56`) filters by product/language and
maps each matching tutorial entry to a `TutorialChapter` whose `lessons` come
from the entry's `lessons` array. `ExampleCodeTab` →
`LocalContentAdapter.loadExamples` (`:58-77`) maps matching examples 1:1.

**Conclusion:** the real, user-visible Dart curriculum is the 100 `type:"dart"`
entries in `assets/content/tutorials.json` and the 100 `type:"dart"` entries in
`assets/content/examples.json`. The hand-written
`assets/tutorials/dart.json` (222 lines, 12 lessons) is **dead content**: it is
only reachable through the legacy `TutorialService` path
(`services/tutorial_service.dart`), which nothing in the app calls (grep shows
`TutorialService` referenced only by `models/tutorial.dart` and itself).
`AssetContentRepository`/`ContentCatalog.fromJson` accept the legacy
`{chapters:[...]}` document shape (`content_repository.dart` `_entries`,
`_tutorialLessons`), but the bundled `dart.json` is not loaded by either tab.

## 2. Quantity and quality of the current Dart content

### 2.1 Tutorials (`assets/content/tutorials.json`, `type:"dart"`)

- 100 entries: 25 `beginner`, 45 `intermediate`, 30 `advanced`.
- Each entry has exactly **1** lesson.
- **Distinct `explain` across all 100 Dart lessons: 1.** Every lesson shares one
  generic paragraph ("把问题分成输入、状态变化和输出三层…").
- Each lesson's `code` is the same `weighted = values[0] + values[1]*2 +
  values[2]*3` program with only the three integer literals changed (e.g.
  `[1,3,5]→weighted=22`, `[61,63,65]→weighted=382`, `[100,102,104]→weighted=616`).
  Raw `code` strings are distinct only because of those literals.
- `concepts` is a rotating pool of ~24 **generic software-engineering topic
  labels**, not Dart language topics: "日志与可观测性", "缓存与失效策略",
  "队列与批处理", "分页与排序", "API 契约与版本兼容", "资源打包与发布", …
- Level labels are semantically wrong: "beginner" entries are assigned advanced
  topics.
- Only 2 `exercises` per lesson, all templated ("先定义契约…").
- `objective` / `prerequisites` / `pitfalls` are absent (validator/test treat
  `objective` and `pitfalls` as expected-present for the rewritten Java set).

### 2.2 Examples (`assets/content/examples.json`, `type:"dart"`)

- 100 entries, 1:1 paired to the tutorials via `sourceLessonId`.
- Every `code` body is the same single-line weighted-sum template; measured body
  length is ~149–155 characters. Distinct only by literals.
- `expectedOutput` = `weighted=<n>` with the same mechanical variation.
- `inputFixtures` is a fabricated `{"case":"fixture-N","mode":"deterministic"}`
  — no real stdin fixture.

### 2.3 Comparison baseline: the already-rewritten Java set

`assets/content/*.json` `type:"java"` entries have **100 distinct `explain`
values and 100 distinct `code` bodies**, real multi-line Java (avg first-lesson
code length ≈ 587 chars vs Dart ≈ 151), real `objective`/`pitfalls`, and a
dedicated integrity test suite:
`qfli_studio_core/test/java_content_test.dart` (loads the real bundled assets;
asserts 100/100, unique ids/titles, 1:1 pairing, complete content, no
placeholder/ellipsis markers, genuinely multi-line method-body structure,
"exactly one Hello World", a near-duplicate guard over normalized code bodies,
and level coverage). `test/java_content_render_test.dart` and
`test/java_inline_run_test.dart` cover rendering and inline execution.

There is **no** `dart_content_test.dart`. The Dart set has only the generic
asset-level tests (`test/content_repository_test.dart`, `test/tutorial_test.dart`).

## 3. Runtime metadata is stale

`assets/tutorials/dart.json` declares
`runtime.kind:"interpreter"`, `runtime.status:"planned"`, engine
"应用内 Dart 子集解释器（纯 Dart，开发中）". The real Dart app has moved on:

- `qfli_dart/lib/main.dart:33-46`: `runtimeKind` is `'official-dart-sdk'` when
  `NativeDartToolchain.supported` (Android/Windows/Linux/macOS) else
  `'dart-eval'`; `runtimeStatus` is `'available'` on Android, else
  `'requires-sdk'` when native is supported, else `'unavailable'`.
- `LocalContentAdapter._runtime()` (`local_content_adapter.dart:79-87`) already
  reads `StudioProfile.current.runtimeKind/runtimeStatus` — so the adapter-driven
  pages show correct runtime info. It is only the legacy `dart.json` that is
  stale, and it is not rendered.

**Conclusion:** the stale `planned` string is a legacy-file artifact, not a live
UI problem. Any content work must not regress the live `runtimeKind/Status`
wiring, and the legacy `dart.json` should be reconciled or retired explicitly.

## 4. The real Dart execution engine (correcting a common mis-inference)

The auditor's caution is right: do **not** treat the core Java-oriented
`DemoRunService` as the Dart run entry.

- `DemoRunService` (`qfli_studio_core/lib/services/demo_run_service.dart`) is
  Java-specific: it infers a Java entry class via `JavaSourceRenamer`, writes
  `<EntryClass>.java`, and calls `RunnerService.runProject`. It is the engine
  behind the inline "Run example" button in `CodeSnippet`
  (`widgets/code_snippet.dart:63-73`, `DemoRunService.start`). For Dart it would
  write a `.java` file and fail — it is not a Dart path.
- The real Dart run surface is the **language runner** injected through
  `StudioProfile.runner` (`qfli_dart/lib/main.dart:29`,
  `dartProfile.runner = DartProgramRunner()`), which
  `RunnerService.runProject` invokes first
  (`qfli_studio_core/lib/services/runner_service.dart`, `custom` branch).
- `DartProgramRunner.run` (`qfli_dart/lib/dart_runner.dart:18-56`) dispatches:
  - native platforms → `NativeDartToolchain.run` (official Dart SDK VM, full
    language incl. Dart 3, async, streams, isolates, dart:io);
  - otherwise → `dart_eval` 0.8.5 in-app interpreter (reduced subset).
- Editor Run tap → project entry via `RunnerService.findEntry` (honors
  `entryFileNames`, `qfli_dart/lib/main.dart:49-59`); long-press → active file
  (`editor_page.dart` `_runProject`/`_runActiveFile`). Dart Tools page has its
  own Compile/Run/Run-compiled buttons (`lib/dart_tools_page.dart`).

**Conclusion:** compatibility labeling for each lesson must be keyed to the real
engines (`official-dart-sdk` vs `dart-eval`), and advanced lessons that use full
Dart 3 / async / isolate / IO must be marked as requiring the native SDK, not
deleted to satisfy `dart_eval`.

## 5. Content delivery is core-owned — no Dart-app injection seam exists

Verified there is **no** override hook for content in the writable repo:

- `StudioProfile` (`core/lib/services/studio_profile.dart`) has `runner`,
  `webPreviewFactory`, `toolsPageBuilder`, `documentToolBuilder`,
  `editorFileTools`, `entryFileNames`, `supportedFileExtensions` — but **no**
  content-repository or tab-builder hook.
- `HomePage` (`core/lib/pages/home_page.dart`) constructs `LocalTutorialsTab` /
  `ExampleCodeTab` directly without a repository argument.
- `AssetContentRepository` (`core/lib/content/asset_content_repository.dart:8`)
  accepts only an `AssetBundle`; it is not a profile field.
- `qfli_dart` bundles no `assets/content/*.json`; its pubspec assets are just
  `assets/app_icon.png` (`qfli_dart/pubspec.yaml:flutter.assets`).
- Flutter asset resolution: a dependent package can only see its own assets plus
  the core package's, keyed by `packages/qfli_studio_core/...`. The adapter tries
  `packages/qfli_studio_core/<asset>` first, then `<asset>`.

**Conclusion:** to change what the Dart app shows for tutorials/examples, either
(a) edit the shared core asset `assets/content/tutorials.json` /
`assets/content/examples.json` (owned by other language pis; high conflict), or
(b) obtain a coordinated core change that adds an injection seam so `qfli_dart`
can supply its own Dart-only catalog. Option (a) risks merge conflicts with the
concurrent Java/core editors and is outside this task's write scope.

## 6. Write-scope and conflict constraints (from user + task)

- Writable this phase: `D:/MyNewProjects/qfli_dart` only.
- Reading core is allowed; **writing core requires explicit external-write
  authorization from the main coordinator.**
- Multiple language pis are editing shared core content concurrently; the Dart
  task must be isolated so it neither edits other types' entries nor races the
  same files. A core change, if required, must be additive and Dart-scoped.
- Existing dirty files in `qfli_dart`/`ohos` etc. must be preserved; no commits
  or pushes this phase.

## 7. Machine-verifiable quality gate model to reuse
`java_content_test.dart` is the template for a `dart_content_test.dart` that
loads the **real bundled assets** and asserts, per lesson/example:

- exact counts, unique ids and titles;
- 1:1 tutorial↔example pairing by `sourceLessonId`;
- non-empty title/summary/explain/code/output, non-empty `objective`/`pitfalls`;
- no placeholder/ellipsis markers;
- genuinely multi-line code with a `main` structure;
- a near-duplicate guard (normalized code bodies must be unique);
- exactly one introductory Hello-World style topic;
- level coverage (beginner/intermediate/advanced).

Additional Dart-specific gates required by this task (see `prd.md`):
per-lesson **compile**, per-lesson **execute with expected stdout**, and
uniqueness of code bodies after normalization. These must run against the real
engine, not the Java-oriented `DemoRunService`.

## 7b. Delivery convention context (evidence only)
A concurrent worker has an authored-source + generator + verifier pattern under
`qfli_studio_core/tool/` for its own language. It is recorded here only as
background evidence of the team's authoring style. The approved direction for
Dart is **K1a** (repository-factory seam, content stored in `qfli_dart`), so this
pattern is informational and does not imply editing shared aggregate content.

## 8. Verified execution constraints (independent review 2)

- **CodeSnippet inline Run is Java-only.** The Run button is gated by
  `CodeImportService.isJavaType(widget.example.type)`
  (`core/lib/widgets/code_snippet.dart:107`), and its engine `DemoRunService`
  writes `.java` via `JavaSourceRenamer`. Dart examples show no inline Run, so the
  Dart acceptance path must be catalog → detail → import → editor Run.
- **`inputFixtures` is dead data.** It is parsed
  (`content_repository.dart:498-516`, field at `:213`) but no code writes an
  `input.txt` from it during import, so it never feeds stdin. Creating it would be
  a fabricated field; do not use it, and do not grow core to wire it.
- **No `engine` parser field.** `_parseLesson`/`_parseExample` read only the known
  keys; an `engine` key is dropped. Compatibility must be stated in `explain` to
  be user-visible.

## 9. Open technical questions resolved by inspection

| Question | Finding |
| --- | --- |
| Does `qfli_dart` have its own tutorial asset? | No; only `assets/app_icon.png`. |
| Can the app override the repository at runtime? | No public seam; `HomePage` hardcodes the tabs. |
| Is `dart.json` rendered anywhere? | No; `TutorialService` is unreferenced in app code. |
| Can `dart_eval` run Dart 3 / isolates? | `dart_eval` 0.8.5 is a reduced subset; isolates/streams/IO limited. |
| Which engine runs on device? | Android → official SDK VM; other native → SDK if found; else `dart_eval`. |
| Where would a Dart-only catalog live if core allows a seam? | Proposed: `qfli_dart/assets/content/dart_{tutorials,examples}.json`, injected via a new `StudioProfile` content hook. |
