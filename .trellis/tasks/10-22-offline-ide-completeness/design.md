# Design

## Ownership and change boundary

The gaps are the portable whitelist leaving 77 lessons unexecuted, secondary Tools route and missing Dart unsaved-buffer diagnostics. They live in curriculum/verifier, `lib/dart_tools_page.dart`, `lib/dart_tools.dart` and product wiring. Core UI/explorer changes are owned by C coordinator. No duplicate editor, explorer or terminal here.

Owned files: `curriculum/**`, generated `assets/content/dart_*.json`, content tools/tests, `lib/dart_tools*.dart`, Dart editor adapter, task/spec evidence. Runner/source loader changes only for proven runtime gaps. `main.dart` gets minimal hook additions preserving previous startup work. Initial OHOS/signing files stay untouched.

## Runtime and authored content

Compile/execute every code unit with actual dart_eval in bounded worker isolates. Preserve stdout and errors; compare expected output and test distinct exampleCode. SDK validation complements portable validation. Compatibility labels cannot bypass execution. Repair code without erasing teaching semantics, or improve runtime bridges. Unsupported advanced features remain unresolved until correctly implemented, never hardcoded output.

New content uses the existing typed authoring model, unique programs and explanation/exercise data. JSON generation stays deterministic. Derive total and chapter counts, preserve old IDs and remove max-120 assumptions. Target 180 additional meaningful paired entries, tested on both engines.

## Tools and diagnostics

Reuse `StudioProfile.toolsTabBuilder` to embed Dart tools directly, with no nested Scaffold/AppBar. Retain the existing full-page constructor and shared terminal callback. Preserve generation/mounted checks, dirty Save/Discard/Cancel, operation exclusion and Stop. Use analyzer AST for useful local source inspection; never introduce network package resolution.

Consume the core owner's typed diagnostic API. Dart provides parser results from the unsaved source with offset/length, code, severity, message and line/column. Core owns debounce, stale suppression, squiggles and Problems navigation. Parser validation is syntax checking, not project-wide type analysis.

## Compatibility and limits

Optional profile hooks leave other products unchanged. Focused commits stage exact paths and leave initial startup/signing changes unstaged. Review the owner's core revision before integration. HDC currently has no target. Host portable testing does not prove device execution. Debugging requires real stepping/variable APIs; parsing prints is not breakpoint debugging. Network/Ports features are excluded.
