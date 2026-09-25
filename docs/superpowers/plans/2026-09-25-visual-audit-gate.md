# Visual-audit companions and the dod_check gate (FE-D2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every production screen has a strict visual-audit companion, the guard's `targets_pending` list is empty, and `dod_check.sh` is the gate.

**Architecture:** A small V8 helper, `auditProductionScreen`, pumps a screen in both themes at 1x and 2x text. Each variant must lay out without an exception and meet flutter_test's tap-target guidelines (Android 48, iOS 44, labeled). A coverage test mirrors `lib/**/*_screen.dart` into `test/visual_audit/screens/` and requires one companion per screen that audits that screen. The guard keeps MX-VIS-001's `skip: true` rule and drops the rule that encodes V7's `memoxAuditTest`. `dod_check.sh` excludes the golden tag, because goldens come only from the Linux container, and defaults to `origin/master`.

**Tech Stack:** Flutter 3.47.5 `flutter_test` accessibility guidelines, Riverpod/Drift test harness (`test/support/library_harness.dart`), code-verification-guard-v2 (ruleset `memox-v8`), bash.

**Spec:** Owner-approved design (popup, 2026-09-25):
- "Companion V8 gọn": light and dark, text scale 1x and 2x, tap-target guidelines, no overflow, and a coverage test. Delete `not_exploratory`, keep `not_skipped`. Contrast waits for FE-C1.
- "Loại golden + base master": `dod_check.sh` full mode runs `--exclude-tags golden` with base `origin/master`, and README points at `dod_check.sh`. No hook and no CI.

Scope from `docs/wbs_FE.md` FE-D2.

## Global Constraints

- V7 is a reference, not a template: no port of V7's `memox_audit.dart` raster auditor.
- Goldens are generated and compared only in the Linux container. On Windows the gate runs `flutter test --exclude-tags golden`, never `--update-goldens`.
- A companion never contains `skip: true` (guard rule `memox.visual.production_screen_audit_not_skipped`).
- Companion path: `lib/<rest>/presentation/<dir>/<name>_screen.dart` maps to `test/visual_audit/screens/<rest>/<dir>/<name>_screen_visual_audit_test.dart`. A screen outside `presentation/` keeps its path under `lib/`.
- `lib/app/gallery/gallery_screen.dart` is exempt: the gallery is registered in debug builds only.
- Code, comments, commits and docs in `docs/` keep their language (the WBS is Vietnamese).

## Review Focus

