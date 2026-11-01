# Draft content verifier (180 expansion lessons)

Design and operating contract for `tool/verify_draft_content.dart`, the gate that
executes every new draft lesson, its paired example, and its standalone exercise
on the real official Dart SDK and on the production portable engine.

## Ownership

This change owns exactly two paths:

- `tool/verify_draft_content.dart` (new)
- `.trellis/tasks/10-22-offline-ide-completeness/research/draft-verifier.md` (this file)

Nothing else is touched. In particular this work does **not** edit
`curriculum/**`, the aggregate `dart_curriculum.dart`, `assets/content/**`,
`lib/**`, `tool/portable_content_runner.dart`, other `tool/verify_*.dart`, tests,
`pubspec.*`, or any platform directory. Drafts are not promoted by this gate.

## Purpose

`tool/verify_dart_content.dart` verifies the original 120 installed lessons
against the aggregate. The 180 expansion drafts (ids 121..300) live in
`curriculum/chapters/*.dart` and are not yet wired into the aggregate or the
generated assets. This gate verifies them in place, without promoting them.

The gate answers three questions per unit and records the evidence:

1. Does the real official Dart SDK compile and run the exact source, and does its
   stdout match the authored `output` (lessons and examples) or serve as the
   reference (exercises)?
2. Does the production portable engine (`runPortableContent`, i.e. tom_d4rt via
   `PortableDartRuntime`) reproduce that same stdout exactly?
3. Is the draft inventory itself complete, contiguous, unique, and structurally
   sane?

## Independent inventory (the denominator)

The expected inventory is declared in the tool as constants. It does not track
the authored files, so a missing, extra, duplicated, or misplaced draft is
reported instead of silently shrinking the gate.

| Item | Value |
| --- | --- |
| Lesson ids | `dart-lesson-121` .. `dart-lesson-300`, contiguous |
| Lessons | 180 |
| Chapters | 16 |
| Paired examples | 180 (one per lesson) |
| Standalone exercises | 180 (exactly one per lesson) |
| Total executable units | 540 |

Chapter ranges (key -> first..last lesson number):

| Chapter key | Range |
| --- | --- |
| `numbers-strings` | 121..132 |
| `text-processing` | 133..144 |
| `algorithms-basic` | 145..156 |
| `algorithms-advanced` | 157..168 |
| `data-structures` | 169..180 |
| `math-stats` | 181..192 |
| `oop-modeling` | 193..204 |
| `enum-states` | 205..215 |
| `errors-resilience` | 216..226 |
| `json-modeling` | 227..238 |
| `dates-money` | 239..249 |
| `collection-reporting` | 250..261 |
| `formatting-output` | 262..272 |
| `async-patterns` | 273..283 |
| `apis-contracts` | 284..294 |
| `mini-apps` | 295..300 |

Draft bodies are read by importing the 16 chapter lists directly
(`numbersStringsLessons` .. `miniAppsLessons`). The aggregate is deliberately not
used: it still exposes only the original 14 chapters.

## Unit model

One unit is one executable program:

| Kind | Source | Expected stdout |
| --- | --- | --- |
| `lesson` | `lesson.code` | authored `lesson.output` |
| `example` | `lesson.resolvedExampleCode` | authored `lesson.output` (shared) |
| `exercise<N>` | `exercises[N-1].answer` | real SDK stdout (reference) |

Every lesson currently uses `exampleCode == null`, so `resolvedExampleCode`
resolves to `lesson.code`. The report marks such units
`"sharedBodyWithLesson": true` and `"sourceOrigin": "shared-with-lesson"`; the
gate never pretends the example body is distinct. Examples are still separate
units and are executed separately on both engines.

Exercise answers have no authored `output`, so the real SDK run is the reference
and the portable engine must match it. This mirrors `verify_dart_content.dart`.

## Engines and lifetime

Official SDK, through the production helper, not a raw `dart` shell-out:

- `const NativeDartToolchain().resolveExecutable()` resolves the SDK exactly as
  the app does (`QFLI_DART_SDK`, `DART_SDK`, `FLUTTER_ROOT`, PATH).
