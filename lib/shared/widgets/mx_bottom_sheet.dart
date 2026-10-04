import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/overlay_style.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Opens [builder] (an `MxBottomSheet`) from the bottom over the 45% scrim,
/// sliding up over 260ms, at once under reduced motion.
Future<T?> showMxBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final bool isStill = MediaQuery.disableAnimationsOf(context);
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: AnimationStyle(
      duration: isStill ? Duration.zero : AppDurations.sheet,
      reverseDuration: isStill ? Duration.zero : AppDurations.sheet,
    ),
  );
}

/// The bottom-anchored modal for action lists, pickers and short forms
/// (DESIGN.md, MxBottomSheet): top corners 20, the chrome shadow, a grabber,
/// an optional title, a scrolling body and a pinned footer. It stops 72
/// below the top safe area (Material 3), so the page behind stays in view to
/// tap away, and rides above the keyboard.
class MxBottomSheet extends StatelessWidget {
  const MxBottomSheet({
    required this.child,
    this.title,
    this.actions,
    super.key,
  });

  final String? title;
  final Widget child;

  /// The pinned footer.
  final MxSheetActions? actions;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final bool isDark = colors.brightness == Brightness.dark;
    final AppShadow chrome = isDark
        ? AppShadows.chromeDark
        : AppShadows.chromeLight;
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;
    // The navigation bar; zero while the keyboard covers it.
    final double systemBar = MediaQuery.paddingOf(context).bottom;
    final String? heading = title;
    final MxSheetActions? footer = actions;
    // The route already lays the sheet out below the top safe area.
    return LayoutBuilder(
      builder: (context, route) => Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: route.maxHeight - keyboard - AppSize.sheetTopClearance,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: mxOverlayGround(colors),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
              boxShadow: [chrome.on(colors.shadow)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Grabber(),
                if (heading != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: AppSpacing.gutter,
                      end: AppSpacing.gutter,
                      bottom: AppSpacing.grouped,
                    ),
                    child: Semantics(
                      header: true,
                      child: Text(heading, style: context.texts.titleLarge),
                    ),
                  ),
                Flexible(child: SingleChildScrollView(child: child)),
                if (footer != null) footer.framedForSheet(),
                SizedBox(height: systemBar),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The 32 × 4 pill at the top (Material 3's drag handle) in `outline`, 3:1
/// on the sheet ground, centred in a 48 band so the drag has a full target.
class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSize.tapTarget,
      child: Center(
        child: SizedBox(
          width: AppSize.grabberWidth,
          height: AppSize.grabberHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.outline,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
        ),
      ),
    );
  }
}
