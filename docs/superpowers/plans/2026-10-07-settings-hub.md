# Settings hub Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the Settings tab into a one-screen hub of five groups and move the study rows and the admin rows onto two new group pages, `/settings/study` (screen 23a) and `/settings/admin` (screen 23b), without changing how any setting is saved.

**Architecture:** `SettingsScreen` keeps only navigation rows and the Reset action row, and takes two account slots (a row and a banner) instead of a whole section. `StudyDefaultsScreen` hosts the existing stepper, tray, toggle and language rows in two sections with their own notes and owns their toasts. `AdminScreen` hosts the three admin row widgets `app/` already composes, behind the existing admin gate. Routes, copy, goldens and docs follow; no provider, use case, repository or schema changes.

**Tech Stack:** Flutter 3.47, Riverpod 3 codegen, go_router, the `Mx*` shared widgets (`MxSection`, `MxSettingsRow`, `MxAppBar`, `MxScreenScroll`), ARB l10n, golden tests through `run_goldens.sh`.

**Spec:** `docs/superpowers/specs/2026-10-07-settings-hub-design.md`

## Global Constraints

- Leaf paths do not move: `/settings/theme`, `/settings/language`, `/settings/reminder`, `/settings/sync`, `/settings/sign-in`, `/settings/account`, `/settings/monitoring` (+ log child), `/settings/users` stay (spec D5). Only `/settings/study` and `/settings/admin` are added.
- No wide control and no toggle on the hub; hub rows name the current value in the subtitle (spec §4).
- Saving behaviour, the 600 ms settle, BR-SETTINGS-007 one transaction per change, E1–E3 and the reset dialog are unchanged (spec §7). `SettingsController` is not modified.
- Copy keys exactly as spec §6; en and vi both; `settingsStudyDefaultsNote` removed. Every new ARB key carries `placeholders` (when any) then `description`, in that order (guard `memox.i18n.arb_entry_needs_description`).
- Design tokens only (`AppSpacing`, `AppIcons`, `context.textStyles`, theme colours); the guard's `memox.design_token.*` rules run on every edit.
- Feature boundaries (`test/architecture/boundary_rules.dart`): `settings` may not import `account` or `monitoring` presentation; `app/` composes their widgets into the Settings pages as slots, as it does today.
- Tests run bundled: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh <files>`; goldens only through `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh [--update]` (Linux container). The gate is `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`.
- Commit messages end with the two attribution lines this session uses (`Co-Authored-By` and `Claude-Session`).
- Owner questions go through `AskUserQuestion`; no question is needed inside this plan unless a task's assumption below turns out false.

## Review Focus

1. **A deep link to `/settings/monitoring` or `/settings/users` with no Admin page on the stack:** Back must return to the hub, not crash or land on an empty route (Task 3 route test "deep link to Monitoring returns to the hub").
2. **A build without Supabase (no account coordinator, no sync status):** the hub shows Study, App and Reset only, with no empty "Account & sync" overline (Task 2 test "no Account & sync section without Supabase").
3. **A read failure while on 23a:** the page shows `MxErrorState` with Retry and no value, exactly as the hub did (Task 1 test "a failed read on the Study defaults page").
4. **The Study row's summary at 360dp in Vietnamese** ("20 thẻ · Theo thứ tự tạo · Đọc to bật"): two lines at most, nothing clipped. No golden runs in Vietnamese, so Task 1's hub test asserts the row's `Text` has no `maxLines` (it may wrap, never clip) and the owner checks the line on the golden-compare page (Task 4 step 5).
5. **An account that becomes admin while the hub is open:** the Admin row appears without a restart and disappears when the confirmation is lost (Task 3 test moved from `monitoring_entry_section_test.dart`).

---

## File structure

| File | Responsibility |
|---|---|
| `lib/app/router/app_routes.dart` | + `settingsStudyChild/settingsStudy`, `settingsAdminChild/settingsAdmin` |
| `lib/app/router/app_router.dart` | Hub callbacks; two new child routes on the root navigator |
| `lib/app/router/account_routes.dart` | `accountSettingsRow(context)` and `accountSettingsBanner(context)` replace `accountSettingsSection` |
| `lib/app/router/admin_routes.dart` | `adminRoute(rootNavigator)` builds the gated `AdminScreen`; `adminSettingsRows` becomes two lists (logs, people) |
| `lib/features/settings/presentation/screens/settings_screen.dart` | The hub (23): five groups, slots, reset toasts |
| `lib/features/settings/presentation/screens/study_defaults_screen.dart` | New, 23a: Session and Speech sections, study toasts |
| `lib/features/settings/presentation/screens/admin_screen.dart` | New, 23b: Logs and People sections from slots |
| `lib/features/settings/presentation/widgets/sections/settings_session_section_widget.dart` | New: Cards per session + New-card order + note (from the old study defaults section) |
| `lib/features/settings/presentation/widgets/sections/settings_speech_section_widget.dart` | New: Read the term aloud + Speech language + note (from the old study defaults section) |
| `lib/features/settings/presentation/widgets/sections/settings_study_defaults_section_widget.dart` | Deleted (split into the two above) |
| `lib/features/settings/presentation/widgets/items/settings_sync_row_widget.dart` | Renamed from `sections/settings_sync_section_widget.dart`; the row only, no `MxSection` |
| `lib/features/settings/presentation/widgets/items/settings_study_summary_widget.dart` | New: `studyDefaultsSummary(l10n, options, isAutoPlay)` for the hub's Study row |
| `lib/features/settings/presentation/widgets/sections/settings_skeleton_widget.dart` | `rowsPerSection` parameter |
| `lib/features/account/presentation/widgets/items/account_settings_row_widget.dart` | New: the account row (Sign in / email), or nothing without a coordinator |
| `lib/features/account/presentation/widgets/sections/account_settings_banner_widget.dart` | New: the re-auth banner with 16 below, or nothing |
| `lib/features/account/presentation/widgets/sections/account_settings_section_widget.dart` | Deleted |
| `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` | Spec §6 keys |
| `test/features/settings/presentation/settings_screen_test.dart` | Hub tests only |
| `test/features/settings/presentation/study_defaults_screen_test.dart` | New: the moved study tests |
| `test/features/settings/presentation/admin_screen_test.dart` | New: the admin page |
| `test/features/monitoring/presentation/monitoring_entry_section_test.dart` | Deleted (its cases move to the two files above) |
| `test/features/settings/presentation/settings_sync_section_test.dart` | Builds the hub with the new slots |
| `test/app/settings_routes_test.dart`, `test/app/account_routes_test.dart` | New routes, Users via the Admin page |
| `test/features/settings/presentation/settings_screen_golden_test.dart` | Hub states |
| `test/features/settings/presentation/study_defaults_golden_test.dart` | New: 23a states |
| `test/features/settings/presentation/admin_golden_test.dart` | New: 23b |
| `test/features/account/presentation/account_golden_test.dart`, `account_manage_golden_test.dart`, `users_golden_test.dart` | New slots; the admin-rows golden leaves `users_golden_test.dart` |
| `test/visual_audit/screens/features/settings/screens/{settings,study_defaults,admin}_screen_visual_audit_test.dart` | Hub + two new audits |
| `DESIGN.md`, handoffs 23/23a/23b, `00-index.md`, `navigation.md`, UC-SETTINGS-001, settings README | Spec §9 |

---

### Task 1: Routes, the Study defaults page (23a) and the hub's Study row

**Files:**
- Modify: `lib/app/router/app_routes.dart`
- Modify: `lib/app/router/app_router.dart` (the Settings branch, lines ~250–290)
- Create: `lib/features/settings/presentation/screens/study_defaults_screen.dart`
- Create: `lib/features/settings/presentation/widgets/sections/settings_session_section_widget.dart`
- Create: `lib/features/settings/presentation/widgets/sections/settings_speech_section_widget.dart`
- Create: `lib/features/settings/presentation/widgets/items/settings_study_summary_widget.dart`
- Delete: `lib/features/settings/presentation/widgets/sections/settings_study_defaults_section_widget.dart`
- Modify: `lib/features/settings/presentation/widgets/sections/settings_skeleton_widget.dart`
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Create: `test/features/settings/presentation/study_defaults_screen_test.dart`
- Modify: `test/features/settings/presentation/settings_screen_test.dart`
- Modify: `test/app/settings_routes_test.dart`
- Modify: `test/visual_audit/screens/features/settings/screens/settings_screen_visual_audit_test.dart`; create `study_defaults_screen_visual_audit_test.dart` beside it

**Interfaces:**
- Produces: `AppRoutes.settingsStudy == '/settings/study'`; `StudyDefaultsScreen()` (const, no parameters); `SettingsScreen` gains `required VoidCallback onOpenStudyDefaults` and loses `SettingsStudyDefaultsSectionWidget`; `SettingsSkeletonWidget({required semanticLabel, List<int> rowsPerSection = hubRows})` with `static const hubRows = [2, 1, 3, 1]` and `static const studyRows = [2, 2]`; `String studyDefaultsSummary(AppLocalizations l10n, StudyOptions options, {required bool isAutoPlay})`.
- Consumes: `SettingsController`, `appSettingsProvider`, `MxStepper`, `MxSegmentedTray`, `MxToggle`, `showSpeechLanguageSheet` as they are today.

- [ ] **Step 1: Add the copy (en, then vi)**

In `lib/l10n/app_en.arb`, replace the `settingsStudyDefaultsNote` entry (key + `@` block) with these, and keep `settingsStudyDefaults`:

```json
  "settingsStudySection": "Study",
  "@settingsStudySection": {
    "description": "Settings hub (screen 23): the overline of the group whose one row opens Study defaults (settings hub spec §5.1)."
  },
  "settingsStudyDefaultsSummary": "{count} cards · {order} · Read aloud {isAutoPlay, select, true{on} other{off}}",
  "@settingsStudyDefaultsSummary": {
    "placeholders": {
      "count": {
        "type": "int"
      },
      "order": {
        "type": "String"
      },
      "isAutoPlay": {
        "type": "String"
      }
    },
    "description": "Settings hub: the Study defaults row's subtitle, the stored defaults in one line (settings hub spec D8). order is the rendered In order / Random."
  },
  "settingsSessionSection": "Session",
  "@settingsSessionSection": {
    "description": "Study defaults (screen 23a): the overline over Cards per session and New-card order."
  },
  "settingsSessionNote": "Apply to sessions started from now on. A deck with its own study options keeps them.",
  "@settingsSessionNote": {
    "description": "Study defaults (screen 23a): the note under the Session section (BR-SETTINGS-004)."
  },
  "settingsSpeechSection": "Speech",
  "@settingsSpeechSection": {
    "description": "Study defaults (screen 23a): the overline over Read the term aloud and Speech language."
  },
  "settingsSpeechNote": "Changes at once. A deck with its own speech language keeps it.",
  "@settingsSpeechNote": {
    "description": "Study defaults (screen 23a): the note under the Speech section (BR-STUDY-080, BR-SETTINGS-009)."
  },
