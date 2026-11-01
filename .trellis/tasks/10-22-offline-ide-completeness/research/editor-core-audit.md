# Shared core read-only audit — editor, content filters, explorer, diagnostics, highlighting

Audit date: 2026-10-22. Auditor: Dart product coordinator (read-only on `D:/MyNewProjects/qfli_studio_core`).
No core file, test, task or index card was modified by this audit. No core test was started after the C
coordinator claimed exclusive shared-core product writes.

## 0. Ownership / channel state at audit time

Source of truth read: `D:/MyNewProjects/qfli-core-release-sync.md`, core `.trellis/tasks/10-22-offline-content-explorer/`,
core `.trellis/tasks/10-22-offline-editor-analysis/`, `git status` + `git diff` of the core repo.

| Fact | Evidence |
| --- | --- |
| Core branch `main`, HEAD `6441a5a fix(core): release idle code focus and preserve terminal cancellation`. | `git log --oneline -1` |
| C/C++ coordinator `w1R:p1` is the **sole shared-core writer** for chips/badges, explorer/workspace persistence, diagnostic API/editor/Problems, and common highlighting. | release-sync.md table rows 2 and "Public API status" |
| Two core Trellis tasks are `in_progress`, both owned by that writer: `10-22-offline-content-explorer`, `10-22-offline-editor-analysis`. | `task.json` of each |
| Dart, Java, Python own only their products and must not write core. | release-sync.md rows 3–5 |
| Core working tree was **being actively written during this audit**: files appeared mid-session (`lib/services/code_analysis.dart`, `lib/widgets/language_badge.dart` were absent at first listing, present minutes later; `git status` grew from 2 to 11 modified/3 untracked files). | two `git status --short` snapshots |
| No core commit yet contains any of this batch. | `git status` shows all work uncommitted |
| `hdc list targets` empty on 2026-10-22 → no device evidence for any product. | release-sync.md "Verification state" |

Consequence: **every finding below is a snapshot of an uncommitted, moving tree.** Re-read the exact files
right before integration and record the core commit hash that Dart builds against.

### Files the C writer has touched in this batch (as observed)

```
 M lib/content/local_content_adapter.dart
 M lib/editor/file_explorer.dart
 M lib/editor/project_history.dart
 M lib/models/tutorial.dart
 M lib/pages/local_content_pages.dart
 M lib/services/example_code_store.dart
 M lib/services/studio_profile.dart
 M lib/services/tutorial_service.dart
 M lib/widgets/project_card.dart
 M test/local_content_lazy_catalog_test.dart
 M tool/verify_java_content.dart
?? lib/content/java_catalog_audit.dart
?? lib/services/code_analysis.dart
?? lib/widgets/language_badge.dart
?? test/file_explorer_state_test.dart
?? test/local_content_filters_test.dart
?? test/project_history_concurrency_test.dart
?? tool/java_content/java_topics_language.dart
```

Note `lib/pages/local_content_pages.dart` is **not** reserved for Dart. Dart must not edit it.

---

## 1. File-tree expansion reset on reopen — root cause was confirmed, fix exists, regression tests exist

### 1.1 Original defect (HEAD `6441a5a`)

`lib/editor/file_explorer.dart` at HEAD:

- `initState()` → `_rebuildRoot()` only. `_restoreExpanded()` was called **only** from `_switchProject()`.
- Therefore the first mount (app start, drawer open, editor rebuild) **never restored** `history.json`
  `expandedDirs`; the tree always came back collapsed to the root. Reopening the drawer or returning to the
  editor re-created the state object and re-collapsed.

### 1.2 Current (uncommitted) implementation

