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

All validation commands in this guide run only on GitHub-hosted runners.

### Shared Core UI contract after the 2026-11-28 migration

- Keep real Dart template execution and exact stdout `Hello, QFLIStudioN!`,
  empty stderr, successful exit and the runtime title assertion.
- Assert the four named Home/Tools/Content/Profile destinations before selecting
  controls by their label identity. Profile is index 3. Preserve every offline
  login, account, network, Git and AI absence assertion after navigation.
- Offline Content mounts the real `TutorialCenterPage` with
  `DartContentRepository`. Reach both tutorial and example sections, drain real
  asset/storage IO with bounded `runAsync` and pump cycles, and assert actual
  bundled titles. The community page must remain absent after switching.
- A fitting editor layout exposes Settings through its quick-bar tooltip/icon.
  Dismiss the popup, activate the visible control and assert the real
  `SettingsPage(showAi: false)` plus local settings and forbidden AI entries.
- Hosted phone tests still call the real `app.main()` and assert its first
  loading frame. Set only `QfliApp.formFactor` to `AppFormFactor.phone`, retaining
  the existing state, stores and readiness notifier. Preserve frame-deferral,
  progress, readiness and exact phone-shell checks. Separately assert that real
  Linux with no override resolves to `LargeScreenWorkbench`.

These contracts follow Core's `core-consumers.md` section 9. Changing a
`TargetPlatformVariant` does not change the host OS. Do not remove assertions,
skip failing behavior or tolerate framework errors to migrate selectors.

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
