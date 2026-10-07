import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/presentation/states/study_speech_cue_state.dart';
import 'package:memox/features/study/presentation/states/study_turn_state.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

// BR-STUDY-078, BR-STUDY-079, BR-STUDY-082; study speech spec §5, D13.

StudyItem _item({
  String cardId = 'c1',
  String front = 'abandon',
  int round = 1,
  int answersInSession = 0,
}) => StudyItem(
  cardId: cardId,
  front: front,
  back: 'từ bỏ',
  example: null,
  hint: null,
  pronunciation: null,
  round: round,
  answersInSession: answersInSession,
  direction: null,
  remainingMs: null,
  isRevealed: false,
);

StudySessionView _view({
  StudyMode mode = StudyMode.browse,
  SessionKind kind = SessionKind.learning,
  SessionStatus status = SessionStatus.inProgress,
  StudyItem? item,
  bool hasItem = true,
}) => StudySessionView(
  sessionId: 's1',
  deckId: 'd1',
  deckName: 'Korean',
  kind: kind,
  status: status,
  endReason: null,
  currentMode: mode,
  direction: null,
  stages: const [StudyMode.browse, StudyMode.selfAssess],
  currentItem: hasItem ? (item ?? _item()) : null,
  progress: hasItem ? const RoundProgress(completed: 0, total: 3) : null,
  summary: null,
);

SpeechCue? _cue(
  StudySessionView view, {
  StudyTurnState turn = const StudyTurnState(),
  String? lastKey,
  bool isAutoPlay = true,
  bool isAccessibleNavigation = false,
}) => speechCueOf(
  view,
  turn,
  lastKey: lastKey,
  isAutoPlay: isAutoPlay,
  isAccessibleNavigation: isAccessibleNavigation,
);

void main() {
  test('a new card in browse is read: its front, keyed by card, mode, round '
      'and turn', () {
    final cue = _cue(_view());

    expect(cue?.text, 'abandon');
    expect(cue?.key, 'c1#browse#1#0');
  });

  test('the same card in the same turn is not read twice', () {
    expect(_cue(_view(), lastKey: 'c1#browse#1#0'), isNull);
  });

  test('the same card coming back as a later turn or round is read again', () {
    expect(
      _cue(_view(item: _item(answersInSession: 1)), lastKey: 'c1#browse#1#0'),
      isNotNull,
    );
    expect(
      _cue(
        _view(mode: StudyMode.guess, item: _item(round: 2)),
        lastKey: 'c1#guess#1#0',
      ),
      isNotNull,
    );
  });

  test('self_assess, guess and recall read; fill and match do not', () {
    for (final mode in [
      StudyMode.selfAssess,
      StudyMode.guess,
      StudyMode.recall,
    ]) {
      expect(_cue(_view(mode: mode)), isNotNull, reason: mode.code);
    }
    expect(_cue(_view(mode: StudyMode.fill)), isNull);
    expect(_cue(_view(mode: StudyMode.match)), isNull);
  });

  test('a review session reads nothing', () {
    expect(
      _cue(_view(mode: StudyMode.selfAssess, kind: SessionKind.reviewing)),
      isNull,
    );
  });

  test('nothing is read while a write runs or a turn is held', () {
    expect(_cue(_view(), turn: const StudyTurnState(isBusy: true)), isNull);
    final held = HeldTurn(_item(), const TurnResult(isCorrect: true));
    expect(_cue(_view(), turn: StudyTurnState(held: held)), isNull);
  });

  test('a stalled or ended session reads nothing', () {
    expect(_cue(_view(hasItem: false)), isNull);
    expect(
      _cue(_view(status: SessionStatus.completed, hasItem: false)),
      isNull,
    );
  });

  test('the switch off reads nothing (BR-STUDY-079)', () {
    expect(_cue(_view(), isAutoPlay: false), isNull);
  });

  test('a screen reader on reads nothing (D13)', () {
    expect(_cue(_view(), isAccessibleNavigation: true), isNull);
  });
}
