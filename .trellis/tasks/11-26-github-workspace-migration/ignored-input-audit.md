# Ignored input and private backup audit - 2026-11-27

Auditor: w5S:p5. Integration and move owner: w5S:p1.
Owned output: this file only.
Source: `D:/MyNewProjects/qfli_dart`.
Backup: `D:/MyNewProjects/_migration-backup/qflistudio-dart-20261127`.
Audited source commit: `24b6e11a80c26beef83eac00c594dd42e5bfc4c8`.

## Decision summary

- Preserve every item in the exact manifest below by MOVE, not deletion. This auditor performed no moves.
- Keep the three ignored Android wrapper inputs privately. Their local hashes identify preserved bytes, not verified upstream equivalence. The clean-cloud regeneration contract below is sufficient for the reviewed Android builds without importing these local files.
- Root adopts the exact portable `ohos/oh-package-lock.json5` bytes into tracked source and will add a root-only ignore exception. Keep this file in the source tree, not in the backup manifest.
- Keep the entry OHOS lock, npm package files and generated registrant out of the portable source set. They are generated/local inputs covered by the pinned clean-cloud sequence, with byte-equivalence limitations below.
- Preserve all of `ohos/.idea` as an editable-settings HOLD. Do not call it disposable cache.
- Preserve `.git/local-signing-backup/ohos-build-profile.json5` privately before any later retirement of the old clone. Do not publish its contents.
- Keep the old clone and tracked sources until root completes GitHub/main parity and target acceptance. These build runs are not final migration acceptance.

## Inputs and inspection boundary

Read the unified migration directive fully, the migration PRD/design/execution records, `cleanup-audit.md`, `remote-audit.md`, the prior journal preservation checkpoint, and relevant Trellis backend/platform/native-runtime and OHOS specifications. AGENTS.md and the unified directive override old local-validation examples in specifications.

Root confirmed that there is no separate prior ignored-source findings file. The supplied prior findings are: 46 ignored `.agents` files match `.trellis/.template-hashes.json`; the root OHOS lock contains public Hypium 1.0.6 with integrity; the entry lock contains machine paths; the wrappers are unverified generated inputs. The `.agents` template match is supplied prior evidence, not a fresh hash comparison by this auditor. The current guarded inventory independently found 46 regular `.agents` files.

Only static reads, read-only Git inventory/hash operations, GitHub API metadata/job logs and Herdr coordination were used. No build, test, analyzer, formatter, dependency installation, regeneration command, SDK/binary/artifact download, Git mutation, target-checkout write, WSL operation or filesystem move was performed. No private signing file contents were opened or printed.

Scope deviation disclosed to root: an early parent-directory filename search enumerated metadata outside this repository to depth four while looking for the named prior audit. It read no sibling file contents and performed no mutation. That discovery approach stopped. Subsequent filesystem inventory was confined to this repository, explicitly skipped reparse entries and nested repositories, and did not inspect their targets or contents. No further discovery is required.

## 1. Exact source-input findings

### Android Gradle wrapper

At the audited commit, only `android/gradle/wrapper/gradle-wrapper.properties` is tracked among these four files. The other three exist locally and are ignored by `android/.gitignore`.

| Source path | Bytes | SHA-256 of local bytes | Status |
| --- | ---: | --- | --- |
| `android/gradlew` | 4971 | `ec56c02543666d92d9ac5ae7fcc48f88ce4de0deb8b7f9b39928ca46f68c1b2b` | Ignored; preserve privately; no upstream byte verification |
| `android/gradlew.bat` | 2404 | `c13c6e91b9a517783976de213d46398c661ea9e17651376d7301e839eaedcc62` | Ignored; preserve privately; no upstream byte verification |
| `android/gradle/wrapper/gradle-wrapper.jar` | 53636 | `16caeaf66d57a0d1d2087fef6a97efa62de8da69afa5b908f40db35afc4342da` | Ignored; preserve privately; binary not executed or downloaded |
| `android/gradle/wrapper/gradle-wrapper.properties` | 201 | `297c9e63b6fa6e7e8b221900fa1787c1a0e38869d8957da66389fd0f6b00f78e` | Tracked; KEEP IN SOURCE, not in move manifest |

The properties file selects `gradle-8.14-all.zip`, with distribution/cache locations under `GRADLE_USER_HOME`. It contains no `distributionSha256Sum`. Preserve this tracked project selection; do not replace it with a regenerated default. Adding a verified distribution checksum is a possible separate source-hardening change, not work performed here.

