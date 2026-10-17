import 'package:flutter/material.dart' show MaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_held_route.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

/// The width cap: 340, 320 or 300, never wider than the column.
enum MxDialogWidth { small, medium, large }

/// Opens [builder] (usually an MxDialog) on ForUI's dialog route, over its
/// barrier, on the root navigator, so the scrim also covers the bottom nav
/// and the rail. The dialog fades and scales in with
/// ForUI's motion, at once under reduced motion. A scrim tap dismisses it
/// with null, unless the dialog is held (MxDialog.isHeld). The result is
/// what the dialog pops with.
Future<T?> showMxDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  // Material's strings, as showDialog read them: ForUI's Vietnamese barrier
  // strings are defective ("Scrim", a literal "$modalRouteContentName").
  final material = MaterialLocalizations.of(context);
  return navigator.push(
    _MxDialogRoute<T>(
      style: context.theme.dialogRouteStyle,
      barrierLabel: material.modalBarrierDismissLabel,
      barrierOnTapHint: material.scrimOnTapHint(material.dialogLabel),
      capturedFTheme: FTheme.capture(from: context, to: navigator.context),
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      builder: (context, _) => builder(context),
    ),
  );
}

/// Asks one yes/no question: [title], [body], an optional [content] (a
/// note: the reassurance, or why the confirm cannot go), Cancel and the
/// confirm. True only on the confirm; Cancel, Back and the scrim are a no.
/// The tone sits on the confirm alone; [canConfirm] false disables it, as
/// a deletion offline. A confirm whose work runs before it closes is not
/// this: it is its own MxDialog, held while it works (SW-REV-009).
Future<bool> showMxConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String cancelLabel,
  required String confirmLabel,
  Widget? content,
  bool isDestructive = false,
  bool isWarning = false,
  bool canConfirm = true,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (dialogContext) => MxDialog(
        title: title,
        body: body,
        content: content,
        actions: MxSheetActions(
          cancelLabel: cancelLabel,
          onCancel: () => Navigator.of(dialogContext).pop(false),
          confirmLabel: confirmLabel,
          isDestructive: isDestructive,
          isWarning: isWarning,
          onConfirm: canConfirm
              ? () => Navigator.of(dialogContext).pop(true)
              : null,
        ),
      ),
    ) ??
    false;

/// The centred modal for confirmations and short forms, on ForUI's
/// [FDialog]: the text sits 24 in, the title over the body 16 apart, and
/// scrolls if it outgrows the screen; [actions], usually MxSheetActions, stay
/// below it, 24 under the text. Title and body take ForUI's dialog styles.
/// ForUI moves it above the keyboard and names the route with [title].
class MxDialog extends StatelessWidget {
  const MxDialog({
    super.key,
    this.title,
    this.body,
    this.content,
    this.actions,
    this.width = MxDialogWidth.large,
    this.isHeld = false,
  });

  final String? title;
  final String? body;

  /// A short form under the body.
  final Widget? content;
  final Widget? actions;
  final MxDialogWidth width;

  /// The dialog stays while its work runs: Back and a scrim tap are refused,
  /// as MxBottomSheet.isHeld does.
  final bool isHeld;

  static const double _largeWidth = 340;
  static const double _mediumWidth = 320;
  static const double _smallWidth = 300;

  /// ForUI's own minimum, capped by the narrowest width.
  static const double _minWidth = 280;

  @override
  Widget build(BuildContext context) {
    final hasText = title != null || body != null || content != null;
    final maxWidth = switch (width) {
      MxDialogWidth.large => _largeWidth,
      MxDialogWidth.medium => _mediumWidth,
      MxDialogWidth.small => _smallWidth,
    };
    return MxHoldRoute(
      isHeld: isHeld,
      child: FDialog(
        // The route's own animation: ForUI animates the dialog itself.
        animation: ModalRoute.of(context)?.animation,
        semanticsLabel: title,
        constraints: BoxConstraints(minWidth: _minWidth, maxWidth: maxWidth),
        builder: (context, style) => MxTintBase(
          // What the dialog holds is tinted over its own ground.
          color: context.colors.card,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasText)
                Flexible(
                  child: SingleChildScrollView(
                    // The text sits on the action pair's edge (DEV-166); the
                    // pair is 24 below it.
                    padding: EdgeInsets.all(context.dimens.space24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: context.dimens.space16,
                      children: [
                        if (title case final text?)
                          Text(text, style: style.titleTextStyle),
                        if (body case final text?)
                          Text(text, style: style.bodyTextStyle),
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
    );
  }
}

/// ForUI's dialog route, with a barrier that a held dialog keeps.
class _MxDialogRoute<T> extends FDialogRoute<T> with MxHeldRoute<T> {
  _MxDialogRoute({
    required super.style,
    required super.builder,
    super.barrierLabel,
    super.barrierOnTapHint,
    super.capturedFTheme,
    super.capturedThemes,
  });
}
