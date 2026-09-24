import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/usecases/delete_deck_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_deck_use_case_provider.g.dart';

@riverpod
DeleteDeckUseCase deleteDeckUseCase(Ref ref) =>
    DeleteDeckUseCase(ref.watch(deckRepositoryProvider));
