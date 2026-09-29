# Monitoring screen (B2): the admin reads and triages the app's logs

Status: draft for owner review · 2026-09-29 · sub-project B2 · decisions in
[ADR-018](../../shared/decisions/ADR-018-log-tap-trung-va-monitoring.md) §6–§8 ·
pipeline in [`2026-09-29-app-logging-design.md`](2026-09-29-app-logging-design.md) §5

## 1. Intent

B1 put every log of the app and the server into `public.app_log`. B2 lets the
admin read those logs and triage them inside the app. During development the
admin is the owner, on their phone.

Owner rulings (Impeccable `shape`, 2026-09-29):

- The main job is to **triage open problems**. The screen opens on open
  warnings and errors, newest first, with their count.
- A log's detail is its **own page**, not a sheet.
- The filters are **full**: level, status, category, time range,
  device/user, and text search.
- A `code` text style (system monospace) joins the design system for stack
  traces and JSON.

Success:

- From Settings, the admin sees the open problems.
- They open one, read its message, error, stack trace and context, and mark it
  fixed with an optional note. It then leaves the default list.
- A non-admin never sees the entry. A deep link gets "Only an admin can see
  this", backed by the RPCs' `FORBIDDEN`.
- Offline, the server tab says so and the "Not sent" tab still shows the
  device's buffer.

## 2. Dependencies

- **`claude/logging-minors`**:
  - the compact `log_query` (null-safe filters, literal search);
  - the new admin RPC `log_get(id)`.

  That PR merges before this one's code starts.
- **`claude/network-logging`** (sub-project D) adds `LogCategory.network`. The
  category filter lists the enum's values, so it picks up `network` whichever
  PR merges first.

## 3. Screens

The kit has no such screen. It is shaped from the kit's widgets, with screen 27
Sync as the precedent for a screen the kit lacks. The handoff file will be
`docs/shared/ui/screen-handoff/28-monitoring.md`, with its deviations there and
in the UI-base register (§9).

### 3.1 Entry (screen 23)

- A new section **Admin** in Settings, with one `MxSettingsRow` "Monitoring".
- Shown only when the session's `app_metadata.role` is `admin` (`isAdminProvider`,
  §4.4). Not shown at all when the build has no Supabase project.
- Route `/settings/monitoring`, on the root navigator like Sync. Back returns to
  23.

### 3.2 List (`/settings/monitoring`)

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` + back `MxIconButton` | "Monitoring" |
| Tabs | `MxSegmentedTray` | **Server** · **Not sent ({n})** |
| Search (Server) | `MxSearchField` | Searches `event` and `message`, debounced 400 ms |
| Filters (Server) | Horizontally scrolling `MxChipTrigger`s | *Level* (default warning + error), *Status* (default open), *Category* (all), *Time* (all), *Device/user* (all). Each opens an `MxBottomSheet` with `MxOptionRow`s: several can be chosen, plus a *Reset*. The time sheet offers 1 h · 24 h · 7 days · 30 days · all. A chip with a value shows it ("Level · 2"). |
| Count | `MxListSectionHeader` | "{n} open" for the default filter; "{n}+ logs" otherwise. The count is what has loaded; `+` means more pages exist |
| Rows | `MxListRow` | See the row table below |
| More | `MxSpinner` under the last row | The next page (100 rows, keyset) loads when the last 10 rows come into view; "No more logs" at the end |

Each row:

| Part | Content |
|---|---|
| Leading | The level as a glyph and colour tile: debug · info · warning · error. The glyph differs per level, so colour is never the only cue |
| Title | `event` |
| Subtitle | The first line of the message, or else the error type, one line, ellipsised |
| Trailing | `HH:mm` today, otherwise "Sep 26"; under it an `MxStatusBadge` open/fixed for warnings and errors |
| Semantics | Reads as "{level}, {event}, {time}, {status}" |

**Not sent tab:**

- An `MxNote`: "{n} logs wait on this device. They are sent when MemoX is online."
- Level filter only. Rows as above, without status.
- Read from the device buffer (`LogDatabase`), watched, so it updates as the
  buffer changes.

### 3.3 Detail (`/settings/monitoring/:id`, with `?local=1` for the buffer)

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` + back, action `MxIconButton` copy | Title: `event`. Copy puts the whole row as JSON on the clipboard; `MxSnackbar` "Copied" |
| Head | `MxIconTile` + level + `MxBadge` | The level's glyph tile and name, the full time (date and `HH:mm:ss`) under it, and the open/fixed pill for a warning or error |
| Message | `MxCard` | Selectable text |
| Error | `MxCard` | The type on its own line in the row-title weight, then the message |
| Stack trace | `MxCard`, `code` style | Selectable; long lines wrap. Each frame's `#n` is in the primary ink, so a new frame reads apart from a wrapped line. Hidden when empty |
| Context | `MxCard`, `code` style | Pretty-printed JSON, selectable |
| Details | `MxSection` of label/value rows, last | Fixed by and Fixed at (a fixed log only), note, category, source, device, app version and build, platform and OS, user. A short value sits beside its label on one 48 row; the note sits under its label; an id sits under its label in the `code` style, wraps between its groups, and has a copy button of its own. No event row: the app bar shows it |
| Triage | `MxFooterBar` + `MxButton` primary | Warnings and errors only, server rows only. The button is **Mark fixed**, or **Reopen** when fixed. It opens an `MxBottomSheet` with an optional note (`MxTextField`) and Confirm |

