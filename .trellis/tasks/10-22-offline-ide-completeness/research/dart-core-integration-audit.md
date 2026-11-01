# Dart product ↔ common-core integration audit (R4/R6/R7/R8/R9)

Read-only review. Writes: this file only. No core or product source was modified.
No SDK/Flutter/Dart/native/build/device command and no control action was run.
Only read-only git queries (`rev-parse`, `status --porcelain`) were used to pin
revisions.

## 1. Exact revisions and WIP state

| Repo | HEAD | Working tree |
| --- | --- | --- |
| `D:/MyNewProjects/qfli_studio_core` | `2f9039a3ba95449679b17257b0313c1ee3644a2c` | Dirty: 42 entries (29 modified, 13 untracked) |
| `D:/MyNewProjects/qfli_dart` | `01c67142053a3c324aef11368fa11dd5ebada2aa` | Dirty: 146 entries |

Core files in this audit that are uncommitted at HEAD: `lib/content/local_content_adapter.dart`,
`lib/pages/home_page.dart`, `lib/pages/local_content_pages.dart`, `lib/pages/tools_grid.dart`,
plus untracked `test/main_saved_workspaces_tab_test.dart`, `test/main_workspace_actions_test.dart`.
So R4/R7/R8/R9 core behavior below is **current WIP source, not a frozen release**.

Note: the earlier signed Dart audit HAP was built from core `daddce27…` (see
`build/dart-audit/build-20261022T171532720.json`). Current core HEAD is `2f9039a3…`.
The two are different revisions; no artifact here was rebuilt against `2f9039a3…`.

## 2. Evidence taxonomy used below

- **SRC** — read directly in current source at the revisions above.
- **TEST-SRC** — an existing test file was read; it was **not executed** here.
- **RUN** — real current execution evidence. **None collected in this session.**

No row below is acceptance. Nothing here proves an installed device or a built
artifact.

## 3. R4 — multi-language chips and title language circles (C/C++ distinct)

| Item | Evidence |
| --- | --- |
| Product profile | SRC `lib/main.dart`: `dartProfile` sets `templates: [empty, dart]`, `productKey: dartWing`, `showHomeTabs: false`, `supportedFileExtensions: ['.dart'(, '.dill')]` |
| Chips filtering | SRC core `studio_profile.dart` `filterLanguages(...)`; `home_page.dart:695-699` `_languageChips = profile.filterLanguages(...)`; `home_page.dart:759-760` `showLanguageChips = showHomeTabs && chipList.length > 1` → hidden for the Dart product by design |
| Content tab language | SRC `home_page.dart:253,261` pass `language: profile?.id ?? qfliStudioKey` → `'dart'` into the local content pages |
| Title circle | SRC `local_content_pages.dart:342,702-703` `LanguageBadge(language: subject)`; `language_badge.dart:4-7` normalizes `c++→cpp`, `:9-24` labels `'C'` vs `'C++'`, `'Dart'` at `:16`; circle shape `:28-59` |
| Content filter chips | SRC `local_content_pages.dart:608-629` `ChoiceChip` per available language (Dart-only content ⇒ `全部` + `Dart`) |
| Dart content source | SRC `lib/dart_content_repository.dart` loads only `dart_tutorials.json`/`dart_examples.json` via `ContentCatalog.fromJson`, filters with `filter.matches` |
| Coverage | TEST-SRC `test/dart_app_test.dart:50-53` `filterLanguages → ['Dart']`; core `test/header_owner_language_test.dart` (C/C++ header precedence); `test/local_content_filters_test.dart` (modified WIP) |

Status: source-complete for a single-language product. Chips are intentionally
hidden for Dart; the title circle and C-vs-C++ distinctness are core-owned. No run.

## 4. R6 — unsaved-buffer diagnostics, messages, Problems panel