| Item | Location in current `lib/editor/file_explorer.dart` |
| --- | --- |
| `int _treeGeneration = 0;` / `Future<void>? _restoring;` | L110–111 |
| `initState` → `_rebuildRoot()` (optimistic remembered-project root) | L120 |
| `void _rebuildRoot()` increments `_treeGeneration`, clears `_children`/`_expanded`, re-adds root, `_loadChildren(_root)`, then `_restoring = _restoreExpanded();` | L144–153 |
| `void _switchProject(Project)` → `setState` + `store.setBrowsedProject` + `_rebuildRoot()` (no bare restore) | L156 |
| `Future<void> _restoreExpanded()` — captures `generation` **and** `projectPath`, normalizes each stored relative path, rejects paths outside the root (`p.isWithin`), awaits `Directory(abs).exists()`, loads missing children with `generation:` | L166–190 |
| `Future<void> _persistExpanded()` writes root-relative POSIX paths | L193 |
| `_loadChildren(FileNode, {int? generation})` drops results from an older generation | L224, L242 |
| `_refresh()` is generation-guarded across the whole loop | L247–258 |
| `Future<void> _toggle(FileNode)` awaits `_restoring` first so a tap cannot be overwritten by a late restore nor persist a partial set | L312–317 |

`lib/editor/project_history.dart` (current) adds a per-root serialized write queue:

- `static final Map<String, Future<void>> _writes = {}` keyed by `p.canonicalize(projectPath)`.
- `load()` waits for any queued write for the same canonical root before reading (`while (true)` loop that
  re-checks after each await) — this is what fixes the "reconstructed explorer reads `history.json` before the
  predecessor's `unawaited` save lands" race.
- `save()` / `saveExpandedDirs()` copy caller collections into snapshots **before** enqueueing, then write
  through `_write`; `_write` is the only writer and tolerates IO failure silently.
- Write failures still do not surface to the UI (intentional, unchanged).

### 1.3 Regression tests that already exist (untracked, owned by C writer)

`test/file_explorer_state_test.dart`
- `reconstructed explorer restores nested expansion` — expand `src/nested`, dispose the widget **immediately**
  (comment explicitly says the unawaited save may still be pending), remount, assert `nested` and `data.json`
  are visible.
- `closing and reopening the drawer keeps expanded folders` — real `Drawer` mount, close by tapping outside,
  reopen via the tooltip button, assert expansion survived.
- `rapid switches keep each project expansion and file ownership` — queues three `onSelected!` root switches
  before async reads finish, asserts no cross-root leakage of `nested`/`first.json`/`second.json`, asserts
  `store.lastBrowsedProjectId`, and asserts the opened tab's `projectRootPath` / `ownerProjectName` belong to
  the browsed root.

`test/project_history_concurrency_test.dart`
- `concurrent updates preserve both fields, expansionFirst=true|false`
- `load observes queued writes and each field keeps the latest update`
- `queued writes capture collections when save is called`
- `normalized aliases serialize updates to the same history file`
- `different projects keep independent sessions and expansions`

### 1.4 Verification actually performed by this audit

Read-only execution before the exclusivity message arrived; both runs finished cleanly and were not killed.

| Command | Result |
| --- | --- |
| `flutter test --no-pub --reporter expanded test/project_history_concurrency_test.dart` | `+6: All tests passed!` |
| `flutter test --no-pub --reporter expanded test/file_explorer_state_test.dart` | `+3: All tests passed!` |

An earlier combined invocation
(`flutter test test/file_explorer_state_test.dart test/project_history_concurrency_test.dart`) exceeded a
600 s wall clock and was abandoned; the per-file runs above are the authoritative evidence. Treat this as
host-only evidence; it says nothing about device behaviour.

### 1.5 Residual gaps in the explorer fix (for the C owner, not for Dart)

1. **`_toggle` awaits `_restoring` while `_restoring` never completes on a failing `ProjectHistory.load`?**
   `load()` cannot throw (its body is guarded), so `_restoring` always completes. OK — but `_restoring` is never
   reset to `null` after completion, so later toggles await an already-completed future (harmless, no leak).
2. **`_create` / `_delete` / `refresh` context menu call `_loadChildren(node)` without a generation.** If a
   menu action is in flight while the user switches roots, the stale result is applied to the new root's
   `_children` map keyed by the old absolute path. Keys are absolute so no wrong rows are rendered, but the map
   grows with unreachable entries. Minor; recommend passing `generation:` in every menu-triggered load.
