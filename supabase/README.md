# MemoX on Supabase

The sync backend (ADR-015; design in
`docs/superpowers/specs/2026-09-28-supabase-backend-design.md`). Everything the
server does is in `migrations/`; `tests/database/` proves it with pgTAP.

## Run and test locally

Needs Docker. From the repo root:

    npx supabase db start      # Postgres with the migrations applied
    npx supabase test db       # pgTAP
    npx supabase db reset      # re-apply migrations after editing one

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

## Rules

- Clients reach data only through `sync_push`, `sync_changes` and `ping`.
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
| `supabase usage` | weekly, or by hand | reports database size, users and 30-day active users; fails at 80% of a Free limit, so GitHub emails the owner |