```

In `lib/l10n/app_vi.arb`, replace `settingsStudyDefaultsNote` with:

```json
  "settingsStudySection": "Học",
  "settingsStudyDefaultsSummary": "{count} thẻ · {order} · Đọc to {isAutoPlay, select, true{bật} other{tắt}}",
  "settingsSessionSection": "Phiên học",
  "settingsSessionNote": "Áp dụng cho các phiên bắt đầu từ bây giờ. Bộ thẻ có tuỳ chọn học riêng vẫn giữ tuỳ chọn đó.",
  "settingsSpeechSection": "Đọc to",
  "settingsSpeechNote": "Đổi ngay. Bộ thẻ có ngôn ngữ đọc riêng vẫn giữ ngôn ngữ đó.",
```

Run: `flutter gen-l10n` then `grep -c settingsStudyDefaultsSummary lib/l10n/generated/app_localizations_en.dart` → `1`.

- [ ] **Step 2: Routes**

In `lib/app/router/app_routes.dart`, after the `settingsSyncChild` pair:

```dart
  /// Study defaults (screen 23a, settings hub spec D1), relative to
  /// [settings], on the root navigator like Theme.
  static const String settingsStudyChild = 'study';
  static const String settingsStudy = '$settings/$settingsStudyChild';

  /// Admin (screen 23b, settings hub spec D4), relative to [settings], on
  /// the root navigator, behind the admin gate.
  static const String settingsAdminChild = 'admin';
  static const String settingsAdmin = '$settings/$settingsAdminChild';
```

- [ ] **Step 3: Split the study defaults section into two section widgets**

Create `settings_session_section_widget.dart`: copy `SettingsStudyDefaultsSectionWidget` and keep only the "Cards per session" and "New-card order" rows; constructor `({required StudyOptions stored})`; `MxSection(title: l10n.settingsSessionSection, note: l10n.settingsSessionNote, children: [...])`. Class name `SettingsSessionSectionWidget`. Doc comment: `/// Screen 23a's Session section (settings hub spec §5.2): the card limit by −/+, a hold or typing, and the new-card order, each saved on change (FE-A3 D1, D6).`

Create `settings_speech_section_widget.dart`: the "Read the term aloud" and "Speech language" rows; constructor `({required StudyOptions stored, required bool isSpeechAutoPlay})`; `MxSection(title: l10n.settingsSpeechSection, note: l10n.settingsSpeechNote, children: [...])`. Class name `SettingsSpeechSectionWidget`. Keep the `showSpeechLanguageSheet(context, selected:, speech: ref.read(speechSynthesizerProvider))` call and the `_controller(ref)` helper verbatim.

Delete `settings_study_defaults_section_widget.dart`.

- [ ] **Step 4: The summary helper**

Create `lib/features/settings/presentation/widgets/items/settings_study_summary_widget.dart`:

```dart
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The hub's Study defaults row in one line (settings hub spec D8):
/// "20 cards · In order · Read aloud on".
String studyDefaultsSummary(
  AppLocalizations l10n,
  StudyOptions options, {
  required bool isAutoPlay,
}) => l10n.settingsStudyDefaultsSummary(
  options.cardLimit,
  switch (options.newCardOrder) {
    NewCardOrder.created => l10n.settingsOrderCreated,
    NewCardOrder.random => l10n.settingsOrderRandom,
  },
  isAutoPlay.toString(),
);
```

- [ ] **Step 5: The skeleton takes its shape**

In `settings_skeleton_widget.dart` replace the fixed `_rowsPerSection` with a parameter:

