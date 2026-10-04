import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/generated/design_values.dart';

/// The DESIGN.md roles that are not a Material 3 TextTheme slot, inked for
/// one theme. A component overrides the nearest role inside itself; it never
/// adds a global style (DESIGN.md, The Seven Roles Rule). Read through
/// `context.textStyles`.
@immutable
class MxTextStyles extends ThemeExtension<MxTextStyles> {
  const MxTextStyles({
    required this.buttonLabel,
    required this.sectionLabel,
    required this.eyebrow,
    required this.fieldLabel,
  });

  factory MxTextStyles.from(ColorScheme scheme) => MxTextStyles(
    buttonLabel: AppTypography.role(DesignType.buttonLabel),
    sectionLabel: AppTypography.role(DesignType.sectionLabel)
        .apply(color: scheme.onSurfaceVariant),
    eyebrow: AppTypography.role(DesignType.eyebrow)
        .apply(color: scheme.onSurfaceVariant),
    fieldLabel: AppTypography.role(DesignType.fieldLabel)
        .apply(color: scheme.onSurface),
  );

  /// Every text-labelled control; the control sets the colour.
  final TextStyle buttonLabel;

  /// The overline of a list or a settings group; the widget upper-cases it.
  final TextStyle sectionLabel;

  /// The one context line above a big title or number.
  final TextStyle eyebrow;

  /// The name of an input or of a read-only field.
  final TextStyle fieldLabel;

  @override
  MxTextStyles copyWith({
    TextStyle? buttonLabel,
    TextStyle? sectionLabel,
    TextStyle? eyebrow,
    TextStyle? fieldLabel,
  }) => MxTextStyles(
    buttonLabel: buttonLabel ?? this.buttonLabel,
    sectionLabel: sectionLabel ?? this.sectionLabel,
    eyebrow: eyebrow ?? this.eyebrow,
    fieldLabel: fieldLabel ?? this.fieldLabel,
  );

  @override
  MxTextStyles lerp(MxTextStyles? other, double t) {
    if (other == null) return this;
    TextStyle mix(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return MxTextStyles(
      buttonLabel: mix(buttonLabel, other.buttonLabel),
      sectionLabel: mix(sectionLabel, other.sectionLabel),
      eyebrow: mix(eyebrow, other.eyebrow),
      fieldLabel: mix(fieldLabel, other.fieldLabel),
    );
  }
}
