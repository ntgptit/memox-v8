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
}
