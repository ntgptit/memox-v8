---
name: flutter-data-layer
description: Networking and persistence for this Flutter app. Today only the persistence half is live — dio is deliberately not a dependency (ADR-012), so the networking guidance here is reference for the backend phase, not current work. Covers the future shared Dio client with auth/logging/error/token-refresh/request-ID interceptors, DTO-to-entity mapping, pagination and error-response contracts, offline and retry behaviour, Drift schema design with indexes and migrations, cache strategy with TTL and a declared source of truth, conflict resolution and sync, and secure storage of tokens. Use this skill when calling an API, adding or changing a repository implementation, designing database tables or writing a Drift migration, deciding what to cache or how to sync, handling offline state, or storing anything sensitive.
---

# Data layer: networking and persistence

The repository is the boundary. Above it, domain entities and `Failure`. Below
it, DTOs, Dio and Drift. Nothing from below crosses up — that single rule is
what keeps the UI testable and the domain framework-free.

Read `references/networking.md` for the Dio client and interceptor setup, and
`references/persistence.md` for cache and sync policy.

**For anything below the repository — `.drift` schema and queries, indexes,
migrations, DAOs, transactions, Drift stream invalidation, or reviewing a
database PR — load `flutter-drift` instead.** That skill owns the database in
depth and knows what this project has already settled; this one owns the
repository contract above it.

## Source of truth — already decided for this project

**The server is canonical, and the app is offline-first (ADR-013).** The app
always reads and writes Drift, online or offline: reads come from `watch()`
streams, and a write lands locally first, so the UI never waits for the
network. Drift is the durable store, not a cache. Sync is the data layer's own
job, which use cases and presentation never see, and none of it is built yet:
no feature calls the API, and the repository contract is what lets sync arrive
without touching `domain/` or `presentation/`.

That means the networking half of this skill —
`references/networking.md` — is **reference material for the sync slices**, not
something to build ahead of them. `dio` is deliberately not a dependency yet
(ADR-012).

The generic reasoning below is kept because it is what makes the decision
reviewable.

**Offline-first** — reads always come from the database and are exposed as a
stream, so the UI updates when data changes for any reason. The network is a
background process that fills the database. Writes go to the database first
and are queued for upload. This is more work up front and dramatically better
under bad connectivity, and it is what ADR-013 chose, with the server holding
the canonical copy.

**Online-first** — the network is the source of truth, the database is a cache
with a TTL. Reads try the network, fall back to cache, and say so in the UI when
they are showing stale data.

Whichever it is, record it in an ADR in `docs/shared/decisions/`. And the UI
must never choose: a widget deciding "if offline read local else read remote"
has pulled a data-layer policy into presentation, and that policy will then
differ per screen.

## Repository shape

```dart
final class ReminderWorkloadRepositoryImpl
    implements ReminderWorkloadRepository {
  ReminderWorkloadRepositoryImpl(AppDatabase db)
    : _dao = ReminderWorkloadDao(db);

  final ReminderWorkloadDao _dao;

  @override
  Future<List<ReminderDeckWorkload>> rootWorkloads({
    required DateTime now,
    required DateTime startOfToday,
  }) async {
    try {
      final rows = await _dao.rootDeckRows(now: now, startOfToday: startOfToday);
      return [for (final row in rows) reminderDeckWorkloadOf(row, startOfToday)];
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}
```

What that demonstrates: the repository reads Drift through its DAO; rows become
domain types before they leave; and an exception is mapped at this boundary and
only here, by `mapDatabaseError` in `lib/core/error/failure.dart`, keeping its
stack trace (ADR-011 D6). A watch does the same with `.mapDatabaseErrors()`
(`progress_repository_impl.dart`). The example is
`lib/features/reminders/data/repositories/reminder_workload_repository_impl.dart`.

When the first API call lands, its `DioException` mapping goes next to
`mapDatabaseError` in `core/error/` and every repository uses it (ADR-012), so
the same status code cannot produce different failures in different features.
Test both directly (`flutter-testing`) — they are high-traffic code that manual
testing rarely exercises.

## DTO and entity are different types

`*_model.dart` in `data/models/` is the wire shape: nullable where the server is
nullable, named as the server names things, `json_serializable` annotations.
`*_entity.dart` in `domain/entities/` is the shape the app reasons about:
non-nullable where the app requires a value, named in domain language.

The mapper between them is where you handle the server's inconsistencies — a
missing field, a date as a string, an enum value you have never seen. Handle an
unknown enum value by mapping to a known `unknown` variant rather than throwing;
a server adding a status should not crash the app for every existing user.

Skipping the split — passing DTOs to the UI — means every server field rename
becomes a UI change, and every nullable server field becomes a null check in a
widget.

## Non-negotiables for this layer

- Never log tokens, passwords, or anything listed as sensitive in
  `docs/shared/decisions/ADR-002-du-lieu-nhay-cam-va-chua-ma-hoa-database.md`.
  Redact by key name in the logging interceptor, not by
  remembering at each call site.
- Verbose HTTP logging is development-only, gated on `EnvConfig.logLevel`.
- Tokens go in `flutter_secure_storage`, never in SharedPreferences, and are
  cleared on logout along with any cached user data — otherwise the next user of
  the device sees the previous one's content.
- Never retry a non-idempotent mutation blindly. A retried POST can double-charge
  or double-create. Retry GETs; retry mutations only with an idempotency key the
  server honours.
- Wrap multi-step writes in a transaction, so a failure halfway does not leave
  half-applied state.
- Never delete user data on a schema migration.

## Checks before the data layer is done

Now (Drift only; no API call yet, ADR-012):

- [ ] ADR-013's source of truth followed everywhere: the app reads and writes
      Drift, online or offline, and the server is canonical.
- [ ] No Drift exception escapes a repository.
- [ ] Exception→failure mapping in one place, with tests.
- [ ] Generated row types never reach presentation.
- [ ] Sensitive fields redacted in logs; verbose logging off in production.
- [ ] Mutations are not blindly retried; duplicate submits are prevented.
- [ ] Indexes exist for the queries actually run.
- [ ] Migration tested from every released schema version.

When the first API call lands (ADR-012):

- [ ] No `DioException` escapes a repository; DTOs never reach presentation.
- [ ] Timeouts set for connect, receive and send.
- [ ] Token refresh handles concurrent 401s without a refresh storm.
- [ ] Requests cancelled when their screen goes away.
- [ ] Tokens in secure storage, cleared on logout.
