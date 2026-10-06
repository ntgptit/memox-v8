-- DEV-188, DEV-200: what the daily cleanup removes.
--
-- DEV-188: an unacknowledged merge receipt is kept whatever its age. The device
-- that merged may be killed after the server committed and before it saved the
-- `merged` stage, then stay closed for months; on its return it retries the
-- merge with the same operation id and must get MERGED (auth spec §3.4: a
-- committed merge never returns to the source). The 7-day `expires_at` is no
-- longer read; a receipt goes once the device acknowledges it (#29).
--
-- DEV-200: applied op ids older than 90 days are forgotten. Every operation is
-- idempotent by content: a forgotten op id resent is applied again as the same
-- upsert (overwriting with the same row) or delete (a tombstoned row answers
-- with its version), never doubled. An index on applied_at keeps the delete,
-- and the activity check above it, off a full scan.
create index if not exists idx_sync_applied_op_applied_at on public.sync_applied_op (applied_at);

create or replace function private.cleanup_accounts() returns void
language plpgsql set search_path = '' as $$
declare
  v_user uuid;
begin
  for v_user in
    -- Activity is a me() call, a sync push or a log push, so a user whose app never
    -- called me() is still seen. An admin is never cleaned up (LAST_ADMIN).
    select u.id from auth.users u join public.profiles p on p.id = u.id
    where u.is_anonymous and p.role = 'user' and p.last_active_at < now() - interval '90 days'
      and not exists (select 1 from public.sync_applied_op o
                      where o.user_id = u.id and o.applied_at >= now() - interval '90 days')
      and not exists (select 1 from public.app_log l
                      where l.user_id = u.id and l.received_at >= now() - interval '90 days')
  loop
    perform private.delete_user_data(v_user);
  end loop;
  delete from public.account_merge_receipt where acknowledged_at is not null;
  delete from public.account_claim where expires_at < now();
  delete from public.sync_applied_op where applied_at < now() - interval '90 days';
end
$$;
revoke all on function private.cleanup_accounts() from public, anon, authenticated;
