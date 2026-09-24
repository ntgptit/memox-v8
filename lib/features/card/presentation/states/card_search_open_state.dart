import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_search_open_state.g.dart';

/// Whether a deck's in-deck search field shows (screen 07): the app bar's
/// search action opens it; closing it clears the term (spec §4.4).
@riverpod
class CardSearchOpen extends _$CardSearchOpen {
  @override
  bool build(String deckId) => false;

  void open() => state = true;

  void close() {
    state = false;
    ref.read(cardListRequestProvider(deckId).notifier).search('');
  }
}
