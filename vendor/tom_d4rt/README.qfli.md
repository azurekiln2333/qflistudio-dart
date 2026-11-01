# QFLIDartWing offline interpreter fork

Vendored from the pub.dev source package `tom_d4rt` version **1.229.0**.
Upstream archive SHA-256 (recorded in the original hosted lockfile):
`2eb61cf0b768dc49f61d28f69c59cbe066d0f1fa3813827045430b1f3a74ebe7`.
The upstream MIT license and copyright remain in `LICENSE`; this copy uses
version `1.229.0+qfli.1`, Dart 3.11.5 and analyzer 8.4.1. Its source is part of
the app build and is never fetched at product runtime.

This fork repairs numeric/contextual bindings, typed async results, nullable
unawaited calls, record display, native whereType filtering, Function/class
identity and constructor tear-offs. Its real isolate bridge reconstructs
source and referenced lexical captures with fresh globals/statics. It preserves
native collection types/immutability, uses a root-owned native spawn broker,
waits for pending creation and exit, and publishes ordered exit markers so
product output drains before streams close.

The opt-in `OfflineHostPolicy` adds project/scratch IO roots, per-run temp/current
directories and output streams. It rejects network/native process execution,
host process exit/global cwd changes, standard input and symbolic-link traversal.
Permissions are still explicit grants under that ceiling. Native `spawnUri` is
unsupported. Filesystem imports remain disabled by the product: only preloaded
project sources and supported standard libraries are visible.

The bridge explicitly rejects unsupported bound/host callbacks, interpreted
object/type/late captures and certain cross-library local-function captures.
This is a bounded interpreter, not the complete official Dart VM. The product
uses direct root source with a canonical `sourceUri` and a preloaded URI map;
it does not depend on the upstream `execute(library:)` double-initialization path.

Retained product tests are in `test/portable_dart_runtime_test.dart`,
`test/portable_isolate_supervisor_test.dart` and the offline-policy test. The full
content gate calls the same product implementation. Host JIT/AOT, OHOS build and
physical-device execution are separate evidence; none implies the others.
Legacy EVC compilation continues to use the separately pinned dart_eval package.
