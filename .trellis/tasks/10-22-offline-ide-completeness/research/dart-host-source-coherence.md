# Dart host source coherence: migrated verifier and asset binding

Scope of this note: the owned files `tool/run_dart_host_gate.py`,
`test/test_dart_host_gate.py`, the new `tool/verify_b_draft_exercises.dart`, and
the report itself.

No lib, curriculum, vendor, pubspec, core, sibling, native, android, ohos or
device file was edited. No Dart, Flutter, SDK, analyzer, test, build or device
command ran. No real control process ran. No git command ran. GRANT630 was not
replayed. No fresh grant was requested or consumed.

Only pure Python ran:

- `python -m py_compile tool/run_dart_host_gate.py` exited 0.
- `python test/test_dart_host_gate.py` ran 9 tests, all OK, exit 0.
- `python tool/run_dart_host_gate.py --help` exited 0.
- A read-only `build_identity(..., require_tools=False)` capture hashed files.
- A static `Select-String` scan checked source markers.

## 1. Change boundary

The behavior gap had four parts.

1. The exercise verifier lived in generated scratch
   `.dart_tool/expansion-b/verify.dart`. It was not reviewable source and not in
   a stable path.
2. The verifier could succeed on an empty or wrong lesson set. A zero count
   compared equal to zero.
3. The verifier assumed its scratch directories already existed.
4. The gate identity did not cover `assets/` or `.flutter-plugins-dependencies`.
   Asset drift was invisible.

The fix lives in the verifier source, the gate constant and capture lists, and
the pure regression test. It does not live in the SDK runner or the portable
runtime, so those stay untouched.

## 2. Verifier migration

New file: `tool/verify_b_draft_exercises.dart`.
SHA256 `08d40cdb3c5b9bc25ba1c7b8918563297c87ee6b036ab07a04ff944e8b208847`.

The old scratch file `.dart_tool/expansion-b/verify.dart` was deleted after the
copy. The old path is now absent from the identity.

Import changes only:

- `../../curriculum/...` became `../curriculum/...`.
- `../../tool/portable_content_runner.dart` became
  `portable_content_runner.dart`.

No grandparent import remains. The static test asserts this.

Preserved behavior, unchanged:

- The five chapter lists still build the full lesson set.
- `--exercise-only`, `--start=` and chapter filters still select lessons the
  same way.
- Each program still runs through the real SDK with
  `Process.run(Platform.resolvedExecutable, ...)`.
- Each program still runs through the production portable path with
  `runPortableContent(source)`.
- Outputs are still decoded with `allowMalformed`, and CRLF is normalized to LF.
- The exercise `expected` is still the SDK output.
- `passed` still requires SDK exit 0, empty SDK stderr, exact SDK output, no
  portable error, and exact portable output.
- The out-of-memory path still sets `infrastructureFailure`, increments
  `failures`, saves, and breaks the batch.
- The result JSON keeps `plannedLessons`, `pairedEntriesChecked`,
  `standaloneExercisesChecked`, `totalEntriesChecked`, `failures`,
  `infrastructureFailure`, `targetDeviceVerified` and `results`.
- The summary line is still
  `unique=${lessons.length} pairs=${results.length} failures=$failures`.
- A failure still sets `exitCode = 1`.

## 3. Scratch paths and directories

The report path is unchanged on purpose. The gate parser expects
`results---exercise-only.json`.

- Scratch root: `.dart_tool/expansion-b`.
- Program directory: `.dart_tool/expansion-b/programs`.
- Report: `.dart_tool/expansion-b/results-$suffix.json`.

The verifier now creates the scratch root and the program directory with
`createSync(recursive: true)` before writing. The report name rule is unchanged.

The gate still derives the exact report name from the same suffix rule. The
static test asserts the name equals `results---exercise-only.json`.

## 4. Empty and wrong-set guard

The verifier now computes the selected id numbers and checks them before any
write.

- An empty lesson set writes a stderr message and exits 1. A zero count is never
  a pass.
