# Network Logging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every request the Supabase client sends leaves one entry in the app log, except the log push itself.

**Architecture:**
- `LoggingHttpClient` wraps the HTTP client that `Supabase.initialize` hands to both GoTrue and PostgREST.
- It logs through `appLogger` under a new `LogCategory.network`.
- A migration widens the server's category check and `private.log_entry_valid`.

**Tech Stack:** Dart `package:http` (`BaseClient`, `MockClient`), `supabase_flutter` 2.17, Postgres/pgTAP.

**Spec:** `docs/superpowers/specs/2026-09-29-network-logging-design.md`

## Global Constraints

- Branch `claude/network-logging` (owner approved separate branches, 2026-09-29).
- The class lives in `lib/core/network/logging_http_client.dart` (owner approved).
- Levels:
  - 2xx/3xx → `debug net.request`;
  - 4xx/5xx → `warning net.http_error`;
  - `SocketException`, `TimeoutException` or `http.ClientException` → `info net.unreachable`;
  - anything else → `error net.failed`.
  - Every thrown error is rethrown with its stack trace.
- A request whose URL path ends in `/rpc/log_push` is not logged.
- Context keys: `method`, `url`, `request_headers`, `request_body`, `status`, `response_headers`, `response_body`, `duration_ms`, `bytes_sent`, `bytes_received`.
- Bodies over 64 KB (65536 bytes) keep their first 64 KB and add `request_body_bytes` / `response_body_bytes` and `request_body_truncated` / `response_body_truncated: true`.
- Invalid UTF-8 is logged as `<N bytes, binary>`.
- Nothing is redacted (ADR-018 §1).
- Never edit an applied migration. The new one is `supabase/migrations/20261005000000_log_network_category.sql`.
- Generated files are gitignored: run `dart run build_runner build --delete-conflicting-outputs` and `flutter gen-l10n` after checkout.
- Every commit ends with:
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2
  ```

## Review Focus

1. **A response body the caller reads after logging.** The bytes, status, headers and reason phrase reach Supabase unchanged. Test: "the caller gets the same response back" (Task 2).
2. **The log push request.** It is not logged, even when it fails. Test: "a failing log_push logs nothing and still throws" (Task 2).
3. **A body cut mid-character at 64 KB.** The cut must never produce invalid UTF-8 that the server refuses. Test: "a 64 KB cut inside a multi-byte character stays valid text" (Task 2).
4. **A streamed request body** (`http.StreamedRequest`, not used by Supabase today). It is sent intact, and its body is logged as `<streamed>`. Test: "a streamed request is sent intact" (Task 2).
5. **A server not yet migrated.** A `network` entry pushed before the migration is skipped and counted, not refused whole. This is covered by `log_entry_valid` returning false, and the B1 pgTAP test "bad rows are skipped and reported" already pins that path, so there is nothing new to add.

---

### Task 1: `LogCategory.network` on client and server

**Files:**
- Modify: `lib/core/logging/log_entry.dart` (enum `LogCategory`)
- Create: `supabase/migrations/20261005000000_log_network_category.sql`
- Test: `supabase/tests/database/09_app_log.sql` (two assertions), `test/core/logging/app_logger_test.dart` (one test)

**Interfaces:**
- Produces: `LogCategory.network` (name `'network'`), accepted by `public.log_push`.

- [ ] **Step 1: Write the failing tests**

In `test/core/logging/app_logger_test.dart`, before the closing `}` of `main`:

```dart
  test('a network entry round-trips through JSON', () {
    final sink = _RecordingSink();
    AppLogger(sinks: [sink], now: () => at)
        .debug('net.request', category: LogCategory.network);

    final json = sink.entries.single.toJson();

    expect(json['category'], 'network');
    expect(LogEntry.fromJson(json).category, LogCategory.network);
  });
```

In `supabase/tests/database/09_app_log.sql`:
- raise `select plan(31);` to `select plan(33);`;
- add after the test named `'an oversized context is accepted'`:

```sql
select is((public.log_push(jsonb_build_array(
    public.t_entry('11111111-0000-0000-0000-000000000008', 'debug') || '{"category": "network"}'))->>'rejected')::int,
  0, 'a network entry is accepted');
