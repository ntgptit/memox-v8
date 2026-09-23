import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';

/// Surface treatments shared by more than one component contract.
abstract final class AppDecorations {
  /// The Card surface: surface-raised fill and radius 20; the whisper shadow
  /// in light and a 1px ghost border in dark, which has no shadow.
  static BoxDecoration raisedCard(
    ColorScheme scheme,
    MxDerivedColors derived,
  ) => BoxDecoration(
    color: scheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(AppRadius.xl),
    border: scheme.brightness == Brightness.dark
        ? Border.all(color: derived.ghostBorder, width: AppStroke.hairline)
        : null,
    boxShadow: AppShadows.whisper(scheme),
  );
}
