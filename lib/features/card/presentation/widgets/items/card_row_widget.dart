import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';

/// One card of the list (spec §6.4): its front and back on one line each, a
/// status dot, and the flag when set. A long-press selects it (BR-CARD-020).
class CardRowWidget extends StatelessWidget {
  const CardRowWidget({
    super.key,
    required this.item,
    required this.isSelecting,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
    this.hasDivider = true,
  });

  final CardListItem item;
  final bool isSelecting;
  final bool isSelected;

  /// Toggles the card while selecting. Ruling P3-L3: outside selection the
  /// detail arrives in phase 4.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final row = MxListRow(
      title: item.front,
      subtitle: item.back,
      leading: isSelecting ? MxSelectionCheckbox(isChecked: isSelected) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.control,
        children: [
          if (item.isFlagged)
            Icon(
              AppIcons.flagged,
              size: AppIconSize.inline,
              semanticLabel: l10n.cardFlagged,
            ),
          MxStatusBadge(
            status: mxCardStatus(item.displayStatus),
            label: l10n.cardStatus(item.displayStatus),
            isDot: true,
          ),
        ],
      ),
      onTap: onTap,
      hasDivider: hasDivider,
    );
    // The row carries the checked state; the box is only painted (ruling I6).
    return Semantics(
      checked: isSelecting ? isSelected : null,
      child: GestureDetector(onLongPress: onLongPress, child: row),
    );
  }
}
