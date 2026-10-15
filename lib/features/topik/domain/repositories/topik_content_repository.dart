import 'package:memox/features/topik/domain/models/topik_test_model.dart';

/// The TOPIK tests the app can offer (BR-TOPIK-008): every bundled test that
/// passes the content check, the first of each id.
abstract interface class TopikContentRepository {
  /// The valid tests, in manifest order. Read once per app run.
  Future<List<TopikTest>> catalog();
}
