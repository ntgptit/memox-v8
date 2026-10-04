import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/chip_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';
import 'package:memox/shared/widgets/primitives/mx_tap_target.dart';

/// The 28dp pill both chips are drawn as, with a 48 hit area; the two chips
/// differ in meaning, not in geometry.
class MxChipShell extends StatelessWidget {
  const MxChipShell({
    required this.label,
    required this.isSelected,
    required this.isGhost,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final String label;
  final bool isSelected;
  final bool isGhost;
  final VoidCallback onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final style = mxChipColors(
      colors: context.colors,
      isSelected: isSelected,
      isGhost: isGhost,
    );
    final BorderRadius pill = BorderRadius.circular(AppRadius.full);
    final IconData? glyph = trailing;
    return MxTapTarget(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.fill,
          borderRadius: pill,
          border: Border.fromBorderSide(style.edge),
        ),
        child: MxRowInk(
          onTap: onTap,
          borderRadius: pill,
          child: SizedBox(
            height: AppSize.chip,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.control,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A selected filter chip says so without colour.
                  if (isSelected && !isGhost) ...[
                    Icon(
                      Icons.check,
                      size: AppIconSize.small,
                      color: style.content,
                    ),
                    const SizedBox(width: AppSpacing.micro),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.labelSmall?.apply(
                        color: style.content,
                      ),
                    ),
                  ),
                  if (glyph != null) ...[
                    const SizedBox(width: AppSpacing.micro),
                    Icon(glyph, size: AppIconSize.small, color: style.content),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
