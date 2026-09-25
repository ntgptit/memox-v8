import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/app_button_style.dart';

const double _verticalPadding = 10;

/// Shows the MemoX toast: a message and one optional action on the inverse
/// surface, which does not flip with the theme. Tapping the action hides the
/// toast first. How long it stays is the platform's call.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showMxSnackbar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}) => ScaffoldMessenger.of(context).showSnackBar(
  buildMxSnackBar(
    context,
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
  ),
);

/// The platform SnackBar that [showMxSnackbar] shows, configured with the
/// contract's surface (ruling O9).
SnackBar buildMxSnackBar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  return SnackBar(
    backgroundColor: context.colors.inverseSurface,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsetsDirectional.only(
      start: AppSpacing.gutter,
      end: AppSpacing.gutter,
      bottom: AppSpacing.gutter,
    ),
    // Only the message carries the 10 vertical padding (MxSnackbarContent),
    // so the action's 48 target sits inside the 48 toast.
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    content: MxSnackbarContent(
      message: message,
      actionLabel: actionLabel,
      onAction: switch (onAction) {
        null => null,
        final action => () {
          messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
          action();
        },
      },
    ),
  );
}

/// The toast's content: the message, which wraps, and the trailing action,
/// which keeps its width.
class MxSnackbarContent extends StatelessWidget {
  const MxSnackbarContent({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction come together',
       );

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.touchTarget),
      child: Row(
        spacing: AppSpacing.grouped,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: _verticalPadding),
              child: Text(message, style: styles.snackbarMessage),
            ),
          ),
          if ((actionLabel, onAction) case (final label?, final onPressed?))
            TextButton(
              onPressed: onPressed,
              // Ruling O9: 32 painted inside the 48 target; the radius is
              // UNSPECIFIED and uses 8.
              style: appButtonStyle(
                fill: null,
                ink: colors.inversePrimary,
                edge: BorderSide.none,
                focusColor: colors.inversePrimary,
                height: AppSize.buttonCompact,
                radius: AppRadius.sm,
                padding: AppSpacing.control,
                label: styles.snackbarAction,
              ),
              child: Text(label),
            ),
        ],
      ),
    );
  }
}
