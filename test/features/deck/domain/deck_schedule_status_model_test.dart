import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_schedule_status_model.dart';

void main() {
  final today = DateTime(2026, 9, 23);

  group('DeckScheduleStatus.of (BR-STUDY-067)', () {
    test('no Due card is notDue', () {
      expect(DeckScheduleStatus.of(null, today), DeckScheduleStatus.notDue);
    });
    test('the oldest Due card due today is dueToday', () {
      expect(DeckScheduleStatus.of(today, today), DeckScheduleStatus.dueToday);
    });
    test('the oldest Due card due before today is overdue', () {
      expect(
        DeckScheduleStatus.of(DateTime(2026, 9, 22), today),
        DeckScheduleStatus.overdue,
      );
    });
  });

  group('DeckScheduleStatus.overdueDays (BR-STUDY-067)', () {
    test('counts the local day boundaries crossed', () {
      expect(DeckScheduleStatus.overdueDays(DateTime(2026, 9, 20), today), 3);
    });
    test('is 0 when nothing is overdue', () {
      expect(DeckScheduleStatus.overdueDays(null, today), 0);
      expect(DeckScheduleStatus.overdueDays(today, today), 0);
    });
    test('counts calendar days, not hours / 24, across a clock change', () {
      // Europe moves its clocks on 2026-03-29: these two midnights are 47
      // hours apart there. Run with TZ=Europe/Berlin to see the difference.
      expect(
        DeckScheduleStatus.overdueDays(
          DateTime(2026, 3, 28),
          DateTime(2026, 3, 30),
        ),
        2,
      );
    });
  });
}
