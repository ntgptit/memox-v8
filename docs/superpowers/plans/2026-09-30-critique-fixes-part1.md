# Critique 2026-09-30 (31/40), part 1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the six Majors of the 2026-09-30 whole-app critique and the shared-component patterns behind its most frequent Minors, without new abstractions.

**Architecture:** Shared widgets change behaviour in place (`MxOptionRow`, `MxSettingsRow` via `MxRowInk`, `MxErrorState`, the `MxButton` outline edge through a new derived colour). Callers fix their own button tones under a new `DESIGN.md` rule, guarded by a test helper. One presentation provider reads the reminder workload for a live preview.

**Tech Stack:** Flutter 3.47.5, Riverpod 3 (`@riverpod` codegen), Drift (read only), ARB l10n (en, vi), goldens rendered in this Linux container.

**Spec:** `docs/superpowers/specs/2026-09-30-critique-fixes-part1-design.md` (rulings R1–R9)

## Global Constraints

- Tests run at the default text scale only (PRODUCT.md); light and dark both stay.
- Components hold no copy; every new string goes in `lib/l10n/app_en.arb` and `lib/l10n/app_vi.arb`; no unused ARB key is left (`reminderPreviewDeck` is removed).
- No new abstraction: no ambient "primary scope", no use case for the reminder preview (spec R3, §5.5).
- A lone Close stays primary (R8). A deck with no content has no FAB (R9). The outline edge changes in dark only (R7).
- Guard (`memox-v8` ruleset) clean: no raw numbers or colours in UI code, no `Icon(color:)` outside the allowed widgets, tokens only.
- Failure copy is local-first: say nothing was lost before offering the retry.
- Goldens are regenerated only with `flutter test --tags golden --update-goldens` in this Linux container, never by hand.
- Commit after each task; messages in English, conventional style, ending with the session's Co-Authored-By and Claude-Session lines.

## Review Focus

- **Keep dialog dismissed by Back or a scrim tap** writes nothing: `keepRejectedOnDevice` is not called and the banner stays (Task 6 test "dismissing the Keep dialog keeps the refused rows").
- **Sync with refused rows and a failure at once**: the refused banner still shows both actions and "Sync now" stays outline (Task 6 test "refused rows and a failure: one primary").
- **Import mapping with a ragged file** (the sample row shorter than the column count, or a blank cell): the missing column shows no sample line and nothing throws (Task 9 test "a short or blank sample cell shows no sample").
- **Reminder preview when the workload read fails**: the neutral line shows, no error tile, and the screen's other rows still work (Task 10 test "a failed read shows the neutral line").
- **Study entry resume with only new cards** (the footer offers Learn, not Review): the footer is still outline while the resume card shows (Task 7 test "resume with only new cards keeps one primary").

---

### Task 1: Outline edge that holds 3:1 in dark

**Files:**
- Modify: `lib/core/theme/mx_derived_colors.dart`
- Modify: `lib/shared/widgets/mx_button.dart:173-180`
- Test: `test/core/theme/token_contrast_test.dart`, `test/shared/widgets/mx_button_test.dart:143-157`

**Interfaces:**
- Produces: `MxDerivedColors.outlineEdge` (`Color`): dark = `Color.lerp(scheme.outline, scheme.onSurface, 0.25)`, light = `scheme.outlineVariant`.

- [ ] **Step 1: Write the failing contrast pairs.** In `token_contrast_test.dart`, inside `_pairs`, add (dark-only pairs are filtered by the existing per-scheme loop; add them unconditionally and guard with `scheme.brightness`):

```dart
    if (scheme.brightness == Brightness.dark) ...[
      ('outline edge on page', derived.outlineEdge, page, _nonText),
      ('outline edge on sheet', derived.outlineEdge, sheet, _nonText),
      (
        'outline edge on the warning ground',
        derived.outlineEdge,
        Color.alphaBlend(derived.warningSoft, page),
        _nonText,
      ),
    ],
```

- [ ] **Step 2: Update the button test** at `mx_button_test.dart:143`: rename to `'outline tone has no fill, primaryInk, 1px outlineEdge'` and expect `BorderSide(color: MxDerivedColors.resolve(scheme, MxSemanticColors.light).outlineEdge)`; add a dark variant pumping with `brightness: Brightness.dark` that expects the dark `outlineEdge`.

- [ ] **Step 3: Run and see it fail.** `flutter test test/core/theme/token_contrast_test.dart test/shared/widgets/mx_button_test.dart` → FAIL, `outlineEdge` is not defined.

- [ ] **Step 4: Implement.** In `MxDerivedColors`: add `required this.outlineEdge` to the private constructor, the field with a doc comment, and in `resolve`:

```dart
      // The outline button's edge. Dark pulls outline toward onSurface so it
      // holds 3:1 on the page, the sheet and the warning ground (3.41 on the
      // sheet); light keeps outlineVariant (owner ruling R7, critique
      // 2026-09-30 part 1).
      outlineEdge: isDark
          ? Color.lerp(scheme.outline, scheme.onSurface, _outlineEdgeDark)!
          : scheme.outlineVariant,
```

with `static const double _outlineEdgeDark = 0.25;`. In `mx_button.dart` outline tone: `color: context.derivedColors.outlineEdge`.

- [ ] **Step 5: Run and see it pass.** Same command → PASS. Also `flutter analyze lib/core/theme lib/shared/widgets`.

- [ ] **Step 6: Commit** `fix(theme): the outline button edge holds 3:1 in dark`.

