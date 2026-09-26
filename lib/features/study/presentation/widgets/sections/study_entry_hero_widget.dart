import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';

/// Screen 14's hero: the algorithm and the session limit (BR-STUDY-024),
/// New and Due as two figures that never merge (BR-STUDY-051), and the
/// overdue note (FE-A6 D15).
class StudyEntryHeroWidget extends StatelessWidget {
  const StudyEntryHeroWidget({super.key, required this.entry});

  final StudyEntry entry;

  /// A figure the screen acts on draws the eye; a zero stays a plain 0
  /// (FE-A6 D17, as the kit draws it).
  static MxStatTileEmphasis _emphasisOf(int count) =>
      count > 0 ? MxStatTileEmphasis.primary : MxStatTileEmphasis.plain;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final overline = l10n.studyEntryOverline(
      l10n.studyScheduler(entry.schedulerType),
      entry.cardLimit,
    );
    return MxCard(
      isHero: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.grouped,
        children: [
          Text(
            overline.toUpperCase(),
            semanticsLabel: overline,
            style: styles.overline,
          ),
          Row(
            spacing: AppSpacing.control,
            children: [
              Expanded(
                child: MxStatTile(
                  value: l10n.studyCount(entry.newCardCount),
                  label: l10n.studyEntryNew,
                  emphasis: _emphasisOf(entry.newCardCount),
                  layout: MxStatTileLayout.boxed,
                ),
              ),
              Expanded(
                child: MxStatTile(
                  value: l10n.studyCount(entry.dueCardCount),
                  label: l10n.studyEntryDue,
                  emphasis: _emphasisOf(entry.dueCardCount),
                  layout: MxStatTileLayout.boxed,
                ),
              ),
            ],
          ),
          if (entry.overdueCardCount > 0)
            Text(
              l10n.studyEntryOverdue(entry.overdueCardCount),
              style: styles.noteText,
            ),
        ],
      ),
    );
  }
}
