import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';

/// What the tappable rows share (spec §4.5, ruling S13):
/// - the platform ripple across the whole row;
/// - a 2px primary ring when focused;
/// - the global 0.38 dim when disabled.
///
/// A row without [onTap] is static: no ripple, and not focusable. A control
/// inside the row keeps its own semantics node and its own tap. A row that is
/// a choice says [isSelected], and the row's one node carries it with its
/// label and tap.
class MxRowInk extends StatefulWidget {
  const MxRowInk({
    super.key,
    required this.onTap,
    required this.child,
    this.onLongPress,
    this.borderRadius,
    this.isEnabled = true,
    this.shouldDimWhenDisabled = true,
    this.isSelected,
  });

  final VoidCallback? onTap;

  /// A long-press, such as starting a selection (Card list, Trash): on the
  /// row's own ink and in its TalkBack node (SW-REV-005).
  final VoidCallback? onLongPress;
  final Widget child;

  /// The corners the ripple, the state layers and the focus ring follow; null
  /// is the row's square edge. A pill-shaped control passes its own radius.
  final BorderRadius? borderRadius;
  final bool isEnabled;

  /// False leaves the dim to the child, which dims only what is unavailable
  /// (MxSettingsRow and MxListRow keep their reason readable); taps stay
  /// blocked.
  final bool shouldDimWhenDisabled;

  /// Whether the row is the chosen one; null is a row with no selected state.
  final bool? isSelected;

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

  /// A row with no tap still says whether it is the chosen one.
  Widget _static() {
    final isSelected = widget.isSelected;
    if (isSelected == null) return widget.child;
    return Semantics(
      container: true,
      selected: isSelected,
      child: widget.child,
    );
  }

  /// A disabled row stays in the semantics tree, says it is disabled, and
  /// answers no pointer: its own target and the controls inside it (a trailing
  /// button, a wide control) are inert, while TalkBack still reads them.
  Widget _blocked(BuildContext context) {
    final isTappable = widget.onTap != null;
    final disabled = IgnorePointer(
      child: Semantics(
        container: isTappable,
        button: isTappable,
        enabled: false,
        selected: widget.isSelected,
        child: widget.child,
      ),
    );
    if (!widget.shouldDimWhenDisabled) return disabled;
    return Opacity(
      opacity: context.dimens.opacityDisabledContent,
      child: disabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    if (!widget.isEnabled) return _blocked(context);
    if (onTap == null) return _static();
    return Semantics(
      container: true,
      button: true,
      selected: widget.isSelected,
      child: InkWell(
        onTap: onTap,
        onLongPress: widget.onLongPress,
        borderRadius: widget.borderRadius,
        onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            border: _hasFocus
                ? Border.all(
                    color: context.colors.primary,
                    width: context.dimens.strokeFocus,
                  )
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
