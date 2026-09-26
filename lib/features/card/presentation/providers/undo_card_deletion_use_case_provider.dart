import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/usecases/undo_card_deletion_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'undo_card_deletion_use_case_provider.g.dart';

@riverpod
UndoCardDeletionUseCase undoCardDeletionUseCase(Ref ref) =>
    UndoCardDeletionUseCase(ref.watch(cardRepositoryProvider));