Static reads show that both scripts invoke `org.gradle.wrapper.GradleWrapperMain` from `gradle/wrapper/gradle-wrapper.jar`. Familiar structure is not proof that these local scripts or JAR equal trusted upstream files. No JAR signature/content verification or comparison with downloaded upstream binary bytes was performed.

Recommended migration choice: retain the existing ignored-wrapper policy plus the exact pinned cloud contract in section 2, and privately preserve these local originals. If root instead tracks wrappers, verify trusted provenance and expected hashes first, review the scripts, preserve Unix executable mode, and make narrow ignore changes for all three files. Do not force-add this unverified local JAR merely because it is small or wrapper-shaped. The migration gate exempts the exact `gradle-wrapper.jar` filename from its generic JAR allow-list requirement; that is not an integrity attestation.

### OHOS root lock: portable input, not entry-local state

`ohos/oh-package-lock.json5` was ignored by `ohos/.gitignore:13` (`**/oh-package-lock.json5`). Its 678 bytes have SHA-256 `afefb3b851a63111b64ca0348f1b95088128524c565bbb0d4c2daefd4771af51`.

Root adopts these exact reviewed bytes into tracked source and will add a root-only exception in `ohos/.gitignore`. Keep the file at `S/ohos/oh-package-lock.json5`; do not move it to backup. The complete file contains lockfile version 3, stable order, non-unified lock mode and a single public package: `@ohos/hypium@1.0.6`. Its resolved host is `ohpm.openharmony.cn`; the path is the public Hypium 1.0.6 tarball. It records both SHA-512 integrity and shasum. No local filesystem paths or signing values occur in this root lock. The tracked `ohos/oh-package.json5` already pins the same development dependency exactly to `1.0.6`; tracked OHOS test sources import Hypium.

Do not unignore nested locks. Root owns the ignore-rule edit and Git staging. This audit records source adoption, not cloud byte identity.

### Entry-local OHOS lock, npm plugin files and registrant

| Source path | Bytes | SHA-256 of local bytes | Finding |
| --- | ---: | --- | --- |
| `ohos/entry/oh-package-lock.json5` | 2745 | `be52810121ffe08b4459544701047e84e966d51c60b58840a6dbf5d5632d9cf9` | Relative paths escape to the old ProgramFiles Flutter SDK and local Pub cache; includes debug ARM64/x64 HARs and path_provider_ohos |
| `ohos/package.json` | 127 | `c9bdf412797392aa854d3946d3aa4c6694ac48b1fafe60ed0f0249a222937223` | `flutter-hvigor-plugin` resolves through an absolute D-drive Flutter SDK path |
| `ohos/package-lock.json` | 649 | `1a9741930aa76667bd4fe3e7df06d96432fa7ec56ee0cfb1ff33237bace2dc5a` | Local file/link resolution into that SDK; not portable registry locking |
| `ohos/entry/src/main/ets/plugins/GeneratedPluginRegistrant.ets` | 693 | `ccdeac9291d7939df7433479050b4e137b917cae99c831a0bbe19af611898c2b` | Generated-file banner; imports/registers PathProviderPlugin from `path_provider_ohos` |

All four are untracked/ignored at the audited commit. The tracked entry package manifest has empty authored dependencies. Tracked `ohos/hvigorfile.ts` and `ohos/hvigorconfig.ts` import the Flutter Hvigor plugin. Tracked `EntryAbility.ets` imports the generated registrant and calls `registerWith`, so this generated file is required build input, not optional decoration.

Local regeneration evidence consists of those generated-file declarations, SDK/Pub-cache package paths, the local npm link record, and four reparse entries inside `ohos/entry/oh_modules`: Flutter embedding, ARM64 native, x64 native and path_provider_ohos. `ohos/node_modules/flutter-hvigor-plugin` is another junction. Targets were not traversed. The old local entry lock's debug/x64 contents must not be confused with the clean-cloud ARM64 release package contract.

Keep these local bytes privately. Do not transplant their paths into the E-drive checkout. Recreate their necessary build roles in disposable hosted runners through the pinned workflow, not through a local `npm install`, `ohpm install`, Flutter bootstrap, or manually copied SDK/Pub-cache tree.

## 2. Verified clean-cloud regeneration contract

