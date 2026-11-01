# Dart host05 actual evidence

Grant raw807: Dart-host-20261026-05. ACK811.
Identity:8c3896140941a4579b0aa2089c78cc46437287d3430447f045cd32dd08015ed1.
Run:build/dart-host-gate/gate-20261026-115746-8020/final.json.
Final SHA256:4caf7073cf58e7c56988aeddd4f7abe00346c9609d3f791c1d545388d2d5f654.

## Actual outcome

- HOST_GATE_FAILED, exit3221226505, runner3.321s.
- Real ownership controls3/3 PASS.
- Verify process80816 aborted. The only79byte log line is Dart VM zone.cc:100 Out of memory. Log SHA2562b7448c554e917a7c0cfcaaf2cbc39bf3b6b494fb9d15433861828681750129c.
- counts={} empty; current05 exercise completion is not claimed.
- Analyze and Flutter fullsuite UNRUN.
- Historical04 exercise58/58 remains a separate actual result. Its artifact cannot establish current05 success.
- All4 exact retained root identities verified, roots terminal, Jobs active0. Repo/core/re_editor/packageConfig/toolchain source identity stable.

## Exit and release evidence

Python process exit in receipt:-1073740791. Windows unsigned final status:3221226505, the same32bit state0xC0000409. The explicit VM log establishes OOM; the status alone is not an OOM diagnosis. Launcher incorrectly compared signed and unsigned integers, threw, and the actual outer invocation returned1 with no pending session. Receipt was preserved by finally.

Root inspected grant/runId/receipt and every exact retained root before manual RELEASE812. Exact PIDs63976,63900,11388,80816 with their handle/creation evidence are in final.json and812. The publication invocation itself then returned terminal0 with812 appended; corroboration813 reported that actual return. Release attempt sampled229.936s after ACK. The later terminal corroboration was outside240. No full240 handoff success claim. No05 replay, no SDK since release; successor C reconciles Lua.

## Source-only repair

Only ignored PowerShell helpers changed. New ConvertTo-WindowsExitBits validates signed/unsigned DWORD input range before comparing exact32bit statuses. Launcher and publisher use this equality, and publisher OuterExit accepts long. Pure script cases:4equivalences,1distinct pair,2out-of-range rejections PASS. PowerShell source parsers clean. Original actual05 wrapper exit1 remains unchanged and disclosed; repair cannot turn the actual failed run into a pass. Product identity still matches8c389614; helper bytes are outside that identity.

## Later host memory observation

Read-only Win32_OperatingSystem snapshot at2026-10-26T12:11:03.3928721+08:00: totalVisibleKiB33285844,freePhysicalKiB5907652,totalVirtualKiB66840276,freeVirtualKiB173008. This is a later observation, not crash-time measurement and not proof of the precise OOM cause. No memory/process cleanup was performed.

Core64f0aa7 is now published with same bound lib/config bytes7bf7d365 and C-reported47/47 terminal tests/scoped analyze clean. This does not validate Dart current-source analysis/fullsuite or OHOS. No new commit/push; installedOHOS/native/currentfullsuite/final300 gates remain open.

## Independent acceptance and next-window source preparation

C816 independently accepted original launch terminal1, actual publisher terminal0 and corroboration terminal0; final SHA and all4 retained roots terminal/identity/Job0 were verified. C explicitly confirmed final proof outside240 and current05OOM/UNRUN. No live reservation remains. C later sampled about6GiB commit headroom and9807MiB physical available; this separate point observation does not explain or negate the earlier VM failure.

C816 requires a fresh preACK memory-headroom observation before another real run. Ignored launcher now captures Win32_PerfFormattedData_PerfOS_Memory immediately before ACK and persists sample time, committed bytes, commit limit, derived headroom and physical availability in the receipt. ACK reports these observed values and explicitly gives no capacity guarantee. Missing/invalid observations refuse beforeACK. No arbitrary minimum threshold or auto-retry was introduced. This path has not been executed under a new grant. No SDK launched.