### Task 2: `MxOptionRow` never dims the selected fact or the reason

**Files:**
- Modify: `lib/shared/widgets/mx_option_row.dart`
- Test: `test/shared/widgets/mx_option_row_test.dart`

**Interfaces:**
- Produces: unchanged API. Behaviour: `isDimmed ?? (onSelected == null && !isSelected)`; when dimmed, the `Opacity` wraps the radio and the title only.

- [ ] **Step 1: Write the failing tests** (append to `main`):

```dart
  testWidgets('a selected row that cannot change is not dimmed (critique '
      '2026-09-30: the locked algorithm)', (tester) async {
    await pumpMx(
      tester,
      const MxOptionRow(title: 'SM-2', isSelected: true, onSelected: null),
    );
    expect(
      find.ancestor(of: find.text('SM-2'), matching: find.byType(Opacity)),
      findsNothing,
    );
  });

  testWidgets('a dimmed row keeps its description at full ink', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxOptionRow(
        title: 'Guess',
        description: 'Needs five different meanings',
        isSelected: false,
        onSelected: null,
      ),
    );
    expect(
      find.ancestor(of: find.text('Guess'), matching: find.byType(Opacity)),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text('Needs five different meanings'),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
  });
```

- [ ] **Step 2: Run** `flutter test test/shared/widgets/mx_option_row_test.dart` → the two new tests FAIL.

- [ ] **Step 3: Implement.** Compute `final isDim = isDimmed ?? (onSelected == null && !isSelected);` at the top of `build`. Wrap the radio `SizedBox` and the title `Text` each in `Opacity(opacity: AppOpacity.disabled, …)` when `isDim` (a small private helper `Widget _dim(Widget child, bool isDim)` returning the child untouched when false). Remove the outer `Opacity` at the end of `build` and return `row`. Update the `isDimmed` doc: "null dims exactly the rows that cannot be selected and are not selected; the description is never dimmed, so a blocked row's reason reads (critique 2026-09-30)." The existing test at line ~139 (`onSelected: null`, unselected → 0.38 above the radio) still holds.

- [ ] **Step 4: Run** the same file → PASS.

- [ ] **Step 5: Commit** `fix(shared): an option row never dims the selected fact or the reason`.

### Task 3: `MxSettingsRow` keeps its explanation; action rows drop the chevron

**Files:**
- Modify: `lib/shared/widgets/mx_row_ink.dart`, `lib/shared/widgets/mx_settings_row.dart`, `lib/features/settings/presentation/screens/settings_screen.dart:106-111`
- Test: `test/shared/widgets/mx_row_ink_test.dart`, `test/shared/widgets/mx_settings_row_test.dart:150-175`

**Interfaces:**
- Produces: `MxRowInk({…, bool shouldDimWhenDisabled = true})`; `MxSettingsRow({…, bool isAction = false})`.

- [ ] **Step 1: Write the failing tests.** In `mx_row_ink_test.dart`:

```dart
  testWidgets('shouldDimWhenDisabled false blocks taps without painting opacity', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxRowInk(
        onTap: () => taps++,
        isEnabled: false,
        shouldDimWhenDisabled: false,
        child: const SizedBox(height: 48, child: Text('Row')),
      ),
    );
    await tester.tap(find.text('Row'), warnIfMissed: false);
    expect(taps, 0);
    expect(
      find.ancestor(of: find.text('Row'), matching: find.byType(Opacity)),
      findsNothing,
    );
  });
```

In `mx_settings_row_test.dart`, replace the body of `'dimmed at 0.38 while unavailable'` so the label is under a 0.38 `Opacity` and add a subtitle; then add:

```dart
  testWidgets('a disabled row keeps its subtitle at full ink (critique '
      '2026-09-30, screen 24)', (tester) async {
    await pumpMx(
      tester,
      _width(
        const MxSettingsRow(
          label: 'Time',
          subtitle: 'Turn the reminder on to choose a time',
          icon: AppIcons.clock,
          isEnabled: false,
        ),
      ),
    );
    expect(
      find.ancestor(
        of: find.text('Turn the reminder on to choose a time'),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(of: find.text('Time'), matching: find.byType(Opacity)),
          )
          .opacity,
      0.38,
    );
  });

  testWidgets('an action row shows no chevron', (tester) async {
    await pumpMx(
      tester,
      _width(MxSettingsRow(label: 'Reset options', isAction: true, onTap: () {})),
    );
    expect(find.byIcon(AppIcons.chevronRight), findsNothing);
  });
```

- [ ] **Step 2: Run** both files → the new tests FAIL.

- [ ] **Step 3: Implement `MxRowInk`.** Add `this.shouldDimWhenDisabled = true` and the field with a doc ("False leaves the dim to the child, which dims only what is unavailable; taps stay blocked."). In `build`, when `!widget.isEnabled`, build the same `Semantics`/child as today and wrap it in `Opacity` only when `shouldDimWhenDisabled`.

- [ ] **Step 4: Implement `MxSettingsRow`.** Add `this.isAction = false` with doc "Runs an action or opens a dialog: no chevron, since nothing is navigated to (critique 2026-09-30)." Set `isNavigable = onTap != null && !isAction && trailing == null && wideControl == null`. Pass `shouldDimWhenDisabled: false` to `MxRowInk`. Wrap the icon tile, the label `Text`, the trailing control and the wide control in `Opacity(opacity: AppOpacity.disabled)` when `!isEnabled` (one private `_dim` helper as in Task 2); the subtitle is not wrapped. Update the `isEnabled` doc: "False dims the tile, label and control while the setting is unavailable; the subtitle, which says why, keeps full ink."

