@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_dart/dart_content_repository.dart';
import 'package:qfli_dart/dart_runner.dart';
import 'package:qfli_studio_core/models/project.dart';
import 'package:qfli_studio_core/services/code_import_service.dart';
import 'package:qfli_studio_core/models/tutorial.dart';

import '../curriculum/dart_curriculum.dart';

/// Integration gate: catalog -> detail example -> import into a real project
/// -> editor Run path ([DartProgramRunner]).
///
/// There is no inline "Run" on the Dart detail page (CodeSnippet's inline run
/// is Java-only), so this is the exact path a user takes: open the catalog,
/// import the example into a project, open it in the editor, press Run.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory projectDir;

  setUp(() async {
    projectDir = await Directory.systemTemp.createTemp('qfli_dart_import_');
  });

  tearDown(() async {
    if (projectDir.existsSync()) {
      await projectDir.delete(recursive: true);
    }
  });

  test('a bundled lesson imports into a project and runs on the real engine',
      () async {
    final repository = DartContentRepository();
    final catalog = await repository.load();
    final examples = catalog.examples;

    // Use lesson 002 so lesson 001's Hello-World stays the unique intro.
    final example = examples.firstWhere(
      (e) => e.sourceLessonId == 'dart-lesson-002',
    );

    final project = Project(
      id: 'local-test',
      name: 'Dart 课程导入测试',
      path: projectDir.path,
      createdAt: DateTime.now(),
      lastOpenedAt: DateTime.now(),
      language: 'dart',
      type: 'dart',
    );

    final domainExample = ExampleCode(
      id: example.id,
      type: example.type,
      title: example.title,
      summary: example.summary,
      code: example.code,
      output: example.expectedOutput,
      sourceLessonId: example.sourceLessonId,
    );

    final result = await CodeImportService.importIntoProject(
      project: project,
      example: domainExample,
      fileName: 'main.dart',
    );

    final imported = File(result.path);
    expect(imported.existsSync(), isTrue, reason: result.path);
    expect(await imported.readAsString(), example.code);

    final run = await const DartProgramRunner().run(
      projectPath: projectDir.path,
      entryFile: result.path,
    );
    expect(run, isNotNull);
    final stdoutLines = await run!.stdout.toList();
    final stderrLines = await run.stderr.toList();
    expect(await run.exitCode, 0, reason: stderrLines.join(' | '));
    expect(
      '${stdoutLines.join('\n')}\n'.trimRight(),
      example.expectedOutput.trimRight(),
    );
  });

  test('every catalog example writes its exact source into a project', () async {
    final catalog = await DartContentRepository().load();
    var checked = 0;
    for (final example in catalog.examples) {
      final domainExample = ExampleCode(
        id: example.id,
        type: example.type,
        title: example.title,
        summary: example.summary,
        code: example.code,
        output: example.expectedOutput,
        sourceLessonId: example.sourceLessonId,
      );
      final project = Project(
        id: 'p-$checked',
        name: 'p$checked',
        path: p.join(projectDir.path, 'p$checked'),
        createdAt: DateTime.now(),
        lastOpenedAt: DateTime.now(),
        language: 'dart',
        type: 'dart',
      );
      Directory(project.path).createSync(recursive: true);
      final result = await CodeImportService.importIntoProject(
        project: project,
        example: domainExample,
        fileName: 'main.dart',
      );
      expect(await File(result.path).readAsString(), example.code, reason: example.id);
      checked++;
    }
    expect(checked, 120);
  });

  test('authored curriculum count stays 120', () {
    expect(dartCurriculum, hasLength(120));
  });
}
