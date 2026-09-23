/// Every duration a V3 widget contract states, named by what moves.
abstract final class AppDurations {
  /// Toggle track colour and thumb offset.
  static const Duration toggle = Duration(milliseconds: 160);

  /// Dialog scale-in, snackbar sheet-in, study progress fill.
  static const Duration standard = Duration(milliseconds: 200);

  /// Modal scrim fade-in.
  static const Duration scrimFade = Duration(milliseconds: 220);

  /// Bottom sheet translate-in.
  static const Duration sheet = Duration(milliseconds: 260);

  /// One spinner revolution.
  static const Duration spinnerCycle = Duration(milliseconds: 800);

  /// One skeleton pulse, 0.45 to 0.75 opacity and back.
  static const Duration skeletonPulse = Duration(milliseconds: 1400);
}
