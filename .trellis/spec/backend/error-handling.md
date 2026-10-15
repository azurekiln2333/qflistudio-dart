# Error Handling

> How this offline Dart app surfaces and contains failures.

---

## Overview

There is no HTTP error envelope. Failures come from three sources:

1. **Process/IO errors** — SDK process spawn, file read/write, platform channel.
2. **User program errors** — a compiled program throws, exits non-zero, or has
   syntax errors.
3. **Environment gaps** — no SDK found, unsupported platform, missing dependency
   resolution.

The governing rule is: **never fake success.** A failed run must carry a
non-zero exit code and a real message on `stderr`; a missing capability must say
so explicitly rather than silently doing nothing. This is asserted directly by
`test/dart_app_test.dart` (`语法错误返回诊断而不伪造成功`,
`别的语言文件交回内核`) and `test/native_dart_toolchain_test.dart`
(`compile errors fail without producing a runnable artifact`).

---

## Error Types and When They Are Used

Use the standard Dart exception that matches the *cause*, not a custom wrapper,
so the message stays specific:

| Exception | Raised for | Example |
| --- | --- | --- |
| `ArgumentError.value` | Bad argument, e.g. entry outside the project | `lib/dart_project_sources.dart` — `'入口文件不在项目目录内'` |
| `FileSystemException` | Missing file/dir, IO failure | `lib/dart_project_sources.dart` — `FileSystemException('找不到入口文件', entry)` |
| `StateError` | Valid state but operation impossible now | `lib/native_dart_toolchain.dart` — `StateError('没有找到 Dart SDK，请配置本地 SDK。')`, `StateError('项目依赖尚未解析，…')` |
| `FormatException` | Malformed structured data | `lib/android_dart_sdk.dart` — `FormatException('Invalid Android Dart SDK path: $key')` |
| `ProcessException` / `PlatformException` | Process spawn or channel failure | caught in `lib/dart_runner.dart` |

Do **not** define a parallel exception hierarchy for these; the core already
has `ContentAssetException` for content loading, and the runner returns a
`ProgramRunResult` instead of throwing to its caller.

---

## Error Handling Patterns

### 1. A user-facing runner returns a result, it does not throw

`DartProgramRunner.run` (`lib/dart_runner.dart`) catches every anticipated
failure and converts it into a `ProgramRunResult` with empty stdout, the message
on stderr, and `kProgramNotRunExitCode`:

```dart
on ArgumentError catch (error) {
  return _failed('运行 ${p.basename(entryFile)}', error.message.toString());
} on FileSystemException catch (error) {
  return _failed('运行 ${p.basename(entryFile)}', error.message);
} on FormatException catch (error) {
  return _failed('运行 ${p.basename(entryFile)}', error.toString());
} on ProcessException catch (error) {
  return _failed('运行 ${p.basename(entryFile)}', error.message);
} on StateError catch (error) {
  return _failed('运行 ${p.basename(entryFile)}', error.message);
} on PlatformException catch (error) {
  return _failed('运行 ${p.basename(entryFile)}', error.message ?? error.code);
}
```

A `null` return is reserved for "not my language" (e.g. `main.py`), which lets
the core fall back — see `test/dart_app_test.dart` (`别的语言文件交回内核`).

### 2. Catch the narrowest type that you can actually handle

Catch specific exception types, in order, and give each a specific action. In
`lib/dart_runner.dart`'s terminal hook and `lib/native_dart_toolchain.dart`, the
catch clauses map directly to the message the user needs. `on Object catch` is
only used as a last-resort boundary where any failure must become a streamed
error (inside the isolate `_execute`, or around `compute`).

### 3. Platform gaps are explicit, never silent

```dart
// lib/dart_runner.dart — dartTerminalDelegate
if (!NativeDartToolchain.supported) {
  backend.error(
    'dart: 当前平台没有官方 Dart SDK，无法执行该命令（便携运行时只支持编辑器运行按钮）。',
  );
  return true; // claimed — the sandbox must not print its own generic message
}
```

Distinguish "claimed and failed with a real reason" (`return true` after
`backend.error`) from "not mine, defer" (`return false`).

### 4. Escaping and containment are checked before use

Before starting a process or compiling, verify the entry is inside the project
root, using resolved paths (symlinks included):

```dart
// lib/native_dart_toolchain.dart (_entry)
final root = await Directory(projectPath).resolveSymbolicLinks();
final entry = await File(entryFile).resolveSymbolicLinks();
if (!p.isWithin(root, entry)) {
  throw ArgumentError.value(entryFile, 'entryFile', '入口文件不在项目目录内');
}
```

### 5. Cleanup in `finally`, and honor cancellation

Temporary directories and processes are released in `finally`
(`lib/native_dart_toolchain.dart` `compileKernel`, `_PackageConfiguration.dispose`),
and a cancelled run reports exit code `130`
(`test/native_dart_toolchain_test.dart` — `an active native program can be stopped`).

### 6. Guard disposed state after every await

Long operations re-check `_disposed` / `mounted` / a generation counter before
touching state:
```dart
// core/services/example_code_store.dart
if (_disposed) return;
// lib/dart_tools_page.dart
if (!mounted || generation != _generation) return;
```

---

## Error Messages

- Messages are **user-facing and in Chinese**, matching the rest of the app
  (`'没有找到 Dart SDK，请配置本地 SDK。'`, `'入口文件不在项目目录内'`).
- Include the **specific missing thing**, not a generic "error": prefer
  `FileSystemException('找不到入口文件', entry)` over `'failed'`.
- For SDK errors, surface the captured `stderr`/`stdout` text
  (`lib/native_dart_toolchain.dart` `compileKernel`: `throw StateError(errors.isNotEmpty ? errors : messages)`).

---

## Common Mistakes

- **Returning `null` for a real failure.** `null` means "not this language";
  a genuine Dart failure must be a `ProgramRunResult` with a non-zero exit code.
- **Swallowing an error and printing success.** Never `catch (_) {}` around a
  run and then report exit code 0.
- **Catching `Object`/`Error` broadly as the first clause.** It hides programming
  bugs; reserve broad catches for isolate/`compute` boundaries.
- **`ArgumentError` message losing the value.** Pass the offending value and a
  name, as in `ArgumentError.value(entryFile, 'entryFile', ...)`.
- **Not rechecking `mounted`/`_disposed` after `await`.** This throws
  `setState() called after dispose` or writes to a closed sink.
- **Hard-coding English or raw exception `toString()` in UI.** Translate to the
  project's Chinese, user-readable message.
