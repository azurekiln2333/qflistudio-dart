# Dart terminal / toolchain release audit

Owner: dart-terminal (Herdr pane `w7:p4`, workspace `w7`)
Repository: `D:/MyNewProjects/qfli_dart` (`git rev-parse --show-toplevel` confirmed)
Task: `.trellis/tasks/10-15-dart-store-release`
Commit: `49df6b34d2af74a9fc0a435d203426b9fcd0a8f9`

## 0. Revision design (Android CLI-subcommand defect)

`runCommand` passed `[--disable-dart-dev, ...arguments]` straight to the SDK
executable. On desktop that executable is the `dart` CLI wrapper, so `dart run`
worked; on Android `AndroidDartSdkLayout.vm` is the raw `dartvm`, which treats
`run` as a script name. Proven on the host `dartvm.exe`:

```
dartvm --disable-dart-dev run main.dart
  -> run: Error: Error when reading 'run'  (exit 254)
dartvm --disable-dart-dev main.dart
  -> vm-ok  (exit 0)
dartvm --snapshot-kind=kernel --snapshot=out.dill main.dart  -> exit 0, out.dill runs
dartvm --version  -> "Dart SDK version: 3.11.5 ..."  (exit 0)
```

So **CLI subcommands must never be handed to `dartvm`**. The terminal hook is
rebuilt around existing, already-verified capabilities instead:

| Terminal input | Route |
| --- | --- |
| `dart run <file.dart>` / `dart <file.dart>` | `DartProgramRunner.run` — the same path as the editor Run button. Native VM on desktop/Android (keeps `--packages`, `input.txt`, containment); portable `dart_eval` on OHOS/iOS/web. |
| `dart run <file.dill>` | `DartProgramRunner.run` (native only; refuses on portable) |
| `dart compile kernel <file.dart>` | `NativeDartToolchain.compileKernel` (native) — writes `build/<entry>.dill`, then points at `dart run <dill>`; portable reports unsupported |
| `dart format <file>` | local `DartTools.format` in place |
| `dart analyze` | local parser diagnostics via `DartTools.syntaxDiagnostics`, labelled syntax-level (not semantic analysis) |
| `dart --version` | real SDK `--version` (VM on Android, CLI on desktop) |
| `dart pub` / `dart global` | refused (offline product) |
| anything else | short unsupported message |

The `dart` executable is a small VM-vs-CLI distinction: a new
`NativeDartToolchain.version()` and a `runsCli`/`compileKernel` capability wrap it.
No `dartdev` snapshot is assumed — it is not exposed by the Android layout and
not verified as a runnable entry.

Scope: stays inside the owned files (`dart_runner.dart`, `native_dart_toolchain.dart`,
`dart_tools.dart`, and the owned tests). No new files outside those. `main.dart`
stays with the offline Pi.

### 0.1 Implementation outcome

- `DartTerminalPolicy` and `NativeDartToolchain.runCommand` were **removed** (they
  embodied the wrong CLI-through-VM model). `NativeDartToolchain.version()` and
  the pure `buildRunArguments` / `buildKernelArguments` helpers replace them.
- `dartTerminalDelegate` routes verbs onto the Runner/`DartTools` paths in the
  table above. Flags other than the parsed verb/operands are not forwarded.
- `dart fix` was dropped from the allowed list (per instruction); `dart --help`
  prints `dartTerminalHelp` describing exactly what is implemented.
- Regression tests: mobile argument assembly (Android uses
  `--snapshot-kind=kernel`/`--snapshot=`, never `compile`/`kernel`/`run`;
  desktop uses `compile kernel` + `-o`), plus portable-branch tests
  (`DartProgramRunner` accepts `.dart` on any platform, `compilePortable`
  round-trips, portable targets decline a `.dill` instead of faking it).
- OHOS/iOS/web: `dart run <file.dart>` reaches `DartProgramRunner`'s portable
  `dart_eval` branch — the same capability the editor Run button has — instead
  of the previous blanket "only the editor button is supported" message.

## 1. Method

Scope of this audit: the two terminal surfaces (editor `TerminalPane` and the
standalone terminal page), plus Dart run/compile/format/diagnostics and the
native toolchain. Owned files only:

- `lib/dart_runner.dart`
- `lib/native_dart_toolchain.dart`
- `lib/dart_project_sources.dart`
- `lib/dart_tools.dart`
- `lib/dart_tools_page.dart`
- `test/dart_tools_test.dart`, `test/dart_tools_page_test.dart`,
  `test/native_dart_toolchain_test.dart`, `test/dart_terminal_delegate_test.dart`

Shared core (`../qfli_studio_core`) was read only; no core file was written.

Host: Windows x64, Flutter `3.27.5-ohos-1.0.1`, Dart SDK `3.11.5`.
Baseline before any edit: `flutter analyze --no-pub` clean; 27 owned host tests
green. Both terminal surfaces were inspected against the shared contracts
`frontend/dart-tools.md` and `backend/dart-native-runtime.md`, and against the
shared core implementation (`terminal_pane.dart`, `terminax_terminal_page.dart`,
`terminal_manager.dart`, `sandbox_shell_backend.dart`, `local_shell_io.dart`,
`runner_service.dart`, `studio_profile.dart`).

