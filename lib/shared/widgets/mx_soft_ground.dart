import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_theme.dart';

/// A soft ground (a toned card, a banner, an outcome tile). Soft grounds are
/// light in both themes (spec 2026-10-10 D4), so the content they hold
/// renders under Indigo Day: its text, glyphs and buttons read Day's tokens.
class MxSoftGround extends StatelessWidget {
  const MxSoftGround({super.key, this.decoration, required this.child});

  /// The ground. Null when the caller paints it itself, as MxCard does on
  /// its Material so a row's ripple lands on the card (ruling S14).
  final BoxDecoration? decoration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Text and icons that set no colour inherit Day's, as a Material in Day
    // would give them.
    final themed = Theme(
      data: _day,
      child: DefaultTextStyle.merge(
        style: _day.textTheme.bodyMedium,
        child: IconTheme.merge(
          data: IconThemeData(color: _day.colorScheme.onSurface),
          child: child,
        ),
      ),
    );
    final ground = decoration;
    if (ground == null) return themed;
    return DecoratedBox(decoration: ground, child: themed);
  }
}

// Built once: the Day theme is immutable and the same for every soft ground.
final ThemeData _day = buildLightTheme();
