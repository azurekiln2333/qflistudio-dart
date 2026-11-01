# Dart tools & diagnostics audit (research only)

Owner: Dart tools/diagnostics (this report). Scope: `lib/dart_tools.dart`,
`lib/dart_tools_page.dart`, `lib/dart_runner.dart`, plus the core
`StudioProfile` / editor-diagnostics seams. **No product code was changed by
this audit.** Findings marked *already implemented* were done by the Dart owner
independently and are not re-proposed here.

---

## 1. What the product must deliver (from task R5 / R6)

| Req | User-facing intent | Where it lands |
| --- | --- | --- |
| R5 | Language-specific functions laid out **directly** on the Tools tab — no second-level "mystery feature cards" | `StudioProfile.toolsTabBuilder` → `DartToolsPage.forTab` |
| R6 | Editor squiggles on **unsaved** buffers + message list / Problems panel | core `CodeAnalyzer` contract + Dart provider |
| R5/R8 | Offline: format, syntax check, run, compile, project stats, import check | `DartTools` / `DartProgramRunner` |

Constraints that bound every option below: the app is offline (no `pub get`
network), OHOS has **no official Dart SDK** (only `dart_eval` 0.8.5), Android
ships a real SDK (`lib/android_dart_sdk.dart`), and shared-core UI/explorer is
owned by the C coordinator (`qfli-core-release-sync.md`).

---

## 2. Audit of the current tools surface

### 2.1 What already exists and is sound

- `DartTools.format` — `dart_style` `DartFormatter`, 80-col, `automate`
  trailing commas. Real formatter, not a stub.
- `DartTools.syntaxDiagnostics` — `parseString(throwIfDiagnostics: false)`
  → scanner/parser diagnostics with `offset`, `length`, 1-based
  `line`/`column`, `code`, `severity`. Correctly labelled "syntax only".
- `DartTools.sourceOverview` — AST outline (class/mixin/enum/extension/
  function/method/getter) + `UriBasedDirective` imports/exports/parts, with
  offsets, so list rows can select the exact source range.
- `DartTools.compile` / `compilePortable` — native Kernel `.dill` where an SDK
  exists, `dart_eval` EVC otherwise.
- `DartProgramRunner` — native process or `dart_eval` worker isolate, real
  stdout/stderr/exit code, cancel → 130, "never ran" → 127.
- `dartTerminalDelegate` — `dart run|compile kernel|format|analyze|--version`
  routed onto the same code paths; `pub`/`global` refused offline.
- Page lifecycle: dirty Save/Discard/Cancel, `_generation` staleness guard,
  `_busy` exclusion, mounted checks, `PopScope` leave-confirm, selection-only
  change does not invalidate diagnostics.

### 2.2 Gaps found (this is the real work list)

1. **Tools tab layout was hand-rolled, not the shared grid.** The embedded
   branch rendered a `SingleChildScrollView` + a "通用" section of `ListTile`s
   over `commonTools`. That is exactly the "second-level feature cards" the
   user rejected, and it duplicated `ToolsGrid`. *Already fixed by the Dart
   owner*: `DartToolsPage.forTab(store, onOpenTerminal)` is now wired in
   `main.dart` as `toolsTabBuilder`, full-page `forStore` retained.
2. **No project-level statistics / import check.** Nothing in the page counted
   files, lines, declarations, or listed unresolved imports. *Partly addressed
   by the new AST structure/import navigation.* A per-project aggregate
   (file count / total lines / public declarations / import graph edges) is
   still absent.
3. **Diagnostics were syntax-only and page-local.** `syntaxDiagnostics` is
   correct but proves parser-only: on `int x = "s"; print(y);` it reports
   **0 errors** (verified below). Editor squiggles/Problems therefore could not
   show type errors or missing imports.