- **The coverage scope silently stops matching.** A glob or path change must fail the coverage test, not pass it with zero screens. The test asserts that the screen list is non-empty and contains `deck_level_screen.dart`.
- **Windows path separators.** `Directory.listSync` yields `\` on Windows. The coverage test normalises paths before mirroring them.
- **A companion that audits the wrong widget.** Each variant asserts `find.byType(screen)` finds one widget, so a companion cannot pass by auditing a blank tree.
- **`pumpAndSettle` hanging on an endless animation** (skeleton pulse, spinner) in a loaded state. Companions seed data before pumping. The probe run on 2026-09-25 settled on every screen.
- **dod_check on a tree whose stamp already passed.** The stamp covers the script itself (it is tracked), so editing the script invalidates the stamp. Run with `--force` once to prove it.

---

### Task 1: The audit helper and the coverage test

**Files:**
- Create: `test/visual_audit/screen_audit.dart`
- Create: `test/visual_audit/screens/screen_audit_coverage_test.dart`

**Interfaces:**
- Produces: `typedef AuditPump = Future<void> Function(Brightness brightness, double textScale);` and `Future<void> auditProductionScreen(WidgetTester tester, {required Type screen, required AuditPump pump})`. The coverage test requires each companion to contain `auditProductionScreen(` and `screen: <ScreenClass>`.

- [ ] **Step 1: Write the helper**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps one variant of a screen: [brightness]'s theme at [textScale].
typedef AuditPump =
    Future<void> Function(Brightness brightness, double textScale);

/// The text scales every production screen is audited at: the default and
/// the 200% a low-vision user sets.
const List<double> auditTextScales = [1, 2];

/// The strict audit every production screen companion runs (MX-VIS-001).
///
/// Each theme at each text scale must show [screen], lay out without an
/// exception (an overflow fails the test), and meet Android's 48 dp and iOS's
/// 44 pt tap targets, with a label on every tappable node. Text contrast joins
/// when FE-C1 settles the palette.
Future<void> auditProductionScreen(
  WidgetTester tester, {
  required Type screen,
  required AuditPump pump,
}) async {
  final semantics = tester.ensureSemantics();
  try {
    for (final brightness in Brightness.values) {
      for (final scale in auditTextScales) {
        await pump(brightness, scale);
        await tester.pumpAndSettle();
        final variant = '${brightness.name} at ${scale}x text';
        expect(find.byType(screen), findsOneWidget, reason: variant);
        for (final guideline in [
          androidTapTargetGuideline,
          iOSTapTargetGuideline,
          labeledTapTargetGuideline,
        ]) {
          await expectLater(
            tester,
            meetsGuideline(guideline),
            reason: variant,
          );
        }
      }
    }
  } finally {
    semantics.dispose();
  }
}
```

- [ ] **Step 2: Write the coverage test**

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Debug-only tooling, not a production screen.
const Set<String> _exempt = {'lib/app/gallery/gallery_screen.dart'};

const String _companionRoot = 'test/visual_audit/screens';

/// Where [screenPath]'s companion lives: its path under `lib/` without the
/// `presentation/` segment, under [_companionRoot].
String companionFor(String screenPath) {
  final rest = screenPath
      .substring('lib/'.length)
      .replaceFirst('/presentation/', '/')
      .replaceFirst(RegExp(r'\.dart$'), '_visual_audit_test.dart');
  return '$_companionRoot/$rest';
}

/// `deck_level_screen.dart` → `DeckLevelScreen`.
String screenClassOf(String screenPath) => screenPath
    .split('/')
    .last
    .replaceFirst(RegExp(r'\.dart$'), '')
    .split('_')
    .map((part) => part[0].toUpperCase() + part.substring(1))
    .join();

List<String> _productionScreens() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path.replaceAll(r'\', '/'))
        .where((path) => path.endsWith('_screen.dart'))
        .where((path) => !_exempt.contains(path))
        .toList()
      ..sort();

void main() {
  test('a companion mirrors its screen without presentation/', () {
    expect(
      companionFor('lib/features/deck/presentation/screens/deck_level_screen.dart'),
      'test/visual_audit/screens/features/deck/screens/'
      'deck_level_screen_visual_audit_test.dart',
    );
    expect(
      companionFor('lib/app/placeholder_screen.dart'),
      'test/visual_audit/screens/app/placeholder_screen_visual_audit_test.dart',
    );
    expect(
      screenClassOf('lib/app/placeholder_screen.dart'),
      'PlaceholderScreen',
    );
  });

  test('the scan still finds the production screens', () {
    final screens = _productionScreens();
    expect(
      screens,
      contains('lib/features/deck/presentation/screens/deck_level_screen.dart'),
    );
    expect(screens, isNot(contains('lib/app/gallery/gallery_screen.dart')));
  });

  test('every production screen has a companion that audits it', () {
    final problems = <String>[];
    for (final screen in _productionScreens()) {
      final companion = File(companionFor(screen));
      if (!companion.existsSync()) {
        problems.add('$screen: no ${companion.path}');
        continue;
      }
      final text = companion.readAsStringSync();
      if (!text.contains('auditProductionScreen(')) {
        problems.add('${companion.path}: never calls auditProductionScreen');
      }
      if (!text.contains('screen: ${screenClassOf(screen)}')) {
        problems.add('${companion.path}: never audits ${screenClassOf(screen)}');
      }
    }
    expect(problems, isEmpty);
  });
}
```

- [ ] **Step 3: Run it to see it fail**

Run: `flutter test test/visual_audit`
Expected: FAIL in "every production screen has a companion that audits it". It lists 6 missing companions: `card_detail_screen`, `card_editor_screen`, `deck_algorithm_screen`, `deck_level_screen`, `deck_search_screen`, `placeholder_screen`. The other two tests pass.

- [ ] **Step 4: Commit**

```bash
git add test/visual_audit
git commit -m "test(visual-audit): the strict screen audit and its coverage test (FE-D2)"
```

### Task 2: Six companions

**Files:**
- Modify: `test/support/library_harness.dart`: add `cardDeckScreen`.
- Modify: `test/features/card/presentation/card_list_golden_test.dart`: use `cardDeckScreen` instead of its private `_screen`.
- Create:
  - `test/visual_audit/screens/features/deck/screens/deck_level_screen_visual_audit_test.dart`
  - `test/visual_audit/screens/features/deck/screens/deck_algorithm_screen_visual_audit_test.dart`
  - `test/visual_audit/screens/features/deck/screens/deck_search_screen_visual_audit_test.dart`
  - `test/visual_audit/screens/features/card/screens/card_editor_screen_visual_audit_test.dart`
  - `test/visual_audit/screens/features/card/screens/card_detail_screen_visual_audit_test.dart`
  - `test/visual_audit/screens/app/placeholder_screen_visual_audit_test.dart`

**Interfaces:**
- Consumes: `auditProductionScreen`, `AuditPump` (Task 1); `libraryTest`, `pumpLibraryScreen`, `deckScreen`, `deckAlgorithmScreen` (harness); `DeckFixtures.root/sub`, `insertCard`.
- Produces: `DeckLevelScreen cardDeckScreen(String deckId)`, the open deck as `app/` composes it: card list, card app bar, breadcrumb and FAB.

- [ ] **Step 1: Move the open-deck composition into the harness**

Move `_screen` from `card_list_golden_test.dart` into `library_harness.dart` as:

```dart
/// Screen 07: the open deck as `app/` composes it (A14).
DeckLevelScreen cardDeckScreen(String deckId) => deckScreen(
  deckId: deckId,
  cardContent: (view) => CardListSectionWidget(
    deckId: view.deck.id,
    algorithm: 'Eight boxes',
    onAddCard: () {},
    onOpenCard: (_) {},
  ),
  cardAppBar: (view, back, actions) =>
      CardDeckAppBarWidget(view: view, back: back, deckActions: actions),
  cardBreadcrumb: (id, child) =>
      CardDeckBreadcrumbWidget(deckId: id, child: child),
  cardFab: (id) => CardAddFabWidget(deckId: id, onAddCard: () {}),
);
```

Then replace the five `_screen(` calls in the golden test with `cardDeckScreen(` and move its imports. Goldens are unchanged, because the composition is the same.

- [ ] **Step 2: Write the companions**

The pattern, with `deck_level_screen_visual_audit_test.dart` in full:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';

import '../../../../../support/card_fixtures.dart';
import '../../../../../support/deck_fixtures.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 01, the Library root with decks', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'Words');
    await auditProductionScreen(
      tester,
      screen: DeckLevelScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        deckScreen(),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });

  libraryTest('screen 01, an empty Library', (tester, env) async {
    await auditProductionScreen(
      tester,
      screen: DeckLevelScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        deckScreen(),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });

  libraryTest('screen 01, an open deck of decks', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'Words');
    await auditProductionScreen(
      tester,
      screen: DeckLevelScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        deckScreen(deckId: korean.id),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });

  libraryTest('screen 07, an open deck of cards', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await insertCard(env.db, id: 'c1', deckId: korean.id, front: 'mul', back: 'water');
    await insertCard(
      env.db,
      id: 'c2',
      deckId: korean.id,
      front: 'sarang',
      back: 'love',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 24),
      isFlagged: true,
    );
    await auditProductionScreen(
      tester,
      screen: DeckLevelScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        cardDeckScreen(korean.id),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
```

The other companions follow the same shape: one `libraryTest` per state, and `screen:` set to the file's screen class.
- **`DeckAlgorithmScreen`** (screen 02): a root deck `Korean`, `deckAlgorithmScreen(deckId: korean.id)`.
- **`DeckSearchScreen`** (screen 04):
  - blank: `DeckSearchScreen(onOpenDeck: (_) {})` over decks `Korean › Words`;
  - with hits: the same, and inside `pump` after `pumpLibraryScreen`, `await tester.enterText(find.byType(EditableText), 'or');`.
- **`CardEditorScreen`** (screens 08 and 09):
  - create: `CardEditorScreen.create(deckId: korean.id, deckContext: _context)`;
  - edit: `CardEditorScreen.edit(cardId: 'c', deckContext: _context)` after `insertCard(env.db, id: 'c', deckId: korean.id, front: 'mul', back: 'water')`;
  - with `Widget _context(String deckId, String label) => DeckContextHeaderWidget(deckId: deckId, currentLabel: label);`.
- **`CardDetailScreen`** (screen 10): the card `c` above, learned 2026-09-01 and due 2026-09-26, box 3, `CardDetailScreen(cardId: 'c', deckContext: _context, onEdit: (_) {})`.
- **`PlaceholderScreen`**: `PlaceholderScreen(title: 'Study', onOpenGallery: () {})` through `pumpLibraryScreen` with a fresh `LibraryEnv`. `libraryTest` supplies it, even though the placeholder reads no data.

Relative import depth: companions under `test/visual_audit/screens/features/<f>/screens/` use `../../../../../support/` and `../../../../screen_audit.dart`. The placeholder companion under `test/visual_audit/screens/app/` uses `../../../support/` and `../../screen_audit.dart`.

- [ ] **Step 3: Run the audit tests**

Run: `flutter test test/visual_audit`
Expected: PASS, all companions and all 3 coverage tests. A guideline failure here is a real defect: fix the widget (TDD, with a focused widget test) and record a `Ruling:` line in the ledger.

- [ ] **Step 4: Run the card list goldens' host half**

Run: `flutter test --exclude-tags golden test/features/card`
Expected: PASS. The golden file itself is verified in the container during Task 4.

- [ ] **Step 5: Commit**

```bash
git add test/support/library_harness.dart test/features/card/presentation/card_list_golden_test.dart test/visual_audit
git commit -m "test(visual-audit): companions for screens 01, 02, 04, 07-10 and the tab placeholder (FE-D2)"
```

### Task 3: The guard's visual-audit layer is live

**Files:**
- Modify: `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-testing-rules.yaml`: delete rule `memox.visual.production_screen_audit_not_exploratory` and rewrite the MX-VIS-001 comment for V8.
- Modify: `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`: delete both `targets_pending: visual-audit` entries and the `visual-audit` line of the comment above them.

- [ ] **Step 1: Watch the guard ask for the change**

Run: `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`
Expected: two `guard.config.stale_targets_pending` warnings, one per MX-VIS-001 rule, because the rules now have targets.

- [ ] **Step 2: Apply the rule and override changes**

In `memox-testing-rules.yaml`, the MX-VIS-001 comment becomes:

```yaml
  # ---- MX-VIS-001 · production screen requires a strict visual audit -------
  #
  # Split across two enforcers on purpose.
  #
  # The guard reads one file at a time, so it owns what a single companion file
  # must not contain: a skip. The other half — "for every screen in lib, a
  # companion exists and runs `auditProductionScreen` on that screen" — is a
  # question about two trees at once and lives in
  # `test/visual_audit/screens/screen_audit_coverage_test.dart`.
  #
  # The rule below is a POSITIVE match. A negative-lookahead over a whole file
  # fires on everything, because `.` does not cross newlines.
```

Delete the whole `memox.visual.production_screen_audit_not_exploratory` rule block. V8 has no exploratory helper to forbid. In `overrides.yaml`, delete the line `# -- \`visual-audit\`: waits for the first test/visual_audit/ companion (UI sub-project)` and the four lines of the two MX-VIS-001 entries. Keep the explanatory comment about `targets_pending`, because the mechanism stays.

- [ ] **Step 3: Run the guard**

Run: `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`
Expected: 0 errors, 0 warnings, and no `rule_targets_pending` info line.

- [ ] **Step 4: Prove the skip rule bites**

Temporarily add `testWidgets('x', (t) async {}, skip: true);` to the placeholder companion and run the guard.
Expected: 1 error, `memox.visual.production_screen_audit_not_skipped`. Revert the line and re-run; expected 0 errors.

- [ ] **Step 5: Commit**

```bash
git add code-verification-guard-v2/registries/projects/memox-v8
git commit -m "chore(guard): MX-VIS-001 has companions; drop the V7 exploratory-helper rule (FE-D2)"
```

### Task 4: dod_check.sh is the gate

**Files:**
- Modify: `.claude/skills/flutter-workflow/scripts/dod_check.sh:81` (base) and `:407-419` (full-mode test step), plus the header comment lines 7-10.
- Modify: `README.md:37-53` (the gate block).
- Modify: `docs/wbs_FE.md`:
  - line 40-42 (gate paragraph);
  - line 112 (FE-D2 → xong);
  - line 151-152;
  - the FE-C1 row: its evidence says contrast joins `auditProductionScreen`.

- [ ] **Step 1: Change the script**

```bash
BASE_REF="origin/master"
```
and the `--changed` guard `[[ $CHANGED -eq 0 && "$BASE_REF" != "origin/master" ]]`. Replace the full-mode branch with:

```bash
  else
    # **`TZ=UTC`, and never goldens here.** Goldens are generated and compared
    # only in the Linux container (golden.Dockerfile, CLAUDE.md); a host run
    # compares them against a different rasteriser and fails on pixels that
    # are not defects.
    plan test "flutter test (full suite, no goldens, TZ=UTC)" \
      "TZ=UTC flutter test --exclude-tags golden"
  fi
```

In the header, the `--changed` line's default becomes `origin/master`.

- [ ] **Step 2: Run the gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh --force`
Expected: every step passes, and the summary says all gates are green. If a step fails on an environment gap, such as `pytest` missing for the guard self-tests, stop and record the step and why. Do not weaken the script.

- [ ] **Step 3: Update README and WBS**

The README block becomes:

````markdown
Verification gate (ADR-011):

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

It runs format, analyze, generated-code freshness, the architecture and docs
checks, the guard and its self-tests, and the host test suite. Goldens are
not part of it: they are compared in the Linux container
(`.claude/skills/flutter-testing/scripts/golden.Dockerfile`).

A guard rule whose layer does not exist yet is listed with
`targets_pending: <layer>` in
`code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`.
Once the rule has a target file, the guard reports
`guard.config.stale_targets_pending` and the gate fails: delete the rule's
entry in the commit that added the file. The list is empty today.
````

In `docs/wbs_FE.md`:
- gate paragraph (lines 40-42): "gate là `dod_check.sh` (FE-D2); danh sách `targets_pending` của guard đã rỗng.";
- line 151-152: "Gate: `dod_check.sh` (`README.md` gốc).";
- FE-D2 status: `xong`, evidence "Companion `test/visual_audit/` cho 01, 02, 04, 07–10 và placeholder; test coverage; luật V7 `not_exploratory` đã xoá; `dod_check.sh` bỏ golden, base `origin/master`";
- FE-C1 evidence gains "; khi quyết xong, `textContrastGuideline` vào `auditProductionScreen`".

- [ ] **Step 4: Verify goldens in the container**

Run the container verify (`verify.sh` in the scratchpad) over the tree.
Expected: all golden tests pass. `card_list` must be unchanged after the Task 2 harness move.

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/flutter-workflow/scripts/dod_check.sh README.md docs/wbs_FE.md
git commit -m "chore(gate): dod_check.sh is the gate; host runs skip goldens, base master (FE-D2)"
```
