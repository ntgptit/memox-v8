import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/theme_context.dart';

/// What the tappable rows share (spec §4.5, ruling S13), on ForUI's
/// [FTappable]:
/// - ForUI's press and hover layer across the whole row;
/// - ForUI's focus outline when focused;
/// - the disabled dim when disabled.
///
/// A row without [onTap] is static: no press layer, and not focusable. A
/// control inside the row keeps its own semantics node and its own tap. A row
/// that is a choice says [isSelected], and the row's one node carries it with
/// its label and tap.
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
  /// row's own target and in its TalkBack node (SW-REV-005).
  final VoidCallback? onLongPress;
  final Widget child;

  /// The corners the press layer and the focus outline follow; null is the
  /// row's square edge. A pill-shaped control passes its own radius.
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
  // The row's content and its semantics node keep their place in the tree
  // whether the row is enabled, blocked, dimmed or static: the wrappers
  // around them change, so global keys move them instead of remounting what
  // the caller put inside the row.
  final GlobalKey _coreKey = GlobalKey();
  final GlobalKey _contentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    final isBlocked = !widget.isEnabled;
    final content = KeyedSubtree(key: _contentKey, child: widget.child);
    final core = IgnorePointer(
      key: _coreKey,
      ignoring: isBlocked,
      child: onTap == null
          ? Semantics(
              container: widget.isSelected != null,
              enabled: isBlocked ? false : null,
              selected: widget.isSelected,
              child: content,
            )
          : _tappable(context, onTap, isBlocked, content),
    );
    if (!isBlocked || !widget.shouldDimWhenDisabled) return core;
    return Opacity(opacity: context.colors.disabledOpacity, child: core);
  }

  Widget _tappable(
    BuildContext context,
    VoidCallback onTap,
    bool isBlocked,
    Widget content,
  ) {
    final colors = context.colors;
    final radius = widget.borderRadius ?? BorderRadius.zero;
    return FTappable.static(
      onPress: isBlocked ? null : onTap,
      onLongPress: isBlocked ? null : widget.onLongPress,
      selected: widget.isSelected ?? false,
      // ForUI's item press layer: the pressed ground at once, no bounce.
      style: FTheme.of(context).itemStyles.primary.tappableStyle,
      focusedOutlineStyle: FFocusedOutlineStyleDelta.delta(
        borderRadius: radius,
      ),
      builder: (context, variants, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          // The item's press ground: secondary under the row.
          color:
              variants.contains(FTappableVariant.pressed) ||
                  variants.contains(FTappableVariant.hovered)
              ? colors.secondary
              : null,
        ),
        child: child,
      ),
      child: content,
    );
  }
}
