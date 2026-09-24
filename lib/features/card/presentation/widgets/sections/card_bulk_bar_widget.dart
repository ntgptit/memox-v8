import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/shared/widgets/mx_unavailable.dart';

/// One command of the bulk bar; a null [onTap] is not available yet and
/// draws dimmed (spec A4).
typedef CardBulkAction = ({IconData icon, String label, VoidCallback? onTap});

/// The card list's bulk bar: the handoff's 5-up icon grid, one icon and
/// label per equal column (ruling P3-L7).
class CardBulkBarWidget extends StatelessWidget {
  const CardBulkBarWidget({super.key, required this.actions});

  final List<CardBulkAction> actions;

  @override
  Widget build(BuildContext context) => MxFooterBar(
    child: Row(
      children: [
        for (final action in actions)
          Expanded(child: _BulkCommand(action: action)),
      ],
    ),
  );
}

class _BulkCommand extends StatelessWidget {
  const _BulkCommand({required this.action});

  final CardBulkAction action;

  @override
  Widget build(BuildContext context) {
    final onTap = action.onTap;
    final command = MergeSemantics(
      child: Semantics(
        button: true,
        enabled: onTap != null,
        child: MxRowInk(
          onTap: onTap,
          isEnabled: onTap != null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.control),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.micro,
              children: [
                Icon(action.icon),
                Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.textStyles.rowDescription,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (onTap != null) return command;
    return MxUnavailable(
      hint: context.l10n.commonNotAvailableYet,
      child: command,
    );
  }
}
