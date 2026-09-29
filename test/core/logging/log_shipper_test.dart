import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/log_api.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/core/logging/log_shipper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

LogEntry _entry(int n) => LogEntry(
  id: 'id-${n.toString().padLeft(4, '0')}',
  occurredAt: DateTime.utc(2026, 9, 29).add(Duration(seconds: n)),
  level: LogLevel.info,
  category: LogCategory.db,
  event: 'db.query',
);

/// Records each call; accepts all ids unless told otherwise.
final class _FakeRpc {
  final calls = <List<Object?>>[];
  Object? failWith;
  Set<String>? acceptOnly;

  /// A call carrying one of these ids is refused whole, as a server error.
  Set<String> poison = {};

  Future<Object?> call(String function, Map<String, Object?> params) async {
    final entries = params['entries']! as List<Object?>;
    calls.add(entries);
    if (failWith case final error?) throw error;
    final ids = [
      for (final e in entries) (e! as Map<String, Object?>)['id']! as String,
    ];
    if (ids.any(poison.contains)) {
      throw const PostgrestException(message: 'payload refused');
    }
    return {
      'accepted': [
        for (final id in ids)
          if (acceptOnly == null || acceptOnly!.contains(id)) id,
      ],
    };
  }
}

// Spec 2026-09-29-app-logging-design.md §3: the shipper.
void main() {
  late LogDatabase db;
  late _FakeRpc rpc;
  late LogShipper shipper;

  setUp(() {
    db = LogDatabase(NativeDatabase.memory());
    rpc = _FakeRpc();
    shipper = LogShipper(
      db,
      LogApi(ensureSession: () async {}, rpc: rpc.call),
      batch: 3,
    );
  });
  tearDown(() => db.close());

  test('an empty buffer makes no call', () async {
    await shipper.runOnce();
    expect(rpc.calls, isEmpty);
  });

  test('batches go oldest first, as log_push reads them, until the buffer is '
      'empty', () async {
    await db.insertAll([for (var n = 0; n < 7; n++) _entry(n)]);

    await shipper.runOnce();

    expect(rpc.calls.map((c) => c.length), [3, 3, 1]);
    expect((rpc.calls.first.first! as Map<String, Object?>)['id'], 'id-0000');
    expect(
      (rpc.calls.first.first! as Map<String, Object?>)['occurredAt'],
      '2026-09-29T00:00:00.000Z',
    );
    expect(await db.count(), 0);
  });

  test('only the ids the server accepted leave the buffer', () async {
    await db.insertAll([_entry(1), _entry(2)]);
    rpc.acceptOnly = {'id-0001'};

    await shipper.runOnce();

    expect((await db.oldest(10)).map((e) => e.id), ['id-0002']);
  });

  test('a failed call keeps every row and rethrows, so the scheduler backs '
      'off', () async {
    await db.insertAll([_entry(1)]);
    rpc.failWith = StateError('offline');

    await expectLater(shipper.runOnce(), throwsStateError);
    expect(await db.count(), 1);
  });

  test('a row the server refuses is found by halving the batch and dropped; '
      'the rest still go', () async {
    await db.insertAll([for (var n = 1; n <= 6; n++) _entry(n)]);
    rpc.poison = {'id-0002'};

    await shipper.runOnce();

    expect(await db.count(), 0);
    final sent = {
      for (final call in rpc.calls)
        for (final e in call) (e! as Map<String, Object?>)['id'],
    };
    expect(sent, containsAll(['id-0001', 'id-0003', 'id-0006']));
    expect(rpc.calls.map((c) => c.length), [3, 2, 1, 1, 1, 1, 1, 1]);
  });

  test('a network error keeps every row and propagates', () async {
    await db.insertAll([for (var n = 1; n <= 2; n++) _entry(n)]);
    rpc.failWith = const SocketException('offline');

    await expectLater(shipper.runOnce(), throwsA(isA<SocketException>()));

    expect(await db.count(), 2);
    expect(rpc.calls, hasLength(1));
  });

  test('when the server refuses every call, one row is dropped and the error '
      'propagates: a broken RPC must not empty the buffer', () async {
    await db.insertAll([for (var n = 1; n <= 4; n++) _entry(n)]);
    rpc.failWith = const PostgrestException(message: 'function not found');

    await expectLater(shipper.runOnce(), throwsA(isA<PostgrestException>()));

    expect(await db.count(), 3);
  });
}
