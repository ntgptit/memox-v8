import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';

/// The centred glyph and caption stating a turn's rule (kit
/// SessionFooterHint). Study-local, not shared. Two lines at most, glyph on
/// the first; it steps aside while the keyboard is up so the answer field
/// keeps the room.
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.control,
        children: [
          IconTheme.merge(
            data: IconThemeData(color: style.color, size: AppIconSize.inline),
            child: ExcludeSemantics(child: Icon(icon)),
          ),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              semanticsLabel: text,
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
