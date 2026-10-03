# UI hardening SP5 — settings and account UX (23–33) and performance — design

Status: draft for owner approval ·
Path: architectural, sub-project SP5 of [the UI hardening spec](2026-10-03-ui-hardening-design.md) ·
Owner rulings: R1, R2, R4, R7, V1–V6 (that spec §3 and §7); owner rule: default text scale only

## 1. Intent

SP5 fixes the backlog rows 5.01–5.30 of §6.4 in the parent spec: the copy, tone, layout and
small behaviour findings of screens 23–33, and five performance findings. The data-safety rows
of the same screens (2.33–2.48) are SP2b's; SP5 builds on them and does not repeat them.

Where a row touches a file SP2b also changes (the reset dialog, the reminder banners, the sync
notice, the transition layer, the sign-in controller), SP5 lands after SP2b and keeps SP2b's
behaviour. Rows 5.03, 5.07, 5.08, 5.13, 5.16, 5.21 and 5.22 say which SP2b row they sit beside.

Success:

- every row below has a test that fails before its fix (copy rows: a widget test on the new
  text; behaviour rows: a controller or widget test);
- `dod_check.sh` is green; the Linux goldens are green;
- the owner approves the golden-compare page;
- the WBS row FE-D32 tells the truth.

Outcome of the 30 rows: 30 fixed (5.14 and 5.15 each carry a recorded part that is ruled out or
already done), 0 merged, 0 already fixed whole, 0 ruled out whole.

## 2. Owner rulings used here

- **R1.** Every finding is in scope, Minor included.
- **R2/R4** (SP1, done): the footer caption and the nav are settled; SP5 does not touch them.
- **R7.** The toast replacement rule stands. 5.14's "toast dropped on leaving" is not fixed by a
  toast queue.
- **DESIGN.md (SP1, 2026-10-03):** "Offline is never warning or danger" (line 377); "name the
  loss on a destructive confirm" (379); "no overline over a one-row group, unless it sets apart a
  destructive group" (391); a note says something new; a leading tile varies or goes.
- **V5, V6:** not used here (SP3/SP4).
- **Default text scale only:** no 2x or large-text tests, goldens or passes.

## 3. Design

### 3.1 Settings (23), Theme (25), Language (26)

