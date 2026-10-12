# Port Dart interpreter and compiler toolchain

## Goal

Make QFLIDartWing a usable Dart development environment: compile, execute, and diagnose project code locally, with practical Dart editing and build tools.

## Requirements

- Port and integrate an existing Dart compiler/interpreter, rather than write a small ad hoc parser.
- Run the bundled Dart template and user projects through the app's Run action, returning program output, errors, and exit status.
- Support project files, imports, cancellation, and failures without blocking the UI.
- Provide useful Dart tooling for formatting, diagnostics, and bytecode compilation.
- Do not show internal development-status copy in the app.
- Verify source, tests, and target-platform behavior before claiming a capability is available.
- Commit each verified change with a conventional commit message, leaving unrelated worktree edits untouched.

## Acceptance Criteria

- [x] A new Dart project template runs locally and displays its actual output.
- [x] Multi-file Dart projects compile and run, with diagnostics for invalid code and runtime errors.
- [x] Infinite or long-running programs can be cancelled without locking the editor.
- [ ] Users can format and analyze Dart source and compile a project to reusable bytecode.
- [x] Automated tests cover compilation, execution, output, errors, imports, and cancellation.
- [ ] Supported mobile targets build and execute representative programs on device or emulator.
- [ ] Product UI contains no development-status placeholder claims.
- [x] Relevant changes are committed with conventional messages.

Local verification covers 28 passing tests and clean static analysis. Source
formatting, parser diagnostics, and reusable bytecode compilation are implemented;
project-wide semantic analysis and target-device execution remain incomplete.
The user requested local verification and commits first, deferring device checks.

## Background

`lib/dart_runner.dart` currently returns a development placeholder. `dart_eval` 0.8.5 supplies a Dart bytecode compiler and interpreter written in Dart, but its published compatibility list does not establish HarmonyOS support. The shared editor and run-result contract live in the sibling `qfli_studio_core` repository.
