import 'package:memox/features/reminders/domain/models/reminder_status_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-REMINDER-001 step 1: the reminder screen, again after every save. The
/// platform's capability is read once; a settings read that fails reaches the
/// stream as its `Failure` (E7).
final class WatchReminderUseCase {
  const WatchReminderUseCase(this._settings, this._platform);

  final SettingsRepository _settings;
  final ReminderPlatformRepository _platform;

  Stream<ReminderStatus> call() async* {
    final capability = await _platform.capability();
    yield* _settings.watchAppSettings().map(
      (settings) =>
          ReminderStatus(capability: capability, reminder: settings.reminder),
    );
  }
}
