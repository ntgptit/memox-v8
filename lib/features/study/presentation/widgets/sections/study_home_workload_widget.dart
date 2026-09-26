import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/presentation/states/study_home_caught_up_state.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

/// Screen 13's workload hero: the cards due across the library, stated as
/// Overdue · Due today · New · Scheduled (BR-STUDY-068, FE-A8 S1). A summary,
/// not a start: sessions start per deck. With nothing to do it is the calm
/// caught-up card, neither an error nor an achievement (BR-STUDY-008, S2).
class StudyHomeWorkloadWidget extends StatelessWidget {
  const StudyHomeWorkloadWidget({
    super.key,
    required this.workload,
    required this.now,
  });

  final RootDeckWorkload workload;

  /// The local day the caught-up body reads [RootDeckWorkload.nextDueAt]
  /// against (BR-STUDY-074).
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (workload.isCaughtUp) return _CaughtUp(workload: workload, now: now);
    final l10n = context.l10n;
    final styles = context.textStyles;
    final primary = context.colors.primary;
    return MxCard(
      isHero: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.micro,
        children: [
          Row(
            spacing: AppSpacing.micro,
            children: [
              IconTheme(
                data: IconThemeData(color: primary, size: AppIconSize.inline),
                child: const ExcludeSemantics(child: Icon(AppIcons.dueNow)),
              ),
              Flexible(
                child: Text(
                  l10n.studyHomeWaiting.toUpperCase(),
                  semanticsLabel: l10n.studyHomeWaiting,
                  style: styles.requiredMarker,
                ),
              ),
            ],
          ),
          Text(
            l10n.studyHomeDueTitle(workload.dueCount),
            style: styles.summaryTitle,
          ),
          MxWorkloadBreakdownLine(
            overdueCount: workload.overdueCount,
            todayCount: workload.dueTodayCount,
            newCount: workload.newCount,
            scheduledCount: workload.scheduledCount,
            overdueLabel: l10n.workloadOverdue,
            todayLabel: l10n.workloadToday,
            newLabel: l10n.workloadNew,
            scheduledLabel: l10n.workloadScheduled,
            fallback: l10n.studyHomeCaughtUpTitle,
            suffix: l10n.studyHomeAcrossDecks(workload.workloadDeckCount),
          ),
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
    return MxCard(
      child: MxEmptyState(
        icon: AppIcons.learned,
        title: l10n.studyHomeCaughtUpTitle,
        body: body,
        tone: MxEmptyStateTone.success,
        isCompact: true,
      ),
    );
  }
}
