import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The session's context line: deck, kind and [mode] (a learning session
/// adds its stage); a round-based stage adds its round, Guess its first-pick
/// rule and Match the board's pairs left (handoffs 17, 18; FE-A6 P3 M3).
String sessionContextOf(
  AppLocalizations l10n,
  StudySessionView view,
  String mode,
) {
  final base = switch (view.kind) {
    SessionKind.learning => l10n.studyContextLearning(
      view.deckName,
      l10n.studyKindLearning,
      view.currentStageIndex + 1,
      view.stages.length,
      mode,
    ),
    SessionKind.reviewing => l10n.studyContextReview(
      view.deckName,
      l10n.studyKindReview,
      mode,
    ),
  };
  if (!view.currentMode.handler.usesRounds) return base;
  final round = l10n.studyContextRound(base, view.currentRound ?? 1);
  return switch (view.currentMode) {
    StudyMode.guess => l10n.studyContextFirstPick(round),
    StudyMode.match => l10n.studyContextPairsLeft(
      round,
      view.board?.terms.where((tile) => !tile.isMatched).length ?? 0,
    ),
    StudyMode.browse ||
    StudyMode.selfAssess ||
    StudyMode.recall ||
    StudyMode.fill => round,
  };
}
