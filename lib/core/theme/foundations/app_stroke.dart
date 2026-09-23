/// Stroke widths. A component contract that states another width adds a
/// named rung here in the phase that builds that component.
abstract final class AppStroke {
  /// The 1px border on cards, inputs and dividers.
  static const double hairline = 1;

  /// The focus ring, one treatment for every control.
  static const double focus = 2;

  /// Gap between a control and its focus ring.
  static const double focusOffset = 2;
}
