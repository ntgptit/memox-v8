import 'package:flutter_tts/flutter_tts.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/core/speech/speech_synthesizer.dart';

/// [SpeechSynthesizer] on the device engine: the one file that imports
/// `flutter_tts` (guard `memox_v8.architecture.tts_plugin_has_one_door`).
/// Every call is wrapped: a failing engine is a warning in the log, never
/// an error in the session (BR-STUDY-081). The text is never logged.
final class PluginSpeechSynthesizer implements SpeechSynthesizer {
  PluginSpeechSynthesizer({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  /// What Android's `setLanguage` answers when the engine has the language
  /// (`TextToSpeech.LANG_AVAILABLE` and above); 0 when it does not.
  static const _languageAvailable = 1;

  /// Bumped by every `speak` and `stop`: a reading whose generation is stale
  /// by the time its engine calls return hands the engine nothing, so a
  /// `stop` issued meanwhile is never overtaken (BR-STUDY-082, D10).
  int _generation = 0;

  @override
  Future<void> speak(String text, {required SpeechLanguage language}) async {
    final toRead = speechTextOf(text);
    final generation = ++_generation;
    try {
      await _tts.stop();
      // A blank term reads nothing, but the last reading still stops.
      if (toRead == null || generation != _generation) return;
      // Before every reading (spec §7): the plugin may rebind its engine,
      // which starts in its default locale.
      final answer = await _tts.setLanguage(language.tag);
      if (answer != _languageAvailable) {
        // D5 offers languages the device lacks: read nothing rather than the
        // term in another voice, and say so (BR-STUDY-081).
        appLogger.warning(
          'speech.language_unavailable',
          category: LogCategory.ui,
          context: {'language': language.tag, 'answer': answer},
        );
        return;
      }
      if (generation != _generation) return;
      await _tts.speak(toRead);
    } on Object catch (error, stackTrace) {
      appLogger.warning(
        'speech.speak_failed',
        category: LogCategory.ui,
        error: error,
        stackTrace: stackTrace,
        context: {'language': language.tag},
      );
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    try {
      await _tts.stop();
    } on Object catch (error, stackTrace) {
      appLogger.warning(
        'speech.stop_failed',
        category: LogCategory.ui,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<bool> isLanguageAvailable(SpeechLanguage language) async {
    try {
      // The plugin's own test, the one its `setLanguage` applies, so the
      // mark on screen agrees with what `speak` will do.
      return await _tts.isLanguageAvailable(language.tag) != false;
    } on Object catch (error, stackTrace) {
      appLogger.warning(
        'speech.languages_failed',
        category: LogCategory.ui,
        error: error,
        stackTrace: stackTrace,
        context: {'language': language.tag},
      );
      return true;
    }
  }
}
