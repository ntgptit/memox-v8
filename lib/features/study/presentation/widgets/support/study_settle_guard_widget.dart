import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';

/// A session screen's actions after an in-place swap (critique 2026-09-30
/// part 3c-2, R1): when [phase] changes, the row takes no tap for [settle]
/// while it eases from the muted opacity to full, so the second tap of a
/// double tap never lands on the button that replaced the first. Under
/// Remove animations it shows at full opacity at once and is still guarded.
/// The first build is not a swap, unless [isGuardedAtStart].
class StudySettleGuardWidget extends StatefulWidget {
  const StudySettleGuardWidget({
    super.key,
    required this.phase,
    required this.child,
    this.isGuardedAtStart = false,
  });

  /// What the row shows; a new value is a swap.
  final Object phase;
  final Widget child;

  /// A row that appears under the finger rather than swapping in place (the
  /// summary's footer after the last answer, 2.09): its first build is
  /// guarded too.
  final bool isGuardedAtStart;

  /// How long a swapped row ignores taps.
  static const Duration settle = Duration(milliseconds: 400);

  @override
  State<StudySettleGuardWidget> createState() => _StudySettleGuardWidgetState();
}

class _StudySettleGuardWidgetState extends State<StudySettleGuardWidget>
    with SingleTickerProviderStateMixin {
  // Preserve: the platform's Remove animations flag would shorten the guard
  // itself, not only its fade.
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: StudySettleGuardWidget.settle,
    animationBehavior: AnimationBehavior.preserve,
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.isGuardedAtStart) unawaited(_settle.forward(from: 0));
  }

  @override
  void didUpdateWidget(StudySettleGuardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase == widget.phase) return;
    unawaited(_settle.forward(from: 0));
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStill = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _settle,
      builder: (context, child) => IgnorePointer(
        // Settled is the end value: at exactly [settle] the controller is
        // at 1 but still counts as animating.
        ignoring: _settle.value < 1,
        child: Opacity(
          opacity: isStill
              ? 1
              : lerpDouble(
                  AppOpacity.muted,
                  1,
                  Easing.standard.transform(_settle.value),
                )!,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
