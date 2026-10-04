import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/control_style.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// A bounded integer with − and +, repeating while held (DESIGN.md, Inputs).
/// [minDigits] zero-pads the value, as the reminder's "07" : "05".
class MxStepper extends StatefulWidget {
  const MxStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.decreaseLabel,
    required this.increaseLabel,
    this.valueLabel,
    this.minDigits = 1,
    super.key,
  }) : assert(min <= max, 'min must not exceed max');

  final int value;
  final int min;
  final int max;

  /// `null` disables both buttons.
  final ValueChanged<int>? onChanged;

  /// The names of the two buttons, read aloud ("Earlier hour").
  final String decreaseLabel;
  final String increaseLabel;

  /// What the value is ("Hour"), read before it.
  final String? valueLabel;
  final int minDigits;

  @override
  State<MxStepper> createState() => _MxStepperState();
}

class _MxStepperState extends State<MxStepper> {
  Timer? _repeat;

  /// The last value sent; a repeat can tick again before the parent rebuilds
  /// with it, so each step counts from here, not from a stale `widget.value`.
  late int _latest = widget.value;

  @override
  void didUpdateWidget(MxStepper old) {
    super.didUpdateWidget(old);
    _latest = widget.value;
  }

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  bool get _canDecrease =>
      widget.onChanged != null && widget.value > widget.min;
  bool get _canIncrease =>
      widget.onChanged != null && widget.value < widget.max;

  void _step(int delta) {
    final int next = (_latest + delta).clamp(widget.min, widget.max);
    if (next == _latest) {
      _stopRepeat();
      return;
    }
    _latest = next;
    widget.onChanged?.call(next);
  }

  void _startRepeat(int delta) {
    _repeat?.cancel();
    _repeat = Timer.periodic(AppDurations.repeat, (_) => _step(delta));
  }

  void _stopRepeat() {
    _repeat?.cancel();
    _repeat = null;
  }

  String get _shown => widget.value.toString().padLeft(widget.minDigits, '0');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.valueLabel,
      value: _shown,
      increasedValue: _canIncrease
          ? (widget.value + 1).toString().padLeft(widget.minDigits, '0')
          : null,
      decreasedValue: _canDecrease
          ? (widget.value - 1).toString().padLeft(widget.minDigits, '0')
          : null,
      onIncrease: _canIncrease ? () => _step(1) : null,
      onDecrease: _canDecrease ? () => _step(-1) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Hold(
            onHold: _canDecrease ? () => _startRepeat(-1) : null,
            onRelease: _stopRepeat,
            child: MxIconButton(
              icon: Icons.remove,
              semanticLabel: widget.decreaseLabel,
              tone: MxIconButtonTone.accent,
              onPressed: _canDecrease ? () => _step(-1) : null,
            ),
          ),
          const SizedBox(width: AppSpacing.micro),
          ExcludeSemantics(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: AppSize.tapTarget),
              child: Text(
                _shown,
                textAlign: TextAlign.center,
                style: mxStepperValueStyle(context.texts),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.micro),
          _Hold(
            onHold: _canIncrease ? () => _startRepeat(1) : null,
            onRelease: _stopRepeat,
            child: MxIconButton(
              icon: Icons.add,
              semanticLabel: widget.increaseLabel,
              tone: MxIconButtonTone.accent,
              onPressed: _canIncrease ? () => _step(1) : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Starts the repeat once a press has been held for the long-press delay and
/// stops it on release. It reads raw pointers, so it never competes with the
/// button's own tap or its tooltip for the gesture.
class _Hold extends StatefulWidget {
  const _Hold({
    required this.onHold,
    required this.onRelease,
    required this.child,
  });

  final VoidCallback? onHold;
  final VoidCallback onRelease;
  final Widget child;

  @override
  State<_Hold> createState() => _HoldState();
}

class _HoldState extends State<_Hold> {
  Timer? _delay;

  void _down(PointerDownEvent event) {
    final VoidCallback? hold = widget.onHold;
    if (hold == null) {
      return;
    }
    _delay = Timer(kLongPressTimeout, hold);
  }

  void _up() {
    _delay?.cancel();
    _delay = null;
    widget.onRelease();
  }

  @override
  void dispose() {
    _delay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _down,
      onPointerUp: (_) => _up(),
      onPointerCancel: (_) => _up(),
      child: widget.child,
    );
  }
}