- [ ] **Step 5: Screen 23.** In `settings_screen.dart`, add `isAction: true` to the Reset row.

- [ ] **Step 6: Run** `flutter test test/shared/widgets/mx_row_ink_test.dart test/shared/widgets/mx_settings_row_test.dart test/features/settings/presentation/` → PASS (fix any settings test that asserted the Reset chevron).

- [ ] **Step 7: Commit** `fix(shared): a disabled setting keeps its reason readable; action rows drop the chevron`.

### Task 4: `MxErrorState` defaults to the alert glyph

**Files:**
- Modify: `lib/shared/widgets/mx_error_state.dart:19`, `lib/features/monitoring/presentation/screens/monitoring_detail_screen.dart:141`, `lib/features/monitoring/presentation/widgets/sections/monitoring_server_list_widget.dart` (the `MonitoringLoadFailure.offline` branch's `MxErrorState`)
- Test: `test/shared/widgets/mx_error_state_test.dart:21-45`, monitoring widget tests

**Interfaces:**
- Produces: `MxErrorState.icon` default `AppIcons.alert`.

- [ ] **Step 1: Update the tests first.** In `mx_error_state_test.dart`, the first test finds `AppIcons.alert` instead of `AppIcons.offline`; add a test that `MxErrorState(title:…, body:…, icon: AppIcons.offline)` shows the offline glyph. In `test/features/monitoring/presentation/monitoring_detail_screen_test.dart:427` (`'offline and other failures offer Retry…'`), assert `find.byIcon(AppIcons.offline)` is found in the offline case and `find.byIcon(AppIcons.alert)` in the other case.

- [ ] **Step 2: Run** those files → FAIL.

- [ ] **Step 3: Implement.** Default `this.icon = AppIcons.alert`; doc on `icon`: "Alert by default; pass `AppIcons.offline` only for a network failure (critique 2026-09-30)." Add `icon: AppIcons.offline` to the two Monitoring offline `MxErrorState`s. Read every other `MxErrorState(` call site (`grep -rn "MxErrorState(" lib/features`) and confirm none reports a network failure; the Drift reads keep the new default.

- [ ] **Step 4: Run** `flutter test test/shared/widgets/mx_error_state_test.dart test/features/monitoring/` → PASS.

- [ ] **Step 5: Commit** `fix(shared): error states show the alert glyph; cloud-off only when offline`.

### Task 5: `expectOnePrimaryPerDecision` helper

**Files:**
- Create: `test/shared/expect_one_primary.dart`
- Test: `test/shared/expect_one_primary_test.dart`

**Interfaces:**
- Produces: `void expectOnePrimaryPerDecision(WidgetTester tester)`.

- [ ] **Step 1: Write the failing test:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

import 'expect_one_primary.dart';
import '../support/widget_harness.dart';

void main() {
  testWidgets('one primary passes; an outline beside it does not count', (
    tester,
  ) async {
    await pumpMx(
      tester,
      Column(
        children: [
          MxButton(label: 'Continue', onPressed: () {}),
          MxButton(
            label: 'Start new',
            tone: MxButtonTone.outline,
            onPressed: () {},
          ),
        ],
      ),
    );
    expectOnePrimaryPerDecision(tester);
  });

  testWidgets('a primary and a FAB fail', (tester) async {
    await pumpMx(
      tester,
      Column(
        children: [
          MxButton(label: 'New card', onPressed: () {}),
          MxFab(icon: AppIcons.add, semanticLabel: 'New', onPressed: () {}),
        ],
      ),
    );
    expect(
      () => expectOnePrimaryPerDecision(tester),
      throwsA(isA<TestFailure>()),
    );
  });
}
```

- [ ] **Step 2: Run** `flutter test test/shared/expect_one_primary_test.dart` → FAIL (file missing).

- [ ] **Step 3: Implement** `test/shared/expect_one_primary.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

/// The One Indigo Rule as a check (DESIGN.md; critique 2026-09-30 part 1):
/// at most one enabled primary fill a finger can reach, the FAB included.
/// A surface under a modal barrier is not hit-testable, so a dialog's own
/// primary does not count against the page below it.
void expectOnePrimaryPerDecision(WidgetTester tester) {
  final primaries = find
      .byWidgetPredicate(
        (widget) =>
            widget is MxButton &&
            widget.tone == MxButtonTone.primary &&
            widget.onPressed != null,
      )
      .hitTestable();
  final fabs = find.byType(MxFab).hitTestable();
  final count = primaries.evaluate().length + fabs.evaluate().length;
  expect(count, lessThanOrEqualTo(1), reason: 'more than one primary fill');
}
```

(If `MxButton` exposes the tone under another name, read `lib/shared/widgets/mx_button.dart` and use it.)

- [ ] **Step 4: Run** → PASS.

- [ ] **Step 5: Commit** `test: a helper that checks one primary per decision`.

### Task 6: Screen 27 Sync — one primary, a consistent status, a guarded Keep

**Files:**
- Create: `lib/features/settings/presentation/widgets/overlays/sync_keep_dialog_widget.dart`
- Modify: `lib/features/settings/presentation/screens/sync_screen.dart:32-36,77-83`, `lib/features/settings/presentation/widgets/sections/sync_status_section_widget.dart`, `lib/features/settings/presentation/widgets/sections/sync_notice_widget.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/settings/presentation/sync_screen_test.dart`, `test/features/settings/presentation/sync_screen_golden_test.dart`

**Interfaces:**
- Consumes: `expectOnePrimaryPerDecision` (Task 5).
- Produces: `Future<bool> showSyncKeepDialog(BuildContext context, int count)`; ARB keys `syncRejectedBody`, `syncWaitingNoneOthers`, `syncKeepTitle(count)`, `syncKeepBody`.

- [ ] **Step 1: Add the strings** (en, then vi; run `flutter gen-l10n`):

| Key | en | vi |
|---|---|---|
| `syncRejectedBody` | The server didn't accept them. They're safe here. Try again, or keep them on this device only; they won't sync to your other devices. | Máy chủ không nhận các thay đổi này. Chúng vẫn an toàn trên máy. Hãy thử lại, hoặc chỉ giữ chúng trên máy này; chúng sẽ không đồng bộ sang các thiết bị khác của bạn. |
| `syncWaitingNoneOthers` | No other changes waiting | Không còn thay đổi nào khác đang chờ |
| `syncKeepTitle` | {count, plural, =1{Keep 1 change on this device only?} other{Keep {count} changes on this device only?}} | {count, plural, other{Chỉ giữ {count} thay đổi trên máy này?}} |
| `syncKeepBody` | They won't sync to your other devices. You can't undo this. | Chúng sẽ không đồng bộ sang các thiết bị khác của bạn. Không thể hoàn tác. |

Each with a `@key` description naming screen 27 and "critique 2026-09-30 part 1"; `syncKeepTitle` declares `count` as `int`.

- [ ] **Step 2: Write the failing tests** in `sync_screen_test.dart`. Replace the Keep half of `'refused rows offer Try again and Keep on this device'` and add:

```dart
  libraryTest('refused rows: Try again is the one primary; Sync now is '
      'outline; the waiting row does not contradict the banner', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(
        const SyncStatus(rejectedCount: 2),
        FakeSyncCommands(),
      ),
    );
    expect(
      tester.widget<MxButton>(find.widgetWithText(MxButton, 'Sync now')).tone,
      MxButtonTone.outline,
    );
    expect(find.text('No other changes waiting'), findsOneWidget);
    expect(find.text('Nothing waiting'), findsNothing);
    expect(
      find.textContaining("they won't sync to your other devices"),
      findsOneWidget,
    );
    expectOnePrimaryPerDecision(tester);
  });

  libraryTest('Keep asks first and keeps only on confirm', (tester, env) async {
    final commands = FakeSyncCommands();
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(const SyncStatus(rejectedCount: 3), commands),
    );
    await tester.tap(find.text('Keep on this device'));
    await tester.pumpAndSettle();
    expect(find.text('Keep 3 changes on this device only?'), findsOneWidget);
    expect(commands.keeps, 0);
    await tester.tap(find.text('Keep on this device').last);
    await _settle(tester);
    expect(commands.keeps, 1);
    expect(find.text('Kept on this device'), findsOneWidget);
  });

  libraryTest('dismissing the Keep dialog keeps the refused rows', (
    tester,
    env,
  ) async {
    final commands = FakeSyncCommands();
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(const SyncStatus(rejectedCount: 3), commands),
    );
    await tester.tap(find.text('Keep on this device'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(commands.keeps, 0);
    await tester.tap(find.text('Keep on this device'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(commands.keeps, 0);
    expect(find.text('3 changes are kept only on this device'), findsOneWidget);
  });

  libraryTest('refused rows and a failure: one primary', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(
        SyncStatus(
          rejectedCount: 1,
          lastFailure: LastSyncFailure(
            SyncFailureKind.network,
            env.clock.now(),
          ),
        ),
        FakeSyncCommands(),
      ),
    );
    expect(find.text('Try again'), findsOneWidget);
    expectOnePrimaryPerDecision(tester);
  });
```

Keep the existing Try again assertions (it still calls `commands.retries`). Import `../../../shared/expect_one_primary.dart`. If `LastSyncFailure` takes other arguments, copy the construction from the existing `'a failure shows its sentence and no code'` test.

- [ ] **Step 3: Run** `flutter test test/features/settings/presentation/sync_screen_test.dart` → FAIL.

- [ ] **Step 4: Implement the dialog** `sync_keep_dialog_widget.dart`, on the `study_exit_dialog_widget.dart` pattern:

```dart
import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Asks before refused changes are kept on this device only: they then never
/// sync (sync status spec R7; critique 2026-09-30 part 1, R4). Completes true
/// to keep; false (Cancel, Back or the scrim) writes nothing.
Future<bool> showSyncKeepDialog(BuildContext context, int count) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => SyncKeepDialogWidget(count: count),
    ) ??
    false;

