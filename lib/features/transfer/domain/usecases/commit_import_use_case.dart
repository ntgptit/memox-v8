import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_summary_model.dart';

/// UC-TRANSFER-001 steps 6–8, E3, E4: the preview's drafts written in one
/// transaction by the card feature, and the counts for the result screen.
/// A database failure leaves as the thrown `Failure` (E5).
final class CommitImportUseCase {
  const CommitImportUseCase(this._cards);

  final CardTransferRepository _cards;

  Future<Outcome<ImportSummary, TransferRejection>> call({
    required String deckId,
    required ImportPreview preview,
    required bool includeDuplicates,
  }) async {
    final drafts = preview.draftsToWrite(includeDuplicates: includeDuplicates);
    if (drafts.isEmpty) {
      return const Rejected(TransferRejection.nothingToImport);
    }
    final result = await _cards.importCards(
      deckId: deckId,
      drafts: drafts,
      includeDuplicates: includeDuplicates,
    );
    return switch (result) {
      Ok(:final value) => Ok(
        ImportSummary(
          written: value.written,
          duplicatesSkipped:
              value.skippedDuplicates +
              (includeDuplicates ? 0 : preview.duplicates),
          invalid: preview.invalid,
          blank: preview.blank,
        ),
      ),
      Rejected(reason: CardRejection.notFound) ||
      Rejected(
        reason: CardRejection.notACardContainer,
      ) => const Rejected(TransferRejection.targetRejected),
      // The preview checked every draft with the same rules, so another
      // refusal is a bug, not a user's error.
      Rejected(:final reason) => throw StateError(
        'import refused a previewed draft: $reason',
      ),
    };
  }
}
