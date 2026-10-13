import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/color_tint.dart';

import 'token_source.dart';

// WCAG 2 contrast of the token pairs, worked from design/tokens.json. Pairs
// below the floor are recorded in design/contrast_exceptions.json with their
// measured ratio and the reason; the test fails when a pair falls below its
// floor without a record, and when a record no longer matches the measurement.

const double _text = 4.5;
const double _nonText = 3;

typedef _Pair = (String name, Color ink, Color ground, double minimum);

List<_Pair> _pairs(String mode) {
  Color c(String name) => tokenColor(name, mode);
  final surface = c('surface');
  final card = c('cardSurface');
  final accent = mode == 'light' ? c('primary') : c('primaryFixedDim');
  final pairs = <_Pair>[];
  void add(String name, Color ink, Color ground, [double min = _text]) =>
      pairs.add((name, ink, ground, min));

  for (final role in [
    'primary',
    'primaryContainer',
    'secondary',
    'secondaryContainer',
    'tertiary',
    'tertiaryContainer',
    'error',
    'errorContainer',
    'inverseSurface',
  ]) {
    final on = 'on${role[0].toUpperCase()}${role.substring(1)}';
    add('$on on $role', c(on), c(role));
  }
  for (final family in ['success', 'warning', 'info']) {
    add(
      '$family-onColor on $family-color',
      c('$family-onColor'),
      c('$family-color'),
    );
    add(
      '$family-onContainer on $family-container',
      c('$family-onContainer'),
      c('$family-container'),
    );
  }
  for (final (ground, where) in [(surface, 'surface'), (card, 'cardSurface')]) {
    add('onSurface on $where', c('onSurface'), ground);
    add('onSurfaceVariant on $where', c('onSurfaceVariant'), ground);
    add('accent on $where', accent, ground);
    add('error on $where', c('error'), ground);
    add('success on $where', c('success-color'), ground);
    add('warning on $where', c('warning-color'), ground);
    add('info on $where', c('info-color'), ground);
    add('outline on $where', c('outline'), ground, _nonText);
  }
  add(
    'inversePrimary on inverseSurface',
    c('inversePrimary'),
    c('inverseSurface'),
  );
  add('primary on surface', c('primary'), surface);
  for (final (name, ink) in [
    ('accent', accent),
    ('success', c('success-color')),
    ('warning', c('warning-color')),
    ('error', c('error')),
  ]) {
    add('$name on its tint over surface', ink, ink.tintOver(surface));
  }
  return pairs;
}

void main() {
  final exceptions =
      (jsonDecode(File('design/contrast_exceptions.json').readAsStringSync())
              as Map<String, dynamic>)['exceptions']
          as List<dynamic>;

  for (final mode in ['light', 'dark']) {
    group(mode, () {
      for (final (name, ink, ground, minimum) in _pairs(mode)) {
        test(name, () {
          final ratio = contrast(ink, ground);
          final known = exceptions.cast<Map<String, dynamic>>().where(
            (e) => e['pair'] == name && e['mode'] == mode,
          );
          if (known.isEmpty) {
            expect(ratio, greaterThanOrEqualTo(minimum));
            return;
          }
          expect(
            ratio,
            lessThan(minimum),
            reason: 'recorded exception is now met',
          );
          expect(
            ratio,
            closeTo((known.single['ratio'] as num).toDouble(), 0.01),
          );
          expect((known.single['reason'] as String).trim(), isNotEmpty);
        });
      }
    });
  }
}
