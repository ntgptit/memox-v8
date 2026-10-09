import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_import_section_model.dart';
import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_summary_model.dart';

/// UC-TRANSFER-001 steps 6–8, E3, E4: the preview's drafts written in one
/// transaction by the card feature, into the target or into the sub-decks
/// its groups name (A6), and the result with every row skipped
/// (critique 2026-10-02, F4).
/// A database failure leaves as the thrown `Failure` (E5).
final class CommitImportUseCase {
  const CommitImportUseCase(this._cards);

  final CardTransferRepository _cards;

  Future<Outcome<ImportSummary, TransferRejection>> call({
    required String deckId,
    required ImportPreview preview,
    required bool includeDuplicates,
  }) async {
    if (preview.isSectioned) {
      return _sectioned(deckId, preview, includeDuplicates: includeDuplicates);
    }
    final toWrite = preview.rowsToWrite(includeDuplicates: includeDuplicates);
    if (toWrite.isEmpty) {
      return const Rejected(TransferRejection.nothingToImport);
    }
    final result = await _cards.importCards(
      deckId: deckId,
      drafts: [for (final row in toWrite) row.draft!],
      includeDuplicates: includeDuplicates,
    );
    return switch (result) {
      Ok(:final value) => Ok(
        ImportSummary(
          written: value.written,
          blank: preview.blank,
          skipped: _skipped(
            preview,
            toWrite,
            value.skippedIndexes,
            includeDuplicates: includeDuplicates,
          ),
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

  /// UC-TRANSFER-001 A6, E9: the groups written as sub-decks in one
  /// transaction by the card feature (spec 2026-10-08 §4.5).
  Future<Outcome<ImportSummary, TransferRejection>> _sectioned(
    String deckId,
    ImportPreview preview, {
    required bool includeDuplicates,
  }) async {
    if (!preview.canCommit) {
      return const Rejected(TransferRejection.sectionChoiceMissing);
    }
    final toWrite = [
      for (final group in preview.groups)
        group.rowsToWrite(includeDuplicates: includeDuplicates),
    ];
    if (toWrite.every((rows) => rows.isEmpty)) {
      return const Rejected(TransferRejection.nothingToImport);
    }
    final result = await _cards.importSections(
      targetDeckId: deckId,
      sections: [
        for (final (index, group) in preview.groups.indexed)
          CardImportSection(
            name: group.name,
            existingDeckId: switch (group.destination) {
              IntoExistingDeck(:final deckId) => deckId,
              _ => null,
            },
            drafts: [for (final row in toWrite[index]) row.draft!],
          ),
      ],
      includeDuplicates: includeDuplicates,
    );
    return switch (result) {
      Ok(:final value) => Ok(
        _summaryOf(
          preview,
          toWrite,
          value,
          includeDuplicates: includeDuplicates,
        ),
      ),
      Rejected(reason: CardRejection.sectionTargetChanged) => const Rejected(
        TransferRejection.sectionTargetChanged,
      ),
      Rejected(reason: CardRejection.depthExceeded) => const Rejected(
        TransferRejection.depthExceeded,
      ),
      Rejected(reason: CardRejection.notFound) ||
      Rejected(
        reason: CardRejection.notADeckContainer,
      ) => const Rejected(TransferRejection.targetRejected),
      // The preview checked every draft and name, so another refusal is a
      // bug, not a user's error.
      Rejected(:final reason) => throw StateError(
        'import refused a previewed section: $reason',
      ),
    };
  }

  static ImportSummary _summaryOf(
    ImportPreview preview,
    List<List<ImportRow>> toWrite,
    List<CardImportSectionResult> written, {
    required bool includeDuplicates,
  }) => ImportSummary(
    written: written.fold(0, (sum, section) => sum + section.written),
    blank: preview.blank,
    skipped: [
      for (final (index, group) in preview.groups.indexed)
        ..._skipped(
          ImportPreview(group.rows),
          toWrite[index],
          written[index].skippedIndexes,
          includeDuplicates: includeDuplicates,
        ),
    ],
    decks: [
      for (final (index, group) in preview.groups.indexed)
        if (written[index].written > 0)
          ImportDeckResult(
            name: group.destination is IntoExistingDeck
                ? group.clash!.name
                : group.name,
            isNew: group.destination is! IntoExistingDeck,
            written: written[index].written,
          ),
    ],
  );

  /// What the preview left out, and what the commit's re-check dropped as
  /// already in the deck, in source order (critique 2026-10-02, F4).
  static List<ImportRow> _skipped(
    ImportPreview preview,
    List<ImportRow> toWrite,
    List<int> dropped, {
    required bool includeDuplicates,
  }) {
    final droppedRows = {for (final index in dropped) toWrite[index].rowNumber};
    return [
      for (final row in preview.rows)
        if (row.kind == ImportRowKind.invalid ||
            (!includeDuplicates && row.isDuplicate))
          row
        else if (droppedRows.contains(row.rowNumber))
          ImportRow(
            rowNumber: row.rowNumber,
            kind: ImportRowKind.duplicateInDeck,
            draft: row.draft,
          ),
    ];
  }
}
