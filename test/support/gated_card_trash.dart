import 'dart:async';

import 'package:memox/core/error/bulk_outcome.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// Moves cards to the Trash through [_inner] only once [open] is called, so
/// a test can press Back or tap the scrim while the write is in flight.
final class GatedCardTrash implements CardRepository {
  GatedCardTrash(this._inner);

  final CardRepository _inner;
  final _gate = Completer<void>();

  void open() => _gate.complete();

  @override
  Future<Outcome<BulkOutcome, CardRejection>> deleteCards({
    required Set<String> cardIds,
    DateTime? now,
  }) async {
    await _gate.future;
    return _inner.deleteCards(cardIds: cardIds, now: now);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
