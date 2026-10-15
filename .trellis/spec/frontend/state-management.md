# State Management

> How state is held and shared in this Flutter app.

---

## Overview

State management is **plain Flutter**: `StatefulWidget` local state with
`setState`, plus `ChangeNotifier` stores from the shared core for app-wide data.
There is **no** Redux/Bloc/Riverpod/Provider package in this project (verified
absent from `pubspec.yaml`). The core's `ProjectStore`, `ExampleCodeStore`,
`AuthStore`, and `SettingsStore` are `ChangeNotifier`s created in `lib/main.dart`
and passed down by constructor.

---

## State Categories

| Category | Held by | Example |
| --- | --- | --- |
| Ephemeral widget state | `State<T>` fields + `setState` | editor buffer, `_busy`, `_diagnostics`, `_output` in `lib/dart_tools_page.dart` |
| App-wide shared data | core `ChangeNotifier` stores | `ProjectStore`, `ExampleCodeStore` |
| Product/runtime config | `StudioProfile.current` | `dartProfile` in `lib/main.dart` |
| Bundled assets | repository cache | `DartContentRepository._catalogFuture` |
| Durable user state | JSON files under the storage dir | `projects.json`, `examples.json` (see [database-guidelines.md](../backend/database-guidelines.md)) |

---

## When to Use Global State

Promote state to a shared store only when it is (a) read by more than one
screen, or (b) backed by persistence. In this app that is the project registry
and custom examples — both already owned by core stores.

Keep everything else local to the widget:
- The Dart Tools page keeps its source buffer, selected file, diagnostics,
  output, and busy flag as `_XState` fields. It does not push them into a global
  store.
- If two Dart screens ever need the same data, that is the signal to add a
  `ChangeNotifier` service, not to duplicate fields.

---

## ChangeNotifier Store Pattern

The shared stores follow a consistent, safe pattern worth copying for any new
Dart-side store:

- Extend `ChangeNotifier`; expose read-only views (`items` getter).
- **Serialize writes** through a single future chain so concurrent mutations do
  not clobber each other:
  ```dart
  // core/lib/services/example_code_store.dart (_updateCustom)
  final previous = _writes;
  final current = previous == null ? write() : previous.catchError((Object _) {}).then((_) => write());
  _writes = current;
  await current;
  ```
- **Commit in-memory state only after the write succeeds**, then
  `notifyListeners()`.
- **Guard disposal**: a `bool _disposed` is checked after every `await`, and
  `dispose()` sets it; writes throw `StateError` if the store is disposed.
- **Notify explicitly**; there is no implicit dependency tracking. Widgets
  subscribe with `addListener` in `initState` and remove in `dispose`.

Consuming a store in a widget:
```dart
// lib/dart_tools_page.dart
widget.store.addListener(_onProjectsChanged);   // initState
widget.store.projects.where((item) => !item.isCloud);  // read in build
widget.store.removeListener(_onProjectsChanged); // dispose
```

---

## Server State

There is **no server state** in this product. `dartProfile` sets
`isOffline: true`, so no network state is fetched or cached in the Dart app. The
core contains network-capable services for other products; they are not on this
app's path and must not be wired in.

---

## Derived State

Derive with getters and locals; do not store a second copy:
- `bool get _canImport => widget.store != null && ...` (core `CodeSnippet`).
- `bool get _dirty` is tracked from a controller listener, not recomputed by
  diffing on every frame.
- Filtered lists are computed in `build`
  (`widget.store.projects.where((item) => !item.isCloud).toList()`).

---

## Common Mistakes

- **Adding a state-management package.** Out of character; use `State<T>` +
  `ChangeNotifier`.
- **Global state for a single screen.** Keep it in `_XState`.
- **Mutating a store directly.** Go through its methods so writes serialize and
  `notifyListeners` fires.
- **Reading a store in `build` without listening.** The UI will not rebuild;
  `addListener` in `initState`.
- **Touching state after `await` without `mounted`/generation checks** — see
  [hook-guidelines.md](./hook-guidelines.md).
- **Storing derived values.** They drift from their source; use getters.
- **Wiring a network-backed core service into the offline Dart app.** `isOffline`
  is a contract, not a suggestion.
