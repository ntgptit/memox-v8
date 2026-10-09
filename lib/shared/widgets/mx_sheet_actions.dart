import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';

/// The footer every dialog and sheet ends with: Cancel and the confirm share
/// the row 1 : 1, since the title names the object and the confirm is its
/// verb alone (DEV-179); when a label cannot fit its half on one line, the
/// two stack instead (MxActionPair, spec 2026-09-26 D3). A popup's buttons
/// carry no icon: the tone already tells the weight (DEV-179).
class MxSheetActions extends StatelessWidget {
  const MxSheetActions({
    super.key,
    required String this.cancelLabel,
    required this.onCancel,
    required String this.confirmLabel,
    required this.onConfirm,
    this.isDestructive = false,
    this.isWarning = false,
    this.isInSheet = false,
    this.isConfirmLoading = false,
  }) : assert(!(isDestructive && isWarning), 'a confirm has one tone'),
       children = const [],
       _singleTone = null;

  /// One action across the row: a lone Close, Done or OK (SW-REV-008). A
  /// lone Close stays primary (The One Indigo Rule, R8); a dismiss beside
  /// choices is outline.
  const MxSheetActions.single({
    super.key,
    required String label,
    required VoidCallback? onPressed,
    MxButtonTone tone = MxButtonTone.primary,
    this.isInSheet = false,
  }) : confirmLabel = label,
       onConfirm = onPressed,
       _singleTone = tone,
       children = const [],
       cancelLabel = null,
       onCancel = null,
       isDestructive = false,
       isWarning = false,
       isConfirmLoading = false;

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
       isDestructive = false,
       isWarning = false,
       isConfirmLoading = false,
       _singleTone = null;

  final String? cancelLabel;

  /// Null disables Cancel, as while an add runs (screen 03 `adding`).
  final VoidCallback? onCancel;
  final String? confirmLabel;

  /// Null disables the confirm; Cancel stays live.
  final VoidCallback? onConfirm;

  /// The destructive Button tone on the confirm.
  final bool isDestructive;

  /// The warning Button tone on the confirm: a merge (FE-B2 spec D15).
  final bool isWarning;

  /// The confirm's work is running: it spins and cannot be pressed; Cancel
  /// stays live, since some work can be cancelled (Export's preparing). Work
  /// that cannot be stopped nulls [onCancel] and holds its popup
  /// (MxDialog.isHeld, MxBottomSheet.isHeld), so Back and the scrim wait too.
  final bool isConfirmLoading;

  /// The sheet form: a ghost rule on top and 8 16 16 padding, instead of
  /// the dialog's 16 all round.
  final bool isInSheet;
  final List<Widget> children;

  /// Set only by [MxSheetActions.single]: the one button's tone.
  final MxButtonTone? _singleTone;

  @override
  Widget build(BuildContext context) {
    final singleTone = _singleTone;
    final Widget row = singleTone != null
        ? Row(
            children: [
              Expanded(
                child: MxButton(
                  label: confirmLabel!,
                  onPressed: onConfirm,
                  tone: singleTone,
                  isBlock: true,
                ),
              ),
            ],
          )
        : children.isNotEmpty
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
              isLoading: isConfirmLoading,
              tone: switch ((isDestructive, isWarning)) {
                (true, _) => MxButtonTone.destructive,
                (_, true) => MxButtonTone.warning,
                _ => MxButtonTone.primary,
              },
              isBlock: true,
              isSingleLine: true,
            ),
          );
    if (!isInSheet) {
      // A dialog's pair, 16 in on the edge its title and body share
      // (DEV-166).
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: row,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.colors.outlineVariant,
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
