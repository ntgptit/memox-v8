import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/presentation/providers/watch_deck_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_view_provider.g.dart';

/// An open deck with its breadcrumb and Create options, again on every
/// change; `Rejected(notFound)` once it is deleted.
@riverpod
Stream<Outcome<DeckView, DeckRejection>> deckView(Ref ref, String deckId) =>
    ref.watch(watchDeckUseCaseProvider)(deckId: deckId);