```dart
  const SettingsSkeletonWidget({
    super.key,
    required this.semanticLabel,
    this.rowsPerSection = hubRows,
  });

  final String semanticLabel;

  /// One entry per section card, the rows it holds.
  final List<int> rowsPerSection;

  /// The hub's shape: Account & sync, Study, App, Reset (spec §5.1).
  static const List<int> hubRows = [2, 1, 3, 1];

  /// Screen 23a's shape: Session, Speech (spec §5.2).
  static const List<int> studyRows = [2, 2];
```

and use `rowsPerSection` in the loop. Update the doc comment: `/// A settings page loading as its sections: cards of rows on one pulse (critique 2026-09-30 part 3d-2, E12).`

- [ ] **Step 6: The Study defaults screen**

Create `lib/features/settings/presentation/screens/study_defaults_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/states/settings_state.dart';
import 'package:memox/features/settings/presentation/widgets/sections/settings_session_section_widget.dart';
import 'package:memox/features/settings/presentation/widgets/sections/settings_skeleton_widget.dart';
import 'package:memox/features/settings/presentation/widgets/sections/settings_speech_section_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 23a, Study defaults (settings hub spec §5.2; UC-SETTINGS-001
/// step 2): the app-wide study defaults in two sections, each saved on
/// change (FE-A3 D1). Every value shown is the persisted one, or the card
/// limit being changed (BR-SETTINGS-001).
class StudyDefaultsScreen extends ConsumerWidget {
  const StudyDefaultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.listen(
      settingsControllerProvider.select((state) => state.notice),
      (_, notice) => _say(context, ref, notice),
    );
    final settings = ref.watch(appSettingsProvider);
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.settingsStudyDefaults,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: switch (settings) {
        AsyncData(:final value) => MxScreenScroll(
          children: [
            SettingsSessionSectionWidget(stored: value.studyDefaults),
            SettingsSpeechSectionWidget(
              stored: value.studyDefaults,
              isSpeechAutoPlay: value.isSpeechAutoPlay,
            ),
          ],
        ),
        AsyncError(:final isLoading) => MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.settingsLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(appSettingsProvider),
              isRetrying: isLoading,
            ),
          ],
        ),
        _ => MxScreenScroll(
          children: [
            SettingsSkeletonWidget(
              semanticLabel: l10n.commonLoading,
              rowsPerSection: SettingsSkeletonWidget.studyRows,
            ),
          ],
        ),
      },
    );
  }

  /// The toasts of the four study rows (settings hub spec D9); the hub
  /// says the reset's.
  void _say(BuildContext context, WidgetRef ref, SettingsNotice? notice) {
    if (notice == null) return;
    final l10n = context.l10n;
    void retry() => unawaited(
      ref.read(settingsControllerProvider.notifier).retry(notice.kind),
    );
    final stored = ref.read(appSettingsProvider).value?.studyDefaults;
    final message = switch ((notice, notice.kind)) {
      (SettingsSaved(), SettingsSubmit.cardLimit) => l10n.settingsSaved,
      (SettingsSaved(), SettingsSubmit.newCardOrder) => l10n.settingsSaved,
      (SettingsSaved(), SettingsSubmit.speechLanguage) => l10n.settingsSaved,
      (SettingsSaved(), SettingsSubmit.speechAutoPlay) => l10n.settingsSaved,
      (SettingsSaveFailed(), SettingsSubmit.cardLimit) when stored != null =>
        l10n.settingsCardLimitSaveFailed(stored.cardLimit),
      (SettingsSaveFailed(), SettingsSubmit.newCardOrder) =>
        l10n.settingsOrderSaveFailed,
      (SettingsSaveFailed(), SettingsSubmit.speechLanguage) =>
        l10n.settingsSpeechLanguageSaveFailed,
      (SettingsSaveFailed(), SettingsSubmit.speechAutoPlay) =>
        l10n.settingsSpeechAutoPlaySaveFailed,
      _ => null,
    };
    if (message == null) return;
    final canRetry = notice is SettingsSaveFailed;
    showMxSnackbar(
      context,
      message: message,
      actionLabel: canRetry ? l10n.commonRetry : null,
      onAction: canRetry ? retry : null,
    );
  }
}
```

- [ ] **Step 7: The hub's Study row and its `_say`**

In `settings_screen.dart`: add `required this.onOpenStudyDefaults` (`final VoidCallback onOpenStudyDefaults;`, doc `/// Opens screen 23a (settings hub spec D2).`). Replace `SettingsStudyDefaultsSectionWidget(...)` with:

```dart
            MxSection(
              title: l10n.settingsStudySection,
              children: [
                MxSettingsRow(
                  label: l10n.settingsStudyDefaults,
                  subtitle: studyDefaultsSummary(
                    l10n,
                    value.studyDefaults,
                    isAutoPlay: value.isSpeechAutoPlay,
                  ),
                  icon: AppIcons.library,
                  onTap: onOpenStudyDefaults,
                ),
              ],
            ),
```

Import `settings_study_summary_widget.dart`; drop the study defaults section import. In `_say`, delete the eight `cardLimit`/`newCardOrder`/`speechLanguage`/`speechAutoPlay` cases and the `stored` line, keep the two `reset` cases; update the comment to `/// The reset's toasts (settings hub spec D9); Study defaults says its own.` Update the class doc comment to: `/// Screen 23, the Settings tab (UC-SETTINGS-001): the hub of the Settings area (settings hub spec §5.1): Account & sync, Study, App, Admin and Reset, each row naming its value and opening its page.`

- [ ] **Step 8: Router**

In `app_router.dart`, the Settings `GoRoute` builder gains `onOpenStudyDefaults: () => context.push(AppRoutes.settingsStudy),` and the children list gains, after the Theme route:

```dart
                  GoRoute(
                    path: AppRoutes.settingsStudyChild,
                    parentNavigatorKey: rootNavigator,
                    builder: (context, state) => const StudyDefaultsScreen(),
                  ),
```

Import `study_defaults_screen.dart`.

- [ ] **Step 9: Move the study tests**

Create `test/features/settings/presentation/study_defaults_screen_test.dart` with the same imports as `settings_screen_test.dart` plus `study_defaults_screen.dart`, `_en`, `_valueKey`, `_storedLimit`, and `Widget _screen() => const StudyDefaultsScreen();`. Move these tests from `settings_screen_test.dart` unchanged except that `_screen()` takes no arguments and every `scrollUntilVisible(find.text(_en.settingsResetRow), 200)` line is deleted (there is no Reset row on 23a):

- "steps settle into one save, then "Saved" (D1)"
- "while the limit writes, the stepper spins and the order stays usable (saving)"
- "a typed 250 is refused under the stepper and saves nothing (E1)"
- "a failed save names the kept value and Retry saves it (E2)"
- "Study defaults show the read-aloud switch and the default language"
- "the speech language row opens the sheet; a pick saves and shows its name (BR-SETTINGS-009)"
- "the read-aloud toggle saves on change (BR-SETTINGS-010)"
- "a failed speech save says so, and Retry writes it (UC-SETTINGS-001 E2)"
- "a saved speech language says "Saved", as the other rows do"

Add two new tests to the new file:

