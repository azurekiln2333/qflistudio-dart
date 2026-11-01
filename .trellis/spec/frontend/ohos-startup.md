# OHOS Native Startup

## 1. Scope / Trigger

Read before changing `lib/main.dart` or the OHOS `EntryAbility.ets` / `Index.ets`
startup flow. The native loading page follows JVMX; the application after startup
uses the shared Flutter UI. Other platforms retain their Flutter loading page.

## 2. Signatures

- Method channel: `qflistudio/platform`.
- Method: `startupProgress`, arguments: `{progress: double}` in `[0, 1]`.
- Ability event: `EVENT_STARTUP_PROGRESS`, payload: normalized progress.
- `FlutterPage.splashScreenView` builds the ArkUI `StartupSplash` component.

## 3. Contracts

- OHOS defers the first engine frame before `runApp`. Load the existing local
  stores through `AppBootstrap.run`; report their real completion progress.
- Match JVMX's native layout: the app's own 96 vp icon, 24 vp rounded corners,
  a bottom linear progress indicator, and the native startup background color.
- Subscribe/unsubscribe the same event callback in the component lifecycle.
- Match JVMX's timing: allow 160 ms for event subscription, keep the native
  loading layer at least 1100 ms, and show completed progress for 320 ms.
- Wait for `binding.endOfFrame` after readiness so the first submitted engine
  frame contains the home page or restore gate. Release deferral in `finally`.
- Do not add network requests or native startup delays on other platforms.

## 4. Validation & Error Matrix

| Condition | Result |
| --- | --- |
| Finite numeric progress | Clamp to `[0, 1]`, emit event, return success |
| Invalid progress | `INVALID_PROGRESS`; no event |
| Missing/rejected progress bridge | Continue loading and release the first frame |
| Stores still loading | Native loading page stays visible |
| Home laid out and display timing complete | Allow first frame; native layer fades out |

## 5. Good / Base / Bad Cases

Base: cold launch shows the native icon and progress before the home page.
Good: unavailable progress reporting does not leave a permanent splash.
Bad: submitting the Flutter loading screen first removes the native layer early.

## 6. Tests Required

`test/dart_startup_test.dart` exercises the real entry point with working,
missing and rejected progress channels, first-frame deferral through home
layout, and immediate Flutter startup on Android. Run analyze and all tests.
Build ARM64 HAP and APP; check the native launch on device separately from
host tests and package verification.

## 7. Wrong vs Correct

Wrong: add only `splashScreenView`; Flutter's loading widget becomes the first
engine frame and dismisses the native layer before initialization completes.
Correct: wire native progress, defer that frame, finish bootstrap and layout,
then allow the first frame in `finally`.
