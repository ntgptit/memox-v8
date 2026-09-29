import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_workload_line_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

/// The Library root's bridge to study (screen 01): how many cards wait in
/// the whole library, and overdue · today · new under it. A tap opens Study
/// home (critique 2026-09-30, R4).
class DeckDueStripWidget extends StatelessWidget {
  const DeckDueStripWidget({super.key, required this.level, this.onOpen});

  final DeckLevel level;

  /// Opens Study home; null keeps the strip display-only.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final due = level.overdueCount + level.dueTodayCount;
    return MxCard(
      isHero: true,
      isFullBleed: true,
      child: MxRowInk(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.card),
          child: Row(
            spacing: AppSpacing.grouped,
            children: [
              const MxIconTile(
                icon: AppIcons.dueNow,
                size: MxIconTileSize.medium,
              ),
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
              if (onOpen != null)
                IconTheme(
                  data: IconThemeData(
                    color: context.colors.onSurfaceVariant,
                    size: AppIconSize.compact,
                  ),
                  child: const ExcludeSemantics(
                    child: Icon(AppIcons.chevronRight),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
