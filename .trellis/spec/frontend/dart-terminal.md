# Dart Terminal Delegate Contract

## 1. Scope / Trigger

Use this contract when changing the embedded terminal's `dart` command, the
`StudioProfile.terminalCommandDelegate` wiring, or the VM/Kernel argument
assembly. It covers **both terminal surfaces**:

- the editor terminal — `TerminalPane` (`../qfli_studio_core/lib/editor/terminal_pane.dart`);
- the app-level terminal — `TerminaxTerminalPage`
  (`../qfli_studio_core/lib/pages/terminax_terminal_page.dart`).

Both read the profile hook, so one delegate serves both:

```dart
// lib/main.dart (dartProfile)
terminalCommandDelegate: dartTerminalDelegate,
```

The delegate is `Future<bool> dartTerminalDelegate(SandboxShellBackend backend,
String command)` in `lib/dart_runner.dart`. It returns `true` when it handled the
line (including refusing it) and `false` only when the line is not a `dart`
command, so the sandbox keeps its own honest message for everything else.

Trigger: any new/changed terminal verb, any change to how a verb maps onto
`DartProgramRunner` / `DartTools` / `NativeDartToolchain`, or any change to the
Android-vs-desktop argument shapes.

> **Warning — the single most important rule.** Android's SDK entry is the raw
> VM (`AndroidDartSdkLayout.vm` → `libqfli_dartvm.so`), not the `dart` CLI.
> Never hand a CLI subcommand to it. `dartvm --disable-dart-dev run main.dart`
> fails with `run: Error: Error when reading 'run'` (exit 254) because the VM
> reads `run` as a script name. Desktop `dart` is a CLI wrapper and tolerates
> the same line, so **host tests alone cannot catch this** — see §6.

## 2. Signatures

- `Future<bool> dartTerminalDelegate(SandboxShellBackend backend, String command)`
- `const String dartTerminalHelp`
- `NativeDartToolchain.version() -> Future<String>`
- `NativeDartToolchain.buildRunArguments({required String entry, String? packageConfig}) -> List<String>`
- `NativeDartToolchain.buildKernelArguments({required String entry, required String artifact, String? packageConfig, required bool android}) -> List<String>`
- `NativeDartToolchain.run({required String projectPath, required String entryFile}) -> Future<ProgramRunResult>`
- `NativeDartToolchain.compileKernel({required String projectPath, required String entryFile}) -> Future<Uint8List>`
- `DartProgramRunner.run({required String projectPath, required String entryFile}) -> Future<ProgramRunResult?>`
- `DartTools.format(String source) -> String`
- `DartTools.syntaxDiagnostics(String source) -> List<DartDiagnostic>`
- `DartTools.compilePortable({required String projectPath, required String entryFile}) -> Future<CompiledDartProgram>`

`buildRunArguments` / `buildKernelArguments` are pure and platform-parameterised
on purpose: the Android branch is unit-testable without a device.

## 3. Contracts

### 3.1 Supported commands (allowlist)

| Terminal input | Route | Result |
| --- | --- | --- |
| `dart run <file.dart>` | `DartProgramRunner.run(projectPath: backend.cwd, entryFile: <abs>)` | native VM on desktop/Android (packages + `input.txt` + containment); portable `dart_eval` on OHOS/iOS/web |
| `dart <file.dart>` (shorthand) | same as `dart run` | same |
| `dart run <file.dill>` | `DartProgramRunner.run` native compiled-program path | runs the Kernel artifact without its source; refused on portable |
| `dart compile kernel <file.dart>` | `NativeDartToolchain.compileKernel` | writes `build/<relative-entry>.dill` in the project, then points at `dart run <dill>` |
| `dart format <file>` | `DartTools.format`, written in place | prints `已格式化 <file>` |
| `dart analyze [path]` | `DartTools.syntaxDiagnostics` over the file or every `.dart` under the path | parser-level diagnostics; **not** semantic analysis |
| `dart --version` / `-v` | `NativeDartToolchain.version()` | real SDK version line |
| `dart --help` / `-h` / `help` | `dartTerminalHelp` | lists exactly the supported set |
| `dart pub …` / `dart global …` | refused | offline: package management/publishing need the network |
| any other verb | refused | short "unsupported; supports run/compile/format/analyze/--version" |

Every verb the delegate handles returns `true`. A non-`dart` first token, or a
compound line (pipeline/redirection/chaining/glob), returns `false` so the
sandbox reports its own construct message.

### 3.2 Argument assembly — raw VM vs CLI

`buildRunArguments` (both platforms):

```
['--disable-dart-dev', '--packages=<cfg>'?, '<entry>']
```

A bare script operand is the VM run form; no `run`/`compile` token appears.

`buildKernelArguments` (Android, `android: true`):

```
['--disable-dart-dev', '--snapshot-kind=kernel', '--snapshot=<artifact>',
 '--packages=<cfg>'?, '<entry>']
```

`buildKernelArguments` (desktop, `android: false`):

```
['compile', 'kernel', '--packages=<cfg>'?, '<entry>', '-o', '<artifact>']
```

Only the desktop branch uses the `compile kernel` CLI subcommand — the desktop
executable is the CLI. No `dartdev` snapshot is assumed: it is not exposed by the
Android layout and is not verified as a runnable entry.

### 3.3 Paths and working directory

- Every operand is resolved with `backend.resolveSandboxPath`, so a relative path
  is relative to the **session cwd** and an escape throws `SandboxEscapeException`
  (reported as `不能越出沙盒目录`, no process spawned).
