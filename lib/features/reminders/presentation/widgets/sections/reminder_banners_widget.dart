import 'package:flutter/material.dart';
import 'package:memox/features/reminders/presentation/states/reminder_action_state.dart';
import 'package:memox/features/reminders/presentation/widgets/sections/reminder_settings_section_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

/// The last operation's problem, with the action that repeats it (E1, E3,
/// E6). Kit 24's "Open system settings" is hidden (FE-B5 spec D1).
class ReminderBannersWidget extends StatelessWidget {
  const ReminderBannersWidget({
    super.key,
    required this.problem,
    required this.storedMinute,
    required this.isBusy,
    required this.onRetry,
  });

  final ReminderProblem? problem;
  final int storedMinute;
  final bool isBusy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget action(String label) => MxButton(
      label: label,
      size: MxButtonSize.compact,
      onPressed: isBusy ? null : onRetry,
    );
    return switch (problem) {
      null => const SizedBox.shrink(),
      ReminderProblem.permissionDenied => MxInlineBanner(
        tone: MxBannerTone.warning,
        title: l10n.reminderDeniedTitle,
        message: l10n.reminderDeniedBody,
        actions: [action(l10n.reminderTryAgain)],
      ),
      ReminderProblem.couldNotTurnOn => MxInlineBanner(
        tone: MxBannerTone.danger,
        title: l10n.reminderCouldNotTurnOnTitle,
        message: l10n.reminderCouldNotTurnOnBody,
        actions: [action(l10n.commonRetry)],
      ),
      ReminderProblem.couldNotChangeTime => MxInlineBanner(
        tone: MxBannerTone.danger,
        title: l10n.reminderCouldNotChangeTimeTitle,
        message: l10n.reminderCouldNotChangeTimeBody(
          reminderTimeLabel(context, storedMinute),
        ),
        actions: [action(l10n.commonRetry)],
      ),
      ReminderProblem.mayStillShow => MxInlineBanner(
        tone: MxBannerTone.warning,
        message: l10n.reminderMayStillShow,
        actions: [action(l10n.reminderTryAgain)],
      ),
    };
  }
}
