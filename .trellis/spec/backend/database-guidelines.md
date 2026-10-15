# Data, Storage, and Configuration (no database)

> How this project persists data. There is **no database, no ORM, and no SQL**
> in `qfli_dart`.

---

## Overview

`QFLIDartWing` is an offline app. All durable state is stored as **JSON files
under the app-writable storage directory**, or as **project files on disk** the
user chose. There is no server, no `drift`/`sqflite`/ORM, no migration
framework, and no remote sync path in this product.

Verification: `grep -R "sqflite\|drift\|shared_preferences\|sqflite" lib test`
returns nothing; `pubspec.yaml` declares no database or key-value package.

### The actual persistence layers

| Layer | Implementation | Owner |
| --- | --- | --- |
| Content assets | Bundled JSON read via `rootBundle` | this repo (`lib/dart_content_repository.dart`) |
| Project registry | `projects.json` (File + JSON) | shared core `store/project_store.dart` |
| Custom examples | `examples.json` (File + JSON) | shared core `services/example_code_store.dart` |
| Project source files | `.dart` / `pubspec.yaml` on disk | user project directory |

There is **no `shared_preferences`** in this repository. Do not introduce it for
product state: the established pattern is a JSON document in the storage
directory, resolved through `AppPaths.storageDirectory()`.

---

## Where the storage root comes from

The shared core resolves the writable root and probes it for real writability
(candidate order: app support → documents → external storage → env vars →
cwd). Read `../qfli_studio_core/lib/services/app_paths.dart`
(`AppPaths.storageDirectory`, `AppPaths._isWritable`) before adding a new
persisted file. Never hard-code a path or assume `path_provider` succeeds on
OHOS/Android.

```dart
// lib/dart_content_repository.dart — bundled assets, not the storage dir.
static const String tutorialAsset =
    'packages/qfli_dart/assets/content/dart_tutorials.json';
// The repository also tries the un-prefixed key for package self-tests.
static const List<String> _tutorialKeys = <String>[
  tutorialAsset,
  'assets/content/dart_tutorials.json',
];
```

---

## Query / read patterns

- **Read files lazily and tolerate absence.** A missing file is normal
  first-run behavior, not an error:
  ```dart
  // core/services/example_code_store.dart
  if (!await file.exists() || _disposed) return;
  ```
- **Decode with explicit shape checks, then skip bad records** instead of
  throwing away the whole document:
  ```dart
  final data = jsonDecode(await file.readAsString());
  if (data is! Map || data['examples'] is! List) return;
  for (final raw in data['examples'] as List) {
    if (raw is! Map) continue;
    final example = _fromJson(Map<String, dynamic>.from(raw));
    if (example != null) loaded[example.id] = example;
  }
  ```
  Catch `FormatException` and `TypeError` and treat them as "empty".
- **Offload large reads to an isolate** with `compute` when the file can be
  large, so the UI isolate is not blocked:
  ```dart
  // core/store/project_store.dart
  final result = await compute(_readProjectRegistry, _storage!.path);
  ```
- **Bundle-read content uses an ordered key fallback** and aggregates failures
  into one exception (`DartContentRepository._loadString`), never a bare
  `rootBundle.loadString` with no fallback.

---

## Write / mutation patterns

- **Serialize writes through a single-slot future chain** so rapid edits cannot
  interleave and lose data. Each new write awaits the previous one:
  ```dart
  // core/store/project_store.dart (_persist)
  final previous = _writes;
  final pending = previous == null ? write() : previous.then((_) => write());
  _writes = pending.catchError((Object _) {});
  return pending; // callers see the real error; later writes still proceed
  ```
- **Write atomically for multi-record documents**: write a temp file on the
  same volume with `flush: true`, then `rename` into place. See
  `_persist` in `core/store/project_store.dart` (`.qfli-project-registry-` temp
  dir → `registry.json` → `rename(file.path)`).
- **Commit in-memory state only after the write succeeds.** Mutate a copy, write
  it, then swap it in and `notifyListeners()`:
  ```dart
  // core/services/example_code_store.dart (_updateCustom)
  final updated = Map<String, ExampleCode>.from(_custom);
  update(updated);
  await file.writeAsString(encoded, flush: true);
  if (_disposed) return;
  _custom..clear()..addAll(updated);
  notifyListeners();
  ```
- **Always `create(recursive: true)` the parent** before writing
  (`file.parent.create(recursive: true)`), and pass `flush: true` on durable
  writes.
- **Roll back optimistic registration on failure.** `ProjectStore._persist`
  takes an `onFailure` callback that removes the pending project and bumps the
  revision. Follow this when a write backs an in-memory registration.

---

## Document shape and versioning

Persisted JSON documents carry a version so a schema change can migrate:

```dart
// core/services/example_code_store.dart
static const int contentVersion = 2;
// document: { schemaVersion: 1, contentVersion: contentVersion, examples: [...] }
```

- Bump the version and write a one-time migration on load; make the migration
  **idempotent** (up-to-date version is a no-op).
- Generated content assets use additive `schemaVersion`/`kind` envelopes and
  are parsed by the core `ContentCatalog.fromJson` — do not invent a parallel
  parser (see [dart-curriculum.md](../frontend/dart-curriculum.md)).

---

## Common Mistakes

- **Adding a database or `shared_preferences` "for convenience."** Out of
  character with this offline, file-based app; use a JSON document in the
  storage directory.
- **Hard-coding `getApplicationDocumentsDirectory()` or a literal path.**
  Resolve through `AppPaths.storageDirectory()`; OHOS/Android may fail a given
  provider.
- **Writing without serialization.** Concurrent `writeAsString` calls race and
  the last writer wins, dropping the other change.
- **Not using a temp-file rename for multi-record files.** A crash mid-write
  truncates the registry.
- **Treating a `FormatException` as fatal.** Corrupt/absent storage should
  degrade to defaults, not crash startup.
- **Editing `assets/content/dart_*.json` by hand.** It is generated; regenerate
  from `curriculum/**` (see [dart-curriculum.md](../frontend/dart-curriculum.md)).
