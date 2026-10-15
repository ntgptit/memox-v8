import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/widgets/items/topik_recent_attempt_row_widget.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/l10n/relative_time.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';

/// Overview of screen 36 (BR-TOPIK-020, BR-TOPIK-021): Overall Progress and
/// the recent attempts. No attempt: the card becomes the empty state with
/// Start, the screen's one action then (critique F2).
class TopikOverviewWidget extends StatelessWidget {
  const TopikOverviewWidget({
    super.key,
    required this.detail,
    required this.now,
    required this.onStart,
    required this.onOpenAttempt,
    required this.onOpenSummary,
  });

  final TopikTestDetail detail;
  final DateTime now;
  final VoidCallback onStart;
  final ValueChanged<String> onOpenAttempt;
  final ValueChanged<String> onOpenSummary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final progress = detail.progress;
    if (progress.isEmpty) {
      return MxEmptyState(
        icon: AppIcons.add,
        title: l10n.topikNoAttemptsTitle,
        body: l10n.topikNoAttemptsBody,
        actionLabel: l10n.topikStart,
        onAction: onStart,
      );
    }
    String figure(int? value, String Function(int) format) =>
        value == null ? '–' : format(value);
    final lastActivity = progress.lastActivityAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxListSectionHeader(label: l10n.topikOverallProgress),
        MxCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: dimens.space16,
            children: [
              Row(
                spacing: dimens.space16,
                children: [
                  Expanded(
                    child: MxStatTile(
                      value: figure(
                        progress.accuracyPercent,
                        l10n.topikPercent,
                      ),
                      label: l10n.topikAccuracy,
                      layout: MxStatTileLayout.boxed,
                    ),
                  ),
                  Expanded(
                    child: MxStatTile(
                      value: figure(progress.bestScore, (v) => '$v'),
                      label: l10n.topikBest,
                      layout: MxStatTileLayout.boxed,
                    ),
                  ),
                ],
              ),
              Row(
                spacing: dimens.space16,
                children: [
                  Expanded(
                    child: MxStatTile(
                      value: figure(progress.averageScore, (v) => '$v'),
                      label: l10n.topikAverage,
                      layout: MxStatTileLayout.boxed,
                    ),
                  ),
                  Expanded(
                    child: MxStatTile(
                      value: l10n.topikOfTotal(
                        progress.completed,
                        progress.sessions,
                      ),
                      label: l10n.topikCompleted,
                      layout: MxStatTileLayout.boxed,
                    ),
                  ),
                ],
              ),
              if (lastActivity != null)
                Text(
                  l10n.topikLastActivity(
                    l10n.ago(lastActivity, now),
                    l10n.duration(progress.totalTimeMs),
                  ),
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: dimens.space8),
        MxNote.hint(text: l10n.topikScoresNote),
        SizedBox(height: dimens.space24),
        MxListSectionHeader(label: l10n.topikRecentAttempts),
        MxCard(
          isFullBleed: true,
          child: MxDividedColumn(
            children: [
              for (final numbered in detail.recent)
                TopikRecentAttemptRowWidget(
                  numbered: numbered,
                  onOpen: () => numbered.attempt.isCompleted
                      ? onOpenSummary(numbered.attempt.id)
                      : onOpenAttempt(numbered.attempt.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
