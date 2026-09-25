import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';

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
    this.title,
    this.titleWidget,
    this.density = MxAppBarDensity.screen,
    this.leading,
    this.actions = const [],
  }) : assert(
         (title == null) != (titleWidget == null),
         'MxAppBar takes a title or a titleWidget, not both',
       );

  final String? title;

  /// Takes the title's place and its width, such as the search field of
  /// screen 04. It brings its own semantics; no header flag is added.
  final Widget? titleWidget;
  final MxAppBarDensity density;

  /// Usually an MxIconButton (back, or close in selection mode).
  final Widget? leading;

  /// MxIconButtons or compact MxButtons; never dropped for the title. A
  /// trailing MxButton ends on the gutter, as the kit's text actions do; an
  /// icon's 48 touch area already insets its glyph.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final isContent = density == MxAppBarDensity.content;
    final styles = context.textStyles;
    final side = isContent ? AppSpacing.control : AppSpacing.gutter;
    final endsOnText = actions.lastOrNull is MxButton;
    return ColoredBox(
      color: context.colors.surface,
      child: SafeArea(
        bottom: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.appBar),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: side,
              end: endsOnText ? AppSpacing.gutter : side,
            ),
            child: Row(
              spacing: AppSpacing.micro,
              children: [
                ?leading,
                Expanded(
                  child:
                      titleWidget ??
                      Semantics(
                        header: true,
                        child: Text(
                          title!,
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
