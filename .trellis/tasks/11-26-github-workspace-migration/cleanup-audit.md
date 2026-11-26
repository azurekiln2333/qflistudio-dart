# Cleanup inventory — 2026-11-26

Herdr read-only audit: w5S:p5. Sizes are logical regular-file lengths, not guaranteed reclaimed space. No WSL distribution was started, mounted, compacted, stopped or deleted. No image contents were read.

## Dart workspace

26 nonoverlapping generated candidate roots total 8,602,909,272 bytes (8.012084 GiB). Every candidate root has zero tracked files in the parent repository. This alone does not make a directory disposable: nested repositories and handwritten evidence exist. The scan skipped 14 nested reparse entries (four Flutter plugin links and ten OHOS junctions), without traversing external SDK or Pub-cache targets.

| Candidate | Regular-file bytes | Decision |
| --- | ---: | --- |
| build | 6,465,525,036 | Hold until source and evidence preservation review |
| .dart_tool | 1,091,755,810 | Generated cache, eligible after handoff |
| native/build | 584,434,321 | Generated SDK staging; verify cloud input release first |
| ohos/entry/build | 249,678,423 | Generated package intermediates |
| ohos/build | 94,216,372 | Generated package intermediates |
| ohos/oh_modules | 80,363,408 | Dependency cache; do not follow junction targets |

Preserve `native/dart-sdk`, vendor, assets, curriculum, tracked platform registrants and all Trellis source/progress. `.agents` and `ohos/.idea` were held separately. The root added explicit pytest and common native cache ignore rules; ignore rules never authorize deletion.

Nested source review is in `remote-audit.md`. Core history and patch preservation passed the live-ref and filesystem checks recorded there. Both temporary checkouts remain present because the path-specific recursive removal command was rejected. The two loose handwritten scripts are copied to `recovered-source/` before cleanup.

Keep these existing historical evidence directories until the target coordinator decides retention: `build/dart-audit`, `build/dart-host-gate`, `build/reports`, `build/legacy-artifacts`, `build/releases`. Signing certificates/profiles occur in `build/dart-audit` and loose `build/*chain.cer` / `build/*profile.p7b` files. Preserve these privately. They are not staged into GitHub. Do not use blanket `git clean -fdx` or recursively remove the whole build directory.

## Private OHOS signing configuration

The tracked OHOS build profile previously contained two machine-specific signing records, including nonempty password fields. The source profile now uses the same unsigned configuration used in hosted builds. The original bytes are preserved privately at `.git/local-signing-backup/ohos-build-profile.json5` in the D clone. Transfer that private file to the signing owner's protected storage before removing the D clone. Earlier GitHub commits already contained those fields. The signing owner must assess exposure and rotate affected credentials. No signing key, historical rewrite, or credential rotation was performed by this migration.

## WSL registrations

The current-user registry contains five WSL2 registrations. Only exact registry-derived host paths and file metadata were inspected.

| Distribution | VHD location | Logical bytes | Owner |
| --- | --- | ---: | --- |
| Ubuntu (default) | D:/WindowsExt/Subsystem/Ubuntu/Ubuntu_2204.1.7.0_x64 | unresolved | shared |
| qfli-terminal-test | D:/MyNewProjects/qflistudio/.artifacts/terminal-runtime-test/ubuntu/ext4.vhdx | 19,723,714,560 | qflistudio |
| qfli-terminal-al3-clean | D:/MyNewProjects/qflistudio/.artifacts/terminal-runtime-test/al3-clean/ext4.vhdx | 13,742,637,056 | qflistudio |
| qfli-terminal-al3-test | D:/MyNewProjects/qflistudio/.artifacts/terminal-runtime-test/al3/ext4.vhdx | 7,114,588,160 | qflistudio |
| qfli-java-build | D:/MyNewProjects/qfli_java/build/wsl/qfli-java-build/ext4.vhdx | 84,817,215,488 | qfli_java |

The four located VHD files total 125,398,155,264 bytes (116.786133 GiB). The default Ubuntu base exists but is empty; no VhdFileName value or conventional ext4.vhdx was found. This is unresolved registration state, not proof of zero size or permission to delete. Physical allocation, running state, other-user/unregistered images and guest contents were not inspected.

Shared WSL cleanup remains outside Dart ownership. Core coordinator w63:p1 confirmed inventory-only coordination. Each owning product must preserve its independent sources/configuration and agree readiness before distribution-specific unregister. Never delete a registered VHD directly.
