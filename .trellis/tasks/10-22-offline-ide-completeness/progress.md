# Progress — October 22, 2026

## Verified product batch

- Direct Tools tab embeds real project source, format/save/check/compile/run/Stop,
  terminal access, common tools and AST structure/import navigation. Full-page
  callers retain their original route.
- `DartCodeAnalyzer` implements the actual frozen core provider API. Exact unsaved
  snapshots, UTF-16/CRLF offsets, open Dart buffers, root containment and honest
  unavailable vs clean syntax results are tested. Scope is explicitly parser-only.
- Independent review reproduced a hidden retained tools page guarding another
  tab's back action. Embedded route protection now follows the core home page's
  `TickerMode`; unsaved buffers remain retained. Standalone behavior is unchanged.
- Full Flutter suite: **116 passed**, including SDK compile/run/output checks for
  all old content. Scoped analysis and formatting pass. This does not establish
  portable or OHOS device success.
- C `w1R:p1` and Java `w28:p1` were informed via Herdr: Dart owns no shared UI
  files and no Java files. Common core remains C's coordinated writer scope.

## Existing portable content gate

`tool/verify_portable_content.dart` executes every tutorial and paired example,
without the previous 43-ID whitelist. Initial report `research/portable-baseline.json`:
**240 checked, 154 failures** on production dart_eval 0.8.5. It captures errors and
actual stdout with bounded worker lifetime; failures produce nonzero exit status.
No new production content is added before old content is fixed.

## Experimental engine research (not shipped)

- d4rt 0.2.4: 68/240 failures.
- tom_d4rt 1.229.0: 20/240 stdout/error failures, with analyzer 8.4.1 override
  matching the production dependency. Its built-in Isolate.run simulates execution
  on the same isolate; passing output for those lessons does not prove correctness.
- d4rt 0.2.6 with analyzer 8.4.1 fails compilation on new analyzer AST APIs.
- Ignored `.dart_tool` candidate copy of tom_d4rt preserves MIT attribution.
  Experiments repair actual numeric binding, record canonical display and
  unawaited dispatch. Production runtime/dependencies remain unchanged.
- Direct copying of interpreter closures can run in real host isolates, but
  incorrectly copies mutated global/static values and overcaptures unsendable
  interpreter state. Rejected as a complete bridge. A source reconstruction
  design is being probed with fresh global initialization and selected captures.

## Open gates

Old portable content, +180 meaningful paired entries, shared-core final reviewed
integration, OHOS release build and actual phone execution remain incomplete.
HDC has no connected target. Native subagents recovered temporarily for bounded
reviews/research; Pi endpoints still return intermittent 502 and cannot be counted
as completed work without files/tests. Initial startup/signing/license changes
remain separate from this task's commits.
