import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/usecases/search_decks_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_decks_use_case_provider.g.dart';

@riverpod
SearchDecksUseCase searchDecksUseCase(Ref ref) =>
    SearchDecksUseCase(ref.watch(deckRepositoryProvider));
