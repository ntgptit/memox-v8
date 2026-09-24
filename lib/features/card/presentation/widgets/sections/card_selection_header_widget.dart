import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// Close and the selected count, pinned above the list while selecting
/// (ruling P3-L1).
class CardSelectionHeaderWidget extends StatelessWidget {
  const CardSelectionHeaderWidget({
    super.key,
    required this.count,
    required this.onClose,
  });

  final int count;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.micro,
        AppSpacing.micro,
        AppSpacing.gutter,
        AppSpacing.micro,
      ),
      child: Row(
        spacing: AppSpacing.control,
        children: [
          MxIconButton(
            icon: AppIcons.close,
            semanticLabel: l10n.cardSelectionClose,
            onPressed: onClose,
          ),
          Expanded(
            // TalkBack reads the new count as it changes.
            child: Semantics(
              liveRegion: true,
              child: Text(
                l10n.cardSelectedCount(count),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.compactTitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