4. **Editor had no diagnostic provider seam.** `editor_page.dart` had
   `editorFileTools` and `documentToolBuilder`, but no analysis hook, so the
   editor could not decorate unsaved buffers. Core has since published
   `lib/services/code_analysis.dart` + `StudioProfile.codeAnalyzer`; the Dart
   adapter `lib/dart_code_analyzer.dart` now implements it (`Isolate.run`
   over parser diagnostics, range-clamped, project-contained).
5. **Formatting ignores project style.** `DartFormatter` is constructed with
   defaults, so a project's `analysis_options.yaml`
   (`formatter: page_width`, `trailing_commas: preserve`) and a
   `// dart format width=N` marker are ignored by the in-app formatter while
   `dart format` honours them. Divergence between our button and official CLI.
6. **Language version is pinned behind the SDK.** Pinned
   `DartFormatter.latestLanguageVersion == 3.10.0`, while `pubspec` requires
   `^3.11.5` and the local SDK is 3.11.5. Code using newer syntax can format
   differently or fail against our default.
7. **Format failures surface as a raw exception string.**
   `_format` catches `Object` and shows `error.toString()`; the official
   behaviour is per-error `line, column` + message. `FormatterException`
   already carries `List<Diagnostic>` with offsets (verified below), so precise
   reporting is available with no new dependency.
8. **Compile writes without the CLI's own directory precondition.**
   `dart compile kernel -o build/x.dill` fails (exit 255) when `build/` does
   not exist. Our page creates `artifact.parent` first and `NativeDartToolchain`
   compiles into an existing temp dir, so we are safe — but any new caller must
   keep that ordering.
9. **No honest "semantic analysis unavailable" state.** `runtimeStatus` exists
   for the runner, but nothing analogous distinguishes "syntax checked" from
   "backend could not type-check" for diagnostics. The core contract has
   `unavailableReason`; the Dart provider must use it rather than claiming clean.

---

## 3. Official-documentation findings (official sources only)

Sources fetched and stored next to this file (`official-*.txt`):
`dart.dev/tools/dart-format`, `dart.dev/tools/dart-analyze`,
`dart.dev/tools/dart-compile`, `dart.dev/tools/dart-run`,
`dart.dev/tools/analysis` (customizing static analysis),
`dart.dev/tools/diagnostics`, `dart.dev/tools/vs-code`,
`dart.dev/tools/analyzer-plugins`, `dart.dev/tools/dart-fix`,
`pub.dev/packages/analyzer`, `pub.dev/packages/dart_style`,
`dartcode.org/docs/` (Dart extension), and the official Analysis Server spec
(`dart-lang/sdk …/analysis_server/tool/spec/spec_input.html`).

### 3.1 `dart format`

- Opinionated, minimally configurable (`dart_style` README).
- Wraps at **80** by default; `formatter: page_width:` in
  `analysis_options.yaml`; per-file `// dart format width=N`.
- `formatter: trailing_commas: preserve` forces a split when a trailing comma
  is present (`automate` is the default; requires language ≥ 3.8).
- `-o write|show|json|none`, `--set-exit-if-changed` (exit 1 on change).
- Unparseable source: **nothing is written**, exit **65**, and every parse
  error is printed with `line N, column M`.
- Editors: VS Code uses `dart_style` by default and supports format-on-save
  (`"[dart]": { "editor.formatOnSave": true }`).

### 3.2 `dart analyze`

- "performs the same static analysis that you get when you use an IDE".
- Accepts a **directory or a single file**; `--fatal-infos`,
  `--[no-]fatal-warnings` (warnings fatal by default), configured by
  `analysis_options.yaml`.
- Output shape: `severity - path:line:col - message - code`
  (e.g. `info - example.dart:9:19 - Unnecessary empty statement. … - empty_statements`).
- Diagnostic catalogue at `dart.dev/tools/diagnostics` uses the same `code`
  names (`empty_statements`, `uri_does_not_exist`, `invalid_assignment`, …).

### 3.3 `dart compile`

- Subcommands `exe`, `aot-snapshot`, `jit-snapshot`, `kernel`, `js`, `wasm`.
- `kernel` = "portable, intermediate representation" — the only offline-usable
  artifact for us; `exe`/`aot-snapshot` are native and JDK/arch specific,
  `js`/`wasm` need the JS/Wasm toolchains.
