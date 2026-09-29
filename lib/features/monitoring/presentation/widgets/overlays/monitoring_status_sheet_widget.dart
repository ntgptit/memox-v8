import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// Opens the triage sheet for changing a log to [target] and returns the
/// note typed (empty for none) once confirmed, or null when it is dismissed.
Future<String?> showMonitoringStatusSheet(
  BuildContext context, {
  required LogStatus target,
}) => showMxBottomSheet<String>(
  context,
  builder: (_) => MonitoringStatusSheetWidget(target: target),
);

/// Mark fixed or Reopen, with an optional note (monitoring spec §3.3).
class MonitoringStatusSheetWidget extends StatefulWidget {
  const MonitoringStatusSheetWidget({super.key, required this.target});

  final LogStatus target;

  @override
  State<MonitoringStatusSheetWidget> createState() =>
      _MonitoringStatusSheetWidgetState();
}

class _MonitoringStatusSheetWidgetState
    extends State<MonitoringStatusSheetWidget> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = switch (widget.target) {
      LogStatus.fixed => l10n.monitoringMarkFixed,
      LogStatus.open => l10n.monitoringReopen,
    };
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Text(title, style: context.textStyles.compactTitle),
      ),
      footer: MxSheetActions(
        isInSheet: true,
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(),
        confirmLabel: title,
        onConfirm: () => Navigator.of(context).pop(_note.text.trim()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: MxTextField(
          controller: _note,
          label: l10n.monitoringNoteLabel,
          hintText: l10n.monitoringNoteHint,
        ),
      ),
    );
  }
}
