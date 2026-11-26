# Remote and source audit — 2026-11-26

Herdr auditor: old Dart pi pane w5S:p2. Integration owner: w5S:p1.
All five exact configured URLs were queried with noninteractive `git ls-remote --symref`. All succeeded. Root subsequently fetched all five with pruning and tags; the tips were unchanged.

| Remote | Advertised main before integration | Additional branches |
| --- | --- | --- |
| origin (GitHub azurekiln2333/qflistudio-dart) | 8dddb9531c52a80216073d71fd75ea04b52f15b5 | none |
| gitee (azurekiln/qflistudio-dart) | 788a519be90ec48b8ad591b1c93668cfcb892435 | none |
| gitcode (azurekiln/qflistudio-dart) | 788a519be90ec48b8ad591b1c93668cfcb892435 | none |
| cnb (azurekiln/qflistudio-dart) | 788a519be90ec48b8ad591b1c93668cfcb892435 | none |
| gitlab (azurekiln-team/qflistudio-dart) | 788a519be90ec48b8ad591b1c93668cfcb892435 | none |

All mirror tips are ancestors of the original local/GitHub main, 32 commits behind. No remote-only work requires a merge. GitHub alone advertises `native-sdk-inputs-3.13.5` at 788a519; preserve this immutable input tag and release. Mirrors are inspected source inputs, not migration publication targets. The target clone has only GitHub origin.

The sole original unpublished branch commit was f885395e3cdb33bd4655d78194b862f92684a1c0 (`ci/installer-packages`), one commit ahead of main. It modifies two workflows and adds the installer helper, tests and Inno Setup source. Commit 70c7a62d950b6f0e31ce73df9b4dcb6bec4b72fe preserves its previously untracked Trellis task, session record, documentation and migration plan. It was pushed to the existing installer branch for cloud validation.

Both clones initially had one worktree and no stashes. Neither clone is shallow. No replace refs or grafts were found. The E clone was clean on main at 8dddb95.

## Reflog recovery review

- 31d2a4739edaf91b697d37be3bb846fb5e74de02 has exactly the same tree as reachable a97c1876c62f664fb8910000dbca20665eeea07c.
- 0b9c566a4930e40c8ff0760eafef04f546fb40a3 differs from reachable 6bce5cb6ff1720d05ffb5c1bcfe71e8ade5bd279 only in `.gitignore`. The reachable replacement removes obsolete partial-Trellis exclusions.
- No source or Trellis payload is missing from these abandoned versions. Do not merge obsolete ignore rules. Reflogs were not expired or pruned.

## Nested core recovery review

`build/stock-core-checkout` and `build/stock-core-crlf` are independent Git repositories at 573d1b6eecf1c2b392ad753264a5a09f62f8335e. Each contains nine modified tracked files and no untracked files. A read-only, in-memory normalized-content comparison shows that each complete diff equals `tool/ci/stock-flutter-core.patch` exactly. The tracked patch already preserves both modified source payloads. No patch was applied locally and no source was executed.

The handwritten `build/generate_core_patch.py` and `build/ohos_perf_gestures.py` are retained byte-for-byte under this task's `recovered-source/`. They are historical source evidence, not approved local execution entrypoints. Their embedded old paths and device address are historical context. AGENTS.md prohibits running them locally.

### Live Core preservation confirmation

On 2026-11-26, Core coordinator w63:p1 verified live GitHub refs. GitHub `main` was `476a30acee21dc486ee2849dd8064a7be665e4d5`; `wsui/integration` was `0defbf39d1ef35e4eae43717e1a910da0f9cfbe5`. All 10 supplied Core tips were available locally and preserved by both live refs. The auditor used live `ls-remote` heads, not cached refs.

Both temporary checkout HEADs are `573d1b6eecf1c2b392ad753264a5a09f62f8335e`; each is an ancestor of all 10 supplied tips. Each checkout has 613 tracked files, exactly 9 modified paths, and no untracked or ignored files. The filesystem inventory matches the tracked index.

Each complete set of additions and deletions matches `tool/ci/stock-flutter-core.patch` after cancelling one identical import-line add/delete pair present only in the patch. `git apply --reverse --check` passes in both checkouts. The worktree patch also matches the GitHub `main` blob after CRLF normalization.

The two temporary directories remain on disk. The path-specific recursive removal command was rejected by the command policy check, so no removal occurred. This does not block source preservation: the patch and Core history are already published.
