# Terminal surface review — widget-level integration verification

Owner: `dart-content` (Herdr pane `w7:p5`).
Task: `.trellis/tasks/10-15-dart-store-release`.
New artifact under my ownership: `test/dart_terminal_surfaces_test.dart`.
Scope of this review: independent verification only — no product code changed.

## 0. Purpose and boundary

The release needs evidence that the **two real terminal surfaces** actually run
a Dart program end to end through the shipped product wiring, not just that a
delegate is non-null. This review adds that widget-level integration test and
records what it proves.

In scope (mine): `test/dart_terminal_surfaces_test.dart`, this report.
Out of scope (not touched): `lib/runner`, `lib/main.dart`, `lib/dart_runner.dart`,
`lib/native_dart_toolchain.dart`, all of `qfli_studio_core`, the Android
`dartvm`/OHOS portable work owned by the terminal Pi, and the offline Pi's
`lib/main.dart` profile/offline surface. No core/Pi implementation was
reimplemented.

## 1. The two surfaces under test

| Surface | Widget | Path | Session model |
| --- | --- | --- | --- |
| Editor terminal | `TerminalPane` + `TerminalPaneState` | `qfli_studio_core/lib/editor/terminal_pane.dart` | private `_TerminalSession` list, tabs render numeric ids |
| App terminal | `TerminaxTerminalPage` | `qfli_studio_core/lib/pages/terminax_terminal_page.dart` | `TerminalManager` → `TerminalSession`, tabs `终端 N` |

Both reach the shipped `dartTerminalDelegate` through
`StudioProfile.terminalCommandDelegate`, which the **real** `dartProfile`
(`qfli_dart/lib/main.dart`) wires to `dartTerminalDelegate`
(`qfli_dart/lib/dart_runner.dart`). The editor pane resolves the delegate lazily
per session (`terminal_pane.dart` `_backendFor`); the app page re-asserts it on
every session creation (`terminax_terminal_page.dart` `_createSession`).

## 2. What the test asserts (and why each is non-tautological)

File: `test/dart_terminal_surfaces_test.dart` (6 tests). It mounts the real
widgets with `StudioProfile.current = dartProfile`, real temp project
directories, and the project's standard **AppPaths reset** (mock the
`plugins.flutter.io/path_provider` channel to a real temp directory). All waits
are bounded pumps with `runAsync` — no fixed sleeps.

### Editor terminal (`TerminalPane`)

1. **profile wiring** — `dartProfile.terminalCommandDelegate` is non-null *and* a
   mounted pane produces a real prompt. (Weak on its own; kept only as a
   precondition for the behavioural tests below.)
2. **`dart run` output + zero success** — types `dart run main.dart`, waits until
   `editor-surface-ok` renders **and the pane is no longer busy**, then asserts the
   marker is present and **no synthetic `exit code 0` line** appears. Fails if the
   pane stops streaming program stdout.
3. **nonzero exit** — a program that writes `boom-diagnostic` to stderr and
   `exit(3)` must render both the diagnostic and the literal `exit code 3`.
   Fails if the real status is dropped or faked.
4. **stop then reuse** — a program that prints `long-running-start` and loops
   forever is started; once the Stop control (`停止`) is shown the test taps it,
   waits for the pane to leave the busy state, then runs a **second** program and
   asserts `after-stop` renders. Fails if a stop leaves the prompt dead or the
   backend wedged.
