import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';

/// The values of the one `app_settings` row a person can set
/// (BR-SETTINGS-001): the study defaults, the theme, the language, the
/// daily reminder and the read-aloud switch.
final class AppSettingsEntity {
  const AppSettingsEntity({
    required this.studyDefaults,
    required this.theme,
    required this.language,
    required this.reminder,
    required this.isSpeechAutoPlay,
  });

  /// What a fresh database holds and what `Reset to defaults` returns to
  /// (BR-SETTINGS-008).
  static const defaults = AppSettingsEntity(
    studyDefaults: StudyOptions.defaults,
    theme: ThemeChoice.system,
    language: LanguageChoice.system,
    reminder: ReminderSettings.defaults,
    isSpeechAutoPlay: true,
  );

  final StudyOptions studyDefaults;
  final ThemeChoice theme;
  final LanguageChoice language;
  final ReminderSettings reminder;

  /// Whether a learning session reads a new card's term aloud
  /// (BR-SETTINGS-010); device-only.
  final bool isSpeechAutoPlay;
}
