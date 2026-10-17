import 'package:flutter/painting.dart';

/// The tint strength of a state colour over the surface below it.
const double _tintStrength = 0.16;

extension ColorTint on Color {
  /// This colour at the tint strength (16%) over [base], rounded per 8-bit
  /// channel. [base] is the surface directly underneath: the page on the
  /// screen, the card inside a card (`MxTintBase`).
  Color tintOver(Color base) =>
      Color.fromARGB(255, _mix(r, base.r), _mix(g, base.g), _mix(b, base.b));
}

int _mix(double foreground, double background) =>
    ((foreground * 255).round() * _tintStrength +
            (background * 255).round() * (1 - _tintStrength))
        .round();
