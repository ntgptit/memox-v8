import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';

void main() {
  test('0 days from now is local midnight of today', () {
    final now = DateTime(2026, 3, 14, 21, 5);
    expect(dueAtLocalMidnight(now, 0), DateTime(2026, 3, 14));
  });

  test('crossing a month end lands on the first of the next month', () {
    final now = DateTime(2026, 1, 30, 10);
    expect(dueAtLocalMidnight(now, 3), DateTime(2026, 2, 2));
  });

  test('128 days (eight_box box 8) crosses a year end correctly', () {
    final now = DateTime(2026, 9, 23);
    // Sep 23 + 7 = Sep 30, + 31 (Oct) = 38, + 30 (Nov) = 68, + 31 (Dec) = 99,
    // + 29 = 128: January 29.
    expect(dueAtLocalMidnight(now, 128), DateTime(2027, 1, 29));
  });

  test('crossing a daylight-saving change still lands on local midnight (BR-STUDY-074)', () {
    // Europe and the US move their clocks in March 2026; adding 30 * 24 hours
    // there lands on 01:00 or 23:00. Run with TZ=Europe/Berlin to see it.
    final now = DateTime(2026, 3, 1, 9);
    expect(dueAtLocalMidnight(now, 30), DateTime(2026, 3, 31));
  });
}
