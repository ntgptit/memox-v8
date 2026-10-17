import 'package:flutter/painting.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/mx_status_colors.dart';

/// The status colours each palette carries, as `context.status` reads them.
final MxStatusColors lightStatus = appLightColors.extension<MxStatusColors>();
final MxStatusColors darkStatus = appDarkColors.extension<MxStatusColors>();

/// The brand's ink in [colors]: the colour of the brand as text, a glyph or an
/// edge (primary itself in light).
Color inkOf(FColors colors) => colors.extension<MxStatusColors>().primaryInk;
