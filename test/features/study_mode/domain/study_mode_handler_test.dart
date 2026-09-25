import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

List<StudyCardFacts> _cards(int count, {Set<int> withExample = const {}}) => [
  for (var i = 0; i < count; i++)
    StudyCardFacts(cardId: 'c$i', hasExample: withExample.contains(i)),
];

StageEligibility _eligibility(
  StudyMode mode,
  List<StudyCardFacts> cards, {
  int meanings = 5,
}) => mode.handler.eligibility(cards, distinctMeaningCount: meanings);

Matcher _runsOn(List<String> cardIds) =>
    isA<StageRuns>().having((runs) => runs.cardIds, 'cardIds', cardIds);

Matcher _skippedFor(ModeUnavailableReason reason) =>
    isA<StageSkipped>().having((skipped) => skipped.reason, 'reason', reason);

void main() {
  group('data conditions', () {
    test('browse, self_assess and recall ask every card', () {
      for (final mode in [
        StudyMode.browse,
        StudyMode.selfAssess,
        StudyMode.recall,
      ]) {
        expect(
          _eligibility(mode, _cards(2), meanings: 1),
          _runsOn(['c0', 'c1']),
        );
      }
    });

    test('fill asks only the cards with an example and is skipped without '
        'one (BR-STUDY-044, BR-STUDY-071; IT-LEARN-005)', () {
      expect(
        _eligibility(StudyMode.fill, _cards(3, withExample: {0, 2})),
        _runsOn(['c0', 'c2']),
      );
      expect(
        _eligibility(StudyMode.fill, _cards(3)),
        _skippedFor(ModeUnavailableReason.noExample),
      );
    });

    test('match needs two pairs: one card is its own answer (BR-STUDY-045; '
        'IT-LEARN-007)', () {
      expect(
        _eligibility(StudyMode.match, _cards(1)),
        _skippedFor(ModeUnavailableReason.tooFewPairs),
      );
      expect(_eligibility(StudyMode.match, _cards(2)), _runsOn(['c0', 'c1']));
    });

    test('guess needs five distinct meanings in its distractor source, not '
        'five cards (BR-STUDY-037, BR-STUDY-040; spec D5; IT-LEARN-006, '
        'IT-MODE-006, IT-MODE-015)', () {
      expect(
        _eligibility(StudyMode.guess, _cards(4), meanings: 4),
        _skippedFor(ModeUnavailableReason.tooFewMeanings),
      );
      expect(
        _eligibility(StudyMode.guess, _cards(1), meanings: 5),
        _runsOn(['c0']),
      );
    });
  });

  group('what a turn does to its row', () {
    RowStep step(StudyMode mode, {required bool lapsed, int answers = 0}) =>
        mode.handler.stepAfter(lapsed: lapsed, answersInSession: answers);

    test('a pass leaves the queue in every mode (BR-STUDY-007)', () {
      for (final mode in StudyMode.values) {
        expect(step(mode, lapsed: false), isA<Leave>());
      }
    });

    test('a forgotten self_assess card comes back after three other turns, '
        'up to three relearning turns, then leaves flagged (BR-STUDY-005, '
        'BR-STUDY-073; IT-LEARN-009)', () {
      for (final answers in [0, 1, 2]) {
        expect(
          step(StudyMode.selfAssess, lapsed: true, answers: answers),
          isA<ComeBack>().having((back) => back.afterTurns, 'afterTurns', 3),
        );
      }
      expect(
        step(StudyMode.selfAssess, lapsed: true, answers: 3),
        isA<LeaveAtCap>(),
      );
    });

    test('a wrong match stays on the board and joins the next round '
        '(BR-STUDY-062)', () {
      expect(step(StudyMode.match, lapsed: true), isA<StayAndEnroll>());
    });

    test('a wrong guess, recall or fill leaves its row and joins the next '
        'round, with no cap (BR-STUDY-059, BR-STUDY-069)', () {
      for (final mode in [StudyMode.guess, StudyMode.recall, StudyMode.fill]) {
        expect(step(mode, lapsed: true, answers: 12), isA<LeaveAndEnroll>());
      }
    });
  });
}
