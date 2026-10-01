import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';

/// The centred glyph and caption stating a turn's rule (kit
/// SessionFooterHint). Study-local, not shared. The glyph sits inline before
/// the first line and wraps with the text, and the hint always reserves two
/// lines, so the CTA above it stands in one place in every mode (critique
/// 2026-09-30 part 3c-2, R6); a third line still grows it. It steps aside
/// while the keyboard is up so the answer field keeps the room.
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
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // The reserve: two lines laid out as a hint lays them out, glyph
          // slot included, never shown and never read.
          Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Text.rich(
              const TextSpan(
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: _GlyphSlot(
                      child: SizedBox.square(dimension: AppIconSize.inline),
                    ),
                  ),
                  TextSpan(text: '\n'),
                ],
              ),
              style: style,
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _GlyphSlot(
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
        ],
      ),
    );
  }
}

/// The glyph's place before the first line, with its gap to the text.
class _GlyphSlot extends StatelessWidget {
  const _GlyphSlot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: AppSpacing.control),
    child: child,
  );
}
