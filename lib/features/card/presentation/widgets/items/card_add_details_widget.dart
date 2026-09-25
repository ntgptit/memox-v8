import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

/// The card editor's "Add details" disclosure (kit 08): a sparkle, the label
/// and the fields it opens, and a chevron, in an outlined box. The kit's
/// dashed edge is solid here: there is no dashed-border token (§9 row 101).
class CardAddDetailsWidget extends StatelessWidget {
  const CardAddDetailsWidget({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final colors = context.colors;
    final radius = BorderRadius.circular(AppRadius.md);
    final glyph = IconThemeData(
      color: colors.primary,
      size: AppIconSize.inline,
    );
    // The ripple paints on this Material, so it keeps to the rounded box.
    return Material(
      type: MaterialType.transparency,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: MxRowInk(
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSize.touchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.control,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: colors.outlineVariant,
              width: AppStroke.hairline,
            ),
          ),
          child: IconTheme.merge(
            data: glyph,
            child: Row(
              spacing: AppSpacing.control,
              children: [
                const Icon(AppIcons.details),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: l10n.cardAddDetails,
                          style: styles.disclosureLabel,
                        ),
                        const WidgetSpan(
                          child: SizedBox(width: AppSpacing.control),
                        ),
                        TextSpan(
                          text: l10n.cardAddDetailsFields,
                          style: styles.rowDescription,
                        ),
                      ],
                    ),
                  ),
                ),
                const Icon(AppIcons.chevronDown),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
