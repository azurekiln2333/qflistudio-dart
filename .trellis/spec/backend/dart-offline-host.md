# Dart native offline boundary

## 1. Scope / Trigger

Read before changing OHOS EntryAbility platform routes or standalone offline
policy. The Dart profile has `isOffline: true`; the OHOS manifest requests only
`ohos.permission.READ_PASTEBOARD`. The product has no external-browser or
remote-agreement feature. Hidden shared UI actions supplement the native guard.

## 2. Signatures

Channel `qflistudio/platform` receives `openUrl` or `openAgreement` and responds
with `result.error('OFFLINE_ONLY', 'Dart 独立版不打开外部页面', null)` exactly once.
No argument is required or read for these denied operations.

## 3. Contracts

Reject absent, malformed, file, custom-scheme, external HTTP and loopback URLs.
Do not call `startAbility`, a router or a browser. The Dart product registers no
native account handler or remote-agreement page. Its editor supports Dart
source and, on native SDK platforms, Kernel binaries; it has no URL preview
contract that requires a native exception to this rule.

Preserve local `shareText`, picker routes, plugin registration, native window
initialization and any existing startup-progress handler. Sharing is an explicit
system-sheet action, not automatic URL delegation. Preserve signing credentials
and permissions. Do not infer that source enforcement proves installed bytes.

## 4. Validation / Error Matrix

| Input / condition | Required observation |
| --- | --- |
| Either denied method, any arguments | One OFFLINE_ONLY reply, zero external ability calls |
| shareText success / failure | Actual local share / SHARE_FAILED |
| Existing picker method | Delegate to local PickerBridge |
| Unknown method | notImplemented, no external action |
| HAP built before this source patch | Historical evidence only; rebuild required |

## 5. Good / Base / Bad Cases

Base: a direct HTTPS openUrl request fails without a system-browser launch.
Good: malformed arguments and loopback/custom/file URIs fail identically while
local picker/share still work. Bad: relying on hidden UI or absence of INTERNET
permission while leaving arbitrary external-intent delegation available.

## 6. Tests Required

`node --max-old-space-size=128 --test test/native_entry_ability_test.cjs`
transpiles and executes the actual EntryAbility handler against stubbed OHOS
services. Assert exactly one refusal and no external calls for both methods,
share success/failure, picker routes, plugin registration and native window
initialization. Set `QFLI_TYPESCRIPT` to override the DevEco TypeScript module
path. The original startup-progress work stays independently owned/tested.

This is behavioral host coverage, not ArkTS type checking or installed-device
network verification. Build and validate the actual current-source OHOS package
before claiming the final artifact includes the guard.

## 7. Wrong vs Correct

Wrong: keep `startAbility(want)` because ordinary offline UI hides its button.
Correct: refuse direct native requests before reading arguments; preserve only
the product's real local share/picker functionality.
