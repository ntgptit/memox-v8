import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_dashed_note.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_note.dart';

/// The current streak (BR-PROGRESS-016): its days and how it stands, beside
/// today's count, with a note when it is held from yesterday or lost. With
/// nothing ever studied, the streak's place.
class ProgressStreakWidget extends StatelessWidget {
  const ProgressStreakWidget({super.key, required this.overview});

  final ProgressOverview overview;

  /// A lost streak names its last day by weekday within this many days, and
  /// by date beyond.
  static const int _weekdayReach = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final streak = overview.streak;
    final note = switch (streak.state) {
      StreakState.heldFromYesterday => l10n.progressHeldNote(streak.days + 1),
      StreakState.lost => l10n.progressLostNote(_lastDay(context)),
      StreakState.includesToday || StreakState.never => null,
    };
    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.progressStreak.toUpperCase(),
            semanticsLabel: l10n.progressStreak,
            style: context.textStyles.overline,
          ),
          const SizedBox(height: AppSpacing.grouped),
          if (streak.state == StreakState.never)
            MxDashedNote(text: l10n.progressNeverStreak)
          else
            _tiles(context),
          if (note != null) ...[
            const SizedBox(height: AppSpacing.grouped),
            MxNote(text: note),
          ],
        ],
      ),
    );
  }

  Widget _tiles(BuildContext context) {
    final l10n = context.l10n;
    final streak = overview.streak;
    final todayCount = overview.today.total;
    final current = _StreakTile(
      icon: AppIcons.streak,
      tint: streak.days > 0
          ? context.semanticColors.streak
          : context.colors.onSurfaceVariant,
      label: l10n.progressStreakCurrent,
      value: l10n.progressStreakDays(streak.days),
      sub: switch (streak.state) {
        StreakState.includesToday => l10n.progressStreakIncludesToday,
        StreakState.heldFromYesterday => l10n.progressStreakHeld,
        StreakState.lost || StreakState.never => l10n.progressStreakLost,
      },
    );
    final today = _StreakTile(
      icon: AppIcons.studiedToday,
      label: l10n.progressToday,
      value: l10n.progressTodayCards(todayCount),
      sub: todayCount == 0
          ? l10n.progressTodayNothing
          : l10n.progressTodayCounted,
    );
    // Side by side as the kit draws them, until a label or a count would
    // break its line (large text, Vietnamese): then one tile per line.
    return LayoutBuilder(
      builder: (context, constraints) {
        final share = (constraints.maxWidth - AppSpacing.control) / 2;
        final isStacked =
            share < _StreakTile.minWidth(context, current) ||
            share < _StreakTile.minWidth(context, today);
        if (isStacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.control,
            children: [current, today],
          );
        }
        return Row(
          spacing: AppSpacing.control,
          children: [
            Expanded(child: current),
            Expanded(child: today),
          ],
        );
      },
    );
  }

  String _lastDay(BuildContext context) {
    final locale = context.l10n.localeName;
    final last = overview.lastActiveDay!;
    final gap = overview.today.date.difference(last).inDays;
    return gap <= _weekdayReach
        ? DateFormat.EEEE(locale).format(last)
        : DateFormat.MMMd(locale).format(last);
  }
}

class _StreakTile extends StatelessWidget {
  const _StreakTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    this.tint,
  });

  final IconData icon;

  /// The narrowest [tile] that keeps its label and its count on one line
  /// each: the inset, the icon tile, the gap and the wider of the two.
  static double minWidth(BuildContext context, _StreakTile tile) {
    final styles = context.textStyles;
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    double widthOf(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final text = math.max(
      widthOf(tile.label.toUpperCase(), styles.compactOverline),
      widthOf(tile.value, styles.summaryBodyStrong),
    );
    return AppSpacing.grouped * 2 +
        MxIconTile.smallBox +
        AppSpacing.control +
        text;
  }

  /// Null tints with primary.
  final Color? tint;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    // The kit's tile: the recessed ground at a 12 inset, tighter than a card,
    // so two fit side by side on a phone.
    return DecoratedBox(
      decoration: AppDecorations.recessedCard(
        context.colors,
        context.derivedColors,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.grouped),
        child: Row(
          spacing: AppSpacing.control,
          children: [
            MxIconTile(icon: icon, seed: tint),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    semanticsLabel: label,
                    style: styles.compactOverline,
                  ),
                  const SizedBox(height: AppSpacing.micro),
                  Text(value, style: styles.summaryBodyStrong),
                  Text(sub, style: styles.footerCaption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
