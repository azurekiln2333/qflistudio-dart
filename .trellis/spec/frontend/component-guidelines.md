# Component Guidelines (Flutter Widgets)

> How widgets are built and composed in this project.

---

## Overview

This is Flutter, not React. There are **no JSX props and no component library of
our own** — the UI is Material 3 Flutter widgets composed by the shared core, and
the Dart app adds a small number of pages. Widgets follow Flutter conventions:
a `StatelessWidget`/`StatefulWidget` with a `const` constructor, named
parameters, and `super.key` forwarding.

---

## Component Structure

A Dart-owned page follows this shape (`lib/dart_tools_page.dart`):

```dart
class DartToolsPage extends StatefulWidget {
  const DartToolsPage({super.key, required this.store});

  final ProjectStore store;

  /// Profile factory: HomePage constructs pages through this, not directly.
  static Widget forStore(ProjectStore store) => DartToolsPage(store: store);

  @override
  State<DartToolsPage> createState() => _DartToolsPageState();
}

class _DartToolsPageState extends State<DartToolsPage> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onProjectsChanged);
    _source.addListener(_onSourceChanged);
    _onProjectsChanged();
  }

  @override
  void dispose() {
    _generation++;
    widget.store.removeListener(_onProjectsChanged);
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) { /* composition */ }
}
```

Key points:
- `const` constructor, `super.key`, required named dependencies.
- Dependencies are received via constructor (`required this.store`), never
  looked up globally inside `build` (the one exception is `StudioProfile.current`,
  which is the app's composition root).
- A `static Widget forStore(...)` factory is the seam the profile uses
  (`toolsPageBuilder: DartToolsPage.forStore` in `lib/main.dart`).

---

## Props Conventions

- Required dependencies are `required` named parameters; optional injected
  dependencies are **nullable** and guarded:
  ```dart
  // core/lib/widgets/code_snippet.dart
  const CodeSnippet({super.key, required this.example,
    this.controller, this.store, this.auth, this.settings});
  bool get _canImport =>
      widget.store != null && widget.auth != null && widget.settings != null;
  ```
  This lets the widget render in tests without a full app environment.
- Callbacks are typed (`VoidCallback`, `ValueChanged<T>`), not `Function`.
- Pass state down as plain values/models; do not pass `BuildContext` into state
  or non-widget helpers.

---

## Styling Patterns

- **Material 3 + `Theme.of(context)`.** Read colors/typography from the theme
  (`colorScheme.surfaceContainerLow`, `outlineVariant`, `textTheme.labelLarge`),
  as in core `CodeSnippet`. Do not hard-code hex colors.
- Rounded surfaces use `BorderRadius.circular(8)` and
  `border: Border.all(color: theme.colorScheme.outlineVariant)` — the core's
  code-surface convention.
- User code is rendered with the bundled editor font
  (`EditorFonts.bundledFamily`) and `height: 1.5`.
- **Responsive by `MediaQuery.sizeOf(context)`** rather than a device check —
  e.g. `lib/dart_tools_page.dart` chooses a `300`/`420` editor height at a
  `720` breakpoint. Never branch on `Platform.isAndroid` for layout.
- User-facing strings are Chinese, matching the app; where the core provides a
  localization object, use it (`StudioLocalizations.of(context)`), otherwise a
  literal Chinese `Text`.

---

## Accessibility

- Interactive controls carry `tooltip:` (see the icon row in
  `lib/dart_tools_page.dart`) so screen readers and long-press get a label.
- Use `SelectableText`/`SelectionArea` for output and error text so it can be
  copied (`_buildResults` in `lib/dart_tools_page.dart`).
- Provide an explicit empty state instead of a blank area
  (`'没有本地项目'` / `'所选项目没有 Dart 文件'`), and a busy indicator while
  loading.
- Disable (do not hide) actions that are temporarily unavailable
  (`onPressed: _busy ? null : ...`), preserving layout stability.

---

## Common Mistakes

- **Looking up dependencies globally in `build`.** Inject via constructor; keep
  `StudioProfile.current` access to the composition root.
- **Forgetting `super.key`** on a widget with a non-const-friendly child, or
  omitting `const` on a stateless constructor.
- **Adding a new page for content** that the existing core catalog/detail pages
  already render. Extend content, not UI.
- **Re-implementing core widgets** (code snippet, terminal, editor) instead of
  composing the core ones.
- **Hard-coded colors/sizes** instead of `Theme.of(context)` /
  `MediaQuery.sizeOf(context)`.
- **`setState` after `await` without a `mounted` check** (see
  [state-management.md](./state-management.md)).
- **No tooltip on icon-only buttons**, making the row unusable to assistive tech.
