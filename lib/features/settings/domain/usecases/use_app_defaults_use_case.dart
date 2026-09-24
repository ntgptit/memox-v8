import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-SETTINGS-001 A1 and E4: `Use app defaults` on a root deck removes its
/// override, so its tree studies with the app-wide defaults again.
final class UseAppDefaultsUseCase {
  const UseAppDefaultsUseCase(this._settings);

  final SettingsRepository _settings;

  Future<Outcome<void, SettingsRejection>> call({required String rootDeckId}) =>
      _settings.clearRootStudyOptions(rootDeckId: rootDeckId);
}
