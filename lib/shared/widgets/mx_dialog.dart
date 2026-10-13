import 'package:flutter/material.dart';
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
  barrierColor: DialogTheme.of(context).barrierColor!,
  transitionDuration: MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : Durations.short4,
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

  /// The Design System defines no shadow for a dialog; Material's own
  /// elevation casts it, the same in light and dark.
  static const double _elevation = 6;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // The surface and radius are the theme's dialog (spec §4.6).
    final dialogs = DialogTheme.of(context);
    final shape = dialogs.shape! as RoundedRectangleBorder;
    final hasText = title != null || body != null || content != null;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.dimens.space24,
            vertical: context.dimens.space24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: switch (width) {
                MxDialogWidth.large => _largeWidth,
                MxDialogWidth.medium => _mediumWidth,
                MxDialogWidth.small => _smallWidth,
              },
            ),
            child: Material(
              color: dialogs.backgroundColor,
              elevation: _elevation,
              shadowColor: colors.shadow,
              shape: shape,
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasText)
                    Flexible(
                      child: SingleChildScrollView(
                        // The text sits on the action pair's 16 edge, so
                        // the pair keeps its width (DEV-166, The Short
                        // Label Rule).
                        padding: actions == null
                            ? EdgeInsets.fromLTRB(
                                context.dimens.space16,
                                context.dimens.space24,
                                context.dimens.space16,
                                context.dimens.space24,
                              )
                            : EdgeInsetsDirectional.only(
                                start: context.dimens.space16,
                                end: context.dimens.space16,
                                top: context.dimens.space24,
                              ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: context.dimens.space8,
                          children: [
                            if (title case final text?)
                              Text(text, style: context.texts.titleSmall),
                            if (body case final text?)
                              Text(text, style: context.texts.bodyMedium),
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
    );
  }
}
