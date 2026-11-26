# Installer package design

## Boundary

One helper, `tool/ci/package_installer.py`, owns installer creation and its
checks. Workflows call it after the application artifact is uploaded, then
upload a separate `installer-<name>` artifact. The application archive steps
stay as they are. The helper derives its provenance from the job's existing
`dist/app/provenance.json`, so toolchain pins keep a single source per job.
The application version comes from `pubspec.yaml`.

## Formats

- Windows: Inno Setup, which the pinned `windows-2022` image ships (6.7.1).
  The script lives at `tool/ci/windows_installer.iss`. It installs per user
  without elevation, packs the validated Release directory unchanged and adds
  the licence. Python starts `ISCC.exe` directly; Git Bash would rewrite its
  `/D` arguments as paths.
- Linux: `dpkg-deb`, with dependencies computed by `dpkg-shlibdeps` from the
  Flutter-built ELF files. The bundle goes to `/opt/qfli-dart-wing` unchanged
  because the application finds `data/dart-sdk` beside its resolved
  executable. `/usr/bin/qfli-dart-wing` is a relative symlink.
- macOS: `hdiutil` UDZO image with the application and an `/Applications`
  link. Creation retries because hosted runners return transient
  "Resource busy" errors.
- iOS: `Payload/Runner.app` zipped with symlinks preserved. The result is an
  unsigned IPA for signing tools, not a device-installable package.
- Android and OHOS: unchanged. A signed iOS or OHOS package needs credentials
  as repository secrets, which is a separate, user-owned decision.

## Verification

Windows installs silently into a temporary directory, compares the installed
file list with the source, runs the installed `dart.exe --version`, uninstalls
and checks that the application files are gone. Linux installs through apt so
the computed dependencies resolve, runs the installed SDK through the launcher
path, then removes the package. macOS verifies the image, mounts it read-only,
runs `codesign --verify --deep --strict` and the SDK link check on the mounted
application. The link check moves from the workflow into the helper so the tar
archive and the disk image share it. iOS reads the IPA back and checks the
executable, Info.plist and frameworks.

None of these checks starts the application window. Provenance records
`installVerified` separately from the unverified UI and device runtime.

## Failure and rollback

Installer steps run after the application upload. The summary step runs even
when an installer step fails and lists only the artifacts that exist. Reverting
the commit restores the previous workflows; no stored state changes.
