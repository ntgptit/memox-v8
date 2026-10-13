import 'package:flutter_test/flutter_test.dart';

import 'write_gate_rules.dart';

// DEV-178: each rule of write_gate_rules.dart fires on a planted violation
// and stays quiet on the shapes the data layers use.

const _path = 'lib/features/x/data/repositories/x_repository_impl.dart';

void main() {
  test('a raw transaction that inserts is reported with its member and '
      'its write', () {
    const source = '''
final class XRepositoryImpl implements XRepository {
  @override
  Future<void> initializeCard({required String cardId}) =>
      _db.transaction(() async {
        final root = await _dao.rootOfCard(cardId);
        await _dao.insertSchedule(cardScheduleColumnsOf(root));
      });
}
''';

    expect(writeGateViolations({_path: source}, const {}), [
      '$_path#initializeCard: insertSchedule',
    ]);
  });

  test('a raw transaction that only reads is a read model', () {
    const source = '''
final class XRepositoryImpl implements XRepository {
  @override
  Stream<Progress> watchProgress(ProgressDays days) => _progress
      .changes()
      .asyncMap((_) => _db.transaction(() => _progressOf(days)))
      .mapDatabaseErrors();

  Future<Outcome<Snapshot, XRejection>> exportSnapshot() => guardDatabase(
    () => _db.transaction(() async {
      final deck = await _dao.deckRow(deckId);
      final rows = await _dao.exportRows(deckId, "SELECT COUNT(*) FROM x");
      return Ok(Snapshot(updatedAt: deck.updatedAt, rows: rows));
    }),
  );
}
''';

    expect(writeGateViolations({_path: source}, const {}), isEmpty);
  });

  test('a write through mappedTransaction is not a raw transaction', () {
    const source = '''
final class XRepositoryImpl implements XRepository {
  Future<void> rename(String id) => _db.mappedTransaction(() async {
    await _dao.updateName(id);
    await _store.inTransaction(() => _dao.deleteRow(id));
  });
}
''';

    expect(rawTransactions({_path: source}), isEmpty);
  });

  test('an allowlisted call is excused, and an entry that excuses nothing '
      'is stale', () {
    const source = '''
final class XRepositoryImpl implements XRepository {
  Future<void> seed() => _db.transaction(() => _dao.customStatement('x'));
}
''';
    const allowlist = {
      '$_path#seed': 'a reason',
      '$_path#gone': 'another reason',
    };

    expect(writeGateViolations({_path: source}, allowlist), isEmpty);
    expect(staleAllowlistEntries({_path: source}, allowlist), ['$_path#gone']);
  });

  test('the body ends at the matching parenthesis, a parenthesis in a '
      'string skipped', () {
    const text = "f(a('(x'), g(b)) + h(c)";

    expect(bodyOf(text, 1), "a('(x'), g(b)");
    expect(writesIn("await _dao.updateRow(1); _dao.deleteRow(2); x.deleted"), [
      'updateRow',
      'deleteRow',
    ]);
  });
}
