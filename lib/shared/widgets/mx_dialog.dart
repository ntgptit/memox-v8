import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/overlay_style.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// A dialog's width cap; it is never wider than the window less its gutters.
enum MxDialogWidth {
  small(AppSize.dialogSmall),
  medium(AppSize.dialogMedium),
  large(AppSize.dialogLarge);

  const MxDialogWidth(this.extent);

  final double extent;
}

/// The scale a dialog grows from as it fades in (component contract).
const double _enterScale = 0.92;

/// Opens [builder] (an `MxDialog`) over the 45% scrim. It fades in and
/// scales from 0.92 over 200ms, and opens at once under reduced motion.
Future<T?> showMxDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  final bool isStill = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: mxScrim(context.colors),
    transitionDuration: isStill ? Duration.zero : AppDurations.standard,
    pageBuilder: (context, _, _) => builder(context),
    transitionBuilder: (context, animation, _, child) {
      final Animation<double> curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: _enterScale, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// The centred modal for a decision or a short form (DESIGN.md, MxDialog):
/// the sheet ground, r20, the overlay shadow, a 20 interior; its title, an
/// optional message and content, and the `MxSheetActions` footer.
class MxDialog extends StatelessWidget {
  const MxDialog({
    required this.title,
    required this.actions,
    this.message,
    this.content,
    this.width = MxDialogWidth.medium,
    super.key,
  });

  final String title;
  final String? message;

  /// A short form or a list under the message.
  final Widget? content;
  final MxSheetActions actions;
  final MxDialogWidth width;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final bool isDark = colors.brightness == Brightness.dark;
    final AppShadow overlay = isDark
        ? AppShadows.overlayDark
        : AppShadows.overlayLight;
    final String? body = message;
    final Widget? extra = content;
    final BorderRadius radius = BorderRadius.circular(AppRadius.xl);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width.extent),
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: title,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: mxOverlayGround(colors),
                borderRadius: radius,
                boxShadow: [overlay.on(colors.shadow)],
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.card),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: AppSpacing.control,
                            children: [
                              Text(title, style: context.texts.titleLarge),
                              if (body != null)
                                Text(
                                  body,
                                  style: context.texts.bodyMedium?.apply(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ?extra,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      actions,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
