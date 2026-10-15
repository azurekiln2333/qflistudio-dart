# Curriculum content audit — 120 tutorials + 120 examples

Owner: `dart-content` (Herdr pane `w7:p5`).
Task: `.trellis/tasks/10-15-dart-store-release`.
Scope audited: `curriculum/**`, `assets/content/dart_{tutorials,examples}.json`,
`tool/{build_dart_content,verify_dart_content,audit_compat}.dart`,
`lib/dart_content_repository.dart`, `test/dart_content*`.
Date: 2026-10-15. Host: Windows, Dart SDK 3.11.5 (stable).

## 0. Environment / identity

- `Get-Location` = `D:/MyNewProjects/qfli_dart`.
- `git rev-parse --show-toplevel` = `D:/MyNewProjects/qfli_dart`.
- Herdr pane `w7:p5` (`$env:HERDR_PANE_ID`).
- Baseline `git status --porcelain`: only
  `?? .trellis/.runtime/sessions/codex-dart-release-20261015.json` (pre-existing
  Trellis scratch, untouched).

## 1. Verdict

**No placeholder content exists. The 120 authored lessons + 120 paired examples
are real, runnable, and machine-verified. Per the task instruction, existing
real content was NOT deleted or rebuilt.** No content defect required a fix in
this audit; the deliverable is this evidence report plus channel status.

The prior `10-12-dart-curriculum-120` task is functionally complete (see §6): its
own acceptance gates all pass on the current tree.

## 2. Inventory

| Artifact | Count | Evidence |
| --- | --- | --- |
| Authored lessons | 120 | `curriculum/chapters/*.dart` (14 files), grep `id: 'dart-lesson-` = 120 |
| Paired examples | 120 | grep `exampleTitle` = 120 |
| `dart_tutorials.json` entries | 120 | `ConvertFrom-Json` `.entries.Count` |
| `dart_examples.json` entries | 120 | `.entries.Count` |
| Tutorials asset size | 324,276 bytes | `Get-ChildItem` |
| Examples asset size | 133,847 bytes | `Get-ChildItem` |

Per-chapter counts match `DartCurriculum.counts` exactly (sum = 120):
basics 10, control 8, collections 10, nullsafety 6, oop 12, generics 8,
exceptions 6, dart3 12, async 10, streams 8, isolates 6, io 8, json 6,
engineering 10.

## 3. Placeholder scan (empty result)

`Select-String` across `curriculum/**` for `TODO|FIXME|placeholder|占位|待补|待完善|...|XXX|Lorem`
→ **0 matches**. The generated JSON assets contain no ellipsis placeholders; the
lone `...` matches in the source are legitimate Dart spread operators
(`...basicsLessons`), not filler.

## 4. Generation determinism

```
dart run tool/build_dart_content.dart   -> "Emitted 120 Dart lessons and 120 Dart examples."
```

- SHA256 before second run:
  - `dart_tutorials.json` = `71D41769D7B10118644369225503596251AE0F680D75D5C82B684753E7B9123D`
  - `dart_examples.json` = `D0FE40247B1209040B3E2440DE4B9B29234F4C2A12217C83D13DA7182EA4E690`
- After re-running the generator, both hashes were **identical** and
  `git status --porcelain` showed **no asset change** (only the pre-existing
  Trellis scratch file). Generation is byte-deterministic and id-sorted.

## 5. Real execution + correctness gates

### 5.1 Canonical verifier (compiles AND executes every lesson on host SDK)

```
dart run tool/verify_dart_content.dart
  -> PASS lines = 120, FAIL lines = 0
  -> checked=120 failures=0
```

Every lesson compiles with `dart <file>.dart`, actually runs, and its stdout is
diffed byte-exactly (LF-normalized, trailing-newline tolerant). A missing host
SDK is a hard failure in this harness — it was **present** and the gate ran for
real (no skip counted as pass).

### 5.2 Compatibility labeling

```
dart run tool/audit_compat.dart
  -> advanced lessons: 42 ; labeled: 42 ; unlabeled: 0
```

All Dart 3 / async / streams / isolates / IO lessons state the official-SDK
requirement inside `explain` (the only field the detail page renders; there is no
parser `engine` field). Verified: the raw assets contain **no** `"engine"` key and
**no** `inputFixtures` key.

### 5.3 Test suite

| Command | Result |
| --- | --- |
| `flutter analyze --no-pub lib tool test curriculum` | **No issues found!** |
| `flutter test --no-pub` (full suite) | **+63: All tests passed!** |
| `flutter test --no-pub test/dart_content_*.dart` (5 files) | **+29: All tests passed!** |
| `dart_content_run_test.dart` | 120 lessons + 120 examples executed via real `DartProgramRunner` |
| `dart_content_dart_eval_test.dart` | `dart_eval: ran=43 of 120 lessons; 77 SDK-required` (honest subset, no overclaim) |
| `dart_content_import_test.dart` | catalog example → `CodeImportService.importIntoProject` → real file → `DartProgramRunner` run; all 120 write exact source |
| `dart_content_widget_test.dart` | real `LocalTutorialsTab`/`ExampleCodeTab` mount the Dart-owned repository and render 120/120 |
| `dart_content_test.dart` | structure/uniqueness/pairing/completeness/no-placeholder/level/license |

