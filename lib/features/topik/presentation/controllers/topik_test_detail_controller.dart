import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/presentation/providers/delete_topik_attempt_use_case_provider.dart';
import 'package:memox/features/topik/presentation/providers/start_topik_attempt_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_test_detail_controller.g.dart';

/// Screen 36's commands, each through its use case (UC-TOPIK-002,
/// UC-TOPIK-003 step 1). The state is whether one runs: a second tap while
/// it does is ignored (Review Focus 3). A database `Failure` is thrown
/// through; the widget says so.
@riverpod
class TopikTestDetailController extends _$TopikTestDetailController {
  @override
  bool build(String testId) => false;

  /// Null when a command already runs.
  Future<Outcome<TopikAttempt, TopikRejection>?> start({
    required bool replaceInProgress,
  }) => _run(
    () => ref.read(startTopikAttemptUseCaseProvider)(
      testId,
      replaceInProgress: replaceInProgress,
    ),
  );

  /// Null when a command already runs.
  Future<Outcome<void, TopikRejection>?> delete(String attemptId) =>
      _run(() => ref.read(deleteTopikAttemptUseCaseProvider)(attemptId));

  Future<T?> _run<T>(Future<T> Function() command) async {
    if (state) return null;
    state = true;
    try {
      return await command();
    } finally {
      if (ref.mounted) state = false;
    }
  }
}
