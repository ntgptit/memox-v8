import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/shared/widgets/mx_focus_ring.dart';

/// What the tappable rows share (spec §4.5, ruling S13):
/// - the platform ripple across the whole row;
/// - the shared focus ring, inside the row, when focused;
/// - the global 0.38 dim when disabled.
///
/// A row without [onTap] is static: no ripple, and not focusable. A control
/// inside the row keeps its own semantics node and its own tap.
class MxRowInk extends StatelessWidget {
  const MxRowInk({
    super.key,
    required this.onTap,
    required this.child,
    this.onLongPress,
    this.isEnabled = true,
    this.shouldDimWhenDisabled = true,
    this.semanticLabel,
  });

  final VoidCallback? onTap;

  /// A long-press, such as starting a selection (Card list, Trash): on the
  /// row's own ink and in its TalkBack node (SW-REV-005).
  final VoidCallback? onLongPress;
  final Widget child;
  final bool isEnabled;

  /// False leaves the dim to the child, which dims only what is unavailable
  /// (MxSettingsRow and MxListRow keep their reason readable); taps stay
  /// blocked.
  final bool shouldDimWhenDisabled;

  /// What TalkBack reads first for the tappable row, before its children's
  /// merged text (the action, then the content); null reads the text alone.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final onTap = this.onTap;
    if (!isEnabled) {
      final disabled = onTap == null
          ? child
          : Semantics(
              container: true,
              button: true,
              enabled: false,
              label: semanticLabel,
              child: child,
            );
      if (!shouldDimWhenDisabled) return disabled;
      return Opacity(opacity: AppOpacity.disabled, child: disabled);
    }
    if (onTap == null) return child;
    // The ring wraps the InkWell, whose node takes the focus: it hears only
    // its descendants'.
    return MxFocusRing(
      radius: BorderRadius.circular(AppRadius.md),
      placement: MxFocusRingPlacement.inside,
      child: Semantics(
        container: true,
        button: true,
        label: semanticLabel,
        child: InkWell(onTap: onTap, onLongPress: onLongPress, child: child),
      ),
    );
  }
}
