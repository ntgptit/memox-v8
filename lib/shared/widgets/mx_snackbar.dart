import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';

/// Shows one transient message (DESIGN.md, MxSnackbar), replacing any that
/// shows: 4s, or 8s when it offers Undo ([isUndo]). While TalkBack is on, a
/// message with an action stays until it is used or dismissed, so the
/// action can be reached.
void showMxSnackbar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  bool isUndo = false,
}) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar();
  final bool hasAction = actionLabel != null && onAction != null;
  messenger.showSnackBar(
    SnackBar(
      duration: isUndo ? AppDurations.toastWithUndo : AppDurations.toast,
      persist: hasAction && MediaQuery.accessibleNavigationOf(context),
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.gutter,
        end: AppSpacing.micro,
      ),
      content: MxSnackbar(
        message: message,
        actionLabel: actionLabel,
        onAction: hasAction
            ? () {
                messenger.hideCurrentSnackBar();
                onAction();
              }
            : null,
      ),
    ),
  );
}

/// The content of a snackbar: the message in `on-inverse-surface` and one
/// optional action in `inverse-primary`, inside a 48 row.
class MxSnackbar extends StatelessWidget {
  const MxSnackbar({
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final String? action = actionLabel;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
      child: Row(
        spacing: AppSpacing.grouped,
        children: [
          Expanded(
            child: Text(
              message,
              style: context.texts.bodyMedium?.apply(
                color: context.colors.onInverseSurface,
              ),
            ),
          ),
          if (action != null)
            MxButton(
              label: action,
              onPressed: onAction,
              tone: MxButtonTone.inverse,
              size: MxButtonSize.small,
            ),
        ],
      ),
    );
  }
}
