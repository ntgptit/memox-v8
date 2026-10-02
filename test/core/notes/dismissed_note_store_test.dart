import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/notes/dismissed_note_store.dart';
import 'package:memox/core/notes/note_keys.dart';

import '../../support/test_database.dart';

// Critique 2026-09-30: a one-time note stays hidden once dismissed, on this
// device only.

void main() {
  late AppDatabase db;
  late DismissedNoteStore store;

  setUp(() {
    db = openTestDatabase();
    store = DismissedNoteStore(db, now: () => DateTime.utc(2026, 9, 30));
  });

  tearDown(() => db.close());

  test('nothing is dismissed at first', () async {
    expect(await store.watchDismissed().first, isEmpty);
  });

  test('a dismissed note is in the set, and dismissing it again changes '
      'nothing', () async {
    await store.dismiss(NoteKeys.trashRetention);
    await store.dismiss(NoteKeys.trashRetention);

    expect(await store.watchDismissed().first, {NoteKeys.trashRetention});
  });

  test('the set is read from the table, so a second store sees it', () async {
    await store.dismiss(NoteKeys.importHelper);

    final other = DismissedNoteStore(db);
    expect(await other.watchDismissed().first, {NoteKeys.importHelper});
  });

  test('a screen watching the set sees a note go as it is dismissed', () async {
    final seen = <Set<String>>[];
    final subscription = store.watchDismissed().listen(seen.add);
    await pumpEventQueue();

    await store.dismiss(NoteKeys.trashRetention);
    await pumpEventQueue();
    await subscription.cancel();

    expect(seen, [
      <String>{},
      {NoteKeys.trashRetention},
    ]);
  });

  test('the table never syncs: dismissing queues nothing', () async {
    await store.dismiss(NoteKeys.starterFixtures);

    final outbox = await db
        .customSelect('SELECT COUNT(*) AS n FROM sync_outbox')
        .getSingle();
    expect(outbox.read<int>('n'), 0);
  });
}
