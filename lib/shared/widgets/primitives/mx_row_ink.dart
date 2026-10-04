import 'package:flutter/material.dart';

/// The press and ripple every tappable row shares: the theme's splash, no
/// hover, clipped to the row's own corners.
class MxRowInk extends StatelessWidget {
  const MxRowInk({
    required this.onTap,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    super.key,
  });

  /// `null` makes the row inert: no ripple and no tap.
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, borderRadius: borderRadius, child: child),
    );
  }
}
