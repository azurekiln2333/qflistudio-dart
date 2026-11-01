import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'permissions.dart';

/// Opt-in host boundaries for an offline editor execution.
///
/// This is a transferable configuration: child interpreters receive the same
/// absolute roots and output port. Explicit runtime permissions are still
/// required; this policy only narrows what those grants can authorize.
/// Symbolic-link traversal, process execution, network access and standard
/// input are unavailable. Directory listings expose links without following
/// them, and operations on paths containing a symbolic link are rejected.
class OfflineHostPolicy {
  OfflineHostPolicy({
    required String scratchPath,
    String? projectPath,
    required this.output,
  }) : scratchPath = _absoluteRoot(scratchPath),
       projectPath = projectPath == null ? null : _absoluteRoot(projectPath);

  final String scratchPath;
  final String? projectPath;
  final SendPort output;

  static final Object _zoneKey = Object();

  static String _absoluteRoot(String path) {
    if (path.isEmpty || !File(path).isAbsolute) {
      throw ArgumentError.value(
        path,
        'path',
        'An absolute directory is required',
      );
    }
    return Directory(path).absolute.path;
  }

  bool get isActive => identical(Zone.current[_zoneKey], this);

  /// Runs native I/O in this execution's directory and standard-stream scope.
  T run<T>(T Function() body) {
    if (isActive) return body();
    return runZoned(
      () => IOOverrides.runWithIOOverrides(body, _OfflineIOOverrides(this)),
      zoneValues: {_zoneKey: this},
    );
  }

  /// A ceiling applied before the caller's explicit permission grants.
  bool allows(dynamic operation) {
    if (operation is! Map) return false;
    if (operation['type'] == 'isolate') return true;
    if (operation['type'] != 'filesystem' || operation['execute'] == true) {
      return false;
    }
    if (operation['pathAgnostic'] == true) return true;
    final path = operation['path'];
    if (path is! String) return false;
    // Reject outside spellings before performing native metadata queries. In
    // particular, an ungranted UNC path must not initiate a remote lookup.
    final lexicalPath = _lexicalPath(path);
    if (!_isWithinRoot(scratchPath, lexicalPath) &&
        (projectPath == null || !_isWithinRoot(projectPath!, lexicalPath))) {
      return false;
    }
    // A broken link can point to an outside file that does not exist yet.
    // Check links without following them before the normal scope resolver's
    // deepest-existing-ancestor fallback can treat that spelling as in scope.
    if (_hasSymbolicLinkComponent(path)) return false;
    final request = <String, dynamic>{
      'type': 'filesystem',
      'path': path,
      'read': true,
    };
    return FilesystemPermission.readPath(scratchPath).allows(request) ||
        (projectPath != null &&
            FilesystemPermission.readPath(projectPath!).allows(request));
  }

  static String _lexicalPath(String path) {
    final normalized = File(path).absolute.uri
        .normalizePath()
        .toFilePath()
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/+$'), '');
    return Platform.isWindows ? normalized.toLowerCase() : normalized;
  }

  static bool _isWithinRoot(String root, String path) {
    final normalizedRoot = _lexicalPath(root);
    return path == normalizedRoot || path.startsWith('$normalizedRoot/');
  }

  bool _hasSymbolicLinkComponent(String path) {
    var probe = File(path).absolute.uri.normalizePath().toFilePath();
    final components = <String>[];
    while (true) {
      components.add(probe);
      final parent = Directory(probe).parent.path;
      if (parent == probe) break;
      probe = parent;
    }
    // Inspect ancestors before descendants, so checking the leaf itself never
    // follows an earlier link before that link is rejected.
    for (final component in components.reversed) {
      if (FileSystemEntity.typeSync(component, followLinks: false) ==
          FileSystemEntityType.link) {
        return true;
      }
    }
    return false;
  }
}

final class _OfflineIOOverrides extends IOOverrides {
  _OfflineIOOverrides(this.policy)
    : _stdout = _RunStdout(policy.output, 'stdout'),
      _stderr = _RunStdout(policy.output, 'stderr');

  final OfflineHostPolicy policy;
  final _RunStdout _stdout;
  final _RunStdout _stderr;

  String get _currentPath => policy.projectPath ?? policy.scratchPath;

  String _absolute(String path) {
    final uri = Uri.file(path, windows: Platform.isWindows);
    if (uri.isAbsolute) return uri.toFilePath(windows: Platform.isWindows);
    return Uri.directory(
      _currentPath,
      windows: Platform.isWindows,
    ).resolveUri(uri).toFilePath(windows: Platform.isWindows);
  }

  @override
  File createFile(String path) => super.createFile(_absolute(path));

  @override
  Directory createDirectory(String path) =>
      super.createDirectory(_absolute(path));

