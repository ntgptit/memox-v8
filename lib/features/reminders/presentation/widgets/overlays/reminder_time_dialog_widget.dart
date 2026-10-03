import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/reminders/presentation/widgets/sections/reminder_settings_section_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';

/// Opens the time dialog of screen 24 (UC-REMINDER-001 A1) on
/// [minuteOfDay]; completes with the chosen minute of the day, or null on
/// Cancel (FE-B5 spec D2, §5.2).
Future<int?> showReminderTimeDialog(
  BuildContext context, {
  required int minuteOfDay,
}) => showMxDialog<int>(
  context,
  builder: (_) => ReminderTimeDialogWidget(minuteOfDay: minuteOfDay),
);

/// An hour stepper 0–23 and a minute stepper 0–59, each repeating on hold
/// and typeable; a typed value out of range marks its stepper, says the range
/// under it and keeps Save off until a valid value is typed or a step clears
/// it.
class ReminderTimeDialogWidget extends StatefulWidget {
  const ReminderTimeDialogWidget({super.key, required this.minuteOfDay});

  final int minuteOfDay;

  @override
  State<ReminderTimeDialogWidget> createState() =>
      _ReminderTimeDialogWidgetState();
}

class _ReminderTimeDialogWidgetState extends State<ReminderTimeDialogWidget> {
  static const int _lastHour = 23;
  static const int _lastMinute = 59;
  static const int _digits = 2;

  late int _hour = widget.minuteOfDay ~/ Duration.minutesPerHour;
  late int _minute = widget.minuteOfDay % Duration.minutesPerHour;
  var _isHourInvalid = false;
  var _isMinuteInvalid = false;

  bool get _canSave => !_isHourInvalid && !_isMinuteInvalid;

  int get _chosen => _hour * Duration.minutesPerHour + _minute;

  /// Digits within 0–[last] set the value; anything else marks it invalid.
  (int, bool) _typed(String text, int current, int last) {
    final value = int.tryParse(text);
    if (value == null || value < 0 || value > last) return (current, true);
    return (value, false);
  }

  /// A step starts again from the number the stepper shows, so it also clears
  /// a typed value that was out of range (SP2b 2.35).
  void _stepHour(int by) => setState(() {
    _hour += by;
    _isHourInvalid = false;
  });

  void _stepMinute(int by) => setState(() {
    _minute += by;
    _isMinuteInvalid = false;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      title: l10n.reminderTimeDialogTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.control,
        children: [
          _labelled(
            context,
            l10n.reminderHour,
            MxStepper(
              value: _hour,
              valueLabel: l10n.reminderHour,
              editHint: l10n.commonEdit,
              decrementLabel: l10n.reminderEarlierHour,
              incrementLabel: l10n.reminderLaterHour,
              maxDigits: _digits,
              // A clock reads 07 : 05 (critique 2026-09-30 part 3d-2).
              minDigits: 2,
              isInvalid: _isHourInvalid,
              onDecrement: _hour > 0 ? () => _stepHour(-1) : null,
              onIncrement: _hour < _lastHour ? () => _stepHour(1) : null,
              onValueSubmitted: (text) {
                final (hour, isInvalid) = _typed(text, _hour, _lastHour);
                setState(() {
                  _hour = hour;
                  _isHourInvalid = isInvalid;
                });
              },
            ),
            problem: _isHourInvalid ? l10n.reminderHourRange : null,
          ),
          _labelled(
            context,
            l10n.reminderMinute,
            MxStepper(
              value: _minute,
              valueLabel: l10n.reminderMinute,
              editHint: l10n.commonEdit,
              decrementLabel: l10n.reminderEarlierMinute,
              incrementLabel: l10n.reminderLaterMinute,
              maxDigits: _digits,
              // A clock reads 07 : 05 (critique 2026-09-30 part 3d-2).
              minDigits: 2,
              isInvalid: _isMinuteInvalid,
              onDecrement: _minute > 0 ? () => _stepMinute(-1) : null,
              onIncrement: _minute < _lastMinute ? () => _stepMinute(1) : null,
              onValueSubmitted: (text) {
                final (minute, isInvalid) = _typed(text, _minute, _lastMinute);
                setState(() {
                  _minute = minute;
                  _isMinuteInvalid = isInvalid;
                });
              },
            ),
            problem: _isMinuteInvalid ? l10n.reminderMinuteRange : null,
          ),
          Text(
            reminderTimeLabel(context, _chosen),
            style: context.textStyles.contentTitle,
          ),
        ],
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(),
        confirmLabel: l10n.reminderTimeSave,
        onConfirm: _canSave ? () => Navigator.of(context).pop(_chosen) : null,
      ),
    );
  }

  Widget _labelled(
    BuildContext context,
    String label,
    Widget stepper, {
    String? problem,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(child: Text(label, style: context.textStyles.settingsLabel)),
          stepper,
        ],
      ),
      if (problem != null) MxFieldMessage(message: problem),
    ],
  );
}
