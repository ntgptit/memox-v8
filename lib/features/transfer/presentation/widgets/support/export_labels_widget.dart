import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/presentation/states/card_export_state.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The export sheet's copy for its domain values (kit 12).
extension ExportLabels on AppLocalizations {
  /// A format's name and what it is for (UC-TRANSFER-002 step 2).
  (String, String) exportFormat(TransferFormat format) => switch (format) {
    TransferFormat.csv => (exportFormatCsv, exportFormatCsvBody),
    TransferFormat.tsv => (exportFormatTsv, exportFormatTsvBody),
    TransferFormat.xlsx => (exportFormatXlsx, exportFormatXlsxBody),
  };

  /// A problem's banner: what happened and what to do (E1–E6).
  ({String title, String body}) exportProblem(CardExportProblem problem) =>
      switch (problem) {
        CardExportProblem.prepareFailed => (
          title: exportFailedTitle,
          body: exportFailedBody,
        ),
        CardExportProblem.shareFailed => (
          title: exportShareFailedTitle,
          body: exportShareFailedBody,
        ),
        CardExportProblem.noShareTarget => (
          title: exportNoTargetTitle,
          body: exportNoTargetBody,
        ),
        CardExportProblem.staleSelection => (
          title: exportStaleTitle,
          body: exportStaleBody,
        ),
        CardExportProblem.nothingToExport => (
          title: exportEmptyTitle,
          body: exportEmptyBody,
        ),
      };
}