- Cross-compilation downloads SDK binaries from `storage.googleapis.com` →
  **not allowed offline**.
- "You don't need to compile Dart programs before running them" — `dart run`
  is JIT; compile is an artifact/distribution step.

### 3.4 Editor integration

- `pub.dev/packages/analyzer`: "**Integrators that want to add Dart support to
  their editor should use the Dart Analysis Server**"; if you embed the library
  instead, "**you are responsible for finding the analysis options file,
  parsing it, and configuring the analyzer**".
- Analysis Server is JSON-RPC over stdio with `analysis.updateContent`
  (unsaved overlays, `ChangeContentOverlay` validated by offset) and an
  `analysis.getErrors`-class diagnostics flow. It requires the `dart` CLI, i.e.
  a real SDK process — unavailable on OHOS.
- Dart Code (VS Code) feature set that defines user expectations: realtime
  errors/warnings, Problems, Go to Definition, document/workspace symbols,
  Format Document, Organize Imports, refactors/code fixes.

**Conclusion:** the Analysis Server is the officially recommended editor path
but needs an SDK process. For an offline phone app whose portable target has no
SDK, embedding `package:analyzer` in-process is the only viable route, and the
official docs place the `analysis_options.yaml` responsibility on us.

---

## 4. Empirical evidence gathered (offline, on this machine)

Host: Dart SDK 3.11.5 (`windows_x64`), package pins `analyzer 8.4.1`,
`dart_style 3.1.3`, `dart_eval 0.8.5`.

### 4.1 CLI behaviour actually observed

| Command | Result |
| --- | --- |
| `dart analyze bad.dart` (type error + undefined name) | 2 errors + 1 warning, exit **3**, format `error - bad.dart:2:11 - … - invalid_assignment` |
| `dart analyze broken.dart` (syntax) | 4 parser errors (`missing_function_body`, `missing_identifier`, `expected_token`), exit 3 |
| `dart analyze good.dart` | `No issues found!`, exit **0** |
| `dart analyze` with `linter: prefer_final_locals` | `info - … - prefer_final_locals`, exit **0** (infos not fatal by default) |
| `dart analyze` on bad imports | `uri_does_not_exist` ×2 → **import check is a real analyzer diagnostic** |
| `dart format -o show broken.dart` | nothing written, exit **65**, per-error `line, column` |
| `dart format` with `formatter: page_width: 40` | wrapped at 40 → project config is honoured by the CLI |
| `dart compile kernel src/main.dart -o build/main.dill` without `build/` | exit **255**, `Unable to open file … for writing snapshot` |
| same after `mkdir build` | exit 0, 8.2 MB `.dill`, `dart run build/main.dill` prints correctly |

### 4.2 Pinned-API probes (`package:analyzer` 8.4.1, `dart_style` 3.1.3)

- `parseString(throwIfDiagnostics: false)` on `void main() { int x = "s"; print(y); }`
  → **0 diagnostics**. Confirms the current seam is parser-only.
- Parse errors expose `diagnosticCode.name` (**UPPER_SNAKE**, e.g.
  `EXPECTED_TOKEN`), `diagnosticCode.type` (`SYNTACTIC_ERROR`),
  `severity`, `offset`/`length`, `message`, `correctionMessage`; the CLI's
  published code is the **lowercase** form (`expected_token`).
- `Diagnostic.problemMessage.url` is `null` for parser errors but the code
  object carries the doc URL for semantic ones.
- `DartFormatter(pageWidth: 40)` wraps at 40 — width is a constructor
  parameter, so project config is reproducible in-process.
- Malformed source throws `FormatterException` with `errors` =
  `List<Diagnostic>` carrying `offset`/`length` (observed `12/1`, `12/0`) and a
  human message. Precise format-error ranges are free.
- `DartFormatter.latestLanguageVersion` = **3.10.0** < SDK 3.11.5 and
  < `pubspec` floor 3.11.5.