Repository for all API/log references: `azurekiln2333/qflistudio-dart`.
Both supplied runs were independently confirmed through the GitHub API as completed/success, attempt 1, at full SHA `24b6e11a80c26beef83eac00c594dd42e5bfc4c8`. Both started November 26, 2026 at 17:24:46 UTC, which is November 27, 2026 at 01:24:46 UTC+08. They ran the candidate branch, not an assertion that main or the target clone already matched it.

The commands below specify existing CLOUD behavior only. They were not executed locally by this audit. Preserve the versioned workflow/helpers and their checks. A toolchain/pin/source change requires new exact-SHA cloud evidence.

### Android wrapper regeneration

Run `45867515254`, workflow `.github/workflows/application-build.yml`:

1. Use fresh GitHub-hosted jobs: Ubuntu 24.04 for both Android ABIs and Linux, Windows 2022 for Windows desktop. Check out the application to `qfli_dart` with no copied local ignored inputs or restored old-worktree outputs.
2. Check out shared core `573d1b6eecf1c2b392ad753264a5a09f62f8335e` to sibling `qflistudio-core`. Check out official Flutter `00b0c91f06209d9e4a41f71b7a512d6eb3b9c694` (3.41.9) to sibling `flutter` and bootstrap it as the workflow specifies.
3. Run `python tool/ci/prepare_core.py --core ../qflistudio-core --flutter ../flutter` only in the disposable cloud core. Run `flutter pub get`. The logs explicitly show `Downloading Gradle Wrapper...` and then `Got dependencies!`.
4. For each Android ABI, use the tracked native SDK input/staging scripts and their pinned hash checks. Keep the immutable `native-sdk-inputs-3.13.5` input release available. Do not replace pinned inputs with old `native/build` contents.
5. Run `flutter build apk --release --no-pub --target-platform android-arm64` or `android-x64`, respectively. Flutter supplies missing wrapper files from its Gradle-wrapper cache before invoking Gradle. Retain the tracked wrapper properties selecting Gradle 8.14.
6. Preserve APK ABI/package checks and upload application and intermediate artifacts. Do not infer signing/device acceptance from compilation.

Pinned upstream TEXT source was inspected through the GitHub API without downloading a binary: `flutter/flutter@00b0c91f06209d9e4a41f71b7a512d6eb3b9c694`, `packages/flutter_tools/lib/src/android/gradle_utils.dart:226-267`. `getExecutable` calls `injectGradleWrapperIfNeeded`; it copies only missing files from cached `gradle_wrapper`, makes them executable, and leaves an existing properties file unchanged. In the same revision, `packages/flutter_tools/lib/src/flutter_cache.dart:507-561` defines the wrapper cache and checks for both scripts and the JAR. This explains regeneration; it does not validate the old local file hashes.

Exact job-log anchors (1-based lines in the individual raw job-log response):

| Job ID / name | Dependency/wrapper evidence | Build/upload evidence |
| --- | --- | --- |
| `140074048366` / android-arm64-v8a | L562-623: `flutter pub get`, wrapper download at L572, dependency success at L622 | L667-686: assembleRelease and APK; L787 app upload; L919 intermediate upload |
| `140074048471` / android-x86_64 | L563-624: `flutter pub get`, wrapper download at L573, dependency success at L623 | L670-687: assembleRelease and APK; L795 app upload; L949 intermediate upload |
| `140074047782` / windows-x64 | L542-602: resolution, wrapper download at L552 | L659 Windows executable; L767 app, L843 installer, L894 intermediate upload |
| `140074048305` / linux-x64 | L1318-1378: resolution, wrapper download at L1328 | L2099 Linux executable; L2210 app, L2418 installer, L2469 intermediate upload |

Each raw log is available through `gh api repos/azurekiln2333/qflistudio-dart/actions/jobs/<job-id>/logs`. Both Android jobs actually ran Gradle and produced APKs. The Windows job was a desktop build: downloading the universal wrapper cache there does NOT prove that `gradlew.bat` was executed. No exact generated-wrapper hashes are printed in these logs, and no byte identity with the old local scripts/JAR is claimed.

### OHOS package/plugin regeneration

Run `45867515245`, workflow `.github/workflows/ohos-build.yml`, job `140074047785` / `OHOS ARM64 unsigned HAP, APP and native libraries`:

1. Use a fresh hosted Ubuntu 24.04 application checkout at the exact application SHA. Do not restore the old local root/entry locks, npm files, modules, generated registrant or local properties as prerequisite inputs.
2. Run `python3 tool/ci/ohos_build.py sanitize` only in the disposable CI copy. Bootstrap the verified official Command Line Tools with the tracked helper/lock. Select hosted Java 21. The observed run had empty override variables and used the locked toolchain. The helper checks the full archive SHA-256 and expected API before use.
3. Check out unpatched shared core `573d1b6eecf1c2b392ad753264a5a09f62f8335e` to `qflistudio-core`. Use official Flutter OHOS tag `3.41.9+ohos-1.0.2`, verify revision `62357a93d653bf844f730bb1f4b7cc9e2139d14e`, and expose its bin/FLUTTER_ROOT as the workflow specifies.
4. Run `flutter config --no-analytics --ohos-sdk "$DEVECO_SDK_HOME"`, record `flutter --version --machine`, and run `flutter pub get`.
5. Run `flutter build hap --release --no-pub --no-codesign --target-platform ohos-arm64`, followed by `flutter build app --release --no-pub --no-codesign --target-platform ohos-arm64`. Let this pinned Flutter/Hvigor sequence create its own package/plugin bindings and generated registrant in the cloud checkout. No standalone local regeneration is authorized.
6. Run `python3 tool/ci/ohos_build.py package`, inspect the HAP and nested APP HAPs, export matching libraries, and upload application, native-library and intermediate artifacts.

Exact raw job-log anchors:

- L107-125: application fetch/checkout at full `24b6e11` SHA.
- L282-314: pinned shared-core fetch/checkout; L363: pinned Flutter OHOS revision.
- L399: `flutter pub get`; L623 at `2026-11-26T17:27:19.3322730Z`: `Got dependencies!`.
- L628-629: the two exact unsigned ARM64 build commands.
- L655-660: Hvigor assembleHap/assembleApp and both completed package paths.
- L676-677: successful standalone and nested HAP inspections, ARM64 ELF machine 183, `libflutter.so` and `libapp.so`, release mode, source-matched curriculum assets. Signature/device flags remain false.
- L713-714: application artifact finalized; L748-749: native-library artifact finalized; L823-824: intermediate artifact finalized.

These logs and the tracked imports establish that the necessary generated OHOS dependency/plugin contract works from a clean checkout without the old ignored files. This is a FUNCTIONAL regeneration result, not a dump/hash comparison of each regenerated file. The standard-verbosity log does not enumerate internal npm/OHPM commands, individual generated file writes, or the generated root-lock/entry-lock/registrant hashes. Do not claim that those local files are byte-identical to cloud or upstream outputs, or that a device plugin behavior test passed.

### Artifact metadata observed; no artifact downloads

| Run | Artifact | ID | Actions archive bytes |
| --- | --- | ---: | ---: |
| 45867515245 | app-ohos-arm64-unsigned | 15140918685 | 34720827 |
| 45867515245 | native-ohos-arm64-libraries | 15140369726 | 14625252 |
| 45867515245 | intermediates-ohos-arm64 | 15140803966 | 134189853 |
| 45867515254 | app-android-arm64-v8a | 15141980395 | 160661869 |
| 45867515254 | app-android-x86_64 | 15141900550 | 219927755 |
| 45867515254 | intermediates-android-arm64-v8a | 15142040289 | 708845469 |
| 45867515254 | intermediates-android-x86_64 | 15142100048 | 892973626 |
| 45867515254 | native-windows-x64 | 15141132752 | 208900946 |
| 45867515254 | app-windows-x64 | 15140064436 | 226279798 |
| 45867515254 | installer-windows-x64 | 15140858704 | 165714449 |
| 45867515254 | intermediates-windows-x64 | 15140978501 | 27856857 |
| 45867515254 | native-linux-x64 | 15139859743 | 226594588 |
| 45867515254 | app-linux-x64 | 15140948838 | 250270043 |
| 45867515254 | installer-linux-x64 | 15142665017 | 170966380 |
| 45867515254 | intermediates-linux-x64 | 15141124102 | 27737895 |
| 45867515254 | host-checks-linux-x64 | 15141034231 | 5620 |

All were reported unexpired at inspection. Intermediate archives and host checks expire November 29, 2026 UTC; application/native/installer artifacts expire December 26, 2026 UTC. Artifact metadata does not prove downloaded archive contents. Preserve durable logs/source contracts rather than relying indefinitely on expiring intermediate artifacts.

## 3. Exact nonoverlapping MOVE manifest for root

This is a preservation manifest, not permission to delete or an execution script.

