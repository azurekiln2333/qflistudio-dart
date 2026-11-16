import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qfli_dart/main.dart' as app;
import 'package:qfli_studio_core/app.dart';
import 'package:qfli_studio_core/pages/home_page.dart';
import 'package:qfli_studio_core/services/app_paths.dart';
import 'package:qfli_studio_core/services/studio_profile.dart';
import 'package:qfli_studio_core/splash_screen.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = binding.defaultBinaryMessenger;
  const channel = MethodChannel('qflistudio/platform');
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  final ohosPlatforms = TargetPlatform.values
      .where((platform) => platform.name == 'ohos')
      .toSet();
  late Directory directory;
  StudioProfile? originalProfile;

  void mockPaths() {
    messenger.setMockMethodCallHandler(pathChannel, (call) async {
      switch (call.method) {
        case 'getApplicationSupportPath':
        case 'getApplicationDocumentsPath':
        case 'getTemporaryPath':
          return directory.path;
      }
      return null;
    });
  }

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('dartwing_startup_');
    mockPaths();
    await AppPaths.storageDirectory();
  });

  tearDownAll(() async {
    messenger.setMockMethodCallHandler(pathChannel, null);
    await directory.delete(recursive: true);
  });

  setUp(() {
    binding.resetFirstFrameSent();
    originalProfile = StudioProfile.current;
    mockPaths();
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(pathChannel, null);
    StudioProfile.current = originalProfile;
  });

  Future<void> waitForBootstrap(WidgetTester tester) async {
    final root = tester.widget<QfliApp>(find.byType(QfliApp));
    for (var attempt = 0; !root.ready!.value && attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(root.ready!.value, isTrue);
  }

  Future<void> unmountApp(WidgetTester tester) async {
    final root = tester.widget<QfliApp>(find.byType(QfliApp));
    await tester.pumpWidget(const SizedBox.shrink());
    root.store.dispose();
    root.auth.dispose();
    root.settings!.dispose();
    (root.ready! as ValueNotifier<bool>).dispose();
  }

  for (final bridge in ['available', 'missing', 'rejected']) {
    testWidgets(
      'OHOS keeps native splash until home layout with $bridge progress bridge',
      (tester) async {
        final progress = <double>[];
        if (bridge != 'missing') {
          messenger.setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'startupProgress');
            if (bridge == 'rejected') {
              throw PlatformException(code: 'INVALID_PROGRESS');
            }
            progress.add((call.arguments as Map)['progress'] as double);
            return null;
          });
        }

        await app.main();
        expect(binding.sendFramesToEngine, isFalse);
        await tester.pump();
        // The Flutter loading widget is laid out but never sent to the engine.
        expect(find.byType(SplashScreen), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 160));
        await waitForBootstrap(tester);
        await tester.pump();
        expect(find.byType(HomePage), findsOneWidget);
        expect(binding.sendFramesToEngine, isFalse);
        if (bridge == 'available') {
          expect(progress.first, 0.05);
          expect(progress.last, 1.0);
          expect(progress, orderedEquals([...progress]..sort()));
          expect(progress, everyElement(inInclusiveRange(0.0, 1.0)));
        }

        await tester.pump(const Duration(milliseconds: 1100));
        await tester.pump();
        expect(binding.sendFramesToEngine, isTrue);
        expect(tester.takeException(), isNull);
        await unmountApp(tester);
      },
      variant: TargetPlatformVariant(
        ohosPlatforms.isEmpty ? {TargetPlatform.android} : ohosPlatforms,
      ),
      skip: ohosPlatforms.isEmpty,
    );
  }

  testWidgets(
    'Android displays its Flutter loading screen immediately',
    (tester) async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        fail('Android should not report progress to the OHOS splash');
      });

      await app.main();
      expect(binding.sendFramesToEngine, isTrue);
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);
      await waitForBootstrap(tester);
      await tester.pump();
      expect(find.byType(HomePage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await unmountApp(tester);
    },
    variant: TargetPlatformVariant({TargetPlatform.android}),
  );
}
