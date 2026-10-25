# Dart HAP inspection

`tool/ohos/inspect_dart_hap.py` inspects a frozen package without signing,
installing or launching it. It uses Python's standard library only.

## Package contract

- Match the bundle, vendor, module, main element, device types and version to
  the authored product configuration. Record hashes of those configuration files.
- Require both `libapp.so` and `libflutter.so` for the requested ABI. Validate
  the ELF header and reject mixed ABIs or native libraries outside `libs/`.
- Compare packaged permissions to the authored manifest. Reject the forbidden
  network and sensitive permission set.
- Derive the curriculum denominator from the authored assets. Compare the exact
  packaged asset bytes, schema, kind, ids, language and lesson/example bodies.
  An explicit `--topics` must agree with the authored count.
- Hash the HAP before and after inspection. An optional `--expect-sha256` must
  match. Write a failure report and return nonzero for a rejected package,
  including a corrupt ZIP archive.
- `releaseModeVerified` requires an actual non-debug release manifest. Merely
  requesting release validation must not set this field true on a debug package.

## Evidence boundary

A successful package inspection establishes the package checks above for those
exact bytes. It does not establish signature/profile validity, installed-device
execution or the native offline URL refusal behavior. Their flags remain false.
The preserved x64 audit HAP predates the native URL guard and must retain that
limitation even when its inspection passes.

## Verification

```powershell
python tool/ohos/test_inspect_dart_hap.py
```

The fixtures exercise valid ARM64/x64 packages and rejected identity, ABI,
permissions, assets, fingerprint and release-mode cases. They also prove that a
corrupt archive leaves a failure report and a debug package never claims verified
release mode. A Dart/Flutter/native rebuild is a separate gate.