3. **`_persistExpanded` is only called from `_toggle`.** Programmatic expansion (`_create` adding `dirPath`,
   restore) never persists. Acceptable, but a "new file into a collapsed folder" leaves the saved set stale.
4. **No test asserts that the *first* mount restores expansion when the process is cold** (i.e. `history.json`
   pre-seeded before the very first `initState`). The third test seeds two roots but immediately switches; the
   first test relies on a prior mount to create the file. Recommend one test that writes
   `ProjectHistory.saveExpandedDirs` before the first `mount()` and asserts the nested file is visible without
   any interaction. This is the closest analogue to the user-reported "每次打开重置展开".
5. **Drawer-close path** is covered; **`EditorPage` full rebuild / tab switch** is not directly covered.

---

## 2. Multi-root workspace — NOT implemented; what exists is single-root with cross-project browsing

Model facts:

| Item | Evidence |
| --- | --- |
| `Project` has exactly one `path`; no root list. | `lib/models/project.dart` |
| `ProjectStore.lastBrowsedProjectId` is a `String?` — one remembered root, persisted in the registry JSON. | `lib/store/project_store.dart` L66–68, L85, L153–161, L552–557 |
| The explorer renders **one** root: `_root` = `_browsing.path`; root row + its children only. | `file_explorer.dart` `_buildBody` ListView |
| Switching roots is `PopupMenuButton<Project>` → `_switchProject` → `_rebuildRoot()`; the previous root's `_children`/`_expanded` are **discarded**, and only the switched-to root's expansion is restored. | `file_explorer.dart` L156–164, L144 |
| `history.json` is per project root (`<root>/history.json`), so expansion and cursors never mix roots. | `project_history.dart` `historyFile` |
| Tabs *do* carry an owner root: `openPath(..., ownerProjectName, ownerProjectPath)` stores `projectRootPath` and `ownerProjectName` on the open file, so a tab opened from another project keeps correct identity. | `editor_controller.dart` L37–42, L71–72 |
| Session restore, however, reloads `session.openFiles` **relative to `widget.project.path`** only, so cross-root tabs are not restored after restart. | `editor_page.dart` L313–316, L372–376 |

Acceptance reading: PRD R7 says "multiple projects share a workspace". Today that is satisfied only as
"one root at a time with remembered browsing root and preserved tabs", **not** as a VS Code–style multi-root
tree. If the user means a tree that simultaneously shows several roots, core has no model, no persistence and
no tests for it — it is an unimplemented feature, not a bug. Recommend the umbrella task state that explicitly
and pick one: (a) declare single-root + cross-project browsing as the design, or (b) add
`workspaceRoots` to the registry/model. Do not let Dart assume (b).

Additional cross-root risk for Dart: `EditorPage` restores open files relative to the *current* project, so a
Dart tab opened while browsing another project's tree loses its restore path. Existing behaviour, not
introduced by this batch.

---

## 3. Diagnostics: wavy underlines / Problems — contract published, **no rendering exists yet**

### 3.1 Published contract (new, untracked, matches the design doc exactly)

`lib/services/code_analysis.dart` (whole file is new):

```dart
abstract interface class CodeAnalyzer {
  Future<CodeAnalysisResult> analyze(CodeAnalysisRequest request);
}
class CodeDocumentSnapshot { const CodeDocumentSnapshot({required String path, required String text, required int revision}); }
class CodeAnalysisRequest {
  CodeAnalysisRequest({required String projectPath, required String activeFilePath, required String language,
    required int revision, required List<CodeDocumentSnapshot> documents}); // documents is List.unmodifiable
}
enum CodeDiagnosticSeverity { error, warning, information, hint }
class CodeDiagnostic { const CodeDiagnostic({required String filePath, required int startOffset, required int endOffset,
  required String message, this.severity = CodeDiagnosticSeverity.error, this.source = '', this.code = ''}); }
class CodeAnalysisResult { const CodeAnalysisResult({this.diagnostics = const [], this.unavailableReason}); }
```

