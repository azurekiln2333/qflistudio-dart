# Type Safety

> Dart static typing and null safety. This project is **not TypeScript** — there
> is no `tsconfig`, no `any`, no Zod/Yup/io-ts. The equivalent is Dart's type
> system: sound null safety, `final`/`const`, sealed/immutable models, and
> explicit JSON parsing.

---

## Overview

Dart is statically typed and null-safe. `analysis_options.yaml` inherits
`package:flutter_lints`, so `flutter analyze` flags implicit `dynamic` misuse,
missing types, and unsafe casts. Prefer the type system over runtime assertions:

- `final` by default for fields and locals; `const` for compile-time constants.
- Avoid `dynamic` at module boundaries; parse into typed models immediately.
- Nullable types (`T?`) are explicit; never use `!` to paper over a real
  possibility of null.

---

## Type Organization

- **Domain models live in the core** (`../qfli_studio_core/lib/models/`):
  `Project`, `ExampleCode`, `TutorialContent`, `ExampleContent`. This repo
  consumes them; it does not fork them.
- **Repo-local value types** are small immutable classes with a `const`
  constructor and `final` fields, e.g.:
  ```dart
  // lib/dart_tools.dart
  class DartDiagnostic {
    const DartDiagnostic({required this.message, required this.code,
      required this.severity, required this.line, required this.column});
    final String message; final String code; final String severity;
    final int line; final int column;
  }
  ```
  and `CompiledDartProgram`, `DartProjectSources`, `AndroidDartSdkLayout`.
- **Records** are used for local aggregates instead of ad-hoc maps, e.g.
  `Future<({int exitCode, String stdout, String stderr})> _run(File file)` in
  `tool/verify_dart_content.dart`, and `ProgramRunResult` fields.
- **Static facades**: `abstract final class DartTools` / `abstract final class
  AndroidDartSdk` group related pure behavior and cannot be instantiated.

---

## JSON Parsing (the "validation" layer)

There is **no schema library**. Validation is explicit, defensive parsing at the
boundary, converting untyped `Map`/`List` into typed models and skipping
malformed records rather than throwing:

```dart
// core/lib/services/example_code_store.dart (_fromJson)
static ExampleCode? _fromJson(Map<String, dynamic> json) {
  final id = json['id'] as String?;
  final type = json['type'] as String?;
  final title = json['title'] as String?;
  final code = json['code'] as String?;
  if (id == null || type == null || title == null || code == null) return null;
  return ExampleCode(
    id: id, type: type, title: title, code: code,
    summary: json['summary'] as String? ?? '',
  );
}
```

Rules:
- Cast field-by-field with `as T?`; validate presence; return `null` for a
  record that cannot be built.
- Use `?? default` for optional fields; never assume a key exists.
- Wrap `jsonDecode` in `try … on FormatException` / `on TypeError` and degrade to
  empty state at the caller.
- Decode child output explicitly as UTF-8 where non-ASCII is possible:
  `Process.run(..., stdoutEncoding: utf8)` (see `tool/verify_dart_content.dart`).

---

## Null Safety Patterns

- **Nullable result means "not applicable", not "failed."**
  `DartProgramRunner.run` returns `ProgramRunResult?`; `null` means the file is
  not a Dart/`.dill` entry (`lib/dart_runner.dart`). A real failure is a
  non-zero result.
- **Promote with local finals**, then use non-null:
  ```dart
  final path = _filePath;      // String?
  if (path == null) return false;
  await File(path).writeAsString(source, flush: true);
  ```
- **Pattern matching for narrowing** is the house style (Dart 3):
  ```dart
  if (Platform.environment['QFLI_DART_SDK'] case final String root) …
  if (_current case final AndroidDartSdkLayout layout) return Future.value(layout);
  ```
- **Avoid `!` except for provably-safe invariants**, and prefer a guard/promotion
  instead. `_storage!` is used only after the store has asserted non-null storage.

---

## Common Patterns

- `abstract final class` for stateless namespaces (`DartTools`, `AppPaths`).
- `static bool get supported` as the single platform-capability gate.
- Records for narrow multi-value returns; small `const` classes for named public
  value types.
- `switch`/pattern matching for branching on shapes and enums.
- Generic free functions only when a real type parameter is needed; otherwise a
  concrete type is clearer.

---

## Forbidden Patterns

- **`dynamic` at a module boundary**, or passing untyped `Map<String, dynamic>`
  through several layers. Parse once at the edge.
- **`as` casts on untyped JSON without a null check** — validate first.
- **Non-null assertion (`!`) to silence the analyzer** on a genuinely nullable
  value. Use a guard, promotion, or pattern match.
- **`ignore:` comments to hide a type error.** Fix the type; only suppress a lint
  with a documented reason when the lint is wrong.
- **Mutable global variables.** Use `final`/`const` or a scoped object.
- **A parallel model.** Reuse core models (`Project`, `ExampleCode`, …) rather
  than defining a lookalike.
- **Introducing TypeScript/JS tooling concepts** (Zod, `any`, `interface`)
  into Dart code — they do not exist here.
