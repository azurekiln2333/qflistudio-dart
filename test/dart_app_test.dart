import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_dart/main.dart' show dartProfile;
import 'package:qfli_studio_core/services/project_templates.dart';
import 'package:qfli_studio_core/services/runner_service.dart';
import 'package:qfli_studio_core/services/studio_profile.dart';

/// Dart 版 App 的接线测试。
///
/// 覆盖的正是「一个语言一个 App」的全部接缝：内核怎么知道该显示哪个模板、
/// 该跑哪个入口文件、以及运行后端有没有正确接管/交回。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory project;
  late StudioProfile? previousProfile;

  setUp(() {
    previousProfile = StudioProfile.current;
    StudioProfile.current = dartProfile;
    project = Directory.systemTemp.createTempSync('qfli_dart_app_test');
  });

  tearDown(() {
    StudioProfile.current = previousProfile;
    if (project.existsSync()) project.deleteSync(recursive: true);
  });

  void write(String relative, String content) {
    final file = File(p.join(project.path, relative));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  group('档位收窄', () {
    test('新建项目只放行「空项目」和 Dart', () {
      expect(dartProfile.filterTemplates(ProjectTemplate.values), [
        ProjectTemplate.empty,
        ProjectTemplate.dart,
      ]);
    });

    test('默认模板是 Dart 而不是空项目', () {
      expect(dartProfile.defaultTemplate, ProjectTemplate.dart);
    });

    test('语言筛选芯片只剩 Dart', () {
      // 首页传给档位的候选本来就不含「空项目」——它不是一门语言。
      const all = ['Web', 'Python', 'Java', 'Dart'];
      expect(dartProfile.filterLanguages(all), ['Dart']);
    });

    test('产品名使用 QFLIStudio+', () {
      expect(dartProfile.appTitle, 'QFLIDartWing');
    });
  });

  group('入口文件识别', () {
    test('优先命中 main.dart', () {
      write('main.dart', '// .dart');
      write('other.txt', 'x');
      expect(
        RunnerService.findEntry(project.path),
        p.join(project.path, 'main.dart'),
      );
    });

    test('入口表覆盖了模板自带的入口文件', () {
      // 这是「一个语言一个 App」最容易出错的地方：模板统一把源码放在 src/ 下，
      // 而入口表要是只写了根目录的文件名，新建项目后点运行就会找不到入口。
      final mainFile = ProjectTemplate.dart.mainFile;
      expect(mainFile, isNotNull, reason: '模板里没有文件');
      expect(dartProfile.entryFileNames, contains(mainFile));
    });

    test('模板把源码放在 src/ 下时也能找到入口', () {
      final mainFile = ProjectTemplate.dart.mainFile!;
      write(mainFile, '// 示例');
      expect(
        RunnerService.findEntry(project.path),
        p.join(project.path, mainFile),
      );
    });
  });

  group('运行后端', () {
    test('Dart 模板编译并执行，输出到终端', () async {
      write('src/main.dart', ProjectTemplate.dart.files.first.content);
      final result = await dartProfile.runner!.run(
        projectPath: project.path,
        entryFile: p.join(project.path, 'src/main.dart'),
      );
      expect(result, isNotNull, reason: '运行后端没有接管本语言文件');
      expect(await result!.stdout.toList(), ['Hello, QFLIStudio+!']);
      expect(await result.stderr.toList(), isEmpty);
      expect(await result.exitCode, 0);
      expect(result.title, isNot(contains('开发中')));
    });

    test('同目录 import 可以运行多个源码文件', () async {
      write(
        'src/main.dart',
        "import 'helper.dart'; void main() { print(answer()); }",
      );
      write('src/helper.dart', 'int answer() => 42;');
      final result = (await dartProfile.runner!.run(
        projectPath: project.path,
        entryFile: p.join(project.path, 'src/main.dart'),
      ))!;
      expect(await result.stdout.toList(), ['42']);
      expect(await result.exitCode, 0);
    });

    test('package import 使用项目 pubspec 名称', () async {
      write('pubspec.yaml', 'name: sample_app\n');
      write('lib/message.dart', "String message() => 'from package';");
      write(
        'src/main.dart',
        "import 'package:sample_app/message.dart'; void main() { print(message()); }",
      );
      final result = (await dartProfile.runner!.run(
        projectPath: project.path,
        entryFile: p.join(project.path, 'src/main.dart'),
      ))!;
      expect(await result.stdout.toList(), ['from package']);
      expect(await result.exitCode, 0);
    });

    test('根目录与 lib 同名入口不会混淆', () async {
      write('pubspec.yaml', 'name: sample_app\n');
      write('main.dart', "void main() { print('root'); }");
      write('lib/main.dart', "void main() { print('library'); }");
      final result = (await dartProfile.runner!.run(
        projectPath: project.path,
        entryFile: p.join(project.path, 'lib/main.dart'),
      ))!;
      expect(await result.stdout.toList(), ['library']);
      expect(await result.exitCode, 0);
    });

    test('main 接收命令行参数列表', () async {
      write(
        'main.dart',
        'void main(List<String> args) { print(args.length); }',
      );
      final result = (await dartProfile.runner!.run(
        projectPath: project.path,
        entryFile: p.join(project.path, 'main.dart'),
      ))!;
      final stderr = await result.stderr.toList();
      expect(await result.stdout.toList(), ['0'], reason: stderr.join('\n'));
      expect(await result.exitCode, 0);
    });

    test('异步 main 等待完成后结束运行', () async {
      write(
        'main.dart',
        "Future<void> main() async { await Future<void>.delayed(Duration(milliseconds: 1)); print('async done'); }",
      );
      final result = (await dartProfile.runner!.run(
        projectPath: project.path,
        entryFile: p.join(project.path, 'main.dart'),
      ))!;
      expect(await result.stdout.toList(), ['async done']);
      expect(await result.exitCode, 0);
    });

    test('语法错误返回诊断而不伪造成功', () async {
      write('main.dart', 'void main( {');
      final result = (await dartProfile.runner!.run(
        projectPath: project.path,
        entryFile: p.join(project.path, 'main.dart'),
      ))!;
      expect(await result.stderr.toList(), isNotEmpty);
      expect(await result.exitCode, kProgramNotRunExitCode);
    });

    test('运行时异常进入 stderr', () async {
      write('main.dart', "void main() { throw 'boom'; }");
      final result = (await dartProfile.runner!.run(
        projectPath: project.path,
        entryFile: p.join(project.path, 'main.dart'),
      ))!;
      expect((await result.stderr.toList()).join('\n'), contains('boom'));
      expect(await result.exitCode, 1);
    });

    test('无限循环可以取消', () async {
      write('main.dart', 'void main() { while (true) {} }');
      final result = (await dartProfile.runner!.run(
        projectPath: project.path,
        entryFile: p.join(project.path, 'main.dart'),
      ))!;
      await result.cancel!();
      expect(await result.exitCode, 130);
    });

    test('别的语言文件交回内核', () async {
      write('main.py', 'x');
      final result = await dartProfile.runner!.run(
        projectPath: project.path,
        entryFile: p.join(project.path, 'main.py'),
      );
      expect(result, isNull);
    });
  });

  group('运行按钮分流', () {
    test('点运行拿到程序输出，而不是兜底提示', () async {
      write('main.dart', "void main() { print('run button'); }");
      final result = await RunnerService.runProject(
        projectPath: project.path,
        entryFile: p.join(project.path, 'main.dart'),
      );
      expect(result, isNotNull);
      expect(result!.hint, isNull, reason: '后端接管了就不该走兜底提示');
      expect(await result.stdout!.toList(), ['run button']);
      expect(await result.exitCode, 0);
    });
  });
}
