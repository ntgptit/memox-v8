import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/presentation/providers/get_reset_learning_summary_use_case_provider.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reset_learning_summary_provider.g.dart';

/// What resetting [rootDeckId]'s tree would clear, for the reset dialog
/// (UC-SRS-001 step 2).
@riverpod
Future<Outcome<ResetLearningSummary, SrsRejection>> resetLearningSummary(
  Ref ref,
  String rootDeckId,
) => ref.watch(getResetLearningSummaryUseCaseProvider)(rootDeckId: rootDeckId);