```dart
  libraryTest('the two sections carry their own notes (settings hub spec '
      'D3)', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen());

    expect(find.text(_en.settingsSessionSection.toUpperCase()), findsOneWidget);
    expect(find.text(_en.settingsSpeechSection.toUpperCase()), findsOneWidget);
    expect(find.text(_en.settingsSessionNote), findsOneWidget);
    expect(find.text(_en.settingsSpeechNote), findsOneWidget);
  });

  libraryTest('a failed read on the Study defaults page shows the error '
      'with Retry and no value (E3)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [
        appSettingsProvider.overrideWith(
          (ref) => Stream.error(FlakySettingsRepository.failure),
        ),
      ],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.byKey(_valueKey), findsNothing);
  });
```

- [ ] **Step 10: Adjust the hub tests**

In `settings_screen_test.dart`: `_screen` gains `VoidCallback? onOpenStudyDefaults` → `onOpenStudyDefaults: onOpenStudyDefaults ?? () {}`. Rewrite the first test:

```dart
  libraryTest('the hub names every group and value: Study summary, Theme, '
      'reminder, Reset (settings hub spec §5.1)', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen());

    // Section titles show in capitals; their semantics keep the words.
    expect(find.text(_en.settingsStudySection.toUpperCase()), findsOneWidget);
    expect(find.text(_en.settingsApp.toUpperCase()), findsOneWidget);
    expect(find.text(_en.settingsReset.toUpperCase()), findsOneWidget);
    expect(
      find.text(
        _en.settingsStudyDefaultsSummary(20, _en.settingsOrderCreated, 'true'),
      ),
      findsOneWidget,
    );
    expect(find.text(_en.settingsThemeFollowsSystem), findsOneWidget);
    expect(find.text(_en.settingsReminderOff), findsOneWidget);
    expect(find.text(_en.settingsResetRow), findsOneWidget);
    expect(find.byKey(_valueKey), findsNothing, reason: 'no stepper on the hub');
    // The summary may wrap, never clip (review focus 4).
    final summary = tester.widget<Text>(
      find.text(
        _en.settingsStudyDefaultsSummary(20, _en.settingsOrderCreated, 'true'),
      ),
    );
    expect(summary.maxLines, isNull);
  });

  libraryTest('the Study defaults row opens screen 23a and reflects a '
      'stored change (D8)', (tester, env) async {
    await tester.runAsync(
      () => SettingsRepositoryImpl(env.db).saveStudyDefaults(
        cardLimit: 35,
        newCardOrder: NewCardOrder.random,
      ),
    );
    await tester.runAsync(
      () => SettingsRepositoryImpl(env.db).setSpeechAutoPlay(isOn: false),
    );
    var opened = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(onOpenStudyDefaults: () => opened++),
    );

    expect(
      find.text(
        _en.settingsStudyDefaultsSummary(35, _en.settingsOrderRandom, 'false'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text(_en.settingsStudyDefaults));
    expect(opened, 1);
  });
```

