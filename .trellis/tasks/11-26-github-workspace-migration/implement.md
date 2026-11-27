# Execution

## Progress checkpoint — 2026-11-26

Integration owner: w5S:p1. This is an in-progress evidence checkpoint, not final migration acceptance.

- [x] Identify old/new clone and Herdr pane ownership.
- [x] Read workflow and applicable specifications.
- [x] Audit all five configured remote heads, local branches and unpublished work.
- [x] Audit tracked/ignored source and Trellis inventories; repair seven archived context paths.
- [x] Review six-platform CI, installer outputs and dependency path contracts.
- [x] Preserve nested checkout changes and loose handwritten source before any cleanup.
- [x] Add cloud-only rules and migration changes in candidate commit 1f63032.
- [x] Record source-preservation evidence and historical cloud-run boundaries.
- [ ] Complete final CI fixes and integrate the reviewed final commit into main.
- [ ] Push the final main commit and pass exact-SHA cloud checks and platform builds.
- [ ] Fast-forward the E drive clone from GitHub; compare commit, tree, tracked content and Trellis inventories.
- [ ] Confirm both workspaces are clean on GitHub main after the evidence updates are committed.
- [ ] Record final run IDs, artifacts, signing limits and target Codex acknowledgement through Herdr.

Validation runs only in GitHub Actions. Local operations are limited to source editing, Git, API/Herdr inspection and read-only inventory/hash comparison. No local build, test, analyzer or dependency-install commands are allowed. This checkpoint update ran none of those commands and created no commit.

## Completed remote inventory

`remote-audit.md` records successful live queries of origin, gitee, gitcode, cnb and gitlab. Root fetched all five and observed unchanged tips. At that audit snapshot:

- GitHub main was `8dddb9531c52a80216073d71fd75ea04b52f15b5`.
- All four mirror main tips were `788a519be90ec48b8ad591b1c93668cfcb892435`, ancestors of GitHub main and 32 commits behind it. No remote-only source required merging.
- `ci/installer-packages` held the sole original unpublished commit, `f885395e3cdb33bd4655d78194b862f92684a1c0`.
- `70c7a62d950b6f0e31ce73df9b4dcb6bec4b72fe` preserved the installer task, runtime records and migration plan. Root pushed it to the installer branch for cloud validation.
- The E drive clone initially had clean main at `8dddb95`. Both clones were non-shallow, with one worktree and no stashes. Reflog review found no missing source or Trellis payload.

These are pre-integration facts, not a claim that either clone now matches final GitHub main. Preserve the immutable `native-sdk-inputs-3.13.5` input tag/release.

## Trellis and source preservation

The installer and migration task artifacts are tracked. Seven obsolete paths were corrected in these four tracked manifests:

- `.trellis/tasks/archive/2026-10/10-01-content-code-import/check.jsonl`
- `.trellis/tasks/archive/2026-10/10-01-content-code-import/implement.jsonl`
- `.trellis/tasks/archive/2026-10/10-12-dart-curriculum-120/check.jsonl`
- `.trellis/tasks/archive/2026-10/10-12-dart-curriculum-120/implement.jsonl`

All corrected targets exist and are Git-tracked archive files. The change repaired references only; no other task was archived. The source audit found no tracked compiled packages or build/cache trees. Keep tracked Flutter registrants, native input scripts and both source vendors. The app's `vendor/tom_d4rt` has 177 tracked files; the pinned core's `vendor/re_editor` has 186 tracked files. These are source directories, not disposable caches.

## Two temporary core checkouts

`remote-audit.md` records the preservation review for `build/stock-core-checkout` and `build/stock-core-crlf`:

- Both HEADs are `573d1b6eecf1c2b392ad753264a5a09f62f8335e`.
- Each has 613 tracked files, nine modified paths and no untracked or ignored files.
- The additions/deletions match tracked `tool/ci/stock-flutter-core.patch` after cancelling one identical import-line add/delete pair. The recorded reverse-application check passed in both checkouts. This documentation pass did not rerun it.
- Core coordinator w63:p1 confirmed all ten supplied Core tips were preserved by live GitHub main `476a30acee21dc486ee2849dd8064a7be665e4d5` and integration tip `0defbf39d1ef35e4eae43717e1a910da0f9cfbe5`. Both temporary HEADs are ancestors of all ten tips.
- Both directories remain on disk. The earlier removal command was rejected; no removal occurred.

The loose handwritten `build/generate_core_patch.py` and `build/ohos_perf_gestures.py` were preserved byte-for-byte in this task's tracked `recovered-source/`. They are historical evidence, not approved local execution entrypoints. `cleanup-audit.md` retains the separate cache, signing-material and shared-WSL boundaries. Do not delete the whole build directory or shared WSL images.

## Migration candidate and historical cloud evidence

Candidate: `1f63032ea41f46c747b935e8379dd1f581a67f46` (`ci: complete cloud-only workspace migration`). At this checkpoint it is on `ci/installer-packages`; final main integration is not accepted. It includes the path contract `../qflistudio-core`, CI aliases, cloud-only checks, intermediate-archive support, preserved source and the seven manifest fixes.

