import 'package:memox/features/topik/data/mappers/topik_test_mapper.dart';
import 'package:memox/features/topik/domain/models/topik_content_check_model.dart';
import 'package:memox/features/topik/domain/models/topik_content_issue_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';

/// One decoded pack file and where it came from.
typedef TopikPackFile = ({String origin, Object? json});

/// What reading a set of packs gave (BR-TOPIK-008).
final class TopikContentLoad {
  const TopikContentLoad({
    required this.accepted,
    required this.issues,
    required this.readCount,
  });

  /// Tests that pass every check, the first of each id, in file order.
  final List<TopikTest> accepted;

  /// Every error and warning, the file problems first.
  final List<TopikContentIssue> issues;

  /// Files that read into a test, valid or not.
  final int readCount;

  bool get hasErrors => issues.any((issue) => issue.isError);
}

/// The one content pipeline (BR-TOPIK-008): the app's loader and the gate's
/// lint both run it, so what the gate stops is what the app refuses. Each
/// file is read, then checked; among the tests that pass, the first of each
/// id wins and a later copy is a duplicate. An invalid copy never blocks a
/// valid one.
TopikContentLoad topikContentOf(
  Iterable<TopikPackFile> files, {
  required bool Function(String assetPath) assetExists,
  List<TopikContentIssue> fileIssues = const [],
}) {
  final issues = [...fileIssues];
  final accepted = <TopikTest>[];
  final ids = <String>{};
  var readCount = 0;
  for (final file in files) {
    final read = topikTestOf(file.json, origin: file.origin);
    issues.addAll(read.issues);
    final test = read.test;
    if (test == null) continue;
    readCount++;
    final checks = checkTopikTest(test, assetExists: assetExists);
    issues.addAll(checks);
    if (checks.any((issue) => issue.isError)) continue;
    if (ids.add(test.testId)) {
      accepted.add(test);
      continue;
    }
    issues.add(
      TopikContentIssue.error(
        TopikContentRule.duplicate,
        test.testId,
        '${file.origin}: an earlier pack already has this test id',
      ),
    );
  }
  return TopikContentLoad(
    accepted: List.unmodifiable(accepted),
    issues: List.unmodifiable(issues),
    readCount: readCount,
  );
}
