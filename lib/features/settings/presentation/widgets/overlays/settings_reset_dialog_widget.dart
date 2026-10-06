import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Asks before Reset app options (UC-SETTINGS-001 A3) and runs it through
/// [resetAppOptions]. The toasts are screen 23's.
Future<void> showSettingsResetDialog(
  BuildContext context, {
  required ResetAppOptions resetAppOptions,
}) => showMxDialog<void>(
  context,
  builder: (_) => SettingsResetDialogWidget(resetAppOptions: resetAppOptions),
);

/// The reset confirmation of kit 23: what goes back to its default, and
/// that learning progress is not touched (BR-SETTINGS-008, BR-SRS-022).
/// While it runs, nothing can look like a cancel.
class SettingsResetDialogWidget extends ConsumerStatefulWidget {
  const SettingsResetDialogWidget({super.key, required this.resetAppOptions});

  final ResetAppOptions resetAppOptions;

  @override
  ConsumerState<SettingsResetDialogWidget> createState() =>
      _SettingsResetDialogWidgetState();
}

class _SettingsResetDialogWidgetState
    extends ConsumerState<SettingsResetDialogWidget> {
  var _isResetting = false;

  Future<void> _reset() async {
    if (_isResetting) return;
    setState(() => _isResetting = true);
    await ref
        .read(settingsControllerProvider.notifier)
        .reset(widget.resetAppOptions);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: !_isResetting,
      child: MxDialog(
        title: l10n.settingsResetTitle,
        body: l10n.settingsResetBody,
        content: MxNote(icon: AppIcons.safe, text: l10n.settingsResetSafe),
        actions: MxSheetActions(
          cancelLabel: l10n.commonCancel,
          onCancel: _isResetting ? null : () => Navigator.of(context).pop(),
          confirmLabel: l10n.settingsResetConfirm,
          onConfirm: () => unawaited(_reset()),
          isConfirmLoading: _isResetting,
        ),
      ),
    );
  }
}