| Item | Evidence |
| --- | --- |
| Product provider | SRC `lib/main.dart` `codeAnalyzer: const DartCodeAnalyzer()`; SRC `lib/dart_code_analyzer.dart` implements `CodeAnalyzer`: rejects non-`dart`, relative paths, outside-root, missing/duplicate/stale active snapshot; emits UTF-16 offsets, `source='Dart 语法'`; runs in `Isolate.run`; never executes user code or writes files |
| Core public API | SRC `lib/services/code_analysis.dart`: `CodeAnalyzer`, `CodeDocumentSnapshot`, `CodeAnalysisRequest`, `CodeDiagnostic`, `CodeAnalysisResult`, `CodeDiagnosticSeverity` |
| Provider hookup | SRC `editor_page.dart:269` `analyzer: StudioProfile.current?.codeAnalyzer` → `EditorAnalysisController` |
| Request build / stale drop | SRC `editor_analysis_controller.dart:174-194` builds request; `:196-246` accepts bounded, owned, in-range diagnostics; `:248-270` `_current` drops stale root/revision/text |
| Squiggles | SRC `editor_analysis_controller.dart:225-233` pushes accepted diagnostics to `file.diagnostics`; `editor_diagnostics.dart:20-68` decorates |
| Problems panel | SRC `editor_page.dart:65` enum `_BottomPanel.problems`; panel `:2515-2521`; status bar `:3102-3106`; `editor_problems_bar.dart:15-70,72-160` |
| Messages | SRC `editor_problems_bar.dart` status text (`_status`) and per-problem `location()`; problems echoed into Output `editor_page.dart:1735-1747` |
| Coverage | TEST-SRC core `test/editor_analysis_test.dart`, `test/editor_problems_visibility_test.dart` (product-scoped provider availability); product `test/dart_code_analyzer_test.dart` |

Status: implemented in current core WIP; product provider is scanner/parser level
only (no type/lint/dependency claims). No run.

## 5. R7 — file-tree state survives reopening; multi-project workspace

| Item | Evidence |
| --- | --- |
| Product capability | SRC `lib/main.dart` `dartProfile` does not set `supportsSavedWorkspaces`; SRC core `studio_profile.dart` default `supportsSavedWorkspaces = true` |
| Workspace scope | SRC `home_page.dart:333` adds `_ProjectScope.workspace` when supported; `:600-601` `SavedWorkspacesTab`; `:1118` opens the editor with the workspace |
| Multi-root tree | SRC `file_explorer.dart:148-169` `_workspace`/`_roots`; `:524-539` `_captureWorkspaceExpansion`; `:657-671` `_persistExpanded`; `:71-85` saved-workspace + `onWorkspaceChanged`; `:295-317` legacy per-project history fallback |
| Reopen persistence | SRC `file_explorer.dart:597-634` restores per-root expansion from the workspace document or `history.json` |
| Coverage | TEST-SRC core `test/saved_workspace_capability_test.dart`, `test/main_workspace_explorer_test.dart`, `test/workspace_editor_session_test.dart`, `test/workspace_store_test.dart`, untracked `test/main_saved_workspaces_tab_test.dart`/`test/main_workspace_actions_test.dart` |

Status: implemented; core WIP (home_page/local_content modified). Multi-project
sharing and reopen are core-owned. No run, no device restart check.

## 6. R8 — real offline debug/log/output/terminal; explicit unsupported

