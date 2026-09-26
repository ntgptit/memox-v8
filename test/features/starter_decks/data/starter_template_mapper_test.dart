import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/data/mappers/starter_template_mapper.dart';

const _card = {'front': 'hello', 'back': 'xin chào'};

Map<String, Object?> _template() => {
  'templateId': 'fixture.test',
  'version': 1,
  'locale': 'en',
  'title': 'Test template',
  'contentSource': 'Development fixture',
  'frontLanguage': 'en',
  'backLanguage': 'vi',
  'defaultScheduler': 'sm2',
  'decks': [
    {
      'name': 'Words',
      'decks': [
        {
          'name': 'Greetings',
          'cards': [
            {'front': 'hello', 'back': 'xin chào', 'hint': 'a greeting'},
          ],
        },
      ],
    },
    {
      'name': 'Travel',
      'cards': [
        {'front': 'ticket', 'back': 'vé'},
        {'front': 'map', 'back': 'bản đồ'},
      ],
    },
  ],
};

/// The template with [decks] as the root's sub-decks.
Map<String, Object?> _withDecks(List<Object?> decks) =>
    _template()..['decks'] = decks;

/// [levels] decks, one inside the other under the root; the last holds a
/// card.
Map<String, Object?> _nested(int levels) {
  Object? deck = {
    'name': 'Level $levels',
    'cards': [_card],
  };
  for (var level = levels - 1; level >= 1; level--) {
    deck = {
      'name': 'Level $level',
      'decks': [deck],
    };
  }
  return _withDecks([deck]);
}

void main() {
  test(
    'a template reads with its fields, its tree in order and its counts',
    () {
      final template = starterTemplateOf(_template())!;

      expect(template.templateId, 'fixture.test');
      expect(template.version, 1);
      expect(template.locale, 'en');
      expect(template.title, 'Test template');
      expect(template.contentSource, 'Development fixture');
      expect(template.frontLanguage, 'en');
      expect(template.backLanguage, 'vi');
      expect(template.suggestedScheduler, SchedulerType.sm2);
      expect(
        [for (final deck in template.decks) deck.name],
        ['Words', 'Travel'],
      );
      expect(template.decks.first.decks.single.cards.single.hint, 'a greeting');
      expect(template.decks.last.cards.last.back, 'bản đồ');
      expect(template.cardCount, 3);
      expect(template.subDeckCount, 3);
    },
  );

  test('a template without a field BR-STARTER-002 needs, or with a blank one, '
      'is left out (D6)', () {
    for (final field in [
      'templateId',
      'version',
      'locale',
      'title',
      'contentSource',
      'frontLanguage',
      'backLanguage',
      'defaultScheduler',
      'decks',
    ]) {
      expect(
        starterTemplateOf(_template()..remove(field)),
        isNull,
        reason: field,
      );
      expect(
        starterTemplateOf(_template()..[field] = '  '),
        isNull,
        reason: '$field blank',
      );
    }
  });

  test('a version below 1 or not a whole number, and a scheduler the app does '
      'not have, are left out (D6)', () {
    expect(starterTemplateOf(_template()..['version'] = 0), isNull);
    expect(starterTemplateOf(_template()..['version'] = 1.5), isNull);
    expect(
      starterTemplateOf(_template()..['defaultScheduler'] = 'leitner'),
      isNull,
    );
  });

  test('a deck with both sub-decks and cards, or neither, and cards at the top '
      'level are left out (D6)', () {
    expect(
      starterTemplateOf(
        _withDecks([
          {
            'name': 'Both',
            'decks': [
              {
                'name': 'Inner',
                'cards': [_card],
              },
            ],
            'cards': [_card],
          },
        ]),
      ),
      isNull,
    );
    expect(
      starterTemplateOf(
        _withDecks([
          {'name': 'Neither'},
        ]),
      ),
      isNull,
    );
    expect(
      starterTemplateOf(
        _withDecks([
          {'name': 'Empty', 'cards': <Object?>[]},
        ]),
      ),
      isNull,
    );
    expect(starterTemplateOf(_withDecks([])), isNull);
    expect(starterTemplateOf(_template()..['cards'] = [_card]), isNull);
  });

  test('a tree deeper than a deck may go is left out; the tenth level is the '
      'last (D6, BR-DECK-001)', () {
    expect(starterTemplateOf(_nested(9)), isNotNull);
    expect(starterTemplateOf(_nested(10)), isNull);
  });

  test('a title, a deck name or a card that breaks the deck and card rules is '
      'left out (D6)', () {
    Map<String, Object?> withCard(Map<String, Object?> card) => _withDecks([
      {
        'name': 'Deck',
        'cards': [card],
      },
    ]);

    expect(starterTemplateOf(_template()..['title'] = 'x' * 201), isNull);
    expect(
      starterTemplateOf(
        _withDecks([
          {
            'name': ' ',
            'cards': [_card],
          },
        ]),
      ),
      isNull,
    );
    expect(
      starterTemplateOf(
        _withDecks([
          {
            'name': 'x' * 201,
            'cards': [_card],
          },
        ]),
      ),
      isNull,
    );
    expect(starterTemplateOf(withCard({'front': ' ', 'back': 'b'})), isNull);
    expect(
      starterTemplateOf(withCard({'front': 'x' * 61, 'back': 'b'})),
      isNull,
    );
    expect(
      starterTemplateOf(withCard({'front': 'a', 'back': 'x' * 241})),
      isNull,
    );
    expect(starterTemplateOf(withCard({'front': 'a'})), isNull);
    expect(
      starterTemplateOf(withCard({'front': 'a', 'back': 'b', 'hint': 5})),
      isNull,
    );
    expect(
      starterTemplateOf(
        withCard({'front': 'a', 'back': 'b', 'example': 'x' * 241}),
      ),
      isNull,
    );
  });

  test('anything but an object is left out', () {
    expect(starterTemplateOf(null), isNull);
    expect(starterTemplateOf([_template()]), isNull);
    expect(starterTemplateOf('template'), isNull);
  });
}
