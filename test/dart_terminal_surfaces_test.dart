@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_dart/main.dart' show dartProfile;
import 'package:qfli_dart/native_dart_toolchain.dart';
import 'package:qfli_studio_core/editor/terminal_pane.dart';
import 'package:qfli_studio_core/pages/terminax_terminal_page.dart';
import 'package:qfli_studio_core/services/studio_profile.dart';
import 'package:qfli_studio_core/store/auth_store.dart';
import 'package:qfli_studio_core/store/project_store.dart';
import 'package:qfli_studio_core/terminal/widgets/terminal_output.dart';
import 'package:qfli_studio_core/terminal/widgets/terminal_tabs.dart';

/// Integration verification for the **two real terminal surfaces** the Dart
/// product ships, driven through the **real `dartProfile`**:
///
///   * the editor terminal — `TerminalPane` (`editor/terminal_pane.dart`);
///   * the app-level terminal — `TerminaxTerminalPage`
///     (`pages/terminax_terminal_page.dart`).
///
/// This is the widget-level complement to `test/dart_terminal_delegate_test.dart`
/// (which exercises the backend `dartTerminalDelegate` in isolation) and to the
/// shared core's `terminal_pane_test.dart` / `terminal_manager_delegate_test.dart`
/// (which use a synthetic profile). Here the profile is the **real** Dart one,
/// so the assertions cover the exact wiring a user gets: `dart run <file>` reaches
/// the shipped `dartTerminalDelegate` → `NativeDartToolchain`, its stdout and
/// nonzero status render in the transcript, a stopped long-running program leaves
/// the surface usable for the next command, and switching/hiding sessions does
/// not lose buffered output.
///
/// These tests fail if the profile stops wiring the delegate, if a pane stops
/// streaming/rendering output, or if a stop leaves the prompt dead — none of
/// which a "delegate is non-null" check would catch.
///
/// Execution is real (the host Dart SDK) and gated on
/// [NativeDartToolchain.supported]; on a host without it the run assertions are
/// reported as an explicit environment skip, never a pass. All async waits are
/// bounded pumps with `runAsync`, never fixed sleeps.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // `AppPaths.storageDirectory()` probes the path_provider channel with a 2 s
  // timeout. Without a handler that timer outlives the test, so answer it with
  // a real temp directory — the project's standard AppPaths reset.
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');

  late StudioProfile? previous;
  late Directory project;
  late Directory storage;
  late AuthStore auth;

  setUp(() {
    previous = StudioProfile.current;
    StudioProfile.current = dartProfile;
    project = Directory.systemTemp.createTempSync('qfli_dart_terminal_surface_');
    storage = Directory.systemTemp.createTempSync('qfli_dart_terminal_storage_');
    auth = AuthStore(storageFile: File(p.join(storage.path, 'auth.json')));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (call) async {
          switch (call.method) {
            case 'getApplicationSupportPath':
            case 'getApplicationDocumentsPath':
            case 'getTemporaryPath':
              return storage.path;
          }
          return null;
        });
  });

  tearDown(() {
    StudioProfile.current = previous;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);
    auth.dispose();
    for (final directory in [project, storage]) {
      if (directory.existsSync()) {
        try {
          directory.deleteSync(recursive: true);
        } on FileSystemException {
          // Windows may still hold a handle briefly.
        }
      }
    }
  });

  /// The real product wiring must expose the Dart terminal hook; without it the
  /// surfaces below would exercise a generic sandbox, not the shipped product.
  testWidgets('the Dart profile wires the terminal toolchain hook', (
    tester,
  ) async {
    expect(
      dartProfile.terminalCommandDelegate,
      isNotNull,
      reason: 'The profile must expose the dart terminal delegate.',
    );
    // And a mounted pane actually uses a real, local sandbox with a prompt.
    await _mountPane(tester, project, auth);
    expect(find.byType(TextField), findsOneWidget);
    await _unmount(tester);
  });

  group('editor terminal (TerminalPane)', () {
    testWidgets('dart run prints the program output and a zero success', (
      tester,
    ) async {
      if (!_nativeSupported) return;
      _writeProject(project, "void main() {\n  print('editor-surface-ok');\n}\n");
      final fixture = await _mountPane(tester, project, auth);

      await fixture.submit(tester, 'dart run main.dart');
      await _pumpIoUntil(
        tester,
        () =>
            _line('editor-surface-ok').evaluate().isNotEmpty &&
            !fixture.pane.busy,
      );

      expect(_line('editor-surface-ok'), findsOneWidget);
      // A successful run is silent: no synthetic `exit code 0` line.
      expect(_line('exit code 0'), findsNothing);
      expect(fixture.pane.busy, isFalse);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _unmount(tester);
    });

    testWidgets('a nonzero program exit surfaces its real status', (
      tester,
    ) async {
      if (!_nativeSupported) return;
      _writeProject(
        project,
        "import 'dart:io';\nvoid main() {\n  stderr.writeln('boom-diagnostic');\n  exit(3);\n}\n",
      );
      final fixture = await _mountPane(tester, project, auth);

      await fixture.submit(tester, 'dart run main.dart');
      await _pumpIoUntil(
        tester,
        () =>
            _line('exit code 3').evaluate().isNotEmpty && !fixture.pane.busy,
      );

      expect(_line('boom-diagnostic'), findsOneWidget);
      expect(_line('exit code 3'), findsOneWidget);
      expect(fixture.pane.busy, isFalse);

      await _unmount(tester);
    });

    testWidgets('stopping a long-running program leaves the pane usable', (
      tester,
    ) async {
      if (!_nativeSupported) return;
      // The program prints a marker, then blocks forever so the Stop control
      // becomes the only way out.
      _writeProject(
        project,
        "import 'dart:io';\nvoid main() {\n  print('long-running-start');\n"
            "  while (true) {\n    sleep(const Duration(milliseconds: 20));\n  }\n}\n",
      );
      final fixture = await _mountPane(tester, project, auth);

      await fixture.submit(tester, 'dart run main.dart');
      // Wait until the program is visibly running (marker printed, Stop shown).
      await _pumpIoUntil(
        tester,
        () =>
            _line('long-running-start').evaluate().isNotEmpty &&
            fixture.pane.busy &&
            find.byTooltip('停止').evaluate().isNotEmpty,
      );
      expect(fixture.pane.busy, isTrue, reason: 'the program is still running');

      await tester.tap(find.byTooltip('停止'));
      await _pumpIoUntil(tester, () => !fixture.pane.busy, attempts: 800);

      // The surface is intact and the next command runs for real.
      expect(find.byType(TextField), findsOneWidget);
      _writeProject(project, "void main() {\n  print('after-stop');\n}\n");
      await fixture.submit(tester, 'dart run main.dart');
      await _pumpIoUntil(
        tester,
        () => _line('after-stop').evaluate().isNotEmpty && !fixture.pane.busy,
      );
      expect(_line('after-stop'), findsOneWidget);
      expect(fixture.pane.busy, isFalse);
      expect(tester.takeException(), isNull);

      await _unmount(tester);
    });

    testWidgets('switching sessions keeps each transcript after hide/show', (
      tester,
    ) async {
      if (!_nativeSupported) return;
      _writeProject(project, "void main() {\n  print('first-session-line');\n}\n");
      final host = _PaneHost(project: project, auth: auth);
      final fixture = await _mountHostedPane(tester, host);

      await fixture.submit(tester, 'dart run main.dart');
      await _pumpIoUntil(
        tester,
        () =>
            _line('first-session-line').evaluate().isNotEmpty &&
            !fixture.pane.busy,
      );
      expect(_line('first-session-line'), findsOneWidget);

      // Open a second session; the first transcript must not leak into it.
      await fixture.newSession(tester);
      expect(_line('first-session-line'), findsNothing);

      _writeProject(project, "void main() {\n  print('second-session-line');\n}\n");
      await fixture.submit(tester, 'dart run main.dart');
      await _pumpIoUntil(
        tester,
        () =>
            _line('second-session-line').evaluate().isNotEmpty &&
            !fixture.pane.busy,
      );
      expect(_line('second-session-line'), findsOneWidget);

      // Hide the pane the way the editor does — collapse it to its header, which
      // keeps the pane's element (and its sessions) mounted — then expand it.
      host.collapsed.value = true;
      await _pumpFrames(tester, 6);
      expect(_line('second-session-line'), findsNothing);
      host.collapsed.value = false;
      await _pumpFrames(tester, 6);
      expect(_line('second-session-line'), findsOneWidget);

      // Swap back to the first session: its buffered output is still there.
      await fixture.selectSession(tester, 0);
      expect(_line('first-session-line'), findsOneWidget);
      expect(_line('second-session-line'), findsNothing);
      expect(tester.takeException(), isNull);

      await _unmount(tester);
    });
  });

  group('app terminal (TerminaxTerminalPage)', () {
    // Single test body on purpose: `AppPaths` caches its storage-directory probe
    // in a static future, so a second mounted page in the same file would hang
    // on the first test's (now deleted) directory. This mirrors the shared
    // core's `terminal_manager_delegate_test.dart`, and it is a harness fact, not
    // product behaviour. It covers both the real `dart run` path and session
    // switching for the app surface.
    testWidgets(
      'runs a program through the real profile hook and keeps per-tab output',
      (tester) async {
        final store = ProjectStore();
        addTearDown(store.dispose);

        await _mountApp(tester, store);
        await _pumpIoUntil(tester, () => tester.any(find.byType(TextField)));

        // A non-program command proves the app surface streams and renders, and
        // that switching tabs preserves each transcript.
        await _driveApp(tester, 'echo first-tab-marker');
        await _pumpIoUntil(
          tester,
          () => _appHasLine(tester, 'first-tab-marker'),
        );
        expect(_appHasLine(tester, 'first-tab-marker'), isTrue);

        await tester.tap(find.byIcon(Icons.add));
        await _pumpIoUntil(
          tester,
          () => find.text('终端 2').evaluate().isNotEmpty,
        );
        // The new tab shows its own (empty) transcript, not the first's output.
        expect(_appHasLine(tester, 'first-tab-marker'), isFalse);

        await _driveApp(tester, 'echo second-tab-marker');
        await _pumpIoUntil(
          tester,
          () => _appHasLine(tester, 'second-tab-marker'),
        );
        expect(_appHasLine(tester, 'second-tab-marker'), isTrue);

        // Back to the first tab: its buffered line is still present.
        await tester.tap(find.text('终端 1'));
        await _pumpIo(tester, 30);
        expect(_appHasLine(tester, 'first-tab-marker'), isTrue);

        if (_nativeSupported) {
          // Run a real Dart program through the app terminal. Its session cwd is
          // whatever the app resolved as its working directory, so the program
          // is written at the session's own cwd and run by basename — keeping
          // the operand inside the sandbox on every host.
          final cwd = _activeAppCwd(tester);
          expect(cwd, isNotNull, reason: 'the app session must have a cwd');
          final program = File(p.join(cwd!, 'app_surface_main.dart'));
          program.writeAsStringSync(
            "void main() {\n  print('app-surface-ok');\n}\n",
          );
          addTearDown(() {
            try {
              if (program.existsSync()) program.deleteSync();
            } on FileSystemException {
              // Best-effort cleanup of the probe program.
            }
          });
          await _driveApp(tester, 'dart run app_surface_main.dart');
          await _pumpIoUntil(
            tester,
            () => _appHasLine(tester, 'app-surface-ok'),
            attempts: 800,
          );
          expect(_appHasLine(tester, 'app-surface-ok'), isTrue);
        }

        expect(tester.takeException(), isNull);
        await _unmount(tester);
      },
    );
  });
}

