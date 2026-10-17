// Lints lib/ with the ForUI boundary rules (UIL00..UIL06, ui_rules.dart).
// Exit 0 when clean, 1 on violations, 2 on a malformed allowlist or when the
// code could not be analyzed.
//
// Usage: dart run tools/ui_lint/ui_lint.dart [path ...]
//   no path   every hand-written Dart file under lib/ (the gate's full mode)
//   path ...  only those files, of the ones that are hand-written Dart under
//             lib/ and still exist (dod_check.sh --changed passes its diff);
//             an allowlist entry is then stale only for a file linted here.
// Resolving lib/ costs about a minute whatever the cache, so the changed mode
// lints what changed and the full gate lints the whole tree.
import 'dart:io';

import 'ui_rules.dart';

const String _allowlistPath = 'tools/ui_lint/allowlist.json';

bool _isLintable(String relativePath) =>
    relativePath.startsWith('lib/') &&
    relativePath.endsWith('.dart') &&
    !relativePath.endsWith('.g.dart');

Future<void> main(List<String> args) async {
  final root = Directory.current.absolute.path;
  final List<AllowEntry> allowlist;
  try {
    allowlist = loadAllowlist('$root/$_allowlistPath');
  } on FormatException catch (e) {
    stderr.writeln('ui_lint: $_allowlistPath is malformed: ${e.message}');
    exit(2);
  } on FileSystemException catch (e) {
    stderr.writeln('ui_lint: cannot read $_allowlistPath: ${e.message}');
    exit(2);
  }
  final partial = args.isNotEmpty;
  final files = partial
      ? [
          for (final arg in args.toSet())
            if (_isLintable(relativeToRoot(File(arg).absolute.path, root)) &&
                File(arg).existsSync())
              File(arg).absolute.path,
        ]
      : [
          for (final entity in Directory('$root/lib').listSync(recursive: true))
            if (entity is File &&
                _isLintable(relativeToRoot(entity.path, root)))
              entity.path,
        ];
  files.sort();
  final List<UiViolation> violations;
  try {
    violations = await lintPaths(
      files,
      root: root,
      allowlist: allowlist,
      partial: partial,
    );
  } on StateError catch (e) {
    stderr.writeln('ui_lint: ${e.message}');
    exit(2);
  }
  for (final v in violations) {
    stdout.writeln(v);
  }
  final scope = partial ? ' (changed files only)' : '';
  if (violations.isEmpty) {
    stdout.writeln('ui_lint: ${files.length} files clean$scope');
    return;
  }
  stdout.writeln('ui_lint: ${violations.length} violation(s)$scope');
  exit(1);
}
