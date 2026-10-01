import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_dart/native_dart_toolchain.dart';
import 'package:qfli_dart/dart_tools_page.dart';
import 'package:qfli_dart/main.dart' show dartProfile;
import 'package:qfli_studio_core/pages/quick_tools_page.dart';
import 'package:qfli_studio_core/services/project_templates.dart';
import 'package:qfli_studio_core/services/studio_profile.dart';
import 'package:qfli_studio_core/store/project_store.dart';

Future<void> _waitFor(
  WidgetTester tester,
  bool Function() complete, {
  required String reason,
}) async {
  final elapsed = Stopwatch()..start();
  while (!complete() && elapsed.elapsed < const Duration(seconds: 15)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(
    complete(),
    isTrue,
    reason:
        '$reason: ${tester.widgetList<Text>(find.byType(Text)).map((item) => item.data).join(' | ')}',
  );
}

Future<void> _mountTools(
  WidgetTester tester,
  ProjectStore store, {
  Size size = const Size(900, 1100),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() async {
    try {
      if (find.byTooltip('停止').evaluate().isNotEmpty) {
        await tester.ensureVisible(find.byTooltip('停止'));
        await tester.tap(find.byTooltip('停止'));
      }
      await _waitFor(
        tester,
        () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
        reason: 'Operation must finish before removing its project',
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ContentToolsPage(store: store),
              ),
            ),
            child: const Text('打开工具'),
          ),
        ),
      ),
    ),
  );
  await _openTools(tester);
}

Future<void> _openTools(WidgetTester tester) async {
  await tester.tap(find.text('打开工具'));
  await tester.pump();
  await _waitFor(
    tester,
    () =>
        find.byType(TextField).evaluate().isNotEmpty &&
        find.byType(CircularProgressIndicator).evaluate().isEmpty,
    reason: 'Real project source must load',
  );
  await tester.pumpAndSettle();
  expect(find.byType(DartToolsPage), findsOneWidget);
}

Future<void> _performAction(WidgetTester tester, String tooltip) async {
  await tester.ensureVisible(find.byTooltip(tooltip));
  await tester.tap(find.byTooltip(tooltip));
  await tester.pump();
  await _waitFor(
    tester,
    () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
    reason: '$tooltip must finish',
  );
}

