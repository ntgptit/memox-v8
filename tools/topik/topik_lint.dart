import 'dart:convert';
import 'dart:io';

import 'package:memox/features/topik/data/mappers/topik_test_mapper.dart';
import 'package:memox/features/topik/domain/models/topik_content_check_model.dart';
import 'package:memox/features/topik/domain/models/topik_content_issue_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';

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
}) {
  final issues = <TopikContentIssue>[];
  final entries = _manifestEntries(contentRoot, issues);
  final tests = <TopikTest>[];
  for (final entry in entries) {
    final json = _decode(File('${contentRoot.path}/$entry'), entry, issues);
    if (json == null) continue;
    final read = topikTestOf(json);
    issues.addAll(read.issues);
    final test = read.test;
    if (test == null) continue;
    tests.add(test);
    issues.addAll(
      checkTopikTest(
        test,
        assetExists: (path) => File('${bundleRoot.path}/$path').existsSync(),
      ),
    );
  }
  issues.addAll(checkTopikCatalog(tests));
  return TopikLintReport(issues: issues, testCount: tests.length);
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
    return jsonDecode(file.readAsStringSync());
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
