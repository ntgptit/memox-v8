import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../support/invariant_queries.dart';
import 'generated/schema.dart';

// BE-D1: every schema version upgrades to the current one, with its rows and
// their values intact (spec §5.3; .claude/skills/flutter-drift/references/
// migrations.md).

/// A v1 database a person could have: two trees, learned and new cards, three
/// ended sessions and one open in `guess`, and turns of every kind, the
/// `recall` and `fill` ones with their own columns.
const _v1Rows = <String>[
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, first_answered_at, study_config, sibling_position, created_at, updated_at) VALUES ('R', 'Korean', NULL, 'R', 1, 'deck', 'eight_box', 1, 1, 100, '{\"cardLimit\": 10}', 0, 0, 0)",
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, first_answered_at, sibling_position, created_at, updated_at) VALUES ('S', 'Verbs', NULL, 'S', 1, 'deck', 'sm2', 1, 1, 100, 1, 0, 0)",
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('R1', 'Food', 'R', 'R', 2, 'card', 0, 0, 0), ('S1', 'Motion', 'S', 'S', 2, 'card', 0, 0, 0)",
  "INSERT INTO card (id, deck_id, front, back, front_folded, back_folded, example, hint, created_at, updated_at) VALUES ('k1', 'R1', '밥', 'Cơm', '밥', 'cơm', 'Tôi ăn cơm.', NULL, 1, 1), ('k2', 'R1', '물', 'Nước', '물', 'nước', NULL, NULL, 2, 2), ('k3', 'R1', '빵', 'Bánh mì', '빵', 'bánh mì', 'Bánh mì nóng.', 'Bắt đầu bằng B', 3, 3), ('k4', 'R1', '차', 'Trà', '차', 'trà', NULL, NULL, 4, 4), ('k5', 'R1', '국', 'Canh', '국', 'canh', NULL, NULL, 5, 5), ('k6', 'R1', '김치', 'Kim chi', '김치', 'kim chi', NULL, NULL, 6, 6), ('m1', 'S1', '가다', 'Đi', '가다', 'đi', NULL, NULL, 7, 7)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, learned_at, due_at, last_answered_at, answer_count, lapse_count, current_box) VALUES ('k1', 'eight_box', 1, 1, 100, 900, 420, 6, 1, 3), ('k2', 'eight_box', 1, 1, 100, 800, 140, 5, 1, 1)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, answer_count, current_box) VALUES ('k3', 'eight_box', 1, 1, 1, 1), ('k4', 'eight_box', 1, 1, 1, 1), ('k5', 'eight_box', 1, 1, 1, 1), ('k6', 'eight_box', 1, 1, 1, 1)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, learned_at, due_at, last_answered_at, answer_count, lapse_count, ease_factor, interval_days, repetitions) VALUES ('m1', 'sm2', 1, 1, 100, 700, 310, 3, 0, 2.5, 6, 2)",
  "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t1', 'Món ăn', 'món ăn', 0)",
  "INSERT INTO card_tags (card_id, tag_id) VALUES ('k1', 't1')",
  "INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, status, end_reason, direction, cursor, card_limit, started_at, ended_at) VALUES ('learned', 'R', 'R', 1, 'learning', 'fill', 'completed', NULL, NULL, 12, 20, 90, 150), ('review', 'R', 'R', 1, 'reviewing', 'recall', 'completed', NULL, NULL, 1, 20, 400, 450), ('sm2', 'S', 'S', 1, 'reviewing', 'self_assess', 'completed', NULL, 'mixed', 1, 20, 300, 320), ('open', 'R', 'R', 1, 'learning', 'guess', 'in_progress', NULL, NULL, 8, 20, 1000, NULL)",
  "INSERT INTO study_queue_items (session_id, mode, round, card_id, position, status, available_at, answers_in_session, remaining_ms, is_revealed, direction) VALUES "
      "('learned', 'browse', 1, 'k1', 0, 'completed', 0, 0, NULL, 0, NULL), ('learned', 'browse', 1, 'k2', 1, 'completed', 0, 0, NULL, 0, NULL), "
      "('learned', 'match', 1, 'k2', 0, 'completed', 0, 1, NULL, 0, NULL), ('learned', 'match', 1, 'k1', 1, 'completed', 0, 1, NULL, 0, NULL), "
      "('learned', 'guess', 1, 'k1', 0, 'completed', 0, 1, NULL, 0, NULL), ('learned', 'guess', 1, 'k2', 1, 'completed', 0, 1, NULL, 0, NULL), "
      "('learned', 'recall', 1, 'k2', 0, 'completed', 0, 1, 0, 0, NULL), ('learned', 'recall', 1, 'k1', 1, 'completed', 0, 1, 7400, 1, NULL), "
      "('learned', 'recall', 2, 'k2', 0, 'completed', 0, 1, 11200, 1, NULL), ('learned', 'fill', 1, 'k1', 0, 'completed', 0, 1, NULL, 0, NULL), "
      "('review', 'recall', 1, 'k1', 0, 'completed', 0, 1, 15000, 1, NULL), "
      "('sm2', 'self_assess', 1, 'm1', 0, 'completed', 0, 1, NULL, 0, 'korean_to_meaning'), "
      "('open', 'browse', 1, 'k3', 0, 'completed', 0, 0, NULL, 0, NULL), ('open', 'browse', 1, 'k4', 1, 'completed', 0, 0, NULL, 0, NULL), "
      "('open', 'browse', 1, 'k5', 2, 'completed', 0, 0, NULL, 0, NULL), ('open', 'browse', 1, 'k6', 3, 'completed', 0, 0, NULL, 0, NULL), "
      "('open', 'match', 1, 'k5', 0, 'completed', 0, 1, NULL, 0, NULL), ('open', 'match', 1, 'k3', 1, 'completed', 0, 1, NULL, 0, NULL), "
      "('open', 'match', 1, 'k6', 2, 'completed', 0, 1, NULL, 0, NULL), ('open', 'match', 1, 'k4', 3, 'completed', 0, 1, NULL, 0, NULL), "
      "('open', 'guess', 1, 'k4', 0, 'pending', 0, 0, NULL, 0, NULL), ('open', 'guess', 1, 'k6', 1, 'pending', 0, 0, NULL, 0, NULL), "
      "('open', 'guess', 1, 'k3', 2, 'pending', 0, 0, NULL, 0, NULL), ('open', 'guess', 1, 'k5', 3, 'pending', 0, 0, NULL, 0, NULL), "
      "('open', 'recall', 1, 'k6', 0, 'pending', 0, 0, NULL, 0, NULL), ('open', 'recall', 1, 'k3', 1, 'pending', 0, 0, NULL, 0, NULL), "
      "('open', 'recall', 1, 'k5', 2, 'pending', 0, 0, NULL, 0, NULL), ('open', 'recall', 1, 'k4', 3, 'pending', 0, 0, NULL, 0, NULL), "
      "('open', 'fill', 1, 'k3', 0, 'pending', 0, 0, NULL, 0, NULL)",
  "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, \"action\", answered_at, next_due_at, previous_box, next_box) VALUES "
      "('l1', 'k2', 'learned', 'eight_box', 1, 'learning', 'match', 'remembered', 100, NULL, 1, 1), ('l2', 'k1', 'learned', 'eight_box', 1, 'learning', 'match', 'remembered', 101, NULL, 1, 1), "
      "('l3', 'k1', 'learned', 'eight_box', 1, 'learning', 'guess', 'remembered', 102, NULL, 1, 1), ('l4', 'k2', 'learned', 'eight_box', 1, 'learning', 'guess', 'remembered', 103, NULL, 1, 1), "
      "('l6', 'k1', 'learned', 'eight_box', 1, 'learning', 'recall', 'remembered', 105, NULL, 1, 1), ('l7', 'k2', 'learned', 'eight_box', 1, 'relearning', 'recall', 'remembered', 106, NULL, 1, 1), "
      "('l9', 'k1', 'review', 'eight_box', 1, 'scheduled', 'recall', 'remembered', 420, 900, 2, 3), "
      "('l10', 'k5', 'open', 'eight_box', 1, 'learning', 'match', 'remembered', 1001, NULL, 1, 1), ('l11', 'k3', 'open', 'eight_box', 1, 'learning', 'match', 'remembered', 1002, NULL, 1, 1), "
      "('l12', 'k6', 'open', 'eight_box', 1, 'learning', 'match', 'remembered', 1003, NULL, 1, 1), ('l13', 'k4', 'open', 'eight_box', 1, 'learning', 'match', 'remembered', 1004, NULL, 1, 1)",
  "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, outcome_reason, \"action\", answered_at, previous_box, next_box) VALUES ('l5', 'k2', 'learned', 'eight_box', 1, 'learning', 'recall', 'timeout', 'forgotten', 104, 1, 1)",
  "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, comparison_version, used_hint, \"action\", answered_at, previous_box, next_box) VALUES ('l8', 'k1', 'learned', 'eight_box', 1, 'learning', 'fill', 1, 0, 'remembered', 107, 1, 1)",
  "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, direction, \"action\", answered_at, next_due_at, previous_ease_factor, next_ease_factor, previous_interval_days, next_interval_days) VALUES ('l14', 'm1', 'sm2', 'sm2', 1, 'scheduled', 'self_assess', 'korean_to_meaning', 'good', 310, 700, 2.5, 2.5, 1, 6)",
  "INSERT INTO app_settings (id, card_limit, new_card_order, theme_mode, language, updated_at) VALUES (1, 15, 'random', 'dark', 'vi', 5)",
];

