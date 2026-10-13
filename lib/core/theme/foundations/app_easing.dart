import 'package:flutter/material.dart';

/// The Material 3 easing curves ("Flashcard Color Tokens" §4.7). Entering
/// the screen decelerates, leaving it accelerates, a change in place is
/// [standard], and a countdown ring is [linear].
abstract final class AppEasing {
  /// A small move that starts and ends on screen: a colour or opacity change.
  static const Curve standard = Easing.standard;

  /// A small element entering the screen.
  static const Curve standardDecelerate = Easing.standardDecelerate;

  /// A small element leaving the screen.
  static const Curve standardAccelerate = Easing.standardAccelerate;

  /// An expressive enter: the next card or screen arriving.
  static const Curve emphasizedDecelerate = Easing.emphasizedDecelerate;

  /// An expressive exit: a card or screen leaving.
  static const Curve emphasizedAccelerate = Easing.emphasizedAccelerate;

  /// An expressive move that starts and ends on screen: a card swipe, a page
  /// transition.
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// Progress over time only, such as the 15 s countdown ring.
  static const Curve linear = Curves.linear;
}
