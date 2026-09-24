import 'package:memox/features/deck/domain/models/deck_search_hit_model.dart';
import 'package:memox/features/deck/presentation/providers/search_decks_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_search_provider.g.dart';

/// Every deck whose name holds [term] (ruling P2-L9: the whole library).
@riverpod
Stream<List<DeckSearchHit>> deckSearch(Ref ref, String term) =>
    ref.watch(searchDecksUseCaseProvider)(scopeDeckId: null, term: term);
