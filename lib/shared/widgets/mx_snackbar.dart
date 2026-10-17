import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// How long a toast stays: the platform's 4 seconds.
const Duration _toastDuration = Duration(seconds: 4);

/// How long a toast offering Undo stays (FE-B1 D3).
const Duration mxUndoWindow = Duration(seconds: 8);

/// The toasts on screen, one per toaster, so a new one replaces the last.
final Expando<FToasterEntry> _shown = Expando('mx-toast');

/// A toast [showMxSnackbar] put on screen.
class MxSnackbarController {
  MxSnackbarController._(this._entry, this._closed);

  final FToasterEntry _entry;
  final Completer<void> _closed;

  /// Completes once the toast has left the screen, however it left: its
  /// time ran out, it was swiped, replaced, acted on or [close]d.
  Future<void> get closed => _closed.future;

  /// Takes the toast off the screen.
  void close() => _entry.dismiss();
}

/// Shows the MemoX toast, ForUI's [FToast]: a message and one optional
/// action, from the app's toaster (`AppThemeHost`), above every route.
/// Tapping the action hides the toast first. It stays [duration], the
/// platform's 4 seconds by default.
///
/// - A new toast replaces the one on screen instead of queueing behind it,
///   so a toast that stays for TalkBack never holds back the next (FE-B1
///   D14).
/// - A toast with an action stays until it is acted on or replaced while
///   TalkBack is on, so the action can be reached (WCAG 2.2.1, FE-B1 D14).
MxSnackbarController showMxSnackbar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = _toastDuration,
}) {
  assert(
    (actionLabel == null) == (onAction == null),
    'actionLabel and onAction come together',
  );
  final toaster = context.findAncestorStateOfType<FToasterState>();
  if (toaster != null) _shown[toaster]?.dismiss();
  final persists =
      onAction != null && MediaQuery.accessibleNavigationOf(context);
  final closed = Completer<void>();
  final entry = showFToast(
    context: context,
    title: Text(message),
    duration: persists ? null : duration,
    onDismiss: () {
      if (!closed.isCompleted) closed.complete();
    },
    suffixBuilder: switch ((actionLabel, onAction)) {
      (final label?, final action?) => (context, entry) => FButton(
        onPress: () {
          entry.dismiss();
          action();
        },
        variant: FButtonVariant.outline,
        size: FButtonSizeVariant.sm,
        mainAxisSize: MainAxisSize.min,
        child: Text(label),
      ),
      _ => null,
    },
  );
  if (toaster != null) _shown[toaster] = entry;
  return MxSnackbarController._(entry, closed);
}
