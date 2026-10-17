import 'package:flutter/scheduler.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A modal route whose barrier can be held: while held, a tap on the scrim
/// does nothing. ForUI's dialog and sheet barriers pop the route outright
/// (`Navigator.pop`), past any `PopScope`, so a popup held while its work
/// runs (`MxDialog.isHeld`, `MxBottomSheet.isHeld`) refuses the scrim here.
/// Back and the drag are refused by the popup itself.
mixin MxHeldRoute<T> on ModalRoute<T> {
  bool _isHeld = false;

  /// Holds or releases the route at once: the barrier refuses taps from now
  /// on, read when the tap lands. Its semantics follow after the frame, since
  /// a route cannot rebuild its barrier while its page builds.
  void hold(bool value) {
    if (value == _isHeld) return;
    _isHeld = value;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (isActive) changedInternalState();
    });
  }

  @override
  bool get barrierDismissible => !_isHeld && super.barrierDismissible;

  @override
  Widget buildModalBarrier() =>
      _HeldGate(isHeld: () => _isHeld, child: super.buildModalBarrier());
}

/// Takes every pointer on [child] while [isHeld] answers true, asked when the
/// pointer lands rather than when [child] was built.
class _HeldGate extends SingleChildRenderObjectWidget {
  const _HeldGate({required this.isHeld, required super.child});

  final bool Function() isHeld;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHeldGate(isHeld);

  @override
  void updateRenderObject(BuildContext context, _RenderHeldGate renderObject) {
    renderObject.isHeld = isHeld;
  }
}

class _RenderHeldGate extends RenderProxyBox {
  _RenderHeldGate(this.isHeld);

  bool Function() isHeld;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Held: the pointer stops here, as on an absorbing barrier.
    if (isHeld()) return size.contains(position);
    return super.hitTest(result, position: position);
  }
}

/// Keeps the [MxHeldRoute] that shows [child] held while [isHeld], from the
/// build that holds it.
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
    if (route is MxHeldRoute) route.hold(widget.isHeld);
  }

  @override
  Widget build(BuildContext context) =>
      PopScope(canPop: !widget.isHeld, child: widget.child);
}
