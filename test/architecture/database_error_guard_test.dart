import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Spec 2026-09-29-database-error-guard-design.md D5: outside `lib/core/`,
/// no file calls `mapDatabaseError(` itself; repositories go through
/// `guardDatabase`, `mappedTransaction` or `mapDatabaseErrors()`, so the
/// private copies do not come back.
List<String> directMappings(Map<String, String> sources) => [
  for (final MapEntry(key: path, value: text) in sources.entries)
    if (!path.startsWith('lib/core/') && text.contains('mapDatabaseError('))
      path,
];

void main() {
  test('a direct call outside core is reported, one inside is not', () {
    expect(
      directMappings({
        'lib/features/x/data/repositories/x_repository_impl.dart':
            'Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);',
        'lib/core/error/failure.dart': 'sink.addError(mapDatabaseError(e));',
      }),
      ['lib/features/x/data/repositories/x_repository_impl.dart'],
    );
  });

  test('lib/ maps database errors only through core', () {
    final sources = {
      for (final entity in Directory('lib').listSync(recursive: true))
        if (entity is File &&
            entity.path.endsWith('.dart') &&
            !entity.path.endsWith('.g.dart'))
          entity.path.replaceAll(r'\', '/'): entity.readAsStringSync(),
    };

    expect(directMappings(sources), isEmpty);
  });
}
