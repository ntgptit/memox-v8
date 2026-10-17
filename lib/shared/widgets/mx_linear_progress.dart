import 'package:flutter/material.dart' show Durations, Easing;
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The colour a plain [MxLinearProgress] fills in. A meaning, never a colour:
/// the theme owns the value.
enum MxProgressTone {
  /// A finished-so-far measure: a resume card's progress.
  success,

  /// The session's own progress, in the brand colour.
  primary,

  /// A signal that is not yet good or bad: a turn clock while time remains.
  neutral,

  /// The signal has turned: a turn clock once time is up.
  warning,
}

/// A thin progress track (FE-A8 H2): ForUI's [FDeterminateProgress] in
/// MemoX's colours and `sizeTrack` height. The fill eases to [value] over the
/// progress track and ForUI steps it at once under Remove animations; it
/// draws its value at once on first mount. Decorative: the text
/// beside it, or its row's semantics, states the fraction, so it says
/// nothing to TalkBack. Screens 13 and 14 draw it in the success container for
/// a session's progress; screen 01 draws [MxLinearProgress.mastery] for a
/// deck's mastery. Both are `sizeTrack` tall.
class MxLinearProgress extends StatefulWidget {
  const MxLinearProgress({
    super.key,
    required this.value,
    this.tone = MxProgressTone.success,
    this.isInstant = false,
  }) : isMastery = false,
       assert(value >= 0 && value <= 1, 'value is a fraction in [0, 1]');

  /// The deck mastery bar (deck mastery spec D8, D13): filled in
  /// the MasteryRamp colour. Some mastery always shows, and a deck not
  /// wholly mastered never looks full: the fill keeps at least its height
  /// in from either end.
  const MxLinearProgress.mastery({
    super.key,
    required this.value,
    this.isInstant = false,
  }) : isMastery = true,
       tone = MxProgressTone.success,
       assert(value >= 0 && value <= 1, 'value is a fraction in [0, 1]');

  final double value;
  final bool isMastery;

  /// The plain bar's fill; the mastery bar takes its colour from the ramp.
  final MxProgressTone tone;

  /// Draws every value at once, with no ease: for a bar that tracks a clock,
  /// where an ease would lag the time it shows.
  final bool isInstant;

  @override
  State<MxLinearProgress> createState() => _MxLinearProgressState();
}

class _MxLinearProgressState extends State<MxLinearProgress> {
  // ForUI's progress animates from empty on mount; the bar shows its value
  // on the first frame instead, and eases only a later change.
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _isMounted = true);
  }

  /// The width factor drawn for [fraction] on a bar [width] wide.
  double _factor(double fraction, double width, double height) {
    if (!widget.isMastery || fraction <= 0 || fraction >= 1) return fraction;
    final inset = height / width;
    if (inset >= 0.5) return 0.5;
    return fraction.clamp(inset, 1 - inset);
  }

  Color? _fill(BuildContext context) {
    final colors = context.colors;
    final status = context.status;
    if (widget.isMastery) {
      return MasteryRamp.fill(status, colors.primary, widget.value);
    }
    return switch (widget.tone) {
      MxProgressTone.success => status.successFill,
      MxProgressTone.primary => colors.primary,
      MxProgressTone.neutral => colors.mutedForeground,
      MxProgressTone.warning => status.warningFill,
    };
  }

  @override
  Widget build(BuildContext context) {
    final track = MasteryRamp.track(context.colors);
    final height = context.dimens.sizeTrack;
    // A mastery of 0 has no fill colour; the track's own colour keeps the
    // fill invisible while it eases back to empty.
    final fill = _fill(context) ?? track;
    final isInstant = widget.isInstant || !_isMounted;
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) => FDeterminateProgress(
          value: _factor(widget.value, constraints.maxWidth, height),
          style: FDeterminateProgressStyleDelta.delta(
            trackDecoration: DecorationDelta.shapeDelta(color: track),
            fillDecoration: DecorationDelta.shapeDelta(color: fill),
            constraints: BoxConstraints.tightFor(height: height),
            motion: FDeterminateProgressMotionDelta.delta(
              duration: isInstant ? Duration.zero : Durations.short4,
              curve: Easing.standard,
            ),
          ),
        ),
      ),
    );
  }
}
