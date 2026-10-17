import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/mx_status_colors.dart';

// The one place colour values are written (ADR-026).
//
// Light is ForUI's neutral palette with three values changed, each for a
// reason:
// - `primary` is the MemoX brand indigo instead of near-black.
// - `mutedForeground` is darker than ForUI's, so secondary text keeps 4.5:1
//   on `muted` as well as on `background`; the stock value is 4.35:1 there.
// - `error` and `destructive` are darker than ForUI's, so error text keeps
//   4.5:1 on its own tint (an error banner, a wrong answer); the stock red
//   reaches 4.07:1 there.
//
// Dark keeps the MemoX navy page and the brand primary from before the ForUI
// migration, and computes every other role from those two seeds
// ([darkColorsFrom], owner ruling 2026-10-17).

/// The brand indigo: `primary` in both modes.
const Color _brand = Color(0xFF564BCB);

/// The dark page, the MemoX navy.
const Color _darkPage = Color(0xFF0A082D);

/// The light palette.
final FColors appLightColors = FColors(
  brightness: Brightness.light,
  systemOverlayStyle: SystemUiOverlayStyle.dark,
  barrier: const Color(0x33000000),
  background: const Color(0xFFFFFFFF),
  foreground: const Color(0xFF0A0A0A),
  primary: _brand,
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
  extensions: const [MxStatusColors.light(primaryInk: _brand)],
);

/// The dark palette: the navy page and the brand primary, and every other
/// role computed from them.
final FColors appDarkColors = darkColorsFrom(
  background: _darkPage,
  primary: _brand,
);

/// A dark palette computed from its page [background] and its brand
/// [primary]. The neutrals step from the page toward a foreground that is
/// white tinted by the page; `primary` stays a fill under white text, and
/// the brand's text, glyph and edge colour ([MxStatusColors.primaryInk])
/// moves from `primary` toward the foreground until it reads on every
/// ground. Only error red and the status hues are not the seeds': they carry
/// meaning, not brand.
FColors darkColorsFrom({required Color background, required Color primary}) {
  final foreground = _mix(const Color(0xFFFFFFFF), background, 0.1);
  final muted = _mix(background, foreground, 0.12);
  return FColors(
    brightness: Brightness.dark,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    barrier: background.withValues(alpha: 0.48),
    background: background,
    foreground: foreground,
    primary: primary,
    primaryForeground: const Color(0xFFFFFFFF),
    secondary: muted,
    secondaryForeground: foreground,
    muted: muted,
    mutedForeground: _mix(foreground, background, 0.3),
    destructive: const Color(0xFFFF6467),
    destructiveForeground: background,
    error: const Color(0xFFFF6467),
    errorForeground: background,
    card: _mix(background, foreground, 0.06),
    border: foreground.withValues(alpha: 0.15),
    extensions: [
      MxStatusColors.dark(primaryInk: _mix(primary, foreground, 0.6)),
    ],
  );
}

/// [from] moved by [t] toward [to], as an opaque colour.
Color _mix(Color from, Color to, double t) => Color.lerp(from, to, t)!;
