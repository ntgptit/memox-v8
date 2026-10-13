import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_component_themes.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';

const double _verticalPadding = 10;

/// How long a toast stays: the platform's 4 seconds.
const Duration _toastDuration = Duration(seconds: 4);

/// How long a toast offering Undo stays (FE-B1 D3).
const Duration mxUndoWindow = Duration(seconds: 8);

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
  Duration duration = _toastDuration,
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

/// The toast's width on a wide window: the column less its gutters.
double _wideWidth(AppDimens dimens) =>
    dimens.sizeContentMax - 2 * dimens.space16;

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
  Duration duration = _toastDuration,
}) {
  final messenger = ScaffoldMessenger.of(context);
  // On a window wider than the screen column the toast is at most the
  // column, centred (FE-C5 D5); SnackBar.width replaces the theme's side
  // inset only there.
  final isWide =
      MediaQuery.sizeOf(context).width > context.dimens.sizeContentMax;
  // The surface, float, inset and radius are the theme's (spec §4.6).
  return SnackBar(
    width: isWide ? _wideWidth(context.dimens) : null,
    duration: duration,
    persist: onAction != null && MediaQuery.accessibleNavigationOf(context),
    // Only the message carries the 10 vertical padding (MxSnackbarContent),
    // so the action's 48 target sits inside the 48 toast.
    padding: EdgeInsets.symmetric(horizontal: context.screenMargin),
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
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: context.dimens.sizeControl),
      child: Row(
        spacing: context.dimens.space12,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: _verticalPadding),
              child: Text(
                message,
                style: context.texts.bodyMedium?.copyWith(
                  color: context.colors.onInverseSurface,
                ),
              ),
            ),
          ),
          if ((actionLabel, onAction) case (final label?, final onPressed?))
            TextButton(
              onPressed: onPressed,
              // Ruling O9: 32 painted inside the 48 target; the radius is
              // UNSPECIFIED and uses 8.
              style:
                  buttonStyle(
                    ThemeTokens.of(context),
                    fill: null,
                    foreground: colors.inversePrimary,
                  ).copyWith(
                    minimumSize: WidgetStatePropertyAll(
                      Size(0, context.dimens.sizeButtonSmall),
                    ),
                    padding: WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: context.dimens.space8),
                    ),
                  ),
              child: Text(label),
            ),
        ],
      ),
    );
  }
}