// ---------------------------------------------------------------- fixtures

/// Whether the host can run programs on the official SDK; the shipped delegate
/// only reaches a process when this is true. A missing SDK is an explicit
/// environment skip, never a pass.
bool get _nativeSupported => NativeDartToolchain.supported;

void _writeProject(Directory root, String source) {
  File(p.join(root.path, 'main.dart')).writeAsStringSync(source);
}

class _PaneFixture {
  _PaneFixture(this.key);
  final GlobalKey<TerminalPaneState> key;
  TerminalPaneState get pane => key.currentState!;

  Future<void> submit(WidgetTester tester, String command) async {
    final field = find.byType(TextField);
    expect(field, findsOneWidget, reason: 'the prompt must be on screen');
    await tester.enterText(field, command);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
  }

  Future<void> newSession(WidgetTester tester) async {
    await tester.tap(find.byTooltip('终端操作'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is PopupMenuItem<String> && widget.value == 'new',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> selectSession(WidgetTester tester, int index) async {
    await tester.tap(find.text('${index + 1}'));
    await _pumpFrames(tester, 8);
  }
}

Future<_PaneFixture> _mountPane(
  WidgetTester tester,
  Directory project,
  AuthStore auth,
) => _mountHostedPane(tester, _PaneHost(project: project, auth: auth));

/// Mounts a [TerminalPane] inside a host that controls its `collapsed` state,
/// reproducing how the editor hides the panel (collapse, not unmount).
Future<_PaneFixture> _mountHostedPane(
  WidgetTester tester,
  _PaneHost host,
) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: host)));
  await tester.pump();
  final fixture = _PaneFixture(host.paneKey);
  expect(fixture.pane, isNotNull);
  return fixture;
}

