import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/trash/domain/usecases/restore_decks_from_trash_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'restore_decks_from_trash_use_case_provider.g.dart';

@riverpod
RestoreDecksFromTrashUseCase restoreDecksFromTrashUseCase(Ref ref) =>
    RestoreDecksFromTrashUseCase(ref.watch(deckRepositoryProvider));
