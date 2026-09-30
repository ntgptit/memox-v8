import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The session's context line: deck and kind (a learning session adds its
/// stage); a round-based stage adds its round and Guess its first-pick rule.
/// The mode is the top bar's pill and Match's board shows its own pairs, so
/// the line repeats neither (critique 2026-09-30).
String sessionContextOf(AppLocalizations l10n, StudySessionView view) {
  final base = switch (view.kind) {
    SessionKind.learning => l10n.studyContextLearning(
      view.deckName,
      l10n.studyKindLearning,
      view.currentStageIndex + 1,
      view.stages.length,
    ),
    SessionKind.reviewing => l10n.studyContextReview(
      view.deckName,
      l10n.studyKindReview,
    ),
  };
  if (!view.currentMode.handler.usesRounds) return base;
  final round = l10n.studyContextRound(base, view.currentRound ?? 1);
  return switch (view.currentMode) {
    StudyMode.guess => l10n.studyContextFirstPick(round),
    StudyMode.match ||
    StudyMode.browse ||
    StudyMode.selfAssess ||
    StudyMode.recall ||
    StudyMode.fill => round,
  };
}
