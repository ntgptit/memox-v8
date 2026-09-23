# Flutter UI Base — Phase 3 (App Wiring, Shell, Gallery) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The app launches into the four-tab shell: Thư viện · Học · Tiến độ · Cài đặt. Each tab shows a localized placeholder, in English and Vietnamese. A debug-only gallery shows every phase-2 widget under a light/dark and 1x/2x switch.

**Architecture:**
- `main.dart` is `ProviderScope(child: MemoxApp())`.
- `MemoxApp` (`lib/app/app.dart`) is a `MaterialApp.router` with the V3 light and dark themes, `ThemeMode.system`, gen-l10n delegates for `en` and `vi`, and a router it owns.
- `buildAppRouter` (`lib/app/router/app_router.dart`) builds a `StatefulShellRoute.indexedStack` of four branches under `MxAppShell` + `MxBottomNav`. `/gallery` is added only when `includeGallery`, which is `kDebugMode` by default.
- Placeholders and the gallery live in `lib/app/`. No `lib/features/*/presentation/` file is created (spec §1).

**Tech Stack:** Flutter 3.47.5, `go_router` 18.0.1 (already a dependency), `flutter_localizations` + gen-l10n, `flutter_riverpod` (`ProviderScope` only).

**Spec:** [`docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`](../specs/2026-09-23-flutter-ui-base-design.md), §6 and §7, §8.1 phase 3, §8.2 "App", §8.3. Tab order and labels come from [`navigation.md`](../../shared/ui/navigation.md).

## Global Constraints

- UI only. No file under `lib/features/`, `lib/core/database|error|id/` is created or changed, and no backend source is touched.
- Imports:
  - `lib/app/` imports `core/`, `shared/`, `l10n/` and packages, never `features/`.
  - `lib/l10n/` hand-written files import only Flutter and `lib/l10n/generated/`.
- l10n:
  - gen-l10n output goes to `lib/l10n/generated/`, which is git-ignored. Guard scopes already exclude it, and `check_generated.py` ignores it on purpose.
  - Template is `app_en.arb`; the translation is `app_vi.arb`.
  - Every key in the template is followed by its `"@key": {"description": …}` entry (guard `memox.i18n.arb_entry_needs_description`).
