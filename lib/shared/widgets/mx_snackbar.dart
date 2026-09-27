import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/app_button_style.dart';

const double _verticalPadding = 10;

/// Shows the MemoX toast: a message and one optional action on the inverse
/// surface, which does not flip with the theme. Tapping the action hides the
/// toast first. It stays [duration], the platform's 4 seconds by default.
///
/// A new toast replaces the one on screen instead of queueing behind it, so
/// a toast that stays for TalkBack never holds back the next (FE-B1 D14).
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showMxSnackbar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = AppDurations.toast,
}) {
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  return messenger.showSnackBar(
    buildMxSnackBar(
      context,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    ),
  );
}

/// The platform SnackBar that [showMxSnackbar] shows, configured with the
/// contract's surface (ruling O9).
///
/// A toast with an action stays until it is acted on or replaced while
/// TalkBack is on, so the action can be reached (WCAG 2.2.1, FE-B1 D14).
/// The action is drawn by [MxSnackbarContent], not [SnackBar.action], so
/// the platform does not do this itself.
SnackBar buildMxSnackBar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = AppDurations.toast,
}) {
  final messenger = ScaffoldMessenger.of(context);
  // The surface, float, inset and radius are the theme's (spec §4.6).
  return SnackBar(
    duration: duration,
    persist: onAction != null && MediaQuery.accessibleNavigationOf(context),
    // Only the message carries the 10 vertical padding (MxSnackbarContent),
    // so the action's 48 target sits inside the 48 toast.
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
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
