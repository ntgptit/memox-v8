import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/sm2_scheduler.dart';
import 'package:memox/features/study/presentation/states/interval_span_state.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

// Handoff 16a, Interval preview: under 30 days in days, under a year in
// months (days / 30, rounded), from a year in years (one decimal, ".0"
// dropped).

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final vi = lookupAppLocalizations(const Locale('vi'));

  test('the three bands and their edges', () {
    expect(intervalSpanOf(1), const DaySpan(1));
    expect(intervalSpanOf(29), const DaySpan(29));
    expect(intervalSpanOf(30), const MonthSpan(1));
    expect(intervalSpanOf(44), const MonthSpan(1));
    expect(intervalSpanOf(45), const MonthSpan(2));
    expect(intervalSpanOf(364), const MonthSpan(12));
    expect(intervalSpanOf(365), const YearSpan(1));
    expect(intervalSpanOf(548), const YearSpan(1.5));
  });

  test('short and spoken forms, with the locale decimal', () {
    expect(en.studyIntervalShort(const DaySpan(6), 'en'), '6d');
    expect(en.studyIntervalShort(const MonthSpan(2), 'en'), '2mo');
    expect(en.studyIntervalShort(const YearSpan(1), 'en'), '1y');
    expect(en.studyIntervalShort(const YearSpan(1.5), 'en'), '1.5y');
    expect(vi.studyIntervalShort(const YearSpan(1.5), 'vi'), '1,5 năm');
    expect(en.studyIntervalLong(const DaySpan(1), 'en'), '1 day');
    expect(en.studyIntervalLong(const DaySpan(6), 'en'), '6 days');
    expect(en.studyIntervalLong(const MonthSpan(1), 'en'), '1 month');
    expect(en.studyIntervalLong(const YearSpan(1), 'en'), '1 year');
    expect(en.studyIntervalLong(const YearSpan(2.5), 'en'), '2.5 years');
  });

  test("the grades are the card screens' action names, in sm2's order", () {
    expect(Sm2Action.values.toSet(), sm2Scheduler.supportedActions);
    expect(Sm2Action.values, sm2Scheduler.supportedActions.toList());
    expect(
      [for (final action in Sm2Action.values) en.studyGrade(action)],
      ['Again', 'Hard', 'Good', 'Easy'],
    );
  });
}
