# Dart terminal / toolchain release audit

Owner: dart-terminal (Herdr pane `w7:p4`, workspace `w7`)
Repository: `D:/MyNewProjects/qfli_dart` (`git rev-parse --show-toplevel` confirmed)
Task: `.trellis/tasks/10-15-dart-store-release`
Commit: `49df6b34d2af74a9fc0a435d203426b9fcd0a8f9`

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

## 1. Method

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

**Fix (owned files).**

- `lib/dart_runner.dart`: new `dartTerminalDelegate(SandboxShellBackend, String)`
  and the pure policy `DartTerminalPolicy`. The delegate tokenizes with
  `EscapePolicy.backslashLiteral` (matching the sandbox), claims only `dart`
  lines, streams stdout/stderr/exit into the backend via `runStreams`, and lets
  everything else fall through to the sandbox's honest message.
- `lib/native_dart_toolchain.dart`: new `runCommand({workingDirectory, arguments})`
  runs the official SDK in the session cwd with the Android SDK environment when
  applicable.

**Offline hardening (per dispatch instruction).** This is an offline product, so
the terminal must not reach the network or leave the sandbox. The policy:

- Allows only `run`, `compile`, `format`, `analyze`, `fix`, `help`, `--version`
  (`-v`), `--help` (`-h`), `--disable-analytics`, and the `dart <script.dart>`
  run shorthand.
- Refuses `dart pub …` and `dart global …` entirely (package management and
  publishing are network features), plus `create`, `test`, and any unknown
  subcommand.
- Refuses `--packages`, `--packages-file`, `--snapshot`, `--snapshot-kind`,
  `--enable-vm-service`, `--observe`, `--disable-service-auth-codes` — flags
  that would reload packages from another location, write a snapshot outside the
  project, or open a network listener.
- Refuses any path-looking operand that escapes the sandbox root via
  `SandboxShellBackend.resolveSandboxPath`, before a process is spawned.
- `NativeDartToolchain.runCommand` enforces the same flag refusal as defense in
  depth (throws `ArgumentError`), so a future caller cannot bypass the policy.

A flag **after** `run` (`dart run main.dart --flag`) is forwarded, because the VM
passes it to the program, not the VM — refusing it would break ordinary programs.

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
| `flutter analyze --no-pub` (whole project) | Clean for owned files; 3 pre-existing info/warning items are in the offline Pi's in-progress `test/dart_offline_test.dart` and `test/_debug_tools_test.dart`, not touched here |
| `flutter analyze --no-pub` (6 owned files) | No issues found |
| `flutter test --no-pub test/dart_terminal_delegate_test.dart` | 15 passed |
| `flutter test --no-pub` (owned: app, tools, toolchain, page, delegate) | 49 passed |
| `flutter test --no-pub` (all test files except the offline Pi's `dart_offline_test.dart`) | 79 passed, 0 failed |
| `dart format` on owned lib + new test files | No remaining changes |
| `git diff --check` | Clean |

Note on full-suite scope: `test/dart_offline_test.dart` and `test/_debug_tools_test.dart`
are concurrent work by the offline Pi and are untracked/not owned here. Running
the full directory included them and produced 5 failures in shared shell/home
widgets (`LocalTutorialsTab`, AI 助手, JSON 格式化) — unrelated to the terminal or
toolchain and outside this scope. Excluding that in-progress file, the rest of
the suite is 79/79 green, including `dart_content_run_test.dart`, which actually
executes all 240 curriculum programs through the real runner.

### 3.1 Windows cleanup-race hardening (test-only)

Under parallel native SDK processes, a `Directory.delete(recursive: true)` in
`tearDown` can hit Windows errno 32 while a child still holds a handle. This
surfaced once as two transient failures. The `tearDown`/`finally` blocks in
`test/native_dart_toolchain_test.dart`, `test/dart_tools_test.dart`,
`test/dart_tools_page_test.dart` and the new delegate test now tolerate it, so
cleanup cannot masquerade as a product failure. Two consecutive full runs then
passed 49/49.

## 4. Regression tests added

`test/dart_terminal_delegate_test.dart` (15 tests):

- `dart run` executes a real program in the session working directory (relative
  `dart:io` write proven against the project).
- `dart --version` returns the real SDK version, exit 0.
- a compile failure surfaces a nonzero native status and stderr.
- unknown commands are not claimed by the hook (sandbox message appears).
- a bare `dart` reports the missing subcommand honestly.
- compound lines (`dart --version | cat`) fall through and name the construct.
- nested session cwd (`cd src` then `dart main.dart`) works.
- policy: all `dart pub`/`global` package commands refused.
- policy: unsupported subcommands refused; the allowlist passes.
- policy: escaping VM flags refused; a program arg after `run` is allowed.
- policy: the `dart <script>` shorthand stays available.
- `runCommand` refuses escape flags as a last resort.
- a `pub` line through the backend never spawns a process.
- an absolute path outside the sandbox is refused.
- an in-sandbox run operand is still allowed.

## 5. Platform limitations (truthful, unchanged)

- **Android:** the native hook and toolchain are wired
  (`AndroidDartSdk.prepare`, `qfli_dartwing/sdk.prepare`). Package management and
  network command paths are disabled by the policy above. No device runtime
  smoke evidence was produced in this session; the Android build/install/run
  gate is dispatch's, and no Android execution claim is made here.
- **OHOS / iOS / web:** portable `dart_eval` path only. The `dart` terminal
  command reports the platform limitation honestly; `.dill` is not accepted;
  `runtimeStatus: unavailable`. Host tests do not establish target support.
- **macOS / Linux:** not exercised on this Windows host. No inference is made
  from Windows results.

## 6. Change boundary

- Modified: `lib/dart_runner.dart`, `lib/native_dart_toolchain.dart`, and three
  owned test files (cleanup hardening); added
  `test/dart_terminal_delegate_test.dart`.
- Not modified: `lib/main.dart`, curriculum, platform packaging, shared core, any
  other workspace.
- Staged and committed with explicit paths only; no `git add .`.

Commit: `49df6b34d2af74a9fc0a435d203426b9fcd0a8f9`
(`feat(dart): add offline-hardened dart terminal command delegate`).
