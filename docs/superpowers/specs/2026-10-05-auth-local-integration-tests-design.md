# Auth integration tests on a local Supabase

Status: approved 2026-10-05; implemented by
`docs/superpowers/plans/2026-10-05-auth-local-integration-tests.md`, with the
amendments of §10. Follows the device check of
[the auth spec](2026-09-30-auth-design.md) §9.1, which the owner stopped after
D1, D2, D6 and D11 (2026-10-05): checking every row by hand on an emulator
took too long, and two bugs it found (F1, F2, `docs/wbs_supabase.md` SB-A7)
sat in a seam the tests did not reach.

## 1. Intent

- **Goal:** the email-based rows of §9.1 run as automated tests against a
  real GoTrue, PostgREST and Postgres, so the manual check shrinks to D2
  (real Google) and a smoke pass.
- **Success:** one script brings up the local stack and runs the suite;
  each row is a test that fails when the behaviour §9.1 expects breaks; the
  default suite and `dod_check.sh` stay free of Docker.
- **Owner rulings (2026-10-05):** the tests run on the host with `flutter
  test`, not on an emulator; they run from their own script, required when a
  PR touches auth, not inside `dod_check.sh`.

## 2. What runs where

| Row of §9.1 | Here | Elsewhere |
|---|---|---|
| D1, D3, D4, D5, D6, D7, D8, D10, D11, D12 | this suite, at the coordinator level | — |
| D2 (real Google: SHA-1, client IDs, nonce, consent) | — | by hand on a device |
| D9 (Android Back) | — | widget tests in `test/app/` and `test/features/account/` |
| Routing after a flow ends (F1, F2) | — | `test/app/account_routes_test.dart` |

UI and routing stay with the widget tests over `AuthWorld`'s fakes. This
suite proves what those fakes cannot: GoTrue's real answers (for example
`email_exists` 400 and `identity_already_exists` 422 for a taken identity),
the RPCs and RLS of `supabase/migrations/`, and real sync.

## 3. A device

`test/integration/auth/support/local_device.dart` builds one device from
production classes, the way `accountCoordinatorProvider`,
`syncApiProvider` and their neighbours do, with two substitutions:

| Part | Here |
|---|---|
| `SupabaseClient` | its own, on the local API URL and publishable key; session storage in memory |
| `SupabaseAuthGateway` | `SupabaseAuthGateway(client.auth, pickGoogle: …)`; picking Google throws, no row uses it |
| `SupabaseAccountApi` | `SupabaseAccountApi(rpc: client.rpc, refreshSession: client.auth.refreshSession)` |
| `SupabaseSyncApi`, sync scheduler and coordinator, `AppSyncControl` | real, over `client.rpc` |
| `AppDatabase`, `AccountStore`, `LocalDataReset`, `MutationGate` | real, the database in memory |
| `SecretStore` | **fake**, in memory |
| `NetworkStatus` | **fake**, switchable, for D7 and D12; while it is off, the client's `http.Client` fails every request too, so "offline" holds whether the coordinator asks the status or meets the failure |

No production code changes: every class above already takes its client or
its calls through its constructor. Two devices, A and B, live in one test
process with separate clients and databases. A device can be rebuilt on its
own database and secret store, which is how D5 resumes after a "kill".

## 4. Mail

`test/integration/auth/support/mailpit.dart` reads the local stack's
Mailpit over HTTP: the newest message to an address, its six-digit code.
Each test uses fresh addresses (`it-<random>@example.com`), so tests share
nothing and nothing is cleaned up between runs.

## 5. Local configuration

- `supabase/templates/` holds the three templates of SB-A4 (magic link,
  confirm signup, change email address), each showing `{{ .Token }}`, and
  `supabase/config.toml` points `[auth.email.template.*]` at them. The
  templates of the real project now have a copy in the repo.
- `[auth.rate_limit] email_sent` goes from 2 to a value the suite cannot
  reach in one run (100).
- `[auth.email] enable_confirmations = true`, as on the real project
  ("Confirm email"): with it off, GoTrue linked an email to an anonymous
  user without sending a code.
- Everything else the suite needs is already set: anonymous sign-ins,
  manual linking, a six-digit OTP.

## 6. The rows

Each row is one test with the expectations of §9.1, checked on the device
and on the server (a service-role client reads `auth.users` and the owned
tables).

