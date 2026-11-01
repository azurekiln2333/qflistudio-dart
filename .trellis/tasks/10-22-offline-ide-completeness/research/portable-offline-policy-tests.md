# Retained offline host-policy regression tests

## Change boundary

The experimental host-policy and permission probes passed, but their checks lived
under ignored `.dart_tool/` directories. The behavior gap is missing retained
regression coverage for the newly vendored interpreter's offline boundaries.

Only `test/portable_offline_policy_test.dart` and this evidence file are owned by
this work. Tests exercise the public policy and the actual filesystem/network
bridge functions from the normal product dependency. Candidate, vendor, runner,
curriculum, shared core and dependency files remain owned by the parent task.
There is no runtime refactor in this step.

## Retained proof

- Execute unchanged lessons 097–104 with actual run scratch directories; compare
  authored exact output and verify the lessons clean their real temporary files.
- Exercise scoped read/write grants, project-relative native handles, raw paths,
  copy/rename destinations and temporary-directory prefix containment.
- Apply broad grants deliberately and verify the offline policy still denies
  outside files, network, process, execute, dangerous and certificate operations.
- Verify standard-stream chunks, split UTF-8 bytes, run-owned close/configuration,
  unsupported stdin, unchanged process cwd and child policy inheritance.
- Use stand-in network objects and a socket override counter; no real DNS,
  socket binding, connections or datagram sends are needed.
- Exercise real symbolic links and broken links. Only inability of the host to
  create the link may skip those fixtures, with the actual host error recorded.
- Preserve file-mode checks against real SDK handles, including independent read
  and write grants and write-only modes.

## Validation

Validation used the normal product package configuration after the parent
promoted `vendor/tom_d4rt` and ran offline dependency resolution. No merged or
experimental package configuration was required for these commands.

| Command | Result |
| --- | --- |
| `dart format test/portable_offline_policy_test.dart` | Formatted |
| `flutter analyze --no-pub test/portable_offline_policy_test.dart` | No issues |
| `flutter test --no-pub --reporter expanded test/portable_offline_policy_test.dart` | **49/49 passed, zero skipped** |
| `git diff --check -- test/portable_offline_policy_test.dart .trellis/tasks/10-22-offline-ide-completeness/research/portable-offline-policy-tests.md` | No whitespace errors reported |

The retained suite combines the earlier 32 offline-policy assertions and 24
permission probe checks into 49 named Flutter tests, preserving the key behavior
and adding independent scoped read/write grants, asynchronous directory listing,
privileged broad-grant denial, and `FileSystemEntity` rename fallback coverage.
Unchanged lessons 097–104 execute their actual code and compare exact authored
output; every lesson also leaves its real scratch directory empty. The earlier
experimental probe compared these lessons directly with the installed Dart SDK.

Both native directory-link listing fixtures (`list` and `listSync`) and the
native broken-file-link fixture executed successfully on this Windows host.
None was skipped. Other hosts may skip only a failed native link creation, and
the skip message includes the actual `FileSystemException`.

The socket-connect override counter remained zero for a denied broad grant.
Reverse-DNS and UDP tests use concrete stand-ins; denial leaves their invocation
counters at zero, while matching non-offline grants reach those stand-ins only.
The suite performs no real DNS, binding, socket connection or datagram send.
File-mode comparisons use real SDK file handles and real temporary-file data.

Earlier experimental evidence remains 32/32 offline-policy checks, 24/24
permission checks, and 22/22 SDK semantic comparisons. Those are distinct from
the retained Flutter test count. This is host evidence; OHOS build and device
execution remain separate gates owned by the parent task.
