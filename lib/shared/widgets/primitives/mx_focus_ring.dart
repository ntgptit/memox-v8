import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The 2dp `primary` ring a control shows while it holds keyboard focus,
/// 2dp outside its edge (DESIGN.md, Shapes). It listens to the focus of the
/// focusable inside [child] and paints only in traditional (keyboard)
/// highlight mode, so a tap never leaves a ring behind.
class MxFocusRing extends StatefulWidget {
  const MxFocusRing({
    required this.borderRadius,
    required this.child,
    this.paintedHeight,
    this.isShown,
    super.key,
  });

  /// The control's own corner radius; the ring follows it, grown by the offset.
  final BorderRadius borderRadius;

  /// The painted height of a control whose box is padded to the 48 target
  /// (a 32 compact button): the ring hugs the paint, not the hit area.
  final double? paintedHeight;

  /// Set by a control that tracks its own focus highlight (one built on
  /// `FocusableActionDetector`); `null` lets the ring listen for itself.
  final bool? isShown;
  final Widget child;

  @override
  State<MxFocusRing> createState() => _MxFocusRingState();
}

class _MxFocusRingState extends State<MxFocusRing> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    super.dispose();
  }

  void _onHighlightMode(FocusHighlightMode mode) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final bool isVisible =
        widget.isShown ??
        (_focused &&
            FocusManager.instance.highlightMode ==
                FocusHighlightMode.traditional);
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: CustomPaint(
        foregroundPainter: isVisible
            ? _RingPainter(
                color: context.colors.primary,
                borderRadius: widget.borderRadius,
                paintedHeight: widget.paintedHeight,
              )
            : null,
        child: widget.child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.color,
    required this.borderRadius,
    this.paintedHeight,
  });

  final Color color;
  final BorderRadius borderRadius;
  final double? paintedHeight;

  @override
  void paint(Canvas canvas, Size size) {
    const double grow = AppSize.focusOffset + AppStroke.focus / 2;
    final double height = paintedHeight ?? size.height;
    final Rect paint = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width,
      height: height < size.height ? height : size.height,
    );
    final RRect ring = borderRadius
        .resolve(TextDirection.ltr)
        .toRRect(paint)
        .inflate(grow);
    canvas.drawRRect(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.focus
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color ||
      old.borderRadius != borderRadius ||
      old.paintedHeight != paintedHeight;
}
