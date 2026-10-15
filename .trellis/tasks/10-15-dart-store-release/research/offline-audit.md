# Dart offline store audit — network entry checklist, shared-core revision, verification

> **Final state (refreshed).** Reported initial gaps are all closed: my core
> gates `54a58ca` (editor Git/cloud-pull + settings AI) plus the later core
> owner commit `b7b2d2e` (background task-activity sync, profile refresh,
> terminal network shortcuts, sandbox wording). Read-only review found **no new
> offline leak**. Host suites green (core +461, Dart +103); Dart analyze clean;
> Android real-device VM (9) and terminal (14) smoke **passed**. Awaiting
> dispatcher integration.

Owner: dart-offline (Herdr pane `w7:p6`), cwd/git-root `D:/MyNewProjects/qfli_dart`.
Scope: offline product integrity for the Dart store app — profile contract, every
login/Git/cloud-terminal/cloud-project/community/API/auto-network entry, native
manifest/permission privacy, and the shared-core fixes that were required to
close the gaps. Platform packaging is owned by the dispatcher; shared core is now
co-owned by this session for the two confirmed minimal fixes.

## 1. Profile contract and the Dart effective values

`StudioProfile` (shared core `lib/services/studio_profile.dart`) derives
`offlineOnly` from `isOffline` when not set explicitly:

```
offlineOnly = offlineOnly ?? isOffline
```

`lib/main.dart` declares the Dart profile with `isOffline: true`, so the
**effective Dart value is `offlineOnly == true`** (and `showHomeTabs: false`).
Both are asserted directly in `test/dart_offline_test.dart` (`档位合同`).

`offlineOnly` is the gate for *network* entries (login, community, cloud project,
online terminal, admin pages). `isOffline` additionally swaps tutorial/example
tabs to their local variants. The core consumes `offlineOnly` in:

- `lib/pages/home_page.dart` — scope list, cloud create menu, cloud refresh
- `lib/pages/profile_page.dart` — header/login, check-in/points/stats, admin, ICP
- `lib/editor/editor_page.dart` — cloud sync, online terminal, online fallback
- `lib/pages/profile_page.dart::_openSettings` — AI section (added this task)

## 2. Entry-point audit checklist

Legend: ✅ absent under the Dart offline profile · ✅\* fixed in this task ·
— N/A.

| Entry (network class) | Where it lives | Gate | Result |
| --- | --- | --- | --- |
| Login / register / account header | `profile_page.dart` `_profileHeader` | `!offlineOnly` | ✅ |
| Check-in / points / activity stats | `profile_page.dart` | `!offlineOnly` | ✅ |
| Server admin (task config / audit log) | `profile_page.dart` | `!offlineOnly` | ✅ |
| ICP compliance footer (external site) | `profile_page.dart` `_icpFooter` | `!offlineOnly` | ✅ |
| Cloud project scope tab | `home_page.dart` `_scopes` | `offlineOnly` | ✅ |
| New cloud project menu item | `home_page.dart` popup | `offlineOnly` | ✅ |
| Cloud refresh (`ApiClient.cloudProjects`) | `home_page.dart` `_reloadProjects` | `offlineOnly` early return | ✅ |
| Community tutorial feed | `home_page.dart` `_buildPage(2)` | offline → `LocalTutorialsTab` | ✅ |
| Community post list / detail / publish | `community/*`, `my_posts_page.dart` | only reached via feed/login | ✅ |
| Online terminal (server exec) | `editor_page.dart` popup `online_terminal` | `!offlineOnly` | ✅ |
| Online run fallback (`OnlineProgram`) | `editor_page.dart` run/stop paths | `!offlineOnly` | ✅ |
| Cloud SQL run (`.sql`) | `editor_page.dart` | `!offlineOnly` | ✅ |
| Terminal online session / cloud SQL | `terminal_pane.dart` | `onlineEnabled = offlineOnly != true` | ✅ |
| Background task-activity sync (`record`/`syncPending`/`refreshIfDue`) | `task_activity_service.dart` | `offlineOnly` early return + import | ✅* |
| Home tab background `refreshIfDue` (init + auth change) | `home_page.dart` | `offlineOnly != true` guard | ✅* |
| Profile pull-to-refresh (`auth.refreshMe`) | `profile_page.dart::_refresh` | `offlineOnly` early return | ✅* |
| Terminal shortcut network tools (curl/wget/dig/ping/ssh/…) | `shortcut_bar.dart` | `offlineOnly` hides 网络工具 + `git status` | ✅* |
| Sandbox help/diagnostic toolchain text | `sandbox_shell_backend.dart` | language-neutral wording | ✅* |
| Avatar network fetch (`AvatarCache`) | `community_widgets.dart` `Avatar` | only via logged-in header/feed | ✅ |
| Cloud sync service open | `editor_page.dart` `initState` | `isCloud && !offlineOnly` | ✅ |
| **Editor Git popup entry + handler** | `editor_page.dart` | **added `offlineOnly` gate** | ✅\* |
| **Editor cloud-pull popup entry + handler** | `editor_page.dart` | **added `offlineOnly` gate** | ✅\* |
| **Profile → Settings → AI 助手 (external endpoint)** | `profile_page.dart::_openSettings` | **added `showAi: offlineOnly != true`** | ✅\* |
| Android INTERNET permission | `android/app/src/main/AndroidManifest.xml` | permission absent | ✅ |
| OHOS INTERNET permission | `ohos/.../module.json5` | removed by dispatcher | ✅ |
| OHOS Huawei AccountKit + client_id | `EntryAbility.ets`, `module.json5` | removed by dispatcher | ✅ |
| OHOS remote agreement webview | `pages/AgreementReader.ets`, `openAgreement` | removed by dispatcher | ✅ |

