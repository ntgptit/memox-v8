import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-SETTINGS-001 step 2: the app-wide card limit and new-card order, for
/// the sessions opened after it (BR-SETTINGS-002, BR-SETTINGS-004).
final class SaveStudyDefaultsUseCase {
  const SaveStudyDefaultsUseCase(this._settings);

  final SettingsRepository _settings;

  Future<Outcome<void, SettingsRejection>> call({
    required StudyOptions options,
  }) => _settings.saveStudyDefaults(options: options);
}
