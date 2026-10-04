import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/design_values.dart';
import 'package:memox/shared/primitives/focus_ring.dart';
import 'package:memox/shared/primitives/hit_target.dart';

/// The surface every tappable `Mx*` stands on (spec 2026-10-04-sp3a §6.2):
/// the decoration with the ink inside it, the pressed overlay at
/// `AppOpacity.pressed`, the focus ring, a 48 dp hit area, and, when
/// [onTap] is null, the disabled look at `AppOpacity.disabled`.
///
/// Internal to the design system: only `lib/shared/widgets/` imports it.
class PressableSurface extends StatefulWidget {
  const PressableSurface({
    super.key,
    required this.shape,
    required this.inkColor,
    required this.child,
    this.color,
    this.onTap,
    this.onLongPress,
    this.padding = EdgeInsetsDirectional.zero,
    this.semanticLabel,
    this.isButton = true,
    this.shouldDimWhenDisabled = true,
  });

  /// The outline of the surface; also the ink's clip and the ring's path.
  final ShapeBorder shape;

  /// The ground; null for a surface with no fill.
  final Color? color;

  /// The colour of the pressed overlay, at `AppOpacity.pressed`.
  final Color inkColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;
  final bool isButton;

  /// A component that dims only part of itself when disabled (a settings
  /// row dims its tile and label, never the reason) sets this to false.
  final bool shouldDimWhenDisabled;
  final Widget child;

  @override
  State<PressableSurface> createState() => _PressableSurfaceState();
}

class _PressableSurfaceState extends State<PressableSurface> {
  bool _isFocused = false;

  bool get _isEnabled => widget.onTap != null || widget.onLongPress != null;

  @override
  Widget build(BuildContext context) {
    final surface = Material(
      type: widget.color == null
          ? MaterialType.transparency
          : MaterialType.canvas,
      color: widget.color,
      shape: widget.shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        customBorder: widget.shape,
        onFocusChange: (isFocused) => setState(() => _isFocused = isFocused),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? widget.inkColor.withValues(alpha: AppOpacity.pressed)
              : widget.inkColor.withValues(alpha: 0),
        ),
        child: Padding(
          padding: widget.padding,
          // A [semanticLabel] replaces what the child would announce.
          child: ExcludeSemantics(
            excluding: widget.semanticLabel != null,
            child: widget.child,
          ),
        ),
      ),
    );
    final dimmed = !_isEnabled && widget.shouldDimWhenDisabled;
    return Semantics(
      button: widget.isButton,
      enabled: _isEnabled,
      label: widget.semanticLabel,
      child: HitTarget(
        child: FocusRing(
          isVisible: _isFocused,
          shape: widget.shape,
          child: dimmed
              ? Opacity(opacity: AppOpacity.disabled, child: surface)
              : surface,
        ),
      ),
    );
  }
}
