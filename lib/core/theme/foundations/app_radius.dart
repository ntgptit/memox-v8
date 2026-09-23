/// V3 radius roles. 24 and 28 exist in the kit but have no call site in V3,
/// so they are not declared.
abstract final class AppRadius {
  /// 20px checkbox.
  static const double xs = 4;

  /// 28 icon tile, compact button.
  static const double sm = 8;

  /// Button, input, note, snackbar, 36–44 icon tile, small controls.
  static const double md = 12;

  /// FAB, bottom-nav bar.
  static const double lg = 16;

  /// Card, dialog, bottom-sheet top corners, 64 empty-state tile.
  static const double xl = 20;

  /// Pill: chip, badge, toggle track, sheet grabber, progress track.
  static const double full = 999;
}
