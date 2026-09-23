/// Visual effect configuration (02-theme-binding EFFECT_TOKEN). Translucency,
/// not interaction, so it lives outside AppOpacity.
abstract final class AppEffects {
  /// Alpha of the bottom-nav glass surface.
  static const double glassOpacity = 0.84;

  /// Backdrop blur sigma behind the glass. The CSS saturate(180%) part of the
  /// source filter has no cheap Flutter equivalent and is dropped (spec §4.4).
  static const double glassBlur = 18;
}