- Duplicate id numbers write a stderr message and exit 1.
- For the canonical scope (`chapterFilters.isEmpty && start == 181`), the sorted
  ids must equal `181..238` exactly. This enforces 58 unique ids with no missing
  and no extra entry.

A filtered or non-181 run still requires a non-empty, duplicate-free set, so a
targeted run stays possible.

Static confirmation of the curriculum source, with no Dart run:

- The five chapters carry 58 literal `id: 'dart-lesson-NNN'` entries.
- The ids are unique, with min 181 and max 238.
- Missing and extra are both empty.
- The five chapters carry 58 `exercises: <DartExercise>[` lists.

So the canonical set is 58 ids from 181 to 238.

## 5. Gate source changes

`tool/run_dart_host_gate.py` now has SHA256
`dab0dc98d04c081b0164ded79de7ebf46ecb0a720097564166f9d6c2a8ad526f`.

Changes, all inside this owned file:

1. `VERIFY_SCRIPT` is now `tool/verify_b_draft_exercises.dart`.
2. `SOURCE_DIRS` now includes `assets`.
3. `SOURCE_FILES` now includes `.flutter-plugins-dependencies`.
4. The module docstring names the new verifier and the new asset/plugin capture.
5. The `verify_result_path` docstring names the migrated verifier.
6. The summary-miss reason names the migrated verifier.
7. The nonzero-exit message names the migrated verifier.
8. The `--expected-exercises` help names the migrated verifier.

No bare `verify.dart` prose remains in the gate. A scan counted 0.

Read-only capture after the change:

- repo files 264
- `assets/app_icon.png` present
- `assets/content/dart_tutorials.json` present
- `assets/content/dart_examples.json` present
- `.flutter-plugins-dependencies` present
- `tool/verify_b_draft_exercises.dart` present
- old `.dart_tool/expansion-b/verify.dart` absent
- core files 164
- re_editor files 37

The count grew from 260 to 264. The four new entries are the icon, the two
content JSON files and the plugin manifest.

## 6. Pure Python tests

`test/test_dart_host_gate.py` now has SHA256
`88b8ff1ca95d4daab328641f4ed646d00def3da2048d48a64d67504505ca34b2`.

Nine tests passed in 0.139 seconds.

Timeout regression, kept:

- `test_deadline_cleanup_records_forced_tree_termination` still asserts exit
  124, `timedOut`, `ownedTreeTerminated`, terminal and active0.

Asset and plugin binding, new. Each uses a temporary synthetic repo built by
`_make_repo`. No process starts and no real asset is touched.

- `test_unchanged_repo_passes` builds the identity twice and verifies it. It
  also asserts the asset key and the plugin key are present, so the test cannot
  pass vacuously.
- `test_modified_asset_is_rejected` rewrites `assets/app_icon.png` and expects
  `verify_identity` to raise `Repo source/config drifted`.
- `test_deleted_asset_is_rejected` deletes the asset and expects the same
  rejection.
- `test_modified_plugin_manifest_is_rejected` rewrites
  `.flutter-plugins-dependencies` and expects the same rejection.

Verifier coherence, new. Static reads only.

- `test_gate_targets_migrated_script` checks the gate constant, the new file and
  the removed old path.
- `test_imports_resolve_without_grandparent` checks every import resolves under
  `tool/` and that no `../../` remains.
- `test_report_path_matches_gate_parser` checks the report name.
- `test_rejects_empty_and_wrong_id_set` checks the empty guard, the duplicate
  guard and the `181..238` guard markers.

The timeout test still passes, so the earlier 630 repair stays covered.

## 7. Source diff self-check

Git is prohibited, so this is a read-back check, not a git diff.

- The gate constants and prose were read back after each edit.
- A `Select-String` scan found 0 bare `verify.dart` prose lines in the gate.
- The new verifier has balanced braces (22 open, 22 close) and 0 grandparent
  imports.
- All three edited files end with a newline and have 0 CRLF.
- File hashes are recorded in sections 2, 5 and 6.

