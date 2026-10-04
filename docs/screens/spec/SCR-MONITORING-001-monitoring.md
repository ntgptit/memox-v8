---
id: SCR-MONITORING-001
name: Monitoring
domain: monitoring
status: ready
route: [/settings/monitoring, /settings/monitoring/:logId]
---

# Monitoring

## Purpose

The admin's window on the app's logs: the server's, and the device's own buffer. It opens on the open
warnings and errors, newest first, and lets the admin filter and search them, open one whole, and
mark it fixed or reopen it. On the root navigator with no bottom bar, like Sync. Opened from the Admin
section's "Monitoring" row of Settings (SCR-SETTINGS-002), shown only to an admin and not at all in a
build with no server; Back returns there. A row opens its detail at `/settings/monitoring/:logId`
(`?local=1` for a row of the device buffer), nested under the list, so Back climbs one page at a time
and the list keeps its pages and scroll position. A deep link from any other account, to the list or
to a log (`?local=1` included), gets "Only an admin can see this" before anything is read: the
device buffer has no server check behind it.

## Related Use Cases

None: the monitoring feature has no use case; its behaviour follows ADR-018 §6–§8 and the monitoring
screen spec (see `docs/functional-spec/monitoring.md`).

## Layout

### List

- **App bar** — back and "Monitoring" (content density).
- **Tabs** — a segmented tray "Server" · "Not sent ({n})"; n is every row of the device buffer.
- **Search** (Server) — "Search event or message"; it asks 400 ms after the last keystroke.
- **Filters** (Server) — five chip triggers in a row that scrolls: Level (default warning + error) ·
  Status (default open) · Category · Time · Device / user. A chip that holds a choice shows it, naming
  one or two and counting from three: "Level · Warning, Error", "Status · Open", "Time · Last 24
  hours", "Level · 3"; Device / user counts a pair, since its choices are ids.
- **Count** — "{n} logs" with any filter (the chip names the filter); "{n}+ logs" while more pages
  exist.
- **Rows** — directly in the page's scroll, with no card around them: a glyph tile per level (debug
  bug, info circle, warning triangle, error circle) on the tint of its level; the event as the title;
  the first line of the message, else of the error message, else the error type; trailing `HH:mm`
  today or "Sep 26", and under it a badge "Open" (warning tone) or "Fixed" (success tone) for warnings
  and errors — except when the Status filter holds that status, which the chip and the header say.
- **End** — the next 100 rows load when the last 10 come into view, with a spinner while they do;
  "Couldn't load more logs." with Retry; "No more logs".
- **Not sent** — the note "These logs wait on this device. They are sent when MemoX is online.", one
  Level chip (default warning + error), then the header "{n} at these levels" over the rows shown:
  the device buffer, watched, without a status.
- **Filter sheets** — Level, Status and Category: a toggle per value. Time: an option row per window
  (last hour, 24 hours, 7 days, 30 days, all time). Device / user: two text fields, "Device ID" and
  "User ID", and a note. Each has Reset (outline) and Apply.

Choosing Debug or Info, or no level at all (every level), clears the status filter: those rows have no
status and it would hide them. Category rows show the stored code (`db`, `sync`, `network`). A pull
down on the Server tab, and any filter or search change, reload from the first page.

### Detail

- **App bar** — back, the event as the title, and an action that copies the whole log as JSON
  ("Copied").
- **Head** — the level's glyph tile and name, the full local time (date and `HH:mm:ss`) under it, and
  "Open" or "Fixed" for a warning or error.
- **Message, Error** — section headers over cards of selectable text; the error's type on its own line
  in the row-title weight, then its message.
- **Stack trace, Context** — section headers over cards in the `code` style, selectable; one frame per
  row, its `#n` in the primary ink in a fixed-width cell so a wrapped line hangs under the frame's text;
  the context is pretty-printed JSON. Hidden when empty.
- **Details** — last, a section of label/value rows: Fixed by, Fixed at (a fixed log only), Note,
  Category, Source, Device, App ("8.0.0 (12)"), Platform, User. A short value sits beside its label on
  one row; the note under its label; an id under its label in the `code` style, with its own copy
  button ("Copy device ID", "Copy user ID"). A row the log does not have is left out.
