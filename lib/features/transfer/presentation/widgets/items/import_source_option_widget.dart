import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

/// One of the two sources of step 1 (kit 11): a file or pasted text. The
/// chosen one is the selected card.
class ImportSourceOptionWidget extends StatelessWidget {
  const ImportSourceOptionWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.isSelected,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final String hint;
  final bool isSelected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Semantics(
      selected: isSelected,
      button: true,
      child: MxCard(
        isFullBleed: true,
        isSelected: isSelected,
        child: MxRowInk(
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.grouped),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.micro,
              children: [
                MxIconTile(icon: icon),
                const SizedBox(height: AppSpacing.micro),
                Text(label, style: styles.contentTitle),
                Text(hint, style: styles.rowDescription),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
