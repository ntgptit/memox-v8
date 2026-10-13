import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// The three learned display states of BR-CARD-008 over a `card_schedule`
/// row, as the SQL the `.drift` queries take through their `$` placeholders
/// (flutter-drift skill, level 2): the SQL copy of the thresholds
/// `CardDisplayStatus` holds in Dart (DEV-211), which
/// `card_status_counts_parity_test.dart` keeps equal. `CardDueSql.isNew` is
/// the fourth state. A box row has no `interval_days` and an SM-2 row no
/// `current_box`, so each side's comparison is NULL and the OR takes the
/// other.
final class CardStatusSql {
  CardStatusSql._();

  // BR-CARD-008: boxes 1-3 are beginning, 4-7 reviewing; under 8 days is
  // beginning, 8 to 127 reviewing. BR-SRS-013: mastered is box 8 or 128+
  // days.
  static const _reviewingFromBox = 4;
  static const _masteredBox = 8;
  static const _reviewingFromDays = 8;
  static const _masteredFromDays = 128;

  static Expression<bool> _isLearned(CardScheduleTable s) =>
      s.learnedAt.isNotNull();

  /// Learned, in a box under 4 or under 8 days.
  static Expression<bool> isBeginning(CardScheduleTable s) =>
      _isLearned(s) &
      (s.currentBox.isSmallerThanValue(_reviewingFromBox) |
          s.intervalDays.isSmallerThanValue(_reviewingFromDays));

  /// Learned, in boxes 4 to 7 or from 8 to 127 days.
  static Expression<bool> isReviewing(CardScheduleTable s) =>
      _isLearned(s) &
      ((s.currentBox.isBiggerOrEqualValue(_reviewingFromBox) &
              s.currentBox.isSmallerThanValue(_masteredBox)) |
          (s.intervalDays.isBiggerOrEqualValue(_reviewingFromDays) &
              s.intervalDays.isSmallerThanValue(_masteredFromDays)));

  /// Learned, at box 8 or 128+ days (BR-SRS-013).
  static Expression<bool> isMastered(CardScheduleTable s) =>
      _isLearned(s) &
      (s.currentBox.isBiggerOrEqualValue(_masteredBox) |
          s.intervalDays.isBiggerOrEqualValue(_masteredFromDays));
}
