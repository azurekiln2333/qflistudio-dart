# Current Core Contracts

- `LocalTutorialsTab` currently receives only language/repository. It needs the
  real store and editor-opening callback threaded through lessons.
- `ExampleCodeTab` receives store/auth but no editor-opening callback. Its outer
  `_ExampleCodeCard` renders the full source directly.
- `ExampleDetailPage._importProject` calls createProjectFromExample and only
  displays a snackbar. It does not allow a filename or open the editor.
- `ProjectStore.createProjectFromExample` registers a template project and writes
  the example to template.mainFile. Add an optional basename without breaking callers.
- `FileService.isValidEntryName` rejects separators and illegal entry characters.
- `EditorPage` requires project, auth, store, settings and supports initialOpenPath.
- `HomePage` owns all three stores and already pushes real EditorPage routes.
- `StudioLocalizations` uses three explicit language maps; add getters/map entries.
- `AppPaths.projectsRoot` resolves app-local writable storage; tests should inject
  the location or mock path_provider to keep real I/O in temporary directories.
- Existing core changes include HomePage retention/layout, task activity reporting,
  project grouping, and editor font use. Preserve them in the working tree.
- New code must use actual repository content. Do not create fake product catalog entries.