Offsets are documented as zero-based, half-open UTF-16 code units including both units of a CRLF. Empty
ranges are insertion points. `unavailableReason == null` means "really checked, possibly zero diagnostics".

Exposure: `StudioProfile` gained `final CodeAnalyzer? codeAnalyzer;` (constructor `this.codeAnalyzer,`) and
`lib/services/studio_profile.dart` now does `import 'code_analysis.dart'; export 'code_analysis.dart';`, so a
product can `import 'package:qfli_studio_core/services/studio_profile.dart';` and get both. Confirmed present
in the current tree.

### 3.2 What does **not** exist yet (verified by exhaustive grep over `lib/**`)

| Capability | Status |
| --- | --- |
| Any consumer of `StudioProfile.current?.codeAnalyzer` | **None.** Nothing reads the field. |
| Debounce / revision / generation scheduler for analysis | None |
| Wavy underline (`spanBuilder`, custom painter, dotted border, `CodeLineEditingController.spanBuilder`) | None. Only `TextDecoration.underline` inside the TextMate theme importer (`editor/highlight_import.dart` L114) and ANSI underline (`terminal/shell/ansi.dart`, `terminal/widgets/terminal_output.dart` L424). |
| Problems panel | **None.** `lib/editor/editor_page.dart` L51: `enum _BottomPanel { none, terminal, ai }` — no problems/output/debug tab. |
| Output panel | None |
| Debug console / debugger | None. No Variables/Watch/Step. Correct to keep absent rather than simulated. |
| `lib/services/code_analysis.dart` tests | None yet |

So R6 (squiggles + messages + Problems) is **0 % implemented** in UI terms; only the type contract landed.
Dart must not build its own panel.

### 3.3 Dart-side readiness (product adapter, this task)

`lib/dart_tools.dart`:

```dart
class DartDiagnostic { final String message, code, severity; final int line, column, offset, length; }
static List<DartDiagnostic> syntaxDiagnostics(String source) // parseString(content: source, throwIfDiagnostics: false)
```

- Uses `package:analyzer` `parseString` — syntax-only, no package resolution, no writes, no execution: exactly
  the "never run user code" requirement.
- `diagnostic.offset` / `diagnostic.length` are already UTF-16 code-unit ranges into the *same* string passed in,
  so they map 1:1 onto `CodeDiagnostic.startOffset` / `endOffset = offset + length`.
- Works on an unsaved buffer because it takes the string directly.

Integration mapping for the Dart provider once the C owner finalizes the consumer:

| Core field | Dart source |
| --- | --- |
| `activeFilePath` | captured active buffer path (must be a normalized absolute path inside the root) |
| `language` | `'dart'` |
| `revision` | the buffer revision Dart tracks for the active file |
| `documents` | active buffer + other open Dart buffers under the root, exact text |
| `CodeDiagnostic.filePath` | `request.activeFilePath` (syntax mode analyzes one unit; other buffers only overlay) |
| `startOffset` / `endOffset` | `offset` / `offset + length` |
| `severity` | see warning below |
| `code` | `diagnosticCode.name` |
| `source` | `'dart-analyzer'` (stable label for Problems grouping) |
| empty success | `const CodeAnalysisResult()` (no diagnostics, `unavailableReason == null`) |
| backend failure | `CodeAnalysisResult(unavailableReason: ...)` — never a silent empty list |

**Severity mapping trap:** analyzer's `DiagnosticSeverity.name` yields `error` / `warning` / `info`
(and historically `hint`), while core uses `information`. A naive `.name` copy produces `info`, which is not a
valid `CodeDiagnosticSeverity` value. Dart must map explicitly:

```
error -> CodeDiagnosticSeverity.error
warning -> CodeDiagnosticSeverity.warning
info/information -> CodeDiagnosticSeverity.information
hint -> CodeDiagnosticSeverity.hint
```

Do not change `DartDiagnostic.severity`'s existing string (the Tools tab already displays it and existing tests
assert it); map at the provider boundary instead.

