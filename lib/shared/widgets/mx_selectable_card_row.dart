import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

/// One item of a list drawn as a card the person can open, long-press into
/// selection and tick: a deck (screen 01), a card (07), a Trash entry (06).
/// The frame is shared, the content is the caller's (audit 2026-10-08 F-03,
/// DEV-304): the raised card, the ink over all of it, the checkbox while
/// selecting, 16 in and 12 down, and one TalkBack node. [trailing] (a ⋮)
/// sits outside the ink, 4 from the edge, and keeps its own node and tap.
class MxSelectableCardRow extends StatelessWidget {
  const MxSelectableCardRow({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.isSelecting = false,
    this.isSelected = false,
    this.isEnabled = true,
    this.trailing,
    this.semanticLabel,
  }) : assert(!isSelected || isSelecting, 'a selected row is selecting');

  final Widget child;

  /// Opens the item, or toggles it while selecting.
  final VoidCallback? onTap;

  /// Starts the selection with this item (BR-CARD-020, Trash spec D8).
  final VoidCallback? onLongPress;

  /// The list is selecting: the checkbox leads the content.
  final bool isSelecting;
  final bool isSelected;

  /// False dims the whole card to the disabled opacity and blocks its taps:
  /// an item that cannot join the selection (BR-TRASH-011).
  final bool isEnabled;

  /// A control of the item's own, usually an MxIconButton; outside the ink.
  final Widget? trailing;

  /// One sentence for TalkBack in place of the content, when the content
  /// is cut or scattered (the Trash entry, spec D15). Without it the
  /// content's own text is read, with the checked state.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ink = MxRowInk(
      onTap: onTap,
      onLongPress: onLongPress,
      isEnabled: isEnabled,
      shouldDimWhenDisabled: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: AppSpacing.grouped,
        ),
        child: Row(
          spacing: AppSpacing.grouped,
          children: [
            if (isSelecting) MxSelectionCheckbox(isChecked: isSelected),
            Expanded(child: child),
          ],
        ),
      ),
    );
    final checked = isSelecting ? isSelected : null;
    final target = switch (semanticLabel) {
      null => MergeSemantics(
        child: Semantics(checked: checked, child: ink),
      ),
      // The excluded content's actions, kept on this one node (SW-REV-005).
      final label => Semantics(
        container: true,
        excludeSemantics: true,
        button: !isSelecting,
        checked: checked,
        enabled: isEnabled && onTap != null,
        label: label,
        onTap: isEnabled ? onTap : null,
        onLongPress: isEnabled ? onLongPress : null,
        child: ink,
      ),
    };
    final trailing = this.trailing;
    final card = MxCard(
      isFullBleed: true,
      isSelected: isSelected,
      child: trailing == null
          ? target
          : Row(
              children: [
                Expanded(child: target),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: AppSpacing.micro,
                  ),
                  child: trailing,
                ),
              ],
            ),
    );
    if (isEnabled) return card;
    return Opacity(opacity: AppOpacity.disabled, child: card);
  }
}
