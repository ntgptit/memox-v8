/// Global interaction-state tokens (02-theme-binding STATE_TOKEN). Applied
/// once by the state policy, never as a colour. Hover is web-only and not
/// implemented on Android.
abstract final class AppOpacity {
  /// Over the whole control, one value everywhere.
  static const double disabled = 0.38;

  /// Readable content that steps back: an answered choice out of play, a
  /// footer caption. `disabled` is for controls that cannot be used.
  static const double muted = 0.7;

  /// The platform pressed overlay.
  static const double pressed = 0.12;

  /// Tint rungs: a role laid at this alpha over its ground, for tiles,
  /// badges and pills. One rung per value, so a tint changes in one place
  /// (audit 2026-10-03 Theming, SP1 §5.3).
  static const double tintFaint = 0.08;
  static const double tintSoft = 0.10;
  static const double tintMedium = 0.12;

  /// The primary tile tint in dark, where 0.10 vanishes on Nebula.
  static const double tintSoftDark = 0.16;

  /// The selected destination's pill, bottom nav and rail alike.
  static const double navPillLight = 0.14;
  static const double navPillDark = 0.20;

  /// Selected text behind the cursor's handles (Material's default).
  static const double selection = 0.24;
}
