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
3. `npx supabase login`, `npx supabase link --project-ref <ref>`,
   `npx supabase db push`.
4. GitHub → Settings → Secrets → Actions: `SUPABASE_URL` and
   `SUPABASE_PUBLISHABLE_KEY` (Project Settings → API Keys), for the
   keep-alive workflow.
5. Build the app with both values:

       flutter run --dart-define=SUPABASE_URL=https://<ref>.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=<key>

## Rules

- Clients reach data only through `sync_push`, `sync_changes` and `ping`.
  Tables have RLS on, no policy and no client privilege; helpers live in the
  unexposed `private` schema.
- A new migration never edits one already pushed to the project.