- `NativeDartToolchain.buildRunArguments(entry:, packageConfig:)` builds the
  argument list. The repository `.dart_tool/package_config.json` is passed when
  present, so any `package:` import resolves as in production.
- The child runs in a temporary scratch directory, stdout and stderr are decoded
  explicitly as UTF-8 so Windows codepage cannot mangle Chinese output.
- Per-unit SDK lifetime is bounded (`--sdk-timeout`, default 30s). On timeout the
  root process is sent `SIGKILL` and `exitCode` is re-awaited for 5s. The drains
  are bounded by their own 5s timeout, and a drain that does not close is an
  infrastructure error, never empty output (see Infrastructure handling).
- `finally` signals the **root** process only. This tool does not reap
  grandchildren and does not claim to: whole-tree containment and kill are the
  responsibility of the outer Windows Job gate.

Portable, through the real production path:

- `runPortableContent(source, timeout: ...)` from
  `tool/portable_content_runner.dart`. It starts `PortableDartRuntime` (tom_d4rt),
  captures stdout/stderr, and cancels the entire owned isolate tree in `finally`.
- Its own timeout cancels pending spawns. An outer guard also bounds the whole
  call, so the gate cannot hang even if that path misbehaves.

## Comparison rules

Comparison is exact, with two normalisations only:

- `\r\n` is treated as `\n` on both sides.
- Exactly one trailing newline is tolerated on either side. This is required
  because `print` emits `\n` while `runPortableContent` joins lines with `\n` and
  appends a final `\n`; a `stdout.write` with no newline must still compare equal.
- Spaces, including trailing spaces, are significant and are never trimmed.

A collapsed, padded, or otherwise altered line is a failure, not a near match.

## Source hashing

Each unit records `sourceHash` and `sourceLength` for the exact UTF-8 program
text. The hash is SHA-256, implemented locally and dependency-free: `crypto` is
only a transitive package here, and importing it would trip
`depend_on_referenced_packages`.

The local digest is self-checked at startup against the published RFC 6234
vectors for the empty string, `abc`, and the 56-byte vector. If any vector
mismatches, the gate exits `2` with an explicit message instead of hashing with
an unverified function. The hashes are for audit and change detection only; this
gate trusts no stored hash to stand in for execution.

## Reporting

Reports are written incrementally to JSON. The default path is
`.dart_tool/expansion-b/draft-verify<suffix>.json`; the suffix encodes the active
filters. `.dart_tool` is git-ignored, so reports never enter the index.

The report is written once after the static checks, then rewritten after every
unit, so a durable record survives an SDK or runtime startup failure. Top-level
keys:

- `verifier`, `generatedAt`, `repository`
- `engines` (resolved SDK path, portable path description)
- `normalisation` (the exact tolerance, stated for the reader)
- `inventory` (declared counts, id range, chapter map)
- `selection` (active filters, selected/skipped counts, `denominator`,
  `lowersDenominator: false`, `historyTrusted: false`)
- `counters` (`passed`, `failed`, `infrastructureFailures`, `notRun`, `records`)
- `structure` (`ok`, `failures`)
- `infrastructure` (`notes`, `halted`)
- `cleanup` (`ok`, `failures`) — scratch-directory retention, reported not assumed
- `gate` (`ok`, `fullCoverage`, `inventoryComplete`, `reason`)
- `units` (one record per unit)

Per-unit record evidence:

- `unit`, `kind`, `lessonId`, `chapter`, `number`, `sourceOrigin`,
  `sharedBodyWithLesson`, `expectedKind`
- `sourceHash`, `sourceLength`
- `passed`, `failure` (present only on failure)
- `sdk`: `exitCode`, `timedOut`, `launchError`, `durationMs`, `stderr`, and
  `stdoutLength`/`stdoutHash` when the pipes closed. If a pipe did not close,
  `streamError` is set and the report says `stdoutKnown: false` instead of
  showing an empty string that could be read as real empty output.
