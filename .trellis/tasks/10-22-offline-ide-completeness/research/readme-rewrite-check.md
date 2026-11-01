# README rewrite verification (three READMEs)

Task: `10-22-offline-ide-completeness`
Scope: `README.md`, `README.zh-Hant.md`, `README.en.md` only.
No runtime, core, vendor, curriculum, asset, test or git state was changed.
No git stage/commit/push was run.

## Exact changes

- `README.md` — Simplified Chinese (was English before the authorized rewrite).
- `README.zh-Hant.md` — Traditional Chinese (new file).
- `README.en.md` — English (new file).
- All three carry relative language links: `README.md`, `README.zh-Hant.md`,
  `README.en.md`.
- Pre-rewrite WIP preserved by root at
  `.dart_tool/pi-briefs-20261025/readme-before-rewrite.md`.

### Corrections applied in this pass

1. Draft promotion is now a mandatory gate, not a possibility.
   Chinese uses `原有 OHOS 验收是草稿提升的必经门槛。` ("original", not `原装`).
   English: `The original OHOS acceptance is a mandatory gate before draft
   promotion.` No `可能/也许` weakens it.
2. `OHOS HAP/APP` scope is separated from the special audit package:
   release HAP/APP carry `arm64-v8a` only, while a separate `x86_64` audit HAP
   exists (`tool/ohos/build_dart_audit.ps1`). The audit HAP is not a release
   package and not device evidence.
3. Native offline guard boundary: the guard is verified by the host channel test
   only, and the existing audit HAP predates it.
4. `test/native_entry_ability_test.cjs` is described as the native offline-channel
   test with two groups (offline rejection, local capability wiring), not a
   startup-progress test. Source: the two `test(...)` blocks in that file.
5. Diagnostic scope is parser-only in both the tools tab and `dart analyze`.
   The earlier `类型分析需要 SDK 目录` claim was wrong and is removed.
6. `便携运行时` unified to `便携解释器` (one term per concept).

## Git status for owned paths

```text
 M README.md
?? README.en.md
?? README.zh-Hant.md
```

## Prerequisite untracked files (root owns committing)

Neither is owned by this task; both were untracked before the rewrite and stay
untracked here.

```text
?? LICENSE
?? scripts/ste-lint-zh.py
```

- `LICENSE` is the GPL-3.0 text (`GNU GENERAL PUBLIC LICENSE Version 3`). The
  README license claim depends on it. It is an initial uncommitted change and
  must be committed by root, or the `/LICENSE` claim has no file behind it.
- `scripts/ste-lint-zh.py` is the controlled-Chinese linter cited in the README
  "check the Chinese documents" step. It must also be committed by root.

No markdown link points at either file, so no link is broken.

## Lint

Command (no suppression, no baseline weakening):

```powershell
python scripts/ste-lint-zh.py README.md README.zh-Hant.md
```

Output:

```text
→ README.md: 硬违规 0 处，未超过 baseline 0
→ README.zh-Hant.md: 硬违规 0 处，未超过 baseline 0
共 0 处发现（硬违规 0，baseline 0），2708 字，每 100 字 0.0 处
exit=0
```

`--json` on both files returned `[]`. Zero total findings means no advisory hit
either (`passive-voice`, `vague-word`, `halfwidth-punct`, `dash-join`,
`compound-aspect`).

## Traditional Chinese manual check

The checker vocabulary is mainly Simplified, so `README.zh-Hant.md` was checked
by character diff against `README.md`:

- 211 lines in both files, aligned 1:1.
- 127 distinct differing character pairs; every pair is a genuine
  Simplified→Traditional conversion (for example `仓→倉`, `验→驗`, `审→審`,
  `线→線`).
- No differing line has a length mismatch.
- No Traditional line still contains a Simplified character from the diff set.
- A separate scan for simplified-only characters leaves only line 3: the
  `简体中文` language-link label. Each language label stays in its own script by
  convention, so this is intended.

## Claim sources

