# CI evidence review

## Completed runs

The GitHub REST API reports success for these exact commits:

| Run | Commit | Output scope |
| --- | --- | --- |
| 43922631253 | ac8dadd3d66a5cf85486b3e22bc6f747563f8b89 | Android arm64-v8a and x86_64 SDK staging |
| 43937445780 | 11eba01af51446554aab21a09958b65d803b84a2 | Android ARM64/x64 apps, Windows x64 app/SDK, Linux x64 app/SDK |
| 43943142540 | 2f9243a78bd22d549518de7d4c03953a28c52ccb | OHOS ARM64 unsigned HAP/APP and extracted native libraries |
| 43999548702 | a08421d | macOS ARM64/x64 SDKs and applications, unsigned iOS archive and native frameworks |

`github-run-evidence.json` records job outcomes and downloadable artifact metadata.
Each artifact record includes its ID, byte count, GitHub SHA-256 digest, creation
time and expiry. The metadata was read from the public GitHub REST API. This
review downloaded and independently checked both OHOS artifact archives. It did
not download all eight earlier artifact archives. Build success does not prove
installation, store signing or device execution.

Apple run 43940734490 was cancelled after its iOS job succeeded and its macOS
x64 app failed in the signing script. Its three uploaded artifacts remain
available: the iOS archive, iOS frameworks and standalone macOS x64 SDK.
The whole Apple run is not marked successful. Commit 7776c35 fixes the Bash 3.2
signing-array failure. Run 43945574938 then completed iOS and both standalone
macOS SDKs, but both macOS apps failed outer signing on SDK data in Helpers.
Commit 9fb8164 moves non-Mach-O data into Resources and preserves original SDK
paths with relative links. Run 43950204148 then rejected a dotted pure-data
directory still left in Helpers. Commit a08421d relocates the highest pure-data
directories, rebases original links and validates both trees. It adds a real
minimal .app signing preflight before the full application build. Run 43999548702
is the acceptance attempt for the complete layout fix.
It completed successfully. Both macOS architectures passed the minimal bundle
signing preflight, full application compilation and signing, architecture
checks, tar extraction, repeated strict codesign verification and SDK resource
link validation. iOS also completed with its unsigned archive and frameworks.
The four recommended runs now provide sixteen artifacts. Prior failed or
cancelled Apple runs remain in the JSON only as historical evidence.

## Final scope review

The independent final reviewer checked the complete task changes, platform
contracts, artifact layouts, license notices and documented evidence boundaries.
At commit 9fb8164, changes since the successful Android/Windows/Linux app run
are limited to Apple/OHOS build support and documentation. The application code,
standard-platform compatibility helper and those platforms' build definitions
remain unchanged. Since the OHOS success, only Apple support and documentation
changed. The Android native staging scripts and workflow are unchanged from
their successful run. Earlier successful artifacts therefore still represent
the final code affecting their respective platforms; their provenance retains
the actual source commits rather than claiming the latest branch commit.
The final review matched all sixteen download URLs and artifact names exactly
against the four recommended successful runs. Every recommended job succeeded
and every artifact was unexpired. All eight platform/architecture rows show
completion. Chinese lint reported zero hard violations, and the final diff
passed whitespace checks. No further implementation or documentation blocker
remained before task archival.
All thirteen links present before the final Apple attempt matched the recorded
artifact IDs. No additional implementation blocker was found. Three READMEs
still listed OHOS packaging as pending; they now distinguish completed unsigned
HAP/APP packaging from unverified signing and device acceptance.

The resource-layout fix passed independent YAML, embedded Python and shell
syntax checks. A fixture used actual files and symbolic links, with a stubbed
file classifier, to verify complete resource relocation and unchanged Mach-O
paths. A second helper run moved zero files and retained readable SDK paths.
The fixture rejects absolute links and links outside the application. These
checks do not claim macOS ditto or Apple signing behavior on Windows.
The directory fix also passed fixtures for dotted pure-data directories, mixed
Mach-O/data directories, paths with spaces, links from Resources to code in
Helpers, directory aliases and repeated packaging after source additions and
deletions. Both output paths are validated before rebuilding their generated
architecture directories, including rejection of symlink roots and any overlap
with the source SDK. The complete source SDK remains read-only.

The new workflow validates the unpacked application with strict codesign
verification. It also verifies SDK links and required resource paths after tar
extraction. The signed embedded helpers have sandbox-inheritance entitlements;
the workflow does not mistake direct execution from an unsandboxed CI shell
for application sandbox runtime verification.

## OHOS completed build and artifacts

Job `133565653606` completed successfully. The complete official toolchain
download, SHA-256 verification, extraction and SDK detection passed. Java 21,
the pinned shared core and the pinned Flutter OHOS checkout also passed.
Dependency resolution, both release builds, package inspection and both uploads
completed successfully.

