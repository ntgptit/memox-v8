import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';

/// Ruling P3-L4: the flag is set or cleared, never toggled (BR-CARD-011).
/// Completes with true to set it, false to clear it, null when dismissed.
Future<bool?> showCardFlagSheet(BuildContext context) =>
    showMxBottomSheet<bool>(
      context,
      builder: (_) => const CardFlagSheetWidget(),
    );

class CardFlagSheetWidget extends StatelessWidget {
  const CardFlagSheetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxBottomSheet(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
        child: Column(
          children: [
            MxActionSheetCommandRow(
              icon: AppIcons.flagged,
              label: l10n.cardFlagSet,
              onTap: () => Navigator.of(context).pop(true),
            ),
            MxActionSheetCommandRow(
              icon: AppIcons.flag,
              label: l10n.cardFlagClear,
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
