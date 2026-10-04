<!-- Hand-written screen record. -->

# 33 · Users (admin)

An admin finds any signed-in account by email and makes it an admin or a user. FE-B11;
auth spec O9; spec
[2026-09-30-users-admin-design.md](../../../superpowers/specs/2026-09-30-users-admin-design.md).

## Entry points

- Screen 23, Admin section, row "Users" · "Who can manage the app" (shown only to an admin).
  Route `/settings/users`, on the root navigator; Back returns to 23.
- A deep link meets the admin gate: a non-admin sees "Only an admin can see this" under
  the app bar "Users" (P4 plan ruling 2).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content) + back | "Users". |
| Search | `MxSearchField` | "Search by email"; asks 400 ms after the last keystroke, and not at all when only spaces changed (P4 minor M5); hidden on the not-admin state. |
| Overline | `MxListSectionHeader` | "ACCOUNTS" (no count: `role_list` has no total). |
| Rows | `MxListRow` | Person tile (tinted, the same for all), the email, "Joined {date}" (locale medium date), `MxBadge` "Admin" (primary) or "User" (neutral); no chevron. The admin's own row reads "Joined {date} · You" and does not tap (U1); not dimmed. |
| End | as screen 28 | The next page loads near the end; "No more users"; a failed page is a danger `MxInlineBanner` with Retry; a page refused as not an admin turns the screen to the not-admin state (final review I1). |

**Role sheet** (`MxBottomSheet`, the merge sheet's form): the email as title; `MxOptionRow`s
"User" · "Studies and syncs their own decks" and "Admin" · "Sees logs and manages roles", the
current role selected; Cancel · "Save" (primary), enabled only when the choice differs and
spinning while it runs. While it runs the sheet is held: Back, a scrim tap and a drag wait,
so the answer always has a sheet to be said in (P4 minor M3). A save lands over any list
still loading, and "not an admin" over any page in flight (P4 minors M1, M2).

| Outcome | Shows |
|---|---|
| saved | the sheet closes, the badge changes in place, toast "{email} is now an admin" / "… a user" |
| last admin | the sheet stays and says, in a warning `MxInlineBanner` under the options, "An admin must remain. Make someone else an admin first." (final review I2: a toast would sit behind the sheet) |
| anonymous | the sheet stays, banner "This account isn't signed in with an email or Google." |
| gone | the sheet closes, toast "That account no longer exists.", the list reloads |
| not an admin | the sheet closes, the screen shows the not-admin state |
| offline / other | the sheet stays, banner "No connection. Nothing changed." / "Couldn't change the role. Nothing changed."; a new choice clears it |

## States

The images are the goldens.

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| loaded | ![](../../../../test/features/account/presentation/goldens/users_loaded_light.png) | ![](../../../../test/features/account/presentation/goldens/users_loaded_dark.png) | Five accounts, the admin's own row with You. Golden `users_loaded_*`. |
| no match | ![](../../../../test/features/account/presentation/goldens/users_empty_search_light.png) | ![](../../../../test/features/account/presentation/goldens/users_empty_search_dark.png) |  Golden `users_empty_search_*`. |
| offline | ![](../../../../test/features/account/presentation/goldens/users_offline_light.png) | ![](../../../../test/features/account/presentation/goldens/users_offline_dark.png) |  Golden `users_offline_*`. |
| role sheet | ![](../../../../test/features/account/presentation/goldens/users_role_sheet_light.png) | ![](../../../../test/features/account/presentation/goldens/users_role_sheet_dark.png) | The current role selected; Save disabled. Golden `users_role_sheet_*`. |
| role sheet, changed | ![](../../../../test/features/account/presentation/goldens/users_role_sheet_changed_light.png) | ![](../../../../test/features/account/presentation/goldens/users_role_sheet_changed_dark.png) | Admin chosen; Save enabled. Golden `users_role_sheet_changed_*`. |
| role sheet, refused | ![](../../../../test/features/account/presentation/goldens/users_role_sheet_refused_light.png) | ![](../../../../test/features/account/presentation/goldens/users_role_sheet_refused_dark.png) | LAST_ADMIN said inside the sheet. Golden `users_role_sheet_refused_*`. |
| loading | — | — | `MxSkeletonList`. |
| no accounts | — | — | "No accounts yet". |
| error | — | — | "Couldn't load users" + Retry. |
| not an admin | — | — | the lock empty state, no search. |

## Rulings

- **U1–U5** (spec §1): the own row is read-only; Settings owns the Admin section; the slice
  lives in `features/account`; the data source follows Monitoring's; the route sits behind
  the admin gate.
- **Spec §6 (shape):** screen 28 is the pattern: pages load at the end of the scroll, no
  "Load more" button; the role lives in the badge alone.
- **P4 plan rulings 1–6:** errors through core's `classifyAuthError`; the gate takes a
  title; dates with `DateFormat.yMMMd`; the sheet runs the change; `isAdminProvider` gates
  the Admin section; the `users` icon.

## Copy

- "Users" · "Search by email" · "ACCOUNTS" · "Joined {date}" · "Joined {date} · You" · "Admin" ·
  "User" · "No more users" · "No users match “{query}”" · "No accounts yet".
- The sheet's and the toasts' copy is in the tables above.
