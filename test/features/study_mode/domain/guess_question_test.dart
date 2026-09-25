import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study_mode/domain/models/guess_mode.dart';
import 'package:memox/features/study_mode/domain/models/round_preparation_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

// The five options of a guess question (graded modes spec §7.5, §7.7).

const _meanings = {
  'q': 'library',
  'a': 'kitchen',
  'b': 'school',
  'c': 'office',
  'd': 'classroom',
  'e': 'garden',
  'f': 'kitchen',
};

List<MeaningCard> _source(Map<String, String> meanings) => [
  for (final MapEntry(:key, :value) in meanings.entries)
    (cardId: key, meaningFolded: value),
];

const MeaningCard _asked = (cardId: 'q', meaningFolded: 'library');

void main() {
  final source = _source(_meanings);

  test('five options: the asked card once, and four other meanings '
      '(BR-STUDY-037, BR-STUDY-039; IT-MODE-005F)', () {
    for (var seed = 0; seed < 20; seed++) {
      final options = guessOptionsFor(_asked, source, Random(seed))!;
      expect(options, hasLength(5));
      expect(options.where((id) => id == 'q'), hasLength(1));
      expect({for (final id in options) _meanings[id]}, hasLength(5));
    }
  });

  test('a card with the asked meaning is never a distractor, whatever its '
      'text (BR-STUDY-039; IT-MODE-015)', () {
    final twin = [...source, (cardId: 'twin', meaningFolded: 'library')];
    for (var seed = 0; seed < 20; seed++) {
      expect(
        guessOptionsFor(_asked, twin, Random(seed)),
        isNot(contains('twin')),
      );
    }
  });

  test('no question below four meanings besides the asked one '
      '(BR-STUDY-040)', () {
    final few = _source({
      'q': 'library',
      'a': 'kitchen',
      'f': 'kitchen',
      'b': 'school',
      'c': 'office',
    });
    expect(guessOptionsFor(_asked, few, Random(1)), isNull);
  });

  test('a seed gives the same question whatever order the source comes in', () {
    expect(
      guessOptionsFor(_asked, source.reversed.toList(), Random(7)),
      guessOptionsFor(_asked, source, Random(7)),
    );
  });

  test('the options have a shuffle of their own: the right one moves '
      '(BR-STUDY-043)', () {
    final places = {
      for (var seed = 0; seed < 20; seed++)
        guessOptionsFor(_asked, source, Random(seed))!.indexOf('q'),
    };
    expect(places.length, greaterThan(1));
  });

  group('preparing a guess round (spec §7.7)', () {
    RoundRowFacts row(
      String id,
      int position, {
      bool isPending = true,
      int optionCount = 0,
    }) => RoundRowFacts(
      cardId: id,
      position: position,
      isPending: isPending,
      meaningSlot: null,
      optionCount: optionCount,
      meaningFolded: _meanings[id]!,
    );

    test('builds a question for each pending row that lacks its five '
        'options, and leaves the others (BR-STUDY-043)', () {
      final preparation = StudyMode.guess.handler.prepareRound(
        [
          row('q', 0),
          row('a', 1, optionCount: 5),
          row('b', 2, isPending: false),
        ],
        meaningSource: source,
        random: Random(1),
      );
      expect(preparation.questions.keys, ['q']);
      expect(preparation.questions['q'], hasLength(5));
      expect(preparation.meaningSlots, isEmpty);
    });

    test('a question that cannot be built is null, so what is left of it '
        'goes (BR-STUDY-040)', () {
      final preparation = StudyMode.guess.handler.prepareRound(
        [row('q', 0, optionCount: 4)],
        meaningSource: _source({'q': 'library', 'a': 'kitchen'}),
        random: Random(1),
      );
      expect(preparation.questions, {'q': null});
    });

    test('only guess asks with options, and the other modes but match '
        'prepare nothing', () {
      expect(
        [
          for (final mode in StudyMode.values)
            if (mode.handler.asksWithOptions) mode,
        ],
        [StudyMode.guess],
      );
      for (final mode in [
        StudyMode.browse,
        StudyMode.selfAssess,
        StudyMode.recall,
        StudyMode.fill,
      ]) {
        final preparation = mode.handler.prepareRound(
          [row('q', 0)],
          meaningSource: source,
          random: Random(1),
        );
        expect(preparation.isEmpty, isTrue, reason: mode.code);
      }
    });
  });
}
