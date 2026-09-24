import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/usecases/reorder_deck_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reorder_deck_use_case_provider.g.dart';

@riverpod
ReorderDeckUseCase reorderDeckUseCase(Ref ref) =>
    ReorderDeckUseCase(ref.watch(deckRepositoryProvider));
