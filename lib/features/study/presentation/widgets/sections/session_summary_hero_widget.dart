import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/states/session_ending_state.dart';
import 'package:memox/features/study/presentation/states/upper_around_name_state.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';

/// Screen 21's hero (kit SessionStatusHero): how the session ended, in its
/// tone (FE-A6 D14), and — for a finished or paused session with answers —
/// its three numbers (D17, D18).
class SessionSummaryHeroWidget extends StatelessWidget {
  const SessionSummaryHeroWidget({
    super.key,
    required this.view,
    required this.summary,
    required this.outcome,
  });

  final StudySessionView view;
  final SessionSummary summary;
  final SummaryOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final tone = outcome.tone;
    final kind = view.kind == SessionKind.learning
        ? l10n.summaryKindLearning
        : l10n.summaryKindReview;
    final overline = l10n.summaryOverline(kind, view.deckName);
    // The app's words upper-cased, the deck name as typed (critique
    // 2026-09-30 part 2, P4).
    final shown = upperAroundName(
      (name) => l10n.summaryOverline(kind, name),
      view.deckName,
    );
    final (body, strong) = _bodyOf(l10n);
    // Text on a container reads its on-container, spec 4.6; the paused
    // surface is a plain card and keeps its neutral roles.
    final ink = switch (tone) {
      SummaryTone.success => context.semanticColors.onSuccessContainer,
      SummaryTone.ended => context.semanticColors.onWarningContainer,
      SummaryTone.error => context.colors.onErrorContainer,
      SummaryTone.paused => null,
    };
    return MxCard(
      isSuccess: tone == SummaryTone.success,
      isWarning: tone == SummaryTone.ended,
      isDanger: tone == SummaryTone.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ExcludeSemantics(
              child: MxIconTile(
                icon: _iconOf(tone),
                size: MxIconTileSize.large,
                tone: _tileToneOf(tone),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.grouped),
          Text(
            shown,
            semanticsLabel: overline,
            textAlign: TextAlign.center,
            style: styles.eyebrowIn(ink),
          ),
          const SizedBox(height: AppSpacing.micro),
          Semantics(
            header: true,
            child: Text(
              _titleOf(l10n),
              textAlign: TextAlign.center,
              style: styles.summaryTitleIn(ink),
            ),
          ),
          const SizedBox(height: AppSpacing.micro),
          _BodyText(body: body, strong: strong, ink: ink),
          if (outcome.drawsStats && summary.hasAnswers) ...[
            const SizedBox(height: AppSpacing.grouped),
            _Stats(
              view: view,
              summary: summary,
              // Every body with stats states the finished count (bold, or
              // "The {n} cards you finished…" when left early) but an
              // interrupted one.
              isFinishedStated: outcome != SummaryOutcome.interrupted,
              // Only a finished session had later rounds (critique
              // 2026-10-02, F1).
              isWrongExplained: tone == SummaryTone.success,
              ink: ink,
            ),
          ],
        ],
      ),
    );
  }

  String _titleOf(AppLocalizations l10n) => switch (outcome) {
    SummaryOutcome.reviewFinished => l10n.summaryReviewFinished,
    SummaryOutcome.learningFinished => l10n.summaryLearningFinished,
    SummaryOutcome.leftEarly => l10n.summaryLeftEarly,
    SummaryOutcome.interrupted => l10n.summaryInterrupted,
    SummaryOutcome.reset => l10n.summaryReset,
    SummaryOutcome.schedulerChanged => l10n.summarySchedulerChanged,
    SummaryOutcome.contentDeleted => l10n.summaryContentDeleted,
    SummaryOutcome.saveError => l10n.summarySaveError,
  };

  /// The body, and the run of it the kit bolds (the count), if any.
  (String, String?) _bodyOf(AppLocalizations l10n) {
    final finished = summaryFinishedCount(view, summary);
    final left = summary.cardCount - finished;
    final cards = l10n.summaryCards(finished);
    return switch (outcome) {
      SummaryOutcome.reviewFinished => (
        switch ((summary.isAtCardLimit, summary.remainingDueCount)) {
          (true, > 0) => l10n.summaryReviewAtLimitMoreBody(
            cards,
            l10n.summaryMoreDue(summary.remainingDueCount),
          ),
          (true, _) => l10n.summaryReviewAtLimitBody(cards),
          (false, _) => l10n.summaryReviewFinishedBody(cards),
        },
        cards,
      ),
      SummaryOutcome.learningFinished => (
        l10n.summaryLearningFinishedBody(cards),
        cards,
      ),
      SummaryOutcome.leftEarly => (
        view.kind == SessionKind.learning
            ? l10n.summaryLeftEarlyLearningBody(finished, left)
            : l10n.summaryLeftEarlyReviewBody(finished, left),
        null,
      ),
      SummaryOutcome.interrupted => (l10n.summaryInterruptedBody, null),
      SummaryOutcome.reset => (l10n.summaryResetBody, null),
      SummaryOutcome.schedulerChanged => (
        l10n.summarySchedulerChangedBody,
        null,
      ),
      SummaryOutcome.contentDeleted => (l10n.summaryContentDeletedBody, null),
      SummaryOutcome.saveError => (l10n.summarySaveErrorBody, null),
    };
  }

  static IconData _iconOf(SummaryTone tone) => switch (tone) {
    SummaryTone.success => AppIcons.learned,
    SummaryTone.paused => AppIcons.pause,
    SummaryTone.ended => AppIcons.resetProgress,
    SummaryTone.error => AppIcons.alert,
  };

  static MxIconTileTone _tileToneOf(SummaryTone tone) => switch (tone) {
    SummaryTone.success => MxIconTileTone.success,
    SummaryTone.paused => MxIconTileTone.tinted,
    SummaryTone.ended => MxIconTileTone.caution,
    SummaryTone.error => MxIconTileTone.danger,
  };
}

