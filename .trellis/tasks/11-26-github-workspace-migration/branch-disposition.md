# Branch disposition - fresh audit, 2026-11-27

Integration owner: `w5S:p1`. Auditor: `w5S:p4`.

**Integration is pending.** This is a read-only Git/remote evidence checkpoint, not final migration acceptance. No branch was merged, advanced, pushed or deleted by this audit. No remote branch deletion is permitted.

## Scope and evidence clock

Read the full `D:/MyNewProjects/_orchestra/qfli-unified-migration.md`, migration task PRD/design/execution records, existing remote/cleanup audits, Trellis workflow, shared guide index, backend/frontend spec indexes and backend quality guidance before editing. The write boundary is only this file and `.trellis/workspace/lichengyu/index.md`.

All timestamps below use the host clock with explicit `+08:00` offset.

- Initial source ref/worktree/stash/status capture started at `2026-11-27T08:43:48.2276337+08:00`.
- Initial target read-only capture started at `2026-11-27T08:46:11.5165568+08:00`.
- Live remote audit ran from `2026-11-27T08:49:31.4979665+08:00` through `2026-11-27T08:49:35.0506887+08:00`.
- Final local ancestry/ref/worktree/stash/status and URL capture ran from `2026-11-27T08:50:55.7574660+08:00` through `2026-11-27T08:50:56.9541184+08:00`.

The live queries used each exact configured fetch URL:

```text
git --no-optional-locks -c credential.interactive=never -c http.lowSpeedLimit=1 -c http.lowSpeedTime=15 -c "core.sshCommand=ssh -o BatchMode=yes -o ConnectTimeout=10 -o ConnectionAttempts=1" ls-remote --symref <configured-url> HEAD "refs/heads/*" "refs/tags/native-sdk-inputs-3.13.5*"
```

Each query had a 35-second process deadline, noninteractive Git credentials and a 10-second SSH connection timeout. All five exited 0 without reaching the deadline. The end times below are when the completed process results were observed, not server-side update timestamps. No fetch was needed or performed. Every advertised branch tip was already available as a local commit object, and cached tracking tips matched the live results.

| Remote | Exact configured URL, same for fetch and push | Query start | Result observed | Result |
| --- | --- | --- | --- | --- |
| cnb | `https://cnb.cool/azurekiln/qflistudio-dart` | `2026-11-27T08:49:31.5705523+08:00` | `2026-11-27T08:49:31.7933496+08:00` | exit 0 |
| gitcode | `https://gitcode.com/azurekiln/qflistudio-dart.git` | `2026-11-27T08:49:31.6082556+08:00` | `2026-11-27T08:49:32.1595045+08:00` | exit 0 |
| gitee | `https://gitee.com/azurekiln/qflistudio-dart.git` | `2026-11-27T08:49:31.6372066+08:00` | `2026-11-27T08:49:32.2476845+08:00` | exit 0 |
| gitlab | `git@gitlab.com:azurekiln-team/qflistudio-dart.git` | `2026-11-27T08:49:31.6661151+08:00` | `2026-11-27T08:49:35.0489920+08:00` | exit 0 |
| origin | `https://github.com/azurekiln2333/qflistudio-dart.git` | `2026-11-27T08:49:31.6957678+08:00` | `2026-11-27T08:49:35.0501048+08:00` | exit 0 |

All five remote HEADs advertised `refs/heads/main`. Source mirror push URLs remain configured, but their presence is not publication permission. Only root may request publication through the orchestrator's GitHub push gate.

## One disposition per source local branch

Source clone: `D:/MyNewProjects/qfli_dart`. Exactly two local branches were present.

| Local branch | Exact tip | Ancestry evidence | Disposition |
| --- | --- | --- | --- |
| `main` | `8dddb9531c52a80216073d71fd75ea04b52f15b5` | Matches live GitHub main; ancestor of candidate, four commits behind. | Retain. Root owns a fast-forward to the reviewed final descendant after pending fixes and evidence are committed. Integration has not happened. |
| `ci/installer-packages` | `24b6e11a80c26beef83eac00c594dd42e5bfc4c8` | Current source HEAD; matches the published GitHub installer branch. `main...candidate` has 0 main-only and 4 candidate-only commits. | Retain as the integration source. Commit reviewed fixes first; root then rechecks ancestry and fast-forwards main. Do not drop pending work or delete the branch. |

