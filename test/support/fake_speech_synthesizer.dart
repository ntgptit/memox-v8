import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/core/speech/speech_synthesizer.dart';

/// Records what the session asked the engine to read (study speech spec
/// §8); [available] is what the "device" reports it can read.
final class FakeSpeechSynthesizer implements SpeechSynthesizer {
  FakeSpeechSynthesizer({this.available = const {}});

  final Set<String> available;

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
  Future<Set<String>> availableLanguageTags() async => available;
}
