import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

final _learnedAt = DateTime(2026, 9, 1);

CardScheduleState _box(int box) => CardScheduleState.initial(
  SchedulerType.eightBox,
  generation: 1,
).copyWith(learnedAt: _learnedAt, currentBox: box);

CardScheduleState _interval(int days) => CardScheduleState.initial(
  SchedulerType.sm2,
  generation: 1,
).copyWith(learnedAt: _learnedAt, intervalDays: days);

void main() {
  test('an unlearned card is new, whatever its values (BR-CARD-007)', () {
    expect(
      CardDisplayStatus.of(
        CardScheduleState.initial(SchedulerType.eightBox, generation: 1),
      ),
      CardDisplayStatus.newCard,
    );
    expect(
      CardDisplayStatus.of(
        CardScheduleState.initial(SchedulerType.sm2, generation: 1),
      ),
      CardDisplayStatus.newCard,
    );
  });

  test('eight_box: boxes 1-3 beginning, 4-7 reviewing, 8 mastered (BR-CARD-008, BR-SRS-013)', () {
    expect(CardDisplayStatus.of(_box(1)), CardDisplayStatus.beginning);
    expect(CardDisplayStatus.of(_box(3)), CardDisplayStatus.beginning);
    expect(CardDisplayStatus.of(_box(4)), CardDisplayStatus.reviewing);
    expect(CardDisplayStatus.of(_box(7)), CardDisplayStatus.reviewing);
    expect(CardDisplayStatus.of(_box(8)), CardDisplayStatus.mastered);
  });

  test('sm2: under 8 days beginning, 8-127 reviewing, 128 and up mastered (BR-CARD-008, BR-SRS-013)', () {
    expect(CardDisplayStatus.of(_interval(7)), CardDisplayStatus.beginning);
    expect(CardDisplayStatus.of(_interval(8)), CardDisplayStatus.reviewing);
    expect(CardDisplayStatus.of(_interval(127)), CardDisplayStatus.reviewing);
    expect(CardDisplayStatus.of(_interval(128)), CardDisplayStatus.mastered);
  });
}
