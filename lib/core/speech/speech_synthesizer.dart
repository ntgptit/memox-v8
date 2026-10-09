import 'package:memox/core/speech/speech_language.dart';

/// Android's `TextToSpeech.getMaxSpeechInputLength()`: longer input is
/// refused by the engine.
const int maxSpeechInputLength = 4000;

/// [text] as it is handed to the engine: trimmed and capped at
/// [maxSpeechInputLength]; null when nothing is left to read.
String? speechTextOf(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.length <= maxSpeechInputLength) return trimmed;
  return trimmed.substring(0, maxSpeechInputLength);
}

/// Reads text aloud through the device (study speech spec §7). The one
/// implementation on a device is `PluginSpeechSynthesizer`, the only file
/// that imports `flutter_tts` (guard `tts_plugin_has_one_door`); tests use a
/// fake. Nothing here throws: a failure is logged (BR-STUDY-081).
abstract interface class SpeechSynthesizer {
  /// Reads [text] in [language], stopping what is being read first
  /// (BR-STUDY-082). Returns once the engine has taken the text, not once
  /// it has finished reading.
  Future<void> speak(String text, {required SpeechLanguage language});

  /// Stops what is being read, if anything.
  Future<void> stop();

  /// Whether a reading in [language] would be heard: false only when the
  /// engine answers that it lacks the language, the same answer `speak`
  /// acts on; true when it has it or cannot say (spec D5).
  Future<bool> isLanguageAvailable(SpeechLanguage language);
}

/// No engine: every platform but Android, and the host running the tests.
final class SilentSpeechSynthesizer implements SpeechSynthesizer {
  const SilentSpeechSynthesizer();

  @override
  Future<void> speak(String text, {required SpeechLanguage language}) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<bool> isLanguageAvailable(SpeechLanguage language) async => true;
}
