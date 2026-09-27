import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';

/// The operating system's side of the reminder, and the one place that may
/// reach a notification plugin: its types are the app's own, and no call
/// throws, as a platform error comes back as a typed reason
/// (BR-REMINDER-012, UC-REMINDER-001 E3).
///
/// `reminderPlatformRepositoryProvider` picks the implementation:
/// `UnsupportedReminderPlatformRepositoryImpl` on every platform until
/// BE-B5b adds Android's (reminders spec D6, D7).
abstract interface class ReminderPlatformRepository {
  /// Whether this platform can deliver the reminder at all
  /// (BR-REMINDER-012).
  Future<ReminderCapability> capability();

  /// Asks for the notification permission, and only when called: after the
  /// person turned the reminder on (BR-REMINDER-011). `granted` at once
  /// where no permission exists; a failure to ask is `denied`.
  Future<ReminderPermission> requestPermission();

  /// One inexact reminder at [at], replacing the pending one, so that at most
  /// one is ever pending (BR-REMINDER-009, BR-REMINDER-010). A refusal is
  /// `couldNotSchedule`.
  Future<Outcome<void, ReminderRejection>> schedule({required DateTime at});

  /// Removes the pending reminder and the notification shown. Nothing to
  /// remove is `Ok`; a refusal is `couldNotCancel`.
  Future<Outcome<void, ReminderRejection>> cancel();

  /// Shows [digest] as the day's one notification, under one fixed id that
  /// replaces the day before's (BR-REMINDER-004), written in [language] from
  /// the digest alone (BR-REMINDER-005). A tap opens Study Home
  /// (BR-REMINDER-008). A refusal is `couldNotShow`.
  Future<Outcome<void, ReminderRejection>> show({
    required ReminderDigest digest,
    required LanguageChoice language,
  });
}