## 6. Semantic + pipeline checks

- **Semantics**: chapter titles map to concrete Dart knowledge points
  (e.g. `dart3` → records/patterns/sealed/enums; `async` → Future/await/`Future.wait`;
  `isolates` → `Isolate.run`/ports; `io` → temp-file read/write; `json` →
  encode/decode/fromJson; `engineering` → assertions/grouping/edge cases). Sample
  lesson 061 showed unique Chinese prose, real concepts, non-empty pitfalls,
  a runnable `main`, declared `output = 3\n7\n3\n10\n2\n`, and an exercise with
  prompt/hint/answer.
- **Output correctness**: enforced structurally by §5.1 (byte diff) and §5.3.
- **Import path**: the required Dart acceptance path
  catalog → detail → import to editor/project → editor Run is covered by
  `dart_content_import_test.dart`; there is no inline detail Run (CodeSnippet's
  inline Run is Java-only), consistent with the spec.
- **Envelope shape**: tutorials/examples use the exact `ContentCatalog.fromJson`
  shape (`kind`, `entries[].lessons[]`; examples carry `code`, `expectedOutput`,
  `sourceLessonId`, `templateType`).
- **License/source (R6/AC14)**: authored values
  `source = https://dart.dev/language`,
  `license = Original QFLI curriculum; reference link retained. CC BY 4.0` — these
  **exactly match** the pre-existing core Dart entries (verified read-only against
  `../qfli_studio_core/assets/content/tutorials.json` `type:"dart"`). No new
  license introduced.
- **Repository/injection**: `lib/dart_content_repository.dart` reads
  `packages/qfli_dart/assets/content/dart_{tutorials,examples}.json` and reuses
  `ContentCatalog.fromJson`; `lib/main.dart:31` wires
  `contentRepositoryFactory: DartContentRepository.new`; the additive core seam
  (`studio_profile.dart:101,204`, `home_page.dart:57`) is present and null-safe.
- **Ownership**: this audit changed **no** product file. Only authored content and
  its own tests/tools/repository are in scope; `core/`, `ohos/`, platform,
  runner, and `main.dart` were not modified.

## 7. Known, non-blocking limitations (reported honestly)

- **dart_eval subset**: only 43/120 lessons are empirically verified on dart_eval
  0.8.5; the other 77 are labeled official-SDK-required in `explain`. This is a
  truthful capability boundary, not a content defect.
- **Device / Android official SDK VM**: not exercised here (no device). The
  official-SDK branch is verified on the host Windows SDK VM; the Android VM path
  remains a device gate owned by the dispatcher.

## 8. Old task `10-12-dart-curriculum-120` — closure recommendation

Recommendation: **close as completed**, not re-run.

- Its `status` is still `in_progress`, but every one of its acceptance gates
  (AC1–AC14) is satisfied on the current tree: 120/120 authored + assets,
  uniqueness/pairing/completeness, host-SDK compile+execute+diff for all 240,
  1:1 `sourceLessonId`, level coverage, engine labeling with `unlabeled: 0`, no
  placeholder/stdin/network, all rendered fields only, real repository+runner
  tests green, additive two-file core seam, existing license.
- Its own research already records the final state: `verification-record.md` and
  `independent-review.md` show P1/P2 cleared, `verify_dart_content.dart`
  `checked=120 failures=0`, and full `flutter test --no-pub` green.
- The one leftover the independent review flagged (lesson-061 claiming dart_eval
  cannot run records) is **already resolved** in the current tree: lesson-061's
  pitfall reads "本课代码已在官方 SDK 与 dart_eval 0.8.5 上实测通过".
- Only `dart_content_dart_eval_test.dart`'s device/Android gate and the
  Android-VM execution evidence remain outstanding — those belong to the
  release task's device gate, not to content authoring.

Action suggested to the dispatcher: set `10-12-dart-curriculum-120` to
`completed`, retaining the device gate as an explicit limitation (do **not**
advance the global task pointer from this session).

## 9. Reproduction commands

```powershell
# from D:/MyNewProjects/qfli_dart
dart run tool/build_dart_content.dart      # Emitted 120/120; re-run is byte-stable
dart run tool/verify_dart_content.dart     # checked=120 failures=0
dart run tool/audit_compat.dart            # advanced 42 / labeled 42 / unlabeled 0
flutter analyze --no-pub lib tool test curriculum   # No issues found
flutter test --no-pub                      # +63 All tests passed
```
