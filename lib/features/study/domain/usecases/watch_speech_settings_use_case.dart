import 'package:memox/features/settings/domain/models/speech_settings_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// What the session of [deckId] reads with, again on every change
/// (BR-STUDY-079, BR-STUDY-080): the app-wide switch and the language of
/// the deck's root. Null once the deck is gone.
final class WatchSpeechSettingsUseCase {
  const WatchSpeechSettingsUseCase(this._settings);

  final SettingsRepository _settings;

  Stream<SpeechSettings?> call({required String deckId}) =>
      _settings.watchSpeechSettings(deckId: deckId);
}
