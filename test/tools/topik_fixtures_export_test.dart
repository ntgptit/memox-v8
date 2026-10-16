import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/topik_contract_fixtures.dart';

// ADR-024 §7: the fixtures are the contract between the Dart validator, the
// SQL shape check and the Admin Web's TypeScript port. The committed files
// must be what the renderer writes today; MEMOX_UPDATE_FIXTURES=1 rewrites them.
void main() {
  test('the exported fixtures and the pgTAP file are fresh', () {
    final shouldWrite = Platform.environment['MEMOX_UPDATE_FIXTURES'] == '1';
    for (final MapEntry(key: path, value: content)
        in renderTopikContractFiles().entries) {
      final file = File(path);
      if (shouldWrite) {
        file
          ..createSync(recursive: true)
          ..writeAsStringSync(content);
        continue;
      }
      expect(
        file.existsSync(),
        isTrue,
        reason:
            '$path is missing: MEMOX_UPDATE_FIXTURES=1 flutter test test/tools/topik_fixtures_export_test.dart',
      );
      expect(file.readAsStringSync(), content, reason: '$path is stale');
    }
  });

  test('every broken fixture is an error in Dart, and the SQL rules it names are among them', () {
    for (final fixture in topikContractFixtures()) {
      expect(
        fixture.dartErrorRules,
        fixture.sqlRules.isEmpty ? isEmpty : isNotEmpty,
        reason: fixture.name,
      );
      // A JSON the mapper refuses never reaches checkTopikTest: both sides
      // reject it, and the SQL rules are not among the Dart ones.
      if (fixture.bothReject) continue;
      expect(
        fixture.dartErrorRules,
        containsAll(fixture.sqlRules),
        reason: fixture.name,
      );
    }
  });
}