- `DartProgramRunner.run` / `compileKernel` receive `backend.cwd` as the project
  root, so the child runs with the session cwd as its working directory and
  relative `dart:io` writes land in the project.
- The `compile kernel` artifact path mirrors the tools page:
  `build/<relative-entry-without-extension>.dill` inside the project.

### 3.4 Output, exit status, cancellation

- Output is streamed through `backend.runStreams(title, stdout, stderr,
  exitCode, cancel)`, so both surfaces render real stdout/stderr and the numeric
  status (the pane prints `exit code N` for nonzero; successful runs are silent).
- `native` run cancellation kills the VM (`SIGTERM`, then `SIGKILL` after 3 s) and
  reports exit **130**. Portable cancellation kills the worker isolate and reports
  **130**. `kProgramNotRunExitCode` (127) is used when the program never started.
- The shared shell clears `lastExitCode` on interruption and emits `^C`; neither
  terminal surface promises to display the runner's cancellation code. Verify
  the runner's 130 separately, then verify that the shell releases its busy state
  and can execute another command.
- `dartTerminalDelegate` awaits `runStreams` before returning, so the sandbox's
  `busy` state spans the whole command and Stop stays wired for its duration.

## 4. Validation & Error Matrix

| Condition | Required behavior |
| --- | --- |
| Empty `dart` | `请在命令中给出子命令…`, no process, no status |
| `dart pub …` / `dart global …` | `离线版终端禁用 dart pub/global（…需要网络）`, no status |
| Unknown verb | `不支持 dart <verb>；支持 run/compile/format/analyze/--version` |
| `run`/shorthand with 0 or >1 operands | usage message, no process |
| Operand starts with `-` | `不接受参数 <operand>`, no process |
| Operand escapes the sandbox | `不能越出沙盒目录：<operand>`, no process |
| Operand file missing | `文件不存在：<operand>`, no process |
| `dart compile <not kernel>` | `只支持 dart compile kernel <文件.dart>` |
| `compile kernel` on a portable target | honest "no official SDK; portable only runs" |
| Compile failure | `编译失败：<stderr>`, no success line |
| Program runtime failure | native stderr + native nonzero exit code |
| Stop during a run | VM/worker terminated; runner returns 130; shell emits `^C`, clears status and releases busy state |
| `.dill` on a portable target | runner returns null → `无法运行 …（该文件类型不受支持）` |
| `.dart` file on any target | runner accepts it (native or portable) |

## 5. Good, Base, Bad Cases

- Good: `dart run src/main.dart` in the editor terminal prints the program's
  stdout with a zero status, and `dart compile kernel src/main.dart` then
  `dart run build/src/main.dill` prints the same output after the source is gone.
- Base: `dart --version` prints the real SDK version; `dart format src/main.dart`
  rewrites the buffer on disk; `dart analyze` reports a syntax error with
  `file:line:col`.
- Bad: `dart pub get` is refused offline; `dart compile exe main.dart` is refused;
  `dart run /elsewhere/main.dart` is refused before any process spawns;
  `dart --version | cat` falls through to the sandbox's pipeline message.

## 6. Tests Required

`test/dart_terminal_delegate_test.dart` (assertion points):

- run routing: real program executes in the session cwd; shorthand equals run;
  exit code preserved (exit 7); missing file no-spawn; bare `dart`; compound line
  falls through; out-of-sandbox path refused; nested `cd src` then run.
- compile: `compile kernel` produces a runnable `build/main.dill` that the
  terminal's own `dart run` executes; `compile exe` refused.
- format/analyze: in-place rewrite; parser diagnostics labelled syntax-level;
  clean project reports none.
- offline refusals: `dart pub get`/`add` refused with no status; unknown verb
  names the supported set; non-`dart` command not claimed.
- version: real SDK version.
- **mobile argument assembly** (the regression for the raw-VM defect): run args
  never contain `run`; Android kernel args use `--snapshot-kind=kernel`/
  `--snapshot=` and never contain `compile`/`kernel`/`run`; desktop kernel args
  use `compile kernel` + `-o`.
- portable branch: `DartProgramRunner` accepts `.dart` on any platform;
  `compilePortable` round-trips `.evc`; portable declines `.dill`.

Android execution is a separate gate (`tools/android_sdk_smoke.dart` +
`QFLI_DART_ANDROID_SMOKE`): `dart --version`, source run, format, syntax check and
source-free Kernel must pass on a device. Host tests never substitute for it.

## 7. Wrong vs Correct

#### Wrong

```dart
// Forward the CLI subcommand to whatever executable resolveExecutable() returns.
process = await Process.start(sdk, [
  '--disable-dart-dev',
  if (packages.path != null) '--packages=${packages.path}',
  ...arguments, // e.g. ['run', 'main.dart']
]);
```

`resolveExecutable()` returns raw `dartvm` on Android, which reads `run` as a
script name → `run: Error: Error when reading 'run'` (exit 254). Desktop `dart`
is the CLI, so a host-only test passes while the device fails.

#### Correct

```dart
// Route by capability; never pass a CLI subcommand to the VM.
if (verb == 'run') {
  await _stream(backend, () => const DartProgramRunner().run(
    projectPath: backend.cwd, entryFile: resolved));
} else if (verb == 'compile') {
  final bytes = await const NativeDartToolchain().compileKernel(...);
  // ...and the VM-native args come from the pure helpers:
  // buildKernelArguments(android: true) ->
  //   ['--disable-dart-dev', '--snapshot-kind=kernel', '--snapshot=<dill>', ...,'<entry>']
}
```
