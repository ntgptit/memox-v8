import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/presentation/states/study_home_caught_up_state.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

/// Screen 13's workload card: the cards due across the library, stated as
/// the Due total over overdue · today (BR-STUDY-068, FE-A8 S1), and a way in:
/// "Review {deck}" opens the Study entry of the deck that needs it most
/// (Study home spec H2). Sessions still start per deck, so it opens a deck
/// and starts nothing, and it is no hero. With nothing due it is the calm
/// caught-up card, neither an error nor an achievement (BR-STUDY-008, S2).
class StudyHomeWorkloadWidget extends StatelessWidget {
  const StudyHomeWorkloadWidget({
    super.key,
    required this.workload,
    required this.now,
    required this.hasResume,
    required this.onOpenDeck,
  });

  final RootDeckWorkload workload;

  /// A Resume card above holds the screen's one fill, so the way in here is
  /// an outline (Study home spec H4).
  final bool hasResume;
  final ValueChanged<String> onOpenDeck;

  /// The local day the caught-up body reads [RootDeckWorkload.nextDueAt]
  /// against (BR-STUDY-074).
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (workload.isCaughtUp) return _CaughtUp(workload: workload, now: now);
    final l10n = context.l10n;
    // The eyebrow's own colour: it no longer borrows the Required foreground
    // (critique 2026-09-30 part 2, P2).
    final foreground = context.colors.mutedForeground;
    final priority = workload.priorityDueDeck;
    return MxCard(
      isCompact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: context.dimens.space4,
        children: [
          Row(
            spacing: context.dimens.space4,
            children: [
              IconTheme(
                data: IconThemeData(
                  color: foreground,
                  size: context.dimens.sizeIconInline,
                ),
                child: const ExcludeSemantics(child: Icon(AppIcons.dueNow)),
              ),
              Flexible(
                child: Text(
                  l10n.studyHomeWaiting.toUpperCase(),
                  semanticsLabel: l10n.studyHomeWaiting,
                  style: context.texts.meta.copyWith(
                    color: context.colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
          Text(
            l10n.studyHomeDueTitle(workload.dueCount),
            style: context.texts.sectionTitle,
          ),
          // The hero states what is due, in its two halves; new and
          // scheduled cards are in the deck rows (BR-STUDY-068, critique
          // 2026-09-30). A zero term drops out.
          MxWorkloadBreakdownLine(
            overdueCount: workload.overdueCount,
            todayCount: workload.dueTodayCount,
            // The hero names only what is due (BR-STUDY-068); a zero
            // count drops the new term.
            newCount: 0,
            overdueLabel: l10n.workloadOverdue,
            todayLabel: l10n.workloadToday,
            newLabel: l10n.workloadNew,
            fallback: l10n.studyHomeCaughtUpTitle,
            suffix: l10n.studyHomeAcrossDecks(workload.workloadDeckCount),
            canWrap: true,
          ),
          // Only while a card is due: new cards alone are no review. 16 above
          // it with the column's 4 (spacing spec L8).
          if (priority != null) ...[
            SizedBox(height: context.dimens.space16),
            MxButton(
              label: l10n.studyHomeReviewDeck(priority.name),
              tone: hasResume ? MxButtonTone.outline : MxButtonTone.primary,
              isBlock: true,
              onPressed: () => onOpenDeck(priority.deckId),
            ),
          ],
        ],
      ),
    );
  }
}

class _CaughtUp extends StatelessWidget {
  const _CaughtUp({required this.workload, required this.now});

  final RootDeckWorkload workload;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final body = switch (caughtUpWhenOf(workload.nextDueAt, now)) {
      CaughtUpResting() => l10n.studyHomeCaughtUpResting,
      CaughtUpTomorrow() => l10n.studyHomeCaughtUpTomorrow,
      CaughtUpOnDay(:final day) => l10n.studyHomeCaughtUpOn(
        DateFormat.MMMd(l10n.localeName).format(day),
      ),
    };
    // The empty state draws its own card surface (kit zero workload).
    return MxEmptyState(
      icon: AppIcons.learned,
      title: l10n.studyHomeCaughtUpTitle,
      body: body,
      tone: MxEmptyStateTone.success,
      isCompact: true,
    );
  }
}
