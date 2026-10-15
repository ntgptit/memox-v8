// GENERATED from design/tokens.json by tools/design/generate.py. Do not edit.

import 'package:flutter/material.dart';

/// The colour tokens of the Design System that Material's [ColorScheme] has no role for.
@immutable
class MxColorsExtension extends ThemeExtension<MxColorsExtension> {
  const MxColorsExtension({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.cardSurface,
    required this.searchSurface,
    required this.tileSurface,
    required this.divider,
  });

  static const MxColorsExtension light = MxColorsExtension(
    success: Color(0xFF006C49),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFF17AE79),
    onSuccessContainer: Color(0xFF003925),
    warning: Color(0xFF855300),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFF59E0B),
    onWarningContainer: Color(0xFF613B00),
    info: Color(0xFF006684),
    onInfo: Color(0xFFFFFFFF),
    infoContainer: Color(0xFF50CCFC),
    onInfoContainer: Color(0xFF00546D),
    cardSurface: Color(0xFFF1F1FB),
    searchSurface: Color(0xFFF1F1FB),
    tileSurface: Color(0xFFEDF8FF),
    divider: Color(0xFFEEEEEE),
  );

  static const MxColorsExtension dark = MxColorsExtension(
    success: Color(0xFF5ADDA4),
    onSuccess: Color(0xFF003824),
    successContainer: Color(0xFF17AE79),
    onSuccessContainer: Color(0xFF003925),
    warning: Color(0xFFFFC174),
    onWarning: Color(0xFF472A00),
    warningContainer: Color(0xFFF59E0B),
    onWarningContainer: Color(0xFF613B00),
    info: Color(0xFFA9E3FF),
    onInfo: Color(0xFF003546),
    infoContainer: Color(0xFF50CCFC),
    onInfoContainer: Color(0xFF00546D),
    cardSurface: Color(0xFF222145),
    searchSurface: Color(0xFF222145),
    tileSurface: Color(0xFF2E3953),
    divider: Color(0xFF18173B),
  );

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color cardSurface;
  final Color searchSurface;
  final Color tileSurface;
  final Color divider;

  @override
  MxColorsExtension copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? cardSurface,
    Color? searchSurface,
    Color? tileSurface,
    Color? divider,
  }) {
    return MxColorsExtension(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      cardSurface: cardSurface ?? this.cardSurface,
      searchSurface: searchSurface ?? this.searchSurface,
      tileSurface: tileSurface ?? this.tileSurface,
      divider: divider ?? this.divider,
    );
  }

  @override
  MxColorsExtension lerp(ThemeExtension<MxColorsExtension>? other, double t) {
    if (other is! MxColorsExtension) return this;
    return MxColorsExtension(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      searchSurface: Color.lerp(searchSurface, other.searchSurface, t)!,
      tileSurface: Color.lerp(tileSurface, other.tileSurface, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}
