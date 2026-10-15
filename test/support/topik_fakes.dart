import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';

/// A catalog of the given tests; a test can change it between reads.
final class FakeTopikContentRepository implements TopikContentRepository {
  FakeTopikContentRepository(this.tests);

  List<TopikTest> tests;

  @override
  Future<List<TopikTest>> catalog() async => tests;
}
