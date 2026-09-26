import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';

/// The platform side where there are no reminders: Web, and every platform
/// until BE-B5b adds Android's (reminders spec D7). It says so, and does
/// nothing else (BR-REMINDER-012).
final class UnsupportedReminderPlatformRepositoryImpl
    implements ReminderPlatformRepository {
  const UnsupportedReminderPlatformRepositoryImpl();

  @override
  Future<ReminderCapability> capability() async =>
      ReminderCapability.unsupported;

  @override
  Future<ReminderPermission> requestPermission() async =>
      ReminderPermission.denied;

  @override
  Future<Outcome<void, ReminderRejection>> schedule({
    required DateTime at,
  }) async => const Rejected(ReminderRejection.unsupported);

  @override
  Future<Outcome<void, ReminderRejection>> cancel() async =>
      const Rejected(ReminderRejection.unsupported);

  @override
  Future<Outcome<void, ReminderRejection>> show({
    required ReminderDigest digest,
    required LanguageChoice language,
  }) async => const Rejected(ReminderRejection.unsupported);
}