/// The body with its [strong] run in the strong role, as the kit bolds the
/// count; the whole [body] plain when it has no such run.
class _BodyText extends StatelessWidget {
  const _BodyText({required this.body, required this.strong, this.ink});

  final String body;
  final String? strong;

  /// The container's on-container; null keeps the neutral roles.
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final run = strong;
    final start = run == null ? -1 : body.indexOf(run);
    if (run == null || start < 0) {
      return Text(
        body,
        textAlign: TextAlign.center,
        style: styles.emptyBodyIn(ink),
      );
    }
    return Text.rich(
      TextSpan(
        style: styles.emptyBodyIn(ink),
        children: [
          TextSpan(text: body.substring(0, start)),
          TextSpan(text: run, style: styles.summaryBodyStrongIn(ink)),
          TextSpan(text: body.substring(start + run.length)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// What the body does not state: the finished count when the body has none,
/// answered only when it differs from it, and wrong turns with their meaning
/// (critique 2026-09-30 part 3c-1, R3; amends FE-A6 D17's three stats).
class _Stats extends StatelessWidget {
  const _Stats({
    required this.view,
    required this.summary,
    required this.isFinishedStated,
    required this.isWrongExplained,
    this.ink,
  });

  final StudySessionView view;
  final SessionSummary summary;

  /// The body states the finished count; an interrupted session's body does
  /// not, so its finished tile stays.
  final bool isFinishedStated;

  /// Wrong cards came back in later rounds only in a finished session.
  final bool isWrongExplained;

  /// The container's on-container; null keeps the neutral roles.
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final finished = summaryFinishedCount(view, summary);
    final answered = summary.answeredCardCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.micro,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.control,
          children: [
            if (!isFinishedStated)
              Expanded(
                child: MxStatTile(
                  value: l10n.studyCount(finished),
                  label: view.kind == SessionKind.learning
                      ? l10n.summaryStatLearned
                      : l10n.summaryStatReviewed,
                  ink: ink,
                ),
              ),
            if (answered != finished)
              Expanded(
                child: MxStatTile(
                  value: l10n.studyCount(answered),
                  label: l10n.summaryStatAnswered,
                  ink: ink,
                ),
              ),
            Expanded(
              child: MxStatTile(
                value: l10n.summaryWrongOf(
                  summary.wrongTurnCount,
                  summary.turnCount,
                ),
                label: l10n.summaryStatWrong,
                ink: ink,
              ),
            ),
          ],
        ),
        if (isWrongExplained && summary.wrongTurnCount > 0)
          Text(
            l10n.summaryWrongExplained,
            textAlign: TextAlign.center,
            style: context.textStyles.emptyBodyIn(ink),
          ),
      ],
    );
  }
}
