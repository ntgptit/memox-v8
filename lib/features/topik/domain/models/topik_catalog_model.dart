import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_status_model.dart';

/// The test list's sort (BR-TOPIK-022); round descending is the default.
enum TopikTestOrder { roundDescending, roundAscending, latestActivity }

/// A test with the person's status on it; null when never taken.
final class TopikCatalogEntry {
  const TopikCatalogEntry({required this.test, required this.status});

  final TopikTest test;
  final TopikTestStatus? status;
}

List<TopikCatalogEntry> topikCatalogEntriesOf(
  List<TopikTest> tests,
  Map<String, TopikTestStatus> statuses,
) => [
  for (final test in tests)
    TopikCatalogEntry(test: test, status: statuses[test.testId]),
];

/// The tests of one [level] and [section] in [order]. Under latest activity,
/// tests never taken come last, by round descending.
List<TopikCatalogEntry> topikTestsOf(
  List<TopikCatalogEntry> entries, {
  required TopikLevel level,
  required TopikSection section,
  required TopikTestOrder order,
}) {
  int byRoundDescending(TopikCatalogEntry a, TopikCatalogEntry b) =>
      b.test.round.compareTo(a.test.round);
  final picked = [
    for (final entry in entries)
      if (entry.test.level == level && entry.test.section == section) entry,
  ];
  return picked..sort(switch (order) {
    TopikTestOrder.roundDescending => byRoundDescending,
    TopikTestOrder.roundAscending => (a, b) => byRoundDescending(b, a),
    TopikTestOrder.latestActivity => (a, b) {
      final left = a.status?.lastActivityAt;
      final right = b.status?.lastActivityAt;
      if (left == null && right == null) return byRoundDescending(a, b);
      if (left == null) return 1;
      if (right == null) return -1;
      final byActivity = right.compareTo(left);
      return byActivity != 0 ? byActivity : byRoundDescending(a, b);
    },
  });
}
