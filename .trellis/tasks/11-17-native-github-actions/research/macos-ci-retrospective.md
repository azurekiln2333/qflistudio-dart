# Bug analysis: macOS packaging commands

## 1. Root cause category

- Change propagation failure: the first lipo fix covered workflow calls but
  missed the same command in `native/dart-sdk/bundle_macos.sh`.
- Implicit platform assumption: the script used empty Bash argument arrays
  under `set -u`. macOS Bash 3.2 rejects their expansion.
- Packaging contract gap: the complete SDK placed loose data in Helpers.
  Apple treats that directory as nested code, so signing every Mach-O file
  does not make the enclosing application signable.

## 2. Why fixes failed

1. Run 43937445620 rejected the binary path as an architecture. Commit fb34fc1
   fixed YAML calls, but the subsequent app build reached an unchanged script.
2. Commit 8ddca2d corrected the script's lipo order. Run 43940734490 then reached
   signing and reported `sign_options[@]: unbound variable` at line 34.
3. Commit 7776c35 initializes the argument array with required signing flags and
   appends optional arguments. It preserves the signing identity and entitlements.
4. Run 43945574938 reached outer signing, then rejected the unsigned
   `analysis_server.dart.snapshot` under Helpers. The next fix separates SDK
   code and resources, preserving SDK-relative lookup through symbolic links.

`bash -n` passed because these were runtime semantics and Apple command errors,
not Bash grammar errors. The new real Apple run remains the acceptance gate.

## 3. Prevention mechanisms

| Priority | Mechanism | Action | Status |
| --- | --- | --- | --- |
| P0 | Complete call-site review | Search workflows and packaging scripts for lipo calls | Done |
| P0 | Script structure | Keep the signing argument array nonempty | Done |
| P0 | Bundle layout | Put non-Mach-O data in Resources and link its original SDK paths | In progress |
| P0 | Platform validation | Run the actual macOS build and codesign verification | In progress |
| P1 | Executable spec | Record argument order and Bash 3.2 constraints | Done |

## 4. Systematic expansion

The affected command exists both in CI and in the Xcode packaging script.
Fixing either location alone is insufficient. Syntax checks on Windows Git Bash
cannot establish compatibility with the macOS system shell or Apple utilities.
No general shell abstraction or unrelated platform refactor is needed.

## 6. Resource layout evidence

Apple Technical Note TN2206, Nested Code and FAQ, identifies Helpers as a nested
code location. It recommends Resources for non-Mach-O files and symlinks when
existing code expects another path. Signing such data instead relies on extended
attributes that common archive or distribution paths can discard.

Primary source: https://developer.apple.com/library/archive/technotes/tn2206/_index.html

Keep the executable files and their entitlements in Helpers. Preserve the full
SDK data under a Resources mirror. Verify links and codesigning after extracting
the inner tar archive as well as before packaging. Actual macOS CI remains the
acceptance gate; host syntax checks cannot establish Apple signing behavior.

## 5. Knowledge capture

The contract is recorded in `.trellis/spec/backend/dart-native-runtime.md`.
The repository does not contain Trellis's `src/templates/markdown/spec` tree,
so there is no template copy to synchronize here.
