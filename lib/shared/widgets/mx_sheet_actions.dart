import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/components/button_style.dart';
import 'package:memox/shared/widgets/mx_button.dart';

/// What a dialog's or sheet's confirm does.
enum MxSheetActionsTone { primary, destructive, warning }

/// The footer every dialog and sheet ends with (DESIGN.md, MxSheetActions).
/// Cancel and the confirm share the row equally while both labels fit one
/// line at the reader's text scale, the confirm on the trailing side; when
/// either would wrap they stack full width, the confirm on top. A lone
/// confirm spans the row. Labels are never cut. In a sheet it sits under a
/// hairline on the gutter.
class MxSheetActions extends StatelessWidget {
  const MxSheetActions({
    required this.confirmLabel,
    required this.onConfirm,
    this.cancelLabel,
    this.onCancel,
    this.tone = MxSheetActionsTone.primary,
    this.isConfirmLoading = false,
    this.isInSheet = false,
    super.key,
  });

  final String confirmLabel;

  /// `null` disables the confirm, as while a form is invalid.
  final VoidCallback? onConfirm;
  final String? cancelLabel;
  final VoidCallback? onCancel;
  final MxSheetActionsTone tone;

  /// The confirm spins and blocks taps while its work runs.
  final bool isConfirmLoading;
  final bool isInSheet;

  /// The same actions framed for a sheet's footer (a hairline, the gutter);
  /// `MxBottomSheet` applies it, so a caller never has to.
  MxSheetActions framedForSheet() => MxSheetActions(
    confirmLabel: confirmLabel,
    onConfirm: onConfirm,
    cancelLabel: cancelLabel,
    onCancel: onCancel,
    tone: tone,
    isConfirmLoading: isConfirmLoading,
    isInSheet: true,
    key: key,
  );

  @override
  Widget build(BuildContext context) {
    final Widget confirm = MxButton(
      label: confirmLabel,
      onPressed: onConfirm,
      isLoading: isConfirmLoading,
      tone: switch (tone) {
        MxSheetActionsTone.primary => MxButtonTone.primary,
        MxSheetActionsTone.destructive => MxButtonTone.destructive,
        MxSheetActionsTone.warning => MxButtonTone.warning,
      },
    );
    return _framed(context, _actions(context, confirm));
  }

  Widget _actions(BuildContext context, Widget confirm) {
    final String? cancel = cancelLabel;
    if (cancel == null) {
      return confirm;
    }
    // One primary per decision: Cancel is the outline tone.
    final Widget dismiss = MxButton(
      label: cancel,
      onPressed: onCancel,
      tone: MxButtonTone.outline,
    );
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, footer) {
        final double share = (footer.maxWidth - AppSpacing.control) / 2;
        final bool isSideBySide =
            mxCanButtonLabelFit(
              texts: context.texts,
              label: cancel,
              width: share,
              textScaler: scaler,
            ) &&
            mxCanButtonLabelFit(
              texts: context.texts,
              label: confirmLabel,
              width: share,
              textScaler: scaler,
            );
        if (isSideBySide) {
          return Row(
            spacing: AppSpacing.control,
            children: [
              Expanded(child: dismiss),
              Expanded(child: confirm),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.control,
          children: [confirm, dismiss],
        );
      },
    );
  }

  Widget _framed(BuildContext context, Widget actions) {
    if (!isInSheet) {
      return actions;
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
        child: actions,
      ),
    );
  }
}