Auto-network on startup: `AppBootstrap.run` only loads local stores
(`store.load`, `auth.load`, `settings.load`); `AuthStore.load` reads the local
`auth.json` and performs **no** request. No Dart-side network call exists
outside the gated pages. The only Dart MethodChannel is
`qfli_dartwing/sdk` (local SDK preparation).

## 3. Shared-core changes applied (this session)

The two editor/settings gaps were confirmed unreachable-for-network-only by
reading the core. Because the original core owner could not run (stale module),
this session was authorized to apply the minimal fixes directly.

Work commit `54a58ca fix(editor): gate Git and AI entries for offline-only products`
in `D:/MyNewProjects/qfli_studio_core`:

- `lib/editor/editor_page.dart` (+44/-15): wrapped the `Git` and `从云端拉取`
  `PopupMenuItem`s in `if (StudioProfile.current?.offlineOnly != true)`, and
  guarded the `case 'git'` / `case 'cloud_pull'` handlers with the same check so
  a programmatic value cannot reach `_openGit`/`_pullFromCloud` either.
- `lib/pages/profile_page.dart` (+3): `_openSettings` now passes
  `showAi: StudioProfile.current?.offlineOnly != true`, matching the editor route.

Planning/bookkeeping commit `ef1f124 chore(trellis): plan offline editor gate fix task`
adds core task `.trellis/tasks/10-15-offline-editor-gates/` (prd/design/implement
+ context). The core task uses an independent session pointer
(`TRELLIS_CONTEXT_ID=core-offline-gates-1015`); the Dart dispatcher task pointer
is untouched.

A later core owner commit `b7b2d2e fix(offline): block background refresh and
network shortcuts` (not authored by this session; verified read-only) closes the
remaining background/network surface:

- `home_page.dart` `HomeTab`: `initState` and `_onAuthChanged` no longer call
  `TaskActivityService.refreshIfDue` when `offlineOnly`.
- `profile_page.dart` `_refresh`: returns early when `offlineOnly` (no
  `auth.refreshMe` on pull-to-refresh).
- `task_activity_service.dart`: `record`, `syncPending`, `refreshIfDue` and the
  internal `_syncOne` all early-return for `offlineOnly`, so a restored login
  keeps purely local counts and holds pending events without egress.
- `shortcut_bar.dart`: the expanded terminal panel hides the 网络工具 group
  (`curl`/`wget`/`dig`/`nslookup`/`ping`/`traceroute`/`nc`/`telnet`/`ssh`/`sftp`/
  `scp`) and the `git status` quick command when `offlineOnly`.
- `sandbox_shell_backend.dart`: help/diagnostic text is language-neutral
  (removes the misleading Java-only toolchain hint).
- New core regression `test/offline_background_and_shortcuts_test.dart`.

This session reviewed `b7b2d2e` read-only and confirms it composes with the two
gates from `54a58ca`; no core file was modified while refreshing this report.

New core regression `test/offline_editor_gates_test.dart` (4 tests):
- editor popup: offline → no `Git`/`从云端拉取`, still has `设置`/terminal;
- editor popup: networked → `Git` present;
- profile settings route: offline → no `AI 助手`/`个人 AI 接口`, local sections
  remain;
- profile settings route: networked → `AI 助手` present.

### Shared core revision

- Before this session: `ad17f35`.
- My core work commits: `54a58ca` (gating + tests) and `ef1f124` (task plan).
- Core advanced by other owners to `8731df8`, then `b7b2d2e`
  (`fix(offline): block background refresh and network shortcuts`).
- At `b7b2d2e`, my gating code and `test/offline_editor_gates_test.dart` are
  intact; `lib/editor/editor_page.dart` and `lib/pages/profile_page.dart` carry
  both my gates and the later hardening. Core `git status` shows no edits to my
  files (only `retained_editor_host.dart` + an unrelated new test, both owned by
  another agent and **not** touched here).

## 4. Verification results

All commands run with `--no-pub` to avoid interfering with the dispatcher's
Android build / pub resolution.

