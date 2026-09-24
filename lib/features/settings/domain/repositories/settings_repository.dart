import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';

/// The one implementation is `SettingsRepositoryImpl` (data layer). The
/// contract exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
abstract interface class SettingsRepository {
  /// The one `app_settings` row, again after every save (BR-SETTINGS-001).
  Stream<AppSettingsEntity> watchAppSettings();

  /// The app-wide study defaults. It never writes a root's override
  /// (BR-SETTINGS-002), and a session already open keeps its limit
  /// (BR-SETTINGS-004).
  Future<Outcome<void, SettingsRejection>> saveStudyDefaults({
    required StudyOptions options,
  });

  Future<Outcome<void, SettingsRejection>> setTheme({
    required ThemeChoice theme,
  });

  Future<Outcome<void, SettingsRejection>> setLanguage({
    required LanguageChoice language,
  });

  /// The four values a person can set back to their defaults, and nothing
  /// else (BR-SETTINGS-008).
  Future<Outcome<void, SettingsRejection>> resetToDefaults();
}
