import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/shared/widgets/mx_term_line.dart';

/// The card editor's "Add details" disclosure (kit 08): a plus, the label
/// and the fields it opens, and a chevron, in an outlined box. The kit's
/// dashed edge is solid here: there is no dashed-border token (§9 row 101).
class CardAddDetailsWidget extends StatelessWidget {
  const CardAddDetailsWidget({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final radius = context.radii.md;
    final glyph = IconThemeData(
      color: context.status.accentMark,
      size: context.dimens.sizeIconInline,
    );
    // The press layer and the focus outline keep to the rounded box.
    return ClipRRect(
      borderRadius: radius,
      child: MxRowInk(
        onTap: onPressed,
        borderRadius: radius,
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
              color: context.colors.border,
              width: context.hairline,
            ),
          ),
          child: IconTheme.merge(
            data: glyph,
            child: Row(
              spacing: context.dimens.space8,
              children: [
                const Icon(AppIcons.add),
                Expanded(
                  // The link, then its fields as whole terms (The Wrap Rule).
                  child: MxTermLine(
                    lead: MxTermLead.label(l10n.cardAddDetails),
                    terms: [
                      for (final field in l10n.cardAddDetailsFields.split(
                        MxTermLine.separator,
                      ))
                        MxTerm(field),
                    ],
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
