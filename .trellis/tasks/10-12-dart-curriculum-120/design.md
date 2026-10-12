# Design: Dart 课程 120 课 (K1a)

## 1. Boundaries

### Writable now (this repository)
- `qfli_dart/lib/**`, `qfli_dart/assets/**`, `qfli_dart/test/**`,
  `qfli_dart/pubspec.yaml`, and a Dart-side authored-source directory.

### Pending external-write authorization (do NOT touch until approved)
- `qfli_studio_core/lib/services/studio_profile.dart`
- `qfli_studio_core/lib/pages/home_page.dart`

### Explicitly untouched
- `qfli_studio_core/assets/content/*.json` (no shared-content edits).
- `qfli_studio_core/assets/tutorials/dart.json` — legacy, **not authorized**, not
  on the active path; left as is.
- Other languages' content; `10-09` terminal surfaces; pre-existing dirty files.

## 2. Content storage and delivery (K1a)

120 lessons and 120 examples live in this repository. `qfli_dart` already bundles
its own assets (`pubspec.yaml` `assets:`), so a Dart-only catalog is added there
and surfaced by injecting a `ContentRepository` into the two core tabs.

```
qfli_dart/
  curriculum/                     # authored source of truth (typed Dart)
    dart_lesson.dart              # model
    chapters/…                    # 120 lessons across the §R1.1 chapters
    dart_curriculum.dart          # aggregate list
  tool/
    build_dart_content.dart       # emits the two asset JSONs deterministically
  assets/content/
    dart_tutorials.json           # generated (committed)
    dart_examples.json            # generated (committed)
  lib/
    dart_content_repository.dart  # loads the two assets via rootBundle
  test/
    dart_content_test.dart
    dart_content_run_test.dart
    dart_content_import_test.dart
```

### Content model (authoring-only, in `qfli_dart`)

Only fields the existing detail page can render are authored:

```dart
class DartLesson {
  final String id;              // dart-lesson-001 … dart-lesson-120
  final String chapter;         // per §R1.1
  final String level;           // beginner | intermediate | advanced
  final String title;
  final String summary;
  final List<String> concepts;
  final String explain;         // unique Chinese prose
  final String objective;
  final List<String> prerequisites; // incl. engine requirement note when needed
  final List<String> pitfalls;
  final String code;            // full, runnable, multi-line, self-contained
  final String output;          // exact stdout
  final List<Exercise> exercises;
  final String exampleTitle;    // paired example (may reuse `code`)
  final String exampleSummary;
}
```

Compatibility is stated **in `explain`** (optionally echoed in
`prerequisites`/`pitfalls`), because the parser has no `engine` field and the
page only renders `objective`/`prerequisites`/`explain`/`code`/`output`/
`pitfalls`/`tasks`. No `engine` or `stdinFixture` JSON key is emitted.

All 120 counted programs are self-contained: no real stdin and no network. IO
lessons create their own temporary files with fixed content and clean them up in
`finally`. A lesson may *explain* stdin as a topic, in which case it documents the
real `input.txt` preparation step; verification supplies input through the real
runner mechanism, never a fabricated `inputFixtures` field.

### Generated JSON (parsed by the existing core parser)

`dart_tutorials.json` uses the shape `ContentCatalog.fromJson` already accepts:
```json
{ "schemaVersion": 1, "kind": "tutorials", "updatedAt": "…",
  "entries": [ { "id": "...", "language": "dart", "type": "dart",
    "locale": "zh-CN", "level": "...", "title": "...", "summary": "...",
    "concepts": ["..."], "source": "<existing repo source>",
    "license": "<existing repo license>", "updatedAt": "…",
    "lessons": [ { "id": "...-lesson", "title": "...", "summary": "...",
      "concepts": ["..."], "explain": "...", "code": "...", "output": "...",
      "objective": "...", "prerequisites": ["..."], "pitfalls": ["..."],
      "exercises": [ {"prompt":"...","hint":"...","answer":"..."} ] } ] } ] }
```
`dart_examples.json` is the same envelope with real `code`/`expectedOutput` and
`sourceLessonId` linking to the lesson. No `inputFixtures` is emitted (it is dead
data today). `source`/`license` copy the **existing** values used by current Dart
entries; no new license is introduced.

