import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';

/// A call the reminder's use cases make of the platform.
enum PlatformCall { capability, requestPermission, schedule, cancel, show }

/// The operating system as the reminder's use cases see it, with the two
/// slots a real one has: at most one pending reminder, which a schedule
/// replaces (BR-REMINDER-010), and at most one notification on the shade,
/// which a show replaces (BR-REMINDER-004). Every call is recorded, so a test
/// measures what was asked of the platform instead of assuming it.
final class FakeReminderPlatform implements ReminderPlatformRepository {
  FakeReminderPlatform({
    this.capabilityValue = ReminderCapability.supported,
    this.permission = ReminderPermission.granted,
  });

  ReminderCapability capabilityValue;
  ReminderPermission permission;

  /// The calls the platform refuses, the way a failing plugin does.
  final Set<PlatformCall> refusing = {};

  /// Every call, in order.
  final List<PlatformCall> calls = [];

  /// The one pending reminder, if any.
  DateTime? pending;

  /// The one notification on the shade, if any.
  ReminderDigest? shown;

  /// The language [shown] was written in.
  LanguageChoice? shownIn;

  @override
  Future<ReminderCapability> capability() async {
    calls.add(PlatformCall.capability);
    return capabilityValue;
  }

  @override
  Future<ReminderPermission> requestPermission() async {
    calls.add(PlatformCall.requestPermission);
    return permission;
  }

  @override
  Future<Outcome<void, ReminderRejection>> schedule({
    required DateTime at,
  }) async {
    calls.add(PlatformCall.schedule);
    if (refusing.contains(PlatformCall.schedule)) {
      return const Rejected(ReminderRejection.couldNotSchedule);
    }
    pending = at;
    return const Ok(null);
  }

  @override
  Future<Outcome<void, ReminderRejection>> cancel() async {
    calls.add(PlatformCall.cancel);
    if (refusing.contains(PlatformCall.cancel)) {
      return const Rejected(ReminderRejection.couldNotCancel);
    }
    pending = null;
    shown = null;
    shownIn = null;
    return const Ok(null);
  }

  @override
  Future<Outcome<void, ReminderRejection>> show({
    required ReminderDigest digest,
    required LanguageChoice language,
  }) async {
    calls.add(PlatformCall.show);
    if (refusing.contains(PlatformCall.show)) {
      return const Rejected(ReminderRejection.couldNotShow);
    }
    shown = digest;
    shownIn = language;
    return const Ok(null);
  }
}