select is((select category from public.app_log where id = '11111111-0000-0000-0000-000000000008'),
  'network', 'and stored as network');
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/core/logging/app_logger_test.dart --plain-name "network entry"`
Expected: compile error `Member not found: 'network'`.

Run: `bash tools/supabase/local_pgtap.sh`
Expected: `09_app_log.sql` FAIL on "a network entry is accepted" (have 1, want 0).

- [ ] **Step 3: Implement**

`lib/core/logging/log_entry.dart`, add `network` after `sync`:

```dart
enum LogCategory {
  ui,
  navigation,
  state,
  db,
  sync,
  network,
  reminder,
  lifecycle,
  server,
}
```

`supabase/migrations/20261005000000_log_network_category.sql`:

```sql
-- Spec 2026-09-29-network-logging-design.md §4: the app logs its HTTP requests under
-- the category `network`. Widens the check and the push validation; nothing else changes.

alter table public.app_log drop constraint app_log_category_check;
alter table public.app_log add constraint app_log_category_check check (category in
  ('ui', 'navigation', 'state', 'db', 'sync', 'network', 'reminder', 'lifecycle', 'server'));

create or replace function private.log_entry_valid(e jsonb) returns boolean
language sql stable set search_path = '' as $$
  select coalesce(jsonb_typeof(e) = 'object'
    and e->>'level' in ('debug', 'info', 'warning', 'error')
    and e->>'category' in ('ui', 'navigation', 'state', 'db', 'sync', 'network', 'reminder', 'lifecycle',
      'server')
    and private.try_uuid(e->>'id') is not null
    and coalesce(e->>'event', '') <> ''
    and private.try_timestamptz(e->>'occurredAt') is not null
    and coalesce(jsonb_typeof(e->'context'), 'object') = 'object', false)
$$;

revoke all on function private.log_entry_valid(jsonb) from public, anon, authenticated;
```

If `local_pgtap.sh` reports that the constraint has another name, read it with
`select conname from pg_constraint where conrelid = 'public.app_log'::regclass and contype = 'c';`
and use that name. Record it in the ledger as a Ruling.

- [ ] **Step 4: Run them to see them pass**

Run: `flutter test test/core/logging` then `bash tools/supabase/local_pgtap.sh`
Expected: all tests passed; every pgTAP file `ok`, and `09_app_log.sql (33)`.

- [ ] **Step 5: Commit**

```bash
git add lib/core/logging/log_entry.dart supabase/migrations/20261005000000_log_network_category.sql \
  supabase/tests/database/09_app_log.sql test/core/logging/app_logger_test.dart
git commit -m "feat(logging): the network log category, on the app and the server"
```

---

### Task 2: `LoggingHttpClient`

**Files:**
- Create: `lib/core/network/logging_http_client.dart`
- Test: `test/core/network/logging_http_client_test.dart`

**Interfaces:**
- Consumes: `LogCategory.network` (Task 1); `AppLogger`, `appLogger` (`lib/core/logging/app_logger.dart`); `RecordingLogSink` (`test/support/recording_log_sink.dart`).
- Produces: `final class LoggingHttpClient extends http.BaseClient { LoggingHttpClient({required http.Client inner, AppLogger? logger, int Function()? micros}); static const maxBodyBytes = 65536; }`

- [ ] **Step 1: Write the failing tests**

`test/core/network/logging_http_client_test.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/network/logging_http_client.dart';

import '../../support/recording_log_sink.dart';

final _url = Uri.parse('https://x.supabase.co/rest/v1/rpc/sync_push?a=1');
final _logPush = Uri.parse('https://x.supabase.co/rest/v1/rpc/log_push');

