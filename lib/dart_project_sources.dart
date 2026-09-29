import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';

class DartProjectSources {
  const DartProjectSources({required this.packages, required this.entryUri});

  final Map<String, Map<String, String>> packages;
  final String entryUri;

  static Future<DartProjectSources> load({
    required String projectPath,
    required String entryFile,
  }) async {
    final root = p.normalize(p.absolute(projectPath));
    final entry = p.normalize(p.absolute(entryFile));
    if (!p.isWithin(root, entry)) {
      throw ArgumentError.value(entryFile, 'entryFile', '入口文件不在项目目录内');
    }

    final sources = await _readSources(root);
    final relativeEntry = p.relative(entry, from: root).replaceAll('\\', '/');
    if (!sources.containsKey(relativeEntry)) {
      throw FileSystemException('找不到入口文件', entry);
    }

    final pubspec = File(p.join(root, 'pubspec.yaml'));
    final packageName = await pubspec.exists()
        ? Pubspec.parse(await pubspec.readAsString()).name
        : 'qfli_project';
    final librarySources = <String, String>{};
    for (final source in sources.entries) {
      if (source.key.startsWith('lib/')) {
        librarySources[source.key.substring(4)] = source.value;
      }
    }

    final workspaceName = '${packageName}_workspace';
    final entryUri = relativeEntry.startsWith('lib/')
        ? 'package:$packageName/${relativeEntry.substring(4)}'
        : 'package:$workspaceName/$relativeEntry';
    return DartProjectSources(
      packages: {packageName: librarySources, workspaceName: sources},
      entryUri: entryUri,
    );
  }

  static Future<Map<String, String>> _readSources(String root) async {
    final sources = <String, String>{};

    Future<void> visit(Directory directory) async {
      await for (final entity in directory.list(followLinks: false)) {
        final name = p.basename(entity.path);
        if (name.startsWith('.') || name == 'build') continue;
        if (entity is Directory) {
          await visit(entity);
        } else if (entity is File &&
            p.extension(name).toLowerCase() == '.dart') {
          sources[p.relative(entity.path, from: root).replaceAll('\\', '/')] =
              await entity.readAsString();
        }
      }
    }

    await visit(Directory(root));
    return sources;
  }
}
