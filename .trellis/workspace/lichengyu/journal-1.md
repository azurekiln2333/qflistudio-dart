# Journal - lichengyu (Part 1)

> AI development session journal
> Started: 2026-09-30

---



## Session 1: Dart store audit, terminal repair and platform verification
<!-- trellis-session: v=2 fp=f74baa67e6d54e45 -->

**Date**: 2026-10-15
**Task**: Dart store audit, terminal repair and platform verification
**Branch**: `main`

### Summary

Three verified Dart Pi sessions completed terminal, curriculum and offline audits. Both terminals repaired; 120 lessons and120 examples retained after full execution. Final committed core8b33443 snapshot verified; Android ARM64 APK153.0MiB and OHOS unsigned HAP39.8MiB built. Current device/signing gates remain explicit.

### Main Changes

- Both terminal surfaces share native/portable Dart routing; offline entry points and OHOS network/account packaging removed.
- Android packaging now selects only requested complete ABIs and SDK assets; APK shrank from350.5MiB to153.0MiB.
- Archived four completed older tasks; refreshed remaining task plans, specs and exact platform evidence.

### Git Commits

| Hash | Message |
|------|---------|
| `3e17a63` | fix(dart): route terminal dart commands onto verified run/compile paths |
| `fae207e` | feat(dart): wire terminal delegate and lock offline store contract |
| `602e4a0` | fix(ohos): remove network account integration from offline Dart app |
| `901bb35` | test(dart): verify both terminal surfaces run Dart through the real profile |
| `2341e78` | style(dart): format curriculum, content tests, generator, terminal test |
| `84ae58b` | test(android): verify terminal commands on native Dart SDK |
| `38e082c` | fix(android): package only requested Dart SDK architectures |
| `07a3d11` | docs(release): record platform verification and remaining signing gates |

### Testing

- [OK] Dart103 tests and pinned shared-core479 tests passed; clean analysis and formatter checks.
- [OK] All240 tutorial/example programs executed on host;120 paired content entries verified without placeholders.
- [OK] Physical ARM64 Android SDK+terminal16 checks passed; ordinary release installed/launched before shared-device hold; final package integrity checks passed.

### Status

[OK] **Completed**

### Next Steps

- Respect Web/Python/SQL Android device queue; install final reduced APK and confirm launch/SDK after release.
- Restore matching or new DartWing OHOS signing identity; sign current HAP and complete portable execution on device.
- Configure Android store signing; preserve43/120 portable lesson compatibility labels and77 official-SDK requirements.


## Session 2: Cross-platform GitHub builds and GPL alignment
<!-- trellis-session: v=2 fp=282a19e82ee50948 -->

**Date**: 2026-11-17
**Task**: Cross-platform GitHub builds and GPL alignment
**Branch**: `ci/native-android-sdk`

### Summary

Built native dependencies and applications for Android, Windows, Linux, macOS, iOS and OHOS on GitHub. Published 16 verified artifact links and aligned GPL v3.0 notices with qflistudio.

### Main Changes

- Pinned official inputs and toolchains; retained local signing credentials and existing build caches.
- Fixed macOS Bash, lipo and SDK resource layout; verified signatures after archive extraction.

### Git Commits

| Hash | Message |
|------|---------|
| `d781661` | chore(license): align GNU GPL v3.0 with main project |
| `2f9243a` | ci(ohos): build unsigned apps with a pinned Huawei toolchain |
| `a08421d` | fix(macos): relocate SDK data directories before signing |
| `edcf9ca` | docs(ci): record successful builds and downloads for all platforms |

### Testing

- [OK] Four recommended GitHub runs succeeded across eight platform/architecture combinations.
- [OK] Linux analysis passed; 221 host tests passed and three OHOS-only tests skipped.
- [OK] OHOS HAP/APP structure and artifact hashes verified; all 16 download links matched API metadata.
- [OK] Chinese lint and final diff checks passed.

### Status

[OK] **Completed**

### Next Steps

- Distribution signing, macOS notarization and device/application sandbox runtime acceptance remain separate follow-up work.


## Session 3: GitHub workspace migration preservation checkpoint

**Date**: 2026-11-26
**Task**: `.trellis/tasks/11-26-github-workspace-migration`
**Branch**: `ci/installer-packages`

### Summary

Recorded the completed remote/source inventory, archived-context repairs and temporary-core preservation evidence for migration candidate `1f63032ea41f46c747b935e8379dd1f581a67f46`. This is an in-progress checkpoint. Final GitHub main integration, exact-final-SHA cloud validation, two-workspace parity and target Codex handoff are not accepted yet. Root w5S:p1 owns integration.

### Completed Audit and Preservation

