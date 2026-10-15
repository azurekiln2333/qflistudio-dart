# Quality Guidelines (Backend / Runtime)

> Code quality standards for runtime, toolchain, and content code.

---

## Overview

Standards are enforced by `flutter analyze` (`analysis_options.yaml` includes
`package:flutter_lints/flutter.yaml`) and the `flutter_test` suites. Every
runtime change must keep static analysis at **zero issues** and the full suite
green:

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

For curriculum/runtime-specific gates see
[dart-curriculum.md](../frontend/dart-curriculum.md) and
[dart-native-runtime.md](./dart-native-runtime.md).

---

## Forbidden Patterns

- **Duplicating core policy.** Do not re-implement content parsing, filtering,
  import, or run dispatch. Reuse `ContentCatalog.fromJson`, `ContentRepository`,
  `CodeImportService`, `RunnerService`. This repo owns only Dart-specific policy.
- **Writing to `../qfli_studio_core`.** It is a shared sibling package; changes
  there require coordination (see task design). This repo's writable surface is
  `lib/`, `curriculum/`, `assets/`, `tool/`, `test/`.
- **Faking execution.** Never report success when a run failed or an SDK is
  absent. A missing SDK is a hard failure / explicit skip, never a pass
  (`tool/verify_dart_content.dart` exits non-zero; the runner returns a
  non-zero `ProgramRunResult`).
- **Unbounded `on Object catch` in normal flow.** Reserve broad catches for
  isolate / `compute` boundaries. Catch narrow types elsewhere.
- **Blocking the UI isolate with file scans or compilation.** Use `compute` /
  `Isolate.run` (`lib/dart_tools_page.dart`, `lib/dart_tools.dart`).
- **Hard-coding SDK paths or platform assumptions.** Resolve via
  `NativeDartToolchain.resolveExecutable()` / `AndroidDartSdk.prepare()`.
- **Editing generated JSON by hand.** Regenerate from `curriculum/**`.
- **Leaking a spawned process or temp directory.** Release in `finally`.

---

## Required Patterns

- **Gate platform capability in one place**: `NativeDartToolchain.supported`
  (and the profile's `runtimeKind`/`runtimeStatus`). Do not scatter
  `Platform.isAndroid` checks through feature code.
- **Return a `ProgramRunResult` from run paths**, with a real `exitCode` and
  streams; reserve `null` for "not this language."
- **Catch narrow, act specific** (see [error-handling.md](./error-handling.md)).
- **Use `path` (`package:path`) for all path joins/normalization**, never string
  concatenation. Cross-platform paths are a real bug source here.
- **Offload heavy CPU/IO to an isolate** (`compute` / `Isolate.run`).
- **Guard async continuations** with `mounted` / `_disposed` / a generation
  counter before touching state.
- **Keep helpers private** (`_` prefix) unless they are part of the intended API.

---

## Testing Requirements

- Tests live in `test/` and use `flutter_test`. Real IO uses
  `Directory.systemTemp.createTemp` + `tearDown` cleanup — see
  `test/native_dart_toolchain_test.dart`, `test/dart_tools_test.dart`.
- **Runtime claims are proven by execution, not mocks.** The runner tests spawn
  the real SDK and assert exact stdout/exit codes.
- **Numeric output comparisons use real runs.** Do not assert on a fabricated
  expected value; derive it from an actual execution.
- Set profile state in `setUp` and restore in `tearDown` when a test depends on
  `StudioProfile.current` (`test/dart_app_test.dart`).
- For pure logic, assert behavior on the real function (e.g.
  `DartTools.syntaxDiagnostics` returns locations for a broken buffer).

---

## Code Review Checklist

- [ ] `flutter analyze --no-pub` is clean.
- [ ] `flutter test --no-pub` passes; new behavior has a test.
- [ ] Failure paths produce a non-zero exit code / explicit message, never a
      simulated success.
- [ ] No process, stream subscription, or temp directory is left unreleased.
- [ ] Paths are built with `package:path`; containment is checked before use.
- [ ] No write to shared core; no hand-edited generated asset.
- [ ] Heavy work is off the UI isolate; async continuations check `mounted`/`_disposed`.
- [ ] Platform-specific behavior is gated in one place and documented when it is
      a known limitation.
