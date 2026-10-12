# Tutorial and Example Code Imports

## Scope

The shared core owns the offline catalogs, detail code blocks, storage, and
editor navigation. Language apps use these pages through HomePage. Verify the
real core worktree and the app that depends on it.

## Signatures

```dart
typedef CodeImportResult = ({Project project, String path});
CodeImportService.suggestedFileName(String type);
CodeImportService.destinationPath({required Project project,
  required ExampleCode example, required String fileName});
CodeImportService.openInEditor({required ExampleCode example,
  required String fileName, String? location});
CodeImportService.importIntoProject({required Project project,
  required ExampleCode example, required String fileName, bool overwrite = false});
ProjectStore.createProjectFromExample({required String name,
  required ExampleCode example, String? location, String? fileName});
```

## Contracts

- Outer catalogs are MD3 title/summary ListTiles. Code and code commands belong
  in details. CodeSnippet uses the currently edited buffer for copy/import.
- Import to editor creates a local snippet project, registers it, and opens it.
  Import to project selects an existing local project or creates a new one.
- A filename is a basename including its editable extension. Existing projects
  use their own template's entry parent; missing metadata falls back to the
  example type. New projects use the example template.
- New custom entries replace the generated template entry, preserve auxiliary
  template files, and store the relative entryFile in `.qfli/project.json`.
  RunnerService.findEntry honors only existing paths contained in the project.
- A successful result follows completed writes. Existing targets require a
  separate confirmation before passing overwrite:true. Replacement writes and
  flushes a temporary file on the same volume before renaming it into place.
- EditorPage restores existing tabs then activates initialOpenPath. Stored
  active tabs must not override an explicit imported path.
- ExampleCodeStore loads `examples.json` from AppPaths.storageDirectory unless
  a test supplies storageFile. HomePage owns the store, and the example tab
  waits for its load. Details start with saved code while Reset uses bundled
  defaults. Custom state becomes visible after persistence succeeds.
- Guard duplicate actions, failed registration, and disposed pages/controllers.
  A failed registry write must remove the new in-memory project.

## Validation and Errors

| Condition | Required Result |
| --- | --- |
| Empty/path/control/reserved/trailing-dot/oversized filename | invalidFileName; no write/navigation |
| Existing file without confirmation | fileExists or replacement dialog; original preserved |
| Replacement declined or dialog cancelled | no write/navigation; commands usable again |
| Directory or link target | reject; never replace or follow the target |
| Cloud/missing project or parent outside project | projectUnavailable |
| Missing writable app storage | storageUnavailable |
| I/O or registry failure | error remains visible; no editor route or success |
| Page/controller disposed during read | stop before creating tabs or notifying listeners |

## Cases

- Base: a Dart snippet defaults to `main.dart` and opens its actual source.
- Good: `custom.dart` imported into an existing project becomes active even
  when history selected another file; the original project entry is preserved.
- Good: importing Dart into a Markdown project follows its root layout.
- Bad: accepting a conflict by retrying with overwrite:true without asking.
- Bad: testing only an injected ExampleCodeStore while HomePage keeps Save
  disabled or omits the persistence layer.

## Verification

Use temporary real directories and a test path-provider implementation. Trace
HomePage -> catalog -> detail -> dialog -> on-disk code -> real EditorPage. Check
the registered project and active CodeEditor buffer, not just a mock callback.

Cover both details and both import modes, edited code, custom names, replacement
acceptance/refusal, invalid names, I/O/registry failures, cancellation, pending
reads after dispose, saved examples after rebuilding HomePage, and Reset.
Check 320px and desktop layouts at 2x text scaling and bounded code surfaces.

Run `flutter test --no-pub` in the core and language app. Analyze core `lib test`
and the app; third-party vendor examples are separate packages. Check the exact
staged commit snapshot when unrelated edits share task files.

## Wrong and Correct

Wrong: show a snackbar after creating the file and leave the user in the detail.

Correct: after successful writing and registration, push EditorPage with the
same ProjectStore/AuthStore/SettingsStore and initialOpenPath set to the exact
imported absolute path. Awaiting a dialog or restoring a session must not lose
that path or access disposed state.
