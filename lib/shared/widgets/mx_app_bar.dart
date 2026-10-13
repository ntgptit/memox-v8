import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

/// Content bar (a back control and a deck/card name, titleMedium) or screen
/// bar (a screen name, titleLarge). Both are 64 tall.
enum MxAppBarDensity { content, screen }

/// The top chrome: leading control, flexible title, trailing actions. The
/// title is the only slot that gives up width; it ellipsises on one line.
///
/// Placed in-flow by MxAppShell. It is 64 tall at minimum and grows only when
/// text scaling makes the title taller (ruling R1). Its sides are the
/// screen's margin ("Flashcard Color Tokens" §6).
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
  /// screen 04. It brings its own semantics; no header flag is added. A
  /// search field keeps 4 above and below it, so the 56 field fills the 64
  /// bar, and its sides line up with the content below.
  final Widget? titleWidget;
  final MxAppBarDensity density;

  /// Usually an MxIconButton (back, or close in selection mode).
  final Widget? leading;

  /// MxIconButtons or compact MxButtons; never dropped for the title.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final isContent = density == MxAppBarDensity.content;
    final styles = context.textStyles;
    final side = context.screenMargin;
    final holdsField = titleWidget is MxSearchField;
    return ColoredBox(
      color: context.colors.surface,
      child: SafeArea(
        bottom: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.appBar),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: side,
              top: holdsField ? AppSpacing.micro : 0,
              end: side,
              bottom: holdsField ? AppSpacing.micro : 0,
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
