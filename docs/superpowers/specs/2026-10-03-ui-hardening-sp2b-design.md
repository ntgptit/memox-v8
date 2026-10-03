# UI hardening SP2b — data safety and dead ends in dialogs, settings, sync and account — design

Status: draft for owner approval ·
Path: architectural, sub-project SP2b of [the UI hardening spec](2026-10-03-ui-hardening-design.md) ·
Owner rulings: R8, R10, R11 (that spec §3) and the "approval mode" call (§7)

## 1. Intent

SP2b fixes backlog items 2.26–2.48 of §6.1 in the parent spec, for screens 01, 02, 03, 05, 06, 23, 24, 27, 28 and 29–33.
Each item loses typed content or work, strands a flow, shows a false state, or acts on the wrong thing.
The visible design does not change except for the banners, dialogs and toasts named below. They follow DESIGN.md:

- a failure says first that nothing was lost (warning = refusal or limit, nothing lost);
- a note says something new; a failure notice, offline included, keeps its warning (owner 2026-10-03, was "offline is neutral");
- a destructive confirm names the loss.

Success:

- every item has a test that fails before its fix;
- `dod_check.sh` is green and the Linux goldens are green;
- the owner approves the golden-compare page;
- the WBS row FE-D29 (added with the plan, status "xong" at the end) tells the truth.

Per the approval mode (§7 of the parent), this spec and its plan are presented together for one approval.
No V1–V6 call touches SP2b.

Accounting of the 23 rows: **21 fixed, 2 merged** (2.36 into 2.34; 2.44 into 2.41), **0 already fixed, 0 ruled out**.
Two partial notes follow. In 2.26, the tag dialogs of screen 05 return a request and the screen writes, so nothing there needs a hold. The trash purge and Settings reset dialogs already hold through their own `PopScope`; they are left alone.

## 2. Owner rulings used here

