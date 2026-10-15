import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/core/theme/theme_rules.dart';

/// The card editor's "Add details" disclosure (kit 08): a plus, the label
/// and the fields it opens, and a chevron, in an outlined box. The kit's
/// dashed edge is solid here: there is no dashed-border token (§9 row 101).
class CardAddDetailsWidget extends StatelessWidget {
  const CardAddDetailsWidget({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final radius = BorderRadius.circular(context.dimens.radiusMd);
    final glyph = IconThemeData(
      color: context.accentColor,
      size: context.dimens.sizeIconInline,
    );
    // The ripple paints on this Material, so it keeps to the rounded box.
    return Material(
      type: MaterialType.transparency,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: MxRowInk(
        onTap: onPressed,
        child: Container(
          constraints: BoxConstraints(minHeight: context.dimens.sizeControl),
          padding: EdgeInsets.symmetric(
            horizontal: context.dimens.space16,
            vertical: context.dimens.space8,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            // The control edge, as the fields beside it (DEV-166).
            border: Border.all(
              color: context.colors.outline,
              width: context.dimens.strokeHairline,
            ),
          ),
          child: IconTheme.merge(
            data: glyph,
            child: Row(
              spacing: context.dimens.space8,
              children: [
                const Icon(AppIcons.add),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: l10n.cardAddDetails,
                          style: context.texts.labelMedium?.copyWith(
                            color: context.accentColor,
                          ),
                        ),
                        WidgetSpan(
                          child: SizedBox(width: context.dimens.space8),
                        ),
                        TextSpan(
                          text: l10n.cardAddDetailsFields,
                          style: context.texts.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
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
