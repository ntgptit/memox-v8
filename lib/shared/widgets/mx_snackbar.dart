import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/shared/widgets/mx_button.dart';

/// How long a toast stays: the platform's 4 seconds.
const Duration _toastDuration = Duration(seconds: 4);

/// How long a toast offering Undo stays (FE-B1 D3).
const Duration mxUndoWindow = Duration(seconds: 8);

/// A toast [showMxSnackbar] put on screen.
class MxSnackbarController {
  MxSnackbarController._(this._host);

  final _MxToastHostState _host;
  final Completer<void> _closed = Completer<void>();

  /// False once the toast is leaving; its view animates out, then removes it.
  final ValueNotifier<bool> _isShown = ValueNotifier(true);
  Timer? _timer;

  /// Completes once the toast has left the screen, however it left: its
  /// time ran out, it was swiped, replaced, acted on or [close]d.
  Future<void> get closed => _closed.future;

  /// Takes the toast off the screen.
  void close() {
    _timer?.cancel();
    _isShown.value = false;
  }

  void _remove() {
    _release();
    _host._remove(this);
  }

  /// Ends the toast without touching the host's tree: its view is being
  /// disposed, by its removal or with the host.
  void _release() {
    _timer?.cancel();
    if (_host._current == this) _host._current = null;
    if (!_closed.isCompleted) _closed.complete();
  }
}

/// Hosts the toasts [showMxSnackbar] shows, above every route and dialog:
/// `AppThemeHost` puts it over the Navigator, as a messenger is.
class MxToastHost extends StatefulWidget {
  const MxToastHost({super.key, required this.child});

  final Widget child;

  @override
  State<MxToastHost> createState() => _MxToastHostState();
}

class _MxToastHostState extends State<MxToastHost> {
  final List<(MxSnackbarController, Widget)> _toasts = [];

  /// The toast on screen, which a new one replaces.
  MxSnackbarController? _current;

  void _show(MxSnackbarController controller, Widget view) {
    _current?.close();
    _current = controller;
    setState(() => _toasts.add((controller, view)));
  }

  void _remove(MxSnackbarController controller) {
    if (!mounted) return;
    setState(() => _toasts.removeWhere((toast) => toast.$1 == controller));
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      widget.child,
      for (final (controller, view) in _toasts)
        Positioned.fill(key: ObjectKey(controller), child: view),
    ],
  );
}

/// Shows the MemoX toast, ForUI's [FToast]: a message and one optional
/// action, from the app's [MxToastHost], above every route. Tapping the
/// action hides the toast first; a swipe down dismisses it. It stays
/// [duration], the platform's 4 seconds by default.
///
/// - A new toast replaces the one on screen instead of queueing behind it,
///   so a toast that stays for TalkBack never holds back the next (FE-B1
///   D14).
/// - A toast with an action stays until it is acted on or replaced while
///   TalkBack is on, so the action can be reached (WCAG 2.2.1, FE-B1 D14).
/// - The toast is a live region, so TalkBack reads it when it appears. It is
///   not shown through ForUI's toaster, whose tap-to-pause gesture lands on
///   the screen's root semantics node as an unlabelled action.
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
  final host = context.findAncestorStateOfType<_MxToastHostState>();
  if (host == null) {
    throw FlutterError(
      'showMxSnackbar needs an MxToastHost above the context; AppThemeHost '
      'puts one over the Navigator.',
    );
  }
  final controller = MxSnackbarController._(host);
  final action = switch ((actionLabel, onAction)) {
    // MxButton, not a bare FButton, so the action keeps the 48 target.
    (final label?, final callback?) => MxButton(
      label: label,
      tone: MxButtonTone.outline,
      size: MxButtonSize.small,
      onPressed: () {
        controller.close();
        callback();
      },
    ),
    _ => null,
  };
  host._show(
    controller,
    _ToastView(controller: controller, message: message, action: action),
  );
  final persists =
      onAction != null && MediaQuery.accessibleNavigationOf(context);
  if (!persists) controller._timer = Timer(duration, controller.close);
  return controller;
}

/// The toast at the bottom of the screen, above the keyboard and the system
/// insets, sliding and fading in and out unless motion is reduced.
class _ToastView extends StatefulWidget {
  const _ToastView({
    required this.controller,
    required this.message,
    required this.action,
  });

  final MxSnackbarController controller;
  final String message;
  final Widget? action;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(vsync: this);

  /// ForUI's toast rule: TalkBack on or reduced motion fades in place,
  /// disabled motion shows and removes at once (FToastMotion).
  FAccessibilityContext get _accessibility => context.accessibility;

  @override
  void initState() {
    super.initState();
    widget.controller._isShown.addListener(_onShownChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = FTheme.of(context).toasterStyle.toastStyles.primary.motion;
    _motion
      ..duration = motion.entranceDuration
      ..reverseDuration = motion.dismissDuration;
    if (_motion.isAnimating || _motion.value > 0) return;
    if (_accessibility.motion == FAccessibilityMotion.disabled) {
      _motion.value = 1;
      return;
    }
    _motion.forward();
  }

  void _onShownChanged() {
    if (widget.controller._isShown.value) return;
    if (_accessibility.motion == FAccessibilityMotion.disabled) {
      widget.controller._remove();
      return;
    }
    _motion.reverse().whenComplete(widget.controller._remove);
  }

  @override
  void dispose() {
    widget.controller._isShown.removeListener(_onShownChanged);
    widget.controller._release();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = FTheme.of(context).toasterStyle;
    final motion = style.toastStyles.primary.motion;
    final curve = CurvedAnimation(
      parent: _motion,
      curve: motion.entranceCurve,
      reverseCurve: motion.dismissCurve,
    );
    final isFadeOnly =
        _accessibility.accessibleNavigation ||
        _accessibility.motion != FAccessibilityMotion.all;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: style.padding,
            child: FadeTransition(
              opacity: curve,
              child: SlideTransition(
                position: Tween(
                  begin: isFadeOnly
                      ? Offset.zero
                      : const Offset(0, _slideFraction),
                  end: Offset.zero,
                ).animate(curve),
                child: Dismissible(
                  key: ObjectKey(widget.controller),
                  direction: DismissDirection.down,
                  onDismissed: (_) => widget.controller._remove(),
                  child: Semantics(
                    container: true,
                    liveRegion: true,
                    child: ConstrainedBox(
                      constraints: style.toastStyles.primary.constraints,
                      child: FToast(
                        title: Text(widget.message),
                        suffix: widget.action,
                      ),
                    ),
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

/// How far below its place the toast starts, as a share of its height.
const double _slideFraction = 0.5;