## One disposition per live remote branch

The wildcard heads query found exactly the six remote branches below: two on GitHub and one main on each of four mirrors. No remote-access gate remains for this snapshot.

| Remote branch | Exact advertised tip | Ancestry evidence | Disposition |
| --- | --- | --- | --- |
| `origin/main` | `8dddb9531c52a80216073d71fd75ea04b52f15b5` | Equals source local main; ancestor of candidate by four commits. | Retain as the canonical published baseline. Root must recheck its live tip before integration/publication. No remote deletion. |
| `origin/ci/installer-packages` | `24b6e11a80c26beef83eac00c594dd42e5bfc4c8` | Equals source candidate; four commits ahead of main, not yet contained in main. | Preserve the published installer/migration history. Integrate its reviewed final descendant through root's main fast-forward and GitHub push gate. No remote deletion. |
| `gitee/main` | `788a519be90ec48b8ad591b1c93668cfcb892435` | Ancestor of main by 32 commits and candidate by 36; no unique commits. | No merge required. Retain unchanged as an audited historical mirror; do not push to it or delete it. |
| `gitcode/main` | `788a519be90ec48b8ad591b1c93668cfcb892435` | Ancestor of main by 32 commits and candidate by 36; no unique commits. | No merge required. Retain unchanged as an audited historical mirror; do not push to it or delete it. |
| `cnb/main` | `788a519be90ec48b8ad591b1c93668cfcb892435` | Ancestor of main by 32 commits and candidate by 36; no unique commits. | No merge required. Retain unchanged as an audited historical mirror; do not push to it or delete it. |
| `gitlab/main` | `788a519be90ec48b8ad591b1c93668cfcb892435` | Ancestor of main by 32 commits and candidate by 36; no unique commits. | No merge required. Retain unchanged as an audited historical mirror; do not push to it or delete it. |

The source `refs/remotes/<remote>/main` refs and `refs/remotes/origin/ci/installer-packages` matched these live tips. The five `refs/remotes/<remote>/HEAD` refs are symbolic aliases to the corresponding main, not extra branches or unique work.

GitHub also advertised immutable input tag `native-sdk-inputs-3.13.5` at `788a519be90ec48b8ad591b1c93668cfcb892435`, matching the local tag. Preserve that tag and its input release. The four mirrors did not advertise this requested tag. No tag or release was changed.

## Candidate ancestry and retained work

Read-only `cat-file -e`, `merge-base --is-ancestor` and `rev-list --left-right --count` checks established:

| Comparison | Left-only commits | Right-only commits |
| --- | ---: | ---: |
| main vs candidate | 0 | 4 |
| main vs each mirror main | 32 | 0 |
| candidate vs each mirror main | 36 | 0 |

The candidate preserves these four commits beyond main, listed oldest first:

| Exact commit | Recorded subject |
| --- | --- |
| `f885395e3cdb33bd4655d78194b862f92684a1c0` | ci(build): build and verify installer packages for desktop and iOS |
| `70c7a62d950b6f0e31ce73df9b4dcb6bec4b72fe` | docs: preserve installer progress and plan cloud-only workspace migration |
| `1f63032ea41f46c747b935e8379dd1f581a67f46` | ci: complete cloud-only workspace migration |
| `24b6e11a80c26beef83eac00c594dd42e5bfc4c8` | ci: harden cloud-only build evidence |

The existing Session 3 journal describes the earlier `1f63032` checkpoint. Its history remains unchanged; the fresh candidate evidence belongs here rather than being backdated into that session.

## Worktrees, stashes and target disposition

