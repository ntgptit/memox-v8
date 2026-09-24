import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_workload_line_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

/// The Library root's bridge to study (screen 01): how many cards wait in
/// the whole library, and overdue · today · new under it. Display only until
/// Study home exists (spec A6).
class DeckDueStripWidget extends StatelessWidget {
  const DeckDueStripWidget({super.key, required this.level});

  final DeckLevel level;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final due = level.overdueCount + level.dueTodayCount;
    return MxCard(
      isHero: true,
      child: Row(
        spacing: AppSpacing.grouped,
        children: [
          const MxIconTile(icon: AppIcons.dueNow, size: MxIconTileSize.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.micro,
              children: [
                Text(
                  l10n.libraryDueTitle(due),
                  style: context.textStyles.rowTitle,
                ),
                DeckWorkloadLineWidget(
                  overdueCount: level.overdueCount,
                  todayCount: level.dueTodayCount,
                  newCount: level.newCount,
                  cardCount: due + level.newCount + level.scheduledCount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
