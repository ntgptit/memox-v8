import 'package:memox/core/speech/speech_language.dart';

/// What a session reads with (BR-STUDY-079, BR-STUDY-080): the app-wide
/// switch and the language in force for the deck's root.
final class SpeechSettings {
  const SpeechSettings({required this.isAutoPlay, required this.language});

  final bool isAutoPlay;
  final SpeechLanguage language;

  @override
  bool operator ==(Object other) =>
      other is SpeechSettings &&
      other.isAutoPlay == isAutoPlay &&
      other.language == language;

  @override
  int get hashCode => Object.hash(isAutoPlay, language);
}
