import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Content bar (a back control and a deck/card name) or screen bar (a screen
/// name). Both are 56 tall.
enum MxAppBarDensity { content, screen }

/// The top chrome: leading control, flexible title, trailing actions. The
/// title is the only slot that gives up width; it ellipsises on one line.
///
/// Placed in-flow by MxAppShell. It is 56 tall at minimum and grows only when
/// text scaling makes the title taller (ruling R1).
class MxAppBar extends StatelessWidget {
  const MxAppBar({
    super.key,
    required this.title,
    this.density = MxAppBarDensity.screen,
    this.leading,
    this.actions = const [],
  });

  final String title;
  final MxAppBarDensity density;

  /// Usually an MxIconButton (back, or close in selection mode).
  final Widget? leading;

  /// MxIconButtons or compact MxButtons; never dropped for the title.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final isContent = density == MxAppBarDensity.content;
    final styles = context.textStyles;
    return ColoredBox(
      color: context.colors.surface,
      child: SafeArea(
        bottom: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.appBar),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isContent ? AppSpacing.control : AppSpacing.gutter,
            ),
            child: Row(
              spacing: AppSpacing.micro,
              children: [
                ?leading,
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: isContent
                          ? styles.contentTitle
                          : styles.screenTitle,
                    ),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
