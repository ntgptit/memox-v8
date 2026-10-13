import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
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
      header: Padding(
        padding: EdgeInsets.fromLTRB(
          context.dimens.space24,
          context.dimens.space4,
          context.dimens.space24,
          context.dimens.space12,
        ),
        child: Text(l10n.cardFlag, style: context.texts.titleSmall),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.dimens.space8),
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
