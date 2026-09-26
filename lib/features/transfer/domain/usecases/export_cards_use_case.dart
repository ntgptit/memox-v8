import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_repository.dart';

/// UC-TRANSFER-002 steps 3-5: the file of an export, named for today's date
/// on the app's clock (BR-TRANSFER-013); nothing is written
/// (BR-TRANSFER-011).
final class ExportCardsUseCase {
  const ExportCardsUseCase(this._transfer, this._clock);

  final TransferRepository _transfer;
  final DayClock _clock;

  Future<Outcome<ExportFile, TransferRejection>> call({
    required String deckId,
    required ExportScope scope,
    required TransferFormat format,
  }) => _transfer.exportCards(
    deckId: deckId,
    scope: scope,
    format: format,
    now: _clock.now(),
  );
}