Both clones are non-shallow. Neither has a stash. Each registered worktree list contains only its own primary checkout; no detached or additional linked worktree was listed.

| Clone/worktree | Branch and exact HEAD | Worktree count | Stash count | Disposition |
| --- | --- | ---: | ---: | --- |
| `D:/MyNewProjects/qfli_dart` | `ci/installer-packages` at `24b6e11a80c26beef83eac00c594dd42e5bfc4c8` | 1 | 0 | Preserve source and all concurrent edits. Keep the old clone until target acceptance. Root commits and integrates; this audit does neither. |
| `E:/MyNewProjects/QFLIProjects/qflistudio-dart` | `main` at `8dddb9531c52a80216073d71fd75ea04b52f15b5` | 1 | 0 | Clean at the captured baseline, not synchronized to candidate. Retain untouched. Root will fast-forward it from GitHub only after publication. |

The target has only GitHub `origin`, with both fetch and push URL `https://github.com/azurekiln2333/qflistudio-dart.git`. Its only local branch is main. Its cached `origin/main` matches main, and cached `origin/ci/installer-packages` matches candidate. Apply the corresponding remote dispositions above; cached refs are not extra unpublished branches.

The candidate source HEAD tree is `150cc1d426ab6b2699d46602b2360862645ce7ec`; target baseline HEAD tree is `77a6762310c8648e74c882481b45ceb4fa72a572`. These committed trees differ. They do not establish final two-clone parity, and the source working tree also contains uncommitted fixes.

At the final local capture, target `status --porcelain=v1 --untracked-files=all` was empty. Source had these six modified tracked paths, with no untracked paths at that capture:

- `.trellis/spec/backend/dart-native-runtime.md`
- `GITHUB_BUILD.zh-CN.md`
- `tool/ci/archive_intermediates.py`
- `tool/ci/package_installer.py`
- `tool/ci/test_archive_intermediates.py`
- `tool/ci/test_package_installer.py`

Those are concurrent owners' changes, not edits by this auditor. Leave them intact. This audit subsequently adds this disposition file and synchronizes the workspace index; root must include the reviewed evidence and fixes in its commit plan. No clean-source claim is made.

## Journal index synchronization

The existing `journal-1.md` contains 164 lines and three sessions. Session 3 is dated `2026-11-26`, titled `GitHub workspace migration preservation checkpoint`, on `ci/installer-packages`. Its Existing Commits table records `f885395`, `70c7a62` and `1f63032`. The index is synchronized to those existing facts: three sessions, last session date `2026-11-26`, approximately 164 lines, and a Session 3 history row. This audit does not create Session 4, rewrite the journal, add `24b6e11` to its historical commit list, or mark the task complete.

## Root handoff and remaining gates

**Ready for root fast-forward integration once the reviewed fixes and these evidence edits are committed. Integration remains pending.** The current graph has no divergence from main. This is graph readiness, not a correctness or CI approval of the concurrent fixes.

Root must:

1. Review and commit pending fixes/evidence without losing another owner's changes. Preserve the candidate ancestry.
2. Recheck the exact final commit and live GitHub main. Fast-forward main only if ancestry still permits it; do not force-push or delete any remote branch.
3. Publish only through the orchestrator's GitHub push gate. Record the final exact SHA and hosted Actions results/artifact metadata. This branch audit did not query Actions or download artifacts and establishes no new exact-candidate/final-main CI pass.
4. Fast-forward the target from GitHub, compare final commit/tree/content/Trellis inventory and verify both workspaces are clean. This auditor made no target writes.
5. Obtain target Codex acknowledgement before migration acceptance or old-clone cleanup. Distribution signing, notarization, installed-device execution and application-sandbox SDK acceptance remain separate gates.

Only static inspection, read-only Git/remote commands, permitted source-document edits and Herdr coordination were used. `GIT_OPTIONAL_LOCKS=0` and `--no-optional-locks` guarded Git inspection, including target status. No local build, test, analyzer, formatter, linter, dependency installation, artifact download, WSL operation, Git mutation, push or deletion was performed.
