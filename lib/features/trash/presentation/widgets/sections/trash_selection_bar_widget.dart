import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';

/// Screen 06's bar while selecting: Restore the selection after asking
/// where, or delete it for good (UC-TRASH-001 A2). Both wait for a pick.
class TrashSelectionBarWidget extends StatelessWidget {
  const TrashSelectionBarWidget({
    super.key,
    required this.count,
    required this.onRestore,
    required this.onPurge,
  });

  final int count;
  final VoidCallback onRestore;
  final VoidCallback onPurge;

  /// Kit 06: Restore 1.3, Delete for good 1.
  static const int _restoreShare = 13;
  static const int _purgeShare = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasPick = count > 0;
    return MxFooterBar(
      child: MxActionPair(
        leading: MxButton(
          label: l10n.trashRestoreSelected(count),
          icon: AppIcons.restore,
          isBlock: true,
          isSingleLine: true,
          onPressed: hasPick ? onRestore : null,
        ),
        trailing: MxButton(
          label: l10n.trashPurgeSelected,
          icon: AppIcons.delete,
          tone: MxButtonTone.destructive,
          isBlock: true,
          isSingleLine: true,
          onPressed: hasPick ? onPurge : null,
        ),
        leadingFlex: _restoreShare,
        trailingFlex: _purgeShare,
      ),
    );
  }
}
