# Commit boundary manifest

Task: `10-22-offline-ide-completeness`.
Purpose: define the exact commit boundary for the next precise commit batch after
the current source gate passes.
Method: read-only inspection of the current Git diff, the initial baseline records
and the task research. No source or README was edited. No `git add`, commit, push
or SDK command was run.

Revision (root accepted the boundary review): this manifest now lists the
unpromoted draft source set, the two new verifier files, and a corrected README
dependency map. Re-read at `01c6714`; the snapshot below still holds.

## 1. Snapshot

| Item | Value |
| --- | --- |
| HEAD | `01c6714 chore(docs): add controlled Chinese lint workflow` |
| Branch | `feat/offline-ide-completeness` at `origin/feat/offline-ide-completeness` (in sync) |
| Index | empty (`git diff --cached` is clean) |
| Already committed focused work | `b90f4b9` tools embed + syntax diagnostics, `da820b4` native offline guard, `edecf05` HAP inspection, `01c6714` controlled-Chinese lint workflow |

| Base for this batch | the uncommitted working tree (42 modified files + untracked set) |

Note: `01c6714` landed while this review was running. It committed
`scripts/ste-lint-zh.py` and `.trellis/spec/guides/controlled-chinese.md`, so those
are no longer untracked. The snapshot and §7 below are re-read against `01c6714`.

The working tree mixes two things that must not be committed together:

- **A. Task migration work** (portable runtime, vendored interpreter, content repair,
  assets, tools/tests, READMEs).
- **B. Initial user WIP** (startup, signing, splash, LICENSE, AGENTS, startup spec).

The PRD (`prd.md` line 11) fixes the rule: preserve the initial 13 uncommitted
startup/signing/license/spec changes; only a minimal reviewed profile-hook
addition in `lib/main.dart` may overlap.

## 2. Bucket B — initial user WIP (must NOT enter the migration commits)

| Path | Change | Why excluded |
| --- | --- | --- |
| `AGENTS.md` | appends the controlled-Chinese rule block | user WIP |
| `LICENSE` (untracked) | GPL-3.0 text | initial WIP outside task ownership; no README cites it (§7) |
| `lib/main.dart` hunk A (`@@ -1,8 +1,10 @@`) | adds `flutter/foundation.dart`, `flutter/services.dart` imports | startup |
| `lib/main.dart` hunk C (`@@ -62,28 +64,67 @@`) | `main()` splash/progress/first-frame rewrite | startup/splash |
| `ohos/AppScope/app.json5` | bundle `…dartwing` → `…dart` | signing identity |
| `ohos/build-profile.json5` | `signingConfigs: []` → debugKey + releaseKey, `signingConfig: "releaseKey"` | signing |
| `ohos/entry/build-profile.json5` | adds `abiFilters: ["arm64-v8a"]` | packaging/arch (ambiguous, see §9) |
| `ohos/entry/src/main/module.json5` | `deviceTypes` phone → phone/2in1/tablet | packaging (ambiguous, see §9) |
| `ohos/entry/src/main/ets/entryability/EntryAbility.ets` | adds the `startupProgress` branch | startup |
| `ohos/entry/src/main/ets/pages/Index.ets` | adds `StartupSplash` + progress UI | splash |
| `.trellis/spec/frontend/ohos-startup.md` (untracked) | startup contract | startup |
| `.trellis/spec/frontend/index.md` | adds the OHOS Native Startup row + checklist line | startup |
| `.trellis/spec/backend/dart-native-runtime.md` hunks 3, 4, 5 (+ part of 1) | signing/arch notes | signing spec |
| `test/dart_startup_test.dart` (untracked) | tests `main()` splash/progress/first frame | startup |

Note: the offline guard itself is already committed in `da820b4`. The uncommitted
`EntryAbility.ets` hunk is only the `startupProgress` branch, so it belongs to B.

## 3. Bucket A — task migration work (the commit source)

### A1. Vendored MIT interpreter
- `vendor/` (177 files, ~3.15 MB): `vendor/tom_d4rt/{lib,LICENSE,pubspec.yaml,README.qfli.md}`
- `pubspec.yaml` — adds `tom_d4rt: path: vendor/tom_d4rt`
- `pubspec.lock` — resolved lock for the above

