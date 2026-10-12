import 'dart:convert';
import 'dart:io';

/// Compatibility audit: lists lessons that use Dart 3 / async / streams /
/// isolates / IO features and whether `explain` states the engine requirement.
///
/// Engine notes must live in `explain` because the lesson detail page renders
/// `explain` but not any `runtime` field.
void main() {
  final doc =
      jsonDecode(File('assets/content/dart_tutorials.json').readAsStringSync())
          as Map<String, dynamic>;
  final entries = (doc['entries'] as List).cast<Map<String, dynamic>>();
  final advanced = RegExp(
    r'\brecord\b|\bsealed\b|switch\s*\(|=>\s*switch|\bwhen\b|'
    r'\basync\b|\bawait\b|Future|\bStream\b|StreamController|Isolate|'
    r'dart:io|Directory|File\(|Process\.|stdin|stdout',
  );
  final label = RegExp(r'官方 Dart SDK|官方 SDK|dart_eval|SDK 引擎|子集');
  var advancedCount = 0;
  var labeled = 0;
  final unlabeled = <String>[];
  for (final e in entries) {
    final id = e['id'] as String;
    final l = (e['lessons'] as List).first as Map<String, dynamic>;
    final code = l['code'] as String;
    final explain = l['explain'] as String;
    if (advanced.hasMatch(code)) {
      advancedCount++;
      if (label.hasMatch(explain)) {
        labeled++;
      } else {
        unlabeled.add(id);
      }
    }
  }
  stdout.writeln('advanced lessons: $advancedCount');
  stdout.writeln('labeled: $labeled');
  stdout.writeln('unlabeled: ${unlabeled.length} $unlabeled');
}
