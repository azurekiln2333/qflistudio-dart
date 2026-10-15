# Frontend Development Guidelines

> Flutter UI conventions for `qfli_dart`.

---

## Overview

`qfli_dart` composes the shared Material 3 UI from `../qfli_studio_core` and adds
only Dart-specific screens and wiring. This is Flutter, not React: there are no
JSX props and no hooks. State uses `State<T>` + `setState` and core
`ChangeNotifier` stores; "effects" are `initState`/`dispose`; "validation" is
explicit Dart null-safe JSON parsing.

---

## Guidelines Index

| Guide | Description | Status |
|-------|-------------|--------|
| [Directory Structure](./directory-structure.md) | Where Flutter pages/assets live, core vs repo ownership | Documented |
| [Component Guidelines](./component-guidelines.md) | Widget structure, props, Material 3 styling, accessibility | Documented |
| [Lifecycle & Effects](./hook-guidelines.md) | No hooks; `initState`/`dispose`, subscriptions, generation guards | Documented |
| [State Management](./state-management.md) | `State<T>` + `ChangeNotifier`; local vs shared; offline contract | Documented |
| [Quality Guidelines](./quality-guidelines.md) | Lints, widget tests, forbidden/required patterns | Documented |
| [Type Safety](./type-safety.md) | Dart null safety, typed models, explicit JSON parsing | Documented |
| [Dart Tools Contract](./dart-tools.md) | Project files, compiler actions, async lifecycle, and verification | Documented |
| [Dart Curriculum Content](./dart-curriculum.md) | 120-lesson authored source, generator, repository, and content gates | Documented |
| [Content Code Imports](./content-code-import.md) | Catalogs, persisted examples, file import, and editor navigation | Documented |

## Pre-Development Checklist

- For Dart tools, read [Dart Tools Contract](./dart-tools.md) before changing
  the page or its integration with the formatter, diagnostics, compiler, and
  runner.
- For curriculum content, read [Dart Curriculum Content](./dart-curriculum.md)
  before editing `curriculum/`, the generator, the repository, or the content
  tests.
- For tutorial and example changes, read
  [Content Code Imports](./content-code-import.md).
- Before adding a page, confirm the core does not already provide it
  ([Directory Structure](./directory-structure.md)).
- Before changing any widget's async behavior, read
  [Lifecycle & Effects](./hook-guidelines.md): guard `setState` with
  `mounted`/generation counters and release every subscription in `dispose`.

## Quality Check

- Run `dart format`, `flutter analyze --no-pub`, and `flutter test --no-pub`.
- Follow [Dart Tools Contract](./dart-tools.md) for verification commands; treat
  target-device execution as a separate gate from host tests and package builds.
