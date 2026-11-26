# Build installer packages on GitHub Actions

## Request and authorization

The user asks which build flows exist for Android, iOS, OHOS, Linux, Windows
and macOS, whether the workflows can produce installer packages, and, if so,
to configure them and push to CI. That explicit instruction authorizes the
implementation, the commits and pushing a dedicated branch. It does not
authorize a default-branch merge, new repository secrets or a public release.

## Current state

All six platforms already build on GitHub Actions. Android produces a
test-signed APK per ABI, which is an installer package. OHOS produces unsigned
HAP and APP packages. Windows produces a ZIP of the Release directory, Linux a
tar.gz bundle, macOS a tar.gz with the ad hoc signed .app, and iOS an unsigned
.xcarchive. The four latter outputs are not installer packages.

## Requirements

- Windows x64: a setup program that installs, creates shortcuts and uninstalls.
- Linux x64: a Debian package with a launcher, a desktop entry and an icon.
- macOS arm64 and x64: a disk image holding the ad hoc signed application.
- iOS arm64: an unsigned IPA made from the existing unsigned archive.
- Keep every existing artifact, pin and validation unchanged.
- Each installer artifact carries its SHA256 and a provenance record.
- Android and OHOS keep their current packages; document them as installers.
- Document downloads, installation and signing limits in controlled Chinese.

## Constraints

- No signing identity, certificate or profile is available in this repository.
  iOS and OHOS packages therefore stay unsigned and need signing before
  installation. Do not claim otherwise in file names, provenance or documents.
- Do not add unpinned third-party downloads or actions. Use tools shipped with
  the pinned hosted runner images and fail clearly when one is absent.
- Do not reuse or upload local signing material.
- An installer failure must not hide a usable application artifact.

## Acceptance

- [ ] Workflow YAML parses and helper unit tests pass locally.
- [ ] A real GitHub run produces every new installer artifact.
- [ ] Windows CI installs silently, runs the installed SDK and uninstalls.
- [ ] Linux CI installs with apt, runs the installed SDK and removes the package.
- [ ] macOS CI mounts the image and verifies the signature and SDK links there.
- [ ] iOS CI checks the IPA layout and records that it is unsigned.
- [ ] The run URL and any blocker are reported honestly.
- [ ] Documents and the native runtime spec describe the new contract.