### 4.3 Full semantic analysis in-process, offline — **feasible**

Probe: `AnalysisContextCollection(includedPaths: [project],
sdkPath: <real SDK>, resourceProvider: OverlayResourceProvider(physical))`,
then `overlay.setOverlay(file, content: <unsaved text>, modificationStamp: n)`,
`context.changeFile(file)`, `await context.applyPendingFileChanges()`,
`await session.getResolvedUnit(file)`.

Observed:

- Cold `setup` ≈ **147 ms**, first `getResolvedUnit` ≈ **1.9 s**.
- Unsaved overlay with `int z = 1.5;` →
  `INVALID_ASSIGNMENT 22/3`, `Severity.error`,
  `type=COMPILE_TIME_ERROR`, `correctionMessage` present,
  `url=https://dart.dev/diagnostics/invalid_assignment`,
  `uniqueName=CompileTimeErrorCode.INVALID_ASSIGNMENT`.
- Re-overlay with clean text → **0 diagnostics** (overlay replacement works, no
  disk writes).
- Overlay with `import 'package:nope/x.dart';` →
  `URI_DOES_NOT_EXIST 7/21` with docs URL.

This maps **1:1 onto the published core contract**:
`startOffset`/`endOffset` are already UTF-16 half-open, `message`,
`severity`, `code` = lowercased name, `source` = e.g. `Dart 分析`.
Offsets are exactly what `CodeDiagnostic` wants — no column/UTF-8 conversion
needed (unlike a compiler-stderr path).

Two gotchas proven by failure:

- Paths must be **`p.normalize(p.absolute(...))`**, i.e. backslash form on
  Windows. `D:/a/b` and `root/src/main.dart` both throw
  `Only absolute normalized paths are supported`. The existing
  `dart_code_analyzer.dart` already normalizes — keep that invariant.
- `setOverlay` signature is named-argument
  (`content:`, `modificationStamp:`), and the SDK root must be the directory
  containing `lib/_internal` (e.g. `…/flutter/bin/cache/dart-sdk`), not the
  `flutter` root or the `dart.bat` wrapper.

### 4.4 The OHOS question

Semantic analysis needs an SDK **directory**: `AnalysisContextCollection`
defaults `sdkPath` to
`path.dirname(path.dirname(Platform.resolvedExecutable))`
(`analyzer/lib/src/util/sdk.dart`), which is meaningless inside a Flutter
phone app, so `sdkPath` must be passed explicitly.

- **Android:** `AndroidDartSdk.prepare()` already yields `home` (the bundled SDK
  root) → semantic analysis is available offline today, no new packaging.
- **OHOS (portable, `dart_eval` era):** the HAP ships no Dart SDK, so
  `_internal` (`sdk_library_metadata`, `vm_platform_strong.dill`, …) is absent
  → semantic type analysis is **not** available. Parser diagnostics still run
  on the app's own VM and remain honest for syntax.
- **Possible future path (not implemented, needs owner decision):** the SDK
  summary is a single file — `lib/_internal/vm_platform_strong.dill` is
  **8.2 MB** on 3.11.5, and `AnalysisContextCollection` accepts
  `sdkSummaryPath`. A summary-only probe was written but **not completed**
  before hand-off, so treat "summary-only semantic analysis on OHOS" as
  **unverified**. If it works, a ~8 MB asset buys real type errors + import
  checks offline on OHOS; if it needs `sdk_library_metadata` too, cost and
  correctness both grow. Recommend: decide only after a measured probe, and
  never advertise the capability until it is proven on device.

Until then the contract's `unavailableReason` is the correct vehicle:
return parser diagnostics always, and add a stable reason string on portable
targets instead of an empty (falsely "clean") result. Note the current adapter
labels itself "语法" honestly but never sets `unavailableReason`; that is the
one behavioural gap left in it.

---

## 5. Implementable boundary (what is provably doable offline)

