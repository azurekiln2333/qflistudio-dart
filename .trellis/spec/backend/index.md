# Backend Development Guidelines

> Runtime, toolchain, content, and platform conventions for `qfli_dart`.

---

## Overview

`qfli_dart` is an **offline Flutter app**, not a client/server backend. There is
no HTTP layer, no database, and no logging framework. "Backend" here means the
Dart runtime, SDK toolchain, process runner, generated content, and platform
packaging that live outside the widget tree. The shared UI/editor/terminal core
is the sibling package `../qfli_studio_core`.

---

## Guidelines Index

| Guide | Description | Status |
|-------|-------------|--------|
| [Directory Structure](./directory-structure.md) | Where runtime/toolchain/content code lives | Documented |
| [Data & Storage](./database-guidelines.md) | No DB: JSON files under the storage dir, serialized/atomic writes | Documented |
| [Error Handling](./error-handling.md) | Result objects, narrow catches, never fake success | Documented |
| [Quality Guidelines](./quality-guidelines.md) | Analyze/test gates, forbidden and required patterns | Documented |
| [Logging Guidelines](./logging-guidelines.md) | No logging package; `debugPrint` / `developer.log` | Documented |
| [Native Dart Runtime](./dart-native-runtime.md) | Official Android/desktop VM, SDK packaging and Kernel compilation | Android and desktop implemented; iOS native port pending |

## Pre-Development Checklist

- Read [Native Dart Runtime](./dart-native-runtime.md) before changing
  execution, compilation, or platform packaging.
- Read [Data & Storage](./database-guidelines.md) before adding any persisted
  state (there is no database; use a JSON file under the storage directory).
- Read [Error Handling](./error-handling.md) before touching a run/compile path:
  a failure must never be reported as success.
- Keep all runtime/product policy in `lib/main.dart`'s `dartProfile` and the
  capability gate `NativeDartToolchain.supported`, not scattered in widgets.

## Quality Check

- Run `flutter analyze --no-pub` and `flutter test --no-pub`; both must be clean.
- Runtime claims require real execution, not mocks: the SDK runner and the
  curriculum verifier execute programs and diff output.
- Treat target-device execution as a separate, explicitly-reported gate from
  host tests.
