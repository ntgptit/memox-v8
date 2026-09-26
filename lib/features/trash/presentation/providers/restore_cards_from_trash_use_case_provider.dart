import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/trash/domain/usecases/restore_cards_from_trash_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'restore_cards_from_trash_use_case_provider.g.dart';

@riverpod
RestoreCardsFromTrashUseCase restoreCardsFromTrashUseCase(Ref ref) =>
    RestoreCardsFromTrashUseCase(ref.watch(cardRepositoryProvider));
