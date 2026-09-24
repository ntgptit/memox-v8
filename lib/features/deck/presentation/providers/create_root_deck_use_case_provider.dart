import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/usecases/create_root_deck_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_root_deck_use_case_provider.g.dart';

@riverpod
CreateRootDeckUseCase createRootDeckUseCase(Ref ref) =>
    CreateRootDeckUseCase(ref.watch(deckRepositoryProvider));
