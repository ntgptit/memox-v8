import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/design_values.dart';

/// The colours DESIGN.md derives by rule (frontmatter `derived`): the inks
/// that read where a fill would fail contrast, the ghost border, the outline
/// edge and the soft tints. The generator computed them; nothing here does
/// arithmetic on a colour (spec 2026-10-04-sp3a §5.2). Read through
/// `context.derivedColors`.
@immutable
class MxDerivedColors extends ThemeExtension<MxDerivedColors> {
  const MxDerivedColors({
    required this.primaryInk,
    required this.ghostBorder,
    required this.outlineEdge,
    required this.statusNewInk,
    required this.statusLearningInk,
    required this.statusReviewingInk,
    required this.statusMasteredInk,
    required this.successInk,
    required this.dangerInk,
    required this.dangerTint,
    required this.dangerTintBorder,
    required this.warningTint,
    required this.warningTintBorder,
    required this.successTint,
    required this.successTintBorder,
  });

  factory MxDerivedColors.from(DesignPalette palette) => MxDerivedColors(
    primaryInk: palette.primaryInk,
    ghostBorder: palette.ghostBorder,
    outlineEdge: palette.outlineEdge,
    statusNewInk: palette.statusNewInk,
    statusLearningInk: palette.statusLearningInk,
    statusReviewingInk: palette.statusReviewingInk,
    statusMasteredInk: palette.statusMasteredInk,
    successInk: palette.successInk,
    dangerInk: palette.dangerInk,
    dangerTint: palette.dangerTint,
    dangerTintBorder: palette.dangerTintBorder,
    warningTint: palette.warningTint,
    warningTintBorder: palette.warningTintBorder,
    successTint: palette.successTint,
    successTintBorder: palette.successTintBorder,
  );

  static final MxDerivedColors light = MxDerivedColors.from(
    DesignPalette.light,
  );
  static final MxDerivedColors dark = MxDerivedColors.from(DesignPalette.dark);

  final Color primaryInk;
  final Color ghostBorder;
  final Color outlineEdge;
  final Color statusNewInk;
  final Color statusLearningInk;
  final Color statusReviewingInk;
  final Color statusMasteredInk;
  final Color successInk;
  final Color dangerInk;
  final Color dangerTint;
  final Color dangerTintBorder;
  final Color warningTint;
  final Color warningTintBorder;
  final Color successTint;
  final Color successTintBorder;

  @override
  MxDerivedColors copyWith({
    Color? primaryInk,
    Color? ghostBorder,
    Color? outlineEdge,
    Color? statusNewInk,
    Color? statusLearningInk,
    Color? statusReviewingInk,
    Color? statusMasteredInk,
    Color? successInk,
    Color? dangerInk,
    Color? dangerTint,
    Color? dangerTintBorder,
    Color? warningTint,
    Color? warningTintBorder,
    Color? successTint,
    Color? successTintBorder,
  }) => MxDerivedColors(
    primaryInk: primaryInk ?? this.primaryInk,
    ghostBorder: ghostBorder ?? this.ghostBorder,
    outlineEdge: outlineEdge ?? this.outlineEdge,
    statusNewInk: statusNewInk ?? this.statusNewInk,
    statusLearningInk: statusLearningInk ?? this.statusLearningInk,
    statusReviewingInk: statusReviewingInk ?? this.statusReviewingInk,
    statusMasteredInk: statusMasteredInk ?? this.statusMasteredInk,
    successInk: successInk ?? this.successInk,
    dangerInk: dangerInk ?? this.dangerInk,
    dangerTint: dangerTint ?? this.dangerTint,
    dangerTintBorder: dangerTintBorder ?? this.dangerTintBorder,
    warningTint: warningTint ?? this.warningTint,
    warningTintBorder: warningTintBorder ?? this.warningTintBorder,
    successTint: successTint ?? this.successTint,
    successTintBorder: successTintBorder ?? this.successTintBorder,
  );

  @override
  MxDerivedColors lerp(MxDerivedColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return MxDerivedColors(
      primaryInk: mix(primaryInk, other.primaryInk),
      ghostBorder: mix(ghostBorder, other.ghostBorder),
      outlineEdge: mix(outlineEdge, other.outlineEdge),
      statusNewInk: mix(statusNewInk, other.statusNewInk),
      statusLearningInk: mix(statusLearningInk, other.statusLearningInk),
      statusReviewingInk: mix(statusReviewingInk, other.statusReviewingInk),
      statusMasteredInk: mix(statusMasteredInk, other.statusMasteredInk),
      successInk: mix(successInk, other.successInk),
      dangerInk: mix(dangerInk, other.dangerInk),
      dangerTint: mix(dangerTint, other.dangerTint),
      dangerTintBorder: mix(dangerTintBorder, other.dangerTintBorder),
      warningTint: mix(warningTint, other.warningTint),
      warningTintBorder: mix(warningTintBorder, other.warningTintBorder),
      successTint: mix(successTint, other.successTint),
      successTintBorder: mix(successTintBorder, other.successTintBorder),
    );
  }
}