Let `S = D:/MyNewProjects/qfli_dart` and `B = D:/MyNewProjects/_migration-backup/qflistudio-dart-20261127`.
For every row except the explicit private-signing exception, MOVE the exact `S/<relative path>` to `B/worktree/<relative path>`. Preserve bytes and metadata. The whole backup is private; do not publish caches, device evidence, local paths, signing profiles or unverified binary inputs.

The source roots/files below are pairwise nonoverlapping. No row includes another row. In particular, `build/` is listed once: do NOT separately move its children as additional manifest entries. `native/build/` and OHOS build roots are different source roots, not children of root `build/`.

### Directory roots: 28 exact rows

| Relative source root | Preservation classification / boundary |
| --- | --- |
| `.agents/` | 46 generated integration files; prior template-hash match supplied by root; retain backup, not source-of-truth replacement for tracked Trellis |
| `.dart_tool/` | Generated Dart/Flutter workspace cache |
| `.pytest_cache/` | Generated pytest cache |
| `.trellis/scripts/common/__pycache__/` | Python cache only; retain every other Trellis source/progress file |
| `android/.gradle/` | Generated Gradle workspace state |
| `android/.kotlin/` | Generated Kotlin/Gradle cache; include this exact root only if present at move time; do not traverse links |
| `android/app/src/main/java/` | Current inventory: one ignored generated Java registrant, no parent-repository tracked files; do not expand to sibling Kotlin sources |
| `build/` | PRIVATE PRESERVATION HOLD: generated outputs plus device evidence, signing material, handwritten originals and two nested core repositories; never discard as a unit |
| `ios/Flutter/ephemeral/` | Generated Flutter support state |
| `linux/flutter/ephemeral/` | Link-only plugin state; two plugin link entries, do not traverse targets |
| `macos/Flutter/ephemeral/` | Generated Flutter support state |
| `native/build/` | Generated native SDK staging; NOT `native/dart-sdk/` source |
| `ohos/.hvigor/` | Generated Hvigor state |
| `ohos/.idea/` | EDITABLE SETTINGS HOLD: 12 regular files / 24493 bytes; modules, workspace, VCS, DevEco state and `.deveco/cxx/.clang-format`; retain all until owner review |
| `ohos/build/` | Generated packaging output; contains one symbol reparse entry; move the link itself only |
| `ohos/entry/build/` | Generated module output; contains two symbol reparse entries; do not traverse targets |
| `ohos/entry/libs/` | Local generated/native package inputs, not authored platform source |
| `ohos/entry/oh_modules/` | Four junction entries; preserve link objects without dereferencing SDK/Pub-cache targets |
| `ohos/entry/src/main/ets/plugins/` | Current inventory: only the 693-byte ignored generated registrant; preserve original |
| `ohos/entry/src/main/resources/rawfile/flutter_assets/` | Generated asset copy; keep authored `assets/` and `curriculum/` in source |
| `ohos/node_modules/` | Local npm state plus Flutter-Hvigor junction; do not follow SDK target |
| `ohos/oh_modules/` | OHPM cache with two Hypium link entries; do not dereference them |
| `scripts/__pycache__/` | Python cache only; keep authored scripts |
| `test/__pycache__/` | Python cache only; keep authored tests |
| `tool/__pycache__/` | Python cache only; keep authored tools |
| `tool/ci/__pycache__/` | Python cache only; keep CI source |
| `tool/ohos/__pycache__/` | Python cache only; keep OHOS source |
| `windows/flutter/ephemeral/` | Link-only plugin state; two plugin link entries, do not traverse targets |

Existing directory rows were checked against the parent repository's tracked-file list and have zero tracked files. The conditional `android/.kotlin/` row is included because the ignore rule identifies it as generated; root must confirm its presence and tracked-file exclusion at move time. This is not proof that a row contains no valuable source: the explicit HOLD classifications remain binding. Filesystem content inventory skipped the two nested repositories under `build/`; it did not inspect sibling repositories.

### Individual files: 17 exact rows including the private-signing exception