### A2. New portable runtime
- `lib/portable_dart_runtime.dart` (new)
- `lib/dart_runner.dart` (modified: drops the dart_eval path, calls `startPortableDart`)
- `lib/dart_tools.dart` (EVC doc comment only)
- `lib/dart_tools_page.dart` (compile tooltip switches on `NativeDartToolchain.supported`)
- `.trellis/spec/backend/dart-portable-runtime.md` (new)
- `.trellis/spec/backend/dart-native-runtime.md` — **portable hunks only** (§4.2)
- `.trellis/spec/backend/index.md` — the Portable Dart Runtime row + checklist line
- `lib/main.dart` — **runtimeKind hunk only** (§4.1)

### A3. Content repair (lessons 001–120)
- `curriculum/chapters/{async,control,dart3,exceptions,generics,io,isolates,streams}.dart`
- `curriculum/dart_chapters.dart` (engine tag/note)
- `.trellis/spec/frontend/dart-curriculum.md`
- `assets/content/dart_tutorials.json`, `assets/content/dart_examples.json`
  (regenerated 120/120 with the new engine notes; still 120 entries each)

### A3b. Unpromoted draft source (lessons 121-300)

Sixteen new chapter files, one per draft chapter.

- `curriculum/chapters/algorithms_advanced.dart`
- `curriculum/chapters/algorithms_basic.dart`
- `curriculum/chapters/apis_contracts.dart`
- `curriculum/chapters/async_patterns.dart`
- `curriculum/chapters/collection_reporting.dart`
- `curriculum/chapters/data_structures.dart`
- `curriculum/chapters/dates_money.dart`
- `curriculum/chapters/enum_states.dart`
- `curriculum/chapters/errors_resilience.dart`
- `curriculum/chapters/formatting_output.dart`
- `curriculum/chapters/json_modeling.dart`
- `curriculum/chapters/math_stats.dart`
- `curriculum/chapters/mini_apps.dart`
- `curriculum/chapters/numbers_strings.dart`
- `curriculum/chapters/oop_modeling.dart`
- `curriculum/chapters/text_processing.dart`

These files carry 180 ids, `dart-lesson-121` through `dart-lesson-300`.

Commit them as unpromoted source. `curriculum/dart_chapters.dart` does not
aggregate them, so the production aggregate and `assets/content/*.json` stay at
120/120. Promotion stays blocked by the installed OHOS acceptance gate. This
batch ships source only. It claims no acceptance and no device run.

### A4. Tools and tests
- `lib/dart_code_analyzer.dart`, `lib/dart_catalog_audit.dart` (new)
- `tool/portable_content_runner.dart`, `tool/build_dart_content.dart`, `tool/verify_portable_content.dart`
- `tool/verify_draft_content.dart` (new), `tool/dart_catalog_ohos_audit.dart` (new), `tool/run_dart_host_gate.py` (new)
- `tool/verify_b_draft_exercises.dart` (new; the host gate requires this file)
- `tool/ohos/build_dart_audit.ps1` (new), `tool/ohos/verify_dart_hap.ps1` (new)
- `test/dart_code_analyzer_test.dart`, `test/dart_content_dart_eval_test.dart`,
  `test/dart_content_run_test.dart`, `test/dart_content_test.dart`
- `test/dart_content_portable_test.dart`, `test/dart_catalog_audit_test.dart`,
  `test/portable_dart_runtime_test.dart`, `test/portable_offline_policy_test.dart`,
  `test/portable_isolate_supervisor_test.dart`, `test/portable_async_semantics_test.dart`
- `test/test_dart_host_gate.py` (new; Python regression for the host gate)
- `.trellis/spec/frontend/dart-tools.md`

### A5. Task docs and evidence
- `.trellis/tasks/10-22-offline-ide-completeness/{prd,design,implement,progress}.md`
- authored research reports (see §6 for the scratch exclusion): `expansion-{a,b,c}.md`,
  `expansion-plan.md`, `content-audit.md`, `dart-tools-audit.md`,
  `dart-analyzer-hardening.md`, `editor-core-audit.md`, `draft-verifier.md`,
  `dart-host-gate.md`, `dart-package-tooling-review.md`,
  `portable-runtime-source-review.md`, `portable-offline-policy-tests.md`,
  `tom-d4rt-semantics-rootcause.md`, `portable-production-baseline.json`,
  `portable-product-candidate.json`, `isolate-host-aot-results.json`,
  `d4rt-024-probe.json`, `tom-d4rt-1229-probe.json`, `tom-d4rt-patched-probe.json`,
  `readme-rewrite-check.md`, `commit-boundary-manifest.md`,
  `dart-core-integration-audit.md`, `dart-host-gate-final-review.md`,
  `dart-host-source-coherence.md`, `dart-host-timeout-repair-review.md`,
  `host-device-current-status.md`, `draft-controlled-chinese-audit.md`,
  `draft-editorial-a.md`, `draft-editorial-b.md`, `draft-editorial-c.md`,
  `draft-editorial-root-review.md`

