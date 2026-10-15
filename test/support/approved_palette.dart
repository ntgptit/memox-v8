import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The 45 Material 3 role names, in the order of `m3RoleColors`.
const List<String> m3RoleNames = [
  'primary',
  'onPrimary',
  'primaryContainer',
  'onPrimaryContainer',
  'primaryFixed',
  'primaryFixedDim',
  'onPrimaryFixed',
  'onPrimaryFixedVariant',
  'secondary',
  'onSecondary',
  'secondaryContainer',
  'onSecondaryContainer',
  'secondaryFixed',
  'secondaryFixedDim',
  'onSecondaryFixed',
  'onSecondaryFixedVariant',
  'tertiary',
  'onTertiary',
  'tertiaryContainer',
  'onTertiaryContainer',
  'tertiaryFixed',
  'tertiaryFixedDim',
  'onTertiaryFixed',
  'onTertiaryFixedVariant',
  'error',
  'onError',
  'errorContainer',
  'onErrorContainer',
  'surface',
  'onSurface',
  'surfaceDim',
  'surfaceBright',
  'surfaceContainerLowest',
  'surfaceContainerLow',
  'surfaceContainer',
  'surfaceContainerHigh',
  'surfaceContainerHighest',
  'onSurfaceVariant',
  'outline',
  'outlineVariant',
  'shadow',
  'scrim',
  'inverseSurface',
  'onInverseSurface',
  'inversePrimary',
];

/// The approved palette, read from `design/tokens.json` at test time: it is
/// the fixture the production theme is compared with, never derived from it.
typedef _Palette = ({Map<String, Color> light, Map<String, Color> dark});

_Palette? _cached;

_Palette _palette() => _cached ??= _read();

_Palette _read() {
  final json = jsonDecode(
    File('design/tokens.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final light = <String, Color>{};
  final dark = <String, Color>{};
  _walk(json['color'], light, dark);
  return (light: light, dark: dark);
}

void _walk(Object? node, Map<String, Color> light, Map<String, Color> dark) {
  if (node is List<Object?>) {
    for (final child in node) {
      _walk(child, light, dark);
    }
    return;
  }
  if (node is! Map<String, Object?>) return;
  final name = node['name'];
  final value = node['value'];
  if (name is String && value is Map<String, Object?>) {
    final lightHex = value['light'];
    final darkHex = value['dark'];
    if (lightHex is String && darkHex is String) {
      light[name] = _color(lightHex);
      dark[name] = _color(darkHex);
      return;
    }
  }
  for (final child in node.values) {
    _walk(child, light, dark);
  }
}

Color _color(String hex) {
  final digits = hex.substring(1);
  final red = int.parse(digits.substring(0, 2), radix: 16);
  final green = int.parse(digits.substring(2, 4), radix: 16);
  final blue = int.parse(digits.substring(4, 6), radix: 16);
  if (digits.length == 6) return Color.fromARGB(255, red, green, blue);
  final alpha = int.parse(digits.substring(6, 8), radix: 16);
  return Color.fromARGB(alpha, red, green, blue);
}

/// The 45 approved role colours of [brightness]. Throws when
/// `design/tokens.json` lacks one of them.
Map<String, Color> approvedRoles(Brightness brightness) {
  final all = brightness == Brightness.light
      ? _palette().light
      : _palette().dark;
  final missing = [
    for (final name in m3RoleNames)
      if (!all.containsKey(name)) name,
  ];
  if (missing.isNotEmpty) {
    throw StateError('design/tokens.json lacks the roles: $missing');
  }
  return {for (final name in m3RoleNames) name: all[name]!};
}

/// One approved colour by token name, `surfaceTint` included (ledger DSD-27).
Color approvedRole(String name, Brightness brightness) {
  final all = brightness == Brightness.light
      ? _palette().light
      : _palette().dark;
  final color = all[name];
  if (color == null) throw StateError('design/tokens.json lacks "$name"');
  return color;
}

/// The 45 role getters of [scheme] (spec 9.3 `m3RoleColors`).
Map<String, Color> m3RoleColors(ColorScheme s) => {
  'primary': s.primary,
  'onPrimary': s.onPrimary,
  'primaryContainer': s.primaryContainer,
  'onPrimaryContainer': s.onPrimaryContainer,
  'primaryFixed': s.primaryFixed,
  'primaryFixedDim': s.primaryFixedDim,
  'onPrimaryFixed': s.onPrimaryFixed,
  'onPrimaryFixedVariant': s.onPrimaryFixedVariant,
  'secondary': s.secondary,
  'onSecondary': s.onSecondary,
  'secondaryContainer': s.secondaryContainer,
  'onSecondaryContainer': s.onSecondaryContainer,
  'secondaryFixed': s.secondaryFixed,
  'secondaryFixedDim': s.secondaryFixedDim,
  'onSecondaryFixed': s.onSecondaryFixed,
  'onSecondaryFixedVariant': s.onSecondaryFixedVariant,
  'tertiary': s.tertiary,
  'onTertiary': s.onTertiary,
  'tertiaryContainer': s.tertiaryContainer,
  'onTertiaryContainer': s.onTertiaryContainer,
  'tertiaryFixed': s.tertiaryFixed,
  'tertiaryFixedDim': s.tertiaryFixedDim,
  'onTertiaryFixed': s.onTertiaryFixed,
  'onTertiaryFixedVariant': s.onTertiaryFixedVariant,
  'error': s.error,
  'onError': s.onError,
  'errorContainer': s.errorContainer,
  'onErrorContainer': s.onErrorContainer,
  'surface': s.surface,
  'onSurface': s.onSurface,
  'surfaceDim': s.surfaceDim,
  'surfaceBright': s.surfaceBright,
  'surfaceContainerLowest': s.surfaceContainerLowest,
  'surfaceContainerLow': s.surfaceContainerLow,
  'surfaceContainer': s.surfaceContainer,
  'surfaceContainerHigh': s.surfaceContainerHigh,
  'surfaceContainerHighest': s.surfaceContainerHighest,
  'onSurfaceVariant': s.onSurfaceVariant,
  'outline': s.outline,
  'outlineVariant': s.outlineVariant,
  'shadow': s.shadow,
  'scrim': s.scrim,
  'inverseSurface': s.inverseSurface,
  'onInverseSurface': s.onInverseSurface,
  'inversePrimary': s.inversePrimary,
};

/// Fails, naming each role, when [actual] differs from [approved] in any of
/// the 45 roles.
void expectM3Roles(ColorScheme actual, Map<String, Color> approved) {
  final observed = m3RoleColors(actual);
  expect(observed.length, 45, reason: '45 M3 role getters required');
  expect(approved.length, 45, reason: 'the fixture must declare all 45 roles');
  expect(
    approved.keys.toSet(),
    observed.keys.toSet(),
    reason: 'missing or extra approved role names',
  );
  final mismatches = [
    for (final role in observed.keys)
      if (observed[role] != approved[role])
        '$role: observed=${observed[role]}, approved=${approved[role]}',
  ];
  expect(
    mismatches,
    isEmpty,
    reason:
        'ColorScheme differs from the approved palette:\n'
        '${mismatches.join('\n')}',
  );
}