| Claim | Source |
| --- | --- |
| Offline app, no external page, OHOS only clipboard permission | `ohos/entry/src/main/module.json5` (`ohos.permission.READ_PASTEBOARD`); `.trellis/spec/backend/dart-offline-host.md` |
| Android manifest has no network permission | `android/app/src/main/AndroidManifest.xml` |
| Android/desktop use official SDK; OHOS uses portable interpreter | `.trellis/spec/backend/dart-native-runtime.md`; `native/dart-sdk/README.md` |
| `vendor/tom_d4rt` `1.229.0+qfli.1`, MIT, analyzer 8.4.1 | `vendor/tom_d4rt/pubspec.yaml`; `vendor/tom_d4rt/README.qfli.md` |
| `dart_eval` 0.8.5 only for legacy EVC; EVC yields dart_eval bytecode | `pubspec.yaml`; `lib/dart_tools.dart` (`compilePortable`, `.evc`); `.trellis/spec/frontend/dart-tools.md` |
| Portable limits (no network/process/stdin/symlink) | `vendor/tom_d4rt/README.qfli.md`; `.trellis/spec/backend/dart-portable-runtime.md` |
| Shipped content 120 lessons + 120 examples, 14 chapters | `assets/content/dart_tutorials.json` and `dart_examples.json` entry counts (120 each); `curriculum/dart_chapters.dart` counts sum 120 |
| 180 draft pairs 121–300 in 16 chapter files, not shipped | `curriculum/chapters/*.dart` draft counts (16 files, 180 ids); `curriculum/dart_curriculum.dart` does not aggregate them; `research/expansion-plan.md` |
| Draft promotion blocked by original OHOS acceptance | `.trellis/tasks/10-22-offline-ide-completeness/progress.md` ("keep production aggregator/assets at120/120 until original installed OHOS acceptance") |
| Host-only draft evidence; one exercise rerun pending | `research/expansion-a.md` (60/60); `research/expansion-b.md` (58, standalone rerun pending); `research/expansion-c.md` (62/62) |
| Four separate gates; no Dart device acceptance; no device slot | `progress.md`; `.trellis/spec/backend/dart-native-runtime.md` |
| Android native SDK nine checks, API 37 x86_64, 16 KiB pages | `native/dart-sdk/README.md` |
| Windows AOT proves host only | `research/isolate-host-aot-results.json`; `.trellis/spec/backend/dart-portable-runtime.md` |
| Release HAP/APP are `arm64-v8a` only | `ohos/entry/build-profile.json5` (`abiFilters: ["arm64-v8a"]`); `.trellis/spec/backend/dart-native-runtime.md` |
| Separate `x86_64` audit HAP, host inspection only | `tool/ohos/build_dart_audit.ps1` (patches abiFilters to `x86_64`, `--target-platform ohos-x64`, preserves in `build/dart-audit/`) |
| Audit HAP predates the native offline guard | `progress.md` ("this HAP predates the native URL guard; it proves neither current policy nor installed device execution") |
| Native offline guard, host test only | `ohos/entry/src/main/ets/entryability/EntryAbility.ets` (`OFFLINE_ONLY` for `openUrl`/`openAgreement`); `test/native_entry_ability_test.cjs` |
| Native test has two groups, not startup progress | `test/native_entry_ability_test.cjs` two `test(...)` blocks; `startupProgress` is a separate channel method not covered by either |
| Tools features; parser-only diagnostics; Kernel `.dill`; no breakpoint debugging | `.trellis/spec/frontend/dart-tools.md`; `lib/dart_code_analyzer.dart`; `lib/dart_tools.dart`; `research/dart-tools-audit.md` |
| Terminal verbs; `dart analyze` is parser-level; Kernel refused on portable | `.trellis/spec/frontend/dart-terminal.md`; `lib/dart_runner.dart` |
| Sibling `qfli_studio_core` and `re_editor` path deps | `pubspec.yaml` |
| Dev/test/content/build commands | `tool/build_dart_content.dart`, `tool/verify_dart_content.dart`, `tool/verify_portable_content.dart`, `tool/audit_compat.dart`; `native/dart-sdk/android/stage.ps1` |
| Android release signs with debug key | `android/app/build.gradle.kts` (`signingConfigs.getByName("debug")`) |
| OHOS `releaseKey`, bundle `com.azurekiln.qfli.dart` | `ohos/build-profile.json5`; `ohos/AppScope/app.json5` |
| HAP/APP signed output paths | existing artifacts `build/ohos/hap/entry-default-signed.hap` and `build/ohos/app/ohos-default-signed.app` |
| Signature verification tool | `tool/ohos/verify_dart_hap.ps1` |
| GPL-3.0 app, MIT `tom_d4rt` | `LICENSE` (untracked); `vendor/tom_d4rt/LICENSE` |

## Pending evidence (not claimed as done)

- Original OHOS release build and installed-device acceptance. This is a
  mandatory gate for draft promotion, not an optional or possible delay.
- Rebuild of the native offline guard into a package and a device run. Only the
  host channel test exists.
- Promotion of the 180 draft pairs into the production aggregate and assets.
- Full 300-pair content verification after promotion.
- Standalone exercise rerun for the `expansion-b` batch.
- Final shared-core revision review and integration.
- Dart device time slot; no Dart install/start/stop performed.

## Uncertainty preserved

- `可能`/`也许` are not used to weaken any gate. Where modality remains, it
  reflects genuine uncertainty, not a softened requirement.
- No statement turns unverified device execution into a pass.
- Host evidence, OHOS build evidence and device evidence stay separate.

## Root follow-up, 2026-10-26

The lint script was committed and pushed in 01c6714. Its untracked status above is historical. Root narrowed the device statements to OHOS, preserving the separate Android emulator result. Signing instructions now read the bundle name from AppScope and select a local signing configuration; the docs no longer depend on the initial releaseKey/bundle WIP. The ARM64 line is an explicit build instruction. Root removed the app GPL claim because the initial LICENSE remains outside this task commit boundary. The third-party MIT statement remains. Both Chinese READMEs passed mechanical lint after these edits. Runtime/vendor/tool dependencies still require coherent commits before the README commit.

## Final independent review disposition

The final read-only Pi review found missing mandatory Android staging arguments, overbroad manifest wording, and imprecise path-override terminology. Root corrected all three language files. Both ABI staging commands now include -Abi/-Sdk with quoted replaceable SDK-directory placeholders. Main Android manifest permission scope is explicit, and debug/profile network permissions are disclosed separately. The re_editor path is identified as an override. Controlled Chinese lint returned0 findings/exit0 after these edits. README paths are outside the host source identity; live READY781 recheck still matched after the docs corrections. No SDK or package build was run.
