@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_dart/dart_content_repository.dart';
import 'package:qfli_dart/main.dart' show dartProfile;
import 'package:qfli_studio_core/editor/editor_page.dart';
import 'package:qfli_studio_core/i18n/studio_localizations.dart';
import 'package:qfli_studio_core/models/project.dart';
import 'package:qfli_studio_core/pages/community/post_list_page.dart';
import 'package:qfli_studio_core/pages/home_page.dart';
import 'package:qfli_studio_core/pages/local_content_pages.dart';
import 'package:qfli_studio_core/pages/profile_page.dart';
import 'package:qfli_studio_core/pages/settings_page.dart';
import 'package:qfli_studio_core/services/project_templates.dart';
import 'package:qfli_studio_core/services/studio_profile.dart';
import 'package:qfli_studio_core/store/auth_store.dart';
import 'package:qfli_studio_core/store/project_store.dart';
import 'package:qfli_studio_core/store/settings_store.dart';

/// Offline release integrity for the Dart store product.
///
/// The Dart app is an **offline** product: it declares `isOffline: true` and
/// therefore inherits the shared core's `offlineOnly` treatment, which must
/// remove every entry that needs the network. These tests assert that contract
/// against the **real profile** and the **real shell widgets** — not a mock of
/// the gating logic — so a regression in either layer fails here.
///
/// What is asserted (per network entry class):
///   * login / register / account header  -> absent from the profile tab
///   * check-in, points, stats, ICP notice -> absent from the profile tab
///   * cloud project scope + create-cloud  -> absent from the home tab
///   * community tutorial feed             -> replaced by the local lessons
///   * cloud terminal / cloud SQL          -> editor online paths disabled
///   * editor Git / cloud pull popup items -> absent under the Dart profile
///     (the shared core gates these on offlineOnly; asserted via a real
///     EditorPage in the last group)

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StudioProfile? previous;
  late Directory storage;

  // The settings route resolves AppPaths.storageDirectory(), which probes the
  // path_provider platform channel with a 2 s timeout. With no handler the
  // timeout timer stays pending past teardown, so answer the channel directly.
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  late String pathRoot;

  setUp(() {
    previous = StudioProfile.current;
    StudioProfile.current = dartProfile;
    storage = Directory.systemTemp.createTempSync('qfli_dart_offline_test');
    pathRoot = storage.path;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (call) async {
          switch (call.method) {
            case 'getApplicationSupportPath':
            case 'getApplicationDocumentsPath':
            case 'getTemporaryPath':
              return pathRoot;
          }
          return null;
        });
  });

  tearDown(() {
    StudioProfile.current = previous;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);
    if (storage.existsSync()) storage.deleteSync(recursive: true);
  });

  AuthStore authWithStorage() =>
      AuthStore(storageFile: File(p.join(storage.path, 'auth.json')));

  ProjectStore storeWithStorage() =>
      ProjectStore(storageFile: File(p.join(storage.path, 'projects.json')));

  SettingsStore settingsWithStorage() =>
      SettingsStore(storageFile: File(p.join(storage.path, 'settings.json')));

  Future<void> mountShell(WidgetTester tester) async {
    // A 1000px window keeps the wider popup labels from overflowing while the
    // shell uses the rail; the rail destinations are tappable like the bar's.
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        // Chinese locale matches the product UI. Global* delegates come from
        // flutter_localizations (a transitive SDK package), so the Material
        // chrome supports zh_CN.
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: const [
          StudioLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: StudioLocalizations.supportedLocales,
        home: HomePage(
          store: storeWithStorage(),
          auth: authWithStorage(),
          settings: settingsWithStorage(),
        ),
      ),
    );
    // Let the real shell mount Home before checking its named destinations.
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(HomeTab), findsOneWidget);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(
      rail.destinations.map((destination) => (destination.label as Text).data),
      ['主页', '工具', '教程', '我的'],
      reason: 'Home, Tools, Content and Profile are the four destinations',
    );
    expect(rail.selectedIndex, 0);
  }

  // Resolve the destination by name, then tap its control rather than its label.
  Future<void> selectTab(WidgetTester tester, String label) async {
    final host = find.byType(NavigationRail);
    final rail = tester.widget<NavigationRail>(host);
    final index = rail.destinations.indexWhere(
      (destination) => (destination.label as Text).data == label,
    );
    expect(index, greaterThanOrEqualTo(0), reason: 'named destination exists');
    final items = find.descendant(
      of: host,
      matching: find.byWidgetPredicate((widget) => widget is InkResponse),
    );
    expect(items, findsNWidgets(4), reason: 'four destinations are tappable');
    await tester.tap(items.at(index));
    // pumpAndSettle never returns: the home shell keeps a periodic timer alive.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(tester.widget<NavigationRail>(host).selectedIndex, index);
  }

  Future<void> waitForContent(WidgetTester tester, Finder target) async {
    // Drain real asset/isolate and saved-example IO without replacing the
    // profile's repository or waiting for the shell's periodic timer to settle.
    for (var attempt = 0; attempt < 200; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 30));
      if (target.evaluate().isNotEmpty) return;
    }
    fail('The requested local Dart content did not render');
  }

  group('档位合同', () {
    test('Dart 是离线档位，并且 offlineOnly 默认继承 isOffline', () {
      expect(dartProfile.isOffline, isTrue);
      expect(dartProfile.offlineOnly, isTrue);
      expect(dartProfile.id, 'dart');
      expect(dartProfile.productKey, StudioProductCatalog.dartWingKey);
      // 单语言产品不显示首页语言筛选芯片。
      expect(dartProfile.showHomeTabs, isFalse);
    });

    test('运行后端与入口表只声明 Dart 资源', () {
      expect(dartProfile.runner, isNotNull);
      expect(dartProfile.templates, [
        ProjectTemplate.empty,
        ProjectTemplate.dart,
      ]);
      expect(dartProfile.supportedFileExtensions, contains('.dart'));
      // 两个终端表面共用本机 Dart 命令钩子（dart run/--version …）。
      expect(dartProfile.terminalCommandDelegate, isNotNull);
    });
  });

  group('首页入口收窄（真实外壳）', () {
    testWidgets('项目范围不含「云端项目」页签', (tester) async {
      await mountShell(tester);
      // 离线档位只保留 All/History/Favorites 三个范围。
      expect(find.text('云端项目'), findsNothing);
      expect(find.text('全部项目'), findsOneWidget);
      expect(find.text('历史项目'), findsOneWidget);
      expect(find.text('收藏项目'), findsOneWidget);
    });

    testWidgets('「更多」菜单不提供新建云项目', (tester) async {
      await mountShell(tester);
      await tester.tap(find.byIcon(Icons.more_vert));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('New cloud project'), findsNothing);
      expect(find.text('新建云端项目'), findsNothing);
      // 本地项目操作仍可用。
      expect(find.text('移除失效项目'), findsOneWidget);
    });

    testWidgets('教程页签是本地课程而不是社区帖子流', (tester) async {
      await mountShell(tester);
      await selectTab(tester, '教程');
      expect(
        StudioProfile.current?.offlineOnly,
        isTrue,
        reason: 'shell must treat the Dart profile as offline',
      );
      final center = find.byType(TutorialCenterPage);
      expect(
        center,
        findsOneWidget,
        reason: 'offline shell must mount the local tutorial/example center',
      );
      final content = tester.widget<TutorialCenterPage>(center);
      expect(content.language, dartProfile.id);
      expect(content.repository, isA<DartContentRepository>());
      final tutorials = find.byKey(TutorialCenterPage.tutorialSectionKey);
      final examples = find.byKey(TutorialCenterPage.examplesSectionKey);
      expect(tutorials.hitTestable(), findsOneWidget);
      expect(examples.hitTestable(), findsOneWidget);
      final firstLesson = find.ancestor(
        of: find.descendant(
          of: center,
          matching: find.text('第一个 Dart 程序'),
        ),
        matching: find.byType(ListTile),
      );
      final firstExample = find.ancestor(
        of: find.descendant(
          of: center,
          matching: find.text('示例 001：第一个 Dart 程序'),
        ),
        matching: find.byType(ListTile),
      );
      await waitForContent(tester, firstLesson);
      expect(firstLesson.hitTestable(), findsOneWidget);
      expect(firstExample, findsNothing);
      // 社区帖子页在本档位不应被构建。
      expect(find.byType(PostListPage), findsNothing);

      await tester.tap(examples);
      await tester.pump();
      await waitForContent(tester, firstExample);
      expect(center, findsOneWidget);
      expect(firstExample.hitTestable(), findsOneWidget);
      expect(firstLesson, findsNothing);
      expect(find.byType(PostListPage), findsNothing);

      await tester.tap(tutorials);
      await tester.pump();
      await waitForContent(tester, firstLesson);
      expect(firstLesson.hitTestable(), findsOneWidget);
      expect(firstExample, findsNothing);
      expect(find.byType(PostListPage), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('个人页入口收窄（真实外壳）', () {
    Future<void> openProfile(WidgetTester tester) async {
      await mountShell(tester);
      await selectTab(tester, '我的');
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
        3,
      );
      expect(find.byType(ProfileTab), findsOneWidget);
    }

    testWidgets('没有登录入口、签到积分和管理区', (tester) async {
      await openProfile(tester);
      expect(find.text('未登录'), findsNothing, reason: '登录头必须隐藏');
      expect(find.text('签到与积分'), findsNothing);
      expect(find.text('每日任务'), findsNothing);
      expect(find.text('积分兑换'), findsNothing);
      expect(find.text('退出登录'), findsNothing);
      expect(find.text('管理'), findsNothing);
      // 合规备案页脚指向外部站点，离线档位不显示。
      expect(find.textContaining('备案'), findsNothing);
    });

    testWidgets('纯本地分区仍可达', (tester) async {
      await openProfile(tester);
      expect(find.text('数据管理'), findsOneWidget);
      expect(find.text('本机记录'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
      expect(find.textContaining('关于 '), findsOneWidget);
    });

    testWidgets('设置页在离线档位不显示 AI 助手入口', (tester) async {
      await openProfile(tester);
      await tester.tap(find.text('设置'));
      // Pump past AppPaths' 2 s path-provider timeout so its guard timer fires
      // before teardown; otherwise the pending timer fails the test.
      for (var i = 0; i < 35; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(
        tester.widget<SettingsPage>(find.byType(SettingsPage)).showAi,
        isFalse,
      );
      expect(find.text('设置'), findsWidgets);
      // 离线产品的设置页不暴露用户自配的外部 AI 网络端点；编辑器入口与
      // 个人页入口都传入 showAi=false。
      expect(find.text('AI 助手'), findsNothing);
      expect(find.text('个人 AI 接口'), findsNothing);
      // 本地设置分区仍然可用。
      expect(find.text('外观与体验'), findsOneWidget);
      expect(find.text('编辑器'), findsOneWidget);
    });
  });

  group('功能页 / 终端入口', () {
    testWidgets('功能页只提供本地通用工具与沙盒终端', (tester) async {
      await mountShell(tester);
      await selectTab(tester, '工具');
      // 通用本地工具存在（不外发数据）。
      expect(find.text('JSON 格式化'), findsOneWidget);
      // Dart 档位注入了自己的本地工具页构建器。
      expect(StudioProfile.current?.toolsPageBuilder, isNotNull);
      // 终端入口是本地沙盒终端，不是服务器在线终端。
      expect(find.text('终端'), findsOneWidget);
      expect(find.textContaining('在线终端'), findsNothing);
    });
  });

  group('编辑器入口收窄（真实 EditorPage）', () {
    testWidgets('Dart 档位下「更多」菜单没有 Git / 云端拉取', (tester) async {
      // 直接挂载真实 EditorPage，证明 Dart 档位（offlineOnly=true）下
      // 共享内核的 Git / 从云端拉取 入口不可达。内核已按 offlineOnly 门控；
      // 这里从 Dart 侧锁定该行为，防止回归。
      final project = Directory.systemTemp.createTempSync('qfli_dart_editor_');
      addTearDown(() {
        if (project.existsSync()) project.deleteSync(recursive: true);
      });
      final mainFile = File(p.join(project.path, 'main.dart'))
        ..writeAsStringSync('void main() {}\n');
      final model = Project.create(name: 'gate', path: project.path);
      final auth = authWithStorage();
      final store = storeWithStorage();
      final settings = settingsWithStorage();
      addTearDown(() {
        auth.dispose();
        store.dispose();
        settings.dispose();
      });

      tester.view.physicalSize = const Size(1100, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: EditorPage(
            project: model,
            auth: auth,
            store: store,
            settings: settings,
            initialOpenPath: mainFile.path,
          ),
        ),
      );
      for (var i = 0; i < 120; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        if (find.byIcon(Icons.more_vert).evaluate().isNotEmpty) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }
      await tester.tap(find.byIcon(Icons.more_vert).first);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Git'), findsNothing);
      expect(find.text('从云端拉取'), findsNothing);
      // The fitting layout keeps Settings in the quick bar, not the popup.
      // Dismiss the popup before proving the real local Settings route.
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final quickBar = find.byKey(const ValueKey('editor-quick-bar'));
      expect(quickBar, findsOneWidget);
      for (final tooltip in ['Git', '从云端拉取', '在线终端（服务器执行）', 'AI 助手']) {
        expect(
          find.descendant(of: quickBar, matching: find.byTooltip(tooltip)),
          findsNothing,
        );
      }
      final settingsAction = find.descendant(
        of: quickBar,
        matching: find.byTooltip('设置'),
      );
      expect(settingsAction, findsOneWidget);
      expect(
        find.descendant(
          of: settingsAction,
          matching: find.byIcon(Icons.settings_outlined),
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(settingsAction);
      expect(settingsAction.hitTestable(), findsOneWidget);
      await tester.tap(settingsAction);
      for (var i = 0; i < 35; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(
        tester.widget<SettingsPage>(find.byType(SettingsPage)).showAi,
        isFalse,
      );
      // 本地入口仍在。
      expect(find.text('设置'), findsWidgets);
      expect(find.text('AI 助手'), findsNothing);
      expect(find.text('个人 AI 接口'), findsNothing);
      expect(find.text('外观与体验'), findsOneWidget);
      expect(find.text('编辑器'), findsOneWidget);
    });
  });
}
