# Cache, sync and secure storage

The database half of this file now lives in the `flutter-drift` skill, so that
one question has one answer: schema and `.drift` conventions, index design,
DAO/data-source boundaries, transactions, migrations and stream invalidation are
all there, together with what this project has already settled about them.

Load `flutter-drift` for any of that. What stays here is the policy that sits
*above* the database — what to cache, how to sync, and where secrets go.

## Cache strategy

**Not for the user's data (ADR-013).** Drift is the durable store the app always
reads, not a cache in front of the server: it is never cleared to refresh, and
freshness comes from sync's pull, not from a TTL.

A cache policy applies only to data the app reads from the server without
syncing it, and there is none today. When such a read appears, decide it per
data type in an ADR in `docs/shared/decisions/`: cached or not, the TTL, and
what the UI shows while the copy is stale. Showing stale data with a refresh
indicator beats a spinner over a blank screen: the user sees something
immediately and the update arrives behind it.

TTL lives in the repository. The UI never decides whether to read local or
remote — that policy belongs in one place, or it will drift per screen.

## Sync and conflicts

Decided once for every synced entity by ADR-013, with ADR-015 putting the
server on Supabase and business rules and SRS in the app only; a feature does
not pick its own conflict policy. The designs are
`docs/superpowers/specs/2026-09-27-server-sync-design.md`, for the deck slice as
built `docs/superpowers/specs/2026-09-27-app-deck-sync-design.md`, and for the
server `docs/superpowers/specs/2026-09-28-supabase-backend-design.md`. What a repository
has to know:

- **A write queues itself.** Today triggers in `sync.drift` add a synced row's
  write to `sync_outbox` in the same statement, so the repository writes its
  row and nothing else (BE-E1); the push carries whole rows. An entry leaves the outbox only once the server
  has answered, so a push that fails loses nothing.
- **The server settles conflicts.** An operation it refuses comes back with
  the server's copy, which replaces the local one. No device clock takes part.
- **Sync is not a feature's code.** `lib/core/sync/` holds it: one
  `SyncCoordinator` pushes and pulls, and use cases and presentation never see
  the network.

## Secure storage

```dart
const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);
```

- Access and refresh tokens only. Not bulk data — secure storage is slow, and on
  Android it has size limits.
- Never store a raw password. If "remember me" is needed, store the token.
- SharedPreferences is not secure. Nothing sensitive goes there.
- **On logout, clear everything**: tokens, cached user data, and any
  feature-specific tables holding personal data. A device shared between users
  otherwise leaks the previous session's content.
- `KeychainAccessibility.first_unlock` keeps tokens readable for background
  refresh after a reboot without exposing them on a locked device.

If the database itself holds sensitive data, consider SQLCipher via
`sqlcipher_flutter_libs`. Decide this before launch — encrypting an existing
plaintext database in a migration is painful, and it is a decision better made
once in `docs/shared/decisions/ADR-002-du-lieu-nhay-cam-va-chua-ma-hoa-database.md`.
