# Network logging: every Supabase request in the app log

Status: draft for owner review · 2026-09-29 · sub-project D of the 2026-09-29
infrastructure review · decisions in
[ADR-018](../../shared/decisions/ADR-018-log-tap-trung-va-monitoring.md)

## 1. Intent

The review proposed network interceptors. Checked on master `2deb7137`:

- **No request goes through Dio.** `dioProvider` (ADR-012) exists and nothing
  reads it.
- **All traffic goes through the Supabase client:** anonymous sign-in, token
  refresh, `sync_push`, `sync_changes`, `ping`, `log_push`.

The owner chose (2026-09-29): log every Supabase request into the app log, so an
admin sees the app's traffic next to its database and UI logs. Dio interceptors
are out: they would be structure for requests that do not exist (CLAUDE.md, no
speculative structure).

Success:

- Every request the Supabase client sends (auth and REST) leaves one log entry
  with method, URL, headers, request and response bodies, status and duration.
- A failed request (HTTP error or no connection) is logged at the level its
  cause deserves.
- The log push never logs itself.
- Supabase receives the response unchanged.

## 2. Decisions

| # | Decision | Why |
|---|---|---|
| D1 | `LoggingHttpClient extends http.BaseClient` in `lib/core/network/logging_http_client.dart`, wrapping an inner `http.Client`. `main.dart` passes it to `Supabase.initialize(httpClient: …)` | `SupabaseClient` hands one client to GoTrue (auth) and PostgREST (RPC), so one wrapper sees every request. `lib/core/network/` already holds `supabase_config.dart`. Owner approved the location (2026-09-29) |
| D2 | A new `LogCategory.network` | The requests are neither `sync` nor `db`. The server's `category` check and `private.log_entry_valid` must accept it (§4) |
| D3 | Levels: 2xx/3xx → `debug net.request`; 4xx/5xx → `warning net.http_error`; a transport failure (`SocketException`, `TimeoutException`, `http.ClientException`) → `info net.unreachable`; anything else → `error net.failed`, rethrown | Same rule as sync (the review round of B1): offline is a normal state, not an open error. A 4xx/5xx is open for triage, since a refused RPC is worth a look |
| D4 | A request whose path ends in `/rpc/log_push` is not logged | Each push would log a new entry for the next push: a loop that never empties the buffer |
| D5 | Context: `method`, `url` (path and query; the host is the one project), `request_headers`, `request_body`, `status`, `response_headers`, `response_body`, `duration_ms`, `bytes_sent`, `bytes_received`. Headers include `Authorization` and `apikey` | "Log everything" (ADR-018 §1, owner ruling). The `apikey` is the publishable key; the bearer is the session, which the owner accepted in ADR-018 |
| D6 | A body over 64 KB is logged as its first 64 KB plus `request_body_bytes` / `response_body_bytes` and `…_truncated: true` | A `sync_changes` page can pass 256 KB, and the server cuts such a context down to `kind` and `sql`, which says nothing about a request. Owner approved (2026-09-29) |
| D7 | The response body is read in full, logged, then handed back as a new `StreamedResponse` with the same status, headers, reason phrase, request and length | The caller must get the same bytes. Supabase responses are JSON read whole anyway, so buffering costs nothing it did not already pay |
| D8 | A body that is not valid UTF-8 is logged as `<N bytes, binary>` | No such request exists today (no storage use). It guards the log from bytes it cannot store |

## 3. Client

- `LoggingHttpClient({required http.Client inner, AppLogger? logger, int Function()? micros})`:
  - the logger defaults to `appLogger`, read at each call like the tracer;
  - `micros` is a Stopwatch seam as in `TracingInterceptor`;
  - `close()` closes the inner client.
- `send(request)`:
  1. Take the request body (for an `http.Request`, `bodyBytes`) before sending.
  2. Time the call and read the response stream in full.
  3. Log per D3–D8.
  4. Return a new `StreamedResponse` built from the bytes.
  5. On a thrown error, log it and rethrow it with its stack trace.
- `main.dart`: `Supabase.initialize(…, httpClient: LoggingHttpClient(inner: http.Client()))`.
- `LogCategory.network` joins the enum. The Monitoring screen (B2) shows it like
  any other category.

## 4. Server

A new migration, `supabase/migrations/20261005000000_log_network_category.sql`.
The existing ones are already applied in production and are never edited.

- It drops and re-adds the `app_log` check on `category` with `network` added.
- It replaces `private.log_entry_valid(e jsonb)` with the same body plus `network`.
- pgTAP: a `network` entry is accepted and stored; an unknown category is still
  skipped.

## 5. Testing

Unit tests with `MockClient` (`package:http/testing.dart`) and a recording sink:

- a 200 logs `debug net.request` with method, URL, both bodies, status and duration;
- the caller gets the same status, headers and body bytes back;
- a 404 or 500 logs `warning net.http_error`;
- a `SocketException` logs `info net.unreachable` and rethrows;
- another exception logs `error net.failed` and rethrows;
- `/rest/v1/rpc/log_push` logs nothing and still returns its response;
- a body over 64 KB is cut, with its real size and the truncation flag;
- a non-UTF-8 body is logged as its size.

Also: pgTAP for §4, the full `dod_check.sh` gate, and a local run of all pgTAP
files.

## 6. Risks

- **Volume:** one `debug` row per request. Sync runs after writes (debounced
  2 s), and the log push every 5 minutes is excluded. This is well below the
  tracer's row per statement.
- **The 64 KB cut hides the tail of a large page.** The row counts stay visible
  in the `sync.pull` entry.
- **Rollback:** revert the PR. The migration only widens a check, so it stays
  harmless if the client code is reverted.
