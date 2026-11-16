# Android native SDK on GitHub Actions

## Request and authorization

The user requests a project status and disk-usage audit, a real GitHub workflow
trial for the native layer, and an explanation of the outputs and download path.
Their explicit instruction to do the work authorizes implementation and pushing
a dedicated trial branch. Do not merge the default branch or delete local caches.

## Acceptance

- Run the existing locked Android SDK preparation and staging on GitHub.
- Preserve the SDK version and source package hashes.
- Export both arm64-v8a and x86_64 artifacts with manifests and checksums.
- Inspect the actual run result and report its URL and any blockers honestly.
- Explain artifact installation, retention, and local space that is rebuildable.
- Distinguish SDK packaging from C++ source compilation, APK packaging, and
  Android device runtime verification.

## Boundary

The missing behavior is remote execution of existing native packaging scripts.
It belongs in `.github/workflows/` and `native/dart-sdk/android/`. Changes may
cover the download source if the pinned package is unavailable, but may not
silently upgrade the SDK. Reuse the existing ELF/ABI/16 KiB validation.
Documentation and task/spec records capture the resulting contract. App runtime,
shared core, signing identities, and local build output remain outside this task.

## Validation

Check workflow syntax, script syntax, native artifact structure, original input
hashes, and a real GitHub run. Read the completed run's artifact inventory.
App-wide Flutter analysis/tests are unnecessary unless app code changes.
