import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/features/starter_decks/presentation/widgets/support/starter_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

/// One template of screen 03: its title, "In library" once added, its
/// facts, the add and the scheduler it suggests (UC-STARTER-001 step 4).
class StarterTemplateCardWidget extends StatelessWidget {
  const StarterTemplateCardWidget({
    super.key,
    required this.entry,
    required this.onAdd,
  });

  final StarterLibraryEntry entry;
  final VoidCallback onAdd;

  static const double _tileGap = AppSpacing.grouped;

  /// The facts and the actions line up with the title, past the tile.
  static const double _indent = MxIconTile.mediumBox + _tileGap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // One node: the title, the badge and the facts.
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.micro,
              children: [
                // The tile centres on the title, which wraps; the badge
                // follows it, or drops below when the line is full
                // (critique P3).
                Row(
                  spacing: _tileGap,
                  children: [
                    const MxIconTile(
                      icon: AppIcons.starterDecks,
                      size: MxIconTileSize.medium,
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.control,
                        runSpacing: AppSpacing.micro,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(entry.title, style: styles.contentTitle),
                          if (entry.isInLibrary)
                            MxBadge(
                              label: l10n.starterInLibrary,
                              tone: MxBadgeTone.neutral,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: _indent),
                  child: Text(
                    starterEntryFacts(l10n, entry),
                    style: styles.footerCaption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.grouped),
          // The suggestion drops below the button, whole, when both do not
          // fit on one line (critique P2a).
          Padding(
            padding: const EdgeInsetsDirectional.only(start: _indent),
            child: Wrap(
              spacing: AppSpacing.grouped,
              runSpacing: AppSpacing.control,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _AddButton(entry: entry, onAdd: onAdd),
                Text(
                  l10n.starterSuggests(
                    starterSchedulerName(l10n, entry.suggestedScheduler),
                  ),
                  style: styles.footerCaption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The add at the small step while its label fits one line; at large text a
/// label that would be cut takes the regular step, which wraps (post-build
/// audit).
class _AddButton extends StatelessWidget {
  const _AddButton({required this.entry, required this.onAdd});

  final StarterLibraryEntry entry;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = entry.isInLibrary
        ? l10n.starterAddAnotherCopy
        : l10n.starterAddToLibrary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final small = MxButton(
          label: label,
          icon: AppIcons.add,
          size: MxButtonSize.small,
          onPressed: onAdd,
        );
        if (small.naturalWidth(context) <= constraints.maxWidth) return small;
        return MxButton(label: label, icon: AppIcons.add, onPressed: onAdd);
      },
    );
  }
}
