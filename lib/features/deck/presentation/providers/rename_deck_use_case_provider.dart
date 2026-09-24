import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/usecases/rename_deck_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rename_deck_use_case_provider.g.dart';

@riverpod
RenameDeckUseCase renameDeckUseCase(Ref ref) =>
    RenameDeckUseCase(ref.watch(deckRepositoryProvider));
