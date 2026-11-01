# Dart analyzer hardening: false-clean boundaries

Scope of this note: `lib/dart_code_analyzer.dart`, `test/dart_code_analyzer_test.dart`.
Read-only inputs: `qfli_studio_core/lib/services/code_analysis.dart`,
`qfli_studio_core/lib/editor/editor_analysis_controller.dart`,
`qfli_studio_core/lib/editor/editor_diagnostics.dart`,
`qfli_studio_core/lib/editor/editor_page.dart`,
`.trellis/spec/frontend/dart-tools.md`.

No core, UI, platform, main or startup file was edited. The provider runs no
user code, reads no source file and writes nothing.

## 1. Why "false clean" is the failure mode

`CodeAnalysisResult` separates two outcomes:

- `unavailableReason == null` + empty `diagnostics`: the backend really checked
  the source and found nothing.
- `unavailableReason != null`: the backend could not check, and the UI must say
  so instead of showing clean.

The editor consumes the first outcome as `checked == true` and renders
"本地检查未发现问题". So any input the provider cannot attribute to exactly one
Dart buffer must be rejected with a reason. Guessing produces diagnostics on the
wrong buffer or a clean verdict for unchecked text.

## 2. Boundaries audited

| Boundary | Before | Risk | Now |
| --- | --- | --- | --- |
| Request language | ignored | a non-Dart request could be answered with Dart parser output | reject unless `language == 'dart'` |
| Relative project/active path | `p.absolute` silently resolved against the process CWD | diagnostics attributed to an unrelated file | reject if not `p.isAbsolute` |
| Active file type | only `p.isWithin` | a non-`.dart` active buffer could be analyzed | reject unless active ends `.dart` |
| Active snapshot present | `.any(...)` | duplicate input still passed | require a non-empty active group |
| Exactly one active snapshot | not checked | two aliases of one path analyzed twice | reject when the active path maps to more than one snapshot |
| Active revision vs `request.revision` | ignored | stale text reported as the current revision | reject on mismatch |
| Other buffer revisions | n/a | (do not require all revisions equal) | only the active revision is checked |
| Duplicate path aliases | not checked | two diagnostics for one file, ambiguous ranges | reject when any normalized path repeats |
| Document path absoluteness | normalized with `p.absolute` | CWD guessing | reject a non-absolute document path |
| Emitted `filePath` | raw `document.path` | contract requires normalized absolute | emit the normalized path |

Ownership and kinds were already correct and are unchanged: `p.isWithin(root, …)`
for root ownership, `.dart`-only filtering, non-Dart files and outside-root files
excluded.

## 3. What the shared core already owns

The provider does not duplicate these:

- debounce, generation and stale text/revision/root rejection.
- 64-document and 4 Mi UTF-16 unit caps.
- re-validation that every returned `filePath` is absolute, root-owned, has a
  non-empty message, `0 <= startOffset`, `startOffset <= endOffset`, and that
  `endOffset <= snapshot.text.length`.
- squiggles and Problems navigation.

The provider still rejects bad input itself, because the frozen contract places
honest availability on the provider and other consumers may not repeat the core
checks.

## 4. Preserved guarantees

- Exact unsaved text is analyzed, so CRLF and UTF-16 offsets stay aligned with
  the editor buffer. No line-ending normalization.
- Ranges stay half-open and clamped inside the captured text. The end clamp now
  has the start as its lower bound, so `endOffset >= startOffset` always holds.
- `source` is always `Dart 语法`.
- Parser-only honesty: undefined names and type errors are outside parser scope,
  so valid syntax yields empty diagnostics with a null reason. This is a completed
  check, not a claim of semantic correctness.
- Severity mapping also covers `hint`. Unknown severities fall back to `error`.

## 5. Tradeoffs

- **Strict rejection of duplicate aliases.** Two snapshots for one normalized
  path are rejected even when their text is identical. Text equality is not
  enough to pick a buffer, and rejecting is cheaper to reason about than
  de-duplicating silently. Cost: a caller that sends a redundant alias gets an
  unavailable result instead of a normal one. Core's `editor.files` does not
  produce such duplicates, so this only fires on a caller bug.
- **Absoluteness is required, normalization is not.** An absolute but
  unnormalized path is accepted and normalized. Only relative paths are rejected,
  because normalization is unambiguous while resolution against the CWD is not.
- **Windows identity lowercases the whole normalized path**, matching the core's
  own `_identity`. This keeps provider and core duplicate detection in agreement.
- **`code` stays UPPER_SNAKE** (`EXPECTED_TOKEN`), the analyzer enum name. The
  official CLI prints the lowercase form (`expected_token`). Changing it is a
  presentation change outside this guard pass, so it is left as is and recorded
  here.
- **No SDK semantic analysis here.** Type/lint/import diagnostics need a Dart SDK
  directory and `AnalysisContextCollection`. That is a separate provider
  extension. Until then the editor's "clean" verdict means clean *syntax* only.

## 6. Tests authored (source only, not run in this session)

`test/dart_code_analyzer_test.dart`:

Kept and still valid (active revision 7 equals request revision 7 in each):

1. `analyzes exact unsaved CRLF and UTF-16 source without changing disk`
2. `checks other open Dart buffers and excludes foreign/outside files`
3. `valid parser result is distinct from missing snapshot availability`

Test 1 also asserts a parser-independent UTF-16 position: the first CRLF starts
at unit 5 after the surrogate-pair emoji, and the unmatched brace sits at unit
32. The test previously relied only on `DartTools.syntaxDiagnostics` output for
offsets, which would not catch a shared offset bug.

Added:

4. `rejects a non-Dart language request instead of reporting clean`
5. `rejects a relative project or active path`
6. `rejects a non-Dart active file`
7. `rejects a duplicate active snapshot alias`
8. `rejects a stale active revision but keeps other revisions free`
9. `rejects duplicate aliases of a non-active buffer`
10. `emits normalized absolute diagnostic paths`
11. `rejects an absolute active file outside the project root`
12. `rejects a duplicate active alias with identical text`
13. `rejects a non-absolute document path`

Test 11 covers the `_activeOutsideRoot` guard, which had no test before. Test 12
proves that identical text does not merge two snapshots for one path.

## 7. Unrun verification (root runs in the serial window)

No SDK, Dart, Flutter, analyzer, test, build or device command ran in this
session. There is no fresh host grant. The following are **UNRUN**:

- `flutter test --no-pub test/dart_code_analyzer_test.dart`
- `flutter analyze --no-pub lib/dart_code_analyzer.dart test/dart_code_analyzer_test.dart`
- `dart format lib/dart_code_analyzer.dart test/dart_code_analyzer_test.dart`
- full `flutter test --no-pub` regression

Expected first run risks to check: that the Dart 3 or-pattern
`'info' || 'information'` in the severity switch analyzes clean on the pinned
SDK, and that `Isolate.run` accepts the private `_DartSnapshot` list across the
isolate boundary.

Source-only cleanup done in this pass: `test/dart_code_analyzer_test.dart` had
no trailing newline, which `dart format` would rewrite. The file now ends with
one newline. Line endings stay LF to match the rest of the file. No CRLF was
introduced.