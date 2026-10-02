# Critique 2026-09-30 tone pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring success and warning back into colour: an amber light `warningInk`, banner titles in their tone's ink, a success badge tone, and success where screens 10, 11, 23, 27, 28 and `MxEmptyState` mean "done" or "fine".

**Architecture:** One token change in `MxDerivedColors` reaches every warning-ink consumer. Three shared widgets gain or change one tone path each (`MxBadge`, `MxInlineBanner`, `MxEmptyState`), `MxSettingsRow` gains `iconTone`, and one presentation predicate (`syncIsSettled`) drives screens 23 and 27. The screen changes are one-line tone swaps.

**Tech Stack:** Flutter 3.47.5, Riverpod 3, flutter_test, goldens rendered in the Linux container.

**Spec:** `docs/superpowers/specs/2026-09-30-critique-fixes-tone-design.md` (owner rulings T1–T8).

## Global Constraints

- Light `warningInk` is `#895806`; dark keeps `semantic.warning`. `semantic.onWarning` stays `#3A2A00` (T1).
- Text, icons and glyphs use inks (`warningInk`, `successInk`, `error`), never a fill (DESIGN.md, the Ink Is Not The Fill).
- Green is mastery for learning progress and success for a right answer or a finished, fine state; never interchangeable (DESIGN.md).
- No layout change anywhere; no new copy or ARB key.
- Commit messages in English and ending with the two attribution lines:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01WHcLQhgp72txzYGsDLm7JX`.
- Goldens render in the Linux container only; the owner reviews changed goldens on a `golden-compare` page before merge.

## Review Focus

1. A warning ink on the darkest light ground it meets (`surfaceContainer` #E9EDF7 with the amber tint) must still reach 4.5:1: Task 1's contrast test covers `surfaceContainer` too.
2. Sync that synced once and then failed must not show the success check or tile: Task 6's predicate test has a failed case with `lastSuccessAt` set.
3. A disabled `MxSettingsRow` with `iconTone: success` must still dim its tile: Task 5 tests the dimmed tile.
4. A titleless banner must keep its `onSurface` lead (only titles take the ink): Task 3 tests both.
5. Dark theme: the success badge and banner titles must read on dark tints: Task 2 and Task 3 each run one dark case.

---

### Task 1: `warningInk` is amber in light

**Files:**
- Modify: `lib/core/theme/mx_derived_colors.dart:76-80` (the `warningInk` line and its comment), plus a constant beside the other private mixes (after line 144)
- Modify: `DESIGN.md` (tokens block, line 37; the Warning Amber line, line 246)
- Test: `test/core/theme/mx_derived_colors_test.dart:93-96` and the L6 contrast test

**Interfaces:**
- Consumes: nothing.
- Produces: `MxDerivedColors.warningInk` = `Color(0xFF895806)` in light, `MxSemanticColors.dark.warning` in dark.

- [ ] **Step 1: Write the failing tests**

In `test/core/theme/mx_derived_colors_test.dart`, add a top-level helper above `void main()`:

```dart
double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}
```

In the L6 test, delete its local `ratio` function and call `_ratio` instead (two `expect` lines).

Replace the test at lines 93-96 with:

```dart
  test('warningInk is #895806 in light and the amber in dark (critique '
      '2026-09-30 tone pass, T1)', () {
    expect(light.warningInk, isColorCloseTo(0xFF895806));
    expect(dark.warningInk, MxSemanticColors.dark.warning);
  });

  test('warningInk reads at 4.5:1 on every ground, the amber tint and the '
      'warning ground (T1)', () {
    for (final (scheme, semantic) in [
      (AppColorSchemes.light, MxSemanticColors.light),
      (AppColorSchemes.dark, MxSemanticColors.dark),
    ]) {
      final derived = MxDerivedColors.resolve(scheme, semantic);
      for (final ground in [
        scheme.surface,
        scheme.surfaceContainerLowest,
        scheme.surfaceContainer,
      ]) {
        final tint = Color.alphaBlend(
          semantic.warning.withValues(alpha: 0.12),
          ground,
        );
        final soft = Color.alphaBlend(derived.warningSoft, ground);
        expect(_ratio(derived.warningInk, ground), greaterThanOrEqualTo(4.5));
        expect(_ratio(derived.warningInk, tint), greaterThanOrEqualTo(4.5));
        expect(_ratio(derived.warningInk, soft), greaterThanOrEqualTo(4.5));
      }
    }
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/core/theme/mx_derived_colors_test.dart`
Expected: FAIL on "warningInk is #895806" (actual `0xFF3A2A00`); the contrast test passes already (#3A2A00 is 12:1), which is fine: it guards the new value.

- [ ] **Step 3: Implement**

In `lib/core/theme/mx_derived_colors.dart`, replace the `warningInk` comment and line with:

```dart
      // Warning TEXT and glyphs. The amber fill fails as 12px text on light
      // surfaces, and onWarning (the ink on an amber fill) reads as body
      // text, so light uses the amber's hue at 28% lightness: 4.79:1 or more
      // on every ground and tint (critique 2026-09-30 tone pass, T1). Dark
      // inks with the amber itself.
      warningInk: isDark ? semantic.warning : _warningInkLight,
```

Beside the other private constants (after `_masteredInkDark`):

```dart
  static const Color _warningInkLight = Color(0xFF895806);
```

In `DESIGN.md`, after `  on-warning: "#3A2A00"` add `  warning-ink: "#895806"`. Replace the Warning Amber line (246) with:

```markdown
- **Warning Amber** (`warning`, `on-warning`, `warning-ink`): a refusal or a limit where nothing was lost. Warning text and glyphs use **Warning Ink** (`warningInk`): #895806 in light (amber's hue at 28% lightness, 4.79:1 or more on every ground and tint), the amber itself in dark. `on-warning` is only the ink on an amber fill (critique 2026-09-30 tone pass, T1).
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/core/theme/`
Expected: PASS, including `token_contrast_test.dart`.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/mx_derived_colors.dart test/core/theme/mx_derived_colors_test.dart DESIGN.md
git commit -m "feat(theme): amber light warning ink (tone pass T1)"
```

### Task 2: `MxBadge` success tone

**Files:**
- Modify: `lib/shared/widgets/mx_badge.dart:7,41-56`
- Modify: `DESIGN.md` (the component list, line 342: `**MxBadge** (primary, mastery, warning, danger, neutral)`)
- Test: `test/shared/widgets/mx_badge_test.dart`

**Interfaces:**
- Consumes: `MxDerivedColors.successInk`, `MxSemanticColors.success`.
- Produces: `MxBadgeTone.success` (enum order: `primary, mastery, success, warning, danger, neutral`).

- [ ] **Step 1: Write the failing test**

Append to `test/shared/widgets/mx_badge_test.dart` inside `main()`:

```dart
  testWidgets('success: the success tint under a success-ink label, in both '
      'themes (critique 2026-09-30 tone pass, T6)', (tester) async {
    await pumpMx(
      tester,
      const MxBadge(label: 'Ready · 2', tone: MxBadgeTone.success),
    );
    expect(_pill(tester).color, semantic.success.withValues(alpha: 0.12));
    expect(_ink(tester, 'Ready · 2'), derived.successInk);

    final darkSemantic = MxSemanticColors.dark;
    final darkDerived = MxDerivedColors.resolve(
      AppColorSchemes.dark,
      darkSemantic,
    );
    await pumpMx(
      tester,
      const MxBadge(label: 'Ready · 2', tone: MxBadgeTone.success),
      brightness: Brightness.dark,
    );
    expect(_pill(tester).color, darkSemantic.success.withValues(alpha: 0.12));
    expect(_ink(tester, 'Ready · 2'), darkDerived.successInk);
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/shared/widgets/mx_badge_test.dart`
Expected: FAIL to compile: `success` is not a member of `MxBadgeTone`.

- [ ] **Step 3: Implement**

In `lib/shared/widgets/mx_badge.dart`:

```dart
/// The tone a count carries. There is no streak tone (ruling S1). Mastery is
/// learning progress; success is a right answer or a finished, fine state
/// (critique 2026-09-30 tone pass, T6).
enum MxBadgeTone { primary, mastery, success, warning, danger, neutral }
```

In `toneColor` add `MxBadgeTone.success => context.semanticColors.success,` after the mastery arm. In `ink` add `(false, MxBadgeTone.success) => context.derivedColors.successInk,` after the mastery arm.

In `DESIGN.md` line 342, change `**MxBadge** (primary, mastery, warning, danger, neutral)` to `**MxBadge** (primary, mastery, success, warning, danger, neutral; mastery is learning progress, success a right answer or a finished, fine state, in its success ink; critique 2026-09-30 tone pass)`.

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/shared/widgets/mx_badge_test.dart test/shared/widgets/primary_ink_widgets_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_badge.dart test/shared/widgets/mx_badge_test.dart DESIGN.md
git commit -m "feat(shared): MxBadge success tone (tone pass T6)"
```

### Task 3: `MxInlineBanner` title takes the tone's ink

**Files:**
- Modify: `lib/shared/widgets/mx_inline_banner.dart:119-122`
- Modify: `DESIGN.md` (the MxInlineBanner entry, line 342)
- Test: `test/shared/widgets/mx_inline_banner_test.dart`

**Interfaces:**
- Consumes: `MxDerivedColors.warningInk` (Task 1), `ColorScheme.error`.
- Produces: nothing new; the title's colour changes.

- [ ] **Step 1: Write the failing test**

Append inside `main()`:

```dart
  testWidgets('the title reads in its tone ink; an untitled lead stays '
      'onSurface (critique 2026-09-30 tone pass, T2)', (tester) async {
    for (final (tone, ink) in [
      (MxBannerTone.warning, derived.warningInk),
      (MxBannerTone.danger, scheme.error),
    ]) {
      await pumpMx(
        tester,
        _width(MxInlineBanner(tone: tone, title: 'Title', message: _message)),
      );
      expect(
        tester.widget<Text>(find.text('Title')).style!.color,
        ink,
        reason: '$tone',
      );
      await pumpMx(
        tester,
        _width(MxInlineBanner(tone: tone, message: _message)),
      );
      expect(
        tester.widget<Text>(find.text(_message)).style!.color,
        scheme.onSurface,
        reason: '$tone untitled',
      );
    }

    final darkDerived = MxDerivedColors.resolve(
      AppColorSchemes.dark,
      MxSemanticColors.dark,
    );
    await pumpMx(
      tester,
      _width(
        const MxInlineBanner(
          tone: MxBannerTone.warning,
          title: 'Title',
          message: _message,
        ),
      ),
      brightness: Brightness.dark,
    );
    expect(
      tester.widget<Text>(find.text('Title')).style!.color,
      darkDerived.warningInk,
    );
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/shared/widgets/mx_inline_banner_test.dart`
Expected: FAIL: the title's colour is `onSurface`, not the ink.

- [ ] **Step 3: Implement**

In `lib/shared/widgets/mx_inline_banner.dart` replace

```dart
                      if (title case final lead?) ...[
                        Text(lead, style: styles.bannerTitle),
```

with

```dart
                      // The title carries the tone, as the glyph does; the
                      // message stays neutral (critique 2026-09-30 tone
                      // pass, T2).
                      if (title case final lead?) ...[
                        Text(
                          lead,
                          style: styles.bannerTitle.copyWith(color: ink),
                        ),
```

In `DESIGN.md` line 342, change `**MxInlineBanner** (warning or danger; its actions put the primary last` to `**MxInlineBanner** (warning or danger; the glyph and the bold title read in the tone's ink, warning ink or error, and the message stays neutral, critique 2026-09-30 tone pass; its actions put the primary last`.

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/shared/widgets/mx_inline_banner_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_inline_banner.dart test/shared/widgets/mx_inline_banner_test.dart DESIGN.md
git commit -m "feat(shared): banner title in its tone ink (tone pass T2)"
```

### Task 4: `MxEmptyState` success tone draws in success

**Files:**
- Modify: `lib/shared/widgets/mx_empty_state.dart:100-106,163-169`
- Modify: `DESIGN.md` (the MxEmptyState entry, line 342)
- Test: `test/shared/widgets/mx_empty_state_test.dart:58-86`

**Interfaces:**
- Consumes: `MxSemanticColors.success`, `MxDerivedColors.successInk`.
- Produces: nothing new.

- [ ] **Step 1: Write the failing test**

In the test 'tone tints the tile at 10% and paints the glyph', change the success entry to `MxEmptyStateTone.success: MxSemanticColors.light.success,` and replace the glyph expectation with:

```dart
      // The primary glyph reads in primaryInk (spec 2026-09-27 D2), the
      // success glyph in its ink (critique 2026-09-30 tone pass, T7).
      final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);
      final glyph = switch (tone) {
        MxEmptyStateTone.primary => MxDerivedColors.primaryInkOf(scheme),
        MxEmptyStateTone.success => derived.successInk,
        _ => color,
      };
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/shared/widgets/mx_empty_state_test.dart`
Expected: FAIL for `MxEmptyStateTone.success`: the tile is the mastery tint.

- [ ] **Step 3: Implement**

In `_toneColor`, change `MxEmptyStateTone.success => context.semanticColors.mastery,` to `MxEmptyStateTone.success => context.semanticColors.success,`. Replace the `_Tile`'s `ink:` argument with:

```dart
                ink: switch (tone) {
                  MxEmptyStateTone.primary => context.derivedColors.primaryInk,
                  MxEmptyStateTone.success => context.derivedColors.successInk,
                  _ => toneColor,
                },
```

and update the `_Tile.ink` doc comment to `/// The glyph: primaryInk for the primary tone (spec 2026-09-27 D2), successInk for success (tone pass T7).`

In `DESIGN.md` line 342, change `**MxEmptyState** (tones primary, neutral, success, warning, danger)` to `**MxEmptyState** (tones primary, neutral, success, warning, danger; success tints with success and draws its glyph in success ink, critique 2026-09-30 tone pass)`.

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/shared/widgets/mx_empty_state_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_empty_state.dart test/shared/widgets/mx_empty_state_test.dart DESIGN.md
git commit -m "fix(shared): success empty state in success, not mastery (tone pass T7)"
```

### Task 5: `MxSettingsRow.iconTone`

**Files:**
- Modify: `lib/shared/widgets/mx_settings_row.dart` (constructor, fields, the tile at line 98)
- Modify: `DESIGN.md` (the MxSettingsRow entry, line 350)
- Test: `test/shared/widgets/mx_settings_row_test.dart`

**Interfaces:**
- Consumes: `MxIconTileTone` from `mx_icon_tile.dart`.
- Produces: `MxSettingsRow({..., MxIconTileTone iconTone = MxIconTileTone.tinted})`, passed to the lead `MxIconTile`.

- [ ] **Step 1: Write the failing test**

Append inside `main()` (`_dim` wraps a disabled row's tile in `Opacity`):

```dart
  testWidgets('iconTone reaches the lead tile, and a disabled row still dims '
      'it (critique 2026-09-30 tone pass, T4)', (tester) async {
    await pumpMx(
      tester,
      _width(const MxSettingsRow(label: 'Sync', icon: AppIcons.sync)),
    );
    expect(
      tester.widget<MxIconTile>(find.byType(MxIconTile)).tone,
      MxIconTileTone.tinted,
    );

    await pumpMx(
      tester,
      _width(
        const MxSettingsRow(
          label: 'Sync',
          icon: AppIcons.sync,
          iconTone: MxIconTileTone.success,
          isEnabled: false,
        ),
      ),
    );
    expect(
      tester.widget<MxIconTile>(find.byType(MxIconTile)).tone,
      MxIconTileTone.success,
    );
    expect(
      find.ancestor(
        of: find.byType(MxIconTile),
        matching: find.byType(Opacity),
      ),
      findsOneWidget,
    );
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/shared/widgets/mx_settings_row_test.dart`
Expected: FAIL to compile: no named parameter `iconTone`.

- [ ] **Step 3: Implement**

In `lib/shared/widgets/mx_settings_row.dart`: add `this.iconTone = MxIconTileTone.tinted,` after `this.icon,` in the constructor; add the field after `icon`:

```dart
  /// The lead tile's tone: tinted by default; success when the setting's
  /// state is fine, as screen 23's Sync row once sync is settled (critique
  /// 2026-09-30 tone pass, T4).
  final MxIconTileTone iconTone;
```

and change the tile to `MxIconTile(icon: glyph, size: MxIconTileSize.medium, tone: iconTone)`.

In `DESIGN.md` line 350, after `an \`isAction\` row, which runs an action or opens a dialog, shows no chevron` add `; \`iconTone\` sets the lead tile's tone, tinted by default (critique 2026-09-30 tone pass)`.

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/shared/widgets/mx_settings_row_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/mx_settings_row.dart test/shared/widgets/mx_settings_row_test.dart DESIGN.md
git commit -m "feat(shared): MxSettingsRow iconTone (tone pass T4)"
```

### Task 6: Sync settled — screens 27 and 23

**Files:**
- Modify: `lib/features/settings/presentation/widgets/support/sync_labels_widget.dart` (add `syncIsSettled`)
- Modify: `lib/features/settings/presentation/widgets/sections/sync_status_section_widget.dart`
- Modify: `lib/features/settings/presentation/widgets/sections/settings_sync_section_widget.dart`
- Modify: `docs/shared/ui/screen-handoff/27-sync.md` and `23-settings.md` (Rulings)
- Test: `test/features/settings/presentation/sync_labels_test.dart`, `sync_screen_test.dart`, `settings_sync_section_test.dart`

**Interfaces:**
- Consumes: `MxSettingsRow.iconTone` (Task 5), `MxDerivedColors.successInk`.
- Produces: `bool syncIsSettled(SyncStatus status)`.

- [ ] **Step 1: Write the failing tests**

In `sync_labels_test.dart`, inside `main()`:

```dart
  test('settled: synced once, nothing waiting, refused or failed (critique '
      '2026-09-30 tone pass, T3)', () {
    final success = DateTime(2026, 9, 28, 0, 10);
    expect(syncIsSettled(SyncStatus(lastSuccessAt: success)), isTrue);
    expect(syncIsSettled(const SyncStatus()), isFalse);
    expect(
      syncIsSettled(SyncStatus(lastSuccessAt: success, pendingCount: 1)),
      isFalse,
    );
    expect(
      syncIsSettled(SyncStatus(lastSuccessAt: success, rejectedCount: 1)),
      isFalse,
    );
    expect(
      syncIsSettled(
        SyncStatus(
          lastSuccessAt: success,
          lastFailure: LastSyncFailure(SyncFailureKind.network, success),
        ),
      ),
      isFalse,
    );
  });
```

In `sync_screen_test.dart` (add `import 'package:flutter/material.dart';`, `import 'package:memox/core/theme/foundations/app_icons.dart';`, `import 'package:memox/core/theme/theme_context.dart';` if missing):

```dart
  libraryTest('settled sync ends the waiting row with a success check; '
      'waiting rows show none (critique 2026-09-30 tone pass, T3)', (
    tester,
    env,
  ) async {
    Finder check() => find.descendant(
      of: find.byType(SyncStatusSectionWidget),
      matching: find.byIcon(AppIcons.check),
    );
    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(SyncStatus(lastSuccessAt: env.clock.now())),
    );
    expect(check(), findsOneWidget);
    final context = tester.element(check());
    expect(
      tester.widget<Icon>(check()).color,
      context.derivedColors.successInk,
    );

    await pumpLibraryScreen(
      tester,
      env,
      const SyncScreen(),
      overrides: syncOverrides(
        SyncStatus(lastSuccessAt: env.clock.now(), pendingCount: 2),
      ),
    );
    expect(check(), findsNothing);
  });
```

In `settings_sync_section_test.dart` (add imports for `package:flutter/material.dart`, `app_icons.dart`, `mx_icon_tile.dart`):

```dart
  libraryTest('the Sync tile is success once sync is settled, tinted '
      'otherwise (critique 2026-09-30 tone pass, T4)', (tester, env) async {
    Finder tile() => find.ancestor(
      of: find.byIcon(AppIcons.sync),
      matching: find.byType(MxIconTile),
    );
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: syncOverrides(SyncStatus(lastSuccessAt: env.clock.now())),
    );
    await tester.scrollUntilVisible(tile(), 200);
    expect(tester.widget<MxIconTile>(tile()).tone, MxIconTileTone.success);

    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: syncOverrides(const SyncStatus(rejectedCount: 1)),
    );
    await tester.scrollUntilVisible(tile(), 200);
    expect(tester.widget<MxIconTile>(tile()).tone, MxIconTileTone.tinted);
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/settings/presentation/sync_labels_test.dart test/features/settings/presentation/sync_screen_test.dart test/features/settings/presentation/settings_sync_section_test.dart`
Expected: FAIL to compile: `syncIsSettled` is not defined.

- [ ] **Step 3: Implement**

In `sync_labels_widget.dart`, after `syncStatusLine`:

```dart
/// Everything is on the server: something synced, nothing waits, nothing
/// was refused and the last run did not fail. Screen 27 ends its waiting row
/// with a success check and screen 23 turns its Sync tile success
/// (critique 2026-09-30 tone pass, T3 and T4).
bool syncIsSettled(SyncStatus status) =>
    status.lastSuccessAt != null &&
    status.pendingCount == 0 &&
    status.rejectedCount == 0 &&
    status.lastFailure == null;
```

In `sync_status_section_widget.dart`, add imports `package:memox/core/theme/foundations/app_icon_size.dart`, `package:memox/core/theme/foundations/app_icons.dart`, `package:memox/core/theme/theme_context.dart`, and give the waiting row:

```dart
          // Settled: the subtitle already says "Nothing waiting", so the
          // check is not read out (critique 2026-09-30 tone pass, T3).
          trailing: syncIsSettled(status)
              ? ExcludeSemantics(
                  child: Icon(
                    AppIcons.check,
                    size: AppIconSize.compact,
                    color: context.derivedColors.successInk,
                  ),
                )
              : null,
```

In `settings_sync_section_widget.dart`, import `package:memox/shared/widgets/mx_icon_tile.dart` and `package:memox/features/settings/presentation/widgets/support/sync_labels_widget.dart` (if not already imported for `syncStatusLine`), and add to the row:

```dart
          iconTone: syncIsSettled(status)
              ? MxIconTileTone.success
              : MxIconTileTone.tinted,
```

In `27-sync.md` Rulings add: `- **Critique 2026-09-30 tone pass (spec \`2026-09-30-critique-fixes-tone-design.md\`), T3:** when sync is settled (synced once, nothing waiting, refused or failed) the waiting row ends with a success check, not read out.`
In `23-settings.md` Rulings add: `- **Critique 2026-09-30 tone pass, T4:** the Sync row's tile is success when sync is settled, tinted otherwise.`

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/features/settings/presentation/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings test/features/settings docs/shared/ui/screen-handoff/27-sync.md docs/shared/ui/screen-handoff/23-settings.md
git commit -m "feat(sync): success check and tile once sync is settled (tone pass T3, T4)"
```

### Task 7: Screens 10, 11 and 28 use success

**Files:**
- Modify: `lib/features/card/presentation/widgets/items/card_history_event_widget.dart:32-36`
- Modify: `lib/features/transfer/presentation/widgets/sections/import_preview_section_widget.dart:47`
- Modify: `lib/features/transfer/presentation/widgets/items/import_preview_row_widget.dart:92`
- Modify: `lib/features/monitoring/presentation/widgets/support/monitoring_labels_widget.dart:44-47`
- Modify: `docs/shared/ui/screen-handoff/10-card-detail.md`, `11-card-import.md`, `28-monitoring.md` (Rulings)
- Test: `test/features/card/presentation/card_history_scroll_test.dart`, `test/features/transfer/presentation/import_preview_row_test.dart`, `card_import_screen_test.dart`, `test/features/monitoring/presentation/monitoring_detail_screen_test.dart`

**Interfaces:**
- Consumes: `MxBadgeTone.success` (Task 2), `MxDerivedColors.successInk`.
- Produces: nothing new.

- [ ] **Step 1: Write the failing tests**

In `card_history_scroll_test.dart` (add imports `package:memox/features/srs/domain/models/review_action_model.dart`, `review_kind_model.dart`, `scheduler_type_model.dart` and `package:memox/shared/widgets/mx_badge.dart`):

```dart
  libraryTest('a lapse is warning, relearning neutral, any other answer '
      'success (critique 2026-09-30 tone pass, T5)', (tester, env) async {
    ReviewHistoryEntry entry(ReviewKind kind, Enum action) =>
        ReviewHistoryEntry(
          id: 'r',
          generation: 1,
          schedulerType: SchedulerType.eightBox,
          kind: kind,
          mode: 'recall',
          action: action,
          answeredAt: DateTime(2026, 9, 1, 8),
          isTimedOut: false,
          usedHint: null,
          nextDueAt: null,
          previousBox: null,
          nextBox: null,
          previousEaseFactor: null,
          nextEaseFactor: null,
          previousIntervalDays: null,
          nextIntervalDays: null,
        );
    for (final (kind, action, tone) in [
      (ReviewKind.scheduled, EightBoxAction.remembered, MxBadgeTone.success),
      (ReviewKind.learning, Sm2Action.good, MxBadgeTone.success),
      (ReviewKind.scheduled, EightBoxAction.forgotten, MxBadgeTone.warning),
      (ReviewKind.scheduled, Sm2Action.again, MxBadgeTone.warning),
      (ReviewKind.relearning, Sm2Action.good, MxBadgeTone.neutral),
    ]) {
      await pumpLibraryScreen(
        tester,
        env,
        Scaffold(body: CardHistoryEventWidget(entry: entry(kind, action))),
      );
      expect(
        tester.widget<MxBadge>(find.byType(MxBadge)).tone,
        tone,
        reason: '$kind $action',
      );
    }
  });
```

In `import_preview_row_test.dart` (add `import 'package:memox/core/theme/theme_context.dart';`):

```dart
  libraryTest('a ready row is marked with a success-ink check (critique '
      '2026-09-30 tone pass, T6)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const Scaffold(
        body: Column(
          children: [
            ImportPreviewRowWidget(
              row: ImportRow(
                rowNumber: 2,
                kind: ImportRowKind.ready,
                draft: CardDraft(front: 'mul', back: 'water'),
              ),
            ),
          ],
        ),
      ),
    );
    final mark = find.byIcon(AppIcons.check);
    expect(
      tester.widget<Icon>(mark).color,
      tester.element(mark).derivedColors.successInk,
    );
  });
```

In `card_import_screen_test.dart` (add `import 'package:memox/shared/widgets/mx_badge.dart';`), in 'a file becomes cards through the four steps', right after `await _tap(tester, _en.importPreviewAction);` add:

```dart
    // Ready is a fine state, not learning progress (tone pass T6).
    expect(
      tester
          .widget<MxBadge>(
            find.widgetWithText(MxBadge, _en.importBadgeReady(2)),
          )
          .tone,
      MxBadgeTone.success,
    );
```

In `monitoring_detail_screen_test.dart`, in 'a fixed error says who and when…', after `expect(find.widgetWithText(MxBadge, 'Fixed'), findsOneWidget);` add:

```dart
    expect(
      tester.widget<MxBadge>(find.widgetWithText(MxBadge, 'Fixed')).tone,
      MxBadgeTone.success,
    );
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/card/presentation/card_history_scroll_test.dart test/features/transfer/presentation/import_preview_row_test.dart test/features/transfer/presentation/card_import_screen_test.dart test/features/monitoring/presentation/monitoring_detail_screen_test.dart`
Expected: FAIL: history success cases are `primary`; the ready mark is the mastery fill; Ready and Fixed are `mastery`.

- [ ] **Step 3: Implement**

`card_history_event_widget.dart`:

```dart
    // A right answer is success, never mastery or the action Indigo
    // (DESIGN.md; critique 2026-09-30 tone pass, T5).
    final (tone, icon) = switch (entry.kind) {
      _ when isLapse => (MxBadgeTone.warning, AppIcons.lapses),
      ReviewKind.relearning => (MxBadgeTone.neutral, AppIcons.repeat),
      _ => (MxBadgeTone.success, AppIcons.check),
    };
```

`import_preview_section_widget.dart`: `tone: MxBadgeTone.success,` for the Ready badge.

`import_preview_row_widget.dart`: `ImportRowKind.ready => (AppIcons.check, context.derivedColors.successInk),`

`monitoring_labels_widget.dart`: update the doc comment to `/// An open problem is a warning-toned pill, a fixed one success: the label says it too, so the tone is never the only cue (critique 2026-09-30 tone pass, T7).` and `LogStatus.fixed => MxBadgeTone.success,`.

Rulings lines:
- `10-card-detail.md`: `- **Critique 2026-09-30 tone pass, T5:** a history badge is success for a right answer, warning for a lapse and neutral for relearning.`
- `11-card-import.md`: `- **Critique 2026-09-30 tone pass, T6:** Ready (chip and row mark) is success; the step tracker's finished steps stay mastery (progress through the flow).`
- `28-monitoring.md`: `- **Critique 2026-09-30 tone pass, T7:** a Fixed log is success; the empty lists' success state tints with success.`

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/features/card test/features/transfer test/features/monitoring`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/card lib/features/transfer lib/features/monitoring test/features/card test/features/transfer test/features/monitoring docs/shared/ui/screen-handoff/10-card-detail.md docs/shared/ui/screen-handoff/11-card-import.md docs/shared/ui/screen-handoff/28-monitoring.md
git commit -m "feat: success tone for right answers, Ready and Fixed (tone pass T5-T7)"
```

### Task 8: Records, goldens and the gate

**Files:**
- Modify: `docs/wbs_FE.md` (a row FE-D12 after FE-D11)
- Modify: `test/**/goldens/*.png` (regenerated)

**Interfaces:**
- Consumes: Tasks 1–7.
- Produces: the regenerated goldens and a green gate.

- [ ] **Step 1: Add the WBS row**

After the FE-D11 row in `docs/wbs_FE.md`, add:

```markdown
| FE-D12 | Critique 2026-09-30, đợt tone: warning ink light #895806, tiêu đề banner theo màu tone, `MxBadge` tone success, `MxSettingsRow.iconTone`; 27 dấu check success và 23 ô icon success khi sync đã ổn; 10 lần nhớ, 11 Ready, 28 Fixed và `MxEmptyState` success dùng success thay mastery | đang làm | FE-D11 | S | [spec](superpowers/specs/2026-09-30-critique-fixes-tone-design.md) và [plan](superpowers/plans/2026-09-30-critique-fixes-tone.md) | — |
```

Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py`
Expected: `PASS — 0 error(s)`.

- [ ] **Step 2: Regenerate the goldens**

Run: `TZ=UTC flutter test --tags golden --update-goldens > /tmp/golden-update.log 2>&1; tail -3 /tmp/golden-update.log; git status --short -- 'test/**/goldens/*.png' | wc -l`
Expected: the run ends `All tests passed!`; roughly 52 light goldens from Task 1 plus the banner, badge, empty-state, sync, settings, card detail, import and monitoring goldens.

Then: `TZ=UTC flutter test --tags golden > /tmp/golden.log 2>&1; tail -2 /tmp/golden.log`
Expected: `All tests passed!` (475 goldens).

- [ ] **Step 3: Run the gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh > /tmp/dod.log 2>&1; tail -15 /tmp/dod.log`
Expected: every step passes (format, analyze, generated code, architecture, docs, guard, full suite).

- [ ] **Step 4: Commit**

```bash
git add docs/wbs_FE.md docs/_generated test
git commit -m "test(goldens): regenerate for the tone pass"
```
