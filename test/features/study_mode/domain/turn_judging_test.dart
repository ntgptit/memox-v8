import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/eight_box_scheduler.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/sm2_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

// Each mode judges the person's real input as a pure function of the answer
// and the facts the session reads (graded modes spec §7).

const _card = TurnCard(cardId: 'c1', frontFolded: 'công', backFolded: 'work');

TurnContext _context({
  bool isRevealed = false,
  bool isHintShown = false,
  List<String>? options,
  Map<String, String> board = const {},
}) => TurnContext(
  card: _card,
  isRevealed: isRevealed,
  isHintShown: isHintShown,
  guessOptionIds: options,
  boardMeanings: board,
);

Outcome<TurnVerdict, StudyModeRejection> _judge(
  StudyMode mode,
  StudyAnswer answer, [
  TurnContext? context,
]) => mode.handler.judge(answer, context ?? _context(), eightBoxScheduler);

Matcher _refusedWith(StudyModeRejection reason) =>
    isA<Rejected<TurnVerdict, StudyModeRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

Matcher _verdict({
  required Object? action,
  bool? isCorrect,
  OutcomeReason? outcomeReason,
  int? comparisonVersion,
  bool? usedHint,
  String? takesMeaningSlotOf,
}) => isA<Ok<TurnVerdict, StudyModeRejection>>().having(
  (ok) => ok.value,
  'verdict',
  isA<TurnVerdict>()
      .having((verdict) => verdict.action, 'action', action)
      .having((verdict) => verdict.isCorrect, 'isCorrect', isCorrect)
      .having(
        (verdict) => verdict.outcomeReason,
        'outcomeReason',
        outcomeReason,
      )
      .having(
        (verdict) => verdict.comparisonVersion,
        'comparisonVersion',
        comparisonVersion,
      )
      .having((verdict) => verdict.usedHint, 'usedHint', usedHint)
      .having(
        (verdict) => verdict.takesMeaningSlotOf,
        'takesMeaningSlotOf',
        takesMeaningSlotOf,
      ),
);

