import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/models/card_export_snapshot_model.dart';
import 'package:memox/features/card/domain/repositories/card_transfer_repository.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';
import 'package:memox/features/transfer/domain/models/tags_cell_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_file_repository.dart';

/// UC-TRANSFER-002 steps 4–5, E3–E6: the deck's cards, or [cardIds], as a
/// file of [format], named for the deck and [today] (BR-TRANSFER-013; the
/// caller reads [today] from the app's clock). Writes nothing
/// (BR-TRANSFER-011).
final class BuildExportUseCase {
  const BuildExportUseCase(this._cards, this._files);

  final CardTransferRepository _cards;
  final TransferFileRepository _files;

  Future<Outcome<ExportArtifact, TransferRejection>> call({
    required String deckId,
    required TransferFormat format,
    required DateTime today,
    Set<String>? cardIds,
  }) async {
    final snapshot = await _cards.exportSnapshot(
      deckId: deckId,
      cardIds: cardIds,
    );
    final CardExportSnapshot value;
    switch (snapshot) {
      case Ok(value: final read):
        value = read;
      case Rejected():
        return Rejected(
          cardIds == null
              ? TransferRejection.emptyScope
              : TransferRejection.staleSelection,
        );
    }
    if (value.rows.isEmpty) return const Rejected(TransferRejection.emptyScope);

    final written = await _files.write(rowsOf(value), format);
    return switch (written) {
      Ok(value: final bytes) => Ok(
        ExportArtifact(
          bytes: bytes,
          fileName: exportFileName(
            deckName: value.deckName,
            date: today,
            format: format,
          ),
          format: format,
        ),
      ),
      Rejected(:final reason) => Rejected(reason),
    };
  }
}

/// The six canonical headers, then one row per card with an empty cell for
/// an absent field (BR-TRANSFER-008, BR-TRANSFER-012).
List<List<String>> rowsOf(CardExportSnapshot snapshot) => [
  [for (final field in TransferField.values) field.header],
  for (final row in snapshot.rows)
    [
      row.front,
      row.back,
      row.example ?? '',
      row.hint ?? '',
      row.pronunciation ?? '',
      TagsCell.encode(row.tagNames),
    ],
];
