import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

/// A standing notice that floats over the page, above its content: one
/// sentence and the compact Buttons that resolve it (SB-U1; owner ruling
/// 2026-09-28, "short, over the content like an alert"). Warning tone only:
/// something waits and nothing was lost. It is not a Snackbar (it stays
/// until its cause is gone) and not an InlineBanner (it takes no room in the
/// page's flow). MxAppShell places it. It wraps and never truncates.
class MxFloatingNotice extends StatelessWidget {
  const MxFloatingNotice({
    super.key,
    required this.message,
    this.actions = const [],
  });

  final String message;

  /// Compact MxButtons. One sits at the end of the message line; more go on
  /// a line of their own under it, at the end.
  final List<Widget> actions;

  /// The Design System defines no shadow for a floating notice; Material's
  /// own elevation casts it, the same in light and dark.
  static const double _elevation = 3;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final messageStyle = context.texts.labelMedium!.copyWith(
      color: context.colors.onSurface,
    );
    // The glyph centres on the first line at any text scale.
    final firstLine =
        MediaQuery.textScalerOf(context).scale(messageStyle.fontSize!) *
        messageStyle.height!;
    final isOneLine = actions.length == 1;
    // On the one-line form the Row centres the glyph itself.
    final glyphInset = isOneLine
        ? 0.0
        : math.max(0.0, (firstLine - context.dimens.sizeIconInline) / 2);
    final line = Row(
      crossAxisAlignment: isOneLine
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      spacing: context.dimens.space8,
      children: [
        Padding(
          padding: EdgeInsets.only(top: glyphInset),
          child: Icon(
            AppIcons.alert,
            size: context.dimens.sizeIconInline,
            // A glyph takes the text colour, never the amber fill (SW-REV-001).
            color: context.mxColors.warning,
          ),
        ),
        Expanded(child: Text(message, style: messageStyle)),
        if (isOneLine) actions.single,
      ],
    );
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: context.mxColors.warning.tintOver(MxTintBase.of(context)),
        elevation: _elevation,
        shadowColor: scheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.dimens.radiusMd),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: context.dimens.sizeControl),
          child: Padding(
            // A DecoratedBox border does not inset its child.
            padding: EdgeInsets.symmetric(
              horizontal: context.screenMargin + context.dimens.strokeHairline,
              vertical: context.dimens.space8 + context.dimens.strokeHairline,
            ),
            child: actions.length < 2
                ? line
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: context.dimens.space8,
                    children: [
                      line,
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: context.dimens.space8,
                        runSpacing: context.dimens.space8,
                        children: actions,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
