# Monitoring screen (B2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** From Settings, an admin reads the app's logs (the server's and the device's buffer), filters and searches them, opens one whole, and marks a warning or error fixed or reopens it.

**Architecture:** A new feature folder `lib/features/monitoring/` (ADR-010/ADR-011 layers, one use case per interaction). A data layer over the three admin RPCs (`log_query`, `log_get`, `log_set_status`) and over `LogDatabase` (the device buffer). Riverpod controllers keep the list's filter, pages and cursor; a generation counter drops a stale answer. Settings takes the entry as a slot that `app/` composes, so the two features stay apart.

**Tech Stack:** Flutter 3.47, Riverpod 3 codegen, Drift (the device buffer), Supabase RPC (`supabase_flutter`), go_router, gen-l10n (en, vi), pgTAP.

**Spec:** [`docs/superpowers/specs/2026-09-29-monitoring-screen-design.md`](../specs/2026-09-29-monitoring-screen-design.md). Also read [ADR-018](../../shared/decisions/ADR-018-log-tap-trung-va-monitoring.md), [ADR-010](../../shared/decisions/ADR-010-kien-truc-lop-v8-va-tooling.md), [ADR-011](../../shared/decisions/ADR-011-cau-truc-thu-muc-v8.md), [ADR-016](../../shared/decisions/ADR-016-mo-hinh-xu-ly-loi.md) and the pipeline spec [`2026-09-29-app-logging-design.md`](../specs/2026-09-29-app-logging-design.md) §5.

## Preconditions

Check these before Task 1; stop and tell the owner if one fails.

