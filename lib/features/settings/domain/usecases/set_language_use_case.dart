import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-SETTINGS-001 step 5: the language, saved on the tap (BR-SETTINGS-006).
final class SetLanguageUseCase {
  const SetLanguageUseCase(this._settings);

  final SettingsRepository _settings;

  Future<Outcome<void, SettingsRejection>> call({
    required LanguageChoice language,
  }) => _settings.setLanguage(language: language);
}