- **Triage** — a footer with "Mark fixed", or "Reopen" for a fixed log (primary block button); for a
  server warning or error only. It opens a sheet with an optional note and the confirm.
- **Toasts** — "Marked fixed"; "Reopened"; "Couldn't change that. Nothing changed." · Retry.

## States

### `list_loaded` · List, loaded

Open warnings and errors.

Golden: light, dark

### `list_all_levels` · List, every level

The filter widened: four glyphs, both statuses.

Golden: light, dark

### `list_empty` · List, empty

"No open problems" · "Warnings and errors will show here.", tinted with success.

Golden: light, dark

### `list_offline` · List, offline

"Can't reach the server" with Retry above Not sent.

Golden: light, dark

### `not_sent` · Not sent

Golden: light, dark

### `level_sheet` · Level sheet

Golden: light, dark

### `detail_open` · Detail, open error

Golden: light, dark

### `detail_open_trace` · Detail, scrolled to the end

The context in the `code` style and the Details.

Golden: light, dark

### `detail_fixed` · Detail, fixed with a note

Scrolled to the Details: Fixed by, Fixed at, the note, Reopen.

Golden: light, dark

### `detail_local` · Detail, a row of the buffer

No triage, no user.

Golden: light, dark

### `list_loading` · List, loading

Skeleton list, six rows.

Golden: none — no golden in V8 (record 28)

### `list_no_match` · List, no match

"Nothing matches" with Clear filters.

Golden: none — no golden in V8 (record 28)

### `list_error` · List, error

"Couldn't load logs" with the local-first body and Retry.

Golden: none — no golden in V8 (record 28)

### `not_admin` · Not an admin

"Only an admin can see this", before anything is read.

Golden: none — no golden in V8 (record 28)

### `detail_loading` · Detail, loading

Skeleton.

Golden: none — no golden in V8 (record 28)

### `detail_error` · Detail, error or offline

"Couldn't load this log" · "Nothing was lost. Try again when you're online." with Retry.

Golden: none — no golden in V8 (record 28)

### `detail_gone` · Detail, gone

"This log is gone" · "It may have been cleaned up."

Golden: none — no golden in V8 (record 28)

## Controls

### Server list (search, filters, pages, pull to refresh)

- Type: read
- Invokes: FN-MONITORING-001

#### On failure

- `NotAdminFailure` → `not_admin`; `OfflineFailure` → `list_offline`; `ServerFailure` → `list_error`;
  a failed next page → "Couldn't load more logs." with Retry.

### Not sent tab

- Type: segmented tray option / read
- Invokes: FN-MONITORING-004

### Filter sheets: Reset, Apply

- Type: sheet actions
- Purpose: Apply reloads from the first page; Reset returns the sheet to its default.

### Clear filters (`list_no_match`)

- Type: button
- Purpose: returns every filter and the search to their defaults.

### Log row

- Type: list row

#### On success