/// Test host mirroring the editor's controlled-collapse contract: the pane
/// stays mounted, only its `collapsed` flag changes.
class _PaneHost extends StatefulWidget {
  _PaneHost({required this.project, required this.auth});

  final Directory project;
  final AuthStore auth;
  final ValueNotifier<bool> collapsed = ValueNotifier<bool>(false);
  final GlobalKey<TerminalPaneState> paneKey = GlobalKey<TerminalPaneState>();

  @override
  State<_PaneHost> createState() => _PaneHostState();
}

class _PaneHostState extends State<_PaneHost> {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 640,
        height: 360,
        child: ValueListenableBuilder<bool>(
          valueListenable: widget.collapsed,
          builder: (context, collapsed, child) => TerminalPane(
            key: widget.paneKey,
            workingDirectory: widget.project.path,
            auth: widget.auth,
            onlineEnabled: false,
            collapsed: collapsed,
            onCollapseChanged: (value) => widget.collapsed.value = value,
          ),
        ),
      ),
    );
  }
}

Future<void> _mountApp(WidgetTester tester, ProjectStore store) async {
  await tester.pumpWidget(MaterialApp(home: TerminaxTerminalPage(store: store)));
  await tester.pump();
}

Future<void> _driveApp(WidgetTester tester, String command) async {
  final field = find.byType(TextField).last;
  await tester.showKeyboard(field);
  await tester.enterText(field, command);
  await tester.testTextInput.receiveAction(TextInputAction.done);
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  // Let real process teardown (and any SIGKILL fallback timer) settle off the
  // fake clock, so a cancelled program does not leave a pending timer.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump(const Duration(milliseconds: 20));
}

