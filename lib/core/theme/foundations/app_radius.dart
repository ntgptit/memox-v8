/// V3 radius roles. 24 and 28 exist in the kit but have no call site in V3,
/// so they are not declared.
abstract final class AppRadius {
  /// 20px checkbox.
  static const double xs = 4;

  /// 28 icon tile, compact button.
  static const double sm = 8;

  /// Card, button, input, note, banner, snackbar, 36–44 icon tile, small
  /// controls: the one radius of in-flow surfaces (spec 2026-09-26 D2).
  static const double md = 12;

  /// FAB, bottom-nav bar.
  static const double lg = 16;

  /// Dialog, bottom-sheet top corners, 64 empty-state tile, the meaning and
  /// term text fields: surfaces that float above the content.
  static const double xl = 20;

  /// Pill: chip, badge, toggle track, sheet grabber, progress track.
  static const double full = 999;
}
