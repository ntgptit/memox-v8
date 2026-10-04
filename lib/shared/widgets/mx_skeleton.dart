import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The share of the text column a row's title and meta lines take, so the
/// placeholder reads as a title over a shorter line (component contract).
const double _titleShare = 0.6;
const double _metaShare = 0.4;

/// One placeholder shape (DESIGN.md, MxSkeleton), as large as what replaces
/// it, so the layout does not jump on load. It pulses with the
/// `MxSkeletonGroup` above it (opacity 0.45 to 0.75 over 1.4s, no shimmer)
/// and rests at 0.45 without one or under reduced motion.
class MxSkeleton extends StatelessWidget {
  /// A text line as tall as the row title it stands for ([isMeta]: the
  /// caption under it), [widthFactor] of the space it is given.
  const MxSkeleton.line({this.widthFactor = 1, this.isMeta = false, super.key})
    : isTile = false;

  /// The tile a row leads with: the medium `MxIconTile`.
  const MxSkeleton.tile({super.key})
    : isTile = true,
      isMeta = false,
      widthFactor = 1;

  final double widthFactor;
  final bool isMeta;
  final bool isTile;

  @override
  Widget build(BuildContext context) {
    final Animation<double>? pulse = _Pulse.of(context);
    final Color fill = context.colors.surfaceContainerHighest;
    final TextStyle? text = isMeta
        ? context.texts.bodySmall
        : context.texts.bodyLarge;
    final Widget sized = isTile
        ? SizedBox.square(
            dimension: AppSize.iconTileMedium,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          )
        : FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: widthFactor,
            child: SizedBox(
              height: text?.fontSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
          );
    if (pulse == null) {
      return Opacity(opacity: AppOpacity.skeletonLow, child: sized);
    }
    return FadeTransition(opacity: pulse, child: sized);
  }
}

/// The standard list placeholder: the row's tile and two lines, title and
/// meta, on a list row's padding.
class MxSkeletonRow extends StatelessWidget {
  const MxSkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.grouped,
      ),
      child: Row(
        spacing: AppSpacing.grouped,
        children: [
          MxSkeleton.tile(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.control,
              children: [
                MxSkeleton.line(widthFactor: _titleShare),
                MxSkeleton.line(widthFactor: _metaShare, isMeta: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// [rowCount] skeleton rows under one pulse, read as one "loading" region.
class MxSkeletonList extends StatelessWidget {
  const MxSkeletonList({
    required this.semanticLabel,
    this.rowCount = 3,
    super.key,
  });

  /// What is loading, read aloud once ("Loading your decks").
  final String semanticLabel;
  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return MxSkeletonGroup(
      semanticLabel: semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (var i = 0; i < rowCount; i++) const MxSkeletonRow()],
      ),
    );
  }
}

/// One pulse shared by every skeleton below it, and one live region that
/// names what is loading; the shapes themselves are silent.
class MxSkeletonGroup extends StatefulWidget {
  const MxSkeletonGroup({
    required this.semanticLabel,
    required this.child,
    super.key,
  });

  final String semanticLabel;
  final Widget child;

  @override
  State<MxSkeletonGroup> createState() => _MxSkeletonGroupState();
}

class _MxSkeletonGroupState extends State<MxSkeletonGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppDurations.skeletonPulse,
  );
  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: AppOpacity.skeletonLow, end: AppOpacity.skeletonHigh),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween(begin: AppOpacity.skeletonHigh, end: AppOpacity.skeletonLow),
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
    if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isStill = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      container: true,
      child: ExcludeSemantics(
        child: _Pulse(opacity: isStill ? null : _opacity, child: widget.child),
      ),
    );
  }
}

class _Pulse extends InheritedWidget {
  const _Pulse({required this.opacity, required super.child});

  final Animation<double>? opacity;

  static Animation<double>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Pulse>()?.opacity;

  @override
  bool updateShouldNotify(_Pulse old) => old.opacity != opacity;
}
