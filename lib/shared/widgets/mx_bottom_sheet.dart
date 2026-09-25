import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Opens [builder] (usually an MxBottomSheet) on the platform modal route
/// over a 45% scrim, sliding up over 260ms. It opens instantly under reduced
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
  });

  final Widget child;
  final Widget? header;

  /// Usually MxSheetActions in its sheet form.
  final Widget? footer;

  /// The drag affordance; off for a sheet that is not draggable.
  final bool hasGrabber;

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
                            decoration: BoxDecoration(
                              color: colors.outlineVariant,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ?header,
                Flexible(child: SingleChildScrollView(child: child)),
                ?footer,
              ],
            ),
          ),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: sheet,
    );
  }
}