class SyncKeepDialogWidget extends StatelessWidget {
  const SyncKeepDialogWidget({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      title: l10n.syncKeepTitle(count),
      body: l10n.syncKeepBody,
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: l10n.syncKeepOnDevice,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }
}
```

- [ ] **Step 5: Implement the notice.** In `sync_notice_widget.dart`'s refused branch: `title: l10n.syncRejectedTitle(status.rejectedCount)`, `message: l10n.syncRejectedBody`; Keep's `onPressed`:

```dart
          onPressed: isIdle ? () => unawaited(_keep(context)) : null,
```

with

```dart
  Future<void> _keep(BuildContext context) async {
    if (!await showSyncKeepDialog(context, status.rejectedCount)) return;
    onRun(SyncTask.keep);
  }
```

(import `dart:async` and the dialog). Update the class doc: the refused banner states why and what Keep costs, and Keep asks first.

- [ ] **Step 6: Implement the screen and status.** In `sync_screen.dart` replace `_needsSync` with:

```dart
  /// Sync now leads only when something waits or the last run failed and no
  /// row was refused; with refused rows the banner's Try again is the one
  /// primary (DESIGN.md One Indigo; critique 2026-09-30 part 1).
  static bool _leadsSyncNow(SyncStatus status) =>
      status.rejectedCount == 0 &&
      (status.pendingCount > 0 || status.lastFailure != null);
```

and use it for the tone. In `sync_status_section_widget.dart` the waiting subtitle becomes:

```dart
          subtitle: switch ((status.pendingCount, status.rejectedCount)) {
            (0, 0) => l10n.syncWaitingNone,
            (0, _) => l10n.syncWaitingNoneOthers,
            (final count, _) => l10n.syncWaitingCount(count),
          },
```

- [ ] **Step 7: Golden.** In `sync_screen_golden_test.dart` add a `sync_keep_dialog_{theme}` golden: pump the rejected state, tap Keep, `pumpAndSettle`, capture (copy the existing rejected golden's setup).

- [ ] **Step 8: Run** `flutter test test/features/settings/presentation/ --exclude-tags golden` → PASS.

- [ ] **Step 9: Commit** `fix(settings): refused sync rows get one primary, a reason and a confirmed Keep`.

### Task 7: Study entry resume and Study home notice yield their tone

**Files:**
- Modify: `lib/features/study/presentation/widgets/sections/study_entry_footer_widget.dart:79-88`, `lib/features/study/presentation/widgets/sections/study_home_sync_banner_widget.dart:28-32`
- Test: `test/features/study/presentation/study_entry_actions_test.dart`, `test/features/study/presentation/study_home_sync_banner_test.dart:50`

**Interfaces:**
- Consumes: `expectOnePrimaryPerDecision` (Task 5).

- [ ] **Step 1: Write the failing tests.** In the resume test at `study_entry_actions_test.dart:163`, before tapping Continue, add:

```dart
    expect(
      tester.widget<MxButton>(_button(_en.studyEntryReviewInstead)).tone,
      MxButtonTone.outline,
    );
    expectOnePrimaryPerDecision(tester);
```

Add a test `'resume with only new cards keeps one primary'`: `sm2Leaf(env.db, env.decks, newCards: 2)`, open a learning session as in the resume test, pump `_screen(leaf)`, then `expectOnePrimaryPerDecision(tester)`. In `study_home_sync_banner_test.dart`, in `'refused rows show the banner; Details opens screen 27'`, before tapping Details add:

```dart
    expect(
      tester.widget<MxButton>(find.widgetWithText(MxButton, 'Details')).tone,
      MxButtonTone.outline,
    );
    expectOnePrimaryPerDecision(tester);
```

- [ ] **Step 2: Run** both files → FAIL.

- [ ] **Step 3: Implement.** In the footer's final `MxFooterBar`, give the `MxButton`:

```dart
        // An open session leads with Continue in its card; the footer's
        // start yields (DESIGN.md One Indigo; critique 2026-09-30 part 1).
        tone: entry.resumable == null
            ? MxButtonTone.primary
            : MxButtonTone.outline,
```

In `study_home_sync_banner_widget.dart` add `tone: MxButtonTone.outline` to Details.

- [ ] **Step 4: Run** `flutter test test/features/study/presentation/ --exclude-tags golden` → PASS.

- [ ] **Step 5: Commit** `fix(study): an open session's Continue is the one primary; the sync notice links quietly`.

### Task 8: Card list search clears the hero

**Files:**
- Modify: `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart:360-372`
- Test: `test/features/card/presentation/card_list_section_test.dart`

- [ ] **Step 1: Write the failing test:**

```dart
  libraryTest('search hides the deck summary and keeps the filters '
      '(critique 2026-09-30: results clear the keyboard)', (tester, env) async {
    final deckId = await _seed(env);
    await pumpLibraryScreen(tester, env, _section(deckId));
    expect(find.byType(CardDeckSummaryWidget), findsOneWidget);
    await _openSearch(tester, deckId);
    expect(find.byType(CardDeckSummaryWidget), findsNothing);
    expect(find.byType(CardListToolbarWidget), findsOneWidget);
  });
```

(import the two widget files from `lib/features/card/presentation/widgets/sections/`.)

- [ ] **Step 2: Run** the file → FAIL.

- [ ] **Step 3: Implement:**

```dart
      if (!isSelecting) ...[
        // Search keeps the filters but not the summary, so the first
        // results sit above the keyboard (critique 2026-09-30 part 1).
        if (!isSearchOpen)
          CardDeckSummaryWidget(
            view: view,
            algorithm: widget.algorithm,
            onStudy: widget.onStudy,
          ),
        CardListToolbarWidget(
          deckId: widget.deckId,
          request: request,
          counts: view.counts,
          onFilter: _show,
        ),
      ],
```

- [ ] **Step 4: Run** `flutter test test/features/card/presentation/ --exclude-tags golden` → PASS.

- [ ] **Step 5: Commit** `fix(card): search hides the deck summary so results clear the keyboard`.

### Task 9: Import mapping shows a sample cell

**Files:**
- Modify: `lib/features/transfer/presentation/widgets/sections/import_mapping_section_widget.dart:30-60`, `lib/features/transfer/presentation/widgets/items/import_mapping_row_widget.dart`
- Test: `test/features/transfer/presentation/card_import_screen_test.dart`, `test/features/transfer/presentation/card_import_golden_test.dart`

**Interfaces:**
- Produces: `ImportMappingRowWidget({…, String? sample})`.

- [ ] **Step 1: Write the failing tests** (append; `_pump`, `_file`, `_tap` exist in the file):

```dart
  libraryTest('each column shows its first value, under the header when '
      'there is one (critique 2026-09-30)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(
      tester,
      env,
      deck.id,
      file: _file('front,back,tags\nmul,water,noun\n'),
    );
    await _tap(tester, _en.importPickAction);
    await _tap(tester, _en.importReadAction);
    expect(find.text('mul'), findsOneWidget);
    expect(find.text('water'), findsOneWidget);

    await tester.tap(find.text(_en.importHeaderToggle));
    await tester.pumpAndSettle();
    // Without a header the first row is data.
    expect(find.text('front'), findsOneWidget);
  });

  libraryTest('a short or blank sample cell shows no sample', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(
      tester,
      env,
      deck.id,
      file: _file('front,back,tags\nmul, \n'),
    );
    await _tap(tester, _en.importPickAction);
    await _tap(tester, _en.importReadAction);
    expect(find.text('mul'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
```

- [ ] **Step 2: Run** the file → the first test FAILS (`mul` not found).

- [ ] **Step 3: Implement the section.** After `headerOf`:

```dart
    // The first data row, so a column is recognised by what it holds
    // (critique 2026-09-30 part 1): row 2 under a header, else row 1.
    final firstData = draft.hasHeaderRow ? 1 : 0;
    final sampleRow = table.rows.length > firstData
        ? table.rows[firstData]
        : null;
    String? sampleOf(int column) {
      if (sampleRow == null || column >= sampleRow.length) return null;
      final cell = sampleRow[column].trim();
      return cell.isEmpty ? null : cell;
    }
```

and pass `sample: sampleOf(column)` to each `ImportMappingRowWidget`.

- [ ] **Step 4: Implement the row.** Add `this.sample` and `/// The first data row's cell, trimmed; null when empty or missing.` `final String? sample;`. In the `Column`, after the header `Text`:

```dart
                if (sample case final text?)
                  Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: styles.rowDescription,
                  ),
```

Update the class doc: "its position name, the header it had, its first value, and a picker…".

- [ ] **Step 5: Golden.** Add `import_mapping_no_header_{theme}` in `card_import_golden_test.dart`: the mapping step of `'mul,water\nbul,fire\n'` with the header toggle off (tap it if the reader turned it on).

- [ ] **Step 6: Run** `flutter test test/features/transfer/presentation/ --exclude-tags golden` → PASS.

- [ ] **Step 7: Commit** `fix(transfer): mapping rows show each column's first value`.

### Task 10: Reminder preview from the real workload

**Files:**
- Create: `lib/features/reminders/presentation/providers/reminder_preview_digest_provider.dart` (+ generated `.g.dart`)
- Modify: `lib/features/reminders/presentation/widgets/sections/reminder_preview_section_widget.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/reminders/presentation/reminder_preview_digest_provider_test.dart` (create), `test/features/reminders/presentation/reminder_screen_test.dart:29-35`, `test/features/reminders/presentation/reminder_screen_golden_test.dart`

**Interfaces:**
- Produces: `reminderPreviewDigestProvider` (`FutureProvider<ReminderDigest?>`, generated from `Future<ReminderDigest?> reminderPreviewDigest(Ref ref)`); ARB `reminderPreviewNothingDue`.

- [ ] **Step 1: Strings.** Add `reminderPreviewNothingDue`: en "Nothing is due right now, so today's reminder would stay silent." vi "Hiện chưa có thẻ nào đến hạn, nên lời nhắc hôm nay sẽ không hiện." Remove `reminderPreviewDeck` (and its `@` entry) from both ARB files. Run `flutter gen-l10n`.

- [ ] **Step 2: Write the failing provider test:**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/reminders/di/reminder_workload_repository_provider.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_workload_repository.dart';
import 'package:memox/features/reminders/presentation/providers/reminder_preview_digest_provider.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart' show libraryToday;

final class _Workloads implements ReminderWorkloadRepository {
  _Workloads(this.result);
  final Future<List<ReminderDeckWorkload>> Function() result;
  @override
  Future<List<ReminderDeckWorkload>> rootWorkloads({
    required DateTime now,
    required DateTime startOfToday,
  }) => result();
}

ProviderContainer _container(_Workloads workloads) {
  final container = ProviderContainer(
    overrides: [
      dayClockProvider.overrideWithValue(FakeDayClock(libraryToday)),
      reminderWorkloadRepositoryProvider.overrideWithValue(workloads),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('the most urgent root, its count and the others', () async {
    final container = _container(
      _Workloads(
        () async => const [
          ReminderDeckWorkload(
            deckId: 'a',
            name: 'Korean',
            overdueCount: 3,
            overdueDays: 2,
            dueTodayCount: 1,
          ),
          ReminderDeckWorkload(
            deckId: 'b',
            name: 'English',
            overdueCount: 0,
            overdueDays: 0,
            dueTodayCount: 2,
          ),
        ],
      ),
    );
    final digest = await container.read(reminderPreviewDigestProvider.future);
    expect(
      (digest!.deckName, digest.dueCount, digest.otherDeckCount),
      ('Korean', 4, 1),
    );
  });

  test('nothing due is null', () async {
    final container = _container(_Workloads(() async => const []));
    expect(await container.read(reminderPreviewDigestProvider.future), isNull);
  });

  test('a failed read is an error', () async {
    final container = _container(_Workloads(() async => throw StateError('db')));
    await expectLater(
      container.read(reminderPreviewDigestProvider.future),
      throwsStateError,
    );
  });
}
```

- [ ] **Step 3: Run** → FAIL (provider missing).

- [ ] **Step 4: Implement the provider:**

```dart
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/reminders/di/reminder_workload_repository_provider.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_preview_digest_provider.g.dart';

/// Screen 24's "What it says": what the notification would say now, read
/// once when the screen opens, as the notification reads once when it fires
/// (BR-REMINDER-003, BR-REMINDER-005). Null when nothing is due. No use
/// case: one read through an existing domain function (critique 2026-09-30
/// part 1, spec §5.5).
@riverpod
Future<ReminderDigest?> reminderPreviewDigest(Ref ref) async {
  final now = ref.watch(dayClockProvider).now();
  final workloads = await ref
      .watch(reminderWorkloadRepositoryProvider)
      .rootWorkloads(now: now, startOfToday: startOfLocalDay(now));
  return reminderDigestOf(workloads);
}
```

Run `dart run build_runner build --delete-conflicting-outputs`, then the test → PASS. Run the architecture guard (`bash .claude/skills/flutter-architecture/scripts/check_architecture.sh`); the `srs/domain` import mirrors `deliver_reminder_use_case.dart` — if the guard rejects it from presentation, move the `startOfLocalDay` call behind the repository call site the guard allows and record why.

- [ ] **Step 5: Write the failing widget tests.** In `reminder_screen_test.dart`: delete `_sample`; give `_pump` an optional `List<Override> overrides = const []` appended to its override list; replace every `find.text(_sample)` with `find.text(_en.reminderPreviewNothingDue)` (the harness database has no due card). Add, importing `../../../support/study_entry_fixtures.dart` and the new provider:

```dart
  libraryTest('the preview says what the notification would say now', (
    tester,
    env,
  ) async {
    // Korean > Lesson with three learned cards due before the harness day.
    await sm2Leaf(env.db, env.decks, dueCards: 3);
    await _pump(tester, env);
    expect(
      find.text(
        _en.reminderPreviewQuoted(
          _en.reminderBody(_en.reminderDueCards(3), 'Korean'),
        ),
      ),
      findsOneWidget,
    );
  });

  libraryTest('nothing due: the preview says the reminder stays silent', (
    tester,
    env,
  ) async {
    await _pump(tester, env);
    expect(find.text(_en.reminderPreviewNothingDue), findsOneWidget);
  });

  libraryTest('a failed read shows the neutral line', (tester, env) async {
    final s = await _pump(
      tester,
      env,
      overrides: [
        reminderPreviewDigestProvider.overrideWith(
          (ref) async => throw StateError('db'),
        ),
      ],
    );
    expect(find.text(_en.reminderPreviewNothingDue), findsOneWidget);
    expect(find.byType(MxErrorState), findsNothing);
    await _toggle(tester);
    expect(s.platform.calls, contains(PlatformCall.schedule));
  });
```

- [ ] **Step 6: Implement the section** as a `ConsumerWidget`:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final digest = ref.watch(reminderPreviewDigestProvider);
    final label = switch (digest) {
      AsyncData(:final value?) => l10n.reminderPreviewQuoted(
        _sentence(l10n, value),
      ),
      // Loading keeps the row's place; nothing due or a failed read says
      // the reminder would stay silent (BR-REMINDER-003).
      AsyncLoading() => '',
      _ => l10n.reminderPreviewNothingDue,
    };
    return MxSection(
      title: l10n.reminderPreviewTitle,
      children: [
        MxSettingsRow(label: label, subtitle: l10n.reminderPreviewHint),
      ],
    );
  }

  /// The notification's own sentence (reminder_notification_mapper.dart),
  /// built from the same strings.
  static String _sentence(AppLocalizations l10n, ReminderDigest digest) {
    final due = l10n.reminderDueCards(digest.dueCount);
    if (digest.otherDeckCount == 0) {
      return l10n.reminderBody(due, digest.deckName);
    }
    return l10n.reminderBodyWithOthers(
      due,
      digest.deckName,
      l10n.reminderOtherDecks(digest.otherDeckCount),
    );
  }
```

Delete `_sampleDue` and `_sampleOtherDecks`; update the class doc ("…over the live workload, as the notification reads it").

- [ ] **Step 7: Goldens.** The reminder golden fixture has no due cards, so `reminder_on`/`reminder_off` now show the nothing-due line; add `reminder_preview_due_{theme}` seeding one root deck with due cards so the quoted sentence stays covered.

- [ ] **Step 8: Run** `flutter test test/features/reminders/ --exclude-tags golden` → PASS. `grep -rn reminderPreviewDeck lib test` → nothing.

- [ ] **Step 9: Commit** `fix(reminders): the preview says what today's notification would say`.

### Task 11: Export final states and the unset-deck FAB

**Files:**
- Modify: `lib/features/transfer/presentation/widgets/overlays/card_export_sheet_widget.dart:113-121`, `lib/features/deck/presentation/screens/deck_level_screen.dart:356-364`
- Test: `test/features/transfer/presentation/card_export_sheet_test.dart`, `test/features/deck/presentation/open_deck_screen_test.dart`

**Interfaces:**
- Consumes: `expectOnePrimaryPerDecision` (Task 5).

- [ ] **Step 1: Write the failing tests.** In `card_export_sheet_test.dart`, in `'a selection with a card gone meanwhile exports nothing (E6)'` add after the stale title:

```dart
    // A final problem leaves nothing to choose (critique 2026-09-30).
    for (final row in tester.widgetList<MxOptionRow>(find.byType(MxOptionRow))) {
      expect(row.onSelected, isNull);
    }
    expectOnePrimaryPerDecision(tester);
```

Leave the M3-C1 tone assertion as it is (R8). In `open_deck_screen_test.dart`, in the test that shows the unset buttons (around line 120), add `expect(find.byType(MxFab), findsNothing); expectOnePrimaryPerDecision(tester);`; in a deck-with-sub-decks test, assert the FAB is still found.

- [ ] **Step 2: Run** both files → FAIL.

- [ ] **Step 3: Implement export.** `onSelected: state.isPreparing || (problem?.isFinal ?? false) ? null : () => _sheet(ref).chooseFormat(format),` (hoist `final isFinal = problem?.isFinal ?? false;` above the `Column`).

- [ ] **Step 4: Implement the FAB.** In the `fab:` switch add, before the generic case:

```dart
        // An unset deck's empty state offers New card and New sub-deck
        // itself (ruling R9, amending P4a-L9).
        DeckContentType.unset => null,
```

- [ ] **Step 5: Run** `flutter test test/features/transfer/presentation/ test/features/deck/presentation/ --exclude-tags golden` → PASS.

- [ ] **Step 6: Commit** `fix(ui): export's final states lock the formats; an unset deck has no FAB`.

### Task 12: Records

**Files:**
- Modify: `DESIGN.md`, `.impeccable/design.json` (only if it lists derived colours), `docs/shared/ui/screen-handoff/{01-deck-list,07-card-list,11-card-import,12-card-export,13-study-home,14-study-entry,23-settings,24-daily-reminder,27-sync}.md`, `docs/superpowers/plans/2026-09-24-library-phase-4a-card-editor.md` (P4a-L9 row), `docs/wbs_FE.md`

- [ ] **Step 1: DESIGN.md.** Under "The One Indigo Rule" add the banner/notice/footer sentence of spec §4.5. In Components: `MxOptionRow` ("the selected row and a row's reason are never dimmed"), `MxSettingsRow` ("disabled dims tile, label and control, never the subtitle; `isAction` rows show no chevron"), `MxErrorState` ("alert glyph by default; cloud-off only for a network failure"), `MxButton` outline ("edge `outlineEdge`: dark pulls outline 25% toward onSurface, 3:1 on page, sheet and warning ground; light `outlineVariant`"). If the frontmatter or `design.json` enumerates derived colours, add `outlineEdge` there.

- [ ] **Step 2: Detail files.** For each screen touched, update layout, states and goldens tables, rulings (cite spec part 1 and R4, R8, R9) and copy: 27 (tones, "No other changes waiting", the refused message, the Keep dialog and its golden), 14 (footer outline under resume), 13 (Details outline), 07 (search hides the summary), 11 (sample cell; headerless golden), 24 (live preview, nothing-due line, new golden; drop the sample wording), 12 (final states lock the formats), 01 (no FAB on an unset deck), 23 (Reset row is an action row).

- [ ] **Step 3: P4a-L9.** Append to the row: "Amended 2026-09-30 (critique part 1, R9): an unset deck has no FAB."

- [ ] **Step 4: WBS.** Add a line to `docs/wbs_FE.md` for "Critique 2026-09-30 part 1" with the spec and plan paths.

- [ ] **Step 5: Commit** `docs: record critique part 1 in DESIGN.md, the screen records and the WBS`.

### Task 13: Goldens, gates, review

- [ ] **Step 1: Regenerate goldens.** `flutter test --tags golden --update-goldens`. Then `git status --short test | grep goldens` and check the list is only: error-state screens (glyph), dark screens with an outline button, 01 unset, 07 search, 11 mapping (+ new headerless), 12 stale/empty, 13 sync stale/rejected, 14 resume, 23 loaded (no Reset chevron), 24 (all states with the preview, + new due), 27 rejected (+ new keep dialog), 02 locked, 14 eight_box (reason ink). Anything else is a regression: stop and investigate with superpowers:systematic-debugging.

- [ ] **Step 2: Gates.** `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `bash .claude/skills/flutter-architecture/scripts/check_architecture.sh`, `flutter test`, `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`. All pass before continuing.

- [ ] **Step 3: Commit** `test(goldens): regenerate for critique part 1`.

- [ ] **Step 4: Impeccable after the build.** Run `/impeccable critique` and `/impeccable audit` on the changed goldens against `DESIGN.md`; fix everything found in one batch, confirm once (CLAUDE.md step 5).

- [ ] **Step 5: Critique snapshot.** In `.impeccable/critique/2026-09-30T02-47-36Z__docs-shared-ui-screen-handoff-00-index-md.md`, mark priority issues 1–5 and S1–S5 as fixed with the commit hashes.

- [ ] **Step 6: Golden review page.** Build the Before · After · Diff page with the `golden-compare` skill (scratchpad and claude.ai only, never the repo) and give the owner its link with the request to review.

- [ ] **Step 7: Whole-branch review** (superpowers:requesting-code-review), then superpowers:finishing-a-development-branch.
