/// Stroke widths. A component contract that states another width adds a
/// named rung here in the phase that builds that component.
abstract final class AppStroke {
  /// The 1px border on cards, inputs and dividers.
  static const double hairline = 1;

  /// The focus ring, one treatment for every control.
  static const double focus = 2;

  /// Gap between a control and its focus ring.
  static const double focusOffset = 2;

  /// Unselected radio ring and checkbox border.
  static const double control = 2;

  /// Selected radio ring: the ring thickens, nothing moves.
  static const double selectedRing = 6;

  /// Spinner arc and other progress strokes.
  static const double indicator = 2;
}