The following successes are historical evidence from `GITHUB_BUILD.zh-CN.md` and the archived native-build task, not newly queried Actions results:

| Run | Source commit | Recorded outcome and scope |
| --- | --- | --- |
| 43922631253 | ac8dadd3d66a5cf85486b3e22bc6f747563f8b89 | Android ARM64/x86_64 native SDK success |
| 43937445780 | 11eba01af51446554aab21a09958b65d803b84a2 | Android, Windows and Linux applications/desktop SDKs succeeded |
| 43943142540 | 2f9243a78bd22d549518de7d4c03953a28c52ccb | OHOS unsigned HAP/APP and native libraries succeeded |
| 43999548702 | a08421daf565d7af59aeebd88caba6f3d0e53c44 | macOS ARM64/x64 and unsigned iOS archive/frameworks succeeded |
| 45807875409, attempt 2 | 70c7a62d950b6f0e31ce73df9b4dcb6bec4b72fe | Application workflow succeeded; Windows/Linux installers uploaded |
| 45807875426, attempt 1 | 70c7a62d950b6f0e31ce73df9b4dcb6bec4b72fe | Apple workflow succeeded; two macOS installers and unsigned iOS IPA uploaded |

The two installer runs precede candidate 1f63032 and do not cover its new cloud checks or intermediate-archive steps. No successful exact-candidate/final-main run is established by this checkpoint. Older six-platform success must not be reported as final migration validation.

## Final acceptance still open

Final acceptance has NOT passed. Root must retain exact final-SHA cloud evidence, finish GitHub main integration, synchronize and compare both workspaces, commit the completed Trellis evidence, and obtain target Codex acknowledgement. Failed, cancelled or unfinished candidate runs require explicit follow-up; historical successes cannot replace them.

Distribution signing, macOS notarization, installed-device execution and application-sandbox SDK acceptance remain distinct external gates. Build/package success does not prove those gates. Cleanup inventory is not deletion approval. Keep this task in progress until the migration acceptance and handoff are complete.

## Unified migration checkpoint - 2026-11-27

The unified directive supersedes the earlier deletion plan. Preserve private/generated content under `D:/MyNewProjects/_migration-backup/qflistudio-dart-20261127`; do not delete files, branches, worktrees or WSL distributions. All future publication goes through `_orchestra/push/qflistudio-dart.json`, never a direct push by this root.

- Refreshed all five remote audits and per-branch dispositions in `branch-disposition.md`. No remote-unique work was found; retain all remote branches.
- Copied the parent QFLI workspace rules verbatim into tracked AGENTS.md. Fixed cloud-reported Chinese terminology without running the linter locally.
- `candidate-cloud-evidence.json` records exact 24b6e11 run metadata and artifact IDs/checksums. Native Android, Android/Windows/Linux and OHOS succeeded. Both macOS jobs succeeded; iOS IPA failed on an inherited Flutter framework signature. Cloud checks failed the Windows relative-link fixture and six Chinese findings.
- Commit `593b1a2` repairs native Windows link targets in fixtures and emits POSIX tar link headers only after the existing strict selection checks. Real Windows junction checks remain intact.
- Commit `1cd9785` removes inherited iOS bundle signatures only from the disposable IPA staging copy. The original xcarchive remains untouched. Failures stop packaging; archive readback still only proves resource/profile absence, not arbitrary Mach-O signature absence or device acceptance.
- Commit `418ef9a` retains the portable public OHOS root lock as source. Nested machine-specific locks remain ignored. Unverified local Gradle wrapper originals will be preserved privately; pinned clean-cloud wrapper regeneration is documented in `ignored-input-audit.md`.
- Target Codex w6M:p1 acknowledged read-only standby and parent policy. This is not final handoff acceptance.

The reviewed fixes still require exact-SHA cloud validation after main publication. Final parity, preservation moves and target handoff remain open. No local builds, tests, analyzers, dependency installations or artifact downloads were run.

## Published main and hosted follow-up, 2026-11-27

The orchestra gate fast-forwarded GitHub main to `f6cc154dbc196bb96ce23258c04cfadc77610362` with no exceptions, problems or warnings. Both source branches and all six audited remote heads were contained; all branches and the native input tag remain. The hosted Android SDK run `45946616268`, application run `45946616239`, Apple run `45946616273` and OHOS run `45946616235` succeeded on that commit. This includes the unsigned IPA staging change. In source/tooling run `45946616388`, Windows archive/junction checks succeeded; the only failed step reported one synonym pair in GITHUB_BUILD.zh-CN.md. The follow-up uses the same verb for generation throughout that document.

For the closing commit, look up Actions by the full GitHub main SHA, including manually dispatched platform workflows when only documentation changes. The acceptance receipt is the orchestra status file `qflistudio-dart.done.json`; an incomplete run uses `qflistudio-dart.blocked.json`. The receipt records the exact SHA, target acknowledgement and preservation results outside the repository so recording those results does not change the tested commit. On another PC, verify the five hosted workflows against the cloned commit before relying on its packages. Release signing, notarization and physical-device acceptance remain separate.
