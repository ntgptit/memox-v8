import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A failure, or a limit reached (not a failure).
enum MxFieldMessageTone { error, warning }

/// The single validation line under a field: an alert glyph and the message,
/// in the supporting-text role (`bodySmall`), starting on the field's text
/// inset. It wraps rather than truncating, because it is the one thing the
/// user must read in full, and it is announced when it appears.
class MxFieldMessage extends StatelessWidget {
  const MxFieldMessage({
    super.key,
    required this.message,
    this.tone = MxFieldMessageTone.error,
  });

  final String message;
  final MxFieldMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final (glyph, foreground) = switch (tone) {
      MxFieldMessageTone.error => (context.colors.error, context.colors.error),
      // A glyph takes the text colour, never the amber fill (SW-REV-001).
      MxFieldMessageTone.warning => (
        context.mxColors.warning,
        context.mxColors.warning,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: context.dimens.space16,
          top: context.dimens.space4,
          end: context.dimens.space16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: context.dimens.space4,
          children: [
            Icon(
              AppIcons.alert,
              size: context.dimens.sizeIconInline,
              color: glyph,
            ),
            Expanded(
              child: Text(
                message,
                style: context.texts.bodySmall?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
