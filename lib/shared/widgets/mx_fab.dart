import 'package:flutter/material.dart';
import 'package:memox/core/theme/focus_ring_border.dart';
import 'package:memox/core/theme/app_component_themes.dart';

/// The one pinned action: the Material 3 regular FAB, a square icon-only box
/// styled by the theme's `FloatingActionButtonThemeData`. V3 has no extended
/// FAB. [semanticLabel] is the accessible name and is never painted.
/// Placement belongs to MxAppShell.
class MxFab extends StatefulWidget {
  const MxFab({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  State<MxFab> createState() => _MxFabState();
}

class _MxFabState extends State<MxFab> {
  bool _focused = false;

  /// The theme's FAB corner, with the focus ring drawn around it.
  MxFocusRingBorder _shape(BuildContext context) {
    final t = ThemeTokens.of(context);
    return MxFocusRingBorder(
      base:
          Theme.of(context).floatingActionButtonTheme.shape! as OutlinedBorder,
      ring: _focused
          ? BorderSide(color: t.scheme.primary, width: t.dimens.strokeFocus)
          : BorderSide.none,
      gap: t.dimens.strokeFocusGap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      onTap: widget.onPressed,
      // The theme's shape is not state-aware, so the focus ring is set here.
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: FloatingActionButton(
          onPressed: widget.onPressed,
          tooltip: widget.semanticLabel,
          // The default tag is shared, so two FABs in one route would clash.
          heroTag: null,
          shape: _shape(context),
          child: Icon(widget.icon),
        ),
      ),
    );
  }
}
