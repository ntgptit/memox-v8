import 'dart:math';

import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/study/data/datasources/study_queue_dao.dart';
import 'package:memox/features/study/data/datasources/study_round_dao.dart';
import 'package:memox/features/study/domain/models/queue_plan_model.dart';
import 'package:memox/features/study_mode/domain/models/round_preparation_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// Builds and prepares the rounds of a session, inside the caller's
/// transaction (graded modes spec §8.2). A later round is numbered unlike the
/// round before it (BR-STUDY-061); every round then gets what its mode says
/// it lacks before it is served: the meaning slots of `match` boards, the
/// questions of `guess` (spec §7.7). Both writers of a session share it.
final class StudyRoundDataSource {
  StudyRoundDataSource(AppDatabase db, this._random)
    : _queue = StudyQueueDao(db),
      _rounds = StudyRoundDao(db);

  final StudyQueueDao _queue;
  final StudyRoundDao _rounds;

  /// The shuffles of round orders, board slots and options.
  final Random _random;

  /// Numbers [round] of [mode] unlike the round before it, then prepares it.
  Future<void> build(
    String sessionId,
    String rootId,
    StudyMode mode,
    int round,
  ) async {
    final previous = await _queue.cardsOf(sessionId, mode.code, round - 1);
    final cards = await _queue.cardsOf(sessionId, mode.code, round);
    await _queue.build(
      sessionId,
      mode.code,
      round,
      shuffledUnlike(cards, previous, _random),
    );
    await prepare(sessionId, rootId, mode, round);
  }

  /// Writes what [round] of [mode] lacks, and only that (spec D8): a board
  /// with its slots and a question with its five options stay as they are.
  Future<void> prepare(
    String sessionId,
    String rootId,
    StudyMode mode,
    int round,
  ) async {
    final handler = mode.handler;
    final rows = await _rounds.builtRows(sessionId, mode.code, round);
    final preparation = handler.prepareRound(
      [
        for (final row in rows)
          RoundRowFacts(
            cardId: row.cardId,
            position: row.position,
            isPending: row.isPending,
            meaningSlot: row.meaningSlot,
            optionCount: row.optionCount,
            meaningFolded: row.backFolded,
          ),
      ],
      meaningSource: handler.asksWithOptions
          ? await _rounds.meaningSource(sessionId, rootId)
          : const [],
      random: _random,
    );
    await _rounds.setMeaningSlots(
      sessionId,
      mode.code,
      round,
      preparation.meaningSlots,
    );
    for (final MapEntry(key: cardId, value: options)
        in preparation.questions.entries) {
      await _rounds.replaceOptions(sessionId, round, cardId, options);
    }
  }
}
