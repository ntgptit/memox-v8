import 'package:memox/features/study/data/datasources/study_queue_dao.dart';
import 'package:memox/features/study/data/datasources/study_view_dao.dart';
import 'package:memox/features/study/data/mappers/study_home_mapper.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';

/// The session Continue can take up, with the round it serves, read as the
/// session screen counts it (spec D3): the Study tab's Resume card and the
/// Study Entry's resume banner share it (FE-A6 D15).
final class ResumableSessionDataSource {
  const ResumableSessionDataSource(this._views, this._queue);

  final StudyViewDao _views;
  final StudyQueueDao _queue;

  /// Of [deckId] when given, of any deck otherwise.
  Future<ResumableSession?> read({
    String? deckId,
    required DateTime startOfToday,
  }) async {
    final row = await _views.resumableSessionRow(
      deckId: deckId,
      startOfToday: startOfToday,
    );
    if (row == null) return null;
    final session = row.session;
    final head = await _queue.headRow(
      session.id,
      session.currentMode,
      session.cursor,
    );
    final round = head == null
        ? null
        : await _views.roundCounts(session.id, head.mode, head.round);
    return resumableSessionOf(row, round);
  }
}
