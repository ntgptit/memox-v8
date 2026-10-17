import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/mx_status_colors.dart';

// The one place colour values are written (ADR-025). ForUI's neutral
// palette is the base; three values differ from it, each for a reason:
// - `primary` is MemoX indigo, the brand, instead of near-black. Dark mode
//   takes the light step, so an accent glyph or label reads on the dark
//   page without a per-mode rule in the widgets.
// - `mutedForeground` is darker (light) and lighter (dark) than ForUI's, so
//   secondary text keeps 4.5:1 on `muted` as well as on `background`; the
//   stock value is 4.35:1 on `muted`.
// - Light `error` and `destructive` are darker than ForUI's, so error text
//   keeps 4.5:1 on its own tint (an error banner, a wrong answer); the stock
//   red reaches 4.07:1 there.

/// The light palette.
final FColors appLightColors = FColors(
  brightness: Brightness.light,
  systemOverlayStyle: SystemUiOverlayStyle.dark,
  barrier: const Color(0x33000000),
  background: const Color(0xFFFFFFFF),
  foreground: const Color(0xFF0A0A0A),
  primary: const Color(0xFF564BCB),
  primaryForeground: const Color(0xFFFFFFFF),
  secondary: const Color(0xFFF5F5F5),
  secondaryForeground: const Color(0xFF171717),
  muted: const Color(0xFFF5F5F5),
  mutedForeground: const Color(0xFF616161),
  destructive: const Color(0xFFC4000A),
  destructiveForeground: const Color(0xFFFAFAFA),
  error: const Color(0xFFC4000A),
  errorForeground: const Color(0xFFFAFAFA),
  card: const Color(0xFFFFFFFF),
  border: const Color(0xFFE5E5E5),
  extensions: const [MxStatusColors.light],
);

/// The dark palette, authored on its own rather than as a filter over light.
final FColors appDarkColors = FColors(
  brightness: Brightness.dark,
  systemOverlayStyle: SystemUiOverlayStyle.light,
  barrier: const Color(0x7A000000),
  background: const Color(0xFF0A0A0A),
  foreground: const Color(0xFFFAFAFA),
  primary: const Color(0xFFC5C0FF),
  primaryForeground: const Color(0xFF1B1464),
  secondary: const Color(0xFF262626),
  secondaryForeground: const Color(0xFFFAFAFA),
  muted: const Color(0xFF262626),
  mutedForeground: const Color(0xFFADADAD),
  destructive: const Color(0xFFFF6467),
  destructiveForeground: const Color(0xFF0A0A0A),
  error: const Color(0xFFFF6467),
  errorForeground: const Color(0xFF0A0A0A),
  card: const Color(0xFF171717),
  border: const Color(0x26FFFFFF),
  extensions: const [MxStatusColors.dark],
);
