import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A row of chips that never shrink or wrap, so it scrolls sideways. A chip
/// that is focused keeps its whole ring: the row clips at its own edges plus
/// the ring's reach, `strokeFocusGap` and `strokeFocus`, not at the chip's.
///
/// Put an MxScrollFade around it to hint at the chips past an edge.
class MxChipRow extends StatelessWidget {
  const MxChipRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    return ClipRect(
      clipper: _RingReachClipper(dimens.strokeFocusGap + dimens.strokeFocus),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // The scroll view's own clip is the chip's edge; the clipper above
        // replaces it with one that leaves room for the ring.
        clipBehavior: Clip.none,
        child: Row(spacing: dimens.space8, children: children),
      ),
    );
  }
}

/// The row's bounds grown on every side by the focus ring's reach.
class _RingReachClipper extends CustomClipper<Rect> {
  const _RingReachClipper(this.reach);

  final double reach;

  @override
  Rect getClip(Size size) => (Offset.zero & size).inflate(reach);

  @override
  Rect getApproximateClipRect(Size size) => getClip(size);

  @override
  bool shouldReclip(_RingReachClipper oldClipper) => oldClipper.reach != reach;
}
