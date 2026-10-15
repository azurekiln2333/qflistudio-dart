# Directory Structure (Frontend / Flutter)

> How Flutter code is organized in this repository.

---

## Overview

`qfli_dart` is a Flutter app. It does **not** re-implement the shared editor,
terminal, catalog, or settings UI — those live in the sibling
`../qfli_studio_core` package and are composed through `StudioProfile`. This
repository supplies only the Dart-specific screens and wiring.

Before adding UI, check whether the core already provides the page/widget. The
Dart app composes core pages; it rarely builds navigation chrome.

---

## Directory Layout

```text
qfli_dart/
├── lib/
│   ├── main.dart                 # dartProfile (identity, runtime, runner, content)
│   ├── dart_tools_page.dart      # the one Dart-owned full page (StatefulWidget)
│   ├── dart_content_repository.dart  # ContentRepository over bundled assets
│   ├── dart_runner.dart          # runner + terminal hook (no widgets)
│   └── *_toolchain.dart, *_tools.dart, *_sources.dart  # non-UI runtime
├── assets/
│   ├── app_icon.png
│   └── content/dart_{tutorials,examples}.json   # generated, committed
└── test/                         # widget + unit tests
```

The core package (`../qfli_studio_core/lib`) owns: `pages/` (home, editor,
local content detail, settings), `widgets/` (`CodeSnippet`), `store/`,
`services/`, `terminal/`, `theme/`, `i18n/`.

---

## Module Organization

- **A Dart-owned page** is a single file under `lib/`, named `<feature>_page.dart`,
  exporting one `StatefulWidget` with a `static Widget forStore(...)` factory
  when the core constructs it from a profile
  (`DartToolsPage.forStore` in `lib/dart_tools_page.dart`, referenced by
  `toolsPageBuilder` in `lib/main.dart`).
- **Profile wiring stays in `lib/main.dart`.** `dartProfile` decides templates,
  entry files, the runner, the tools page, and the content repository. A widget
  never decides product identity.
- **Content projection is a repository, not a widget concern.**
  `lib/dart_content_repository.dart` implements the core's `ContentRepository`;
  the tabs are core widgets that accept it. See
  [content-code-import.md](./content-code-import.md).
- **Asset content is generated.** Never hand-edit `assets/content/*.json`
  (see [dart-curriculum.md](./dart-curriculum.md)).

---

## Naming Conventions

- Files: `snake_case.dart`. Widget file name matches its primary widget.
- Widgets: `PascalCase`; private `State` classes are `_<Widget>State`.
- Optional injected dependencies are **nullable** and checked before use
  (`ProjectStore? store` in core `CodeSnippet`; `_canImport` guards it),
  so the widget can render without a full app environment in tests.
- Event handlers: `_onX` for listeners (`_onProjectsChanged`,
  `_onSourceChanged`), `_verb...` for async actions (`_selectProject`,
  `_writeSource`, `_execute`).
- Private file-level helpers: leading underscore top-level functions
  (`_scanDartFiles`, `_readSourceFile` in `lib/dart_tools_page.dart`).

---

## Examples

- Dart-owned page with async lifecycle and dialogs:
  `lib/dart_tools_page.dart`.
- Repository implementing a core content interface:
  `lib/dart_content_repository.dart`.
- Core widget showing optional-dependency + `key` conventions (read-only):
  `../qfli_studio_core/lib/widgets/code_snippet.dart`.

## Where new UI goes

- A **new Dart-specific screen** → `lib/<feature>_page.dart`, constructed from
  the profile.
- A **change to shared chrome** (catalog, detail, editor, terminal) → the core
  package, coordinated; not here.
- **New content** shown in existing tabs → authored `curriculum/**` + generated
  assets, not a new page.
