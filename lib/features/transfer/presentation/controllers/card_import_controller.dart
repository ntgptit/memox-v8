import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';
import 'package:memox/features/transfer/presentation/providers/commit_import_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/providers/preview_import_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/providers/read_import_source_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_import_controller.g.dart';

/// The import wizard of one deck (UC-TRANSFER-001, kit 11). Every step goes
/// through one use case; nothing is written before [commit].
@riverpod
class CardImportController extends _$CardImportController {
  @override
  CardImportState build(String deckId) => const CardImportDraft();

  CardImportDraft? get _draft => switch (state) {
    final CardImportDraft draft => draft,
    _ => null,
  };

  /// Step 1: a file from the system picker. A cancelled picker keeps the
  /// source chosen before (A5); a name that is not CSV, TSV or XLSX is
  /// refused at once (E1).
  Future<void> chooseFile() async {
    final draft = _draft;
    if (draft == null || draft.isBusy) return;
    final ImportPickedFile? picked;
    try {
      picked = await ref.read(importFilePickerProvider)();
    } on Object {
      // The platform's message may carry a path: only the reason shows.
      if (!ref.mounted) return;
      state = draft.copyWith(problem: TransferRejection.unreadableFile);
      return;
    }
    if (!ref.mounted || picked == null) return;
    final format = TransferFormat.ofFileName(picked.name);
    if (format == null) {
      state = CardImportDraft(
        fileName: picked.name,
        problem: TransferRejection.unreadableFile,
      );
      return;
    }
    state = CardImportDraft(
      fileName: picked.name,
      source: FileSource(bytes: picked.bytes, format: format),
    );
  }

  /// Step 1: switches the source between a file and pasted text.
  void chooseSourceKind(CardImportSourceKind kind) {
    final draft = _draft;
    if (draft == null || draft.isBusy || draft.sourceKind == kind) return;
    state = CardImportDraft(sourceKind: kind);
  }

  /// Step 1 (A1): the pasted text as it is typed; blank text is no source.
  void pasteText(String text) {
    final draft = _draft;
    if (draft == null || draft.isBusy) return;
    state = CardImportDraft(
      sourceKind: CardImportSourceKind.paste,
      source: text.trim().isEmpty ? null : PastedSource(text),
    );
  }

  /// Removes the chosen file or text: back to an empty step 1.
  void clearSource() {
    final draft = _draft;
    if (draft == null || draft.isBusy) return;
    state = CardImportDraft(sourceKind: draft.sourceKind);
  }

  /// Step 1 → 2 ("Read and map columns"), or another sheet of the same
  /// workbook (A2): the rows are read again and mapped from their header.
  Future<void> readSource({int? sheetIndex}) async {
    final draft = _draft;
    final source = draft?.source;
    if (draft == null || source == null || draft.isBusy) return;
    state = draft.copyWith(isBusy: true, isProblemCleared: true);
    final result = await ref.read(readImportSourceUseCaseProvider)(
      source,
      sheetIndex: sheetIndex,
    );
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => CardImportDraft(
        step: CardImportStep.columns,
        sourceKind: draft.sourceKind,
        fileName: draft.fileName,
        source: source,
        table: value,
        mapping: ColumnMapping.fromHeader(
          value.rows.isEmpty ? const [] : value.rows.first,
        ),
      ),
      Rejected(:final reason) => draft.copyWith(isBusy: false, problem: reason),
    };
  }

  /// Step 2 (A3): whether the first row names the columns. The mapping the
  /// user made stays.
  void setHasHeaderRow({required bool hasHeaderRow}) {
    final draft = _draft;
    if (draft == null || draft.step != CardImportStep.columns) return;
    state = draft.copyWith(hasHeaderRow: hasHeaderRow, isProblemCleared: true);
  }

  /// Step 2: [column] feeds [field], or nothing when it is null
  /// (BR-TRANSFER-002).
  void assignColumn(int column, TransferField? field) {
    final draft = _draft;
    if (draft == null || draft.step != CardImportStep.columns) return;
    state = draft.copyWith(
      mapping: draft.mapping.assign(column, field),
      isProblemCleared: true,
    );
  }

  /// Step 2 → 3 ("Preview rows"): every row's status against the deck as it
  /// is now.
  Future<void> previewRows() async {
    final draft = _draft;
    final table = draft?.table;
    if (draft == null || table == null || draft.isBusy) return;
    state = draft.copyWith(isBusy: true, isProblemCleared: true);
    final result = await ref.read(previewImportUseCaseProvider)(
      deckId: deckId,
      table: table,
      mapping: draft.mapping,
      hasHeaderRow: draft.hasHeaderRow,
    );
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => draft.copyWith(
        step: CardImportStep.preview,
        preview: value,
        isBusy: false,
      ),
      Rejected(:final reason) => draft.copyWith(isBusy: false, problem: reason),
    };
  }

  /// Step 3 (A4): write the duplicates as new cards too.
  void setIncludingDuplicates({required bool isIncluding}) {
    final draft = _draft;
    if (draft == null || draft.step != CardImportStep.preview) return;
    state = draft.copyWith(isIncludingDuplicates: isIncluding);
  }

  /// Step 3 → 4 → a result (UC-TRANSFER-001 steps 6–8, E3–E5).
  Future<void> commit() async {
    final draft = _draft;
    final preview = draft?.preview;
    if (draft == null || preview == null || draft.isBusy) return;
    if (draft.willWrite == 0) return;
    state = draft.copyWith(step: CardImportStep.importing, isBusy: true);
    try {
      final result = await ref.read(commitImportUseCaseProvider)(
        deckId: deckId,
        preview: preview,
        includeDuplicates: draft.isIncludingDuplicates,
      );
      if (!ref.mounted) return;
      state = switch (result) {
        Ok(:final value) => CardImportDone(value),
        Rejected(reason: TransferRejection.targetRejected) => CardImportFailed(
          draft: draft,
          isTargetRejected: true,
        ),
        Rejected(:final reason) => draft.copyWith(problem: reason),
      };
    } on Failure {
      if (!ref.mounted) return;
      state = CardImportFailed(draft: draft, isTargetRejected: false);
    }
  }

  /// "Try again" after a failed write: the same preview, committed again
  /// (E5).
  Future<void> retry() async {
    if (state case CardImportFailed(:final draft, isTargetRejected: false)) {
      state = draft;
      await commit();
    }
  }

  /// "Import another file" after a result: a fresh step 1 for the same deck
  /// (UC-TRANSFER-001 step 8).
  void startOver() => state = const CardImportDraft();

  /// Android Back and the app bar's Back (IT-NAV-012 step 4): one step back,
  /// keeping what the step held. False at step 1 and on a result, where the
  /// screen closes. While writing, Back does nothing (step 5).
  bool stepBack() {
    final draft = _draft;
    if (draft == null) return false;
    switch (draft.step) {
      case CardImportStep.source:
        return false;
      case CardImportStep.importing:
        return true;
      case CardImportStep.columns:
        state = CardImportDraft(
          sourceKind: draft.sourceKind,
          fileName: draft.fileName,
          source: draft.source,
        );
        return true;
      case CardImportStep.preview:
        state = CardImportDraft(
          step: CardImportStep.columns,
          sourceKind: draft.sourceKind,
          fileName: draft.fileName,
          source: draft.source,
          table: draft.table,
          mapping: draft.mapping,
          hasHeaderRow: draft.hasHeaderRow,
        );
        return true;
    }
  }
}
