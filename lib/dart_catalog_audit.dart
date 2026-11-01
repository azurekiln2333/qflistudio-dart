import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_studio_core/tools/offline_tools.dart';

import 'dart_project_sources.dart';
import 'portable_dart_runtime.dart';

/// A program actually displayed by one of this app's two bundled catalogs.
class DartCatalogProgram {
  const DartCatalogProgram({
    required this.id,
    required this.location,
    required this.source,
    required this.expected,
  });

  final String id;
  final String location;
  final String source;
  final String expected;
}

/// Strict inventory: a truncated or malformed catalog cannot lower the gate.
/// This validates the authoring schema before execution, independently of the
/// permissive UI parser, and never silently drops an unknown entry.
List<DartCatalogProgram> inventoryDartCatalog({
  required String tutorials,
  required String examples,
  required int expectedTopics,
}) {
  if (expectedTopics <= 0) throw ArgumentError.value(expectedTopics);
  Map<String, dynamic> object(Object? value, String location) {
    if (value is! Map<String, dynamic>) {
      throw FormatException('$location must be an object');
    }
    return value;
  }

  String string(
    Map<String, dynamic> value,
    String key,
    String location, {
    bool allowEmpty = false,
  }) {
    final result = value[key];
    if (result is! String || (!allowEmpty && result.trim().isEmpty)) {
      throw FormatException('$location.$key must be a string');
    }
    return result;
  }

  List<dynamic> entries(String source, String kind) {
    final document = object(jsonDecode(source), kind);
    final values = document['entries'];
    if (document['schemaVersion'] != 1 ||
        document['kind'] != kind ||
        values is! List ||
        values.length != expectedTopics) {
      throw FormatException(
        '$kind must contain $expectedTopics schema1 entries',
      );
    }
    return values;
  }

  final programs = <DartCatalogProgram>[];
  final tutorialIds = <String>{};
  final exampleIds = <String>{};
  final pairedIds = <String>{};
  for (final raw in entries(tutorials, 'tutorials')) {
    final entry = object(raw, 'tutorial');
    final id = string(entry, 'id', 'tutorial');
    if (!tutorialIds.add(id) ||
        entry['language'] != 'dart' ||
        entry['type'] != 'dart') {
      throw FormatException('Duplicate or non-Dart tutorial: $id');
    }
    final lessons = entry['lessons'];
    if (lessons is! List || lessons.length != 1) {
      throw FormatException('$id must contain exactly one complete lesson');
    }
    final lesson = object(lessons.single, '$id.lessons[0]');
    if (lesson['id'] != '$id-lesson') {
      throw FormatException('Mismatched displayed lesson id: $id');
    }
    programs.add(
      DartCatalogProgram(
        id: id,
        location: 'tutorials/$id/lessons/0',
        source: string(lesson, 'code', id),
        expected: string(lesson, 'output', id, allowEmpty: true),
      ),
    );
  }
  for (final raw in entries(examples, 'examples')) {
    final entry = object(raw, 'example');
    final id = string(entry, 'id', 'example');
    final pair = string(entry, 'sourceLessonId', id);
    if (!exampleIds.add(id) ||
        !pairedIds.add(pair) ||
        !tutorialIds.contains(pair) ||
        id != pair.replaceFirst('dart-lesson-', 'dart-example-') ||
        entry['language'] != 'dart' ||
        entry['type'] != 'dart') {
      throw FormatException('Duplicate, foreign or unpaired example: $id');
    }
    programs.add(
      DartCatalogProgram(
        id: id,
        location: 'examples/$id',
        source: string(entry, 'code', id),
        expected: string(entry, 'expectedOutput', id, allowEmpty: true),
      ),
    );
  }
  for (var number = 1; number <= expectedTopics; number++) {
    final suffix = number.toString().padLeft(3, '0');
    if (!tutorialIds.contains('dart-lesson-$suffix') ||
        !exampleIds.contains('dart-example-$suffix')) {
      throw FormatException('Missing topic identity $suffix');
    }
  }
  return List.unmodifiable(programs);
}

