import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_summary_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';

/// The four steps of the tracker (kit 11, spec §8.1 ruling 4).
enum CardImportStep { source, columns, preview, importing }

/// The two sources of step 1 (UC-TRANSFER-001 step 2, A1).
enum CardImportSourceKind { file, paste }

/// What the import screen shows (kit 11): the wizard while the user works,
/// then one result.
sealed class CardImportState {
  const CardImportState();
}

/// Steps 1–4. Each step keeps what the earlier ones settled, so Back and a
/// failure never lose the user's work (UC-TRANSFER-001 E1, E4, E5).
final class CardImportDraft extends CardImportState {
  const CardImportDraft({
    this.step = CardImportStep.source,
    this.sourceKind = CardImportSourceKind.file,
    this.fileName,
    this.source,
    this.table,
    this.mapping = const ColumnMapping({}),
    this.hasHeaderRow = true,
    this.preview,
    this.isIncludingDuplicates = false,
    this.isBusy = false,
    this.problem,
  });

  final CardImportStep step;
  final CardImportSourceKind sourceKind;

  /// The picked file's name for its chip; kept in memory only
  /// (BR-TRANSFER-006).
  final String? fileName;

  /// Null until a file is picked or text is pasted.
  final TransferSource? source;

  /// The rows read at step 1; null before.
  final SourceTable? table;
  final ColumnMapping mapping;
  final bool hasHeaderRow;

  /// Null before step 3.
  final ImportPreview? preview;
  final bool isIncludingDuplicates;

  /// Reading or previewing is running.
  final bool isBusy;

  /// Why the last step was refused, shown where it happened.
  final TransferRejection? problem;

  /// What the commit bar's Import writes (UC-TRANSFER-001 step 6).
  int get willWrite =>
      preview?.willWrite(includeDuplicates: isIncludingDuplicates) ?? 0;

  CardImportDraft copyWith({
    CardImportStep? step,
    ColumnMapping? mapping,
    bool? hasHeaderRow,
    ImportPreview? preview,
    bool? isIncludingDuplicates,
    bool? isBusy,
    TransferRejection? problem,
    bool isProblemCleared = false,
  }) => CardImportDraft(
    step: step ?? this.step,
    sourceKind: sourceKind,
    fileName: fileName,
    source: source,
    table: table,
    mapping: mapping ?? this.mapping,
    hasHeaderRow: hasHeaderRow ?? this.hasHeaderRow,
    preview: preview ?? this.preview,
    isIncludingDuplicates: isIncludingDuplicates ?? this.isIncludingDuplicates,
    isBusy: isBusy ?? this.isBusy,
    problem: isProblemCleared ? null : problem ?? this.problem,
  );
}

/// The commit wrote what it could (UC-TRANSFER-001 step 8): success,
/// partial or none.
final class CardImportDone extends CardImportState {
  const CardImportDone(this.summary);

  final ImportSummary summary;
}

/// The commit wrote nothing: the deck no longer takes cards (E4), or a write
/// failed and rolled back (E5). [draft] is the preview Try again returns to.
final class CardImportFailed extends CardImportState {
  const CardImportFailed({required this.draft, required this.isTargetRejected});

  final CardImportDraft draft;
  final bool isTargetRejected;
}
