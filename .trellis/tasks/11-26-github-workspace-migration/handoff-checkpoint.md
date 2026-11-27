# Accepted migration checkpoint and remaining preservation hold

Date: 2026-11-27. Source coordinator: w5S:p1. Destination coordinator: w6M:p1.

## Published and verified checkpoint

GitHub main, source main and destination main reached `59236e3885fc1c11e3c2ac3d75c6584e2668f70e`, tree `4951903c33732caa7360596f9c352effa3daae2b`. All 867 tracked files, including 407 Trellis files, matched byte-for-byte after the source's existing LF/CRLF checkout difference was reconciled. Both worktrees were clean. The destination has only origin, with GitHub fetch and push URLs. The parent workspace's cloud-only policy is present verbatim in AGENTS.md.

All five hosted workflows passed at that exact SHA. `accepted-cloud-evidence.json` contains the run/job/artifact metadata: 45951389682 (source/tooling and Windows junction boundaries), 45951786422 (Android SDK), 45951761396 (Android/Windows/Linux), 45951769696 (macOS/iOS), and 45951779258 (OHOS). Thirty expected artifacts were present and unexpired. Evidence is metadata plus hosted job conclusions, not locally downloaded archives. Installer output covers Windows setup, Linux DEB, two macOS DMGs and unsigned iOS IPA; Android APKs and OHOS HAP/APP are the mobile packages. Signing limits remain those recorded in the evidence.

This document is an additional evidence-only commit. It cannot contain its own SHA. Root must publish it through the gate, validate all five workflows on the resulting main SHA, then pull and compare the destination again. The final receipt lives at `D:/MyNewProjects/_orchestra/status/qflistudio-dart.done.json` or `qflistudio-dart.blocked.json`. On another PC, query Actions for the exact cloned HEAD. Never substitute these checkpoint runs for another commit.

## Destination acknowledgement

Received through Herdr from w6M:p1:

> DESTINATION READY: Verified HEAD 59236e3885fc1c11e3c2ac3d75c6584e2668f70e; tree 4951903c33732caa7360596f9c352effa3daae2b; target main clean; origin fetch and push are GitHub-only at https://github.com/azurekiln2333/qflistudio-dart.git; target AGENTS.md enforces cloud-only builds/tests and GitHub-hosted validation. Read final-ci and parity records: five exact-SHA workflows passed, 30 artifacts, 867 tracked files, 407 Trellis files, byte-identical parity. Handoff accepted and ready. No target edits, pulls, local builds/tests/analyzers/installs/downloads. Source preservation moves remain pending your closeout.

## Preservation completed after acknowledgement

The reviewed manifest has 45 nonoverlapping entries. Root moved 44 into `D:/MyNewProjects/_migration-backup/qflistudio-dart-20261127` using same-volume directory/file renames. The backup's `preservation-manifest.json` records exact paths, original persistent file IDs and movement results. Every moved object's ID remained the same; all 17 individual-file hashes and 22 explicit source probes remained equal.

The complete build directory, both nested Core repositories and their Git directories, nine modified source files in each, original helper scripts, native SDK staging, diagnostic/device evidence and signing material remain intact in that private backup. No descendant link target was traversed during a move. The 17 individual files include the private OHOS signing recovery file under `private-signing/`. The portable tracked OHOS root lock stayed in source.

The only remaining ignored directory is `.agents/`. Its first rename was denied by Windows. Inspection showed explicit deny ACL entries. Root retained it and did not change its ACL, delegate a bypass or repeat the mutation. Prior audit established that its 46 files equal the tracked Trellis template hashes; it contains no identified unique product source. Nevertheless, the manifest's relocation requirement is not fully complete. Record this exact hold rather than claim all 45 entries moved. Keep this task in progress until the owner resolves or expressly accepts the retained helper directory.

No file, branch, worktree or WSL distribution was deleted. Moving files within D: does not reclaim D: capacity. The old source clone remains. No shared WSL image was started, mounted, stopped or unregistered. Future retention/deletion decisions belong to the relevant owners. The signing owner still owns assessment of password fields in earlier history and credential rotation.

## Next coordinator

Use the E-drive checkout for source work, with all builds, tests, analyzers and dependency installations hosted on GitHub Actions. Keep the source and private backup intact. Do not repeat already completed moves. Inspect the manifest before any recovery action. Obtain the final SHA acknowledgement after root's evidence-only publication and exact-SHA checks. The remaining ACL hold is an administrative preservation issue, not a missing build result.
