import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';

/// The in-flow commit bar (Save, Done, bulk actions): a sibling of the
/// scroll, so it never overlaps content. It owns the gesture inset below
/// itself; call sites never re-declare it. The caption steps aside while
/// the keyboard is up.
///
/// The caption sits at full ink: it can carry a reason, such as the offline
/// note (Contrast Floor Rule).
class MxFooterBar extends StatelessWidget {
  const MxFooterBar({super.key, required this.child, this.caption});

  /// Usually one block MxButton, or a row of them.
  final Widget child;

  /// The calm line under the actions.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    // While the keyboard is up the field needs the height; the caption is a
    // calm restatement of the rule and waits (audit 2026-09-29, pattern 1).
    final isTyping = MxAppShell.isTypingOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(
            color: context.derivedColors.ghostBorder,
            width: AppStroke.hairline,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.control,
          AppSpacing.gutter,
          AppSpacing.gutter + inset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.control,
          children: [
            child,
            if (caption case final caption? when !isTyping)
              Text(
                caption,
                textAlign: TextAlign.center,
                style: context.textStyles.footerCaption,
              ),
          ],
        ),
      ),
    );
  }
}
