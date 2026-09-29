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

6. Make your own user the log admin (ADR-018 §7), once per user id. Find the
   id under Authentication → Users (the app's anonymous user on your phone),
   then run in the SQL Editor:

       update auth.users
       set raw_app_meta_data = raw_app_meta_data || '{"role":"admin"}'
       where id = '<uuid>';

   The role reaches the app with its next token refresh (up to an hour) or
   sign-in. Only an admin can call `log_query`, `log_get` and `log_set_status`; everyone
   else gets `FORBIDDEN`. This changes data, not schema, so the drift check
   does not see it.

## Rules

- Clients reach data only through `sync_push`, `sync_changes`, `ping` and the
  log RPCs: `log_push` for everyone, `log_query`, `log_get` and `log_set_status`
  for an admin (ADR-018).
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
