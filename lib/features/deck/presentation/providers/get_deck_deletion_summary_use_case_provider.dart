import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/usecases/get_deck_deletion_summary_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_deck_deletion_summary_use_case_provider.g.dart';

@riverpod
GetDeckDeletionSummaryUseCase getDeckDeletionSummaryUseCase(Ref ref) =>
    GetDeckDeletionSummaryUseCase(ref.watch(deckRepositoryProvider));
