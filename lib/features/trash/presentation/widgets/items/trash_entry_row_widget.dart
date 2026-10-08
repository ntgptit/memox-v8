import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/presentation/widgets/support/trash_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/l10n/relative_time.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_selectable_card_row.dart';
import 'package:memox/shared/widgets/mx_badge.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = trashEntryName(entry);
    final meta = _meta(context);
    final timeLeft = trashTimeLeft(l10n, entry, now);
    final origin = l10n.trashWasIn(trashOrigin(l10n, entry));
    // While selecting, an entry of the other kind cannot be picked
    // (BR-TRASH-011): the shared row dims it and blocks its taps.
    final isLocked = isSelecting && onTap == null;
    final onActions = this.onActions;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.control),
      child: MxSelectableCardRow(
        onTap: onTap,
        onLongPress: onLongPress,
        isSelecting: isSelecting,
        isSelected: isSelected,
        isEnabled: !isLocked,
        // One TalkBack node with every fact, whatever the ellipsis hides
        // (spec D15); the ⋮ stays its own control.
        semanticLabel: l10n.trashEntrySemantics(name, meta, timeLeft, origin),
        trailing: onActions == null || isSelecting
            ? null
            : MxIconButton(
                icon: AppIcons.more,
                semanticLabel: l10n.trashEntryActions(name),
                onPressed: onActions,
              ),
        child: Row(
          spacing: AppSpacing.grouped,
          children: [
            // The kind's tile; while selecting the shared row's checkbox
            // takes its place (spec 2026-09-26 D4).
            if (!isSelecting)
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
    );
  }

  String _meta(BuildContext context) {
    final l10n = context.l10n;
    final ago = l10n.ago(entry.deletedAt, now);
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

  /// A deck's meta may take a second line instead of losing its age.
  static const int _metaLines = 2;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    // Under three days the time left is a warning pill, so it reads as a
    // warning and not as darker text (owner 2026-09-26).
    final timeLeftLabel = isExpiringSoon
        ? MxBadge(label: timeLeft, tone: MxBadgeTone.warning)
        : Text(
            timeLeft,
            style: styles.badgeLabel(context.colors.onSurfaceVariant),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.control,
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
            timeLeftLabel,
          ],
        ),
        Text(
          meta,
          maxLines: _metaLines,
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
