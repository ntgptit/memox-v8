import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/presentation/providers/build_export_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/providers/share_export_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/states/card_export_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_export_controller.g.dart';

/// One export sheet over [scope] (kit 12, UC-TRANSFER-002). It lives as
/// long as the sheet: closing the sheet while a file is prepared shares
/// nothing.
@riverpod
class CardExportController extends _$CardExportController {
  /// The sheet is closing. Its route stays mounted while it slides away, so
  /// the provider outlives the tap by the close animation.
  var _isClosed = false;

  bool get _isGone => _isClosed || !ref.mounted;

  @override
  CardExportState build(CardExportScope scope) => CardExportState(
    problem: scope.cardCount == 0 ? CardExportProblem.nothingToExport : null,
  );

  /// Step 3, A2: CSV, TSV or XLSX; fixed while a file is prepared.
  void chooseFormat(TransferFormat format) {
    if (state.isPreparing || state.isHandedOver) return;
    state = CardExportState(format: format, problem: state.problem);
  }

  /// Cancel, Back, a scrim tap or a drag down (A5): the file in progress is
  /// never shared.
  void close() => _isClosed = true;

  /// Steps 4–7: build the file and hand it to the share sheet. A second
  /// call while one runs does nothing (A4).
  Future<void> export() async {
    if (!state.canExport) return;
    final format = state.format;
    state = CardExportState(format: format, isPreparing: true);
    // Null once the state says why, or once the sheet has closed.
    final artifact = await _build(format);
    if (artifact == null) return;

    final shared = await ref.read(shareExportUseCaseProvider)(artifact);
    if (!ref.mounted) return;
    state = switch (shared) {
      Ok(value: ExportShareResult.shared) => CardExportState(
        format: format,
        isHandedOver: true,
      ),
      // A3: a cancel, not an error; the sheet is as it was.
      Ok(value: ExportShareResult.dismissed) => CardExportState(format: format),
      Rejected(reason: TransferRejection.shareUnavailable) => CardExportState(
        format: format,
        problem: CardExportProblem.noShareTarget,
      ),
      Rejected() => CardExportState(
        format: format,
        problem: CardExportProblem.shareFailed,
      ),
    };
  }

  /// Steps 4–5, E3–E6: the file, or null once the state says why not or
  /// the sheet has closed meanwhile.
  Future<ExportArtifact?> _build(TransferFormat format) async {
    final Outcome<ExportArtifact, TransferRejection> built;
    try {
      built = await ref.read(buildExportUseCaseProvider)(
        deckId: scope.deckId,
        format: format,
        today: ref.read(dayClockProvider).now(),
        cardIds: scope.cardIds,
      );
    } on Failure {
      if (!_isGone) _fail(format, CardExportProblem.prepareFailed);
      return null;
    }
    if (_isGone) return null;
    switch (built) {
      case Ok(:final value):
        return value;
      case Rejected(:final reason):
        _fail(format, switch (reason) {
          TransferRejection.emptyScope => CardExportProblem.nothingToExport,
          TransferRejection.staleSelection => CardExportProblem.staleSelection,
          _ => CardExportProblem.prepareFailed,
        });
        return null;
    }
  }

  void _fail(TransferFormat format, CardExportProblem problem) =>
      state = CardExportState(format: format, problem: problem);
}
