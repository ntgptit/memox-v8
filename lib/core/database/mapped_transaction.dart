import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';

/// A transaction whose unexpected error leaves as its [Failure], after the
/// rollback: the one place repositories open a write (spec
/// 2026-09-29-database-error-guard-design.md D2). It refuses to start while
/// the account's gate is shut (auth spec R3).
extension MappedTransaction on AppDatabase {
  Future<T> mappedTransaction<T>(Future<T> Function() body) =>
      guardDatabase(() {
        mutationGate.check();
        return transaction(body);
      });
}