- The remote audit queried all five configured remotes successfully: origin, gitee, gitcode, cnb and gitlab. Root's subsequent fetches found unchanged tips. At that snapshot GitHub main was `8dddb9531c52a80216073d71fd75ea04b52f15b5`; all four mirrors were at ancestor `788a519be90ec48b8ad591b1c93668cfcb892435`, 32 commits behind. No remote-only work needed merging. Preserve the immutable `native-sdk-inputs-3.13.5` input tag/release.
- The original unpublished installer commit was `f885395e3cdb33bd4655d78194b862f92684a1c0`. Commit `70c7a62d950b6f0e31ce73df9b4dcb6bec4b72fe` preserved the previously untracked installer/migration task artifacts and runtime records; root pushed that branch for cloud validation. The E drive clone initially had clean main at `8dddb95`. Reflog review found no unique missing source/Trellis payload.
- Fixed seven old task paths across `check.jsonl` and `implement.jsonl` in archived `10-01-content-code-import` and `10-12-dart-curriculum-120`. All corrected targets exist and are Git-tracked archive files. The repairs did not archive or complete other tasks.
- The app vendor `tom_d4rt` has 177 tracked files and retained provenance/license. The pinned core vendor `re_editor` has 186 tracked files. Keep both as source. No compiled packages or build/cache trees were found in the tracked source inventory; keep tracked platform registrants.

### Temporary Core Checkout Evidence

The detailed evidence is in the migration task's `remote-audit.md` and `cleanup-audit.md`.

- `build/stock-core-checkout` and `build/stock-core-crlf` both have HEAD `573d1b6eecf1c2b392ad753264a5a09f62f8335e`. Each has 613 tracked files, exactly nine modified paths and no untracked or ignored files.
- Both sets of additions/deletions match tracked `tool/ci/stock-flutter-core.patch` after cancellation of one identical import-line add/delete pair. The prior audit recorded successful reverse-application checks. This journal update did not execute those checks or modify core.
- Core coordinator w63:p1 confirmed preservation of all ten supplied tips by live main `476a30acee21dc486ee2849dd8064a7be665e4d5` and integration ref `0defbf39d1ef35e4eae43717e1a910da0f9cfbe5`. Both temporary HEADs are ancestors of all ten tips.
- Both temporary directories remain present; the attempted removal was rejected. The loose handwritten `generate_core_patch.py` and `ohos_perf_gestures.py` were retained byte-for-byte in this task's tracked `recovered-source/`. They are historical evidence, not approved local execution entrypoints.
- Preserve private signing materials and historical build evidence separately. Shared WSL cleanup is outside Dart ownership; the inventory is not deletion approval.

### Existing Commits

These commits were created before this documentation update. No commit was made in this update.

| Hash | Scope |
| --- | --- |
| `f885395e3cdb33bd4655d78194b862f92684a1c0` | Installer implementation and workflow source |
| `70c7a62d950b6f0e31ce73df9b4dcb6bec4b72fe` | Preserved task/runtime progress and migration plan |
| `1f63032ea41f46c747b935e8379dd1f581a67f46` | Migration candidate: cloud-only rules/checks, sibling-core path contract, archive support, preserved source and JSONL repairs |

### Historical Cloud Evidence — Not Final Validation

The existing build documentation and archived native-build evidence record these successes. This documentation pass did not re-query Actions or download artifacts.

| Run | Recorded source commit | Scope |
| --- | --- | --- |
| 43922631253 | ac8dadd3d66a5cf85486b3e22bc6f747563f8b89 | Android ARM64/x86_64 native SDKs |
| 43937445780 | 11eba01af51446554aab21a09958b65d803b84a2 | Android, Windows and Linux applications/desktop SDKs |
| 43943142540 | 2f9243a78bd22d549518de7d4c03953a28c52ccb | OHOS unsigned HAP/APP and native libraries |
| 43999548702 | a08421daf565d7af59aeebd88caba6f3d0e53c44 | macOS ARM64/x64 and unsigned iOS archive/frameworks |
| 45807875409, attempt 2 | 70c7a62d950b6f0e31ce73df9b4dcb6bec4b72fe | Application workflow; Windows/Linux installers |
| 45807875426, attempt 1 | 70c7a62d950b6f0e31ce73df9b4dcb6bec4b72fe | Apple workflow; macOS installers and unsigned iOS IPA |

The installer runs uploaded five installer artifacts. They precede `1f63032` and do not cover its new cloud source checks or intermediate-archive steps. Older six-platform success does not establish candidate or final-main success.

### Validation Boundary

Only documentation edits and read-only source/Git evidence inspection were performed for this update. No local tests, builds, analyzers, dependency installations or artifact downloads ran. No core files were modified. No tasks were archived and no commit was created.

### Status

**In Progress — final acceptance NOT passed.** No successful exact-candidate/final-main validation is established in this checkpoint. Updating the plan and journal does not establish a clean, synchronized main or complete the handoff.

### Next Steps — Root Integration Owner

- Finish reviewed CI fixes and integrate the final candidate into GitHub main without discarding work.
- Validate the exact final SHA with cloud source checks and required native/application/installer workflows. Record exact run IDs, job outcomes, artifact IDs and signing limits; do not substitute old runs for missing, failed or unfinished final runs.
- Commit the final evidence records, fast-forward the E drive clone from GitHub, and compare commit/tree, actual tracked contents and Trellis inventories. Confirm both workspaces are clean and match GitHub main.
- Obtain target Codex acknowledgement through Herdr before accepting migration or cleaning the old workspace.
- Retain distribution signing, macOS notarization, installed-device execution and application-sandbox SDK acceptance as separate external gates.
