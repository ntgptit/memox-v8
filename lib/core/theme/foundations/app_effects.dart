/// Visual effect configuration (02-theme-binding EFFECT_TOKEN). Translucency,
/// not interaction, so it lives outside AppOpacity. The bottom bar's glass
/// (opacity and blur) went with DEV-302: nothing scrolled under it.
abstract final class AppEffects {
  /// Alpha of the `scrim` behind a dialog or a bottom sheet (spec §5, O8).
  static const double scrimOpacity = 0.45;
}