| Artifact | ID | Actions ZIP bytes | Files |
| --- | --- | --- | --- |
| app-ohos-arm64-unsigned | 14264177854 | 34719102 | HAP, APP, two inspection reports, provenance and SHA256SUMS |
| native-ohos-arm64-libraries | 14263248969 | 14625255 | libflutter.so, libapp.so, README, provenance and SHA256SUMS |

The HAP is `entry-default-unsigned.hap` (45678274 bytes). The APP is
`ohos-default-unsigned.app` (18016445 bytes). Both Actions ZIP SHA-256 values
match the GitHub artifact digests. Every listed file passes its internal
SHA256SUMS check: five application entries and four native entries.
The artifacts expire on December 16, 2026 UTC.

The standalone HAP and the HAP nested in the APP both pass inspection:

- Bundle `com.azurekiln.qfli.dart`, version `1.0.0`, packaged version code `1`.
- Release build mode with `debug=false`.
- ARM64 ELF machine `183` for `libflutter.so` and `libapp.so`.
- Tutorial and example assets each contain 120 topics. Their hashes match the
  authored source assets.
- Packaged minimum API `50100018` and target API `60101024` remain unchanged.
- Each archive remains byte-identical before and after inspection.

The native artifact contains the two libraries actually present in this HAP.
It is not an independent Dart SDK. Signature verification, installed device
execution and the native offline guard remain unverified in these reports.
Flutter overrides AppScope's version code `1000000` with pubspec build number
`1`; the inspection reports record this explicitly.

## HarmonyOS source verification

`ohos-toolchain-source-evidence.json` records two official Linux x64 archives:

- Primary: Command Line Tools 26.0.0.821, SDK 26.0.0.105, API 26.
- Fallback candidate: Command Line Tools 6.1.1.268, SDK 6.1.1.115, API 24 Beta1.

Both official hosts returned HTTP 206 for `Range: bytes=0-0`. Each response's
`x-amz-content-sha256` matches the recorded digest. `Content-Range` confirms the
recorded archive size. The CI bootstrap separately computes SHA-256 over the
complete download before extraction. Run `43943142540` completed that full-file
check for the primary archive. Its artifact provenance records all 2347882285
bytes and SHA-256 `58da7359019e9360a8bb82da0cd1d3b3b26fedc338379f257849f2162e3ac1fc`.
A matching response header alone is not claimed as a local full-file checksum.
The fallback remains unselected and has no full CI checksum claim.

The API 24 SDK metadata was read directly from the ZIP central directory and
`command-line-tools/sdk/default/sdk-pkg.json`. This required about 18.2 MB of
metadata requests. It is explicitly Beta1 and was not selected for the current
workflow. The official API 26 layout was independently inspected by the workflow
design worker. It contains `tool/node/bin/node`, root `bin/ohpm` and `bin/hvigorw`
wrappers, and SDK `default/openharmony/toolchains/hdc`.

The original official source for stable Command Line Tools 6.1.1.280 was not
recovered. Its third-party GitHub release exists, but its historical build logs
have expired. No stable API 24 input is asserted. Project target API 24 remains
unchanged. The successful HAP and APP builds establish that the selected API 26
toolchain can package this project with its current minimum and target APIs.
This does not establish installed-device compatibility.

Download query signatures, authentication tokens and local signing values are
excluded from these research files. The primary complete URL remains in the
reviewed toolchain lock file. The fallback source reference identifies a fixed
public metadata commit from which its complete download URL can be retrieved.

## OHOS helper review

The pinned Flutter OHOS commit is
`62357a93d653bf844f730bb1f4b7cc9e2139d14e`. Its official GitCode content API shows:

- `packages/flutter_tools/lib/src/context_runner.dart:125` selects
  `OhosHvigorBuilder`.
- `packages/flutter_tools/lib/src/ohos/hvigor.dart:440` copies HAP output into
  `build/ohos/hap/`.
- The same file at line 605 copies APP output into `build/ohos/app/`.
- `project.dart` selects `entry-default-unsigned.hap` and
  `ohos-default-unsigned.app` when code signing is disabled.

The helper's fixed output paths therefore match the selected upstream builder.
Its application inspection also opens each nested HAP in the APP, validates
ARM64 ELF contents and checks authored identity and assets.

Review checks passed:

- Workflow YAML parsing, 40-digit action revision format and Python compilation.
- Remote action tags match the pinned checkout and upload-artifact commits.
- Sanitizing a temporary copy of the real profile removes signing fields. The
  local original remains byte-identical. No signing values were printed.
- Fixture packaging exports the inspected HAP, APP, ARM64 libraries, provenance
  and checksum files. Runtime and independent-SDK claims remain false.
- The helper rejects local execution outside its GitHub Actions guard.
- All 31 existing HAP inspector tests passed.

The initial toolchain discovery assumed `tool/ohpm` and `tool/hvigor`. The
workflow design worker corrected it to support the observed root wrappers and
selected the runner's Java 21 runtime. Run `43943142540` subsequently verified
Ubuntu tool execution and application packaging with that layout. The original
job log is retained only in local scratch storage and is not uploaded as research.