| Capability | Portable (OHOS, `dart_eval`) | With SDK (Android/desktop) | Basis |
| --- | --- | --- | --- |
| Format (`dart_style`, 80 or configured width) | Yes | Yes | API probe |
| Project-config format (`page_width`, `trailing_commas`) | Yes — parse `analysis_options.yaml` ourselves | Yes | official docs |
| Format error positions | Yes — `FormatterException.errors` offsets | Yes | API probe |
| Syntax diagnostics w/ exact ranges | Yes | Yes | existing |
| AST outline + import/export/part list | Yes | Yes | existing |
| **Type/lint diagnostics** | **No** (no SDK dir) → `unavailableReason` | **Yes**, unsaved overlay, offline | §4.3 |
| **Import check** (`uri_does_not_exist`) | Partial: file/relative existence only, no `package:` | Yes, real analyzer | §4.1/§4.3 |
| Project statistics | Yes (file/line/declaration counts from AST) | Yes | existing AST |
| Run program | `dart_eval` subset, real stdout/exit | native VM + `input.txt` | existing |
| Compile | EVC bytes | Kernel `.dill` | existing |
| `dart format/analyze/compile kernel` in terminal | run/format/analyze only | all | existing |
| `dart pub get`, cross-compile, `exe/js/wasm` | Refused (network/native) | Refused by product policy | official docs |

Not in scope and should stay refused: package resolution over the network,
`dart compile exe`, AOT/JS/Wasm, breakpoint debugging (no stepping API), Ports.

---

## 6. Reuse interfaces (do not fork)

Dart-owned (already present, extend rather than replace):

- `DartTools.format`, `DartTools.syntaxDiagnostics`,
  `DartTools.sourceOverview`, `DartTools.compile`, `DartTools.compilePortable`.
- `DartDiagnostic` (message/code/severity/line/column/offset/length) — the one
  place that knows how to shape a diagnostic for the tools page.
- `DartProgramRunner` / `ProgramRunResult` / `kProgramNotRunExitCode`.
- `NativeDartToolchain` (`resolveExecutable`, `buildRunArguments`,
  `buildKernelArguments` — pure and unit-tested; Android = raw VM, no CLI verb).
- `AndroidDartSdk.prepare()` → `home` is the `sdkPath` for semantic analysis.
- `DartProjectSources.load` → package map + entry URI (portable path).
- `dart_code_analyzer.dart` → the `CodeAnalyzer` implementation.

Shared core (C owner; read-only from here, single writer remains C):

- `services/code_analysis.dart` — `CodeAnalyzer`, `CodeAnalysisRequest`,
  `CodeDocumentSnapshot`, `CodeDiagnostic`, `CodeAnalysisResult`,
  `CodeDiagnosticSeverity`.
- `StudioProfile.codeAnalyzer` (optional; null keeps other products unchanged),
  `StudioProfile.toolsTabBuilder(store, onOpenTerminal)`.
- `pages/tools_grid.dart` — `ToolsGrid`, `ToolSection`, `ToolDefinition`,
  `commonTools`; `widgets/tool_widgets.dart` — `ToolCard`,
  `ToolsSectionHeading`, `ToolResultCard`, `ToolScaffold`, `ToolField`,
  `ResultRow`, `ToolError`, `ToolsTheme`.

Any change to those core files must go through C, and the Dart side must consume
the published contract, per `D:/MyNewProjects/qfli-core-release-sync.md`.

---

## 7. Recommended follow-ups (ranked, not yet done)

1. **`unavailableReason` on the portable path.** When no SDK dir is available,
   return parser diagnostics **plus** a stable reason
   (`'便携运行时不提供类型分析（无 Dart SDK），仅做语法检查'`), so the editor
   never paints a false "clean". Android passes `sdkPath` and returns real
   semantic results. Smallest change with the largest honesty gain.
