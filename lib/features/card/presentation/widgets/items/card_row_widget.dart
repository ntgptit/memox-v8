import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_due_chip_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_flag_mark.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

/// One card of the list (screen 07), a card of its own: a status dot, the
/// front and back on one line each, the status and up to two tags, then the
/// flag and when the card comes back. A long-press selects it
/// (BR-CARD-020); while selecting, a checkbox takes the dot's place and the
/// selected card is edged.
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

  /// Opens the card, or toggles it while selecting.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// The tags a row names; the rest count as "+N".
  static const int _shownTags = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final status = mxCardStatus(item.displayStatus);
    final statusLabel = l10n.cardStatus(item.displayStatus);
    final row = MxCard(
      isFullBleed: true,
      isSelected: isSelected,
      child: MxRowInk(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.grouped,
            children: [
              _FirstLine(
                style: styles.compactTitle,
                child: isSelecting
                    ? MxSelectionCheckbox(isChecked: isSelected)
                    // The status line below already says it: one
                    // announcement per row.
                    : ExcludeSemantics(
                        child: MxStatusBadge(
                          status: status,
                          label: statusLabel,
                          isDot: true,
                        ),
                      ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.micro,
                  children: [
                    Text(
                      item.front,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: styles.compactTitle,
                    ),
                    Text(
                      item.back,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: styles.rowSubtitle,
                    ),
                    _StatusAndTags(
                      item: item,
                      status: status,
                      statusLabel: statusLabel,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: AppSpacing.micro,
                children: [
                  if (item.isFlagged)
                    MxFlagMark(semanticLabel: l10n.cardFlagged),
                  CardDueChipWidget(due: item.due),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    // One node carries the label, the checked state, the tap and the
    // long-press; the box is only painted (ruling I6).
    return MergeSemantics(
      child: Semantics(
        checked: isSelecting ? isSelected : null,
        child: GestureDetector(onLongPress: onLongPress, child: row),
      ),
    );
  }
}

/// Centres [child] on the first line of text set in [style], at any text
/// scale; a child taller than the line sets the height itself.
class _FirstLine extends StatelessWidget {
  const _FirstLine({required this.style, required this.child});

  final TextStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final firstLine =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) *
        (style.height ?? 1);
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: firstLine),
      child: Center(child: child),
    );
  }
}

/// The status in its ink, then up to two tags and how many more.
class _StatusAndTags extends StatelessWidget {
  const _StatusAndTags({
    required this.item,
    required this.status,
    required this.statusLabel,
  });

  final CardListItem item;
  final MxCardStatus status;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final hidden = item.tags.length - CardRowWidget._shownTags;
    return Wrap(
      spacing: AppSpacing.control,
      runSpacing: AppSpacing.micro,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        MxStatusBadge(status: status, label: statusLabel, isPlain: true),
        for (final tag in item.tags.take(CardRowWidget._shownTags))
          MxTagChip(label: tag.name, isDense: true),
        if (hidden > 0)
          Text(
            context.l10n.cardTagsMore(hidden),
            style: context.textStyles.rowSubtitle,
          ),
      ],
    );
  }
}
