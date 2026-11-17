# Native dependencies and applications on GitHub Actions

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

## Expanded acceptance (user clarification)

The user explicitly requires Android, Windows, Linux, macOS, iOS and OHOS,
and selected both native dependencies and complete application build outputs.
Run each feasible hosted build and report genuine environment blockers.
Unsigned iOS archives are not installable IPA files. macOS unsigned/ad-hoc
bundles are not notarized releases. OHOS uses its portable runtime, so exported
native libraries must not be labeled an independent Dart SDK.

## License alignment (additional user instruction)

The user requests GNU GPL v3.0 alignment with `../qflistudio`, followed by a
conventional commit and push. The existing tracked LICENSE has the identical
SHA256 in both repositories. Add the same project notice to all three READMEs,
preserving the separately licensed vendored content. Commit d781661 completes
this request on the existing trial branch. Do not modify the main project's
unrelated working-tree changes or interpret alignment as a default-branch merge.

## Boundary

The missing behavior is remote execution of existing native packaging scripts.
It belongs in `.github/workflows/` and `native/dart-sdk/android/`. Changes may
cover the download source if the pinned package is unavailable, but may not
silently upgrade the SDK. Reuse the existing ELF/ABI/16 KiB validation.
Documentation and task/spec records capture the resulting contract. Expand into
cross-platform workflows, CI bootstrap helpers, minimal app platform detection
compatibility, and a reviewed patch of a fixed shared-core CI checkout. Preserve
the user's local shared-core edits and local custom Flutter SDK. No signing
identity upload, default-branch merge, or deletion of existing local outputs.

## Validation

Check workflow syntax, script syntax, native artifact structure, original input
hashes, and a real GitHub run. Read the completed run's artifact inventory.
App-wide Flutter analysis/tests are unnecessary unless app code changes.
