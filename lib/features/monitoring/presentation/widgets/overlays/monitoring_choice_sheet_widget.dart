import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// One choice of a filter sheet: the value and the name it shows.
@immutable
final class MonitoringChoice<T> {
  const MonitoringChoice(this.value, this.label);

  final T value;
  final String label;
}

/// Opens a filter sheet (monitoring spec §3.2) and returns the choice made,
/// or null when it is dismissed. [isMulti] lets several be chosen, as toggles
/// (an option row is a radio, which says "one of"); otherwise one is, as
/// option rows. Reset puts the sheet back to [resetTo]; Apply returns.
Future<Set<T>?> showMonitoringChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<MonitoringChoice<T>> choices,
  required Set<T> selected,
  required Set<T> resetTo,
  required bool isMulti,
}) => showMxBottomSheet<Set<T>>(
  context,
  builder: (_) => MonitoringChoiceSheetWidget<T>(
    title: title,
    choices: choices,
    selected: selected,
    resetTo: resetTo,
    isMulti: isMulti,
  ),
);

class MonitoringChoiceSheetWidget<T> extends StatefulWidget {
  const MonitoringChoiceSheetWidget({
    super.key,
    required this.title,
    required this.choices,
    required this.selected,
    required this.resetTo,
    required this.isMulti,
  });

  final String title;
  final List<MonitoringChoice<T>> choices;
  final Set<T> selected;
  final Set<T> resetTo;
  final bool isMulti;

  @override
  State<MonitoringChoiceSheetWidget<T>> createState() =>
      _MonitoringChoiceSheetWidgetState<T>();
}

class _MonitoringChoiceSheetWidgetState<T>
    extends State<MonitoringChoiceSheetWidget<T>> {
  late Set<T> _picked = {...widget.selected};

  void _toggle(T value, {required bool isOn}) => setState(
    () => _picked = isOn ? {..._picked, value} : ({..._picked}..remove(value)),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxBottomSheet(
      title: widget.title,
      footer: MxSheetActions.custom(
        isInSheet: true,
        children: [
          Expanded(
            child: MxButton(
              label: l10n.monitoringReset,
              tone: MxButtonTone.outline,
              isBlock: true,
              onPressed: () => setState(() => _picked = {...widget.resetTo}),
            ),
          ),
          Expanded(
            child: MxButton(
              label: l10n.monitoringApply,
              isBlock: true,
              onPressed: () => Navigator.of(context).pop(_picked),
            ),
          ),
        ],
      ),
      child: widget.isMulti ? _toggles() : _options(),
    );
  }

  Widget _toggles() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
    child: MxSection(
      children: [
        for (final choice in widget.choices)
          MxSettingsRow(
            label: choice.label,
            trailing: MxToggle(
              isOn: _picked.contains(choice.value),
              semanticLabel: choice.label,
              onChanged: (isOn) => _toggle(choice.value, isOn: isOn),
            ),
          ),
      ],
    ),
  );

  Widget _options() => Column(
    children: [
      for (final choice in widget.choices)
        MxOptionRow(
          title: choice.label,
          isSelected: _picked.contains(choice.value),
          onSelected: () => setState(() => _picked = {choice.value}),
          hasDivider: choice != widget.choices.last,
        ),
    ],
  );
}
