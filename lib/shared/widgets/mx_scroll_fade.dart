import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The ground a fade dissolves into: the page, a raised card, or the
/// recessed answer face.
enum MxScrollFadeGround { page, raised, recessed }

/// A soft fade over the edge of a scroll view while more of it lies past
/// that edge, so a cut row or chip reads as "scroll for more" (study faces,
/// FE-A6 P3 C4; breadcrumb and chip rows, audit 2026-10-08 F-05, DEV-306).
/// Vertical, it fades the bottom; horizontal, each edge that still has
/// content, in the scroll's own direction, so a reversed view fades the
/// right side. Decorative: it takes no taps and says nothing to TalkBack.
class MxScrollFade extends StatefulWidget {
  const MxScrollFade({
    super.key,
    required this.child,
    this.axis = Axis.vertical,
    this.ground = MxScrollFadeGround.page,
  });

  /// A scroll view, or a tree with one scroll view on [axis].
  final Widget child;
  final Axis axis;
  final MxScrollFadeGround ground;

  /// The fade over the start edge (left, or top), for tests.
  @visibleForTesting
  static const Key leadingKey = ValueKey('mx-scroll-fade-leading');

  /// The fade over the end edge (right, or bottom), for tests.
  @visibleForTesting
  static const Key trailingKey = ValueKey('mx-scroll-fade-trailing');

  static const double _extent = AppSpacing.section;

  @override
  State<MxScrollFade> createState() => _MxScrollFadeState();
}

class _MxScrollFadeState extends State<MxScrollFade> {
  var _hasMoreBefore = false;
  var _hasMoreAfter = false;
  var _direction = AxisDirection.down;

  bool _onMetrics(ScrollMetrics metrics) {
    if (metrics.axis != widget.axis) return false;
    final before = metrics.extentBefore > 0;
    final after = metrics.extentAfter > 0;
    final direction = metrics.axisDirection;
    if (before == _hasMoreBefore &&
        after == _hasMoreAfter &&
        direction == _direction) {
      return false;
    }
    setState(() {
      _hasMoreBefore = before;
      _hasMoreAfter = after;
      _direction = direction;
    });
    return false;
  }

  /// Whether the start edge (left or top) and the end edge (right or
  /// bottom) still hide content. A reversed view counts "after" at its
  /// start. The vertical form fades the bottom only.
  (bool, bool) _edges() {
    final isReversed =
        _direction == AxisDirection.up || _direction == AxisDirection.left;
    final (start, end) = isReversed
        ? (_hasMoreAfter, _hasMoreBefore)
        : (_hasMoreBefore, _hasMoreAfter);
    if (widget.axis == Axis.vertical) return (false, end);
    return (start, end);
  }

  Color _ground(BuildContext context) => switch (widget.ground) {
    MxScrollFadeGround.page => context.colors.surface,
    MxScrollFadeGround.raised => context.colors.surfaceContainerLowest,
    MxScrollFadeGround.recessed => context.colors.surfaceContainerLow,
  };

  @override
  Widget build(BuildContext context) {
    final ground = _ground(context);
    final (fadeStart, fadeEnd) = _edges();
    return Stack(
      children: [
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (notification) => _onMetrics(notification.metrics),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) => _onMetrics(notification.metrics),
            child: widget.child,
          ),
        ),
        if (fadeStart)
          _Fade(
            key: MxScrollFade.leadingKey,
            axis: widget.axis,
            isAtEnd: false,
            ground: ground,
          ),
        if (fadeEnd)
          _Fade(
            key: MxScrollFade.trailingKey,
            axis: widget.axis,
            isAtEnd: true,
            ground: ground,
          ),
      ],
    );
  }
}

/// One edge's fade: from the ground at the edge to clear toward the content.
class _Fade extends StatelessWidget {
  const _Fade({
    super.key,
    required this.axis,
    required this.isAtEnd,
    required this.ground,
  });

  final Axis axis;
  final bool isAtEnd;
  final Color ground;

  @override
  Widget build(BuildContext context) {
    final isVertical = axis == Axis.vertical;
    final clear = ground.withValues(alpha: 0);
    final gradient = LinearGradient(
      begin: isVertical ? Alignment.topCenter : Alignment.centerLeft,
      end: isVertical ? Alignment.bottomCenter : Alignment.centerRight,
      colors: isAtEnd ? [clear, ground] : [ground, clear],
    );
    return Positioned(
      left: isVertical || !isAtEnd ? 0 : null,
      right: isVertical || isAtEnd ? 0 : null,
      top: !isVertical || !isAtEnd ? 0 : null,
      bottom: !isVertical || isAtEnd ? 0 : null,
      width: isVertical ? null : MxScrollFade._extent,
      height: isVertical ? MxScrollFade._extent : null,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
        ),
      ),
    );
  }
}
