import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/core/speech/speech_synthesizer.dart';

/// Records what the session asked the engine to read (study speech spec
/// §8); [available] is the tags the "device" can read, or null for an
/// engine that cannot say (which marks nothing).
final class FakeSpeechSynthesizer implements SpeechSynthesizer {
  FakeSpeechSynthesizer({this.available});

  final Set<String>? available;

  /// Every `speak`, in order: the text and its language.
  final spoken = <(String, SpeechLanguage)>[];

  /// How many times `stop` was called.
  var stops = 0;

  @override
  Future<void> speak(String text, {required SpeechLanguage language}) async {
    spoken.add((text, language));
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<bool> isLanguageAvailable(SpeechLanguage language) async =>
      available?.contains(language.tag) ?? true;
}