- `portable`: `timedOut`, `error`, `durationMs`, `outputLength`, `outputHash`,
  and captured `output` on failure
- `notRun` marker where the unit was filtered out or the batch halted. There is
  no `reused` marker: no unit is ever credited from a previous run.

Captured text is bounded to 4000 characters per field so the report stays
readable; hashes and lengths are always recorded.

## Filters and the denominator

Filters select what a run executes. They never lower the denominator:

- `--chapter=<key>` (repeatable / comma separated)
- `--start=<n>`, `--end=<n>`
- `--kind=lesson|example|exercise` (repeatable / comma separated; `all` resets)
- `--limit=<n>` for a bounded run
- `--inventory-only` performs the static checks with no execution
- `--report=<path>`, `--sdk-timeout=<s>`, `--portable-timeout=<s>`, `--help`

When any filter or `--limit` is active, or in inventory-only mode, the gate
reports `fullCoverage: false` and `gate.ok: false`. Units removed by a filter are
still recorded, as `notRun` entries, so the report always accounts for all 540
units. `inventoryComplete` requires 540 records and zero `notRun`.

`--resume` is refused with a usage error (`exit 3`). A stored pass does not
fingerprint the SDK, the portable vendor, the expected stdout or the engine
evidence, so it cannot stand in for a run in the current environment. Every
selected unit always runs. A prior report is at most a human reference; no
verdict from it is reused or counted.

## Exit codes

| Code | Meaning |
| --- | --- |
| `0` | Full inventory executed and passed on both engines, structure clean |
| `1` | Content or behaviour failure (SDK/portable mismatch, nonzero exit, stderr) |
| `2` | Infrastructure failure (SDK missing/unsupported, launch failure, timeout, OOM) |
| `3` | Usage error |
| `4` | Partial run (filtered, limited, or inventory-only) with no other failure |

## Infrastructure handling

- SDK executable cannot be resolved, or the platform is unsupported: record an
  infrastructure note, mark the gate, and exit `2`. No unit passes or skips.
- SDK launch failure, per-unit timeout, a stuck output drain, or detected OOM
  (`out of memory`, `cannot allocate memory`, `std::bad_alloc`) is an
  infrastructure failure. The unit is recorded as infrastructure, the batch
  **halts**, and every remaining unit is recorded as `notRun`. Continuing after a
  failed or memory-starved SDK would produce meaningless results.
- A drain that does not close within 5s is never treated as empty output. The
  captured values are marked unknown and the unit is infrastructure; an empty
  substitution could otherwise let an empty-output program look like it passed.

## Static checks (run before any engine work)

Identity and inventory:

- Authored lesson count equals 180.
- Authored ids equal `121..300` exactly: no gaps, no extras.
- No duplicate lesson ids.
- Each lesson's `chapter` equals the chapter declared by its id range.
- Total standalone exercises equal 180.

Per-lesson content:

- `title`, `summary`, `explain`, `objective`, `code`, `output`, `exampleTitle`,
  `exampleSummary` are non-empty.
- `concepts` and `pitfalls` are non-empty; `exercises` is non-empty.
- Each exercise has non-empty `prompt`, `hint`, `answer`; each `answer` has
  `main(`.
- `code` is multi-line (>= 3 lines), contains `main(`, and contains no
  placeholder marker (`TODO`, `FIXME`, `<code>`, `placeholder`, 待补, 待实现,
  未完待续).

Uniqueness (whitespace-normalised, so a re-indent does not hide a copy):

- 180 distinct lesson bodies.
- 180 distinct example bodies.
- 180 distinct `explain` prose.
- Distinct `title`, `summary`, `exampleTitle`, `exampleSummary`.

## Exact CLI

Run from the repository root (SDK and portable execution, host window required):

