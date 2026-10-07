import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/core/speech/speech_synthesizer.dart';

// What reaches the engine (spec §7): trimmed, never empty, never over
// Android's input limit.

void main() {
  test('a term is read trimmed', () {
    expect(speechTextOf('  abandon \n'), 'abandon');
  });

  test('a blank term is nothing to read', () {
    expect(speechTextOf(''), isNull);
    expect(speechTextOf('   \n'), isNull);
  });

  test('a term over the limit is cut at the limit', () {
    final long = 'a' * (maxSpeechInputLength + 10);
    expect(speechTextOf(long), hasLength(maxSpeechInputLength));
  });

  test('the silent synthesizer does nothing and reports no language', () async {
    const silent = SilentSpeechSynthesizer();
    await silent.speak('abandon', language: SpeechLanguage.enUs);
    await silent.stop();
    expect(await silent.availableLanguageTags(), isEmpty);
  });
}
