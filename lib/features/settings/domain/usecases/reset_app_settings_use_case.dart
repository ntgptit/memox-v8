import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-SETTINGS-001 A3: every value back to its default after the person
/// confirms. Learning progress is not touched (BR-SETTINGS-008).
final class ResetAppSettingsUseCase {
  const ResetAppSettingsUseCase(this._settings);

  final SettingsRepository _settings;

  Future<Outcome<void, SettingsRejection>> call() =>
      _settings.resetToDefaults();
}
