import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// One calm information line (DESIGN.md, Containers › MxNote): the muted fill
/// with a hairline edge, or, as [MxNote.hint], the footnote form with neither.
/// A one-time note offers a close button; storing that it was dismissed is
/// the caller's.
class MxNote extends StatelessWidget {
  const MxNote({
    required this.text,
    this.onDismiss,
    this.dismissLabel,
    super.key,
  }) : isHint = false,
       assert(
         (onDismiss == null) == (dismissLabel == null),
         'A dismissible note names its close button.',
       );

  /// The footnote under a section or a form: no fill and no edge.
  const MxNote.hint({required this.text, super.key})
    : isHint = true,
      onDismiss = null,
      dismissLabel = null;

  final String text;
  final bool isHint;
  final VoidCallback? onDismiss;

  /// The close button's name, read aloud and shown as its tooltip.
  final String? dismissLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextStyle? style = isHint
        ? context.texts.bodySmall?.apply(color: colors.onSurfaceVariant)
        : context.texts.bodyMedium?.apply(color: colors.onSurfaceVariant);
    final VoidCallback? dismiss = onDismiss;
    final Widget line = Row(
      spacing: AppSpacing.control,
      children: [
        Icon(
          Icons.info_outline,
          size: AppIconSize.small,
          color: colors.onSurfaceVariant,
        ),
        Expanded(child: Text(text, style: style)),
        if (dismiss != null)
          MxIconButton(
            icon: Icons.close,
            semanticLabel: dismissLabel!,
            onPressed: dismiss,
          ),
      ],
    );
    if (isHint) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.micro),
        child: line,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colors.outlineVariant,
          width: AppStroke.hairline,
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.grouped,
          end: dismiss == null ? AppSpacing.grouped : AppSpacing.micro,
          top: dismiss == null ? AppSpacing.grouped : AppSpacing.micro,
          bottom: dismiss == null ? AppSpacing.grouped : AppSpacing.micro,
        ),
        child: line,
      ),
    );
  }
}