/// The tables of v1, whose rows the upgrade must keep as they are.
const _v1Tables = [
  'deck',
  'card',
  'card_schedule',
  'tags',
  'card_tags',
  'study_session',
  'study_queue_items',
  'review_log',
  'app_settings',
];

/// The columns v2 adds to v1's tables (spec §6.1).
const _v2Columns = {'hint_shown', 'meaning_slot'};

/// A row as text, its columns in name order, so two reads compare as sets.
String _canonical(Map<String, Object?> row) =>
    ([...row.keys]..sort()).map((column) => '$column=${row[column]}').join('|');

/// [rows] as text without v2's columns, in a stable order.
List<String> _v1Values(Iterable<Map<String, Object?>> rows) => [
  for (final row in rows)
    _canonical({
      for (final MapEntry(:key, :value) in row.entries)
        if (!_v2Columns.contains(key)) key: value,
    }),
]..sort();

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v1 upgrades to the schema of v2', () async {
    final db = AppDatabase(await verifier.startAt(1));
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);
  });

  test(
    'a new database has the schema of v2, the one an upgrade ends at',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 2);
    },
  );

  group('a v1 database with rows', () {
    late AppDatabase db;
    late Map<String, List<String>> before;

    setUp(() async {
      final schema = await verifier.schemaAt(1);
      for (final statement in _v1Rows) {
        schema.rawDatabase.execute(statement);
      }
      before = {
        for (final table in _v1Tables)
          table: _v1Values(schema.rawDatabase.select('SELECT * FROM $table')),
      };
      db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 2);
    });
    tearDown(() => db.close());

    test('keeps every row of v1 with its values', () async {
      for (final table in _v1Tables) {
        final after = await db.customSelect('SELECT * FROM $table').get();
        expect(
          _v1Values([for (final row in after) row.data]),
          before[table],
          reason: table,
        );
      }
      expect(before['study_queue_items'], hasLength(29));
      expect(before['review_log'], hasLength(14));
    });

    test('gives the new columns their defaults and adds no option', () async {
      final queue = await db
          .customSelect(
            'SELECT COUNT(*) AS n FROM study_queue_items'
            ' WHERE hint_shown = 0 AND meaning_slot IS NULL',
          )
          .getSingle();
      expect(queue.read<int>('n'), 29);
      final options = await db
          .customSelect('SELECT COUNT(*) AS n FROM study_guess_options')
          .getSingle();
      expect(options.read<int>('n'), 0);
    });

    test('still holds every invariant of schema.md', () async {
      for (final MapEntry(key: number, value: query)
          in invariantQueries.entries) {
        expect(
          await db.customSelect(query).get(),
          isEmpty,
          reason: 'invariant $number: ${invariantSummaries[number]}',
        );
      }
    });

    test('passes the integrity and foreign key checks', () async {
      final integrity = await db.customSelect('PRAGMA integrity_check').get();
      expect([for (final row in integrity) row.data.values.single], ['ok']);
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    });
  });
}
