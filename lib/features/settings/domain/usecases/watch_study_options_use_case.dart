import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-SETTINGS-001 A1: the study options a deck studies with and where they
/// come from, again on every change, and deckNotFound once the deck is gone
/// (BR-STUDY-056, IT-STUDY-013).
final class WatchStudyOptionsUseCase {
  const WatchStudyOptionsUseCase(this._settings);

  final SettingsRepository _settings;

  Stream<Outcome<EffectiveStudyOptions, SettingsRejection>> call({
    required String deckId,
  }) => _settings
      .watchStudyOptions(deckId: deckId)
      .map<Outcome<EffectiveStudyOptions, SettingsRejection>>(
        (effective) => switch (effective) {
          final EffectiveStudyOptions effective => Ok(effective),
          null => const Rejected(SettingsRejection.deckNotFound),
        },
      );
}