## 3. The repository (Dart-only)

`lib/dart_content_repository.dart`:
```dart
class DartContentRepository implements ContentRepository {
  DartContentRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  static const tutorialAsset = 'packages/qfli_dart/assets/content/dart_tutorials.json';
  static const exampleAsset  = 'packages/qfli_dart/assets/content/dart_examples.json';
  // load(): read both assets via _bundle, delegate to ContentCatalog.fromJson,
  // cache the parsed catalog; tutorials()/examples() apply ContentFilter.
}
```
It reuses `ContentCatalog.fromJson`, `ContentFilter`, and the existing models —
no parser change.

## 4. Exact 2-file core seam (K1a)

One optional factory, passed at the two tab call sites.

### 4.1 `qfli_studio_core/lib/services/studio_profile.dart`
- Add import: `import '../content/content_repository.dart';`
- Add constructor parameter (default null) and field:
```dart
/// Product-owned offline content source. Null keeps the shared catalog.
final ContentRepository Function()? contentRepositoryFactory;
```
No other change. Null keeps every existing product's behavior.

### 4.2 `qfli_studio_core/lib/pages/home_page.dart`
Pass the factory result into both offline tabs (two one-line additions):
```dart
LocalTutorialsTab(
  …,
  repository: StudioProfile.current?.contentRepositoryFactory?.call(),
)
ExampleCodeTab(
  …,
  repository: StudioProfile.current?.contentRepositoryFactory?.call(),
)
```
Both tabs already accept an optional `repository` (`local_content_pages.dart:27`,
`:110`), so no tab change is required.

### 4.3 `qfli_dart/lib/main.dart`
```dart
contentRepositoryFactory: () => DartContentRepository(),
```

Total core diff: one field + one import in `studio_profile.dart`; two `repository:`
arguments in `home_page.dart`. Additive, Dart-scoped, null-safe.

## 5. Data flow

```
curriculum/*.dart (120 lessons)
  → tool/build_dart_content.dart
     → assets/content/dart_{tutorials,examples}.json
        → DartContentRepository (rootBundle)
           → ContentCatalog.fromJson (existing)
              → LocalContentAdapter (existing)
                 → LocalTutorialsTab / ExampleCodeTab (existing UI, now repository-injected)
                    → CodeSnippet → CodeImportService / DartProgramRunner (existing)
```

## 6. Runtime compatibility (R3)

- No change to `main.dart`'s `runtimeKind`/`runtimeStatus`; the adapter already
  projects the live profile runtime.
- Dart 3 / async / streams / isolates / IO lessons state the official-SDK
  requirement **inside `explain`** (the only reliable rendered surface for engine
  notes; there is no `engine` parser field).
- Host SDK: all 240 artifacts compile+execute+diff. Device SDK: separate gate.
- CodeSnippet's inline Run is Java-only; Dart has no inline Run. The acceptance
  path is catalog → detail → import → editor Run.

## 7. Tradeoffs and rollback

- Tradeoff: the two core edits are unavoidable for the app to show a Dart-only
  catalog without editing shared content; they are minimal and null-safe.
- Rollback: remove `contentRepositoryFactory:` from `main.dart`; remove the field
  and the two `repository:` arguments → app reverts to the shared catalog. Authored
  content and tests remain valid.
- Determinism: the generator sorts by id and writes stable JSON; a test asserts
  byte-identical re-generation.

## 8. Verification strategy

- `dart_content_test.dart` — 120/120, unique ids/titles, 1:1 pairing, complete
  fields, no placeholder markers, multi-line structure, near-duplicate guard,
  one Hello-World, level coverage, license equals existing value.
- `dart_content_run_test.dart` — compile+execute all 240 with the host SDK; stdout
  diff; self-contained programs (no stdin/network); IO via temp files with cleanup.
  Host SDK absence is an explicit environment skip, not a pass.
- `dart_content_import_test.dart` — catalog → detail → import to editor/project →
  editor Run (no inline detail Run; CodeSnippet's Run is Java-only).
- `flutter analyze --no-pub` + `flutter test --no-pub` in `qfli_dart`; core tests
  if the seam lands.
