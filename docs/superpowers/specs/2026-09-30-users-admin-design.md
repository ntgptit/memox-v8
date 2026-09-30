# Users (admin): screen 33 and the role client (P4)

Status: approved 2026-09-30 in the P4 brainstorm; implemented by
`docs/superpowers/plans/2026-09-30-users-admin.md`. Phase P4 of
[the auth spec](2026-09-30-auth-design.md) §11: the **Users** screen of O9,
under Settings › Admin, over the P1 RPCs `role_list` and `role_set` (auth spec
§2, `supabase/migrations/20261010000000_accounts.sql`). The auth spec's §8
row 33 was shaped against the retired kit; this file and
[`DESIGN.md`](../../../DESIGN.md) replace it
([ADR-019](../../shared/decisions/ADR-019-app-la-chuan-ui.md)). No server
change.

## 1. Rulings

| # | Ruling | Source |
|---|---|---|
| U1 | **An admin's own row is read-only.** It carries a "You" label and does not open the sheet; another admin demotes you. Nobody locks themself out of the screen they are on | owner, 2026-09-30 |
| U2 | **Settings owns the Admin section.** Screen 23 draws "ADMIN" only while `isAdminProvider` holds, from an `adminRows` slot of rows that features supply (Monitoring's row, then Users'), composed in `app/`. Monitoring's entry becomes a row; no feature imports another | owner, 2026-09-30 (approach A) |
| U3 | **Users lives in `features/account`**, as auth spec §5 names: `domain/UserRoleRepository` (`list`, `set`), `data/UserRoleRemoteDataSource` (`role_list`, `role_set`), `UsersController` | auth spec §5 |
| U4 | **The data source follows `MonitoringRemoteDataSource`**: the shared `RpcCall` on the session sync already holds; no session means "not an admin" without asking the server | brainstorm |
| U5 | **The route is `/settings/users`**, on the root navigator under Settings like Monitoring, behind the same admin gate (`MonitoringAdminGateWidget`, composed in `app/`) | brainstorm |

## 2. Data

- `role_list(p_query, p_after)` → `{items: [{id, email, role, createdAt, lastSignInAt}], next}`:
  non-anonymous users with an email, ordered by email, 50 a page, `next` the
  last email when another page exists. A blank query lists everyone.
- `role_set(p_user, p_role)` → `{id, role}`. Refusals: `FORBIDDEN`,
  `INVALID_ROLE`, `NOT_FOUND`, `ANONYMOUS_USER`, `LAST_ADMIN`.
- Domain: `ManagedUser` (id, email, `AccountRole` role, createdAt,
  lastSignInAt?), `UserPage` (users, `next`), `UserRoleRepository.list(query,
  after)` and `set(userId, role)`, which returns the user's new role or null
  when the user is gone (`NOT_FOUND`, as Monitoring returns null for a gone
  log). Two use cases: `SearchUsersUseCase`, `SetUserRoleUseCase`.
- Errors at the repository boundary (ADR-016 D2), as `mapMonitoringError`
  does: `FORBIDDEN` or no session → `NotAdminFailure`; `LAST_ADMIN` →
  `LastAdminFailure`; `ANONYMOUS_USER` → `AnonymousUserFailure` (both exist in
  core); a call that never arrived → `OfflineFailure`; anything else →
  `ServerFailure`.

## 3. Screen 33

| Region | Design |
|---|---|
| App bar | `MxAppBar` (content) + back: "Users". |
| Search | `MxSearchField` "Search by email"; a query runs 400 ms after the last keystroke; clearing it lists everyone. |
| Rows | Under an "ACCOUNTS" overline, `MxListRow` per user: a tinted person tile, the email (title), "Joined {date}" (subtitle, the locale's medium date), an `MxBadge` "Admin" (primary) or "User" (neutral) as trailing; no chevron (a badge or a chevron, never both). The signed-in admin's row reads "Joined {date} · You" and does not tap (U1); it is not dimmed. |
| More | The next page loads when the list reaches its end, as screen 28; the end reads "No more users"; a failed page is an inline danger banner with Retry (§6). |
| States | loading (`MxSkeletonList`); empty ("No users match {query}" or, with no query, "No accounts yet"); error (`MxErrorState` + Retry; offline says so first); not an admin (the gate's state). |

**Role sheet** (`MxBottomSheet`): the email as title; two `MxOptionRow`s,
"User" · "Studies and syncs their own decks" and "Admin" · "Sees logs and
manages roles", the current one selected; `MxSheetActions`: Cancel · "Save"
(primary), enabled only when the choice differs, spinning while it runs.

| Outcome | Shows |
|---|---|
| saved | the sheet closes, the row's badge changes in place, toast "{email} is now an admin" / "{email} is now a user" |
| `LastAdminFailure` | the sheet stays and says it inside, in a warning banner (a toast would sit behind the sheet; final review I2): "An admin must remain. Make someone else an admin first." |
| `AnonymousUserFailure` | toast "This account isn't signed in with an email or Google." |
| gone (null) | the sheet closes, toast "That account no longer exists.", the list reloads |
| `NotAdminFailure` | the sheet closes and the screen shows the gate's not-admin state |
| offline / server | the sheet stays, toast "No connection. Nothing changed." / "Couldn't change the role. Nothing changed." |

## 4. Settings (23)

The Admin section (U2): "ADMIN", then "Monitoring" · "Logs of the app and the
server" (unchanged), then "Users" · "Who can manage the app" with the people
glyph, opening 33. Hidden for everyone but an admin and in a build with no
Supabase, as today.

## 5. Verification

- Unit: the data source's JSON and errors, the mapper, the repository and use
  cases, `UsersController` (search debounce, paging, set, every refusal).
- Widget: screen 33 in every state of §3, the sheet's outcomes, the "You" row,
  screen 23's Admin section with two rows and without admin.
- Goldens (light and dark, English, this Linux container): 33 loaded, empty,
  error, the sheet, the admin section on 23; a golden-compare page before the
  owner is asked to merge. The Monitoring entry's goldens must not change
  beyond the added row.
- Impeccable: critique and `shape` before the plan, critique and audit of the
  goldens after the build (one fix batch).
- Docs: `33-users.md`, the screen index, 23's detail file, a new FE row in
  `docs/wbs_FE.md`.

## 6. Shape (Impeccable, 2026-09-30)

Critiqued against `DESIGN.md` and the goldens of 28 (`monitoring_list_*`,
`monitoring_level_sheet_*`) and the merge sheet (`merge_sheet_*`); approved by
the owner.

- **Screen 28 is the pattern**: the search field under the app bar, an
  overline over the list, rows with a leading tile and a trailing badge, pages
  that load at the end of the scroll and close on "No more …". 28 has no
  "Load more" button, so 33 has none (this replaces the first draft of §3).
- **Rows**: the person tile is the same for everyone (a scan anchor); the role
  lives in the badge alone, so it is not said twice. The "You" row is content,
  not a disabled control: full contrast, no tap.
- **Sheet**: the merge sheet's form (title, `MxOptionRow` × 2, `MxSheetActions`);
  its one fill is Save, disabled until the choice differs.
- **One Indigo Rule**: no primary fill on 33 itself; the sheet's Save is its
  one fill.
