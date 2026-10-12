# Implement: Dart 课程 120 课 (K1a)

## Preconditions (before any product-code change)

- [ ] Final approval of K1a as the technical plan.
- [ ] **External-write authorization granted** for exactly:
  `qfli_studio_core/lib/services/studio_profile.dart` and
  `qfli_studio_core/lib/pages/home_page.dart`.
- [ ] Confirm no other worker is writing those two core files at edit time.
- [ ] Read `.trellis/spec/frontend/dart-tools.md` and
  `.trellis/spec/frontend/content-code-import.md` before coding.

## Ordered checklist

### Phase A — Authoring scaffolding (qfli_dart only)
- [ ] A1. Add `curriculum/dart_lesson.dart` (model with only page-renderable
  fields) and the chapter skeleton per PRD §R1.1 (total 120).
- [ ] A2. Add `tool/build_dart_content.dart` emitting
  `assets/content/dart_tutorials.json` and `dart_examples.json` in the exact
  `ContentCatalog.fromJson` shape; deterministic, id-sorted.

### Phase B — Author 120 lessons + 120 examples
- [ ] B1. Author lessons 001–120 with unique `explain`, unique multi-line code,
  exact `output`, `objective`, `prerequisites`, `pitfalls`, ≥1 exercise.
- [ ] B2. Author the 120 paired examples (may reuse the lesson's own code), with
  real `expectedOutput` and `sourceLessonId`.
- [ ] B3. Enforce per-type uniqueness while authoring; keep all 120 counted
  programs self-contained (no stdin/network); label Dart 3 / async / streams /
  isolates / IO by stating the official-SDK requirement in `explain`; IO lessons
  use program-created temp files with `finally` cleanup; document stdin as a topic
  via the real `input.txt` step only.
- [ ] B4. Use the repository's existing `source`/`license` strings only.

### Phase C — Repository + seam (seam only after authorization)
- [ ] C1. Add `lib/dart_content_repository.dart`.
- [ ] C2. Apply the exact 2-file core seam (design §4.1, §4.2).
- [ ] C3. Wire `contentRepositoryFactory` in `lib/main.dart`.
- [ ] C4. Register `assets/content/*.json` in `pubspec.yaml`.

### Phase D — Tests (quality gate)
- [ ] D1. `test/dart_content_test.dart` — counts, uniqueness within each type,
  1:1 pairing, completeness, no placeholders, multi-line structure, one
  Hello-World, level coverage, license check.
- [ ] D2. `test/dart_content_run_test.dart` — host SDK compile+execute+stdout diff
  for all 240; self-contained programs; IO temp-file cleanup; host-absent is an
  explicit skip.
- [ ] D3. `test/dart_content_import_test.dart` — catalog → detail → import to
  editor/project → editor Run (no inline detail Run; CodeSnippet Run is Java-only).
- [ ] D4. Generator determinism test.

### Phase E — Verification
- [ ] E1. `flutter analyze --no-pub` (qfli_dart).
- [ ] E2. `flutter test --no-pub` (qfli_dart), full suite.
- [ ] E3. If the seam landed: core `flutter analyze --no-pub` and
  `content_repository_test.dart` + `content_code_import_test.dart`.
- [ ] E4. Prove `core/assets/content/*.json` and `core/assets/tutorials/dart.json`
  are byte-identical (untouched) and pre-existing dirty files are preserved.

## Validation commands

```powershell
# from D:/MyNewProjects/qfli_dart
dart run tool/build_dart_content.dart
dart format --output=none --set-exit-if-changed lib test tool curriculum
flutter analyze --no-pub
flutter test --no-pub

# only after the seam is authorized and applied
cd D:/MyNewProjects/qfli_studio_core
flutter analyze --no-pub
flutter test --no-pub test/content_repository_test.dart test/content_code_import_test.dart
```

## Risky files / rollback points

| File | Risk | Rollback |
| --- | --- | --- |
| `core/lib/services/studio_profile.dart` | additive field, shared by all products | remove field + import |
| `core/lib/pages/home_page.dart` | two tab call sites | remove `repository:` args |
| `qfli_dart/lib/main.dart` | profile wiring | remove `contentRepositoryFactory:` |
| `qfli_dart/pubspec.yaml` | asset list | remove added lines |
| `qfli_dart/assets/content/*.json` | generated | regenerate |
| `core/assets/tutorials/dart.json` | **NOT authorized — must stay untouched** | n/a |

Rollback posture: reverting the seam reverts the app to the shared catalog;
authored content and tests remain valid.

## Follow-up checks before `task.py start`

- [ ] K1a approved and the two-file external write authorized (recorded in notes).
- [ ] Local Dart SDK confirmed so the run gate executes all 240 for real.
- [ ] `implement.jsonl` / `check.jsonl` already curated (7 / 6 entries).
