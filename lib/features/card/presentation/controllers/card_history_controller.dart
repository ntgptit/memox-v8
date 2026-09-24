import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/presentation/providers/load_card_history_page_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_history_controller.g.dart';

/// A card's review history as its detail shows it (UC-CARD-002): the newest
/// page, then older pages on request.
final class CardHistoryView {
  const CardHistoryView({
    required this.entries,
    required this.next,
    this.isLoadingMore = false,
    this.hasMoreFailed = false,
  });

  /// Newest first (BR-CARD-015).
  final List<ReviewHistoryEntry> entries;

  /// Null once the oldest answer is shown (A5).
  final ReviewHistoryCursor? next;
  final bool isLoadingMore;

  /// The last older page failed; what is shown stays (E4).
  final bool hasMoreFailed;

  CardHistoryView copyWith({bool? isLoadingMore, bool? hasMoreFailed}) =>
      CardHistoryView(
        entries: entries,
        next: next,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMoreFailed: hasMoreFailed ?? this.hasMoreFailed,
      );
}

/// Read once per visit (ruling P4b-L2): only studying adds answers, and
/// nothing on the detail studies.
@riverpod
class CardHistoryController extends _$CardHistoryController {
  @override
  Future<CardHistoryView> build(String cardId) async {
    final page = await _page(null);
    return CardHistoryView(
      entries: page?.entries ?? const [],
      next: page?.next,
    );
  }

  /// Null once the card is gone; the detail's own stream says so.
  Future<ReviewHistoryPage?> _page(ReviewHistoryCursor? cursor) async =>
      switch (await ref.read(loadCardHistoryPageUseCaseProvider)(
        cardId: cardId,
        cursor: cursor,
      )) {
        Ok(:final value) => value,
        Rejected() => null,
      };

  /// The page after the last answer shown (UC-CARD-002 step 6). A failure
  /// keeps the rows and a retry resumes at the same cursor (E4); an answer
  /// that arrives late or twice is dropped (E5).
  Future<void> loadMore() async {
    final view = state.value;
    final cursor = view?.next;
    if (view == null || cursor == null || view.isLoadingMore) return;
    state = AsyncData(view.copyWith(isLoadingMore: true, hasMoreFailed: false));
    try {
      final page = await _page(cursor);
      if (!ref.mounted) return;
      final current = state.value;
      if (current == null || !identical(current.next, cursor)) return;
      state = AsyncData(
        CardHistoryView(
          entries: [...current.entries, ...?page?.entries],
          next: page?.next,
        ),
      );
    } on Failure {
      if (!ref.mounted) return;
      final current = state.value;
      if (current == null) return;
      state = AsyncData(
        current.copyWith(isLoadingMore: false, hasMoreFailed: true),
      );
    }
  }
}