### A6. README docs (separate docs commit)
- `README.md`, `README.zh-Hant.md` (new), `README.en.md` (new)

## 4. Precise hunk boundaries

### 4.1 `lib/main.dart` — stage only the runtimeKind hunk

```
Hunk A  @@ -1,8 +1,10 @@      imports: flutter/foundation.dart, flutter/services.dart   -> BUCKET B
Hunk B  @@ -39,9 +41,9 @@     ': 'dart-eval'',  ->  ': 'offline-dart-interpreter',' -> BUCKET A2 (stage this)
Hunk C  @@ -62,28 +64,67 @@   main(): binding.deferFirstFrame, startupProgress, splash handoff -> BUCKET B
```

Exact staged line pair for hunk B:

```
   runtimeKind: NativeDartToolchain.supported
       ? 'official-dart-sdk'
-      : 'dart-eval',
+      : 'offline-dart-interpreter',
```

Stage with an interactive hunk pick:

```powershell
git add -p lib/main.dart      # y on hunk B only; n on A and C
```

Do not stage A or C. Hunk B needs no new import, so it compiles alone.

### 4.2 `.trellis/spec/backend/dart-native-runtime.md` — old hunks vs new notes

```
Hunk 1  @@ -1,10 +1,12 @@    MIXED
Hunk 2  @@ -27,9 +29,9 @@    NEW  (dart_eval -> portable interpreter wording)
Hunk 3  @@ -39,8 +41,22 @@   OLD  (arm64 abiFilters note + releaseKey signing note)
Hunk 4  @@ -72,8 +88,11 @@   OLD  (signing/bundle error-matrix rows)
Hunk 5  @@ -96,11 +115,32 @@  OLD  (OHOS packaging + release-signing verification, wrong/correct signing)
```

Hunk 1 must be split by hand. Keep only the portable sentences:

```
-Use this contract for Android/desktop run, compilation, SDK discovery or packaging.
-Android and desktop use the official SDK's C++ VM. iOS/OHOS retain dart_eval;
+Use this contract for Android/desktop run, compilation, SDK discovery or packaging.
+Android and desktop use the official SDK's C++ VM. iOS/OHOS use the vendored
+portable interpreter ([contract](./dart-portable-runtime.md));
```

Drop the added line `+and for OHOS native-library architecture filtering.` and keep
the original `packaging.` (no trailing comma). That dropped phrase documents the
arm64 packaging WIP, so it belongs with bucket B (or with the packaging tool batch,
per §9).

Stage hunks 2 and the trimmed hunk 1 only:

```powershell
git add -p .trellis/spec/backend/dart-native-runtime.md   # y hunk 2, edit hunk 1, n hunks 3-5
```

## 5. Suggested commit batches (ordered)

Ordering puts dependencies before the docs that cite them.

| # | Message | Paths | Hunk selection |
| --- | --- | --- | --- |
| 1 | `build(deps): vendor tom_d4rt 1.229.0+qfli.1 for offline execution` | `vendor/`, `pubspec.yaml`, `pubspec.lock` | whole files |
| 2 | `feat(runtime): run lessons on the vendored portable interpreter` | `lib/portable_dart_runtime.dart`, `lib/dart_runner.dart`, `lib/dart_tools.dart`, `lib/dart_tools_page.dart`, `.trellis/spec/backend/dart-portable-runtime.md`, `.trellis/spec/backend/index.md`, `lib/main.dart` (hunk B only), `.trellis/spec/backend/dart-native-runtime.md` (hunks 2 + trimmed 1) | selective (see §4) |
| 3 | `fix(content): repair lessons 001-120 for the portable runtime` | `curriculum/chapters/*.dart` (8 modified), `curriculum/dart_chapters.dart`, `.trellis/spec/frontend/dart-curriculum.md`, `assets/content/*.json` | whole files |
| 3b | `feat(content): add unpromoted draft lessons 121-300` | the 16 `curriculum/chapters/*.dart` drafts in A3b | whole files |
| 4 | `feat(tools): add portable, draft and OHOS audit tooling` | `lib/dart_code_analyzer.dart`, `lib/dart_catalog_audit.dart`, `tool/*.dart` (including `tool/verify_b_draft_exercises.dart`), `tool/*.py`, `tool/ohos/build_dart_audit.ps1`, `tool/ohos/verify_dart_hap.ps1`, `.trellis/spec/frontend/dart-tools.md` | whole files |
| 5 | `test(runtime): cover portable runtime, supervisor and offline policy` | `test/dart_*.dart`, `test/portable_*.dart`, `test/test_dart_host_gate.py` (all listed in A4) | whole files |
| 6 | `chore(task): record offline IDE completeness research` | `.trellis/tasks/10-22-offline-ide-completeness/*.md`, A5 research files only | whole files, minus §6 scratch |
| 7 | `docs(readme): add Simplified, Traditional and English READMEs` | `README.md`, `README.zh-Hant.md`, `README.en.md` | whole files |

