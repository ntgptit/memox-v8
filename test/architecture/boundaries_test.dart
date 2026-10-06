import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'boundary_rules.dart';

/// Applies the ADR-011 folder and import rules to the real `lib/`. Each rule
/// is proven to fire on a planted violation in `boundary_rules_test.dart`.
void main() {
  final sources = readSources(Directory.current);

  test('the tree has the ADR-011 shape', () {
    expect(shapeViolations(sources), isEmpty);
  });

  test('domain layers stay plain Dart', () {
    expect(domainPurityViolations(sources), isEmpty);
  });

  test('features reach each other through public buckets, along the map', () {
    expect(crossFeatureViolations(sources), isEmpty);
  });

  test('core imports no feature, app/ or shared/', () {
    expect(coreViolations(sources), isEmpty);
  });

  // DEV-173: a table's sync adapter lives in the feature that owns the
  // table, so core/sync names none of the feature tables.
  test('core/sync names no feature table', () {
    const companions = [
      'DeckCompanion',
      'CardCompanion',
      'TagsCompanion',
      'CardScheduleCompanion',
      'ReviewLogCompanion',
      'AppSettingsCompanion',
      'DeleteBatchesCompanion',
    ];
    final offenders = <String>[];
    for (final file in Directory('lib/core/sync').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.endsWith('.g.dart')) continue;
      final source = file.readAsStringSync();
      for (final name in companions) {
        if (source.contains(name)) offenders.add('${file.path}: $name');
      }
    }
    expect(offenders, isEmpty);
  });

  test('the feature import map is acyclic', () {
    expect(cyclesIn(allowedFeatureImports), isEmpty);
  });
}