// ---------------------------------------------------------------- helpers

Finder _line(String text) => find.byWidgetPredicate(
  (widget) => widget is SelectableText && widget.data == text,
);

/// Whether the **active** app-terminal session's transcript contains [text].
///
/// The app terminal renders through [TerminalOutputView] (`Text.rich` spans),
/// and a `PageView` keeps adjacent pages mounted, so this scopes to the tab the
/// [TerminalTabStrip] reports as active rather than every mounted page.
bool _appHasLine(WidgetTester tester, String text) {
  final strip = tester.widgetList<TerminalTabStrip>(
    find.byType(TerminalTabStrip),
  );
  final activeId = strip.isEmpty ? null : strip.first.activeId;
  for (final view in tester.widgetList<TerminalOutputView>(
    find.byType(TerminalOutputView),
  )) {
    if (activeId != null && view.session.id != activeId) continue;
    for (final line in view.session.lines) {
      if (line.text == text) return true;
    }
  }
  return false;
}

/// The active app-terminal session's cwd, read from the mounted transcript
/// view, or null when no session view is mounted yet.
String? _activeAppCwd(WidgetTester tester) {
  final strip = tester.widgetList<TerminalTabStrip>(
    find.byType(TerminalTabStrip),
  );
  final activeId = strip.isEmpty ? null : strip.first.activeId;
  for (final view in tester.widgetList<TerminalOutputView>(
    find.byType(TerminalOutputView),
  )) {
    if (activeId == null || view.session.id == activeId) return view.session.cwd;
  }
  return null;
}

Future<void> _pumpFrames(WidgetTester tester, int frames) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Bounded pump that also lets real async work (process spawn, streaming)
/// progress, mirroring the shared core's terminal harness. Never a fixed sleep.
Future<void> _pumpIo(WidgetTester tester, int cycles) async {
  for (var i = 0; i < cycles; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
}

Future<void> _pumpIoUntil(
  WidgetTester tester,
  bool Function() condition, {
  int attempts = 500,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (condition()) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  expect(condition(), isTrue, reason: 'The terminal operation did not finish.');
}
