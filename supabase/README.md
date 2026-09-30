# MemoX on Supabase

The sync backend (ADR-015; design in
`docs/superpowers/specs/2026-09-28-supabase-backend-design.md`). Everything the
server does is in `migrations/`; `tests/database/` proves it with pgTAP.

## Run and test locally

Needs Docker. From the repo root:

    npx supabase db start      # Postgres with the migrations applied
    npx supabase test db       # pgTAP
    npx supabase db reset      # re-apply migrations after editing one

Without Docker (a cloud container), `bash tools/supabase/local_pgtap.sh` runs the same
migrations and tests on a local Postgres 16 with pgTAP (`apt-get install
postgresql-16-pgtap`), with a shim for the Supabase roles and `auth.uid()`. It is a
convenience; the CI `supabase` job is the gate.

## Owner setup (once)

1. Create a project on supabase.com (Free plan).
2. Authentication → Sign In / Providers: enable **Anonymous sign-ins**, and
   turn on CAPTCHA or keep the default rate limit for anonymous sign-ins.
3. GitHub → Settings → Secrets → Actions: `SUPABASE_ACCESS_TOKEN` (Account →
   Access Tokens) and `SUPABASE_DB_PASSWORD`, for the migrations workflow,
   which pushes `migrations/` on every merge to `master` that changes them
   and on demand (`workflow_dispatch`). The workflow runs pgTAP before the
   push and, after it, fails when the project schema differs from
   `migrations/`. The weekly usage workflow reads the same access token.
4. Same place: `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` (Project
   Settings → API Keys), for the keep-alive workflow and the Build APK
   workflow, which passes them to `--dart-define-from-file`.
5. Build the app with both values:

       flutter run --dart-define=SUPABASE_URL=https://<ref>.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=<key>

   Native Google sign-in also needs `--dart-define=GOOGLE_WEB_CLIENT_ID=<Web
   OAuth client id of SB-A4>` (auth spec O11); without it, email sign-in still
   works.

6. Make your own user the first admin, once per user id. Find the id under
   Authentication → Users (your account, or the app's anonymous user on your
   phone), then run in the SQL Editor:

       update public.profiles set role = 'admin' where id = '<uuid>';

   The server reads the role from `public.profiles` (auth spec 2026-09-30,
   migration `20261010000000`), at once; the migration already copied an
   existing `app_metadata.role = admin`. Until the app reads `me()` (auth
   phase P2), it still shows the Admin section from the token, so also keep

       update auth.users
       set raw_app_meta_data = raw_app_meta_data || '{"role":"admin"}'
       where id = '<uuid>';

   Later admins are granted in the app (`role_set`). Only an admin can call
   `log_query`, `log_get`, `log_set_status`, `role_list` and `role_set`;
   everyone else gets `FORBIDDEN`. This changes data, not schema, so the drift
   check does not see it.

## Sign-in setup (SB-A4, once)

The app signs in with a 6-digit email code and with native Google (auth spec
2026-09-30, O1 and O11). Nothing opens a link, so the project needs no
redirect URL and the app no deep link for auth; the Site URL can stay as it
is. Until this is done, anonymous use and sync work as before, and signing in
fails.

1. **Google Cloud** (console.cloud.google.com, one project for MemoX):
   1. Google Auth Platform → Branding: the app name, a support email and,
      before real users, a privacy policy link. While the audience is
      "Testing", add your Google accounts as test users.
   2. Clients → Create client → **Web application**. No origins or redirect
      URIs are needed. Keep its client ID and secret.
   3. Clients → Create client → **Android**, package `com.memox.memox`, and
      the SHA-1 of the key that signs the build you install. For a debug or
      `flutter run --release` build on your machine:

          keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

      One Android client per signing key: another machine and the release
      key of step 6 each need their own.
2. **Supabase → Authentication → Sign In / Providers:**
   - **Google:** on. *Client IDs*: the Web client ID **first**, then every
     Android client ID, separated by commas. *Client Secret*: the Web
     client's secret. *Skip nonce check*: on, as Supabase's Flutter guide
     says (the device check, row D2 of the auth spec §9.1, confirms it).
   - **Allow manual linking:** on. Linking an email or Google to the
     anonymous user needs it.
   - **Email:** on, with *Email OTP Length* **6** (the app's code field takes
     exactly six digits) and an *Email OTP Expiration* of at most one hour.
   - **Anonymous sign-ins:** stays on.
