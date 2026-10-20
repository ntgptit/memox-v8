import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
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
  String plain(String text) =>
      text.replaceAll('\u00A0', ' ').replaceAll('\u2060', '');

  test('a status line for every case, in-progress first', () {
    expect(en.topikTestStatusLine(null), 'Not started');
    expect(
      plain(en.topikTestStatusLine(_status(hasInProgress: true))),
      'In progress',
    );
    expect(
      plain(en.topikTestStatusLine(_status(completedCount: 1, bestScore: 82))),
      'Best 82 · 1 attempt',
    );
    expect(
      plain(
        en.topikTestStatusLine(
          _status(hasInProgress: true, completedCount: 3, bestScore: 82),
        ),
      ),
      'In progress · Best 82 · 3 attempts',
    );
    expect(
      plain(vi.topikTestStatusLine(_status(completedCount: 3, bestScore: 82))),
      'Cao nhất 82 · 3 lượt',
    );
  });

  test('level names and scopes', () {
    expect(en.topikLevelName(TopikLevel.topik1), 'TOPIK I');
    // Grades and sections are separate terms, so the line can break
    // between them (The Wrap Rule).
    expect(en.topikLevelGrades(TopikLevel.topik2), 'Levels 3–6');
    expect(en.topikBothSections, 'Reading, Listening');
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

  test('audio clock, speed and option numbers (screen 37)', () {
    expect(topikClockText(0), '0:00');
    expect(topikClockText(42999), '0:42');
    expect(topikClockText(93000), '1:33');
    expect(en.topikSpeedText(1), '1');
    expect(en.topikSpeedText(0.75), '0.75');
    expect(vi.topikSpeedText(1.25), '1,25');
    expect(
      [for (var idx = 1; idx <= 4; idx++) topikCircled(idx)].join(),
      '①②③④',
    );
  });

  test('screen 38 names: every type, filter and status in both languages', () {
    for (final type in TopikQuestionType.values) {
      expect(en.topikTypeName(type), isNotEmpty, reason: type.name);
      expect(vi.topikTypeName(type), isNotEmpty, reason: type.name);
    }
    expect(
      en.topikTypeName(TopikQuestionType.r2SentenceInsert),
      'Where the sentence goes',
    );
    expect(
      [for (final f in TopikAnswerFilter.values) en.topikFilterName(f)],
      ['All', 'Wrong', 'Unanswered', 'Correct'],
    );
    expect(
      en.topikAnswerStatusName(TopikAnswerStatus.unanswered),
      'Unanswered',
    );
    expect(en.topikFilterEmpty(TopikAnswerFilter.wrong), 'No wrong answers');
  });

  test('an answer\'s meta line: circled on screen, plain digits spoken, in '
      'every variant (owner 2026-10-17)', () {
    final both = en.topikAnswerMeta(selected: 3, right: 1, time: '2m 05s');
    expect(both.shown, ['Your answer ③', 'Right answer ①', '2m 05s']);
    expect(both.spoken, 'Your answer 3, Right answer 1, 2m 05s');

    // The right answer hidden (the eye on 38).
    final hidden = en.topikAnswerMeta(selected: 3, right: null, time: '1m');
    expect(hidden.shown, ['Your answer ③', '1m']);
    expect(hidden.spoken, 'Your answer 3, 1m');

    // Unanswered, the right answer shown.
    final blank = en.topikAnswerMeta(selected: null, right: 2);
    expect(blank.shown, ['Not answered', 'Right answer ②']);
    expect(blank.spoken, 'Not answered, Right answer 2');

    final spokenVi = vi.topikAnswerMeta(selected: 4, right: 2).spoken;
    expect(spokenVi, 'Bạn chọn 4, Đáp án đúng 2');
  });
}
