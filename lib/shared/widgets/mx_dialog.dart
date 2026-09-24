import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_effects.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The width cap: 340, 320 or 300, never wider than the column.
enum MxDialogWidth { small, medium, large }

const double _enterScale = 0.94;

/// Opens [builder] (usually an MxDialog) over a 45% scrim. The dialog fades
/// in and scales from 0.94 over 200ms; it opens instantly under reduced
/// motion (ruling O7). A scrim tap dismisses it with null.
Future<T?> showMxDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: context.colors.scrim.withValues(alpha: AppEffects.scrimOpacity),
  transitionDuration: MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : AppDurations.standard,
  pageBuilder: (dialogContext, _, _) => builder(dialogContext),
  transitionBuilder: (_, animation, _, child) {
    final curved = CurvedAnimation(parent: animation, curve: Easing.standard);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: _enterScale, end: 1).animate(curved),
        child: child,
      ),
    );
  },
);

/// The centred modal for confirmations and short forms. The text sits 20 in
/// (ruling O5) and scrolls if it outgrows the screen; [actions], usually
/// MxSheetActions, stay below it.
class MxDialog extends StatelessWidget {
  const MxDialog({
    super.key,
    this.title,
    this.body,
    this.content,
    this.actions,
    this.width = MxDialogWidth.large,
  });

  final String? title;
  final String? body;

  /// A short form under the body.
  final Widget? content;
  final Widget? actions;
  final MxDialogWidth width;

  static const double _largeWidth = 340;
  static const double _mediumWidth = 320;
  static const double _smallWidth = 300;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final radius = BorderRadius.circular(AppRadius.xl);
    final hasText = title != null || body != null || content != null;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.card,
            vertical: AppSpacing.section,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: switch (width) {
                MxDialogWidth.large => _largeWidth,
                MxDialogWidth.medium => _mediumWidth,
                MxDialogWidth.small => _smallWidth,
              },
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: AppShadows.overlay(colors),
              ),
              child: Material(
                color: colors.surfaceContainerHigh,
                shape: RoundedRectangleBorder(borderRadius: radius),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasText)
                      Flexible(
                        child: SingleChildScrollView(
                          padding: actions == null
                              ? const EdgeInsets.all(AppSpacing.card)
                              : const EdgeInsetsDirectional.only(
                                  start: AppSpacing.card,
                                  end: AppSpacing.card,
                                  top: AppSpacing.card,
                                ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: AppSpacing.control,
                            children: [
                              if (title case final text?)
                                Text(text, style: styles.compactTitle),
                              if (body case final text?)
                                Text(text, style: styles.dialogBody),
                              ?content,
                            ],
                          ),
                        ),
                      ),
                    ?actions,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
