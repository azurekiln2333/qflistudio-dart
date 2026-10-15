# Lifecycle and Effects (this project has no Flutter hooks)

> The template name is "Hook Guidelines", but this project uses **no React and no
> `flutter_hooks` package**. The equivalent concept is Flutter's
> `initState` / `dispose` / `didUpdateWidget` + stream subscriptions, plus
> `ChangeNotifier` listeners. This file documents that reality.

---

## Overview

Verified: `grep -R "flutter_hooks\|HookWidget\|useState" lib pubspec.yaml`
returns nothing. There is no hooks library and no hooks convention to follow.
Instead, stateful behavior lives in `State<T>` subclasses.

The pattern the template calls "custom hooks" maps to:

| Hook concept | This project's equivalent |
| --- | --- |
| `useState` | fields on `_XState`, mutated with `setState` |
| `useEffect(() => …, [])` | `initState` (+ call an async method) |
| `useEffect` cleanup | `dispose` / remove listener / cancel subscription |
| `useContext` | `Theme.of(context)` / `StudioLocalizations.of(context)` in `build` |
| `useMemo`/derived | a getter or a local in `build` |
| shared stateful logic | a plain service/helper class, or `ChangeNotifier` |

---

## Custom Logic Patterns

### Subscribe in `initState`, release in `dispose`

```dart
// lib/dart_tools_page.dart
@override
void initState() {
  super.initState();
  widget.store.addListener(_onProjectsChanged);
  _source.addListener(_onSourceChanged);
  _onProjectsChanged();
}

@override
void dispose() {
  _generation++;                              // invalidate in-flight async work
  widget.store.removeListener(_onProjectsChanged);
  unawaited(_stdoutSubscription?.cancel());   // stream subscriptions
  unawaited(_stderrSubscription?.cancel());
  unawaited(_run?.cancel?.call());            // running program
  _source.dispose();                          // controllers
  super.dispose();
}
```

### Invalidate superseded async work with a generation counter

Every `await` can resume after the user moved on. Capture a generation before
the await and compare after:

```dart
final generation = ++_generation;
final files = await _listDartFiles(path);
if (!mounted || generation != _generation) return;
setState(() => _files = files);
```

This is the local substitute for a hook dependency array.

### Serialize "one operation at a time" with a busy guard

```dart
bool _beginOperation() {
  if (!mounted || _busy) return false;
  setState(() { _busy = true; _error = null; });
  return true;
}
void _finishOperation() {
  if (!mounted) return;
  setState(() => _busy = false);
  // re-run work that was requested while busy
  if (_projectsChangedWhileBusy) { _projectsChangedWhileBusy = false; _onProjectsChanged(); }
}
```

### Derive, do not cache

Computed values are getters or locals, not duplicated state
(`bool get _canImport => ...` in core `CodeSnippet`).

### Offload expensive work to an isolate (the "effect" runs off the frame)

```dart
static Future<List<String>> _listDartFiles(String root) => compute(_scanDartFiles, root);
```

---

## Data Fetching

There is **no React Query / SWR**. "Data fetching" is:

- **Bundled assets** loaded once through a repository and cached
  (`DartContentRepository.load` caches `_catalogFuture`). See
  [content-code-import.md](./content-code-import.md).
- **Files/processes** read through a repository or service, initiated from a
  lifecycle method, with `mounted`/generation guards around the `await`.
- **`ChangeNotifier` stores** (core `ProjectStore`, `ExampleCodeStore`) are the
  shared reactive source; widgets subscribe with `addListener` and re-read in
  `build`.

No request is fired from `build`. Effects start in `initState` (or a user
action), never as a side effect of rendering.

---

## Naming Conventions

- Listener handlers: `_onX` (`_onProjectsChanged`, `_onSourceChanged`).
- Async actions: verb-first `_selectProject`, `_loadFile`, `_writeSource`,
  `_execute`.
- Guards: `_beginOperation` / `_finishOperation`; a "changed while busy" flag is
  `_xChangedWhileBusy`.
- State fields are private and lowerCamelCase; controllers/subscriptions are
  nullable and disposed.

---

## Common Mistakes

- **Adding `flutter_hooks`.** Not used in this codebase; stay with `State<T>`.
- **Starting work in `build`.** It re-runs every frame. Use `initState` or a
  user callback.
- **`setState` (or `setState` via a stream listener) after dispose.** Always
  guard with `if (mounted)` and cancel subscriptions in `dispose`.
- **Subscribing without unsubscribing.** A leaked `addListener`/stream
  subscription keeps the widget alive and fires after disposal.
- **No generation/`mounted` guard after `await`.** A slow load overwrites a
  newer selection.
- **Duplicating derived state.** Prefer a getter over a field that can drift.
