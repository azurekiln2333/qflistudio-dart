import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:qfli_studio_core/services/studio_profile.dart';
import 'package:qfli_studio_core/store/project_store.dart';

import 'dart_runner.dart';
import 'dart_tools.dart';

class DartToolsPage extends StatefulWidget {
  const DartToolsPage({super.key, required this.store});

  final ProjectStore store;

  static Widget forStore(ProjectStore store) => DartToolsPage(store: store);

  @override
  State<DartToolsPage> createState() => _DartToolsPageState();
}

class _DartToolsPageState extends State<DartToolsPage> {
  final _source = TextEditingController();
  String _observedSource = '';
  String? _projectPath;
  String? _filePath;
  List<String> _files = [];
  List<DartDiagnostic>? _diagnostics;
  List<String> _output = [];
  String? _artifact;
  String? _error;
  bool _dirty = false;
  bool _busy = false;
  bool _settingSource = false;
  bool _projectsChangedWhileBusy = false;
  int? _exitCode;
  int _generation = 0;
  ProgramRunResult? _run;
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onProjectsChanged);
    _source.addListener(_onSourceChanged);
    _onProjectsChanged();
  }

  @override
  void dispose() {
    _generation++;
    widget.store.removeListener(_onProjectsChanged);
    unawaited(_stdoutSubscription?.cancel());
    unawaited(_stderrSubscription?.cancel());
    unawaited(_run?.cancel?.call());
    _source.dispose();
    super.dispose();
  }

  void _onSourceChanged() {
    if (_settingSource || _filePath == null) return;
    if (_source.text == _observedSource) return;
    _observedSource = _source.text;
    setState(() {
      _dirty = true;
      _diagnostics = null;
      _artifact = null;
    });
  }

  void _replaceSource(String text) {
    _settingSource = true;
    _source.text = text;
    _observedSource = text;
    _settingSource = false;
    _dirty = false;
  }

  void _onProjectsChanged() {
    if (_busy) {
      _projectsChangedWhileBusy = true;
      return;
    }
    final projects = widget.store.projects.where((item) => !item.isCloud);
    if (_projectPath != null &&
        projects.any((item) => item.path == _projectPath)) {
      return;
    }
    final first = projects.isEmpty ? null : projects.first.path;
    if (first == _projectPath) return;
    unawaited(_selectProject(first));
  }

  bool _beginOperation() {
    if (!mounted || _busy) return false;
    setState(() {
      _busy = true;
      _error = null;
    });
    return true;
  }

  void _finishOperation() {
    if (!mounted) return;
    setState(() => _busy = false);
    if (_projectsChangedWhileBusy) {
      _projectsChangedWhileBusy = false;
      _onProjectsChanged();
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未保存的更改'),
        content: const Text('要如何处理当前未保存的内容？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('放弃更改'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (!mounted) return false;
    if (choice == 'save') return _writeSource();
    return choice == 'discard';
  }

  Future<void> _requestPop() async {
    if (!_beginOperation()) return;
    try {
      if (await _confirmDiscard() && mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      _finishOperation();
    }
  }

  Future<void> _selectProject(String? path) async {
    if (path == _projectPath || !_beginOperation()) return;
    try {
      if (!await _confirmDiscard() || !mounted) return;
      final generation = ++_generation;
      setState(() {
        _projectPath = path;
        _filePath = null;
        _files = [];
        _diagnostics = null;
        _output = [];
        _artifact = null;
        _error = null;
        _exitCode = null;
        _replaceSource('');
      });
      if (path == null) return;
      final files = await _listDartFiles(path);
      if (!mounted || generation != _generation) return;
      setState(() => _files = files);
      if (files.isNotEmpty) await _loadFile(files.first, generation);
    } on FileSystemException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      _finishOperation();
    }
  }

  static Future<List<String>> _listDartFiles(String root) =>
      compute(_scanDartFiles, root);

  Future<void> _selectFile(String path) async {
    if (path == _filePath || !_beginOperation()) return;
    try {
      if (!await _confirmDiscard() || !mounted) return;
      await _loadFile(path, ++_generation);
    } finally {
      _finishOperation();
    }
  }

  Future<void> _loadFile(String path, int generation) async {
    try {
      final text = await compute(_readSourceFile, path);
      if (!mounted || generation != _generation) return;
      setState(() {
        _filePath = path;
        _replaceSource(text);
        _diagnostics = null;
        _output = [];
        _artifact = null;
        _error = null;
        _exitCode = null;
      });
    } on FileSystemException catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = error.message);
      }
    }
  }

  Future<void> _save() async {
    if (!_beginOperation()) return;
    try {
      await _writeSource();
    } finally {
      _finishOperation();
    }
  }

  Future<bool> _writeSource() async {
    final path = _filePath;
    if (path == null) return false;
    final source = _source.text;
    final generation = _generation;
    try {
      await File(path).writeAsString(source, flush: true);
      if (mounted && generation == _generation && _source.text == source) {
        setState(() => _dirty = false);
      }
      return true;
    } on FileSystemException catch (error) {
      if (mounted) setState(() => _error = error.message);
      return false;
    }
  }

  Future<void> _format() async {
    if (!_beginOperation()) return;
    final source = _source.text;
    try {
      final formatted = await compute(DartTools.format, source);
      if (!mounted || _source.text != source) return;
      _source.text = formatted;
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      _finishOperation();
    }
  }

  Future<void> _analyze() async {
    if (!_beginOperation()) return;
    final source = _source.text;
    setState(() {
      _diagnostics = null;
      _artifact = null;
      _output = [];
      _exitCode = null;
    });
    try {
      final diagnostics = await compute(DartTools.syntaxDiagnostics, source);
      if (mounted && _source.text == source) {
        setState(() => _diagnostics = diagnostics);
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      _finishOperation();
    }
  }

  Future<void> _compile() async {
    final project = _projectPath;
    final file = _filePath;
    if (project == null || file == null || !_beginOperation()) return;
    setState(() {
      _artifact = null;
      _diagnostics = null;
      _output = [];
      _exitCode = null;
    });
    try {
      if (!await _writeSource() || !mounted) return;
      final compiled = await DartTools.compile(
        projectPath: project,
        entryFile: file,
      );
      final relative = p.relative(file, from: project);
      final artifact = File(
        p.join(
          project,
          'build',
          '${p.withoutExtension(relative)}${compiled.extension}',
        ),
      );
      await artifact.parent.create(recursive: true);
      await artifact.writeAsBytes(compiled.bytecode, flush: true);
      if (mounted) {
        setState(() => _artifact = p.relative(artifact.path, from: project));
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      _finishOperation();
    }
  }

  Future<void> _execute() async {
    final project = _projectPath;
    final file = _filePath;
    if (project == null || file == null || !_beginOperation()) return;
    setState(() {
      _output = [];
      _exitCode = null;
      _diagnostics = null;
      _artifact = null;
    });
    StreamSubscription<String>? stdoutSubscription;
    StreamSubscription<String>? stderrSubscription;
    try {
      if (!await _writeSource() || !mounted) return;
      final run = await const DartProgramRunner().run(
        projectPath: project,
        entryFile: file,
      );
      if (run == null) return;
      if (!mounted) {
        await run.cancel?.call();
        return;
      }
      setState(() => _run = run);
      _stdoutSubscription = stdoutSubscription = run.stdout.listen((line) {
        if (mounted) setState(() => _output.add(line));
      });
      _stderrSubscription = stderrSubscription = run.stderr.listen((line) {
        if (mounted) setState(() => _output.add(line));
      });
      final code = await run.exitCode;
      if (mounted) setState(() => _exitCode = code);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      await stdoutSubscription?.cancel();
      await stderrSubscription?.cancel();
      _stdoutSubscription = null;
      _stderrSubscription = null;
      _run = null;
      _finishOperation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = widget.store.projects
        .where((item) => !item.isCloud)
        .toList();
    final root = _projectPath;
    final file = _filePath;
    return PopScope<void>(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_requestPop());
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Dart 工具')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InputDecorator(
              decoration: const InputDecoration(labelText: '项目'),
              isEmpty: root == null,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: projects.any((item) => item.path == root)
                      ? root
                      : null,
                  isExpanded: true,
                  items: [
                    for (final project in projects)
                      DropdownMenuItem(
                        value: project.path,
                        child: Text(
                          project.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (path) => unawaited(_selectProject(path)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (root != null)
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Dart 文件'),
                isEmpty: file == null,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _files.contains(file) ? file : null,
                    isExpanded: true,
                    items: [
                      for (final path in _files)
                        DropdownMenuItem(
                          value: path,
                          child: Text(
                            p.relative(path, from: root),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _busy
                        ? null
                        : (path) {
                            if (path != null) unawaited(_selectFile(path));
                          },
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (file != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  IconButton(
                    tooltip: '保存',
                    onPressed: _busy || !_dirty
                        ? null
                        : () => unawaited(_save()),
                    icon: const Icon(Icons.save_outlined),
                  ),
                  IconButton(
                    tooltip: '格式化 Dart',
                    onPressed: _busy ? null : () => unawaited(_format()),
                    icon: const Icon(Icons.format_align_left),
                  ),
                  IconButton(
                    tooltip: '语法检查',
                    onPressed: _busy ? null : () => unawaited(_analyze()),
                    icon: const Icon(Icons.fact_check_outlined),
                  ),
                  IconButton(
                    tooltip: '编译',
                    onPressed: _busy ? null : () => unawaited(_compile()),
                    icon: const Icon(Icons.memory_outlined),
                  ),
                  IconButton(
                    tooltip: '运行',
                    onPressed: _busy ? null : () => unawaited(_execute()),
                    icon: const Icon(Icons.play_arrow),
                  ),
                  if (_run != null)
                    IconButton(
                      tooltip: '停止',
                      onPressed: () => unawaited(_run?.cancel?.call()),
                      icon: const Icon(Icons.stop),
                    ),
                  if (_busy)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: MediaQuery.sizeOf(context).width >= 720 ? 420 : 300,
                child: TextField(
                  controller: _source,
                  readOnly: _busy,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  style: const TextStyle(fontFamily: 'monospace'),
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(height: 200, child: _buildResults()),
            ] else
              SizedBox(
                height: 240,
                child: Center(
                  child: _busy
                      ? const CircularProgressIndicator()
                      : _error != null
                      ? SelectableText(_error!)
                      : Text(projects.isEmpty ? '没有本地项目' : '所选项目没有 Dart 文件'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_error != null) return SelectableText(_error!);
    if (_diagnostics != null) {
      if (_diagnostics!.isEmpty) return const Center(child: Text('没有语法错误'));
      return ListView.builder(
        itemCount: _diagnostics!.length,
        itemBuilder: (context, index) {
          final item = _diagnostics![index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.error_outline),
            title: Text('${item.line}:${item.column}  ${item.message}'),
            subtitle: Text(item.code),
          );
        },
      );
    }
    if (_artifact != null) return SelectableText('已生成 $_artifact');
    if (_output.isNotEmpty || _exitCode != null) {
      return ListView(
        children: [
          for (final line in _output) SelectableText(line),
          if (_exitCode != null) Text('退出码 $_exitCode'),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

String _readSourceFile(String path) => File(path).readAsStringSync();

List<String> _scanDartFiles(String root) {
  final result = <String>[];

  void visit(Directory directory) {
    for (final entity in directory.listSync(followLinks: false)) {
      final name = p.basename(entity.path);
      if (name.startsWith('.') || name == 'build') continue;
      if (entity is Directory) {
        visit(entity);
      } else if (entity is File && p.extension(name).toLowerCase() == '.dart') {
        result.add(entity.path);
      }
    }
  }

  visit(Directory(root));
  result.sort();
  return result;
}
