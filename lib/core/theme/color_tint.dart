import 'package:flutter/painting.dart';
import 'package:memox/core/theme/generated/token_constants.g.dart';
import 'package:memox/core/theme/color_tint.dart';

extension ColorTint on Color {
  /// This colour at the Design System tint strength (`opacity-dragged`, 16%)
  /// over [base], rounded per 8-bit channel so it matches the token spec's
  /// precomputed hex. [base] is the surface directly underneath: the page
  /// surface on the screen, the card surface inside a card.
  Color tintOver(Color base) =>
      Color.fromARGB(255, _mix(r, base.r), _mix(g, base.g), _mix(b, base.b));
}

int _mix(double foreground, double background) =>
    ((foreground * 255).round() * kOpacityDragged +
            (background * 255).round() * (1 - kOpacityDragged))
        .round();