void main() {
  group('fill', () {
    test('folds the typed term and compares it with front_folded: spaces and '
        'case fall away, accents stay (BR-STUDY-026; IT-MODE-010)', () {
      expect(
        _judge(StudyMode.fill, const FillAnswer('  cÔnG  ')),
        _verdict(
          action: EightBoxAction.remembered,
          isCorrect: true,
          comparisonVersion: 1,
          usedHint: false,
        ),
      );
      expect(
        _judge(StudyMode.fill, const FillAnswer('cong')),
        _verdict(
          action: EightBoxAction.forgotten,
          isCorrect: false,
          comparisonVersion: 1,
          usedHint: false,
        ),
      );
    });

    test('a blank answer is refused, so it records nothing (BR-STUDY-029)', () {
      for (final typed in ['', '   ', '\n\t ']) {
        expect(
          _judge(StudyMode.fill, FillAnswer(typed)),
          _refusedWith(StudyModeRejection.emptyAnswer),
        );
      }
    });

    test('a shown hint rides on the turn and changes nothing else '
        '(BR-STUDY-028; IT-MODE-011)', () {
      expect(
        _judge(
          StudyMode.fill,
          const FillAnswer('nope'),
          _context(isHintShown: true),
        ),
        _verdict(
          action: EightBoxAction.forgotten,
          isCorrect: false,
          comparisonVersion: 1,
          usedHint: true,
        ),
      );
      expect(
        _judge(
          StudyMode.fill,
          const FillAnswer('Công'),
          _context(isHintShown: true),
        ),
        _verdict(
          action: EightBoxAction.remembered,
          isCorrect: true,
          comparisonVersion: 1,
          usedHint: true,
        ),
      );
    });
  });

  group('recall', () {
    test('a self-assessment needs the answer revealed, then records the '
        "person's choice (BR-STUDY-065)", () {
      for (final outcome in [RecallOutcome.remembered, RecallOutcome.forgot]) {
        expect(
          _judge(StudyMode.recall, RecallAnswer(outcome)),
          _refusedWith(StudyModeRejection.notRevealed),
        );
      }
      expect(
        _judge(
          StudyMode.recall,
          const RecallAnswer(RecallOutcome.remembered),
          _context(isRevealed: true),
        ),
        _verdict(action: EightBoxAction.remembered, isCorrect: true),
      );
      expect(
        _judge(
          StudyMode.recall,
          const RecallAnswer(RecallOutcome.forgot),
          _context(isRevealed: true),
        ),
        _verdict(action: EightBoxAction.forgotten, isCorrect: false),
      );
    });

    test('a timeout records wrong with its reason, and never once the answer '
        'is revealed (BR-STUDY-032 to BR-STUDY-034)', () {
      expect(
        _judge(StudyMode.recall, const RecallAnswer(RecallOutcome.timedOut)),
        _verdict(
          action: EightBoxAction.forgotten,
          isCorrect: false,
          outcomeReason: OutcomeReason.timeout,
        ),
      );
      expect(
        _judge(
          StudyMode.recall,
          const RecallAnswer(RecallOutcome.timedOut),
          _context(isRevealed: true),
        ),
        _refusedWith(StudyModeRejection.alreadyRevealed),
      );
      expect(OutcomeReason.timeout.code, 'timeout');
    });
  });

  group('guess', () {
    const options = ['d1', 'c1', 'd2', 'd3', 'd4'];

    test('an option is judged by its card id (BR-STUDY-041)', () {
      expect(
        _judge(
          StudyMode.guess,
          const GuessAnswer('c1'),
          _context(options: options),
        ),
        _verdict(action: EightBoxAction.remembered, isCorrect: true),
      );
      expect(
        _judge(
          StudyMode.guess,
          const GuessAnswer('d3'),
          _context(options: options),
        ),
        _verdict(action: EightBoxAction.forgotten, isCorrect: false),
      );
    });

    test('a card that is not one of the options is refused (BR-STUDY-041)', () {
      expect(
        _judge(
          StudyMode.guess,
          const GuessAnswer('x'),
          _context(options: options),
        ),
        _refusedWith(StudyModeRejection.notAnOption),
      );
    });

    test('a question without its five options is blocked (BR-STUDY-040; '
        'IT-MODE-014)', () {
      expect(
        _judge(StudyMode.guess, const GuessAnswer('c1')),
        _refusedWith(StudyModeRejection.questionBlocked),
      );
      expect(
        _judge(
          StudyMode.guess,
          const GuessAnswer('c1'),
          _context(options: const ['d1', 'c1', 'd2', 'd3']),
        ),
        _refusedWith(StudyModeRejection.questionBlocked),
      );
    });
  });

  group('match', () {
    const board = {'c1': 'work', 'c2': 'water', 'c3': 'work'};

    test("the turn is the term card's, and a meaning of the same back_folded "
        'is right (BR-STUDY-062; spec D3)', () {
      expect(
        _judge(
          StudyMode.match,
          const MatchAnswer('c1'),
          _context(board: board),
        ),
        _verdict(action: EightBoxAction.remembered, isCorrect: true),
      );
      expect(
        _judge(
          StudyMode.match,
          const MatchAnswer('c3'),
          _context(board: board),
        ),
        _verdict(
          action: EightBoxAction.remembered,
          isCorrect: true,
          takesMeaningSlotOf: 'c3',
        ),
      );
      expect(
        _judge(
          StudyMode.match,
          const MatchAnswer('c2'),
          _context(board: board),
        ),
        _verdict(action: EightBoxAction.forgotten, isCorrect: false),
      );
    });

    test('a meaning that is not a pending pair of the board is refused '
        '(BR-STUDY-049)', () {
      expect(
        _judge(
          StudyMode.match,
          const MatchAnswer('c9'),
          _context(board: board),
        ),
        _refusedWith(StudyModeRejection.notOnBoard),
      );
    });
  });

  group('every mode', () {
    test("an answer of another mode's kind is refused", () {
      const foreign = <StudyMode, StudyAnswer>{
        StudyMode.browse: FillAnswer('x'),
        StudyMode.selfAssess: GuessAnswer('c1'),
        StudyMode.match: RecallAnswer(RecallOutcome.remembered),
        StudyMode.guess: MatchAnswer('c1'),
        StudyMode.recall: FillAnswer('x'),
        StudyMode.fill: AdvanceAnswer(),
      };
      for (final MapEntry(key: mode, value: answer) in foreign.entries) {
        expect(
          _judge(mode, answer, _context(isRevealed: true)),
          _refusedWith(StudyModeRejection.answerDoesNotFitMode),
          reason: mode.code,
        );
      }
    });

    test('browse moves on with no action, and self_assess records the action '
        'pressed from its scheduler (BR-MODE-005, BR-MODE-011)', () {
      expect(
        _judge(StudyMode.browse, const AdvanceAnswer()),
        _verdict(action: null),
      );
      final selfAssess = StudyMode.selfAssess.handler;
      expect(
        selfAssess.judge(
          const SelfAssessAnswer(Sm2Action.hard),
          _context(),
          sm2Scheduler,
        ),
        _verdict(action: Sm2Action.hard),
      );
      expect(
        selfAssess.judge(
          const SelfAssessAnswer(EightBoxAction.remembered),
          _context(),
          sm2Scheduler,
        ),
        _refusedWith(StudyModeRejection.unsupportedAction),
      );
    });

    test('a graded verdict has no action under sm2 (BR-MODE-007)', () {
      expect(
        StudyMode.recall.handler.judge(
          const RecallAnswer(RecallOutcome.remembered),
          _context(isRevealed: true),
          sm2Scheduler,
        ),
        _refusedWith(StudyModeRejection.unsupportedAction),
      );
    });
  });
}
