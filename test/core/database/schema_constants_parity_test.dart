import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study_mode/domain/models/guess_mode.dart';
import 'package:memox/features/study_mode/domain/models/match_mode.dart';
import 'package:memox/features/study_mode/domain/models/recall_mode.dart';
import 'package:memox/features/study_mode/domain/models/self_assess_mode.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../support/test_database.dart';

// DEV-222 (BR-REV-011): the domain constants the schema's CHECKs copy by
// hand. Each pair is read from the SQL the app ships (sqlite_master of the
// current schema; the Supabase migration files as text) and compared with
// the Dart constant, so a change on one side fails here instead of in a
// CHECK at the end of a session or at the server.
void main() {
  late AppDatabase db;
  late Map<String, String> tableSql;

  setUpAll(() async {
    db = openTestDatabase();
    final rows = await db
        .customSelect(
          "SELECT name, sql FROM sqlite_master WHERE type = 'table'",
        )
        .get();
    tableSql = {
      for (final row in rows) row.read<String>('name'): row.read<String>('sql'),
    };
  });
  tearDownAll(() => db.close());

  /// The one integer the [pattern]'s group captures in [sql].
  int literalOf(String sql, String pattern) {
    final matches = RegExp(pattern, caseSensitive: false).allMatches(sql);
    expect(matches, hasLength(1), reason: 'one `$pattern` in the SQL');
    return int.parse(matches.single.group(1)!);
  }

  /// The quoted codes of the `IN (...)` list the [pattern]'s group captures.
  Set<String> codesOf(String sql, String pattern) {
    final matches = RegExp(pattern).allMatches(sql);
    expect(matches, hasLength(1), reason: 'one `$pattern` in the SQL');
    return {
      for (final code in RegExp(
        "'([a-z_]+)'",
      ).allMatches(matches.single.group(1)!))
        code.group(1)!,
    };
  }

  group('Drift CHECKs', () {
    test('deck.depth is capped at DeckEntity.maxDepth (BR-DECK-001)', () {
      expect(
        literalOf(tableSql['deck']!, r'depth BETWEEN 1 AND (\d+)'),
        DeckEntity.maxDepth,
      );
    });

    test('a self_assess row answers at most selfAssessTurnCap times '
        '(BR-STUDY-073, invariant 17)', () {
      expect(
        literalOf(
          tableSql['study_queue_items']!,
          r"mode <> 'self_assess' OR answers_in_session <= (\d+)",
        ),
        selfAssessTurnCap,
      );
    });

    test('a match board has matchBoardSize slots (BR-STUDY-049)', () {
      expect(
        literalOf(
          tableSql['study_queue_items']!,
          r'meaning_slot BETWEEN 0 AND (\d+)',
        ),
        matchBoardSize - 1,
      );
    });

    test('a guess question has guessOptionCount options (BR-MODE-012)', () {
      expect(
        literalOf(
          tableSql['study_guess_options']!,
          r'slot BETWEEN 0 AND (\d+)',
        ),
        guessOptionCount - 1,
      );
    });

    test('a recall turn holds at most recallTurnMs (BR-STUDY-031)', () {
      expect(
        literalOf(
          tableSql['study_queue_items']!,
          r'remaining_ms BETWEEN 0 AND (\d+)',
        ),
        recallTurnMs,
      );
    });

    test('study_session stores every SessionStatus, SessionEndReason and '
        'StudyMode code and no other', () {
      final sql = tableSql['study_session']!;
      expect(
        codesOf(sql, r'"status" TEXT NOT NULL CHECK \(status IN \(([^)]*)\)'),
        {for (final status in SessionStatus.values) status.code},
      );
      expect(
        codesOf(sql, r'"end_reason" TEXT CHECK \(end_reason IN \(([^)]*)\)'),
        {for (final reason in SessionEndReason.values) reason.code},
      );
      expect(
        codesOf(
          sql,
          r'"current_mode" TEXT NOT NULL CHECK \(current_mode IN \(([^)]*)\)',
        ),
        {for (final mode in StudyMode.values) mode.code},
      );
    });
  });

  test('the srs feature invalidates sessions with the end reasons the study '
      'feature names (BR-SRS-013)', () {
    // srs may not import study (ADR-011), so it holds the two codes itself.
    expect(schedulerResetEndReason, SessionEndReason.schedulerReset.code);
    expect(schedulerChangedEndReason, SessionEndReason.schedulerChanged.code);
  });

  group('Supabase migrations', () {
    String migration(String name) =>
        File('supabase/migrations/$name').readAsStringSync();

    test('deck.depth is capped at DeckEntity.maxDepth, in the CHECK and in '
        'deck_push (BR-DECK-001)', () {
      final deckSync = migration('20260928000000_deck_sync.sql');
      expect(
        literalOf(deckSync, r'depth between 1 and (\d+)'),
        DeckEntity.maxDepth,
      );
      // deck_push is created in deck_sync and re-created by the trash rules.
      for (final sql in [
        deckSync,
        migration('20261011000000_trash_purge_rules.sql'),
      ]) {
        expect(
          literalOf(sql, r'v_depth \+ v_height > (\d+)'),
          DeckEntity.maxDepth,
        );
      }
    });
  });
}
