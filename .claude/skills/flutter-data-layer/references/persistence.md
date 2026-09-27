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

Decided once for every synced entity by ADR-013 and its design,
`docs/superpowers/specs/2026-09-27-server-sync-design.md`; a feature does not
pick its own conflict policy. What a repository has to know:

- **A write queues itself.** The row and one `sync_outbox` entry go in the same
  Drift transaction. The outbox keeps at most one entry per entity, its id is
  the push's idempotency key, and the entry leaves only once the server has
  answered, so a push that fails loses nothing.
- **The server settles conflicts.** Content follows the operation the server
  receives last, and an operation that would break the deck tree is rejected
  and replaced by the server's copy. No device clock takes part.
- **Sync is not a feature's code.** One `SyncCoordinator` pushes and pulls; use
  cases and presentation never see the network.

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
