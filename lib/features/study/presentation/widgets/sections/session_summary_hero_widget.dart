import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/states/session_ending_state.dart';
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
    final overline = l10n.summaryOverline(
      view.kind == SessionKind.learning
          ? l10n.summaryKindLearning
          : l10n.summaryKindReview,
      view.deckName,
    );
    final (body, strong) = _bodyOf(l10n);
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
            overline.toUpperCase(),
            semanticsLabel: overline,
            textAlign: TextAlign.center,
            style: styles.overline,
          ),
          const SizedBox(height: AppSpacing.micro),
          Semantics(
            header: true,
            child: Text(
              _titleOf(l10n),
              textAlign: TextAlign.center,
              style: styles.summaryTitle,
            ),
          ),
          const SizedBox(height: AppSpacing.micro),
          _BodyText(body: body, strong: strong),
          if (outcome.drawsStats && summary.hasAnswers) ...[
            const SizedBox(height: AppSpacing.grouped),
            _Stats(view: view, summary: summary),
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
        l10n.summaryReviewFinishedBody(cards),
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
  const _BodyText({required this.body, required this.strong});

  final String body;
  final String? strong;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final run = strong;
    final start = run == null ? -1 : body.indexOf(run);
    if (run == null || start < 0) {
      return Text(body, textAlign: TextAlign.center, style: styles.emptyBody);
    }
    return Text.rich(
      TextSpan(
        style: styles.emptyBody,
        children: [
          TextSpan(text: body.substring(0, start)),
          TextSpan(text: run, style: styles.summaryBodyStrong),
          TextSpan(text: body.substring(start + run.length)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Finished, answered, wrong out of all turns (kit; FE-A6 D11).
class _Stats extends StatelessWidget {
  const _Stats({required this.view, required this.summary});

  final StudySessionView view;
  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final finished = summaryFinishedCount(view, summary);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.control,
      children: [
        Expanded(
          child: MxStatTile(
            value: l10n.studyCount(finished),
            label: view.kind == SessionKind.learning
                ? l10n.summaryStatLearned
                : l10n.summaryStatReviewed,
          ),
        ),
        Expanded(
          child: MxStatTile(
            value: l10n.studyCount(summary.answeredCardCount),
            label: l10n.summaryStatAnswered,
          ),
        ),
        Expanded(
          child: MxStatTile(
            value: l10n.summaryWrongOf(
              summary.wrongTurnCount,
              summary.turnCount,
            ),
            label: l10n.summaryStatWrong,
          ),
        ),
      ],
    );
  }
}
