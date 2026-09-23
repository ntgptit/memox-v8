import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _importPattern = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Which other features each feature may import (through its barrel only).
const _allowedFeatureImports = <String, Set<String>>{
  'deck': {'srs'},
  'srs': {},
  'card': {'deck', 'srs'},
};

/// Layers that must stay free of Flutter, Riverpod and Drift.
const _pureFolders = [
  'lib/features/srs/domain/',
  'lib/features/deck/domain/',
  'lib/features/card/domain/',
];

const _forbiddenInPure = [
  'package:flutter/',
  'package:flutter_riverpod/',
  'package:riverpod_annotation/',
  'package:drift/',
  'package:memox/core/database/',
];

const _featurePrefix = 'package:memox/features/';

class _Source {
  _Source(this.path, this.imports);
  final String path;
  final List<String> imports;
}

List<_Source> _sources() {
  final dir = Directory('lib');
  if (!dir.existsSync()) return const [];
  return [
    for (final file in dir.listSync(recursive: true).whereType<File>())
      if (file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'))
        _Source(file.path.replaceAll(r'\', '/'), [
          for (final m in _importPattern.allMatches(file.readAsStringSync()))
            m.group(1)!,
        ]),
  ];
}

/// `lib/features/<name>/...` -> `<name>`, otherwise null.
String? _featureOf(String path) {
  const prefix = 'lib/features/';
  if (!path.startsWith(prefix)) return null;
  return path.substring(prefix.length).split('/').first;
}

/// `lib/features/<name>/domain/...` -> true (data/di may see Drift/Riverpod).
bool _isPresentationOrDataOnlyLayer(String path) =>
    path.contains('/data/') || path.contains('/di/');

void main() {
  final sources = _sources();

  test('domain layers import no Flutter, Riverpod, Drift or core/database', () {
    final violations = [
      for (final s in sources)
        if (_pureFolders.any(s.path.startsWith))
          for (final i in s.imports)
            if (_forbiddenInPure.any(i.startsWith)) '${s.path} imports $i',
    ];
    expect(violations, isEmpty);
  });

  test('features import other features only through an allowed barrel', () {
    final violations = <String>[];
    for (final s in sources) {
      final own = _featureOf(s.path);
      if (own == null) continue;
      for (final i in s.imports) {
        if (!i.startsWith(_featurePrefix)) continue;
        final rest = i.substring(_featurePrefix.length);
        final target = rest.split('/').first;
        if (target == own) continue;
        final allowed = _allowedFeatureImports[own] ?? const <String>{};
        if (!allowed.contains(target)) {
          violations.add('${s.path} may not depend on feature $target');
        } else if (rest != '$target/$target.dart') {
          violations.add('${s.path} must import $target via its barrel: $i');
        }
      }
    }
    expect(violations, isEmpty);
  });

  test('app and core never import feature internals', () {
    final violations = [
      for (final s in sources)
        if (s.path.startsWith('lib/app/') || s.path.startsWith('lib/core/'))
          for (final i in s.imports)
            if (i.startsWith(_featurePrefix) &&
                !RegExp(r'^package:memox/features/(\w+)/\1\.dart$').hasMatch(i))
              '${s.path} imports $i',
    ];
    expect(violations, isEmpty);
  });

  test('no file sits directly under a feature\'s data or di folder without a layer subfolder', () {
    // Guards the ADR-010 shape: data/{repositories,datasources}, di/ providers only.
    final violations = [
      for (final s in sources)
        if (_featureOf(s.path) != null &&
            _isPresentationOrDataOnlyLayer(s.path))
          if (s.path.endsWith(
                    '/data/${_featureOf(s.path)}_repository_impl.dart',
                  ) ==
                  false &&
              !RegExp(r'/data/(repositories|datasources|mappers)/')
                  .hasMatch(s.path) &&
              !RegExp(r'/di/').hasMatch(s.path))
            s.path,
    ];
    expect(violations, isEmpty);
  });
}
