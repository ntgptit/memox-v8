<!-- Hand-written screen record. -->

# 23 · Settings

The Settings tab, a hub (settings hub spec 2026-10-07, D1): five groups of rows that
name their value and open their page, and one action row. The study rows live on
[23a Study options](23a-study-defaults.md), the admin rows on [23b Admin](23b-admin.md);
Theme, Language, Daily reminder, Sync and the account keep their pages. UC-SETTINGS-001;
specs [2026-09-26-settings-ui-design.md](../../../superpowers/specs/2026-09-26-settings-ui-design.md)
§5.2 (the rows' behaviour) and
[2026-10-07-settings-hub-design.md](../../../superpowers/specs/2026-10-07-settings-hub-design.md)
§5.1 (the hub).

## Entry points

- **The Settings tab** of the bottom bar, `/settings`.
- **Debug builds only:** the app bar's gallery icon opens the component gallery (D11).

Every row opens its page on the root navigator, with no bottom bar (FE-A3 D2): 23a
(`/settings/study`), 25, 26, 24, 27, 30/32, 23b (`/settings/admin`). Back returns here.

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | "Settings"; the gallery icon in debug builds. |
| Account & sync | `MxSection` + `MxSettingsRow` × 2 | "Account & sync" (D2, D7). The account row as the account feature draws it (FE-B9, FE-B10): an anonymous device gets "Sign in" / "Keep your decks if you reinstall or change phones" with the person tile, opening screen 30; while the account cannot link yet (offline) the row is disabled with "Available when you're online"; an attached account shows its email / "Your decks sync to this account" with a chevron to screen 32. Then "Sync" (SB-U1) with the cloud-sync tile toned by state and its sub-line, the first that applies of "{n} changes weren't accepted", "Couldn't sync · no connection" (or "· couldn't sign in", "· server error", "· something went wrong"), "Synced {Today, 14:32}", "Not synced yet" (sync status spec §5.1), opening screen 27. An expired sign-in puts a warning `MxInlineBanner` above the overline: "Your sign-in expired. Your decks are still on this phone." · "Sign in" → 30 `reauth` (account UI spec §5.5; P3b plan ruling 1). `app/` composes the row and the banner as slots and passes none in a build without Supabase, where the Sync row has no status either, so the section is hidden whole. |
| Study | `MxSection` + `MxSettingsRow` | "Study". "Study options" / "{n} cards · {order} · Read aloud on\|off", "1 card" for one (D8), library tile, opens 23a. |
| App | `MxSection` + `MxSettingsRow` × 3 | "App". "Theme" with the choice ("Follows the system setting", "Light" or "Dark"); "Language" with "System · {language}", "English" or "Tiếng Việt"; "Daily reminder" with "Off" or "On · {HH:mm}" (FE-B5). Each opens its page. |
| Admin | `MxSection` + `MxSettingsRow` | "Admin", only while the session's account is an admin (users spec U2, ADR-018 §7). "Admin tools" / "Monitoring, users, SQL log" with the shield tile (`AppIcons.safe`), opens 23b (D4). |
| Reset | `MxSection` + `MxSettingsRow` (`isAction`: it opens a dialog, so no chevron; critique 2026-09-30 part 1) | "Reset app options" / "Theme, language, study options, read-aloud, reminder". The note: "Only these app options return to their defaults. Decks, cards, per-deck study options and learning progress are not touched." |
| Reset dialog | `MxDialog` + `MxNote` + `MxSheetActions.custom` | "Reset app options?", "Theme, language, cards per session, new-card order, read-aloud settings and the daily reminder (off, 20:00) go back to their defaults.", the shield note "Your decks, cards, schedules and study history stay exactly as they are. This is not “Reset learning progress”.", then Cancel (outline) · "Reset" (primary, spinning while it runs), 1 : 1 (DEV-179), stacked when a label cannot fit (UI-base row 118). Back and Cancel do nothing while it runs. |
| Toasts | `MxSnackbar` | The reset's only (D9): "App options reset to defaults"; "Couldn't reset the app options. Nothing changed." · Retry. |

At 360×800 the tab shows ≈696 dp between the bars. Without an account the hub fits; with
a signed-in account and Sync it is ≈774 dp (about one row of scroll), ≈885 dp for an
admin; only Reset falls below the fold (spec §5.1, measured on the goldens).

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| loaded | `settings_loaded_light.png` | `settings_loaded_dark.png` | Study, App and Reset (no account in the test); Theme opens 25 (D2); the Daily reminder row reads "Off" or "On · {HH:mm}" and opens 24 (FE-B5). |
| loading | `settings_loading_light.png` | `settings_loading_dark.png` | Section-shaped skeleton cards of `MxSkeletonRow`s: 2·1·3·1 rows, or 1·3·1 when `app/` composes no account, as in the golden (UI-base row 125, part 3d-2). |
| admin row | `settings_admin_row_light.png` | `settings_admin_row_dark.png` | The Admin group with its one row, for an admin. |
| resetConfirm | `settings_reset_confirm_light.png` | `settings_reset_confirm_dark.png` | — |
| resetDone | `settings_reset_done_light.png` | `settings_reset_done_dark.png` | — |
| syncSynced | ![](../../../../test/features/settings/presentation/goldens/settings_sync_synced_light.png) | ![](../../../../test/features/settings/presentation/goldens/settings_sync_synced_dark.png) | (SB-U1) the Sync row after a success, in Account & sync. |
| syncFailed | ![](../../../../test/features/settings/presentation/goldens/settings_sync_failed_light.png) | ![](../../../../test/features/settings/presentation/goldens/settings_sync_failed_dark.png) | (SB-U1) the Sync row after a failed run. |
| syncRejected | ![](../../../../test/features/settings/presentation/goldens/settings_sync_rejected_light.png) | ![](../../../../test/features/settings/presentation/goldens/settings_sync_rejected_dark.png) | (SB-U1) the Sync row with refused rows. |
| account | ![](../../../../test/features/account/presentation/goldens/settings_account_light.png) | ![](../../../../test/features/account/presentation/goldens/settings_account_dark.png) | Golden `settings_account_*` (in the account tests): the Account & sync section first, anonymous. |
| account, signed in | ![](../../../../test/features/account/presentation/goldens/settings_account_signed_in_light.png) | ![](../../../../test/features/account/presentation/goldens/settings_account_signed_in_dark.png) | (FE-B10) the account row and its chevron. |
| account, re-auth | ![](../../../../test/features/account/presentation/goldens/settings_account_reauth_light.png) | ![](../../../../test/features/account/presentation/goldens/settings_account_reauth_dark.png) | (FE-B10) the banner leads the section. |
| read error | — | — | (UC E3) `MxErrorState` "Couldn't open Settings" with the local-first body and Retry; no value is shown. |

Goldens: `test/features/settings/presentation/goldens/settings_{loaded,loading,admin_row,reset_confirm,reset_done,sync_synced,sync_failed,sync_rejected}_{light,dark}.png`.

## Rulings

- **Settings hub spec 2026-10-07, D1–D11:** the tab is a hub of navigation rows; the study rows are on 23a and the admin rows on 23b; the account feature supplies a row and a banner, not a section; leaf paths do not move; the pattern is in `DESIGN.md`, Components, "Settings pattern".
- **D2 (owner), UI-base row 124:** Theme is a row naming the choice and opens screen 25.
- **UI-base row 125, UC E3:** loading is section-shaped skeleton cards (part 3d-2); a read error is `MxErrorState` with Retry.
- **ADR-015, SB-U1 (owner rulings R1, R5):** the Sync row opens screen 27.
- **Account UI spec §5.5, R2, P3b plan ruling 1:** the attached account opens screen 32; an expired sign-in's banner leads the Account & sync section, since 23 owns the problem.
- **ADR-018 §8, monitoring spec §3.1, users spec U2:** the admin rows show only while the account is an admin; on the hub as one row to 23b.
- **Critique 2026-09-30 tone pass, T4; part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-design.md`):** the Sync row's tile is success when sync is settled; warning when the last run failed or a change was refused; tinted otherwise (D5).
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** loading shows section-shaped skeleton cards of `MxSkeletonRow`s, not a generic list.

## Copy

- Groups: "Account & sync" · "Study" · "Study options" · "1 card" / "{count} cards · {order} · Read aloud on" / "… off" · "App" · "Admin" · "Admin tools" · "Monitoring, users, SQL log" · "Reset".
- App: "App" · "Theme" · "Follows the system setting" · "Light" · "Dark" · "Language" · "System · {language}" · "English" · "Tiếng Việt" · "Daily reminder" · "Off" · "On · {time}".
- Reset: "Reset" · "Reset app options" · "Theme, language, study options, read-aloud, reminder" · "Only these app options return to their defaults. Decks, cards, per-deck study options and learning progress are not touched." · "Reset app options?" · "Theme, language, cards per session, new-card order, read-aloud settings and the daily reminder (off, 20:00) go back to their defaults." · "Your decks, cards, schedules and study history stay exactly as they are. This is not “Reset learning progress”." · "Cancel" · "Reset".
- Sync (SB-U1): "Sync" · "{n} changes weren't accepted" · "Couldn't sync · no connection" · "Couldn't sync · couldn't sign in" · "Couldn't sync · server error" · "Couldn't sync · something went wrong" · "Synced {time}" · "Not synced yet"; times "Today, {HH:mm}" · "Yesterday, {HH:mm}" · "{MMM d}, {HH:mm}".
- Admin: "Admin" · "Admin tools" · "Monitoring, users, SQL log" (the rows themselves are on 23b).
- Toasts: "App options reset to defaults" · "Couldn't reset the app options. Nothing changed." · "Retry" (the study rows' toasts are 23a's).
- Error: "Couldn't open Settings" · "Nothing was lost. Try again in a moment." · "Retry".