/// Audit exact packaged bytes through the production source loader and runtime.
/// The caller supplies an independent denominator, never derived from assets.
Future<Map<String, Object?>> auditBundledDartCatalog({
  required Directory workspace,
  required File reportFile,
  required int expectedTopics,
  AssetBundle? bundle,
  Duration timeout = const Duration(seconds: 15),
  void Function(String message)? onProgress,
}) async {
  final assetBundle = bundle ?? rootBundle;
  final results = <Map<String, Object?>>[];
  final assets = <String, Object?>{};
  final report = <String, Object?>{
    'schemaVersion': 1,
    'startedAt': DateTime.now().toUtc().toIso8601String(),
    'ok': false,
    'deviceGatePassed': false,
    'executionComplete': false,
    'expectedTopics': expectedTopics,
    'expectedPrograms': expectedTopics * 2,
    'engine': 'tom_d4rt 1.229.0+qfli.1; production loader/policy/supervisor',
    'operatingSystem': Platform.operatingSystem,
    'operatingSystemVersion': Platform.operatingSystemVersion,
    'dartVersion': Platform.version,
    'assets': assets,
    'results': results,
  };
  Future<void> persist() async {
    await reportFile.parent.create(recursive: true);
    final temporary = File('${reportFile.path}.pending');
    await temporary.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
      flush: true,
    );
    await temporary.rename(reportFile.path);
  }

  await persist();
  try {
    final sources = <String, String>{};
    for (final kind in ['tutorials', 'examples']) {
      final key = 'assets/content/dart_$kind.json';
      final data = await assetBundle.load(key);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      sources[kind] = utf8.decode(bytes);
      assets[kind] = {
        'key': key,
        'bytes': bytes.length,
        'sha256': OfflineDigest.sha256Bytes(
          bytes,
        ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
      };
    }
    final programs = inventoryDartCatalog(
      tutorials: sources['tutorials']!,
      examples: sources['examples']!,
      expectedTopics: expectedTopics,
    );
    for (final program in programs) {
      results.add({
        'id': program.id,
        'location': program.location,
        'sourceSha256': OfflineDigest.sha256(program.source),
        'expected': program.expected,
        'status': 'not_run',
      });
    }
    await workspace.create(recursive: true);
    await persist();
    var passed = 0;
    for (final (index, program) in programs.indexed) {
      final observation = await _runProgram(program, workspace, timeout);
      results[index].addAll(observation);
      if (observation['status'] == 'passed') passed++;
      report['checked'] = index + 1;
      report['passed'] = passed;
      report['failed'] = index + 1 - passed;
      await persist();
      onProgress?.call(
        '[${index + 1}/${programs.length}] ${program.id}: ${observation['status']}',
      );
      if (observation['status'] == 'launch_timeout') break;
    }
    final complete = results.every((row) => row['status'] != 'not_run');
    final ok = complete && passed == expectedTopics * 2;
    report['executionComplete'] = complete;
    report['ok'] = ok;
    report['deviceGatePassed'] = ok && Platform.operatingSystem == 'ohos';
  } on Object catch (error, stack) {
    report['error'] = error.toString();
    report['stack'] = stack.toString();
  }
  report['finishedAt'] = DateTime.now().toUtc().toIso8601String();
  await persist();
  return report;
}

Future<Map<String, Object?>> _runProgram(
  DartCatalogProgram program,
  Directory workspace,
  Duration timeout,
) async {
  final project = await workspace.createTemp('dart-audit-');
  PortableDartRun? run;
  var pendingLaunch = false;
  final watch = Stopwatch()..start();
  final observation = <String, Object?>{};
  try {
    final entry = File(p.join(project.path, 'main.dart'));
    await entry.writeAsString(program.source, flush: true);
    final loaded = await DartProjectSources.load(
      projectPath: project.path,
      entryFile: entry.path,
    );
    final launch = startPortableDart(
      packages: loaded.packages,
      entryUri: loaded.entryUri,
      projectPath: project.path,
    );
    run = await launch.timeout(
      timeout,
      onTimeout: () {
        pendingLaunch = true;
        unawaited(
          launch
              .then((late) async {
                await late.cancel();
                await project.delete(recursive: true);
              })
              .catchError((Object error) {
                // This late cleanup cannot turn the already-recorded timeout into pass.
                observation['lateCleanupError'] = error.toString();
              }),
        );
        throw TimeoutException('Portable launch exceeded $timeout');
      },
    );
    final output = run.stdout.toList();
    final errors = run.stderr.toList();
    try {
      observation['exitCode'] = await run.exitCode.timeout(timeout);
    } on TimeoutException catch (error) {
      observation['error'] = error.toString();
      observation['timedOut'] = true;
    } finally {
      await run.cancel();
    }
    final actual = (await output).join('\n');
    final stderr = (await errors).join('\n');
    observation['actual'] = actual;
    observation['stderr'] = stderr;
    observation['status'] =
        observation['exitCode'] == 0 &&
            stderr.isEmpty &&
            _normalize(actual) == _normalize(program.expected)
        ? 'passed'
        : 'failed';
  } on Object catch (error, stack) {
    observation['status'] = pendingLaunch ? 'launch_timeout' : 'failed';
    observation['error'] = error.toString();
    observation['stack'] = stack.toString();
  } finally {
    if (!pendingLaunch) {
      await run?.cancel();
      try {
        await project.delete(recursive: true);
      } on FileSystemException catch (error) {
        observation['cleanupError'] = error.toString();
        observation['status'] = 'failed';
      }
    }
    observation['elapsedMilliseconds'] = watch.elapsedMilliseconds;
  }
  return observation;
}

String _normalize(String value) =>
    value.replaceAll('\r\n', '\n').replaceFirst(RegExp(r'\n+$'), '');
