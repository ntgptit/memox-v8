import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-SETTINGS-001 step 2: whether a learning session reads a new card's
/// term aloud, saved on the toggle (BR-SETTINGS-010).
final class SetSpeechAutoPlayUseCase {
  const SetSpeechAutoPlayUseCase(this._settings);

  final SettingsRepository _settings;

  Future<Outcome<void, SettingsRejection>> call({required bool isOn}) =>
      _settings.setSpeechAutoPlay(isOn: isOn);
}
