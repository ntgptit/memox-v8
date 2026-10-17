import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:material_ui/material_ui.dart' show ThemeExtension;

/// The status colours ForUI's [FColors] has no role for: success, warning and
/// info, which carry learning progress, mastery and right or wrong answers
/// (ADR-026). It rides on the palette's `FColors.extensions`, read as
/// `context.status`.
///
/// Each status has an ink, the text and glyph colour that keeps 4.5:1 on the
/// page and on a tint of itself, and a fill, the bright colour of a bar, a
/// dot or a solid tile. Text on a fill uses the matching `on…Fill`.
@immutable
class MxStatusColors extends ThemeExtension<MxStatusColors> {
  const MxStatusColors({
    required this.success,
    required this.successFill,
    required this.onSuccessFill,
    required this.warning,
    required this.warningFill,
    required this.onWarningFill,
    required this.info,
    required this.infoFill,
  });

  static const MxStatusColors light = MxStatusColors(
    success: Color(0xFF006C49),
    successFill: Color(0xFF17AE79),
    onSuccessFill: Color(0xFF003925),
    warning: Color(0xFF855300),
    warningFill: Color(0xFFF59E0B),
    onWarningFill: Color(0xFF613B00),
    info: Color(0xFF006684),
    infoFill: Color(0xFF50CCFC),
  );

  static const MxStatusColors dark = MxStatusColors(
    success: Color(0xFF5ADDA4),
    successFill: Color(0xFF17AE79),
    onSuccessFill: Color(0xFF003925),
    warning: Color(0xFFFFC174),
    warningFill: Color(0xFFF59E0B),
    onWarningFill: Color(0xFF613B00),
    info: Color(0xFFA9E3FF),
    infoFill: Color(0xFF50CCFC),
  );

  /// A right answer, a finished session, mastered text.
  final Color success;

  /// The mastered band of the mastery ramp, a success dot or bar.
  final Color successFill;
  final Color onSuccessFill;

  /// A limit or something that waits; the learning band's text.
  final Color warning;

  /// The learning band of the mastery ramp, a warning dot or bar.
  final Color warningFill;
  final Color onWarningFill;

  /// A deck's glyph on its tile.
  final Color info;
  final Color infoFill;

  @override
  MxStatusColors copyWith({
    Color? success,
    Color? successFill,
    Color? onSuccessFill,
    Color? warning,
    Color? warningFill,
    Color? onWarningFill,
    Color? info,
    Color? infoFill,
  }) => MxStatusColors(
    success: success ?? this.success,
    successFill: successFill ?? this.successFill,
    onSuccessFill: onSuccessFill ?? this.onSuccessFill,
    warning: warning ?? this.warning,
    warningFill: warningFill ?? this.warningFill,
    onWarningFill: onWarningFill ?? this.onWarningFill,
    info: info ?? this.info,
    infoFill: infoFill ?? this.infoFill,
  );

  @override
  MxStatusColors lerp(ThemeExtension<MxStatusColors>? other, double t) {
    if (other is! MxStatusColors) return this;
    return MxStatusColors(
      success: Color.lerp(success, other.success, t)!,
      successFill: Color.lerp(successFill, other.successFill, t)!,
      onSuccessFill: Color.lerp(onSuccessFill, other.onSuccessFill, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningFill: Color.lerp(warningFill, other.warningFill, t)!,
      onWarningFill: Color.lerp(onWarningFill, other.onWarningFill, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoFill: Color.lerp(infoFill, other.infoFill, t)!,
    );
  }
}
