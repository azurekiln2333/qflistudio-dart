import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:qfli_studio_core/app.dart';
import 'package:qfli_studio_core/services/project_templates.dart';
import 'package:qfli_studio_core/services/studio_profile.dart';
import 'package:qfli_studio_core/splash_screen.dart';
import 'package:qfli_studio_core/store/auth_store.dart';
import 'package:qfli_studio_core/store/project_store.dart';
import 'package:qfli_studio_core/store/settings_store.dart';

import 'dart_content_repository.dart';
import 'dart_code_analyzer.dart';
import 'dart_runner.dart';
import 'dart_tools_page.dart';
import 'native_dart_toolchain.dart';

/// 本 App 的产品名。窗口标题、任务切换器和应用内顶栏都读它。
const String _appTitle = StudioProductCatalog.dartWing;

/// Dart 版档位：同一套内核 UI，收窄成只服务 Dart。
///
/// 单独提出来是为了让测试能直接断言档位，而不必为了一个常量去跑 `main()`。
final StudioProfile dartProfile = StudioProfile(
  id: 'dart',
  appTitle: _appTitle,
  templates: [ProjectTemplate.empty, ProjectTemplate.dart],
  runner: DartProgramRunner(),
  toolsPageBuilder: DartToolsPage.forStore,
  toolsTabBuilder: DartToolsPage.forTab,
  codeAnalyzer: const DartCodeAnalyzer(),
  contentRepositoryFactory: DartContentRepository.new,
  isOffline: true,
  // 独立终端与编辑器终端共用同一命令引擎；注入 Dart 档位的命令钩子后，
  // 两个终端表面都能执行 `dart run …` / `dart --version` 等本机命令。
  terminalCommandDelegate: dartTerminalDelegate,
  productKey: StudioProductCatalog.dartWingKey,
  showHomeTabs: false,
  runtimeKind: NativeDartToolchain.supported
      ? 'official-dart-sdk'
      : 'offline-dart-interpreter',
  runtimeStatus: Platform.isAndroid
      ? 'available'
      : NativeDartToolchain.supported
      ? 'requires-sdk'
      : 'unavailable',
  supportedFileExtensions: [
    '.dart',
    if (NativeDartToolchain.supported) '.dill',
  ],
  // main.dart 排在默认入口表前面，保证本版一定先命中它。
  entryFileNames: [
    'main.dart',
    'src/main.dart',
    if (NativeDartToolchain.supported) ...[
      'main.dill',
      'src/main.dill',
      'build/main.dill',
      'build/src/main.dill',
    ],
  ],
);

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  final nativeStartup = !kIsWeb && defaultTargetPlatform == TargetPlatform.ohos;
  if (nativeStartup) binding.deferFirstFrame();

  // 在 runApp 之前定档。
  StudioProfile.current = dartProfile;

  final store = ProjectStore();
  final auth = AuthStore();
  final settings = SettingsStore();
  final ready = ValueNotifier<bool>(false);
  runApp(QfliApp(store: store, auth: auth, settings: settings, ready: ready));

  const platformChannel = MethodChannel('qflistudio/platform');
  Future<void> reportProgress(double progress) async {
    try {
      await platformChannel.invokeMethod<void>('startupProgress', {
        'progress': progress,
      });
    } on PlatformException catch (error) {
      debugPrint('Startup progress unavailable: ${error.code}');
    } on MissingPluginException {
      // A missing progress bridge must not prevent the first frame.
    }
  }

  Future<void> completeStartup() async {
    try {
      final minimumDisplay = nativeStartup
          ? Future<void>.delayed(const Duration(milliseconds: 1100))
          : Future<void>.value();
      if (nativeStartup) {
        // Match JVMX: let the native splash subscribe before reporting progress.
        await Future<void>.delayed(const Duration(milliseconds: 160));
        unawaited(reportProgress(0.05));
      }
      await AppBootstrap.run(
        store: store,
        auth: auth,
        settings: settings,
        ready: ready,
        onProgress: nativeStartup
            ? (progress) => unawaited(reportProgress(0.05 + progress * 0.95))
            : null,
      );
      await Future.wait([
        minimumDisplay,
        if (nativeStartup)
          Future<void>.delayed(const Duration(milliseconds: 320)),
      ]);
      // FlutterPage removes the native splash on the first engine frame.
      // Keep that frame deferred until the home (or restore gate) is laid out.
      if (nativeStartup) await binding.endOfFrame;
    } finally {
      if (nativeStartup) binding.allowFirstFrame();
    }
  }

  binding.addPostFrameCallback((_) {
    unawaited(completeStartup());
  });
}
