import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';

/// The screen's floating creation action: a 52dp `primary` square, r16, icon
/// only, flat in every state (DESIGN.md, Actions: no shadow, no elevation).
/// Pressed shows as the state layer and focus as the ring.
class MxFab extends StatelessWidget {
  const MxFab({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.focusNode,
    super.key,
  });

  final IconData icon;

  /// Read aloud and shown as the tooltip: the FAB has no visible label.
  final String semanticLabel;
  final VoidCallback onPressed;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return MxFocusRing(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: FloatingActionButton(
        heroTag: null,
        focusNode: focusNode,
        tooltip: semanticLabel,
        onPressed: onPressed,
        child: Icon(icon),
      ),
    );
  }
}
