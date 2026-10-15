import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';

/// A catalog of the given tests; a test can change it between reads, or
/// make the next reads throw [failure].
final class FakeTopikContentRepository implements TopikContentRepository {
  FakeTopikContentRepository(this.tests);

  List<TopikTest> tests;
  Object? failure;

  @override
  Future<List<TopikTest>> catalog() async {
    final failure = this.failure;
    if (failure != null) throw failure;
    return tests;
  }
}
