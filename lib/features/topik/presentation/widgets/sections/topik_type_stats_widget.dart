import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_linear_progress.dart';
import 'package:memox/shared/widgets/mx_section.dart';

/// Screen 38's By question type (critique S7, BR-TOPIK-024): each type with
/// "{correct} / {total}" and a thin track; the weakest marked.
class TopikTypeStatsWidget extends StatelessWidget {
  const TopikTypeStatsWidget({super.key, required this.summary});

  final TopikAttemptSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    return MxSection(
      title: l10n.topikByType,
      children: [
        for (final stat in summary.typeStats)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dimens.space16,
              vertical: dimens.space12,
            ),
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: dimens.space8,
                children: [
                  Row(
                    spacing: dimens.space8,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.topikTypeName(stat.type),
                          style: context.texts.titleSmall,
                        ),
                      ),
                      if (stat.type == summary.weakestType)
                        MxBadge(
                          label: l10n.topikWeakest,
                          tone: MxBadgeTone.warning,
                        ),
                      Text(
                        l10n.topikOfTotal(stat.correct, stat.total),
                        style: context.texts.labelMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  MxLinearProgress(
                    value: stat.total == 0 ? 0 : stat.correct / stat.total,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
