import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';

/// UC-TOPIK-001: the tests with the person's status on each, again on every
/// attempt write (BR-TOPIK-022).
final class WatchTopikCatalogUseCase {
  const WatchTopikCatalogUseCase(this._content, this._attempts);

  final TopikContentRepository _content;
  final TopikAttemptRepository _attempts;

  Stream<List<TopikCatalogEntry>> call() =>
      Stream.fromFuture(_content.catalog()).asyncExpand(
        (tests) => _attempts.watchTestStatuses().map(
          (statuses) => topikCatalogEntriesOf(tests, statuses),
        ),
      );
}
