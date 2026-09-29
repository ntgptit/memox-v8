import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ADR-018: every log goes through AppLogger; outside `lib/core/logging/`, no
/// file imports `dart:developer`.
List<String> developerImports(Map<String, String> sources) => [
  for (final MapEntry(key: path, value: text) in sources.entries)
    if (!path.startsWith('lib/core/logging/') &&
        RegExp(r'''import\s+['"]dart:developer['"]''').hasMatch(text))
      path,
];

void main() {
  test('a dart:developer import outside core/logging is reported', () {
    expect(
      developerImports({
        'lib/core/sync/sync_scheduler.dart': "import 'dart:developer';",
        'lib/core/logging/console_sink.dart':
            "import 'dart:developer' as developer;",
      }),
      ['lib/core/sync/sync_scheduler.dart'],
    );
  });

  test('lib/ logs only through AppLogger', () {
    final sources = {
      for (final entity in Directory('lib').listSync(recursive: true))
        if (entity is File && entity.path.endsWith('.dart'))
          entity.path.replaceAll(r'\', '/'): entity.readAsStringSync(),
    };

    expect(developerImports(sources), isEmpty);
  });
}
