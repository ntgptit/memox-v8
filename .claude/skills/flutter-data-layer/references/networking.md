# Networking with Dio

Location: `core/network/`.

## One client, configured once

```dart
Dio buildDio(EnvConfig env) {
  final dio = Dio(BaseOptions(
    baseUrl: env.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 20),
    headers: const {'Accept': 'application/json'},
    validateStatus: (status) => status != null && status < 400,
  ));

  dio.interceptors.addAll([
    RequestIdInterceptor(),
    AuthInterceptor(tokenStore, dio),
    if (env.logLevel == LogLevel.debug) LoggingInterceptor(),
  ]);
  return dio;
}
```

All three timeouts matter and they fail differently: `connectTimeout` covers
reaching the server, `receiveTimeout` covers a server that accepts and then
stalls, `sendTimeout` covers a stalled upload. Without a receive timeout a
request can hang until the OS gives up — minutes of a spinner.

Expose it as a single `keepAlive` provider. Multiple Dio instances mean multiple
interceptor chains, and a token refreshed on one is not applied to the others.
V8's is `dioProvider` in `lib/core/network/di/network_providers.dart`: these
three timeouts and the request-ID interceptor, with the base URL from
`ApiConfig`. The auth and logging interceptors above come with login and with
a need to log.

## Endpoints: Retrofit interfaces, never hand-written Dio calls (ADR-012)

Each group of endpoints is a Retrofit interface in the feature's
`data/datasources/`; `retrofit_generator` writes the calls. Features never call
`dio.get`/`dio.post` themselves.

```dart
part 'deck_api.g.dart';

@RestApi()
abstract class DeckApi {
  factory DeckApi(Dio dio) = _DeckApi;

  @GET('/api/v1/decks')
  Future<DeckPageModel> findDecks(@Query('page') int page, @Query('size') int size);

  @POST('/api/v1/decks')
  Future<DeckModel> createDeck(@Body() CreateDeckRequestModel request);
}

@Riverpod(keepAlive: true)
DeckApi deckApi(Ref ref) => DeckApi(ref.watch(dioProvider));
```

DTOs (`DeckModel`, …) are `json_serializable` classes in `data/models/`, not
Freezed; the repository maps them to entities and catches `DioException`.

## Interceptors

**Request ID** — attach a UUID per request and log it. When a user reports a
failure, this is what correlates their report with the server's logs.

**Auth** — attach the bearer token; on 401, refresh once and retry.

The trap is concurrent 401s: five parallel requests fail, five refreshes fire,
four are rejected as reusing a consumed refresh token, and the user is logged
out. Serialise it — hold a single in-flight refresh `Future` and have every
waiter await the same one:

```dart
Future<String>? _refreshInFlight;

Future<String> _refreshToken() {
  final existing = _refreshInFlight;
  if (existing != null) return existing;          // join the in-flight refresh

  final future = _performRefresh().whenComplete(() => _refreshInFlight = null);
  _refreshInFlight = future;
  return future;
}
```

If the refresh itself fails, clear the session and let the router's guard move
the user to login. Do not retry a failed refresh — the token is gone.

**Logging** — development only, and redact by key:

```dart
const _redactedKeys = {'authorization', 'password', 'token', 'refresh_token'};
```

Redact in the interceptor rather than at call sites: one place to get right, and
it cannot be forgotten by a new endpoint. Never log a full response body in
production — it will contain user data.

**Error mapping** — do not map inside the interceptor. Let `DioException`
propagate to the code that owns the decision of what a failure means: sync
today, a repository once one calls the API. An interceptor cannot know that.

## Mapping to Failure

Only sync calls the API today, and it maps nothing: `SyncScheduler` retries a
failed run with backoff (`lib/core/sync/sync_scheduler.dart`). When a
repository first calls the API, the mapping follows ADR-011 D6 and ADR-012, the
way `lib/core/error/` already maps the database:

- **A refusal the server states is a value.** A `ProblemDetail` whose `code`
  names a business rule becomes `Rejected(reason)`, the reason a value of the
  calling feature's enum in `domain/failures/`. The UI maps each reason to its
  own words, so it never renders the server's message; the `requestId` goes to
  the log, to trace the failure on the server.
- **Anything else is a `Failure`.** No connection, a timeout, a 5xx, or a body
  the contract does not describe: the sealed `Failure` in
  `lib/core/error/failure.dart` gains the subclasses they need, and one
  `mapDioException` beside `mapDatabaseError` maps them, keeping the stack
  trace.

Test that function directly, per status code and exception type
(`flutter-testing`). It is the code most likely to be wrong and least likely to
be exercised by hand.

## API contract

Document in `docs/features/<feature>/api.md`: endpoints, request and response
shapes, the error envelope, pagination style, and auth behaviour.

**Pagination** — normalise whatever the server does into one internal shape:

```dart
final class Page<T> {
  const Page({required this.items, required this.nextCursor, required this.hasMore});
  final List<T> items;
  final String? nextCursor;
  final bool hasMore;
}
```

Cursor pagination is more robust than offset for lists that change while being
paged — offset skips or duplicates rows when items are inserted mid-scroll.

**Backward compatibility** — treat every field the server might not send as
nullable in the DTO and resolve it in the mapper. An unknown enum value maps to
an `unknown` variant rather than throwing; otherwise the server adding a status
crashes the app for every user who has not updated.

## Resilience

- **Offline** — surface it as an explicit state, not a generic error. If the app
  is offline-first, show cached data with an offline indicator instead of an
  error screen. `connectivity_plus` reports link state, not reachability — a
  captive portal reads as connected, so treat it as a hint, not proof.
- **Retry** — bounded, exponential backoff with jitter, GETs only. Jitter
  matters when many clients retry after an outage; without it they synchronise
  and re-flood the server.
- **Never blindly retry a mutation.** Use an idempotency key the server honours,
  or do not retry.
- **Duplicate submissions** — guard in the controller (see
  `flutter-state-riverpod`), not only in the UI.
- **Cancellation** — `CancelToken` tied to the provider's `onDispose`.