5. **sessions + hide/show** — runs a program in session 1, opens session 2 (its
   transcript must not leak session 1's line), runs a program there, then
   **collapses the pane** (the editor's real hide mechanism — the pane stays
   mounted with height 0) and expands it, asserting session 2's output survives;
   switching back to session 1 restores its buffered line. Fails if collapse
   drops the element, sessions, or scrollback.

### App terminal (`TerminaxTerminalPage`)

6. **run + per-tab output** — one test body (see §3). It drives `echo` commands
   to prove streaming/rendering and per-tab isolation (`终端 1` vs `终端 2`), then
   writes a real Dart program at the session's resolved cwd and runs
   `dart run app_surface_main.dart`, asserting `app-surface-ok` renders in the
   active session. Fails if the app surface loses the delegate, mis-scopes a tab,
   or fails to render program output.

Assertions read **rendered output** (`SelectableText` rows for the pane;
`TerminalOutputView.session.lines` scoped to the active tab for the app
surface) and the public `TerminalPaneState.busy` / exit lines — never a
"delegate is non-null" or source-string check.

## 3. Harness facts discovered (not product bugs)

These are real, reproducible behaviour of the shared harness; they shaped the
test and are recorded so the next author does not rediscover them:

- **`AppPaths` caches its storage probe in static futures.** A second mounted
  `TerminaxTerminalPage` in the same process can hang on the first test's cached
  directory. The shared core's own `terminal_manager_delegate_test.dart` works
  around this with a single test body; this test does the same for the app
  surface (test 6). This is a harness artifact, not a product defect.
- **`path_provider` is answered by a channel mock**, the project's standard
  AppPaths reset. The app page's session cwd resolves from that storage root (or
  the OS home fallback); the test therefore writes its program **at the session's
  reported cwd** and runs it by basename, keeping the operand inside the sandbox
  on any host, and deletes the file in a `tearDown`.
- **Disposing a pane mid-run schedules the toolchain's 3 s SIGKILL-fallback
  timer** (`NativeDartToolchain.run` `cancel` → `status.timeout(3s)`). Under the
  test's fake clock a pending real timer fails teardown, so the tests drive each
  program to a terminal state and unmount with `runAsync` so real teardown
  settles. Worth noting for future pane-disposal tests; not changed here because
  it is shared-core + terminal-Pi code.

## 4. First-run failures found and how they were resolved

The test was written before the implementation was assumed correct and was
allowed to fail. Observed failures:

- `busy` still true immediately after output appeared → **test-timing**: wait for
  `!busy`, not only for the output line (bounded pump).
- Pending-timer failures on teardown → **harness**: unmount via `runAsync` so the
  real process/timer settles (§3).
- Session hide/show originally unmounted the pane via a different widget type,
  which destroyed the sessions → **test correction**: hide the way the editor
  does (controlled `collapsed`, element preserved).
- App-surface `dart run` produced no output → **test correction**: the session cwd
  is host-dependent; write the program at the reported cwd (§2, §3).

None of these was a product defect; all were corrected in the test, per the
instruction to iterate the test against real behaviour.

## 5. Verification

```powershell
# from D:/MyNewProjects/qfli_dart
flutter analyze --no-pub test/dart_terminal_surfaces_test.dart   # No issues found
flutter test --no-pub test/dart_terminal_surfaces_test.dart       # +6 All tests passed
# stability: 3 consecutive runs -> +6 All tests passed each time (no flakiness)

# after the terminal Pi's implementation stabilised (lib/ fully committed):
flutter analyze --no-pub lib test tool curriculum                 # No issues found
flutter test --no-pub                                             # +103 All tests passed
```

- Host: Windows, Dart SDK 3.11.5; `NativeDartToolchain.supported` is true, so
  every `dart run` above executed on the real official VM and its stdout was
  compared to the declared marker.
- The run assertions are gated on `NativeDartToolchain.supported`; a host without
  the SDK reports an explicit **environment skip**, never a pass.

## 6. Findings for the terminal Pi / dispatcher

- **No product defect was found on the verified host path.** Both surfaces run a
  real program through the shipped delegate, render stdout, surface a nonzero
  exit, recover after a stop, and preserve per-session transcripts across switch
  and collapse/expand.
- **Not covered here (terminal Pi's domain, still open):** Android `dartvm`
  accepting CLI subcommands and OHOS portable `dart run`. Those paths need a
  device/emulator and are exercised separately; this Windows host can only
  verify the official-SDK VM branch. The `!NativeDartToolchain.supported`
  portable branch of `dartTerminalDelegate` reports a platform limitation rather
  than silently doing nothing (see `lib/dart_runner.dart`), which the delegate
  unit tests cover; the widget path on a portable-only device remains a device
  gate.
- **Harness note for future terminal tests** (§3): `AppPaths` static caching,
  the pending SIGKILL-fallback timer on mid-run disposal, and the host-dependent
  app-session cwd.

## 7. Files

- Added: `test/dart_terminal_surfaces_test.dart` (6 integration tests).
- Added: `.trellis/tasks/10-15-dart-store-release/research/terminal-surface-review.md` (this report).
- No product, core, or other-Pi file was modified.
