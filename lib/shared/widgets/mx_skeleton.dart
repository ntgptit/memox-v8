import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// One placeholder shape. It pulses: opacity travels 0.45 ↔ 0.75 over 1.4s,
/// with no shimmer sweep. Under reduced motion it rests at 0.5.
class MxSkeleton extends StatefulWidget {
  const MxSkeleton({
    super.key,
    this.width,
    this.height = _defaultHeight,
    this.isCircle = false,
  });

  /// Null fills the available width.
  final double? width;
  final double height;

  /// A circle as wide as it is tall, with a full radius.
  final bool isCircle;

  static const double _defaultHeight = 12;

  /// Ruling O3: the contract's 6 has no radius token.
  static const double _radius = 6;
  static const double _restingOpacity = 0.5;
  static const double _lowOpacity = 0.45;
  static const double _highOpacity = 0.75;

  @override
  State<MxSkeleton> createState() => _MxSkeletonState();
}

/// The 0.45 ↔ 0.75 pulse driven by [controller].
Animation<double> _pulseOf(AnimationController controller) =>
    TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: MxSkeleton._lowOpacity,
          end: MxSkeleton._highOpacity,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: MxSkeleton._highOpacity,
          end: MxSkeleton._lowOpacity,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]).animate(controller);

/// Runs [controller] unless the reader asked for reduced motion.
void _runUnlessStill(BuildContext context, AnimationController controller) {
  if (MediaQuery.disableAnimationsOf(context)) {
    controller.stop();
    return;
  }
  if (!controller.isAnimating) controller.repeat();
}

/// One pulse shared by every skeleton below it (§9 row 66: a ticker per
/// list, not per bar).
class _SkeletonPulse extends InheritedWidget {
  const _SkeletonPulse({required this.opacity, required super.child});

  final Animation<double> opacity;

  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkeletonPulse>()?.opacity;

  @override
  bool updateShouldNotify(_SkeletonPulse oldWidget) =>
      opacity != oldWidget.opacity;
}

class _MxSkeletonState extends State<MxSkeleton>
    with SingleTickerProviderStateMixin {
  /// Only a skeleton with no shared pulse above it runs its own.
  AnimationController? _own;
  Animation<double>? _opacity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shared = _SkeletonPulse.maybeOf(context);
    if (shared != null) {
      _opacity = shared;
      return;
    }
    final own = _own ??= AnimationController(
      vsync: this,
      duration: AppDurations.skeletonPulse,
    );
    _opacity ??= _pulseOf(own);
    _runUnlessStill(context, own);
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shape = SizedBox(
      width: widget.isCircle ? widget.height : widget.width ?? double.infinity,
      height: widget.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(
            widget.isCircle ? AppRadius.full : MxSkeleton._radius,
          ),
        ),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      return Opacity(opacity: MxSkeleton._restingOpacity, child: shape);
    }
    return FadeTransition(opacity: _opacity!, child: shape);
  }
}

/// The standard list placeholder (ruling O3): a tile and two bars at 70% and
/// 45% of the text column, on ListRow's padding and gap.
class MxSkeletonRow extends StatelessWidget {
  const MxSkeletonRow({super.key});

  static const double _tileSize = 28;
  static const double _titleShare = 0.7;
  static const double _subtitleShare = 0.45;

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.gutter,
      vertical: AppSpacing.grouped,
    ),
    child: Row(
      spacing: AppSpacing.grouped,
      children: [
        MxSkeleton(width: _tileSize, height: _tileSize),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.control,
            children: [
              FractionallySizedBox(
                widthFactor: _titleShare,
                child: MxSkeleton(),
              ),
              FractionallySizedBox(
                widthFactor: _subtitleShare,
                child: MxSkeleton(),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// A loading list: [rows] skeleton rows on one pulse, heard once as
/// [semanticLabel] (§9 row 61), since the bars themselves say nothing.
class MxSkeletonList extends StatefulWidget {
  const MxSkeletonList({
    super.key,
    required this.semanticLabel,
    this.rows = _defaultRows,
  });

  /// What is loading, in the caller's copy ("Loading").
  final String semanticLabel;
  final int rows;

  static const int _defaultRows = 4;

  @override
  State<MxSkeletonList> createState() => _MxSkeletonListState();
}

class _MxSkeletonListState extends State<MxSkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppDurations.skeletonPulse,
  );
  late final Animation<double> _opacity = _pulseOf(_pulse);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _runUnlessStill(context, _pulse);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: widget.semanticLabel,
    child: ExcludeSemantics(
      child: _SkeletonPulse(
        opacity: _opacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < widget.rows; i++) const MxSkeletonRow(),
          ],
        ),
      ),
    ),
  );
}
