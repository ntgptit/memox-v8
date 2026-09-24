/// The scheduler a root deck uses (spec §5), stored as a stable text code.
enum SchedulerType {
  eightBox('eight_box'),
  sm2('sm2');

  const SchedulerType(this.code);

  /// The code `deck.scheduler_type`, `card_schedule.scheduler_type` and
  /// `review_log.scheduler_type` store (schema.md).
  final String code;

  /// The scheduler a stored [code] names. An unknown code is corrupt data,
  /// never a reason to fall back to a default.
  static SchedulerType fromCode(String code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    throw ArgumentError.value(code, 'code', 'unknown scheduler code');
  }
}
