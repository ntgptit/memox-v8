import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

part 'topik_attempt_sync_dao.g.dart';

/// Syncs submitted TOPIK attempts, each with all its answers (TOPIK spec
/// §7.2, §13.2, BR-TOPIK-026). The server keeps them insert-only with a final
/// tombstone, so a pulled attempt is written once and only its version is
/// recorded after that; one in progress never leaves the device.
@DriftAccessor(
  include: {
    'package:memox/core/database/queries/sync_topik_attempt_queries.drift',
  },
)
class TopikAttemptSyncDao extends DatabaseAccessor<AppDatabase>
    with _$TopikAttemptSyncDaoMixin, EntitySyncAdapter {
  TopikAttemptSyncDao(super.attachedDatabase);

  static const type = 'topik_attempt';

  @override
  String get entityType => type;

  @override
  Future<Map<String, Object?>?> readRow(String id) async {
    final a = await syncTopikAttemptRow(id).getSingleOrNull();
    if (a == null) return null;
    return {
      'id': a.id,
      'testId': a.testId,
      'level': a.level,
      'section': a.section,
      'round': a.round,
      'mode': a.mode,
      'status': a.status,
      'startedAt': _time(a.startedAt),
      'completedAt': _time(a.completedAt),
      'updatedAt': _time(a.updatedAt),
      'totalTimeMs': a.totalTimeMs,
      'currentQuestionNo': a.currentQuestionNo,
      'questionCount': a.questionCount,
      'maxScore': a.maxScore,
      'score': a.score,
      'correctCount': a.correctCount,
      'answeredCount': a.answeredCount,
      'contentVersion': a.contentVersion,
      'answers': [
        for (final x in await syncTopikAttemptAnswers(id).get())
          {
            'questionNo': x.questionNo,
            'selectedIdx': x.selectedIdx,
            'timeSpentMs': x.timeSpentMs,
            'answeredAt': _time(x.answeredAt),
            'correctIdx': x.correctIdx,
            'points': x.points,
            'pointsEarned': x.pointsEarned,
            'questionType': x.questionType,
          },
      ],
    };
  }

  @override
  Future<void> upsertFromServer(
    Map<String, Object?> row,
    int serverVersion,
  ) async {
    final id = row['id'] as String;
    if (await syncTopikAttemptExists(id).getSingle()) {
      await acknowledgeTopikAttempt(serverVersion, id);
      return;
    }
    final answers = row['answers'];
    if (!_isKnown(row) || answers is! List) {
      appLogger.warning(
        'topik.sync_skipped',
        category: LogCategory.sync,
        context: {'id': id, 'mode': row['mode'], 'status': row['status']},
      );
      return;
    }
    await insertSyncedTopikAttempt(
      TopikAttemptCompanion.insert(
        id: id,
        testId: row['testId'] as String,
        level: row['level'] as String,
        section: row['section'] as String,
        round: row['round'] as int,
        mode: row['mode'] as String,
        status: row['status'] as String,
        startedAt: fromWireTime(row['startedAt'])!,
        completedAt: Value(fromWireTime(row['completedAt'])),
        updatedAt: fromWireTime(row['updatedAt'])!,
        totalTimeMs: Value(row['totalTimeMs'] as int),
        currentQuestionNo: row['currentQuestionNo'] as int,
        questionCount: row['questionCount'] as int,
        maxScore: row['maxScore'] as int,
        score: Value(row['score'] as int?),
        correctCount: Value(row['correctCount'] as int?),
        answeredCount: Value(row['answeredCount'] as int?),
        contentVersion: row['contentVersion'] as int,
        serverVersion: Value(serverVersion),
      ),
    );
    for (final answer in answers.cast<Map<String, Object?>>()) {
      await insertSyncedTopikAnswer(
        TopikAttemptAnswerCompanion.insert(
          attemptId: id,
          questionNo: answer['questionNo'] as int,
          selectedIdx: Value(answer['selectedIdx'] as int?),
          timeSpentMs: Value(answer['timeSpentMs'] as int),
          answeredAt: Value(fromWireTime(answer['answeredAt'])),
          correctIdx: Value(answer['correctIdx'] as int?),
          points: Value(answer['points'] as int?),
          pointsEarned: Value(answer['pointsEarned'] as int?),
          questionType: Value(answer['questionType'] as String?),
        ),
      );
    }
  }

  @override
  Future<void> deleteFromServer(String id) => deleteSyncedTopikAttempt(id);

  @override
  Future<void> markAcknowledged(String id, int serverVersion) =>
      acknowledgeTopikAttempt(serverVersion, id);

  /// Whether every code of [row] is one this build stores; a newer build's
  /// attempt (Exam mode, a new section) is skipped, not a failed pull.
  static bool _isKnown(Map<String, Object?> row) =>
      TopikLevel.ofCode(row['level']) != null &&
      TopikSection.ofCode(row['section']) != null &&
      TopikAttemptMode.values.any((m) => m.code == row['mode']) &&
      row['status'] == TopikAttemptStatus.completed.code;

  /// Drift stores whole seconds; the wire drops the fraction so a round trip
  /// is exact.
  static String? _time(DateTime? value) =>
      toWireTime(value)?.replaceFirst(RegExp(r'\.\d+Z$'), 'Z');
}
