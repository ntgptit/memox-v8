import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/reminders/presentation/states/reminder_action_state.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// Kit 24's first section: the toggle row and the time row, under the note
/// that says when it fires (UC-REMINDER-001 step 1). While an operation
/// runs, nothing here starts another (FE-B5 spec D4).
class ReminderSettingsSectionWidget extends StatelessWidget {
  const ReminderSettingsSectionWidget({
    super.key,
    required this.reminder,
    required this.action,
    required this.isPickingTime,
    required this.onToggle,
    required this.onPickTime,
  });

  final ReminderSettings reminder;
  final ReminderActionState action;

  /// The time dialog is open (kit `changingTime`).
  final bool isPickingTime;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isOn = reminder.isEnabled;
    final time = reminderTimeLabel(context, reminder.minuteOfDay);
    final isTurning =
        action.running == ReminderOperation.turnOn ||
        action.running == ReminderOperation.turnOff;
    return MxSection(
      note: l10n.reminderNote,
      children: [
        MxSettingsRow(
          label: l10n.reminderTitle,
          icon: AppIcons.reminder,
          subtitle: switch ((isOn, action.problem)) {
            (true, _) => l10n.reminderOnHint,
            (false, ReminderProblem.permissionDenied) =>
              l10n.reminderDeniedHint,
            (false, _) => l10n.reminderOffHint,
          },
          trailing: isTurning
              ? MxSpinner(semanticLabel: l10n.commonLoading)
              : MxToggle(
                  isOn: isOn,
                  semanticLabel: l10n.reminderTitle,
                  onChanged: action.isBusy ? null : onToggle,
                ),
        ),
        MxSettingsRow(
          label: l10n.reminderTime,
          icon: AppIcons.clock,
          isEnabled: isOn,
          subtitle: isOn ? l10n.reminderTimeOnHint : l10n.reminderTimeOffHint,
          trailing: MxButton(
            label: time,
            semanticLabel: l10n.reminderTimeButton(time),
            size: MxButtonSize.compact,
            tone: isPickingTime ? MxButtonTone.outline : MxButtonTone.secondary,
            isLoading: action.running == ReminderOperation.changeTime,
            onPressed: isOn && !action.isBusy ? onPickTime : null,
          ),
        ),
      ],
    );
  }
}

/// A minute of the local day as 24-hour `HH:mm` in every language (FE-B5
/// spec D9).
String reminderTimeLabel(BuildContext context, int minuteOfDay) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: minuteOfDay ~/ 60, minute: minuteOfDay % 60),
      alwaysUse24HourFormat: true,
    );