Batch 7 depends on batch 1 (`vendor/tom_d4rt`) and batch 4 (`tool/ohos/*.ps1`).
`scripts/ste-lint-zh.py` already landed in `01c6714`. Land batches 1 and 4 first, or
in the same window, or the README references point at files absent from the tree.
Batch 7 does not depend on `LICENSE`; no README cites it (§7).

Batch 2 depends on batch 1 (the `tom_d4rt` dependency must resolve before the
runtime compiles). Do not reorder 1 and 2.

Batch 3b adds source only. It must not touch `assets/content/*.json` and must not
change `curriculum/dart_chapters.dart`, so the production aggregate stays 120/120.

## 6. Scratch / non-evidence files — never stage

These are probe harnesses and downloaded material, not authored evidence:

- `.trellis/tasks/10-22-offline-ide-completeness/research/_*.dart` and `_*.py`
  (`_cap`, `_caps`, `_cases`, `_dump`, `_mkcaps*`, `_p1`, `_probe`, `_probe_fs`, `_show`)
- `.trellis/tasks/10-22-offline-ide-completeness/research/caps*/` (193 probe files)
- `.trellis/tasks/10-22-offline-ide-completeness/research/official-*.txt`
  (downloaded third-party docs; reference only, not project evidence)
- `.trellis/.runtime/sessions/*.json` (runtime session state; not ignored)
- `tool/ohos/__pycache__/` (ignored)
- `build/**` (ignored, including `build/dart-audit/*.hap`)

Also excluded: any `*.hap`, `*.app`, `*.dill` under `build/` or `ohos/*/build/`.
A filename or a copied artifact is not evidence; cite the JSON report instead.

The 16 draft chapter files in A3b are authored source, not scratch. §6 does not
apply to them. They ship in batch 3b as unpromoted source.

## 7. README (three-language) dependency map and remote gaps

Checked against `origin/feat/offline-ide-completeness` (`01c6714`).

| README reference | Path | Worktree state | On remote |
| --- | --- | --- | --- |
| lint command | `scripts/ste-lint-zh.py` | committed in `01c6714` | present |
| lint contract | `.trellis/spec/guides/controlled-chinese.md` | committed in `01c6714` | present |
| audit HAP builder | `tool/ohos/build_dart_audit.ps1` | untracked | **MISSING** |
| signing verifier | `tool/ohos/verify_dart_hap.ps1` | untracked | **MISSING** |
| interpreter + MIT license | `vendor/tom_d4rt/` | untracked | **MISSING** |
| language links | `README.en.md`, `README.zh-Hant.md` | untracked | **MISSING** |
| content verify | `tool/verify_dart_content.dart` | tracked | present |
| compat audit | `tool/audit_compat.dart` | tracked | present |
| portable verify | `tool/verify_portable_content.dart` | tracked (modified) | present |
| content build | `tool/build_dart_content.dart` | tracked (modified) | present |
| SDK stage | `native/dart-sdk/android/stage.ps1` | tracked | present |
| native channel test | `test/native_entry_ability_test.cjs` | tracked | present |

Every other named path resolves. `tool/ohos/inspect_dart_hap.py` is tracked, but
no README cites it, so it is not a README dependency and it stays out of this
table. `tool/run_dart_host_gate.py` and `tool/verify_b_draft_exercises.dart` are
cited by the task docs only.

Consequence: a docs-only commit leaves three dangling references on the remote
(the two OHOS PowerShell tools and `vendor/tom_d4rt`). The two new READMEs are
themselves the added files. No markdown link points at the tools, so no link is
broken, but the named paths would not exist. Land batches 1 and 4 before batch 7,
or accept that batch 7 documents a working tree whose dependencies land in later
commits.

