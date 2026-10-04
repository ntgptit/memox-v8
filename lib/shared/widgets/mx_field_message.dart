import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Whether a field's message stops the save or only warns.
enum MxFieldMessageTone { error, warning }

/// One line under a field: a glyph and the message in the tone's role
/// (`error` or `warning`), announced when it appears.
class MxFieldMessage extends StatelessWidget {
  const MxFieldMessage({
    required this.message,
    this.tone = MxFieldMessageTone.error,
    super.key,
  });

  final String message;
  final MxFieldMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color ink, IconData glyph) = switch (tone) {
      MxFieldMessageTone.error => (context.colors.error, Icons.error_outline),
      MxFieldMessageTone.warning => (
        context.semanticColors.warning,
        Icons.warning_amber_outlined,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Icon(glyph, size: AppIconSize.small, color: ink),
          const SizedBox(width: AppSpacing.micro),
          Expanded(
            child: Text(
              message,
              style: context.texts.bodySmall?.apply(color: ink),
            ),
          ),
        ],
      ),
    );
  }
}
