# Dart editor gestures and terminal continuity

## Requirements
- Short Run executes the project entry; long Run executes the active supported file.
- The editor terminal and standalone terminal both use the Dart profile command delegate.
- Show real stdout, stderr and exit status; stopping a program permits another run.
- Session switching and hiding/reopening the terminal preserve each transcript.
- Use local execution and keep network entry points hidden for the offline product.

## Acceptance
- [x] Shared editor run-gesture tests pass for project/current-file dispatch.
- [x] Dart profile wires dartTerminalDelegate into both shared terminal surfaces.
- [x] Real host VM programs run through both terminal widgets and render their output.
- [x] Nonzero exit, cancellation, subsequent run and session transcript retention are verified.
- [x] Changes and meaningful regression tests have Conventional Commits.

## Evidence and boundaries
`test/dart_terminal_surfaces_test.dart` mounts both actual widgets with the actual
Dart profile; its six integration tests pass. The shared-core editor run suite
also passes. See release research/terminal-audit.md and
research/terminal-surface-review.md. Android backend execution is additionally
checked by tools/android_sdk_smoke.dart. OHOS signed-device execution remains a
separate release gate, because no DartWing signing profile is available.

The former placeholder planning record is replaced by these verified contracts.
All commits were made directly on main; use --skip-branch-validation to archive.
