import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/features/topik/data/mappers/topik_content_pack_mapper.dart';
import 'package:memox/features/topik/domain/models/topik_content_issue_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';

/// Reads the packs once and keeps the result (spec §13.4): the content never
/// changes while the app runs. A failed read is forgotten, so Retry reads
/// again.
final class TopikContentRepositoryImpl implements TopikContentRepository {
  TopikContentRepositoryImpl({required this._load});

  final Future<TopikContentLoad> Function() _load;
  Future<List<TopikTest>>? _catalog;

  @override
  Future<List<TopikTest>> catalog() => _catalog ??= _read();

  Future<List<TopikTest>> _read() async {
    try {
      final load = await _load();
      _logRejections(load.issues);
      return load.accepted;
    } on Object {
      // Not swallowed: forget the failed read so Retry reads again.
      _catalog = null;
      rethrow;
    }
  }

  /// One log per rejected pack, with the first error that rejected it.
  void _logRejections(List<TopikContentIssue> issues) {
    final logged = <String>{};
    for (final issue in issues) {
      if (!issue.isError || !logged.add(issue.testId)) continue;
      appLogger.warning(
        'topik.content_rejected',
        category: LogCategory.state,
        context: {
          'testId': issue.testId,
          'rule': issue.rule.name,
          'detail': issue.detail,
        },
      );
    }
  }
}
