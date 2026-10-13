import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/speech/speech_language.dart';

// Study speech spec §4, D5: the fixed list and its tags.

void main() {
  test('every language has a distinct BCP-47 tag', () {
    final tags = SpeechLanguage.values.map((l) => l.tag).toSet();
    expect(tags, hasLength(SpeechLanguage.values.length));
    for (final tag in tags) {
      expect(tag, matches(RegExp(r'^[a-z]{2}-[A-Z]{2}$')), reason: tag);
    }
  });

  test('the default is en-US', () {
    expect(SpeechLanguage.defaultLanguage, SpeechLanguage.enUs);
    expect(SpeechLanguage.enUs.tag, 'en-US');
  });

  test('fromTag reads every tag back and knows nothing else', () {
    for (final language in SpeechLanguage.values) {
      expect(SpeechLanguage.fromTag(language.tag), language);
    }
    expect(SpeechLanguage.fromTag('en_US'), isNull);
    expect(SpeechLanguage.fromTag('xx-XX'), isNull);
    expect(SpeechLanguage.fromTag(null), isNull);
  });
}
