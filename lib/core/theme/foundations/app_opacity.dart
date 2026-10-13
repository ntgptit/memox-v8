/// The Material 3 state layers ("Flashcard Color Tokens" §4.6), applied once
/// by the state policy, never as a colour.
abstract final class AppOpacity {
  /// The hover overlay (web and desktop only).
  static const double hover = 0.08;

  /// The pressed overlay.
  static const double pressed = 0.10;

  /// The keyboard-focus overlay, drawn with the focus ring.
  static const double focus = 0.10;

  /// The dragged overlay.
  static const double dragged = 0.16;

  /// Disabled text and icons; over a whole control, one value everywhere.
  static const double disabled = 0.38;

  /// A disabled container's fill (onSurface at this alpha).
  static const double disabledContainer = 0.12;

  /// Readable content that steps back: an answered choice out of play, a
  /// footer caption. `disabled` is for controls that cannot be used.
  static const double muted = 0.7;

  /// A control kept for input and semantics while something else paints it,
  /// such as the code field's hidden text field under its slots.
  static const double hidden = 0;
}
