# Spec audit and bootstrap fill — `.trellis/spec`

Owner: `dart-content` (Herdr pane `w7:p5`).
Task: `10-15-dart-store-release` (work assigned for `00-bootstrap-guidelines`).
Date: 2026-10-15. Scope: `D:/MyNewProjects/qfli_dart` only.

## 0. Environment / identity

- `Get-Location` = `D:/MyNewProjects/qfli_dart`; git root the same.
- Herdr pane `w7:p5`.
- Core inspected **read-only**; no writes to `../qfli_studio_core`.

## 1. What was done

Filled the 11 template spec files left by `trellis init` and rewrote both index
files, using real source from `lib/`, `test/`, and (read-only) the shared core.
The existing valid contracts (`dart-tools.md`, `dart-native-runtime.md`,
`dart-curriculum.md`, `content-code-import.md`) were **not modified**.

The project is an offline Flutter/Dart app, so templates written for a
TypeScript/ORM/React stack were replaced with reality — not with fabricated
TypeScript, ORM, or React-hook guidance.

### Backend

| File | Content |
| --- | --- |
| `backend/directory-structure.md` | Runtime/toolchain/content layout; `lib/main.dart` profile as composition root; module/naming rules |
| `backend/database-guidelines.md` | **No database/ORM/shared_preferences**: JSON files under `AppPaths.storageDirectory()`, serialized + atomic (temp-then-rename) writes, document versioning/migration, rollback-on-failure |
| `backend/error-handling.md` | Standard Dart exception types, `ProgramRunResult` returns instead of throws, narrow catches, explicit platform gaps, containment checks, `finally` cleanup, exit 130 vs `kProgramNotRunExitCode` (127), Chinese messages |
| `backend/logging-guidelines.md` | **No logging package**: `debugPrint` for diagnostics, `developer.log` for timing, no `print` in `lib/`, what not to log |
| `backend/quality-guidelines.md` | Analyze/test gates, forbidden patterns (duplicating core policy, faking execution, broad catches), required patterns, testing + review checklist |
| `backend/index.md` | Navigation + pre-development checklist + quality check |

### Frontend

| File | Content |
| --- | --- |
| `frontend/directory-structure.md` | Flutter page/asset layout; core-vs-repo ownership; `forStore` profile factory; naming |
| `frontend/component-guidelines.md` | Widget structure, `const`/`super.key`/nullable injected deps, Material 3 theming, `MediaQuery` responsiveness, accessibility, anti-patterns |
| `frontend/hook-guidelines.md` | **No React/`flutter_hooks`**: `initState`/`dispose`, subscriptions, generation-counter guards, busy guard, `compute` offload |
| `frontend/state-management.md` | `State<T>` + `setState` and core `ChangeNotifier` stores; local vs shared; serialized store writes; offline (no server state) |
| `frontend/type-safety.md` | **Not TypeScript**: sound null safety, records, `abstract final class`, explicit JSON validation pattern, forbidden `dynamic`/unsafe `!` |
| `frontend/quality-guidelines.md` | Lint/format/test gates, forbidden/required patterns, widget-test requirements |
| `frontend/index.md` | Navigation + pre-development checklist + quality check |

`00-bootstrap-guidelines/prd.md` status checklist was updated. Its `task.json`
was **not** modified and the task was **not** archived (dispatcher owns
finishing).

## 2. Evidence behind the specs (real paths)

- Runtime/profile wiring: `lib/main.dart`, `lib/dart_runner.dart`,
  `lib/native_dart_toolchain.dart`, `lib/android_dart_sdk.dart`,
  `lib/dart_tools.dart`, `lib/dart_project_sources.dart`.
- Flutter page + state/lifecycle: `lib/dart_tools_page.dart`
  (`initState`/`dispose`, `_generation`, `_beginOperation`, `compute`,
  `_run`/subscriptions, `forStore`).
- Content repository: `lib/dart_content_repository.dart`.
- Storage/persistence (core, read-only): `services/app_paths.dart`,
  `services/local_store_backend.dart`, `store/project_store.dart` (temp-then-rename
  + serialized writes), `services/example_code_store.dart` (JSON doc +
  `contentVersion` migration + `_disposed` guard).
- Logging usage (core, read-only): `editor/open_performance.dart` (`developer.log`),
  `services/tutorial_service.dart` / `local_audit_service.dart` /
  `local_stats_service.dart` / `splash_screen.dart` (`debugPrint`).
- Component/prop conventions (core, read-only): `widgets/code_snippet.dart`.
- Tests: `test/native_dart_toolchain_test.dart`, `test/dart_tools_test.dart`,
  `test/dart_app_test.dart`, `test/dart_content_widget_test.dart`.

### Facts asserted and verified

| Claim | Verification |
| --- | --- |
| No `print(` in `lib/**` | recursive scan → 0 matches |
| No `flutter_hooks`/`logging`/`sqflite`/`drift`/`shared_preferences`/state-mgmt libs | `pubspec.yaml` scan → none |
| `NativeDartToolchain.supported` is the platform gate | `lib/native_dart_toolchain.dart` |
| Cancelled run → 130; not-run → `kProgramNotRunExitCode` (127) | `lib/dart_runner.dart:332`; core `const int kProgramNotRunExitCode = 127` |
| `DartToolsPage.forStore` is the profile seam | `lib/dart_tools_page.dart`; wired in `lib/main.dart` `toolsPageBuilder` |
| Exceptions used: `ArgumentError.value` / `FileSystemException` / `StateError` / `FormatException` / `ProcessException` / `PlatformException` | `lib/dart_project_sources.dart`, `lib/native_dart_toolchain.dart`, `lib/android_dart_sdk.dart`, `lib/dart_runner.dart` |

References rejected as non-existent in this repo and therefore **not** written
into the specs: TypeScript/`tsconfig`, ORM/migrations, Zod/Yup/io-ts, React
hooks, `shared_preferences`, a logging library, a database.

## 3. Verification

```powershell
# No placeholders anywhere under .trellis/spec
Get-ChildItem .trellis/spec -Recurse -File -Filter *.md |
  Select-String 'To be filled|TODO: fill|\(To be filled by the team\)|Replace with your actual|placeholder'
  -> 0 matches

# All referenced file paths exist (lib/**, core/**, curriculum, tests, specs)
# -> every path OK

# All relative markdown links between spec files resolve
# -> 42/42 links OK

git diff --check   # -> exit 0 (only repository-standard CRLF warnings)
```

Specs are documentation only; no Dart code changed, so the analyze/test gates
are unaffected by this task. (Unrelated in-flight work by other Pi sessions is
present in the worktree and was left untouched.)

## 4. Cross-contract preservation

The following documented contracts were kept verbatim and linked, not rewritten:

- `frontend/dart-tools.md` — tool action/lifecycle contract.
- `backend/dart-native-runtime.md` — SDK packaging/kernel compilation.
- `frontend/dart-curriculum.md` — 120-lesson source/generator/repository gates.
- `frontend/content-code-import.md` — catalog/detail/import/editor path.

Both index files now list all guides with an accurate `Status` column.

## 5. Outstanding (not blocking)

- `00-bootstrap-guidelines/task.json` still shows `in_progress`; per instruction
  it is left for the dispatcher to finish/archive. The PRD checklist reflects the
  completed work.
- The guides (`spec/guides/*`) were already populated and left unchanged, except
  no change was needed.