2. **Semantic provider behind the same contract.** In the adapter, try
   `AnalysisContextCollection(includedPaths: [project], sdkPath: sdkHome,
   resourceProvider: OverlayResourceProvider(physical))`; overlay **every**
   `documents` snapshot (not only the active file) at its own
   `modificationStamp`, `changeFile` + `applyPendingFileChanges`, then
   `getResolvedUnit`. Map `diagnosticCode.name.toLowerCase()` → `code`,
   `problemMessage.url` → `source`/docs, `severity` → `CodeDiagnosticSeverity`,
   `offset`/`offset+length` → the half-open range (no column math). Dispose the
   collection; run in an isolate; never write the project.
3. **Project statistics + import check as first-class tools rows.** Derive from
   AST already produced by `sourceOverview`: files, lines, declarations per
   kind, import/export/part edges, plus unresolved-import rows that select the
   directive range. Mark the import verdict "syntax/relative only" on portable
   and "analyzer" when an SDK resolves them.
4. **Honour project formatting config.** Read `analysis_options.yaml`
   `formatter.page_width` / `formatter.trailing_commas` and a leading
   `// dart format width=N`, then construct
   `DartFormatter(languageVersion: …, pageWidth: …, trailingCommas: …)`.
   Keep the SDK-derived language version rather than the pinned 3.10.0 where a
   newer SDK exists.
5. **Precise format errors.** Catch `FormatterException` explicitly and render
   its `errors` with `line:column`, selecting the range, instead of
   `error.toString()`.
6. **OHOS summary experiment (spike only).** Finish the `sdkSummaryPath` probe
   with `vm_platform_strong.dill`, measure HAP growth and cold resolve time,
   and only then decide. Do not ship a claim before device evidence.

---

## 8. Verification plan (for whoever implements)

Unit (`test/dart_tools_test.dart`):

- format honours `pageWidth`; `FormatterException` yields ranges;
- `syntaxDiagnostics` stays 0 on semantic-only code (locks the "syntax only"
  claim);
- semantic probe (skipped when no SDK dir): `int z = 1.5` →
  `<unknown>`… `invalid_assignment` with `startOffset == code.indexOf('1.5')`
  and `endOffset - startOffset == 3`; `import 'package:nope/x.dart'` →
  `uri_does_not_exist`; clean overlay → empty result; no project file mutated.

Widget (`test/dart_tools_page_test.dart`, existing helpers `_waitFor`,
`_mountTools`, `_performAction`):

- real project loads, format/save/check/compile/run/Stop unchanged;
- compact 320×640 @ textScale 1.8 keeps every control reachable;
- selection-only change preserves diagnostics (existing regression);
- new rows navigate to precise ranges.

Provider (`test/dart_code_analyzer_test.dart`): foreign path rejected, missing
active snapshot rejected, portable reason present, ranges within text length.

Gates: `dart format`, `flutter analyze --no-pub`, `flutter test --no-pub`,
`git diff --check`. Keep target-device evidence separate: host tests never prove
OHOS/Android execution (`spec/backend/dart-native-runtime.md`).

---

## 9. Sources

Official only, fetched to `research/official-*.txt` in this folder:

- <https://dart.dev/tools/dart-format>
- <https://dart.dev/tools/dart-analyze>
- <https://dart.dev/tools/dart-compile>
- <https://dart.dev/tools/dart-run>
- <https://dart.dev/tools/analysis> (Customizing static analysis)
- <https://dart.dev/tools/diagnostics>
- <https://dart.dev/tools/analyzer-plugins>
- <https://dart.dev/tools/dart-fix>
- <https://dart.dev/tools/vs-code>
- <https://pub.dev/packages/analyzer>
- <https://pub.dev/packages/dart_style>
- <https://dartcode.org/docs/> (Dart & Flutter extension for VS Code)
- Dart Analysis Server API spec —
  <https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/tool/spec/spec_input.html>

Local pinned-API facts read from the pub cache (`analyzer-8.4.1`,
`dart_style-3.1.3`, `_fe_analyzer_shared-91.0.0`) and reproduced by the probes in
§4; the temporary probe projects live under `%TEMP%\qfli_*` and are disposable.