| Surface | Availability for the Dart product | Evidence |
| --- | --- | --- |
| Terminal | **Real** | SRC `lib/main.dart` `terminalCommandDelegate: dartTerminalDelegate`; SRC `lib/dart_runner.dart` (run/compile kernel/format/analyze/`--version`; `pub`/`global` refused); core `terminal_pane.dart`, wired `editor_page.dart:2495-2496,2589` |
| Output | **Real** | SRC `editor_output_panel.dart:6-66` `EditorOutputBuffer` (bounded 128 Ki UTF-16), `:68-127` `EditorOutputPanel`; wired `editor_page.dart:1814`; problems also echoed `:1735-1747` |
| Debug console | **Present, debugging unavailable** | SRC `editor_output_panel.dart:129-196` `EditorDebugConsolePanel` ("只读日志；当前后端不提供表达式求值"); Dart profile sets no `debugger` → `editor_debug_controller.dart:300` throws `当前产品未安装离线调试器`; `editor_debug_widgets.dart:62` shows `本产品未提供离线调试器`; wired `editor_page.dart:1819` |
| Ports | **Present, no Dart listener** | SRC `editor_output_panel.dart:198-291` `EditorPortsPanel` lists only the app preview session; Dart profile sets no `webPreviewFactory` → `当前没有由应用启动的预览监听器` (`:266`); wired `editor_page.dart:1824` |
| Breakpoints | **Explicitly unsupported** (no debugger backend) | SRC `editor_debug_controller.dart:175,179,228`; no `StudioDebugger` installed by the product |
| Runtime declaration | SRC `lib/main.dart`: `runtimeKind = supported ? 'official-dart-sdk' : 'offline-dart-interpreter'`; `runtimeStatus = Android ? 'available' : supported ? 'requires-sdk' : 'unavailable'`; SRC `lib/native_dart_toolchain.dart:18-22` `supported` excludes OHOS → on OHOS status is `offline-dart-interpreter` / `unavailable` even though the portable interpreter runs |
| Coverage | TEST-SRC core `test/editor_output_panel_test.dart`, `test/terminal_pane_test.dart`, `test/sandbox_terminal_test.dart`; product `test/dart_terminal_delegate_test.dart`, `test/dart_terminal_surfaces_test.dart`, `test/dart_tools_page_test.dart` |

Status: terminal and Output are real; DebugConsole and Ports render with explicit
"not provided" messages rather than fake success; breakpoints are honestly
unsupported. No run.

## 7. R9 — Dart highlighting entry

| Item | Evidence |
| --- | --- |
| Extension → language | SRC core `highlight_themes.dart:55` `'.dart': 'dart'` |
| Grammar registration | SRC `highlight_themes.dart:35` `'dart': langDart` in `_languages`; `:235-283` resolves and registers the mode with size/line caps (`:31-32`) |
| Editor entry | SRC core `editor_page.dart` uses `HighlightThemes` for open project files; `.dart` files therefore highlight via the shared core |
| Custom grammars | SRC `highlight_import.dart` (TextMate import, 512 KiB cap), `pages/highlight_settings_page.dart` |
| Dart tools page | SRC `lib/dart_tools_page.dart` editor is a plain monospace `TextField` (no highlighter) — the tools page does **not** highlight; only the core `EditorPage` does |
| Coverage | TEST-SRC core `test/highlight_preferences_test.dart`, `test/highlight_worker_test.dart`; no Dart-specific highlighting test (product relies on core) |

Status: Dart highlighting exists only through the shared core editor for `.dart`
project files. Actual tokenization is core-owned and was not run. The Dart tools
page is unhighlighted by design.

## 8. Explicitly unavailable / open, not claimed

- No real current-run evidence: no Flutter test, no analysis run, no build, no
  device. Every "Status" above is source reading plus unexecuted test files.
- Debugging (breakpoints/step/variables) is unavailable for Dart: no
  `StudioDebugger` is installed.
- Ports shows no Dart listener: no `webPreviewFactory` is installed.
- OHOS `runtimeStatus` is declared `unavailable` while the portable interpreter
  runs; this is the product's own declaration, not a verified status.
- Core is WIP at `2f9039a3…` with dirty content/home/workspace files, and differs
  from the `daddce27…` revision used for the signed audit HAP.

## 9. Coordination boundary

Missing public evidence belongs to root and C, not this product:

- Actual tokenization/render checks for R9 and real editor render for R6 are
  core-owned runtime evidence.
- Workspace reopen/multi-root persistence proof (R7) is core-owned and needs a
  real restart run.
- The shared diagnostic/Problems UI and highlight settings are C-owned; this
  product must not reimplement them. The Dart product only supplies
  `DartCodeAnalyzer` and the profile flags.

No core or product source was changed, no public UI was duplicated, and no other
product was contacted.