`LICENSE` is outside this task's ownership. Root removed the app GPL claim from
all three READMEs, so no README depends on `LICENSE` any more. Leave it untracked
and out of every batch above. `scripts/ste-lint-zh.py` is already committed in
`01c6714`, so the README lint command resolves on the remote.

## 8. Pre-commit gates per batch

Run the current source gate once, then commit in the §5 order. Per batch:

- 1: `flutter pub get` resolves `tom_d4rt` from `vendor/`; no network fetch.
- 2: `flutter analyze --no-pub`; `test/portable_*.dart`; content gate 240/240 host.
- 3: `dart run tool/build_dart_content.dart` regenerates 120/120; assets unchanged
  in count; `dart run tool/verify_dart_content.dart` and
  `dart run tool/verify_portable_content.dart` both pass.
- 3b: source only. `assets/content/*.json` and `curriculum/dart_chapters.dart`
  stay unchanged, so the production aggregate stays 120/120.
- 4: `flutter test --no-pub` for the tool/analyzer suites; Python fixtures for
  `tool/ohos/inspect_dart_hap.py`; `python -m unittest test/test_dart_host_gate.py`.
- 5: full `flutter test --no-pub`.
- 6: docs only; no gate.
- 7: `python scripts/ste-lint-zh.py README.md README.zh-Hant.md` (0 findings) and
  the Simplified/Traditional character diff.

Do not commit a batch whose own gate has not passed. Host portable passes do not
prove OHOS build or device execution; keep those gates open.

## 9. Caveats and open classification

- `ohos/entry/build-profile.json5` (abiFilters arm64) and
  `ohos/entry/src/main/module.json5` (deviceTypes) are neither startup nor
  signing by content. They may be initial WIP or part of the OHOS packaging tool
  work. Recommendation: keep them out of every batch in §5 until root confirms; if they
  are task work, add them to batch 4 and move the abiFilters bullet of spec hunk 3
  with them. The signing bullet of hunk 3 stays in bucket B either way.
- Spec hunk 1 mixes a packaging phrase with the portable sentence. If root treats
  the arm64 packaging note as task work, keep the dropped phrase and move it to
  batch 4; otherwise it stays in bucket B. The portable sentence is task work in
  both readings.
- `tool/run_dart_host_gate.py` is a gate harness, not a product tool. It is listed
  in batch 4 because the task docs cite the host gate. No README mentions it. It
  hard-requires `tool/verify_b_draft_exercises.dart` (`VERIFY_SCRIPT`), so both
  files must land together. If root prefers, move them to batch 6 with the research.
- `test/dart_startup_test.dart` is classified as bucket B because it exercises the
  startup/splash path. If root wants startup coverage committed with the startup
  WIP, it moves with that batch, not with batch 5.
- `research/portable-baseline.json` is already tracked from an earlier commit; it
  is not part of this batch and must not be re-added.
- The 16 draft chapter files in A3b are source, not scratch. Keep the production
  aggregate at 120/120 until the installed OHOS gate passes.
- Four of the 16 draft files write lesson ids with double quotes; the other twelve
  use single quotes. Both parse. This is a style difference only, not a boundary
  fact.
- `tool/run_dart_host_gate.py` hashes file bytes over `lib`, `test`, `tool`,
  `curriculum`, `vendor` and `assets` (`SOURCE_DIRS`), not the Git index or HEAD.
  The identity therefore covers the untracked draft and test files as bytes.
  Staging or committing leaves those bytes unchanged, so a commit does not
  invalidate an identity by itself. Three requirements follow. Snapshot the
  identity after the owned bytes are final. Keep those bytes unchanged through the
  commit. Make the commit include every hashed intended source file, because a
  clean clone that lacks one of them cannot reproduce the identity.
  `.dart_tool/package_config.json` is a separate case. It stores absolute paths and
  is deliberately machine-local, so a clean clone resolves its own package config
  instead of reusing this identity.
- Batch sizes are large (vendor is ~3.15 MB, 177 files). Splitting vendor into its
  own commit keeps the runtime diff reviewable.
- `01c6714 chore(docs): add controlled Chinese lint workflow` landed during this
  review. Re-read `git log` and `git status` before staging; root may advance the
  tree again while commits are prepared.

Scope of this review: only this research manifest was edited, in the revision noted
at the top. No source, core, README or spec file was modified. No Git write
operation and no SDK command was executed.
