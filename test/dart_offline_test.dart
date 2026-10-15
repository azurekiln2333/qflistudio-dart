@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_dart/main.dart' show dartProfile;
import 'package:qfli_studio_core/editor/editor_page.dart';
import 'package:qfli_studio_core/i18n/studio_localizations.dart';
import 'package:qfli_studio_core/models/project.dart';
import 'package:qfli_studio_core/pages/community/post_list_page.dart';
import 'package:qfli_studio_core/pages/home_page.dart';
import 'package:qfli_studio_core/pages/local_content_pages.dart';
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
    // Let the shell build its first frame; the retained page view mounts the
    // home tab. Content-tab loads are left pending on purpose — the assertions
    // are about which *entries* exist, not their loaded content.
    await tester.pump(const Duration(milliseconds: 50));
  }

  // The navigation labels are not the hit targets; tap the destination control
  // (the nth tappable region of the rail/bar), matching the shell's own tests.
  Future<void> selectTab(WidgetTester tester, int index) async {
    final host = find.byType(NavigationRail).evaluate().isNotEmpty
        ? find.byType(NavigationRail)
        : find.byType(NavigationBar);
    final items = find.descendant(
      of: host,
      matching: find.byWidgetPredicate((widget) => widget is InkResponse),
    );
    expect(items, findsNWidgets(5), reason: 'five destinations are tappable');
    await tester.tap(items.at(index));
    // pumpAndSettle never returns: the home shell keeps a periodic timer alive.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
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
      // The PageView builds tabs lazily, so navigate to the lesson tab first.
      await selectTab(tester, 2);
      expect(
        StudioProfile.current?.offlineOnly,
        isTrue,
        reason: 'shell must treat the Dart profile as offline',
      );
      expect(
        find.byType(LocalTutorialsTab),
        findsOneWidget,
        reason: 'offline shell must mount the local lesson tab',
      );
      // 社区帖子页在本档位不应被构建。
      expect(find.byType(PostListPage), findsNothing);
    });
  });

  group('个人页入口收窄（真实外壳）', () {
    Future<void> openProfile(WidgetTester tester) async {
      await mountShell(tester);
      await selectTab(tester, 4);
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
      await selectTab(tester, 1);
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
      // 本地入口仍在。
      expect(find.text('设置'), findsWidgets);
    });
  });
}