3. **Authentication → Emails → Templates.** The app never uses the link, so
   each of these templates must show `{{ .Token }}`:
   - **Magic link:** signing in by email.
   - **Confirm signup:** the first email to an address with no account yet.
   - **Change email address:** linking an email to the anonymous user.

   For example, subject `{{ .Token }} is your MemoX code`, body:

       <h2>Your MemoX code</h2>
       <p>Enter this code in the app: <strong>{{ .Token }}</strong></p>
       <p>If you didn't ask for it, ignore this email.</p>

4. **Authentication → Emails → SMTP Settings:** turn on custom SMTP with a
   mail provider (sender address, host, port, user, password). The built-in
   mailer sends very few emails and only for testing (auth spec §10). Then
   raise the email limit under **Authentication → Rate Limits**.
5. **Build with the Web client ID:**

       flutter run --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_PUBLISHABLE_KEY=… --dart-define=GOOGLE_WEB_CLIENT_ID=<Web client ID>

   For the Build APK workflow, add the repository secret
   `GOOGLE_WEB_CLIENT_ID`. Without it, email sign-in still works and Google
   does not.

6. **The release key for the Build APK workflow.** Without it the workflow
   signs with a debug key the runner creates on each run: no Android client
   can match it, Google sign-in fails on those APKs (email works), and a new
   APK cannot be installed over the last one. Once:
   1. Create the key, with passwords of letters and digits only (the
      workflow writes them into a `.properties` file, where `\` escapes):

          keytool -genkeypair -keystore memox-release.jks -alias memox -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=MemoX"

      Keep the `.jks` and both passwords somewhere safe outside the repo:
      without them no later APK installs over one signed by this key (on
      Google Play it would become the upload key).
   2. Repository secrets: `ANDROID_KEYSTORE_BASE64` (the output of
      `base64 -w0 memox-release.jks`), `ANDROID_KEYSTORE_PASSWORD`,
      `ANDROID_KEY_ALIAS` (`memox`) and `ANDROID_KEY_PASSWORD`.
   3. Run Build APK by hand. Its job summary shows the APK's signer; add its
      SHA-1 as another Android client (step 1.3), and that client ID to
      Supabase's *Client IDs* (step 2).
   4. The first APK with this key does not install over an older one: let
      sync finish (or sign in) on the phone, uninstall, then install it.

   The workflow fails if a key is given and the APK still carries the debug
   key; `flutter run` on your machine keeps the debug key.

After setup, run the device check (auth spec §9.1) and record its results
there.

## Rules

- Clients reach data only through `sync_push`, `sync_changes`, `ping`, the
  log RPCs (`log_push` for everyone, `log_query`, `log_get` and `log_set_status`
  for an admin, ADR-018) and the account RPCs (`me`, `account_claim_begin`,
  `account_merge`, `account_merge_ack`, `account_delete` for everyone,
  `role_list` and `role_set` for an admin, auth spec 2026-09-30). Every owned
  row references `auth.users`, so deleting a user deletes their data.
  Tables have RLS on, no policy and no client privilege; helpers live in the
  unexposed `private` schema.
- A new migration never edits one already pushed to the project.
- The schema changes only through `migrations/`, never in the dashboard's SQL
  Editor or Table Editor: the migrations workflow fails on any other change.
  One exemption (owner's ruling, 2026-09-28): `public.rls_auto_enable()`, the
  event-trigger function Supabase created with the project to switch RLS on
  for new tables. It is not in `migrations/`, and it cannot be called directly
  (it returns `event_trigger`), so the drift check skips it.

## Workflows

| Workflow | When | Does |
|---|---|---|
| `supabase migrations` | merge to `master` touching `migrations/`, or by hand | pgTAP, `db push`, then `db diff --linked` must be empty |
| `supabase keep-alive` | daily | calls `ping` so the Free project does not pause |
| `app-log-retention` (pg_cron, in the database) | daily at 03:41 UTC | `private.purge_app_log()`: deletes `debug`/`info` logs older than 7 days and `warning`/`error` older than 180 days (ADR-018 §5) |
| `supabase usage` | weekly, or by hand | reports database size, users and 30-day active users; fails at 80% of a Free limit, so GitHub emails the owner |
