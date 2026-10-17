import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/shared/widgets/mx_route_name.dart';

/// The top chrome: leading control, flexible title (with an optional
/// subtitle line under it), trailing actions. The title is the only slot
/// that gives up width; it ellipsises on one line.
///
/// Placed in-flow by MxAppShell, which paints its ground (the page
/// background, with a hairline under it once content scrolls under it)
/// full-bleed behind it. It is `sizeAppBar` tall at minimum and grows only
/// when text scaling makes the title taller (ruling R1). The title is the
/// screen title role, the controls ForUI's ghost icon buttons
/// (MxIconButton).
///
/// The icon glyphs sit on the screen margin, in line with the body: the
/// control's touch area reaches out past the margin by its inset.
class MxAppBar extends StatelessWidget {
  const MxAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.leading,
    this.actions = const [],
    this.isLastActionText = false,
    this.isTitleField = false,
    this.isTitleWidgetRouteName = false,
  }) : assert(
         (title == null) != (titleWidget == null),
         'MxAppBar takes a title or a titleWidget, not both',
       ),
       assert(
         subtitle == null || title != null,
         'A subtitle goes under a title, not under a titleWidget',
       ),
       assert(
         !isTitleWidgetRouteName || titleWidget != null,
         'Only a titleWidget is asked to name the route; a title always does',
       );

  final String? title;

  /// One line under [title] (the label role, muted), such as the
  /// level and section of a TOPIK test (screens 34, 36). It is read in the
  /// title's heading node, so the route is named once with both (Q-P6-2).
  final String? subtitle;

  /// Takes the title's place and its width, such as the search field of
  /// screen 04. It brings its own semantics; no header flag is added. Say
  /// [isTitleField] when it is a search field.
  final Widget? titleWidget;

  /// Usually an MxIconButton (back, or close in selection mode).
  final Widget? leading;

  /// MxIconButtons or compact MxButtons; never dropped for the title. They
  /// may be wrapper widgets, so the bar is told what the last one is rather
  /// than reading its type.
  final List<Widget> actions;

  /// The last of [actions] is a text button. It ends on the screen margin, as
  /// the kit's text actions do; without this the last action is an icon,
  /// whose 48 touch area already insets its glyph.
  final bool isLastActionText;

  /// The [titleWidget] is a search field. The bar keeps `space8` above and
  /// below it, so it grows rather than pressing a `sizeSearch` field against
  /// its edges, and the field ends on the screen margin so its border lines
  /// up with the content below.
  final bool isTitleField;

  /// The [titleWidget] names the route, as a [title] always does (DEV-393),
  /// such as the deck's name on screen 14 or the search field on screen 04.
  /// Off for a bar that is not the top of its route, such as a selection
  /// bar, and where the screen names the route itself.
  final bool isTitleWidgetRouteName;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final margin = context.screenMargin;
    // A control's touch area reaches past its glyph by this much, so the
    // glyph, not the touch area, lands on the margin.
    final glyphInset = (dimens.sizeControl - dimens.sizeIcon) / 2;
    final endsOnIcon = actions.isNotEmpty && !isLastActionText;
    return SafeArea(
      bottom: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: dimens.sizeAppBar),
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            // A bar without a leading control starts its title on the screen
            // margin, in line with the body (critique 2026-09-30 part 3c-1).
            start: leading == null ? margin : margin - glyphInset,
            top: isTitleField ? dimens.space8 : 0,
            end: endsOnIcon && !isTitleField ? margin - glyphInset : margin,
            bottom: isTitleField ? dimens.space8 : 0,
          ),
          child: Row(
            spacing: dimens.space4,
            children: [
              ?leading,
              Expanded(
                child: switch (titleWidget) {
                  final widget? when isTitleWidgetRouteName => MxRouteName(
                    child: widget,
                  ),
                  final widget? => widget,
                  null => MxRouteName(isHeader: true, child: _title(context)),
                },
              ),
              if (actions.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: dimens.space4,
                  children: actions,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The title, with its subtitle under it when there is one.
  Widget _title(BuildContext context) {
    final titleText = Text(
      title!,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.texts.screenTitle,
    );
    final subtitle = this.subtitle;
    if (subtitle == null) return titleText;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleText,
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.texts.label.copyWith(
            color: context.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
