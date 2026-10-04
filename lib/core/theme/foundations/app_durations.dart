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

  /// How long a toast stays: the platform's 4 seconds.
  static const Duration toast = Duration(milliseconds: 4000);

  /// How long a toast offering Undo stays (FE-B1 D3).
  static const Duration undoWindow = Duration(seconds: 8);

  /// How long a stepper button is held before it starts repeating (FE-A3 D6).
  static const Duration stepperRepeatDelay = Duration(milliseconds: 400);

  /// The pace of a held stepper button, one step each (FE-A3 D6).
  static const Duration stepperRepeatInterval = Duration(milliseconds: 80);
}
