# Design

## Ownership and change boundary

The gaps are the portable whitelist leaving 77 lessons unexecuted, secondary Tools route and missing Dart unsaved-buffer diagnostics. They live in curriculum/verifier, `lib/dart_tools_page.dart`, `lib/dart_tools.dart` and product wiring. Core UI/explorer changes are owned by C coordinator. No duplicate editor, explorer or terminal here.

Owned files: `curriculum/**`, generated `assets/content/dart_*.json`, content tools/tests, `lib/dart_tools*.dart`, Dart editor adapter, task/spec evidence. Runner/source loader changes only for proven runtime gaps. `main.dart` gets minimal hook additions preserving previous startup work. Initial OHOS/signing files stay untouched.

## Runtime and authored content

Execute every code unit through the production portable helper in bounded native workers. Preserve stdout and errors; compare expected output for each lesson and example even when they share code. SDK validation complements portable validation. Compatibility labels cannot bypass execution. Repair code without erasing teaching semantics, or improve runtime bridges. Unsupported advanced features remain unresolved until correctly implemented, never hardcoded output.

New content uses the existing typed authoring model, unique programs and explanation/exercise data. JSON generation stays deterministic. Derive total and chapter counts, preserve old IDs and remove max-120 assumptions. Target 180 additional meaningful paired entries, tested on both engines.

### Portable interpreter migration decision (October 22)

The complete dart_eval 0.8.5 baseline fails 154/240 programs. Reducing advanced
lessons would erase the requested semantics. Local source probes compare
d4rt 0.2.4 (68 failures), incompatible d4rt 0.2.6 (analyzer API mismatch), and
tom_d4rt 1.229.0 (20 failures). The repaired tom_d4rt candidate executes all
240 old units with matching output after lesson 048 explicitly supplies
`Pair<V, K>` constructor arguments; its generic-container lesson and SDK output
are preserved. The normal vendored product path now passes all 240; durable report
`research/portable-production-baseline.json` records real host execution.

Vendor the MIT-licensed candidate as `vendor/tom_d4rt`, pinned
`1.229.0+qfli.1` with analyzer 8.4.1 and retained upstream license/provenance.
Do not patch global pub cache or add a global analyzer override. Keep
dart_eval solely for the explicitly named legacy EVC compilation action;
the AST interpreter does not create EVC artifacts. Native SDK execution and
its no-fallback behavior remain unchanged.

`lib/portable_dart_runtime.dart` owns execution and stream/lifecycle policy;
the product runner and content gate call the same implementation. Flatten
`DartProjectSources.packages` into canonical package URI sources without
reading external files for imports. Parser errors, runtime errors, absent
imports and capability denial must produce nonzero results. Execute in a
native worker isolate. A root-owned supervisor creates the worker and every
descendant paused, registers their exit listeners, then resumes them. Finish,
error and cancel await supervisor shutdown; pending native spawns are killed
when they finish and rejected requests cannot create orphan descendants.

The repaired isolate bridge reconstructs source and selected lexical captures
in a fresh runtime, with fresh globals/statics and real native isolate handles.
It rejects unsupported interpreter-object, bound-host-function and late captures
explicitly. `spawnUri` must not load native user programs or bypass supervision.
Do not claim full Dart language or debugger compatibility.

Before shipping, prove real temporary-file IO works while network/process
execution are denied; stdio, process-global cwd/exit and source loading must
not escape the product execution policy. The interpreter's default permission
checks alone are not assumed to isolate all native bridge operations. Maintain
separate evidence for exact output, cancellation races, native host AOT build,
OHOS build and device execution. Rollback consists of reverting the focused
portable migration commit; experimental probe directories stay outside product
source and startup/signing work remains untouched.

## Tools and diagnostics

Reuse `StudioProfile.toolsTabBuilder` to embed Dart tools directly, with no nested Scaffold/AppBar. Retain the existing full-page constructor and shared terminal callback. Preserve generation/mounted checks, dirty Save/Discard/Cancel, operation exclusion and Stop. Use analyzer AST for useful local source inspection; never introduce network package resolution.

Consume the core owner's typed diagnostic API. Dart provides parser results from the unsaved source with offset/length, code, severity, message and line/column. Core owns debounce, stale suppression, squiggles and Problems navigation. Parser validation is syntax checking, not project-wide type analysis.

## Compatibility and limits

Optional profile hooks leave other products unchanged. Focused commits stage exact paths and leave initial startup/signing changes unstaged. Review the owner's core revision before integration. HDC currently has no target. Host portable testing does not prove device execution. Debugging requires real stepping/variable APIs; parsing prints is not breakpoint debugging. Network/Ports features are excluded.
