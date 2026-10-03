import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Asks before Reset app options (UC-SETTINGS-001 A3) and runs it. The
/// toasts are screen 23's.
Future<void> showSettingsResetDialog(BuildContext context) =>
    showMxDialog<void>(
      context,
      builder: (_) => const SettingsResetDialogWidget(),
    );

/// The reset confirmation of kit 23: what goes back to its default, and
/// that learning progress is not touched (BR-SETTINGS-008, BR-SRS-022).
/// While it runs, nothing can look like a cancel.
class SettingsResetDialogWidget extends ConsumerStatefulWidget {
  const SettingsResetDialogWidget({super.key});

  @override
  ConsumerState<SettingsResetDialogWidget> createState() =>
      _SettingsResetDialogWidgetState();
}

class _SettingsResetDialogWidgetState
    extends ConsumerState<SettingsResetDialogWidget> {
  var _isResetting = false;

  /// The last reset wrote nothing: the banner shows and the confirm reads
  /// Retry (SP2b 2.33).
  var _hasFailed = false;

  Future<void> _reset() async {
    if (_isResetting) return;
    setState(() {
      _isResetting = true;
      _hasFailed = false;
    });
    // `reset()` answers false for any failed write and reports a non-Failure
    // itself (the controller is the one place that does), so it never throws.
    final hasReset = await ref
        .read(settingsControllerProvider.notifier)
        .reset();
    if (!mounted) return;
    if (hasReset) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isResetting = false;
      _hasFailed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      // While it runs, nothing may look like a cancel (BR-SETTINGS-008).
      isHeld: _isResetting,
      title: l10n.settingsResetTitle,
      body: l10n.settingsResetBody,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.grouped,
        children: [
          if (_hasFailed)
            MxInlineBanner(
              tone: MxBannerTone.warning,
              hasMargin: false,
              message: l10n.settingsResetFailed,
            ),
          MxNote(icon: AppIcons.safe, text: l10n.settingsResetSafe),
        ],
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: _isResetting ? null : () => Navigator.of(context).pop(),
        confirmLabel: l10n.settingsResetConfirm,
        onConfirm: () => unawaited(_reset()),
        isConfirmLoading: _isResetting,
      ),
    );
  }
}