| # | Steps | Expected |
|---|---|---|
| D1 | A anonymous with two decks synced; link an email, code from Mailpit | `Ready`, **same user id**, now with the email; the decks still on the device and the server |
| D3 | an account (D1's) with decks; B anonymous with its own decks; B signs in with that email; Merge | B shows both libraries after a sync; B's decks on the account; B's anonymous user gone |
| D4 | as D3 with Discard | B shows only the account's decks; B's own rows gone from the server |
| D5 | as D3, and drop B's coordinator after the merge commit, before the ack; rebuild it on the same database and secrets | it resumes and ends as D3; no duplicated decks |
| D6 | an account with a deck; Sign out online | the change is pushed first; the device is a new anonymous user with no decks; signing in again brings the deck back |
| D7 | an account, the network off, a local edit; Sign out | refused with the number of unsent changes; nothing is cleared |
| D8 | an account; its sessions revoked with the service role; the access token expired | `ReauthRequired`; signing in with the same email returns to `Ready` with nothing lost |
| D10 | an admin and a user; `role_set` both ways; the only admin demotes itself | `role_list` shows both; the role changes; `LAST_ADMIN` refuses the last demotion |
| D11 | an account with data; delete it online | the user and its rows are gone from the server; the device is a fresh anonymous user |
| D12 | the network off; ask for a code | `OfflineFailure`, the state unchanged; back online, the code arrives and sign-in completes |

D8 does not wait an hour for the access token to run out. The service role
signs the account out everywhere (`auth.admin.signOut` with the device's
token, global scope), which revokes its refresh tokens; the test then makes
the device refresh, the path the app takes when the token runs out, and
GoTrue refuses it.

## 7. Running it

- The files sit in `test/integration/auth/` and carry `@Tags(['supabase'])`;
  `dart_test.yaml` declares the tag. `run_tests.sh`, `dod_check.sh` and the
  bundling of the default suite exclude it, as they exclude `golden`.
- They are plain `test()`s: the widget binding blocks real HTTP.
- `tools/supabase/run_auth_it.sh`: `npx supabase start` (Docker), reads the
  API URL, publishable key, service-role key and Mailpit URL from
  `npx supabase status -o env`, passes them as environment variables, and
  runs `flutter test --tags supabase test/integration/auth`. A missing stack
  or variable fails with a message that names it, never as a skipped test.
- **When it is required:** a PR that changes `lib/core/auth/`,
  `lib/features/account/` or `supabase/migrations/` runs it, as such a PR
  already runs `npx supabase test db`. `supabase/README.md` and the gate
  section of `CLAUDE.md` say so.

## 8. Risks

- **Docker on Windows:** the first `supabase start` pulls images and takes
  minutes; later starts take seconds. The script prints the step it is on.
- **GoTrue versions:** the local stack's GoTrue follows the CLI version, not
  the project's. A difference shows as a failing row, which is the point;
  the CLI version is the one `supabase-migrations.yml` pins.
- **D5 is not a real kill:** dropping and rebuilding the coordinator is the
  crash test's model on fakes, now on the real server. A process kill stays
  with the device check if it is ever needed.
- **Time:** each row should run in seconds; a row that needs a wait gets
  it from the server, not from a sleep.

## 9. Out of scope

- Google sign-in (D2), which needs a real Google account and Play services.
- UI and routing, which the widget tests own.
- Running the suite in CI, which is paused; the script is the gate.

## 10. Amendments in implementation (2026-10-05)

- **Location:** the suite lives in `test_supabase/auth/`, not in
  `test/integration/auth/` with a `supabase` tag. `bundle_tests.py` refuses a
  library-level `@Tags` in a host file and gathers every `_test.dart` under
  `test/`; a top-level directory keeps the suite out of `run_tests.sh` and
  `dod_check.sh` with no change to either.
- **The script** stops the stack before starting it (a running stack keeps
  the config it started with) and starts only GoTrue, PostgREST, Kong,
  Mailpit and Postgres (`supabase start -x` the rest).
- **D7** checks the coordinator's contract: offline, a sign-out stops in
  `Transitioning` with `OfflineFailure` before anything is removed, and
  `cancelSignOut()` restores the account; the dialog that names the loss
  reads the unsent count (account UI spec, B2).
- **Clients** use the app's PKCE flow with an in-memory storage.
