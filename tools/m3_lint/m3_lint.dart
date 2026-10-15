// Lints lib/ with the Material 3 rules (M3L00..M3L08).
// Exit 0 when clean, 1 on violations, 2 on a malformed allowlist or when the
// code could not be analyzed.
import 'dart:io';

import 'm3_rules.dart';

const String _allowlistPath = 'tools/m3_lint/allowlist.json';

Future<void> main() async {
  final root = Directory.current.absolute.path;
  final List<AllowEntry> allowlist;
  try {
    allowlist = loadAllowlist('$root/$_allowlistPath');
  } on FormatException catch (e) {
    stderr.writeln('m3_lint: $_allowlistPath is malformed: ${e.message}');
    exit(2);
  } on FileSystemException catch (e) {
    stderr.writeln('m3_lint: cannot read $_allowlistPath: ${e.message}');
    exit(2);
  }
  final files = [
    for (final entity in Directory('$root/lib').listSync(recursive: true))
      if (entity is File &&
          entity.path.endsWith('.dart') &&
          !entity.path.endsWith('.g.dart'))
        entity.path,
  ]..sort();
  final List<M3Violation> violations;
  try {
    violations = await lintPaths(files, root: root, allowlist: allowlist);
  } on StateError catch (e) {
    stderr.writeln('m3_lint: ${e.message}');
    exit(2);
  }
  for (final v in violations) {
    stdout.writeln(v);
  }
  if (violations.isEmpty) {
    stdout.writeln('m3_lint: ${files.length} files clean');
    return;
  }
  stdout.writeln('m3_lint: ${violations.length} violation(s)');
  exit(1);
}
