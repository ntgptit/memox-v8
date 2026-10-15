import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_status_model.dart';

import '../../../support/topik_content_fixtures.dart';

TopikTestStatus _status(String testId, DateTime at) => TopikTestStatus(
  testId: testId,
  hasInProgress: false,
  completedCount: 1,
  bestScore: 80,
  lastActivityAt: at,
);

// BR-TOPIK-022, spec §6.3.
void main() {
  final r91 = topikTestFixture(round: 91);
  final r96 = topikTestFixture(round: 96);
  final r83 = topikTestFixture(round: 83);
  final listening = topikTestFixture(section: TopikSection.listening);
  final entries = topikCatalogEntriesOf(
    [r91, r96, r83, listening],
    {
      r83.testId: _status(r83.testId, DateTime.utc(2026, 10, 2)),
      r91.testId: _status(r91.testId, DateTime.utc(2026, 10, 5)),
    },
  );

  List<int> rounds(TopikTestOrder order) => [
    for (final e in topikTestsOf(
      entries,
      level: TopikLevel.topik2,
      section: TopikSection.reading,
      order: order,
    ))
      e.test.round,
  ];

  test('each entry carries its status, or none when never taken', () {
    expect(entries.firstWhere((e) => e.test.round == 96).status, isNull);
    expect(entries.firstWhere((e) => e.test.round == 91).status, isNotNull);
  });

  test('one level and section, by round', () {
    expect(rounds(TopikTestOrder.roundDescending), [96, 91, 83]);
    expect(rounds(TopikTestOrder.roundAscending), [83, 91, 96]);
  });

  test(
    'latest activity first; tests never taken last, by round descending',
    () {
      expect(rounds(TopikTestOrder.latestActivity), [91, 83, 96]);
    },
  );
}
