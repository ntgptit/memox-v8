<!-- Hand-written screen record. -->

# 41 · Startup failure

The recovery screen for a launch whose database did not open: a migration that stopped, a
file that cannot be read, a full disk. It says first that nothing was deleted, names the
upgrade step that stopped when it was one, and offers Retry and Send report. It never
touches the file itself. DEV-195; UC-STARTER-001 E1 ("database cannot open: clear error
screen with retry"). `StartupFailureApp`, `lib/app/startup_failure_app.dart`, shown by
`AppRoot` (`lib/app/app_root.dart`).

## Entry points

- **The launch:** `main` runs `startApp`; `_openDatabase` calls `ensureOpened()` before
  anything reads the database. A throw is logged to the log buffer
  (`lifecycle.database_unavailable`, with the `from->to` of the step when the open failed
  inside an upgrade) and returned as `StartupDatabaseUnavailable`; `AppRoot` then builds
  this screen instead of `MemoxApp`. No step after the guard runs (no schedulers, no
  Welcome, no reminder plugins).
- **Retry:** `retryStartApp` invalidates the database provider and runs the start again
  from the database on; the screen stays when the open fails again, and `MemoxApp`
  replaces it when the file opens.
- It is not part of the router: it is its own `MaterialApp`, so there is no tab shell, no
  bottom bar and no Back target.

## Layout

| Region | Widget | Design |
|---|---|---|
| Host | `MaterialApp` with `AppThemeHost` | The app's light and dark themes and its localizations, with no settings row to read: the brightness follows the platform (`resolveBrightness(context, ThemeMode.system)`) and the language follows the device. |
| Shell | `MxAppShell` + `SafeArea` | No app bar, no footer. |
| Body | `ListView`, 24 padding | Scrolls on a short window. |
| Error state | `MxErrorState` | The alert glyph on the error tint, the title "Couldn't open your data", the body, and Retry (a `MxButton` that spins while the start runs again). |
| Gap | 16 | Between the error state and the report line. |
| Report | `MxButton` secondary, block, or a text line | "Send report" until it is tapped; then, in its place, the muted centred line "Report queued; it goes up with the logs." |

The body is `startupDatabaseErrorBody` alone, or, when the open stopped inside an upgrade
step, the migration hint (the version it stopped between), a line break, then
`startupDatabaseErrorBody`.

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| failed | — | — | The open failed with no upgrade step to name: title, body, Retry and Send report. No golden. `startup_failure_app_test.dart::the recovery screen shows the title, the body, Retry and Send report, and confirms a queued report`. |
| migrationStopped | — | — | The open stopped inside an upgrade step: the body starts with "The update of your data from version {from} to {to} stopped before it finished. Nothing was changed; Retry runs it again." No golden. `startup_failure_app_test.dart::an open that stopped inside an upgrade step names it`. |
| retrying | — | — | Retry was tapped: its button spins (`isRetrying`) while `retryStartApp` runs. No golden. `UNVERIFIED (code read)`: `app_root.dart` `_retry` sets the flag, `startup_failure_app.dart` passes it to `MxErrorState`; no test holds the start open to read the spinner. |
| reportQueued | — | — | Send report was tapped: the button gives way to "Report queued; it goes up with the logs." and does not come back. No golden. `startup_failure_app_test.dart::the recovery screen shows the title, the body, Retry and Send report, and confirms a queued report` (second pump: the line is shown, the button gone). |

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| (launch) | the database does not open | failed, or migrationStopped when the failure was inside an upgrade step; the error is logged to the buffer and no later start step runs | DEV-195. VERIFIED `app_bootstrap_test.dart::a database that cannot open ends in StartupDatabaseUnavailable, logged to the buffer, with no step after the guard run (DEV-195)`; `startup_failure_app_test.dart::an open that stopped inside an upgrade step names it` |
| failed / migrationStopped | tap Retry | retrying | VERIFIED the tap runs the callback `startup_failure_app_test.dart::the recovery screen shows the title, the body, Retry and Send report, and confirms a queued report`; the spinner `UNVERIFIED (code read)` |
| retrying | the file opens | the app: `MemoxApp` replaces this screen | VERIFIED `startup_failure_app_test.dart::Retry on AppRoot runs the start again and swaps in the app once the file opens`; `app_bootstrap_test.dart::Retry opens the database again from a fresh connection and, once the file opens, finishes the start (DEV-195)` |
| retrying | the open fails again | failed (or migrationStopped); Retry is tappable again | `UNVERIFIED (code read)`: `app_root.dart` `_retry` stores the new `StartupDatabaseUnavailable`; no test retries into a second failure |
| retrying | the start dies on a bug, not a closed file | the bug is reported; the old result stays (failed or migrationStopped) and Retry is tappable again, never spinning for good | VERIFIED `startup_failure_app_test.dart::a Retry that dies on a bug, not a closed file, is reported and lets Retry be tapped again (audit 2026-10-17)` |
| retrying | the screen is gone before the start answers | nothing is set | `UNVERIFIED (code read)`: `_retry` returns on `!mounted` |
| retrying | a second tap on Retry | ignored while the button spins | `UNVERIFIED (code read)`: `MxButton(isLoading: isRetrying)` |
| failed / migrationStopped | tap Send report | reportQueued; the log scheduler uploads the buffer now (`syncNow`) | VERIFIED for the swap `startup_failure_app_test.dart::the recovery screen shows the title, the body, Retry and Send report, and confirms a queued report`; the upload `UNVERIFIED (code read)`: `app_root.dart` `_sendReport` (`logSchedulerProvider` is null when the build names no Supabase project, so the line shows and nothing is sent) |
| reportQueued | tap Retry | retrying, the report line kept | `UNVERIFIED (code read)`: `_isReportQueued` is never cleared |
| any | system Back | the OS leaves the app: this is the only route | `UNVERIFIED (code read)`: `home` of the recovery `MaterialApp`; no test presses Back |

## Rulings

- **DEV-195:** the screen says first that nothing was deleted, and never repairs, resets or deletes the file. Retry only opens it again.
- **Own host:** the screen runs before settings can be read, so it is a `MaterialApp` of its own with the app's themes and localizations, not part of `MemoxApp` (no router, no account redirect, no Welcome).
- **Send report** ships the log buffer, which is its own file and usually still opens when the data file does not. It is a courtesy, not a repair; it asks nothing and shows no progress.
- **UC-STARTER-001 E1** is the use case this screen answers; the screen belongs to no feature folder and lives in `lib/app/`.
- **No golden:** the frames are a stock `MxErrorState` and `MxButton`; the four widget tests and the bootstrap tests are the evidence.

## Copy

"Couldn't open your data" · "Nothing was deleted. Try again; if it keeps failing, send a report so it can be looked into." · "The update of your data from version {from} to {to} stopped before it finished. Nothing was changed; Retry runs it again." · "Retry" · "Send report" · "Report queued; it goes up with the logs."

Vietnamese: "Không mở được dữ liệu của bạn" · "Không có gì bị xoá. Hãy thử lại; nếu vẫn lỗi, hãy gửi báo cáo để được xem xét." · "Việc cập nhật dữ liệu từ phiên bản {from} lên {to} đã dừng giữa chừng. Chưa có gì thay đổi; Thử lại sẽ chạy lại bước đó." · "Gửi báo cáo" · "Đã xếp báo cáo vào hàng; nó sẽ được gửi cùng nhật ký."