  @override
  Link createLink(String path) => super.createLink(_absolute(path));

  @override
  Directory getCurrentDirectory() => super.createDirectory(_currentPath);

  @override
  void setCurrentDirectory(String path) {
    throw UnsupportedError(
      'Changing Directory.current is unavailable in offline execution.',
    );
  }

  @override
  Directory getSystemTempDirectory() =>
      super.createDirectory(policy.scratchPath);

  @override
  Future<FileStat> stat(String path) => super.stat(_absolute(path));

  @override
  FileStat statSync(String path) => super.statSync(_absolute(path));

  @override
  Future<bool> fseIdentical(String path1, String path2) =>
      super.fseIdentical(_absolute(path1), _absolute(path2));

  @override
  bool fseIdenticalSync(String path1, String path2) =>
      super.fseIdenticalSync(_absolute(path1), _absolute(path2));

  @override
  Future<FileSystemEntityType> fseGetType(String path, bool followLinks) =>
      super.fseGetType(_absolute(path), followLinks);

  @override
  FileSystemEntityType fseGetTypeSync(String path, bool followLinks) =>
      super.fseGetTypeSync(_absolute(path), followLinks);

  @override
  Stdin get stdin => throw UnsupportedError(
    'Standard input is unavailable in offline execution.',
  );

  @override
  Stdout get stdout => _stdout;

  @override
  Stdout get stderr => _stderr;

  @override
  Never exit(int code) {
    throw UnsupportedError(
      'Exiting the host process is unavailable in offline execution.',
    );
  }
}

/// A run-owned stream. Closing or configuring it never changes the host stream.
class _RunStdout implements Stdout {
  _RunStdout(this._output, this._type);

  final SendPort _output;
  final String _type;
  final Completer<void> _done = Completer<void>();
  Encoding _encoding = utf8;
  String _lineTerminator = '\n';
  Sink<List<int>>? _decoder;
  bool _closed = false;
  bool _addingStream = false;

  void _checkOpen() {
    if (_closed) throw StateError('The output stream is closed');
  }

  void _checkWritable() {
    _checkOpen();
    if (_addingStream) throw StateError('A stream is already being added');
  }

  void _emit(String text) {
    if (text.isNotEmpty) _output.send({'type': _type, 'data': text});
  }

  void _addBytes(List<int> bytes) {
    _decoder ??= _encoding.decoder.startChunkedConversion(
      StringConversionSink.fromStringSink(_PortStringSink(_emit)),
    );
    _decoder!.add(bytes);
  }

  @override
  void write(Object? object) {
    _checkWritable();
    var text = '$object';
    if (_lineTerminator == '\r\n') {
      text = text.replaceAll(RegExp(r'(?<!\r)\n'), '\r\n');
    }
    _emit(text);
  }

  @override
  void writeln([Object? object = '']) => write('$object\n');

  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      write(objects.join(separator));

  @override
  void writeCharCode(int charCode) => write(String.fromCharCode(charCode));

  @override
  void add(List<int> data) {
    _checkWritable();
    _addBytes(data);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    _checkWritable();
    _addingStream = true;
    try {
      await for (final bytes in stream) {
        _checkOpen();
        _addBytes(bytes);
      }
    } finally {
      _addingStream = false;
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      throw UnsupportedError('Standard output does not accept error events');

  @override
  Future<void> flush() async => _checkOpen();

  @override
  Future<void> close() async {
    if (_closed) return;
    _decoder?.close();
    _closed = true;
    _done.complete();
  }

  @override
  Future<void> get done => _done.future;

  @override
  Encoding get encoding => _encoding;

  @override
  set encoding(Encoding value) {
    _checkWritable();
    _decoder?.close();
    _decoder = null;
    _encoding = value;
  }

  @override
  String get lineTerminator => _lineTerminator;

  @override
  set lineTerminator(String value) {
    if (value != '\n' && value != '\r\n') {
      throw ArgumentError.value(value, 'lineTerminator');
    }
    _lineTerminator = value;
  }

  @override
  bool get hasTerminal => false;

  @override
  bool get supportsAnsiEscapes => false;

  @override
  int get terminalColumns => throw StdoutException('No terminal is attached');

  @override
  int get terminalLines => throw StdoutException('No terminal is attached');

  @override
  IOSink get nonBlocking => this;
}

class _PortStringSink implements StringSink {
  _PortStringSink(this.emit);
  final void Function(String) emit;

  @override
  void write(Object? object) => emit('$object');

  @override
  void writeln([Object? object = '']) => emit('$object\n');

  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      emit(objects.join(separator));

  @override
  void writeCharCode(int charCode) => emit(String.fromCharCode(charCode));
}
