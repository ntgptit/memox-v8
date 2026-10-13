import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/states/session_ending_state.dart';
import 'package:memox/features/study/presentation/states/study_turn_state.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';

/// What the session reads now (BR-STUDY-078).
final class SpeechCue {
  const SpeechCue({required this.key, required this.text});

  /// One reading per turn of a card in a mode: `card#mode#round#turn`. A
  /// card that comes back (self_assess Again, a later round) is a new turn
  /// and is read again.
  final String key;

  /// The card's term.
  final String text;
}

/// The turn [view] serves, as the reading is keyed: `card#mode#round#turn`;
/// null while no card is served.
String? speechTurnKeyOf(StudySessionView view) {
  final item = view.currentItem;
  if (item == null) return null;
  return '${item.cardId}#${view.currentMode.code}#${item.round}#${item.answersInSession}';
}

/// The reading due for [view] under [turn], or null (study speech spec §5):
/// a learning session serving a card in a mode that reads the term, no
/// write running and no turn held (the next card is read when it is drawn,
/// not when the stream moves under a hold), the session open, and a turn
/// not read yet ([lastKey]). The switch off (BR-STUDY-079) or a screen
/// reader on (D13: TalkBack reads the card itself) reads nothing; the
/// speaker button is the way then.
SpeechCue? speechCueOf(
  StudySessionView view,
  StudyTurnState turn, {
  required String? lastKey,
  required bool isAutoPlay,
  required bool isAccessibleNavigation,
}) {
  if (!isAutoPlay || isAccessibleNavigation) return null;
  if (view.kind != SessionKind.learning) return null;
  if (turn.isBusy || turn.held != null) return null;
  if (sessionEndingOf(view) != null) return null;
  final item = view.currentItem;
  final key = speechTurnKeyOf(view);
  if (item == null || key == null) return null;
  if (!view.currentMode.handler.readsTermAloud) return null;
  if (key == lastKey) return null;
  return SpeechCue(key: key, text: item.front);
}
