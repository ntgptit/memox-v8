import 'dart:async';

import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_draft_repository.dart';

/// Keeps the card being written in its device-local draft (SP2a R9, 2.14):
/// each change is written once typing pauses, in order, and a form equal to
/// what it was opened with keeps no draft. The draft is a convenience, so a
/// failed write never reaches the form. A plain class: the form's state owns
/// it and its timer, and flushes it when it goes.
final class CardDraftController {
  CardDraftController({
    required this._repository,
    required this.key,
    this.delay = pause,
  });

  /// How long typing must pause before the draft is written.
  static const Duration pause = Duration(milliseconds: 500);

  final String key;
  final Duration delay;
  final CardDraftRepository _repository;

  Timer? _timer;
  ({CardDraft draft, CardDraft saved})? _pending;
  Future<void> _writes = Future<void>.value();

  /// The draft kept under [key]; null when there is none or the read fails.
  Future<CardDraft?> read() async {
    try {
      return await _repository.read(key);
    } on Failure {
      // An unreadable draft offers nothing; it must not stop the editor.
      return null;
    }
  }

  /// Writes [draft] once typing pauses for [delay]; when it is the same card
  /// as [saved] (what the form was opened with) the draft is dropped instead.
  void schedule(CardDraft draft, {required CardDraft saved}) {
    _pending = (draft: draft, saved: saved);
    _timer?.cancel();
    _timer = Timer(delay, _write);
  }

  /// Writes what waits, now; completes when every queued write is done.
  Future<void> flush() {
    _timer?.cancel();
    _write();
    return _writes;
  }

  /// Drops the draft and whatever still waits to be written.
  Future<void> clear() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
    _enqueue(() => _repository.clear(key));
    return _writes;
  }

  void _write() {
    _timer = null;
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    _enqueue(
      () => pending.draft.sameContentAs(pending.saved)
          ? _repository.clear(key)
          : _repository.save(key, pending.draft),
    );
  }

  void _enqueue(Future<void> Function() write) {
    _writes = _writes.then((_) async {
      try {
        await write();
      } on Failure {
        // The draft is a convenience: a failed write never interrupts typing.
      }
    });
  }
}
