import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/features/settings/data/mappers/study_config_mapper.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';

// The JSON a root deck keeps its own study options in (spec D5).

void main() {
  test('the options a save writes read back the same', () {
    const options = StudyOptions(
      cardLimit: 35,
      newCardOrder: NewCardOrder.random,
      speechLanguage: SpeechLanguage.koKr,
    );

    final studyConfig = studyConfigOf(options);
    final read = studyOptionsOf(studyConfig);

    expect(
      studyConfig,
      '{"card_limit":35,"new_card_order":"random","tts_language":"ko-KR"}',
    );
    expect(read?.cardLimit, 35);
    expect(read?.newCardOrder, NewCardOrder.random);
    expect(read?.speechLanguage, SpeechLanguage.koKr);
  });

  test('an override written before speech reads in the default language '
      '(spec D6)', () {
    final read = studyOptionsOf('{"card_limit":20,"new_card_order":"created"}');

    expect(read?.speechLanguage, SpeechLanguage.defaultLanguage);
  });

  for (final (shape, studyConfig) in [
    (
      'a tts_language that is a number',
      '{"card_limit":20,"new_card_order":"created","tts_language":7}',
    ),
    (
      'a tts_language the app does not know',
      '{"card_limit":20,"new_card_order":"created","tts_language":"xx-XX"}',
    ),
  ]) {
    test('$shape cannot be read (spec D6)', () {
      expect(studyOptionsOf(studyConfig), isNull);
    });
  }

  test('both bounds of the card limit read back (BR-STUDY-003)', () {
    expect(
      studyOptionsOf('{"card_limit":1,"new_card_order":"created"}')?.cardLimit,
      1,
    );
    expect(
      studyOptionsOf('{"card_limit":200,"new_card_order":"created"}')
          ?.cardLimit,
      200,
    );
  });

  test('a key the app does not know is ignored', () {
    final read = studyOptionsOf(
      '{"card_limit":20,"new_card_order":"created","review_order":"due"}',
    );

    expect(read?.cardLimit, 20);
    expect(read?.newCardOrder, NewCardOrder.created);
  });

  for (final (shape, studyConfig) in [
    ('not JSON', 'card_limit=20'),
    ('empty', ''),
    ('not an object', '[20, "created"]'),
    ('missing card_limit', '{"new_card_order":"created"}'),
    ('missing new_card_order', '{"card_limit":20}'),
    (
      'a card_limit that is text',
      '{"card_limit":"20","new_card_order":"created"}',
    ),
    (
      'a fractional card_limit',
      '{"card_limit":20.5,"new_card_order":"created"}',
    ),
    ('a null card_limit', '{"card_limit":null,"new_card_order":"created"}'),
    ('a card_limit of 0', '{"card_limit":0,"new_card_order":"created"}'),
    ('a card_limit of 201', '{"card_limit":201,"new_card_order":"created"}'),
    (
      'an unknown new_card_order',
      '{"card_limit":20,"new_card_order":"shuffled"}',
    ),
    (
      'a new_card_order that is a number',
      '{"card_limit":20,"new_card_order":1}',
    ),
  ]) {
    test('an override with $shape cannot be read (D5)', () {
      expect(studyOptionsOf(studyConfig), isNull);
    });
  }
}
