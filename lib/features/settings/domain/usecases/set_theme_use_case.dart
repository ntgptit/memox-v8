import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-SETTINGS-001 step 4: the theme, saved on the tap (BR-SETTINGS-005).
final class SetThemeUseCase {
  const SetThemeUseCase(this._settings);

  final SettingsRepository _settings;

  Future<Outcome<void, SettingsRejection>> call({required ThemeChoice theme}) =>
      _settings.setTheme(theme: theme);
}
