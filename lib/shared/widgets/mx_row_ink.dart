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
///
/// A row with [isEnabled] false is blocked (M3F-17): it ignores every pointer,
/// its own target and the controls inside it, and its semantics say it is
/// disabled. The nodes stay in the tree, so TalkBack still reads the row and
/// its controls, but their tap actions are gone. A busy row is passed here as
/// disabled.
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

  /// False blocks the row: no tap or long-press on it or on a control inside
  /// it, and `enabled: false` in the semantics. The row is also dimmed, unless
  /// [shouldDimWhenDisabled] is false.
  final bool isEnabled;

  /// False leaves the dim to the child, which dims only what is unavailable
  /// (MxSettingsRow and MxListRow keep their reason readable); taps stay
  /// blocked.
  final bool shouldDimWhenDisabled;

  /// Whether the row is the chosen one, said on the row's own semantics node
  /// (enabled, disabled or static); null is a row with no selected state.
  final bool? isSelected;

  @override
  State<MxRowInk> createState() => _MxRowInkState();
}

class _MxRowInkState extends State<MxRowInk> {
  var _hasFocus = false;

  // The row's skeleton (pointer block, semantics node) and its content keep
  // their keys, so turning the row enabled, disabled, busy or static does not
  // remount what the caller put inside it or drop its semantics node.
  final _coreKey = GlobalKey();
  final _contentKey = GlobalKey();

  @override
  void didUpdateWidget(MxRowInk oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A row that stops being tappable drops out of focus without a callback.
    if (widget.onTap == null || !widget.isEnabled) _hasFocus = false;
  }

  /// A disabled row stays in the semantics tree, says it is disabled, and
  /// answers no pointer: its own target and the controls inside it (a trailing
  /// button, a wide control) are inert, while TalkBack still reads them.
  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    final isBlocked = !widget.isEnabled;
    final isSelected = widget.isSelected;
    final content = KeyedSubtree(key: _contentKey, child: widget.child);
    final core = IgnorePointer(
      key: _coreKey,
      ignoring: isBlocked,
      child: onTap == null
          ? _static(isBlocked, isSelected, content)
          : _tappable(context, onTap, isBlocked, isSelected, content),
    );
    if (!isBlocked || !widget.shouldDimWhenDisabled) return core;
    return Opacity(opacity: context.dimens.opacityDisabledContent, child: core);
  }

  /// A row with no tap is no button and takes no focus; it still says whether
  /// it is the chosen one and whether it is disabled.
  Widget _static(bool isBlocked, bool? isSelected, Widget content) {
    return Semantics(
      container: isSelected != null,
      enabled: isBlocked ? false : null,
      selected: isSelected,
      child: content,
    );
  }

  Widget _tappable(
    BuildContext context,
    VoidCallback onTap,
    bool isBlocked,
    bool? isSelected,
    Widget content,
  ) {
    return Semantics(
      container: true,
      button: true,
      enabled: isBlocked ? false : null,
      selected: isSelected,
      child: InkWell(
        onTap: isBlocked ? null : onTap,
        onLongPress: isBlocked ? null : widget.onLongPress,
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
          child: content,
        ),
      ),
    );
  }
}
