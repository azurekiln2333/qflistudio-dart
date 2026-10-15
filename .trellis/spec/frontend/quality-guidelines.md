# Quality Guidelines (Frontend / Flutter)

> Linting, testing, and UI standards for this app.

---

## Overview

Frontend quality is enforced by `flutter analyze` (with `package:flutter_lints`)
and by widget tests. There is **no ESLint/Prettier/lint-staged**; the Dart
equivalents are `dart format` and `flutter analyze`.

```powershell
dart format --output=none --set-exit-if-changed lib test tool curriculum
flutter analyze --no-pub
flutter test --no-pub
```

---

## Forbidden Patterns

- **Re-implementing core UI.** Use the core's editor, terminal, catalog, detail,
  and `CodeSnippet` widgets; do not fork them.
- **Network UI in the offline Dart app.** `dartProfile.isOffline` is true; do not
  surface login/Git/cloud entries (see [state-management.md](./state-management.md)).
- **Hard-coded colors, fonts, or device checks for layout.** Use
  `Theme.of(context)` and `MediaQuery.sizeOf(context)` (see
  [component-guidelines.md](./component-guidelines.md)).
- **`print` in `lib/**`.** Use `debugPrint` for diagnostics
  (see [logging-guidelines.md](../backend/logging-guidelines.md)).
- **Starting async work in `build`.** Use `initState` or a user action.
- **`setState` after `await` without `mounted`/generation guards.**
- **Leaking listeners/subscriptions/controllers.** Release them in `dispose`.
- **Hand-editing generated assets.** Regenerate from `curriculum/**`.

---

## Required Patterns

- `const` constructors where possible; `super.key` on every widget constructor.
- Inject dependencies via constructor; optional ones are nullable and guarded.
- Subscribe to core `ChangeNotifier` stores with `addListener`/`removeListener`.
- Dispose controllers, stream subscriptions, and running programs in `dispose`.
- Provide empty/loading/error states for every async surface.
- Use `tooltip:` on icon-only controls and `SelectableText` for output/errors.
- Keep user-visible strings Chinese and consistent with the rest of the app.

---

## Testing Requirements

- `test/` uses `flutter_test`. Widget tests mount the **real** core pages where
  possible (e.g. `test/dart_content_widget_test.dart` mounts
  `LocalTutorialsTab` / `ExampleCodeTab` with the real repository).
- Set `TestWidgetsFlutterBinding.ensureInitialized()` for widget/binding tests.
- **Set and restore `StudioProfile.current`** in `setUp`/`tearDown` when it
  matters (`test/dart_app_test.dart`).
- Use real temp directories and `tearDown` cleanup for file-backed tests.
- Widget tests must not leave pending Futures; if real asset IO is needed, drain
  it with `tester.runAsync` and replay a synchronously-completing wrapper — the
  pattern in `test/dart_content_widget_test.dart`.
- Assert on rendered text/fields the user can actually see (the detail page
  renders `objective`/`explain`/`pitfalls`, not engine metadata).
- Cover both narrow (≈320px) and wide layouts at large text scale when a surface
  is responsive/scrollable.

---

## Code Review Checklist

- [ ] `flutter analyze --no-pub` is clean.
- [ ] `flutter test --no-pub` passes; new UI has a widget/behavior test.
- [ ] No duplicated core widget; composition used instead.
- [ ] Colors/typography/sizes come from the theme; layout uses `MediaQuery`.
- [ ] Every subscription/controller/program is disposed or cancelled.
- [ ] Async continuations are guarded by `mounted`/generation.
- [ ] Empty, loading, and error states exist; icon-only buttons have tooltips.
- [ ] No network entry points; no `print` in `lib/`; no hand-edited generated JSON.