- Product copy comes from the ARB files: tab labels, placeholder, and the gallery entry's tooltip. The gallery's own labels and demo copy are English literals (ruling G1).
- `lib/app/` is in the typography guard scopes: no `TextStyle(` and no `fontWeight: FontWeight.`.
- Tests find app strings through `lookupAppLocalizations(Locale(...))`, not English literals.
- The phase gate has six steps: the five phase-1 steps plus `python tools/docs/check.py` (ruling G2). All must exit 0.
- Commits are conventional (`ui`, `app`, `l10n`, `chore`), ending `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Replies to the user are in Vietnamese.

## Rulings made while planning (carried into the spec by Task 6)

- **G1:** The gallery is a debug-only developer surface, compiled out of release by `includeGallery`. Its section titles, toggle labels and demo copy stay English literals and are not put in the ARB files. The guard's i18n rule does not scope `lib/app/`. Spec §6 said gallery strings would be localized; it is amended.
- **G2:** `dod_check.sh` cannot pass yet. Its generated-code step fails with zero scope until the backend adds Riverpod/Drift codegen, and its docs step reports 54 false errors on a Windows CRLF checkout.
  - This phase fixes the second: `.gitattributes` makes every checkout LF. A trial LF checkout gave `tools/docs/check.py` → `PASS — 0 error(s)`.
  - The phase gate stays the five steps plus the docs check. `dod_check.sh` becomes the gate once backend codegen exists (spec §8.3 amended).
- **G3:** There is no Android emulator on this machine; `flutter devices` lists only Chrome and Edge, and the project has no web target. The spec's "run the app and capture the gallery" check becomes app-level goldens instead: the Library tab and the gallery, light and dark, at 3x.
- **G4:** Placeholder bodies use `MxEmptyState` in the neutral tone, "a fact, not a failure" per the EmptyState contract.

## Review Focus

1. **Router state across widget tests.** A `GoRouter` built at top level would carry one test's location into the next. `MemoxApp` builds its router in `initState` and disposes it. Pinned by every app test starting at `/decks`.
2. **Locale fallback.** A device locale that is neither `en` nor `vi` (for example `fr`) must fall back to English, not crash on a missing delegate. Pinned in Task 3.
3. **Re-tapping the current tab** must return that branch to its root (`goBranch(initialLocation: true)`), not no-op or rebuild the whole shell. Pinned in Task 3.
4. **Gallery in release.** With `includeGallery: false`, neither the route nor the Settings action may exist, or a release build ships a developer screen. Pinned in Task 4.
5. **Inset through two nested shells.** Each tab screen is an `MxAppShell` inside the tab shell's `MxAppShell`. The status inset must be consumed once at the top, and the nav must still own the bottom inset. Pinned by the Library golden and an inset test in Task 3.

---

## File Structure

```
.gitattributes                                  every checkout LF; Windows scripts CRLF
.gitignore                                      + lib/l10n/generated/
pubspec.yaml                                    + flutter_localizations, intl, generate: true, OFL.txt asset
l10n.yaml                                       gen-l10n config
lib/l10n/app_en.arb, app_vi.arb                 product strings
lib/l10n/l10n_context.dart                      context.l10n
lib/core/theme/foundations/app_icons.dart       + gallery, themeMode, textScale
lib/main.dart                                   ProviderScope(child: MemoxApp())
lib/app/app.dart                                MemoxApp
lib/app/font_license.dart                       registerFontLicense()
lib/app/placeholder_screen.dart                 PlaceholderScreen
lib/app/router/app_routes.dart                  AppRoutes
lib/app/router/app_router.dart                  buildAppRouter, the tab shell
lib/app/gallery/gallery_screen.dart             GalleryScreen
lib/app/gallery/gallery_section.dart            GallerySection frame
lib/app/gallery/gallery_actions_section.dart    B · actions
lib/app/gallery/gallery_chrome_section.dart     A · chrome and navigation
lib/app/gallery/gallery_states_section.dart     G · loading, empty, error
lib/app/gallery/gallery_layout_section.dart     H · layout shell
code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml   − arb_entry_needs_description
test/support/golden_harness.dart                + goldenBoundaryKey, expectBoundaryGolden
test/app/l10n_test.dart
test/app/font_license_test.dart
test/app/app_test.dart
test/app/gallery_test.dart
test/app/app_golden_test.dart, test/app/goldens/*.png
docs/superpowers/plans/2026-09-23-memox-v8-foundation.md   Task 10 text only
docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md  §6, §8.3, §9
```

---

### Task 1: LF checkouts, and the docs check in the gate

**Files:**
- Create: `.gitattributes`

- [ ] **Step 1: Show the failure**

Run: `python tools/docs/check.py`
Expected: `FAIL — 54 error(s)`. 51 are "differs from a fresh split of the JSON" and 3 are `docs/_generated/*` "stale". `git ls-files --eol docs/shared/ui/design-handoff/widgets/toggle.md` shows `i/lf w/crlf`.

- [ ] **Step 2: Add `.gitattributes`**

```gitattributes
# Every text file is checked out with LF, whatever core.autocrlf says, so a
# Windows checkout matches what generators write (tools/docs/check.py compares
# byte for byte). Windows-only scripts keep CRLF.
* text=auto eol=lf
*.bat text eol=crlf
*.cmd text eol=crlf
*.ps1 text eol=crlf
```

- [ ] **Step 3: Commit it, then re-check out the tree**

The tree must be clean first (`git status --short` prints nothing apart from `.gitattributes`).

```bash
git add .gitattributes
git commit -m "chore: check out text files with LF on every platform

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git rm -r -q --cached .
git reset -q --hard HEAD
git status --short
git ls-files --eol docs/shared/ui/design-handoff/widgets/toggle.md
```

Expected: `git status --short` prints nothing, and the last line shows `i/lf w/lf`. `reset --hard` here only rewrites line endings of committed files. Nothing uncommitted exists at this point.

- [ ] **Step 4: Verify**

```bash
python tools/docs/check.py
flutter analyze
flutter test
```

Expected: `PASS — 0 error(s)` (warnings are allowed), analyze clean, and all tests pass. Goldens are PNG and unaffected.

---

### Task 2: Localization

**Files:**
- Create: `l10n.yaml`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`, `lib/l10n/l10n_context.dart`
- Modify: `pubspec.yaml`, `.gitignore`, `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`
- Test: `test/app/l10n_test.dart`

**Interfaces:**
- Produces:
  - `AppLocalizations` (generated): `appTitle, navLibrary, navStudy, navProgress, navSettings, placeholderTitle, placeholderBody, openGallery`
  - `lookupAppLocalizations(Locale)`
  - `context.l10n` → `AppLocalizations`, from `package:memox/l10n/l10n_context.dart`

- [ ] **Step 1: Write the failing test**

`test/app/l10n_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

Iterable<String> _keys(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@'));

void main() {
  test('every template key has a description and a Vietnamese value', () {
    final en = _arb('en');
    final vi = _arb('vi');

    for (final key in _keys(en)) {
      final meta = en['@$key'] as Map<String, dynamic>?;
      expect(meta?['description'], isA<String>(), reason: key);
      expect(vi[key], isA<String>().having((v) => v.trim(), 'value', isNotEmpty), reason: key);
    }
    expect(_keys(vi).toSet(), _keys(en).toSet());
  });

  test('the tab labels follow navigation.md in both languages', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final vi = lookupAppLocalizations(const Locale('vi'));

    expect(
      [en.navLibrary, en.navStudy, en.navProgress, en.navSettings],
      ['Library', 'Study', 'Progress', 'Settings'],
    );
    expect(
      [vi.navLibrary, vi.navStudy, vi.navProgress, vi.navSettings],
      ['Thư viện', 'Học', 'Tiến độ', 'Cài đặt'],
    );
  });

  testWidgets('context.l10n resolves the active locale', (tester) async {
    late String title;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            title = context.l10n.placeholderTitle;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(title, 'Sắp có');
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/app/l10n_test.dart`
Expected: FAIL, because `lib/l10n/generated/app_localizations.dart` does not exist.

- [ ] **Step 3: Configure gen-l10n and write the ARB files**

In `pubspec.yaml`, add under `dependencies:` (keep alphabetical order):

```yaml
  flutter_localizations:
    sdk: flutter
```

```yaml
  intl: any
```

Replace the `flutter:` section header lines with:

```yaml
flutter:
  generate: true
  uses-material-design: true
  assets:
    # Shipped for the licence page (font_license.dart), as the OFL requires.
    - assets/fonts/OFL.txt
```

Keep the existing `fonts:` block unchanged below it.

`l10n.yaml`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-dir: lib/l10n/generated
output-localization-file: app_localizations.dart
nullable-getter: false
```

Append to `.gitignore`:

```gitignore

# generated by gen-l10n (flutter pub get / flutter test)
lib/l10n/generated/
```

`lib/l10n/app_en.arb`:

```json
{
  "@@locale": "en",
  "appTitle": "MemoX",
  "@appTitle": {
    "description": "App name in the task switcher."
  },
  "navLibrary": "Library",
  "@navLibrary": {
    "description": "Bottom navigation: the deck library tab (navigation.md: Thư viện)."
  },
  "navStudy": "Study",
  "@navStudy": {
    "description": "Bottom navigation: the study tab."
  },
  "navProgress": "Progress",
  "@navProgress": {
    "description": "Bottom navigation: the progress tab."
  },
  "navSettings": "Settings",
  "@navSettings": {
    "description": "Bottom navigation: the settings tab."
  },
  "placeholderTitle": "Coming soon",
  "@placeholderTitle": {
    "description": "Title on a tab whose screen is not built yet."
  },
  "placeholderBody": "This screen is being built.",
  "@placeholderBody": {
    "description": "Line under placeholderTitle."
  },
  "openGallery": "Component gallery",
  "@openGallery": {
    "description": "Debug builds only: the Settings action that opens the component gallery."
  }
}
```

`lib/l10n/app_vi.arb`:

```json
{
  "@@locale": "vi",
  "appTitle": "MemoX",
  "navLibrary": "Thư viện",
  "navStudy": "Học",
  "navProgress": "Tiến độ",
  "navSettings": "Cài đặt",
  "placeholderTitle": "Sắp có",
  "placeholderBody": "Màn hình này đang được xây dựng.",
  "openGallery": "Thư viện component"
}
```

`lib/l10n/l10n_context.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The one way UI code reads its strings.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
```

Run: `flutter pub get`
Expected: exit 0, and `lib/l10n/generated/app_localizations.dart`, `_en.dart` and `_vi.dart` exist.

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/app/l10n_test.dart`
Expected: PASS, 3 tests.

- [ ] **Step 5: Retire the ARB guard entry**

Run: `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`
Expected: exactly one `stale_targets_pending`, for `memox.i18n.arb_entry_needs_description`. A trial on 2026-09-23 showed the same.

In `overrides.yaml`, delete its two lines and the comment line above them (`# -- \`l10n\`: waits for lib/l10n/app_en.arb …`). Re-run. Expected: `Errors: 0 | Warnings: 0`.

- [ ] **Step 6: Gate, commit**

```bash
dart format lib test
flutter analyze
flutter test
python tools/docs/check.py
git status --short
git add pubspec.yaml pubspec.lock l10n.yaml .gitignore lib/l10n test/app/l10n_test.dart code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml
git commit -m "feat(l10n): gen-l10n with English and Vietnamese product strings

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Expected: `git status` does not list `lib/l10n/generated/` (it is ignored).

---

### Task 3: MemoxApp, the router, the tab shell and placeholders

**Files:**
- Create: `lib/app/app.dart`, `lib/app/font_license.dart`, `lib/app/placeholder_screen.dart`, `lib/app/router/app_routes.dart`, `lib/app/router/app_router.dart`
- Modify: `lib/main.dart`, `lib/core/theme/foundations/app_icons.dart`
- Test: `test/app/app_test.dart`, `test/app/font_license_test.dart`

**Interfaces:**
- Consumes: `context.l10n` and `lookupAppLocalizations` (Task 2); `MxAppShell`, `MxAppBar`, `MxBottomNav`, `MxNavDestination`, `MxScreenScroll`, `MxEmptyState`, `MxIconButton` (phase 2).
- Produces:
  - `MemoxApp({bool includeGallery = kDebugMode})`
  - `GoRouter buildAppRouter({bool includeGallery = kDebugMode})`
  - `AppRoutes.decks/study/progress/settings/gallery` (`String`)
  - `PlaceholderScreen({required String title, VoidCallback? onOpenGallery})`
  - `registerFontLicense()`
  - `AppIcons.gallery`, `AppIcons.themeMode`, `AppIcons.textScale`
- Task 4 creates `GalleryScreen`. This task routes `/gallery` to a temporary `Placeholder()` so the route exists. Task 4 swaps it (see Task 4 Step 3).

- [ ] **Step 1: Write the failing tests**

`test/app/font_license_test.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/font_license.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the Plus Jakarta Sans OFL notice is on the licence page', () async {
    registerFontLicense();

    final entries = await LicenseRegistry.licenses.toList();
    final font = entries.where((e) => e.packages.contains('Plus Jakarta Sans'));
    expect(font, isNotEmpty);
    expect(
      font.first.paragraphs.map((p) => p.text).join(' '),
      contains('SIL Open Font License'),
    );
  });
}
```

`test/app/app_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _pumpApp(WidgetTester tester, {bool includeGallery = true}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(child: MemoxApp(includeGallery: includeGallery)),
  );
  await tester.pumpAndSettle();
}

Finder _barTitle(String title, {bool skipOffstage = true}) => find.descendant(
  of: find.byType(MxAppBar, skipOffstage: skipOffstage),
  matching: find.text(title, skipOffstage: skipOffstage),
  skipOffstage: skipOffstage,
);

MxBottomNav _nav(WidgetTester tester) =>
    tester.widget<MxBottomNav>(find.byType(MxBottomNav));

/// A tab label inside the bottom nav; the app bar may show the same text.
Finder _tab(String label) => find.descendant(
  of: find.byType(MxBottomNav),
  matching: find.text(label),
);

void main() {
  testWidgets('cold start lands on Library', (tester) async {
    await _pumpApp(tester);

    expect(_barTitle(_en.navLibrary), findsOneWidget);
    expect(_nav(tester).selectedIndex, 0);
  });

  testWidgets('four tabs in navigation.md order', (tester) async {
    await _pumpApp(tester);

    expect(_nav(tester).destinations.map((d) => d.label), [
      _en.navLibrary,
      _en.navStudy,
      _en.navProgress,
      _en.navSettings,
    ]);
  });

  testWidgets('switching tabs keeps the other branch alive', (tester) async {
    await _pumpApp(tester);
    await tester.tap(_tab(_en.navStudy));
    await tester.pumpAndSettle();

    expect(_nav(tester).selectedIndex, 1);
    expect(_barTitle(_en.navStudy), findsOneWidget);
    expect(_barTitle(_en.navLibrary, skipOffstage: false), findsOneWidget);
  });

  testWidgets('re-tapping the current tab keeps it selected', (tester) async {
    await _pumpApp(tester);
    await tester.tap(_tab(_en.navLibrary));
    await tester.pumpAndSettle();

    expect(_nav(tester).selectedIndex, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('each tab shows the neutral placeholder', (tester) async {
    await _pumpApp(tester);

    expect(find.text(_en.placeholderTitle), findsOneWidget);
    expect(find.text(_en.placeholderBody), findsOneWidget);
  });

  testWidgets('Vietnamese device locale gives Vietnamese tabs', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('vi')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await _pumpApp(tester);
    final vi = lookupAppLocalizations(const Locale('vi'));

    expect(_nav(tester).destinations.map((d) => d.label), [
      vi.navLibrary,
      vi.navStudy,
      vi.navProgress,
      vi.navSettings,
    ]);
  });

  testWidgets('an unsupported locale falls back to English', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await _pumpApp(tester);

    expect(_barTitle(_en.navLibrary), findsOneWidget);
  });

  testWidgets('dark system theme gives the dark page ground', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _pumpApp(tester);

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
      AppColorSchemes.dark.surface,
    );
  });

  testWidgets('the status inset is consumed once, above the tab app bar', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 72, bottom: 60);
    addTearDown(tester.view.resetPadding);
    await _pumpApp(tester);

    // 72 physical px at 3x = 24 logical.
    expect(tester.getTopLeft(find.byType(MxAppBar)).dy, 24);
    expect(
      tester.getSize(find.byType(MxAppBar)).height,
      56,
    );
  });

  testWidgets('Settings offers the gallery in debug builds', (tester) async {
    await _pumpApp(tester);
    await tester.tap(_tab(_en.navSettings));
    await tester.pumpAndSettle();

    expect(find.byTooltip(_en.openGallery), findsOneWidget);
  });

  testWidgets('without the gallery there is no route and no action', (
    tester,
  ) async {
    await _pumpApp(tester, includeGallery: false);
    await tester.tap(_tab(_en.navSettings));
    await tester.pumpAndSettle();

    expect(find.byTooltip(_en.openGallery), findsNothing);
    final router = buildAppRouter(includeGallery: false);
    addTearDown(router.dispose);
    expect(
      router.configuration.routes.whereType<GoRoute>().map((r) => r.path),
      isNot(contains(AppRoutes.gallery)),
    );
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/app/app_test.dart test/app/font_license_test.dart`
Expected: FAIL, because `app.dart`, `font_license.dart` and the router files do not exist.

- [ ] **Step 3: Implement**

Add to `lib/core/theme/foundations/app_icons.dart`, after `tag`:

```dart

  // Debug gallery.
  static const IconData gallery = Icons.widgets_outlined;
  static const IconData themeMode = Icons.contrast;
  static const IconData textScale = Icons.format_size;
```

`lib/app/router/app_routes.dart`:

```dart
/// Route paths. The four top-level branches are in bottom-nav order
/// (navigation.md); the app opens on [decks].
abstract final class AppRoutes {
  static const String decks = '/decks';
  static const String study = '/study';
  static const String progress = '/progress';
  static const String settings = '/settings';

  /// Debug builds only: the component gallery.
  static const String gallery = '/gallery';
}
```

`lib/app/font_license.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const String _oflAsset = 'assets/fonts/OFL.txt';
const String _fontPackage = 'Plus Jakarta Sans';

var _isRegistered = false;

/// Puts the bundled font's SIL Open Font License on the licence page, as the
/// licence requires of anyone shipping the font. Safe to call more than once.
void registerFontLicense() {
  if (_isRegistered) return;
  _isRegistered = true;
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString(_oflAsset);
    yield LicenseEntryWithLineBreaks(const [_fontPackage], text);
  });
}
```

`lib/app/placeholder_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// The stand-in for a tab whose feature screen is not built yet. The
/// feature's first real screen replaces it in its branch.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, this.onOpenGallery});

  final String title;

  /// Debug builds only: opens the component gallery.
  final VoidCallback? onOpenGallery;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(
        title: title,
        actions: [
          if (onOpenGallery case final openGallery?)
            MxIconButton(
              icon: AppIcons.gallery,
              semanticLabel: l10n.openGallery,
              onPressed: openGallery,
            ),
        ],
      ),
      body: MxScreenScroll(
        children: [
          // Ruling G4: a fact, not a failure.
          MxEmptyState(
            icon: AppIcons.inbox,
            title: l10n.placeholderTitle,
            body: l10n.placeholderBody,
            tone: MxEmptyStateTone.neutral,
          ),
        ],
      ),
    );
  }
}
```

`lib/app/router/app_router.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/placeholder_screen.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

/// The app's routes: four top-level branches in a stateful shell, each
/// keeping its own stack, plus the component gallery when [includeGallery]
/// (debug builds by default, so release builds never register it).
GoRouter buildAppRouter({bool includeGallery = kDebugMode}) => GoRouter(
  initialLocation: AppRoutes.decks,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _TabShell(navigationShell: navigationShell),
      branches: [
        _branch(AppRoutes.decks, (context) => context.l10n.navLibrary),
        _branch(AppRoutes.study, (context) => context.l10n.navStudy),
        _branch(AppRoutes.progress, (context) => context.l10n.navProgress),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => PlaceholderScreen(
                title: context.l10n.navSettings,
                onOpenGallery: includeGallery
                    ? () => context.push(AppRoutes.gallery)
                    : null,
              ),
            ),
          ],
        ),
      ],
    ),
    if (includeGallery)
      GoRoute(
        path: AppRoutes.gallery,
        builder: (context, state) => const Placeholder(),
      ),
  ],
);

StatefulShellBranch _branch(
  String path,
  String Function(BuildContext) title,
) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      builder: (context, state) => PlaceholderScreen(title: title(context)),
    ),
  ],
);

/// The bottom nav around the current branch.
class _TabShell extends StatelessWidget {
  const _TabShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxAppShell(
      body: navigationShell,
      bottomBar: MxBottomNav(
        destinations: [
          MxNavDestination(
            icon: AppIcons.library,
            selectedIcon: AppIcons.librarySelected,
            label: l10n.navLibrary,
          ),
          MxNavDestination(
            icon: AppIcons.study,
            selectedIcon: AppIcons.studySelected,
            label: l10n.navStudy,
          ),
          MxNavDestination(
            icon: AppIcons.progress,
            selectedIcon: AppIcons.progressSelected,
            label: l10n.navProgress,
          ),
          MxNavDestination(
            icon: AppIcons.settings,
            selectedIcon: AppIcons.settingsSelected,
            label: l10n.navSettings,
          ),
        ],
        selectedIndex: navigationShell.currentIndex,
        // Re-tapping the current tab returns its branch to its root.
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
```

`lib/app/app.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/font_license.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The composition root: themes, localization and the router.
class MemoxApp extends StatefulWidget {
  const MemoxApp({super.key, this.includeGallery = kDebugMode});

  /// Registers the debug-only component gallery.
  final bool includeGallery;

  @override
  State<MemoxApp> createState() => _MemoxAppState();
}

class _MemoxAppState extends State<MemoxApp> {
  // Owned here, not at top level, so each app instance starts at its initial
  // location and a disposed app releases its router.
  late final GoRouter _router = buildAppRouter(
    includeGallery: widget.includeGallery,
  );

  @override
  void initState() {
    super.initState();
    // Android 15 draws edge-to-edge regardless; earlier versions opt in here.
    // Every inset is read from MediaQuery.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    registerFontLicense();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    theme: buildLightTheme(),
    darkTheme: buildDarkTheme(),
    // The system choice until the settings feature persists one
    // (BR-SETTINGS-005, BR-SETTINGS-006).
    themeMode: ThemeMode.system,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: _router,
  );
}
```

`lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/app/app.dart';

void main() {
  runApp(const ProviderScope(child: MemoxApp()));
}
```

- [ ] **Step 4: Run them to verify they pass**

Run: `flutter test test/app/app_test.dart test/app/font_license_test.dart`
Expected: PASS, 11 + 1 tests.

If "the status inset is consumed once" fails with the bar at 48 (inset counted twice), the tab shell's `SafeArea` and the placeholder's `MxAppBar` `SafeArea` both consumed it. Debug with superpowers:systematic-debugging. The fix belongs in `MxAppShell` (one owner of the top inset), not in the test.

- [ ] **Step 5: Gate, commit**

```bash
dart format lib test
flutter analyze
flutter test
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/main.dart lib/app lib/core/theme/foundations/app_icons.dart test/app
git commit -m "feat(app): four-tab shell with localized placeholders

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Expected: every command exits 0, and the guard reports `Errors: 0 | Warnings: 0` before the commit runs.

---

### Task 4: The debug component gallery

**Files:**
- Create: `lib/app/gallery/gallery_screen.dart`, `gallery_section.dart`, `gallery_actions_section.dart`, `gallery_chrome_section.dart`, `gallery_states_section.dart`, `gallery_layout_section.dart`
- Modify: `lib/app/router/app_router.dart` (the `/gallery` builder)
- Test: `test/app/gallery_test.dart`

**Interfaces:**
- Consumes: every phase-2 widget; `AppIcons.themeMode/textScale/back`; `buildLightTheme`/`buildDarkTheme`.
- Produces: `GalleryScreen()`, and `GallerySection({required String title, required List<Widget> children})`.

- [ ] **Step 1: Write the failing test**

`test/app/gallery_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/gallery/gallery_screen.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';

Future<void> _pumpGallery(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const GalleryScreen(),
    ),
  );
  await tester.pump();
}

/// Scrolls the whole gallery so every lazily built section is laid out.
Future<void> _scrollThrough(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  testWidgets('every section renders without an exception', (tester) async {
    await _pumpGallery(tester);
    await _scrollThrough(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('the four phase-2 groups are present', (tester) async {
    await _pumpGallery(tester);

    for (final title in [
      'B · Actions',
      'A · Chrome & navigation',
      'G · Loading, empty & error',
      'H · Layout',
    ]) {
      await tester.scrollUntilVisible(
        find.text(title),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('the theme switch flips the gallery to dark', (tester) async {
    await _pumpGallery(tester);
    await tester.tap(find.byTooltip('Dark theme'));
    await tester.pump();

    expect(
      Theme.of(tester.element(find.byType(MxAppBar).first)).brightness,
      Brightness.dark,
    );
  });

  testWidgets('the text switch renders everything at 2x', (tester) async {
    await _pumpGallery(tester);
    await tester.tap(find.byTooltip('Large text'));
    await tester.pump();

    expect(
      MediaQuery.textScalerOf(
        tester.element(find.byType(MxAppBar).first),
      ).scale(10),
      20,
    );
    await _scrollThrough(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings opens the gallery and back returns', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final en = lookupAppLocalizations(const Locale('en'));
    await tester.pumpWidget(const ProviderScope(child: MemoxApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.navSettings));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(en.openGallery));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(GalleryScreen), findsOneWidget);

    // The page's own back comes first; the chrome demos also say 'Back'.
    await tester.tap(find.byTooltip('Back').first);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(GalleryScreen), findsNothing);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/app/gallery_test.dart`
Expected: FAIL, because `gallery_screen.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/app/gallery/gallery_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// One handoff group in the gallery: its title, then its widgets.
class GallerySection extends StatelessWidget {
  const GallerySection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.major),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.grouped,
      children: [
        Text(title, style: context.texts.titleLarge),
        ...children,
      ],
    ),
  );
}
```

`lib/app/gallery/gallery_actions_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// Group B: every Button tone, size and state, and the IconButton.
class GalleryActionsSection extends StatelessWidget {
  const GalleryActionsSection({super.key});

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'B · Actions',
    children: [
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        children: [
          for (final tone in MxButtonTone.values)
            MxButton(label: tone.name, tone: tone, onPressed: () {}),
        ],
      ),
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          MxButton(
            label: 'Small',
            size: MxButtonSize.small,
            icon: AppIcons.add,
            onPressed: () {},
          ),
          MxButton(
            label: 'Compact',
            size: MxButtonSize.compact,
            onPressed: () {},
          ),
          MxButton(label: 'Chip', size: MxButtonSize.chip, onPressed: () {}),
          MxButton(label: 'Reveal', size: MxButtonSize.study, onPressed: () {}),
        ],
      ),
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        children: [
          const MxButton(label: 'Disabled', onPressed: null),
          MxButton(label: 'Saving', isLoading: true, onPressed: () {}),
        ],
      ),
      MxButton(
        label: 'A block action whose label is long enough to wrap',
        icon: AppIcons.play,
        isBlock: true,
        onPressed: () {},
      ),
      Row(
        children: [
          MxIconButton(icon: AppIcons.back, semanticLabel: 'Back', onPressed: () {}),
          MxIconButton(icon: AppIcons.search, semanticLabel: 'Search', onPressed: () {}),
          MxIconButton(icon: AppIcons.more, semanticLabel: 'More', onPressed: () {}),
          const MxIconButton(icon: AppIcons.close, semanticLabel: 'Close', onPressed: null),
        ],
      ),
    ],
  );
}
```

`lib/app/gallery/gallery_chrome_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';

/// Group A: the app bars, study bar, breadcrumb, bottom nav and FAB.
class GalleryChromeSection extends StatelessWidget {
  const GalleryChromeSection({super.key});

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'A · Chrome & navigation',
    children: [
      const MxAppBar(title: 'Library'),
      MxAppBar(
        title: 'Japanese N5 · Verbs of motion and a very long deck name',
        density: MxAppBarDensity.content,
        leading: MxIconButton(icon: AppIcons.back, semanticLabel: 'Back', onPressed: () {}),
        actions: [
          MxIconButton(icon: AppIcons.search, semanticLabel: 'Search', onPressed: () {}),
          MxIconButton(icon: AppIcons.more, semanticLabel: 'More', onPressed: () {}),
        ],
      ),
      MxStudyTopBar(
        modeLabel: 'Review',
        current: 3,
        total: 10,
        counterLabel: '3 / 10',
        closeLabel: 'Close',
        onClose: () {},
      ),
      MxStudyTopBar(
        modeLabel: 'Recall',
        current: 10,
        total: 10,
        counterLabel: '10 / 10',
        closeLabel: 'Close',
        onClose: () {},
        accent: context.semanticColors.mastery,
      ),
      MxBreadcrumb(
        segments: [
          for (var level = 1; level < 10; level++)
            MxBreadcrumbSegment(label: 'Level $level', onTap: () {}),
          const MxBreadcrumbSegment(label: 'Level 10'),
        ],
      ),
      MxBottomNav(
        destinations: const [
          MxNavDestination(icon: AppIcons.library, selectedIcon: AppIcons.librarySelected, label: 'Library'),
          MxNavDestination(icon: AppIcons.study, selectedIcon: AppIcons.studySelected, label: 'Study'),
          MxNavDestination(icon: AppIcons.progress, selectedIcon: AppIcons.progressSelected, label: 'Progress'),
          MxNavDestination(icon: AppIcons.settings, selectedIcon: AppIcons.settingsSelected, label: 'Settings'),
        ],
        selectedIndex: 0,
        onSelected: (_) {},
      ),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: MxFab(icon: AppIcons.add, semanticLabel: 'New deck', onPressed: () {}),
      ),
    ],
  );
}
```

`lib/app/gallery/gallery_states_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

/// Group G: the empty state in each tone (Skeleton, Spinner and ErrorState
/// join in phase 6).
class GalleryStatesSection extends StatelessWidget {
  const GalleryStatesSection({super.key});

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'G · Loading, empty & error',
    children: [
      MxEmptyState(
        icon: AppIcons.inbox,
        title: 'No decks yet',
        body: 'Create a deck or add a starter deck to begin.',
        actionLabel: 'Create deck',
        onAction: () {},
      ),
      for (final tone in MxEmptyStateTone.values.skip(1))
        MxEmptyState(
          icon: AppIcons.search,
          title: tone.name,
          body: 'Compact, ${tone.name} tone.',
          tone: tone,
          isCompact: true,
        ),
    ],
  );
}
```

`lib/app/gallery/gallery_layout_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';

/// Group H: the footer bar. MxAppShell and MxScreenScroll are this page's
/// own frame.
class GalleryLayoutSection extends StatelessWidget {
  const GalleryLayoutSection({super.key});

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'H · Layout',
    children: [
      MxFooterBar(
        caption: '12 cards selected',
        child: MxButton(label: 'Move', isBlock: true, onPressed: () {}),
      ),
    ],
  );
}
```

`lib/app/gallery/gallery_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/app/gallery/gallery_actions_section.dart';
import 'package:memox/app/gallery/gallery_chrome_section.dart';
import 'package:memox/app/gallery/gallery_layout_section.dart';
import 'package:memox/app/gallery/gallery_states_section.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// Debug builds only (ruling G1): every shared widget in its variants and
/// states, under a local light/dark and 1x/2x text switch.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  static const double _largeTextScale = 2;

  var _isDark = false;
  var _isLargeText = false;

  @override
  Widget build(BuildContext context) => Theme(
    data: _isDark ? buildDarkTheme() : buildLightTheme(),
    child: MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: _isLargeText
            ? const TextScaler.linear(_largeTextScale)
            : TextScaler.noScaling,
      ),
      child: MxAppShell(
        appBar: MxAppBar(
          title: 'Gallery',
          density: MxAppBarDensity.content,
          leading: MxIconButton(
            icon: AppIcons.back,
            semanticLabel: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            MxIconButton(
              icon: AppIcons.themeMode,
              semanticLabel: _isDark ? 'Light theme' : 'Dark theme',
              onPressed: () => setState(() => _isDark = !_isDark),
            ),
            MxIconButton(
              icon: AppIcons.textScale,
              semanticLabel: _isLargeText ? 'Normal text' : 'Large text',
              onPressed: () => setState(() => _isLargeText = !_isLargeText),
            ),
          ],
        ),
        body: const MxScreenScroll(
          children: [
            GalleryActionsSection(),
            GalleryChromeSection(),
            GalleryStatesSection(),
            GalleryLayoutSection(),
          ],
        ),
      ),
    ),
  );
}
```

In `lib/app/router/app_router.dart`, replace the temporary builder and add the import:

```dart
import 'package:memox/app/gallery/gallery_screen.dart';
```

```dart
        builder: (context, state) => const GalleryScreen(),
```

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/app/gallery_test.dart`
Expected: PASS, 5 tests.

If "every section renders" fails with an overflow, a phase-2 widget breaks inside the gallery's layout. Find the widget in the exception and fix it through systematic-debugging, not by changing the gallery around it.

- [ ] **Step 5: Gate, commit**

Same commands as Task 3 Step 5. Commit message: `feat(app): debug component gallery`. Stage `lib/app` and `test/app`.

---

### Task 5: App-level goldens (visual evidence, ruling G3)

**Files:**
- Modify: `test/support/golden_harness.dart`
- Create: `test/app/app_golden_test.dart`, `test/app/goldens/*.png`

**Interfaces:**
- Produces, in `golden_harness.dart`:
  - `const Key goldenBoundaryKey`
  - `Future<void> expectBoundaryGolden(WidgetTester tester, String path)`, which captures the `RepaintBoundary` keyed `goldenBoundaryKey` at 3x with real shadows

- [ ] **Step 1: Extract the capture into the harness**

In `test/support/golden_harness.dart`, rename `_boundaryKey` to `goldenBoundaryKey` (it is public now). Add the two functions below. Then make `expectThemedGoldens` run its whole loop inside `withRealShadows`, and replace its inline capture with `expectBoundaryGolden(tester, 'goldens/${name}_$suffix.png')`.

Shadows must be on while the tree is *painted*, not only while it is captured. Nested repaint boundaries (routes, list items) keep layers painted with blur off.

```dart
/// Runs [body] with shadow blur painted for real: flutter_test's default
/// draws shadows as hard shapes, and the shadow treatments are design truth.
/// Restores the default before the test's invariant check.
Future<void> withRealShadows(Future<void> Function() body) async {
  debugDisableShadows = false;
  try {
    await body();
  } finally {
    debugDisableShadows = true;
  }
}

/// Compares the RepaintBoundary keyed [goldenBoundaryKey], captured at 3x,
/// with the golden at [path] beside the calling test. Call it inside
/// [withRealShadows], after pumping.
Future<void> expectBoundaryGolden(WidgetTester tester, String path) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(goldenBoundaryKey),
  );
  final image = await tester.runAsync(
    () => boundary.toImage(pixelRatio: _goldenPixelRatio),
  );
  await expectLater(image, matchesGoldenFile(path));
  image!.dispose();
}
```

Run: `flutter test --tags golden test/shared/widgets/shared_widgets_golden_test.dart`
Expected: PASS. The component goldens are unchanged by the refactor. If a golden differs, the refactor changed what is painted: fix the harness, never regenerate those goldens.

- [ ] **Step 2: Write the app goldens**

`test/app/app_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../support/golden_harness.dart';

Future<void> _pumpApp(WidgetTester tester, Brightness brightness) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 72, bottom: 60);
  addTearDown(tester.view.reset);
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(
    const RepaintBoundary(
      key: goldenBoundaryKey,
      child: ProviderScope(child: MemoxApp()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  for (final brightness in Brightness.values) {
    testWidgets('Library tab, ${brightness.name}', (tester) async {
      await withRealShadows(() async {
        await _pumpApp(tester, brightness);
        await expectBoundaryGolden(
          tester,
          'goldens/app_library_${brightness.name}.png',
        );
      });
    });

    testWidgets('Gallery, ${brightness.name}', (tester) async {
      await withRealShadows(() async {
        await _pumpApp(tester, brightness);
        await tester.tap(find.text(en.navSettings));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(en.openGallery));
        await tester.pump(const Duration(seconds: 1));
        if (brightness == Brightness.dark) {
          await tester.tap(find.byTooltip('Dark theme'));
          await tester.pump(const Duration(milliseconds: 300));
        }
        await expectBoundaryGolden(
          tester,
          'goldens/app_gallery_${brightness.name}.png',
        );
      });
    });
  }
}
```

- [ ] **Step 3: Generate and look**

```bash
flutter test --update-goldens --tags golden test/app/app_golden_test.dart
flutter test --tags golden test/app/app_golden_test.dart
```

Expected: 4 PNGs at 1080×2400, and the second run passes. Open all four with the Read tool:
- **Library:** the status inset clear at the top, "Library" at 24/700, the neutral placeholder card, and the glass nav with Library selected, clear of the gesture inset at the bottom.
- **Gallery:** the content app bar with back, theme and text actions, and group B at the top.
- **Dark:** Tokyo Nebula grounds and surfaces in both.

A mismatch is a code defect: fix it and regenerate.

- [ ] **Step 4: Gate, commit**

```bash
dart format lib test
flutter analyze
flutter test
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add test/support/golden_harness.dart test/app
git commit -m "test(app): Library and gallery goldens, light and dark, at 3x

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: The foundation plan boundary, spec amendments, gate, hand back

**Files:**
- Modify: `docs/superpowers/plans/2026-09-23-memox-v8-foundation.md` (Task 10, text only)
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (§6, §8.3, §9)

- [ ] **Step 1: Rewrite foundation plan Task 10 (spec §7)**

In `docs/superpowers/plans/2026-09-23-memox-v8-foundation.md`, replace everything from the line `### Task 10: Wiring (app shell, retry policy) and end-to-end smoke test` up to, but not including, the `---` line before `## Plan self-review`. The replacement is below, and it keeps Steps 5–6 (the smoke test) verbatim.

~~~markdown
### Task 10: Provider retry policy and end-to-end smoke test

The UI base sub-project already created `lib/main.dart`, `lib/app/app.dart`,
the router and `test/app/app_test.dart`
(spec `2026-09-23-flutter-ui-base-design.md` §7). This task adds only what the
backend owns. It does not create or restructure `app.dart` or the router, and
the `app` guard entries it used to retire are already gone.

**Files:**
- Modify: `lib/main.dart` (the existing `ProviderScope`)
- Test: `test/integration/foundation_smoke_test.dart`

**Interfaces:**
- Consumes: `deckRepositoryProvider`, `cardRepositoryProvider`,
  `scheduleRepositoryProvider` (Tasks 7–9); `databaseProvider` (Task 5).
- Produces: Riverpod retry disabled at the `ProviderScope` root.

- [ ] **Step 1: Disable provider retry in `lib/main.dart`**

```dart
void main() {
  runApp(
    const ProviderScope(
      // DB errors are mapped to Failure explicitly (core/error/failure.dart);
      // Riverpod's default retry-on-error would otherwise sit a failed
      // provider in a hidden retry loop while showing AsyncLoading.
      retry: _noRetry,
      child: MemoxApp(),
    ),
  );
}

Duration? _noRetry(int retryCount, Object error) => null;
```

Run: `flutter test test/app`
Expected: PASS. The app tests still pump `ProviderScope(child: MemoxApp())`.
~~~

After that block, keep the old Steps 5 and 6 (the smoke test and its run) renumbered as Steps 2 and 3. Then add:

~~~markdown
- [ ] **Step 4: Run the full gate and commit**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib/main.dart test/integration
git commit -m "feat(app): disable provider retry, add foundation smoke test" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
~~~

Delete the old Steps 1–4 and 7–8.

- [ ] **Step 2: Amend the spec**

In `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`:
1. §6 **l10n**, last bullet: replace "The only strings are those of the shell, the placeholder, the gallery and the components' built-in labels." with "The only strings are those of the shell, the placeholder and the gallery's entry action. The debug-only gallery's own labels and demo copy stay English literals (phase 3 ruling G1)."
2. §8.3: replace the bullet beginning "**From phase 3**" with: "**From phase 3** the gate adds `python tools/docs/check.py`. `dod_check.sh` becomes the gate once the backend adds Riverpod/Drift codegen; its generated-code step reports zero scope until then (phase 3 ruling G2)."
3. §9: append these rows after row 17.

```markdown
| 18 | No Android emulator on the development machine: the phase 3 visual check is app-level goldens (Library, gallery; light, dark; 3x) instead of a device run | phase 3 plan G3 |
| 19 | The debug gallery's labels and demo copy are English literals, not ARB strings | phase 3 plan G1 |
```

- [ ] **Step 3: Gate, scope, commit**

```bash
dart format lib test
flutter analyze
flutter test
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p "test_*.py"
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python tools/docs/check.py
git diff --name-only origin/master...HEAD
git add docs/superpowers
git commit -m "docs: foundation Task 10 keeps only the backend's part; phase 3 rulings

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Expected:
- All gate commands exit 0.
- The docs check prints `PASS — 0 error(s)`.
- The diff lists only `.gitattributes`, `.gitignore`, `pubspec.*`, `l10n.yaml`, `lib/main.dart`, `lib/app/`, `lib/l10n/`, `lib/core/theme/foundations/app_icons.dart`, `test/`, `overrides.yaml` and `docs/superpowers/`.

- [ ] **Step 4: Hand back**

Report to the user in Vietnamese:
- Test and golden counts, and the guard and docs results.
- Every execution ruling.
- The four app goldens, sent with SendUserFile.

Ask through the AskUserQuestion popup whether to open the PR, merge it, and continue to phase 4.