1. **`claude/logging-minors` is merged into `master` (PR #157).** It added `supabase/migrations/20261007000000_log_admin_reads.sql`, which defines:
   - `public.log_query(filter jsonb) returns jsonb`: admin check first; a list filter counts only when it is a JSON array; literal search; result `{items: [...]}` of compact rows (`id, occurred_at, level, source, category, event, message` first 300 chars, `error_message` first 300 chars, `error_type, status, user_id, device_id, app_version, platform`); keyset `before: {occurredAt, id}`; `limit <= 100`; filter keys `levels, sources, categories, statuses, search, from, to, userId, before, limit`.
   - `public.log_get(log_id uuid) returns jsonb`: the whole row (`to_jsonb`); `FORBIDDEN` for a non-admin, `NOT_FOUND` if absent.
   - The existing `public.log_set_status(log_id uuid, new_status text, note text) returns jsonb` (the whole row; admin only; warning and error only; `NOT_FOUND`).

   Verify: `ls supabase/migrations | grep log_admin_reads`.
2. **`claude/network-logging` is merged (PR #155)**: `LogCategory.network` and `lib/core/network/logging_http_client.dart` are on `master`. Verify: `grep -n network lib/core/logging/log_entry.dart` and `ls lib/core/network/logging_http_client.dart`.
3. **The follow-up migration `supabase/migrations/20261008000000_log_query_safe_scalars.sql` is merged** (it is on another branch when this plan is written; it is the only precondition still pending). It makes a non-number `limit` and an invalid `before` cursor count as absent, and it again `create or replace`s `log_query`. Task 3's migration must start from **its** body, so it cannot be written before it lands. Verify: `ls supabase/migrations | grep log_query_safe_scalars`. If it is not there, do Tasks 1, 2 and 4 to 14 in order, and leave Task 3 for when it lands: nothing in the app needs the device filter to compile, only to filter.

Keep an **execution ledger** at the end of this file as you go: one line per task with its commit and any deviation from the plan, with the reason. It travels to the PR (CLAUDE.md: plan-time rulings live in the plan and its ledger).

Then bring this branch up to date (it holds only documents): `git fetch origin && git merge origin/master` (never force-push). Do the work in a worktree (`using-git-worktrees`), run `flutter pub get` and `dart run build_runner build --delete-conflicting-outputs` once, and read `CLAUDE.md`. Goldens are rendered only in the Linux container; run them here.

## Global Constraints

From the spec, verbatim, and from the repo's rules. Every task's requirements include this section.

- **Default view:** the Server tab opens on open warnings and errors, newest first, with their count (spec §1, §3.2). Default filter: *Level* warning + error, *Status* open, *Category* all, *Time* all, *Device/user* all.
- **Tabs:** `MxSegmentedTray`, **Server** · **Not sent ({n})**. Search is `MxSearchField`, debounced **400 ms**, over `event` and `message`.
- **Paging:** keyset, **100 rows** a page; the next page loads when the last **10 rows** come into view; "No more logs" at the end. The count is what has loaded, `+` means more pages exist: "{n} open" for the default filter, "{n}+ logs" otherwise.
- **Filter sheets:** each chip opens an `MxBottomSheet`; the time sheet offers 1 h · 24 h · 7 days · 30 days · all; every sheet has a *Reset*. A chip with a value shows it ("Level · 2"). The category filter lists `LogCategory.values`, never a hard-coded list.
- **Row:** leading level glyph on a tile (the glyph differs per level: colour is never the only cue), title `event`, subtitle the first line of the message (or else the error message, or else the error type), trailing `HH:mm` today, otherwise "Sep 26", and under it the status for warnings and errors. TalkBack reads "{level}, {event}, {time}, {status}".
- **Not sent tab:** an `MxNote` "{n} logs wait on this device. They are sent when MemoX is online."; level filter only; rows read from the device buffer (`LogDatabase`), watched; no status.
- **Detail:** `/settings/monitoring/:id`, `?local=1` for the buffer. Its own page. App bar title `event`, action `MxIconButton` copy (the whole row as JSON, then `MxSnackbar` "Copied"). Summary `MxSection` of key/value `MxSettingsRow`s; `MxCard`s for message, error, stack trace and context (the last two in the `code` style; selectable; long lines wrap; empty ones hidden). Triage: `MxFooterBar` + primary `MxButton` **Mark fixed** / **Reopen**, warnings and errors of the server only, opening an `MxBottomSheet` with an optional note (`MxTextField`) and Confirm. Toasts "Marked fixed" / "Reopened"; on failure "Couldn't change that. Nothing changed." · Retry.
- **States (Server tab):** loading `MxSkeletonList` 6 rows; empty default "No open problems" / "Warnings and errors will show here."; empty other "Nothing matches" + *Clear filters*; offline `MxErrorState` "Can't reach the server" / "Monitoring reads the logs online. The ones this device hasn't sent are under Not sent."; error "Couldn't load logs" with the local-first body and Retry; not admin `MxEmptyState` "Only an admin can see this". The detail has loading, error, offline and not-found ("This log is gone. It may have been cleaned up.").
- **Behaviour:** pull to refresh on the Server tab, and any filter or search change, reload from the first page; Back from the detail keeps the list's pages and scroll position; times are local, stored in UTC (ADR-008), 24-hour `HH:mm`; the 720 dp column (FE-C5); large text: rows grow and never clip, the chips keep scrolling.
- **Admin:** `app_metadata.role == 'admin'` from the Supabase session; the entry is a new **Admin** section in Settings with one `MxSettingsRow` "Monitoring", hidden in a build with no Supabase; the RPCs enforce the role again (`FORBIDDEN`).
- **Design system:** `MxTextStyles.code` is the system monospace (`fontFamily: 'monospace'`), `bodySmall` metrics, tabular figures. No new shared widget. No hard-coded colour, spacing, radius, duration or text style (guard `memox.design_token.*`, `memox_v8.design_system.*`); no `dynamic`; no `dart:developer`.
- **Repo rules:** `flutter.max_build_lines` 100; `common.no_large_source_file` 400 logical lines; no magic numbers (a named const); Riverpod `@riverpod` codegen, `ref.mounted` after every `await` that sets state, no `ref.read` in `build`; every string in ARB **en and vi** with a description (`test/app/l10n_test.dart`); every `*_screen.dart` has a visual-audit companion (`test/visual_audit/`); `domain/` imports no Flutter, Riverpod, Drift or `core/database/`.
- **Language and names:** reply to the owner in Vietnamese; code, identifiers, commits and PR text keep their existing conventions. Never put a model name in a file or a commit.

## Rulings made while planning

Each is where the spec was silent or ambiguous. The cost is what a wrong ruling costs to undo.

1. **The status pill is `MxBadge`, not `MxStatusBadge`.** `MxStatusBadge` names a *card* lifecycle (`MxCardStatus`), and its colours are the card statuses'. Open is `MxBadgeTone.warning`, fixed is `MxBadgeTone.mastery`; the label says it too. Cost: swap the widget in `log_row_widget.dart`.
2. **Several-choice filter sheets use `MxSettingsRow` + `MxToggle`; the one-choice Time sheet uses `MxOptionRow`.** The spec says "`MxOptionRow`s: several can be chosen", but `MxOptionRow` announces a mutually exclusive group and draws a radio. Cost: swap the row widget in one file; the sheet goldens change.
3. **Category rows show the stored code** (`db`, `sync`, `network`), not a translated name: the codes are the technical words the admin also sees in event names and JSON, and a `switch` over `LogCategory` would break the build of whichever branch merges second. Cost: one `switch` and N ARB keys.
4. **Device/user filter is a sheet with two text fields**, a device id and a user id (a uuid, validated: the server casts it). The spec names the chip but not what it offers; the ids are what the detail page and Copy show. Cost: a picker of known devices would replace the sheet.
5. **No `MonitoringLocalDataSource`.** It would only forward `watchPending` and `byId`, which `LogDatabase` already owns (CLAUDE.md: no pass-through layers). The repository takes `LogDatabase`. Cost: a 15-line file.
6. **Not found is an `Outcome`, not a `Failure`.** The repository returns null for a log that is gone; the use cases return `Outcome<LogRecordEntity, MonitoringRejection>` (ADR-016 D1, ADR-011 D6). The spec's `getServer`/`setStatus` return a record; they return `LogRecordEntity?`.
7. **`NotAdminFailure`, `OfflineFailure`, `ServerFailure` are added to the sealed `Failure`** (`lib/core/error/failure.dart`), because a sealed class cannot be extended elsewhere and the spec says "the existing Failure model". `OfflineFailure` is what `classifySyncFailure` calls `network`; a missing session is `NotAdminFailure` (no session, no admin). Cost: three classes and three `l10n.failure` cases.
8. **The sources filter is left out of `LogFilter`.** No chip offers it and `category == server` already means "written by the server". Cost: one field and one JSON key.
9. **Choosing Debug or Info clears the status filter.** Those rows have no status, so a status filter would hide them and the list would look empty for no visible reason. Cost: one method in `LogFilter`.
10. **Not sent opens on warning and error too**, like the Server tab; its note and tab count are the whole buffer. Cost: one constant.
11. **The category and the source of a record stay text** in `LogRecordEntity`: a server newer than the build may hold a category the build does not know.
12. **Offline also offers Retry**, above the *Not sent* action the spec names. Cost: one button.
13. **Rows are direct children of the page's scroll (no `MxCard`)**, so the list builds lazily. Cost: wrap them in `MxCard(isFullBleed: true)` if Impeccable prefers a card.
14. **Copy is not a use case**: it touches no data, only the clipboard, like a snackbar (ADR-011 D4 is about reads and writes).
15. **The screen does not gate itself on `isAdminProvider`.** The spec's "a deep link gets Only an admin can see this" is the RPC's `FORBIDDEN`; the Not sent tab shows this device's own buffer.
16. **A monospace face is added to the test tree** (`test/support/fonts/DejaVuSansMono.ttf`, 343 kB, its licence beside it): the app's `code` style asks for the system `monospace`, which a test host lacks, so goldens of a stack trace would be Ahem boxes. Cost: swap the file, regenerate the goldens.
17. **Localization rides with each task**, not in a task of its own: `test/app/l10n_test.dart` fails on a key with no Vietnamese, so each UI task adds its en and vi entries. The Vietnamese and text-scale checks are tests inside those tasks.

## Review Focus

Five conditions the spec implies and that are most likely to bite an admin, each with the test that pins it:

1. **A 256 kB context on the detail** renders whole, selectable, inside the page's scroll, and its JSON is written once per log, not on every rebuild. Test: Task 10, `monitoring_detail_screen_test.dart` ("a 256 kB context renders whole…"), and `monitoring_detail_controller_test.dart` ("a context of 256 kB is read and kept whole").
2. **A filter change while a page is loading**: a slow answer to the old filter never overwrites the new one, in either order, for a first page, a failure and a next page. Test: Task 8, `monitoring_list_controller_test.dart` (four "stale" cases).
3. **A token refresh that adds the admin role while Settings is open** shows the Monitoring row without a restart, and a sign-out hides it. Test: Task 7, `is_admin_provider_test.dart` and `monitoring_entry_section_test.dart`.
4. **A status change that fails offline** changes nothing on screen, says "Nothing changed", and Retry sends the same status and note. Test: Task 8 (`monitoring_detail_controller_test.dart`) and Task 10 (`monitoring_detail_screen_test.dart`).
5. **Large text on a row with a long event name** lays out in English and Vietnamese at scale 2.0 with no overflow, the title ellipsised. Test: Task 9, `monitoring_screen_test.dart` (both locales).

---

### Task 1: The `code` text style, level glyphs and a monospace face for tests

**Files:**
- Modify: `lib/core/theme/mx_text_styles.dart`
- Modify: `lib/core/theme/foundations/app_icons.dart`
- Modify: `test/flutter_test_config.dart`
- Create: `test/support/fonts/DejaVuSansMono.ttf`, `test/support/fonts/DejaVu-LICENSE.txt`
- Test: `test/core/theme/mx_text_styles_code_test.dart`

**Interfaces:**
- Consumes: `MxTextStyles` (`context.textStyles`), `AppIcons`.
- Produces: `MxTextStyles.code` (a `TextStyle`); `AppIcons.levelDebug`, `AppIcons.levelWarning`, `AppIcons.copy`, `AppIcons.monitoring`; tests render `fontFamily: 'monospace'` in DejaVu Sans Mono instead of Ahem boxes.

- [ ] **Step 1: Write the failing test**

`test/core/theme/mx_text_styles_code_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// Monitoring (owner 2026-09-29): the code style for stack traces and JSON.
void main() {
  final theme = buildLightTheme();
  final scheme = AppColorSchemes.light;
  final styles = MxTextStyles(theme.textTheme, scheme);

  test('code is the system monospace at the caption size, no tracking', () {
    final code = styles.code;

    expect(code.fontFamily, 'monospace');
    expect(code.fontFamilyFallback, contains('Menlo'));
    expect(code.fontSize, theme.textTheme.bodySmall!.fontSize);
    expect(code.letterSpacing, 0);
    expect(code.color, scheme.onSurface);
  });

  test('code has tabular figures and no wght axis of the app font', () {
    final code = styles.code;

    expect(code.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(code.fontVariations, isEmpty);
  });

  test('code keeps a 1.5 line box, so a wrapped trace never clips', () {
    expect(styles.code.height, 1.5);
  });
}
```

- [ ] **Step 2: Run it to see it fail**

Run: `flutter test test/core/theme/mx_text_styles_code_test.dart`
Expected: FAIL to compile: `The getter 'code' isn't defined for the type 'MxTextStyles'`.

- [ ] **Step 3: Add the style and the glyphs**

```diff
--- a/lib/core/theme/mx_text_styles.dart
+++ b/lib/core/theme/mx_text_styles.dart
@@ -37,6 +37,8 @@
   static const double _compactTitleTracking = -0.2;
   static const double _bannerHeight = 1.55;
   static const double _snackbarHeight = 1.4;
+  static const String _codeFamily = 'monospace';
+  static const List<String> _codeFallback = ['Menlo', 'Courier New'];
   static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];
   static const double _termTracking = -0.4;
   static const double _badgeTracking = 1.2;
@@ -59,6 +61,7 @@
   static const double _optionTracking = -0.1;
   static const double _choiceHeight = 1.25;
   static const double _studyPassageHeight = 1.55;
+  static const double _codeHeight = 1.5;
 
   /// Button label: 14/600, 0.1 tracking (regular, small, study action).
   TextStyle get buttonLabel => AppTypography.withWeight(
@@ -330,6 +333,20 @@
     color: _scheme.onSurfaceVariant,
   );
 
+  /// Code, a stack trace or JSON (Monitoring, owner 2026-09-29): the system
+  /// monospace at bodySmall's size with no tracking, tabular figures, at the
+  /// single-line height. It sets no weight and no `wght` axis: the axis is
+  /// Plus Jakarta Sans's, and a system face has none.
+  TextStyle get code => _texts.bodySmall!.copyWith(
+    fontFamily: _codeFamily,
+    fontFamilyFallback: _codeFallback,
+    fontVariations: const <FontVariation>[],
+    height: _codeHeight,
+    letterSpacing: 0,
+    fontFeatures: _tabular,
+    color: _scheme.onSurface,
+  );
+
   /// Note text: the caption role at line-height 1.5 (S5).
   TextStyle get noteText => _texts.labelSmall!.copyWith(
     height: _noteHeight,
```

```diff
--- a/lib/core/theme/foundations/app_icons.dart
+++ b/lib/core/theme/foundations/app_icons.dart
@@ -55,6 +55,13 @@
   static const IconData lockOpen = Icons.lock_open_outlined; // lock-open
   static const IconData timeout = Icons.timer_off_outlined; // timer-off
   static const IconData calendar = Icons.event; // calendar
+  // Monitoring (screen 28): one glyph per log level, so colour is never the
+  // only cue; info and error are [info] and [alert].
+  static const IconData levelDebug = Icons.bug_report_outlined; // bug
+  static const IconData levelWarning =
+      Icons.warning_amber_outlined; // triangle-alert
+  static const IconData copy = Icons.content_copy_outlined; // copy
+  static const IconData monitoring = Icons.monitor_heart_outlined; // activity
 
   // Debug gallery.
   static const IconData gallery = Icons.widgets_outlined;
```

- [ ] **Step 4: Give tests a monospace face**

The app asks for the system `monospace`; a test host has none, so a stack trace in a golden would be Ahem boxes. Copy a real face into the repo and load it under that family name:

```bash
mkdir -p test/support/fonts
cp /usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf test/support/fonts/DejaVuSansMono.ttf
cp /usr/share/doc/fonts-dejavu-core/copyright test/support/fonts/DejaVu-LICENSE.txt
```

```diff
--- a/test/flutter_test_config.dart
+++ b/test/flutter_test_config.dart
@@ -1,15 +1,31 @@
 import 'dart:async';
 import 'dart:convert';
+import 'dart:io';
 
 import 'package:flutter/services.dart';
 import 'package:flutter_test/flutter_test.dart';
 
-/// Loads every font the app bundles (Plus Jakarta Sans, Material Icons), so
-/// text and glyphs render for real in every test instead of as Ahem boxes.
+/// The face a test renders `MxTextStyles.code` in: the app asks for the
+/// system `monospace`, which a test host does not have, so it would paint
+/// Ahem boxes. DejaVu Sans Mono stands in; its licence sits beside it.
+const String _monospaceFamily = 'monospace';
+const String _monospaceFile = 'test/support/fonts/DejaVuSansMono.ttf';
+
+/// Loads every font the app bundles (Plus Jakarta Sans, Material Icons) and
+/// a monospace stand-in, so text and glyphs render for real in every test
+/// instead of as Ahem boxes.
 Future<void> testExecutable(FutureOr<void> Function() testMain) async {
   TestWidgetsFlutterBinding.ensureInitialized();
   await _loadBundledFonts();
+  await _loadMonospace();
   await testMain();
+}
+
+Future<void> _loadMonospace() async {
+  final bytes = await File(_monospaceFile).readAsBytes();
+  final loader = FontLoader(_monospaceFamily)
+    ..addFont(Future.value(ByteData.sublistView(bytes)));
+  await loader.load();
 }
 
 Future<void> _loadBundledFonts() async {
```

- [ ] **Step 5: Run the test and the theme suite**

Run: `flutter test test/core/theme`
Expected: PASS (`All tests passed!`).

- [ ] **Step 6: Commit**

```bash
git add lib/core/theme test/flutter_test_config.dart test/support/fonts test/core/theme/mx_text_styles_code_test.dart
git commit -m "feat(theme): the code text style, level glyphs and a monospace face for tests"
```

---

### Task 2: `LogDatabase.watchPending` and `byId`

**Files:**
- Modify: `lib/core/database/log/log_database.dart`
- Test: `test/core/database/log/log_database_pending_test.dart`

**Interfaces:**
- Consumes: `LogDatabase` (`logEntries`, `count()`, `_entryOf`), `LogEntry`, `LogLevel`.
- Produces: `const int pendingLimit = 200`, `const int pendingMessageLength = 300`; `PendingLog {id, occurredAt (UTC), level, event, message?, errorMessage?, errorType?}` (message and error message cut to 300 characters); `PendingLogRows {items: List<PendingLog>, total: int}`; `Stream<PendingLogRows> LogDatabase.watchPending({required Set<LogLevel> levels, int limit = pendingLimit})` (an empty set means every level; newest first; `total` counts every row, whatever the level); `Future<LogEntry?> LogDatabase.byId(String id)`.

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/log_entry.dart';

LogEntry _entry(
  String id,
  LogLevel level,
  DateTime at, {
  String? message,
  String? errorMessage,
  String? stackTrace,
}) => LogEntry(
  id: id,
  occurredAt: at,
  level: level,
  category: LogCategory.db,
  event: 'db.query',
  message: message ?? 'm $id',
  errorType: level == LogLevel.error ? 'StateError' : null,
  errorMessage: errorMessage,
  stackTrace: stackTrace,
  context: {'sql': 'SELECT ?'},
);

// ADR-018 §8, monitoring spec §4.2: the Not sent tab reads the buffer.
void main() {
  late LogDatabase db;
  final now = DateTime.utc(2026, 9, 29, 12);

  setUp(() => db = LogDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test(
    'watchPending lists the newest rows of the levels, newest first',
    () async {
      await db.insertAll([
        _entry('a', LogLevel.error, now.subtract(const Duration(minutes: 2))),
        _entry('b', LogLevel.debug, now.subtract(const Duration(minutes: 1))),
        _entry('c', LogLevel.warning, now),
      ]);

      final pending = await db
          .watchPending(levels: {LogLevel.warning, LogLevel.error})
          .first;

      expect(pending.items.map((row) => row.id), ['c', 'a']);
      expect(pending.items.last.errorType, 'StateError');
      expect(pending.items.first.level, LogLevel.warning);
    },
  );

  test(
    'the total counts every level, and a limit cuts only the list',
    () async {
      await db.insertAll([
        for (var i = 0; i < 5; i++)
          _entry('r$i', LogLevel.info, now.add(Duration(seconds: i))),
        _entry('d', LogLevel.debug, now),
      ]);

      final pending = await db
          .watchPending(levels: {LogLevel.info}, limit: 3)
          .first;

      expect(pending.items.map((row) => row.id), ['r4', 'r3', 'r2']);
      expect(pending.total, 6);
    },
  );

  test('an empty level set lists every level', () async {
    await db.insertAll([
      _entry('a', LogLevel.debug, now),
      _entry('b', LogLevel.error, now),
    ]);

    final pending = await db.watchPending(levels: {}).first;

    expect(pending.items, hasLength(2));
  });

  test('a list row carries the first 300 characters of the message and the error only', () async {
    await db.insertAll([
      _entry(
        'long',
        LogLevel.error,
        now,
        message: 'x' * 1000,
        errorMessage: 'y' * 1000,
        stackTrace: 'trace',
      ),
    ]);

    final row = (await db.watchPending(levels: {}).first).items.single;

    expect(row.message, hasLength(300));
    expect(row.errorMessage, hasLength(300));
  });

  test('watchPending emits again when the buffer changes', () async {
    final seen = <int>[];
    final sub = db
        .watchPending(levels: {})
        .listen((pending) => seen.add(pending.items.length));
    await pumpEventQueue();

    await db.insertAll([_entry('a', LogLevel.error, now)]);
    await pumpEventQueue();
    await db.deleteIds({'a'});
    await pumpEventQueue();
    await sub.cancel();

    expect(seen, [0, 1, 0]);
  });

  test('byId returns the whole row, or null once it is gone', () async {
    await db.insertAll([
      _entry('a', LogLevel.error, now, message: 'boom', stackTrace: '#0 main'),
    ]);

    final entry = await db.byId('a');

    expect(entry!.stackTrace, '#0 main');
    expect(entry.context['sql'], 'SELECT ?');
    await db.deleteIds({'a'});
    expect(await db.byId('a'), isNull);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/core/database/log/log_database_pending_test.dart`
Expected: FAIL to compile: `The method 'watchPending' isn't defined for the type 'LogDatabase'`.

- [ ] **Step 3: Implement**

`watchPending` maps Drift's own watch, which re-runs on every write and cancels cleanly. (A hand-rolled `async*` over `tableUpdates` was tried and hangs on `cancel()`.)

```diff
--- a/lib/core/database/log/log_database.dart
+++ b/lib/core/database/log/log_database.dart
@@ -35,6 +35,43 @@
 
   @override
   Set<Column<Object>> get primaryKey => {id};
+}
+
+/// How many buffered rows Monitoring lists at most, and how much of a
+/// message: the list shows one line.
+const int pendingLimit = 200;
+const int pendingMessageLength = 300;
+
+/// One buffered row as a list shows it.
+final class PendingLog {
+  const PendingLog({
+    required this.id,
+    required this.occurredAt,
+    required this.level,
+    required this.event,
+    this.message,
+    this.errorMessage,
+    this.errorType,
+  });
+
+  final String id;
+  final DateTime occurredAt;
+  final LogLevel level;
+  final String event;
+
+  /// The first [pendingMessageLength] characters of the message and of the
+  /// error's message.
+  final String? message;
+  final String? errorMessage;
+  final String? errorType;
+}
+
+/// What the buffer holds for a list: the newest rows, and every row's count.
+final class PendingLogRows {
+  const PendingLogRows({required this.items, required this.total});
+
+  final List<PendingLog> items;
+  final int total;
 }
 
 @DriftDatabase(tables: [LogEntries])
@@ -79,6 +116,67 @@
               ..limit(limit))
             .get();
     return [for (final row in rows) _entryOf(row)];
+  }
+
+  /// The buffer as Monitoring's Not sent tab lists it, again after every
+  /// write: the newest [limit] rows of [levels] (every level when it is
+  /// empty), each without its stack trace and context (a row's context can
+  /// be large), and how many rows wait in all, whatever the level.
+  Stream<PendingLogRows> watchPending({
+    required Set<LogLevel> levels,
+    int limit = pendingLimit,
+  }) {
+    final message = logEntries.message.substr(1, pendingMessageLength);
+    final errorMessage = logEntries.errorMessage.substr(
+      1,
+      pendingMessageLength,
+    );
+    final query = selectOnly(logEntries)
+      ..addColumns([
+        logEntries.id,
+        logEntries.occurredAt,
+        logEntries.level,
+        logEntries.event,
+        message,
+        errorMessage,
+        logEntries.errorType,
+      ])
+      ..orderBy([
+        OrderingTerm.desc(logEntries.occurredAt),
+        OrderingTerm.desc(logEntries.id),
+      ])
+      ..limit(limit);
+    if (levels.isNotEmpty) {
+      query.where(logEntries.level.isIn([for (final l in levels) l.name]));
+    }
+    return query.watch().asyncMap(
+      (rows) async => PendingLogRows(
+        items: [
+          for (final row in rows)
+            PendingLog(
+              id: row.read(logEntries.id)!,
+              occurredAt: DateTime.fromMillisecondsSinceEpoch(
+                row.read(logEntries.occurredAt)!,
+                isUtc: true,
+              ),
+              level: LogLevel.values.byName(row.read(logEntries.level)!),
+              event: row.read(logEntries.event)!,
+              message: row.read(message),
+              errorMessage: row.read(errorMessage),
+              errorType: row.read(logEntries.errorType),
+            ),
+        ],
+        total: await count(),
+      ),
+    );
+  }
+
+  /// One buffered row whole, or null once it is pushed or pruned.
+  Future<LogEntry?> byId(String id) async {
+    final row = await (select(
+      logEntries,
+    )..where((t) => t.id.equals(id))).getSingleOrNull();
+    return row == null ? null : _entryOf(row);
   }
 
   Future<void> deleteIds(Iterable<String> ids) =>
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/core/database/log`
Expected: PASS (`All tests passed!`), the existing buffer tests included.

- [ ] **Step 5: Commit**

```bash
git add lib/core/database/log/log_database.dart test/core/database/log/log_database_pending_test.dart
git commit -m "feat(logging): the device buffer can be watched by level and read by id"
```

---

### Task 3: Server migration: the device filter, with pgTAP

**Files:**
- Create: `supabase/migrations/20261009000000_log_query_device.sql`
- Create: `supabase/tests/database/11_log_query_device.sql` (if `11_*` is taken by then, use the next free number and change it in the commands below)

**Interfaces:**
- Consumes: `public.log_query(filter jsonb)` as `20261008000000_log_query_safe_scalars.sql` last defined it; `private.is_admin()`.
- Produces: `log_query` with one more filter key, `deviceIds` (a JSON array of device ids; applied only when it is an array; an empty array matches no device, as the other lists do; the app omits the key when no device is chosen).

- [ ] **Step 1: Write the failing pgTAP test**

```sql
begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

-- ADR-018 §8; monitoring spec §3.2: the admin filters the logs by device.
create function public.t_as(p_sub text, p_admin boolean) returns void language sql as $$
  select set_config('request.jwt.claims', jsonb_build_object('sub', p_sub, 'role', 'authenticated',
    'app_metadata', case when p_admin then jsonb_build_object('role', 'admin') else '{}'::jsonb end)::text, true) $$;

insert into public.app_log (id, occurred_at, level, category, event, device_id, error_message) values
  ('33333333-0000-0000-0000-000000000001', now() - interval '3 minutes', 'error', 'db', 'a.one', 'dev-a',
    repeat('e', 400)),
  ('33333333-0000-0000-0000-000000000002', now() - interval '2 minutes', 'warning', 'db', 'b.one', 'dev-b', null),
  ('33333333-0000-0000-0000-000000000003', now() - interval '1 minute', 'error', 'db', 'c.one', 'dev-c', null),
  ('33333333-0000-0000-0000-000000000004', now(), 'info', 'db', 'none.one', null, null);

set local role authenticated;
select public.t_as('aaaaaaaa-0000-0000-0000-000000000001', false);
select throws_ok($$ select public.log_query('{"deviceIds": ["dev-a"]}'::jsonb) $$, 'P0001', 'FORBIDDEN',
  'a user still cannot read logs');

select public.t_as('bbbbbbbb-0000-0000-0000-00000000000a', true);
select is((select array_agg(i->>'event') from jsonb_array_elements(
    public.log_query('{"deviceIds": ["dev-a"]}'::jsonb)->'items') i),
  array['a.one'], 'one device');
select is((select array_agg(i->>'event' order by i->>'event') from jsonb_array_elements(
    public.log_query('{"deviceIds": ["dev-a", "dev-c"]}'::jsonb)->'items') i),
  array['a.one', 'c.one'], 'several devices');
-- As the other lists: an empty array names no device, so nothing matches. The app omits
-- the key when no device is chosen.
select is(jsonb_array_length(public.log_query('{"deviceIds": []}'::jsonb)->'items'), 0,
  'an empty list matches no device');
select is(jsonb_array_length(public.log_query('{"deviceIds": null}'::jsonb)->'items'), 4,
  'a null restricts nothing');
select is(jsonb_array_length(public.log_query('{"deviceIds": "dev-a"}'::jsonb)->'items'), 4,
  'a scalar restricts nothing');
select is((select array_agg(i->>'event') from jsonb_array_elements(public.log_query(
    '{"deviceIds": ["dev-a", "dev-b", "dev-c"], "levels": ["error"]}'::jsonb)->'items') i),
  array['c.one', 'a.one'], 'the device filter combines with the others, newest first');
select is(public.log_query('{"deviceIds": ["dev-a"]}'::jsonb)->'items'->0->>'device_id', 'dev-a',
  'a compact row carries its device');
select is(length(public.log_query('{"deviceIds": ["dev-a"]}'::jsonb)->'items'->0->>'error_message'), 300,
  'a compact row carries the first 300 characters of its error message');

select * from finish();
rollback;
```

- [ ] **Step 2: Run it to see it fail**

Run: `bash tools/supabase/local_pgtap.sh`
Expected: `FAIL  11_log_query_device.sql` with `not ok 2 - one device` (the key is ignored, so every row comes back); the other files `ok`. (Without local Postgres: `npx supabase db start && npx supabase test db`.)

- [ ] **Step 3: Write the migration**

Do **not** type the body from here: copy the whole `create or replace function public.log_query` from `20261008000000_log_query_safe_scalars.sql` (the version merged on `master` wins over the body printed below wherever they differ, above all in how `limit` and `before` are read), then add these two lines to its `where` list, next to the other list filters:

```sql
      and (jsonb_typeof(filter->'deviceIds') is distinct from 'array'
        or a.device_id in (select jsonb_array_elements_text(filter->'deviceIds')))
```

The body below is `20261007000000`'s (the last one on `master` when this plan was written: compact rows with `error_message`, list filters counting only as JSON arrays, literal search, keyset) with the two lines added; the `20261008` version differs from it only in reading `limit` and `before`:

```sql
-- ADR-018 §8 (monitoring spec §3.2): the admin's device filter. The body of log_query is
-- 20261008000000's (itself 20261007000000's with a safer limit and cursor), plus one
-- filter: deviceIds, a list of device ids, applied only when it is a JSON array (a null
-- or a scalar restricts nothing, as the other lists; an empty array matches no device).

create or replace function public.log_query(filter jsonb) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_limit int;
  v_search text;
  v_items jsonb;
begin
  if not private.is_admin() then
    raise exception 'FORBIDDEN';
  end if;
  v_limit := least(greatest(coalesce((filter->>'limit')::int, 100), 1), 100);
  v_search := replace(replace(replace(filter->>'search', '\', '\\'), '%', '\%'), '_', '\_');
  select coalesce(jsonb_agg(to_jsonb(l) order by l.occurred_at desc, l.id desc), '[]') into v_items
  from (
    select a.id, a.occurred_at, a.level, a.source, a.category, a.event,
      left(a.message, 300) as message, a.error_type, left(a.error_message, 300) as error_message,
      a.status, a.user_id, a.device_id,
      a.app_version, a.platform
    from public.app_log a
    where (jsonb_typeof(filter->'levels') is distinct from 'array'
        or a.level in (select jsonb_array_elements_text(filter->'levels')))
      and (jsonb_typeof(filter->'sources') is distinct from 'array'
        or a.source in (select jsonb_array_elements_text(filter->'sources')))
      and (jsonb_typeof(filter->'categories') is distinct from 'array'
        or a.category in (select jsonb_array_elements_text(filter->'categories')))
      and (jsonb_typeof(filter->'statuses') is distinct from 'array'
        or a.status in (select jsonb_array_elements_text(filter->'statuses')))
      and (jsonb_typeof(filter->'deviceIds') is distinct from 'array'
        or a.device_id in (select jsonb_array_elements_text(filter->'deviceIds')))
      and (v_search is null
        or a.event ilike '%' || v_search || '%' escape '\'
        or a.message ilike '%' || v_search || '%' escape '\')
      and (filter->>'from' is null or a.occurred_at >= (filter->>'from')::timestamptz)
      and (filter->>'to' is null or a.occurred_at < (filter->>'to')::timestamptz)
      and (filter->>'userId' is null or a.user_id = (filter->>'userId')::uuid)
      and (jsonb_typeof(filter->'before') is distinct from 'object' or (a.occurred_at, a.id) <
        ((filter->'before'->>'occurredAt')::timestamptz, (filter->'before'->>'id')::uuid))
    order by a.occurred_at desc, a.id desc
    limit v_limit
  ) l;
  return jsonb_build_object('items', v_items);
end
$$;

revoke all on function public.log_query(jsonb) from public, anon, authenticated;
grant execute on function public.log_query(jsonb) to authenticated;
```

Never edit an applied migration: this one is new, and it sorts after every applied migration (`20261008000000` is the newest), so `supabase db push` accepts it.

- [ ] **Step 4: Run pgTAP**

Run: `bash tools/supabase/local_pgtap.sh`
Expected: every file `ok`, including `ok    11_log_query_device.sql (9)`, `ok    10_log_admin_reads.sql` and `ok    09_app_log.sql`.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20261009000000_log_query_device.sql supabase/tests/database/11_log_query_device.sql
git commit -m "feat(supabase): log_query filters by device"
```

---

### Task 4: Monitoring's RPCs are not logged by the network logger

Monitoring calls `log_query`, `log_get` and `log_set_status`. `LoggingHttpClient` (network logging, merged) logs every Supabase request, bodies included, and skips only `log_push`. Without this task every load would write a response full of other logs into the admin's own buffer: noise, and logs inside logs.

**Files:**
- Modify: `lib/core/network/logging_http_client.dart`
- Test: `test/core/network/logging_http_client_test.dart`

**Interfaces:**
- Consumes: `LoggingHttpClient.send`, its `_logPushPath` constant, `RecordingLogSink`.
- Produces: no request whose `url.path` ends with `/rpc/log_push`, `/rpc/log_query`, `/rpc/log_get` or `/rpc/log_set_status` is logged; each still reaches the inner client and its response or error comes back unchanged.

- [ ] **Step 1: Write the failing tests**

Add to `test/core/network/logging_http_client_test.dart`: the map of URLs after `_logPush`, and, before the "a body over 64 KB" test, a pair of tests per RPC in the style of "the log push logs nothing and still returns", plus one that pins the match to the whole path:

```diff
--- a/test/core/network/logging_http_client_test.dart
+++ b/test/core/network/logging_http_client_test.dart
@@ -12,6 +12,13 @@
 
 final _url = Uri.parse('https://x.supabase.co/rest/v1/rpc/sync_push?a=1');
 final _logPush = Uri.parse('https://x.supabase.co/rest/v1/rpc/log_push');
+
+/// The admin's log RPCs (ADR-018 §7): Monitoring's reads and its status
+/// change. Their answers are logs, so logging them would copy logs into logs.
+final _adminLogRpcs = {
+  for (final name in ['log_query', 'log_get', 'log_set_status'])
+    name: Uri.parse('https://x.supabase.co/rest/v1/rpc/$name'),
+};
 
 // Spec 2026-09-29-network-logging-design.md §2, §5.
 void main() {
@@ -126,6 +133,40 @@
     );
 
     expect(sink.entries, isEmpty);
+  });
+
+  for (final MapEntry(key: name, value: url) in _adminLogRpcs.entries) {
+    test('$name logs nothing and still returns', () async {
+      final c = client((request) async => http.Response('{"items":[]}', 200));
+
+      final response = await c.post(url, body: '{}');
+
+      expect(response.statusCode, 200);
+      expect(response.body, '{"items":[]}');
+      expect(sink.entries, isEmpty);
+    });
+
+    test('a failing $name logs nothing and still throws', () async {
+      final c = client((request) async => throw const SocketException('down'));
+
+      await expectLater(
+        c.post(url, body: '{}'),
+        throwsA(isA<SocketException>()),
+      );
+
+      expect(sink.entries, isEmpty);
+    });
+  }
+
+  test('another RPC that only starts like a log one is still logged', () async {
+    final c = client((request) async => http.Response('{}', 200));
+
+    await c.post(
+      Uri.parse('https://x.supabase.co/rest/v1/rpc/log_queryable'),
+      body: '{}',
+    );
+
+    expect(sink.entries, hasLength(1));
   });
 
   test('a body over 64 KB keeps its first 64 KB and says it was cut', () async {
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/core/network/logging_http_client_test.dart`
Expected: FAIL: `log_query logs nothing and still returns`, `log_get …`, `log_set_status …` and the three "failing …" ones (`Expected: empty, Actual: [LogEntry…]`); the `log_queryable` test and the older ones pass.

- [ ] **Step 3: Replace the constant with a set**

In `send`, the skip is checked first. Read the file first: if `master` has changed it since this plan, keep its structure and change only the constant and the check.

```diff
--- a/lib/core/network/logging_http_client.dart
+++ b/lib/core/network/logging_http_client.dart
@@ -8,7 +8,8 @@
 /// Logs every request the Supabase client sends (spec
 /// 2026-09-29-network-logging-design.md): the whole exchange at `debug`, an
 /// HTTP error as a warning, no connection at `info`, anything else as an
-/// error. The log push is never logged: each push would log the next one.
+/// error. The log RPCs are never logged: a push would log the next one, and
+/// Monitoring's reads would copy logs into logs.
 final class LoggingHttpClient extends http.BaseClient {
   LoggingHttpClient({
     required this._inner,
@@ -19,7 +20,14 @@
   /// A body past this many bytes is logged as its head (spec D6).
   static const maxBodyBytes = 65536;
 
-  static const _logPushPath = '/rpc/log_push';
+  /// The RPCs that move logs: the device's push, and the admin's reads and
+  /// change (ADR-018). Each request would log a response full of other logs.
+  static const _unlogged = {
+    '/rpc/log_push',
+    '/rpc/log_query',
+    '/rpc/log_get',
+    '/rpc/log_set_status',
+  };
   static final _stopwatch = Stopwatch()..start();
 
   final http.Client _inner;
@@ -30,7 +38,7 @@
 
   @override
   Future<http.StreamedResponse> send(http.BaseRequest request) async {
-    if (request.url.path.endsWith(_logPushPath)) return _inner.send(request);
+    if (_unlogged.any(request.url.path.endsWith)) return _inner.send(request);
     final sent = request is http.Request ? request.bodyBytes : null;
     final start = _micros();
     final http.StreamedResponse response;
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/core/network`
Expected: PASS (`All tests passed!`).

- [ ] **Step 5: Commit**

```bash
git add lib/core/network/logging_http_client.dart test/core/network/logging_http_client_test.dart
git commit -m "fix(logging): the network logger skips the admin log RPCs"
```

---

### Task 5: Failures, the domain layer and the feature map

**Files:**
- Modify: `lib/core/error/failure.dart`, `lib/l10n/failure_message.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`, `test/architecture/boundary_rules.dart`
- Create: `lib/features/monitoring/domain/models/{log_status_model,log_window_model,log_cursor_model,log_filter_model,log_page_model,pending_logs_model}.dart`
- Create: `lib/features/monitoring/domain/entities/{log_summary_entity,log_record_entity}.dart`
- Create: `lib/features/monitoring/domain/failures/monitoring_failure.dart`
- Create: `lib/features/monitoring/domain/repositories/monitoring_repository.dart`
- Create: `lib/features/monitoring/domain/usecases/{query_server_logs,get_server_log,get_pending_log,set_log_status,watch_pending_logs}_use_case.dart`
- Create: `test/support/monitoring_fakes.dart`
- Test: `test/features/monitoring/domain/{log_filter_test,log_entities_test,monitoring_use_cases_test}.dart`

**Interfaces:**
- Consumes: `Failure` (sealed), `Outcome`/`Rejected`/`Ok`, `DayClock`, `LogLevel`, `LogCategory`.
- Produces (later tasks rely on exactly these):
  - `NotAdminFailure`, `OfflineFailure`, `ServerFailure` (`const X({required super.cause})`); `l10n.failure(...)` covers them.
  - `enum LogStatus {open, fixed}` with `LogStatus.parse(String?)`; `enum LogWindow {hour, day, week, month, all}` with `Duration? span` and `DateTime? since(DateTime now)`.
  - `LogCursor(occurredAt, id)` (value equality); `LogPage(items)` with `LogPage.size = 100` and `LogCursor? next`; `PendingLogs(items, total)`.
  - `LogFilter({levels, statuses, categories, window, deviceId, userId, search})` with `defaultLevels`, `defaultStatuses`, `isDefault`, `withLevels/withStatuses/withCategories/withWindow/withDevice/withUser/withSearch`, value equality.
  - `LogSummaryEntity(id, occurredAt, level, event, message?, errorMessage?, errorType?, status?)` with `subtitle` and `withStatus`; `LogRecordEntity(...)` with `canTriage` and `toJson()`.
  - `enum MonitoringRejection {notFound}`.
  - `MonitoringRepository`: `queryServer(LogFilter, LogCursor?, {required DateTime now}) → Future<LogPage>`, `getServer(String) → Future<LogRecordEntity?>`, `setStatus(String, LogStatus, String?) → Future<LogRecordEntity?>`, `watchPending(Set<LogLevel>) → Stream<PendingLogs>`, `getPending(String) → Future<LogRecordEntity?>`.
  - Use cases, each `call(...)`: `QueryServerLogsUseCase(repo, clock)(LogFilter, {LogCursor? after}) → Future<LogPage>`; `GetServerLogUseCase(repo)(id)` and `GetPendingLogUseCase(repo)(id)` → `Future<Outcome<LogRecordEntity, MonitoringRejection>>`; `SetLogStatusUseCase(repo)(id, LogStatus, {String? note})` → same; `WatchPendingLogsUseCase(repo)(Set<LogLevel>) → Stream<PendingLogs>`.
  - Test support: `FakeMonitoringRepository` (`queries`, `lastQuery`, `autoPage`, `servers`, `pendings`, `statusChanges`, `readError`, `statusError`, `readGate`, `statusGate`, `watches`), `summary(...)`, `record(...)`, `pageOf(n)`, `sessionWithRole(String?)`.

- [ ] **Step 1: Write the failing tests and the fakes**

```dart
import 'dart:async';

import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/entities/log_summary_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_cursor_model.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/features/monitoring/domain/repositories/monitoring_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session, User;

/// A Supabase session whose account has [role] in `app_metadata`, as the
/// dashboard sets it (ADR-018 §7); no role when null.
Session sessionWithRole(String? role) => Session(
  accessToken: 'token',
  tokenType: 'bearer',
  user: User(
    id: '00000000-0000-0000-0000-0000000000ad',
    appMetadata: {'role': ?role},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-09-29T00:00:00Z',
  ),
);

final DateTime monitoringNow = DateTime.utc(2026, 9, 29, 12);

/// A list row: `id` in the title's place so a test reads which row is which.
LogSummaryEntity summary(
  String id, {
  LogLevel level = LogLevel.error,
  LogStatus? status = LogStatus.open,
  String? message,
  String? errorMessage,
  String? errorType,
  DateTime? at,
  String? event,
}) => LogSummaryEntity(
  id: id,
  occurredAt: at ?? monitoringNow,
  level: level,
  event: event ?? 'sync.push_failed',
  message: message ?? 'message of $id',
  errorMessage: errorMessage,
  errorType: errorType,
  status: status,
);

/// One page of [count] rows named `<prefix>0`, `<prefix>1`, …, newest first.
LogPage pageOf(int count, {String prefix = 'r'}) => LogPage(
  items: [
    for (var i = 0; i < count; i++)
      summary('$prefix$i', at: monitoringNow.subtract(Duration(minutes: i))),
  ],
);

/// A whole log.
LogRecordEntity record(
  String id, {
  LogLevel level = LogLevel.error,
  LogStatus? status = LogStatus.open,
  String source = 'app',
  String category = 'sync',
  String event = 'sync.push_failed',
  String? message = 'The server refused the push',
  String? errorType = 'PostgrestException',
  String? errorMessage = 'PostgrestException(message: NOT_AUTHENTICATED)',
  String? stackTrace =
      '#0      SyncCoordinator.runOnce (sync_coordinator.dart:42)',
  Map<String, Object?> context = const {'entity': 'deck', 'count': 3},
  String? statusNote,
  String? statusChangedBy,
  DateTime? statusChangedAt,
}) => LogRecordEntity(
  id: id,
  occurredAt: DateTime.utc(2026, 9, 26, 8, 30, 15),
  level: level,
  source: source,
  category: category,
  event: event,
  message: message,
  errorType: errorType,
  errorMessage: errorMessage,
  stackTrace: stackTrace,
  context: context,
  userId: '00000000-0000-0000-0000-00000000dead',
  deviceId: 'device-1',
  appVersion: '8.0.0',
  buildNumber: '12',
  platform: 'android',
  osVersion: '14',
  status: status,
  statusChangedAt: statusChangedAt,
  statusChangedBy: statusChangedBy,
  statusNote: statusNote,
);

/// One `queryServer` call, answered by the test when it likes.
final class QueryCall {
  QueryCall(this.filter, this.after, this.now);

  final LogFilter filter;
  final LogCursor? after;

  /// The moment the Time filter counts back from.
  final DateTime now;
  final Completer<LogPage> _answer = Completer<LogPage>();

  bool get isAnswered => _answer.isCompleted;

  void answer(LogPage page) => _answer.complete(page);

  void fail(Object error) => _answer.completeError(error);
}

/// Monitoring's repository, driven by the test: a server query waits until
/// the test answers it, so a test can answer two in the other order.
final class FakeMonitoringRepository implements MonitoringRepository {
  final queries = <QueryCall>[];
  final statusChanges = <({String id, LogStatus status, String? note})>[];

  /// A log by id, for [getServer] and [setStatus] to find.
  final servers = <String, LogRecordEntity>{};
  final pendings = <String, LogRecordEntity>{};

  /// Thrown by the next [getServer] and [setStatus] while set.
  Object? readError;
  Object? statusError;

  /// While set, [setStatus] waits for it.
  Completer<void>? statusGate;

  /// While set, [getServer] waits for it.
  Completer<void>? readGate;

  /// Answers every query at once, with this page, while set.
  LogPage? autoPage;

  /// Each `watchPending` call's controller, by the levels asked for.
  final watches =
      <({Set<LogLevel> levels, StreamController<PendingLogs> feed})>[];

  QueryCall get lastQuery => queries.last;

  @override
  Future<LogPage> queryServer(
    LogFilter filter,
    LogCursor? after, {
    required DateTime now,
  }) {
    final call = QueryCall(filter, after, now);
    queries.add(call);
    if (autoPage case final page?) call.answer(page);
    return call._answer.future;
  }

  @override
  Future<LogRecordEntity?> getServer(String id) async {
    if (readGate case final gate?) await gate.future;
    if (readError case final error?) throw error;
    return servers[id];
  }

  @override
  Future<LogRecordEntity?> setStatus(
    String id,
    LogStatus status,
    String? note,
  ) async {
    statusChanges.add((id: id, status: status, note: note));
    if (statusGate case final gate?) await gate.future;
    if (statusError case final error?) throw error;
    final row = servers[id];
    if (row == null) return null;
    final changed = record(
      id,
      level: row.level,
      status: status,
      statusNote: note,
      statusChangedBy: 'admin-1',
      statusChangedAt: monitoringNow,
    );
    servers[id] = changed;
    return changed;
  }

  @override
  Stream<PendingLogs> watchPending(Set<LogLevel> levels) {
    final feed = StreamController<PendingLogs>();
    watches.add((levels: levels, feed: feed));
    return feed.stream;
  }

  @override
  Future<LogRecordEntity?> getPending(String id) async => pendings[id];
}
```

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/log_window_model.dart';

// Monitoring spec §3.2: the filter's defaults and how its choices interact.
void main() {
  test('the default is open warnings and errors, everything else open', () {
    const filter = LogFilter();

    expect(filter.levels, {LogLevel.warning, LogLevel.error});
    expect(filter.statuses, {LogStatus.open});
    expect(filter.categories, isEmpty);
    expect(filter.window, LogWindow.all);
    expect(filter.deviceId, isNull);
    expect(filter.userId, isNull);
    expect(filter.search, '');
    expect(filter.isDefault, isTrue);
  });

  test('two filters with the same choices are equal, in any set order', () {
    final a = const LogFilter().withCategories({
      LogCategory.db,
      LogCategory.sync,
    });
    final b = const LogFilter().withCategories({
      LogCategory.sync,
      LogCategory.db,
    });

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a.isDefault, isFalse);
  });

  test('a level with no status clears the status filter', () {
    final filter = const LogFilter().withLevels({
      LogLevel.error,
      LogLevel.info,
    });

    expect(filter.statuses, isEmpty);
    expect(filter.levels, {LogLevel.error, LogLevel.info});
  });

  test('warning and error keep the status filter', () {
    final filter = const LogFilter().withLevels({LogLevel.error});

    expect(filter.statuses, {LogStatus.open});
  });

  test('a blank device or user is none, and an id is trimmed', () {
    expect(const LogFilter().withDevice('   ').deviceId, isNull);
    expect(const LogFilter().withUser('').userId, isNull);
    expect(const LogFilter().withDevice(' dev-1 ').deviceId, 'dev-1');
  });

  test('a search is trimmed', () {
    expect(const LogFilter().withSearch('  sync  ').search, 'sync');
  });

  test('a window reaches back from now, and all reaches without limit', () {
    final now = DateTime.utc(2026, 9, 29, 12);

    expect(LogWindow.hour.since(now), DateTime.utc(2026, 9, 29, 11));
    expect(LogWindow.day.since(now), DateTime.utc(2026, 9, 28, 12));
    expect(LogWindow.week.since(now), DateTime.utc(2026, 9, 22, 12));
    expect(LogWindow.month.since(now), DateTime.utc(2026, 8, 30, 12));
    expect(LogWindow.all.since(now), isNull);
  });

  test('a status is parsed from its stored code, or is none', () {
    expect(LogStatus.parse('open'), LogStatus.open);
    expect(LogStatus.parse('fixed'), LogStatus.fixed);
    expect(LogStatus.parse(null), isNull);
    expect(LogStatus.parse('wontfix'), isNull);
  });
}
```

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/log_cursor_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';

import '../../../support/monitoring_fakes.dart';

// Monitoring spec §4.1: the entities and the page's cursor.
void main() {
  test('a row\'s subtitle is the message\'s first line', () {
    expect(
      summary('a', message: '  first line\nsecond line').subtitle,
      'first line',
    );
  });

  test('with no message the subtitle is the error message\'s first line', () {
    expect(
      summary(
        'a',
        message: '   ',
        errorMessage: 'Bad state: closed\n#0 main',
        errorType: 'StateError',
      ).subtitle,
      'Bad state: closed',
    );
  });

  test('with neither, the subtitle is the error type, else none', () {
    expect(
      summary(
        'a',
        message: '   ',
        errorMessage: '\n',
        errorType: 'StateError',
      ).subtitle,
      'StateError',
    );
    expect(summary('a', message: '\n', errorType: null).subtitle, isNull);
  });

  test('a row keeps everything but its status when the status changes', () {
    final changed = summary(
      'a',
      level: LogLevel.warning,
    ).withStatus(LogStatus.fixed);

    expect(changed.status, LogStatus.fixed);
    expect(changed.id, 'a');
    expect(changed.level, LogLevel.warning);
    expect(changed.event, 'sync.push_failed');
  });

  test('a full page points at the row after its last', () {
    final page = pageOf(LogPage.size);

    expect(
      page.next,
      LogCursor(
        occurredAt: page.items.last.occurredAt,
        id: 'r${LogPage.size - 1}',
      ),
    );
  });

  test('a page that is not full is the last', () {
    expect(pageOf(LogPage.size - 1).next, isNull);
    expect(pageOf(0).next, isNull);
  });

  test('only a row with a status can be triaged', () {
    expect(record('a').canTriage, isTrue);
    expect(record('a', status: null).canTriage, isFalse);
  });

  test('a record\'s JSON has every field, in UTC', () {
    final json = record(
      'a',
      status: LogStatus.fixed,
      statusNote: 'index added',
    ).toJson();

    expect(json['occurredAt'], '2026-09-26T08:30:15.000Z');
    expect(json['level'], 'error');
    expect(json['status'], 'fixed');
    expect(json['statusNote'], 'index added');
    expect(json['context'], {'entity': 'deck', 'count': 3});
    expect(json.keys, hasLength(21));
  });
}
```

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/failures/monitoring_failure.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/features/monitoring/domain/usecases/get_pending_log_use_case.dart';
import 'package:memox/features/monitoring/domain/usecases/get_server_log_use_case.dart';
import 'package:memox/features/monitoring/domain/usecases/query_server_logs_use_case.dart';
import 'package:memox/features/monitoring/domain/usecases/set_log_status_use_case.dart';
import 'package:memox/features/monitoring/domain/usecases/watch_pending_logs_use_case.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/monitoring_fakes.dart';

// ADR-011 D4: one use case per interaction of the Monitoring screens.
void main() {
  late FakeMonitoringRepository repository;

  setUp(() => repository = FakeMonitoringRepository());

  test('the query asks the repository at the clock\'s now', () async {
    final clock = FakeDayClock(DateTime(2026, 9, 29, 9));
    final page = QueryServerLogsUseCase(repository, clock)(const LogFilter());

    expect(repository.lastQuery.after, isNull);
    expect(repository.lastQuery.now, DateTime(2026, 9, 29, 9));
    repository.lastQuery.answer(pageOf(2));
    expect((await page).items, hasLength(2));
  });

  test(
    'a server log that exists is Ok, one that is gone is notFound',
    () async {
      repository.servers['a'] = record('a');
      final get = GetServerLogUseCase(repository);

      expect((await get('a') as Ok).value.id, 'a');
      expect(
        (await get('gone') as Rejected).reason,
        MonitoringRejection.notFound,
      );
    },
  );

  test('a buffered log that was sent meanwhile is notFound', () async {
    repository.pendings['a'] = record('a', status: null);
    final get = GetPendingLogUseCase(repository);

    expect((await get('a') as Ok).value.id, 'a');
    expect(
      (await get('sent') as Rejected).reason,
      MonitoringRejection.notFound,
    );
  });

  test('an empty id is a programming error', () {
    expect(() => GetServerLogUseCase(repository)(''), throwsArgumentError);
    expect(() => GetPendingLogUseCase(repository)(''), throwsArgumentError);
    expect(
      () => SetLogStatusUseCase(repository)('', LogStatus.fixed),
      throwsArgumentError,
    );
  });

  test('a status change trims its note and drops a blank one', () async {
    repository.servers['a'] = record('a');
    final set = SetLogStatusUseCase(repository);

    await set('a', LogStatus.fixed, note: '  index added  ');
    await set('a', LogStatus.open, note: '   ');
    await set('a', LogStatus.fixed);

    expect(repository.statusChanges.map((c) => c.note), [
      'index added',
      null,
      null,
    ]);
  });

  test('a status change of a log that is gone is notFound', () async {
    final outcome = await SetLogStatusUseCase(repository)(
      'gone',
      LogStatus.fixed,
    );

    expect((outcome as Rejected).reason, MonitoringRejection.notFound);
  });

  test('the buffer is watched for the levels asked', () async {
    final rows = WatchPendingLogsUseCase(repository)({LogLevel.error});
    final seen = <PendingLogs>[];
    final sub = rows.listen(seen.add);
    repository.watches.single.feed.add(
      PendingLogs(items: [summary('a', status: null)], total: 7),
    );
    await pumpEventQueue();
    await sub.cancel();

    expect(repository.watches.single.levels, {LogLevel.error});
    expect(seen.single.total, 7);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/monitoring/domain`
Expected: FAIL to compile: `Error when reading 'lib/features/monitoring/domain/…': No such file or directory`.

- [ ] **Step 3: Add the three failures and their sentences**

A sealed class cannot be extended outside its library, and the spec says "the existing Failure model", so they join it. `OfflineFailure` is what `classifySyncFailure` calls `network`.

```diff
--- a/lib/core/error/failure.dart
+++ b/lib/core/error/failure.dart
@@ -33,6 +33,27 @@
 final class UnknownDatabaseFailure extends Failure {
   const UnknownDatabaseFailure({required super.cause})
     : super(message: 'Something went wrong.');
+}
+
+/// A read or change only an admin may make, from a caller that is not one or
+/// has no session (ADR-018 §7). The server's `FORBIDDEN`.
+final class NotAdminFailure extends Failure {
+  const NotAdminFailure({required super.cause})
+    : super(message: 'Only an admin can see this.');
+}
+
+/// A server call that never reached the server (no connection, a timeout).
+/// The kind of failure sync calls `network`.
+final class OfflineFailure extends Failure {
+  const OfflineFailure({required super.cause})
+    : super(message: "Can't reach the server.");
+}
+
+/// The server was reached and could not answer: an error of its own, or an
+/// answer this build cannot read.
+final class ServerFailure extends Failure {
+  const ServerFailure({required super.cause})
+    : super(message: "The server couldn't answer.");
 }
 
 /// Maps a raw exception from the Drift/sqlite3 boundary to one [Failure].
```

```diff
--- a/lib/l10n/failure_message.dart
+++ b/lib/l10n/failure_message.dart
@@ -9,5 +9,8 @@
     ConstraintFailure() => failureConstraint,
     DatabaseLockedFailure() => failureBusy,
     UnknownDatabaseFailure() => failureUnknown,
+    NotAdminFailure() => failureNotAdmin,
+    OfflineFailure() => failureOffline,
+    ServerFailure() => failureServer,
   };
 }
```

Append to `lib/l10n/app_en.arb` (a comma after the last entry, the new entries before the closing brace):

```json
  "failureNotAdmin": "Only an admin can see this.",
  "@failureNotAdmin": {
    "description": "A failure sentence (ADR-016 D3): the server refused a Monitoring call because the account is not an admin (FORBIDDEN), or has no session."
  },
  "failureOffline": "Can't reach the server. Nothing was lost.",
  "@failureOffline": {
    "description": "A failure sentence (ADR-016 D3): a server call never reached the server."
  },
  "failureServer": "The server couldn't answer. Nothing was lost. Try again in a moment.",
  "@failureServer": {
    "description": "A failure sentence (ADR-016 D3): the server answered with an error or an answer this build cannot read."
  }
```

and to `lib/l10n/app_vi.arb`:

```json
  "failureNotAdmin": "Chỉ quản trị viên mới xem được mục này.",
  "failureOffline": "Không kết nối được máy chủ. Không mất gì cả.",
  "failureServer": "Máy chủ chưa trả lời được. Không mất gì cả, thử lại sau một lát."
```

Run `flutter gen-l10n`.

- [ ] **Step 4: Write the domain**

Value objects and enums:

```dart
/// Where a warning or an error stands (ADR-018 §6). The names are the codes
/// of `app_log.status`. Other levels have none.
enum LogStatus {
  open,
  fixed;

  /// The status stored as [code], or null for a level with none.
  static LogStatus? parse(String? code) {
    for (final status in values) {
      if (status.name == code) return status;
    }
    return null;
  }
}
```

```dart
/// How far back the Time filter reaches (monitoring spec §3.2). The window is
/// relative, so the same filter asked again a minute later reaches a minute
/// further.
enum LogWindow {
  hour(Duration(hours: 1)),
  day(Duration(hours: 24)),
  week(Duration(days: 7)),
  month(Duration(days: 30)),
  all(null);

  const LogWindow(this.span);

  /// Null reaches back without limit.
  final Duration? span;

  /// The earliest time a log may have happened at, or null for [all].
  DateTime? since(DateTime now) {
    final reach = span;
    return reach == null ? null : now.subtract(reach);
  }
}
```

```dart
/// Where the next page of the server's logs starts: just after the row with
/// this time and id, in the order `log_query` pages by (newest first, then
/// id).
final class LogCursor {
  const LogCursor({required this.occurredAt, required this.id});

  final DateTime occurredAt;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is LogCursor && other.occurredAt == occurredAt && other.id == id;

  @override
  int get hashCode => Object.hash(occurredAt, id);
}
```

```dart
import 'package:collection/collection.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/log_window_model.dart';

/// What the Server tab asks the server for (monitoring spec §3.2). The
/// default is the admin's main job: open warnings and errors.
///
/// An empty set restricts nothing. A change is a `with…` call, so every
/// rule about how two choices interact lives here.
final class LogFilter {
  const LogFilter({
    this.levels = defaultLevels,
    this.statuses = defaultStatuses,
    this.categories = const {},
    this.window = LogWindow.all,
    this.deviceId,
    this.userId,
    this.search = '',
  });

  static const Set<LogLevel> defaultLevels = {LogLevel.warning, LogLevel.error};
  static const Set<LogStatus> defaultStatuses = {LogStatus.open};

  final Set<LogLevel> levels;
  final Set<LogStatus> statuses;
  final Set<LogCategory> categories;
  final LogWindow window;

  /// One device id, or null for every device.
  final String? deviceId;

  /// One user id (a uuid), or null for every user.
  final String? userId;

  /// Matched against `event` and `message`, as typed.
  final String search;

  /// The filter the screen opens with: nothing changed by the admin.
  bool get isDefault => this == const LogFilter();

  /// A debug or info row has no status, so a status filter would hide it:
  /// choosing one of those levels clears the status filter (the admin can set
  /// it again after).
  LogFilter withLevels(Set<LogLevel> next) {
    final hasStatusless =
        next.contains(LogLevel.debug) || next.contains(LogLevel.info);
    return _copy(levels: next, statuses: hasStatusless ? const {} : statuses);
  }

  LogFilter withStatuses(Set<LogStatus> next) => _copy(statuses: next);

  LogFilter withCategories(Set<LogCategory> next) => _copy(categories: next);

  LogFilter withWindow(LogWindow next) => _copy(window: next);

  /// A blank id is no device.
  LogFilter withDevice(String? id) => LogFilter(
    levels: levels,
    statuses: statuses,
    categories: categories,
    window: window,
    deviceId: _idOrNull(id),
    userId: userId,
    search: search,
  );

  /// A blank id is no user.
  LogFilter withUser(String? id) => LogFilter(
    levels: levels,
    statuses: statuses,
    categories: categories,
    window: window,
    deviceId: deviceId,
    userId: _idOrNull(id),
    search: search,
  );

  LogFilter withSearch(String text) => _copy(search: text.trim());

  LogFilter _copy({
    Set<LogLevel>? levels,
    Set<LogStatus>? statuses,
    Set<LogCategory>? categories,
    LogWindow? window,
    String? search,
  }) => LogFilter(
    levels: levels ?? this.levels,
    statuses: statuses ?? this.statuses,
    categories: categories ?? this.categories,
    window: window ?? this.window,
    deviceId: deviceId,
    userId: userId,
    search: search ?? this.search,
  );

  static String? _idOrNull(String? id) {
    final trimmed = id?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  @override
  bool operator ==(Object other) =>
      other is LogFilter &&
      const SetEquality<LogLevel>().equals(other.levels, levels) &&
      const SetEquality<LogStatus>().equals(other.statuses, statuses) &&
      const SetEquality<LogCategory>().equals(other.categories, categories) &&
      other.window == window &&
      other.deviceId == deviceId &&
      other.userId == userId &&
      other.search == search;

  @override
  int get hashCode => Object.hash(
    const SetEquality<LogLevel>().hash(levels),
    const SetEquality<LogStatus>().hash(statuses),
    const SetEquality<LogCategory>().hash(categories),
    window,
    deviceId,
    userId,
    search,
  );
}
```

```dart
import 'package:memox/features/monitoring/domain/entities/log_summary_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_cursor_model.dart';

/// One page of the server's logs, newest first.
final class LogPage {
  const LogPage({required this.items});

  /// The most a page holds; the server never sends more.
  static const int size = 100;

  final List<LogSummaryEntity> items;

  /// Where the next page starts, or null when this page was not full and so
  /// the last one.
  LogCursor? get next {
    if (items.length < size) return null;
    final last = items.last;
    return LogCursor(occurredAt: last.occurredAt, id: last.id);
  }
}
```

```dart
import 'package:memox/features/monitoring/domain/entities/log_summary_entity.dart';

/// The device buffer as the Not sent tab shows it: the newest rows of the
/// chosen levels, and how many rows wait in all, whatever the level.
final class PendingLogs {
  const PendingLogs({required this.items, required this.total});

  final List<LogSummaryEntity> items;
  final int total;
}
```

Entities:

```dart
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';

/// One row of the list (monitoring spec §3.2): what a row shows and nothing
/// heavier. The server sends the first 300 characters of the message and of
/// the error's message, the device buffer the same.
final class LogSummaryEntity {
  const LogSummaryEntity({
    required this.id,
    required this.occurredAt,
    required this.level,
    required this.event,
    this.message,
    this.errorMessage,
    this.errorType,
    this.status,
  });

  final String id;
  final DateTime occurredAt;
  final LogLevel level;
  final String event;
  final String? message;
  final String? errorMessage;
  final String? errorType;

  /// Null for a debug or info row, and for a row of the device buffer.
  final LogStatus? status;

  /// The row's second line: the message's first line, or else the first line
  /// of the error's message, or else the error's type; null when it has none
  /// of them.
  String? get subtitle {
    for (final text in [message, errorMessage]) {
      final line = text?.trim().split('\n').first.trim();
      if (line != null && line.isNotEmpty) return line;
    }
    final type = errorType?.trim();
    return type == null || type.isEmpty ? null : type;
  }

  LogSummaryEntity withStatus(LogStatus next) => LogSummaryEntity(
    id: id,
    occurredAt: occurredAt,
    level: level,
    event: event,
    message: message,
    errorMessage: errorMessage,
    errorType: errorType,
    status: next,
  );
}
```

```dart
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';

/// One log, whole (monitoring spec §3.3): the detail's read of a server row
/// or of a row of the device buffer.
final class LogRecordEntity {
  const LogRecordEntity({
    required this.id,
    required this.occurredAt,
    required this.level,
    required this.source,
    required this.category,
    required this.event,
    this.message,
    this.errorType,
    this.errorMessage,
    this.stackTrace,
    this.context = const {},
    this.userId,
    this.deviceId,
    this.appVersion,
    this.buildNumber,
    this.platform,
    this.osVersion,
    this.status,
    this.statusChangedAt,
    this.statusChangedBy,
    this.statusNote,
  });

  final String id;
  final DateTime occurredAt;
  final LogLevel level;

  /// `app` or `server`.
  final String source;

  /// The stored code, kept as text: a server newer than this build may hold
  /// a category this build does not know.
  final String category;
  final String event;
  final String? message;
  final String? errorType;
  final String? errorMessage;
  final String? stackTrace;
  final Map<String, Object?> context;
  final String? userId;
  final String? deviceId;
  final String? appVersion;
  final String? buildNumber;
  final String? platform;
  final String? osVersion;
  final LogStatus? status;
  final DateTime? statusChangedAt;
  final String? statusChangedBy;
  final String? statusNote;

  /// Only a warning or an error of the server has a status, and only such a
  /// row can be marked fixed or reopened (ADR-018 §6).
  bool get canTriage => status != null;

  /// Every field, as the Copy action puts it on the clipboard.
  Map<String, Object?> toJson() => {
    'id': id,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'level': level.name,
    'source': source,
    'category': category,
    'event': event,
    'message': message,
    'errorType': errorType,
    'errorMessage': errorMessage,
    'stackTrace': stackTrace,
    'context': context,
    'userId': userId,
    'deviceId': deviceId,
    'appVersion': appVersion,
    'buildNumber': buildNumber,
    'platform': platform,
    'osVersion': osVersion,
    'status': status?.name,
    'statusChangedAt': statusChangedAt?.toUtc().toIso8601String(),
    'statusChangedBy': statusChangedBy,
    'statusNote': statusNote,
  };
}
```

The rejection, the contract and the use cases (ADR-011 D4: one per interaction; an empty id is a programming error and throws):

```dart
/// Why Monitoring refuses a read or a change (ADR-011 D6).
enum MonitoringRejection {
  /// The log is gone: cleaned up by the retention job, or sent from the
  /// device since the list was drawn.
  notFound,
}
```

```dart
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_cursor_model.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';

/// The admin's reads and change of the logs (monitoring spec §4.1). The
/// server calls throw `NotAdminFailure`, `OfflineFailure` or `ServerFailure`;
/// a log that is gone is null.
abstract interface class MonitoringRepository {
  /// The page of `public.app_log` that follows [after] (the first page when
  /// null) for [filter], asked at [now] (the Time filter is relative).
  Future<LogPage> queryServer(
    LogFilter filter,
    LogCursor? after, {
    required DateTime now,
  });

  Future<LogRecordEntity?> getServer(String id);

  /// Marks the warning or error [id] [status], with an optional [note];
  /// returns the row as the server now holds it.
  Future<LogRecordEntity?> setStatus(String id, LogStatus status, String? note);

  /// The device buffer, again after every write.
  Stream<PendingLogs> watchPending(Set<LogLevel> levels);

  Future<LogRecordEntity?> getPending(String id);
}
```

```dart
import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/monitoring/domain/models/log_cursor_model.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/repositories/monitoring_repository.dart';

/// The Server tab's list: a page of the server's logs for [filter], starting
/// after [after] (the first page when null).
final class QueryServerLogsUseCase {
  const QueryServerLogsUseCase(this._logs, this._clock);

  final MonitoringRepository _logs;
  final DayClock _clock;

  Future<LogPage> call(LogFilter filter, {LogCursor? after}) =>
      _logs.queryServer(filter, after, now: _clock.now());
}
```

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/failures/monitoring_failure.dart';
import 'package:memox/features/monitoring/domain/repositories/monitoring_repository.dart';

/// The detail of a server log; `Rejected(notFound)` when it is gone.
final class GetServerLogUseCase {
  const GetServerLogUseCase(this._logs);

  final MonitoringRepository _logs;

  Future<Outcome<LogRecordEntity, MonitoringRejection>> call(String id) async {
    if (id.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');
    final record = await _logs.getServer(id);
    if (record == null) return const Rejected(MonitoringRejection.notFound);
    return Ok(record);
  }
}
```

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/failures/monitoring_failure.dart';
import 'package:memox/features/monitoring/domain/repositories/monitoring_repository.dart';

/// The detail of a log still in the device buffer; `Rejected(notFound)` when
/// it has been sent since the list was drawn.
final class GetPendingLogUseCase {
  const GetPendingLogUseCase(this._logs);

  final MonitoringRepository _logs;

  Future<Outcome<LogRecordEntity, MonitoringRejection>> call(String id) async {
    if (id.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');
    final record = await _logs.getPending(id);
    if (record == null) return const Rejected(MonitoringRejection.notFound);
    return Ok(record);
  }
}
```

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/failures/monitoring_failure.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/repositories/monitoring_repository.dart';

/// Marks a warning or error fixed, or reopens it (ADR-018 §6). A blank note
/// is no note; `Rejected(notFound)` when the log is gone.
final class SetLogStatusUseCase {
  const SetLogStatusUseCase(this._logs);

  final MonitoringRepository _logs;

  Future<Outcome<LogRecordEntity, MonitoringRejection>> call(
    String id,
    LogStatus status, {
    String? note,
  }) async {
    if (id.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');
    final trimmed = note?.trim();
    final record = await _logs.setStatus(
      id,
      status,
      trimmed == null || trimmed.isEmpty ? null : trimmed,
    );
    if (record == null) return const Rejected(MonitoringRejection.notFound);
    return Ok(record);
  }
}
```

```dart
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/features/monitoring/domain/repositories/monitoring_repository.dart';

/// The Not sent tab: the device buffer's newest rows of [levels] (every level
/// when empty), again after every write.
final class WatchPendingLogsUseCase {
  const WatchPendingLogsUseCase(this._logs);

  final MonitoringRepository _logs;

  Stream<PendingLogs> call(Set<LogLevel> levels) => _logs.watchPending(levels);
}
```

- [ ] **Step 5: Register the feature in the import map**

A new feature adds its entry in the commit that creates its folder (ADR-011 D2). Monitoring imports no other feature:

```diff
--- a/test/architecture/boundary_rules.dart
+++ b/test/architecture/boundary_rules.dart
@@ -30,6 +30,7 @@
   'transfer': {'card'},
   'starter_decks': {'deck', 'card', 'srs'},
   'reminders': {'settings', 'deck', 'srs'},
+  'monitoring': {},
 };
 
 const _package = 'package:memox/';
```

- [ ] **Step 6: Run the tests and the boundary checks**

Run: `flutter test test/features/monitoring/domain test/architecture test/app/l10n_test.dart`
Expected: PASS (`All tests passed!`).
Run: `python3 .claude/skills/flutter-architecture/scripts/check_architecture.py`
Expected: `✓ architecture boundaries clean`.

- [ ] **Step 7: Commit**

```bash
git add lib/core/error lib/l10n lib/features/monitoring/domain test/architecture test/support/monitoring_fakes.dart test/features/monitoring/domain
git commit -m "feat(monitoring): the domain of the log monitor, and three server failures"
```

---

### Task 6: The data layer

**Files:**
- Create: `lib/features/monitoring/data/datasources/monitoring_remote_data_source.dart`
- Create: `lib/features/monitoring/data/mappers/{log_mapper,monitoring_error_mapper}.dart`
- Create: `lib/features/monitoring/data/repositories/monitoring_repository_impl.dart`
- Test: `test/features/monitoring/data/{log_mapper_test,monitoring_error_mapper_test,monitoring_remote_data_source_test,monitoring_repository_test}.dart`

**Interfaces:**
- Consumes: Task 5's contract and entities; `RpcCall` (`lib/core/sync/supabase_sync_api.dart`); `classifySyncFailure`; `LogDatabase.watchPending/byId`, `PendingLog`, `PendingLogRows` (Task 2); `guardDatabase`, `DatabaseErrorStream.mapDatabaseErrors`.
- Produces:
  - `MonitoringRemoteDataSource({required RpcCall rpc, required bool Function() hasSession})` with `query(Map filter) → List<Map>` (`log_query`, arg `filter`), `get(id)` (`log_get`, arg `log_id`) and `setStatus(id, status, note)` (`log_set_status`, args `log_id`, `new_status`, `note`), both `Map?` (null on `NOT_FOUND`); throws `MonitoringSessionMissing` without calling when there is no session.
  - `queryFilterOf(LogFilter, LogCursor?, DateTime now)`; `summaryOfJson`, `recordOfJson`, `summaryOfPending`, `pendingLogsOf`, `recordOfEntry`.
  - `Failure mapMonitoringError(Object)`: `FORBIDDEN` and no session → `NotAdminFailure`; `classifySyncFailure` network → `OfflineFailure`; else `ServerFailure`.
  - `MonitoringRepositoryImpl({required MonitoringRemoteDataSource remote, required LogDatabase local})`.

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/data/mappers/log_mapper.dart';
import 'package:memox/features/monitoring/domain/models/log_cursor_model.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/log_window_model.dart';

// Monitoring spec §5: JSON to entity, missing fields, and the filter to JSON.
void main() {
  final now = DateTime.utc(2026, 9, 29, 12);

  test('the default filter asks for open warnings and errors, 100 a page', () {
    expect(queryFilterOf(const LogFilter(), null, now), {
      'levels': ['warning', 'error'],
      'statuses': ['open'],
      'limit': 100,
    });
  });

  test('a choice left open is left out, never an empty list', () {
    final json = queryFilterOf(
      const LogFilter().withLevels({}).withStatuses({}),
      null,
      now,
    );

    expect(json, {'limit': 100});
  });

  test('every choice is sent, the time as a moment, the device as a list', () {
    final filter = const LogFilter()
        .withCategories({LogCategory.db, LogCategory.sync})
        .withWindow(LogWindow.day)
        .withDevice('dev-1')
        .withUser('00000000-0000-0000-0000-00000000dead')
        .withSearch('push');
    final after = LogCursor(
      occurredAt: DateTime.utc(2026, 9, 29, 11, 30, 5, 123, 456),
      id: 'row-9',
    );

    expect(queryFilterOf(filter, after, now), {
      'levels': ['warning', 'error'],
      'statuses': ['open'],
      'categories': ['db', 'sync'],
      'search': 'push',
      'from': '2026-09-28T12:00:00.000Z',
      'deviceIds': ['dev-1'],
      'userId': '00000000-0000-0000-0000-00000000dead',
      'before': {'occurredAt': '2026-09-29T11:30:05.123456Z', 'id': 'row-9'},
      'limit': 100,
    });
  });

  test('a compact row becomes a summary', () {
    final row = summaryOfJson({
      'id': 'a',
      'occurred_at': '2026-09-29T10:00:00.5+00:00',
      'level': 'warning',
      'event': 'sync.rejected',
      'message': 'first line\nsecond',
      'error_message': 'Bad state: closed',
      'error_type': null,
      'status': 'open',
      'category': 'sync',
      'device_id': 'dev-1',
    });

    expect(row.occurredAt, DateTime.utc(2026, 9, 29, 10, 0, 0, 500));
    expect(row.level, LogLevel.warning);
    expect(row.status, LogStatus.open);
    expect(row.errorMessage, 'Bad state: closed');
    expect(row.subtitle, 'first line');
  });

  test('a compact row of a level with no status has none', () {
    final row = summaryOfJson({
      'id': 'a',
      'occurred_at': '2026-09-29T10:00:00+00:00',
      'level': 'debug',
      'event': 'db.query',
      'status': null,
    });

    expect(row.status, isNull);
    expect(row.message, isNull);
    expect(row.subtitle, isNull);
  });

  Map<String, Object?> full() => {
    'id': 'a',
    'occurred_at': '2026-09-26T08:30:15.25+00:00',
    'level': 'error',
    'source': 'server',
    'category': 'network',
    'event': 'server.exception',
    'message': 'boom',
    'error_type': 'StateError',
    'error_message': 'Bad state',
    'stack_trace': '#0 main',
    'context': {
      'sql': 'SELECT 1',
      'args': [1, 2],
    },
    'user_id': '00000000-0000-0000-0000-00000000dead',
    'device_id': 'dev-1',
    'app_version': '8.0.0',
    'build_number': '12',
    'platform': 'android',
    'os_version': '14',
    'status': 'fixed',
    'status_changed_at': '2026-09-27T09:00:00+00:00',
    'status_changed_by': '00000000-0000-0000-0000-0000000000ad',
    'status_note': 'index added',
    'received_at': '2026-09-26T08:31:00+00:00',
  };

  test('a whole row becomes a record, an unknown category kept as text', () {
    final record = recordOfJson(full());

    expect(record.category, 'network');
    expect(record.source, 'server');
    expect(record.context['args'], [1, 2]);
    expect(record.status, LogStatus.fixed);
    expect(record.statusChangedAt, DateTime.utc(2026, 9, 27, 9));
    expect(record.statusNote, 'index added');
    expect(record.canTriage, isTrue);
  });

  test('a row with only its required columns still maps', () {
    final record = recordOfJson({
      'id': 'a',
      'occurred_at': '2026-09-26T08:30:15+00:00',
      'level': 'info',
      'category': 'ui',
      'event': 'nav.push',
      'context': null,
    });

    expect(record.source, 'app');
    expect(record.context, isEmpty);
    expect(record.message, isNull);
    expect(record.stackTrace, isNull);
    expect(record.status, isNull);
    expect(record.statusChangedAt, isNull);
    expect(record.canTriage, isFalse);
  });

  test('a buffered row is an app row with no status', () {
    final record = recordOfEntry(
      LogEntry(
        id: 'a',
        occurredAt: now,
        level: LogLevel.error,
        category: LogCategory.sync,
        event: 'sync.failed',
        message: 'm',
        stackTrace: '#0 x',
        context: const {'k': 1},
        stamp: const LogStamp(deviceId: 'dev-1', platform: 'android'),
      ),
    );

    expect(record.source, 'app');
    expect(record.category, 'sync');
    expect(record.deviceId, 'dev-1');
    expect(record.platform, 'android');
    expect(record.canTriage, isFalse);
    expect(record.context, {'k': 1});
  });

  test('a buffered list row keeps the total of the buffer', () {
    final rows = pendingLogsOf(
      PendingLogRows(
        items: [
          PendingLog(
            id: 'a',
            occurredAt: now,
            level: LogLevel.warning,
            event: 'e',
            message: 'm',
            errorMessage: 'e',
          ),
        ],
        total: 42,
      ),
    );

    expect(rows.total, 42);
    expect(rows.items.single.id, 'a');
    expect(rows.items.single.errorMessage, 'e');
    expect(rows.items.single.status, isNull);
  });
}
```

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/monitoring/data/datasources/monitoring_remote_data_source.dart';
import 'package:memox/features/monitoring/data/mappers/monitoring_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthRetryableFetchException, PostgrestException;

// ADR-016 D2, monitoring spec §4.1: the server's errors as Failures.
void main() {
  test('FORBIDDEN is not an admin', () {
    const error = PostgrestException(message: 'FORBIDDEN', code: 'P0001');

    expect(mapMonitoringError(error), isA<NotAdminFailure>());
  });

  test('no session is not an admin', () {
    expect(
      mapMonitoringError(const MonitoringSessionMissing()),
      isA<NotAdminFailure>(),
    );
  });

  test('a call that never arrived is offline', () {
    for (final error in <Object>[
      const SocketException('no route'),
      TimeoutException('slow'),
      http.ClientException('reset'),
      AuthRetryableFetchException(message: 'offline'),
    ]) {
      expect(
        mapMonitoringError(error),
        isA<OfflineFailure>(),
        reason: '$error',
      );
    }
  });

  test('another server error, or an answer that cannot be read, is the '
      'server\'s', () {
    for (final error in <Object>[
      const PostgrestException(message: 'boom', code: '500'),
      const FormatException('not json'),
      StateError('odd'),
    ]) {
      expect(mapMonitoringError(error), isA<ServerFailure>(), reason: '$error');
    }
  });

  test('a Failure passes through, and its cause is kept', () {
    const failure = OfflineFailure(cause: 'x');

    expect(mapMonitoringError(failure), same(failure));
    expect(
      (mapMonitoringError(StateError('odd')) as ServerFailure).cause,
      isA<StateError>(),
    );
  });
}
```

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/monitoring/data/datasources/monitoring_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

// ADR-018 §7: the three admin RPCs, on the session sync holds.
void main() {
  final calls = <(String, Map<String, Object?>)>[];
  Object? answer;
  Object? error;
  var hasSession = true;

  MonitoringRemoteDataSource source() => MonitoringRemoteDataSource(
    rpc: (function, params) async {
      calls.add((function, params));
      if (error case final thrown?) throw thrown;
      return answer;
    },
    hasSession: () => hasSession,
  );

  setUp(() {
    calls.clear();
    answer = null;
    error = null;
    hasSession = true;
  });

  test('query sends the filter and returns the items', () async {
    answer = {
      'items': [
        {'id': 'a'},
        {'id': 'b'},
      ],
    };

    final rows = await source().query({'limit': 100});

    expect(calls.single.$1, 'log_query');
    expect(calls.single.$2, {
      'filter': {'limit': 100},
    });
    expect(rows.map((row) => row['id']), ['a', 'b']);
  });

  test('get and setStatus name their arguments as the SQL does', () async {
    answer = {'id': 'a'};

    await source().get('a');
    await source().setStatus('a', 'fixed', 'index added');

    expect(calls.map((call) => call.$1), ['log_get', 'log_set_status']);
    expect(calls[0].$2, {'log_id': 'a'});
    expect(calls[1].$2, {
      'log_id': 'a',
      'new_status': 'fixed',
      'note': 'index added',
    });
  });

  test('NOT_FOUND is null, for a read and for a change', () async {
    error = const PostgrestException(message: 'NOT_FOUND', code: 'P0001');

    expect(await source().get('a'), isNull);
    expect(await source().setStatus('a', 'open', null), isNull);
  });

  test('another error goes up as it is', () {
    error = const PostgrestException(message: 'FORBIDDEN', code: 'P0001');

    expect(source().get('a'), throwsA(isA<PostgrestException>()));
    expect(source().query({}), throwsA(isA<PostgrestException>()));
  });

  test('with no session the server is not asked', () async {
    hasSession = false;

    await expectLater(
      source().query({}),
      throwsA(isA<MonitoringSessionMissing>()),
    );
    await expectLater(
      source().setStatus('a', 'fixed', null),
      throwsA(isA<MonitoringSessionMissing>()),
    );
    expect(calls, isEmpty);
  });
}
```

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/data/datasources/monitoring_remote_data_source.dart';
import 'package:memox/features/monitoring/data/repositories/monitoring_repository_impl.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

// Monitoring spec §5: FORBIDDEN is not an admin, a network error is offline,
// and the buffer is read through the log database.
void main() {
  late LogDatabase local;
  late List<(String, Map<String, Object?>)> calls;
  Object? Function(String function) answer = (_) => null;
  final now = DateTime.utc(2026, 9, 29, 12);

  MonitoringRepositoryImpl repository() => MonitoringRepositoryImpl(
    remote: MonitoringRemoteDataSource(
      rpc: (function, params) async {
        calls.add((function, params));
        final result = answer(function);
        if (result is Exception) throw result;
        return result;
      },
      hasSession: () => true,
    ),
    local: local,
  );

  Map<String, Object?> compact(int i) => {
    'id': 'r$i',
    'occurred_at': DateTime.utc(2026, 9, 29, 11, 59 - i % 60).toIso8601String(),
    'level': 'error',
    'event': 'sync.failed',
    'message': 'm$i',
    'status': 'open',
  };

  setUp(() {
    local = LogDatabase(NativeDatabase.memory());
    calls = [];
    answer = (_) => null;
  });
  tearDown(() => local.close());

  test('a page maps its rows, and a full page has a next cursor', () async {
    answer = (_) => {
      'items': [for (var i = 0; i < LogPage.size; i++) compact(i)],
    };

    final page = await repository().queryServer(
      const LogFilter(),
      null,
      now: now,
    );

    expect(page.items, hasLength(100));
    expect(page.next!.id, 'r99');
    final sent = calls.single.$2['filter']! as Map<String, Object?>;
    expect(sent['levels'], ['warning', 'error']);
  });

  test('a short page is the last', () async {
    answer = (_) => {
      'items': [compact(0)],
    };

    final page = await repository().queryServer(
      const LogFilter(),
      null,
      now: now,
    );

    expect(page.next, isNull);
  });

  test('FORBIDDEN is a NotAdminFailure, for a read and a change', () async {
    answer = (_) => const PostgrestException(message: 'FORBIDDEN');

    await expectLater(
      repository().queryServer(const LogFilter(), null, now: now),
      throwsA(isA<NotAdminFailure>()),
    );
    await expectLater(
      repository().setStatus('a', LogStatus.fixed, null),
      throwsA(isA<NotAdminFailure>()),
    );
  });

  test('a network error is an OfflineFailure', () async {
    answer = (_) => const SocketException('no route');

    await expectLater(
      repository().queryServer(const LogFilter(), null, now: now),
      throwsA(isA<OfflineFailure>()),
    );
    await expectLater(
      repository().getServer('a'),
      throwsA(isA<OfflineFailure>()),
    );
  });

  test('a log that is gone is null', () async {
    answer = (_) => const PostgrestException(message: 'NOT_FOUND');

    expect(await repository().getServer('a'), isNull);
    expect(await repository().setStatus('a', LogStatus.open, null), isNull);
  });

  test('the row the server returns after a change is the record', () async {
    answer = (_) => {
      'id': 'a',
      'occurred_at': '2026-09-26T08:30:15+00:00',
      'level': 'error',
      'category': 'sync',
      'event': 'sync.failed',
      'status': 'fixed',
      'status_note': 'index added',
    };

    final record = await repository().setStatus(
      'a',
      LogStatus.fixed,
      'index added',
    );

    expect(record!.status, LogStatus.fixed);
    expect(record.statusNote, 'index added');
  });

  test('the buffer is watched and read through the log database', () async {
    await local.insertAll([
      LogEntry(
        id: 'a',
        occurredAt: now,
        level: LogLevel.error,
        category: LogCategory.sync,
        event: 'sync.failed',
        message: 'boom',
        stackTrace: '#0 x',
      ),
      LogEntry(
        id: 'b',
        occurredAt: now,
        level: LogLevel.debug,
        category: LogCategory.db,
        event: 'db.query',
      ),
    ]);

    final pending = await repository().watchPending({LogLevel.error}).first;
    final record = await repository().getPending('a');

    expect(pending.items.map((row) => row.id), ['a']);
    expect(pending.total, 2);
    expect(record!.stackTrace, '#0 x');
    expect(await repository().getPending('nope'), isNull);
  });

  test('a buffer read that fails is a database Failure', () async {
    await local.customStatement('DROP TABLE log_entry');

    await expectLater(
      repository().getPending('a'),
      throwsA(isA<UnknownDatabaseFailure>()),
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/monitoring/data`
Expected: FAIL to compile: `Error when reading 'lib/features/monitoring/data/…': No such file or directory`.

- [ ] **Step 3: Implement**

```dart
import 'package:memox/core/sync/supabase_sync_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// The admin RPCs of `public.app_log` (ADR-018 §7): `log_query`, `log_get`
/// and `log_set_status`, on the session sync already holds. It never signs
/// in: a caller with no session is not an admin.
final class MonitoringRemoteDataSource {
  MonitoringRemoteDataSource({required this._rpc, required this._hasSession});

  final RpcCall _rpc;
  final bool Function() _hasSession;

  static const _notFound = 'NOT_FOUND';

  /// The compact rows of one page, newest first.
  Future<List<Map<String, Object?>>> query(Map<String, Object?> filter) async {
    final json = await _call('log_query', {'filter': filter});
    return [
      for (final item in (json! as Map<String, Object?>)['items']! as List)
        item! as Map<String, Object?>,
    ];
  }

  /// One row whole, or null when it is gone.
  Future<Map<String, Object?>?> get(String id) =>
      _row('log_get', {'log_id': id});

  /// The row as the server now holds it, or null when it is gone.
  Future<Map<String, Object?>?> setStatus(
    String id,
    String status,
    String? note,
  ) => _row('log_set_status', {
    'log_id': id,
    'new_status': status,
    'note': note,
  });

  Future<Map<String, Object?>?> _row(
    String function,
    Map<String, Object?> params,
  ) async {
    try {
      final json = await _call(function, params);
      return json! as Map<String, Object?>;
    } on PostgrestException catch (error) {
      if (error.message == _notFound) return null;
      rethrow;
    }
  }

  Future<Object?> _call(String function, Map<String, Object?> params) async {
    if (!_hasSession()) throw const MonitoringSessionMissing();
    return _rpc(function, params);
  }
}

/// A Monitoring call with no session behind it: the caller cannot be an
/// admin, so the server is not asked.
final class MonitoringSessionMissing implements Exception {
  const MonitoringSessionMissing();

  @override
  String toString() => 'MonitoringSessionMissing: no session';
}
```

```dart
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/entities/log_summary_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_cursor_model.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';

/// The `filter` argument of `log_query` for [filter]. A choice left open is
/// left out: an empty list would match no row (`log_query` counts a list
/// only when it is a JSON array, and an array names what may match).
Map<String, Object?> queryFilterOf(
  LogFilter filter,
  LogCursor? after,
  DateTime now,
) {
  final since = filter.window.since(now);
  return {
    if (filter.levels.isNotEmpty)
      'levels': [for (final level in filter.levels) level.name],
    if (filter.statuses.isNotEmpty)
      'statuses': [for (final status in filter.statuses) status.name],
    if (filter.categories.isNotEmpty)
      'categories': [for (final category in filter.categories) category.name],
    if (filter.search.isNotEmpty) 'search': filter.search,
    if (since != null) 'from': since.toUtc().toIso8601String(),
    if (filter.deviceId case final device?) 'deviceIds': [device],
    'userId': ?filter.userId,
    if (after != null)
      'before': {
        'occurredAt': after.occurredAt.toUtc().toIso8601String(),
        'id': after.id,
      },
    'limit': LogPage.size,
  };
}

/// A compact row of `log_query`.
LogSummaryEntity summaryOfJson(Map<String, Object?> json) => LogSummaryEntity(
  id: json['id']! as String,
  occurredAt: DateTime.parse(json['occurred_at']! as String).toUtc(),
  level: LogLevel.values.byName(json['level']! as String),
  event: json['event']! as String,
  message: json['message'] as String?,
  errorMessage: json['error_message'] as String?,
  errorType: json['error_type'] as String?,
  status: LogStatus.parse(json['status'] as String?),
);

/// A whole row of `app_log`, as `log_get` and `log_set_status` return it
/// (`to_jsonb`, so snake_case and every column).
LogRecordEntity recordOfJson(Map<String, Object?> json) => LogRecordEntity(
  id: json['id']! as String,
  occurredAt: DateTime.parse(json['occurred_at']! as String).toUtc(),
  level: LogLevel.values.byName(json['level']! as String),
  source: json['source'] as String? ?? 'app',
  category: json['category']! as String,
  event: json['event']! as String,
  message: json['message'] as String?,
  errorType: json['error_type'] as String?,
  errorMessage: json['error_message'] as String?,
  stackTrace: json['stack_trace'] as String?,
  context: Map<String, Object?>.from(
    json['context'] as Map<String, Object?>? ?? const {},
  ),
  userId: json['user_id'] as String?,
  deviceId: json['device_id'] as String?,
  appVersion: json['app_version'] as String?,
  buildNumber: json['build_number'] as String?,
  platform: json['platform'] as String?,
  osVersion: json['os_version'] as String?,
  status: LogStatus.parse(json['status'] as String?),
  statusChangedAt: _timeOf(json['status_changed_at']),
  statusChangedBy: json['status_changed_by'] as String?,
  statusNote: json['status_note'] as String?,
);

DateTime? _timeOf(Object? text) =>
    text is String ? DateTime.parse(text).toUtc() : null;

/// A row of the device buffer, as a list shows it: no status, the buffer
/// never holds one.
LogSummaryEntity summaryOfPending(PendingLog row) => LogSummaryEntity(
  id: row.id,
  occurredAt: row.occurredAt,
  level: row.level,
  event: row.event,
  message: row.message,
  errorMessage: row.errorMessage,
  errorType: row.errorType,
);

PendingLogs pendingLogsOf(PendingLogRows rows) => PendingLogs(
  items: [for (final row in rows.items) summaryOfPending(row)],
  total: rows.total,
);

/// A row of the device buffer, whole. It is from this device, so `app`.
LogRecordEntity recordOfEntry(LogEntry entry) => LogRecordEntity(
  id: entry.id,
  occurredAt: entry.occurredAt,
  level: entry.level,
  source: 'app',
  category: entry.category.name,
  event: entry.event,
  message: entry.message,
  errorType: entry.errorType,
  errorMessage: entry.errorMessage,
  stackTrace: entry.stackTrace,
  context: entry.context,
  deviceId: entry.deviceId,
  appVersion: entry.appVersion,
  buildNumber: entry.stamp.buildNumber,
  platform: entry.stamp.platform,
  osVersion: entry.stamp.osVersion,
);
```

```dart
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/features/monitoring/data/datasources/monitoring_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

const _forbidden = 'FORBIDDEN';

/// The [Failure] a server call's error becomes at the repository boundary
/// (ADR-016 D2). The server's `FORBIDDEN` and a missing session are "not an
/// admin"; the rest is sync's classification: a call that never arrived is
/// offline, anything else is the server's.
Failure mapMonitoringError(Object error) {
  if (error is Failure) return error;
  if (error is MonitoringSessionMissing) return NotAdminFailure(cause: error);
  if (error is PostgrestException && error.message == _forbidden) {
    return NotAdminFailure(cause: error);
  }
  return switch (classifySyncFailure(error)) {
    SyncFailureKind.network => OfflineFailure(cause: error),
    SyncFailureKind.signIn ||
    SyncFailureKind.server ||
    SyncFailureKind.unknown => ServerFailure(cause: error),
  };
}
```

```dart
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/data/datasources/monitoring_remote_data_source.dart';
import 'package:memox/features/monitoring/data/mappers/log_mapper.dart';
import 'package:memox/features/monitoring/data/mappers/monitoring_error_mapper.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_cursor_model.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/features/monitoring/domain/repositories/monitoring_repository.dart';

/// The server's logs through the admin RPCs, and the device buffer through
/// [LogDatabase] (which already is the buffer's data access, so no data
/// source stands between them).
final class MonitoringRepositoryImpl implements MonitoringRepository {
  MonitoringRepositoryImpl({required this._remote, required this._local});

  final MonitoringRemoteDataSource _remote;
  final LogDatabase _local;

  @override
  Future<LogPage> queryServer(
    LogFilter filter,
    LogCursor? after, {
    required DateTime now,
  }) => _server(() async {
    final rows = await _remote.query(queryFilterOf(filter, after, now));
    return LogPage(items: [for (final row in rows) summaryOfJson(row)]);
  });

  @override
  Future<LogRecordEntity?> getServer(String id) => _server(() async {
    final row = await _remote.get(id);
    return row == null ? null : recordOfJson(row);
  });

  @override
  Future<LogRecordEntity?> setStatus(
    String id,
    LogStatus status,
    String? note,
  ) => _server(() async {
    final row = await _remote.setStatus(id, status.name, note);
    return row == null ? null : recordOfJson(row);
  });

  @override
  Stream<PendingLogs> watchPending(Set<LogLevel> levels) => _local
      .watchPending(levels: levels)
      .map(pendingLogsOf)
      .mapDatabaseErrors();

  @override
  Future<LogRecordEntity?> getPending(String id) => guardDatabase(() async {
    final entry = await _local.byId(id);
    return entry == null ? null : recordOfEntry(entry);
  });

  /// [body], with any error leaving as the [Failure] of
  /// [mapMonitoringError], with its stack trace.
  Future<T> _server<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapMonitoringError(error), stackTrace);
    }
  }
}
```

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/monitoring test/architecture`
Expected: PASS (`All tests passed!`).

- [ ] **Step 5: Commit**

```bash
git add lib/features/monitoring/data test/features/monitoring/data
git commit -m "feat(monitoring): the data layer over the admin RPCs and the device buffer"
```

---

### Task 7: Admin detection and the Settings entry

**Files:**
- Create: `lib/features/monitoring/di/{auth_session_provider,is_admin_provider,monitoring_repository_provider}.dart`
- Create: `lib/features/monitoring/presentation/widgets/sections/monitoring_entry_section_widget.dart`
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/monitoring/di/is_admin_provider_test.dart`, `test/features/monitoring/presentation/monitoring_entry_section_test.dart`

**Interfaces:**
- Consumes: `supabaseConfigProvider` (`lib/core/sync/di/sync_providers.dart`), `logDatabaseProvider` (`lib/core/logging/di/logging_providers.dart`), `sessionWithRole` (Task 5).
- Produces:
  - `authSessionProvider: Stream<Session?>` (the current session, then every `onAuthStateChange`; overridable, since `Supabase.instance` is a singleton).
  - `bool isAdminSession(Session?)` and `isAdminProvider: bool` (false when `supabaseConfigProvider.isEnabled` is false).
  - `monitoringRepositoryProvider: MonitoringRepository` (built from `Supabase.instance.client`; read only from Monitoring's screens).
  - `MonitoringEntrySectionWidget({required VoidCallback onOpen})`; `SettingsScreen({..., Widget? adminSection})` draws it after the Sync section.
  - ARB: `settingsAdmin`, `settingsMonitoring`, `settingsMonitoringHint`.

- [ ] **Step 1: Write the failing tests**

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/network/supabase_config.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/features/monitoring/di/auth_session_provider.dart';
import 'package:memox/features/monitoring/di/is_admin_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session, User;

import '../../../support/monitoring_fakes.dart';

// ADR-018 §7, monitoring spec §4.4: the entry shows for an admin's session,
// and follows the session when a refreshed token adds the role.
void main() {
  test('an admin role in app_metadata is an admin, nothing else is', () {
    expect(isAdminSession(sessionWithRole('admin')), isTrue);
    expect(isAdminSession(sessionWithRole(null)), isFalse);
    expect(isAdminSession(sessionWithRole('editor')), isFalse);
    expect(isAdminSession(null), isFalse);
  });

  test('a role only in user_metadata is not an admin', () {
    final session = Session(
      accessToken: 'token',
      tokenType: 'bearer',
      user: const User(
        id: 'u',
        appMetadata: {},
        userMetadata: {'role': 'admin'},
        aud: 'authenticated',
        createdAt: '2026-09-29T00:00:00Z',
      ),
    );

    expect(isAdminSession(session), isFalse);
  });

  test('a build with no Supabase project has no admin', () {
    final container = ProviderContainer(
      overrides: [
        supabaseConfigProvider.overrideWithValue(
          const SupabaseConfig(url: '', publishableKey: ''),
        ),
        authSessionProvider.overrideWith(
          (ref) => Stream.value(sessionWithRole('admin')),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(isAdminProvider, (_, _) {});

    expect(container.read(isAdminProvider), isFalse);
  });

  // Review focus: a token refresh that adds the admin role while Settings is
  // open.
  test('a refreshed token that adds the role turns it on, and a sign-out '
      'turns it off', () async {
    final sessions = StreamController<Session?>();
    addTearDown(sessions.close);
    final container = ProviderContainer(
      overrides: [
        supabaseConfigProvider.overrideWithValue(
          const SupabaseConfig(
            url: 'https://x.supabase.co',
            publishableKey: 'k',
          ),
        ),
        authSessionProvider.overrideWith((ref) => sessions.stream),
      ],
    );
    addTearDown(container.dispose);
    final seen = <bool>[];
    container.listen(isAdminProvider, (_, next) => seen.add(next));

    expect(container.read(isAdminProvider), isFalse);
    sessions.add(sessionWithRole(null));
    await pumpEventQueue();
    sessions.add(sessionWithRole('admin'));
    await pumpEventQueue();
    expect(container.read(isAdminProvider), isTrue);
    sessions.add(null);
    await pumpEventQueue();

    expect(container.read(isAdminProvider), isFalse);
    expect(seen, [true, false]);
  });
}
```

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/network/supabase_config.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/features/monitoring/di/auth_session_provider.dart';
import 'package:memox/features/monitoring/di/is_admin_provider.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_entry_section_widget.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session;

import '../../../support/library_harness.dart';
import '../../../support/monitoring_fakes.dart';

// Monitoring spec §3.1, §5: the entry shows only for an admin.
SettingsScreen _screen({required void Function() onOpen}) => SettingsScreen(
  onOpenTheme: () {},
  onOpenLanguage: () {},
  onOpenReminder: () {},
  onAppOptionsReset: () {},
  onOpenSync: () {},
  adminSection: MonitoringEntrySectionWidget(onOpen: onOpen),
);

const _enabled = SupabaseConfig(
  url: 'https://x.supabase.co',
  publishableKey: 'key',
);

void main() {
  libraryTest('a non-admin sees no Admin section at all', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen(onOpen: () {}));
    await tester.scrollUntilVisible(find.text('Reset app options'), 200);

    expect(find.text('ADMIN'), findsNothing);
    expect(find.text('Monitoring'), findsNothing);
  });

  libraryTest('an admin sees Monitoring and it opens the screen', (
    tester,
    env,
  ) async {
    var opened = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(onOpen: () => opened++),
      overrides: [isAdminProvider.overrideWithValue(true)],
    );
    await tester.scrollUntilVisible(find.text('Monitoring'), 200);

    expect(find.text('ADMIN'), findsOneWidget);
    expect(find.text('Logs of the app and the server'), findsOneWidget);
    await tester.tap(find.text('Monitoring'));
    expect(opened, 1);
  });

  libraryTest('a build with no Supabase shows nothing, whatever the session', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen(onOpen: () {}),
      overrides: [
        supabaseConfigProvider.overrideWithValue(
          const SupabaseConfig(url: '', publishableKey: ''),
        ),
        authSessionProvider.overrideWith(
          (ref) => Stream.value(sessionWithRole('admin')),
        ),
      ],
    );
    await tester.scrollUntilVisible(find.text('Reset app options'), 200);

    expect(find.text('Monitoring'), findsNothing);
  });

  // Review focus: a token refresh that adds the admin role while Settings is
  // open.
  libraryTest('a token refresh that adds the role shows the row without a '
      'restart, and a sign-out hides it', (tester, env) async {
    final sessions = StreamController<Session?>();
    addTearDown(sessions.close);
    await pumpLibraryScreen(
      tester,
      env,
      _screen(onOpen: () {}),
      overrides: [
        supabaseConfigProvider.overrideWithValue(_enabled),
        authSessionProvider.overrideWith((ref) => sessions.stream),
      ],
    );
    sessions.add(sessionWithRole(null));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Reset app options'), 200);
    expect(find.text('Monitoring'), findsNothing);

    sessions.add(sessionWithRole('admin'));
    await tester.pump();
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Monitoring'), 200);
    expect(find.text('Monitoring'), findsOneWidget);

    sessions.add(null);
    await tester.pump();
    await tester.pump();
    expect(find.text('Monitoring'), findsNothing);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/monitoring/di test/features/monitoring/presentation/monitoring_entry_section_test.dart`
Expected: FAIL to compile: `Error when reading 'lib/features/monitoring/di/…'`.

- [ ] **Step 3: Write the providers**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_session_provider.g.dart';

/// The Supabase session now, and again whenever it changes: a sign-in, a
/// sign-out or a token refresh (which is how a role set on the account
/// arrives). Read only when this build names a Supabase project; a test
/// overrides it, since `Supabase.instance` is a singleton.
@Riverpod(keepAlive: true)
Stream<Session?> authSession(Ref ref) async* {
  final auth = Supabase.instance.client.auth;
  yield auth.currentSession;
  yield* auth.onAuthStateChange.map((state) => state.session);
}
```

```dart
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/features/monitoring/di/auth_session_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session;

part 'is_admin_provider.g.dart';

const _adminRole = 'admin';

/// Whether [session]'s account is an admin (ADR-018 §7): `app_metadata.role`,
/// which only the service role and the dashboard can set.
bool isAdminSession(Session? session) =>
    session?.user.appMetadata['role'] == _adminRole;

/// Whether to show the Monitoring entry: the session's account is an admin.
/// False for a build with no Supabase project. It only decides visibility;
/// the RPCs check the role again (`FORBIDDEN`).
@Riverpod(keepAlive: true)
bool isAdmin(Ref ref) {
  if (!ref.watch(supabaseConfigProvider).isEnabled) return false;
  return isAdminSession(ref.watch(authSessionProvider).value);
}
```

```dart
import 'package:memox/core/logging/di/logging_providers.dart';
import 'package:memox/features/monitoring/data/datasources/monitoring_remote_data_source.dart';
import 'package:memox/features/monitoring/data/repositories/monitoring_repository_impl.dart';
import 'package:memox/features/monitoring/domain/repositories/monitoring_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'monitoring_repository_provider.g.dart';

/// The admin RPCs through the Supabase project main.dart initialized, and
/// the device's log buffer. Read only from Monitoring's screens, which only
/// an admin of a build with Supabase reaches.
@riverpod
MonitoringRepository monitoringRepository(Ref ref) {
  final client = Supabase.instance.client;
  return MonitoringRepositoryImpl(
    remote: MonitoringRemoteDataSource(
      rpc: (function, params) => client.rpc<Object?>(function, params: params),
      hasSession: () => client.auth.currentSession != null,
    ),
    local: ref.watch(logDatabaseProvider),
  );
}
```

- [ ] **Step 4: Write the entry, its strings and the Settings slot**

Settings takes the section as a slot, the way `DeckLevelScreen` takes `cardContent`, so Settings imports nothing from Monitoring (`app/` composes them in Task 11).

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/monitoring/di/is_admin_provider.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// Screen 23's Admin section (monitoring spec §3.1): one row opening
/// Monitoring, shown only while the session's account is an admin, and gone
/// again if it stops being one. Settings takes it as a slot, so the two
/// features stay apart; `app/` composes them.
class MonitoringEntrySectionWidget extends ConsumerWidget {
  const MonitoringEntrySectionWidget({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isAdminProvider)) return const SizedBox.shrink();
    final l10n = context.l10n;
    return MxSection(
      title: l10n.settingsAdmin,
      children: [
        MxSettingsRow(
          label: l10n.settingsMonitoring,
          subtitle: l10n.settingsMonitoringHint,
          icon: AppIcons.monitoring,
          onTap: onOpen,
        ),
      ],
    );
  }
}
```

```diff
--- a/lib/features/settings/presentation/screens/settings_screen.dart
+++ b/lib/features/settings/presentation/screens/settings_screen.dart
@@ -35,6 +35,7 @@
     required this.onOpenReminder,
     required this.onAppOptionsReset,
     required this.onOpenSync,
+    this.adminSection,
     this.onOpenGallery,
   });
 
@@ -48,6 +49,10 @@
 
   /// Opens screen 27 (SB-U1).
   final VoidCallback onOpenSync;
+
+  /// The Admin section, which `app/` composes from Monitoring (monitoring
+  /// spec §3.1): a widget that draws nothing unless the account is an admin.
+  final Widget? adminSection;
 
   /// Debug builds only: opens the component gallery.
   final VoidCallback? onOpenGallery;
@@ -93,6 +98,7 @@
                 now: ref.watch(dayClockProvider).now(),
                 onOpenSync: onOpenSync,
               ),
+            ?adminSection,
             MxSection(
               title: l10n.settingsReset,
               note: l10n.settingsResetNote,
```

Append to `lib/l10n/app_en.arb`:

```json
  "settingsAdmin": "Admin",
  "@settingsAdmin": {
    "description": "Screen 23 (Monitoring): the section title of the admin-only entry."
  },
  "settingsMonitoring": "Monitoring",
  "@settingsMonitoring": {
    "description": "Screen 23 (Monitoring): the row that opens screen 28."
  },
  "settingsMonitoringHint": "Logs of the app and the server",
  "@settingsMonitoringHint": {
    "description": "Screen 23 (Monitoring): the Monitoring row subtitle."
  }
```

and to `lib/l10n/app_vi.arb`:

```json
  "settingsAdmin": "Quản trị",
  "settingsMonitoring": "Giám sát",
  "settingsMonitoringHint": "Nhật ký của ứng dụng và máy chủ"
```

- [ ] **Step 5: Generate and run**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter gen-l10n`
Run: `flutter test test/features/monitoring test/features/settings test/app/l10n_test.dart`
Expected: PASS (`All tests passed!`); the existing Settings tests and goldens are unchanged (`adminSection` is optional).

- [ ] **Step 6: Commit**

```bash
git add lib/features/monitoring/di lib/features/monitoring/presentation/widgets/sections/monitoring_entry_section_widget.dart lib/features/settings lib/l10n test/features/monitoring
git commit -m "feat(monitoring): admin detection and the Settings entry"
```

---

### Task 8: The list and Not sent controllers

**Files:**
- Create: `lib/features/monitoring/presentation/states/{monitoring_load_failure_state,monitoring_list_state,pending_logs_state}.dart`
- Create: `lib/features/monitoring/presentation/providers/{query_server_logs,get_server_log,get_pending_log,set_log_status,watch_pending_logs}_use_case_provider.dart`
- Create: `lib/features/monitoring/presentation/controllers/{monitoring_list_controller,pending_logs_controller}.dart`
- Test: `test/features/monitoring/presentation/{monitoring_list_controller_test,pending_logs_controller_test}.dart`

**Interfaces:**
- Consumes: Task 5's use cases and fakes; `monitoringRepositoryProvider` (Task 7); `dayClockProvider`.
- Produces:
  - `enum MonitoringLoadFailure {notAdmin, offline, other}` with `MonitoringLoadFailure.of(Object error)`.
  - `enum MonitoringMore {idle, loading, failed}`; sealed `MonitoringListContent` = `MonitoringListLoading | MonitoringListLoaded(items, next, more) | MonitoringListFailed(failure)`; `MonitoringListState({filter, content})`.
  - `PendingLogsState({levels, logs: AsyncValue<PendingLogs>})`.
  - Use-case providers `queryServerLogsUseCaseProvider`, `getServerLogUseCaseProvider`, `getPendingLogUseCaseProvider`, `setLogStatusUseCaseProvider`, `watchPendingLogsUseCaseProvider`.
  - `monitoringListControllerProvider` (auto-dispose): `setFilter(LogFilter)`, `clearFilters()`, `retry()`, `search(String)` (`monitoringSearchDebounce` = 400 ms), `Future<void> refresh()`, `Future<void> loadMore()`, `statusChanged(String id, LogStatus)`. The first page is asked from a microtask after `build`.
  - `pendingLogsControllerProvider`: `setLevels(Set<LogLevel>)`; starts on warning and error.

- [ ] **Step 1: Write the failing tests**

The list controller's tests run in fake time. The four "stale" tests are Review Focus 2.

```dart
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_list_controller.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_list_state.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_load_failure_state.dart';

import '../../../support/monitoring_fakes.dart';

// Monitoring spec §3.2, §3.5, §5: default filter, pages, a filter change
// starts again, and a stale answer never overwrites a newer one.

typedef _Body = void Function(
  FakeAsync async,
  MonitoringListController controller,
  MonitoringListState Function() state,
  FakeMonitoringRepository repository,
);

/// Runs [body] in fake time over a container whose repository is the fake,
/// after the first ask (made in a microtask) has been made.
void _run(_Body body) {
  fakeAsync((async) {
    final repository = FakeMonitoringRepository();
    final container = ProviderContainer(
      overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
    );
    final keepAlive = container.listen(
      monitoringListControllerProvider,
      (_, _) {},
    );
    async.flushMicrotasks();
    body(
      async,
      container.read(monitoringListControllerProvider.notifier),
      () => container.read(monitoringListControllerProvider),
      repository,
    );
    keepAlive.close();
    container.dispose();
    async.flushMicrotasks();
  });
}

MonitoringListLoaded _loaded(MonitoringListState state) =>
    state.content as MonitoringListLoaded;

List<String> _ids(MonitoringListState state) => [
  for (final item in _loaded(state).items) item.id,
];

void main() {
  test('it opens on open warnings and errors, loading the first page', () {
    _run((async, controller, state, repository) {
      expect(state().filter.isDefault, isTrue);
      expect(state().content, isA<MonitoringListLoading>());
      expect(repository.queries, hasLength(1));
      expect(repository.lastQuery.filter, const LogFilter());
      expect(repository.lastQuery.after, isNull);

      repository.lastQuery.answer(pageOf(3));
      async.flushMicrotasks();

      expect(_ids(state()), ['r0', 'r1', 'r2']);
      expect(_loaded(state()).next, isNull);
    });
  });

  test(
    'a full page is followed by the next, and a short one ends the list',
    () {
      _run((async, controller, state, repository) {
        repository.lastQuery.answer(pageOf(LogPage.size));
        async.flushMicrotasks();
        final cursor = _loaded(state()).next;
        expect(cursor!.id, 'r99');

        unawaited(controller.loadMore());
        expect(_loaded(state()).more, MonitoringMore.loading);
        expect(repository.lastQuery.after, cursor);
        repository.lastQuery.answer(pageOf(5, prefix: 'p'));
        async.flushMicrotasks();

        expect(_loaded(state()).items, hasLength(LogPage.size + 5));
        expect(_loaded(state()).next, isNull);
        expect(_loaded(state()).more, MonitoringMore.idle);

        unawaited(controller.loadMore());
        expect(
          repository.queries,
          hasLength(2),
          reason: 'the end asks nothing',
        );
      });
    },
  );

  test('a second loadMore while one is in flight asks nothing', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(LogPage.size));
      async.flushMicrotasks();

      unawaited(controller.loadMore());
      unawaited(controller.loadMore());

      expect(repository.queries, hasLength(2));
    });
  });

  test('a failed page keeps the rows and loadMore is its retry', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(LogPage.size));
      async.flushMicrotasks();

      unawaited(controller.loadMore());
      repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
      async.flushMicrotasks();

      expect(_loaded(state()).more, MonitoringMore.failed);
      expect(_loaded(state()).items, hasLength(LogPage.size));

      unawaited(controller.loadMore());
      repository.lastQuery.answer(pageOf(2, prefix: 'p'));
      async.flushMicrotasks();

      expect(_loaded(state()).items, hasLength(LogPage.size + 2));
      expect(_loaded(state()).more, MonitoringMore.idle);
    });
  });

  test('a filter change starts again from the first page', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(LogPage.size));
      async.flushMicrotasks();

      final next = const LogFilter().withCategories({LogCategory.sync});
      controller.setFilter(next);

      expect(state().filter, next);
      expect(state().content, isA<MonitoringListLoading>());
      expect(repository.lastQuery.filter, next);
      expect(repository.lastQuery.after, isNull);
    });
  });

  test('the same filter again asks nothing', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(1));
      async.flushMicrotasks();

      controller.setFilter(const LogFilter());

      expect(repository.queries, hasLength(1));
    });
  });

  // Review focus: a filter change while a page is loading.
  test('a slow answer to the old filter never overwrites the new one', () {
    _run((async, controller, state, repository) {
      final old = repository.lastQuery;
      controller.setFilter(const LogFilter().withCategories({LogCategory.db}));
      final fresh = repository.lastQuery;

      fresh.answer(pageOf(2, prefix: 'new'));
      async.flushMicrotasks();
      old.answer(pageOf(4, prefix: 'old'));
      async.flushMicrotasks();

      expect(_ids(state()), ['new0', 'new1']);
      expect(state().filter.categories, {LogCategory.db});
    });
  });

  test('an old answer that lands first is dropped too', () {
    _run((async, controller, state, repository) {
      final old = repository.lastQuery;
      controller.setFilter(const LogFilter().withCategories({LogCategory.db}));
      final fresh = repository.lastQuery;

      old.answer(pageOf(4, prefix: 'old'));
      async.flushMicrotasks();
      expect(state().content, isA<MonitoringListLoading>());
      fresh.answer(pageOf(2, prefix: 'new'));
      async.flushMicrotasks();

      expect(_ids(state()), ['new0', 'new1']);
    });
  });

  test('an old failure never replaces the new rows', () {
    _run((async, controller, state, repository) {
      final old = repository.lastQuery;
      controller.setFilter(const LogFilter().withCategories({LogCategory.db}));

      repository.lastQuery.answer(pageOf(1, prefix: 'new'));
      async.flushMicrotasks();
      old.fail(const OfflineFailure(cause: 'x'));
      async.flushMicrotasks();

      expect(_ids(state()), ['new0']);
    });
  });

  test('a next page that lands after a filter change is dropped', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(LogPage.size));
      async.flushMicrotasks();
      unawaited(controller.loadMore());
      final more = repository.lastQuery;

      controller.setFilter(const LogFilter().withCategories({LogCategory.db}));
      repository.lastQuery.answer(pageOf(1, prefix: 'new'));
      async.flushMicrotasks();
      more.answer(pageOf(5, prefix: 'late'));
      async.flushMicrotasks();

      expect(_ids(state()), ['new0']);
    });
  });

  test('the search asks once, 400 ms after the last keystroke', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(1));
      async.flushMicrotasks();

      controller.search('pu');
      async.elapse(monitoringSearchDebounce - const Duration(milliseconds: 1));
      controller.search('push');
      async.elapse(monitoringSearchDebounce - const Duration(milliseconds: 1));
      expect(repository.queries, hasLength(1));

      async.elapse(const Duration(milliseconds: 1));

      expect(repository.queries, hasLength(2));
      expect(repository.lastQuery.filter.search, 'push');
      expect(state().filter.search, 'push');
    });
  });

  test('a pull to refresh keeps the rows until the first page lands', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(2));
      async.flushMicrotasks();

      var isDone = false;
      controller.refresh().then((_) => isDone = true);
      expect(_ids(state()), ['r0', 'r1']);
      expect(isDone, isFalse);
      repository.lastQuery.answer(pageOf(1, prefix: 'n'));
      async.flushMicrotasks();

      expect(_ids(state()), ['n0']);
      expect(isDone, isTrue);
    });
  });

  test('a failure is told apart: not an admin, offline, or other', () {
    for (final (error, expected) in <(Object, MonitoringLoadFailure)>[
      (const NotAdminFailure(cause: 'x'), MonitoringLoadFailure.notAdmin),
      (const OfflineFailure(cause: 'x'), MonitoringLoadFailure.offline),
      (const ServerFailure(cause: 'x'), MonitoringLoadFailure.other),
      (StateError('odd'), MonitoringLoadFailure.other),
    ]) {
      _run((async, controller, state, repository) {
        repository.lastQuery.fail(error);
        async.flushMicrotasks();

        expect((state().content as MonitoringListFailed).failure, expected);
      });
    }
  });

  test('a retry after a failure asks the first page again', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
      async.flushMicrotasks();

      controller.setFilter(const LogFilter().withSearch('a'));
      repository.lastQuery.answer(pageOf(1));
      async.flushMicrotasks();

      expect(_ids(state()), ['r0']);
    });
  });

  test('clearing the filters resets every filter and the search', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(1));
      async.flushMicrotasks();
      controller.setFilter(
        const LogFilter().withSearch('push').withCategories({LogCategory.db}),
      );
      repository.lastQuery.answer(pageOf(0));
      async.flushMicrotasks();

      controller.clearFilters();

      expect(state().filter.isDefault, isTrue);
      expect(repository.lastQuery.filter, const LogFilter());
    });
  });

  test('a row marked fixed leaves the default list', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(3));
      async.flushMicrotasks();

      controller.statusChanged('r1', LogStatus.fixed);

      expect(_ids(state()), ['r0', 'r2']);
    });
  });

  test('with no status filter the row stays and shows its new status', () {
    _run((async, controller, state, repository) {
      repository.lastQuery.answer(pageOf(1));
      async.flushMicrotasks();
      controller.setFilter(const LogFilter().withStatuses({}));
      repository.lastQuery.answer(pageOf(2));
      async.flushMicrotasks();

      controller.statusChanged('r1', LogStatus.fixed);

      expect(_ids(state()), ['r0', 'r1']);
      expect(_loaded(state()).items[1].status, LogStatus.fixed);
      expect(_loaded(state()).items[0].status, LogStatus.open);
    });
  });
}
```

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/features/monitoring/presentation/controllers/pending_logs_controller.dart';

import '../../../support/monitoring_fakes.dart';

// Monitoring spec §3.2: the Not sent tab watches the device buffer.
void main() {
  late FakeMonitoringRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeMonitoringRepository();
    container = ProviderContainer(
      overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(pendingLogsControllerProvider, (_, _) {});
  });

  PendingLogs rows(int count, {int total = 0}) => PendingLogs(
    items: [for (var i = 0; i < count; i++) summary('p$i', status: null)],
    total: total,
  );

  test(
    'it watches warnings and errors first, and shows what arrives',
    () async {
      expect(repository.watches.single.levels, {
        LogLevel.warning,
        LogLevel.error,
      });
      expect(
        container.read(pendingLogsControllerProvider).logs.isLoading,
        isTrue,
      );

      repository.watches.single.feed.add(rows(2, total: 9));
      await pumpEventQueue();

      final logs = container
          .read(pendingLogsControllerProvider)
          .logs
          .requireValue;
      expect(logs.items, hasLength(2));
      expect(logs.total, 9);
    },
  );

  test('new levels watch again, keep the rows until the answer, and stop '
      'the old watch', () async {
    repository.watches.single.feed.add(rows(2));
    await pumpEventQueue();

    container.read(pendingLogsControllerProvider.notifier).setLevels({
      LogLevel.debug,
    });

    expect(repository.watches, hasLength(2));
    expect(repository.watches.last.levels, {LogLevel.debug});
    expect(repository.watches.first.feed.hasListener, isFalse);
    final state = container.read(pendingLogsControllerProvider);
    expect(state.levels, {LogLevel.debug});
    expect(state.logs.requireValue.items, hasLength(2));

    repository.watches.last.feed.add(rows(1));
    await pumpEventQueue();
    expect(
      container.read(pendingLogsControllerProvider).logs.requireValue.items,
      hasLength(1),
    );
  });

  test('every write to the buffer shows', () async {
    final feed = repository.watches.single.feed;

    feed.add(rows(1, total: 1));
    await pumpEventQueue();
    feed.add(rows(3, total: 3));
    await pumpEventQueue();

    expect(
      container.read(pendingLogsControllerProvider).logs.requireValue.total,
      3,
    );
  });

  test('a watch that fails shows its error', () async {
    repository.watches.single.feed.addError(StateError('closed'));
    await pumpEventQueue();

    expect(container.read(pendingLogsControllerProvider).logs.hasError, isTrue);
  });

  test('disposing stops the watch', () async {
    container.dispose();

    expect(repository.watches.single.feed.hasListener, isFalse);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/monitoring/presentation/monitoring_list_controller_test.dart test/features/monitoring/presentation/pending_logs_controller_test.dart`
Expected: FAIL to compile: `Error when reading 'lib/features/monitoring/presentation/…'`.

- [ ] **Step 3: Write the states**

```dart
import 'package:memox/core/error/failure.dart';

/// Why a Monitoring read failed, as the screens tell it apart (monitoring
/// spec §3.4): not an admin, offline, or anything else.
enum MonitoringLoadFailure {
  notAdmin,
  offline,
  other;

  /// The kind of [error], which is a `Failure` from the repository.
  static MonitoringLoadFailure of(Object error) => switch (error) {
    NotAdminFailure() => notAdmin,
    OfflineFailure() => offline,
    _ => other,
  };
}
```

```dart
import 'package:flutter/foundation.dart';
import 'package:memox/features/monitoring/domain/entities/log_summary_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_cursor_model.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_load_failure_state.dart';

/// Where the next page stands (monitoring spec §3.2).
enum MonitoringMore { idle, loading, failed }

/// What the Server tab's rows are.
sealed class MonitoringListContent {
  const MonitoringListContent();
}

/// The first page is on its way; no row is shown.
final class MonitoringListLoading extends MonitoringListContent {
  const MonitoringListLoading();
}

/// The pages read so far. Empty is a state the screen words (default
/// filter, or another); [next] is null at the last page.
final class MonitoringListLoaded extends MonitoringListContent {
  const MonitoringListLoaded({
    required this.items,
    required this.next,
    this.more = MonitoringMore.idle,
  });

  final List<LogSummaryEntity> items;
  final LogCursor? next;
  final MonitoringMore more;

  MonitoringListLoaded withMore(MonitoringMore value) =>
      MonitoringListLoaded(items: items, next: next, more: value);

  MonitoringListLoaded withItems(List<LogSummaryEntity> value) =>
      MonitoringListLoaded(items: value, next: next, more: more);
}

/// The first page failed; no stale row is shown.
final class MonitoringListFailed extends MonitoringListContent {
  const MonitoringListFailed(this.failure);

  final MonitoringLoadFailure failure;
}

/// The Server tab: the filter asked and what it returned. The filter is
/// always the one the content answers.
@immutable
final class MonitoringListState {
  const MonitoringListState({
    this.filter = const LogFilter(),
    this.content = const MonitoringListLoading(),
  });

  final LogFilter filter;
  final MonitoringListContent content;
}
```

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';

/// The Not sent tab: the levels shown and the device buffer's rows.
@immutable
final class PendingLogsState {
  const PendingLogsState({
    this.levels = LogFilter.defaultLevels,
    this.logs = const AsyncLoading(),
  });

  final Set<LogLevel> levels;
  final AsyncValue<PendingLogs> logs;
}
```

- [ ] **Step 4: Write the use-case providers**

```dart
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/usecases/query_server_logs_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'query_server_logs_use_case_provider.g.dart';

@riverpod
QueryServerLogsUseCase queryServerLogsUseCase(Ref ref) =>
    QueryServerLogsUseCase(
      ref.watch(monitoringRepositoryProvider),
      ref.watch(dayClockProvider),
    );
```

```dart
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/usecases/get_server_log_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_server_log_use_case_provider.g.dart';

@riverpod
GetServerLogUseCase getServerLogUseCase(Ref ref) =>
    GetServerLogUseCase(ref.watch(monitoringRepositoryProvider));
```

```dart
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/usecases/get_pending_log_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_pending_log_use_case_provider.g.dart';

@riverpod
GetPendingLogUseCase getPendingLogUseCase(Ref ref) =>
    GetPendingLogUseCase(ref.watch(monitoringRepositoryProvider));
```

```dart
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/usecases/set_log_status_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_log_status_use_case_provider.g.dart';

@riverpod
SetLogStatusUseCase setLogStatusUseCase(Ref ref) =>
    SetLogStatusUseCase(ref.watch(monitoringRepositoryProvider));
```

```dart
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/usecases/watch_pending_logs_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_pending_logs_use_case_provider.g.dart';

@riverpod
WatchPendingLogsUseCase watchPendingLogsUseCase(Ref ref) =>
    WatchPendingLogsUseCase(ref.watch(monitoringRepositoryProvider));
```

- [ ] **Step 5: Write the controllers**

`_generation` is bumped by every ask from the first page; an answer (or a failure) carries the number it was asked under and is dropped when it is no longer the latest. That is what keeps a slow answer from overwriting a newer filter's rows.

```dart
import 'dart:async';

import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/providers/query_server_logs_use_case_provider.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_list_state.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_load_failure_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'monitoring_list_controller.g.dart';

/// How long the search field stays still before it asks the server
/// (monitoring spec §3.2).
const Duration monitoringSearchDebounce = Duration(milliseconds: 400);

/// The Server tab (monitoring spec §3.2, §3.5): the filter, the pages read
/// so far and the one read in flight. A filter change, a search and a pull
/// to refresh start again from the first page; an answer to an earlier ask
/// than the latest is dropped, so a slow response never overwrites a newer
/// one.
@riverpod
class MonitoringListController extends _$MonitoringListController {
  Timer? _debounce;

  /// Bumped by every ask from the first page; an answer carries the number
  /// it was asked under.
  var _generation = 0;

  @override
  MonitoringListState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(_loadFirst);
    return const MonitoringListState();
  }

  /// A new filter: the first page of it, at once.
  void setFilter(LogFilter next) {
    _debounce?.cancel();
    if (next == state.filter) return;
    state = MonitoringListState(filter: next);
    unawaited(_loadFirst());
  }

  /// Every filter and the search back to the default.
  void clearFilters() => setFilter(const LogFilter());

  /// After a failure: the first page again, the failure gone at once.
  void retry() {
    _debounce?.cancel();
    state = MonitoringListState(filter: state.filter);
    unawaited(_loadFirst());
  }

  /// The search field changed: asked [monitoringSearchDebounce] after the
  /// last change.
  void search(String text) {
    _debounce?.cancel();
    _debounce = Timer(
      monitoringSearchDebounce,
      () => setFilter(state.filter.withSearch(text)),
    );
  }

  /// Pull to refresh: the first page again, the rows kept until it lands.
  Future<void> refresh() {
    _debounce?.cancel();
    return _loadFirst();
  }

  /// One more page, keeping the rows until it arrives; after a failure it is
  /// the retry.
  Future<void> loadMore() async {
    final current = state.content;
    if (current is! MonitoringListLoaded) return;
    final after = current.next;
    if (after == null || current.more == MonitoringMore.loading) return;
    final generation = _generation;
    final filter = state.filter;
    _show(current.withMore(MonitoringMore.loading));
    try {
      final page = await ref.read(queryServerLogsUseCaseProvider)(
        filter,
        after: after,
      );
      if (!_isCurrent(generation)) return;
      final latest = _loaded;
      if (latest == null) return;
      state = MonitoringListState(
        filter: filter,
        content: MonitoringListLoaded(
          items: [...latest.items, ...page.items],
          next: page.next,
        ),
      );
    } on Object {
      if (!_isCurrent(generation)) return;
      final latest = _loaded;
      if (latest == null) return;
      _show(latest.withMore(MonitoringMore.failed));
    }
  }

  /// The detail changed [id]'s status: it shows the new one, or, when the
  /// filter no longer matches it, leaves the list.
  void statusChanged(String id, LogStatus status) {
    final current = _loaded;
    if (current == null) return;
    final wanted = state.filter.statuses;
    final keeps = wanted.isEmpty || wanted.contains(status);
    _show(
      current.withItems([
        for (final item in current.items)
          if (item.id != id) item else if (keeps) item.withStatus(status),
      ]),
    );
  }

  MonitoringListLoaded? get _loaded {
    final content = state.content;
    return content is MonitoringListLoaded ? content : null;
  }

  void _show(MonitoringListContent content) =>
      state = MonitoringListState(filter: state.filter, content: content);

  bool _isCurrent(int generation) => ref.mounted && generation == _generation;

  Future<void> _loadFirst() async {
    if (!ref.mounted) return;
    final generation = ++_generation;
    final filter = state.filter;
    try {
      final page = await ref.read(queryServerLogsUseCaseProvider)(filter);
      if (!_isCurrent(generation)) return;
      state = MonitoringListState(
        filter: filter,
        content: MonitoringListLoaded(items: page.items, next: page.next),
      );
    } on Object catch (error) {
      if (!_isCurrent(generation)) return;
      _show(MonitoringListFailed(MonitoringLoadFailure.of(error)));
    }
  }
}
```

```dart
import 'dart:async';

import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/features/monitoring/domain/usecases/watch_pending_logs_use_case.dart';
import 'package:memox/features/monitoring/presentation/providers/watch_pending_logs_use_case_provider.dart';
import 'package:memox/features/monitoring/presentation/states/pending_logs_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_logs_controller.g.dart';

/// The Not sent tab (monitoring spec §3.2): the device buffer, watched, for
/// the levels chosen. It lives as long as the screen, so the tab's count is
/// always the buffer's.
@riverpod
class PendingLogsController extends _$PendingLogsController {
  StreamSubscription<PendingLogs>? _watch;
  late WatchPendingLogsUseCase _watchLogs;

  @override
  PendingLogsState build() {
    _watchLogs = ref.watch(watchPendingLogsUseCaseProvider);
    ref.onDispose(() => unawaited(_watch?.cancel()));
    const initial = PendingLogsState();
    _listen(initial.levels);
    return initial;
  }

  /// Another set of levels; the rows stay until the buffer answers for it.
  void setLevels(Set<LogLevel> levels) {
    state = PendingLogsState(levels: levels, logs: state.logs);
    _listen(levels);
  }

  void _listen(Set<LogLevel> levels) {
    unawaited(_watch?.cancel());
    _watch = _watchLogs(levels).listen(
      (logs) => _show(levels, AsyncData(logs)),
      onError: (Object error, StackTrace stackTrace) =>
          _show(levels, AsyncError(error, stackTrace)),
    );
  }

  void _show(Set<LogLevel> levels, AsyncValue<PendingLogs> logs) {
    if (!ref.mounted) return;
    state = PendingLogsState(levels: levels, logs: logs);
  }
}
```

- [ ] **Step 6: Generate and run**

Run: `dart run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/features/monitoring/presentation/monitoring_list_controller_test.dart test/features/monitoring/presentation/pending_logs_controller_test.dart`
Expected: PASS (`All tests passed!`).

- [ ] **Step 7: Commit**

```bash
git add lib/features/monitoring/presentation test/features/monitoring/presentation
git commit -m "feat(monitoring): the list and Not sent controllers"
```

---

### Task 9: The list screen, the row and the filter sheets

**Files:**
- Create: `lib/features/monitoring/presentation/states/monitoring_tab_state.dart`
- Create: `lib/features/monitoring/presentation/widgets/support/monitoring_labels_widget.dart`
- Create: `lib/features/monitoring/presentation/widgets/items/log_row_widget.dart`
- Create: `lib/features/monitoring/presentation/widgets/overlays/{monitoring_choice_sheet_widget,monitoring_filter_sheets_widget,monitoring_device_user_sheet_widget}.dart`
- Create: `lib/features/monitoring/presentation/widgets/sections/{monitoring_filter_bar_widget,monitoring_server_list_widget,monitoring_server_tab_widget,monitoring_pending_tab_widget}.dart`
- Create: `lib/features/monitoring/presentation/screens/monitoring_screen.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/support/monitoring_screen_harness.dart`, `test/features/monitoring/presentation/{monitoring_screen_test,monitoring_filters_test,monitoring_not_sent_test}.dart`, `test/visual_audit/screens/features/monitoring/screens/monitoring_screen_visual_audit_test.dart`

**Interfaces:**
- Consumes: Tasks 1, 5, 7 and 8; shared widgets `MxSegmentedTray`, `MxSearchField`, `MxChipTrigger`, `MxBottomSheet`, `MxOptionRow`, `MxSettingsRow`, `MxToggle`, `MxSection`, `MxSheetActions`, `MxListRow`, `MxListSectionHeader`, `MxIconTile`, `MxBadge`, `MxNote`, `MxEmptyState`, `MxErrorState`, `MxInlineBanner`, `MxSkeletonList`, `MxSpinner`, `MxTextField`, `MxButton`.
- Produces:
  - `MonitoringScreen({required ValueChanged<String> onOpenServerLog, required ValueChanged<String> onOpenPendingLog})`.
  - `LogRowWidget`, `showMonitoringChoiceSheet<T>`, `showMonitoringLevelSheet` / `showMonitoringStatusFilterSheet` / `showMonitoringCategorySheet` / `showMonitoringWindowSheet`, `showMonitoringDeviceUserSheet`.
  - Label helpers in `monitoring_labels_widget.dart`: `monitoringLevelLabel/Icon/Tone`, `monitoringStatusLabel/Tone`, `monitoringWindowLabel`, `monitoringChipLabel`, `monitoringRowTime`, `monitoringFullTime`.
  - Test harness: `pumpMonitoring`, `settleMonitoring`, `openNotSentTab`, `tapMonitoringChip`, `monitoringOverrides`.
  - ARB keys (list group below).

- [ ] **Step 1: Write the failing tests**

The harness first, then the three test files. Review Focus 5 is the last test of `monitoring_screen_test.dart` (English and Vietnamese at scale 2.0, a long event name). The load-more test drives the scroll and checks the retry does not loop.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_screen.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

import 'library_harness.dart';
import 'monitoring_fakes.dart';

List<Override> monitoringOverrides(FakeMonitoringRepository repository) => [
  monitoringRepositoryProvider.overrideWithValue(repository),
];

/// Screen 28's list over [repository], on the library harness.
Future<void> pumpMonitoring(
  WidgetTester tester,
  LibraryEnv env,
  FakeMonitoringRepository repository, {
  ValueChanged<String>? onOpenServerLog,
  ValueChanged<String>? onOpenPendingLog,
  double textScale = 1,
  Locale locale = const Locale('en'),
}) => pumpLibraryScreen(
  tester,
  env,
  MonitoringScreen(
    onOpenServerLog: onOpenServerLog ?? (_) {},
    onOpenPendingLog: onOpenPendingLog ?? (_) {},
  ),
  overrides: monitoringOverrides(repository),
  textScale: textScale,
  locale: locale,
);

Future<void> settleMonitoring(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

/// Opens the Not sent tab. Its skeleton pulses for ever until the buffer
/// answers, so this never waits for the animations to end.
Future<void> openNotSentTab(WidgetTester tester) async {
  await tester.tap(find.textContaining('Not sent ('));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Taps the filter chip whose label holds [label], scrolling it in first.
Future<void> tapMonitoringChip(WidgetTester tester, String label) async {
  final chip = find.descendant(
    of: find.byType(MxChipTrigger),
    matching: find.textContaining(label),
  );
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await tester.pumpAndSettle();
}
```

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../../support/library_harness.dart';
import '../../../support/monitoring_fakes.dart';
import '../../../support/monitoring_screen_harness.dart';

// Monitoring spec §3.2, §3.4, §5: the Server tab.
void main() {
  libraryTest('it opens on open warnings and errors, with their count', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()
      ..autoPage = LogPage(
        items: [
          summary('a', event: 'sync.push_failed'),
          summary('b', level: LogLevel.warning, event: 'db.slow_query'),
        ],
      );

    await pumpMonitoring(tester, env, repository);

    expect(find.text('2 OPEN'), findsOneWidget);
    expect(find.text('sync.push_failed'), findsOneWidget);
    expect(find.text('db.slow_query'), findsOneWidget);
    expect(find.text('message of a'), findsOneWidget);
    expect(find.widgetWithText(MxBadge, 'Open'), findsNWidgets(2));
    expect(repository.lastQuery.filter.isDefault, isTrue);
  });

  libraryTest('a row reads as level, event, time and status', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()
      ..autoPage = LogPage(items: [summary('a', event: 'sync.push_failed')]);
    final semantics = tester.ensureSemantics();

    await pumpMonitoring(tester, env, repository);

    expect(
      find.bySemanticsLabel(RegExp('Error, sync.push_failed, .*, Open')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  libraryTest('the time is HH:mm today and a short date before', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()
      ..autoPage = LogPage(
        items: [
          summary('today', at: libraryToday.subtract(const Duration(hours: 1))),
          summary('older', at: DateTime(2026, 9, 20, 22, 5)),
        ],
      );

    await pumpMonitoring(tester, env, repository);

    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('Sep 20'), findsOneWidget);
  });

  libraryTest('a tap on a row opens its detail', (tester, env) async {
    final repository = FakeMonitoringRepository()
      ..autoPage = LogPage(items: [summary('a')]);
    String? opened;

    await pumpMonitoring(
      tester,
      env,
      repository,
      onOpenServerLog: (id) => opened = id,
    );
    await tester.tap(find.byType(MxListRow));

    expect(opened, 'a');
  });

  libraryTest('while the first page loads the list is a skeleton', (
    tester,
    env,
  ) async {
    await pumpMonitoring(tester, env, FakeMonitoringRepository());

    expect(find.byType(MxSkeletonList), findsOneWidget);
  });

  libraryTest('no open problems is a calm empty state', (tester, env) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(0);

    await pumpMonitoring(tester, env, repository);

    expect(find.text('No open problems'), findsOneWidget);
    expect(find.text('Warnings and errors will show here.'), findsOneWidget);
  });

  libraryTest('another filter with no match offers to clear the filters', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(0);
    await pumpMonitoring(tester, env, repository);
    await tester.enterText(find.byType(TextField).first, 'nothing');
    await tester.pump(const Duration(milliseconds: 400));
    await settleMonitoring(tester);

    expect(find.text('Nothing matches'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await settleMonitoring(tester);

    expect(find.text('No open problems'), findsOneWidget);
    expect(repository.lastQuery.filter.isDefault, isTrue);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
    );
  });

  libraryTest('offline says so and points at Not sent, with a Retry', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
    await settleMonitoring(tester);

    expect(find.text("Can't reach the server"), findsOneWidget);
    expect(find.textContaining('under Not sent'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await settleMonitoring(tester);
    expect(repository.queries, hasLength(2));
    repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
    await settleMonitoring(tester);

    await tester.tap(find.widgetWithText(MxButton, 'Not sent'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(MxSkeletonList), findsOneWidget);
  });

  libraryTest('another failure is a local-first error with a Retry', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    repository.lastQuery.fail(const ServerFailure(cause: 'x'));
    await settleMonitoring(tester);

    expect(find.text("Couldn't load logs"), findsOneWidget);
    expect(
      find.text('Nothing was lost. Try again in a moment.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Retry'));
    await settleMonitoring(tester);
    repository.lastQuery.answer(pageOf(1));
    await settleMonitoring(tester);

    expect(find.byType(MxErrorState), findsNothing);
    expect(find.text('r0'), findsNothing);
    expect(find.text('sync.push_failed'), findsOneWidget);
  });

  libraryTest('FORBIDDEN says only an admin can see this', (tester, env) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    repository.lastQuery.fail(const NotAdminFailure(cause: 'x'));
    await settleMonitoring(tester);

    expect(find.text('Only an admin can see this'), findsOneWidget);
  });

  libraryTest('the next page loads near the end, and the end says so', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    repository.lastQuery.answer(pageOf(LogPage.size));
    await settleMonitoring(tester);
    expect(find.text('100+ OPEN'), findsOneWidget);

    await tester.fling(find.byType(ListView), const Offset(0, -20000), 8000);
    await tester.pump();
    expect(repository.queries, hasLength(2));
    expect(repository.lastQuery.after!.id, 'r99');
    repository.lastQuery.answer(pageOf(3, prefix: 'p'));
    await settleMonitoring(tester);
    await tester.fling(find.byType(ListView), const Offset(0, -20000), 8000);
    await tester.pumpAndSettle();

    expect(find.text('No more logs'), findsOneWidget);
    expect(repository.queries, hasLength(2));
    await tester.fling(find.byType(ListView), const Offset(0, 20000), 8000);
    await tester.pumpAndSettle();
    expect(find.text('103 OPEN'), findsOneWidget);
  });

  libraryTest('a failed page keeps the rows and offers Retry, not a loop', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    repository.lastQuery.answer(pageOf(LogPage.size));
    await settleMonitoring(tester);

    await tester.fling(find.byType(ListView), const Offset(0, -20000), 8000);
    await tester.pump();
    repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
    await tester.pumpAndSettle();
    await tester.fling(find.byType(ListView), const Offset(0, -20000), 8000);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load more logs."), findsOneWidget);
    expect(repository.queries, hasLength(2), reason: 'no retry loop');
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(repository.queries, hasLength(3));
  });

  libraryTest('pull to refresh asks the first page again', (tester, env) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(2);
    await pumpMonitoring(tester, env, repository);

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(repository.queries, hasLength(2));
    expect(repository.lastQuery.after, isNull);
  });

  libraryTest('the search asks once the field has been still for 400 ms', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
    await pumpMonitoring(tester, env, repository);

    await tester.enterText(find.byType(TextField).first, 'push');
    await tester.pump(const Duration(milliseconds: 399));
    expect(repository.queries, hasLength(1));
    await tester.pump(const Duration(milliseconds: 1));

    expect(repository.lastQuery.filter.search, 'push');
  });

  for (final locale in [const Locale('en'), const Locale('vi')]) {
    libraryTest('${locale.languageCode} at text scale 2 lays out a long event '
        'name without overflow', (tester, env) async {
      final repository = FakeMonitoringRepository()
        ..autoPage = LogPage(
          items: [
            summary(
              'a',
              event: 'db.slow_query.${'very_long_segment.' * 6}end',
              message: 'A message that is long enough to be cut at one line',
            ),
            summary('b', level: LogLevel.warning),
          ],
        );

      await pumpMonitoring(
        tester,
        env,
        repository,
        textScale: 2,
        locale: locale,
      );

      expect(tester.takeException(), isNull);
      final title = tester.widget<Text>(
        find.textContaining('db.slow_query.very_long').first,
      );
      expect(title.overflow, TextOverflow.ellipsis);
      expect(find.byType(MxListRow), findsNWidgets(2));
    });
  }

  libraryTest('an info row has no status and a debug row its own glyph', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()
      ..autoPage = LogPage(
        items: [
          summary('a', level: LogLevel.info, status: null),
          summary('b', level: LogLevel.debug, status: null),
          summary('c', status: LogStatus.fixed),
        ],
      );

    await pumpMonitoring(tester, env, repository);

    expect(find.widgetWithText(MxBadge, 'Fixed'), findsOneWidget);
    expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });
}
```

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/log_window_model.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../../support/library_harness.dart';
import '../../../support/monitoring_fakes.dart';
import '../../../support/monitoring_screen_harness.dart';

// Monitoring spec §3.2: the filter chips and their sheets.
void main() {
  libraryTest('the Level chip shows its choice and its sheet applies it', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
    await pumpMonitoring(tester, env, repository);
    expect(find.text('Level · 2'), findsOneWidget);
    expect(find.text('Status · Open'), findsOneWidget);

    await tapMonitoringChip(tester, 'Level');
    await tester.tap(find.byType(MxToggle).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Level · 3'), findsOneWidget);
    expect(repository.lastQuery.filter.levels, {
      LogLevel.info,
      LogLevel.warning,
      LogLevel.error,
    });
    expect(repository.lastQuery.filter.statuses, isEmpty);
    expect(find.text('Status'), findsOneWidget);
  });

  libraryTest('Reset puts a sheet back to its default, Apply keeps it', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
    await pumpMonitoring(tester, env, repository);

    await tapMonitoringChip(tester, 'Status');
    await tester.tap(find.byType(MxToggle).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(repository.queries, hasLength(1), reason: 'the default is kept');
    expect(find.text('Status · Open'), findsOneWidget);
  });

  libraryTest('the Category sheet lists every LogCategory value', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
    await pumpMonitoring(tester, env, repository);

    await tapMonitoringChip(tester, 'Category');

    expect(find.byType(MxToggle), findsNWidgets(LogCategory.values.length));
    for (final category in LogCategory.values) {
      expect(find.text(category.name), findsOneWidget);
    }
  });

  libraryTest('the Time sheet picks one window', (tester, env) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
    await pumpMonitoring(tester, env, repository);

    await tapMonitoringChip(tester, 'Time');
    await tester.tap(find.text('Last 24 hours'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(repository.lastQuery.filter.window, LogWindow.day);
    expect(find.text('Time · Last 24 hours'), findsOneWidget);
  });

  libraryTest('the device and user sheet sets both, and refuses a bad user', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
    await pumpMonitoring(tester, env, repository);

    await tapMonitoringChip(tester, 'Device');
    await tester.enterText(find.byType(TextField).at(1), 'dev-1');
    await tester.enterText(find.byType(TextField).at(2), 'not a uuid');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text("That isn't a valid user ID."), findsOneWidget);
    expect(repository.queries, hasLength(1));

    const user = '00000000-0000-0000-0000-00000000dead';
    await tester.enterText(find.byType(TextField).at(2), user);
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(repository.lastQuery.filter.deviceId, 'dev-1');
    expect(repository.lastQuery.filter.userId, user);
    expect(find.text('Device / user · 2'), findsOneWidget);
  });
}
```

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/shared/widgets/mx_badge.dart';

import '../../../support/library_harness.dart';
import '../../../support/monitoring_fakes.dart';
import '../../../support/monitoring_screen_harness.dart';

// Monitoring spec §3.2: the Not sent tab, and the tabs together.
void main() {
  libraryTest('the Not sent tab shows the count, the note and the rows', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
    String? opened;
    await pumpMonitoring(
      tester,
      env,
      repository,
      onOpenPendingLog: (id) => opened = id,
    );
    repository.watches.single.feed.add(
      PendingLogs(
        items: [
          summary('p1', status: null, event: 'sync.failed'),
          summary('p2', status: null, level: LogLevel.warning),
        ],
        total: 12,
      ),
    );
    await settleMonitoring(tester);

    expect(find.text('Not sent (12)'), findsOneWidget);
    await tester.tap(find.text('Not sent (12)'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        '12 logs wait on this device. They are sent when MemoX is online.',
      ),
      findsOneWidget,
    );
    expect(find.byType(MxBadge), findsNothing, reason: 'no status');
    await tester.tap(find.text('sync.failed'));
    expect(opened, 'p1');
  });

  libraryTest('Not sent works while the server tab is offline', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository();
    await pumpMonitoring(tester, env, repository);
    repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
    repository.watches.single.feed.add(
      PendingLogs(items: [summary('p1', status: null)], total: 1),
    );
    await settleMonitoring(tester);

    await tester.tap(find.text('Not sent (1)'));
    await tester.pumpAndSettle();

    expect(find.text('sync.push_failed'), findsOneWidget);
  });

  libraryTest('Not sent has words for an empty buffer and for a level with '
      'no row', (tester, env) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
    await pumpMonitoring(tester, env, repository);
    await openNotSentTab(tester);
    repository.watches.single.feed.add(const PendingLogs(items: [], total: 0));
    await settleMonitoring(tester);
    expect(find.text('Nothing waiting'), findsOneWidget);

    repository.watches.single.feed.add(const PendingLogs(items: [], total: 4));
    await settleMonitoring(tester);
    expect(find.text('No logs at these levels'), findsOneWidget);
  });

  libraryTest('switching tabs keeps the pages of the server tab', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(3);
    await pumpMonitoring(tester, env, repository);
    repository.watches.single.feed.add(const PendingLogs(items: [], total: 0));
    await settleMonitoring(tester);

    await tester.tap(find.textContaining('Not sent ('));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Server'));
    await tester.pumpAndSettle();

    expect(repository.queries, hasLength(1));
    expect(find.text('3 OPEN'), findsOneWidget);
  });

  // Review focus: large text scale on a row with a long event name.
}
```

```dart
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/monitoring_fakes.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 28', (tester, env) async {
    final repository = FakeMonitoringRepository()
      ..autoPage = LogPage(
        items: [
          summary('a', event: 'sync.push_failed'),
          summary('b', level: LogLevel.warning, event: 'db.slow_query'),
          summary('c', status: LogStatus.fixed),
        ],
      );
    await auditProductionScreen(
      tester,
      screen: MonitoringScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        MonitoringScreen(onOpenServerLog: (_) {}, onOpenPendingLog: (_) {}),
        brightness: brightness,
        textScale: scale,
        overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
      ),
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/monitoring/presentation/monitoring_screen_test.dart`
Expected: FAIL to compile: `Error when reading 'lib/features/monitoring/presentation/screens/monitoring_screen.dart'`.

- [ ] **Step 3: Add the strings**

Append to `lib/l10n/app_en.arb`:

```json
  "monitoringTitle": "Monitoring",
  "@monitoringTitle": {
    "description": "Screen 28: the app bar title."
  },
  "monitoringTabServer": "Server",
  "@monitoringTabServer": {
    "description": "Screen 28: the first tab, the logs on the server."
  },
  "monitoringTabNotSent": "Not sent ({count})",
  "@monitoringTabNotSent": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    },
    "description": "Screen 28: the second tab, the logs still on this device; {count} is how many wait."
  },
  "monitoringSearchHint": "Search event or message",
  "@monitoringSearchHint": {
    "description": "Screen 28: the search field placeholder."
  },
  "monitoringSearchClear": "Clear search",
  "@monitoringSearchClear": {
    "description": "Screen 28: the search clear button name."
  },
  "monitoringChipLevel": "Level",
  "@monitoringChipLevel": {
    "description": "Screen 28: the level filter chip and its sheet title."
  },
  "monitoringChipStatus": "Status",
  "@monitoringChipStatus": {
    "description": "Screen 28: the status filter chip and its sheet title."
  },
  "monitoringChipCategory": "Category",
  "@monitoringChipCategory": {
    "description": "Screen 28: the category filter chip and its sheet title."
  },
  "monitoringChipTime": "Time",
  "@monitoringChipTime": {
    "description": "Screen 28: the time filter chip and its sheet title."
  },
  "monitoringChipDevice": "Device / user",
  "@monitoringChipDevice": {
    "description": "Screen 28: the device and user filter chip and its sheet title."
  },
  "monitoringChipValue": "{label} · {value}",
  "@monitoringChipValue": {
    "placeholders": {
      "label": {
        "type": "String"
      },
      "value": {
        "type": "String"
      }
    },
    "description": "Screen 28: a filter chip that holds a choice; {value} is its name or how many are chosen."
  },
  "monitoringLevelDebug": "Debug",
  "@monitoringLevelDebug": {
    "description": "Screen 28: the debug level."
  },
  "monitoringLevelInfo": "Info",
  "@monitoringLevelInfo": {
    "description": "Screen 28: the info level."
  },
  "monitoringLevelWarning": "Warning",
  "@monitoringLevelWarning": {
    "description": "Screen 28: the warning level."
  },
  "monitoringLevelError": "Error",
  "@monitoringLevelError": {
    "description": "Screen 28: the error level."
  },
  "monitoringStatusOpen": "Open",
  "@monitoringStatusOpen": {
    "description": "Screen 28: a warning or error not yet handled."
  },
  "monitoringStatusFixed": "Fixed",
  "@monitoringStatusFixed": {
    "description": "Screen 28: a warning or error marked fixed."
  },
  "monitoringWindowHour": "Last hour",
  "@monitoringWindowHour": {
    "description": "Screen 28: the time filter, one hour."
  },
  "monitoringWindowDay": "Last 24 hours",
  "@monitoringWindowDay": {
    "description": "Screen 28: the time filter, 24 hours."
  },
  "monitoringWindowWeek": "Last 7 days",
  "@monitoringWindowWeek": {
    "description": "Screen 28: the time filter, 7 days."
  },
  "monitoringWindowMonth": "Last 30 days",
  "@monitoringWindowMonth": {
    "description": "Screen 28: the time filter, 30 days."
  },
  "monitoringWindowAll": "All time",
  "@monitoringWindowAll": {
    "description": "Screen 28: the time filter, no limit."
  },
  "monitoringReset": "Reset",
  "@monitoringReset": {
    "description": "Screen 28: a filter sheet button that clears its choice."
  },
  "monitoringApply": "Apply",
  "@monitoringApply": {
    "description": "Screen 28: a filter sheet button that applies its choice."
  },
  "monitoringDeviceLabel": "Device ID",
  "@monitoringDeviceLabel": {
    "description": "Screen 28: the device field of the device and user sheet."
  },
  "monitoringUserLabel": "User ID",
  "@monitoringUserLabel": {
    "description": "Screen 28: the user field of the device and user sheet."
  },
  "monitoringDeviceUserNote": "Paste an ID from a log's details.",
  "@monitoringDeviceUserNote": {
    "description": "Screen 28: the note of the device and user sheet."
  },
  "monitoringUserInvalid": "That isn't a valid user ID.",
  "@monitoringUserInvalid": {
    "description": "Screen 28: the user field error when the text is not a uuid."
  },
  "monitoringCountOpen": "{count} open",
  "@monitoringCountOpen": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    },
    "description": "Screen 28: the list header for the default filter; {count} is what has loaded."
  },
  "monitoringCountOpenMore": "{count}+ open",
  "@monitoringCountOpenMore": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    },
    "description": "Screen 28: the list header for the default filter while more pages exist."
  },
  "monitoringCountLogs": "{count, plural, =1{1 log} other{{count} logs}}",
  "@monitoringCountLogs": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    },
    "description": "Screen 28: the list header for another filter; {count} is what has loaded."
  },
  "monitoringCountLogsMore": "{count}+ logs",
  "@monitoringCountLogsMore": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    },
    "description": "Screen 28: the list header for another filter while more pages exist."
  },
  "monitoringNoMore": "No more logs",
  "@monitoringNoMore": {
    "description": "Screen 28: the end of the list."
  },
  "monitoringLoadMoreFailed": "Couldn't load more logs.",
  "@monitoringLoadMoreFailed": {
    "description": "Screen 28: the end of the list when the next page failed."
  },
  "monitoringEmptyTitle": "No open problems",
  "@monitoringEmptyTitle": {
    "description": "Screen 28: the Server tab with the default filter and no row."
  },
  "monitoringEmptyBody": "Warnings and errors will show here.",
  "@monitoringEmptyBody": {
    "description": "Screen 28: the body of the empty Server tab."
  },
  "monitoringNoMatchTitle": "Nothing matches",
  "@monitoringNoMatchTitle": {
    "description": "Screen 28: a filter that matches no log."
  },
  "monitoringClearFilters": "Clear filters",
  "@monitoringClearFilters": {
    "description": "Screen 28: resets every filter and the search."
  },
  "monitoringOfflineTitle": "Can't reach the server",
  "@monitoringOfflineTitle": {
    "description": "Screen 28: the server could not be reached."
  },
  "monitoringOfflineBody": "Monitoring reads the logs online. The ones this device hasn't sent are under Not sent.",
  "@monitoringOfflineBody": {
    "description": "Screen 28: the body of the offline Server tab."
  },
  "monitoringOpenNotSent": "Not sent",
  "@monitoringOpenNotSent": {
    "description": "Screen 28: the offline state action that opens the Not sent tab."
  },
  "monitoringErrorTitle": "Couldn't load logs",
  "@monitoringErrorTitle": {
    "description": "Screen 28: the Server tab failed to load."
  },
  "monitoringNotAdminTitle": "Only an admin can see this",
  "@monitoringNotAdminTitle": {
    "description": "Screen 28 and its detail: the server refused the call (FORBIDDEN)."
  },
  "monitoringPendingNote": "{count, plural, =1{1 log waits on this device. It is sent when MemoX is online.} other{{count} logs wait on this device. They are sent when MemoX is online.}}",
  "@monitoringPendingNote": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    },
    "description": "Screen 28: the note of the Not sent tab; {count} is every row of the buffer."
  },
  "monitoringPendingNoneTitle": "Nothing waiting",
  "@monitoringPendingNoneTitle": {
    "description": "Screen 28: the Not sent tab with an empty buffer."
  },
  "monitoringPendingNoneBody": "Every log on this device has been sent.",
  "@monitoringPendingNoneBody": {
    "description": "Screen 28: the body of the empty Not sent tab."
  },
  "monitoringPendingFilteredTitle": "No logs at these levels",
  "@monitoringPendingFilteredTitle": {
    "description": "Screen 28: the Not sent tab where the chosen levels match no row."
  },
  "monitoringPendingFilteredBody": "Try another level.",
  "@monitoringPendingFilteredBody": {
    "description": "Screen 28: the body of the Not sent tab where the levels match no row."
  },
  "monitoringRowLabel": "{level}, {event}, {time}, {status}",
  "@monitoringRowLabel": {
    "placeholders": {
      "level": {
        "type": "String"
      },
      "event": {
        "type": "String"
      },
      "time": {
        "type": "String"
      },
      "status": {
        "type": "String"
      }
    },
    "description": "Screen 28: what a screen reader says for a row with a status."
  },
  "monitoringRowLabelNoStatus": "{level}, {event}, {time}",
  "@monitoringRowLabelNoStatus": {
    "placeholders": {
      "level": {
        "type": "String"
      },
      "event": {
        "type": "String"
      },
      "time": {
        "type": "String"
      }
    },
    "description": "Screen 28: what a screen reader says for a row with no status."
  }
```

and to `lib/l10n/app_vi.arb`:

```json
  "monitoringTitle": "Giám sát",
  "monitoringTabServer": "Máy chủ",
  "monitoringTabNotSent": "Chưa gửi ({count})",
  "monitoringSearchHint": "Tìm theo sự kiện hoặc nội dung",
  "monitoringSearchClear": "Xoá tìm kiếm",
  "monitoringChipLevel": "Mức",
  "monitoringChipStatus": "Trạng thái",
  "monitoringChipCategory": "Nhóm",
  "monitoringChipTime": "Thời gian",
  "monitoringChipDevice": "Thiết bị / người dùng",
  "monitoringChipValue": "{label} · {value}",
  "monitoringLevelDebug": "Gỡ lỗi",
  "monitoringLevelInfo": "Thông tin",
  "monitoringLevelWarning": "Cảnh báo",
  "monitoringLevelError": "Lỗi",
  "monitoringStatusOpen": "Đang mở",
  "monitoringStatusFixed": "Đã xử lý",
  "monitoringWindowHour": "1 giờ qua",
  "monitoringWindowDay": "24 giờ qua",
  "monitoringWindowWeek": "7 ngày qua",
  "monitoringWindowMonth": "30 ngày qua",
  "monitoringWindowAll": "Tất cả",
  "monitoringReset": "Đặt lại",
  "monitoringApply": "Áp dụng",
  "monitoringDeviceLabel": "Mã thiết bị",
  "monitoringUserLabel": "Mã người dùng",
  "monitoringDeviceUserNote": "Dán mã lấy từ chi tiết của một nhật ký.",
  "monitoringUserInvalid": "Mã người dùng này không hợp lệ.",
  "monitoringCountOpen": "{count} đang mở",
  "monitoringCountOpenMore": "{count}+ đang mở",
  "monitoringCountLogs": "{count, plural, other{{count} nhật ký}}",
  "monitoringCountLogsMore": "{count}+ nhật ký",
  "monitoringNoMore": "Hết nhật ký",
  "monitoringLoadMoreFailed": "Chưa tải thêm được nhật ký.",
  "monitoringEmptyTitle": "Không có vấn đề nào đang mở",
  "monitoringEmptyBody": "Cảnh báo và lỗi sẽ hiện ở đây.",
  "monitoringNoMatchTitle": "Không có gì khớp",
  "monitoringClearFilters": "Xoá bộ lọc",
  "monitoringOfflineTitle": "Không kết nối được máy chủ",
  "monitoringOfflineBody": "Giám sát đọc nhật ký qua mạng. Những nhật ký máy này chưa gửi nằm ở mục Chưa gửi.",
  "monitoringOpenNotSent": "Chưa gửi",
  "monitoringErrorTitle": "Không tải được nhật ký",
  "monitoringNotAdminTitle": "Chỉ quản trị viên mới xem được mục này",
  "monitoringPendingNote": "{count, plural, other{{count} nhật ký đang chờ trên máy này. Chúng được gửi khi MemoX có mạng.}}",
  "monitoringPendingNoneTitle": "Không có gì đang chờ",
  "monitoringPendingNoneBody": "Mọi nhật ký trên máy này đã được gửi.",
  "monitoringPendingFilteredTitle": "Không có nhật ký ở các mức này",
  "monitoringPendingFilteredBody": "Thử mức khác.",
  "monitoringRowLabel": "{level}, {event}, {time}, {status}",
  "monitoringRowLabelNoStatus": "{level}, {event}, {time}"
```

Run `flutter gen-l10n`.

- [ ] **Step 4: Write the labels, the row and the sheets**

```dart
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/log_window_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

/// The level's name (monitoring spec §3.2).
String monitoringLevelLabel(AppLocalizations l10n, LogLevel level) =>
    switch (level) {
      LogLevel.debug => l10n.monitoringLevelDebug,
      LogLevel.info => l10n.monitoringLevelInfo,
      LogLevel.warning => l10n.monitoringLevelWarning,
      LogLevel.error => l10n.monitoringLevelError,
    };

/// One glyph per level, so colour is never the only cue.
IconData monitoringLevelIcon(LogLevel level) => switch (level) {
  LogLevel.debug => AppIcons.levelDebug,
  LogLevel.info => AppIcons.info,
  LogLevel.warning => AppIcons.levelWarning,
  LogLevel.error => AppIcons.alert,
};

/// The level's tile: the existing status tints, warning as the caution tint
/// and error as the danger tint.
MxIconTileTone monitoringLevelTone(LogLevel level) => switch (level) {
  LogLevel.debug || LogLevel.info => MxIconTileTone.tinted,
  LogLevel.warning => MxIconTileTone.caution,
  LogLevel.error => MxIconTileTone.danger,
};

String monitoringStatusLabel(AppLocalizations l10n, LogStatus status) =>
    switch (status) {
      LogStatus.open => l10n.monitoringStatusOpen,
      LogStatus.fixed => l10n.monitoringStatusFixed,
    };

/// An open problem is a warning-toned pill, a fixed one the green: the label
/// says it too, so the tone is never the only cue.
MxBadgeTone monitoringStatusTone(LogStatus status) => switch (status) {
  LogStatus.open => MxBadgeTone.warning,
  LogStatus.fixed => MxBadgeTone.mastery,
};

String monitoringWindowLabel(AppLocalizations l10n, LogWindow window) =>
    switch (window) {
      LogWindow.hour => l10n.monitoringWindowHour,
      LogWindow.day => l10n.monitoringWindowDay,
      LogWindow.week => l10n.monitoringWindowWeek,
      LogWindow.month => l10n.monitoringWindowMonth,
      LogWindow.all => l10n.monitoringWindowAll,
    };

/// A filter chip: its name alone, with the choice's name when one is made,
/// with how many when several are (monitoring spec §3.2).
String monitoringChipLabel(
  AppLocalizations l10n,
  String label,
  List<String> chosen,
) => switch (chosen.length) {
  0 => label,
  1 => l10n.monitoringChipValue(label, chosen.single),
  final count => l10n.monitoringChipValue(label, '$count'),
};

/// A row's time (monitoring spec §3.2): 24-hour `HH:mm` for today, else the
/// short month and day, in local time.
String monitoringRowTime(AppLocalizations l10n, DateTime at, DateTime now) {
  final local = at.toLocal();
  final day = DateTime(local.year, local.month, local.day);
  if (day == DateTime(now.year, now.month, now.day)) {
    return DateFormat('HH:mm', l10n.localeName).format(local);
  }
  return DateFormat.MMMd(l10n.localeName).format(local);
}

/// The detail's time: the full date and `HH:mm:ss`, in local time.
String monitoringFullTime(AppLocalizations l10n, DateTime at) =>
    DateFormat.yMMMd(l10n.localeName).add_Hms().format(at.toLocal());
```

```dart
import 'package:flutter/material.dart';
import 'package:memox/features/monitoring/domain/entities/log_summary_entity.dart';
import 'package:memox/features/monitoring/presentation/widgets/support/monitoring_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// One log of a list (monitoring spec §3.2): the level as a glyph on a tile,
/// the event, the message's first line, the time and, for a warning or an
/// error of the server, its status. A screen reader hears one sentence.
class LogRowWidget extends StatelessWidget {
  const LogRowWidget({
    super.key,
    required this.log,
    required this.now,
    required this.onTap,
    this.hasDivider = true,
  });

  final LogSummaryEntity log;
  final DateTime now;
  final VoidCallback onTap;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final time = monitoringRowTime(l10n, log.occurredAt, now);
    final level = monitoringLevelLabel(l10n, log.level);
    final status = log.status;
    final statusLabel = status == null
        ? null
        : monitoringStatusLabel(l10n, status);
    return Semantics(
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      label: statusLabel == null
          ? l10n.monitoringRowLabelNoStatus(level, log.event, time)
          : l10n.monitoringRowLabel(level, log.event, time, statusLabel),
      child: MxListRow(
        leading: MxIconTile(
          icon: monitoringLevelIcon(log.level),
          tone: monitoringLevelTone(log.level),
        ),
        title: log.event,
        subtitle: log.subtitle,
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: AppSpacing.micro,
          children: [
            Text(time, style: context.textStyles.counter),
            if (status != null && statusLabel != null)
              MxBadge(label: statusLabel, tone: monitoringStatusTone(status)),
          ],
        ),
        onTap: onTap,
        hasDivider: hasDivider,
      ),
    );
  }
}
```

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// One choice of a filter sheet: the value and the name it shows.
@immutable
final class MonitoringChoice<T> {
  const MonitoringChoice(this.value, this.label);

  final T value;
  final String label;
}

/// Opens a filter sheet (monitoring spec §3.2) and returns the choice made,
/// or null when it is dismissed. [isMulti] lets several be chosen, as toggles
/// (an option row is a radio, which says "one of"); otherwise one is, as
/// option rows. Reset puts the sheet back to [resetTo]; Apply returns.
Future<Set<T>?> showMonitoringChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<MonitoringChoice<T>> choices,
  required Set<T> selected,
  required Set<T> resetTo,
  required bool isMulti,
}) => showMxBottomSheet<Set<T>>(
  context,
  builder: (_) => MonitoringChoiceSheetWidget<T>(
    title: title,
    choices: choices,
    selected: selected,
    resetTo: resetTo,
    isMulti: isMulti,
  ),
);

class MonitoringChoiceSheetWidget<T> extends StatefulWidget {
  const MonitoringChoiceSheetWidget({
    super.key,
    required this.title,
    required this.choices,
    required this.selected,
    required this.resetTo,
    required this.isMulti,
  });

  final String title;
  final List<MonitoringChoice<T>> choices;
  final Set<T> selected;
  final Set<T> resetTo;
  final bool isMulti;

  @override
  State<MonitoringChoiceSheetWidget<T>> createState() =>
      _MonitoringChoiceSheetWidgetState<T>();
}

class _MonitoringChoiceSheetWidgetState<T>
    extends State<MonitoringChoiceSheetWidget<T>> {
  late Set<T> _picked = {...widget.selected};

  void _toggle(T value, {required bool isOn}) => setState(
    () => _picked = isOn ? {..._picked, value} : ({..._picked}..remove(value)),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Text(widget.title, style: context.textStyles.compactTitle),
      ),
      footer: MxSheetActions.custom(
        isInSheet: true,
        children: [
          Expanded(
            child: MxButton(
              label: l10n.monitoringReset,
              tone: MxButtonTone.outline,
              isBlock: true,
              onPressed: () => setState(() => _picked = {...widget.resetTo}),
            ),
          ),
          Expanded(
            child: MxButton(
              label: l10n.monitoringApply,
              isBlock: true,
              onPressed: () => Navigator.of(context).pop(_picked),
            ),
          ),
        ],
      ),
      child: widget.isMulti ? _toggles() : _options(),
    );
  }

  Widget _toggles() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
    child: MxSection(
      children: [
        for (final choice in widget.choices)
          MxSettingsRow(
            label: choice.label,
            trailing: MxToggle(
              isOn: _picked.contains(choice.value),
              semanticLabel: choice.label,
              onChanged: (isOn) => _toggle(choice.value, isOn: isOn),
            ),
          ),
      ],
    ),
  );

  Widget _options() => Column(
    children: [
      for (final choice in widget.choices)
        MxOptionRow(
          title: choice.label,
          isSelected: _picked.contains(choice.value),
          onSelected: () => setState(() => _picked = {choice.value}),
          hasDivider: choice != widget.choices.last,
        ),
    ],
  );
}
```

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/log_window_model.dart';
import 'package:memox/features/monitoring/presentation/widgets/overlays/monitoring_choice_sheet_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/support/monitoring_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';

/// The Level sheet: any of the four levels. Reset is the default, warning
/// and error.
Future<Set<LogLevel>?> showMonitoringLevelSheet(
  BuildContext context, {
  required Set<LogLevel> selected,
}) {
  final l10n = context.l10n;
  return showMonitoringChoiceSheet<LogLevel>(
    context,
    title: l10n.monitoringChipLevel,
    choices: [
      for (final level in LogLevel.values)
        MonitoringChoice(level, monitoringLevelLabel(l10n, level)),
    ],
    selected: selected,
    resetTo: LogFilter.defaultLevels,
    isMulti: true,
  );
}

/// The Status sheet: open, fixed or both. Reset is the default, open.
Future<Set<LogStatus>?> showMonitoringStatusFilterSheet(
  BuildContext context, {
  required Set<LogStatus> selected,
}) {
  final l10n = context.l10n;
  return showMonitoringChoiceSheet<LogStatus>(
    context,
    title: l10n.monitoringChipStatus,
    choices: [
      for (final status in LogStatus.values)
        MonitoringChoice(status, monitoringStatusLabel(l10n, status)),
    ],
    selected: selected,
    resetTo: LogFilter.defaultStatuses,
    isMulti: true,
  );
}

/// The Category sheet: every value of [LogCategory], by the code the logs
/// carry, so a category another branch adds shows without a change here.
/// Reset is every category.
Future<Set<LogCategory>?> showMonitoringCategorySheet(
  BuildContext context, {
  required Set<LogCategory> selected,
}) => showMonitoringChoiceSheet<LogCategory>(
  context,
  title: context.l10n.monitoringChipCategory,
  choices: [
    for (final category in LogCategory.values)
      MonitoringChoice(category, category.name),
  ],
  selected: selected,
  resetTo: const {},
  isMulti: true,
);

/// The Time sheet: one window, from the last hour to all time.
Future<Set<LogWindow>?> showMonitoringWindowSheet(
  BuildContext context, {
  required LogWindow selected,
}) {
  final l10n = context.l10n;
  return showMonitoringChoiceSheet<LogWindow>(
    context,
    title: l10n.monitoringChipTime,
    choices: [
      for (final window in LogWindow.values)
        MonitoringChoice(window, monitoringWindowLabel(l10n, window)),
    ],
    selected: {selected},
    resetTo: const {LogWindow.all},
    isMulti: false,
  );
}
```

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The two ids of the device and user sheet; empty text is no id.
typedef DeviceUserChoice = ({String device, String user});

final _uuid = RegExp(r'^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$');

/// Opens the device and user sheet (monitoring spec §3.2) on [initial] and
/// returns what was applied, or null when it is dismissed.
Future<DeviceUserChoice?> showMonitoringDeviceUserSheet(
  BuildContext context, {
  required DeviceUserChoice initial,
}) => showMxBottomSheet<DeviceUserChoice>(
  context,
  builder: (_) => MonitoringDeviceUserSheetWidget(initial: initial),
);

/// Two fields, a device id and a user id: the ids the admin copies from a
/// log's details. A user id must be a uuid, since the server casts it.
class MonitoringDeviceUserSheetWidget extends StatefulWidget {
  const MonitoringDeviceUserSheetWidget({super.key, required this.initial});

  final DeviceUserChoice initial;

  @override
  State<MonitoringDeviceUserSheetWidget> createState() =>
      _MonitoringDeviceUserSheetWidgetState();
}

class _MonitoringDeviceUserSheetWidgetState
    extends State<MonitoringDeviceUserSheetWidget> {
  late final _device = TextEditingController(text: widget.initial.device);
  late final _user = TextEditingController(text: widget.initial.user);
  var _hasUserError = false;

  @override
  void dispose() {
    _device.dispose();
    _user.dispose();
    super.dispose();
  }

  void _apply() {
    final user = _user.text.trim();
    if (user.isNotEmpty && !_uuid.hasMatch(user)) {
      setState(() => _hasUserError = true);
      return;
    }
    Navigator.of(context).pop((device: _device.text.trim(), user: user));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Text(
          l10n.monitoringChipDevice,
          style: context.textStyles.compactTitle,
        ),
      ),
      footer: MxSheetActions.custom(
        isInSheet: true,
        children: [
          Expanded(
            child: MxButton(
              label: l10n.monitoringReset,
              tone: MxButtonTone.outline,
              isBlock: true,
              onPressed: () => setState(() {
                _device.clear();
                _user.clear();
                _hasUserError = false;
              }),
            ),
          ),
          Expanded(
            child: MxButton(
              label: l10n.monitoringApply,
              isBlock: true,
              onPressed: _apply,
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Column(
          spacing: AppSpacing.grouped,
          children: [
            MxTextField(
              controller: _device,
              label: l10n.monitoringDeviceLabel,
              hintText: l10n.monitoringDeviceLabel,
            ),
            MxTextField(
              controller: _user,
              label: l10n.monitoringUserLabel,
              hintText: l10n.monitoringUserLabel,
              errorText: _hasUserError ? l10n.monitoringUserInvalid : null,
              onChanged: (_) {
                if (_hasUserError) setState(() => _hasUserError = false);
              },
            ),
            MxNote(text: l10n.monitoringDeviceUserNote),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Write the tabs and the screen**

The rows are direct children of the page's scroll, so the list builds lazily; the search field and the chips sit above it and do not scroll. `_Refreshable` lets a short list still be pulled to refresh.

```dart
/// The two tabs of the Monitoring screen (monitoring spec §3.2). Which one is
/// open is the screen's own, not persisted.
enum MonitoringTab { server, notSent }
```

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/log_window_model.dart';
import 'package:memox/features/monitoring/presentation/widgets/overlays/monitoring_device_user_sheet_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/overlays/monitoring_filter_sheets_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/support/monitoring_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

/// The Server tab's filters (monitoring spec §3.2): five chips in a row that
/// scrolls, each opening its sheet. A chip that holds a choice shows it.
class MonitoringFilterBarWidget extends StatelessWidget {
  const MonitoringFilterBarWidget({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final LogFilter filter;
  final ValueChanged<LogFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final levels = [
      for (final level in LogLevel.values)
        if (filter.levels.contains(level)) monitoringLevelLabel(l10n, level),
    ];
    final statuses = [
      for (final status in LogStatus.values)
        if (filter.statuses.contains(status))
          monitoringStatusLabel(l10n, status),
    ];
    final ids = [?filter.deviceId, ?filter.userId];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Row(
        spacing: AppSpacing.control,
        children: [
          MxChipTrigger(
            label: monitoringChipLabel(l10n, l10n.monitoringChipLevel, levels),
            onPressed: () => unawaited(_pickLevels(context)),
          ),
          MxChipTrigger(
            label: monitoringChipLabel(
              l10n,
              l10n.monitoringChipStatus,
              statuses,
            ),
            onPressed: () => unawaited(_pickStatuses(context)),
          ),
          MxChipTrigger(
            label: monitoringChipLabel(l10n, l10n.monitoringChipCategory, [
              for (final category in filter.categories) category.name,
            ]),
            onPressed: () => unawaited(_pickCategories(context)),
          ),
          MxChipTrigger(
            label: monitoringChipLabel(l10n, l10n.monitoringChipTime, [
              if (filter.window != LogWindow.all)
                monitoringWindowLabel(l10n, filter.window),
            ]),
            onPressed: () => unawaited(_pickWindow(context)),
          ),
          MxChipTrigger(
            label: monitoringChipLabel(l10n, l10n.monitoringChipDevice, ids),
            onPressed: () => unawaited(_pickDeviceUser(context)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLevels(BuildContext context) async {
    final picked = await showMonitoringLevelSheet(
      context,
      selected: filter.levels,
    );
    if (picked != null) onChanged(filter.withLevels(picked));
  }

  Future<void> _pickStatuses(BuildContext context) async {
    final picked = await showMonitoringStatusFilterSheet(
      context,
      selected: filter.statuses,
    );
    if (picked != null) onChanged(filter.withStatuses(picked));
  }

  Future<void> _pickCategories(BuildContext context) async {
    final picked = await showMonitoringCategorySheet(
      context,
      selected: filter.categories,
    );
    if (picked != null) onChanged(filter.withCategories(picked));
  }

  Future<void> _pickWindow(BuildContext context) async {
    final picked = await showMonitoringWindowSheet(
      context,
      selected: filter.window,
    );
    if (picked != null && picked.isNotEmpty) {
      onChanged(filter.withWindow(picked.single));
    }
  }

  Future<void> _pickDeviceUser(BuildContext context) async {
    final picked = await showMonitoringDeviceUserSheet(
      context,
      initial: (device: filter.deviceId ?? '', user: filter.userId ?? ''),
    );
    if (picked != null) {
      onChanged(filter.withDevice(picked.device).withUser(picked.user));
    }
  }
}
```

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_list_controller.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_list_state.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_load_failure_state.dart';
import 'package:memox/features/monitoring/presentation/widgets/items/log_row_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

/// The Server tab's body: one widget per state of monitoring spec §3.4.
class MonitoringServerListWidget extends ConsumerWidget {
  const MonitoringServerListWidget({
    super.key,
    required this.onOpenLog,
    required this.onOpenNotSent,
    required this.onClearFilters,
  });

  final ValueChanged<String> onOpenLog;
  final VoidCallback onOpenNotSent;
  final VoidCallback onClearFilters;

  static const int _skeletonRows = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(monitoringListControllerProvider);
    final controller = ref.watch(monitoringListControllerProvider.notifier);
    return switch (state.content) {
      MonitoringListLoading() => MxScreenScroll(
        children: [
          MxSkeletonList(
            semanticLabel: l10n.commonLoading,
            rows: _skeletonRows,
          ),
        ],
      ),
      MonitoringListFailed(:final failure) => MxScreenScroll(
        children: [
          const SizedBox(height: AppSpacing.control),
          _failure(context, failure, controller),
        ],
      ),
      MonitoringListLoaded(:final items) when items.isEmpty => _Refreshable(
        onRefresh: controller.refresh,
        child: MxScreenScroll(
          children: [
            const SizedBox(height: AppSpacing.control),
            if (state.filter.isDefault)
              MxEmptyState(
                icon: AppIcons.learned,
                title: l10n.monitoringEmptyTitle,
                body: l10n.monitoringEmptyBody,
                tone: MxEmptyStateTone.success,
                isCompact: true,
              )
            else
              MxEmptyState(
                icon: AppIcons.searchOff,
                title: l10n.monitoringNoMatchTitle,
                tone: MxEmptyStateTone.neutral,
                isCompact: true,
                actionLabel: l10n.monitoringClearFilters,
                onAction: onClearFilters,
              ),
          ],
        ),
      ),
      final MonitoringListLoaded loaded => _Rows(
        loaded: loaded,
        isDefaultFilter: state.filter.isDefault,
        onOpenLog: onOpenLog,
      ),
    };
  }

  Widget _failure(
    BuildContext context,
    MonitoringLoadFailure failure,
    MonitoringListController controller,
  ) {
    final l10n = context.l10n;
    return switch (failure) {
      MonitoringLoadFailure.notAdmin => MxEmptyState(
        icon: AppIcons.lock,
        title: l10n.monitoringNotAdminTitle,
        tone: MxEmptyStateTone.neutral,
        isCompact: true,
      ),
      MonitoringLoadFailure.offline => Column(
        spacing: AppSpacing.grouped,
        children: [
          MxErrorState(
            title: l10n.monitoringOfflineTitle,
            body: l10n.monitoringOfflineBody,
            retryLabel: l10n.commonRetry,
            onRetry: controller.retry,
          ),
          MxButton(
            label: l10n.monitoringOpenNotSent,
            tone: MxButtonTone.outline,
            icon: AppIcons.inbox,
            isBlock: true,
            onPressed: onOpenNotSent,
          ),
        ],
      ),
      MonitoringLoadFailure.other => MxErrorState(
        title: l10n.monitoringErrorTitle,
        body: l10n.libraryLoadErrorBody,
        retryLabel: l10n.commonRetry,
        onRetry: controller.retry,
      ),
    };
  }
}

/// The rows read so far, the count above them and the state of the end
/// below. The next page is asked for when the last ten rows come into view;
/// a failed page waits for its Retry instead of asking again on every
/// scroll.
class _Rows extends ConsumerWidget {
  const _Rows({
    required this.loaded,
    required this.isDefaultFilter,
    required this.onOpenLog,
  });

  final MonitoringListLoaded loaded;
  final bool isDefaultFilter;
  final ValueChanged<String> onOpenLog;

  static const double _prefetchExtent = 10 * AppSize.listRowMin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.watch(monitoringListControllerProvider.notifier);
    final now = ref.watch(dayClockProvider).now();
    final count = loaded.items.length;
    final hasMore = loaded.next != null;
    final header = switch ((isDefaultFilter, hasMore)) {
      (true, false) => l10n.monitoringCountOpen(count),
      (true, true) => l10n.monitoringCountOpenMore(count),
      (false, false) => l10n.monitoringCountLogs(count),
      (false, true) => l10n.monitoringCountLogsMore(count),
    };
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (loaded.more == MonitoringMore.idle &&
            hasMore &&
            notification.metrics.extentAfter < _prefetchExtent) {
          unawaited(controller.loadMore());
        }
        return false;
      },
      child: _Refreshable(
        onRefresh: controller.refresh,
        child: MxScreenScroll(
          children: [
            const SizedBox(height: AppSpacing.control),
            MxListSectionHeader(label: header),
            for (final (index, log) in loaded.items.indexed)
              LogRowWidget(
                log: log,
                now: now,
                onTap: () => onOpenLog(log.id),
                hasDivider: index < count - 1,
              ),
            const SizedBox(height: AppSpacing.grouped),
            _End(loaded: loaded, onRetry: controller.loadMore),
          ],
        ),
      ),
    );
  }
}

/// The spinner under the last row while a page loads, the retry when it
/// failed, "No more logs" at the end.
class _End extends StatelessWidget {
  const _End({required this.loaded, required this.onRetry});

  final MonitoringListLoaded loaded;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch ((loaded.more, loaded.next)) {
      (MonitoringMore.loading, _) => Center(
        child: MxSpinner(semanticLabel: l10n.commonLoading),
      ),
      (MonitoringMore.failed, _) => MxInlineBanner(
        tone: MxBannerTone.danger,
        message: l10n.monitoringLoadMoreFailed,
        actions: [
          MxButton(
            label: l10n.commonRetry,
            size: MxButtonSize.compact,
            onPressed: () => unawaited(onRetry()),
          ),
        ],
      ),
      (_, null) => Text(
        l10n.monitoringNoMore,
        textAlign: TextAlign.center,
        style: context.textStyles.footerCaption,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// Pull to refresh over a list that may be shorter than the screen: the
/// scroll accepts a drag whatever its length, on top of the platform's own
/// physics.
class _Refreshable extends StatelessWidget {
  const _Refreshable({required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final behavior = ScrollConfiguration.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ScrollConfiguration(
        behavior: behavior.copyWith(
          physics: AlwaysScrollableScrollPhysics(
            parent: behavior.getScrollPhysics(context),
          ),
        ),
        child: child,
      ),
    );
  }
}
```

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_list_controller.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_filter_bar_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_server_list_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

/// The Server tab: the search field and the filters above the list, which
/// alone scrolls. The search field's text is the screen's, so a reset of
/// the filters can clear it.
class MonitoringServerTabWidget extends ConsumerWidget {
  const MonitoringServerTabWidget({
    super.key,
    required this.search,
    required this.onOpenLog,
    required this.onOpenNotSent,
    required this.onClearFilters,
  });

  final TextEditingController search;
  final ValueChanged<String> onOpenLog;
  final VoidCallback onOpenNotSent;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.watch(monitoringListControllerProvider.notifier);
    final filter = ref.watch(
      monitoringListControllerProvider.select((state) => state.filter),
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.grouped,
            AppSpacing.gutter,
            AppSpacing.control,
          ),
          child: MxSearchField(
            controller: search,
            hintText: l10n.monitoringSearchHint,
            clearLabel: l10n.monitoringSearchClear,
            onChanged: controller.search,
          ),
        ),
        MonitoringFilterBarWidget(
          filter: filter,
          onChanged: controller.setFilter,
        ),
        Expanded(
          child: MonitoringServerListWidget(
            onOpenLog: onOpenLog,
            onOpenNotSent: onOpenNotSent,
            onClearFilters: onClearFilters,
          ),
        ),
      ],
    );
  }
}
```

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/features/monitoring/presentation/controllers/pending_logs_controller.dart';
import 'package:memox/features/monitoring/presentation/widgets/items/log_row_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/overlays/monitoring_filter_sheets_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/support/monitoring_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// The Not sent tab (monitoring spec §3.2): the device buffer, read-only, so
/// it works offline. Only the level can be filtered.
class MonitoringPendingTabWidget extends ConsumerWidget {
  const MonitoringPendingTabWidget({super.key, required this.onOpenLog});

  final ValueChanged<String> onOpenLog;

  static const int _skeletonRows = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(pendingLogsControllerProvider);
    final levels = [
      for (final level in LogLevel.values)
        if (state.levels.contains(level)) monitoringLevelLabel(l10n, level),
    ];
    return Column(
      children: [
        if (state.logs.value case final logs?)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.grouped,
              AppSpacing.gutter,
              0,
            ),
            child: MxNote(text: l10n.monitoringPendingNote(logs.total)),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: MxChipTrigger(
              label: monitoringChipLabel(
                l10n,
                l10n.monitoringChipLevel,
                levels,
              ),
              onPressed: () => unawaited(_pickLevels(context, ref)),
            ),
          ),
        ),
        Expanded(
          child: switch (state.logs) {
            AsyncData(:final value) => _rows(context, ref, value),
            AsyncError() => MxScreenScroll(
              children: [
                MxErrorState(
                  title: l10n.monitoringErrorTitle,
                  body: l10n.libraryLoadErrorBody,
                  retryLabel: l10n.commonRetry,
                  onRetry: () => ref.invalidate(pendingLogsControllerProvider),
                ),
              ],
            ),
            _ => MxScreenScroll(
              children: [
                MxSkeletonList(
                  semanticLabel: l10n.commonLoading,
                  rows: _skeletonRows,
                ),
              ],
            ),
          },
        ),
      ],
    );
  }

  Widget _rows(BuildContext context, WidgetRef ref, PendingLogs logs) {
    final l10n = context.l10n;
    if (logs.items.isEmpty) {
      final isBufferEmpty = logs.total == 0;
      return MxScreenScroll(
        children: [
          const SizedBox(height: AppSpacing.control),
          MxEmptyState(
            icon: isBufferEmpty ? AppIcons.learned : AppIcons.searchOff,
            title: isBufferEmpty
                ? l10n.monitoringPendingNoneTitle
                : l10n.monitoringPendingFilteredTitle,
            body: isBufferEmpty
                ? l10n.monitoringPendingNoneBody
                : l10n.monitoringPendingFilteredBody,
            tone: isBufferEmpty
                ? MxEmptyStateTone.success
                : MxEmptyStateTone.neutral,
            isCompact: true,
          ),
        ],
      );
    }
    final now = ref.watch(dayClockProvider).now();
    return MxScreenScroll(
      children: [
        const SizedBox(height: AppSpacing.control),
        for (final (index, log) in logs.items.indexed)
          LogRowWidget(
            log: log,
            now: now,
            onTap: () => onOpenLog(log.id),
            hasDivider: index < logs.items.length - 1,
          ),
      ],
    );
  }

  Future<void> _pickLevels(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(pendingLogsControllerProvider.notifier);
    final picked = await showMonitoringLevelSheet(
      context,
      selected: ref.read(pendingLogsControllerProvider).levels,
    );
    if (picked != null) controller.setLevels(picked);
  }
}
```

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_list_controller.dart';
import 'package:memox/features/monitoring/presentation/controllers/pending_logs_controller.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_tab_state.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_pending_tab_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_server_tab_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';

/// Screen 28, Monitoring (ADR-018 §8): the admin reads the app's logs and
/// triages them. Not in the kit; shaped with Impeccable 2026-09-29. Two
/// tabs: the server's logs and the device's buffer. Navigation arrives as
/// callbacks.
class MonitoringScreen extends ConsumerStatefulWidget {
  const MonitoringScreen({
    super.key,
    required this.onOpenServerLog,
    required this.onOpenPendingLog,
  });

  final ValueChanged<String> onOpenServerLog;
  final ValueChanged<String> onOpenPendingLog;

  @override
  ConsumerState<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen> {
  final _search = TextEditingController();
  var _tab = MonitoringTab.server;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    ref.read(monitoringListControllerProvider.notifier).clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Both tabs' controllers live as long as the screen, so switching tabs
    // or coming back from a detail keeps the pages read (spec §3.5).
    ref.listen(
      monitoringListControllerProvider.select((state) => state.filter),
      (_, _) {},
    );
    final waiting = ref.watch(
      pendingLogsControllerProvider.select(
        (state) => state.logs.value?.total ?? 0,
      ),
    );
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.monitoringTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.control,
              AppSpacing.gutter,
              0,
            ),
            child: MxSegmentedTray<MonitoringTab>(
              segments: [
                MxSegment(
                  value: MonitoringTab.server,
                  label: l10n.monitoringTabServer,
                ),
                MxSegment(
                  value: MonitoringTab.notSent,
                  label: l10n.monitoringTabNotSent(waiting),
                ),
              ],
              selected: _tab,
              onSelected: (tab) => setState(() => _tab = tab),
            ),
          ),
          Expanded(
            child: switch (_tab) {
              MonitoringTab.server => MonitoringServerTabWidget(
                search: _search,
                onOpenLog: widget.onOpenServerLog,
                onOpenNotSent: () =>
                    setState(() => _tab = MonitoringTab.notSent),
                onClearFilters: _clearFilters,
              ),
              MonitoringTab.notSent => MonitoringPendingTabWidget(
                onOpenLog: widget.onOpenPendingLog,
              ),
            },
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Run the tests, the audit and the guard**

Run: `flutter test test/features/monitoring test/visual_audit test/app/l10n_test.dart`
Expected: PASS (`All tests passed!`; the audit runs both themes at 1x and 2x text).
Run: `python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8` (any interpreter of Python 3.12+ with the guard's requirements)
Expected: `Code verification passed.`

- [ ] **Step 7: Commit**

```bash
git add lib/features/monitoring lib/l10n test/support/monitoring_screen_harness.dart test/features/monitoring test/visual_audit/screens/features/monitoring
git commit -m "feat(monitoring): the list screen, Not sent tab and filter sheets"
```

---

### Task 10: The detail controller, page and triage sheet

**Files:**
- Create: `lib/features/monitoring/presentation/states/monitoring_detail_state.dart`
- Create: `lib/features/monitoring/presentation/controllers/monitoring_detail_controller.dart`
- Create: `lib/features/monitoring/presentation/widgets/overlays/monitoring_status_sheet_widget.dart`
- Create: `lib/features/monitoring/presentation/widgets/sections/{monitoring_detail_summary_widget,monitoring_code_card_widget,monitoring_detail_body_widget}.dart`
- Create: `lib/features/monitoring/presentation/screens/monitoring_detail_screen.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/monitoring/presentation/{monitoring_detail_controller_test,monitoring_detail_screen_test}.dart`, `test/visual_audit/screens/features/monitoring/screens/monitoring_detail_screen_visual_audit_test.dart`

**Interfaces:**
- Consumes: Tasks 5 to 9; `monitoringListControllerProvider.notifier.statusChanged` (Task 8); labels (Task 9).
- Produces:
  - sealed `MonitoringDetailContent` = `MonitoringDetailLoading | MonitoringDetailLoaded(record) | MonitoringDetailGone | MonitoringDetailFailed(failure)`; sealed `MonitoringDetailNotice` = `StatusChanged(status) | StatusChangeFailed(status, note)`; `MonitoringDetailState({content, changing, notice})`.
  - `monitoringDetailControllerProvider(String id, bool isLocal)`: `Future<void> retry()`, `Future<void> setStatus(LogStatus, {String? note})` (one at a time; only a loaded record with a status; updates the list's row when a list controller is alive).
  - `showMonitoringStatusSheet(context, {required LogStatus target}) → Future<String?>` (the trimmed note, empty for none; null when dismissed).
  - `MonitoringDetailScreen({required String logId, required bool isLocal})`.

- [ ] **Step 1: Write the failing tests**

Review Focus 1 (256 kB context) and 4 (a change failing offline) are in these files.

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_detail_controller.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_list_controller.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_detail_state.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_list_state.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_load_failure_state.dart';

import '../../../support/monitoring_fakes.dart';

// Monitoring spec §3.3, §5: the detail reads one log and changes its status.
void main() {
  late FakeMonitoringRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeMonitoringRepository();
    container = ProviderContainer(
      overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  final server = monitoringDetailControllerProvider('a', false);
  final local = monitoringDetailControllerProvider('a', true);

  Future<MonitoringDetailState> open(
    MonitoringDetailControllerProvider provider,
  ) async {
    container.listen(provider, (_, _) {});
    await pumpEventQueue();
    return container.read(provider);
  }

  test('a server log is read and shown', () async {
    repository.servers['a'] = record('a');

    final state = await open(server);

    expect(
      (state.content as MonitoringDetailLoaded).record.event,
      'sync.push_failed',
    );
    expect(state.changing, isNull);
    expect(state.notice, isNull);
  });

  test(
    'a buffered log is read from the buffer, and cannot be triaged',
    () async {
      repository.pendings['a'] = record('a', status: null);

      final state = await open(local);
      await container.read(local.notifier).setStatus(LogStatus.fixed);

      expect(state.content, isA<MonitoringDetailLoaded>());
      expect(repository.statusChanges, isEmpty);
    },
  );

  test('a log that is gone is told so', () async {
    final state = await open(server);

    expect(state.content, isA<MonitoringDetailGone>());
  });

  test('a read that fails is told apart, and a retry reads again', () async {
    repository.readError = const OfflineFailure(cause: 'x');

    final state = await open(server);

    expect(
      (state.content as MonitoringDetailFailed).failure,
      MonitoringLoadFailure.offline,
    );
    repository
      ..readError = null
      ..servers['a'] = record('a');
    await container.read(server.notifier).retry();
    expect(container.read(server).content, isA<MonitoringDetailLoaded>());
  });

  test('not an admin is its own failure', () async {
    repository.readError = const NotAdminFailure(cause: 'x');

    final state = await open(server);

    expect(
      (state.content as MonitoringDetailFailed).failure,
      MonitoringLoadFailure.notAdmin,
    );
  });

  test('marking fixed shows the server\'s row and says so', () async {
    repository.servers['a'] = record('a');
    await open(server);

    await container
        .read(server.notifier)
        .setStatus(LogStatus.fixed, note: 'index added');

    final state = container.read(server);
    final row = (state.content as MonitoringDetailLoaded).record;
    expect(row.status, LogStatus.fixed);
    expect(row.statusNote, 'index added');
    expect((state.notice! as StatusChanged).status, LogStatus.fixed);
    expect(state.changing, isNull);
    expect(repository.statusChanges.single.note, 'index added');
  });

  test('the list drops the row when its filter no longer matches', () async {
    repository.servers['a'] = record('a');
    repository.autoPage = LogPage(items: [summary('a'), summary('b')]);
    container.listen(monitoringListControllerProvider, (_, _) {});
    await pumpEventQueue();
    await open(server);

    await container.read(server.notifier).setStatus(LogStatus.fixed);

    final list =
        container.read(monitoringListControllerProvider).content
            as MonitoringListLoaded;
    expect([for (final item in list.items) item.id], ['b']);
  });

  test('a change with no list open does not open one', () async {
    repository.servers['a'] = record('a');
    await open(server);

    await container.read(server.notifier).setStatus(LogStatus.fixed);

    expect(container.exists(monitoringListControllerProvider), isFalse);
  });

  // Review focus: a status change failing offline.
  test('a change that fails changes nothing and offers the same change '
      'again', () async {
    repository.servers['a'] = record('a');
    await open(server);
    repository.statusError = const OfflineFailure(cause: 'x');

    await container
        .read(server.notifier)
        .setStatus(LogStatus.fixed, note: 'index added');

    final state = container.read(server);
    expect(
      (state.content as MonitoringDetailLoaded).record.status,
      LogStatus.open,
    );
    final failed = state.notice! as StatusChangeFailed;
    expect(failed.status, LogStatus.fixed);
    expect(failed.note, 'index added');
    expect(state.changing, isNull);

    repository.statusError = null;
    await container
        .read(server.notifier)
        .setStatus(failed.status, note: failed.note);
    expect(
      (container.read(server).content as MonitoringDetailLoaded).record.status,
      LogStatus.fixed,
    );
  });

  test('a second change waits for the first', () async {
    repository.servers['a'] = record('a');
    await open(server);
    repository.statusGate = Completer<void>();

    final first = container.read(server.notifier).setStatus(LogStatus.fixed);
    await pumpEventQueue();
    expect(container.read(server).changing, LogStatus.fixed);
    await container.read(server.notifier).setStatus(LogStatus.open);
    repository.statusGate!.complete();
    await first;

    expect(repository.statusChanges, hasLength(1));
  });

  test('a change of a log that is gone leaves the page saying so', () async {
    repository.servers['a'] = record('a');
    await open(server);
    repository.servers.remove('a');

    await container.read(server.notifier).setStatus(LogStatus.fixed);

    expect(container.read(server).content, isA<MonitoringDetailGone>());
  });

  test('a context of 256 kB is read and kept whole', () async {
    final big = 'x' * (256 * 1024);
    repository.servers['a'] = record('a', context: {'args': big});

    final state = await open(server);

    final row = (state.content as MonitoringDetailLoaded).record;
    expect((row.context['args']! as String).length, 256 * 1024);
  });
}
```

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_detail_screen.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../../support/library_harness.dart';
import '../../../support/monitoring_fakes.dart';

// Monitoring spec §3.3, §3.4, §5: the detail page and its triage.

List<Override> _overrides(FakeMonitoringRepository repository) => [
  monitoringRepositoryProvider.overrideWithValue(repository),
];

/// The page on a tall phone, so every card is built: a list builds only
/// what is near the screen.
Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  FakeMonitoringRepository repository, {
  bool isLocal = false,
  double textScale = 1,
  Locale locale = const Locale('en'),
}) async {
  await pumpLibraryScreen(
    tester,
    env,
    MonitoringDetailScreen(logId: 'a', isLocal: isLocal),
    overrides: _overrides(repository),
    textScale: textScale,
    locale: locale,
  );
  tester.view.physicalSize = const Size(360, 4000);
  await tester.pump();
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Marks the log fixed through the sheet, with [note].
Future<void> _markFixed(WidgetTester tester, {String note = ''}) async {
  await tester.tap(find.widgetWithText(MxButton, 'Mark fixed'));
  await tester.pumpAndSettle();
  if (note.isNotEmpty) {
    await tester.enterText(find.byType(TextField), note);
  }
  await tester.tap(find.widgetWithText(MxButton, 'Mark fixed').last);
  await _settle(tester);
}

void main() {
  libraryTest('an open error shows its summary, message, error, stack '
      'trace and context', (tester, env) async {
    final repository = FakeMonitoringRepository()..servers['a'] = record('a');

    await _pump(tester, env, repository);

    expect(find.text('sync.push_failed'), findsWidgets);
    expect(find.text('Error'), findsWidgets);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('sync'), findsOneWidget);
    expect(find.text('device-1'), findsOneWidget);
    expect(find.text('8.0.0 (12)'), findsOneWidget);
    expect(find.text('android 14'), findsOneWidget);
    expect(find.text('The server refused the push'), findsOneWidget);
    expect(find.textContaining('PostgrestException'), findsWidgets);
    expect(find.textContaining('SyncCoordinator.runOnce'), findsOneWidget);
    expect(find.textContaining('"entity": "deck"'), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Mark fixed'), findsOneWidget);
  });

  libraryTest('the stack trace and context are set in the code style, '
      'selectable', (tester, env) async {
    final repository = FakeMonitoringRepository()..servers['a'] = record('a');

    await _pump(tester, env, repository);

    final trace = tester.widget<SelectableText>(
      find.widgetWithText(
        SelectableText,
        '#0      SyncCoordinator.runOnce (sync_coordinator.dart:42)',
      ),
    );
    expect(trace.style!.fontFamily, 'monospace');
    expect(find.byType(SelectableText), findsNWidgets(4));
  });

  libraryTest('a fixed error says who and when, shows the note, and offers '
      'Reopen', (tester, env) async {
    final repository = FakeMonitoringRepository()
      ..servers['a'] = record(
        'a',
        status: LogStatus.fixed,
        statusNote: 'index added',
        statusChangedBy: 'admin-1',
        statusChangedAt: DateTime.utc(2026, 9, 27, 9, 30, 5),
      );

    await _pump(tester, env, repository);

    expect(
      find.text('Fixed by admin-1 · Sep 27, 2026 09:30:05'),
      findsOneWidget,
    );
    expect(find.text('index added'), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Reopen'), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Mark fixed'), findsNothing);
  });

  libraryTest('a row of the device buffer has no triage and no user', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()
      ..pendings['a'] = record('a', status: null);

    await _pump(tester, env, repository, isLocal: true);

    expect(find.byType(MxFooterBar), findsNothing);
    expect(find.text('Status'), findsNothing);
    expect(find.text('MESSAGE'), findsOneWidget);
  });

  libraryTest('an info with no error, trace or context shows only what it '
      'has', (tester, env) async {
    final repository = FakeMonitoringRepository()
      ..servers['a'] = record(
        'a',
        level: LogLevel.info,
        status: null,
        errorType: null,
        errorMessage: null,
        stackTrace: null,
        context: const {},
      );

    await _pump(tester, env, repository);

    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.text('Stack trace'), findsNothing);
    expect(find.byType(MxFooterBar), findsNothing);
  });

  libraryTest('Mark fixed asks for an optional note, says so, and the button '
      'becomes Reopen', (tester, env) async {
    final repository = FakeMonitoringRepository()..servers['a'] = record('a');
    await _pump(tester, env, repository);

    await _markFixed(tester, note: '  index added ');

    expect(repository.statusChanges.single.status, LogStatus.fixed);
    expect(repository.statusChanges.single.note, 'index added');
    expect(find.text('Marked fixed'), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Reopen'), findsOneWidget);
    expect(find.text('index added'), findsOneWidget);
  });

  libraryTest('cancelling the sheet changes nothing', (tester, env) async {
    final repository = FakeMonitoringRepository()..servers['a'] = record('a');
    await _pump(tester, env, repository);

    await tester.tap(find.widgetWithText(MxButton, 'Mark fixed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.statusChanges, isEmpty);
    expect(find.widgetWithText(MxButton, 'Mark fixed'), findsOneWidget);
  });

  libraryTest('Reopen says Reopened', (tester, env) async {
    final repository = FakeMonitoringRepository()
      ..servers['a'] = record('a', status: LogStatus.fixed);
    await _pump(tester, env, repository);

    await tester.tap(find.widgetWithText(MxButton, 'Reopen'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MxButton, 'Reopen').last);
    await _settle(tester);

    expect(repository.statusChanges.single.status, LogStatus.open);
    expect(find.text('Reopened'), findsOneWidget);
  });

  // Review focus: a status change failing offline.
  libraryTest('a change that fails offline says nothing changed and Retry '
      'does it', (tester, env) async {
    final repository = FakeMonitoringRepository()
      ..servers['a'] = record('a')
      ..statusError = const OfflineFailure(cause: 'x');
    await _pump(tester, env, repository);

    await _markFixed(tester, note: 'index added');

    expect(find.text("Couldn't change that. Nothing changed."), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Mark fixed'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);

    repository.statusError = null;
    await tester.tap(find.text('Retry'));
    await _settle(tester);

    expect(repository.statusChanges, hasLength(2));
    expect(repository.statusChanges.last.note, 'index added');
    expect(find.widgetWithText(MxButton, 'Reopen'), findsOneWidget);
  });

  libraryTest('Copy puts the whole log on the clipboard as JSON', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..servers['a'] = record('a');
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(tester, env, repository);

    await tester.tap(find.byTooltip('Copy log'));
    await _settle(tester);

    expect(copied, contains('"event": "sync.push_failed"'));
    expect(copied, contains('"stackTrace"'));
    expect(copied, contains('"deviceId": "device-1"'));
    expect(find.text('Copied'), findsOneWidget);
  });

  libraryTest('while it loads the page is a skeleton, with no actions', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()
      ..servers['a'] = record('a')
      ..readGate = Completer<void>();

    await _pump(tester, env, repository);

    expect(find.byType(MxSkeletonList), findsOneWidget);
    expect(find.byTooltip('Copy log'), findsNothing);
    expect(find.byType(MxFooterBar), findsNothing);
    repository.readGate!.complete();
    await _settle(tester);
    expect(find.byType(MxSkeletonList), findsNothing);
  });

  libraryTest('a log that is gone says it may have been cleaned up', (
    tester,
    env,
  ) async {
    await _pump(tester, env, FakeMonitoringRepository());

    expect(find.text('This log is gone'), findsOneWidget);
    expect(find.text('It may have been cleaned up.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  libraryTest('offline and other failures offer Retry, not an admin its '
      'words', (tester, env) async {
    final repository = FakeMonitoringRepository()
      ..readError = const OfflineFailure(cause: 'x');
    await _pump(tester, env, repository);
    expect(find.text("Can't reach the server"), findsOneWidget);
    expect(find.byType(MxErrorState), findsOneWidget);

    repository.readError = const NotAdminFailure(cause: 'x');
    await tester.tap(find.text('Retry'));
    await _settle(tester);
    expect(find.text('Only an admin can see this'), findsOneWidget);
  });

  // Review focus: a 256 kB context on the detail.
  libraryTest('a 256 kB context renders whole, selectable, in a scroll', (
    tester,
    env,
  ) async {
    final big = List.generate(4096, (i) => 'line $i ${'x' * 50}').join('\n');
    final repository = FakeMonitoringRepository()
      ..servers['a'] = record('a', context: {'args': big});

    await _pump(tester, env, repository);
    await tester.fling(find.byType(ListView), const Offset(0, -30000), 20000);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SelectableText), findsWidgets);
  });

  for (final locale in [const Locale('en'), const Locale('vi')]) {
    libraryTest('${locale.languageCode} at text scale 2 does not overflow', (
      tester,
      env,
    ) async {
      final repository = FakeMonitoringRepository()
        ..servers['a'] = record(
          'a',
          event: 'db.slow_query.${'very_long_segment.' * 6}end',
          status: LogStatus.fixed,
          statusNote: 'A note that is long enough to wrap onto several lines',
          statusChangedBy: '00000000-0000-0000-0000-0000000000ad',
          statusChangedAt: DateTime.utc(2026, 9, 27, 9, 30, 5),
        );

      await _pump(tester, env, repository, textScale: 2, locale: locale);

      expect(tester.takeException(), isNull);
    });
  }
}
```

```dart
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_detail_screen.dart';

import '../../../../../support/library_harness.dart';
import '../../../../../support/monitoring_fakes.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 28, detail', (tester, env) async {
    final repository = FakeMonitoringRepository()..servers['a'] = record('a');
    await auditProductionScreen(
      tester,
      screen: MonitoringDetailScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        const MonitoringDetailScreen(logId: 'a', isLocal: false),
        brightness: brightness,
        textScale: scale,
        overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
      ),
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/monitoring/presentation/monitoring_detail_controller_test.dart`
Expected: FAIL to compile: `Error when reading 'lib/features/monitoring/presentation/controllers/monitoring_detail_controller.dart'`.

- [ ] **Step 3: Add the strings**

Append to `lib/l10n/app_en.arb`:

```json
  "monitoringDetailTitle": "Log",
  "@monitoringDetailTitle": {
    "description": "Screen 28 detail: the app bar title while the log loads."
  },
  "monitoringCopy": "Copy log",
  "@monitoringCopy": {
    "description": "Screen 28 detail: the copy button name; it copies the log as JSON."
  },
  "monitoringCopied": "Copied",
  "@monitoringCopied": {
    "description": "Screen 28 detail: the toast after Copy log."
  },
  "monitoringSummary": "Details",
  "@monitoringSummary": {
    "description": "Screen 28 detail: the summary section title."
  },
  "monitoringFieldEvent": "Event",
  "@monitoringFieldEvent": {
    "description": "Screen 28 detail: the event row label."
  },
  "monitoringFieldLevel": "Level",
  "@monitoringFieldLevel": {
    "description": "Screen 28 detail: the level row label."
  },
  "monitoringFieldStatus": "Status",
  "@monitoringFieldStatus": {
    "description": "Screen 28 detail: the status row label."
  },
  "monitoringFieldTime": "Time",
  "@monitoringFieldTime": {
    "description": "Screen 28 detail: the time row label."
  },
  "monitoringFieldCategory": "Category",
  "@monitoringFieldCategory": {
    "description": "Screen 28 detail: the category row label."
  },
  "monitoringFieldSource": "Source",
  "@monitoringFieldSource": {
    "description": "Screen 28 detail: the source row label."
  },
  "monitoringFieldDevice": "Device",
  "@monitoringFieldDevice": {
    "description": "Screen 28 detail: the device row label."
  },
  "monitoringFieldApp": "App",
  "@monitoringFieldApp": {
    "description": "Screen 28 detail: the app version row label."
  },
  "monitoringFieldPlatform": "Platform",
  "@monitoringFieldPlatform": {
    "description": "Screen 28 detail: the platform row label."
  },
  "monitoringFieldUser": "User",
  "@monitoringFieldUser": {
    "description": "Screen 28 detail: the user row label."
  },
  "monitoringFieldNote": "Note",
  "@monitoringFieldNote": {
    "description": "Screen 28 detail: the triage note row label."
  },
  "monitoringFixedBy": "Fixed by {user} · {date}",
  "@monitoringFixedBy": {
    "placeholders": {
      "user": {
        "type": "String"
      },
      "date": {
        "type": "String"
      }
    },
    "description": "Screen 28 detail: the status row of a fixed log."
  },
  "monitoringMessage": "Message",
  "@monitoringMessage": {
    "description": "Screen 28 detail: the message card title."
  },
  "monitoringError": "Error",
  "@monitoringError": {
    "description": "Screen 28 detail: the error card title."
  },
  "monitoringStackTrace": "Stack trace",
  "@monitoringStackTrace": {
    "description": "Screen 28 detail: the stack trace card title."
  },
  "monitoringContext": "Context",
  "@monitoringContext": {
    "description": "Screen 28 detail: the context card title."
  },
  "monitoringMarkFixed": "Mark fixed",
  "@monitoringMarkFixed": {
    "description": "Screen 28 detail: the triage button of an open log."
  },
  "monitoringReopen": "Reopen",
  "@monitoringReopen": {
    "description": "Screen 28 detail: the triage button of a fixed log."
  },
  "monitoringNoteLabel": "Note (optional)",
  "@monitoringNoteLabel": {
    "description": "Screen 28 detail: the note field of the triage sheet."
  },
  "monitoringNoteHint": "What did you do?",
  "@monitoringNoteHint": {
    "description": "Screen 28 detail: the note field placeholder."
  },
  "monitoringMarkedFixed": "Marked fixed",
  "@monitoringMarkedFixed": {
    "description": "Screen 28 detail: the toast after Mark fixed."
  },
  "monitoringReopened": "Reopened",
  "@monitoringReopened": {
    "description": "Screen 28 detail: the toast after Reopen."
  },
  "monitoringStatusChangeFailed": "Couldn't change that. Nothing changed.",
  "@monitoringStatusChangeFailed": {
    "description": "Screen 28 detail: the toast when the status change failed; it offers Retry."
  },
  "monitoringDetailErrorTitle": "Couldn't load this log",
  "@monitoringDetailErrorTitle": {
    "description": "Screen 28 detail: the detail failed to load."
  },
  "monitoringDetailOfflineBody": "Nothing was lost. Try again when you're online.",
  "@monitoringDetailOfflineBody": {
    "description": "Screen 28 detail: the body of the offline detail."
  },
  "monitoringGoneTitle": "This log is gone",
  "@monitoringGoneTitle": {
    "description": "Screen 28 detail: the log no longer exists."
  },
  "monitoringGoneBody": "It may have been cleaned up.",
  "@monitoringGoneBody": {
    "description": "Screen 28 detail: the body of the gone log."
  }
```

and to `lib/l10n/app_vi.arb`:

```json
  "monitoringDetailTitle": "Nhật ký",
  "monitoringCopy": "Sao chép nhật ký",
  "monitoringCopied": "Đã sao chép",
  "monitoringSummary": "Chi tiết",
  "monitoringFieldEvent": "Sự kiện",
  "monitoringFieldLevel": "Mức",
  "monitoringFieldStatus": "Trạng thái",
  "monitoringFieldTime": "Thời gian",
  "monitoringFieldCategory": "Nhóm",
  "monitoringFieldSource": "Nguồn",
  "monitoringFieldDevice": "Thiết bị",
  "monitoringFieldApp": "Ứng dụng",
  "monitoringFieldPlatform": "Nền tảng",
  "monitoringFieldUser": "Người dùng",
  "monitoringFieldNote": "Ghi chú",
  "monitoringFixedBy": "Xử lý bởi {user} · {date}",
  "monitoringMessage": "Nội dung",
  "monitoringError": "Lỗi",
  "monitoringStackTrace": "Ngăn xếp gọi",
  "monitoringContext": "Ngữ cảnh",
  "monitoringMarkFixed": "Đánh dấu đã xử lý",
  "monitoringReopen": "Mở lại",
  "monitoringNoteLabel": "Ghi chú (không bắt buộc)",
  "monitoringNoteHint": "Bạn đã làm gì?",
  "monitoringMarkedFixed": "Đã đánh dấu đã xử lý",
  "monitoringReopened": "Đã mở lại",
  "monitoringStatusChangeFailed": "Chưa đổi được. Không có gì thay đổi.",
  "monitoringDetailErrorTitle": "Không tải được nhật ký này",
  "monitoringDetailOfflineBody": "Không mất gì cả. Thử lại khi có mạng.",
  "monitoringGoneTitle": "Nhật ký này không còn nữa",
  "monitoringGoneBody": "Có thể nó đã bị dọn."
```

Run `flutter gen-l10n`.

- [ ] **Step 4: Write the state and the controller**

```dart
import 'package:flutter/foundation.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_load_failure_state.dart';

/// What the detail page shows of its log.
sealed class MonitoringDetailContent {
  const MonitoringDetailContent();
}

final class MonitoringDetailLoading extends MonitoringDetailContent {
  const MonitoringDetailLoading();
}

final class MonitoringDetailLoaded extends MonitoringDetailContent {
  const MonitoringDetailLoaded(this.record);

  final LogRecordEntity record;
}

/// "This log is gone": cleaned up, or sent from the device since the list.
final class MonitoringDetailGone extends MonitoringDetailContent {
  const MonitoringDetailGone();
}

final class MonitoringDetailFailed extends MonitoringDetailContent {
  const MonitoringDetailFailed(this.failure);

  final MonitoringLoadFailure failure;
}

/// What the page says when a status change ends. Each is a new object, so a
/// listener sees two of the same kind in a row.
sealed class MonitoringDetailNotice {}

final class StatusChanged extends MonitoringDetailNotice {
  StatusChanged(this.status);

  final LogStatus status;
}

/// The change could not be made; [status] and [note] are what to try again.
final class StatusChangeFailed extends MonitoringDetailNotice {
  StatusChangeFailed(this.status, this.note);

  final LogStatus status;
  final String? note;
}

/// The detail page's own state: the log, the status being set (null when
/// none), and the last notice.
@immutable
final class MonitoringDetailState {
  const MonitoringDetailState({
    this.content = const MonitoringDetailLoading(),
    this.changing,
    this.notice,
  });

  final MonitoringDetailContent content;

  /// The status a change in flight sets; one change at a time.
  final LogStatus? changing;
  final MonitoringDetailNotice? notice;
}
```

```dart
import 'dart:async';

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/failures/monitoring_failure.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_list_controller.dart';
import 'package:memox/features/monitoring/presentation/providers/get_pending_log_use_case_provider.dart';
import 'package:memox/features/monitoring/presentation/providers/get_server_log_use_case_provider.dart';
import 'package:memox/features/monitoring/presentation/providers/set_log_status_use_case_provider.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_detail_state.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_load_failure_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'monitoring_detail_controller.g.dart';

/// The detail page of one log (monitoring spec §3.3): read from the server,
/// or from the device buffer when [isLocal]; and, for a warning or an error
/// of the server, marked fixed or reopened. One change at a time.
@riverpod
class MonitoringDetailController extends _$MonitoringDetailController {
  @override
  MonitoringDetailState build(String id, bool isLocal) {
    Future.microtask(_load);
    return const MonitoringDetailState();
  }

  /// After a failure: read it again.
  Future<void> retry() {
    state = const MonitoringDetailState();
    return _load();
  }

  /// Marks the log [status], with an optional [note]. The row shows the
  /// server's answer, and the list drops or updates its row; a failure
  /// leaves everything as it was and offers the same change again.
  Future<void> setStatus(LogStatus status, {String? note}) async {
    final current = state.content;
    if (current is! MonitoringDetailLoaded ||
        !current.record.canTriage ||
        state.changing != null) {
      return;
    }
    state = MonitoringDetailState(content: current, changing: status);
    try {
      final outcome = await ref.read(setLogStatusUseCaseProvider)(
        id,
        status,
        note: note,
      );
      if (!ref.mounted) return;
      switch (outcome) {
        case Ok(:final value):
          _changed(value, status);
        case Rejected(reason: MonitoringRejection.notFound):
          state = const MonitoringDetailState(content: MonitoringDetailGone());
      }
    } on Object {
      if (!ref.mounted) return;
      state = MonitoringDetailState(
        content: current,
        notice: StatusChangeFailed(status, note),
      );
    }
  }

  void _changed(LogRecordEntity record, LogStatus status) {
    state = MonitoringDetailState(
      content: MonitoringDetailLoaded(record),
      notice: StatusChanged(status),
    );
    if (ref.exists(monitoringListControllerProvider)) {
      ref
          .read(monitoringListControllerProvider.notifier)
          .statusChanged(id, status);
    }
  }

  Future<void> _load() async {
    try {
      final outcome = isLocal
          ? await ref.read(getPendingLogUseCaseProvider)(id)
          : await ref.read(getServerLogUseCaseProvider)(id);
      if (!ref.mounted) return;
      state = MonitoringDetailState(
        content: switch (outcome) {
          Ok(:final value) => MonitoringDetailLoaded(value),
          Rejected() => const MonitoringDetailGone(),
        },
      );
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = MonitoringDetailState(
        content: MonitoringDetailFailed(MonitoringLoadFailure.of(error)),
      );
    }
  }
}
```

- [ ] **Step 5: Write the page, the sheet and the screen**

The stack trace and the error are shown with `SelectableText`, on purpose: a log is the one place the app shows an error's own words (ADR-018 §1), and `memox.error_handling.no_technical_detail_in_user_message` is about `Text(error…)`. The context's JSON is written once per log id.

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// Opens the triage sheet for changing a log to [target] and returns the
/// note typed (empty for none) once confirmed, or null when it is dismissed.
Future<String?> showMonitoringStatusSheet(
  BuildContext context, {
  required LogStatus target,
}) => showMxBottomSheet<String>(
  context,
  builder: (_) => MonitoringStatusSheetWidget(target: target),
);

/// Mark fixed or Reopen, with an optional note (monitoring spec §3.3).
class MonitoringStatusSheetWidget extends StatefulWidget {
  const MonitoringStatusSheetWidget({super.key, required this.target});

  final LogStatus target;

  @override
  State<MonitoringStatusSheetWidget> createState() =>
      _MonitoringStatusSheetWidgetState();
}

class _MonitoringStatusSheetWidgetState
    extends State<MonitoringStatusSheetWidget> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = switch (widget.target) {
      LogStatus.fixed => l10n.monitoringMarkFixed,
      LogStatus.open => l10n.monitoringReopen,
    };
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Text(title, style: context.textStyles.compactTitle),
      ),
      footer: MxSheetActions(
        isInSheet: true,
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(),
        confirmLabel: title,
        onConfirm: () => Navigator.of(context).pop(_note.text.trim()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: MxTextField(
          controller: _note,
          label: l10n.monitoringNoteLabel,
          hintText: l10n.monitoringNoteHint,
        ),
      ),
    );
  }
}
```

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/widgets/support/monitoring_labels_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// The detail's key/value rows (monitoring spec §3.3). A row whose value the
/// log does not have is left out: a buffered log has no user, an info has no
/// status.
class MonitoringDetailSummaryWidget extends StatelessWidget {
  const MonitoringDetailSummaryWidget({super.key, required this.record});

  final LogRecordEntity record;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <(String, String?)>[
      (l10n.monitoringFieldEvent, record.event),
      (l10n.monitoringFieldLevel, monitoringLevelLabel(l10n, record.level)),
      (l10n.monitoringFieldStatus, _status(l10n)),
      (l10n.monitoringFieldNote, _nonBlank(record.statusNote)),
      (l10n.monitoringFieldTime, monitoringFullTime(l10n, record.occurredAt)),
      (l10n.monitoringFieldCategory, record.category),
      (l10n.monitoringFieldSource, record.source),
      (l10n.monitoringFieldDevice, record.deviceId),
      (l10n.monitoringFieldApp, _app),
      (l10n.monitoringFieldPlatform, _platform),
      (l10n.monitoringFieldUser, record.userId),
    ];
    return MxSection(
      title: l10n.monitoringSummary,
      children: [
        for (final (label, value) in rows)
          if (value != null) MxSettingsRow(label: label, subtitle: value),
      ],
    );
  }

  /// "Open", or "Fixed by {user} · {date}" once someone marked it.
  String? _status(AppLocalizations l10n) {
    final status = record.status;
    if (status == null) return null;
    final by = record.statusChangedBy;
    final at = record.statusChangedAt;
    if (status == LogStatus.fixed && by != null && at != null) {
      return l10n.monitoringFixedBy(by, monitoringFullTime(l10n, at));
    }
    return monitoringStatusLabel(l10n, status);
  }

  String? get _app {
    final version = _nonBlank(record.appVersion);
    if (version == null) return null;
    final build = _nonBlank(record.buildNumber);
    return build == null ? version : '$version ($build)';
  }

  String? get _platform {
    final parts = [?_nonBlank(record.platform), ?_nonBlank(record.osVersion)];
    return parts.isEmpty ? null : parts.join(' ');
  }

  static String? _nonBlank(String? text) =>
      text == null || text.trim().isEmpty ? null : text;
}
```

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';

/// One block of text under a title: the message, the error, a stack trace, or
/// the context as JSON. The text is selectable, and long lines wrap. [isCode]
/// sets it in the monospace [MxTextStyles.code]. It is a `SelectableText`, not
/// a `Text`: a log is the one place the app shows an error's own words, on
/// purpose (ADR-018 §1; BR-CORE-005 is about what a user sees).
class MonitoringCodeCardWidget extends StatelessWidget {
  const MonitoringCodeCardWidget({
    super.key,
    required this.title,
    required this.text,
    this.isCode = true,
  });

  final String title;
  final String text;
  final bool isCode;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxListSectionHeader(label: title),
        MxCard(
          child: SelectableText(
            text,
            style: isCode ? styles.code : styles.dialogBody,
          ),
        ),
      ],
    );
  }
}
```

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_code_card_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_detail_summary_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// The detail's page (monitoring spec §3.3): the summary, then the message,
/// the error, the stack trace and the context, each only when the log has
/// it. The context's JSON is written once per log: it can be 256 kB.
class MonitoringDetailBodyWidget extends StatefulWidget {
  const MonitoringDetailBodyWidget({super.key, required this.record});

  final LogRecordEntity record;

  @override
  State<MonitoringDetailBodyWidget> createState() =>
      _MonitoringDetailBodyWidgetState();
}

class _MonitoringDetailBodyWidgetState
    extends State<MonitoringDetailBodyWidget> {
  static const _json = JsonEncoder.withIndent('  ');

  late String _context = _contextText(widget.record);

  @override
  void didUpdateWidget(MonitoringDetailBodyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.id != widget.record.id) {
      _context = _contextText(widget.record);
    }
  }

  static String _contextText(LogRecordEntity record) =>
      record.context.isEmpty ? '' : _json.convert(record.context);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final record = widget.record;
    final message = record.message?.trim() ?? '';
    final error = [
      ?record.errorType,
      ?record.errorMessage,
    ].where((part) => part.trim().isNotEmpty).join('\n');
    final trace = record.stackTrace?.trim() ?? '';
    return MxScreenScroll(
      children: [
        const SizedBox(height: AppSpacing.control),
        MonitoringDetailSummaryWidget(record: record),
        for (final (title, text, isCode) in [
          (l10n.monitoringMessage, message, false),
          (l10n.monitoringError, error, false),
          (l10n.monitoringStackTrace, trace, true),
          (l10n.monitoringContext, _context, true),
        ])
          if (text.isNotEmpty) ...[
            MonitoringCodeCardWidget(title: title, text: text, isCode: isCode),
            const SizedBox(height: AppSpacing.gutter),
          ],
      ],
    );
  }
}
```

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_detail_controller.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_detail_state.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_load_failure_state.dart';
import 'package:memox/features/monitoring/presentation/widgets/overlays/monitoring_status_sheet_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_detail_body_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 28's detail (monitoring spec §3.3): one log whole, and, for a
/// warning or an error of the server, Mark fixed or Reopen. [isLocal] reads
/// the device buffer instead of the server. Not in the kit; shaped with
/// Impeccable 2026-09-29.
class MonitoringDetailScreen extends ConsumerWidget {
  const MonitoringDetailScreen({
    super.key,
    required this.logId,
    required this.isLocal,
  });

  final String logId;
  final bool isLocal;

  static const int _skeletonRows = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = monitoringDetailControllerProvider(logId, isLocal);
    ref.listen(
      provider.select((state) => state.notice),
      (_, notice) => _say(context, ref, notice),
    );
    final state = ref.watch(provider);
    final content = state.content;
    final record = content is MonitoringDetailLoaded ? content.record : null;
    return MxAppShell(
      appBar: MxAppBar(
        title: record?.event ?? l10n.monitoringDetailTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
        actions: [
          if (record != null)
            MxIconButton(
              icon: AppIcons.copy,
              semanticLabel: l10n.monitoringCopy,
              onPressed: () => unawaited(_copy(context, record)),
            ),
        ],
      ),
      body: switch (content) {
        MonitoringDetailLoading() => MxScreenScroll(
          children: [
            MxSkeletonList(
              semanticLabel: l10n.commonLoading,
              rows: _skeletonRows,
            ),
          ],
        ),
        MonitoringDetailLoaded(:final record) => MonitoringDetailBodyWidget(
          record: record,
        ),
        MonitoringDetailGone() => MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.monitoringGoneTitle,
              body: l10n.monitoringGoneBody,
              icon: AppIcons.searchOff,
            ),
          ],
        ),
        MonitoringDetailFailed(:final failure) => MxScreenScroll(
          children: [_failure(context, ref, failure)],
        ),
      },
      footer: record != null && record.canTriage
          ? _triage(context, ref, record, state)
          : null,
    );
  }

  Widget _failure(
    BuildContext context,
    WidgetRef ref,
    MonitoringLoadFailure failure,
  ) {
    final l10n = context.l10n;
    void retry() => unawaited(
      ref
          .read(monitoringDetailControllerProvider(logId, isLocal).notifier)
          .retry(),
    );
    return switch (failure) {
      MonitoringLoadFailure.notAdmin => MxEmptyState(
        icon: AppIcons.lock,
        title: l10n.monitoringNotAdminTitle,
        tone: MxEmptyStateTone.neutral,
        isCompact: true,
      ),
      MonitoringLoadFailure.offline => MxErrorState(
        title: l10n.monitoringOfflineTitle,
        body: l10n.monitoringDetailOfflineBody,
        retryLabel: l10n.commonRetry,
        onRetry: retry,
      ),
      MonitoringLoadFailure.other => MxErrorState(
        title: l10n.monitoringDetailErrorTitle,
        body: l10n.libraryLoadErrorBody,
        retryLabel: l10n.commonRetry,
        onRetry: retry,
      ),
    };
  }

  Widget _triage(
    BuildContext context,
    WidgetRef ref,
    LogRecordEntity record,
    MonitoringDetailState state,
  ) {
    final l10n = context.l10n;
    final target = record.status == LogStatus.fixed
        ? LogStatus.open
        : LogStatus.fixed;
    return MxFooterBar(
      child: MxButton(
        label: target == LogStatus.fixed
            ? l10n.monitoringMarkFixed
            : l10n.monitoringReopen,
        isBlock: true,
        isLoading: state.changing != null,
        onPressed: state.changing == null
            ? () => unawaited(_change(context, ref, target))
            : null,
      ),
    );
  }

  Future<void> _change(
    BuildContext context,
    WidgetRef ref,
    LogStatus target,
  ) async {
    final controller = ref.read(
      monitoringDetailControllerProvider(logId, isLocal).notifier,
    );
    final note = await showMonitoringStatusSheet(context, target: target);
    if (note == null) return;
    await controller.setStatus(target, note: note);
  }

  Future<void> _copy(BuildContext context, LogRecordEntity record) async {
    final l10n = context.l10n;
    final text = const JsonEncoder.withIndent('  ').convert(record.toJson());
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    showMxSnackbar(context, message: l10n.monitoringCopied);
  }

  void _say(
    BuildContext context,
    WidgetRef ref,
    MonitoringDetailNotice? notice,
  ) {
    final l10n = context.l10n;
    switch (notice) {
      case null:
        return;
      case StatusChanged(:final status):
        showMxSnackbar(
          context,
          message: status == LogStatus.fixed
              ? l10n.monitoringMarkedFixed
              : l10n.monitoringReopened,
        );
      case StatusChangeFailed(:final status, :final note):
        showMxSnackbar(
          context,
          message: l10n.monitoringStatusChangeFailed,
          actionLabel: l10n.commonRetry,
          onAction: () => unawaited(
            ref
                .read(
                  monitoringDetailControllerProvider(logId, isLocal).notifier,
                )
                .setStatus(status, note: note),
          ),
        );
    }
  }
}
```

- [ ] **Step 6: Generate and run**

Run: `dart run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/features/monitoring test/visual_audit test/app/l10n_test.dart`
Expected: PASS (`All tests passed!`).

- [ ] **Step 7: Commit**

```bash
git add lib/features/monitoring lib/l10n test/features/monitoring test/visual_audit/screens/features/monitoring
git commit -m "feat(monitoring): the log detail page and its triage"
```

---

### Task 11: Routes and the Settings wiring

**Files:**
- Modify: `lib/app/router/app_routes.dart`, `lib/app/router/app_router.dart`
- Test: `test/app/monitoring_routes_test.dart`

**Interfaces:**
- Consumes: `MonitoringScreen`, `MonitoringDetailScreen`, `MonitoringEntrySectionWidget`, `SettingsScreen.adminSection`.
- Produces: `AppRoutes.settingsMonitoringChild` (`monitoring`), `AppRoutes.settingsMonitoring` (`/settings/monitoring`), `AppRoutes.monitoringLogChild` (`:logId`), `AppRoutes.settingsMonitoringLog(id, {isLocal})` (`…/{id}` or `…/{id}?local=1`), `AppRoutes.isLocalLog(query)`; both screens on the root navigator like Sync, the detail nested under the list so Back climbs one page at a time.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/monitoring/di/is_admin_provider.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_detail_screen.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_screen.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

import '../support/library_harness.dart';
import '../support/monitoring_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Finder _tab(String label) =>
    find.descendant(of: find.byType(MxBottomNav), matching: find.text(label));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// The routes of Monitoring (screen 28): an admin's pages on the root
/// navigator, under Settings.
void main() {
  test('a log\'s path names it, and the buffer is a query', () {
    expect(AppRoutes.settingsMonitoringLog('abc'), '/settings/monitoring/abc');
    expect(
      AppRoutes.settingsMonitoringLog('abc', isLocal: true),
      '/settings/monitoring/abc?local=1',
    );
    expect(AppRoutes.isLocalLog({'local': '1'}), isTrue);
    expect(AppRoutes.isLocalLog({}), isFalse);
    expect(AppRoutes.isLocalLog({'local': '0'}), isFalse);
  });

  libraryTest('Settings opens Monitoring above the shell, a row opens its '
      'detail, and Back climbs one page at a time', (tester, env) async {
    final repository = FakeMonitoringRepository()
      ..autoPage = LogPage(items: [summary('a', event: 'sync.push_failed')])
      ..servers['a'] = record('a');
    await pumpMemoxApp(
      tester,
      env,
      overrides: [
        isAdminProvider.overrideWithValue(true),
        monitoringRepositoryProvider.overrideWithValue(repository),
      ],
    );
    await tester.tap(_tab(_en.navSettings));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(_en.settingsMonitoring), 200);
    // Clear of the bottom bar, which the row was scrolled under.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.settingsMonitoring));
    await _settle(tester);

    expect(find.byType(MonitoringScreen), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);

    await tester.tap(find.text('sync.push_failed'));
    await _settle(tester);
    expect(find.byType(MonitoringDetailScreen), findsOneWidget);

    await tester.tap(find.byTooltip(_en.commonBack));
    await _settle(tester);
    expect(find.byType(MonitoringScreen), findsOneWidget);
    expect(find.text('sync.push_failed'), findsOneWidget);
    expect(repository.queries, hasLength(1), reason: 'the pages are kept');

    await tester.tap(find.byTooltip(_en.commonBack));
    await _settle(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(MxBottomNav), findsOneWidget);
  });

  libraryTest('a deep link to a log opens its detail, and Back lands on '
      'Monitoring', (tester, env) async {
    final repository = FakeMonitoringRepository()
      ..autoPage = pageOf(1)
      ..pendings['a'] = record('a', status: null, event: 'sync.failed');
    await pumpMemoxApp(
      tester,
      env,
      overrides: [
        isAdminProvider.overrideWithValue(true),
        monitoringRepositoryProvider.overrideWithValue(repository),
      ],
    );

    GoRouter.of(tester.element(find.byType(MxBottomNav)))
        .go(AppRoutes.settingsMonitoringLog('a', isLocal: true));
    await _settle(tester);

    final detail = tester.widget<MonitoringDetailScreen>(
      find.byType(MonitoringDetailScreen),
    );
    expect((detail.logId, detail.isLocal), ('a', true));

    await tester.tap(find.byTooltip(_en.commonBack));
    await _settle(tester);
    expect(find.byType(MonitoringScreen), findsOneWidget);
  });

  libraryTest('a deep link from an account the server refuses says only an '
      'admin can see this', (tester, env) async {
    final repository = FakeMonitoringRepository();
    await pumpMemoxApp(
      tester,
      env,
      overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
    );

    GoRouter.of(tester.element(find.byType(MxBottomNav)))
        .go(AppRoutes.settingsMonitoring);
    await _settle(tester);
    repository.lastQuery.fail(const NotAdminFailure(cause: 'x'));
    await _settle(tester);

    expect(find.text(_en.monitoringNotAdminTitle), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run it to see it fail**

Run: `flutter test test/app/monitoring_routes_test.dart`
Expected: FAIL to compile: `Member not found: 'settingsMonitoringLog'`.

- [ ] **Step 3: Add the routes and wire the entry**

```diff
--- a/lib/app/router/app_routes.dart
+++ b/lib/app/router/app_routes.dart
@@ -31,6 +31,31 @@
   /// navigator like Theme and Language.
   static const String settingsSyncChild = 'sync';
   static const String settingsSync = '$settings/$settingsSyncChild';
+
+  /// Monitoring (screen 28, ADR-018 §8), relative to [settings]: an admin's
+  /// page on the root navigator like Sync, and one log's detail under it.
+  static const String settingsMonitoringChild = 'monitoring';
+  static const String settingsMonitoring = '$settings/$settingsMonitoringChild';
+
+  /// The path parameter that names a log, and the query parameter that says
+  /// it is read from the device buffer (`?local=1`).
+  static const String monitoringLogIdParam = 'logId';
+  static const String monitoringLocalParam = 'local';
+  static const String monitoringLogChild = ':$monitoringLogIdParam';
+  static const String _monitoringLocalOn = '1';
+
+  /// One log's detail, from the server or, when [isLocal], the buffer.
+  static String settingsMonitoringLog(String logId, {bool isLocal = false}) =>
+      Uri(
+        path: '$settingsMonitoring/$logId',
+        queryParameters: isLocal
+            ? {monitoringLocalParam: _monitoringLocalOn}
+            : null,
+      ).toString();
+
+  /// Whether [query] asks for the device buffer.
+  static bool isLocalLog(Map<String, String> query) =>
+      query[monitoringLocalParam] == _monitoringLocalOn;
 
   /// Debug builds only: the component gallery.
   static const String gallery = '/gallery';
```

```diff
--- a/lib/app/router/app_router.dart
+++ b/lib/app/router/app_router.dart
@@ -10,6 +10,9 @@
 import 'package:memox/app/router/log_navigator_observer.dart';
 import 'package:memox/app/router/route_not_found_screen.dart';
 import 'package:memox/core/error/failure.dart';
+import 'package:memox/features/monitoring/presentation/screens/monitoring_detail_screen.dart';
+import 'package:memox/features/monitoring/presentation/screens/monitoring_screen.dart';
+import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_entry_section_widget.dart';
 import 'package:memox/features/reminders/presentation/providers/reconcile_reminder_provider.dart';
 import 'package:memox/features/reminders/presentation/screens/reminder_screen.dart';
 import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
@@ -246,6 +249,9 @@
                   // The reset turned the reminder off; the pending alarm
                   // follows through the gate (FE-B5 spec D7).
                   onOpenSync: () => context.push(AppRoutes.settingsSync),
+                  adminSection: MonitoringEntrySectionWidget(
+                    onOpen: () => context.push(AppRoutes.settingsMonitoring),
+                  ),
                   onAppOptionsReset: () => unawaited(
                     _reconcileAfterReset(ProviderScope.containerOf(context)),
                   ),
@@ -273,6 +279,33 @@
                     path: AppRoutes.settingsSyncChild,
                     parentNavigatorKey: rootNavigator,
                     builder: (context, state) => const SyncScreen(),
+                  ),
+                  GoRoute(
+                    path: AppRoutes.settingsMonitoringChild,
+                    parentNavigatorKey: rootNavigator,
+                    builder: (context, state) => MonitoringScreen(
+                      onOpenServerLog: (id) => unawaited(
+                        context.push(AppRoutes.settingsMonitoringLog(id)),
+                      ),
+                      onOpenPendingLog: (id) => unawaited(
+                        context.push(
+                          AppRoutes.settingsMonitoringLog(id, isLocal: true),
+                        ),
+                      ),
+                    ),
+                    routes: [
+                      GoRoute(
+                        path: AppRoutes.monitoringLogChild,
+                        parentNavigatorKey: rootNavigator,
+                        builder: (context, state) => MonitoringDetailScreen(
+                          logId: state
+                              .pathParameters[AppRoutes.monitoringLogIdParam]!,
+                          isLocal: AppRoutes.isLocalLog(
+                            state.uri.queryParameters,
+                          ),
+                        ),
+                      ),
+                    ],
                   ),
                 ],
               ),
```

- [ ] **Step 4: Run the app tests**

Run: `flutter test test/app test/features/settings test/features/monitoring`
Expected: PASS (`All tests passed!`).

- [ ] **Step 5: Commit**

```bash
git add lib/app/router test/app/monitoring_routes_test.dart
git commit -m "feat(monitoring): routes under Settings, on the root navigator"
```

---

### Task 12: Goldens

**Files:**
- Test: `test/features/monitoring/presentation/monitoring_screen_golden_test.dart`, `test/features/monitoring/presentation/monitoring_detail_golden_test.dart`
- Create (generated): `test/features/monitoring/presentation/goldens/*.png`

**Interfaces:**
- Consumes: `pumpLibraryGolden`, `withRealShadows`, `expectBoundaryGolden`, the fakes; the monospace face of Task 1 (so the stack trace is text, not Ahem boxes).
- Produces: 20 goldens, light and dark: `monitoring_{list_loaded,list_all_levels,list_empty,list_offline,not_sent,level_sheet}_*.png` and `monitoring_detail_{open,open_trace,fixed,local}_*.png`.

- [ ] **Step 1: Write the golden tests**

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/entities/log_summary_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_list_controller.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_screen.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/monitoring_fakes.dart';

final _screen = MonitoringScreen(
  onOpenServerLog: (_) {},
  onOpenPendingLog: (_) {},
);

/// Open warnings and errors over today and the day before: what the
/// default filter returns.
LogPage _openPage() => LogPage(
  items: [
    summary(
      'a',
      event: 'sync.push_failed',
      message: 'The server refused the push\nsecond line',
      at: libraryToday.subtract(const Duration(minutes: 12)),
    ),
    summary(
      'b',
      level: LogLevel.warning,
      event: 'db.slow_query',
      message: 'SELECT * FROM card WHERE deck_id = ? ORDER BY created_at',
      at: libraryToday.subtract(const Duration(hours: 3)),
    ),
    summary(
      'c',
      event: 'ui.uncaught',
      message: null,
      errorType: 'StateError',
      at: DateTime(2026, 9, 23, 18, 40),
    ),
  ],
);

/// Every level and both statuses: what the filter returns once widened.
LogPage _allPage() => LogPage(
  items: [
    ..._openPage().items,
    summary(
      'd',
      event: 'sync.rejected',
      message: 'deck 3f2a refused: CONFLICT',
      status: LogStatus.fixed,
      at: DateTime(2026, 9, 22, 21, 15),
    ),
    summary(
      'e',
      level: LogLevel.info,
      status: null,
      event: 'sync.pull',
      message: '12 changes in 340 ms',
      at: DateTime(2026, 9, 22, 8, 5),
    ),
    summary(
      'f',
      level: LogLevel.debug,
      status: null,
      event: 'db.query',
      message: 'SELECT 1',
      at: DateTime(2026, 9, 20, 22, 5),
    ),
  ],
);

/// What the device has not sent yet: no row has a status.
List<LogSummaryEntity> _pending() => [
  summary(
    'p1',
    event: 'sync.failed',
    message: 'No connection',
    status: null,
    at: libraryToday.subtract(const Duration(minutes: 2)),
  ),
  summary(
    'p2',
    level: LogLevel.warning,
    event: 'db.slow_query',
    message: 'SELECT * FROM card WHERE deck_id = ?',
    status: null,
    at: libraryToday.subtract(const Duration(minutes: 40)),
  ),
  summary(
    'p3',
    level: LogLevel.info,
    event: 'lifecycle.resume',
    message: '8.0.0',
    status: null,
    at: libraryToday.subtract(const Duration(hours: 2)),
  ),
];

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> golden(
      WidgetTester tester,
      LibraryEnv env,
      String state,
      FakeMonitoringRepository repository, {
      Future<void> Function()? act,
    }) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen,
          brightness,
          overrides: [
            monitoringRepositoryProvider.overrideWithValue(repository),
          ],
        );
        await act?.call();
        await expectBoundaryGolden(
          tester,
          'goldens/monitoring_${state}_$theme.png',
        );
      });
    }

    libraryTest('monitoring, list loaded, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'list_loaded',
        FakeMonitoringRepository()..autoPage = _openPage(),
      );
    });

    libraryTest('monitoring, list all levels, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'list_all_levels',
        FakeMonitoringRepository()..autoPage = _allPage(),
        act: () async {
          ProviderScope.containerOf(
                tester.element(find.byType(MonitoringScreen)),
              )
              .read(monitoringListControllerProvider.notifier)
              .setFilter(const LogFilter().withLevels({}).withStatuses({}));
          await _settle(tester);
        },
      );
    });

    libraryTest('monitoring, list empty, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'list_empty',
        FakeMonitoringRepository()..autoPage = pageOf(0),
      );
    });

    libraryTest('monitoring, list offline, $theme', (tester, env) async {
      final repository = FakeMonitoringRepository();
      await golden(
        tester,
        env,
        'list_offline',
        repository,
        act: () async {
          repository.lastQuery.fail(const OfflineFailure(cause: 'x'));
          await _settle(tester);
        },
      );
    });

    libraryTest('monitoring, not sent, $theme', (tester, env) async {
      final repository = FakeMonitoringRepository()..autoPage = _openPage();
      await golden(
        tester,
        env,
        'not_sent',
        repository,
        act: () async {
          repository.watches.single.feed.add(
            PendingLogs(items: _pending(), total: 27),
          );
          await _settle(tester);
          await tester.tap(find.textContaining('Not sent ('));
          await _settle(tester);
        },
      );
    });

    libraryTest('monitoring, level sheet, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'level_sheet',
        FakeMonitoringRepository()..autoPage = _openPage(),
        act: () async {
          await tester.tap(
            find.descendant(
              of: find.byType(MxChipTrigger),
              matching: find.textContaining('Level'),
            ),
          );
          await _settle(tester);
        },
      );
    });
  }
}
```

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_detail_screen.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/monitoring_fakes.dart';

const _trace = '''
#0      SyncCoordinator.runOnce (package:memox/core/sync/sync_coordinator.dart:42:7)
<asynchronous suspension>
#1      SyncScheduler._run (package:memox/core/sync/sync_scheduler.dart:88:11)
<asynchronous suspension>
#2      SyncScheduler.start.<anonymous closure> (package:memox/core/sync/sync_scheduler.dart:61:5)''';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> golden(
      WidgetTester tester,
      LibraryEnv env,
      String state,
      FakeMonitoringRepository repository, {
      bool isLocal = false,
      bool isScrolled = false,
    }) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          MonitoringDetailScreen(logId: 'a', isLocal: isLocal),
          brightness,
          overrides: [
            monitoringRepositoryProvider.overrideWithValue(repository),
          ],
        );
        await _settle(tester);
        if (isScrolled) {
          await tester.fling(
            find.byType(ListView),
            const Offset(0, -3000),
            6000,
          );
          await _settle(tester);
        }
        await expectBoundaryGolden(
          tester,
          'goldens/monitoring_detail_${state}_$theme.png',
        );
      });
    }

    libraryTest('monitoring detail, open error, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'open',
        FakeMonitoringRepository()
          ..servers['a'] = record('a', stackTrace: _trace),
      );
    });

    libraryTest('monitoring detail, open error, trace, $theme', (
      tester,
      env,
    ) async {
      await golden(
        tester,
        env,
        'open_trace',
        FakeMonitoringRepository()
          ..servers['a'] = record('a', stackTrace: _trace),
        isScrolled: true,
      );
    });

    libraryTest('monitoring detail, fixed error with note, $theme', (
      tester,
      env,
    ) async {
      await golden(
        tester,
        env,
        'fixed',
        FakeMonitoringRepository()
          ..servers['a'] = record(
            'a',
            stackTrace: _trace,
            status: LogStatus.fixed,
            statusNote: 'Added an index on card.deck_id',
            statusChangedBy: '00000000-0000-0000-0000-0000000000ad',
            statusChangedAt: DateTime.utc(2026, 9, 27, 9, 30, 5),
          ),
      );
    });

    libraryTest('monitoring detail, local row, $theme', (tester, env) async {
      await golden(
        tester,
        env,
        'local',
        FakeMonitoringRepository()
          ..pendings['a'] = record('a', status: null, stackTrace: _trace),
        isLocal: true,
      );
    });
  }
}
```

- [ ] **Step 2: Run them to see them fail**

Run: `TZ=UTC flutter test --tags golden test/features/monitoring`
Expected: FAIL: `Could not be compared against non-existent file: "goldens/monitoring_list_loaded_light.png"` (and the rest).

- [ ] **Step 3: Generate them in the Linux container**

Run: `TZ=UTC flutter test --tags golden --update-goldens test/features/monitoring`
Expected: `All tests passed!` and 20 files in `test/features/monitoring/presentation/goldens/`.
Run: `TZ=UTC flutter test --tags golden test/features/monitoring`
Expected: PASS without `--update-goldens` (the pictures are stable).

- [ ] **Step 4: Look at every picture**

Open each PNG. Check: the stack trace and JSON are readable monospace text; the four levels have four glyphs; open is amber and fixed is green with the word; the chips scroll off the right edge; the sheet's Reset and Apply sit under the toggles; dark has no light patches. Fix code, not the picture, and regenerate.

- [ ] **Step 5: Commit**

```bash
git add test/features/monitoring/presentation
git commit -m "test(monitoring): goldens of the list, Not sent, a filter sheet and the detail"
```

---

### Task 13: Documents

**Files:**
- Create: `docs/shared/ui/screen-handoff/28-monitoring.md`
- Modify: `docs/shared/ui/screen-handoff/00-index.md`, `docs/shared/ui/screen-handoff/23-settings.md`, `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (§9), `docs/wbs_FE.md`
- Regenerate: `docs/_generated/`

- [ ] **Step 1: Write the screen handoff, in the format of `27-sync.md`**

`docs/shared/ui/screen-handoff/28-monitoring.md` (English, like its neighbours; the images are the goldens):

```markdown
<!-- Hand-written screen handoff. Not generated by tools/docs/split_handoff.py. -->

# 28 · Monitoring

The admin's window on the app's logs: the server's, and the device's own buffer. It opens
on the open warnings and errors, newest first, and lets the admin filter and search them,
open one whole, and mark it fixed or reopen it. Not in the kit: UI Kit v3 predates the
server and has no admin tooling; the screen was shaped with Impeccable on 2026-09-29.
FE-B8; ADR-018 §6 to §8; spec
[2026-09-29-monitoring-screen-design.md](../../../superpowers/specs/2026-09-29-monitoring-screen-design.md)
§3; plan
[2026-09-29-monitoring-screen.md](../../../superpowers/plans/2026-09-29-monitoring-screen.md).

## Entry points

- Screen 23, Admin section, row "Monitoring". Route `/settings/monitoring`, on the root
  navigator like Sync; Back returns to 23.
- A row opens its detail at `/settings/monitoring/:id` (`?local=1` for a row of the device
  buffer), nested under the list, so Back climbs one page at a time and the list keeps its
  pages and scroll position.
- The row exists only while the session's account has `app_metadata.role = admin`, and not
  at all in a build with no Supabase. A deep link from another account gets "Only an admin
  can see this", the server's `FORBIDDEN`.

## Layout: the list

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content density) + back `MxIconButton` | "Monitoring". |
| Tabs | `MxSegmentedTray` | "Server" · "Not sent ({n})"; n is every row of the device buffer. |
| Search (Server) | `MxSearchField` | "Search event or message"; asks 400 ms after the last keystroke. |
| Filters (Server) | `MxChipTrigger` × 5 in a row that scrolls | Level (default warning + error) · Status (default open) · Category · Time · Device / user. A chip that holds a choice shows it: "Level · 2", "Status · Open", "Time · Last 24 hours". |
| Count | `MxListSectionHeader` | "{n} open" for the default filter, "{n} logs" otherwise; "{n}+" while more pages exist. |
| Rows | `MxListRow` | Leading `MxIconTile` with a glyph per level (debug bug, info circle, warning triangle, error circle) on the tint of its level; title `event`; subtitle the first line of the message, or else of the error message, or else the error type; trailing `HH:mm` today or "Sep 26", and under it an `MxBadge` "Open" / "Fixed" for warnings and errors. TalkBack: "{level}, {event}, {time}, {status}". |
| End | `MxSpinner` / `MxInlineBanner` / caption | The next 100 rows load when the last 10 come into view; a spinner while they do; "Couldn't load more logs." with Retry; "No more logs". |
| Not sent | `MxNote` + one `MxChipTrigger` (Level, default warning + error) + rows | "{n} logs wait on this device. They are sent when MemoX is online." The rows are the device buffer, watched, without a status. |
| Filter sheets | `MxBottomSheet` | Level, Status and Category: a toggle per value (`MxSettingsRow` + `MxToggle`). Time: an `MxOptionRow` per window (last hour, 24 hours, 7 days, 30 days, all time). Device / user: two `MxTextField`s and an `MxNote`. Each has Reset (outline) and Apply. |

Choosing Debug or Info clears the status filter: those rows have no status and it would
hide them. Category rows show the stored code (`db`, `sync`, `network`) and come from
`LogCategory.values`. A pull down on the Server tab, and any filter or search change,
reload from the first page.

## Layout: the detail

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` + back, action `MxIconButton` | Title: the event. The action copies the whole log as JSON; `MxSnackbar` "Copied". |
| Summary | `MxSection` + `MxSettingsRow`s | Event, Level, Status ("Open", or "Fixed by {user} · {date}"), Note, Time (full date and `HH:mm:ss`, local), Category, Source, Device, App ("8.0.0 (12)"), Platform, User. A row the log does not have is left out. |
| Message, Error | `MxListSectionHeader` + `MxCard` | Selectable text. Error: the type, then its message. |
| Stack trace, Context | `MxListSectionHeader` + `MxCard`, `code` style | Selectable, long lines wrap; the context is pretty-printed JSON. Hidden when empty. A context can be 256 kB. |
| Triage | `MxFooterBar` + `MxButton` (primary, block) | "Mark fixed", or "Reopen" for a fixed one; for a warning or error of the server only. It opens an `MxBottomSheet` with an optional note (`MxTextField`) and the confirm. |
| Toasts | `MxSnackbar` | "Marked fixed"; "Reopened"; "Couldn't change that. Nothing changed." · Retry. |

## States

Every state is a V8 addition; the images are the goldens.

| State | Light | Dark | V8 |
|---|---|---|---|
| list, loaded | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_list_loaded_light.png) | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_list_loaded_dark.png) | Golden `monitoring_list_loaded_*`: open warnings and errors. |
| list, every level | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_list_all_levels_light.png) | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_list_all_levels_dark.png) | Golden `monitoring_list_all_levels_*`: the filter widened; four glyphs, both statuses. |
| list, empty | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_list_empty_light.png) | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_list_empty_dark.png) | Golden `monitoring_list_empty_*`. |
| list, offline | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_list_offline_light.png) | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_list_offline_dark.png) | Golden `monitoring_list_offline_*`. |
| Not sent | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_not_sent_light.png) | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_not_sent_dark.png) | Golden `monitoring_not_sent_*`. |
| Level sheet | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_level_sheet_light.png) | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_level_sheet_dark.png) | Golden `monitoring_level_sheet_*`. |
| detail, open error | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_detail_open_light.png) | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_detail_open_dark.png) | Golden `monitoring_detail_open_*`. |
| detail, its trace and context | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_detail_open_trace_light.png) | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_detail_open_trace_dark.png) | Golden `monitoring_detail_open_trace_*`: the `code` style. |
| detail, fixed with a note | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_detail_fixed_light.png) | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_detail_fixed_dark.png) | Golden `monitoring_detail_fixed_*`: "Fixed by {user} · {date}", the note, Reopen. |
| detail, a row of the buffer | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_detail_local_light.png) | ![](../../../../test/features/monitoring/presentation/goldens/monitoring_detail_local_dark.png) | Golden `monitoring_detail_local_*`: no triage, no user. |
| list, loading | — | — | `MxSkeletonList`, six rows. |
| list, no match | — | — | `MxEmptyState` "Nothing matches" with Clear filters. |
| list, error | — | — | `MxErrorState` "Couldn't load logs" with the local-first body and Retry. |
| list, not an admin | — | — | `MxEmptyState` "Only an admin can see this" (the server's `FORBIDDEN`). |
| detail, loading / error / offline / gone | — | — | Skeleton; `MxErrorState` with Retry; offline with Retry; "This log is gone" / "It may have been cleaned up." |

Goldens: `test/features/monitoring/presentation/goldens/monitoring_{list_loaded,list_all_levels,list_empty,list_offline,not_sent,level_sheet}_{light,dark}.png` and `monitoring_detail_{open,open_trace,fixed,local}_{light,dark}.png`.

## Deviations

| Artifact | V8 | Wins |
|---|---|---|
| No such screen; the kit has no admin tooling | Screen 28, from the kit's widgets | ADR-018 §8; owner rulings of the Impeccable shape 2026-09-29 |
| `MxStatusBadge` for open and fixed | `MxBadge`: open in the warning tone, fixed in the mastery tone, each with its word | `MxStatusBadge` names a card lifecycle (plan ruling 1); UI-base row 147 |
| `MxOptionRow`s with several choices | Toggles for Level, Status and Category; `MxOptionRow` only for the one-choice Time | `MxOptionRow` is a radio and announces one of a group (plan ruling 2) |
| Category by name | The stored code, from `LogCategory.values` | Plan ruling 3 |
| A device / user choice | A sheet of two text fields, a device id and a user id | Plan ruling 4 |
| The offline state's one action, Not sent | Retry above it | Plan ruling 12 |
| A card around the rows | Rows directly in the page's scroll | Plan ruling 13 |
| No monospace in the type scale | `MxTextStyles.code`: the system monospace, `bodySmall` size, tabular figures | Owner 2026-09-29; UI-base row 147 |
| Times of the sync screens ("Today, 14:32") | `HH:mm` today, "Sep 26" before, on a row; the full date and `HH:mm:ss` in the detail | Spec §3.2, §3.5 (24-hour in every language, ADR-008 local time) |

## Copy

- App bar and tabs: "Monitoring" · "Server" · "Not sent ({n})".
- Search and chips: "Search event or message" · "Clear search" · "Level" · "Status" · "Category" · "Time" · "Device / user" · "{label} · {value}"; levels "Debug" · "Info" · "Warning" · "Error"; statuses "Open" · "Fixed"; windows "Last hour" · "Last 24 hours" · "Last 7 days" · "Last 30 days" · "All time"; sheets "Reset" · "Apply" · "Device ID" · "User ID" · "Paste an ID from a log's details." · "That isn't a valid user ID."
- List: "{n} open" · "{n}+ open" · "{n} logs" · "{n}+ logs" · "No more logs" · "Couldn't load more logs." · "Retry".
- States: "No open problems" · "Warnings and errors will show here." · "Nothing matches" · "Clear filters" · "Can't reach the server" · "Monitoring reads the logs online. The ones this device hasn't sent are under Not sent." · "Not sent" · "Couldn't load logs" · "Nothing was lost. Try again in a moment." · "Only an admin can see this".
- Not sent: "{n} logs wait on this device. They are sent when MemoX is online." · "Nothing waiting" · "Every log on this device has been sent." · "No logs at these levels" · "Try another level."
- Detail: "Log" · "Copy log" · "Copied" · "Details" · "Event" · "Level" · "Status" · "Note" · "Time" · "Category" · "Source" · "Device" · "App" · "Platform" · "User" · "Fixed by {user} · {date}" · "Message" · "Error" · "Stack trace" · "Context".
- Triage: "Mark fixed" · "Reopen" · "Note (optional)" · "What did you do?" · "Marked fixed" · "Reopened" · "Couldn't change that. Nothing changed." · "Retry".
- Detail states: "Couldn't load this log" · "Nothing was lost. Try again when you're online." · "This log is gone" · "It may have been cleaned up."
```

- [ ] **Step 2: Add the index row and the Settings row**

```diff
--- a/docs/shared/ui/screen-handoff/00-index.md
+++ b/docs/shared/ui/screen-handoff/00-index.md
@@ -56,11 +56,12 @@
 | 20 | Study · Fill | 3 | FE-A6 | aligned | [20-study-fill.md](20-study-fill.md) |
 | 21 | Session summary | 10 | FE-A6 | aligned | [21-session-summary.md](21-session-summary.md) |
 | 22 | Progress | 8 | FE-A9 | aligned | [22-progress.md](22-progress.md) |
-| 23 | Settings | 11 | FE-A3, SB-U1 | aligned | [23-settings.md](23-settings.md) |
+| 23 | Settings | 11 | FE-A3, SB-U1, FE-B8 | aligned | [23-settings.md](23-settings.md) |
 | 24 | Daily reminder | 9 | FE-B5, FE-B6 | aligned | [24-daily-reminder.md](24-daily-reminder.md) |
 | 25 | Theme | 3 | FE-A3 | aligned | [25-theme.md](25-theme.md) |
 | 26 | Language | 3 | FE-A3 | aligned | [26-language.md](26-language.md) |
 | 27 | Sync (not in the kit) | 7 | SB-U1 | aligned | [27-sync.md](27-sync.md) (shape brief in the spec) |
+| 28 | Monitoring (not in the kit; admin only) | 15 | FE-B8 | aligned | [28-monitoring.md](28-monitoring.md) (shape brief in the spec) |
 
 ## Rules shared by every screen
 
```

```diff
--- a/docs/shared/ui/screen-handoff/23-settings.md
+++ b/docs/shared/ui/screen-handoff/23-settings.md
@@ -25,6 +25,7 @@
 | Card limit message | `MxFieldMessage` (error) | "Enter a number from 1 to 200", under the stepper, while a typed value is out of range (E1). |
 | App | `MxSection` + `MxSettingsRow` × 2 | "Theme" with the choice ("Follows the system setting", "Light" or "Dark"); "Language" with "System · {language}", "English" or "Tiếng Việt". Both open their page. |
 | Sync | `MxSection` + `MxSettingsRow` | SB-U1, V8 addition: "Sync", one row with the cloud-sync tile; its sub-line is the first that applies of "{n} changes kept only on this device", "Couldn't sync · no connection" (or "· couldn't sign in", "· server error", "· something went wrong"), "Synced {Today, 14:32}", "Not synced yet" (sync status spec §5.1). Opens screen 27. Hidden when the build has no Supabase. |
+| Admin | `MxSection` + `MxSettingsRow` | FE-B8, V8 addition: "Admin", one row "Monitoring" / "Logs of the app and the server" with the monitor tile. Opens screen 28. Drawn only while the session's account is an admin; hidden for everyone else and in a build with no Supabase. |
 | Reset | `MxSection` + `MxSettingsRow` | "Reset app options" / "Theme, language, study defaults". The note: "Only these app options return to their defaults. Decks, cards, per-deck study options and learning progress are not touched." |
 | Reset dialog | `MxDialog` + `MxNote` + `MxSheetActions.custom` | "Reset app options?", "Theme, language, cards per session and new-card order go back to their defaults.", the shield note "Your decks, cards, schedules and study history stay exactly as they are. This is not “Reset learning progress”.", then Cancel (outline) · "Reset options" (primary, spinning while it runs), stacked when a label cannot fit (UI-base row 118). Back and Cancel do nothing while it runs. |
 | Toasts | `MxSnackbar` | "Saved"; "Couldn't save cards per session. Still {n}." · Retry; "Couldn't save the new-card order." · Retry; "App options reset to defaults"; "Couldn't reset the app options. Nothing changed." · Retry. |
@@ -63,6 +64,7 @@
 | No read-error state | `MxErrorState` with Retry | UC E3; UI-base row 125 |
 | The tray on one line at any size | The options stack when their labels do not fit | UI-base row 127 |
 | No Sync section (kit v3 has no network UI) | A Sync section with one row opening screen 27 | ADR-015; SB-U1 (owner rulings R1, R5; Impeccable shape 2026-09-28) |
+| No admin area | An Admin section with one row opening screen 28, drawn only for an admin | ADR-018 §8; monitoring spec §3.1 |
 | The tile centred on a row with a wide control | The tile beside the label, as the kit draws it | UI-base row 128 |
 
 ## Copy
@@ -71,5 +73,6 @@
 - App: "App" · "Theme" · "Follows the system setting" · "Light" · "Dark" · "Language" · "System · {language}" · "English" · "Tiếng Việt".
 - Reset: "Reset" · "Reset app options" · "Theme, language, study defaults" · "Only these app options return to their defaults. Decks, cards, per-deck study options and learning progress are not touched." · "Reset app options?" · "Theme, language, cards per session and new-card order go back to their defaults." · "Your decks, cards, schedules and study history stay exactly as they are. This is not “Reset learning progress”." · "Cancel" · "Reset options".
 - Sync (SB-U1): "Sync" · "{n} changes kept only on this device" · "Couldn't sync · no connection" · "Couldn't sync · couldn't sign in" · "Couldn't sync · server error" · "Couldn't sync · something went wrong" · "Synced {time}" · "Not synced yet"; times "Today, {HH:mm}" · "Yesterday, {HH:mm}" · "{MMM d}, {HH:mm}".
+- Admin (FE-B8): "Admin" · "Monitoring" · "Logs of the app and the server".
 - Toasts: "Saved" · "Couldn't save cards per session. Still {n}." · "Couldn't save the new-card order." · "App options reset to defaults" · "Couldn't reset the app options. Nothing changed." · "Retry".
 - Error: "Couldn't open Settings" · "Nothing was lost. Try again in a moment." · "Retry".
```

- [ ] **Step 3: Add the UI-base register row**

```diff
--- a/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
+++ b/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
@@ -549,6 +549,7 @@
 | 144 | `RouteNotFoundScreen`, not in the kit: an unknown route or deep link shows `MxEmptyState` (search-off glyph, "Page not found", one line, "Back to Library") on a bare `Scaffold`, in place of go_router's default page, which prints the exception (IT-NAV-005) | FE-D3 spec D5 |
 | 145 | FE-C1 moves these off the kit so text meets 4.5:1 and meaningful edges 3:1 in both themes: the light `error` is `#C02447` (the kit's `#DC2D4E` is 3.74:1 as text on a sheet; `errorFill` keeps the kit value); `inversePrimary` is `#A0ACFF` in both themes; a tonal mastery Badge and the Recall/Fill chip of `MxStudyTopBar` (new `accentInk`) read in `statusMasteredInk` (the green is 3.56:1 on its tint in light); the warning banner glyph is `warningInk`; the off `MxToggle` has an `outline` ring and an `onSurfaceVariant` thumb; `MasteryRamp.track` is `surfaceContainerLow`; the sheet grabber is `onSurfaceVariant`. `textContrastGuideline` stays out of `auditProductionScreen`: it misreads anti-aliased 12px text and filled buttons, so the pairs are checked from the tokens | FE-C1, owner 2026-09-28 |
 | 146 | The kit draws phones only. V8's `MxNavRail` (80 wide, `surfaceContainerLow`, `MxBottomNav`'s glyphs, pill and label) and the 720 dp screen column, with the FAB on the column's edge and the snackbar at most the column, are V8's own; sheets and dialogs keep their widths | FE-C5, owner 2026-09-28 |
+| 147 | Screen 28, Monitoring, is not in the kit; it is shaped from the kit's widgets. Its deviations, each recorded in [28-monitoring.md](../../shared/ui/screen-handoff/28-monitoring.md): the status pill is `MxBadge` (open in the warning tone, fixed in the mastery tone), because `MxStatusBadge` names a card lifecycle; the several-choice filter sheets use `MxSettingsRow` + `MxToggle`, because `MxOptionRow` is a radio; a `code` text style (system monospace, `bodySmall` size, tabular figures) for stack traces and JSON, added to `MxTextStyles`; category rows show the stored code; the device and user filter is a sheet of two text fields; the rows sit directly in the page's scroll, not in a card | Owner rulings 2026-09-29 (Impeccable shape), monitoring spec §3, §4.5; plan rulings 1 to 4 and 13 |
 
 Further contradictions found while implementing are appended here with the same
 rule applied. `docs/_generated/open-questions.md` is generated and is not
```

- [ ] **Step 4: Add the WBS row (Vietnamese, as the table is)**

```diff
--- a/docs/wbs_FE.md
+++ b/docs/wbs_FE.md
@@ -97,6 +97,7 @@
 | FE-B5 | Nhắc học hằng ngày trong Cài đặt; chỉ xin quyền notification sau khi người dùng bật (UC-REMINDER-001; BR-REMINDER-011) | xong | BE-B5a, BE-B5b, FE-A3 | S–M | [spec](superpowers/specs/2026-09-28-daily-reminder-ui-design.md) và [plan](superpowers/plans/2026-09-28-daily-reminder-ui.md); màn 24 [24-daily-reminder.md](shared/ui/screen-handoff/24-daily-reminder.md) `aligned`, 9/9 state của kit; bật, tắt, đổi giờ qua `ReminderOperationGate`; hàng Daily reminder của màn 23, câu chữ reset nêu nhắc học và `app/` hoà giải sau reset (dòng 123 của sổ nợ UI-base đóng); [ui.md](features/reminders/ui.md); test trong `test/features/reminders/presentation/`, `test/features/settings/presentation/`, companion `test/visual_audit/screens/features/reminders/` | — (đã kiểm trên emulator cùng BE-B5b, 2026-09-28) |
 | FE-B6 | Nút "Open system settings" ở state `permDenied` của màn 24 (D1 của [spec FE-B5](superpowers/specs/2026-09-28-daily-reminder-ui-design.md)): thao tác mới của `ReminderPlatformRepository` mở cài đặt notification của app | xong | FE-B5, BE-B5b | S | Kit 24 vẽ nút này. `ReminderPlatformRepository.openNotificationSettings` qua channel `memox/notification_settings` của `MainActivity.kt`; banner E1 có "Open system settings" (primary) rồi "Try again" (outline); D1 của spec FE-B5 đóng. Test trong `test/features/reminders/`; kiểm trên emulator API 36 (2026-09-28): nút mở trang notification của MemoX, cho phép rồi Try again thì bật | — |
 | FE-B7 | Trạng thái đồng bộ trên màn hình (SB-U1): màn 27 Sync, dòng Sync ở màn 23, thẻ nổi sync ở màn 13 (`MxFloatingNotice`, quyết định của chủ dự án 2026-09-28); không có trong kit, dựng theo Impeccable `shape` ngày 2026-09-28 | xong | SB-U1 của [`wbs_supabase.md`](wbs_supabase.md) | M | [PR #138](https://github.com/ntgptit/memox-v8/pull/138); [spec](superpowers/specs/2026-09-28-sync-status-design.md) và [plan](superpowers/plans/2026-09-28-sync-status.md); màn 27 [27-sync.md](shared/ui/screen-handoff/27-sync.md) `aligned`, 7 golden light/dark; 3 golden dòng Sync ở màn 23, 2 golden thẻ nổi ở màn 13; deviation ghi ở 13, 23 và 27 | Ẩn hết khi build không có Supabase |
+| FE-B8 | Màn giám sát log cho admin (ADR-018 §8): màn 28 Monitoring với tab Server và Chưa gửi, bộ lọc đầy đủ, trang chi tiết và đánh dấu đã xử lý; mục Admin ở màn 23; kiểu chữ `code`; không có trong kit, dựng theo Impeccable `shape` ngày 2026-09-29 | xong | SB-U1 của [`wbs_supabase.md`](wbs_supabase.md), pipeline log của sub-project B1 | L | [spec](superpowers/specs/2026-09-29-monitoring-screen-design.md) và [plan](superpowers/plans/2026-09-29-monitoring-screen.md); màn 28 [28-monitoring.md](shared/ui/screen-handoff/28-monitoring.md) `aligned`, 20 golden light/dark; deviation ghi ở 23, 28 và dòng 147 của §9 | Ẩn hết khi build không có Supabase hoặc tài khoản không phải admin |
 
 ### Nợ của UI base (spec UI base §9)
 
```

- [ ] **Step 5: Regenerate and check the documents**

Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py`
Expected: `check.py` exits 0 with no broken link or stale `docs/_generated/`.

`CLAUDE.md` lists the RPCs a client may call ("`log_query` and `log_set_status`" for an admin). The PR that added `log_get` owns that sentence; if it does not name `log_get`, say so to the owner rather than editing `CLAUDE.md` here.

- [ ] **Step 6: Commit**

```bash
git add docs
git commit -m "docs(monitoring): screen 28 handoff, index, Settings row, register row and WBS"
```

---

### Task 14: The gate, Impeccable, the golden review

**Files:** whatever the checks below find.

- [ ] **Step 1: The full mechanical gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
Expected: `✓ mechanical gates passed` (format, analyze, generated code, architecture, docs, guard, tests without goldens). If it reports formatting, run it once with `--fix` and re-run.

- [ ] **Step 2: Goldens and the database**

Run: `TZ=UTC flutter test --tags golden`
Expected: PASS: every golden of the repo, the 20 new ones included; no existing golden changed (`git status test/` shows only `test/features/monitoring/`).
Run: `bash tools/supabase/local_pgtap.sh`
Expected: every file `ok`.

- [ ] **Step 3: Impeccable critique and audit of the goldens, against the kit**

Per `CLAUDE.md` (a screen's workflow, step 5): run Impeccable `critique` and `audit` on the 20 goldens against the kit ("MemoX — Mobile UI Kit v3", read with the Artifact tool's `read` action) and against the quality floor. The kit has no such screen, so judge it against the kit's widgets and the shaped design of the spec. Collect every finding, fix them **in one batch**, regenerate the goldens (Task 12, Step 3) and confirm once. Do not loop on polish. Record each deviation from the kit in `28-monitoring.md` and, if it is a design-system matter, in the register row 147.

- [ ] **Step 4: The final whole-branch review**

Use `requesting-code-review` on the whole branch against the spec and this plan. Fix what it finds, then re-run Steps 1 and 2.

- [ ] **Step 5: The golden review page for the owner**

The branch adds 20 goldens, so, before asking the owner to review or merge, build the private Artifact page with the `golden-compare` skill: each changed golden Before · After · Diff (Before is empty: all are new), with a sentence on what each shows and why. Its link goes in the reply that asks the owner to review, approve or merge. The page and its images live in the scratchpad and on claude.ai, never in the repo.

- [ ] **Step 6: Open the PR (after the owner says so)**

Ask through the `AskUserQuestion` popup. When it is opened, add its link to the FE-B8 row's evidence in `docs/wbs_FE.md`, run `python3 tools/docs/generate.py && python3 tools/docs/check.py`, and commit.

---

## Self-review

**Spec coverage.**

| Spec | Task |
|---|---|
| §1 success: the admin sees, reads, marks fixed; a non-admin sees nothing; offline still shows Not sent | 7 (entry), 9 (list, Not sent), 10 (detail), 8 and 10 (fixed leaves the default list) |
| §2 dependencies (`logging-minors`, `network-logging`) | Preconditions; Task 3 (device filter); Task 9 (categories from `LogCategory.values`) |
| §3.1 entry, route | Tasks 7, 11 |
| §3.2 list: tabs, search, chips, sheets, count, rows, paging; Not sent | Tasks 8, 9 |
| §3.3 detail: summary, cards, code style, triage, copy, failure toast | Tasks 1, 10 |
| §3.4 states | Task 9 (list), Task 10 (detail) |
| §3.5 behaviour: refresh, filter resets, Back keeps pages, local times, 720 dp, large text | Tasks 8, 9, 10, 11 |
| §4.1 domain; §4.2 data; §4.3 presentation; §4.4 admin detection; §4.5 design system | Tasks 5; 2 and 6; 8 to 10; 7; 1 |
| §5 testing, goldens, gate | every task; Tasks 12, 14 |
| §6 out of scope | not built |
| §7 risks (many debug rows, 256 kB, role arrives on refresh) | 100-row keyset (6, 8); Review Focus 1; Review Focus 3 |
| Network logger must not log Monitoring's RPCs | Task 4 |

**Placeholder scan.** No step says "similar to", "TBD" or "add appropriate handling"; every code step shows its code or a diff. The two places that tell the executor to read a file first (Task 3's migration body, Task 4's `send`) do so because the sibling PRs may have changed those files, and each names what wins.

**Type consistency.** `PendingLogRows`/`PendingLog` (core) are mapped to `PendingLogs`/`LogSummaryEntity` (domain) by `pendingLogsOf`; `MonitoringRepository` is implemented by `MonitoringRepositoryImpl` with the same five methods; the controllers call the use cases through the providers of Task 8; the detail controller's `setStatus(LogStatus, {String? note})` matches the sheet's `String?` result and the screen's Retry; `MonitoringLoadFailure.of` is used by both list and detail controllers.

**Review Focus.** Each of the five lines has its test in the task that owns the code (see the list above).
