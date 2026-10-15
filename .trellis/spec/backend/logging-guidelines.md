# Logging Guidelines

> How this project reports diagnostics. There is **no logging framework**.

---

## Overview

`qfli_dart` declares **no logging package** (`logging`, `logger`, `talker`,
crash reporters — verified absent from `pubspec.yaml`). It is an offline app
with no log sink and no telemetry. Diagnostics are written with Flutter's
built-in `debugPrint` (and `developer.log` for structured timing), which are
stripped/compiled out in release builds for `debugPrint` throttling.

Verification: `grep -R "logger\|logging" lib pubspec.yaml` returns nothing.
`print` does not appear in `lib/**` at all — it is reserved for scripts and for
**user programs**, whose stdout is captured by the runner, not by the app's own
logging.

---

## Log Levels

There is no level enum. Match intent to the one available tool:

| Intent | Tool | Where |
| --- | --- | --- |
| Best-effort diagnostic on a recoverable failure | `debugPrint` | `core/lib/services/local_audit_service.dart`, `local_stats_service.dart`, `tutorial_service.dart`, `splash_screen.dart` |
| Structured performance/timing record | `developer.log` | `core/lib/editor/open_performance.dart` |
| User-visible program output | a stream on `ProgramRunResult` | `lib/dart_runner.dart` |
| Script result | `print` (scripts only) | `tool/*.dart` |

Do **not** add a logging dependency to "improve" this; an offline app with no
collector does not benefit, and the team's established pattern is `debugPrint`.

---

## Structured Logging

`debugPrint` takes a single message string. The local convention is a short
**bracketed tag** plus a Chinese description and the error:

```dart
// core/lib/services/tutorial_service.dart
debugPrint('[TutorialService] 读取 $language 教程失败：${failures.join(' | ')}');
// core/lib/services/local_audit_service.dart
debugPrint('LocalAuditService write failed: $error');
```

For timing, use `developer.log` with a name so it is filterable:
```dart
// core/lib/editor/open_performance.dart
developer.log(..., name: 'qfli.editor.open');
```

There is no JSON log format and no required field set — do not invent one.

---

## What to Log

- A recoverable failure that would otherwise be silently swallowed (a load that
  fell back to defaults, a best-effort write that failed).
- Slow-path timing in performance-sensitive flows (`open_performance.dart`).
- Startup configuration failures, so a blank screen has a trace
  (`splash_screen.dart`: `debugPrint('本地配置加载失败：$error\n$stack');`).

## What NOT to Log

- **User program stdout/stderr.** That is the program's output and is streamed
  to the terminal via `ProgramRunResult`; do not also `debugPrint` it.
- **Secrets/credentials.** Even though this product is offline, the shared core
  has network-capable services for other products; never log tokens, API keys,
  or file contents.
- **`print` in library code.** It is not throttled and cannot be disabled; use
  `debugPrint`. (`print` is acceptable only in `tool/*.dart` scripts, which run
  under `dart run` and are not shipped.)
- **Debug spam in hot paths** (per-frame, per-stream-line). Stream line handling
  belongs in widget state with `setState`, not in a log.

---

## Common Mistakes

- **Reaching for a logging package.** Out of character; use `debugPrint`.
- **Using `print` in `lib/**`.** It ships to release and bypasses Flutter's
  throttling; the codebase has zero `print` calls in `lib/`.
- **Logging without a tag or context.** `'failed'` is useless; include what
  failed and the error (`'[TutorialService] 读取 … 失败：$…'`).
- **Logging and swallowing.** If the failure matters, it must also reach the
  user through the error-handling path (see [error-handling.md](./error-handling.md));
  a `debugPrint` alone is not error handling.