In the loading test change `findsNWidgets(3)` to `findsNWidgets(4)` (the hub's four cards) and drop the `find.byKey(_valueKey)` line. In the reset tests delete every `scrollUntilVisible(find.text(_en.settingsResetRow), 200)` and the `drag(... Offset(0, -300))` lines: the hub fits. Remove the moved tests and the now-unused imports (`speech_providers`, `speech_language`, `mx_bottom_sheet`, `mx_toggle`, `mx_spinner`, `fake_speech_synthesizer`, `cardLimitSettle` if unused). Keep "Reset asks first…", "the Theme row names a fixed choice…", "the Theme and Language rows open their pages", "the reminder row…", "a failed read…", "reset runs the reset app/ composed…".

- [ ] **Step 11: Route test**

In `test/app/settings_routes_test.dart` add after the Theme/Language loop:

```dart
  libraryTest('the Study defaults row opens screen 23a above the shell; '
      'Back returns (settings hub spec D1)', (tester, env) async {
    await pumpMemoxApp(tester, env);
    await _tap(tester, _tab(_en.navSettings));

    await _tap(tester, find.text(_en.settingsStudyDefaults));
    expect(find.byType(StudyDefaultsScreen), findsOneWidget);
    expect(_barTitle(_en.settingsStudyDefaults), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);

    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(find.byType(StudyDefaultsScreen), findsNothing);
    expect(_barTitle(_en.navSettings), findsOneWidget);
  });
```

Remove the `ensureVisible` lines added on 2026-10-07 in the Theme/Language loop (the hub fits; keep the test otherwise). Import `study_defaults_screen.dart`.

- [ ] **Step 12: Visual audits**

`settings_screen_visual_audit_test.dart`: add `onOpenStudyDefaults: () {},`. Create `study_defaults_screen_visual_audit_test.dart` as a copy of `theme_screen_visual_audit_test.dart` with `screen: StudyDefaultsScreen` and `const StudyDefaultsScreen()`.

- [ ] **Step 13: Run, format, analyze**

```bash
dart format lib test
dart analyze lib test
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/settings/presentation test/app/settings_routes_test.dart test/visual_audit/screens/features/settings
```
Expected: analyze clean; all pass except the golden tests, which are not in these bundles (Task 5), and `settings_sync_section_test.dart`, `account`/`users` golden tests, `monitoring_entry_section_test.dart`, `account_routes_test.dart`, which still compile against the old `accountSection`/`adminRows` parameters (Tasks 2 and 3 fix them; they are not in this bundle). If `run_tests.sh` bundles a failing-to-compile file, run the three settings test files by name instead.

- [ ] **Step 14: Commit**

```bash
git add -A lib test
git commit -m "Settings hub: Study defaults page (23a) and the hub's Study row

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018UmUaGtGmYdc1ei6GLyTKb"
```

---

### Task 2: The hub's Account & sync section and the account slots

**Files:**
- Create: `lib/features/account/presentation/widgets/items/account_settings_row_widget.dart`
- Create: `lib/features/account/presentation/widgets/sections/account_settings_banner_widget.dart`
- Delete: `lib/features/account/presentation/widgets/sections/account_settings_section_widget.dart`
- Rename: `lib/features/settings/presentation/widgets/sections/settings_sync_section_widget.dart` → `lib/features/settings/presentation/widgets/items/settings_sync_row_widget.dart`
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`
- Modify: `lib/app/router/account_routes.dart`, `lib/app/router/app_router.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Modify: `test/features/settings/presentation/settings_sync_section_test.dart`, `test/features/settings/presentation/settings_screen_test.dart`, `test/features/account/presentation/account_golden_test.dart`, `test/features/account/presentation/account_manage_golden_test.dart`

**Interfaces:**
- Produces: `AccountSettingsRowWidget({required onSignIn, required onOpenAccount})` (renders nothing without a coordinator); `AccountSettingsBannerWidget({required onSignIn})` (the re-auth banner with 16 below, else nothing); `SettingsSyncRowWidget({required status, required now, required onOpenSync})`; `SettingsScreen` parameters `Widget? accountRow`, `Widget? accountBanner` replace `Widget? accountSection`; `accountSettingsRow(BuildContext)` and `accountSettingsBanner(BuildContext)` in `account_routes.dart`.
- Consumes: Task 1's `SettingsScreen`.

- [ ] **Step 1: Copy**

`app_en.arb`, before `"settingsApp"`:

```json
  "settingsAccountSync": "Account & sync",
  "@settingsAccountSync": {
    "description": "Settings hub (screen 23): the overline over the account row and the Sync row (settings hub spec D2)."
  },
```

`app_vi.arb`, before `"settingsApp"`: `"settingsAccountSync": "Tài khoản & đồng bộ",`. Run `flutter gen-l10n`.

- [ ] **Step 2: The account row and banner widgets**

Create `account_settings_row_widget.dart` from the row half of `AccountSettingsSectionWidget`:

```dart
/// The hub's account row (account UI spec §5.5; settings hub spec D7):
/// attach an account, or the account attached, which opens screen 32.
/// Settings draws the "Account & sync" section; `app/` puts this row in
/// it. A build that cannot sign in shows nothing.
class AccountSettingsRowWidget extends ConsumerWidget {
  const AccountSettingsRowWidget({
    super.key,
    required this.onSignIn,
    required this.onOpenAccount,
  });

  /// Opens screen 30 in its link mode.
  final VoidCallback onSignIn;

  /// Opens screen 32 (spec §5.5).
  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(accountCoordinatorProvider) == null) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final account = ref.watch(deviceAccountProvider);
    final canLink = ref.watch(canLinkProvider);
    if (account == null) {
      return MxSettingsRow(
        label: l10n.accountSignIn,
        subtitle: canLink ? l10n.accountSignInHint : l10n.accountSignInLater,
        icon: AppIcons.account,
        isEnabled: canLink,
        onTap: canLink ? onSignIn : null,
      );
    }
    return MxSettingsRow(
      label: account.email ?? l10n.accountSignedIn,
      subtitle: l10n.accountSignedInHint,
      icon: AppIcons.account,
      onTap: onOpenAccount,
    );
  }
}
```

Create `account_settings_banner_widget.dart`:

```dart
/// An expired sign-in, above the hub's "Account & sync" overline (P3b plan
/// ruling 1; settings hub spec D7): the banner with the section's gap
/// below it, or nothing.
class AccountSettingsBannerWidget extends ConsumerWidget {
  const AccountSettingsBannerWidget({super.key, required this.onSignIn});

  /// Opens screen 30 in its reauth mode.
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(authStateProvider).value is! ReauthRequired) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: AccountReauthBannerWidget(onSignIn: onSignIn),
    );
  }
}
```

Imports as in the old section widget (`account_coordinator`, `device_account`, `can_link`, `auth_state` providers; `AppIcons`; `AppSpacing`; `MxSettingsRow`; `AccountReauthBannerWidget`). Delete `account_settings_section_widget.dart`.

- [ ] **Step 3: The Sync row widget**

`git mv` the sync section file to `widgets/items/settings_sync_row_widget.dart`; rename the class `SettingsSyncRowWidget`; return the `MxSettingsRow` directly (drop the `MxSection`). Doc: `/// The hub's Sync row (SB-U1, sync status spec §5.1): names the state, tone on the tile, opens screen 27. Settings draws it in "Account & sync" (settings hub spec D2).`

- [ ] **Step 4: The hub's section**

In `settings_screen.dart` replace `this.accountSection` with `this.accountRow, this.accountBanner` (docs: `/// The account row, which app/ composes from the account feature (settings hub spec D7); null in a test without an account.` and `/// The expired sign-in banner, above the Account & sync overline; null in a test without an account.`). Replace `?accountSection,` and the Sync section. Above the `MxScreenScroll`, read the sync status once:

```dart
    // Hidden on a stream error too (sync status spec §6).
    final sync = ref.watch(syncStatusProvider);
    final syncStatus = sync is AsyncData<SyncStatus?> ? sync.value : null;
    final hasAccountSync = accountRow != null || syncStatus != null;
```

and in the children:

```dart
            ?accountBanner,
            if (hasAccountSync)
              MxSection(
                title: l10n.settingsAccountSync,
                children: [
                  ?accountRow,
                  if (syncStatus case final status?)
                    SettingsSyncRowWidget(
                      status: status,
                      now: ref.watch(dayClockProvider).now(),
                      onOpenSync: onOpenSync,
                    ),
                ],
              ),
```

Import `settings_sync_row_widget.dart` and `SyncStatus`.

- [ ] **Step 5: `app/`**

In `account_routes.dart` replace `accountSettingsSection` with:

```dart
/// The hub's account row (settings hub spec D7).
Widget accountSettingsRow(BuildContext context) => AccountSettingsRowWidget(
  onSignIn: () => unawaited(context.push(AppRoutes.settingsSignInLink)),
  onOpenAccount: () => unawaited(context.push(AppRoutes.settingsAccount)),
);

/// The expired sign-in banner above the hub's Account & sync section.
Widget accountSettingsBanner(BuildContext context) =>
    AccountSettingsBannerWidget(
      onSignIn: () => unawaited(
        context.push(AppRoutes.settingsSignInReauth(from: AppRoutes.settings)),
      ),
    );
```

In `app_router.dart`: `accountRow: accountSettingsRow(context), accountBanner: accountSettingsBanner(context),`.

- [ ] **Step 6: Tests**

`settings_sync_section_test.dart`: `_screen` adds `onOpenStudyDefaults: () {}`; every `find.text('SYNC')` or `_en.settingsSync.toUpperCase()` assertion becomes `_en.settingsAccountSync.toUpperCase()`; the test "no Sync section without Supabase" becomes:

```dart
  libraryTest('no Account & sync section without Supabase', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [
        supabaseConfigProvider.overrideWithValue(
          const SupabaseConfig(url: '', publishableKey: ''),
        ),
      ],
    );

    expect(find.text(_en.settingsAccountSync.toUpperCase()), findsNothing);
    expect(find.text(_en.settingsSync), findsNothing);
  });
```

(keep the existing override the file uses to hide Sync if it differs; the assertion is what matters). Add to `settings_screen_test.dart`:

```dart
  libraryTest('the account row and the Sync row share one section, the '
      'banner above its overline (settings hub spec D7)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      SettingsScreen(
        onOpenStudyDefaults: () {},
        onOpenTheme: () {},
        onOpenLanguage: () {},
        onOpenReminder: () {},
        resetAppOptions: () async => const Ok(null),
        onOpenSync: () {},
        accountBanner: const Text('banner'),
        accountRow: const Text('account row'),
      ),
      overrides: syncOverrides(const SyncStatus()),
    );

    expect(find.text(_en.settingsAccountSync.toUpperCase()), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('banner')).dy,
      lessThan(tester.getTopLeft(find.text(_en.settingsAccountSync.toUpperCase())).dy),
    );
    expect(
      tester.getTopLeft(find.text('account row')).dy,
      lessThan(tester.getTopLeft(find.text(_en.settingsSync)).dy),
    );
  });
```

(`syncOverrides` comes from `test/support/sync_fakes.dart`, as the golden test uses it.) `account_golden_test.dart` and `account_manage_golden_test.dart`: replace `accountSection: AccountSettingsSectionWidget(...)` with `accountRow: AccountSettingsRowWidget(onSignIn: () {}, onOpenAccount: () {}), accountBanner: AccountSettingsBannerWidget(onSignIn: () {}),` and add `onOpenStudyDefaults: () {},`; fix imports. Their goldens are regenerated in Task 5.

- [ ] **Step 7: Run and commit**

```bash
dart format lib test && dart analyze lib test
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/settings/presentation/settings_screen_test.dart test/features/settings/presentation/settings_sync_section_test.dart test/features/account/presentation/account_routes_test.dart
git add -A lib test
git commit -m "Settings hub: Account & sync section from the account row and banner slots

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018UmUaGtGmYdc1ei6GLyTKb"
```

(`account_routes_test.dart` still fails on the Users case until Task 3; run it only to see that failure alone.)

---

### Task 3: The Admin page (23b) and the hub's Admin row

**Files:**
- Create: `lib/features/settings/presentation/screens/admin_screen.dart`
- Modify: `lib/app/router/admin_routes.dart`, `lib/app/router/app_router.dart`
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Create: `test/features/settings/presentation/admin_screen_test.dart`
- Delete: `test/features/monitoring/presentation/monitoring_entry_section_test.dart`
- Modify: `test/features/settings/presentation/settings_screen_test.dart`, `test/app/account_routes_test.dart`, `test/app/settings_routes_test.dart`, `test/features/account/presentation/users_golden_test.dart`
- Create: `test/visual_audit/screens/features/settings/screens/admin_screen_visual_audit_test.dart`

**Interfaces:**
- Produces: `AdminScreen({required List<Widget> logsRows, required List<Widget> peopleRows})`; `AppRoutes.settingsAdmin`; `adminRoute(GlobalKey<NavigatorState>)` in `admin_routes.dart`; `SettingsScreen` gains `required VoidCallback onOpenAdmin` and loses `adminRows`.
- Consumes: `MonitoringEntryRowWidget`, `UsersEntryRowWidget`, `SqlLogRowWidget`, `MonitoringAdminGateWidget(title:, child:)`, `isAdminProvider`.

- [ ] **Step 1: Copy**

`app_en.arb`, after the `settingsAdmin` block:

```json
  "settingsAdminTools": "Admin tools",
  "@settingsAdminTools": {
    "description": "Settings hub (screen 23): the one Admin row, for an admin only; opens screen 23b (settings hub spec D4)."
  },
  "settingsAdminToolsHint": "Monitoring, users, SQL log",
  "@settingsAdminToolsHint": {
    "description": "Subtitle of the Admin tools row."
  },
  "settingsAdminLogs": "Logs",
  "@settingsAdminLogs": {
    "description": "Admin (screen 23b): the overline over Monitoring and Log SQL statements."
  },
  "settingsAdminPeople": "People",
  "@settingsAdminPeople": {
    "description": "Admin (screen 23b): the overline over Users."
  },
```

`app_vi.arb` after `settingsAdmin`: `"settingsAdminTools": "Công cụ quản trị", "settingsAdminToolsHint": "Giám sát, người dùng, log SQL", "settingsAdminLogs": "Nhật ký", "settingsAdminPeople": "Người dùng",` (one key per line). `flutter gen-l10n`.

- [ ] **Step 2: Failing tests for the page**

Create `test/features/settings/presentation/admin_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/presentation/screens/admin_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/library_harness.dart';

// Settings hub spec §5.3: the admin rows the features supply, in Logs and
// People; the gate is the router's (Task 3 route tests).

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('Logs holds Monitoring and the SQL switch, People holds Users, '
      'in that order', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const AdminScreen(
        logsRows: [Text('Monitoring'), Text('Log SQL statements')],
        peopleRows: [Text('Users')],
      ),
    );

    expect(find.text(_en.settingsAdmin), findsOneWidget); // the title
    expect(find.text(_en.settingsAdminLogs.toUpperCase()), findsOneWidget);
    expect(find.text(_en.settingsAdminPeople.toUpperCase()), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Monitoring')).dy,
      lessThan(tester.getTopLeft(find.text('Log SQL statements')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Log SQL statements')).dy,
      lessThan(tester.getTopLeft(find.text('Users')).dy),
    );
    expect(find.byTooltip(_en.commonBack), findsOneWidget);
  });
}
```

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/settings/presentation/admin_screen_test.dart` → fails to compile (`AdminScreen` undefined).

- [ ] **Step 3: The page**

Create `admin_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_section.dart';

/// Screen 23b, Admin (settings hub spec §5.3): the rows the monitoring,
/// account and settings features supply, which `app/` composes, in Logs
/// and People. The router puts it behind the admin gate (ADR-018 §7).
class AdminScreen extends StatelessWidget {
  const AdminScreen({
    super.key,
    required this.logsRows,
    required this.peopleRows,
  });

  /// Monitoring, then the SQL log switch.
  final List<Widget> logsRows;

  /// Users.
  final List<Widget> peopleRows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.settingsAdmin,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: MxScreenScroll(
        children: [
          MxSection(title: l10n.settingsAdminLogs, children: logsRows),
          MxSection(title: l10n.settingsAdminPeople, children: peopleRows),
        ],
      ),
    );
  }
}
```

Run the test → PASS.

- [ ] **Step 4: Router and the hub row**

`admin_routes.dart`: replace `adminSettingsRows` with

```dart
/// Screen 23b (settings hub spec §5.3) under Settings on the root
/// navigator, behind the admin gate a deep link meets too.
GoRoute adminRoute(GlobalKey<NavigatorState> rootNavigator) => GoRoute(
  path: AppRoutes.settingsAdminChild,
  parentNavigatorKey: rootNavigator,
  builder: (context, state) => MonitoringAdminGateWidget(
    title: context.l10n.settingsAdmin,
    child: AdminScreen(
      logsRows: [
        MonitoringEntryRowWidget(
          onOpen: () => unawaited(context.push(AppRoutes.settingsMonitoring)),
        ),
        const SqlLogRowWidget(),
      ],
      peopleRows: [
        UsersEntryRowWidget(
          onOpen: () => unawaited(context.push(AppRoutes.settingsUsers)),
        ),
      ],
    ),
  ),
);
```

`app_router.dart`: drop `adminRows: adminSettingsRows(context),`, add `onOpenAdmin: () => context.push(AppRoutes.settingsAdmin),` and `adminRoute(rootNavigator),` after `usersRoute(rootNavigator),`.

`settings_screen.dart`: replace `this.adminRows = const []` with `required this.onOpenAdmin` (`/// Opens screen 23b (settings hub spec D4); the row shows only to an admin.`) and the Admin section with:

