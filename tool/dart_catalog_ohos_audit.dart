import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_dart/dart_catalog_audit.dart';
import 'package:qfli_studio_core/services/app_paths.dart';

/// Alternate installed audit entry, never the normal product home.
/// Restore lib/main.dart after the exclusive target acceptance window.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: Text('Dart 课程运行验证中')),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) => _audit());
}

Future<void> _audit() async {
  try {
    final storage = await AppPaths.storageDirectory();
    if (storage == null) throw StateError('No writable app storage');
    final reportFile = File(p.join(storage, 'qfli-dart-catalog-audit.json'));
    final report = await auditBundledDartCatalog(
      workspace: Directory(p.join(storage, 'qfli-dart-catalog-projects')),
      reportFile: reportFile,
      expectedTopics: const int.fromEnvironment(
        'QFLI_DART_EXPECTED_TOPICS',
        defaultValue: 120,
      ),
      onProgress: (message) => debugPrint('QFLI_DART_CATALOG_ITEM $message'),
    );
    debugPrint(
      'QFLI_DART_CATALOG_AUDIT ${jsonEncode({'ok': report['ok'], 'deviceGatePassed': report['deviceGatePassed'], 'checked': report['checked'], 'passed': report['passed'], 'error': report['error'], 'report': reportFile.path, 'operatingSystem': Platform.operatingSystem})}',
    );
  } on Object catch (error, stack) {
    debugPrint(
      'QFLI_DART_CATALOG_AUDIT ${jsonEncode({'ok': false, 'deviceGatePassed': false, 'error': error.toString(), 'stack': stack.toString()})}',
    );
  }
}
