import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/widgets/items/card_due_chip_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_selectable_card_row.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

/// Tags a row names before "+N" (screen 07, spec A15).
const int _shownTags = 2;

/// One card of the list (screen 07's CardRow): the status dot, or the
/// checkbox while selecting; front and back on one line each; the status in
/// its text token with up to two tags and "+N"; the flag and when it comes back. A
/// long-press selects it (BR-CARD-020).
class CardRowWidget extends StatelessWidget {
  const CardRowWidget({
    super.key,
    required this.item,
    required this.isSelecting,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
  });

  final CardListItem item;
  final bool isSelecting;
  final bool isSelected;

  /// Opens the card, or toggles it while selecting (BR-CARD-020).
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.control),
    // The frame is the shared card row (DEV-304): the checkbox while
    // selecting, the ink, 16/12 and one node with the checked state. No
    // status dot: the status line states it once (critique 2026-09-30 part
    // 3b, R3).
    child: MxSelectableCardRow(
      onTap: onTap,
      onLongPress: onLongPress,
      isSelecting: isSelecting,
      isSelected: isSelected,
      child: Row(
        spacing: AppSpacing.grouped,
        children: [
          Expanded(child: _Content(item: item)),
          _Trailing(item: item),
        ],
      ),
    ),
  );
}

class _Content extends StatelessWidget {
  const _Content({required this.item});

  final CardListItem item;

  static Color _statusInk(BuildContext context, CardDisplayStatus status) {
    final semantic = context.semanticColors;
    return switch (status) {
      CardDisplayStatus.newCard => context.colors.onSurfaceVariant,
      CardDisplayStatus.beginning => semantic.learningText,
      CardDisplayStatus.reviewing => semantic.primaryText,
      CardDisplayStatus.mastered => semantic.masteryText,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final status = item.displayStatus;
    final label = l10n.cardStatus(status);
    final tags = item.tags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.micro,
      children: [
        Text(
          item.front,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: styles.contentTitle,
        ),
        Text(
          item.back,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: styles.rowDescription,
        ),
        const SizedBox(height: AppSpacing.micro),
        // Wraps rather than clips, so large text keeps every word.
        Wrap(
          spacing: AppSpacing.micro,
          runSpacing: AppSpacing.micro,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              label.toUpperCase(),
              semanticsLabel: label,
              style: styles.statusLabel(_statusInk(context, status)),
            ),
            for (final tag in tags.take(_shownTags))
              MxTagChip(label: tag.name, isDense: true),
            if (tags.length > _shownTags)
              Text(
                l10n.cardMoreTags(tags.length - _shownTags),
                style: styles.rowDescription,
              ),
          ],
        ),
      ],
    );
  }
}

/// The flag in plain ink, the filled glyph carrying the state as in the
/// editor and the detail (critique 2026-10-02, F6; supersedes E-L2), over
/// the due chip.
class _Trailing extends StatelessWidget {
  const _Trailing({required this.item});

  final CardListItem item;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    spacing: AppSpacing.micro,
    children: [
      if (item.isFlagged)
        IconTheme.merge(
          data: IconThemeData(
            color: context.colors.onSurface,
            size: AppIconSize.inline,
          ),
          child: Icon(
            AppIcons.flagged,
            semanticLabel: context.l10n.cardFlagged,
          ),
        ),
      CardDueChipWidget(due: item.due),
    ],
  );
}
