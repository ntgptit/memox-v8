# Settings hub: regrouping the Settings area — design

Status: approved in conversation 2026-10-07, spec under owner review · Path: architectural · Owner rulings 2026-10-07 (§3)

## 1. Intent

The Settings tab (screen 23) has grown by accretion: six sections in the order the
features landed (Account, Study defaults, App, Sync, Admin, Reset), two wide controls
(the card-limit stepper and the new-card-order tray) and a toggle sitting in the page,
and ten sub-screens (24–33) hanging flat under `/settings`, each reached by its own
convention. On a 360×800 phone the tab is about two and a half screens long, and
Theme, Sync and Reset sit below the fold. The owner's words: "như một bãi rác".

This spec regroups the area as a **hub and group pages**:

- **Screen 23 "Settings"** becomes a hub that fits one screen: five groups of navigation
  rows and one action row, no wide control.
- **Screen 23a "Study defaults"** (new, `/settings/study`) holds the four study rows
  that were inline on the tab.
- **Screen 23b "Admin"** (new, `/settings/admin`, admins only) holds the three admin
  rows.
- The sub-screens 24–33 keep their paths, their content and their rulings.
- One written rule set says what a settings row is allowed to be (hub row, toggle,
  sheet, page), so the next setting lands in the right place without a debate.

Success means: the hub's loaded state fits a 360×800 phone in English and Vietnamese
at the default text scale; every setting is at most two taps from the tab; every
existing UC-SETTINGS-001 flow and every test of screens 24–33 still passes; the
rule set is in `DESIGN.md` and the three handoff files.

## 2. Context (2026-10-07)

- `SettingsScreen` (`lib/features/settings/presentation/screens/settings_screen.dart`)
  draws the sections in a fixed order from `MxScreenScroll`; `app/` composes two slots
  into it: `accountSection` (a whole `MxSection`, from `AccountSettingsSectionWidget`,
  with the re-auth banner above it) and `adminRows` (three row widgets:
  `MonitoringEntryRowWidget`, `UsersEntryRowWidget`, `SqlLogRowWidget`), shown only
  while `isAdminProvider` is true.
- `SettingsStudyDefaultsSectionWidget` holds the stepper, the tray, the read-aloud
  toggle and the speech language row; `SettingsAppSectionWidget` the Theme, Language and
  Daily reminder rows; `SettingsSyncSectionWidget` the Sync row (hidden when the sync
  status stream has no value, so also in a build without Supabase).
- `SettingsController` emits a `SettingsNotice` for the card limit, the order, the
  speech switch, the speech language and the reset; `SettingsScreen._say` turns it into
  the toasts.
- Routes (`lib/app/router/app_router.dart`): the Settings branch has the hub at
  `/settings` and, on the root navigator (no bottom bar), `theme`, `language`,
  `reminder`, `sync`, `sign-in`, `account`, `monitoring` (with a log child and a deep
  link), `users`. Monitoring and Users sit behind `MonitoringAdminGateWidget`.
- Screens 25 (Theme) and 26 (Language) are pages of their own by FE-A3 D2 (Theme has
  a live preview); 24 (Daily reminder) is a page with a toggle, a time dialog and a
  preview; 27 (Sync) a page with status and commands; 32 (Account) a page of commands.
- The hub's skeleton (`SettingsSkeletonWidget`) draws three section-shaped cards of
  2·3·2 rows.
- The visual system: `MxSection` (overline + card + an `MxNote.hint` note),
  `MxSettingsRow` (label, subtitle, lead tile, a chevron when `onTap` is set and no
  trailing control, `isAction` for a row that opens a dialog) — `DESIGN.md`,
  Components.

## 3. Decisions

