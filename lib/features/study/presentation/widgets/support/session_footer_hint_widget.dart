import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';

/// The centred glyph and caption stating a turn's rule (kit
/// SessionFooterHint). Study-local, not shared. The glyph sits inline before
/// the first line and wraps with the text (critique 2026-09-30 part 3c-2,
/// R6). Every hint is one line at normal size, in English and Vietnamese, so
/// the CTA above it stands in one place in every mode with no empty line
/// reserved under it (owner, 3c-2 golden review); a wrapped hint still grows.
/// It steps aside while the keyboard is up so the answer field keeps the room.
class SessionFooterHintWidget extends StatelessWidget {
  const SessionFooterHintWidget({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (MxAppShell.isTypingOf(context)) {
      return const SizedBox.shrink();
    }
    final style = context.textStyles.sessionHint;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.control,
        AppSpacing.gutter,
        AppSpacing.gutter,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: AppSpacing.control,
                ),
                child: IconTheme.merge(
                  data: IconThemeData(
                    color: style.color,
                    size: AppIconSize.inline,
                  ),
                  child: ExcludeSemantics(child: Icon(icon)),
                ),
              ),
            ),
            TextSpan(text: text),
          ],
        ),
        semanticsLabel: text,
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}
