import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/presentation/widgets/support/trash_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

/// One Trash entry (kit 06): its kind, its name and time left, what went
/// with it and when, and where it was (information only, BR-TRASH-012).
/// Selecting, it is a checkbox; an entry of the other kind cannot be picked
/// (BR-TRASH-011).
class TrashEntryRowWidget extends StatelessWidget {
  const TrashEntryRowWidget({
    super.key,
    required this.entry,
    required this.now,
    required this.onTap,
    this.onLongPress,
    this.onActions,
    this.isSelecting = false,
    this.isSelected = false,
  });

  final TrashEntry entry;
  final DateTime now;

  /// Null while selecting for an entry of the other kind.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// The ⋮ command; absent while selecting.
  final VoidCallback? onActions;
  final bool isSelecting;
  final bool isSelected;

  static const double _rowPadding = 12;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = trashEntryName(entry);
    final meta = _meta(context);
    final timeLeft = trashTimeLeft(l10n, entry, now);
    final origin = l10n.trashWasIn(trashOrigin(l10n, entry));
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.control),
      child: MxCard(
        isFullBleed: true,
        isSelected: isSelected,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              // One TalkBack node with every fact, whatever the ellipsis
              // hides (spec D15); the ⋮ stays its own control.
              child: Semantics(
                container: true,
                excludeSemantics: true,
                button: !isSelecting,
                checked: isSelecting ? isSelected : null,
                enabled: onTap != null,
                label: l10n.trashEntrySemantics(name, meta, timeLeft, origin),
                child: GestureDetector(
                  onLongPress: onLongPress,
                  child: MxRowInk(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(_rowPadding),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppSpacing.grouped,
                        children: [
                          if (isSelecting)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.micro,
                              ),
                              child: MxSelectionCheckbox(isChecked: isSelected),
                            )
                          else
                            MxIconTile(
                              icon: entry is TrashDeckEntry
                                  ? AppIcons.library
                                  : AppIcons.cardDeck,
                            ),
                          Expanded(
                            child: _Lines(
                              name: name,
                              timeLeft: timeLeft,
                              isExpiringSoon: isTrashExpiringSoon(entry, now),
                              meta: meta,
                              origin: origin,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (onActions case final onActions? when !isSelecting)
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.micro,
                  right: AppSpacing.micro,
                ),
                child: MxIconButton(
                  icon: AppIcons.more,
                  semanticLabel: l10n.trashEntryActions(name),
                  onPressed: onActions,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _meta(BuildContext context) {
    final l10n = context.l10n;
    final ago = trashDeletedAgo(l10n, entry.deletedAt, now);
    return switch (entry) {
      TrashCardEntry() => l10n.trashCardMeta(ago),
      TrashDeckEntry(:final subDeckCount, :final cardCount) =>
        l10n.trashDeckMeta(subDeckCount, cardCount, ago),
    };
  }
}

class _Lines extends StatelessWidget {
  const _Lines({
    required this.name,
    required this.timeLeft,
    required this.isExpiringSoon,
    required this.meta,
    required this.origin,
  });

  final String name;
  final String timeLeft;
  final bool isExpiringSoon;
  final String meta;
  final String origin;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final ink = isExpiringSoon
        ? context.derivedColors.warningInk
        : context.colors.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.micro,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: AppSpacing.control,
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: styles.rowTitle,
              ),
            ),
            Text(timeLeft, style: styles.badgeLabel(ink)),
          ],
        ),
        Text(
          meta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: styles.rowDescription,
        ),
        Text(
          origin,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: styles.rowDescription,
        ),
      ],
    );
  }
}
