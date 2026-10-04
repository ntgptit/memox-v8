import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/design_values.dart';

/// DESIGN.md's shadow vocabulary, per theme (frontmatter `shadows`,
/// `shadows-dark`). Dark has no whisper: a card draws the ghost border there
/// instead. Read through `context.elevation`.
@immutable
class MxElevation extends ThemeExtension<MxElevation> {
  const MxElevation({
    required this.whisper,
    required this.chrome,
    required this.overlay,
    required this.fab,
  });

  factory MxElevation.from(DesignPalette palette) => MxElevation(
    whisper: palette.shadowWhisper,
    chrome: palette.shadowChrome,
    overlay: palette.shadowOverlay,
    fab: palette.shadowFab,
  );

  static final MxElevation light = MxElevation.from(DesignPalette.light);
  static final MxElevation dark = MxElevation.from(DesignPalette.dark);

  final List<BoxShadow> whisper;
  final List<BoxShadow> chrome;
  final List<BoxShadow> overlay;
  final List<BoxShadow> fab;

  @override
  MxElevation copyWith({
    List<BoxShadow>? whisper,
    List<BoxShadow>? chrome,
    List<BoxShadow>? overlay,
    List<BoxShadow>? fab,
  }) => MxElevation(
    whisper: whisper ?? this.whisper,
    chrome: chrome ?? this.chrome,
    overlay: overlay ?? this.overlay,
    fab: fab ?? this.fab,
  );

  @override
  MxElevation lerp(MxElevation? other, double t) {
    if (other == null) return this;
    List<BoxShadow> mix(List<BoxShadow> a, List<BoxShadow> b) =>
        BoxShadow.lerpList(a, b, t) ?? const [];
    return MxElevation(
      whisper: mix(whisper, other.whisper),
      chrome: mix(chrome, other.chrome),
      overlay: mix(overlay, other.overlay),
      fab: mix(fab, other.fab),
    );
  }
}
