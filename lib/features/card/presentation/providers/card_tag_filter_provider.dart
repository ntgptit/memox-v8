import 'package:memox/features/card/presentation/providers/watch_card_tag_filter_use_case_provider.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_tag_filter_provider.g.dart';

/// The tags the card list of [deckId] can filter by, each with its cards
/// in the deck, 0 included (UC-TAG-001 step 6; BE-B2 D3).
@riverpod
Stream<List<TagCount>> cardTagFilter(Ref ref, String deckId) =>
    ref.watch(watchCardTagFilterUseCaseProvider)(deckId: deckId);
