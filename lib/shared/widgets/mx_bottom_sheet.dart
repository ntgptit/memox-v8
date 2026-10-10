import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Opens [builder] (usually an MxBottomSheet) on the platform modal route
/// over a 56% scrim, sliding up over 260ms. It opens instantly under reduced
/// motion (ruling O7). A scrim tap or a drag down dismisses it.
Future<T?> showMxBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  // The surface, radius and scrim are the theme's sheet (spec §4.6).
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: AnimationStyle(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppDurations.sheet,
      curve: Easing.standard,
    ),
  );
}

/// The bottom-anchored modal for action lists and pickers. It stops at 85% of
/// the screen:
/// - only [child] scrolls, so [header] and [footer] stay in view (ruling
///   O12);
/// - the fill runs under the gesture bar, and the content stays above it.
///
/// It is a Material, so the ripple of a row inside is visible.
class MxBottomSheet extends StatelessWidget {
  const MxBottomSheet({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.hasGrabber = true,
    this.isHeld = false,
    this.title,
    this.subtitle,
  }) : assert(header == null || title == null, 'a header or a title'),
       assert(subtitle == null || title != null, 'a subtitle needs a title');

  final Widget child;

  /// A head drawn by the caller, for one that is not a title and a line
  /// (a chip, a 16 inset); most sheets pass [title] instead.
  final Widget? header;

  /// The sheet's head: the compact title 20 in, at most two lines, and
  /// [subtitle] under it in the note role (SW-REV-008). The title is a
  /// heading to TalkBack; it names the route on iOS only, since on Android
  /// the modal route's own "Dialog" label wins.
  final String? title;
  final String? subtitle;

  /// Usually MxSheetActions in its sheet form.
  final Widget? footer;

  /// The drag affordance; off for a sheet that is not draggable.
  final bool hasGrabber;

  /// The sheet stays while its work runs: Back and a scrim tap are refused,
  /// and a drag down is absorbed. The modal route's own drag pops without
  /// asking, so refusing the pop alone does not hold it (FE-B4 final
  /// review).
  final bool isHeld;

  static const double _maxHeightShare = 0.85;
  static const double _grabberWidth = 36;
  static const double _grabberHeight = 4;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sheets = Theme.of(context).bottomSheetTheme;
    final shape = context.sheetShape;
    // A field inside keeps above the keyboard (§9 row 64): the sheet sits on
    // the IME inset and caps itself within what is left.
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final sheet = ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            (MediaQuery.sizeOf(context).height - inset) * _maxHeightShare,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: shape.borderRadius,
          boxShadow: AppShadows.chrome(colors),
        ),
        child: Material(
          color: sheets.backgroundColor,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasGrabber)
                  // Material's drag-handle semantics: a screen reader can
                  // dismiss by the grabber (§9 row 65).
                  Semantics(
                    key: const ValueKey('mx-sheet-grabber'),
                    container: true,
                    button: true,
                    label: MaterialLocalizations.of(context)
                        .modalBarrierDismissLabel,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.control,
                        bottom: AppSpacing.micro,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: _grabberWidth,
                          height: _grabberHeight,
                          child: DecoratedBox(
                            // The variant text colour, 3:1 on the sheet.
                            decoration: BoxDecoration(
                              color: colors.onSurfaceVariant,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (title case final text?)
                  _SheetHead(title: text, subtitle: subtitle)
                else
                  ?header,
                Flexible(child: SingleChildScrollView(child: child)),
                ?footer,
              ],
            ),
          ),
        ),
      ),
    );
    return PopScope(
      canPop: !isHeld,
      child: Padding(
        padding: EdgeInsets.only(bottom: inset),
        // Inside the route's drag detector, so it wins the vertical drag.
        child: isHeld
            ? GestureDetector(
                onVerticalDragStart: (_) {},
                onVerticalDragUpdate: (_) {},
                onVerticalDragEnd: (_) {},
                child: sheet,
              )
            : sheet,
      ),
    );
  }
}

/// The sheet's head: the title and, when given, the line under it.
class _SheetHead extends StatelessWidget {
  const _SheetHead({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  static const int _titleMaxLines = 2;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.card,
        AppSpacing.micro,
        AppSpacing.card,
        AppSpacing.grouped,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.micro,
        children: [
          // A user's name (a deck, an entry) stops at two lines. A heading;
          // the route's name on iOS (Android keeps the route's own label).
          Semantics(
            namesRoute: true,
            header: true,
            child: Text(
              title,
              maxLines: _titleMaxLines,
              overflow: TextOverflow.ellipsis,
              style: styles.compactTitle,
            ),
          ),
          if (subtitle case final text?) Text(text, style: styles.noteText),
        ],
      ),
    );
  }
}