```dart
            if (accountRow != null && ref.watch(isAdminProvider))
              MxSection(
                title: l10n.settingsAdmin,
                children: [
                  MxSettingsRow(
                    label: l10n.settingsAdminTools,
                    subtitle: l10n.settingsAdminToolsHint,
                    icon: AppIcons.safe,
                    onTap: onOpenAdmin,
                  ),
                ],
              ),
```

(`accountRow != null` stands for "a build with an account"; `isAdminProvider` is false without one anyway, and a test can pass `accountRow: const SizedBox.shrink()`.)

- [ ] **Step 5: Move the admin visibility tests**

Delete `test/features/monitoring/presentation/monitoring_entry_section_test.dart`. Add to `settings_screen_test.dart` (its `_screen` gains `VoidCallback? onOpenAdmin` and `Widget? accountRow`):

```dart
  // Settings hub spec D4; users spec U2; ADR-018 §7.

  libraryTest('a non-admin sees no Admin section at all', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen(accountRow: const SizedBox.shrink()),
    );

    expect(find.text(_en.settingsAdmin.toUpperCase()), findsNothing);
    expect(find.text(_en.settingsAdminTools), findsNothing);
  });

  libraryTest('an admin sees one Admin tools row, and it opens screen 23b', (
    tester,
    env,
  ) async {
    var opened = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(
        accountRow: const SizedBox.shrink(),
        onOpenAdmin: () => opened++,
      ),
      overrides: [isAdminProvider.overrideWithValue(true)],
    );

    expect(find.text(_en.settingsAdmin.toUpperCase()), findsOneWidget);
    expect(find.text(_en.settingsAdminToolsHint), findsOneWidget);
    await tester.tap(find.text(_en.settingsAdminTools));
    expect(opened, 1);
  });

  // Review focus: a token refresh that adds the admin role while the hub
  // is open.
  libraryTest('an account confirmed as admin shows the row without a '
      'restart, and a lost confirmation hides it', (tester, env) async {
    final states = StreamController<AuthState>();
    addTearDown(states.close);
    await pumpLibraryScreen(
      tester,
      env,
      _screen(accountRow: const SizedBox.shrink()),
      overrides: [
        supabaseConfigProvider.overrideWithValue(
          const SupabaseConfig(url: 'https://x.supabase.co', publishableKey: 'key'),
        ),
        authStateProvider.overrideWith((ref) => states.stream),
      ],
    );
    states.add(const Ready(userAccount));
    await tester.pump();
    expect(find.text(_en.settingsAdminTools), findsNothing);

    states.add(const Ready(adminAccount));
    await tester.pump();
    await tester.pump();
    expect(find.text(_en.settingsAdminTools), findsOneWidget);

    states.add(const Validating(null));
    await tester.pump();
    await tester.pump();
    expect(find.text(_en.settingsAdminTools), findsNothing);
  });
```

