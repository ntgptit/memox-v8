import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A modal route whose barrier can be held: while held, a tap on the scrim
/// does nothing. ForUI's dialog and sheet barriers pop the route outright
/// (`Navigator.pop`), past any `PopScope`, so a popup held while its work
/// runs (`MxDialog.isHeld`, `MxBottomSheet.isHeld`) refuses the scrim here.
/// Back and the drag are refused by the popup itself.
mixin MxHeldRoute<T> on ModalRoute<T> {
  bool _isHeld = false;

  set isHeld(bool value) {
    if (value == _isHeld) return;
    _isHeld = value;
    // Rebuilds the barrier, which reads [barrierDismissible].
    changedInternalState();
  }

  @override
  bool get barrierDismissible => !_isHeld && super.barrierDismissible;
}

/// Keeps the [MxHeldRoute] that shows [child] held while [isHeld]. The flag
/// reaches the route after the frame, since a route cannot rebuild its
/// barrier while its page builds.
class MxHoldRoute extends StatefulWidget {
  const MxHoldRoute({super.key, required this.isHeld, required this.child});

  final bool isHeld;
  final Widget child;

  @override
  State<MxHoldRoute> createState() => _MxHoldRouteState();
}

class _MxHoldRouteState extends State<MxHoldRoute> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(MxHoldRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isHeld != widget.isHeld) _sync();
  }

  void _sync() {
    final route = ModalRoute.of(context);
    if (route is! MxHeldRoute) return;
    final isHeld = widget.isHeld;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (route.isActive) route.isHeld = isHeld;
    });
  }

  @override
  Widget build(BuildContext context) =>
      PopScope(canPop: !widget.isHeld, child: widget.child);
}
