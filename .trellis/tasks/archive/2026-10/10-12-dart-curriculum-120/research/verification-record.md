# Verification Record — Dart 120-lesson curriculum

Owner: integration pi (w7:p2). All numbers are from commands run in
`D:/MyNewProjects/qfli_dart` on the Windows host with Dart SDK 3.11.5.

## Authored content

- Lessons: 120 (`curriculum/chapters/*.dart`, 14 chapters).
- Examples: 120 (generated 1:1 with `sourceLessonId`).
- Per-chapter: basics 10, control 8, collections 10, nullsafety 6, oop 12,
  generics 8, exceptions 6, dart3 12, async 10, streams 8, isolates 6, io 8,
  json 6, engineering 10 = **120**.

## Generated assets

`dart run tool/build_dart_content.dart` → "Emitted 120 Dart lessons and 120 Dart
examples." Assets:
- `assets/content/dart_tutorials.json` (~304 KB, 120 entries)
- `assets/content/dart_examples.json` (~130 KB, 120 entries)

## Real execution gate (host SDK, not skipped)

`dart run tool/verify_dart_content.dart` → **checked=120 failures=0**
(every lesson compiles and runs; stdout compared byte-exactly, LF-normalized).

`flutter test --no-pub test/dart_content_run_test.dart` → **All tests passed**
(all 120 lessons + 120 examples executed through the real `DartProgramRunner`).

## Integrity gate

`flutter test --no-pub test/dart_content_test.dart` → **All tests passed**
(18 assertions: 120/120 counts, unique ids/titles, 1:1 pairing, complete fields,
no placeholder markers, multi-line `main`, normalized code uniqueness per type,
distinct `explain`, distinct normalized summaries, one Hello-World, level
coverage, existing license string, adapter projection).

## Import integration

`flutter test --no-pub test/dart_content_import_test.dart` → **All tests passed**
(catalog example → `CodeImportService.importIntoProject` writes real file →
`DartProgramRunner` runs it; all 120 examples write their exact source).

## Widget evidence

`flutter test --no-pub test/dart_content_widget_test.dart` → **All tests passed**
(mounted real `LocalTutorialsTab`/`ExampleCodeTab` with the Dart-owned repository
and real assets; asserts the 120-lesson/120-example catalogs and the rendered
lesson detail fields objective/explain/pitfalls).

## dart_eval portable-engine branch

`flutter test --no-pub test/dart_content_dart_eval_test.dart` → **All tests
passed**: `dart_eval: ran=43 of 120 lessons; 77 SDK-required`.

The 43-lesson list is the empirically observed dart_eval 0.8.5 subset, produced
by running every lesson through the dart_eval compile+execute path. The other 77
need the official SDK. dart_eval's gaps observed include: `runtimeType` printing
`Type`, `int.parse` casts, `Set.toSet()`, spread/collection-for, `Map.update`,
`continue`, operator overloads, value-equality in `Set`, and user-exception
messages. No interpreter change was made; the branch is reported honestly.

## Static analysis

`flutter analyze --no-pub lib tool test curriculum` → **No issues found**.

## Compatibility labeling (per-lesson, in the UI)

Engine compatibility is a first-class, per-lesson property:

- Shared source of truth: `DartCurriculum.dartEvalVerifiedIds` (43 lessons,
  empirically verified on dart_eval 0.8.5) + `engineNote(id)` / `engineTag(id)`
  in `curriculum/dart_chapters.dart`.
- The generator projects the requirement into the **real assets**: every lesson's
  `explain` ends with `engineNote`, and every paired example's `summary` ends with
  `engineTag`. These are the fields the detail page renders.
- `test/dart_content_test.dart` asserts, per lesson and example from the real
  assets, that the visible text matches the shared whitelist: the 43 verified
  lessons say dart_eval-capable; the other 77 say "需要官方 Dart SDK".

`dart run tool/audit_compat.dart` → advanced lessons: 42, labeled: 42, unlabeled: 0.

Cross-check: `test/dart_content_test.dart` also asserts that no dart_eval-verified
lesson's authored prose contradicts its engine note (the appended note is stripped
before the check). Contradictions found and fixed for lessons 001, 002, 061, 074
(their inline "需要官方 Dart SDK" was neutralized).

## Known gates / limitations

- **dart_eval branch**: separately exercised — `test/dart_content_dart_eval_test.dart`
  verifies 43/120 lessons on dart_eval 0.8.5; the remaining 77 are reported as
  official-SDK-required (see above).
- **Android device / official SDK VM**: no device available; the official-SDK
  branch is exercised on the host Windows SDK VM via `DartProgramRunner`. The
  Android VM path is reported as a device gate, not counted as passed.
- Dart 3 lessons (control 013 switch-expression, exceptions 059 sealed/pattern)
  and all async/streams/isolates/io lessons state the official-SDK requirement
  in `explain`; `tool/audit_compat.dart` reports unlabeled: 0.

## Full test suite

`flutter test --no-pub` → **All tests passed (62 tests)**, including content
integrity, per-lesson UI engine labeling, real-SDK run of all 240 programs,
import integration, widget render, and the dart_eval branch (43/120 verified).

## Core seam (additive, coordinated)

- `qfli_studio_core/lib/services/studio_profile.dart`: added
  `contentRepositoryFactory` field + constructor param (null default).
- `qfli_studio_core/lib/pages/home_page.dart`: passed the factory result into the
  two offline tabs. No shared content JSON touched; no other language affected.