## 2. Findings

### 2.1 Complete and correct (verified, no change needed)

- **Editor terminal run path.** `RunnerService.runProject` → `StudioProfile.runner`
  (`DartProgramRunner`) → `NativeDartToolchain`. Output, stderr and exit code are
  taken over by `TerminalPane.attachOutput`; Stop calls `ProgramRunResult.cancel`
  and an infinite program ends at 130. Verified by
  `test/dart_tools_page_test.dart` ("Stop cancels an infinite program") and
  `test/native_dart_toolchain_test.dart` ("an active native program can be stopped").
- **Working directory.** `NativeDartToolchain.run` spawns the SDK with
  `workingDirectory: <project>` and passes `--packages=<config>`. A probe program
  printing `Directory.current.path` printed the project directory. Relative
  `dart:io` writes land in the project.
- **Compile / format / diagnostics.** `DartTools.compile` selects native Kernel on
  Android/desktop and writes `build/<relative-entry><extension>` using
  `CompiledDartProgram.extension`; the `.dill` artifact is reloadable and runnable
  after its source is deleted (verified in the page test). `DartTools.format` and
  `DartTools.syntaxDiagnostics` behave per contract; a caret move preserves
  diagnostics and compiled-artifact status (page test "moving the selection").
- **`.dill` entry.** `DartProgramRunner.run` accepts `.dill` on native platforms
  and `dartProfile.entryFileNames` lists `build/main.dill`; a `build/main.dill`
  runs when its source is gone (probe + page test).
- **No placeholders.** A scan of the owned files for `TODO/FIXME/占位/未实现/开发中`
  returned nothing.
- **`.dill` on portable targets.** On OHOS/iOS/web `NativeDartToolchain.supported`
  is false, so a `.dill` run returns null (honest "cannot identify entry"), the
  profile reports `runtimeKind: dart-eval` / `runtimeStatus: unavailable`, and no
  evaluator is silently substituted. No false capability claim inside the owned
  files.

### 2.2 Gap found and fixed — the terminal had no `dart` command (Gap 1)

**Symptom.** `dartProfile` declared no `terminalCommandDelegate`, so the shared
terminal (`SandboxShellBackend`) had no way to run `dart`. Typing
`dart run src/main.dart` in either the editor terminal or the standalone terminal
produced the sandbox's generic "当前平台的内置终端不支持该命令" message. A Dart IDE's
embedded terminal that cannot run `dart` is incomplete on the run/stop/output/
working-directory axis the audit covers.

**First fix (commit 49df6b3) and its defect.** The first version added a
`dartTerminalDelegate` that forwarded the CLI subcommand to the SDK executable
(`[--disable-dart-dev, ...arguments]`). On desktop that executable is the `dart`
CLI, so `dart run` worked and the host tests passed. On Android
`AndroidDartSdkLayout.vm` is the raw `dartvm`, and the VM reads `run` as a script
name — so every CLI subcommand failed there. The host test masked the target
defect. See §0 for the proof and the redesigned routing.

**Final fix (owned files).**

- `lib/dart_runner.dart`: `dartTerminalDelegate` routes by verb onto
  `DartProgramRunner` / `DartTools` / `NativeDartToolchain.version()`, never
  passing a subcommand to the VM.
- `lib/native_dart_toolchain.dart`: `version()` and the pure
  `buildRunArguments` / `buildKernelArguments` helpers pin the VM-native argument
  assembly for both Android and desktop.

**Offline.** `dart pub` and `dart global` are refused (network package
management/publishing); unknown subcommands get a short honest message. Because
flags are no longer forwarded to the VM at all, there is no `--packages` /
`--snapshot` / `--enable-vm-service` bypass to blacklist — the surface is the
allowlist itself.

**Wiring.** The profile literal lives in `lib/main.dart`, which this Pi does not
own (offline Pi owns main/profile). The one-line hook
`terminalCommandDelegate: dartTerminalDelegate,` (plus the already-present
`dart_runner.dart` import) was reported to `dart-dispatch`; the offline Pi
(`w7:p6`) has since applied it. **This audit did not modify `main.dart`.**

### 2.3 Flagged to dispatch (not owned here)

- `lib/main.dart` sets `runtimeStatus: Platform.isAndroid ? 'available' : …`. Per
  `backend/dart-native-runtime.md`, `available` is reserved for a tested
  target-platform path (`QFLI_DART_ANDROID_SMOKE`). No Android runtime evidence
  was produced in this session; the honest status would be `requires-sdk`-like
  until the smoke gate passes. Reported for the owner's decision; no Android
  capability is asserted by this audit.

## 3. Verification (commands and results)

All commands run from `D:/MyNewProjects/qfli_dart`.

