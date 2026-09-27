import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_dashed_note.dart';
import 'package:memox/shared/widgets/mx_stacked_day_bars.dart';

/// Today and the last seven days (UC-PROGRESS-001 step 4; BR-PROGRESS-014,
/// BR-PROGRESS-015): today's card-days split into learning and reviewing,
/// and a bar per day. With nothing ever studied, the chart's place and a way
/// to the Study tab (FE-A9 D1).
class ProgressTodayWidget extends StatelessWidget {
  const ProgressTodayWidget({
    super.key,
    required this.overview,
    required this.onStartStudying,
  });

  final ProgressOverview overview;
  final VoidCallback onStartStudying;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final today = overview.today;
    final isNever = !overview.hasLifetimeActivity;
    final sub = switch ((isNever, today.total)) {
      (true, _) => l10n.progressNothingYet,
      (false, 0) => l10n.progressTodayNone,
      _ => l10n.progressTodaySplit(today.learning, today.reviewing),
    };
    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.progressToday.toUpperCase(),
            semanticsLabel: l10n.progressToday,
            style: styles.overline,
          ),
          const SizedBox(height: AppSpacing.micro),
          Text(
            '${today.total}',
            style: styles.statValue(context.colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.micro),
          Text(sub, style: styles.footerCaption),
          const SizedBox(height: AppSpacing.grouped),
          if (isNever) ...[
            MxDashedNote(text: l10n.progressNeverChart),
            const SizedBox(height: AppSpacing.grouped),
            MxButton(
              label: l10n.progressStartStudying,
              icon: AppIcons.play,
              tone: MxButtonTone.secondary,
              isBlock: true,
              onPressed: onStartStudying,
            ),
          ] else
            _chart(context),
        ],
      ),
    );
  }

  Widget _chart(BuildContext context) {
    final l10n = context.l10n;
    final narrow = DateFormat('EEEEE', l10n.localeName);
    final weekday = DateFormat.EEEE(l10n.localeName);
    final days = overview.lastSevenDays;
    return MxStackedDayBars(
      days: [
        for (final (index, day) in days.indexed)
          MxDayBar(
            label: index == days.length - 1
                ? l10n.progressToday
                : narrow.format(day.date),
            base: day.reviewing,
            top: day.learning,
            isCurrent: index == days.length - 1,
            semanticLabel: l10n.progressDayBar(
              weekday.format(day.date),
              day.total,
              day.learning,
              day.reviewing,
            ),
          ),
      ],
      base: MxBarSeries(
        label: l10n.progressReviewing,
        color: context.colors.primary,
      ),
      top: MxBarSeries(
        label: l10n.progressLearning,
        color: context.semanticColors.statusLearning,
      ),
    );
  }
}
