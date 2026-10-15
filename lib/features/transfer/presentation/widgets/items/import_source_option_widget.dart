import 'package:flutter/material.dart';
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
    return MxCard(
      isFullBleed: true,
      isSelected: isSelected,
      child: MxRowInk(
        onTap: onSelected,
        // No tap while a file is read: the option says it is disabled, keeps
        // its selected state and is not dimmed.
        isEnabled: onSelected != null,
        shouldDimWhenDisabled: false,
        isSelected: isSelected,
        child: Padding(
          padding: EdgeInsets.all(context.dimens.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: context.dimens.space4,
            children: [
              MxIconTile(icon: icon),
              SizedBox(height: context.dimens.space4),
              Text(label, style: context.texts.titleMedium),
              Text(
                hint,
                style: context.texts.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
