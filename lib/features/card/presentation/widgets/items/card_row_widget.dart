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
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

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
    final status = item.displayStatus;
    // One node carries the label, the checked state, the tap and the
    // long-press; the box is only painted (ruling I6).
    return MergeSemantics(
      child: Semantics(
        checked: isSelecting ? isSelected : null,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.control),
          child: GestureDetector(
            onLongPress: onLongPress,
            child: MxCard(
              isFullBleed: true,
              isSelected: isSelected,
              child: MxRowInk(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.grouped),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.grouped,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.micro),
                        child: isSelecting
                            ? MxSelectionCheckbox(isChecked: isSelected)
                            // The status line already says it: one
                            // announcement per row.
                            : ExcludeSemantics(
                                child: MxStatusBadge(
                                  status: mxCardStatus(status),
                                  label: context.l10n.cardStatus(status),
                                  isDot: true,
                                ),
                              ),
                      ),
                      Expanded(child: _Content(item: item)),
                      _Trailing(item: item),
                    ],
                  ),
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
    final derived = context.derivedColors;
    return switch (status) {
      CardDisplayStatus.newCard => derived.statusNewInk,
      CardDisplayStatus.beginning => derived.statusLearningInk,
      CardDisplayStatus.reviewing => derived.statusReviewingInk,
      CardDisplayStatus.mastered => derived.statusMasteredInk,
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

/// The flag, in warning for want of a streak token (ruling E-L2), over the
/// due chip.
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
            color: context.semanticColors.warning,
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
