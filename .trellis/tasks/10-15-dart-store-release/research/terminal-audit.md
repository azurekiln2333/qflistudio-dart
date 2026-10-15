# Dart terminal / toolchain release audit

Owner: dart-terminal (Herdr pane `w7:p4`, workspace `w7`)
Repository: `D:/MyNewProjects/qfli_dart` (`git rev-parse --show-toplevel` confirmed)
Task: `.trellis/tasks/10-15-dart-store-release`

This report reflects the **final implementation**. Earlier intermediate notes
(the removed `DartTerminalPolicy`, `NativeDartToolchain.runCommand`, and the
"OHOS only supports the editor button" conclusion) are superseded and are not
restated here as current behaviour. The final contract lives in
[`frontend/dart-terminal.md`](../../../spec/frontend/dart-terminal.md) and
[`frontend/dart-tools.md`](../../../spec/frontend/dart-tools.md).

Owned files:

- `lib/dart_runner.dart`, `lib/native_dart_toolchain.dart`,
  `lib/dart_project_sources.dart`, `lib/dart_tools.dart`, `lib/dart_tools_page.dart`
- `test/dart_tools_test.dart`, `test/dart_tools_page_test.dart`,
  `test/native_dart_toolchain_test.dart`, `test/dart_terminal_delegate_test.dart`

Shared core was read only; no core file was written.

## 1. Final behaviour

### 1.1 Two terminal surfaces, one delegate

`dartProfile` wires `terminalCommandDelegate: dartTerminalDelegate`
(`lib/main.dart`, applied by the offline Pi who owns the profile). Both the
editor `TerminalPane` and the app-level `TerminaxTerminalPage` read
`StudioProfile.current?.terminalCommandDelegate`, so one hook serves both. A
`dart` line reaches the same verified paths the editor Run button uses, in the
session's working directory.

### 1.2 Supported commands

| Input | Route |
| --- | --- |
| `dart run <file.dart>` / `dart <file.dart>` | `DartProgramRunner.run` — native VM on desktop/Android, portable `dart_eval` on OHOS/iOS/web |
| `dart run <file.dill>` | runner's native compiled-program path (portable declines) |
| `dart compile kernel <file.dart>` | `NativeDartToolchain.compileKernel` → `build/<entry>.dill`, runnable via `dart run` |
| `dart format <file>` | `DartTools.format`, in place |
| `dart analyze [path]` | `DartTools.syntaxDiagnostics` — parser/scanner level, not semantic analysis |
| `dart --version` | `NativeDartToolchain.version()` |
| `dart --help` | `dartTerminalHelp` |
| `dart pub …` / `dart global …` | refused (offline: no network) |
| other | short unsupported message |

### 1.3 Raw VM vs CLI (the decisive correctness point)

The Android SDK entry `AndroidDartSdkLayout.vm` is the raw `dartvm`, which reads
`run` as a script name. This was confirmed on the host `dartvm.exe`:

```
dartvm --disable-dart-dev run main.dart
  -> run: Error: Error when reading 'run'   (exit 254)
dartvm --disable-dart-dev main.dart         -> runs (exit 0)
dartvm --snapshot-kind=kernel --snapshot=out.dill main.dart -> exit 0, out.dill runs
dartvm --version                            -> "Dart SDK version: ..."  (exit 0)
```

Therefore **no CLI subcommand is ever handed to the VM**. `buildRunArguments` and
`buildKernelArguments` (pure, `android`-parameterised, unit-tested) pin the two
shapes; only the desktop branch uses the `compile kernel` CLI subcommand. No
`dartdev` snapshot is assumed.

### 1.4 Portable targets (OHOS/iOS/web)

`dart run <file.dart>` works through `DartProgramRunner`'s portable `dart_eval`
branch — the same capability the editor Run button has — not a "button only"
restriction. `dart compile kernel` and `.dill` runs report the missing native SDK
honestly; `.dill` is declined rather than faked. `dart format` / `dart analyze`
run locally on every target.

### 1.5 Errors, exit status, cancellation, cwd

- Operands resolve through `backend.resolveSandboxPath`; an escape is refused
  before any process spawns.
- The child runs with the session cwd; relative `dart:io` writes land in the
  project.
- `runStreams` streams real stdout/stderr and the numeric status; success is
  silent, nonzero shows `exit code N`.
- Stop terminates the VM (SIGTERM, then SIGKILL after 3 s) or the portable worker
  and reports **130**; pre-execution failures use 127.

## 2. Repository verification

| Check | Result |
| --- | --- |
| `flutter analyze --no-pub` (whole project) | clean |
| `flutter test --no-pub` (full suite) | 103/103 passed |
| `test/dart_terminal_delegate_test.dart` | 23 passed |
| `dart format` on owned files | no remaining changes |
| `git diff --check` | clean |

`dart_content_run_test.dart` executes all 240 curriculum programs through the
real runner, so the full-suite pass includes real execution.

## 3. Android device verification

Run by the dispatcher's Android SDK smoke harness (`tools/android_sdk_smoke.dart`
/ `QFLI_DART_ANDROID_SMOKE`), extended to the terminal surface. Final results are
recorded in the dispatcher's platform report; the terminal-relevant outcomes are:

- the 9 core official-VM smoke checks passed;
- the terminal extensions passed: `dart --version`, source run, `dart format`,
  syntax check, and source-free Kernel (`compile kernel` → run the `.dill`);
- the cancellation tool required waiting for the stdout synchronous callback to
  unwind its stack — a **tool** fix, not a product defect.

The final Android numbers and artifacts are attached by the dispatcher; this
report does not duplicate or pre-empt them.

## 4. Remaining limits (truthful)

- **Android:** native hook, toolchain and terminal commands use VM-native shapes
  only; verified on a device by the dispatcher's smoke report. This section defers
  to that report for the authoritative result.
- **OHOS / iOS / web:** portable `dart_eval` only. `dart run <file.dart>` works;
  `compile kernel` and `.dill` runs are declined with an honest message;
  `runtimeStatus: unavailable`. Host tests do not establish target support.
- **macOS / Linux:** not exercised on this Windows host; no inference from
  Windows results.

## 5. Change boundary

- Modified: `lib/dart_runner.dart`, `lib/native_dart_toolchain.dart`, and the
  owned tests; added `test/dart_terminal_delegate_test.dart`.
- Removed (obsolete intermediate design, unreferenced elsewhere):
  `DartTerminalPolicy`, `NativeDartToolchain.runCommand`.
- Not modified: `lib/main.dart` (profile), curriculum, platform packaging, shared
  core, `tools/`, any other workspace.

Key commits: `49df6b3` (first delegate), `3e17a63` (route onto verified
run/compile paths), `909e4a3` (revision report). `fae207e` wired the profile in
`main.dart` (offline Pi).
