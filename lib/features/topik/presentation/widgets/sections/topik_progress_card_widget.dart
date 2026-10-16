import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_test_progress_model.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/l10n/meta_line.dart';
import 'package:memox/l10n/relative_time.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';

/// Overall Progress of screen 36 (BR-TOPIK-020): accuracy, best, average
/// and completed as four figures, then when and how long in all. A figure
/// with nothing to show reads as a dash.
class TopikProgressCardWidget extends StatelessWidget {
  const TopikProgressCardWidget({
    super.key,
    required this.progress,
    required this.now,
  });

  final TopikTestProgress progress;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    String figure(int? value, String Function(int) format) =>
        value == null ? '–' : format(value);
    // TalkBack reads a bare dash as "en dash" (Q-P6-5).
    String? spoken(int? value) => value == null ? l10n.topikNoFigure : null;
    final lastActivity = progress.lastActivityAt;
    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: dimens.space16,
        children: [
          Row(
            spacing: dimens.space16,
            children: [
              Expanded(
                child: MxStatTile(
                  value: figure(progress.accuracyPercent, l10n.topikPercent),
                  label: l10n.topikAccuracy,
                  semanticValue: spoken(progress.accuracyPercent),
                  layout: MxStatTileLayout.boxed,
                ),
              ),
              Expanded(
                child: MxStatTile(
                  value: figure(progress.bestScore, (v) => '$v'),
                  label: l10n.topikBest,
                  semanticValue: spoken(progress.bestScore),
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
                  semanticValue: spoken(progress.averageScore),
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
              metaLine(
                l10n.topikLastActivity(
                  l10n.ago(lastActivity, now),
                  l10n.duration(progress.totalTimeMs),
                ),
              ),
              style: context.texts.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
