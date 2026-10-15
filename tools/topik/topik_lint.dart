import 'dart:convert';
import 'dart:io';

import 'package:memox/features/topik/data/mappers/topik_content_pack_mapper.dart';
import 'package:memox/features/topik/domain/models/topik_content_issue_model.dart';

/// Checks TOPIK content packs the way the app does (BR-TOPIK-008).
///
///     dart run tools/topik/topik_lint.dart [contentRoot] [bundleRoot]
///
/// contentRoot holds manifest.json (default assets/topik); asset paths in the
/// packs resolve against bundleRoot (default the current directory). Prints
/// one line per issue; exits 1 when any is an error.

const String _manifestName = 'manifest.json';

final class TopikLintReport {
  const TopikLintReport({required this.issues, required this.testCount});

  final List<TopikContentIssue> issues;

  /// Tests that were read, whether or not they pass.
  final int testCount;

  bool get passes => !issues.any((issue) => issue.isError);
}

TopikLintReport lintTopikContent({
  required Directory contentRoot,
  required Directory bundleRoot,
  Set<String>? declaredAssetFolders,
}) {
  final fileIssues = <TopikContentIssue>[];
  final files = <TopikPackFile>[];
  final entries = _manifestEntries(contentRoot, fileIssues);
  for (final entry in entries) {
    final json = _decode(File('${contentRoot.path}/$entry'), entry, fileIssues);
    if (json == null) continue;
    files.add((origin: entry, json: json));
  }
  final load = topikContentOf(
    files,
    assetExists: (path) => File('${bundleRoot.path}/$path').existsSync(),
    fileIssues: fileIssues,
  );
  final folderIssues = declaredAssetFolders == null
      ? const <TopikContentIssue>[]
      : _undeclaredFolders(load, entries, declaredAssetFolders);
  return TopikLintReport(
    issues: [...load.issues, ...folderIssues],
    testCount: load.readCount,
  );
}

const String _bundleFolder = 'assets/topik/';

/// Flutter reads a declared folder's files, not its subfolders: every folder
/// holding a pack or an asset the packs name must be declared.
List<TopikContentIssue> _undeclaredFolders(
  TopikContentLoad load,
  List<String> entries,
  Set<String> declared,
) {
  final needed = <String, String>{
    _folderOf('$_bundleFolder$_manifestName'): _manifestName,
    for (final entry in entries) _folderOf('$_bundleFolder$entry'): entry,
    for (final test in load.accepted) ...{
      if (test.audioAsset case final audio?) _folderOf(audio): test.testId,
      for (final group in test.groups)
        if (group.passage?.image case final image?)
          _folderOf(image): test.testId,
      for (final question in test.questions)
        for (final option in question.options)
          if (option.image case final image?) _folderOf(image): test.testId,
    },
  };
  return [
    for (final MapEntry(key: folder, value: owner) in needed.entries)
      if (!declared.contains(folder))
        TopikContentIssue.error(
          TopikContentRule.assets,
          owner,
          'folder $folder is not declared in pubspec.yaml flutter.assets',
        ),
  ];
}

String _folderOf(String path) => path.substring(0, path.lastIndexOf('/') + 1);

/// The folder entries (ending in `/`) listed under `flutter: assets:`.
Set<String> declaredAssetFoldersOf(String pubspecYaml) {
  final folders = <String>{};
  var inAssets = false;
  for (final line in const LineSplitter().convert(pubspecYaml)) {
    final trimmed = line.trim();
    if (trimmed == 'assets:') {
      inAssets = true;
      continue;
    }
    if (!inAssets || trimmed.isEmpty || trimmed.startsWith('#')) continue;
    if (!trimmed.startsWith('- ')) {
      inAssets = false;
      continue;
    }
    final value = trimmed.substring(2).split('#').first.trim();
    if (value.endsWith('/')) folders.add(value);
  }
  return folders;
}

List<String> _manifestEntries(Directory root, List<TopikContentIssue> issues) {
  final json = _decode(
    File('${root.path}/$_manifestName'),
    _manifestName,
    issues,
  );
  if (json == null) return const [];
  final tests = json is Map<String, Object?> ? json['tests'] : null;
  if (tests is! List<Object?> || tests.any((entry) => entry is! String)) {
    issues.add(
      const TopikContentIssue.error(
        TopikContentRule.shape,
        _manifestName,
        'tests must be a list of paths',
      ),
    );
    return const [];
  }
  return tests.cast<String>();
}

Object? _decode(File file, String name, List<TopikContentIssue> issues) {
  if (!file.existsSync()) {
    issues.add(
      TopikContentIssue.error(TopikContentRule.shape, name, 'file not found'),
    );
    return null;
  }
  try {
    // Decoded here, not by readAsStringSync, so bytes that are not UTF-8
    // are a FormatException like malformed JSON, not a crash.
    return jsonDecode(utf8.decode(file.readAsBytesSync()));
  } on FormatException catch (error) {
    issues.add(
      TopikContentIssue.error(
        TopikContentRule.shape,
        name,
        'not JSON: ${error.message}',
      ),
    );
    return null;
  }
}

void main(List<String> args) {
  final contentRoot = Directory(args.isNotEmpty ? args[0] : 'assets/topik');
  final bundleRoot = Directory(args.length > 1 ? args[1] : '.');
  final report = lintTopikContent(
    contentRoot: contentRoot,
    bundleRoot: bundleRoot,
  );
  for (final issue in report.issues) {
    stdout.writeln(issue);
  }
  final verdict = report.passes ? 'PASS' : 'FAIL';
  stdout.writeln(
    '$verdict: ${report.testCount} test(s), ${report.issues.length} issue(s)',
  );
  exitCode = report.passes ? 0 : 1;
}
