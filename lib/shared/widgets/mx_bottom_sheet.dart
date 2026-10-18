import 'package:flutter/material.dart' show MaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_held_route.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

/// Opens [builder] (usually an MxBottomSheet) on ForUI's bottom sheet
/// route, over its barrier, from the nearest navigator. It slides up with
/// ForUI's motion, at once under reduced motion (ruling O7). A scrim tap or
/// a drag down dismisses it, unless the sheet is held (MxBottomSheet.isHeld).
/// The result is what the sheet pops with.
Future<T?> showMxBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final navigator = Navigator.of(context);
  // Material's strings, as showModalBottomSheet read them: ForUI's Vietnamese
  // barrier strings are defective ("Scrim", a literal "$modalRouteContentName").
  final material = MaterialLocalizations.of(context);
  return navigator.push(
    _MxSheetRoute<T>(
      style: context.theme.modalSheetStyle,
      side: FLayout.btt,
      builder: builder,
      // MxBottomSheet caps itself at 85% and scrolls its body.
      mainAxisMaxRatio: null,
      useSafeArea: true,
      barrierLabel: material.scrimLabel,
      barrierOnTapHint: material.scrimOnTapHint(material.bottomSheetLabel),
      capturedFTheme: FTheme.capture(from: context, to: navigator.context),
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
    ),
  );
}

/// ForUI's sheet route, with a barrier that a held sheet keeps.
class _MxSheetRoute<T> extends FModalSheetRoute<T> with MxHeldRoute<T> {
  _MxSheetRoute({
    required super.style,
    required super.side,
    required super.builder,
    super.mainAxisMaxRatio,
    super.useSafeArea,
    super.barrierLabel,
    super.barrierOnTapHint,
    super.capturedFTheme,
    super.capturedThemes,
  });
}

/// The bottom-anchored modal for action lists and pickers. It stops at 85% of
/// the screen:
/// - only [child] scrolls, so [header] and [footer] stay in view (ruling
///   O12);
/// - the fill runs under the gesture bar, and the content stays above it.
///
/// It paints ForUI's sheet surface: the background, a hairline border on top
/// and the large radius on its top corners; ForUI's route keeps it above the
/// keyboard.
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
  /// (a chip, a 16 inset); most sheets pass [title] instead. The caller
  /// marks its heading as [title] is marked: `Semantics(header: true,
  /// namesRoute: true)` around it.
  final Widget? header;

  /// The sheet's head: the compact title 24 in, at most two lines, and
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
  /// and a drag down is absorbed. ForUI's route pops on its own drag and
  /// barrier without asking, so refusing the pop alone does not hold it
  /// (FE-B4 final review; MxHeldRoute).
  final bool isHeld;

  static const double _maxHeightShare = 0.85;

  /// The drag handle's painted size.
  static const Size _handle = Size(32, 4);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = context.radii.xl2.topLeft;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final sheet = ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            (MediaQuery.sizeOf(context).height - inset) * _maxHeightShare,
      ),
      child: MxTintBase(
        // What the sheet holds is tinted over its own ground.
        color: colors.background,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(
              top: BorderSide(color: colors.border, width: context.hairline),
            ),
            borderRadius: BorderRadius.vertical(top: radius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: radius),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasGrabber) _grabber(context),
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
      ),
    );
    return MxHoldRoute(
      isHeld: isHeld,
      // Inside the route's drag detector, so a held sheet's absorber wins the
      // vertical drag. Opaque: a drag that starts on a locked row (which
      // ignores pointers) still reaches it. Always present, so a hold that
      // comes or goes never remounts the sheet's content.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: isHeld ? (_) {} : null,
        onVerticalDragUpdate: isHeld ? (_) {} : null,
        onVerticalDragEnd: isHeld ? (_) {} : null,
        child: sheet,
      ),
    );
  }

  /// The drag affordance: a screen reader can dismiss by it (§9 row 65).
  Widget _grabber(BuildContext context) {
    return Center(
      child: Semantics(
        key: const ValueKey('mx-sheet-grabber'),
        container: true,
        button: true,
        label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        onTap: () => Navigator.of(context).maybePop(),
        child: SizedBox.square(
          dimension: context.dimens.sizeControl,
          child: Center(
            child: SizedBox.fromSize(
              size: _handle,
              child: DecoratedBox(
                // Muted ink, 3:1 on the sheet.
                decoration: BoxDecoration(
                  color: context.colors.mutedForeground,
                  borderRadius: context.radii.pill,
                ),
              ),
            ),
          ),
        ),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.dimens.space24,
        context.dimens.space4,
        context.dimens.space24,
        context.dimens.space12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: context.dimens.space4,
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
              style: context.texts.itemTitle,
            ),
          ),
          if (subtitle case final text?)
            Text(
              text,
              style: context.texts.body.copyWith(
                color: context.colors.mutedForeground,
              ),
            ),
        ],
      ),
    );
  }
}
