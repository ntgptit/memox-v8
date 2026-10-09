import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'write_gate_rules.dart';

/// The raw transactions that write on purpose, by `file#member`, each with
/// its reason. None today: every business write goes through
/// `mappedTransaction`, where the account's gate is checked (auth spec R3).
const _writesOutsideTheGate = <String, String>{};

// Auth spec R3, database error guard spec D2 (DEV-178) over the real
// `lib/features/*/data/`: a raw `transaction(` is a read model. Each rule is
// proven on planted sources in `write_gate_rules_test.dart`.
void main() {
  late Map<String, String> sources;
  setUpAll(() => sources = readDataSources(Directory.current));

  test('the data layers hold the files the rule reads', () {
    expect(
      sources.keys,
      contains(
        'lib/features/srs/data/repositories/schedule_repository_impl.dart',
      ),
    );
  });

  test('every write of a data layer goes through mappedTransaction, or '
      'says why it does not (auth spec R3)', () {
    expect(writeGateViolations(sources, _writesOutsideTheGate), isEmpty);
  });

  test('every allowlist entry still excuses a write', () {
    expect(staleAllowlistEntries(sources, _writesOutsideTheGate), isEmpty);
  });
}