// Spec 2026-09-29-network-logging-design.md §2, §5.
void main() {
  late RecordingLogSink sink;

  setUp(() => sink = RecordingLogSink());

  LoggingHttpClient client(MockClientHandler handler, {List<int>? ticks}) {
    var now = 0;
    final steps = [...?ticks];
    return LoggingHttpClient(
      inner: MockClient(handler),
      logger: AppLogger(sinks: [sink]),
      micros: () => now += steps.isEmpty ? 0 : steps.removeAt(0),
    );
  }

  test('a 200 logs debug net.request with the whole exchange', () async {
    final c = client(
      (request) async => http.Response('{"ok":true}', 200,
          headers: {'content-type': 'application/json'}),
      ticks: [0, 12000],
    );

    await c.post(_url, headers: {'Authorization': 'Bearer t'}, body: '{"x":1}');

    final entry = sink.entries.single;
    expect((entry.level, entry.category, entry.event),
        (LogLevel.debug, LogCategory.network, 'net.request'));
    expect(entry.context['method'], 'POST');
    expect(entry.context['url'], '/rest/v1/rpc/sync_push?a=1');
    expect(entry.context['request_body'], '{"x":1}');
    expect(entry.context['response_body'], '{"ok":true}');
    expect(entry.context['status'], 200);
    expect(entry.context['duration_ms'], 12);
    expect(
      (entry.context['request_headers']! as Map)['Authorization'],
      'Bearer t',
    );
  });

  test('the caller gets the same response back', () async {
    final c = client((request) async => http.Response.bytes(
          utf8.encode('{"a":"é"}'), 201,
          headers: {'x-h': 'v'}, reasonPhrase: 'Created'));

    final response = await c.get(_url);

    expect(response.statusCode, 201);
    expect(response.reasonPhrase, 'Created');
    expect(response.headers['x-h'], 'v');
    expect(utf8.decode(response.bodyBytes), '{"a":"é"}');
  });

  test('a 4xx or 5xx logs warning net.http_error', () async {
    final c = client((request) async => http.Response('{"code":"P0001"}', 400));

    await c.get(_url);

    expect((sink.entries.single.level, sink.entries.single.event),
        (LogLevel.warning, 'net.http_error'));
  });

  test('no connection logs info net.unreachable and rethrows', () async {
    final c = client((request) async => throw const SocketException('down'));

    await expectLater(c.get(_url), throwsA(isA<SocketException>()));

    expect((sink.entries.single.level, sink.entries.single.event),
        (LogLevel.info, 'net.unreachable'));
  });

  test('another error logs error net.failed and rethrows', () async {
    final c = client((request) async => throw StateError('bug'));

    await expectLater(c.get(_url), throwsStateError);

    final entry = sink.entries.single;
    expect((entry.level, entry.event), (LogLevel.error, 'net.failed'));
    expect(entry.stackTrace, isNotNull);
  });

  test('the log push logs nothing and still returns', () async {
    final c = client((request) async => http.Response('{"accepted":[]}', 200));

    final response = await c.post(_logPush, body: '{}');

    expect(response.statusCode, 200);
    expect(sink.entries, isEmpty);
  });

  test('a failing log_push logs nothing and still throws', () async {
    final c = client((request) async => throw const SocketException('down'));

    await expectLater(c.post(_logPush, body: '{}'), throwsA(isA<SocketException>()));

    expect(sink.entries, isEmpty);
  });

  test('a body over 64 KB keeps its first 64 KB and says it was cut', () async {
    final big = 'a' * (LoggingHttpClient.maxBodyBytes + 10);
    final c = client((request) async => http.Response(big, 200));

    await c.get(_url);

    final context = sink.entries.single.context;
    expect((context['response_body']! as String).length,
        LoggingHttpClient.maxBodyBytes);
    expect(context['response_body_bytes'], LoggingHttpClient.maxBodyBytes + 10);
    expect(context['response_body_truncated'], isTrue);
  });

  test('a 64 KB cut inside a multi-byte character stays valid text', () async {
    final big = '${'a' * (LoggingHttpClient.maxBodyBytes - 1)}é tail';
    final c = client((request) async => http.Response.bytes(utf8.encode(big), 200));

    await c.get(_url);

    final body = sink.entries.single.context['response_body']! as String;
    expect(() => utf8.encode(body), returnsNormally);
    expect(body.endsWith('a'), isTrue);
  });

  test('a body that is not UTF-8 is logged as its size', () async {
    final c = client((request) async => http.Response.bytes([0xff, 0xfe, 0x00], 200));

    await c.get(_url);

    expect(sink.entries.single.context['response_body'], '<3 bytes, binary>');
  });

  test('a streamed request is sent intact', () async {
    List<int>? received;
    final c = client((request) async {
      received = request.bodyBytes;
      return http.Response('', 204);
    });
    final request = http.StreamedRequest('POST', _url);
    unawaited(Future(() {
      request.sink.add(utf8.encode('chunk'));
      request.sink.close();
    }));

    await c.send(request);

    expect(utf8.decode(received!), 'chunk');
    expect(sink.entries.single.context['request_body'], '<streamed>');
  });
}
```

- [ ] **Step 2: Run to see it fail**

Run: `flutter test test/core/network/logging_http_client_test.dart`
Expected: compile error `Error when reading 'lib/core/network/logging_http_client.dart'`.

- [ ] **Step 3: Implement**

`lib/core/network/logging_http_client.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:memox/core/logging/app_logger.dart';

