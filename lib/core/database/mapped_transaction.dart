import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';

/// A transaction whose unexpected error leaves as its [Failure], after the
/// rollback: the one place repositories open a write (spec
/// 2026-09-29-database-error-guard-design.md D2).
extension MappedTransaction on AppDatabase {
  Future<T> mappedTransaction<T>(Future<T> Function() body) =>
      guardDatabase(() => transaction(body));
}
