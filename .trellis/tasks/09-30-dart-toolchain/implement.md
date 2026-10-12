# Implementation plan

- [x] Inspect current runner, shared editor contract, toolchain, and worktree.
- [x] Select and resolve a maintained existing Dart bytecode compiler/runtime.
- [x] Replace placeholder runner with project compilation and isolate execution.
- [x] Add focused tests for template, imports, output, compile/runtime failures, and cancellation.
- [x] Provide formatting, syntax diagnostics, and reusable bytecode tools through user-facing actions.
- [ ] Run `flutter analyze`, `flutter test`, and target-platform build/run checks.
- [ ] Remove development-status text and reconcile the product capability metadata.
- [x] Review scope and commit verified local changes with conventional messages.

Leave pre-existing HarmonyOS edits and unrelated untracked configuration untouched.

## Verified Batches

- `8a7daa6`: project source compilation and isolate execution through the app runner.
- `9c69a4e`: official Dart formatting, source-located parser diagnostics, and reusable EVC compilation.
- `4292be0`: real project/file selection, Save, Format, Syntax Check,
  Compile, Run, and Stop. Seven focused widget tests passed, including EVC reload
  returning 42, actual run output/exit 0, cancellation/exit 130, cancelled file
  selection, compact layout with enlarged text, app-bar/system Back confirmation,
  and selection-only changes preserving results and clean-buffer state.

## Current Validation

- [x] Focused tools-page tests and `flutter analyze --no-pub` after implementation.
- [x] Final independent review, full `flutter test --no-pub` (28/28), analysis (no issues), format (0 changes), and whitespace checks.
- [x] Rebuild the final UI sources for HarmonyOS and record the exact packaging result.
- [x] Commit only `lib/main.dart`, `lib/dart_tools_page.dart`, and `test/dart_tools_page_test.dart` (`4292be0`).

Final `flutter build hap --debug --no-pub` generated
`ohos/entry/build/default/outputs/default/entry-default-unsigned.hap`
(140509783 bytes, 2026-09-30 11:22 local time), but returned exit 1 because
`entry-default-signed.hap` was missing. This is unsigned package generation,
not a successful signed build or device execution.

## Remaining Target Gate

The user requested local verification and commit first. `hdc list targets`
returned `[Empty]`; device execution is deferred. The build currently generates
an unsigned HAP but fails while looking for `entry-default-signed.hap`. Preserve
the existing signing configuration. Keep target runtime metadata unavailable
until installation and representative execution have been verified.

Syntax diagnostics do not provide project-wide semantic analysis. External
dependencies and wider Dart SDK/language compatibility remain unverified.
