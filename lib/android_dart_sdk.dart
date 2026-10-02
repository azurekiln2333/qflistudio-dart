import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class AndroidDartSdkLayout {
  const AndroidDartSdkLayout({
    required this.home,
    required this.vm,
    required this.libraryDirectory,
  });

  final String home;
  final String vm;
  final String libraryDirectory;

  factory AndroidDartSdkLayout.fromMap(Map<Object?, Object?> value) {
    String path(String key) {
      final result = value[key];
      if (result is! String || result.isEmpty || !p.isAbsolute(result)) {
        throw FormatException('Invalid Android Dart SDK path: $key');
      }
      return result;
    }

    return AndroidDartSdkLayout(
      home: path('home'),
      vm: path('vm'),
      libraryDirectory: path('libraryDirectory'),
    );
  }

  Map<String, String> get environment => {
    'DART_SDK': home,
    'QFLI_DART_SDK': home,
    'TMPDIR': p.join(home, 'tmp'),
    'LD_LIBRARY_PATH': [
      libraryDirectory,
      if (Platform.environment['LD_LIBRARY_PATH'] case final String existing)
        existing,
    ].join(':'),
  };
}

abstract final class AndroidDartSdk {
  static const _channel = MethodChannel('qfli_dartwing/sdk');
  static AndroidDartSdkLayout? _current;
  static Future<AndroidDartSdkLayout>? _preparing;

  static Future<AndroidDartSdkLayout> prepare() {
    if (_current case final AndroidDartSdkLayout layout) {
      return Future.value(layout);
    }
    return _preparing ??= _prepare().whenComplete(() => _preparing = null);
  }

  static Future<AndroidDartSdkLayout> _prepare() async {
    final value = await _channel.invokeMapMethod<Object?, Object?>('prepare');
    if (value == null) {
      throw const FormatException('Android Dart SDK is missing');
    }
    final layout = AndroidDartSdkLayout.fromMap(value);
    final process = await Process.start(
      layout.vm,
      ['--version'],
      environment: layout.environment,
      workingDirectory: layout.home,
    );
    final output = process.stdout.transform(utf8.decoder).join();
    final errors = process.stderr.transform(utf8.decoder).join();
    try {
      final code = await process.exitCode.timeout(const Duration(seconds: 30));
      final text = '${await output}\n${await errors}';
      if (code != 0 ||
          !RegExp(r'Dart SDK version: \d+.* on "android_').hasMatch(text)) {
        throw StateError('Android Dart VM probe failed: ${text.trim()}');
      }
    } catch (_) {
      process.kill(ProcessSignal.sigkill);
      await process.exitCode;
      await output;
      await errors;
      rethrow;
    }
    return _current = layout;
  }
}
