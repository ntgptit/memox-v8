import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-SETTINGS-001 (Local): a root deck's own card limit and new-card order,
/// for the sessions of its tree opened after it (BR-SETTINGS-003,
/// BR-STUDY-056).
final class SaveRootStudyOptionsUseCase {
  const SaveRootStudyOptionsUseCase(this._settings);

  final SettingsRepository _settings;

  Future<Outcome<void, SettingsRejection>> call({
    required String rootDeckId,
    required StudyOptions options,
  }) =>
      _settings.saveRootStudyOptions(rootDeckId: rootDeckId, options: options);
}