Future<void> _chooseOption(
  WidgetTester tester,
  int dropdown,
  String label,
) async {
  await tester.tap(find.byType(DropdownButton<String>).at(dropdown));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pump();
  await _waitFor(
    tester,
    () => find.byType(AlertDialog).evaluate().isNotEmpty,
    reason: 'Unsaved changes must be confirmed',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory workspace;
  late ProjectStore store;
  late File mainFile;
  late StudioProfile? previousProfile;

  setUp(() async {
    previousProfile = StudioProfile.current;
    StudioProfile.current = dartProfile;
    workspace = await Directory.systemTemp.createTemp('qfli_dart_tools_page');
    store = ProjectStore(
      storageFile: File(p.join(workspace.path, 'projects.json')),
    );
    await store.load();
    final created = await store.createProject(
      name: 'Demo',
      location: workspace.path,
      template: ProjectTemplate.dart,
    );
    expect(created.error, isNull);
    mainFile = File(p.join(created.project!.path, 'src', 'main.dart'));
    expect(mainFile.existsSync(), isTrue);
  });

  tearDown(() async {
    StudioProfile.current = previousProfile;
    store.dispose();
    await workspace.delete(recursive: true);
  });

  testWidgets('real source can be formatted, saved, checked, and compiled', (
    tester,
  ) async {
    expect(dartProfile.toolsPageBuilder, isNotNull);
    await _mountTools(tester, store);
    expect(find.text('Dart 工具'), findsOneWidget);
    expect(find.text('Demo'), findsWidgets);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, ProjectTemplate.dart.files.first.content);

    await tester.enterText(find.byType(TextField), 'void main(){print("hi");}');
    await _performAction(tester, '格式化 Dart');
    expect(
      field.controller!.text,
      contains('void main() {\n  print("hi");\n}'),
    );
    await _performAction(tester, '保存');
    expect(
      await tester.runAsync(mainFile.readAsString),
      field.controller!.text,
    );

    await tester.enterText(find.byType(TextField), 'void main( {');
    await _performAction(tester, '语法检查');
    expect(find.byIcon(Icons.error_outline), findsWidgets);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);

    const compiledSource = 'void main() { print(42); }';
    await tester.enterText(find.byType(TextField), compiledSource);
    await tester.tap(find.byTooltip('编译'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    expect(
      tester
          .widgetList<DropdownButton<String>>(
            find.byType(DropdownButton<String>),
          )
          .every((item) => item.onChanged == null),
      isTrue,
    );
    await _waitFor(
      tester,
      () =>
          find.byType(CircularProgressIndicator).evaluate().isEmpty &&
          find.textContaining('已生成 ').evaluate().isNotEmpty,
      reason: 'Bytecode write and flush must finish successfully',
    );
    final project = store.projects.first;
    final artifact = File(p.join(project.path, 'build', 'src', 'main.dill'));
    final result = await tester.runAsync(() async {
      final run = await const NativeDartToolchain().run(
        projectPath: project.path,
        entryFile: artifact.path,
      );
      final errors = run.stderr.toList();
      final output = await run.stdout.toList();
      expect(await errors, isEmpty);
      expect(await run.exitCode, 0);
      return output;
    });
    expect(result, ['42']);
    expect(await tester.runAsync(mainFile.readAsString), compiledSource);
  });

  testWidgets('Run saves edits and displays actual output and exit status', (
    tester,
  ) async {
    await _mountTools(tester, store);
    const source = 'void main() { print("tool-output"); }';
    await tester.enterText(find.byType(TextField), source);
    await _performAction(tester, '运行');
    expect(find.text('tool-output'), findsOneWidget);
    expect(find.text('退出码 0'), findsOneWidget);
    expect(find.byTooltip('停止'), findsNothing);
    expect(await tester.runAsync(mainFile.readAsString), source);

    await tester.enterText(
      find.byType(TextField),
      'void main() { print("second-run"); }',
    );
    await _performAction(tester, '运行');
    expect(find.text('tool-output'), findsNothing);
    expect(find.text('second-run'), findsOneWidget);
    expect(find.text('退出码 0'), findsOneWidget);
  });

  testWidgets('Stop cancels an infinite program and restores the editor', (
    tester,
  ) async {
    await _mountTools(tester, store);
    await tester.enterText(
      find.byType(TextField),
      'void main() { print("started"); while (true) {} }',
    );
    await tester.tap(find.byTooltip('运行'));
    await tester.pump();
    await _waitFor(
      tester,
      () =>
          find.byTooltip('停止').evaluate().isNotEmpty &&
          find.text('started').evaluate().isNotEmpty,
      reason: 'Infinite program must start and expose Stop',
    );
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    await _performAction(tester, '停止');
    expect(find.text('退出码 130'), findsOneWidget);
    expect(find.byTooltip('停止'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);
  });

  testWidgets(
    'Back confirms unsaved edits and honors cancel, save, and discard',
    (tester) async {
      await _mountTools(tester, store);
      const saved = 'void main() { print("saved-on-back"); }';
      await tester.enterText(find.byType(TextField), saved);
      await tester.pump();

      await tester.tap(find.byType(BackButton));
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, '取消'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        saved,
      );
      expect(await tester.runAsync(mainFile.readAsString), isNot(saved));

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, '取消'));
      await tester.pumpAndSettle();
      expect(find.byType(ContentToolsPage), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, '保存'));
      await _waitFor(
        tester,
        () => find.byType(ContentToolsPage).evaluate().isEmpty,
        reason: 'Saving must complete before leaving the tools route',
      );
      await tester.pumpAndSettle();
      expect(await tester.runAsync(mainFile.readAsString), saved);

      await _openTools(tester);
      await tester.enterText(find.byType(TextField), 'void main() {}');
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, '放弃更改'));
      await tester.pumpAndSettle();
      expect(find.byType(ContentToolsPage), findsNothing);
      expect(await tester.runAsync(mainFile.readAsString), saved);
    },
  );

  testWidgets('moving the selection keeps diagnostics and the saved state', (
    tester,
  ) async {
    await _mountTools(tester, store);
    await _performAction(tester, '语法检查');
    expect(find.text('没有语法错误'), findsOneWidget);

    final controller = tester
        .widget<TextField>(find.byType(TextField))
        .controller!;
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 3);
    await tester.pump();
    expect(find.text('没有语法错误'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) => widget is IconButton && widget.tooltip == '保存',
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(ContentToolsPage), findsNothing);
  });

  testWidgets(
    'cancelled file and project switches keep the current selection',
    (tester) async {
      await tester.runAsync(
        () => File(
          p.join(mainFile.parent.path, 'other.dart'),
        ).writeAsString('void main() {}'),
      );
      await _mountTools(tester, store);
      final originalProject = store.projects.first.path;
      final created = await tester.runAsync(
        () => store.createProject(
          name: 'Other',
          location: workspace.path,
          template: ProjectTemplate.dart,
        ),
      );
      expect(created!.error, isNull);
      await tester.pump();
      const edited = 'void main() { print("unsaved"); }';
      await tester.enterText(find.byType(TextField), edited);

      await _chooseOption(tester, 1, p.join('src', 'other.dart'));
      await tester.tap(find.widgetWithText(TextButton, '取消'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButton<String>>(
              find.byType(DropdownButton<String>).at(1),
            )
            .value,
        mainFile.path,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        edited,
      );

      await _chooseOption(tester, 0, 'Other');
      await tester.tap(find.widgetWithText(TextButton, '取消'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButton<String>>(
              find.byType(DropdownButton<String>).first,
            )
            .value,
        originalProject,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        edited,
      );
      expect(await tester.runAsync(mainFile.readAsString), isNot(edited));
    },
  );

  testWidgets('compact tools with enlarged text have reachable controls', (
    tester,
  ) async {
    await _mountTools(
      tester,
      store,
      size: const Size(320, 640),
      textScale: 1.8,
    );
    for (final tooltip in ['保存', '格式化 Dart', '语法检查', '编译', '运行']) {
      await tester.ensureVisible(find.byTooltip(tooltip));
      final rect = tester.getRect(find.byTooltip(tooltip));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
    }
    await tester.enterText(find.byType(TextField), 'void main( {');
    await _performAction(tester, '语法检查');
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.error_outline), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
