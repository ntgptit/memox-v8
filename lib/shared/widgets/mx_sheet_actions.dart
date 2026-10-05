import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';

/// The footer every dialog and sheet ends with. The confirm takes 1.3 shares
/// to Cancel's 1 (an even half each with [isEvenSplit]), so a real verb ("Move to Trash") keeps its line and Cancel
/// gives up width first; when a label cannot fit its share on one line, the
/// two stack instead (MxActionPair, spec 2026-09-26 D3).
class MxSheetActions extends StatelessWidget {
  const MxSheetActions({
    super.key,
    required String this.cancelLabel,
    required this.onCancel,
    required String this.confirmLabel,
    required this.onConfirm,
    this.confirmIcon,
    this.isDestructive = false,
    this.isWarning = false,
    this.isInSheet = false,
    this.isConfirmLoading = false,
    this.isEvenSplit = false,
  }) : assert(!(isDestructive && isWarning), 'a confirm has one tone'),
       children = const [];

  /// A custom footer (Trash restore / delete-forever, a single OK) in place
  /// of the pair (ruling O10).
  const MxSheetActions.custom({
    super.key,
    required this.children,
    this.isInSheet = false,
  }) : assert(children.length > 0, 'a custom footer has children'),
       cancelLabel = null,
       onCancel = null,
       confirmLabel = null,
       onConfirm = null,
       confirmIcon = null,
       isDestructive = false,
       isWarning = false,
       isConfirmLoading = false,
       isEvenSplit = false;

  final String? cancelLabel;

  /// Null disables Cancel, as while an add runs (screen 03 `adding`).
  final VoidCallback? onCancel;
  final String? confirmLabel;

  /// Null disables the confirm; Cancel stays live.
  final VoidCallback? onConfirm;
  final IconData? confirmIcon;

  /// The destructive Button tone on the confirm.
  final bool isDestructive;

  /// The warning Button tone on the confirm: a merge (FE-B2 spec D15).
  final bool isWarning;

  /// The confirm's work is running: it spins and cannot be pressed; Cancel
  /// stays live.
  final bool isConfirmLoading;

  /// Cancel and the confirm share the width 1:1 (the sign-in confirms,
  /// 2026-10-05 L2).
  final bool isEvenSplit;

  /// The sheet form: a ghost rule on top and 8 16 16 padding, instead of
  /// the dialog's 16 on top and 20 at the sides and bottom (DEV-166).
  final bool isInSheet;
  final List<Widget> children;

  static const int _cancelShare = 10;
  static const int _confirmShare = 13;

  @override
  Widget build(BuildContext context) {
    final Widget row = children.isNotEmpty
        ? Row(spacing: AppSpacing.control, children: children)
        : MxActionPair(
            leading: MxButton(
              label: cancelLabel!,
              onPressed: onCancel,
              tone: MxButtonTone.outline,
              isBlock: true,
              isSingleLine: true,
            ),
            trailing: MxButton(
              label: confirmLabel!,
              onPressed: onConfirm,
              icon: confirmIcon,
              isLoading: isConfirmLoading,
              tone: switch ((isDestructive, isWarning)) {
                (true, _) => MxButtonTone.destructive,
                (_, true) => MxButtonTone.warning,
                _ => MxButtonTone.primary,
              },
              isBlock: true,
              isSingleLine: true,
            ),
            leadingFlex: isEvenSplit ? 1 : _cancelShare,
            trailingFlex: isEvenSplit ? 1 : _confirmShare,
          );
    if (!isInSheet) {
      // A dialog's pair lines up with its title and body (20), 16 under the
      // content (L3) and 20 above the edge (DEV-166).
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.gutter,
          AppSpacing.card,
          AppSpacing.card,
        ),
        child: row,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.derivedColors.ghostBorder,
            width: AppStroke.hairline,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.control,
          AppSpacing.gutter,
          AppSpacing.gutter,
        ),
        child: row,
      ),
    );
  }
}
