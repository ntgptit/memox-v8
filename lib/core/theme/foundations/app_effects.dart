/// Visual effect configuration (02-theme-binding EFFECT_TOKEN). Translucency,
/// not interaction, so it lives outside AppOpacity.
abstract final class AppEffects {
  /// Alpha of the bottom-nav glass surface.
  static const double glassOpacity = 0.84;

  /// Alpha of the `scrim` behind a dialog or a bottom sheet (spec §5, O8).
  static const double scrimOpacity = 0.45;
}
