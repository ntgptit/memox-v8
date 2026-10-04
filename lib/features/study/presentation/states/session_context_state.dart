import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/states/upper_around_name_state.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The session's context line: deck and kind (a learning session adds its
/// stage); a round-based stage adds its round. Guess's first-pick rule is its
/// footer's (critique 2026-09-30 part 3c-2, R9).
/// The mode is the top bar's pill and Match's board shows its own pairs, so
/// the line repeats neither (critique 2026-09-30).
String sessionContextOf(AppLocalizations l10n, StudySessionView view) =>
    _contextOf(l10n, view, view.deckName);

/// The line as shown: the app's words upper-cased, the deck name as typed
/// (critique 2026-09-30 part 2, P4). [sessionContextOf] is what a screen
/// reader hears.
String sessionContextShownOf(AppLocalizations l10n, StudySessionView view) =>
    upperAroundName((name) => _contextOf(l10n, view, name), view.deckName);

String _contextOf(
  AppLocalizations l10n,
  StudySessionView view,
  String deckName,
) {
  final base = switch (view.kind) {
    SessionKind.learning => l10n.studyContextLearning(
      deckName,
      l10n.studyKindLearning,
      view.currentStageIndex + 1,
      view.stages.length,
    ),
    SessionKind.reviewing => l10n.studyContextReview(
      deckName,
      l10n.studyKindReview,
    ),
  };
  if (!view.currentMode.handler.usesRounds) return base;
  return l10n.studyContextRound(base, view.currentRound ?? 1);
}
