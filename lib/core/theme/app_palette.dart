import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/mx_status_colors.dart';

// The one place colour values are written (ADR-026). ForUI's neutral
// palette is the base; three values differ from it, each for a reason:
// - `primary` is MemoX indigo, the brand, instead of near-black. Dark mode
//   keeps the same indigo on the MemoX navy page (#0A082D), as before the
//   ForUI migration; every other dark value is computed from those two
//   colours (owner ruling 2026-10-17).
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

/// The dark palette: the MemoX navy page and the brand indigo, as before the
/// ForUI migration. The other values come from those two: the foreground is
/// white moved 10% toward the page, `card` and `muted` the page moved 6% and
/// 12% toward the foreground, `mutedForeground` the foreground moved 30%
/// toward the page, `border` the foreground at 15% and `barrier` the page at
/// 48%. Error red and the status hues carry meaning, not brand.
final FColors appDarkColors = FColors(
  brightness: Brightness.dark,
  systemOverlayStyle: SystemUiOverlayStyle.light,
  barrier: const Color(0x7A0A082D),
  background: const Color(0xFF0A082D),
  foreground: const Color(0xFFE6E6EA),
  primary: const Color(0xFF564BCB),
  primaryForeground: const Color(0xFFFFFFFF),
  secondary: const Color(0xFF242344),
  secondaryForeground: const Color(0xFFE6E6EA),
  muted: const Color(0xFF242344),
  mutedForeground: const Color(0xFFA4A3B1),
  destructive: const Color(0xFFFF6467),
  destructiveForeground: const Color(0xFF0A082D),
  error: const Color(0xFFFF6467),
  errorForeground: const Color(0xFF0A082D),
  card: const Color(0xFF171538),
  border: const Color(0x26E6E6EA),
  extensions: const [MxStatusColors.dark],
);
