# Tutorial and Example Code Imports

## Goal

Make the tutorial and example catalogs simple Material Design 3 lists. Show code
inside details and let users import that code directly into the editor or a
project, choose a filename, and open the project with that file selected.

## Requirements

- Both outer catalogs show titles and short summaries without source code.
- Use the existing Material 3 theme, list tiles, icon commands, and dialogs.
- Both lesson and example details expose Copy, Import to Editor, and Import to Project.
- Import to Editor creates a local project and opens the imported file in the real editor.
- Import to Project supports selecting an existing local project and creating a new one.
- Both import flows provide a prefilled, editable filename including its extension.
- Validate names, handle errors and cancellation, and explicitly confirm existing-file replacement.
- Open the corresponding project and exact file only after writing successfully.
- Preserve editable example content and existing example Save/Reset behavior.
- Keep Chinese, Traditional Chinese, and English UI strings consistent with the core localization layer.

## Acceptance Criteria

- [x] Tutorial and example catalog tests prove source code is absent from outer lists.
- [x] Details display their actual code and both import commands.
- [x] Import to Editor writes a customized filename and opens its project/file.
- [x] Import to an existing project writes a customized filename and opens its project/file.
- [x] New-project import works from lesson and example details.
- [x] Invalid names, cancellation, conflict rejection, and I/O failure cannot be reported as success or open an editor.
- [x] Compact and desktop layouts, including enlarged text, have no overlap or overflow.
- [x] Meaningful workflow tests and static analysis pass against the actual app/core integration.

## Scope and Constraints

The pages live in sibling `qfli_studio_core`, which already contains unrelated
uncommitted edits. The current writable root is `qfli_dart`. Prepare an incremental
patch against the current core sources inside this task directory, check it, and
request filesystem approval before applying it to the sibling repository. Preserve
all existing user changes. The Dart compiler work is a separate ongoing task.

## Release reconciliation — 2026-10-15

Verified against the current source and real assets in
`10-15-dart-store-release/research/content-audit.md`. Shared-core
`content_code_import_test.dart`, `home_content_repository_test.dart`,
`editor_run_test.dart` and `terminal_manager_delegate_test.dart` passed together
(55 tests). The import suite includes real file writes, exact editor navigation,
conflict/cancellation/error handling and 320px/1280px layouts at 2x text.
Existing core content edits owned by other language sessions were preserved.
All work was committed directly on main, without a PR branch; archive uses the
documented --skip-branch-validation option.
