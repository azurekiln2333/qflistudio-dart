# Design

## Boundaries

Use the shared `local_content_pages.dart`, HomePage wiring, localization table,
and example-project creation method. The current worktree now has
`CodeImportService` and `CodeSnippet`; extend these existing components and use
the real ProjectStore and EditorPage.

## Presentation

Use unframed chapter headings and MD3 ListTiles with title, concise summary,
leading icon, and navigation chevron. Remove the runtime summary from the catalog.
Details keep explanations/output/practice and show a reusable code block with
Copy and direct import actions. Keep editable examples and their Reset/Save actions.

## Import Contract

- A successful import returns the Project and absolute file path.
- Editor import creates and registers a local snippet project. Project import
  selects a local project or creates one.
- Filename is a single basename, including extension; validate using FileService
  and reject null characters. Defaults follow ProjectTemplate.mainFile.
- Existing-project imports follow the target project's template main-file
  parent, falling back to the example's template (Dart projects use `src/`,
  Markdown projects use the root). New projects use the example's template.
  Unknown types still write the requested source file.
- Existing targets require explicit replacement confirmation; directories and
  links are not writable file targets. Write and flush before returning success.
- New projects with a custom entry name must not retain a generated default main
  with unrelated template code. Only the new operation's own generated entry may be removed.
- HomePage passes store/auth/settings to both catalogs and details. CodeSnippet
  pushes the real EditorPage with the imported path as initialOpenPath. Explicit
  paths take precedence over a restored session's active tab.
- Async imports guard repeated actions, disposed contexts, and failure states.

## Filesystem and Existing Work

The original snapshots live in `staging/old` and `staging/new`. Concurrent core
changes introduced a different implementation before the original patch was
applied. Preserve these changes and snapshot the current import service/widget
into `staging/rebased/{old,new}`. Prepare only the remaining acceptance fixes
there, check the incremental patch against the actual worktree, and request
filesystem approval before applying it. Tests are prepared under staging.

## Verification

Tests must trace catalog -> detail -> import dialog -> real file -> editor route.
Use real temporary directories for storage. Advance both real I/O time and
Flutter's fake time for asynchronous writes and route transitions. Check MD3
layout at compact and desktop sizes and with enlarged text.
