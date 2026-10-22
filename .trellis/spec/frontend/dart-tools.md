# Dart Tools Contract

## 1. Scope and Trigger

`lib/dart_tools_page.dart` connects real local project files to the embedded
compiler, formatter, parser diagnostics, source structure, and runner. Embed
these actions directly through `StudioProfile.toolsTabBuilder`. Retain
`toolsPageBuilder` for callers that need the full-page route.
Do not use sample buffers as a substitute for files from `ProjectStore`.

## 2. Signatures

- `DartToolsPage({required ProjectStore store, bool embedded = false,
  VoidCallback? onOpenTerminal})`
- `DartToolsPage.forTab(ProjectStore, VoidCallback) -> Widget` embeds the body
  without a nested Scaffold/AppBar and includes common tools and terminal access.
- `DartTools.format(String source) -> String`
- `DartTools.syntaxDiagnostics(String source) -> List<DartDiagnostic>`
- `DartTools.sourceOverview(String source) -> DartSourceOverview` returns line
  and Unicode character counts, AST declarations and import/export/part items.
  Every item has `label`, `kind`, `offset`, `length`, and one-based `line`.
- `const DartCodeAnalyzer().analyze(CodeAnalysisRequest)` returns
  `Future<CodeAnalysisResult>` using the shared frozen
  `package:qfli_studio_core/services/code_analysis.dart` types.
- `DartTools.compile({required String projectPath, required String entryFile})`
  returns `Future<CompiledDartProgram>`.
- `DartProgramRunner.run({required String projectPath, required String entryFile})`
  returns `Future<ProgramRunResult?>`.

The shared core owns the navigation hook and run-result types. Changes to the
core repository require separate review and commits.

## 3. Contracts

- Show local projects only; scan actual `.dart` files without following links.
  Skip hidden entries and `build` output.
- Formatting changes the editor buffer. Explicit Save, Compile, and Run persist
  the current buffer; compile and run must wait for saving to succeed.
- Syntax checks use the unsaved buffer. Diagnostics include a one-based line
  and column, UTF-16 `offset`/`length`, code, severity, and message. These are scanner/parser diagnostics,
  not project-wide type or dependency analysis.
- The editor provider accepts normalized absolute project-owned `.dart` snapshot
  paths. It analyzes the exact immutable unsaved text in a worker isolate, without
  reading/writing source files or running user programs. Preserve CRLF and UTF-16
  ranges; `endOffset = offset + length` is exclusive. Source label is `Dart 语法`.
  Other open Dart snapshots are analyzed too; other languages/outside-root paths
  are excluded. Missing active snapshot/outside-root active path returns a
  nonnull `unavailableReason`. Completed clean syntax analysis has null reason
  and an empty diagnostics list; undefined names are outside parser scope.
- The shared core owns debounce, stale revision/text/root rejection, squiggles
  and Problems navigation. The product provider must not duplicate this UI or
  claim parser results establish type/dependency correctness.
- AST structure uses the current unsaved source and ignores code-shaped comments
  and strings. Selecting an item moves the caret using its UTF-16 range. Actual
  edits/file/project switches invalidate the overview; selection changes do not.
- Home retains tab buffers under `TickerMode(enabled: selectedTab == index)`.
  An embedded page only guards route back while its ticker mode is enabled;
  hidden dirty tools must not open a dialog from another tab. Standalone route
  guards remain active. Switching tabs keeps the unsaved buffer in memory.
- `TextEditingController` also notifies on selection changes. Compare the text
  with the last observed buffer before marking it dirty or invalidating results;
  moving the caret must preserve diagnostics and compiled-artifact status.
- Compilation writes upstream Kernel `.dill` bytes on Android/desktop, and EVC
  bytes on the retained portable platforms, to
  `build/<relative-entry-path-without-extension><compiled.extension>` inside the selected project.
  Display success only after the write and flush complete.
- A saved `.dill` exposes Run compiled result. This action reads the artifact
  without saving the source buffer, and works after the source has been removed.
- Expensive operations run in worker isolates. Prevent edits and duplicate
  actions while an operation owns a source snapshot. Discard stale asynchronous
  file results and avoid updating disposed widgets.
- A run displays actual stdout/stderr and its exit code. Cancellation terminates
  the worker and returns 130. Run failures before execution use 127; runtime
  exceptions use 1. Release stream subscriptions on completion or disposal.
- `dart_eval` compatibility is narrower than the Dart SDK. On portable targets keep
  `runtimeStatus: 'unavailable'` until a target-platform build and execution are
  verified; passing host tests alone does not establish target support.

## 4. Validation and Error Matrix

| Condition | Required behavior |
| --- | --- |
| No local projects or Dart files | Show a real empty state |
| Unsaved changes before selecting another file/project | Offer Save, Discard, and Cancel; Cancel keeps the current selection |
| Unsaved changes when leaving the tools route | Offer Save, Discard, and Cancel; leave only after successful Save or explicit Discard |
| Save or source-read failure | Show the error; do not compile/run stale disk content |
| Invalid syntax | Show parser diagnostics or a formatter/compiler error |
| Missing active editor snapshot | Return analysis unavailable; do not report clean |
| Valid syntax with unresolved names | Completed parser result; do not claim semantic validation |
| Emoji/CRLF before a diagnostic/declaration | Preserve exact UTF-16 navigation offsets |
| Unsupported language/library feature | Report the compiler failure |
| Bytecode write failure | Show the filesystem error, with no success message |
| Infinite program | Stop remains available and releases the worker |
| Widget removed during an operation | No setState after disposal; cancel an active run |

## 5. Good, Base, and Bad Cases

- Good: format a project buffer, compile it, reload the generated bytes with
  `Runtime(ByteData.sublistView(bytes))`, and execute the compiled entry URI.
- Good: inspect unsaved declarations/imports, select an item, and keep the
  overview while moving the caret; edit the text and require fresh results.
- Base: create the bundled Dart project, select `src/main.dart`, and run its
  actual greeting with exit code 0.
- Bad: invalid syntax yields diagnostics; an unsupported import fails compilation;
  cancelling a file switch preserves the original buffer and dropdown value.

## 6. Required Verification

Run `flutter test --no-pub`, `flutter analyze --no-pub`, Dart formatting, and
`git diff --check` before committing a verified batch. Widget tests should cover
  loading real files, saved edits, formatting, diagnostics, compiler output, run output,
and Stop. Verify compact viewports and enlarged text when changing layout.
Provider tests must distinguish unavailable from actual clean syntax results,
assert an independent numeric offset after an emoji/CRLF, check other open
buffers, exclude foreign/outside paths, and prove disk is unchanged. Profile
tests must retain both the direct tools hook and analyzer hook.

Widget tests with real file I/O and isolates must use bounded real-time polling
through `tester.runAsync` and pump between polls. Wait for the operation's
completion state, unmount the page, and then dispose the store/delete temporary
files. File existence alone does not prove an asynchronous writer has closed.
When waiting for a navigation animation, advance Flutter's fake clock with a
duration-bearing `tester.pump`, as well as allowing real I/O time. A zero-duration
pump cannot complete a route's exit animation even when the save is finished.

## 7. Wrong vs Correct

Wrong: stop waiting as soon as `artifact.existsSync()` is true and delete the
project immediately. On Windows the writer may still own the file (errno 32).

Correct: wait for the compile action to finish and its success state, assert the
artifact can be read and executed, then unmount the widget before cleanup.

Wrong: return an empty successful analysis when there is no active snapshot,
or normalize line endings before mapping parser offsets.

Correct: return an unavailable reason for missing input and analyze the exact
captured String, leaving stale-result rejection to the shared core.
