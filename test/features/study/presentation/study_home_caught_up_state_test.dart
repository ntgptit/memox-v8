import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/presentation/states/study_home_caught_up_state.dart';

// Screen 13's caught-up body names when the next card falls due, on the
// local day (FE-A8 S2, BR-STUDY-074).

void main() {
  final now = DateTime(2026, 9, 24, 21, 30);

  test('no next due date: every card is simply resting', () {
    expect(caughtUpWhenOf(null, now), isA<CaughtUpResting>());
  });

  test('any time on the next local day is tomorrow', () {
    expect(caughtUpWhenOf(DateTime(2026, 9, 25), now), isA<CaughtUpTomorrow>());
    expect(
      caughtUpWhenOf(DateTime(2026, 9, 25, 23, 59), now),
      isA<CaughtUpTomorrow>(),
    );
  });

  test('from the day after tomorrow on, the day is named', () {
    final when = caughtUpWhenOf(DateTime(2026, 9, 26), now);
    expect(when, isA<CaughtUpOnDay>());
    expect((when as CaughtUpOnDay).day, DateTime(2026, 9, 26));
  });

  test('later today, which a caught-up snapshot never holds, reads as '
      'tomorrow rather than a past day', () {
    expect(
      caughtUpWhenOf(DateTime(2026, 9, 24, 23), now),
      isA<CaughtUpTomorrow>(),
    );
  });
}
