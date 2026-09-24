import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/queue_plan_model.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

List<StudyCardFacts> _cards(
  List<String> ids, {
  Set<String> withExample = const {},
}) => [
  for (final id in ids)
    StudyCardFacts(cardId: id, hasExample: withExample.contains(id)),
];

List<String> _ids(List<StudyCardFacts> cards) => [
  for (final card in cards) card.cardId,
];

void main() {
  group('newCardsToLearn', () {
    final candidates = _cards(['c1', 'c2', 'c3', 'c4']);

    test('created takes the oldest card_limit cards (BR-STUDY-003, '
        'BR-STUDY-057)', () {
      const options = StudyOptions(
        cardLimit: 2,
        newCardOrder: NewCardOrder.created,
      );

      expect(_ids(newCardsToLearn(candidates, options, Random(1))), [
        'c1',
        'c2',
      ]);
    });

    test('random draws card_limit cards with the random source '
        '(BR-STUDY-057)', () {
      const options = StudyOptions(
        cardLimit: 2,
        newCardOrder: NewCardOrder.random,
      );

      final draws = {
        for (var seed = 0; seed < 20; seed++)
          (_ids(
            newCardsToLearn(candidates, options, Random(seed)),
          )..sort()).join(),
      };

      expect(draws.every((draw) => draw.length == 4), isTrue);
      expect(draws.length, greaterThan(1));
    });
  });

  group('shuffledUnlike', () {
    test('keeps every card once', () {
      for (var seed = 0; seed < 20; seed++) {
        final order = shuffledUnlike(
          ['a', 'b', 'c', 'd'],
          const [],
          Random(seed),
        );
        expect([...order]..sort(), ['a', 'b', 'c', 'd']);
      }
    });

    test('never repeats the order of the cards it shares with the queue '
        'before it (BR-STUDY-022, BR-STUDY-061)', () {
      for (var seed = 0; seed < 50; seed++) {
        expect(
          shuffledUnlike(['a', 'b', 'c'], ['a', 'b', 'c'], Random(seed)),
          isNot(['a', 'b', 'c']),
        );
        expect(shuffledUnlike(['a', 'c'], ['a', 'b', 'c', 'd'], Random(seed)), [
          'c',
          'a',
        ]);
      }
    });

    test('one shared card, or none, leaves the shuffle as it came', () {
      expect(shuffledUnlike(['a'], ['a'], Random(3)), ['a']);
      final orders = {
        for (var seed = 0; seed < 20; seed++)
          shuffledUnlike(['x', 'y'], ['a', 'b'], Random(seed)).join(),
      };
      expect(orders, {'xy', 'yx'});
    });
  });

  group('learningQueues', () {
    test('five cards with examples and five meanings run the whole '
        'eight_box chain, each stage in an order unlike the one before '
        '(IT-LEARN-001, IT-LEARN-004)', () {
      final ids = ['c1', 'c2', 'c3', 'c4', 'c5'];

      final queues = learningQueues(
        SchedulerType.eightBox,
        _cards(ids, withExample: ids.toSet()),
        distinctMeaningCount: 5,
        random: Random(2),
      );

      expect(
        [for (final queue in queues) queue.mode],
        [
          StudyMode.browse,
          StudyMode.match,
          StudyMode.guess,
          StudyMode.recall,
          StudyMode.fill,
        ],
      );
      for (final queue in queues) {
        expect([...queue.cardIds]..sort(), ids);
      }
      for (var i = 1; i < queues.length; i++) {
        expect(queues[i].cardIds, isNot(queues[i - 1].cardIds));
      }
    });

    test('a stage that does not run has no queue, and fill asks only the '
        'cards with an example (BR-MODE-009, BR-STUDY-071)', () {
      final queues = learningQueues(
        SchedulerType.eightBox,
        _cards(['c1', 'c2', 'c3'], withExample: {'c2'}),
        distinctMeaningCount: 3,
        random: Random(2),
      );

      expect(
        [for (final queue in queues) queue.mode],
        [StudyMode.browse, StudyMode.match, StudyMode.recall, StudyMode.fill],
      );
      expect(queues.last.cardIds, ['c2']);
    });

    test('an sm2 set runs browse, then self_assess (BR-MODE-004)', () {
      final queues = learningQueues(
        SchedulerType.sm2,
        _cards(['c1']),
        distinctMeaningCount: 1,
        random: Random(2),
      );

      expect(
        [for (final queue in queues) queue.mode],
        [StudyMode.browse, StudyMode.selfAssess],
      );
    });
  });

  group('reviewQueue', () {
    Outcome<StageQueue, StudyRejection> review(
      SchedulerType type,
      StudyMode mode, {
      DirectionChoice? direction,
      List<String> due = const ['c1', 'c2'],
    }) => reviewQueue(
      type,
      mode,
      direction: direction,
      dueCards: _cards(due),
      distinctMeaningCount: 2,
      random: Random(1),
    );

    StudyRejection? refusal(Outcome<StageQueue, StudyRejection> result) =>
        switch (result) {
          Rejected(:final reason) => reason,
          Ok() => null,
        };

    test('it checks the request before the cards: the mode, the direction, '
        'then the due cards and the stage (BR-STUDY-055, BR-MODE-018, '
        'BR-STUDY-054, BR-MODE-009)', () {
      expect(
        refusal(review(SchedulerType.sm2, StudyMode.browse, due: [])),
        StudyRejection.modeNotOffered,
      );
      expect(
        refusal(review(SchedulerType.sm2, StudyMode.selfAssess, due: [])),
        StudyRejection.directionRequired,
      );
      expect(
        refusal(
          review(
            SchedulerType.eightBox,
            StudyMode.recall,
            direction: DirectionChoice.mixed,
            due: [],
          ),
        ),
        StudyRejection.directionNotAllowed,
      );
      expect(
        refusal(review(SchedulerType.eightBox, StudyMode.fill, due: [])),
        StudyRejection.nothingDue,
      );
      expect(
        refusal(review(SchedulerType.eightBox, StudyMode.fill)),
        StudyRejection.modeUnavailable,
      );
    });

    test('round 1 keeps the due order, with one direction per card when the '
        'review takes one (BR-STUDY-002, BR-MODE-015)', () {
      final selfAssess = review(
        SchedulerType.sm2,
        StudyMode.selfAssess,
        direction: DirectionChoice.meaningToKorean,
        due: ['c2', 'c1'],
      );
      final recall = review(SchedulerType.eightBox, StudyMode.recall);

      final queue = (selfAssess as Ok<StageQueue, StudyRejection>).value;
      expect(queue.cardIds, ['c2', 'c1']);
      expect(queue.directions, [
        QuestionDirection.meaningToKorean,
        QuestionDirection.meaningToKorean,
      ]);
      expect(
        (recall as Ok<StageQueue, StudyRejection>).value.directions,
        isNull,
      );
    });
  });
}
