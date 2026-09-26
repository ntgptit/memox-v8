import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';

/// What scheduling and delivering the reminder read of `app_settings`, at one
/// moment: `schema.md` keeps the last delivery in the same row so that it is
/// read together with the switch and the time.
final class ReminderSnapshot {
  const ReminderSnapshot({
    required this.reminder,
    required this.lastDeliveredAt,
    required this.language,
  });

  final ReminderSettings reminder;

  /// When the last digest was shown; null before the first
  /// (BR-REMINDER-004).
  final DateTime? lastDeliveredAt;

  /// The language the digest is written in (BR-SETTINGS-006).
  final LanguageChoice language;
}
