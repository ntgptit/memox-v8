import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-SETTINGS-001 step 2: the app-wide card limit, new-card order and
/// speech language, for the sessions opened after it (BR-SETTINGS-002,
/// BR-SETTINGS-004, BR-SETTINGS-009).
final class SaveStudyDefaultsUseCase {
  const SaveStudyDefaultsUseCase(this._settings);

  final SettingsRepository _settings;

  Future<Outcome<void, SettingsRejection>> call({
    int? cardLimit,
    NewCardOrder? newCardOrder,
    SpeechLanguage? speechLanguage,
  }) => _settings.saveStudyDefaults(
    cardLimit: cardLimit,
    newCardOrder: newCardOrder,
    speechLanguage: speechLanguage,
  );
}