| # | Decision | Owner |
|---|---|---|
| D1 | The Settings area is a **hub and group pages**: the tab lists groups; a group with more than one setting of its own, or with wide controls, gets a page. The owner chose this over "one page, regrouped" and over a hybrid with inline toggles on the hub. | Owner, 2026-10-07 |
| D2 | The hub's groups, in order: **Account & sync** (the account row, the Sync row), **Study** (one row → 23a), **App** (Theme, Language, Daily reminder, as today), **Admin** (one row → 23b, admins only), **Reset** (the action row). Theme, Language and Daily reminder stay one tap away; the owner declined folding them into an App page. | Owner, 2026-10-07 |
| D3 | **Screen 23a "Study defaults"** holds the four study rows in two sections, *Session* (Cards per session, New-card order) and *Speech* (Read the term aloud, Speech language), each with its own note, so the note no longer has to explain two timings in one sentence. | Design 2026-10-07, approved |
| D4 | **Screen 23b "Admin"** holds *Logs* (Monitoring, Log SQL statements) and *People* (Users). It sits behind the same admin gate as Monitoring and Users: a non-admin who deep-links to it sees the gate's refusal. | Design 2026-10-07, approved |
| D5 | **Leaf paths do not move.** `/settings/theme`, `/settings/language`, `/settings/reminder`, `/settings/sync`, `/settings/sign-in`, `/settings/account`, `/settings/monitoring` (and its log child), `/settings/users` stay as they are; only `/settings/study` and `/settings/admin` are added. Back returns to wherever the page was pushed from: Monitoring and Users to 23b when opened from it, to the hub from a deep link. | Design 2026-10-07, approved |
| D6 | **The settings pattern** is written once in `DESIGN.md` (§4 below) and applied by 23, 23a and 23b. Theme and Language keep their pages although they are a pick from three values, because they are built and Theme carries a preview; `DESIGN.md` records them as the exception. | Design 2026-10-07, approved |
| D7 | The account feature supplies **a row and a banner**, not a section: Settings draws the "Account & sync" section itself, with the Sync row after the account row, and puts the re-auth banner above the section's overline, as today. The slot in `app/` changes shape; the account feature's widgets are reused. | Design 2026-10-07, approved |
| D8 | The hub's Study row reads the stored defaults in one line: "{n} cards · {order} · Read aloud on" (or "off"). The speech language is not in the line: it belongs to the page, and the line stays two lines at most at 360dp in both languages. | Design 2026-10-07, approved |
| D9 | Toasts follow their rows: 23a listens to the controller's notices for the card limit, the order, the speech switch and the speech language; the hub listens to the reset's. The controller is unchanged. | Design 2026-10-07, approved |
| D10 | The new screens are numbered **23a** and **23b** in the screen index, as 16a sits under 16. | Design 2026-10-07, approved |
| D11 | The debug-only gallery icon stays in the hub's app bar; it is a build affordance, not a setting. | Design 2026-10-07, approved |

## 4. The settings pattern (for `DESIGN.md`, Components, after `MxSettingsRow`)

> **Settings pattern.** The Settings tab is a hub: `MxSection`s of navigation rows
> (label, the current value first in the subtitle, a chevron) and at most one action
> row (`isAction`, opens a dialog). No wide control and no toggle on the hub. A group
> with more than one setting of its own, or with a wide control, is a page under
> `/settings/<group>`, titled as its hub row, with a content-density app bar and Back;
> its rows sit in `MxSection`s with one note per section. On a page a setting is:
> a boolean → an `MxToggle` in the row; a pick from at most ten fixed values → a
> bottom sheet of `MxOptionRow`s opened by a value row; a value with its own state,
> feedback or preview (a number, a time, sync, the account) → a page of its own. Theme
> and Language predate the rule and keep their pages (FE-A3 D2). A row that opens a
> page or a sheet always names the current value in its subtitle.

## 5. Structure

### 5.1 Screen 23 "Settings" (the hub)

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | "Settings"; the gallery icon in debug builds (D11). |
| Account & sync | `MxSection` + `MxSettingsRow` × 2 | Title "Account & sync". The account row as the account feature draws it today (Sign in / disabled offline / the email → 32); then "Sync" with the status line and the status-toned tile (→ 27). The re-auth banner leads the section, above the overline (P3b ruling 1). Hidden whole in a build without Supabase (no account coordinator): the sync status stream has no value then either. |
| Study | `MxSection` + `MxSettingsRow` | Title "Study". "Study defaults" / "{n} cards · {order} · Read aloud on|off" (D8), library tile, → 23a. |
| App | `MxSection` + `MxSettingsRow` × 3 | Title "App". Theme, Language, Daily reminder, unchanged. |
| Admin | `MxSection` + `MxSettingsRow` | Title "Admin", only while `isAdminProvider` is true and a build has Supabase. "Admin tools" / "Monitoring, users, SQL log", `AppIcons.safe` (shield) tile, → 23b. |
| Reset | `MxSection` + `MxSettingsRow` (`isAction`) | Unchanged: "Reset app options" / "Theme, language, study defaults, read-aloud, reminder", the note, the dialog. |
| Loading | `SettingsSkeletonWidget` | Section-shaped cards of 2·1·3·1 rows (the hub's shape). |
| Read error | `MxErrorState` | Unchanged (UC E3). |
| Toasts | `MxSnackbar` | The reset's only: "App options reset to defaults"; "Couldn't reset the app options. Nothing changed." · Retry (D9). |

Height check at 360×800 (3 px = 1 dp): app bar 56 + 5 overlines + 8 rows of 72 (two
lines each) + the reset note ≈ 56 + 5·36 + 576 + 56 ≈ 870 with the signed-in account
row and the admin row; the hub scrolls by less than one row for an admin, and fits for
everyone else. The two-line subtitles ("{n} cards · In order · Read aloud on",
"a@example.com · Your decks sync to this account") are the longest lines; the plan
verifies both languages in the goldens.

### 5.2 Screen 23a "Study defaults" (`/settings/study`)

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content density) + Back | "Study defaults". |
| Session | `MxSection` + `MxSettingsRow` × 2, note | Title "Session". "Cards per session" / "1 to 200 · default 20" with the `MxStepper` (D6 of FE-A3, unchanged); "New-card order" / "How new cards enter a learning session" with the `MxSegmentedTray`. Note: "Apply to sessions started from now on. A deck with its own study options keeps them." (BR-SETTINGS-004). |
| Card limit message | `MxFieldMessage` | Unchanged (UC E1). |
| Speech | `MxSection` + `MxSettingsRow` × 2, note | Title "Speech". "Read the term aloud" / "When a new card comes up while learning" with the `MxToggle`; "Speech language" / "{language} · Used by decks that follow the defaults" with a chevron, opening the speech language sheet (study speech spec §6). Note: "Changes at once. A deck with its own speech language keeps it." (BR-STUDY-080, BR-SETTINGS-009). |
| Loading | `SettingsSkeletonWidget` | Two section-shaped cards of 2·2 rows. |
| Read error | `MxErrorState` | As the hub's (UC E3), retrying the same provider. |
| Toasts | `MxSnackbar` | "Saved"; "Couldn't save cards per session. Still {n}." · Retry; "Couldn't save the new-card order." · Retry; "Couldn't save the read-aloud switch." · Retry; "Couldn't save the speech language." · Retry (D9). |