| # | Fix | Where |
|---|---|---|
| 5.01 | A network failure no longer turns the Sync tile amber. `syncNeedsAttention` is true for a refused row or a failure of kind server, sign-in or unknown; a network failure leaves the tile tinted (as screen 27's neutral note). The sub-line "Couldn't sync · no connection" stays: it is a fact. | `sync_labels_widget.dart:57-58`, `settings_sync_section_widget.dart:33-37` |
| 5.02 | Overlines go from the one-row groups: the Account section and the Sync section lose their title (DESIGN.md). Reset keeps "Reset" (a destructive group). Sync moves up to follow Account, so the two cloud rows sit together: Account, Sync, Study defaults, App, Admin, Reset. The expired-sign-in banner still leads the Account row. | `settings_screen.dart:90-122`, `account_settings_section_widget.dart:60`, `settings_sync_section_widget.dart:30` |
| 5.03 | The page note under Reset goes. The row says what resets ("Theme, language, study defaults, reminder"); the reassurance that decks and progress stay is said once, in the dialog's shield note, at the decision. SP2b 2.33 owns the dialog's failure behaviour; SP5 does not touch the dialog. | `settings_screen.dart:109-112`, ARB `settingsResetNote` (removed) |
| 5.04 | One name, one gloss. The option is **System** everywhere; its gloss is **"Same as your phone"** (VI "Giống điện thoại"). Theme card hint "Match phone" becomes "Same as your phone"; Settings' Theme row reads "System" (was "Follows the system setting"); the Language option title "Follow the system" becomes "System" (VI "Hệ thống"). "Phone is set to {language}" and "System · {language}" stay. D7's card titles ("System", "Always light", "Always dark") stand. | ARB `settingsThemeSystemHint`, `settingsThemeFollowsSystem`, `settingsLanguageSystem`; `settings_app_section_widget.dart:257-260`, `language_screen.dart:152` |
| 5.05 | A tap on New-card order while a limit write runs is no longer dropped: it is queued and the last choice writes when the group is free, as the limit already does. The failure toast names the value that stands: "Couldn't save the new-card order. Still {order}." / "Không lưu được thứ tự thẻ mới. Vẫn là {order}." | `settings_controller.dart:86-101` (queue beside `_isCardLimitQueued`), `settings_screen.dart:161-162`, ARB `settingsOrderSaveFailed` |
| 5.10 | Theme drops its note "Applies at once…" (the page changes as you tap). Language keeps only the new fact: "Your cards stay in their own language." / "Thẻ của bạn vẫn giữ ngôn ngữ riêng." | `theme_screen.dart:91-98`, ARB `settingsAppliesAtOnce` (removed), `settingsLanguageNote` |
| 5.11 | A second theme tap during a theme write is queued; the last tap wins and writes next. (Language keeps its drop: its toast names the language written, and a queue would name the wrong one.) | `settings_controller.dart:103-112` |
| 5.12 | When the phone's language is one MemoX lacks and Language is "System", Settings' Language row says so: "Your phone's language isn't available · English" (the string screen 26 already has). The "supported phone language" check moves from `LanguageScreen._phoneLocale` to a helper in `settings/presentation/widgets/support/` that both screens call. | `settings_app_section_widget.dart:249-251,267-268`, `language_screen.dart:41-47` |

### 3.2 Daily reminder (24)

| # | Fix | Where |
|---|---|---|
| 5.06 | "What it says" shows only while the reminder is on and no problem banner is up. Off, or under a banner, the screen is the toggle, the time and the banner; the preview no longer reads as a pending notification. | `reminder_screen.dart:140-141` |
| 5.07 | The off-may-show banner is neutral (nothing is wrong, nothing lost) and its action is named: "Cancel today's reminder" / "Huỷ nhắc học hôm nay" (it cancels again and writes nothing). The message "Turned off. A reminder already scheduled for today may still appear once." stays. Sits beside SP2b 2.34-2.36 (other banners). | `reminder_banners_widget.dart:225-229`, ARB `reminderTryAgain` use, new `reminderCancelToday` |
| 5.08 | The Time button works while the reminder is off. `ChangeReminderTimeUseCase` already saves only the time when off (spec D17), so no domain change. The row's off hint changes to "Used when you turn the reminder on" / "Dùng khi bạn bật nhắc học". SP2b 2.35 (dialog validity) is unaffected. | `reminder_settings_section_widget.dart:293-311`, ARB `reminderTimeOffHint` |
| 5.09 | Back and the app-bar back are held while an operation runs (`PopScope(canPop: !action.isBusy)`), so leaving mid-permission-prompt cannot drop the outcome. The operations are short (prompt, schedule, save). | `reminder_screen.dart:64` |

### 3.3 Sync (27)

| # | Fix | Where |
|---|---|---|
| 5.13 | While rows are refused, the screen shows no "Sync now": the banner's "Try again" requeues the refused rows and runs a sync (`SyncCommands.retryRejected`), a superset of Sync now. One verb per state. With nothing refused the button stays as now. SP2b 2.37 adds the sign-in action to the failure notice; the two do not overlap. | `sync_screen.dart:82-97` |
| 5.14 | (a) The Keep dialog reads the refused count live (it is a `ConsumerWidget` on `syncStatusProvider`), so the title and the effect match what Keep forgets; if the count reaches 0 it closes with false. (b) "Today"/"Yesterday" follow the day: a feature-local `syncDayProvider` emits `dayClock.now()` then each `dayStarts()` event, and Settings and Sync read it instead of `dayClock.now()` at build. (c) *Ruled out:* the toast dropped by leaving mid-run. The outcome is not lost: it is on screen 23's Sync row and screen 27's status; holding Back for a network run would trap the person for a network timeout. | `sync_keep_dialog_widget.dart`, `sync_notice_widget.dart:247`, `sync_screen.dart:71`, `settings_screen.dart:104` |

### 3.4 Monitoring (28)

| # | Fix | Where |
|---|---|---|
| 5.15 | The chip edge and the selected state exist (SP1 §5.3-17, FE-D27: *already fixed* for `MxChipTrigger`). SP5 sets `isActive: chosen.isNotEmpty` on each chip and replaces the horizontal scroll with a `Wrap` (spacing control), so no chip is off-screen. | `monitoring_filter_bar_widget.dart:44-99` |
| 5.16 | A list that failed offline hides search and chips as a refused one does (they cannot help; Retry and "Open not sent" are the way on). Offline there is also drawn neutral: `MxEmptyState(neutral, offline glyph)` with Retry and a secondary "Open not sent", in the list and in the detail page, instead of the danger `MxErrorState`. Sits beside SP2b 2.38 (a failed refresh keeps its rows and filters). | `monitoring_server_tab_widget.dart:301-314`, `monitoring_server_list_widget.dart:110-128`, `monitoring_detail_screen.dart:140-146` |
| 5.17 | (a) A log opened from "Not sent" that is gone was sent: title "This log was sent" / body "It left this device after the list was drawn. Find it on the Server tab." (VI "Log này đã được gửi" / "Log đã rời khỏi máy này sau khi danh sách hiện ra. Xem nó ở tab Máy chủ."), neutral `MxEmptyState`; a server log keeps "This log is gone" / "It may have been cleaned up." (b) The triage note takes 500 characters: over it, an error line "Keep the note to 500 characters." / "Ghi chú tối đa 500 ký tự." and the confirm is off. (c) The device id is validated as the user id is (the app's device ids are uuids, `SyncStore.deviceId`): "That isn't a valid device ID." / "Mã thiết bị không hợp lệ." Sits beside SP2b 2.39. | `monitoring_detail_screen.dart:105-110`, `monitoring_status_sheet_widget.dart:63-70`, `monitoring_device_user_sheet_widget.dart:51-58`, ARB |

### 3.5 Welcome (29), Sign-in (30), Code (31)

| # | Fix | Where |
|---|---|---|
| 5.18 | The offline note moves into the footer, above the three buttons it explains (`MxNote` first in the footer column). The three benefit rows become parallel and one line each: "Keep your decks after a reinstall" / "Study on more than one phone" / "Study offline, sync later" (VI "Giữ bộ thẻ sau khi cài lại app" / "Học trên nhiều điện thoại" / "Học khi không có mạng, đồng bộ sau"). | `welcome_screen.dart:103-152` |
| 5.19 | The loss confirm names the loss: the button reads "Lose {n} changes and continue" (VI "Mất {n} thay đổi và tiếp tục"), a new `accountUnsentConfirm`, not a bare "Continue". Used by the sign-in form and the code form through `confirmUnsentLoss`. | `account_confirm_dialog_widget.dart:40-49` |
| 5.20 | When changes are unsent, the continue-without dialog leads with the loss that cannot be undone: title `accountUnsentTitle` ("Lose {n} changes?"), body = `accountUnsentBody` then `accountWithoutBody`, confirm = 5.19's label; the danger banner goes (the body says it). With nothing unsent it is unchanged. | `sign_in_screen.dart:110-124` |
| 5.21 | (a) A stopped layer keeps a title naming the step that stopped, over the banner: "Your changes weren't sent" / "Couldn't get your decks ready" / "Couldn't merge" / "Couldn't download your decks" / "Couldn't sign out" / "Couldn't delete your account" (6 ARB keys, VI "Chưa gửi được các thay đổi" / "Chưa chuẩn bị xong bộ thẻ" / "Không gộp được" / "Không tải được bộ thẻ" / "Không đăng xuất được" / "Không xoá được tài khoản"). (b) Cancel shows a busy state and ignores a second tap while `cancelSwitch`/`cancelSignOut` runs (`_LayerPage` becomes stateful). Applies on top of SP2b 2.43's stuck layout. | `account_transition_layer_widget.dart:69-81,202-219` |
| 5.22 | (a) The re-auth form says why the address is there: under the field, "The address you signed in with. A code is sent to it." / "Địa chỉ bạn đã đăng nhập. Mã sẽ được gửi tới địa chỉ này." (b) Editing the field clears an email problem (`SignInController.clearProblem`), so "Enter an email address…" no longer lingers after a fix. Sits beside SP2b 2.41-2.42. | `sign_in_form_widget.dart:137-170`, `sign_in_controller.dart` |
| 5.23 | (a) The code field shows its shape: a hint of six placeholder dots at the code's tracking (DECISION 3). (b) "Use another email" goes; Back does the same and screen 30 keeps the typed address. `onUseAnotherEmail` leaves `CodeFormWidget`, `CodeScreen` and the layer's code page. | `mx_text_field.dart:147,167`, `code_form_widget.dart:105-131`, `code_screen.dart:48-56`, `account_transition_layer_widget.dart:167-171` |

### 3.6 Account (32), Users (33)

| # | Fix | Where |
|---|---|---|
| 5.24 | The Account section loses its overline (one row, the screen is titled "Account"); Delete keeps "Delete" (a destructive group). The Validating note stops saying "needs a connection" (it is also shown while the check is merely running): "We're still checking your account. Switch, sign out and delete wait until that's done. Your decks are safe on this phone." (VI "Đang kiểm tra tài khoản. Đổi tài khoản, đăng xuất và xoá chờ xong việc này. Bộ thẻ vẫn an toàn trên điện thoại này."). | `account_screen.dart:88-104,122-124`, ARB `accountNeedsConnection` |
| 5.25 | (a) A hint note leads the list, saying both the tap and the own row: "Tap an account to change its role. You can't change your own." (VI "Chạm vào một tài khoản để đổi vai trò. Bạn không thể đổi vai trò của chính mình."); rows stay badge-only (no chevron beside a badge). (b) The role sheet is titled "Role for {email}" / "Vai trò của {email}". (c) Offline is neutral: `MxEmptyState(neutral, offline glyph)` with Retry, not the danger `MxErrorState`. Sits beside SP2b 2.48 (timeout, load more). | `users_list_widget.dart:52-77,139`, `user_role_sheet_widget.dart:153`, ARB |

### 3.7 Performance

| # | Fix | Where |
|---|---|---|
| 5.26 | Rows are built only in view. Decks: the rows become direct children of the `MxScreenScroll` list, 12 apart (no `Column`). Tags and search hits sit in one grouped card; they use the new lazy card (DECISION 1) over a `SliverList.builder`. Pixel parity is the proof: no golden moves. | `deck_level_list_widget.dart:138-160`, `tags_screen.dart:216-227`, `search_results_widget.dart:55-93` |
| 5.27 | The window doubles on each growth (50, 100, 200, 400…) instead of +50: the reads of the growing window fall from n/50 to log2(n). `// ponytail:` the stream still re-reads the whole window on a table change; a keyset window is the next step if a deck passes a few thousand cards. | `card_list_request_state.dart:97` (`windowSize * 2`), `cardListWindowStep` stays the first window |
| 5.28 | Startup runs its independent steps together after the logger: `readStartupSettings`, the Supabase chain (`initializeSupabase`, then `prepare`, then `showWelcomeIfDue`) and the reminder plugin `initialize` run in one `Future.wait`. The R3 order is kept: the write gate shuts in `prepare` before `syncSchedulerProvider` is read, and a reminder failure never blocks. The sequence moves to `lib/app/startup.dart` so it is testable. The plan records first-frame time before and after on the emulator. | `main.dart:26-60` |
| 5.29 | The Recall bar rebuilds its texts and semantics once a second, not at 60 Hz: the caption, seconds text and `Semantics` read a whole-second `ValueListenable` derived from the clock; only the track's fill sits in an `AnimatedBuilder` on the clock. Under Remove animations the fill still steps by whole seconds. | `study_recall_widget.dart:204-218`, `recall_countdown_bar_widget.dart` |
| 5.30 | Formatters are built once per pattern and locale, not per row: `dateFormatOf(pattern, locale)` and `numberFormatOf(pattern, locale)` (DECISION 2) in the three per-row builders: the user row, the monitoring log row, the card history event. Single-use formatters elsewhere stay. | `user_row_widget.dart:33`, `monitoring_labels_widget.dart:95-102`, `card_history_event_widget.dart:71,96,114` |

## 4. Shared code

- **DECISION (owner) 1, lazy grouped card (5.26).** Add `MxScreenScroll.slivers` and `MxCardSliver`
  (`lib/shared/widgets/`): the card's ground, ghost edge and light shadow painted by a
  `DecoratedSliver` around a `SliverList.builder`, the first and last rows' ink taking the card
  radius. Recommended: it is the one way to keep the grouped card and build only visible rows;
  decks need nothing shared. Alternative: cap the group and add "Show more" (changes the UX).
- **DECISION (owner) 2, formatter cache (5.30).** Add `lib/core/format/format_cache.dart` with
  `dateFormatOf` and `numberFormatOf`, a map keyed by pattern and locale. Recommended: about 15
  lines, safe because the cached formats are never mutated (no `add_Hm`). Alternative: each
  list builds its formats once and passes them down, which adds a parameter to every row.
- **DECISION (owner) 3, code field shape (5.23).** `MxTextFieldVariant.code` paints its hint in the
  code's letter spacing, and `CodeFormWidget` passes six dots. Recommended: one hint style, no new
  widget. Alternative: six separate slots, a custom input that must also carry autofill and
  paste.

Nothing else changes in `lib/core/` or `lib/shared/`. The offline states reuse `MxEmptyState`'s
neutral tone, and `MxChipTrigger.isActive` already exists.

## 5. Business-rule changes

| File | New wording (Vietnamese, as the doc) |
|---|---|
| `docs/features/settings/rules/BR-SETTINGS-007-moi-lan-luu-mot-transaction.md` | Thay câu "Lần gửi thứ hai khi lần đầu chưa xong MUST bị bỏ qua" bằng: "Lần gửi thứ hai khi lần đầu chưa xong MUST NOT mở transaction song song. Với theme và thứ tự thẻ mới, lựa chọn cuối cùng MUST được ghi ngay sau khi lần đầu xong; ngôn ngữ và reset vẫn bỏ qua lần gửi thứ hai." |
| `docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md` | A4 và dòng nghiệm thu "một lần ghi của một nhóm … lần bấm sau bị bỏ qua" (line 101): theme và thứ tự thẻ mới xếp hàng, lần chọn cuối được ghi sau; ngôn ngữ vẫn bỏ qua. |
| `docs/features/reminders/usecases/UC-REMINDER-001-bat-nhac-hoc-hang-ngay.md` | Main flow bước 1: giờ gợi ý "hiển thị ở trạng thái không hoạt động" thành "chọn được ngay cả khi nhắc đang tắt". A1: thêm "Khi nhắc đang tắt, xác nhận chỉ lưu giờ: không đặt lịch, không xin quyền; lần bật sau dùng giờ này." |

## 6. Testing

Each row gets a failing test first. Subsets run through `run_tests.sh` (`MEMOX_TEST_BUNDLES=2`).

| Cluster | Test files | Review Focus (not covered by any row's own test) |
|---|---|---|
| 3.1 Settings, Theme, Language | `settings_screen_test`, `settings_sync_section_test`, `sync_labels_test`, `settings_controller_test`, `theme_screen_test`, `language_screen_test`, a phone-locale helper test | Phone language French with Language "System" (row and screen 26 agree); Random tapped twice fast then In order during a limit write (last wins, no third write); Vietnamese strings of "System / Same as your phone"; Account hidden (no Supabase) leaves Sync first; expired sign-in banner above a section with no overline |
| 3.2 Reminder | `reminder_screen_test`, `reminder_controller_test`, `reminder_screen_golden_test` | Change the time while off, then turn on (uses the new time; permission asked then, not at the time change); turning off with a failed cancel (neutral banner, preview hidden, Time still usable); Back during the permission prompt; revoked permission (SP2b) with the preview hidden |
| 3.3 Sync | `sync_screen_test`, `sync_screen_golden_test`, a keep-dialog test | Count drops from 3 to 0 while the dialog is open; refused rows plus pending rows (no Sync now, Try again still sends both); the app open across midnight (Today becomes Yesterday without a tap); Back during Keep |
| 3.4 Monitoring | `monitoring_filters_test`, `monitoring_screen_test`, `monitoring_detail_screen_test`, `monitoring_not_sent_test` | A filter with all five chips set wraps to three lines; offline then Retry keeps the typed search text; a 500-character note with emoji (count in characters, not code units); a device id pasted with spaces or capitals |
| 3.5 Welcome, Sign-in, Code | `welcome_screen_test`, `account_confirm_dialog_test`, `sign_in_screen_test`, `code_screen_test`, `account_transition_layer_test` | Welcome offline then online (note leaves, buttons enable); one unsent change (singular) and 300 (plural); a wrong code then typing again keeps no stale error; Cancel tapped twice in the layer; Back from the code step returns to the typed address |
| 3.6 Account, Users | `account_screen_test`, `users_screen_test`, `users_golden_test` | A 40-character email in the role-sheet title (wraps, no overflow); the own row: no tap, no chevron, the note names it; Validating with the network up, then Ready |
| 3.7 Performance | `deck_level_screen_test`, tags and search screen tests, `card_list_request_state` test, `study_recall` tests, a startup test (`test/app/`), a format-cache test | 300 decks: only the visible rows build (count via a builder probe); tags search that empties and refills the lazy card; Recall: caption `Text` identity stable across 60 frames inside one second; startup with the reminder plugin throwing, and with Supabase absent; a locale switch gets its own cached format |

Performance claims are measured, not asserted: the plan records the before and after for 5.26
(frame build time of 300 decks), 5.27 (reads to reach 1,000 cards), 5.28 (`am start -W` on the
`memox_e2e` emulator) and 5.29 (rebuild count per second), in the PR.

## 7. Goldens

Default text scale only, regenerated in the Linux container; the golden-compare page goes to the
owner before the merge.

- **Move:** `settings_*` (all, Account then Sync order, no overlines, no Reset note),
  `settings_account_*`, `settings_theme_*` (hint, no note), `settings_language_*`,
  `settings_sync_*` (network tile tinted); `reminder_off_*`, `reminder_on_*`,
  `reminder_off_may_show_*`, `reminder_perm_denied_*` (preview hidden, neutral banner, time
  enabled off); `sync_rejected_*` (no Sync now); the monitoring screen and filter goldens (wrapped
  active chips, neutral offline); `welcome_ready_*`, `welcome_offline_*`; the sign-in, code and
  account goldens; the users goldens.
- **New:** reminder off with the time enabled; Monitoring filters active; Monitoring offline
  (neutral); Users offline and Users with the hint note; the layer stopped with its title (sign
  out); the continue-without dialog with unsent changes; the code field empty (six dots).
- **Must not move:** the deck, tags and search goldens (5.26 is a no-paint-change refactor).

## 8. Detail files and WBS

- Detail files (layout, states, rulings, copy): `23-settings.md` (order, overlines, no Reset
  note, wording), `24-daily-reminder.md` (preview rule, neutral banner, time off), `25-theme.md`,
  `26-language.md`, `27-sync.md`, `28-monitoring.md`, `29-welcome.md`, `30-sign-in.md`,
  `31-code.md`, `32-account.md`, `33-users.md`, and the state counts in `00-index.md`.
- `DESIGN.md`: no new rule (SP1 holds them). One line in MxTextField's entry for the code hint.
- `docs/wbs_FE.md`: row FE-D32, done when the gate, the Linux goldens and the owner's golden review
  pass (depends on FE-D29, the SP2b row).
- Business rules: §5.

## 9. Out of scope

- SP2b rows 2.33–2.48 (data safety on these screens).
- A server-side length check on the triage note (client cap only; the RPC is unchanged).
- Holding Back through a network sync (5.14c); a root-level toast announcer.
- A keyset window for the card list; virtualising the Library's lists beyond 5.26's three.
- Larger text scales; two-pane layouts; the launcher icon.

## Owner decisions (2026-10-03, `AskUserQuestion`)

- **Shared code:** all three approved — `MxScreenScroll.slivers` + `MxCardSliver`,
  `lib/core/format/format_cache.dart`, the code field's six-dot hint.
- **BR-SETTINGS-007:** unchanged — a second tap while the first write runs is still
  dropped; UC-SETTINGS-001 A4 stays. The row that proposed queueing is ruled out by the
  owner; keep only its non-BR parts (if any) and say so in the plan.

## Owner override on tone (2026-10-03, after SP2b)

A failure or refusal notice that asks the person to retry or wait, including "no connection", is
warning (DESIGN.md as amended). 5.01 is ruled out (the Sync tile keeps amber); 5.07 keeps its
warning tone; 5.16 and 5.25 draw offline with the warning tone. Three pre-existing neutral failure
notes move to warning in SP5: the screen 27 network-failure note, the offline note in the delete
account confirm (32) and the offline note on Welcome (29).
