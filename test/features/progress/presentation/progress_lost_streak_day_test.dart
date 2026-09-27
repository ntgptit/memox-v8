import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_streak_widget.dart';

// A lost streak's note names its last day (FE-A9 C8), counted on calendar
// dates. Run under a zone with a clock change (TZ=Europe/Berlin) to see the
// spring change of 29 March 2026.

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  test('six calendar days back is a weekday, seven is a date, across a '
      'spring clock change', () {
    final today = DateTime(2026, 3, 31);

    expect(
      progressLostStreakDay(
        today: today,
        last: DateTime(2026, 3, 25),
        locale: 'en',
      ),
      'Wednesday',
    );
    expect(
      progressLostStreakDay(
        today: today,
        last: DateTime(2026, 3, 24),
        locale: 'en',
      ),
      'Mar 24',
    );
  });
}
