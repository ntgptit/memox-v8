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

class _MxSkeletonState extends State<MxSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppDurations.skeletonPulse,
  );
  late final Animation<double> _opacity = TweenSequence<double>([
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
  ]).animate(_pulse);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      return;
    }
    if (!_pulse.isAnimating) _pulse.repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
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
    return FadeTransition(opacity: _opacity, child: shape);
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
