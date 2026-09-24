import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/usecases/move_deck_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'move_deck_use_case_provider.g.dart';

@riverpod
MoveDeckUseCase moveDeckUseCase(Ref ref) =>
    MoveDeckUseCase(ref.watch(deckRepositoryProvider));