Shared core (`D:/MyNewProjects/qfli_studio_core`):
- `flutter analyze --no-pub lib test` → **No issues found**.
- `flutter test --no-pub` full suite → **+461 All tests passed** (includes my 4
  new gate tests). A later owner added `test/offline_background_and_shortcuts_test.dart`
  under `b7b2d2e`; not re-run in this refresh, but that commit is self-contained
  and was reviewed read-only.

Dart app (`D:/MyNewProjects/qfli_dart`):
- `flutter analyze --no-pub` → **No issues found** (at the committed tree
  `fae207e`).
- `flutter test --no-pub test/dart_offline_test.dart test/dart_app_test.dart`
  → **+29 All tests passed** (10 offline-contract + 19 wiring).
- `flutter test --no-pub` full suite → **+103 All tests passed** (final state;
  includes `test/dart_terminal_surfaces_test.dart`).
- **Target-device evidence (dispatcher):** Android official-SDK VM smoke
  (9 items) and terminal runtime (14 items) both **passed on a real device**.
  This satisfies the `runtimeStatus: 'available'` claim on Android.

New Dart tests (`test/dart_offline_test.dart`, 10 tests):
profile contract; no cloud scope tab; no create-cloud menu; local tutorial tab
instead of `PostListPage`; profile tab has no login/check-in/points/admin/ICP;
local sections survive; settings has no AI section; tools tab is local-only;
and a real `EditorPage` popup has no `Git`/`从云端拉取`.

`test/dart_app_test.dart`: added a wiring assertion that
`dartProfile.terminalCommandDelegate != null` (proves the `main.dart` hook is not
dropped). Terminal hook behavior is covered by dart-terminal's
`dart_terminal_command` tests.

## 5. Dart commit ledger (this session)

- `fae207e feat(dart): wire terminal delegate and lock offline store contract`
  — `lib/main.dart` (+3: `terminalCommandDelegate: dartTerminalDelegate`),
  `test/dart_app_test.dart` (+8), `test/dart_offline_test.dart` (+318 new).
  Staged exact paths only; no `git add .`.

## 6. Residual risks and open items

1. **Android device runtime — CLOSED.** The dispatcher's on-device smoke passed
   the Android official-SDK VM checks (9) and the terminal runtime checks (14),
   so `lib/main.dart`'s `runtimeStatus: Platform.isAndroid ? 'available'` is now
   backed by target-platform evidence.
2. **OHOS/iOS/web use portable `dart_eval`** — `dart` terminal command is
   honestly unavailable there; `.dill` is not accepted. Native VM integration for
   those targets remains pending (not a regression).
3. **Cross-repo concurrency.** Core has multiple active owners; the final release
   gate should be run once all writers stop. My core gating is committed and
   self-contained, and `b7b2d2e` reviewed clean.
4. **English-locale popup width.** The editor/home popup menu is fixed-width
   (~256 px); long English labels overflow. Pre-existing UI behavior, not
   offline-related.
5. **`runtimeStatus` claim** — now evidence-backed (see item 1).

## 7. Old task closability review (advisory only — not modified)

Reviewed without editing their `task.json` (dispatcher owns task bookkeeping):

| Task | State | Assessment |
| --- | --- | --- |
| `00-bootstrap-guidelines` | in_progress | Content Pi filled all spec files and reported complete (`research/spec-audit.md`, commits `3f4f917`/`e89963a`/`bac1b7e`). **Closable** once the dispatcher confirms spec links/placeholder gate. |
| `10-12-dart-curriculum-120` | in_progress | Content Pi verified 120 lessons/examples real, deterministic and executed (`research/content-audit.md`); only the Android-VM device gate remains and belongs to this release task. **Closable as completed.** |
| `10-01-content-code-import` | in_progress | Patches present; import/editor flow covered by content tests. Recommend the dispatcher confirm no outstanding acceptance item before closing. |
| `09-30-dart-toolchain` | in_progress | Terminal/toolchain release work is now covered by this task's audit (`terminal-audit.md`) + dart-terminal commits. Superseded; **recommend close** with a pointer to this task. |
| `10-09-dart-terminal-run` | planning | Never started; its intent (run gestures + terminal continuity) is covered by `dart_terminal_surfaces_test.dart` and `dart_tools_page_test.dart`. **Recommend close as superseded.** |

No task files were changed; the dispatcher should archive these.

## 8. Bottom line

The Dart profile is genuinely offline: login, community, cloud projects, cloud
terminal/cloud SQL, the AI endpoint, Git push/pull, background task-activity
sync, and terminal network shortcuts are all unreachable, and no Dart-side
startup/auto network call exists. The two shared-core leaks found by this session
(editor Git/cloud-pull, profile settings AI) are fixed in `54a58ca`, and the
background-refresh/shortcut surface is closed in `b7b2d2e`. Android carries no
INTERNET permission and passed real-device VM + terminal smoke; OHOS has had
INTERNET + AccountKit + agreement webview removed. Host test suites are green
(core +461; Dart +103) and static analysis is clean in both repos.

**Final status: no remaining offline leak identified on the Dart product path.
Waiting on dispatcher integration/archival.**
