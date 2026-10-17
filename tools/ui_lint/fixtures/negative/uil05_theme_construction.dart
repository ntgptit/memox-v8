import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

final material = ThemeData(useMaterial3: true);

final scheme = const ColorScheme.light(primary: Color(0xFF000000));

final colors = FColors(
  brightness: Brightness.light,
  systemOverlayStyle: SystemUiOverlayStyle.dark,
  barrier: const Color(0x33000000),
  background: const Color(0xFFFFFFFF),
  foreground: const Color(0xFF000000),
  primary: const Color(0xFF000000),
  primaryForeground: const Color(0xFFFFFFFF),
  secondary: const Color(0xFFF5F5F5),
  secondaryForeground: const Color(0xFF000000),
  muted: const Color(0xFFF5F5F5),
  mutedForeground: const Color(0xFF616161),
  destructive: const Color(0xFFC4000A),
  destructiveForeground: const Color(0xFFFFFFFF),
  error: const Color(0xFFC4000A),
  errorForeground: const Color(0xFFFFFFFF),
  card: const Color(0xFFFFFFFF),
  border: const Color(0xFFE5E5E5),
);

final theme = FThemeData(colors: colors, touch: true);
