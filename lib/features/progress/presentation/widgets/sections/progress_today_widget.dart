import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/app_icons.dart';
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
    final today = overview.today;
    final isNever = !overview.hasLifetimeActivity;
    final sub = switch ((isNever, today.total)) {
      (true, _) => l10n.progressNothingYet,
      (false, 0) => l10n.progressTodayNone,
      _ => l10n.progressTodaySplit(today.learning, today.reviewing),
    };
    return MxCard(
      isCompact: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.progressToday.toUpperCase(),
            semanticsLabel: l10n.progressToday,
            style: context.texts.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: context.dimens.space4),
          Text(
            '${today.total}',
            style: context.texts.displayMedium?.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          SizedBox(height: context.dimens.space4),
          Text(
            sub,
            style: context.texts.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: context.dimens.space12),
          if (isNever) ...[
            MxDashedNote(text: l10n.progressNeverChart),
            SizedBox(height: context.dimens.space12),
            MxButton(
              label: l10n.progressStartStudying,
              icon: AppIcons.play,
              // The screen's only action (One Accent; critique 2026-09-30
              // part 3d-1).
              tone: MxButtonTone.primary,
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
        // The learning status fill, as MxStatusBadge's dot. The mastery
        // ramp draws its learning band in `warning` instead, to hold 3:1 on
        // its track (deck mastery spec R4).
        color: context.mxColors.warningContainer,
      ),
    );
  }
}