| Relative source file | Preservation classification |
| --- | --- |
| `.flutter-plugins-dependencies` | Generated plugin dependency state |
| `android/gradlew` | Unverified local wrapper input; preserve original privately |
| `android/gradlew.bat` | Unverified local wrapper input; preserve original privately |
| `android/gradle/wrapper/gradle-wrapper.jar` | Unverified local wrapper binary; preserve original privately |
| `android/local.properties` | Machine-local properties; private backup, not Git |
| `flutter_01.log` | Historical local diagnostic log |
| `flutter_02.log` | Historical local diagnostic log |
| `flutter_03.log` | Historical local diagnostic log |
| `ios/Flutter/Generated.xcconfig` | Generated machine-local Flutter configuration |
| `ios/Flutter/flutter_export_environment.sh` | Generated machine-local environment |
| `ios/Runner/GeneratedPluginRegistrant.h` | Ignored generated registrant |
| `ios/Runner/GeneratedPluginRegistrant.m` | Ignored generated registrant |
| `ohos/local.properties` | Machine-local properties; private backup, not Git |
| `ohos/entry/oh-package-lock.json5` | Machine-local SDK/Pub-cache lock; preserve, do not port |
| `ohos/package.json` | Machine-path Flutter-Hvigor plugin dependency |
| `ohos/package-lock.json` | Machine-path npm link lock |
| `.git/local-signing-backup/ohos-build-profile.json5` | EXCEPTION: MOVE to `B/private-signing/ohos-build-profile.json5`, not under `B/worktree/.git/`; 2116 bytes; contents not read |

The table has 17 rows INCLUDING the private-signing exception. No whole `.git/` move is authorized. Retain the old repository metadata/history until target acceptance. The signing backup is private recovery material, not build cache. `cleanup-audit.md` records prior credential exposure and the signing owner's assessment/rotation gate; this audit performs no rotation or historical rewrite.

### Mandatory preservation inside the single build root

The `build/` row includes, without overlapping extra MOVE rows:

- Historical evidence roots `dart-audit/`, `dart-host-gate/`, `reports/`, `legacy-artifacts/` and `releases/`.
- Loose certificates/profiles, signing verification outputs, raw device logs/screenshots, packages and SDK smoke evidence. Keep them private.
- `stock-core-checkout/` and `stock-core-crlf/`, including their nested `.git` histories and modified files. Do not traverse or integrate them during this move. `remote-audit.md` records the earlier preservation review; this audit does not revalidate their current internal state.
- The original `generate_core_patch.py` and `ohos_perf_gestures.py`. Fresh SHA-256 comparisons found their bytes still equal the tracked `recovered-source/` copies: respectively `ecc79711774ae2da024b0dce132ec1ea767dad4af5e7b41b247c1f846d344344` and `94e1806388ee8d06decd4063dd4ab01986c127381acef9338c8f94a1e4d9688f`. Preserve the originals anyway; do not run these historical scripts.

### Root execution gates, not auditor actions

1. Finish source preservation and target handoff gates before retiring any old-clone content. Close or quiesce tools that may rewrite listed generated/local files.
2. Recheck only each exact source root/file for intervening edits and destination collisions. Do not overwrite an existing backup item or silently merge conflicting trees. Record any changed bytes before a move.
3. Move directories containing reparse points only with behavior known to preserve/move link objects WITHOUT dereferencing targets. If the chosen operation cannot guarantee that, HOLD that exact row. Do not walk SDK, Pub-cache, external source, WSL or sibling paths to make the move succeed.
4. Preserve `.idea` intact as editable state. A future settings review may decide what is reusable; the migration does not grant disposal approval.
5. Keep the adopted `ohos/oh-package-lock.json5` in source. Root owns the root-only ignore exception and staging. If root later chooses to track verified wrapper inputs, amend this manifest for those exact paths before moving them. Never move a now-tracked source input out of the working tree.
6. Verify source/destination preservation and the intended old-clone state using read-only inventory/hash checks. No blanket `git clean`, recursive deletion, WSL action or artifact download belongs to this plan.

## 4. Explicit KEEP / unresolved boundaries

KEEP all tracked source and Trellis records, `native/dart-sdk/`, vendor, authored `assets/` and `curriculum/`, tracked platform registrants, native input scripts, the wrapper properties file, the adopted `ohos/oh-package-lock.json5`, OHOS manifests/build/Hvigor source, and this audit. Do not move platform parent directories such as `android/`, `ohos/`, `ios/`, `native/`, `tool/` or `.trellis/` wholesale.

No sibling repository, WSL registration/image, external SDK/Pub cache, target checkout or global cache is part of this manifest. Do not follow a preserved link into one. Earlier WSL inventory is historical context only; no WSL inspection was repeated.

The successful candidate runs establish the specified clean-cloud build/regeneration behavior. They do not establish local/upstream byte equivalence, signed OHOS distribution, installed-device acceptance, Windows Android-wrapper execution, final main status, target parity, or validation of concurrent source edits. Root owns those remaining gates and all execution of the MOVE manifest.
