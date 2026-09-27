import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/usecases/undo_deck_deletion_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'undo_deck_deletion_use_case_provider.g.dart';

@riverpod
UndoDeckDeletionUseCase undoDeckDeletionUseCase(Ref ref) =>
    UndoDeckDeletionUseCase(ref.watch(deckRepositoryProvider));
