import 'package:flutter/material.dart';

/// Every duration a widget contract states, named by what moves. The motion
/// ones are Material 3's tokens ("Flashcard Color Tokens" §4.7).
abstract final class AppDurations {
  /// A selection and a state layer (`motion-duration-short2`).
  static const Duration selection = Durations.short2;

  /// A state's colour change, such as a toggle or a match tile
  /// (`motion-duration-short3`).
  static const Duration toggle = Durations.short3;

  /// A small exit or fade, a dialog's scale-in, a study progress fill
  /// (`motion-duration-short4`).
  static const Duration standard = Durations.short4;

  /// Modal scrim fade-in (`motion-duration-short4`).
  static const Duration scrimFade = Durations.short4;

  /// A small enter or expand: a bottom sheet, a banner, the navigation pill
  /// (`motion-duration-medium2`).
  static const Duration sheet = Durations.medium2;

  /// A card swipe, a page transition, and the hold after a right answer
  /// (`motion-duration-medium4`).
  static const Duration pageTransition = Durations.medium4;

  /// A large transition, and the hold after a wrong match before the tiles
  /// reset (`motion-duration-long4`).
  static const Duration longTransition = Durations.long4;

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
