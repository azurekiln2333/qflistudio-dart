# Expansion C: lessons 239–300

Date: 2026-10-22. Ownership: six new Dart curriculum chapter files only.
No core, Java, runtime/vendor, existing chapter, aggregator, generator, asset,
model or test edits were made by this author. Root owns integration.

| Chapter | File/list | IDs | Lessons / paired examples |
| --- | --- | --- | --- |
| dates-money | `dates_money.dart` / `datesMoneyLessons` | 239–249 | 11 / 11 |
| collection-reporting | `collection_reporting.dart` / `collectionReportingLessons` | 250–261 | 12 / 12 |
| formatting-output | `formatting_output.dart` / `formattingOutputLessons` | 262–272 | 11 / 11 |
| async-patterns | `async_patterns.dart` / `asyncPatternsLessons` | 273–283 | 11 / 11 |
| apis-contracts | `apis_contracts.dart` / `apisContractsLessons` | 284–294 | 11 / 11 |
| mini-apps | `mini_apps.dart` / `miniAppsLessons` | 295–300 | 6 / 6 |
| Total | | 239–300 | **62 / 62** |

## Content review

Every lesson has its own program, summary, explanation and topic, at least three
concepts, two specific pitfalls and a meaningful exercise with a complete runnable
answer. Explanations measure 190–250 characters, including at least 159 Chinese
characters. A lesson and its paired example intentionally share code; uniqueness
is required separately within each content type.

Dates use fixed UTC inputs and state leap-day, interval and due-date rules.
Money examples use integer cents where exact accumulation matters; illustrative
interest and tiered-fee formulas disclose their fictional parameters and rounding.
Text layout programs state ASCII/display-width limits. CSV correctly quotes commas,
quotes and embedded newlines. Version matching explicitly limits its grammar and
correctly narrows caret ranges for zero-major versions.

The superseded dart_eval research restrictions were not used to reduce async
semantics. New programs actually await Futures, run finite parallel batches,
catch failures occurring after await, retry within a bound, trigger real timeout,
observe the still-running original Future, propagate context, and coordinate
cancellation/cleanup. Fixed-window/token-bucket examples implement time-based
algorithms with injected timestamps; they do not pretend to demonstrate elapsed
wall-clock time. Mini apps perform real aggregation, validation, BFS path search
and two-stack expression evaluation. The evaluator tokenizes the original input
so spaces cannot merge adjacent numeric tokens into a different integer.

## Validation

SDK: `D:/ProgramFiles/flutter_ohos/bin/cache/dart-sdk/bin/dart.exe`.
Portable: the real product `runPortableContent` from
`tool/portable_content_runner.dart`, normal repository package configuration,
production vendored tom_d4rt; not a probe interpreter or mock.

Authoring helpers and raw execution evidence are isolated in
`.dart_tool/expansion_c/`. `final_verify.dart` imports the six actual authored
chapter lists, executes lesson and paired example independently on both engines,
compares stdout exactly after SDK CRLF normalization, and additionally executes
every complete exercise answer on SDK and portable with output comparison.
Failures remain nonzero and are reported with both outputs/errors.

Initial gates:

- Dates 11/11, formatting 11/11, APIs 11/11 and mini apps 6/6 passed SDK,
  two portable runs per pair, and SDK exercise execution.
- Histogram 252 initially exposed indexed postfix increment on a wrapped List.
  Root fixed the runtime with regression coverage; idiomatic `bins[index]++`
  was restored and the full chapter passed again on both engines.
- Async 273 initially exposed the engine deferring an async body before its first
  await. SDK prints stage-start before caller-continues, portable reversed them.
  Correct lesson source and SDK expectation were kept. The runtime owner fixed
  synchronous async prefixes and await ordering; lesson 273 now passes unchanged.

Final verification: **PASS — 62 lessons, 62 paired examples and 62 complete
exercise answers; 186 SDK executions + 186 product-portable executions;
0 failures.** Every tutorial/example output equals its authored expected stdout;
every exercise answer has identical successful stdout on both engines. The final
run imports all six actual chapter files and uses the final repaired vendor state.
282's direct awaited iterable now passes unchanged after the runtime fix.

Exact final command:

```powershell
D:/ProgramFiles/flutter_ohos/bin/cache/dart-sdk/bin/dart.exe run .dart_tool/expansion_c/final_verify.dart
```

Raw final per-unit checks: `.dart_tool/expansion_c/final-all.json`.
The complete per-ID pass matrix is retained below so the result is durable even
when ignored harness files are cleared. Root's shared all-content gates remain
responsible for final aggregate asset and app integration checks.

Metadata validation also imports all 30 chapter files directly: **300 contiguous
001–300 IDs, with unique IDs, titles, summaries, explanations and program bodies**.
The new 62 entries additionally satisfy all required concepts, pitfalls, exercise
and explanation-length constraints. Command: `dart run
.dart_tool/expansion_c/all_metadata.dart`.

No device build or phone execution was performed by this author. Host SDK and
portable success do not establish OHOS phone execution.

Formatting of six files completed, scoped `dart analyze` reports no issues, and
`git diff --check` of owned paths is clean. No commits were created by this author.

## Final per-ID execution matrix

