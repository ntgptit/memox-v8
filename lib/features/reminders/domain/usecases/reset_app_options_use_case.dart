import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/domain/usecases/reconcile_reminder_use_case.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/usecases/reset_app_settings_use_case.dart';

/// Reset app options as the app runs it (UC-SETTINGS-001 A3): the settings
/// back to their defaults, then the pending reminder brought in line with
/// the stored one, which the reset turned off. The two run as one reminder
/// operation, so no Enable can land between them and leave "on" stored
/// after the reset was confirmed (DEV-218).
///
/// The reset's outcome is the result. A reset that fails leaves as its
/// `Failure` and touches no alarm. A reconcile that fails or is refused
/// after the reset landed is not an error of the reset: the next start or
/// resume reconciles again.
final class ResetAppOptionsUseCase {
  const ResetAppOptionsUseCase(this._reset, this._reconcile);

  final ResetAppSettingsUseCase _reset;
  final ReconcileReminderUseCase _reconcile;

  Future<Outcome<void, SettingsRejection>> call() async {
    final outcome = await _reset();
    if (outcome case Rejected()) return outcome;
    try {
      await _reconcile();
    } on Failure {
      // The reset landed; the alarm follows at the next start or resume.
    }
    return outcome;
  }
}
