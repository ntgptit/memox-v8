import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study_mode/domain/models/match_mode.dart';
import 'package:memox/features/study_mode/domain/models/round_preparation_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

// The boards of a match round and the order of their meanings
// (BR-STUDY-049; graded modes spec D7, §7.6, §7.7).

void main() {
  test('a board of two or more pairs never keeps the order of its terms', () {
    for (final pairs in [2, 3, 5]) {
      for (var seed = 0; seed < 50; seed++) {
        final slots = meaningSlotsFor(pairs, Random(seed));
        expect(slots.toSet(), {for (var i = 0; i < pairs; i++) i});
        expect(slots, isNot([for (var i = 0; i < pairs; i++) i]));
      }
    }
  });

  test('one pair takes slot 0', () {
    expect(meaningSlotsFor(1, Random(1)), [0]);
  });

  test('a board is five positions of the round', () {
    expect(
      [
        for (final position in [0, 4, 5, 9, 10]) matchBoardOf(position),
      ],
      [0, 0, 1, 1, 2],
    );
  });

  group('preparing a match round', () {
    RoundRowFacts row(
      String id,
      int position, {
      int? slot,
      bool isPending = true,
    }) => RoundRowFacts(
      cardId: id,
      position: position,
      isPending: isPending,
      meaningSlot: slot,
      optionCount: 0,
      meaningFolded: 'meaning $id',
    );

    test('each board gets its own slots, its matched pairs too', () {
      final rows = [
        for (var i = 0; i < 7; i++) row('c$i', i, isPending: i != 2),
      ];
      final preparation = StudyMode.match.handler.prepareRound(
        rows,
        meaningSource: const [],
        random: Random(3),
      );
      final slots = preparation.meaningSlots;
      expect(slots.keys.toSet(), {for (var i = 0; i < 7; i++) 'c$i'});
      expect({for (var i = 0; i < 5; i++) slots['c$i']}, {0, 1, 2, 3, 4});
      expect({slots['c5'], slots['c6']}, {0, 1});
      expect(preparation.questions, isEmpty);
    });

    test('a board that has its slots is left as it is (spec D8)', () {
      final preparation = StudyMode.match.handler.prepareRound(
        [row('a', 0, slot: 1), row('b', 1, slot: 0), row('c', 5), row('d', 6)],
        meaningSource: const [],
        random: Random(3),
      );
      expect(preparation.meaningSlots.keys.toSet(), {'c', 'd'});
    });
  });
}
