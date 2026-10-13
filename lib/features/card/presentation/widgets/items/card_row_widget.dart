import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/widgets/items/card_due_chip_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';
import 'package:memox/core/theme/theme_rules.dart';

/// Tags a row names before "+N" (screen 07, spec A15).
const int _shownTags = 2;

/// One card of the list (screen 07's CardRow): the status dot, or the
/// checkbox while selecting; front and back on one line each; the status in
/// its ink with up to two tags and "+N"; the flag and when it comes back. A
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
  Widget build(BuildContext context) {
    // The checkbox, while selecting, and the trailing column centre on the
    // row (spec 2026-09-26 D4, extended by the owner 2026-09-26). No status
    // dot: the status line states it once (critique 2026-09-30 part 3b, R3).
    final row = Row(
      spacing: context.dimens.space12,
      children: [
        if (isSelecting) MxSelectionCheckbox(isChecked: isSelected),
        Expanded(child: _Content(item: item)),
        _Trailing(item: item),
      ],
    );
    // One node carries the label, the checked state, the tap and the
    // long-press; the box is only painted (ruling I6).
    return MergeSemantics(
      child: Semantics(
        checked: isSelecting ? isSelected : null,
        child: Padding(
          padding: EdgeInsets.only(bottom: context.dimens.space8),
          child: GestureDetector(
            onLongPress: onLongPress,
            child: MxCard(
              isFullBleed: true,
              isSelected: isSelected,
              child: MxRowInk(
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.dimens.space16,
                    vertical: context.dimens.space12,
                  ),
                  child: row,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.item});

  final CardListItem item;

  static Color _statusInk(BuildContext context, CardDisplayStatus status) {
    return switch (status) {
      CardDisplayStatus.newCard => context.colors.onSurfaceVariant,
      CardDisplayStatus.beginning => context.mxColors.warning,
      CardDisplayStatus.reviewing => context.accentColor,
      CardDisplayStatus.mastered => context.mxColors.success,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = item.displayStatus;
    final label = l10n.cardStatus(status);
    final tags = item.tags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.dimens.space4,
      children: [
        Text(
          item.front,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.texts.titleMedium,
        ),
        Text(
          item.back,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.texts.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: context.dimens.space4),
        // Wraps rather than clips, so large text keeps every word.
        Wrap(
          spacing: context.dimens.space4,
          runSpacing: context.dimens.space4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              label.toUpperCase(),
              semanticsLabel: label,
              style: context.texts.labelSmall?.copyWith(
                color: _statusInk(context, status),
              ),
            ),
            for (final tag in tags.take(_shownTags))
              MxTagChip(label: tag.name, isDense: true),
            if (tags.length > _shownTags)
              Text(
                l10n.cardMoreTags(tags.length - _shownTags),
                style: context.texts.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
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
    spacing: context.dimens.space4,
    children: [
      if (item.isFlagged)
        IconTheme.merge(
          data: IconThemeData(
            color: context.colors.onSurface,
            size: context.dimens.sizeIconInline,
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
