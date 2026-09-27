import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// The Study Entry hero (kit 14): the algorithm and its card limit
/// (BR-STUDY-024), then New and Due as two separate tiles that never merge
/// (BR-STUDY-051), each dimmed at zero (BR-STUDY-047).
class StudyEntryHeroWidget extends StatelessWidget {
  const StudyEntryHeroWidget({
    super.key,
    required this.entry,
    required this.algorithm,
  });

  final StudyEntry entry;

  /// The deck's algorithm, named.
  final String algorithm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final line = l10n.studyEntryHeroLine(algorithm, entry.cardLimit);
    return MxCard(
      isHero: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.grouped,
        children: [
          Text(
            line.toUpperCase(),
            semanticsLabel: line,
            style: context.textStyles.overline,
          ),
          Row(
            spacing: AppSpacing.gutter,
            children: [
              Expanded(
                child: _StatTile(
                  label: l10n.studyEntryNewLabel,
                  value: entry.newCardCount,
                ),
              ),
              Expanded(
                child: _StatTile(
                  label: l10n.studyEntryDueLabel,
                  value: entry.dueCardCount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final int value;

  static const double _dimOpacity = 0.38;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return MergeSemantics(
      child: Opacity(
        opacity: value == 0 ? _dimOpacity : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              NumberFormat.decimalPattern(
                Localizations.localeOf(context).toLanguageTag(),
              ).format(value),
              style: styles.screenTitle,
            ),
            Text(label, style: styles.rowDescription),
          ],
        ),
      ),
    );
  }
}