**Other provider obligations from the design doc that Dart must honour:**
- Reject/normalize any path outside `request.projectPath`.
- Do not read `history.json` read-only snapshots; only live buffers.
- Ignore selection-only changes (core debounces, but the provider should stay cheap).
- Do not claim "clean syntax" when the analyzer fails; return `unavailableReason`.

---

## 4. Debug console / Output / Problems / Terminal — current capability inventory

### 4.1 Bottom panel surface

`lib/editor/editor_page.dart` L51 `enum _BottomPanel { none, terminal, ai }`; `_terminalVisible` derives from
it (L150); the app-bar actions at L1402–1428 toggle `terminal` and `ai`; `_buildTerminalPane` at L1885+ and
`AiPanel` at L1830+. There is no tab bar for a bottom panel and no Output/Problems/DebugConsole view. Any
"add a Problems tab" work is a structural change to this enum + layout and belongs to the C owner
(`10-22-offline-editor-analysis` design.md already says "Problems integrates as a real bottom-panel tab with
bounded layout and jump actions. Existing terminal retains stream/cancel/focus semantics.").

### 4.2 Terminal reality (shared, portable)

- Backend: `lib/terminal/shell/sandbox_shell_backend.dart` over `portable_filesystem.dart`, plus an optional
  product `TerminalCommandDelegate` (`StudioProfile.terminalCommandDelegate`) that Dart already injects.
- Portable builtins actually implemented (`portable_filesystem.dart` switch): `ls`/`dir`, `pwd`, `cat`, `echo`,
  `mkdir`, `touch`, `rm`, plus `cp`/`mv` via `_copyOrMove`. Unknown commands route to the delegate, otherwise an
  honest "unsupported" message (`sandbox_shell_backend.dart` L226).
- Explicitly **rejected** constructs: `|`, `&`, `;`, `>`, `<`, backtick, `*`, `?`, `[` (`sandbox_shell_backend.dart`
  L282–310). So no pipes, redirection or globbing — do not promise them in any Dart doc/UI copy.
- Session model `lib/terminal/models/terminal_session.dart`, tabs `terminal/widgets/terminal_tabs.dart`,
  output `terminal/widgets/terminal_output.dart` (ANSI), manager `terminal/state/terminal_manager.dart`.
- `kProgramNotRunExitCode == 127` convention is documented in `studio_profile.dart` and is the required signal
  when a Dart run backend cannot start. Dart's runner must keep honouring it.

### 4.3 Run output

`editor_page.dart` L1106 `pane.attachOutput(...)` feeds `ProgramRunner` streams into the terminal pane. There is
no separate "output channel" concept; program output and shell output share the terminal. Realistic feature set
for R8 is therefore: terminal + run streams + explicit "debugging unavailable" messaging. No breakpoints, no
variable inspection, no step-through.

---

## 5. Tutorials / examples: language chips, level chips, title language circles

### 5.1 What the C writer implemented (uncommitted; re-verify before integration)

`lib/widgets/language_badge.dart` (new) — shared circular badge:
`languageKey()` normalizes (`'c++'` → `'cpp'`, lower-case trim), `languageLabel()` renders `C`, `C++`,
`JavaScript`, `TypeScript`, `Python`, `Java`, `Dart`, `Lua`, `Rust`, `Go`, `Shell`, `MD`, `Web`, `Kotlin`,
fallback upper-case. `LanguageBadge(language:, size: 30)` is a `secondaryContainer` circle with `FittedBox`
text and `Semantics(label:)` + `ExcludeSemantics`. Used by `lib/widgets/project_card.dart` L168 (`size: 26`) and
by the content list titles.

`lib/models/tutorial.dart` — `TutorialLesson` and `ExampleCode` gained `final String language;` and
`final String level;` with defaults `''`; `ExampleCode.copyWith` preserves them; new
`ExampleCode.withCatalogMetadata(ExampleCode? bundled)` lets old saved overrides inherit bundled metadata.

`lib/services/tutorial_service.dart` — parses document-level `type`, `language`, `level` with chapter-level
`level` fallback and per-lesson/per-example `language`/`level` overrides; example→lesson projections carry
`language`/`level`.

`lib/content/local_content_adapter.dart` — passes `entry.language` / `entry.level` into the legacy
`TutorialLesson` / `ExampleCode` models.

`lib/services/example_code_store.dart` — saves/loads `language`/`level` only when non-empty, and merges
`_custom[id]?.withCatalogMetadata(_defaults[id])`, so legacy saved code keeps working.

`lib/pages/local_content_pages.dart` — `_TutorialList` / `_ExampleCodeList` became stateful with a shared
`_ContentFilterSelection { TextEditingController query; String? language; String? level; }` and
`_ContentFilterBar`:

- query `TextField` (`ValueKey('content-query')`) matching `'{chapter.title} {lesson.title} {lesson.summary}
  {concepts}'` plus the language label; words are ANDed (`words.every(searchable.contains)`);
- `ChoiceChip` language row with `ValueKey('content-language-all')` and `ValueKey('content-language-$key')`,
  built from `_contentLanguage(lesson.type, lesson.language)` = `languageKey(type.isEmpty ? language : type)`;
- `ChoiceChip` level row with `ValueKey('content-level-all')` / `ValueKey('content-level-$level')`, values
  normalized `trim().toLowerCase()`, labels localized (入门/进阶/高级) by a page-local `_ContentLabels` class;
- result count label, `ValueKey('content-reset')` reset button shown only while a filter is active, and
  `ValueKey('content-no-results')` empty state;
- chapter headers are dropped when all their lessons are filtered out.

Labels are page-local (`_ContentLabels`) — **no** `studio_localizations.dart` change was needed, and that file
is indeed unmodified. Good: no cross-product i18n churn.

`languageKey`/`languageLabel` distinguish C and C++ (`c` → `C`, `cpp`/`c++` → `C++`), satisfying the "C/C++
distinct" requirement.

### 5.2 Interactions Dart must know about

- **Chip source is per-page, not per-profile.** Choices are derived from the loaded rows, so the Dart product
  will show one language chip (`Dart`) plus three level chips. `StudioLocalizations.allLanguages` is reused for
  the "all" chip, so no new string is required.
- **`TutorialLesson.type` is the fallback language key.** Dart's aggregate JSON sets `language: "dart"` and
  `type: "dart"` on every lesson and `level` in `{beginner|intermediate|advanced}` (verified in
  `assets/content/dart_tutorials.json`), so both chips populate without Dart-side JSON changes.
- `LocalTutorialsTab` / `ExampleCodeTab` are otherwise unchanged; `StudioProfile.contentRepositoryFactory`
  still selects the Dart repository, so this is transparent to Dart.
- `StudioProfile.filterLanguages()` (home page project chips) still keys on `ProjectTemplate.language`
  display names, while `HomePage._languageFilter` compares `Project.language`. Those are the *project* chips,
  unrelated to the new content chips; no change needed for Dart, but note that the two chip systems now use
  different key normalization (`languageKey` vs raw names). If a project is stored with `language: 'C++'` and a
  template uses `'cpp'`, the home chips can miss. Out of scope for Dart; flag to the C owner.

### 5.3 Existing test coverage for the new content UI

`test/local_content_filters_test.dart` (untracked, C writer) exists; `test/local_content_lazy_catalog_test.dart`
was adjusted (diff touches 3 lines). Not executed by this audit (exclusivity).

---

## 6. Highlighting audit

`lib/editor/highlight_themes.dart` is the single registry (unchanged by this batch):

| Item | Evidence |
| --- | --- |
| Built-in modes | `dart, java, python, c, cpp, kotlin, javascript, css, xml(_htmlMode), json, markdown` (L27–42) |
| `_extToLang` | `.dart .java .py .c .h .cpp .hpp .cc .cxx .kt .kts .js .mjs .ts .jsx .tsx .css .scss .html .htm .xml .svg .json .md .markdown` (L44–75) |
| Limits | `maxFileSize = 256 KiB`, `maxLineLength = 2048` |
| TextMate | imported grammars registered by `grammar.scopeName` with a `tm:`-prefixed cache key, so an imported grammar wins over the built-in |
| Cache | `_cache` keyed by language or `tm:<scope>`; `forceRepaint` used by the editor after theme change |

Gaps relevant to the umbrella R9 (verified by grep: only `re_highlight/languages/{c,cpp,css,dart,java,javascript,json,kotlin,markdown,python,xml}.dart` are imported):

- **No Rust, Go, Lua, Shell/Bash, SQL, TypeScript (real grammar), Ruby, PHP, Swift.** `.ts/.tsx` map to
  `javascript`, which highlights most TypeScript but not types/`interface`/decorators/enums faithfully.
- **No `.rs`, `.go`, `.lua`, `.sh`/`.bash`/`.zsh`, `.sql`, `.rb`, `.php`, `.swift`, `.toml`, `.yaml`/`.yml`,
  `.ini`, `.diff`/`.patch` extensions.** Those files open with **no highlighting at all** in the editor.
- C/C++ header aliases are present (`h/hpp/cc/cxx`). `cpp` vs `c` selection is by extension only.
- Dart is covered (`dart` mode + `.dart`).

The C owner's `10-22-offline-editor-analysis` design already commits to adding
"missing default Rust/Go/Lua/Shell/SQL/TypeScript grammars and relevant header aliases" plus parameterized
tokenization tests per extension. Dart consumes the result; **Dart should not add grammars**.
Product-side consequence today: `.dart` is fine; a Dart project containing `.yaml`/`.toml`/`.md` gets partial
(`.md` is covered) or no highlighting. No action for Dart beyond documenting the limitation.

`test/highlight_worker_test.dart`, `test/highlight_preferences_test.dart`, `lib/pages/highlight_settings_page.dart`
exist for preferences; per-extension tokenization is what is missing.

---

## 7. Concrete recommendations

### For the C core owner (hand off, do not implement from Dart)

1. Treat `initState`-restore as **already fixed** with regression tests; do not re-fix. Instead add the missing
   cold-start test described in §1.5 item 4, and pass `generation:` in the context-menu `_loadChildren` calls
   (§1.5 item 2).
2. Publish the diagnostics consumer (`StudioProfile.current?.codeAnalyzer` scheduling + `spanBuilder` wavy
   spans + Problems bottom-panel tab) — currently only the types exist. Until then, Dart cannot show anything.
3. Decide and document the multi-root answer (§2). If single-root + cross-project browsing is the design, say so
   in the release-sync doc so R7 evidence can be written honestly.
4. When adding grammars, add a parameterized test that highlights a real snippet for **every** default
   extension in `_extToLang` plus new ones, asserting a non-empty token span set, not merely "no exception".

### For Dart (this task)

5. Keep the Dart provider a thin adapter: `DartTools.syntaxDiagnostics` → `CodeAnalysisResult`, with the explicit
   severity mapping table in §3.3 and `endOffset = offset + length`.
6. Wire `dartProfile.codeAnalyzer` in `lib/main.dart` next to `runner:`/`toolsTabBuilder:` (a one-line addition,
   the only core-overlapping surface).
7. Add provider tests that need no UI: unsaved-buffer text analyzed unchanged, empty source → empty success with
   `unavailableReason == null`, syntax error → exact offsets, CRLF text → offsets count both units, non-Dart
   buffer still returns `unavailableReason` rather than a fake clean result, and enormous input stays bounded.
8. Do not add content chips, badges, grammar maps, Problems UI, output panel or debugger to Dart. Rely on core.
9. Record in the Dart task that `.yaml/.toml/.rs/.go/.lua/.sh/.sql` highlighting is a **known core gap**, not a
   Dart defect, so acceptance for R9 is not silently claimed.

### Evidence discipline

10. Before integration, capture `git -C D:/MyNewProjects/qfli_studio_core rev-parse HEAD` and re-run the four
    new core test files plus `test/local_content_filters_test.dart`, recording pass counts. All of the above is
    uncommitted and was moving during the audit.
11. Host `flutter test` results are host-only. `hdc list targets` is empty, so no OHOS device evidence exists for
    any product; keep that gate explicit.

---

## 8. Audit verification log (this session)

| Action | Result |
| --- | --- |
| `git -C qfli_studio_core log/status/diff` | HEAD `6441a5a`; 11 modified + 3 untracked core files; no core commit for this batch |
| `git diff lib/editor/file_explorer.dart` at HEAD vs worktree | confirms `initState` restore bug at HEAD and the generation-guard fix in worktree |
| `git diff lib/editor/project_history.dart` | confirms new per-root write queue + snapshot-on-enqueue |
| `flutter test --no-pub test/project_history_concurrency_test.dart` | **6/6 passed** |
| `flutter test --no-pub test/file_explorer_state_test.dart` | **3/3 passed** |
| Grep `lib/**` for Problems / DebugConsole / spanBuilder / squiggle / wavy | no matches → no implementation |
| Grep `lib/**` for FilterChip/ChoiceChip/badge/LanguageBadge | content chips + `LanguageBadge` present after the C writer's edits |
| Grep `lib/editor/highlight_themes.dart` registry and `_extToLang` | 11 built-in modes; Rust/Go/Lua/Shell/SQL/TypeScript missing |
| Read `lib/services/code_analysis.dart`, `lib/widgets/language_badge.dart` | contract and badge match the design docs |
| `git status lib/i18n/studio_localizations.dart` | unmodified; new content labels are page-local (`_ContentLabels`) |
| Re-checked core `git status` after writing this file | identical 11 M + 3 untracked set; **this audit changed nothing in core** |

---

## 9. Dart adapter status (already landed in this product, for cross-checking §3.3)

`lib/dart_code_analyzer.dart` (untracked in `qfli_dart`) implements `CodeAnalyzer` already:

- normalizes `projectPath` and `activeFilePath`, returns `unavailableReason` when the active file is outside the
  root or has no captured snapshot (honest unavailable, never a fake clean result);
- filters `documents` to `.dart` files inside the root before analysis;
- runs `DartTools.syntaxDiagnostics` inside `Isolate.run`, so a large buffer does not block the UI isolate;
- maps `startOffset = diagnostic.offset.clamp(0, text.length)` and
  `endOffset = (offset + length).clamp(0, text.length)` — the clamp is a good guard for a stale offset;
- **already maps severity explicitly**: `warning → warning`, `info → information`, everything else `error`.
  This is the trap described in §3.3 and it is handled; `hint` currently falls through to `error`, which is
  acceptable for the analyzer's actual severity set but worth an explicit `'hint' => hint` arm for clarity;
- `source: 'Dart 语法'` is a display label for Problems grouping.

Residual adapter notes (no action required until core consumes the API):

1. Diagnostics are produced for **all** captured Dart buffers, not only the active one. The design allows this
   (they are all inside the root and all captured text), but Problems will then list other buffers' syntax errors.
   That is desirable; just be aware it is not "active file only".
2. `p.absolute()` without `p.normalize` first is applied via `p.normalize(p.absolute(...))`, which is correct on
   Windows drive-letter casing only if callers pass consistent casing; `ProjectHistory` uses `p.canonicalize`.
   If core ever passes a case-different path, `p.isWithin` may reject a legitimate file. Cheap hardening:
   also compare `p.equals` against the normalized root.
3. CRLF: `parseString` reports offsets against the exact string, so CRLF is preserved; the clamp keeps ranges in
   bounds. Add a CRLF test to `test/dart_code_analyzer_test.dart` if it is not already there.
4. Nothing consumes the profile hook yet (core §3.2). Wiring `dartProfile.codeAnalyzer` in `lib/main.dart` will
   have no visible effect until the C owner lands the editor/Problems consumer — do not ship a UI in Dart.

No core test was launched after the exclusivity instruction. No file under `D:/MyNewProjects/qfli_studio_core`
was created, edited or deleted by this audit. Nothing was committed anywhere.
