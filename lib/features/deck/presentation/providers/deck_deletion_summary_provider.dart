import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/presentation/providers/get_deck_deletion_summary_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_deletion_summary_provider.g.dart';

/// What deleting [deckId] would take with it (BR-DECK-023).
@riverpod
Future<Outcome<DeckDeletionSummary, DeckRejection>> deckDeletionSummary(
  Ref ref,
  String deckId,
) => ref.watch(getDeckDeletionSummaryUseCaseProvider)(deckId: deckId);
