import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

/// Content bar (a back control and a deck/card name) or screen bar (a screen
/// name). Both are `sizeAppBar` tall, set the title in `titleLarge` and put
/// their icon glyphs on the screen margin; the name says which screen the bar
/// belongs to.
enum MxAppBarDensity { content, screen }

/// The top chrome: leading control, flexible title, trailing actions. The
/// title is the only slot that gives up width; it ellipsises on one line.
///
/// Placed in-flow by MxAppShell, which paints its ground (`surface`, or
/// `surfaceContainer` once content scrolls under it) full-bleed behind it. It
/// is `sizeAppBar` tall at minimum and grows only when text scaling makes the
/// title taller (ruling R1).
///
/// The icon glyphs sit on the screen margin, in line with the body: the
/// control's touch area reaches out past the margin by its inset. The leading
/// control is `onSurface`, the trailing icons `onSurfaceVariant`.
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
  /// search field keeps 8 above and below it, so the bar grows rather
  /// than pressing a `sizeSearch` field against its edges, and ends on the screen margin so
  /// its border lines up with the content below.
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
    final dimens = context.dimens;
    final margin = context.screenMargin;
    // A control's touch area reaches past its glyph by this much, so the
    // glyph, not the touch area, lands on the margin.
    final glyphInset = (dimens.sizeControl - dimens.sizeIcon) / 2;
    final endsOnIcon = actions.isNotEmpty && actions.last is! MxButton;
    final holdsField = titleWidget is MxSearchField;
    return SafeArea(
      bottom: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: dimens.sizeAppBar),
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            // A bar without a leading control starts its title on the screen
            // margin, in line with the body (critique 2026-09-30 part 3c-1).
            start: leading == null ? margin : margin - glyphInset,
            top: holdsField ? dimens.space8 : 0,
            end: endsOnIcon && !holdsField ? margin - glyphInset : margin,
            bottom: holdsField ? dimens.space8 : 0,
          ),
          child: Row(
            spacing: dimens.space4,
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
                        style: context.texts.titleLarge,
                      ),
                    ),
              ),
              if (actions.isNotEmpty)
                IconButtonTheme(
                  data: _actionsTheme(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: dimens.space4,
                    children: actions,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The ambient icon button, with the trailing icons in `onSurfaceVariant`.
  IconButtonThemeData _actionsTheme(BuildContext context) {
    final colors = context.colors;
    final disabled = colors.onSurfaceVariant.withValues(
      alpha: context.dimens.opacityDisabledContent,
    );
    final foreground = WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? disabled
          : colors.onSurfaceVariant,
    );
    final ambient = IconButtonTheme.of(context).style ?? const ButtonStyle();
    return IconButtonThemeData(
      style: ambient.copyWith(foregroundColor: foreground),
    );
  }
}
