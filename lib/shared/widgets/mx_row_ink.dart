import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// What the tappable rows share (spec §4.5, ruling S13):
/// - the platform ripple across the whole row;
/// - a 2px primary ring when focused;
/// - the global 0.38 dim when disabled.
///
/// A row without [onTap] is static: no ripple, and not focusable. A control
/// inside the row keeps its own semantics node and its own tap.
class MxRowInk extends StatefulWidget {
  const MxRowInk({
    super.key,
    required this.onTap,
    required this.child,
    this.isEnabled = true,
  });

  final VoidCallback? onTap;
  final Widget child;
  final bool isEnabled;

  @override
  State<MxRowInk> createState() => _MxRowInkState();
}

class _MxRowInkState extends State<MxRowInk> {
  var _hasFocus = false;

  @override
  void didUpdateWidget(MxRowInk oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A row that stops being tappable drops out of focus without a callback.
    if (widget.onTap == null || !widget.isEnabled) _hasFocus = false;
  }

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    if (!widget.isEnabled) {
      return Opacity(
        opacity: AppOpacity.disabled,
        child: onTap == null
            ? widget.child
            : Semantics(
                container: true,
                button: true,
                enabled: false,
                child: widget.child,
              ),
      );
    }
    if (onTap == null) return widget.child;
    return Semantics(
      container: true,
      button: true,
      child: InkWell(
        onTap: onTap,
        onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: _hasFocus
                ? Border.all(
                    color: context.colors.primary,
                    width: AppStroke.focus,
                  )
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
