# Dart Curriculum Content Contract

## 1. Scope / Trigger

Use this when editing the 120-lesson Dart curriculum, its generator, the
Dart-owned content repository, or the content test gates. The app is offline and
renders the Dart app's own assets; it does not read the shared core catalog.

## 2. Files and ownership

- Authored source of truth: `qfli_dart/curriculum/`
  - `dart_lesson.dart` — `DartLesson` model (only page-renderable fields).
  - `dart_chapters.dart` — 14 chapters + fixed per-chapter `counts` (sum 120).
  - `dart_curriculum.dart` — concatenates the 14 chapter lists.
  - `chapters/<key>.dart` — one file per chapter, exporting
    `const List<DartLesson> <listName>`. Edit only the chapter you own.
- Generator: `tool/build_dart_content.dart` (deterministic, id-sorted).
- Assets: `assets/content/dart_tutorials.json`, `assets/content/dart_examples.json`.
- Repository: `lib/dart_content_repository.dart` (reads the two assets).
- Injection: `lib/main.dart` → `StudioProfile.contentRepositoryFactory`.

## 3. Contracts

- Exactly 120 lessons and 120 examples. Per-chapter counts must equal
  `DartCurriculum.counts` and total 120.
- Lesson ids are `dart-lesson-NNN` (001..120), ascending; the example id is the
  same number as `dart-example-NNN`; `sourceLessonId` links example → lesson.
- Every lesson has non-empty: `title`, `summary`, `concepts`, `explain`,
  `objective`, `pitfalls`, `code`, `output`, `exercises` (≥1, with
  prompt/hint/answer), `exampleTitle`, `exampleSummary`.
- `explain` must be unique per lesson; normalized `code` bodies unique within
  lessons and (separately) within examples; normalized `summary` unique per type.
- `code` is a complete, self-contained `main` program: **no stdin, no network**.
  IO lessons create their own temporary files and clean them up.
- `output` must equal real stdout on the official Dart SDK (LF-normalized).
- A lesson and its own paired example MAY share code; uniqueness is per type.
- **Engine compatibility is stated in `explain`** (optionally echoed in
  `pitfalls`). The detail page renders `explain` but no `runtime` field, so any
  other location is invisible.
- `source`/`license` mirror the existing bundled Dart values; do not introduce a
  new license.

## 4. Validation

Run from `qfli_dart`:

```powershell
dart run tool/build_dart_content.dart          # must emit 120 / 120
dart run tool/verify_dart_content.dart          # checked=120 failures=0
dart run tool/audit_compat.dart                 # unlabeled: 0
flutter analyze --no-pub lib tool test curriculum
flutter test --no-pub
```

`tool/verify_dart_content.dart` compiles and **actually runs** each lesson on the
host SDK and diffs stdout. A missing host SDK is a hard failure, never a skip.

## 5. Test gates

- `test/dart_content_test.dart` — structure, uniqueness, adapter projection.
- `test/dart_content_run_test.dart` — real compile/run/output for all 240.
- `test/dart_content_import_test.dart` — import → editor Run path.
- `test/dart_content_widget_test.dart` — real pages render the Dart catalog.
- `test/dart_content_dart_eval_test.dart` — dart_eval portable-engine branch;
  asserts the curated subset (`_dartEvalPortableIds`, empirically verified) and
  reports the rest as official-SDK-required. Never guess the subset by regex.

## 6. Wrong vs correct

Wrong: emit an `engine` JSON key (parser drops it; user cannot see it).
Correct: state the official-SDK requirement in `explain`.

Wrong: read from stdin and ship a fabricated `inputFixtures` field.
Correct: keep counted programs self-contained; explain stdin with the real
`input.txt` step if the topic requires it.

Wrong: pad lesson counts by copying a template and changing numbers.
Correct: each lesson is an independent knowledge point with its own prose and
code.
