import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_status_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

TopikTestStatus _status({
  bool hasInProgress = false,
  int completedCount = 0,
  int? bestScore,
}) => TopikTestStatus(
  testId: 't',
  hasInProgress: hasInProgress,
  completedCount: completedCount,
  bestScore: bestScore,
  lastActivityAt: DateTime.utc(2026, 9, 24),
);

// BR-TOPIK-022: the status line of a test, in both languages.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final vi = lookupAppLocalizations(const Locale('vi'));

  test('a status line for every case, in-progress first', () {
    expect(en.topikTestStatusLine(null), 'Not started');
    expect(en.topikTestStatusLine(_status(hasInProgress: true)), 'In progress');
    expect(
      en.topikTestStatusLine(_status(completedCount: 1, bestScore: 82)),
      'Best 82 · 1 attempt',
    );
    expect(
      en.topikTestStatusLine(
        _status(hasInProgress: true, completedCount: 3, bestScore: 82),
      ),
      'In progress · Best 82 · 3 attempts',
    );
    expect(
      vi.topikTestStatusLine(_status(completedCount: 3, bestScore: 82)),
      'Cao nhất 82 · 3 lượt',
    );
  });

  test('level names and scopes', () {
    expect(en.topikLevelName(TopikLevel.topik1), 'TOPIK I');
    expect(
      en.topikLevelScope(TopikLevel.topik2),
      'Levels 3–6 · Reading, Listening',
    );
  });

  test('every rejection reads in the local-first voice', () {
    for (final reason in TopikRejection.values) {
      expect(en.topikRejectionMessage(reason), isNotEmpty);
    }
    expect(
      en.topikRejectionMessage(TopikRejection.testUnavailable),
      "This test isn't available",
    );
  });
}
