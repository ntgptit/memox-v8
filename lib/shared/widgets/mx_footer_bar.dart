import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_term_line.dart';

/// The in-flow commit bar (Save, Done, bulk actions): a sibling of the
/// scroll, so it never overlaps content. It owns the gesture inset below
/// itself; call sites never re-declare it. Its sides are the screen margin, in
/// line with the body above. The caption steps aside while
/// the keyboard is up.
///
/// The caption sits at full strength: it can carry a reason, such as the offline
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
        color: context.colors.background,
        border: Border(
          top: BorderSide(
            color: context.colors.border,
            width: context.hairline,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.screenMargin,
          context.dimens.space8,
          context.screenMargin,
          context.dimens.space16 + inset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: context.dimens.space8,
          children: [
            child,
            if (caption case final caption? when !isTyping)
              // A line of terms wraps between whole terms, with no dot at a
              // line edge (The Wrap Rule).
              MxTermLine.text(
                caption,
                role: MxTermLineRole.meta,
                align: MxTermLineAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