| ID | SDK lesson/example/exercise | Portable lesson/example/exercise |
| --- | --- | --- |
| dart-lesson-239 | 3/3 pass | 3/3 pass |
| dart-lesson-240 | 3/3 pass | 3/3 pass |
| dart-lesson-241 | 3/3 pass | 3/3 pass |
| dart-lesson-242 | 3/3 pass | 3/3 pass |
| dart-lesson-243 | 3/3 pass | 3/3 pass |
| dart-lesson-244 | 3/3 pass | 3/3 pass |
| dart-lesson-245 | 3/3 pass | 3/3 pass |
| dart-lesson-246 | 3/3 pass | 3/3 pass |
| dart-lesson-247 | 3/3 pass | 3/3 pass |
| dart-lesson-248 | 3/3 pass | 3/3 pass |
| dart-lesson-249 | 3/3 pass | 3/3 pass |
| dart-lesson-250 | 3/3 pass | 3/3 pass |
| dart-lesson-251 | 3/3 pass | 3/3 pass |
| dart-lesson-252 | 3/3 pass | 3/3 pass |
| dart-lesson-253 | 3/3 pass | 3/3 pass |
| dart-lesson-254 | 3/3 pass | 3/3 pass |
| dart-lesson-255 | 3/3 pass | 3/3 pass |
| dart-lesson-256 | 3/3 pass | 3/3 pass |
| dart-lesson-257 | 3/3 pass | 3/3 pass |
| dart-lesson-258 | 3/3 pass | 3/3 pass |
| dart-lesson-259 | 3/3 pass | 3/3 pass |
| dart-lesson-260 | 3/3 pass | 3/3 pass |
| dart-lesson-261 | 3/3 pass | 3/3 pass |
| dart-lesson-262 | 3/3 pass | 3/3 pass |
| dart-lesson-263 | 3/3 pass | 3/3 pass |
| dart-lesson-264 | 3/3 pass | 3/3 pass |
| dart-lesson-265 | 3/3 pass | 3/3 pass |
| dart-lesson-266 | 3/3 pass | 3/3 pass |
| dart-lesson-267 | 3/3 pass | 3/3 pass |
| dart-lesson-268 | 3/3 pass | 3/3 pass |
| dart-lesson-269 | 3/3 pass | 3/3 pass |
| dart-lesson-270 | 3/3 pass | 3/3 pass |
| dart-lesson-271 | 3/3 pass | 3/3 pass |
| dart-lesson-272 | 3/3 pass | 3/3 pass |
| dart-lesson-273 | 3/3 pass | 3/3 pass |
| dart-lesson-274 | 3/3 pass | 3/3 pass |
| dart-lesson-275 | 3/3 pass | 3/3 pass |
| dart-lesson-276 | 3/3 pass | 3/3 pass |
| dart-lesson-277 | 3/3 pass | 3/3 pass |
| dart-lesson-278 | 3/3 pass | 3/3 pass |
| dart-lesson-279 | 3/3 pass | 3/3 pass |
| dart-lesson-280 | 3/3 pass | 3/3 pass |
| dart-lesson-281 | 3/3 pass | 3/3 pass |
| dart-lesson-282 | 3/3 pass | 3/3 pass |
| dart-lesson-283 | 3/3 pass | 3/3 pass |
| dart-lesson-284 | 3/3 pass | 3/3 pass |
| dart-lesson-285 | 3/3 pass | 3/3 pass |
| dart-lesson-286 | 3/3 pass | 3/3 pass |
| dart-lesson-287 | 3/3 pass | 3/3 pass |
| dart-lesson-288 | 3/3 pass | 3/3 pass |
| dart-lesson-289 | 3/3 pass | 3/3 pass |
| dart-lesson-290 | 3/3 pass | 3/3 pass |
| dart-lesson-291 | 3/3 pass | 3/3 pass |
| dart-lesson-292 | 3/3 pass | 3/3 pass |
| dart-lesson-293 | 3/3 pass | 3/3 pass |
| dart-lesson-294 | 3/3 pass | 3/3 pass |
| dart-lesson-295 | 3/3 pass | 3/3 pass |
| dart-lesson-296 | 3/3 pass | 3/3 pass |
| dart-lesson-297 | 3/3 pass | 3/3 pass |
| dart-lesson-298 | 3/3 pass | 3/3 pass |
| dart-lesson-299 | 3/3 pass | 3/3 pass |
| dart-lesson-300 | 3/3 pass | 3/3 pass |

## Authored file SHA-256 at final verification

| File | SHA-256 |
| --- | --- |
| `dates_money.dart` | `e8e111079b0277cc1f46be74cb6e9e99e708e0f93086ed8bd070a913338f49ee` |
| `collection_reporting.dart` | `a7aa9cf9a5d2717c76f0ca1f96a7b0ef28a6a6ed1584129a65142ce778095ed0` |
| `formatting_output.dart` | `d1eda50b609c7ca7517533ae400bbaf5332fe50b004c5df1e5b6d497796fba28` |
| `async_patterns.dart` | `436288630b02c79882575d42728887ef0bd08aca4346e3974ed57e018f4e69d6` |
| `apis_contracts.dart` | `f83553dddd8ae6cf4842cf65e5d4a80db77bb4cb71921018a120ecd359a1d518` |
| `mini_apps.dart` | `5e6659cb3e360d03de8587dc78e3f100eb5f6e1ad0aa0859c9ab6245281c0293` |
