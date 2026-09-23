import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';

/// The one of four states a card shows (BR-CARD-006): derived on read from
/// its schedule, never stored.
enum CardDisplayStatus {
  newCard,
  beginning,
  reviewing,
  mastered;

  // BR-CARD-008: `eight_box` boxes 1-3 are beginning, 4-7 reviewing; `sm2`
  // under 8 days is beginning. BR-SRS-013: mastered is box 8 or 128+ days.
  static const _reviewingFromBox = 4;
  static const _masteredBox = 8;
  static const _reviewingFromDays = 8;
  static const _masteredFromDays = 128;

  static CardDisplayStatus of(CardScheduleState state) {
    // BR-CARD-007: not learned yet is new, in both schedulers.
    if (state.learnedAt == null) return newCard;
    if (state.currentBox case final box?) {
      if (box >= _masteredBox) return mastered;
      return box >= _reviewingFromBox ? reviewing : beginning;
    }
    final days = state.intervalDays!;
    if (days >= _masteredFromDays) return mastered;
    return days >= _reviewingFromDays ? reviewing : beginning;
  }
}
