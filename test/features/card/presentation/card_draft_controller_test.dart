import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_draft_repository.dart';
import 'package:memox/features/card/presentation/controllers/card_draft_controller.dart';

// SP2a 2.14 (R9): the draft is written once typing pauses, in order, and an
// unchanged form keeps none. A failed draft write never reaches the form.

final class _FakeDrafts implements CardDraftRepository {
  final stored = <String, CardDraft>{};
  final calls = <String>[];

  /// Start and end of each save, to see whether two writes overlapped.
  final events = <String>[];
  Duration saveTime = Duration.zero;
  Failure? failure;
  Object? crash;

  @override
  Future<CardDraft?> read(String key) async {
    calls.add('read $key');
    if (crash case final crash?) throw crash;
    if (failure case final failure?) throw failure;
    return stored[key];
  }

  @override
  Future<void> save(String key, CardDraft draft) async {
    calls.add('save $key ${draft.front}');
    if (crash case final crash?) throw crash;
    events.add('start ${draft.front}');
    if (saveTime > Duration.zero) await Future<void>.delayed(saveTime);
    if (failure case final failure?) throw failure;
    stored[key] = draft;
    events.add('end ${draft.front}');
  }

  @override
  Future<void> clear(String key) async {
    calls.add('clear $key');
    if (failure case final failure?) throw failure;
    stored.remove(key);
  }
}

const _key = 'create:d';
const _empty = CardDraft(front: '', back: '');

void main() {
  late _FakeDrafts drafts;

  setUp(() => drafts = _FakeDrafts());

  // Built inside each fakeAsync: the write chain starts on a future whose
  // microtasks belong to the zone it was created in.
  CardDraftController build() =>
      CardDraftController(repository: drafts, key: _key);

  test('a change is written once typing pauses, not before', () {
    fakeAsync((async) {
      final controller = build();
      controller.schedule(
        const CardDraft(front: 'bap', back: ''),
        saved: _empty,
      );

      async.elapse(const Duration(milliseconds: 499));
      expect(drafts.calls, isEmpty);

      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();
      expect(drafts.calls, ['save $_key bap']);
      expect(drafts.stored[_key]!.front, 'bap');
    });
  });

  test(
    'a later change restarts the pause and only the last text is written',
    () {
      fakeAsync((async) {
        final controller = build();
        controller.schedule(
          const CardDraft(front: 'b', back: ''),
          saved: _empty,
        );
        async.elapse(const Duration(milliseconds: 300));
        controller.schedule(
          const CardDraft(front: 'ba', back: ''),
          saved: _empty,
        );
        async.elapse(const Duration(milliseconds: 300));
        expect(drafts.calls, isEmpty);

        async.elapse(const Duration(milliseconds: 200));
        async.flushMicrotasks();
        expect(drafts.calls, ['save $_key ba']);
      });
    },
  );

  test(
    'a form equal to the saved one drops the draft instead of keeping it',
    () {
      fakeAsync((async) {
        final controller = build();
        drafts.stored[_key] = const CardDraft(front: 'x', back: 'y');
        controller.schedule(_empty, saved: _empty);

        async.elapse(CardDraftController.pause);
        async.flushMicrotasks();
        expect(drafts.calls, ['clear $_key']);
        expect(drafts.stored, isEmpty);
      });
    },
  );

  test('clear cancels a write that is still waiting', () {
    fakeAsync((async) {
      final controller = build();
      controller.schedule(
        const CardDraft(front: 'bap', back: ''),
        saved: _empty,
      );
      unawaited(controller.clear());

      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();
      expect(drafts.calls, ['clear $_key']);
    });
  });

  test('flush writes what waits at once', () {
    fakeAsync((async) {
      final controller = build();
      controller.schedule(
        const CardDraft(front: 'bap', back: ''),
        saved: _empty,
      );
      unawaited(controller.flush());

      async.flushMicrotasks();
      expect(drafts.calls, ['save $_key bap']);
      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();
      expect(drafts.calls, hasLength(1));
    });
  });

  test('writes keep their order: a clear after a slow save wins', () {
    fakeAsync((async) {
      final controller = build();
      drafts.saveTime = const Duration(milliseconds: 100);
      controller.schedule(
        const CardDraft(front: 'bap', back: ''),
        saved: _empty,
      );
      async.elapse(CardDraftController.pause);
      unawaited(controller.clear());

      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(drafts.calls, ['save $_key bap', 'clear $_key']);
      expect(drafts.stored, isEmpty);
    });
  });

  test('a failed write is swallowed and the next one still runs', () {
    fakeAsync((async) {
      final controller = build();
      drafts.failure = const UnknownDatabaseFailure(cause: 'disk full');
      controller.schedule(
        const CardDraft(front: 'a', back: ''),
        saved: _empty,
      );
      async.elapse(CardDraftController.pause);
      async.flushMicrotasks();

      drafts.failure = null;
      controller.schedule(
        const CardDraft(front: 'ab', back: ''),
        saved: _empty,
      );
      async.elapse(CardDraftController.pause);
      async.flushMicrotasks();
      expect(drafts.stored[_key]!.front, 'ab');
    });
  });

  test('any error, not only a Failure, leaves the chain alive', () {
    fakeAsync((async) {
      final controller = build();
      drafts.crash = StateError('not a Failure');
      controller.schedule(
        const CardDraft(front: 'a', back: ''),
        saved: _empty,
      );
      async.elapse(CardDraftController.pause);
      async.flushMicrotasks();

      drafts.crash = null;
      controller.schedule(
        const CardDraft(front: 'ab', back: ''),
        saved: _empty,
      );
      async.elapse(CardDraftController.pause);
      async.flushMicrotasks();
      expect(drafts.stored[_key]!.front, 'ab');
    });
  });

  test('save then save with the first in flight: the latest text wins', () {
    fakeAsync((async) {
      final controller = build();
      // Longer than the pause, so the second timer fires while the first
      // save is still running.
      drafts.saveTime = const Duration(milliseconds: 700);
      controller.schedule(
        const CardDraft(front: 'a', back: ''),
        saved: _empty,
      );
      async.elapse(CardDraftController.pause);
      controller.schedule(
        const CardDraft(front: 'ab', back: ''),
        saved: _empty,
      );
      async.elapse(CardDraftController.pause);
      expect(drafts.events, ['start a']);

      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();
      expect(drafts.events, ['start a', 'end a', 'start ab', 'end ab']);
      expect(drafts.stored[_key]!.front, 'ab');
    });
  });

  test(
    'read hands back the kept draft, or nothing when the read fails',
    () async {
      final controller = build();
      drafts.stored[_key] = const CardDraft(front: 'kept', back: 'k');
      expect((await controller.read())!.front, 'kept');

      drafts.failure = const UnknownDatabaseFailure(cause: 'disk full');
      expect(await controller.read(), isNull);

      drafts.failure = null;
      drafts.crash = StateError('not a Failure');
      expect(await controller.read(), isNull);
    },
  );

  test(
    'a kill inside the pause loses at most that window: dispose flushes',
    () {
      fakeAsync((async) {
        final controller = build();
        controller.schedule(
          const CardDraft(front: 'ba', back: ''),
          saved: _empty,
        );
        async.elapse(const Duration(milliseconds: 400));
        expect(drafts.calls, isEmpty);

        // The form's dispose flushes the controller.
        unawaited(controller.flush());
        async.flushMicrotasks();
        expect(drafts.stored[_key]!.front, 'ba');
      });
    },
  );
}
