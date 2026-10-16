import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_test_progress_model.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/l10n/meta_line.dart';
import 'package:memox/l10n/relative_time.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';

/// Overall Progress of screen 36 (BR-TOPIK-020): accuracy and completion,
/// best and average, sessions and completed as six figures, then when and
/// how long in all. A figure with nothing to show reads as a dash.
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
    Widget tile(String value, String label, String? semanticValue) =>
        MxStatTile(
          value: value,
          label: label,
          semanticValue: semanticValue,
          layout: MxStatTileLayout.boxed,
        );
    final lastActivity = progress.lastActivityAt;
    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: dimens.space16,
        children: [
          for (final pair in [
            [
              tile(
                figure(progress.accuracyPercent, l10n.topikPercent),
                l10n.topikAccuracy,
                spoken(progress.accuracyPercent),
              ),
              tile(
                figure(progress.completionPercent, l10n.topikPercent),
                l10n.topikCompletion,
                spoken(progress.completionPercent),
              ),
            ],
            [
              tile(
                figure(progress.bestScore, (v) => '$v'),
                l10n.topikBest,
                spoken(progress.bestScore),
              ),
              tile(
                figure(progress.averageScore, (v) => '$v'),
                l10n.topikAverage,
                spoken(progress.averageScore),
              ),
            ],
            [
              tile('${progress.sessions}', l10n.topikSessions, null),
              tile('${progress.completed}', l10n.topikCompleted, null),
            ],
          ])
            Row(
              spacing: dimens.space16,
              children: [for (final figure in pair) Expanded(child: figure)],
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