Imports: the ones `monitoring_entry_section_test.dart` used for `isAdminProvider`, `authStateProvider`, `supabaseConfigProvider`, `SupabaseConfig`, `AuthState`, `Ready`, `Validating`, `userAccount`, `adminAccount` (copy its import block).

- [ ] **Step 6: Route tests**

`account_routes_test.dart`, the Users case: after `_router(tester).go(AppRoutes.settings); await tester.pumpAndSettle();` replace the scroll/ensureVisible/tap lines with:

```dart
    await tester.tap(find.text(_en.settingsAdminTools));
    await tester.pumpAndSettle();
    expect(find.byType(AdminScreen), findsOneWidget);
    await tester.tap(find.text(_en.usersTitle));
    await tester.pumpAndSettle();
    expect(find.byType(UsersScreen), findsOneWidget);
    expect(find.text('ann@example.com'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AdminScreen), findsOneWidget, reason: 'Back to 23b');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
```

Add two cases to `account_routes_test.dart`:

```dart
  accountTest('a non-admin\'s deep link to Admin meets the gate, titled '
      'Admin', (tester, env, world) async {
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));

    _router(tester).go(AppRoutes.settingsAdmin);
    await tester.pumpAndSettle();

    expect(find.byType(AdminScreen), findsNothing);
    expect(find.text(_en.monitoringNotAdminTitle), findsOneWidget);
    expect(find.text(_en.settingsAdmin), findsOneWidget);
  });

  accountTest('an admin\'s deep link to Monitoring returns to the hub, not '
      'to 23b (settings hub spec D5)', (tester, env, world) async {
    await pumpMemoxApp(
      tester,
      env,
      overrides: [...accountOverrides(world), isAdminProvider.overrideWithValue(true)],
    );

    _router(tester).go(AppRoutes.settingsMonitoring);
    await tester.pumpAndSettle();
    expect(find.text(_en.monitoringTitle), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
```

Import `admin_screen.dart`. `users_golden_test.dart`: `_settings()` is no longer needed; delete it, its `SettingsScreen` import and the "settings, admin rows" golden test (Task 5 adds `admin_golden_test.dart`), and delete `test/features/account/presentation/goldens/settings_admin_rows_{light,dark}.png`.

- [ ] **Step 7: Visual audit**

Create `admin_screen_visual_audit_test.dart` with `screen: AdminScreen` and

```dart
        const AdminScreen(
          logsRows: [MxSettingsRow(label: 'Monitoring', subtitle: 'Logs')],
          peopleRows: [MxSettingsRow(label: 'Users', subtitle: 'Who can manage')],
        ),
```

- [ ] **Step 8: Run and commit**

```bash
dart format lib test && dart analyze lib test
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/settings/presentation test/app/settings_routes_test.dart test/app/account_routes_test.dart test/visual_audit/screens/features/settings
git add -A lib test
git commit -m "Settings hub: Admin page (23b) behind the gate, one Admin tools row on the hub

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018UmUaGtGmYdc1ei6GLyTKb"
```

---

### Task 4: Goldens, golden tests and the golden-compare page

**Files:**
- Modify: `test/features/settings/presentation/settings_screen_golden_test.dart`
- Create: `test/features/settings/presentation/study_defaults_golden_test.dart`, `test/features/settings/presentation/admin_golden_test.dart`
- Modify: `test/features/account/presentation/account_golden_test.dart`, `account_manage_golden_test.dart` (done in Task 2; verify)
- Goldens under `test/features/settings/presentation/goldens/` and `test/features/account/presentation/goldens/`

**Interfaces:**
- Consumes: Tasks 1–3's screens and slots.

- [ ] **Step 1: Hub golden test**

In `settings_screen_golden_test.dart`: `_screen` adds `onOpenStudyDefaults: () {}, onOpenAdmin: () {},`. Delete the tests `settings, saving`, `settings, speech language sheet`, `settings, saved`, `settings, invalid limit`, `settings, save failed` (they move to 23a) and the `_stepAndSettle` helper. In `reset confirm`, `reset done` and the sync loop delete the `scrollUntilVisible(... Reset app options ...)` lines (the hub fits). Add:

```dart
    libraryTest('settings, admin row, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          SettingsScreen(
            onOpenStudyDefaults: () {},
            onOpenTheme: () {},
            onOpenLanguage: () {},
            onOpenReminder: () {},
            resetAppOptions: () async => const Ok(null),
            onOpenSync: () {},
            onOpenAdmin: () {},
            accountRow: const SizedBox.shrink(),
          ),
          brightness,
          overrides: [isAdminProvider.overrideWithValue(true)],
        );
        await expectBoundaryGolden(tester, 'goldens/settings_admin_row_$theme.png');
      });
    });
```

- [ ] **Step 2: 23a golden test**

Create `study_defaults_golden_test.dart` from the deleted hub cases, with `const _screen = StudyDefaultsScreen();`, the `_settle`/`_stepAndSettle` helpers, `@Tags(['golden'])`, and these names: `goldens/study_defaults_loaded_$theme.png`, `study_defaults_saving`, `study_defaults_saved`, `study_defaults_invalid_limit`, `study_defaults_save_failed`, `study_defaults_speech_language_sheet` (no `ensureVisible` needed). Add a `loading` case with the `never` stream like the hub's.

- [ ] **Step 3: 23b golden test**

Create `admin_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/account/presentation/widgets/items/users_entry_row_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/items/monitoring_entry_row_widget.dart';
import 'package:memox/features/settings/presentation/screens/admin_screen.dart';
import 'package:memox/features/settings/presentation/widgets/items/sql_log_row_widget.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

// Settings hub spec §5.3.
void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;
    libraryTest('admin, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          AdminScreen(
            logsRows: [
              MonitoringEntryRowWidget(onOpen: () {}),
              const SqlLogRowWidget(),
            ],
            peopleRows: [UsersEntryRowWidget(onOpen: () {})],
          ),
          brightness,
        );
        await expectBoundaryGolden(tester, 'goldens/admin_$theme.png');
      });
    });
  }
}
```