The widgets move, they are not rewritten: `SettingsStudyDefaultsSectionWidget` splits
into the two sections above (its stepper, tray, toggle and language row keep their
code and tests); the `_say` mapping of the study notices moves from the hub to this
screen.

### 5.3 Screen 23b "Admin" (`/settings/admin`)

| Region | Widget | Design |
|---|---|---|
| Gate | `MonitoringAdminGateWidget(title: "Admin")` | A non-admin, or a deep link before the account is confirmed, sees the gate's wait or refusal, as Monitoring and Users do (ADR-018 §7). |
| App bar | `MxAppBar` (content density) + Back | "Admin". |
| Logs | `MxSection` + rows | Title "Logs". `MonitoringEntryRowWidget` ("Monitoring" / "Logs of the app and the server", → 28), `SqlLogRowWidget` ("Log SQL statements" with its toggle, unchanged). |
| People | `MxSection` + row | Title "People". `UsersEntryRowWidget` ("Users" / "Who can manage the app", → 33). |

`app/` composes the three row widgets into the page as it composes them into the hub
today (`adminSettingsRows` becomes the page's rows); the hub keeps only the "Admin
tools" row.

### 5.4 Routes

`AppRoutes` gains `settingsStudyChild = 'study'`, `settingsStudy`, `settingsAdminChild =
'admin'`, `settingsAdmin`. Both are children of the Settings branch on the root
navigator, like Theme. The hub's `onOpenStudyDefaults` and `onOpenAdmin` callbacks push
them; the Admin page's rows push Monitoring and Users as today. Nothing else in the
router changes (D5). `account_redirect.dart` is untouched.

## 6. Copy

New keys, English / Vietnamese:

| Key | en | vi |
|---|---|---|
| `settingsAccountSync` | Account & sync | Tài khoản & đồng bộ |
| `settingsStudySection` | Study | Học |
| `settingsStudyDefaultsSummary(count, order, isAutoPlay)` | {count} cards · {order} · Read aloud on / off | {count} thẻ · {order} · Đọc to bật / tắt |
| `settingsSessionSection` | Session | Phiên học |
| `settingsSessionNote` | Apply to sessions started from now on. A deck with its own study options keeps them. | Áp dụng cho các phiên bắt đầu từ bây giờ. Bộ thẻ có tuỳ chọn học riêng vẫn giữ tuỳ chọn đó. |
| `settingsSpeechSection` | Speech | Đọc to |
| `settingsSpeechNote` | Changes at once. A deck with its own speech language keeps it. | Đổi ngay. Bộ thẻ có ngôn ngữ đọc riêng vẫn giữ ngôn ngữ đó. |
| `settingsAdminTools` | Admin tools | Công cụ quản trị |
| `settingsAdminToolsHint` | Monitoring, users, SQL log | Giám sát, người dùng, log SQL |
| `settingsAdminLogs` | Logs | Nhật ký |
| `settingsAdminPeople` | People | Người dùng |

`settingsStudyDefaultsNote` is removed (its two halves are the section notes above).
`settingsStudyDefaults` ("Study defaults") titles the hub row and 23a; `settingsAdmin`
("Admin") titles 23b; `settingsSync` keeps its row. `order` is `settingsOrderCreated` /
`settingsOrderRandom` as rendered.

## 7. Behaviour unchanged

Saving on change, the 600 ms settle of the card limit, the one-transaction rule
(BR-SETTINGS-007), the validation message (E1), the save-failed toasts with Retry
(E2), the read error (E3), the reset dialog and its copy (BR-SETTINGS-008), the theme
and language pages, the reminder page, the sync page, the account pages, the admin gate
and every BR. No schema, repository, use case or provider changes.

## 8. Tests

- **Widget, hub:** every section in the right order with the stored values in the
  subtitles; the Study row's summary for on/off and both orders; Account & sync hidden
  without a coordinator; the Admin row only for an admin; the reset flow and its toasts
  (moved from `settings_screen_test.dart` where they are today); loading skeleton;
  read error with Retry.
- **Widget, 23a:** the stepper, tray, toggle and language-sheet flows and their toasts
  (moved from `settings_screen_test.dart`, same assertions); the two notes.
- **Widget, 23b:** the three rows for an admin; the gate's refusal for a non-admin.
- **Routes (`test/app`):** the hub's Study row opens 23a and Back returns; the Admin row
  opens 23b; Monitoring and Users open from 23b and Back returns to 23b; deep links to
  `/settings/study`, `/settings/admin`, `/settings/monitoring`, `/settings/users` still
  land; `account_routes_test.dart` and `settings_routes_test.dart` adjusted to the new
  path to Users and to the shorter hub (no scroll past the bottom bar needed).
- **Goldens:** hub `settings_{loaded,loading,account,account_signed_in,account_reauth,admin_row,sync_synced,sync_failed,sync_rejected,reset_confirm,reset_done}_{light,dark}`; 23a `study_defaults_{loaded,saving,saved,invalid_limit,save_failed,speech_language_sheet}_{light,dark}`; 23b `admin_{light,dark}`. The old `settings_{saving,saved,invalid_limit,save_failed,speech_language_sheet,admin_rows}` goldens are deleted, since those states move to 23a and 23b. Screens 24–33 goldens unchanged. A golden-compare page goes to the owner before merge.
- **Visual audit:** `settings_screen_visual_audit_test.dart` keeps the hub; new audits for 23a and 23b.
- The gate (`dod_check.sh`) and `run_goldens.sh` in the container.

## 9. Documents

- `DESIGN.md`: the settings pattern of §4 after `MxSettingsRow` in Components.
- `docs/shared/ui/screen-handoff/23-settings.md` rewritten for the hub; new
  `23a-study-defaults.md` and `23b-admin.md`; `00-index.md` rows for 23, 23a, 23b;
  `docs/shared/ui/navigation.md`'s Settings paragraph names the two group pages.
- `docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md` step 1 and
  the UI section: the tab is a hub; the study defaults are on the Study defaults page;
  the acceptance criterion about "ba nhóm" names the hub's groups.
- `docs/features/settings/README.md` screen table: 23a added.
- The handoff files of 24, 25, 26, 27, 28, 32, 33: no change to their content; their
  "Entry points" line names the hub or 23b where it named screen 23's section.

## 10. Plans

One plan, tasks in this order so the app builds after each: routes and the two new
screens as shells; the Study defaults page (moved sections, notes, notices) and the
hub's Study row; the hub's Account & sync section and the slot change; the Admin page
and the hub's Admin row; skeletons, copy and the remaining hub states; tests and
goldens; docs and `DESIGN.md`.

## 11. Out of scope

- Redesigning screens 24–33, or turning Theme and Language into sheets.
- An About, Help or Feedback group; nothing in the app needs one today.
- Moving leaf paths under their group (`/settings/admin/monitoring`): the monitoring
  deep link and the notification tap would have to change for no user-visible gain.
- Changing how any setting is saved or synced.

## 12. Risks and rollback

- **Risk:** the hub still overflows for an admin with a signed-in account (§5.1
  estimate ≈ 870dp). Accepted: the owner is the only admin; the hub fits for everyone
  else, and the goldens show the exact height.
- **Risk:** a deep link to Monitoring now returns to the hub, not to 23b. Accepted (D5);
  recorded in 23b's handoff.
- **Risk:** the many moved tests and goldens hide a regression in a flow that did not
  change. Mitigation: the moved tests keep their assertions; the golden-compare page
  shows screens 24–33 unchanged.
- **Rollback:** revert the PR. No data, schema or sync change is involved.
