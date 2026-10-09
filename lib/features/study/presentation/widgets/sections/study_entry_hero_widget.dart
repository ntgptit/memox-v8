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

  /// As the kit inks them (FE-A6 D17): the due cards, what a review takes,
  /// draw the eye; waiting new cards are a quieter fact; a zero stays a
  /// plain 0.
  static MxStatTileEmphasis _emphasisOf(
    int count, {
    required MxStatTileEmphasis whenAny,
  }) => count > 0 ? whenAny : MxStatTileEmphasis.plain;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final algorithm = l10n.studyScheduler(entry.schedulerType);
    // A summary, not a door (critique 2026-09-30 part 3d-2, E5).
    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.grouped,
        children: [
          // The algorithm alone as overline, the limit its own line: no
          // orphan word (critique 2026-09-30 part 3c-1, R5).
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.micro,
            children: [
              Text(
                algorithm.toUpperCase(),
                semanticsLabel: algorithm,
                style: styles.eyebrow,
              ),
              Text(
                l10n.studyEntryLimit(entry.cardLimit),
                style: styles.rowDescription,
              ),
            ],
          ),
          Row(
            spacing: AppSpacing.control,
            children: [
              Expanded(
                child: MxStatTile(
                  value: l10n.studyCount(entry.newCardCount),
                  label: l10n.studyEntryNew,
                  emphasis: _emphasisOf(
                    entry.newCardCount,
                    whenAny: MxStatTileEmphasis.muted,
                  ),
                  layout: MxStatTileLayout.boxed,
                ),
              ),
              Expanded(
                child: MxStatTile(
                  value: l10n.studyCount(entry.dueCardCount),
                  label: l10n.studyEntryDue,
                  emphasis: _emphasisOf(
                    entry.dueCardCount,
                    whenAny: MxStatTileEmphasis.primary,
                  ),
                  layout: MxStatTileLayout.boxed,
                ),
              ),
            ],
          ),
          if (entry.overdueCardCount > 0)
            Text(
              l10n.studyEntryOverdue(entry.overdueCardCount),
              style: styles.statusNote(context.semanticColors.warning),
            ),
        ],
      ),
    );
  }
}
