import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

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

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final messageStyle = context.textStyles.bannerMessage(isLead: true);
    // The glyph centres on the first line at any text scale.
    final firstLine =
        MediaQuery.textScalerOf(context).scale(messageStyle.fontSize!) *
        messageStyle.height!;
    final isOneLine = actions.length == 1;
    // On the one-line form the Row centres the glyph itself.
    final glyphInset = isOneLine
        ? 0.0
        : math.max(0.0, (firstLine - AppIconSize.inline) / 2);
    final line = Row(
      crossAxisAlignment: isOneLine
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      spacing: AppSpacing.control,
      children: [
        Padding(
          padding: EdgeInsets.only(top: glyphInset),
          child: Icon(
            AppIcons.alert,
            size: AppIconSize.inline,
            // A glyph is ink, never the amber fill (T1, SW-REV-001).
            color: context.derivedColors.warningInk,
          ),
        ),
        Expanded(child: Text(message, style: messageStyle)),
        if (isOneLine) actions.single,
      ],
    );
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: AppDecorations.warningCard(
          scheme,
          context.derivedColors,
        ).copyWith(boxShadow: AppShadows.overlay(scheme)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.touchTarget),
          child: Padding(
            // A DecoratedBox border does not inset its child.
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gutter + AppStroke.hairline,
              vertical: AppSpacing.control + AppStroke.hairline,
            ),
            child: actions.length < 2
                ? line
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.control,
                    children: [
                      line,
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: AppSpacing.control,
                        runSpacing: AppSpacing.control,
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