- Navigate to: SCR-MONITORING-001 (the log's detail, nested under the list).

### Server log detail

- Type: read
- Invokes: FN-MONITORING-002

#### On failure

- `notFound` → `detail_gone`; `NotAdminFailure` → `not_admin`; `OfflineFailure`, `ServerFailure` →
  `detail_error`.

### Device log detail

- Type: read
- Invokes: FN-MONITORING-005

#### On failure

- `notFound` (sent since the list was read) → `detail_gone`; a database failure → `detail_error`.

### Copy log, Copy device ID, Copy user ID

- Type: icon buttons
- Purpose: copy to the clipboard; the toast "Copied".

### Mark fixed, Reopen

- Type: primary block button, then the sheet's confirm
- Enabled when: the log is a server warning or error.
- Invokes: FN-MONITORING-003

#### On success

- The toast "Marked fixed" or "Reopened"; the badge and the Details change in place.

#### On failure

- "Couldn't change that. Nothing changed." · Retry.

### Retry (`list_offline`, `list_error`, `detail_error`)

- Type: button
- Invokes: FN-MONITORING-001, FN-MONITORING-002

## Responsive Behavior

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

A row reads "{level}, {event}, {time}, {status}". Otherwise follows the shared floor (DESIGN.md,
SCREEN_CATALOG.md).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| Only an admin sees any log, the device buffer included; others see the lock state before anything is read. | — |
| A status filter never hides rows that have no status. | — |
| Triage is offered for server warnings and errors only. | — |
| A failed triage changes nothing. | — |
| Times are 24-hour in every language. | — |

## Copy

- App bar and tabs: "Monitoring" · "Server" · "Not sent ({n})".
- Search and chips: "Search event or message" · "Clear search" · "Level" · "Status" · "Category" ·
  "Time" · "Device / user" · "{label} · {value}"; levels "Debug" · "Info" · "Warning" · "Error";
  statuses "Open" · "Fixed"; windows "Last hour" · "Last 24 hours" · "Last 7 days" · "Last 30 days" ·
  "All time"; sheets "Reset" · "Apply" · "Device ID" · "User ID" · "Paste an ID from a log's
  details." · "That isn't a valid user ID."
- List: "{n} logs" · "{n}+ logs" · "No more logs" · "Couldn't load more logs." · "Retry".
- States: "No open problems" · "Warnings and errors will show here." · "Nothing matches" · "Clear
  filters" · "Can't reach the server" · "Monitoring reads the logs online. The ones this device hasn't
  sent are under Not sent." · "Not sent" · "Couldn't load logs" · "Nothing was lost. Try again in a
  moment." · "Only an admin can see this".
- Not sent: "These logs wait on this device. They are sent when MemoX is online." · "{n} at these
  levels" · "Nothing waiting" · "Every log on this device has been sent." · "No logs at these levels"
  · "Try another level."
- Detail: "Log" · "Copy log" · "Copied" · "Copy device ID" · "Copy user ID" · "Details" · "Fixed by" ·
  "Fixed at" · "Note" · "Category" · "Source" · "Device" · "App" · "Platform" · "User" · "Message" ·
  "Error" · "Stack trace" · "Context".
- Triage: "Mark fixed" · "Reopen" · "Note (optional)" · "What did you do?" · "Marked fixed" ·
  "Reopened" · "Couldn't change that. Nothing changed." · "Retry".
- Detail states: "Couldn't load this log" · "Nothing was lost. Try again when you're online." · "This
  log is gone" · "It may have been cleaned up."

## Rulings

- **ADR-018 §8, Impeccable shape 2026-09-29:** the screen is built from the shared widgets.
- **Plan ruling 1, UI-base row 147:** open and fixed are badges, open in the warning tone and fixed in
  the success tone (tone pass T7), each with its word; the card status badge names a card lifecycle
  only.
- **Plan ruling 2:** Level, Status and Category filter with toggles; only the one-choice Time uses
  option rows.
- **Plan ruling 3:** a category shows its stored code.
- **Plan ruling 4:** the device / user filter is a sheet of two text fields, a device id and a user id.
- **Plan ruling 12:** the offline state offers Retry above Not sent.
- **Plan ruling 13:** rows sit directly in the page's scroll, with no card around them.
- **Owner 2026-09-29, UI-base row 147:** code uses the `code` text style: the system monospace at body
  small size, tabular figures.
- **Owner 2026-09-29 (Impeccable audit):** the detail shows the level and status first, then the
  message, error, trace and context, then compact Details without an Event row.
- **Monitoring screen spec §3.2, §3.5 (ADR-008):** a row shows `HH:mm` today and "Sep 26" before; the
  detail shows the full date and `HH:mm:ss`, 24-hour in every language.
- **Critique 2026-09-30 tone pass, T7:** a Fixed log is success; the empty lists tint with success.
- **Critique 2026-09-30 part 3b:** a chip names one or two choices and counts from three; a row's
  status badge is left out when the Status filter says it; Not sent's header counts the rows shown.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the list
  header counts logs with any filter; a stack trace lays out one frame per row with the `#n` in a
  fixed-width cell, selectable, the `#n` in the primary ink.