```powershell
# Full gate, all 540 units on both engines.
dart run tool/verify_draft_content.dart

# One chapter.
dart run tool/verify_draft_content.dart --chapter=mini-apps

# A lesson-number window.
dart run tool/verify_draft_content.dart --start=250 --end=261

# One unit kind only.
dart run tool/verify_draft_content.dart --kind=exercise

# Bounded run: stop after 20 units. Nothing is reused; every selected unit runs.
dart run tool/verify_draft_content.dart --limit=20

# Static checks only, no execution, never a passing gate.
dart run tool/verify_draft_content.dart --inventory-only
```

## Validation status

**UNRUN on the SDK and the portable engine.** No `dart`, `flutter`, analyze,
build, or device command has been executed for this gate. The host execution
window is not available yet, and the original installed OHOS 240-lesson gate must
pass before promotion; host checks require a separate fresh named execution
window.

Source-only checks that were performed (light Python static checks, no Dart):

| Check | Result |
| --- | --- |
| Inventory: 180 lessons, ids 121..300, 0 gaps, 0 duplicates | Confirmed |
| Exactly one exercise per lesson (180 total) | Confirmed |
| `exampleCode` never set (0 occurrences) | Confirmed |
| 16 chapter list export names match the imports | Confirmed |
| `DartLesson` / `DartExercise` fields and `resolvedExampleCode` exist | Confirmed |
| `runPortableContent(String, {Duration timeout})` signature | Confirmed |
| `NativeDartToolchain.resolveExecutable()` is an instance method; `supported` and `buildRunArguments` are static | Confirmed |
| Delimiters balanced across the tool source (string-aware scan) | Confirmed |
| Only `Map<String, Object?>` occurrence left is the `Json` typedef | Confirmed |
| Lines over 80 characters are comments or the usage string only | Confirmed |
| No cross-run reuse: `--resume` refused, no `reused` counter, no verdict from a prior report is credited | Confirmed |
| No `onTimeout: () => ''` fabrication; a stuck drain sets `streamError` and halts as infrastructure | Confirmed |
| `finally` signals the root process only; whole-tree kill is delegated to the outer Windows Job gate | Confirmed (by inspection) |
| Scratch deletion failure is reported with the retained path, not assumed reclaimed | Confirmed (by inspection) |

Gates that remain unverified until a host window exists:

| Gate | Status | Note |
| --- | --- | --- |
| Full 540-unit run on the official SDK and portable engine | UNRUN | Needs execution window |
| SHA-256 self-check at runtime | UNRUN | Fails loudly (`exit 2`) if wrong |
| `dart format --output=none --set-exit-if-changed tool` | UNRUN | Hand-formatted; not run |
| `flutter analyze --no-pub` (tool is analyzed with the repo) | UNRUN | Not run |
| Windows SDK resolution and UTF-8 stdout capture | UNRUN | Exercised only at run time |
| Drain-timeout path (`streamError`) | UNRUN | Only reachable when a pipe stalls |
| Scratch-directory cleanup failure path | UNRUN | Only reachable on a held handle |
| `--resume` rejection exit code `3` | UNRUN | Not executed |

## Relationship to the original gate

This gate complements `tool/verify_dart_content.dart`; it does not replace it.
The original installed OHOS 240-lesson gate remains the acceptance gate for
promotion. Draft content stays in `curriculum/chapters/*.dart` until that gate
passes and a separate promotion change wires the 16 chapters into the aggregate
and the generated assets.

## Remaining concerns

- The 180 paired examples share their lesson body, so example coverage currently
  proves the engine on the lesson code a second time. Distinct example bodies are
  a future authoring task, not something this gate can create.
- Any draft that uses a construct tom_d4rt cannot execute will fail here and must
  be rewritten within the author rules in `expansion-plan.md`; the gate reports
  the failure but does not modify drafts.
- A hand-rolled SHA-256 is a deliberate dependency trade-off; the startup
  self-check is the safety net for the recorded audit hashes.
- There is no cross-run reuse. Every gate run re-executes the selected units, so
  a full pass is always a fresh pass in the current environment. A future
  environment-fingerprint scheme could allow safe reuse; none exists today.
- `dart format` and `flutter analyze` have not run, so style compliance is
  asserted by hand, not proven.