Files changed by me:

- `tool/run_dart_host_gate.py` (constant, capture lists, prose)
- `test/test_dart_host_gate.py` (rewritten, 9 tests)
- `tool/verify_b_draft_exercises.dart` (new, migrated)
- `.dart_tool/expansion-b/verify.dart` (deleted, migrated)
- `research/dart-host-source-coherence.md` (this note)

Not changed: `lib/`, `curriculum/`, `vendor/`, `pubspec.yaml`, core, sibling,
other worker research notes and READMEs.

Stale references remain in older notes, left untouched on purpose:
`research/dart-host-gate.md` (4), `dart-host-gate-final-review.md` (2),
`dart-host-timeout-repair-review.md` (2), and the expansion notes. Those still
name the old scratch path. The root should refresh the gate note before
publishing. The executable source and its inline explanation are coherent now.

## 8. Pub cache and SDK coverage: plan and cost risk

This is a plan only. I did not implement it and did not add expensive reads.
The coverage gap is real: only `pubspec.lock`, `package_config.json`, `dart.exe`
and `flutter.bat` are bound. The resolved package bytes and SDK internals are
not.

Measured package counts, from the small `package_config.json` files only:

- repo: 85 packages, 76 hosted, 4 local, 5 file.
- core: 61 packages, 54 hosted, 2 local, 5 file.
- The hosted union is roughly 100 or more packages.

Cost estimate, not measured:

- Each full deep capture would open and hash tens of thousands of files.
- The gate re-captures the identity before the run, after each of up to three
  phases, and once in `finally`. That is up to five full captures per run.
- A deep capture that costs T seconds becomes about 5T per run. A modest T of
  20 to 60 seconds becomes 100 to 300 seconds, which exceeds the 240 second
  window and can exceed the prepare budget under load.

Options, cheapest first:

1. Keep the current cheap binding and record the residual risk. Recommended for
   the next READY.
2. Bind hosted packages by name, version and rootUri from the existing
   `package_config.json`, plus `pubspec.lock`. This adds no large read, but it
   does not hash package bytes.
3. Opt-in deep hash of hosted `lib/` trees, run only in `--prepare`, never in the
   per-phase recheck. Give it its own budget and a clear cost line.
4. Opt-in SDK digest: hash `bin/cache/flutter_tools.snapshot` and the Dart SDK
   `lib/` tree. Very expensive. Prefer a version string captured by the root
   during preparation instead.

Recommendation: ship option 1 now, document the residual risk, and add option 3
as an explicit prepare-only flag in a later task. Do not put deep hashing into
`build_identity`, because the per-phase recheck would multiply its cost.

## 9. UNRUN items

None of these ran. Each needs a new named window.

- the normal, orphan and timeout controls
- `dart tool/verify_b_draft_exercises.dart --exercise-only`
- `flutter analyze --no-pub`
- `flutter test --no-pub --concurrency=1`
- any target-device action

The migrated verifier has not been compiled or executed. Its Dart syntax,
imports and runtime behavior are proven only by static checks. The real SDK and
portable behavior, and the 58-exercise count, remain UNRUN until the gate runs.

## 10. Ready state

- Identity capture now includes `assets/` and `.flutter-plugins-dependencies`.
- The old identity is stale again. The gate hash changed from `40db6e90...` to
  `dab0dc98...`, and the repo file set changed.
- A new `--prepare` is required before any new READY.
- No grant was consumed. No control, SDK or device action occurred.

## Root review, 2026-10-26

Root removed the four source-marker tests. They mirrored implementation text and depended on an ignored scratch path being absent. The remaining five tests exercise timeout accounting and asset/plugin drift rejection. Root ran all five successfully. The worker nine-test count above is historical. The migrated Dart verifier still needs real SDK execution.

The identity now includes explicit coverage metadata: assets and plugin manifest are captured. External resolved package bytes and SDK internals are not captured. Toolchain hashes cover only the Dart executable and Flutter launcher. A new READY must state these limits.