- **R8.** SP2 is two PRs; this is the second (2.26–2.48).
- **R10.** "The Trash purge clock is the earlier of the device clock and the server time seen at the last sync; nothing is swept as expired without a recorded server time." (2.30) A manual purge without a server time deletes only the batches the person selected.
- **R11 (V7).** "A stuck account layer offers 'Close MemoX' beside Retry. No data changes." (2.43) Owner ruling at the final fix: the copy no longer promises a resume; it says the move cannot finish on this phone, the decks are kept, and the way out is to close the app and report the problem.
- **R7** (a new toast replaces the one on screen) still holds. Toasts below are built to be read once; anything the person must act on is a banner.
- **Failure-in-dialog pattern** (this spec's refinement of 2.27). A database `Failure` inside a dialog or sheet shows an `MxInlineBanner` (warning, `l10n.failure(f)`, no title) inside it.
  - The confirm button stays enabled and is the retry, so the dialog keeps its confirm step.
  - A typed `Rejected` that closes the dialog keeps its toast (ruling P2-L10), since the dialog is gone and the toast is visible.

## 3. Design

### 3.1 Deck dialogs and sheets (screens 01, 02, 05)

| # | Fix | Where |
|---|---|---|
| 2.26 | Pass `isHeld` to `MxDialog` while the write runs (the same wiring as `card_delete_dialog_widget.dart:120`). Back and a scrim tap then wait, so the toast and the pop always arrive. Covers delete, rename and create-sub-deck (`DeckNameDialog`), create-root and reset. In create-root `_leave()` returns at once while `_isSubmitting`, so the discard dialog cannot open over a write. The sibling writing sheets (deck move 01, card move 07, Trash restore 06) pass the new `MxDeckPickerSheet.isHeld` (DECISION 1). Card tag dialog (07) gets `isHeld: _isSubmitting`. 05: the tag rename and delete dialogs return a request, so no change. | `deck_delete_dialog_widget.dart:62,107`, `deck_name_dialog_widget.dart:124`, `create_root_deck_dialog_widget.dart:66,106`, `deck_reset_dialog_widget.dart:58,113`, `deck_move_sheet_widget.dart:50`, `card_move_sheet_widget.dart:67`, `trash_restore_sheet_widget.dart:66`, `card_tag_dialog_widget.dart:124` |
| 2.27 | In each of these, `on Failure` sets `Failure? _failure` (cleared at the next submit) instead of calling `showMxSnackbar`. The dialog renders the warning banner at the top of its `content`: delete, rename/sub-deck, create-root, reset, card tag. The sheets (deck move, card move, Trash restore) pass it as `MxDeckPickerSheet.banner` (DECISION 1). The Trash purge dialog does the same, so a failed purge keeps the dialog with the banner and Delete as retry (06). | `deck_delete_dialog_widget.dart:81`, `deck_name_dialog_widget.dart:114`, `create_root_deck_dialog_widget.dart:96`, `deck_reset_dialog_widget.dart:77`, `deck_move_sheet_widget.dart:65`, `card_move_sheet_widget.dart:101`, `trash_restore_sheet_widget.dart:108`, `trash_purge_dialog_widget.dart:72` |
| 2.28 | When the reset summary read throws (`AsyncError`), the body is empty and `content` leads with a warning banner `l10n.failure(error)` plus a compact Retry. Retry calls `ref.invalidate(resetLearningSummaryProvider(id))`. A typed `Rejected` (deck gone) has no retry: it keeps its message and the confirm stays off. Cancel stays live, so the dialog is never a dead end. | `deck_reset_dialog_widget.dart:96-112,120` |

### 3.2 Starter sheet (screen 03)

| # | Fix | Where |
|---|---|---|
| 2.29 | `add()` catches `on Object catch (error, stack)`. A non-`Failure` is reported with `FlutterError.reportError` (library 'starter add'), as the import-undo dialog does. Both kinds set `hasFailed: true` and clear `isAdding`. The sheet then reads "Try again" and Back is released. | `starter_add_controller.dart:43-46` |

### 3.3 Trash (screen 06)

| # | Fix | Where |
|---|---|---|
| 2.30 | **R10 (owner ruling: the min clock).** `trashPurgeClock(now, serverTime)` is the earlier of the device clock and the server time seen at the last sync; null when this device never synced. `PurgeExpiredTrashUseCase` takes a `ServerTimeReader` (`typedef Future<DateTime?> Function()`, trash domain) and sweeps by that clock: with no server time it returns an empty `PurgeReport` and deletes nothing, and a device clock set ahead never expires a batch before the server's time does. Manual `purge(batchIds)` always deletes the chosen batches; the expired batches that ride along are swept by the same clock, so without a server time only the selected batches go. **Server time source (DECISION 3):** `sync_changes` returns `serverTime` (epoch ms of `now()`); the pull loop stores the last page's value in `sync_state` (`server_time`) through `SyncStore.recordServerTime`, which never moves it backwards, and `SyncStore.serverTime()` is the reader (a read error is a `Failure`). **Write side:** `insertDeleteBatch` stamps `deleted_at` with the later of the device clock and the stored server time, so a clock set back cannot make a fresh batch look old. **Trash row (final fix 4):** a row whose device-clock expiry has passed while the purge clock's has not reads "Removed after the next sync" in warning ink (owner 2026-10-03; first neutral). | `trash_entry_entity.dart`, `purge_expired_trash_use_case.dart`, `purge_trash_use_case.dart`, `purge_expired_trash_use_case_provider.dart`, `sync_coordinator.dart`, `sync_store.dart`, `sync_keys.dart`, `sync_models.dart`, `delete_batch_queries.drift`, `trash_labels_widget.dart`, migration `20261011000000_sync_server_time.sql` |
| 2.31 | After `purge`, when `report.blocked` is not empty the dialog's toast names what was kept. The notes come from `trashBlockedNotes(l10n, blocked, entries)`, moved out of `trash_screen.dart:280` into `trash_labels_widget.dart`. The entries come from `trashEntriesProvider`. One blocked deck uses `trashPurgeBlocked` (name and blocker). Several use `trashPurgeKeptMany(n)`. If something also purged, `trashPurgedWithKept(purged, kept)` joins them. The toast uses `bulkToastDuration(hasNews: true)`. The screen's banner stays. `report.missing` needs no toast: the rows are already gone. | `trash_purge_dialog_widget.dart:55-71`, `trash_screen.dart:280-298`, `trash_labels_widget.dart` |
| 2.32 | The confirm body names what goes. One deck: `trashPurgeDeckBody(deck, subDeckCount, cardCount)`, from `TrashDeckEntry`. Several decks: `trashPurgeDecksTotalBody(count, subDecks, cards)`, with sums. Cards keep `trashPurgeBody`. | `trash_purge_dialog_widget.dart:91` |

Copy (EN · VI):

- `trashPurgeDeckBody`: "“{deck}”, with {subDeckCount, plural, =1{1 sub-deck} other{{subDeckCount} sub-decks}} and {cardCount, plural, =1{1 card} other{{cardCount} cards}}, disappears for good, together with its study history. This cannot be undone." · "“{deck}”, cùng {subDeckCount} bộ thẻ con và {cardCount} thẻ, biến mất hẳn, cùng lịch sử học. Không thể hoàn tác."
- `trashPurgeDecksTotalBody`: "{count} decks, with {subDecks} sub-decks and {cards} cards, disappear for good, together with their study history. This cannot be undone." · "{count} bộ thẻ, cùng {subDecks} bộ thẻ con và {cards} thẻ, biến mất hẳn, cùng lịch sử học. Không thể hoàn tác."
- `trashPurgeKeptMany`: "{count} decks were kept: they still hold entries deleted earlier. The notes above the list say which." · "{count} bộ thẻ được giữ lại vì còn chứa mục đã xoá trước đó. Các ghi chú phía trên danh sách nói rõ từng bộ."
- `trashPurgedWithKept`: "{purged}. {kept}" in both languages.

### 3.4 Settings reset (screen 23)

| # | Fix | Where |
|---|---|---|
| 2.33 | `_reset()` uses the `bool` that `reset()` returns. True pops. False releases the dialog (`_isResetting = false`) and shows the warning banner `settingsResetFailed` inside it; the confirm reads "Retry" (`commonRetry`) and is the retry, so it goes through the dialog again. The screen's toast for `(SettingsSaveFailed, reset)` is removed, so the dialog owns the failure. The success toast stays on the screen. | `settings_reset_dialog_widget.dart:35-60`, `settings_screen.dart:163`, `settings_controller.dart:127-139` |

### 3.5 Daily reminder (screen 24)

| # | Fix | Where |
|---|---|---|
| 2.34 | Add `notificationPermission()` to `ReminderPlatformRepository`. It only reads, never asks (BR-REMINDER-011 amended). Android uses a new `ReminderPluginsDataSource.notificationsEnabled()` over `areNotificationsEnabled()`. A throw or null counts as granted, so an unknown never shows a false banner. The unsupported repository answers granted. A new autoDispose `reminderPermissionProvider` reads it. The screen invalidates it on open and on `AppLifecycleState.resumed` (an `AppLifecycleListener`). When `reminder.isEnabled` and the permission is denied: the row subtitle reads `reminderRevokedHint`, and a warning `ReminderBannersWidget` case shows `reminderDeniedTitle`, `reminderRevokedBody` and "Open system settings". The stored reminder is not changed. | `reminder_platform_repository.dart:23`, `android_reminder_platform_repository_impl.dart:30-41`, `reminder_plugins_data_source.dart`, `plugin_reminder_plugins_data_source.dart:60`, `unsupported_reminder_platform_repository_impl.dart`, `reminder_screen.dart:39-144`, `reminder_banners_widget.dart:36`, `reminder_settings_section_widget.dart:47` |
| 2.35 | A step (`onDecrement`, `onIncrement`) clears that stepper's invalid flag. While a flag is set, `MxFieldMessage` sits under its stepper: `reminderHourRange` or `reminderMinuteRange`. Save stays off while a flag is set, and now says why. | `reminder_time_dialog_widget.dart:44-113` |
| 2.36 | **Merged into 2.34.** The same resume read lets `ref.listen(reminderPermissionProvider)` call `ReminderController.clearPermissionProblem()` when permission is granted and `problem == permissionDenied`. The banner and the "denied" subtitle go. The toggle stays off; turning it on is the person's tap (BR-REMINDER-011 forbids an automatic request). | `reminder_controller.dart:222`, `reminder_screen.dart:51` |

Copy (EN · VI):

- `reminderRevokedHint`: "On · notifications are blocked for MemoX" · "Đang bật · thông báo của MemoX đang bị chặn"
- `reminderRevokedBody`: "The reminder is on, but Android won't show it. Allow notifications in Android Settings › Apps › MemoX › Notifications." · "Nhắc nhở đang bật nhưng Android sẽ không hiển thị. Hãy cho phép thông báo trong Cài đặt Android › Ứng dụng › MemoX › Thông báo."
- `reminderHourRange`: "Enter an hour from 0 to 23." · "Nhập giờ từ 0 đến 23."
- `reminderMinuteRange`: "Enter a minute from 0 to 59." · "Nhập phút từ 0 đến 59."

### 3.6 Sync and Monitoring (screens 27, 28)

| # | Fix | Where |
|---|---|---|
| 2.37 | When the last failure is `signIn` and `canSignInAgainProvider` is true, the warning banner reads `syncSignInAgain` with a compact primary "Sign in" (`accountSignIn`). It opens `AppRoutes.settingsSignInReauth(from: AppRoutes.settingsSync)` through a new `SyncScreen.onSignIn`, wired in the router. `_leadsSyncNow` is false in that case, so Sync now is outline. When auth is not `ReauthRequired` (a transient refusal), nothing changes. | `sync_notice_widget.dart:41-47`, `sync_screen.dart:41,76,90`, `app_router.dart:290` |
| 2.38 | `MonitoringListLoaded` gains `refreshFailure` (offline or other). `_loadFirst` keeps the rows when it fails with them on screen and the filter unchanged (a pull to refresh). The list shows a warning `MxInlineBanner` (`monitoringRefreshFailed`) with Retry, which calls `refresh()`. A `notAdmin` failure still replaces the rows, since the person may no longer see logs. A new filter or search clears the rows first, so its failure stays the full page. | `monitoring_list_controller.dart:82-88,148-162`, `monitoring_list_state.dart:20-39`, `monitoring_server_list_widget.dart:75-140` |
| 2.39 | `setStatus` catches `NotAdminFailure` before `on Object`. It sets `MonitoringDetailFailed(notAdmin)`, which the page already draws as "Only an admin can see this" with no triage footer. No Retry toast is shown. | `monitoring_detail_controller.dart:61-66` |

Copy (EN · VI):

- `syncSignInAgain`: "Your sign-in expired, so sync is paused. Your changes are safe on this device. Sign in again to resume." · "Phiên đăng nhập đã hết hạn nên đồng bộ đang tạm dừng. Thay đổi vẫn an toàn trên điện thoại này. Đăng nhập lại để tiếp tục."
- `monitoringRefreshFailed`: "Nothing was lost. Couldn't refresh the list. The rows below are from the last time it loaded." · "Không mất dữ liệu nào. Không làm mới được danh sách. Các dòng bên dưới là lần tải trước." (final fix 7: says nothing was lost first, per DESIGN.md)

### 3.7 Account (screens 29–33)

| # | Fix | Where |
|---|---|---|
| 2.40 | `startLinkSwitch` calls `accounts.forgetPickedGoogle()` on every `return false` after the sheet: the sheet dismissed, `beginSwitch` throwing a `Failure`, and a `StateError`. A started switch keeps the credential, because the target sign-in needs it. `cancelSwitch` already forgets. | `merge_choice_sheet_widget.dart:45-60`, `account_coordinator_switch.dart:42-71` |
| 2.41 | **Includes 2.44.** A keep-alive `lastCodeSentProvider` (in-memory, feature-local) holds `(purpose, email trimmed and lower-cased, sentAt)`. `SignInController.sendCode` returns `codeSent` without calling the server when the same key was sent less than `resendWait` ago, so the code step reopens. `CodeController.build` starts at `max(0, resendWait - (now - sentAt))` instead of a fresh 60 s. A successful send or resend records `now`. | `sign_in_controller.dart:31-48`, `code_controller.dart:24-26,89-91`, new `last_code_sent_provider.dart` |
| 2.44 | **Merged into 2.41.** `resend()` on `RateLimitedFailure` records `sentAt = now` (the server has seen a send within the minute) and returns `resendIn: resendWait` with `_startWait()`. Other failures still return `Duration.zero`. | `code_controller.dart:166-179` |
| 2.42 | `classifyAuthError` maps `email_address_invalid`, and `validation_failed` whose message names the email, to a new `InvalidEmailFailure extends AuthFailure` (DECISION 2). `signInProblemOf` maps it to the existing `SignInProblem.invalidEmail`, so the field shows the address problem and not "try again". | `supabase_auth_errors.dart:28-47`, `sign_in_state.dart:256-261` |
| 2.43 | **R11.** When `view.isStuck`: `accountLayerStuck` is replaced by the copy below (final fix: EN "This move can't finish on this phone. Your decks are kept. Close MemoX and report the problem — the log has the details."; it promises no resume). Retry sits beside a new "Close MemoX" (outline) in an `MxActionPair`, with Close leading and Retry trailing. Close calls `SystemNavigator.pop()` and changes no data. The non-stuck stopped states are unchanged. | `account_transition_layer_widget.dart:202-219,254`, ARB |
| 2.45 | A wrong code (`SignInProblem.wrongCode`) still clears the field. Offline, failed or rate-limited keeps the digits and shows the problem, with a compact "Retry" (`commonRetry`) that checks the same code again. `isEnabled` stays true while verifying, since a disabled field drops focus. A `FocusNode` requests focus on first frame (autofocus) and again after a wrong code. | `code_form_widget.dart:55-64,105-112` |
| 2.46 | `PopScope(canPop: !running)` on Welcome (Google link), screen 30 (send, Google) and screen 31 (verify, resend). The app bar back reads `maybePop`, so it is held too. The spinner already shows what is running. | `welcome_screen.dart:81`, `sign_in_screen.dart:57`, `code_screen.dart:36` |
| 2.47 | `DeleteRefused(failure: SessionInvalidFailure())` shows `accountDeleteUnknown` instead of `accountDeleteRefused`, since the server may have taken the deletion. All other refusals keep "Nothing changed". | `account_layer_host_widget.dart:81-92`, `account_coordinator_leave.dart:155-161` |
| 2.48 | (a) `UserRoleRemoteDataSource._call` adds `.timeout(roleCallTimeout)` (20 s, as the Dio receive timeout). `TimeoutException` maps to `OfflineFailure` through `classifyRemoteError`. `role_set` is idempotent, so a retry is safe. (b) The list's listener also handles `ScrollMetricsNotification`, so a first page shorter than the viewport asks for the next page after layout. The same listener on screen 28's `_Rows` gets the same change. | `user_role_remote_data_source.dart:33-36`, `users_list_widget.dart:125-131`, `monitoring_server_list_widget.dart:143-175` |

Copy (EN · VI):

- `accountLayerStuck`: "Something went wrong while moving your account. Your data is safe on this phone. MemoX picks the move up again the next time it opens." · "Đã có lỗi khi chuyển tài khoản. Dữ liệu vẫn an toàn trên điện thoại này. MemoX sẽ tiếp tục việc chuyển ở lần mở sau."
- `accountCloseApp`: "Close MemoX" · "Đóng MemoX"
- `accountDeleteUnknown`: "Couldn't confirm the deletion. Sign in again to check." · "Chưa xác nhận được việc xoá. Đăng nhập lại để kiểm tra."

## 4. Shared code

- **DECISION (owner) 1: `MxDeckPickerSheet` gains `isHeld` and `banner`.**
  - Both are optional, and `isHeld` passes through to `MxBottomSheet`.
  - Recommended: yes. Three feature sheets need both, and the alternative is a toast under the scrim, which is the defect.
- **DECISION (owner) 2: `InvalidEmailFailure` in `lib/core/error/failure.dart`.**
  - It is mapped in `supabase_auth_errors.dart`. `FailureMessage.failure` falls under its existing `AuthFailure` branch.
  - Recommended: yes. It is the one typed way for a data source to say "the address is wrong".
- **DECISION (owner) 3: the server time for R10 (2.30).**
  - Option A (recommended): `sync_changes` returns `serverTime`.
    - A new migration, with a pgTAP file `13_sync_server_time.sql`.
    - `ChangesResponseModel.serverTime` is nullable and `build_runner` is rerun.
    - `SyncStore` gains `recordServerTime` and `serverTime`, with a new `sync_state` key.
    - An old server gives null, and the purge waits.
    - It touches `supabase/` once. The RPC list in `supabase/README.md#rules` does not change.
  - Option B: read `iat` from the Supabase access token. This needs no server change, but it couples trash safety to the auth layer and to token refresh timing.
- **DECISION (owner) 4: no shared failure widget for dialogs.** Each dialog renders its own `MxInlineBanner`.
  - Recommended: reuse. It is a four-line use at seven sites, and the message mapping already lives in `l10n.failure`.

Feature-local additions (no decision needed):

- `ReminderPlatformRepository.notificationPermission()`;
- `lastCodeSentProvider`;
- the `ServerTimeReader` typedef;
- `trashBlockedNotes`.

## 5. Business-rule changes

The BR docs are in Vietnamese and keep that language.

- `docs/features/trash/rules/BR-TRASH-009-retention-30-ngay.md`. Append to the Rule:
  "Auto-purge MUST chỉ chạy khi giờ máy lệch không quá 1 ngày so với giờ server thấy ở lần đồng bộ gần nhất; nếu chưa từng đồng bộ hoặc lệch quá 1 ngày, auto-purge MUST chờ (không xoá gì) cho đến lần chạy sau. Purge do người dùng chọn không bị ảnh hưởng." Add an edge-case row: "Giờ máy chỉnh tới trước 40 ngày khi offline → không xoá; xoá sau lần đồng bộ kế".
- `docs/features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md`:
  - A4 and step 3 gain "khi đồng hồ tin cậy (BR-TRASH-009)";
  - a purge confirm of a deck names the deck and its counts;
  - a purge that skips a batch says so in a toast (E4).
- `docs/features/reminders/rules/BR-REMINDER-011-xin-quyen-sau-khi-bat.md`. Add: "App MAY đọc (không xin) trạng thái quyền khi mở màn và khi resume. Nếu nhắc đang bật mà quyền bị tắt, UI MUST nói và chỉ đường mở cài đặt hệ thống; settings MUST NOT bị đổi. Banner 'bị từ chối' tự mất khi quyền đã bật lại." UC-REMINDER-001 step 1 and E1 get the same line.
- `docs/superpowers/specs/2026-09-30-account-ui-design.md:151` (`Recovering.isStuck`): the new copy and "Close MemoX".
- `docs/superpowers/specs/2026-09-28-sync-status-design.md` §5.4: `signIn` with `ReauthRequired` offers "Sign in".
- `docs/superpowers/specs/2026-09-28-supabase-backend-design.md` §4.2: `sync_changes` returns `serverTime` (if DECISION 3 is A).

## 6. Testing

TDD: each fix gets a failing test first. On Windows, run subsets with `run_tests.sh` (`MEMOX_TEST_BUNDLES=2`); goldens run only in the Linux container.

| Cluster | Tests (files extended unless "new") |
|---|---|
| 3.1 | `deck_name_dialog_widget_test`, `create_root_deck_dialog_widget_test`, `deck_reset_dialog_test`, new `deck_delete_dialog_test`, card move, card tag and `trash_restore_test`, `test/shared/widgets/mx_deck_picker_sheet_test`. Pattern: a completer-held write; Back and scrim do nothing; the write fails and the banner shows; the confirm retries. |
| 3.2 | `starter_add_controller_test`: a use case that throws `StateError` ends with `hasFailed` and not `isAdding`. |
| 3.3 | `trash_use_cases_test` (null, 23 h, 24 h, 25 h and a backwards skew); `sync_store_test` and `sync_coordinator_test` (the server time is stored and kept when the page lacks it); `sync_models_test`; pgTAP `13_sync_server_time.sql`; `trash_screen_test` and `trash_golden_test` (the toasts and the deck confirm). |
| 3.4 | `settings_controller_test`, `settings_screen_test`, and a new reset-dialog test: a false result keeps the dialog and the banner, and Retry runs again. |
| 3.5 | `android_reminder_platform_repository_test`, `reminder_screen_test` (resume revoked and granted via `handleAppLifecycleStateChanged`), `reminder_controller_test`, new `reminder_time_dialog_test`. |
| 3.6 | `sync_screen_test`, `monitoring_list_controller_test` and `monitoring_screen_test` (refresh fails with rows, then Retry), `monitoring_detail_controller_test` (FORBIDDEN on `setStatus`). |
| 3.7 | `account_coordinator_switch_test` (Google cancelled at the sheet, then `pickGoogle` is called again), `supabase_auth_errors_test`, `sign_in_controller_test`, `code_controller_test`, `code_screen_test`, `sign_in_screen_test`, `welcome_screen_test`, `account_transition_layer_test` (Close calls the platform pop), `users_screen_test` (short first page), and a new `user_role_remote_data_source_test` (timeout). |

**Review Focus** (inputs a row's own test would not exercise):

- **Dialogs and sheets.**
  - Back gesture plus scrim tap during a slow delete, then a failure, then an immediate second tap.
  - The create-root dialog with the keyboard up and both a field error and a failure banner.
  - A reset-summary Retry after the deck was reset on another device.
- **R10.**
  - A clock set 40 days forward, offline, then reconnect.
  - A clock exactly 24 h apart.
  - A time-zone change (compare in UTC).
  - A fresh install that has never synced (the purge waits forever; see §8).
- **Reminder.**
  - Permission revoked while the screen is open, and granted again.
  - Reminder off with permission revoked (no banner).
  - A typed "24", then Cancel.
- **Account.**
  - Cancel the merge sheet, then Continue with Google again.
  - A one-letter edit of the address inside a minute.
  - "A@x.com" and "a@x.com " counted as the same address.
  - Back during a send; a rate-limited resend, then leave and return (the wait persists).
  - Verify offline with six digits kept.
  - Delete with a dead session.
- **Lists.**
  - Users with exactly one short page and `next != null`; a refresh failure on Monitoring while a filter is set.

## 7. Goldens (default text scale only)

Existing goldens that move (Linux container, light and dark):

- `trash_purge_blocked` (the toast now shows);
- `layer_stuck` (copy and the Close MemoX button).

New goldens:

- deck delete failed (banner in the dialog);
- reset summary failed;
- settings reset failed;
- `trash_purge_confirm_deck`;
- `reminder_perm_revoked`;
- `reminder_time_invalid`;
- `sync_failed_sign_in`;
- `monitoring_list_refresh_failed`;
- `code_offline_kept`.

The golden-compare page goes to the owner before the merge.

## 8. Detail files, WBS, out of scope

- **Detail files**, each with States and Copy updated:
  - `docs/shared/ui/screen-handoff/` 01, 02, 03, 06, 23, 24, 27, 28, 30, 31, 32 and 33;
  - 29 gets the hold-Back note;
  - their rows in `00-index.md`.
- **DESIGN.md.** The failure-in-dialog pattern goes under Components → MxInlineBanner.
- **WBS.** Add `FE-D29` to `docs/wbs_FE.md`, "xong" at the end, with the spec and plan links.
- **Out of scope:**
  - SP2a items (2.01–2.25, 2.49–2.51);
  - a visible "purge is waiting" cue in the Trash. R10 says the purge waits, and says nothing about telling the person.
  - a never-synced install never auto-purges. R10 reads literally this way. If the owner wants a fallback for that case, it is one more ruling.

The review of the whole branch runs on Opus, and every other subagent runs on Sonnet, per CLAUDE.md.

## 9. Owner decisions (2026-10-03, `AskUserQuestion`)

- **Server time for R10 (2.30):** Option A — `sync_changes` returns `serverTime`
  (migration, pgTAP, `ChangesResponseModel.serverTime`, `SyncStore`).
- **Shared code:** `MxDeckPickerSheet` gains `isHeld` and `banner`;
  `InvalidEmailFailure` is added to `lib/core/error/failure.dart`. Dialogs render their
  own `MxInlineBanner`; no shared failure widget.
- **Never synced:** a device without a recorded server time never auto-purges; manual
  purge from the Trash screen still works.
