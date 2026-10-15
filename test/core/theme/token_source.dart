import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

/// `design/tokens.json` and `design/app_tokens.json`, read at run time: no test
/// states a token value of its own, so a new export needs no test edit.
final Map<String, dynamic> tokensJson = jsonDecode(
  File('design/tokens.json').readAsStringSync(),
) as Map<String, dynamic>;

final Map<String, dynamic> appTokensJson = jsonDecode(
  File('design/app_tokens.json').readAsStringSync(),
) as Map<String, dynamic>;

List<Map<String, dynamic>> _list(Object? value) =>
    (value! as List<dynamic>).cast<Map<String, dynamic>>();

List<Map<String, dynamic>> get colorTokens =>
    _list((tokensJson['color'] as Map<String, dynamic>)['tokens']);

List<Map<String, dynamic>> groupTokens(String group) =>
    _list((tokensJson[group] as Map<String, dynamic>)['tokens']);

Color hexColor(String hex) =>
    Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));

/// The colour of the token [name] in [mode] (`light` or `dark`).
Color tokenColor(String name, String mode) {
  final token = colorTokens.firstWhere((t) => t['name'] == name);
  final value = token['value'];
  return hexColor(value is String ? value : (value as Map)[mode] as String);
}

/// `24px` / `0.08` / `100ms` as a number.
double tokenNumber(String text) =>
    double.parse(text.replaceAll('px', '').replaceAll('ms', ''));

/// `space-4` -> `space4`, `size-nav-indicator-width` -> `sizeNavIndicatorWidth`.
String camelName(String kebab) {
  final parts = kebab.split('-');
  return parts.first +
      parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
}

/// The numeric dimension tokens by their Dart field name, `radius-full` excluded.
Map<String, double> get dimensionTokens => {
  for (final group in ['spacing', 'radius', 'size', 'stroke', 'opacity'])
    for (final token in groupTokens(group))
      if (token['name'] != 'radius-full')
        camelName(token['name'] as String): tokenNumber(
          token['value'] as String,
        ),
};

Map<String, double> get appOnlyTokens => {
  for (final token in _list(appTokensJson['tokens']))
    token['name'] as String: (token['value'] as num).toDouble(),
};

/// WCAG 2 contrast ratio.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