The head, then what triage reads, then the details: the owner reordered the page
after the Impeccable audit (2026-09-29, F1), so the message, error and trace show
without scrolling.

Changing the status:

- The row updates in place, on the detail and in the list.
- `MxSnackbar` "Marked fixed" / "Reopened".
- On failure: "Couldn't change that. Nothing changed." · Retry.

### 3.4 States (list, Server tab)

| State | Design |
|---|---|
| loading | `MxSkeletonList`, 6 rows |
| loaded | As above |
| empty, default filter | `MxEmptyState` "No open problems", body "Warnings and errors will show here." |
| empty, other filter | `MxEmptyState` "Nothing matches", action *Clear filters* |
| offline | `MxErrorState` "Can't reach the server", body "Monitoring reads the logs online. The ones this device hasn't sent are under Not sent." Action *Not sent* |
| error | `MxErrorState` "Couldn't load logs", local-first body, Retry |
| not admin | `MxEmptyState` "Only an admin can see this" (the RPC said `FORBIDDEN`) |
| loading more / end | The spinner under the list / "No more logs" |

The detail has loading, error, offline and not-found ("This log is gone. It
may have been cleaned up.").

### 3.5 Behaviour

- Pull to refresh on the Server tab reloads from the first page with the same
  filters. So does any filter or search change.
- Back from the detail keeps the list's scroll position and pages.
- Times are shown in local time, stored in UTC (ADR-008): 24-hour `HH:mm`
  everywhere, dates as screen 27 shows them.
- Tablet: the 720 dp column, like every screen (FE-C5).
- Large text: rows grow and never clip; the filter chips keep scrolling.

## 4. Architecture

A new feature folder `lib/features/monitoring/` (ADR-010 layers).

### 4.1 Domain

- Entities:
  - `LogRecordEntity`: every `app_log` field that is shown, with status fields;
  - `LogSummaryEntity`: a list row;
  - `LogFilter`: levels, statuses, categories, sources, time range, device,
    user, search;
  - `LogCursor`: `occurredAt` and `id`.
- `MonitoringRepository`:
  - `Future<LogPage> queryServer(LogFilter, LogCursor?)`;
  - `Future<LogRecordEntity> getServer(String id)`;
  - `Future<LogRecordEntity> setStatus(String id, LogStatus, String? note)`;
  - `Stream<List<LogSummaryEntity>> watchPending(Set<LogLevel>)`;
  - `Future<LogRecordEntity?> getPending(String id)`.
- One use case per interaction (ADR-011 D4/D5): `QueryServerLogsUseCase`,
  `GetServerLogUseCase`, `SetLogStatusUseCase`, `WatchPendingLogsUseCase`,
  `GetPendingLogUseCase`.
- Failures map to the existing `Failure` model. `FORBIDDEN` becomes
  `NotAdminFailure`; a network error becomes the same offline failure sync uses
  (`classifySyncFailure`).

### 4.2 Data

- `MonitoringRemoteDataSource`: the three admin RPCs through the Supabase client
  (`rpc`), on the existing session. It never signs in: without a session it
  reports offline/not admin.
- `MonitoringLocalDataSource` over `LogDatabase`: a new
  `watchPending({levels, limit})` and `byId(id)`.
- Mappers between the JSON or rows and the entities.

### 4.3 Presentation

- Controllers (Riverpod `@riverpod`):
  - `MonitoringListController`: state = filter, items, cursor, `hasMore`, and
    the status of the loading or loading-more task (sealed, per
    `flutter-state-riverpod`);
  - `MonitoringDetailController`: family by id and local;
  - `PendingLogsProvider`: a stream.
- Side effects (snackbar, sheets) happen in listeners, never on rebuild.
- Filter sheets are widgets in the feature, built from Mx widgets. Copy lives
  in l10n (en and vi).

### 4.4 Admin detection

- `isAdminProvider` (in the feature's `di/`) reads
  `Supabase.instance.client.auth.currentSession?.user.appMetadata['role'] == 'admin'`
  and listens to `onAuthStateChange`, so a refreshed token that carries the role
  shows the entry without a restart.
- False when the build has no Supabase.
- The RPCs enforce the role again, so the provider only decides visibility.

### 4.5 Design system

- `MxTextStyles.code`:
  - system monospace (`fontFamily: 'monospace'`), `bodySmall` metrics;
  - tabular figures;
  - added in `lib/core/theme/mx_text_styles.dart` (owner approved, 2026-09-29).
- No new shared widget. Level tiles reuse `MxIconTile` with the level's colour
  and glyph. Warning and error use the existing status colour roles, and
  contrast holds (the FE-C1 token test covers those pairs).

## 5. Testing

- **Unit:**
  - mappers (JSON to entity, missing fields);
  - the repository (FORBIDDEN → `NotAdminFailure`, network → offline);
  - `watchPending` on an in-memory `LogDatabase`;
  - each use case.
- **Controllers:**
  - default filter, next page and end, a filter change resets to page 1;
  - a status change updates the row, and a failure leaves it as it was;
  - offline and not-admin states.
- **Widget:**
  - the entry shows only for an admin;
  - each state of §3.4;
  - the detail with and without triage (local rows have none);
  - copy to the clipboard;
  - TalkBack labels of a row;
  - text scale 2.0.
- **Goldens, light and dark:**
  - list: loaded, empty, offline;
  - Not sent tab;
  - detail: open error, fixed error with note, local row;
  - a filter sheet.

  The owner reviews them on a golden-compare page (CLAUDE.md, Golden review).
- **Gate:** `dod_check.sh`, goldens in the Linux container, and Impeccable
  critique and audit of the goldens against the kit after the build
  (CLAUDE.md, a screen's workflow).

## 6. Out of scope

- Charts or aggregates.
- Export, deleting logs, bulk triage.
- Push alerts on new errors.
- Filtering the Not sent tab by anything but level.

## 7. Risks

- **Many debug rows.** The default filter hides them; keyset pages keep each
  call at 100 compact rows.
- **A context of up to 256 kB on the detail.** `SelectableText` in a scrolling
  page handles it; the list never loads context.
- **The admin role arrives with the next token refresh** (up to an hour after
  the owner sets it). The README step 6 says so.
- **Rollback:** revert the PR. The RPCs stay; nothing else calls them.
