# Dart OHOS package/audit tooling review

Owner: p5 (OHOS audit packaging tools). Scope: `tool/ohos/**` and this report only.
No common-core writes. No source edits outside `tool/ohos/**`. No git stage,
commit or push. No signing credentials, release profiles or persistent SDK
config were rewritten.

## 1. Boundary: old artifact vs current native guard

The signed x64 audit HAP `build/dart-audit/dart-catalog-x64-700336efe21b71ac.hap`
is the frozen artifact built from core `daddce27eed1f9389efed0360a0ca954af422da8`
and the production 120/120 assets. It predates the current native offline guard.
Package and signature inspection of this file prove manifest, ABI, assets,
fingerprint and signature. They cannot prove the current EntryAbility URL refusal,
because the guard is native source behavior, not packaged data.

The tools now state this boundary explicitly instead of implying it:

- `inspect_dart_hap.py` reports `nativeGuardVerified: false` and lists the guard
  test as a pending gate.
- `build_dart_audit.ps1` reports `gates.nativeGuardVerified = false` and lists the
  guard test as pending.
- `verify_dart_hap.ps1` reports `nativeGuardVerified: false` and widens
  `trustScope` to keep installed acceptance and the native guard separate.

A rebuilt HAP from current source is still required before any claim that the
shipped package contains the guard. Root owns that build and the guard test.

## 2. Preserved old evidence (unchanged by this review)

| Artifact | SHA-256 |
| --- | --- |
| `build/dart-audit/dart-catalog-x64-700336efe21b71ac.hap` | `700336efe21b71acee178e6f7ad7949e7623f0f7c423fad9d7b930d241307589` |
| `build/dart-audit/build-20261022T171532720.json` | `9370d2b88a7ad9988662c0447221dfb4e97197881109078147586a6d2497cff5` |
| `build/dart-audit/package-20261022T171532720.json` | `d4357cf8a0aabee6343fd6300966332a8a5022308c204193186602561d45a4eb` |
| `build/dart-audit/verify-20261023T020947782/signature-report.json` | `16061383e03e323e16767328a984493245a361ed804c333e6a1fa9d59d955b17` |

The old build report records `coreRevision daddce27...`, `expectedTopics 120`,
`buildExitCode 0`, and all three restoration flags true. The old signature report
records bundle `com.azurekiln.qfli.dart`, profile `release`, distribution
`app_gallery`, `deviceVerified false`. These files were read only; their bytes
were not modified.

## 3. Tool hashes after this review

| File | SHA-256 |
| --- | --- |
| `tool/ohos/build_dart_audit.ps1` | `3d81878ddb63016b12bbef361eb823693c61dac498a066aa808cba102a0feef4` |
| `tool/ohos/inspect_dart_hap.py` | `99afc8e47d7f3afd867cabe17fcf48281acb5c9012e52eee155ea4ebeb1ee001` |
| `tool/ohos/verify_dart_hap.ps1` | `2d66879faa2ca454762e5611c4c168d0efb1e3e1a7406bd5b13539b7b45061f8` |
| `tool/ohos/test_inspect_dart_hap.py` | `a3e67eea8a66f2095a9b021c271adea2b1c6f41dc60fac2e5d26e77db5dc9aad` |

## 4. Gaps found and fixed

### 4.1 Identity configs were not fingerprinted

`inspect_dart_hap.py` read bundle, vendor, version, module and permissions from
`ohos/AppScope/app.json5`, `ohos/entry/src/main/module.json5` and `pubspec.yaml`,
but never recorded those config bytes. A later config edit could reuse an older
report without detection.

Fix: added `IDENTITY_SOURCES` and `identity_fingerprints()`. The report now has
`fingerprints.identitySources` with the SHA-256 of all three configs. The build
report records the same three hashes under `fingerprints.identitySources`, and the
signature report records them under `identitySources`.

### 4.2 Package and signature reports implied more than they proved

Neither report named the native guard. Both now carry `nativeGuardVerified: false`
and a pending-gate entry for `test/native_entry_ability_test.cjs`. The signature
report also records its own `toolSha256` and the HAP byte size so the report is
self-describing.

### 4.3 Tests did not cover the new guarantees

Added two fixture tests to `test_inspect_dart_hap.py`:

- `test_identity_source_fingerprints_are_pinned` checks all three identity hashes
  match the fixture files.
- `test_native_guard_is_never_claimed` checks the guard flag stays false and the
  guard test stays pending.

## 5. Gaps reviewed and left as intended separation

- Exact asset denominator: `build_dart_audit.ps1` derives the count from authored
  assets, requires tutorials == examples, and rejects a disagreeing
  `ExpectedTopics`. `inspect_dart_hap.py` checks packaged == authored, requested ==
  authored, kind, schema, ids and language. No change needed.
- ABI/ELF: the inspector checks ELF class/data/version/type/machine, requires
  `libapp.so` and `libflutter.so`, rejects stray `.so` outside `libs/`, and rejects
  more than one ABI directory. No change needed.
- Permissions: the inspector rejects a fixed network/sensitive set and requires the
  packaged set to equal the declared set. No change needed.
- Immutable artifact: the inspector hashes before and after inspection, and
  `--expect-sha256` pins the value. The build script copies the HAP and re-hashes
  the copy. No change needed.
- Finally restoration: the build script restores profile bytes, package_config
  bytes, `JAVA_TOOL_OPTIONS`, working directory, the core snapshot and the lock,
  then writes the report and throws if any restoration failed. No change needed.
- `verify_dart_hap.ps1` does not re-check module name, mainElement, deviceTypes or
  pubspec version. That duplication is intentional: the inspector owns manifest
  identity, and the verifier owns signature, profile and packaged release flags.

## 6. Actual checks run in this review

All checks below are Python or PowerShell parsing only. No Dart, Flutter, Java,
SDK, Hvigor, build, HDC or emulator command was run.

- `python tool/ohos/test_inspect_dart_hap.py`: 30 tests, 30 passed, 0 failed.
- PowerShell parse of `build_dart_audit.ps1`: 0 errors.
- PowerShell parse of `verify_dart_hap.ps1`: 0 errors.
- Read-only inspector run against the preserved old HAP with
  `--abi x86_64 --topics 120 --expect-sha256 700336ef...`:
  `ok true`, no failures, `immutableVerified true`, `releaseModeVerified true`,
  bundle `com.azurekiln.qfli.dart`, version `1.0.0+1`, libs
  `libs/x86_64/libapp.so` and `libs/x86_64/libflutter.so`, assets 120/120 with
  SHA-256 `2f0a65bb...` and `dbf85c17...`, `nativeGuardVerified false`.
- Current authored assets match the old HAP payload: tutorials 120 entries
  `2f0a65bbe05b652a3f54b86e6e9fda6c3ea124091bd37958d10a61f07050d194`, examples 120
  entries `dbf85c172bfd92ae2f1d81af87698f93bf76ba8f116183db4e325b15820ce05d`.

## 7. Not run (unverified)

- No HAP was rebuilt from current source. The current native guard is not proven to
  be in any package.
- `flutter build hap --release --target-platform ohos-x64`, Hvigor and any packaging
  step were not run.
- `verify_dart_hap.ps1` was not executed because it needs Java and the sign tool.
  The existing signature evidence under `verify-20261023T020947782` is unchanged.
- `test/native_entry_ability_test.cjs` was not run here; root owns it.
- No installed-device execution exists. `deviceVerified` stays false.

A pass of the package inspector on the old HAP proves packaged identity, ABI, assets
and immutability for that frozen file only. It does not prove the current source,
the native guard, the signature (separate tool) or installed behavior.
