import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// One calm line stating a product rule. Info tone only: never a warning,
/// never an action. [MxNote.hint] is the footnote form, with no fill and no
/// border, for the line under a section (critique 2026-09-30).
class MxNote extends StatelessWidget {
  const MxNote({
    super.key,
    required this.text,
    this.icon = AppIcons.info,
    this.onDismiss,
    this.dismissLabel,
  }) : isHint = false,
       assert(
         onDismiss == null || dismissLabel != null,
         'a dismissible note names its close button',
       );

  /// A footnote: the glyph and text in the secondary foreground, no box.
  const MxNote.hint({super.key, required this.text, this.icon = AppIcons.info})
    : isHint = true,
      onDismiss = null,
      dismissLabel = null;

  final String text;

  /// The footnote form: no fill, no border, tight padding.
  final bool isHint;

  /// Hides a one-time note for good; the caller stores that it was dismissed.
  final VoidCallback? onDismiss;

  /// The close button's tooltip and TalkBack label; required with
  /// [onDismiss], since a component holds no copy.
  final String? dismissLabel;

  /// The info glyph, or a clock or shield where the rule is about time or
  /// safety.
  final IconData icon;

  static const double _verticalPadding = 10;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.texts.body.copyWith(
      color: context.colors.mutedForeground,
    );
    // The glyph centres on the first line at any text scale.
    final firstLine =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) * style.height!;
    final glyphInset = math.max(
      0.0,
      (firstLine - context.dimens.sizeIconInline) / 2,
    );
    final line = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.dimens.space8,
      children: [
        Padding(
          padding: EdgeInsets.only(top: glyphInset),
          child: Icon(
            icon,
            size: context.dimens.sizeIconInline,
            color: colors.mutedForeground,
          ),
        ),
        Expanded(child: Text(text, style: style)),
        if (onDismiss case final dismiss?)
          MxIconButton(
            icon: AppIcons.close,
            semanticLabel: dismissLabel!,
            onPressed: dismiss,
          ),
      ],
    );
    if (isHint) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: context.dimens.space4),
        child: line,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: context.radii.md,
        border: Border.all(
          color: context.colors.border,
          width: context.hairline,
        ),
      ),
      child: Padding(
        // A DecoratedBox border does not inset its child, so the padding
        // starts after the hairline, as in the kit's CSS box.
        padding: EdgeInsets.symmetric(
          horizontal: context.dimens.space12 + context.hairline,
          vertical: _verticalPadding + context.hairline,
        ),
        child: line,
      ),
    );
  }
}
