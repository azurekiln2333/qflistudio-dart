# GitHub workspace migration

## Requirements

- Preserve all Dart source, tasks, specifications and journals on GitHub.
- Inspect every configured remote and every local/remote branch before integration.
- Integrate reviewed history into main without force-pushing or discarding work.
- Exclude generated build outputs, caches, intermediate files and signing secrets.
- Run all builds, tests, analyzers and dependency installation on GitHub Actions.
- Cover native SDK outputs, Flutter applications and installer packages for Windows, Linux, macOS, iOS, Android and OHOS.
- Synchronize E:/MyNewProjects/QFLIProjects/qflistudio-dart from GitHub only.
- Compare source trees and Trellis progress between the old and new clones.
- Hand off evidence and remaining external gates to the target Codex through Herdr.
- Inventory cleanup separately from deletion. Shared WSL deletion requires cross-product readiness.

## Acceptance

- Both workspaces are clean on main and match GitHub main.
- Every inspected branch is contained in main, or an explicit unresolved remote-access gate is recorded.
- Trellis progress is tracked and reproduced by the new clone.
- No generated native/Flutter/test outputs are committed.
- Cloud evidence identifies exact commits, run IDs, artifacts and signing limits.
- AGENTS.md prohibits local builds/tests and dependency downloads.
- The target Codex acknowledges the final handoff.
