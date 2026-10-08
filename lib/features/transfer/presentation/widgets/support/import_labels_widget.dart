import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// Whether a preview was refused because the target cannot take the decks
/// the file names (UC-TRANSFER-001 E7, E8).
bool isImportTargetProblem(TransferRejection? problem) =>
    problem == TransferRejection.sectionsNeedDeckContainer ||
    problem == TransferRejection.depthExceeded;

/// The import screen's copy for its domain values (kit 11).
extension ImportLabels on AppLocalizations {
  String importStepName(CardImportStep step) => switch (step) {
    CardImportStep.source => importStepSource,
    CardImportStep.columns => importStepColumns,
    CardImportStep.preview => importStepPreview,
    CardImportStep.importing => importStepImport,
  };

  String importField(TransferField? field) => switch (field) {
    null => importFieldNone,
    TransferField.front => importFieldFront,
    TransferField.back => importFieldBack,
    TransferField.example => importFieldExample,
    TransferField.hint => importFieldHint,
    TransferField.pronunciation => importFieldPronunciation,
    TransferField.tags => importFieldTags,
  };

  /// Why a row will not be written, or null for a ready row.
  String? importRowNote(ImportRow row) => switch (row.kind) {
    ImportRowKind.ready => null,
    ImportRowKind.blank => importRowBlank,
    ImportRowKind.duplicateInDeck => importRowDuplicateInDeck,
    ImportRowKind.duplicateInSource => importRowDuplicateInSource(
      row.firstRowNumber!,
    ),
    ImportRowKind.invalid => switch (row.deckNameReason) {
      null => _invalid(row),
      DeckRejection.blankName => importRowDeckNameBlank,
      _ => importRowDeckNameTooLong,
    },
  };

  /// The error under the default deck's name field (spec 2026-10-08 U4).
  String importNameProblem(ImportNameProblem problem) => switch (problem) {
    ImportNameProblem.blank => deckRejectionBlankName,
    ImportNameProblem.tooLong => deckRejectionNameTooLong,
    ImportNameProblem.takenInFile => importDeckNameTaken,
  };

  String _invalid(ImportRow row) => switch (row.reason) {
    CardRejection.blankContent when row.draft!.front.trim().isEmpty =>
      importRowFrontEmpty,
    CardRejection.blankContent => importRowBackEmpty,
    CardRejection.frontTooLong => importRowFrontTooLong,
    CardRejection.backTooLong => importRowBackTooLong,
    CardRejection.optionalFieldTooLong => importRowOptionalTooLong,
    CardRejection.invalidTagName => importRowInvalidTag,
    CardRejection.tooManyTags => importRowTooManyTags,
    _ => importRowOptionalTooLong,
  };

  /// A refusal of step 1 or 2, as a title and what to do.
  ({String title, String body}) importProblem(TransferRejection reason) =>
      switch (reason) {
        TransferRejection.badEncoding => (
          title: importProblemEncodingTitle,
          body: importProblemEncodingBody,
        ),
        TransferRejection.emptySource => (
          title: importProblemEmptyTitle,
          body: importProblemEmptyBody,
        ),
        TransferRejection.sectionsNeedDeckContainer => (
          title: importProblemSectionsTitle,
          body: importProblemSectionsBody,
        ),
        TransferRejection.depthExceeded => (
          title: importProblemDepthTitle,
          body: importProblemDepthBody,
        ),
        TransferRejection.sectionTargetChanged => (
          title: importProblemChangedTitle,
          body: importProblemChangedBody,
        ),
        _ => (
          title: importProblemUnreadableTitle,
          body: importProblemUnreadableBody,
        ),
      };
}
