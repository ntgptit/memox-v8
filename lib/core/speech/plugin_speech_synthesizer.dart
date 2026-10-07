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

  @override
  Future<void> speak(String text, {required SpeechLanguage language}) async {
    final toRead = speechTextOf(text);
    if (toRead == null) return;
    try {
      await _tts.stop();
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
  Future<Set<String>> availableLanguageTags() async {
    try {
      final languages = await _tts.getLanguages;
      if (languages is! List) return const {};
      return {for (final language in languages) language.toString()};
    } on Object catch (error, stackTrace) {
      appLogger.warning(
        'speech.languages_failed',
        category: LogCategory.ui,
        error: error,
        stackTrace: stackTrace,
      );
      return const {};
    }
  }
}