| Command | Result |
| --- | --- |
| `flutter analyze --no-pub` (whole project) | No issues found |
| `flutter analyze --no-pub` (10 owned files) | No issues found |
| `flutter test --no-pub test/dart_terminal_delegate_test.dart` | 23 passed |
| `flutter test --no-pub` (owned: app, tools, toolchain, page, delegate) | 57 passed |
| `dart format` on owned lib + test files | No remaining changes |
| `dartvm` mobile-shape probes (see §0) | command shapes confirmed |

Note on full-suite scope: `test/dart_offline_test.dart` and
`test/dart_terminal_surfaces_test.dart` are concurrent work by other Pis and are
untracked/not owned here. During this session those files were mid-edit and had a
compile error (`dart_offline_test.dart`) and a duplicate `GlobalKey` harness bug
(`dart_terminal_surfaces_test.dart`) — unrelated to the toolchain and outside
this scope. Excluding them, the owned suite is green, including
`dart_content_run_test.dart`, which executes all 240 curriculum programs through
the real runner.

### 3.1 Windows cleanup-race hardening (test-only)

Under parallel native SDK processes, a `Directory.delete(recursive: true)` in
`tearDown` can hit Windows errno 32 while a child still holds a handle. This
surfaced once as two transient failures. The `tearDown`/`finally` blocks in
`test/native_dart_toolchain_test.dart`, `test/dart_tools_test.dart`,
`test/dart_tools_page_test.dart` and the new delegate test now tolerate it, so
cleanup cannot masquerade as a product failure. Two consecutive full runs then
passed 49/49.

## 4. Regression tests added

`test/dart_terminal_delegate_test.dart` (23 tests):

*run routing*

- `dart run <file>` executes a real program in the session working directory
  (relative `dart:io` write proven against the project).
- the `dart <file>` shorthand behaves like `run`.
- a runtime failure keeps the program exit code (exit 7).
- a missing file is reported without spawning.
- a bare `dart` reports the missing subcommand honestly.
- compound lines (`dart --version | cat`) fall through and name the construct.
- an absolute path outside the sandbox is refused.
- a `dart` line from a nested session directory works.

*compile*

- `dart compile kernel` actually produces a runnable `build/main.dill`, runnable
  through the terminal's own `dart run build/main.dill`.
- `dart compile exe` is refused with the supported-form message.

*format and analyze*

- `dart format` rewrites the file in place.
- `dart analyze` reports parser diagnostics and labels them syntax-level.
- `dart analyze` on a clean project reports none.

*offline refusals*

- `dart pub get` / `dart pub add` are refused (no process, no status).
- an unknown subcommand (`dart test`) names the supported set.
- a non-`dart` command is not claimed by the hook.

*version*

- `dart --version` reports the real SDK version.

*mobile argument assembly*

- run arguments are VM-native and never contain `run`.
- Android kernel arguments use `--snapshot-kind=kernel` / `--snapshot=` and never
  contain `compile`/`kernel`/`run` (the exact defect this revision fixes).
- desktop kernel arguments use `compile kernel` and `-o`.

*portable branch*

- `DartProgramRunner` accepts a `.dart` file on every platform (the branch OHOS
  relies on).
- `DartTools.compilePortable` round-trips through the evaluator.
- a portable target declines a `.dill` instead of faking success.

## 5. Platform limitations (truthful, unchanged)

- **Android:** the native hook and toolchain are wired
  (`AndroidDartSdk.prepare`, `qfli_dartwing/sdk.prepare`). Terminal commands use
  the VM-native argument shapes only (`dartvm <script>`, `dartvm
  --snapshot-kind=kernel`), never CLI subcommands — verified by the pure argument
  assembly tests rather than a device. No device runtime smoke evidence was
  produced in this session; the Android build/install/run gate is dispatch's,
  and no Android execution claim is made here.
- **OHOS / iOS / web:** portable `dart_eval` path. `dart run <file.dart>` works
  through `DartProgramRunner`'s portable branch (same as the editor button);
  `dart compile kernel` reports the missing native SDK honestly; `.dill` entries
  are declined; `runtimeStatus: unavailable`. Host tests do not establish target
  support.
- **macOS / Linux:** not exercised on this Windows host. No inference is made
  from Windows results.

## 6. Change boundary

- Modified: `lib/dart_runner.dart`, `lib/native_dart_toolchain.dart`, and three
  owned test files (cleanup hardening); added
  `test/dart_terminal_delegate_test.dart`.
- Removed symbols (no other file referenced them; whole-project analyze is
  clean): `DartTerminalPolicy`, `NativeDartToolchain.runCommand`.
- Not modified: `lib/main.dart`, curriculum, platform packaging, shared core, any
  other workspace.
- Staged and committed with explicit paths only; no `git add .`.

Commits:

- `49df6b34d2af74a9fc0a435d203426b9fcd0a8f9`
  `feat(dart): add offline-hardened dart terminal command delegate`
- revision `fix(dart): route terminal dart commands onto verified run/compile
  paths instead of raw VM CLI subcommands` (this change).
