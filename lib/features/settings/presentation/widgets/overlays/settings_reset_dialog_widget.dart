import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
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
  // MxSheetActions' shares: the confirm keeps its line first.
  static const int _cancelShare = 10;
  static const int _confirmShare = 13;

  var _isResetting = false;

  Future<void> _reset() async {
    if (_isResetting) return;
    setState(() => _isResetting = true);
    await ref.read(settingsControllerProvider.notifier).reset();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: !_isResetting,
      child: MxDialog(
        width: MxDialogWidth.medium,
        title: l10n.settingsResetTitle,
        body: l10n.settingsResetBody,
        content: MxNote(icon: AppIcons.safe, text: l10n.settingsResetSafe),
        // The pair of MxSheetActions, with Cancel off while it runs.
        actions: MxSheetActions.custom(
          children: [
            Expanded(
              child: MxActionPair(
                leading: MxButton(
                  label: l10n.commonCancel,
                  tone: MxButtonTone.outline,
                  isBlock: true,
                  isSingleLine: true,
                  onPressed: _isResetting
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
                trailing: MxButton(
                  label: l10n.settingsResetConfirm,
                  isBlock: true,
                  isSingleLine: true,
                  isLoading: _isResetting,
                  onPressed: _reset,
                ),
                leadingFlex: _cancelShare,
                trailingFlex: _confirmShare,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
