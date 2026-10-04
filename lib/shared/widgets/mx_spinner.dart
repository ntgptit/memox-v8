import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The four spinner sizes (DESIGN.md, Feedback and Status).
enum MxSpinnerSize {
  small(AppSize.spinnerSmall),
  medium(AppSize.spinnerMedium),
  large(AppSize.spinnerLarge),
  xlarge(AppSize.spinnerXlarge);

  const MxSpinnerSize(this.extent);

  final double extent;
}

/// Who colours the spinner: the Indigo Accent (`on-primary-container`) on its
/// own, or the content colour of
/// the control it sits in (a button's label colour while it loads).
enum MxSpinnerTone { accent, inherit }

/// An indeterminate wait: a three-quarter arc turning once every 800 ms. Still
/// when the platform asks for reduced motion.
class MxSpinner extends StatefulWidget {
  const MxSpinner({
    this.semanticLabel,
    this.size = MxSpinnerSize.medium,
    this.tone = MxSpinnerTone.accent,
    super.key,
  });

  /// What is being waited for, read aloud; `null` only inside a control that
  /// already names the wait (a loading button keeps its own label).
  final String? semanticLabel;
  final MxSpinnerSize size;
  final MxSpinnerTone tone;

  @override
  State<MxSpinner> createState() => _MxSpinnerState();
}

class _MxSpinnerState extends State<MxSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: AppDurations.spinnerCycle,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _turn.stop();
      return;
    }
    if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = switch (widget.tone) {
      MxSpinnerTone.accent => context.colors.onPrimaryContainer,
      MxSpinnerTone.inherit =>
        IconTheme.of(context).color ?? context.colors.onPrimaryContainer,
    };
    final Widget arc = SizedBox.square(
      dimension: widget.size.extent,
      child: RotationTransition(
        turns: _turn,
        child: CustomPaint(painter: _ArcPainter(color)),
      ),
    );
    final String? label = widget.semanticLabel;
    if (label == null) {
      return ExcludeSemantics(child: arc);
    }
    return Semantics(label: label, liveRegion: true, child: arc);
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double sweep = math.pi * 1.5;
    final Rect box = (Offset.zero & size).deflate(AppStroke.control / 2);
    canvas.drawArc(
      box,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = AppStroke.control
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}