If `SqlLogRowWidget` needs the account's admin state to draw its toggle, add `overrides: [isAdminProvider.overrideWithValue(true)]` as `users_golden_test.dart` did.

- [ ] **Step 4: Regenerate and run**

```bash
rm -f test/features/settings/presentation/goldens/settings_{saving,saved,invalid_limit,save_failed,speech_language_sheet}_{light,dark}.png
bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update
bash .claude/skills/flutter-workflow/scripts/run_goldens.sh
```
Expected: the second run passes. Open `settings_loaded_light.png` and `settings_admin_row_light.png` with the Read tool and check the hub fits (the Reset note visible without scrolling for a non-admin) and no subtitle clips.

- [ ] **Step 5: Golden-compare page**

Follow the `golden-compare` skill: `build --base "$(git merge-base origin/master HEAD)"` into the scratchpad, write one `why` per shot in Vietnamese (hub: sections regrouped, study rows gone to 23a; 23a/23b: new, no before; account/sync goldens: the row moved into "Account & sync"), `render`, publish as a new Artifact (`icon="compare"`), and keep its URL for the PR.

- [ ] **Step 6: Commit**

```bash
git add -A test
git commit -m "Settings hub: goldens for the hub, Study defaults (23a) and Admin (23b)

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018UmUaGtGmYdc1ei6GLyTKb"
```

---

### Task 5: Docs, `DESIGN.md` and the gate

**Files:**
- Modify: `DESIGN.md` (Components, after the `MxListRow`/`MxSettingsRow` bullet at line ~356)
- Modify: `docs/shared/ui/screen-handoff/23-settings.md`; create `23a-study-defaults.md`, `23b-admin.md`; modify `00-index.md`
- Modify: `docs/shared/ui/navigation.md`, `docs/features/settings/usecases/UC-SETTINGS-001-dat-tuy-chon-ung-dung.md`, `docs/features/settings/README.md`
- Modify: the "Entry points" line of `24-daily-reminder.md`, `25-theme.md`, `26-language.md`, `27-sync.md`, `28-monitoring.md`, `32-account.md`, `33-users.md` where it names screen 23's section
- Modify: `docs/superpowers/specs/2026-10-07-settings-hub-design.md` status line

- [ ] **Step 1: `DESIGN.md`**

After the bullet that defines `MxSettingsRow` (the `- **MxListRow** (…), **MxSettingsRow** (…)` bullet), add a new bullet:

```markdown
- **Settings pattern** (settings hub spec 2026-10-07, §4). The Settings tab is a hub: `MxSection`s of navigation rows (label, the current value first in the subtitle, a chevron) and at most one action row (`isAction`, opens a dialog). No wide control and no toggle on the hub. A group with more than one setting of its own, or with a wide control, is a page under `/settings/<group>`, titled as its hub row, with a content-density app bar and Back; its rows sit in `MxSection`s with one note per section. On a page a setting is: a boolean → an `MxToggle` in the row; a pick from at most ten fixed values → a bottom sheet of `MxOptionRow`s opened by a value row; a value with its own state, feedback or preview (a number, a time, sync, the account) → a page of its own. Theme and Language predate the rule and keep their pages (FE-A3 D2). A row that opens a page or a sheet always names the current value in its subtitle.
```

- [ ] **Step 2: Handoff 23**

Rewrite `23-settings.md`'s Layout table to the hub of spec §5.1 (regions: App bar, Account & sync, Study, App, Admin, Reset, Reset dialog, Toasts), its States table to `loaded`, `loading`, `admin row`, `reset confirm`, `reset done`, `sync synced/failed/rejected`, `account`, `account signed in`, `account re-auth`, `read error` with the golden names of Task 4, add the ruling "**Settings hub spec 2026-10-07 D1–D11:** the tab is a hub; the study rows are on 23a, the admin rows on 23b; the account feature supplies a row and a banner", and trim Copy to the hub's strings (the groups' titles, the Study summary, the Admin tools row, Reset, Sync, Toasts, Error). Keep every ruling that still applies (D2, UI-base rows 124/125, SB-U1, account spec, ADR-018, the tone-pass rulings on the Sync tile).

- [ ] **Step 3: Handoffs 23a and 23b**

Create `23a-study-defaults.md` and `23b-admin.md` in the house format (`<!-- Hand-written screen record. -->`, title, intro, Entry points, Layout, States, Rulings, Copy) from spec §5.2 and §5.3, with the golden names of Task 4. 23a's rulings: FE-A3 D1, D6; UC E1–E3; study speech spec §6; settings hub spec D3, D9. 23b's rulings: ADR-018 §7 (the gate), users spec U2, SQL log switch spec, settings hub spec D4, D5 (a deep link to Monitoring returns to the hub).

- [ ] **Step 4: Index, navigation, UC, README, entry points**

`00-index.md`: row 23 → States `11`, FE item adds `settings hub (2026-10-07)`; insert rows `| 23a | Settings · Study defaults | 7 | settings hub (2026-10-07) | built | [23a-study-defaults.md](23a-study-defaults.md) |` and `| 23b | Settings · Admin (admin only) | 1 | settings hub (2026-10-07) | built | [23b-admin.md](23b-admin.md) |` after 23. `navigation.md`: in the Settings bullet, after "mặc định học, theme và ngôn ngữ;" add "tab là một hub; mặc định học ở màn 23a (`/settings/study`), các công cụ admin ở màn 23b (`/settings/admin`, chỉ admin thấy);". UC-SETTINGS-001 step 1: "Người dùng mở tab Settings (hub) và hàng `Study defaults` mở màn 23a. Hệ thống đọc dòng `app_settings` qua stream và hiển thị hai nhóm `Session` và `Speech` — mỗi control hiển thị **giá trị đang có hiệu lực**…"; the first acceptance criterion names "hub với các nhóm Account & sync, Study, App, Reset, và màn Study defaults với hai nhóm Session, Speech". `docs/features/settings/README.md`: add `| Study defaults (màn 23a) | UC-SETTINGS-001 |` and `| Admin (màn 23b) | Chưa có UC; hành vi theo [spec settings hub](../../superpowers/specs/2026-10-07-settings-hub-design.md) §5.3 |`. Entry points of 24–33: replace "the Daily reminder row of screen 23's App section" style phrases with the hub's row where the text names a section that moved (28 and 33: "the Admin page (23b)").

- [ ] **Step 5: Spec status, docs check, gate**

Set the spec's status line to `Status: approved 2026-10-07 · Path: architectural · Owner rulings 2026-10-07 (§3)`. Then:

```bash
python3 tools/docs/generate.py && python3 tools/docs/check.py
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
bash .claude/skills/flutter-workflow/scripts/run_goldens.sh
```
Expected: `PASS — 0 error(s)`, `✓ mechanical gates passed`, goldens pass.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Settings hub: DESIGN.md pattern, handoffs 23/23a/23b, index, navigation, UC-SETTINGS-001

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018UmUaGtGmYdc1ei6GLyTKb"
```

Then the final whole-branch review (Opus) and `finishing-a-development-branch`: push, open the PR against `master` with the golden-compare link, subscribe to its activity.