/// Logs every request the Supabase client sends (spec
/// 2026-09-29-network-logging-design.md): the whole exchange at `debug`, an
/// HTTP error as a warning, no connection at `info`, anything else as an
/// error. The log push is never logged: each push would log the next one.
final class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient({
    required http.Client inner,
    AppLogger? logger,
    int Function()? micros,
  }) : _inner = inner,
       _logger = logger,
       _micros = micros ?? (() => _stopwatch.elapsedMicroseconds);

  /// A body past this many bytes is logged as its head (spec D6).
  static const maxBodyBytes = 65536;

  static const _logPushPath = '/rpc/log_push';
  static final _stopwatch = Stopwatch()..start();

  final http.Client _inner;
  final AppLogger? _logger;
  final int Function() _micros;

  AppLogger get _log => _logger ?? appLogger;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.path.endsWith(_logPushPath)) return _inner.send(request);
    final sent = request is http.Request ? request.bodyBytes : null;
    final start = _micros();
    final http.StreamedResponse response;
    final List<int> received;
    try {
      response = await _inner.send(request);
      received = await response.stream.toBytes();
    } on Object catch (error, stackTrace) {
      _failed(request, sent, start, error, stackTrace);
      rethrow;
    }
    _done(request, sent, response, received, start);
    return http.StreamedResponse(
      Stream.value(received),
      response.statusCode,
      contentLength: received.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();

  void _done(
    http.BaseRequest request,
    List<int>? sent,
    http.StreamedResponse response,
    List<int> received,
    int start,
  ) {
    final context = {
      ..._requestContext(request, sent, start),
      'status': response.statusCode,
      'response_headers': response.headers,
      ..._body('response', received),
    };
    if (response.statusCode >= 400) {
      _log.warning('net.http_error', category: LogCategory.network, context: context);
      return;
    }
    _log.debug('net.request', category: LogCategory.network, context: context);
  }

  void _failed(
    http.BaseRequest request,
    List<int>? sent,
    int start,
    Object error,
    StackTrace stackTrace,
  ) {
    final context = _requestContext(request, sent, start);
    if (_isUnreachable(error)) {
      _log.info(
        'net.unreachable',
        category: LogCategory.network,
        message: '$error',
        context: context,
      );
      return;
    }
    _log.error(
      'net.failed',
      category: LogCategory.network,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  Map<String, Object?> _requestContext(
    http.BaseRequest request,
    List<int>? sent,
    int start,
  ) => {
    'method': request.method,
    'url': request.url.hasQuery
        ? '${request.url.path}?${request.url.query}'
        : request.url.path,
    'request_headers': request.headers,
    if (sent == null) 'request_body': '<streamed>' else ..._body('request', sent),
    'duration_ms': (_micros() - start) ~/ 1000,
  };

  /// The body as text, its head past [maxBodyBytes] (cut on a character
  /// boundary), or its size when it is not UTF-8.
  static Map<String, Object?> _body(String side, List<int> bytes) {
    final cut = bytes.length > maxBodyBytes;
    final head = cut ? bytes.sublist(0, maxBodyBytes) : bytes;
    final String text;
    try {
      text = utf8.decode(head, allowMalformed: cut);
    } on FormatException {
      return {'${side}_body': '<${bytes.length} bytes, binary>'};
    }
    return {
      '${side}_body': cut ? text.replaceAll('�', '') : text,
      'bytes_${side == 'request' ? 'sent' : 'received'}': bytes.length,
      if (cut) ...{'${side}_body_bytes': bytes.length, '${side}_body_truncated': true},
    };
  }

  static bool _isUnreachable(Object error) =>
      error is SocketException ||
      error is TimeoutException ||
      error is http.ClientException;
}
```

A note for the executor on the cut rule: decoding the head with
`allowMalformed: true` turns a split multi-byte character into U+FFFD, and the
code removes it. Stripping every U+FFFD from a cut body also drops a real U+FFFD
in the text. That is acceptable for a log head; record it in the ledger as a
Ruling if you keep it. The test "a 64 KB cut inside a multi-byte character"
expects the head to end in `a`: `maxBodyBytes - 1` bytes of `a` plus the first
byte of `é`, minus the replacement.

- [ ] **Step 4: Run to see it pass**

Run: `flutter test test/core/network/logging_http_client_test.dart`
Expected: `+11: All tests passed!`

Run: `flutter analyze lib/core/network test/core/network`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/core/network/logging_http_client.dart test/core/network/logging_http_client_test.dart
git commit -m "feat(network): LoggingHttpClient logs every Supabase request"
```

---

### Task 3: Wire it into `main.dart`, docs and gate

**Files:**
- Modify: `lib/main.dart` (the `Supabase.initialize` call)
- Modify: `docs/superpowers/specs/2026-09-29-app-logging-design.md` (§3 capture-points table: a row for the network)
- Modify: `docs/shared/decisions/ADR-018-log-tap-trung-va-monitoring.md` (Hệ quả: one bullet)
- Modify: `.claude/skills/flutter-ship/SKILL.md` ("Already captured" bullet: add "every Supabase request (`LoggingHttpClient`)")
- Modify: `docs/wbs_BE.md` (a row `BE-D10` under "Hạ tầng và tài liệu")

**Interfaces:**
- Consumes: `LoggingHttpClient` (Task 2).

- [ ] **Step 1: Wire**

`lib/main.dart`:

```dart
    await Supabase.initialize(
      url: supabase.url,
      publishableKey: supabase.publishableKey,
      // Every request, auth and RPC, is logged (ADR-018; spec
      // 2026-09-29-network-logging-design.md).
      httpClient: LoggingHttpClient(inner: http.Client()),
    );
```

Add the imports `package:http/http.dart' as http;` and `package:memox/core/network/logging_http_client.dart`.

`main()` has no unit test, because it needs the platform. The wiring is verified by `flutter analyze` and by the gate's full test run. Record that in the ledger.

- [ ] **Step 2: Docs**

- Spec §3 table:
  `| Supabase HTTP client (`core/network/logging_http_client.dart`) | `debug net.request`; `warning net.http_error`; `info net.unreachable`; `error net.failed` | method, url, headers, bodies (64 KB head), status, `duration_ms` |`
- ADR-018 Hệ quả:
  `- Log mạng: mọi request của Supabase client (trừ `log_push`) được ghi với category `network` (spec [`2026-09-29-network-logging-design.md`](../../superpowers/specs/2026-09-29-network-logging-design.md)).`
- `wbs_BE.md` row `BE-D10`:
  - a Vietnamese result sentence;
  - status `xong`;
  - dependency `BE-D8`;
  - size `S`;
  - evidence: the spec, this plan, the test file names and the pgTAP count.
- Then run: `python3 tools/docs/generate.py && python3 tools/docs/check.py`
  Expected: `PASS — 0 error(s)`.

- [ ] **Step 3: Gate**

Run:
- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze`
- `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
- `bash tools/supabase/local_pgtap.sh`

Expected:
- format reports 0 changed;
- `No issues found!`;
- dod_check ends without `failed gates`;
- every pgTAP file `ok`.

Goldens are unaffected (no UI), so do not run `--update-goldens`.

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart docs .claude/skills/flutter-ship/SKILL.md
git commit -m "feat(network): log every Supabase request; docs"
```
