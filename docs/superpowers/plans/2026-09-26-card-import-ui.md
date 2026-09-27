# MemoX V8 Card Import UI Implementation Plan (FE-B3, plan 1 of 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the import half of FE-B3 in [`docs/wbs_FE.md`](../../wbs_FE.md): kit
screen 11, "Import cards", a four-step wizard over the BE-B3 use cases, and its entry
points in the Library. Plan 2 of FE-B3 adds export: sheet 12, Export on the bulk bar
and in the deck's `⋮` sheet.

**Architecture:** `lib/features/transfer/presentation/` gains the wizard. One
`@riverpod` controller per deck holds a sealed state: a draft at one of four steps, a
done summary, or a failure. Every step calls a BE-B3 use case through its provider, and
`file_picker` is reached through one provider that tests replace. The screen draws each
step from existing `Mx*` widgets and is a full-screen route on the root navigator. The
deck feature gains a callback, and `app/` wires it to the route. No new shared widget,
no schema change.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `flutter_riverpod` 3 with
`riverpod_generator`, `go_router` 18, gen-l10n (en, vi). Added: `file_picker` ^13.1.0.

**Spec:** [`docs/superpowers/specs/2026-09-26-card-transfer-design.md`](../specs/2026-09-26-card-transfer-design.md)
§8 (with the rulings of §8.1 and the deviations K1–K4 of §8.2), read with the
Clarifications below. Use case: UC-TRANSFER-001; IT: IT-NAV-012, IT-CARD-014. The kit
is the visual authority: "MemoX — Mobile UI Kit v3", screen 11, 16 states.

**Prerequisite:** branch `claude/lexilize-flashcard-app-lpklbs` at `5126fd2`, which holds
BE-B3 ([backend plan](2026-09-26-card-transfer-backend.md)). Generated code is not
committed: in a fresh working tree, run `flutter pub get`, `flutter gen-l10n` and
`dart run build_runner build --delete-conflicting-outputs` first (root `README.md`).

**How this plan was checked:** every code block below was written and run in a scratch
worktree of this branch, and every block was then replayed mechanically onto a clean
checkout of `5126fd2`: the result matched the scratch files byte for byte. The full gate
(`dod_check.sh --force`) passed there with 1,529 host tests, a clean `flutter analyze`, a
clean guard and clean architecture boundaries. Its only reds were in the docs gate: this
plan's link from `wbs_FE.md` (the plan did not exist yet) and the generated index, which
Task 6 regenerates. The goldens were rendered in this Linux container and compared with the kit
captures. Rules were then broken on purpose, and each break failed a test:
- Include duplicates not passed to the commit.
- Back allowed while the cards are written.
- A deck that gained sub-decks kept on the preview instead of the rejects result.
- Back from Preview dropping the mapping.
- `PopScope` letting Back close the wizard at any step.
- Import offered on a root deck and a deck of decks.

The first review of the goldens found the tracker wrapping to two lines at 360 dp and the
deck context indented twice. Both are fixed in the code below (F11).

## Clarifications (amend the spec where they differ)

- **F1 (spec D8).** The import is a `GoRoute` under the deck route, `cards/import`, with
  `parentNavigatorKey` set to the root navigator. `buildAppRouter` therefore owns a
  local `GlobalKey<NavigatorState>`, passed as `navigatorKey`, not a top-level one. The
  URL is `/decks/deck/<id>/cards/import`; IT-NAV-012 step 1 is corrected to it.
- **F2 (backend seam).** Flutter's `compute` never finishes under a widget test's fake
  clock. `TransferFileRepositoryImpl` takes an optional `TransferRunner` that defaults to
  `compute`. `library_harness` overrides `transferFileRepositoryProvider` with one that
  runs inline. Production behaviour is unchanged.
- **F3 (UC-TRANSFER-001 step 8 beats the kit).** The result footers work like this:
  - success and partial: Import another file · View the cards;
  - `none`: Import another file · Back to deck (ruling 1);
  - failed: Close · Try again, which commits the same preview again (E5).
  "Import another file" also clears the critique's P3 item of the same name.
- **F4.** Rejects (E4, the deck gained sub-decks) offers Close only. The kit's "Choose
  another deck" has no use case behind it.
- **F5 (spec D2).** A header auto-maps only by the six canonical names, compared after
  folding. The kit's `term`/`meaning` sample would stay unmapped and show the mapping
  banner.
- **F6 (amends spec §5.1).** The file name is shown on the source chip while the wizard
  is open. The domain never carries it, and nothing logs or stores it.
- **F7 (K2, K3).** The preview shows the first 50 rows (`shownRows`), and the note says
  so when there are more. A row stacks front over back instead of the kit's three
  columns, because a two-line cell does not fit three columns at 360 dp.
- **F8 (ruling 3).** Import cards is offered in two places:
  - the open deck's `⋮` sheet, only when the deck can take cards: an unset or card deck,
    and never a root (BR-DECK-005, BR-TRANSFER-008);
  - the unset deck's third action, "Import cards from a file".
  An empty card list is that unset state (E-L1), so it needs no third place.
- **F9.** Coming soon keeps one transfer line, "Export cards", until plan 2 removes it.
- **F10 (spec §12).** The repository has no `web/` folder: `flutter build web` answers
  "This project is not configured for the web", so the web check has nothing to build.
  `file_picker` lists web support for when it is added. The Android build is proven by
  the `build-apk` workflow (Task 6 Step 6). Its trigger was refused from this session
  (403), so the owner runs it.
- **F11.** The deck context (breadcrumb and deck name) and the tracker stay above the
  scroll, as on the card editor, so they line up with the cards at 16 dp. The tracker
  measures its labels at the reader's text scale:
  - when they fit, it is one row with stretching connectors;
  - otherwise, at a large text scale, it wraps with fixed connectors.
- **F12.** A picker that throws, or a file whose extension is not csv, tsv or xlsx, gives
  the "can't be read" problem (E1). A cancelled picker keeps the source chosen before
  (A5).
- **F13.** The draft's flag is `isIncludingDuplicates` (the guard's predicate rule). The
  BE-B3 parameter `includeDuplicates` stays as it is.

## Global Constraints

Every task's requirements implicitly include these.

- The kit's screen 11 is the visual authority. Every difference is in F1–F13 or in
  `docs/shared/ui/screen-handoff/11-card-import.md`.
- Only `Mx*` widgets and theme tokens: no raw colour, `TextStyle`, spacing or radius
  literal, no raw Material control (`Switch`, `InkWell`, `Card`…), `IconTheme.merge`
  instead of `Icon(color:)`, no `ref.read` inside `build`, no literal user string (the
  guard). Numbers shown alone come from `{count}` messages too.
- File suffixes follow the guard: `_screen`, `_controller`, `_state`, `_provider`,
  `_widget`; widgets live in `sections/`, `items/`, `overlays/` or `support/`.
- `file_picker` is imported only by `import_file_picker_provider.dart`.
- Nothing logs card content, pasted text, a file name or a raw row (BR-CORE-002,
  BR-TRANSFER-006). No message carries a path, a file name or an id (BR-CORE-005).
- Every message is in `app_en.arb` (with its description) and `app_vi.arb`.
- Goldens render in the Linux container only; on Windows run
  `flutter test --exclude-tags golden` and never `--update-goldens`.
- The import map is unchanged: `transfer` already imports `card` (BE-B3), and the deck
  feature learns about the import only through a callback that `app/` wires.

## Review Focus

These are the inputs a person meets first. Each is pinned by the test named.

1. **A Latin-1 CSV** (Excel's "CSV (Comma delimited)" on Windows): refused at step 1
   with the encoding guidance, and nothing written. Test: "a Latin-1 file is refused
   at step 1 with guidance (E1)".
2. **Android Back in the middle of the wizard:** it steps back one step and keeps the
   mapping. While the cards are written, it does nothing. Tests: "Back steps back one
   step…" and "Back does nothing while the cards are written".
3. **A file whose rows are all in the deck already:** Import is locked with "No row will
   be imported". Include duplicates writes them. Tests: "duplicates are skipped unless
   included…" and "Include duplicates writes them as new cards (A4)".
4. **A deck that gains a sub-deck between Preview and Import:** the rejects result, and
   nothing written. Test: "a deck that gained sub-decks refuses the commit…".
5. **A 360 dp phone at text scale 2:** the tracker wraps, nothing overflows, and every
   target is 48 dp. Tests: the screen 11 visual audit, both steps.

## File map

| File | Task | Responsibility |
|---|---|---|
| `pubspec.yaml`, `pubspec.lock` | 1 | `file_picker` |
| `lib/core/theme/foundations/app_icons.dart` | 1 | seven icons for the wizard and the sheet |
| `lib/core/theme/mx_text_styles.dart` | 1 | the step label and number |
| `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` | 1 | the wizard's copy; Coming soon names export only |
| `lib/features/transfer/data/repositories/transfer_file_repository_impl.dart` | 1 | the `TransferRunner` seam (F2) |
| `test/support/library_harness.dart` | 1, 5 | codecs inline; `deckScreen(onImportCards:)` |
| `lib/features/transfer/presentation/providers/*_use_case_provider.dart` | 2 | the three import use cases |
| `lib/features/transfer/presentation/providers/import_file_picker_provider.dart` | 2 | the picker, replaceable in tests |
| `lib/features/transfer/presentation/states/card_import_state.dart` | 2 | step, draft, done, failed |
| `lib/features/transfer/presentation/controllers/card_import_controller.dart` | 2 | the wizard's transitions |
| `lib/features/transfer/presentation/widgets/**` | 3 | tracker, source, mapping, preview, commit bar, result |
| `lib/features/transfer/presentation/screens/card_import_screen.dart` | 4 | the screen, Back and the result footers |
| `lib/app/router/app_routes.dart`, `lib/app/router/app_router.dart` | 5 | the route on the root navigator |
| `lib/features/deck/presentation/**` (4 files) | 5 | `onImportCards`, the sheet row, the unset action |
| `tools/design/screen_states.json`, `docs/**` | 6 | kit capture, detail file, index, WBS, specs |

---


### Task 1: Foundations: the picker package, icons, step type, copy and an inline file runner

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/core/theme/foundations/app_icons.dart`
- Modify: `lib/core/theme/mx_text_styles.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_vi.arb`
- Modify: `lib/features/transfer/data/repositories/transfer_file_repository_impl.dart`
- Modify: `test/features/deck/presentation/goldens/library_coming_soon_light.png`
- Modify: `test/features/deck/presentation/goldens/library_coming_soon_dark.png`
- Test (create): `test/core/theme/mx_text_styles_step_test.dart`
- Test (modify): `test/support/library_harness.dart`

**Interfaces:**
- Produces: `AppIcons.{fileUp, clipboard, fileText, folderOpen, arrowRight, preview, download}`;
  `MxTextStyles.stepLabel({required bool isReached})` and `stepNumber(Color ink)`; the
  `import*`, `deckActionImport` and `deckUnsetImport` messages in en and vi, and
  "Export cards" as the one transfer line under Coming soon;
  `typedef TransferRunner` and `TransferFileRepositoryImpl({TransferRunner run})` (F2);
  every `library_harness` backend runs the file codecs inline.

- [ ] **Step 1: Add the package**

```bash
flutter pub add file_picker:^13.1.0
```

Expected: `pubspec.yaml` lists `file_picker: ^13.1.0` under `dependencies`.

- [ ] **Step 2: Write the failing test**

`test/core/theme/mx_text_styles_step_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

// The import step tracker's type (kit 11), apart from the component styles.
void main() {
  final theme = buildLightTheme();
  final scheme = AppColorSchemes.light;
  final styles = MxTextStyles(theme.textTheme, scheme);

  test('a step label is 12, onSurface once reached, muted before', () {
    expect(styles.stepLabel(isReached: true).color, scheme.onSurface);
    expect(styles.stepLabel(isReached: false).color, scheme.onSurfaceVariant);
    expect(styles.stepLabel(isReached: true).fontSize, 12);
  });

  test("a step's number is the tabular counter in the dot's ink", () {
    final number = styles.stepNumber(scheme.onPrimary);
    expect(number.color, scheme.onPrimary);
    expect(number.fontFeatures, styles.counter.fontFeatures);
    expect(number.fontSize, styles.counter.fontSize);
  });
}
```

- [ ] **Step 3: Run it to see it fail**

```bash
flutter test test/core/theme/mx_text_styles_step_test.dart
```

Expected: FAIL to compile: `stepLabel` and `stepNumber` are not defined.

- [ ] **Step 4: Implement**

`lib/core/theme/foundations/app_icons.dart` (apply this diff):

```diff
diff --git a/lib/core/theme/foundations/app_icons.dart b/lib/core/theme/foundations/app_icons.dart
index bca9917..0422015 100644
--- a/lib/core/theme/foundations/app_icons.dart
+++ b/lib/core/theme/foundations/app_icons.dart
@@ -60,6 +60,14 @@ abstract final class AppIcons {
   static const IconData transfer = Icons.import_export; // arrow-up-down
   static const IconData dueNow = Icons.bolt_outlined; // zap
   static const IconData cardDeck = Icons.copy_all_outlined; // copy
+  // Card import (kit 11).
+  static const IconData fileUp = Icons.upload_file_outlined; // file-up
+  static const IconData clipboard = Icons.content_paste; // clipboard
+  static const IconData fileText = Icons.description_outlined; // file-text
+  static const IconData folderOpen = Icons.folder_open_outlined; // folder-open
+  static const IconData arrowRight = Icons.arrow_forward; // arrow-right
+  static const IconData preview = Icons.visibility_outlined; // eye
+  static const IconData download = Icons.download; // download
   static const IconData library = Icons.layers_outlined;
   static const IconData librarySelected = Icons.layers;
   static const IconData study = Icons.play_circle_outline;
```

`lib/core/theme/mx_text_styles.dart` (apply this diff):

```diff
diff --git a/lib/core/theme/mx_text_styles.dart b/lib/core/theme/mx_text_styles.dart
index 31349ef..d3933f9 100644
--- a/lib/core/theme/mx_text_styles.dart
+++ b/lib/core/theme/mx_text_styles.dart
@@ -102,6 +102,15 @@ final class MxTextStyles {
     color: _scheme.onSurfaceVariant,
   );
 
+  /// The import step tracker's label (kit 11): 12/600, onSurface once the
+  /// step is reached, onSurfaceVariant before.
+  TextStyle stepLabel({required bool isReached}) => _texts.labelSmall!.copyWith(
+    color: isReached ? _scheme.onSurface : _scheme.onSurfaceVariant,
+  );
+
+  /// The number on an import step's dot (kit 11): the counter in [ink].
+  TextStyle stepNumber(Color ink) => counter.copyWith(color: ink);
+
   /// BottomNav label: 12/600, primary on the current destination.
   TextStyle navLabel({required bool isSelected}) => _texts.labelSmall!.copyWith(
     color: isSelected ? _scheme.primary : _scheme.onSurfaceVariant,
```

`lib/features/transfer/data/repositories/transfer_file_repository_impl.dart` (apply this diff):

```diff
diff --git a/lib/features/transfer/data/repositories/transfer_file_repository_impl.dart b/lib/features/transfer/data/repositories/transfer_file_repository_impl.dart
index c29cecd..22f8214 100644
--- a/lib/features/transfer/data/repositories/transfer_file_repository_impl.dart
+++ b/lib/features/transfer/data/repositories/transfer_file_repository_impl.dart
@@ -1,3 +1,4 @@
+import 'dart:async';
 import 'dart:typed_data';
 
 import 'package:flutter/foundation.dart' show compute;
@@ -10,24 +11,36 @@ import 'package:memox/features/transfer/domain/models/transfer_format_model.dart
 import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';
 import 'package:memox/features/transfer/domain/repositories/transfer_file_repository.dart';
 
+/// Runs [callback] on [message]: off the UI isolate by default.
+typedef TransferRunner = Future<R> Function<Q, R>(
+  FutureOr<R> Function(Q) callback,
+  Q message,
+);
+
 /// Reading and writing run off the UI isolate through [compute], which runs
-/// them inline on the web build E2E uses (spec D7, ADR-001).
+/// them inline on the web build E2E uses (spec D7, ADR-001). A widget test,
+/// whose clock is fake, passes a runner that calls inline.
 final class TransferFileRepositoryImpl implements TransferFileRepository {
-  const TransferFileRepositoryImpl();
+  const TransferFileRepositoryImpl({this._run = _compute});
+
+  final TransferRunner _run;
 
   @override
   Future<Outcome<SourceTable, TransferRejection>> read(
     TransferSource source, {
     int? sheetIndex,
-  }) => compute(_read, (source, sheetIndex));
+  }) => _run(_read, (source, sheetIndex));
 
   @override
   Future<Outcome<Uint8List, TransferRejection>> write(
     List<List<String>> rows,
     TransferFormat format,
-  ) => compute(_write, (rows, format));
+  ) => _run(_write, (rows, format));
 }
 
+Future<R> _compute<Q, R>(FutureOr<R> Function(Q) callback, Q message) =>
+    compute(callback, message);
+
 const _delimited = DelimitedTextDataSource();
 const _xlsx = XlsxDataSource();
 
```

`test/support/library_harness.dart` (apply this diff):

```diff
diff --git a/test/support/library_harness.dart b/test/support/library_harness.dart
--- a/test/support/library_harness.dart
+++ b/test/support/library_harness.dart
@@ -17,6 +17,8 @@ import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart'
 import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
 import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
 import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
+import 'package:memox/features/transfer/data/repositories/transfer_file_repository_impl.dart';
+import 'package:memox/features/transfer/di/transfer_file_repository_provider.dart';
 import 'package:memox/l10n/generated/app_localizations.dart';
 import 'package:memox/shared/widgets/mx_app_bar.dart';
 import 'package:memox/features/deck/presentation/screens/deck_algorithm_screen.dart';
@@ -68,6 +70,7 @@ void libraryTest(
 List<Override> _backend(LibraryEnv env) => [
   databaseProvider.overrideWithValue(env.db),
   dayClockProvider.overrideWithValue(env.clock),
+  _inlineTransferFiles,
 ];
 
 /// A provider container over [env]'s backend, for a test that drives
@@ -241,3 +244,12 @@ Future<void> pumpMemoxApp(WidgetTester tester, LibraryEnv env) async {
 
 /// As `main.dart`: no hidden retry loop, so a failure shows as a failure.
 Duration? _noRetry(int retryCount, Object error) => null;
+
+/// Card transfer's file codecs without a background isolate, which a widget
+/// test's fake clock never lets finish.
+final Override _inlineTransferFiles = transferFileRepositoryProvider
+    .overrideWithValue(
+      TransferFileRepositoryImpl(
+        run: <Q, R>(callback, message) async => callback(message),
+      ),
+    );
```

The copy. `app_en.arb` carries each message's description and placeholders; `app_vi.arb`
the Vietnamese text. Both change `comingSoonTransfer`/`comingSoonTransferBody` to export
only (F9):

`lib/l10n/app_en.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_en.arb b/lib/l10n/app_en.arb
index d8fa329..8ca6999 100644
--- a/lib/l10n/app_en.arb
+++ b/lib/l10n/app_en.arb
@@ -1751,13 +1751,13 @@
   "@comingSoonProgressSortBody": {
     "description": "Coming soon: what the progress sort does."
   },
-  "comingSoonTransfer": "Import and export",
+  "comingSoonTransfer": "Export cards",
   "@comingSoonTransfer": {
-    "description": "Coming soon: the import and export feature's name."
+    "description": "Coming soon: the export feature's name (import shipped, FE-B3)."
   },
-  "comingSoonTransferBody": "Cards from and to files.",
+  "comingSoonTransferBody": "Cards to a file, for a spreadsheet or another app.",
   "@comingSoonTransferBody": {
-    "description": "Coming soon: what import and export do."
+    "description": "Coming soon: what export does."
   },
   "cardDeckProgress": "Deck progress · {algorithm}",
   "@cardDeckProgress": {
@@ -2418,5 +2418,543 @@
   "galleryN5": "N5",
   "@galleryN5": {
     "description": "Debug gallery: sample copy in the component showcase."
+  },
+  "importTitle": "Import cards",
+  "@importTitle": {
+    "description": "Import screen: the app bar title while importing."
+  },
+  "importResultsTitle": "Import results",
+  "@importResultsTitle": {
+    "description": "Import screen: the app bar title on a result."
+  },
+  "importBreadcrumb": "Import",
+  "@importBreadcrumb": {
+    "description": "Import screen: the last breadcrumb segment."
+  },
+  "importClose": "Close import",
+  "@importClose": {
+    "description": "Import screen: the close button's accessible label."
+  },
+  "importStepSource": "Source",
+  "@importStepSource": {
+    "description": "Import step tracker: step 1."
+  },
+  "importStepColumns": "Columns",
+  "@importStepColumns": {
+    "description": "Import step tracker: step 2."
+  },
+  "importStepPreview": "Preview",
+  "@importStepPreview": {
+    "description": "Import step tracker: step 3."
+  },
+  "importStepImport": "Import",
+  "@importStepImport": {
+    "description": "Import step tracker: step 4."
+  },
+  "importStepNumber": "{step}",
+  "@importStepNumber": {
+    "placeholders": {
+      "step": {
+        "type": "int"
+      }
+    },
+    "description": "Import step tracker: the number on a step's dot."
+  },
+  "importResultCount": "{count}",
+  "@importResultCount": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Import result: the count at the end of an added or skipped row."
+  },
+  "importStepLabel": "Step {step} of 4: {name}",
+  "@importStepLabel": {
+    "placeholders": {
+      "step": {
+        "type": "int"
+      },
+      "name": {
+        "type": "String"
+      }
+    },
+    "description": "Import step tracker: the accessible label of the current step."
+  },
+  "importSectionSource": "1 · Choose a source",
+  "@importSectionSource": {
+    "description": "Import: the source section header."
+  },
+  "importSectionColumns": "2 · Map columns",
+  "@importSectionColumns": {
+    "description": "Import: the mapping section header."
+  },
+  "importSectionPreview": "3 · Preview",
+  "@importSectionPreview": {
+    "description": "Import: the preview section header."
+  },
+  "importSourceFile": "Choose a file",
+  "@importSourceFile": {
+    "description": "Import source card: a file."
+  },
+  "importSourceFileHint": "CSV, TSV or XLSX · UTF-8",
+  "@importSourceFileHint": {
+    "description": "Import source card: what a file may be."
+  },
+  "importSourcePaste": "Paste text",
+  "@importSourcePaste": {
+    "description": "Import source card: pasted text."
+  },
+  "importSourcePasteHint": "Tab- or comma-separated rows",
+  "@importSourcePasteHint": {
+    "description": "Import source card: what pasted text may be."
+  },
+  "importPickTitle": "Pick a spreadsheet or text file",
+  "@importPickTitle": {
+    "description": "Import: the empty file picker card title."
+  },
+  "importPickBody": ".csv, .tsv or .xlsx · UTF-8 · nothing is added until you confirm",
+  "@importPickBody": {
+    "description": "Import: the empty file picker card body."
+  },
+  "importPickAction": "Choose file",
+  "@importPickAction": {
+    "description": "Import: opens the system file picker."
+  },
+  "importPasteHint": "Paste rows here",
+  "@importPasteHint": {
+    "description": "Import: the pasted text field's hint."
+  },
+  "importPastedLines": "{count, plural, =1{1 line} other{{count} lines}}",
+  "@importPastedLines": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Import: how many lines were pasted."
+  },
+  "importHelperTitle": "Each row makes one card",
+  "@importHelperTitle": {
+    "description": "Import helper banner title."
+  },
+  "importHelperBody": "You will map columns to term, meaning, example, hint, pronunciation and tags next. Several tags in one cell are separated by “;”.",
+  "@importHelperBody": {
+    "description": "Import helper banner body."
+  },
+  "importRemoveSource": "Remove the file",
+  "@importRemoveSource": {
+    "description": "Import file chip: the remove button's accessible label."
+  },
+  "importFileReady": "{format} · UTF-8 · ready to read",
+  "@importFileReady": {
+    "placeholders": {
+      "format": {
+        "type": "String"
+      }
+    },
+    "description": "Import file chip before reading."
+  },
+  "importFileRead": "{format} · {rows, plural, =1{1 row} other{{rows} rows}} · {columns, plural, =1{1 column} other{{columns} columns}}",
+  "@importFileRead": {
+    "placeholders": {
+      "format": {
+        "type": "String"
+      },
+      "rows": {
+        "type": "int"
+      },
+      "columns": {
+        "type": "int"
+      }
+    },
+    "description": "Import file chip after reading."
+  },
+  "importPastedFormat": "Text",
+  "@importPastedFormat": {
+    "description": "Import file chip: the format of pasted text."
+  },
+  "importSheet": "Sheet: {name} ({index} of {count})",
+  "@importSheet": {
+    "placeholders": {
+      "name": {
+        "type": "String"
+      },
+      "index": {
+        "type": "int"
+      },
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Import file chip: the chosen sheet of a workbook (A2)."
+  },
+  "importSheetPickerTitle": "Choose a sheet",
+  "@importSheetPickerTitle": {
+    "description": "Import: the sheet picker sheet title."
+  },
+  "importReading": "Reading your file…",
+  "@importReading": {
+    "description": "Import: shown while the source is read."
+  },
+  "importHeaderToggle": "First row is a header",
+  "@importHeaderToggle": {
+    "description": "Import mapping: the header row toggle."
+  },
+  "importColumnName": "Column {letter}",
+  "@importColumnName": {
+    "placeholders": {
+      "letter": {
+        "type": "String"
+      }
+    },
+    "description": "Import mapping: a column by its position."
+  },
+  "importFieldNone": "Not imported",
+  "@importFieldNone": {
+    "description": "Import mapping: a column that feeds no field."
+  },
+  "importFieldFront": "Term (front)",
+  "@importFieldFront": {
+    "description": "Import mapping: the front field."
+  },
+  "importFieldBack": "Meaning (back)",
+  "@importFieldBack": {
+    "description": "Import mapping: the back field."
+  },
+  "importFieldExample": "Example",
+  "@importFieldExample": {
+    "description": "Import mapping: the example field."
+  },
+  "importFieldHint": "Hint",
+  "@importFieldHint": {
+    "description": "Import mapping: the hint field."
+  },
+  "importFieldPronunciation": "Pronunciation",
+  "@importFieldPronunciation": {
+    "description": "Import mapping: the pronunciation field."
+  },
+  "importFieldTags": "Tags",
+  "@importFieldTags": {
+    "description": "Import mapping: the tags field."
+  },
+  "importFieldPickerTitle": "Column {letter} goes to",
+  "@importFieldPickerTitle": {
+    "placeholders": {
+      "letter": {
+        "type": "String"
+      }
+    },
+    "description": "Import mapping: the field picker sheet title."
+  },
+  "importMappingNote": "Known header names were mapped for you. Term and meaning are required; the rest is optional.",
+  "@importMappingNote": {
+    "description": "Import mapping: the note under the columns."
+  },
+  "importMappingIncomplete": "Map one column to Term and one to Meaning. Both are required.",
+  "@importMappingIncomplete": {
+    "description": "Import mapping: front or back is not mapped (BR-TRANSFER-002)."
+  },
+  "importPreviewReady": "{ready} of {total} rows ready",
+  "@importPreviewReady": {
+    "placeholders": {
+      "ready": {
+        "type": "int"
+      },
+      "total": {
+        "type": "int"
+      }
+    },
+    "description": "Import preview: the ready count."
+  },
+  "importBadgeReady": "Ready · {count}",
+  "@importBadgeReady": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Import preview summary badge."
+  },
+  "importBadgeInvalid": "Invalid · {count}",
+  "@importBadgeInvalid": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Import preview summary badge."
+  },
+  "importBadgeDuplicate": "Duplicate · {count}",
+  "@importBadgeDuplicate": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Import preview summary badge."
+  },
+  "importBadgeBlank": "Blank · {count}",
+  "@importBadgeBlank": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Import preview summary badge."
+  },
+  "importRowReady": "Ready",
+  "@importRowReady": {
+    "description": "Import preview row: the ready status's accessible label."
+  },
+  "importRowNumber": "Row {row}",
+  "@importRowNumber": {
+    "placeholders": {
+      "row": {
+        "type": "int"
+      }
+    },
+    "description": "Import preview row: the row number's accessible label."
+  },
+  "importRowEmptyCell": "(empty)",
+  "@importRowEmptyCell": {
+    "description": "Import preview row: an empty cell."
+  },
+  "importRowBlank": "Blank row · ignored",
+  "@importRowBlank": {
+    "description": "Import preview row: a blank row."
+  },
+  "importRowDuplicateInDeck": "Already in this deck",
+  "@importRowDuplicateInDeck": {
+    "description": "Import preview row: a duplicate of a card in the deck."
+  },
+  "importRowDuplicateInSource": "Repeated in the file (row {row})",
+  "@importRowDuplicateInSource": {
+    "placeholders": {
+      "row": {
+        "type": "int"
+      }
+    },
+    "description": "Import preview row: a duplicate of an earlier row."
+  },
+  "importRowFrontEmpty": "Term is empty",
+  "@importRowFrontEmpty": {
+    "description": "Import preview row: the front is blank."
+  },
+  "importRowBackEmpty": "Meaning is empty",
+  "@importRowBackEmpty": {
+    "description": "Import preview row: the back is blank."
+  },
+  "importRowFrontTooLong": "Term over 60 characters",
+  "@importRowFrontTooLong": {
+    "description": "Import preview row: BR-CARD-002."
+  },
+  "importRowBackTooLong": "Meaning over 240 characters",
+  "@importRowBackTooLong": {
+    "description": "Import preview row: BR-CARD-002."
+  },
+  "importRowOptionalTooLong": "A field over 240 characters",
+  "@importRowOptionalTooLong": {
+    "description": "Import preview row: BR-CARD-003."
+  },
+  "importRowInvalidTag": "A tag name is not allowed",
+  "@importRowInvalidTag": {
+    "description": "Import preview row: BR-TAG-001."
+  },
+  "importRowTooManyTags": "More than 10 tags",
+  "@importRowTooManyTags": {
+    "description": "Import preview row: BR-TAG-002."
+  },
+  "importShowingFirst": "Showing the first {shown} of {total} rows",
+  "@importShowingFirst": {
+    "placeholders": {
+      "shown": {
+        "type": "int"
+      },
+      "total": {
+        "type": "int"
+      }
+    },
+    "description": "Import preview: the table shows only the first rows (kit deviation K2)."
+  },
+  "importIncludeDuplicates": "Include duplicates",
+  "@importIncludeDuplicates": {
+    "description": "Import preview: the duplicate policy toggle (A4)."
+  },
+  "importIncludeDuplicatesBody": "Off: rows already in the deck or repeated in the file are skipped.",
+  "@importIncludeDuplicatesBody": {
+    "description": "Import preview: what the duplicate toggle does."
+  },
+  "importReadAction": "Read and map columns",
+  "@importReadAction": {
+    "description": "Import commit bar: step 1 → 2."
+  },
+  "importPreviewAction": "Preview rows",
+  "@importPreviewAction": {
+    "description": "Import commit bar: step 2 → 3."
+  },
+  "importCommitAction": "{count, plural, =1{Import 1 card} other{Import {count} cards}}",
+  "@importCommitAction": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Import commit bar: step 3 → 4."
+  },
+  "importCommitting": "Importing…",
+  "@importCommitting": {
+    "description": "Import commit bar while writing."
+  },
+  "importCaptionSource": "Pick a file or paste text to continue.",
+  "@importCaptionSource": {
+    "description": "Import commit bar caption with no source."
+  },
+  "importCaptionPrivate": "Your file is read on this device only.",
+  "@importCaptionPrivate": {
+    "description": "Import commit bar caption with a source (BR-TRANSFER-006)."
+  },
+  "importCaptionColumns": "Next you’ll preview every row before anything is imported.",
+  "@importCaptionColumns": {
+    "description": "Import commit bar caption at step 2."
+  },
+  "importCaptionPreview": "{count, plural, =0{No row will be imported.} =1{1 row will become a new card.} other{{count} rows will become new cards.}}",
+  "@importCaptionPreview": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Import commit bar caption at step 3 (E3 when 0)."
+  },
+  "importImportingTitle": "{count, plural, =1{Adding 1 card…} other{Adding {count} cards…}}",
+  "@importImportingTitle": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Import: the commit is running."
+  },
+  "importImportingBody": "Written in one step — either every card is added or none is.",
+  "@importImportingBody": {
+    "description": "Import: the commit is all or nothing (BR-TRANSFER-004)."
+  },
+  "importProblemEncodingTitle": "This file is not UTF-8",
+  "@importProblemEncodingTitle": {
+    "description": "Import problem: BR-TRANSFER-006."
+  },
+  "importProblemEncodingBody": "Save it again as UTF-8 (CSV UTF-8 in Excel or Sheets) and choose it once more. Nothing was read.",
+  "@importProblemEncodingBody": {
+    "description": "Import problem: how to fix the encoding."
+  },
+  "importProblemUnreadableTitle": "This file can’t be read",
+  "@importProblemUnreadableTitle": {
+    "description": "Import problem: E1."
+  },
+  "importProblemUnreadableBody": "Choose a CSV, TSV or XLSX file that is not protected. Nothing was read.",
+  "@importProblemUnreadableBody": {
+    "description": "Import problem: how to fix an unreadable file."
+  },
+  "importProblemEmptyTitle": "There are no rows to import",
+  "@importProblemEmptyTitle": {
+    "description": "Import problem: E2."
+  },
+  "importProblemEmptyBody": "The file, sheet or text has no row with anything in it.",
+  "@importProblemEmptyBody": {
+    "description": "Import problem: an empty source."
+  },
+  "importChooseAnother": "Choose another file",
+  "@importChooseAnother": {
+    "description": "Import problem: pick a file again."
+  },
+  "importDoneTitle": "Imported",
+  "@importDoneTitle": {
+    "description": "Import result: success."
+  },
+  "importDoneBody": "{count, plural, =1{Added 1 new card. It enters learning on your next session.} other{Added {count} new cards. They enter learning on your next session.}}",
+  "@importDoneBody": {
+    "placeholders": {
+      "count": {
+        "type": "int"
+      }
+    },
+    "description": "Import result: success body."
+  },
+  "importPartialTitle": "Imported with skips",
+  "@importPartialTitle": {
+    "description": "Import result: partial."
+  },
+  "importPartialBody": "Some rows were skipped; the rest are new cards.",
+  "@importPartialBody": {
+    "description": "Import result: partial body."
+  },
+  "importNoneTitle": "Nothing added",
+  "@importNoneTitle": {
+    "description": "Import result: none (spec §8.1 ruling 1)."
+  },
+  "importNoneBody": "Every row already exists in this deck, so no card was created. The deck is unchanged.",
+  "@importNoneBody": {
+    "description": "Import result: none body."
+  },
+  "importFailedTitle": "Import didn’t finish",
+  "@importFailedTitle": {
+    "description": "Import result: E5."
+  },
+  "importFailedBody": "No cards were added — an import is all or nothing. Your file and your deck are unchanged.",
+  "@importFailedBody": {
+    "description": "Import result: E5 body."
+  },
+  "importRejectsTitle": "This deck no longer accepts cards",
+  "@importRejectsTitle": {
+    "description": "Import result: E4."
+  },
+  "importRejectsBody": "It now holds sub-decks. No cards were added. Pick a deck that holds cards or is empty and import again.",
+  "@importRejectsBody": {
+    "description": "Import result: E4 body."
+  },
+  "importCountAdded": "Added as new cards",
+  "@importCountAdded": {
+    "description": "Import result count row."
+  },
+  "importCountDuplicates": "Skipped — duplicates",
+  "@importCountDuplicates": {
+    "description": "Import result count row."
+  },
+  "importCountInvalid": "Skipped — invalid rows",
+  "@importCountInvalid": {
+    "description": "Import result count row."
+  },
+  "importSkipNote": "Fix the invalid rows in your source and import again; duplicates are skipped by the case-insensitive term + meaning.",
+  "@importSkipNote": {
+    "description": "Import result: how skips work."
+  },
+  "importViewCards": "View the cards",
+  "@importViewCards": {
+    "description": "Import result: back to the card list."
+  },
+  "importAnother": "Import another file",
+  "@importAnother": {
+    "description": "Import result: a fresh import into the same deck (UC-TRANSFER-001 step 8)."
+  },
+  "importBackToDeck": "Back to deck",
+  "@importBackToDeck": {
+    "description": "Import result: none, back to the deck."
+  },
+  "importCloseAction": "Close",
+  "@importCloseAction": {
+    "description": "Import result: close the import."
+  },
+  "importTryAgain": "Try again",
+  "@importTryAgain": {
+    "description": "Import result: commit the same preview again (E5)."
+  },
+  "deckActionImport": "Import cards",
+  "@deckActionImport": {
+    "description": "Deck action sheet: opens the import (UC-TRANSFER-001)."
+  },
+  "deckUnsetImport": "Import cards from a file",
+  "@deckUnsetImport": {
+    "description": "An empty deck's third option: opens the import."
   }
 }
```

`lib/l10n/app_vi.arb` (apply this diff):

```diff
diff --git a/lib/l10n/app_vi.arb b/lib/l10n/app_vi.arb
index 1e9334a..5685816 100644
--- a/lib/l10n/app_vi.arb
+++ b/lib/l10n/app_vi.arb
@@ -349,8 +349,8 @@
   "comingSoonStudyOptionsBody": "Số thẻ mỗi phiên, thứ tự thẻ mới.",
   "comingSoonProgressSort": "Sắp xếp theo độ thuộc",
   "comingSoonProgressSortBody": "Bộ thẻ thuộc ít nhất lên trước.",
-  "comingSoonTransfer": "Nhập và xuất",
-  "comingSoonTransferBody": "Nhập thẻ từ tệp, xuất thẻ ra tệp.",
+  "comingSoonTransfer": "Xuất thẻ",
+  "comingSoonTransferBody": "Thẻ ra tệp, cho bảng tính hoặc ứng dụng khác.",
   "cardDeckProgress": "Tiến độ bộ thẻ · {algorithm}",
   "cardMasteredOf": "{mastered}/{total} thẻ đã thuộc",
   "cardShowingOf": "Đang hiện {shown}/{total}",
@@ -492,5 +492,108 @@
   "galleryToday": "{count} hôm nay",
   "galleryNewCount": "{count} mới",
   "galleryLoadErrorBody": "Không mất gì cả. Hãy thử lại sau giây lát.",
-  "galleryN5": "N5"
+  "galleryN5": "N5",
+  "importTitle": "Nhập thẻ",
+  "importResultsTitle": "Kết quả nhập",
+  "importBreadcrumb": "Nhập",
+  "importClose": "Đóng màn nhập",
+  "importStepSource": "Nguồn",
+  "importStepColumns": "Cột",
+  "importStepPreview": "Xem trước",
+  "importStepImport": "Nhập",
+  "importStepNumber": "{step}",
+  "importResultCount": "{count}",
+  "importStepLabel": "Bước {step}/4: {name}",
+  "importSectionSource": "1 · Chọn nguồn",
+  "importSectionColumns": "2 · Ghép cột",
+  "importSectionPreview": "3 · Xem trước",
+  "importSourceFile": "Chọn tệp",
+  "importSourceFileHint": "CSV, TSV hoặc XLSX · UTF-8",
+  "importSourcePaste": "Dán văn bản",
+  "importSourcePasteHint": "Các dòng tách bằng tab hoặc dấu phẩy",
+  "importPickTitle": "Chọn một bảng tính hoặc tệp văn bản",
+  "importPickBody": ".csv, .tsv hoặc .xlsx · UTF-8 · chưa thêm gì cho tới khi bạn xác nhận",
+  "importPickAction": "Chọn tệp",
+  "importPasteHint": "Dán các dòng vào đây",
+  "importPastedLines": "{count, plural, other{{count} dòng}}",
+  "importHelperTitle": "Mỗi dòng thành một thẻ",
+  "importHelperBody": "Bước sau bạn ghép cột vào thuật ngữ, nghĩa, ví dụ, gợi ý, phát âm và tag. Nhiều tag trong một ô ngăn bằng “;”.",
+  "importRemoveSource": "Bỏ tệp này",
+  "importFileReady": "{format} · UTF-8 · sẵn sàng đọc",
+  "importFileRead": "{format} · {rows} dòng · {columns} cột",
+  "importPastedFormat": "Văn bản",
+  "importSheet": "Sheet: {name} ({index}/{count})",
+  "importSheetPickerTitle": "Chọn sheet",
+  "importReading": "Đang đọc tệp…",
+  "importHeaderToggle": "Dòng đầu là tiêu đề",
+  "importColumnName": "Cột {letter}",
+  "importFieldNone": "Không nhập",
+  "importFieldFront": "Thuật ngữ (mặt trước)",
+  "importFieldBack": "Nghĩa (mặt sau)",
+  "importFieldExample": "Ví dụ",
+  "importFieldHint": "Gợi ý",
+  "importFieldPronunciation": "Phát âm",
+  "importFieldTags": "Tag",
+  "importFieldPickerTitle": "Cột {letter} vào",
+  "importMappingNote": "Cột có tên chuẩn đã được ghép sẵn. Thuật ngữ và nghĩa là bắt buộc; còn lại tuỳ chọn.",
+  "importMappingIncomplete": "Hãy ghép một cột vào Thuật ngữ và một cột vào Nghĩa. Cả hai là bắt buộc.",
+  "importPreviewReady": "{ready}/{total} dòng sẵn sàng",
+  "importBadgeReady": "Sẵn sàng · {count}",
+  "importBadgeInvalid": "Không hợp lệ · {count}",
+  "importBadgeDuplicate": "Trùng · {count}",
+  "importBadgeBlank": "Trống · {count}",
+  "importRowReady": "Sẵn sàng",
+  "importRowNumber": "Dòng {row}",
+  "importRowEmptyCell": "(trống)",
+  "importRowBlank": "Dòng trống · bỏ qua",
+  "importRowDuplicateInDeck": "Đã có trong deck này",
+  "importRowDuplicateInSource": "Lặp lại trong tệp (dòng {row})",
+  "importRowFrontEmpty": "Thuật ngữ trống",
+  "importRowBackEmpty": "Nghĩa trống",
+  "importRowFrontTooLong": "Thuật ngữ quá 60 ký tự",
+  "importRowBackTooLong": "Nghĩa quá 240 ký tự",
+  "importRowOptionalTooLong": "Có trường quá 240 ký tự",
+  "importRowInvalidTag": "Có tên tag không hợp lệ",
+  "importRowTooManyTags": "Quá 10 tag",
+  "importShowingFirst": "Đang hiện {shown}/{total} dòng đầu",
+  "importIncludeDuplicates": "Nhập cả dòng trùng",
+  "importIncludeDuplicatesBody": "Tắt: dòng đã có trong deck hoặc lặp lại trong tệp sẽ bị bỏ qua.",
+  "importReadAction": "Đọc và ghép cột",
+  "importPreviewAction": "Xem trước các dòng",
+  "importCommitAction": "{count, plural, other{Nhập {count} thẻ}}",
+  "importCommitting": "Đang nhập…",
+  "importCaptionSource": "Chọn tệp hoặc dán văn bản để tiếp tục.",
+  "importCaptionPrivate": "Tệp chỉ được đọc trên thiết bị này.",
+  "importCaptionColumns": "Tiếp theo bạn xem trước mọi dòng trước khi nhập.",
+  "importCaptionPreview": "{count, plural, =0{Không dòng nào được nhập.} other{{count} dòng sẽ thành thẻ mới.}}",
+  "importImportingTitle": "{count, plural, other{Đang thêm {count} thẻ…}}",
+  "importImportingBody": "Ghi trong một lần — hoặc thêm đủ mọi thẻ, hoặc không thẻ nào.",
+  "importProblemEncodingTitle": "Tệp này không phải UTF-8",
+  "importProblemEncodingBody": "Lưu lại dạng UTF-8 (CSV UTF-8 trong Excel hoặc Sheets) rồi chọn lại. Chưa đọc gì cả.",
+  "importProblemUnreadableTitle": "Không đọc được tệp này",
+  "importProblemUnreadableBody": "Hãy chọn tệp CSV, TSV hoặc XLSX không đặt mật khẩu. Chưa đọc gì cả.",
+  "importProblemEmptyTitle": "Không có dòng nào để nhập",
+  "importProblemEmptyBody": "Tệp, sheet hoặc văn bản không có dòng nào có dữ liệu.",
+  "importChooseAnother": "Chọn tệp khác",
+  "importDoneTitle": "Đã nhập",
+  "importDoneBody": "{count, plural, other{Đã thêm {count} thẻ mới. Chúng vào phần học ở phiên tới.}}",
+  "importPartialTitle": "Đã nhập, có dòng bị bỏ",
+  "importPartialBody": "Một số dòng bị bỏ qua; các dòng còn lại thành thẻ mới.",
+  "importNoneTitle": "Không thêm thẻ nào",
+  "importNoneBody": "Mọi dòng đều đã có trong deck này nên không tạo thẻ nào. Deck không đổi.",
+  "importFailedTitle": "Nhập chưa hoàn tất",
+  "importFailedBody": "Chưa thêm thẻ nào — nhập là tất cả hoặc không. Tệp và deck của bạn không đổi.",
+  "importRejectsTitle": "Deck này không còn nhận thẻ",
+  "importRejectsBody": "Deck giờ chứa deck con. Chưa thêm thẻ nào. Hãy chọn deck chứa thẻ hoặc deck trống rồi nhập lại.",
+  "importCountAdded": "Thêm thành thẻ mới",
+  "importCountDuplicates": "Bỏ qua — trùng",
+  "importCountInvalid": "Bỏ qua — dòng không hợp lệ",
+  "importSkipNote": "Sửa các dòng không hợp lệ trong nguồn rồi nhập lại; dòng trùng được xác định theo thuật ngữ + nghĩa, không phân biệt hoa thường.",
+  "importViewCards": "Xem các thẻ",
+  "importAnother": "Nhập tệp khác",
+  "importBackToDeck": "Về deck",
+  "importCloseAction": "Đóng",
+  "importTryAgain": "Thử lại",
+  "deckActionImport": "Nhập thẻ",
+  "deckUnsetImport": "Nhập thẻ từ tệp"
 }
```

- [ ] **Step 5: Regenerate, run, and re-render the Coming soon golden**

```bash
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter test test/core/theme test/features/transfer test/app/l10n_test.dart
flutter test --tags golden --update-goldens test/features/deck/presentation/deck_screens_golden_test.dart
flutter test --tags golden test/features/deck/presentation
```

Expected: PASS. Only `library_coming_soon_{light,dark}.png` change: the sheet names
"Export cards" instead of import and export together. Look at both before committing.

- [ ] **Step 6: Commit**

```bash
git add \
  pubspec.yaml \
  pubspec.lock \
  lib/core/theme/foundations/app_icons.dart \
  lib/core/theme/mx_text_styles.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  lib/features/transfer/data/repositories/transfer_file_repository_impl.dart \
  test/core/theme/mx_text_styles_step_test.dart \
  test/support/library_harness.dart \
  test/features/deck/presentation/goldens/library_coming_soon_light.png \
  test/features/deck/presentation/goldens/library_coming_soon_dark.png
git commit -m "$(cat <<'EOF'
feat(transfer): foundations for the import screen: picker, icons, step type, copy

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 2: The wizard's state and controller

**Files:**
- Create: `lib/features/transfer/presentation/providers/read_import_source_use_case_provider.dart`
- Create: `lib/features/transfer/presentation/providers/preview_import_use_case_provider.dart`
- Create: `lib/features/transfer/presentation/providers/commit_import_use_case_provider.dart`
- Create: `lib/features/transfer/presentation/providers/import_file_picker_provider.dart`
- Create: `lib/features/transfer/presentation/states/card_import_state.dart`
- Create: `lib/features/transfer/presentation/controllers/card_import_controller.dart`
- Test (create): `test/features/transfer/presentation/card_import_controller_test.dart`

**Interfaces:**
- Consumes: `ReadImportSourceUseCase`, `PreviewImportUseCase`, `CommitImportUseCase`
  (BE-B3), `transferFileRepositoryProvider`, `cardRepositoryProvider`.
- Produces: `readImportSourceUseCaseProvider`, `previewImportUseCaseProvider`,
  `commitImportUseCaseProvider`; `typedef ImportPickedFile = ({String name, Uint8List bytes})`
  and `importFilePickerProvider` (the only import of `file_picker`); `enum CardImportStep
  {source, columns, preview, importing}`, `enum CardImportSourceKind {file, paste}`,
  `sealed class CardImportState` with `CardImportDraft`, `CardImportDone(summary)` and
  `CardImportFailed({draft, isTargetRejected})`; `cardImportControllerProvider(deckId)`
  with `chooseFile`, `chooseSourceKind`, `pasteText`, `clearSource`,
  `readSource({int? sheetIndex})`, `setHasHeaderRow`, `assignColumn`, `previewRows`,
  `setIncludingDuplicates`, `commit`, `retry`, `startOver` and `bool stepBack()`.

- [ ] **Step 1: Write the failing tests**

`test/features/transfer/presentation/card_import_controller_test.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_import_result_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_summary_model.dart';
import 'package:memox/features/transfer/domain/usecases/commit_import_use_case.dart';
import 'package:memox/features/transfer/presentation/controllers/card_import_controller.dart';
import 'package:memox/features/transfer/presentation/providers/commit_import_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The import wizard's steps over the real repositories and a fake picker
// (UC-TRANSFER-001, IT-NAV-012 step 4).

DateTime _now() => DateTime(2026, 9, 26);

ImportPickedFile _file(String name, String text) =>
    (name: name, bytes: Uint8List.fromList(utf8.encode(text)));

/// Throws on the commit, the way a full disk does (E5), until [isBroken]
/// turns false; holds the commit open while [hold] is pending.
final class _BrokenImport implements CardRepository {
  _BrokenImport(this._cards);

  final CardRepository _cards;
  var isBroken = true;
  Completer<void>? hold;

  @override
  Future<Set<({String front, String back})>> foldedPairs(String deckId) =>
      _cards.foldedPairs(deckId);

  @override
  Future<Outcome<CardImportResult, CardRejection>> importCards({
    required String deckId,
    required List<CardDraft> drafts,
    required bool includeDuplicates,
    DateTime? now,
  }) async {
    await hold?.future;
    if (isBroken) throw const UnknownDatabaseFailure(cause: 'disk full');
    return _cards.importCards(
      deckId: deckId,
      drafts: drafts,
      includeDuplicates: includeDuplicates,
      now: now,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late DeckEntity root;
  late DeckEntity leaf;
  ImportPickedFile? picked;

  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _now);
    root = await decks.root('r');
    leaf = await decks.sub(root.id, 'Nhà hàng');
    picked = _file(
      'vocab.csv',
      'front,back,tags\nmenu,thực đơn,food\nbill,,\n',
    );
  });
  tearDown(() => db.close());

  ProviderContainer container({CardRepository Function(CardRepository)? wrap}) {
    final cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _now),
      TagRepositoryImpl(db, now: _now),
      now: _now,
    );
    final result = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        importFilePickerProvider.overrideWithValue(() async => picked),
        if (wrap != null)
          commitImportUseCaseProvider.overrideWithValue(
            CommitImportUseCase(wrap(cards)),
          ),
      ],
    );
    addTearDown(result.dispose);
    return result;
  }

  CardImportDraft draftOf(ProviderContainer c) =>
      c.read(cardImportControllerProvider(leaf.id)) as CardImportDraft;

  test(
    'a file goes through the four steps and ends on a summary (steps 1–8)',
    () async {
      final c = container();
      final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
      c.listen(cardImportControllerProvider(leaf.id), (_, _) {});

      await wizard.chooseFile();
      expect(draftOf(c).fileName, 'vocab.csv');
      expect(draftOf(c).step, CardImportStep.source);

      await wizard.readSource();
      expect(draftOf(c).step, CardImportStep.columns);
      expect(draftOf(c).mapping.isComplete, isTrue);

      await wizard.previewRows();
      expect(draftOf(c).step, CardImportStep.preview);
      expect(draftOf(c).willWrite, 1);

      await wizard.commit();
      final done =
          c.read(cardImportControllerProvider(leaf.id)) as CardImportDone;
      expect(done.summary.kind, ImportSummaryKind.partial);
      expect(await _count(db), 1);
    },
  );

  test('a cancelled picker keeps the source chosen before (A5)', () async {
    final c = container();
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
    await wizard.chooseFile();

    picked = null;
    await wizard.chooseFile();

    expect(draftOf(c).fileName, 'vocab.csv');
  });

  test('a file that is not CSV, TSV or XLSX, or not UTF-8, is refused at step 1 (E1)', () async {
    final c = container();
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});

    picked = _file('deck.apkg', 'x');
    await wizard.chooseFile();
    expect(draftOf(c).problem, TransferRejection.unreadableFile);

    picked = (
      name: 'latin.csv',
      bytes: Uint8List.fromList([0x63, 0xE9, 0x2C, 0x62]),
    );
    await wizard.chooseFile();
    await wizard.readSource();
    expect(
      (draftOf(c).step, draftOf(c).problem),
      (CardImportStep.source, TransferRejection.badEncoding),
    );
  });

  test('pasted text is a source once it holds something (A1)', () async {
    final c = container();
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});

    wizard
      ..chooseSourceKind(CardImportSourceKind.paste)
      ..pasteText('   ');
    expect(draftOf(c).source, isNull);

    wizard.pasteText('front\tback\na\tb');
    await wizard.readSource();
    expect(draftOf(c).table!.rows.last, ['a', 'b']);
  });

  test('an unmapped back stops the preview, and mapping it lets it through (BR-TRANSFER-002)', () async {
    picked = _file('vocab.csv', 'term,meaning\na,b\n');
    final c = container();
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
    await wizard.chooseFile();
    await wizard.readSource();

    await wizard.previewRows();
    expect(draftOf(c).problem, TransferRejection.mappingIncomplete);

    wizard
      ..assignColumn(0, TransferField.front)
      ..assignColumn(1, TransferField.back);
    await wizard.previewRows();
    expect(draftOf(c).step, CardImportStep.preview);
  });

  test('Back steps back one step and keeps what it held; at step 1 it closes (IT-NAV-012)', () async {
    final c = container();
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
    await wizard.chooseFile();
    await wizard.readSource();
    wizard.assignColumn(2, null);
    await wizard.previewRows();

    expect(wizard.stepBack(), isTrue);
    expect(draftOf(c).step, CardImportStep.columns);
    expect(draftOf(c).mapping.columnOf(TransferField.front), 0);
    expect(draftOf(c).mapping.columnOf(TransferField.tags), isNull);
    expect(wizard.stepBack(), isTrue);
    expect(
      (draftOf(c).step, draftOf(c).fileName),
      (CardImportStep.source, 'vocab.csv'),
    );
    expect(wizard.stepBack(), isFalse);
  });

  test(
    'Back does nothing while the cards are written (IT-NAV-012 step 5)',
    () async {
      late _BrokenImport held;
      final c = container(
        wrap: (cards) => held = _BrokenImport(cards)
          ..isBroken = false
          ..hold = Completer<void>(),
      );
      final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
      c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
      await wizard.chooseFile();
      await wizard.readSource();
      await wizard.previewRows();

      final writing = wizard.commit();
      await pumpEventQueue();
      expect(draftOf(c).step, CardImportStep.importing);
      expect(wizard.stepBack(), isTrue);
      expect(draftOf(c).step, CardImportStep.importing);

      held.hold!.complete();
      await writing;
      expect(
        c.read(cardImportControllerProvider(leaf.id)),
        isA<CardImportDone>(),
      );
    },
  );

  test('Include duplicates writes them as new cards (A4)', () async {
    await insertCard(
      db,
      id: 'x',
      deckId: leaf.id,
      front: 'menu',
      back: 'thực đơn',
    );
    final c = container();
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
    await wizard.chooseFile();
    await wizard.readSource();
    await wizard.previewRows();
    expect(draftOf(c).willWrite, 0);

    wizard.setIncludingDuplicates(isIncluding: true);
    expect(draftOf(c).willWrite, 1);
    await wizard.commit();

    final done =
        c.read(cardImportControllerProvider(leaf.id)) as CardImportDone;
    expect(done.summary.written, 1);
    expect(await _count(db), 2);
  });

  test(
    'a deck that gained sub-decks refuses the commit: the rejects result (E4)',
    () async {
      final c = container();
      final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
      c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
      await wizard.chooseFile();
      await wizard.readSource();
      await wizard.previewRows();
      await decks.sub(leaf.id, 'child');

      await wizard.commit();

      final failed =
          c.read(cardImportControllerProvider(leaf.id)) as CardImportFailed;
      expect(failed.isTargetRejected, isTrue);
    },
  );

  test(
    'a write that fails keeps the preview, and Try again commits it again (E5)',
    () async {
      late _BrokenImport broken;
      final c = container(wrap: (cards) => broken = _BrokenImport(cards));
      final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
      c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
      await wizard.chooseFile();
      await wizard.readSource();
      await wizard.previewRows();

      await wizard.commit();
      final failed =
          c.read(cardImportControllerProvider(leaf.id)) as CardImportFailed;
      expect(
        (failed.isTargetRejected, failed.draft.step),
        (false, CardImportStep.preview),
      );
      expect(await _count(db), 0);

      broken.isBroken = false;
      await wizard.retry();
      expect(
        c.read(cardImportControllerProvider(leaf.id)),
        isA<CardImportDone>(),
      );
    },
  );

  test('Import another file starts a fresh step 1', () async {
    await insertCard(
      db,
      id: 'x',
      deckId: leaf.id,
      front: 'menu',
      back: 'thực đơn',
    );
    final c = container();
    final wizard = c.read(cardImportControllerProvider(leaf.id).notifier);
    c.listen(cardImportControllerProvider(leaf.id), (_, _) {});
    await wizard.chooseFile();
    await wizard.readSource();
    await wizard.previewRows();
    expect(draftOf(c).willWrite, 0);

    await wizard.commit();
    expect(draftOf(c).step, CardImportStep.preview);

    wizard.startOver();
    expect(draftOf(c).source, isNull);
  });
}

Future<int> _count(AppDatabase db) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM card').getSingle())
        .read<int>('n');
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/transfer/presentation/card_import_controller_test.dart
```

Expected: FAIL to compile: the controller and its providers do not exist.

- [ ] **Step 3: Implement**

`lib/features/transfer/presentation/providers/read_import_source_use_case_provider.dart`:

```dart
import 'package:memox/features/transfer/di/transfer_file_repository_provider.dart';
import 'package:memox/features/transfer/domain/usecases/read_import_source_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'read_import_source_use_case_provider.g.dart';

@riverpod
ReadImportSourceUseCase readImportSourceUseCase(Ref ref) =>
    ReadImportSourceUseCase(ref.watch(transferFileRepositoryProvider));
```

`lib/features/transfer/presentation/providers/preview_import_use_case_provider.dart`:

```dart
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/transfer/domain/usecases/preview_import_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'preview_import_use_case_provider.g.dart';

@riverpod
PreviewImportUseCase previewImportUseCase(Ref ref) =>
    PreviewImportUseCase(ref.watch(cardRepositoryProvider));
```

`lib/features/transfer/presentation/providers/commit_import_use_case_provider.dart`:

```dart
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/transfer/domain/usecases/commit_import_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'commit_import_use_case_provider.g.dart';

@riverpod
CommitImportUseCase commitImportUseCase(Ref ref) =>
    CommitImportUseCase(ref.watch(cardRepositoryProvider));
```

`lib/features/transfer/presentation/providers/import_file_picker_provider.dart`:

```dart
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'import_file_picker_provider.g.dart';

/// A file the user picked: its name, shown on the file chip and never
/// logged, and its bytes, read in memory (BR-TRANSFER-006).
typedef ImportPickedFile = ({String name, Uint8List bytes});

/// Opens the system file picker on CSV, TSV and XLSX; null when the user
/// cancels (UC-TRANSFER-001 A5). A provider so tests replace the platform.
@riverpod
Future<ImportPickedFile?> Function() importFilePicker(Ref ref) => () async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: [
      for (final format in TransferFormat.values) format.extension,
    ],
  );
  if (file == null) return null;
  return (name: file.name, bytes: await file.readAsBytes());
};
```

`lib/features/transfer/presentation/states/card_import_state.dart`:

```dart
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_summary_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';

/// The four steps of the tracker (kit 11, spec §8.1 ruling 4).
enum CardImportStep { source, columns, preview, importing }

/// The two sources of step 1 (UC-TRANSFER-001 step 2, A1).
enum CardImportSourceKind { file, paste }

/// What the import screen shows (kit 11): the wizard while the user works,
/// then one result.
sealed class CardImportState {
  const CardImportState();
}

/// Steps 1–4. Each step keeps what the earlier ones settled, so Back and a
/// failure never lose the user's work (UC-TRANSFER-001 E1, E4, E5).
final class CardImportDraft extends CardImportState {
  const CardImportDraft({
    this.step = CardImportStep.source,
    this.sourceKind = CardImportSourceKind.file,
    this.fileName,
    this.source,
    this.table,
    this.mapping = const ColumnMapping({}),
    this.hasHeaderRow = true,
    this.preview,
    this.isIncludingDuplicates = false,
    this.isBusy = false,
    this.problem,
  });

  final CardImportStep step;
  final CardImportSourceKind sourceKind;

  /// The picked file's name for its chip; kept in memory only
  /// (BR-TRANSFER-006).
  final String? fileName;

  /// Null until a file is picked or text is pasted.
  final TransferSource? source;

  /// The rows read at step 1; null before.
  final SourceTable? table;
  final ColumnMapping mapping;
  final bool hasHeaderRow;

  /// Null before step 3.
  final ImportPreview? preview;
  final bool isIncludingDuplicates;

  /// Reading or previewing is running.
  final bool isBusy;

  /// Why the last step was refused, shown where it happened.
  final TransferRejection? problem;

  /// What the commit bar's Import writes (UC-TRANSFER-001 step 6).
  int get willWrite =>
      preview?.willWrite(includeDuplicates: isIncludingDuplicates) ?? 0;

  CardImportDraft copyWith({
    CardImportStep? step,
    ColumnMapping? mapping,
    bool? hasHeaderRow,
    ImportPreview? preview,
    bool? isIncludingDuplicates,
    bool? isBusy,
    TransferRejection? problem,
    bool isProblemCleared = false,
  }) => CardImportDraft(
    step: step ?? this.step,
    sourceKind: sourceKind,
    fileName: fileName,
    source: source,
    table: table,
    mapping: mapping ?? this.mapping,
    hasHeaderRow: hasHeaderRow ?? this.hasHeaderRow,
    preview: preview ?? this.preview,
    isIncludingDuplicates: isIncludingDuplicates ?? this.isIncludingDuplicates,
    isBusy: isBusy ?? this.isBusy,
    problem: isProblemCleared ? null : problem ?? this.problem,
  );
}

/// The commit wrote what it could (UC-TRANSFER-001 step 8): success,
/// partial or none.
final class CardImportDone extends CardImportState {
  const CardImportDone(this.summary);

  final ImportSummary summary;
}

/// The commit wrote nothing: the deck no longer takes cards (E4), or a write
/// failed and rolled back (E5). [draft] is the preview Try again returns to.
final class CardImportFailed extends CardImportState {
  const CardImportFailed({required this.draft, required this.isTargetRejected});

  final CardImportDraft draft;
  final bool isTargetRejected;
}
```

`lib/features/transfer/presentation/controllers/card_import_controller.dart`:

```dart
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';
import 'package:memox/features/transfer/presentation/providers/commit_import_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/providers/preview_import_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/providers/read_import_source_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_import_controller.g.dart';

/// The import wizard of one deck (UC-TRANSFER-001, kit 11). Every step goes
/// through one use case; nothing is written before [commit].
@riverpod
class CardImportController extends _$CardImportController {
  @override
  CardImportState build(String deckId) => const CardImportDraft();

  CardImportDraft? get _draft => switch (state) {
    final CardImportDraft draft => draft,
    _ => null,
  };

  /// Step 1: a file from the system picker. A cancelled picker keeps the
  /// source chosen before (A5); a name that is not CSV, TSV or XLSX is
  /// refused at once (E1).
  Future<void> chooseFile() async {
    final draft = _draft;
    if (draft == null || draft.isBusy) return;
    final ImportPickedFile? picked;
    try {
      picked = await ref.read(importFilePickerProvider)();
    } on Object {
      // The platform's message may carry a path: only the reason shows.
      if (!ref.mounted) return;
      state = draft.copyWith(problem: TransferRejection.unreadableFile);
      return;
    }
    if (!ref.mounted || picked == null) return;
    final format = TransferFormat.ofFileName(picked.name);
    if (format == null) {
      state = CardImportDraft(
        fileName: picked.name,
        problem: TransferRejection.unreadableFile,
      );
      return;
    }
    state = CardImportDraft(
      fileName: picked.name,
      source: FileSource(bytes: picked.bytes, format: format),
    );
  }

  /// Step 1: switches the source between a file and pasted text.
  void chooseSourceKind(CardImportSourceKind kind) {
    final draft = _draft;
    if (draft == null || draft.isBusy || draft.sourceKind == kind) return;
    state = CardImportDraft(sourceKind: kind);
  }

  /// Step 1 (A1): the pasted text as it is typed; blank text is no source.
  void pasteText(String text) {
    final draft = _draft;
    if (draft == null || draft.isBusy) return;
    state = CardImportDraft(
      sourceKind: CardImportSourceKind.paste,
      source: text.trim().isEmpty ? null : PastedSource(text),
    );
  }

  /// Removes the chosen file or text: back to an empty step 1.
  void clearSource() {
    final draft = _draft;
    if (draft == null || draft.isBusy) return;
    state = CardImportDraft(sourceKind: draft.sourceKind);
  }

  /// Step 1 → 2 ("Read and map columns"), or another sheet of the same
  /// workbook (A2): the rows are read again and mapped from their header.
  Future<void> readSource({int? sheetIndex}) async {
    final draft = _draft;
    final source = draft?.source;
    if (draft == null || source == null || draft.isBusy) return;
    state = draft.copyWith(isBusy: true, isProblemCleared: true);
    final result = await ref.read(readImportSourceUseCaseProvider)(
      source,
      sheetIndex: sheetIndex,
    );
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => CardImportDraft(
        step: CardImportStep.columns,
        sourceKind: draft.sourceKind,
        fileName: draft.fileName,
        source: source,
        table: value,
        mapping: ColumnMapping.fromHeader(
          value.rows.isEmpty ? const [] : value.rows.first,
        ),
      ),
      Rejected(:final reason) => draft.copyWith(isBusy: false, problem: reason),
    };
  }

  /// Step 2 (A3): whether the first row names the columns. The mapping the
  /// user made stays.
  void setHasHeaderRow({required bool hasHeaderRow}) {
    final draft = _draft;
    if (draft == null || draft.step != CardImportStep.columns) return;
    state = draft.copyWith(hasHeaderRow: hasHeaderRow, isProblemCleared: true);
  }

  /// Step 2: [column] feeds [field], or nothing when it is null
  /// (BR-TRANSFER-002).
  void assignColumn(int column, TransferField? field) {
    final draft = _draft;
    if (draft == null || draft.step != CardImportStep.columns) return;
    state = draft.copyWith(
      mapping: draft.mapping.assign(column, field),
      isProblemCleared: true,
    );
  }

  /// Step 2 → 3 ("Preview rows"): every row's status against the deck as it
  /// is now.
  Future<void> previewRows() async {
    final draft = _draft;
    final table = draft?.table;
    if (draft == null || table == null || draft.isBusy) return;
    state = draft.copyWith(isBusy: true, isProblemCleared: true);
    final result = await ref.read(previewImportUseCaseProvider)(
      deckId: deckId,
      table: table,
      mapping: draft.mapping,
      hasHeaderRow: draft.hasHeaderRow,
    );
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => draft.copyWith(
        step: CardImportStep.preview,
        preview: value,
        isBusy: false,
      ),
      Rejected(:final reason) => draft.copyWith(isBusy: false, problem: reason),
    };
  }

  /// Step 3 (A4): write the duplicates as new cards too.
  void setIncludingDuplicates({required bool isIncluding}) {
    final draft = _draft;
    if (draft == null || draft.step != CardImportStep.preview) return;
    state = draft.copyWith(isIncludingDuplicates: isIncluding);
  }

  /// Step 3 → 4 → a result (UC-TRANSFER-001 steps 6–8, E3–E5).
  Future<void> commit() async {
    final draft = _draft;
    final preview = draft?.preview;
    if (draft == null || preview == null || draft.isBusy) return;
    if (draft.willWrite == 0) return;
    state = draft.copyWith(step: CardImportStep.importing, isBusy: true);
    try {
      final result = await ref.read(commitImportUseCaseProvider)(
        deckId: deckId,
        preview: preview,
        includeDuplicates: draft.isIncludingDuplicates,
      );
      if (!ref.mounted) return;
      state = switch (result) {
        Ok(:final value) => CardImportDone(value),
        Rejected(reason: TransferRejection.targetRejected) => CardImportFailed(
          draft: draft,
          isTargetRejected: true,
        ),
        Rejected(:final reason) => draft.copyWith(problem: reason),
      };
    } on Failure {
      if (!ref.mounted) return;
      state = CardImportFailed(draft: draft, isTargetRejected: false);
    }
  }

  /// "Try again" after a failed write: the same preview, committed again
  /// (E5).
  Future<void> retry() async {
    if (state case CardImportFailed(:final draft, isTargetRejected: false)) {
      state = draft;
      await commit();
    }
  }

  /// "Import another file" after a result: a fresh step 1 for the same deck
  /// (UC-TRANSFER-001 step 8).
  void startOver() => state = const CardImportDraft();

  /// Android Back and the app bar's Back (IT-NAV-012 step 4): one step back,
  /// keeping what the step held. False at step 1 and on a result, where the
  /// screen closes. While writing, Back does nothing (step 5).
  bool stepBack() {
    final draft = _draft;
    if (draft == null) return false;
    switch (draft.step) {
      case CardImportStep.source:
        return false;
      case CardImportStep.importing:
        return true;
      case CardImportStep.columns:
        state = CardImportDraft(
          sourceKind: draft.sourceKind,
          fileName: draft.fileName,
          source: draft.source,
        );
        return true;
      case CardImportStep.preview:
        state = CardImportDraft(
          step: CardImportStep.columns,
          sourceKind: draft.sourceKind,
          fileName: draft.fileName,
          source: draft.source,
          table: draft.table,
          mapping: draft.mapping,
          hasHeaderRow: draft.hasHeaderRow,
        );
        return true;
    }
  }
}
```

- [ ] **Step 4: Generate and run**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/transfer/presentation/card_import_controller_test.dart
flutter analyze
```

Expected: 11 tests PASS; no analyzer issue.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/features/transfer/presentation/providers/read_import_source_use_case_provider.dart \
  lib/features/transfer/presentation/providers/preview_import_use_case_provider.dart \
  lib/features/transfer/presentation/providers/commit_import_use_case_provider.dart \
  lib/features/transfer/presentation/providers/import_file_picker_provider.dart \
  lib/features/transfer/presentation/states/card_import_state.dart \
  lib/features/transfer/presentation/controllers/card_import_controller.dart \
  test/features/transfer/presentation/card_import_controller_test.dart
git commit -m "$(cat <<'EOF'
feat(transfer): the import wizard state and controller (UC-TRANSFER-001)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 3: The step widgets

These widgets have no screen yet; Task 4 tests them through the screen, its goldens
and its visual audit. This task stops at a clean analyzer.

**Files:**
- Create: `lib/features/transfer/presentation/widgets/support/import_labels_widget.dart`
- Create: `lib/features/transfer/presentation/widgets/sections/import_step_tracker_widget.dart`
- Create: `lib/features/transfer/presentation/widgets/items/import_source_option_widget.dart`
- Create: `lib/features/transfer/presentation/widgets/overlays/import_option_sheet_widget.dart`
- Create: `lib/features/transfer/presentation/widgets/sections/import_source_section_widget.dart`
- Create: `lib/features/transfer/presentation/widgets/items/import_mapping_row_widget.dart`
- Create: `lib/features/transfer/presentation/widgets/sections/import_mapping_section_widget.dart`
- Create: `lib/features/transfer/presentation/widgets/items/import_preview_row_widget.dart`
- Create: `lib/features/transfer/presentation/widgets/sections/import_preview_section_widget.dart`
- Create: `lib/features/transfer/presentation/widgets/sections/import_commit_bar_widget.dart`
- Create: `lib/features/transfer/presentation/widgets/sections/import_result_widget.dart`

**Interfaces:**
- Consumes: `CardImportDraft`, `CardImportState`, the transfer domain models, the `Mx*`
  widget set.
- Produces: `ImportLabels` (step, field, row note and problem names);
  `ImportStepTrackerWidget(current)`; `ImportSourceSectionWidget`,
  `ImportMappingSectionWidget`, `ImportPreviewSectionWidget` (`shownRows = 50`),
  `ImportCommitBarWidget`, `ImportResultWidget`; `showImportOptionSheet<T>`.

- [ ] **Step 1: Implement**

`lib/features/transfer/presentation/widgets/support/import_labels_widget.dart`:

```dart
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The import screen's copy for its domain values (kit 11).
extension ImportLabels on AppLocalizations {
  String importStepName(CardImportStep step) => switch (step) {
    CardImportStep.source => importStepSource,
    CardImportStep.columns => importStepColumns,
    CardImportStep.preview => importStepPreview,
    CardImportStep.importing => importStepImport,
  };

  String importField(TransferField? field) => switch (field) {
    null => importFieldNone,
    TransferField.front => importFieldFront,
    TransferField.back => importFieldBack,
    TransferField.example => importFieldExample,
    TransferField.hint => importFieldHint,
    TransferField.pronunciation => importFieldPronunciation,
    TransferField.tags => importFieldTags,
  };

  /// Why a row will not be written, or null for a ready row.
  String? importRowNote(ImportRow row) => switch (row.kind) {
    ImportRowKind.ready => null,
    ImportRowKind.blank => importRowBlank,
    ImportRowKind.duplicateInDeck => importRowDuplicateInDeck,
    ImportRowKind.duplicateInSource => importRowDuplicateInSource(
      row.firstRowNumber!,
    ),
    ImportRowKind.invalid => _invalid(row),
  };

  String _invalid(ImportRow row) => switch (row.reason) {
    CardRejection.blankContent when row.draft!.front.trim().isEmpty =>
      importRowFrontEmpty,
    CardRejection.blankContent => importRowBackEmpty,
    CardRejection.frontTooLong => importRowFrontTooLong,
    CardRejection.backTooLong => importRowBackTooLong,
    CardRejection.optionalFieldTooLong => importRowOptionalTooLong,
    CardRejection.invalidTagName => importRowInvalidTag,
    CardRejection.tooManyTags => importRowTooManyTags,
    _ => importRowOptionalTooLong,
  };

  /// A refusal of step 1 or 2, as a title and what to do.
  ({String title, String body}) importProblem(TransferRejection reason) =>
      switch (reason) {
        TransferRejection.badEncoding => (
          title: importProblemEncodingTitle,
          body: importProblemEncodingBody,
        ),
        TransferRejection.emptySource => (
          title: importProblemEmptyTitle,
          body: importProblemEmptyBody,
        ),
        _ => (
          title: importProblemUnreadableTitle,
          body: importProblemUnreadableBody,
        ),
      };
}
```

`lib/features/transfer/presentation/widgets/sections/import_step_tracker_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/support/import_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';

/// The four steps of the import (kit 11's tracker, spec §8.1 ruling 4): done
/// steps in the mastery colour with a check, the current one in primary with
/// its number, later ones muted. It is not a control.
class ImportStepTrackerWidget extends StatelessWidget {
  const ImportStepTrackerWidget({super.key, required this.current});

  final CardImportStep current;

  static const double _dot = AppIconSize.compact;

  /// The shortest connector a one-row tracker keeps; below it the steps wrap.
  static const double _minLine = AppSpacing.control;

  /// A connector's length when the steps wrap.
  static const double _wrappedLine = AppSpacing.grouped;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = [
      for (final step in CardImportStep.values) l10n.importStepName(step),
    ];
    return Semantics(
      label: l10n.importStepLabel(
        current.index + 1,
        l10n.importStepName(current),
      ),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            0,
            AppSpacing.gutter,
            AppSpacing.grouped,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) =>
                _oneRowWidth(context, labels) <= constraints.maxWidth
                ? Row(
                    spacing: AppSpacing.micro,
                    children: _children(labels, isOneRow: true),
                  )
                : Wrap(
                    spacing: AppSpacing.micro,
                    runSpacing: AppSpacing.micro,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: _children(labels, isOneRow: false),
                  ),
          ),
        ),
      ),
    );
  }

  /// The steps with a connector between each pair: stretched to fill one
  /// row, or of a fixed length when they wrap (large text).
  List<Widget> _children(List<String> labels, {required bool isOneRow}) => [
    for (final (index, step) in CardImportStep.values.indexed) ...[
      _Step(
        number: index + 1,
        label: labels[index],
        isDone: step.index < current.index,
        isCurrent: step == current,
      ),
      if (index < labels.length - 1)
        isOneRow
            ? Expanded(child: _Line(isDone: step.index < current.index))
            : SizedBox(
                width: _wrappedLine,
                child: _Line(isDone: step.index < current.index),
              ),
    ],
  ];

  /// The width the four steps need on one row with the shortest connectors,
  /// at the reader's text scale.
  double _oneRowWidth(BuildContext context, List<String> labels) {
    final style = context.textStyles.stepLabel(isReached: true);
    var width = (labels.length - 1) * (_minLine + 2 * AppSpacing.micro);
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      width += _dot + AppSpacing.micro + painter.width;
      painter.dispose();
    }
    return width;
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.label,
    required this.isDone,
    required this.isCurrent,
  });

  final int number;
  final String label;
  final bool isDone;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semantic = context.semanticColors;
    final fill = isDone
        ? semantic.mastery
        : isCurrent
        ? colors.primary
        : colors.surfaceContainerHigh;
    final ink = isDone || isCurrent
        ? colors.onPrimary
        : colors.onSurfaceVariant;
    final styles = context.textStyles;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.micro,
      children: [
        SizedBox.square(
          dimension: ImportStepTrackerWidget._dot,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Center(
              child: isDone
                  ? IconTheme.merge(
                      data: IconThemeData(color: ink, size: AppIconSize.inline),
                      child: const Icon(AppIcons.check),
                    )
                  : Text(
                      context.l10n.importStepNumber(number),
                      style: styles.stepNumber(ink),
                    ),
            ),
          ),
        ),
        Text(label, style: styles.stepLabel(isReached: isDone || isCurrent)),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.isDone});

  final bool isDone;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppStroke.indicator,
    child: ColoredBox(
      color: isDone
          ? context.semanticColors.mastery
          : context.derivedColors.ghostBorder,
    ),
  );
}
```

`lib/features/transfer/presentation/widgets/items/import_source_option_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

/// One of the two sources of step 1 (kit 11): a file or pasted text. The
/// chosen one is the selected card.
class ImportSourceOptionWidget extends StatelessWidget {
  const ImportSourceOptionWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.isSelected,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final String hint;
  final bool isSelected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Semantics(
      selected: isSelected,
      button: true,
      child: MxCard(
        isFullBleed: true,
        isSelected: isSelected,
        child: MxRowInk(
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.grouped),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.micro,
              children: [
                MxIconTile(icon: icon),
                const SizedBox(height: AppSpacing.micro),
                Text(label, style: styles.contentTitle),
                Text(hint, style: styles.rowDescription),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

`lib/features/transfer/presentation/widgets/overlays/import_option_sheet_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

/// A one-choice sheet of the import (kit 11): the field a column feeds, or
/// the sheet of a workbook (A2). The chosen option closes the sheet.
Future<void> showImportOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required T selected,
  required String Function(T option) label,
  required ValueChanged<T> onSelected,
}) => showMxBottomSheet<void>(
  context,
  builder: (sheetContext) => ImportOptionSheetWidget<T>(
    title: title,
    options: options,
    selected: selected,
    label: label,
    onSelected: (option) {
      onSelected(option);
      Navigator.of(sheetContext).pop();
    },
  ),
);

class ImportOptionSheetWidget<T> extends StatelessWidget {
  const ImportOptionSheetWidget({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final String title;
  final List<T> options;
  final T selected;
  final String Function(T option) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => MxBottomSheet(
    header: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.card,
        AppSpacing.micro,
        AppSpacing.card,
        AppSpacing.grouped,
      ),
      child: Text(title, style: context.textStyles.compactTitle),
    ),
    child: Column(
      children: [
        for (final (index, option) in options.indexed)
          MxOptionRow(
            title: label(option),
            isSelected: option == selected,
            onSelected: () => onSelected(option),
            hasDivider: index < options.length - 1,
          ),
      ],
    ),
  );
}
```

`lib/features/transfer/presentation/widgets/sections/import_source_section_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_source_option_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/overlays/import_option_sheet_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/support/import_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// Step 1 of the import (kit 11). While choosing: the two sources, then the
/// file picker, the pasted text, the problem or the reading card. Once the
/// source is read, only its chip stays (kit deviation K1).
class ImportSourceSectionWidget extends StatefulWidget {
  const ImportSourceSectionWidget({
    super.key,
    required this.draft,
    required this.onChooseKind,
    required this.onChooseFile,
    required this.onPaste,
    required this.onClear,
    required this.onChooseSheet,
  });

  final CardImportDraft draft;
  final ValueChanged<CardImportSourceKind> onChooseKind;
  final VoidCallback onChooseFile;
  final ValueChanged<String> onPaste;
  final VoidCallback onClear;
  final ValueChanged<int> onChooseSheet;

  @override
  State<ImportSourceSectionWidget> createState() =>
      _ImportSourceSectionWidgetState();
}

class _ImportSourceSectionWidgetState extends State<ImportSourceSectionWidget> {
  late final _pasted = TextEditingController(
    text: switch (widget.draft.source) {
      PastedSource(:final text) => text,
      _ => '',
    },
  );

  @override
  void dispose() {
    _pasted.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = widget.draft;
    final isChoosing = draft.step == CardImportStep.source;
    final isPaste = draft.sourceKind == CardImportSourceKind.paste;
    final canChange = !draft.isBusy;
    final children = <Widget>[
      if (isChoosing) ...[
        MxListSectionHeader(label: l10n.importSectionSource),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.control,
            children: [
              Expanded(
                child: ImportSourceOptionWidget(
                  icon: AppIcons.fileUp,
                  label: l10n.importSourceFile,
                  hint: l10n.importSourceFileHint,
                  isSelected: !isPaste,
                  onSelected: canChange
                      ? () => widget.onChooseKind(CardImportSourceKind.file)
                      : null,
                ),
              ),
              Expanded(
                child: ImportSourceOptionWidget(
                  icon: AppIcons.clipboard,
                  label: l10n.importSourcePaste,
                  hint: l10n.importSourcePasteHint,
                  isSelected: isPaste,
                  onSelected: canChange
                      ? () => widget.onChooseKind(CardImportSourceKind.paste)
                      : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.gutter),
      ],
      ..._body(context),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  List<Widget> _body(BuildContext context) {
    final l10n = context.l10n;
    final draft = widget.draft;
    final isChoosing = draft.step == CardImportStep.source;
    if (isChoosing && draft.isBusy) {
      return [_ReadingCard(label: l10n.importReading)];
    }
    final problem = draft.problem;
    if (isChoosing && problem != null) {
      final copy = l10n.importProblem(problem);
      return [
        MxInlineBanner(
          tone: MxBannerTone.warning,
          title: copy.title,
          message: copy.body,
          actions: [
            if (draft.sourceKind == CardImportSourceKind.file)
              MxButton(
                label: l10n.importChooseAnother,
                icon: AppIcons.folderOpen,
                tone: MxButtonTone.outline,
                size: MxButtonSize.small,
                onPressed: widget.onChooseFile,
              ),
          ],
        ),
        if (draft.sourceKind == CardImportSourceKind.paste) ...[
          const SizedBox(height: AppSpacing.grouped),
          _pasteField(context),
        ],
      ];
    }
    if (draft.sourceKind == CardImportSourceKind.paste && isChoosing) {
      return [
        _pasteField(context),
        const SizedBox(height: AppSpacing.grouped),
        MxNote(text: l10n.importHelperBody),
      ];
    }
    if (draft.source == null) {
      return [
        MxCard(
          child: MxEmptyState(
            icon: AppIcons.fileUp,
            title: l10n.importPickTitle,
            body: l10n.importPickBody,
            isCompact: true,
            actionLabel: l10n.importPickAction,
            onAction: widget.onChooseFile,
          ),
        ),
        const SizedBox(height: AppSpacing.grouped),
        MxNote(text: l10n.importHelperBody),
      ];
    }
    return [
      _SourceChip(
        draft: draft,
        onClear: draft.isBusy ? null : widget.onClear,
        onChooseSheet: widget.onChooseSheet,
      ),
      if (isChoosing) ...[
        const SizedBox(height: AppSpacing.grouped),
        MxNote(text: l10n.importHelperBody),
      ],
    ];
  }

  Widget _pasteField(BuildContext context) {
    final l10n = context.l10n;
    final lines = _pasted.text.trim().isEmpty
        ? 0
        : _pasted.text.trim().split('\n').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.micro,
      children: [
        MxTextField(
          controller: _pasted,
          label: l10n.importSourcePaste,
          hintText: l10n.importPasteHint,
          variant: MxTextFieldVariant.detail,
          onChanged: (text) {
            widget.onPaste(text);
            setState(() {});
          },
        ),
        if (lines > 0)
          Text(
            l10n.importPastedLines(lines),
            style: context.textStyles.rowDescription,
          ),
      ],
    );
  }
}

/// The source once chosen (kit 11 file chip): its name and what was read,
/// the sheet of a workbook with several (spec §8.1 ruling 2), and a remove
/// button that returns to an empty step 1.
class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.draft,
    required this.onClear,
    required this.onChooseSheet,
  });

  final CardImportDraft draft;
  final VoidCallback? onClear;
  final ValueChanged<int> onChooseSheet;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final source = draft.source;
    final table = draft.table;
    final format = switch (source) {
      FileSource(:final format) => format.extension.toUpperCase(),
      _ => l10n.importPastedFormat,
    };
    final isFile = source is FileSource;
    final meta = table == null
        ? l10n.importFileReady(format)
        : l10n.importFileRead(format, table.rows.length, table.columnCount);
    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.control,
        children: [
          Row(
            spacing: AppSpacing.grouped,
            children: [
              MxIconTile(icon: isFile ? AppIcons.fileText : AppIcons.clipboard),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.micro,
                  children: [
                    Text(
                      isFile ? draft.fileName ?? '' : l10n.importSourcePaste,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: styles.contentTitle,
                    ),
                    Text(meta, style: styles.rowDescription),
                  ],
                ),
              ),
              MxIconButton(
                icon: AppIcons.close,
                semanticLabel: l10n.importRemoveSource,
                onPressed: onClear,
              ),
            ],
          ),
          if (table != null && table.sheetNames.length > 1)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _SheetTrigger(table: table, onChooseSheet: onChooseSheet),
            ),
        ],
      ),
    );
  }
}

class _SheetTrigger extends StatelessWidget {
  const _SheetTrigger({required this.table, required this.onChooseSheet});

  final SourceTable table;
  final ValueChanged<int> onChooseSheet;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final names = table.sheetNames;
    return MxChipTrigger(
      label: l10n.importSheet(
        names[table.sheetIndex],
        table.sheetIndex + 1,
        names.length,
      ),
      onPressed: () => showImportOptionSheet<int>(
        context,
        title: l10n.importSheetPickerTitle,
        options: [for (var index = 0; index < names.length; index++) index],
        selected: table.sheetIndex,
        label: (index) => names[index],
        onSelected: onChooseSheet,
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => MxCard(
    child: Column(
      spacing: AppSpacing.grouped,
      children: [
        MxSpinner(size: MxSpinnerSize.large, semanticLabel: label),
        Text(label, style: context.textStyles.emptyBody),
      ],
    ),
  );
}
```

`lib/features/transfer/presentation/widgets/items/import_mapping_row_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/presentation/widgets/overlays/import_option_sheet_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/support/import_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

/// One source column and the field it feeds (kit 11 mapping row): its
/// position name, the header it had, and a picker of the six fields or none.
class ImportMappingRowWidget extends StatelessWidget {
  const ImportMappingRowWidget({
    super.key,
    required this.column,
    required this.header,
    required this.field,
    required this.onAssign,
  });

  final int column;

  /// The first row's cell, when the first row is a header.
  final String? header;
  final TransferField? field;
  final ValueChanged<TransferField?> onAssign;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final letter = columnLetter(column);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.grouped,
      ),
      child: Row(
        spacing: AppSpacing.control,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.micro,
              children: [
                Text(
                  l10n.importColumnName(letter),
                  style: styles.rowDescription,
                ),
                if (header case final text? when text.trim().isNotEmpty)
                  Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: styles.contentTitle,
                  ),
              ],
            ),
          ),
          ExcludeSemantics(
            child: IconTheme.merge(
              data: IconThemeData(
                color: context.colors.onSurfaceVariant,
                size: AppIconSize.inline,
              ),
              child: const Icon(AppIcons.arrowRight),
            ),
          ),
          MxChipTrigger(
            label: l10n.importField(field),
            onPressed: () => showImportOptionSheet<TransferField?>(
              context,
              title: l10n.importFieldPickerTitle(letter),
              options: const [null, ...TransferField.values],
              selected: field,
              label: l10n.importField,
              onSelected: onAssign,
            ),
          ),
        ],
      ),
    );
  }
}
```

`lib/features/transfer/presentation/widgets/sections/import_mapping_section_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_mapping_row_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// Step 2 of the import (kit 11): whether the first row is a header, and the
/// field each column feeds. An unmapped face says so on its own row, above
/// the note (BR-TRANSFER-002; kit deviation K3).
class ImportMappingSectionWidget extends StatelessWidget {
  const ImportMappingSectionWidget({
    super.key,
    required this.draft,
    required this.onHeaderRow,
    required this.onAssign,
  });

  final CardImportDraft draft;
  final ValueChanged<bool> onHeaderRow;
  final void Function(int column, TransferField? field) onAssign;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final table = draft.table!;
    final header = draft.hasHeaderRow && table.rows.isNotEmpty
        ? table.rows.first
        : null;
    String? headerOf(int column) =>
        header != null && column < header.length ? header[column] : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxSection(
          title: l10n.importSectionColumns,
          children: [
            MxSettingsRow(
              label: l10n.importHeaderToggle,
              onTap: () => onHeaderRow(!draft.hasHeaderRow),
              subtitle: header
                  ?.where((cell) => cell.trim().isNotEmpty)
                  .join(' · '),
              trailing: MxToggle(
                isOn: draft.hasHeaderRow,
                onChanged: onHeaderRow,
                semanticLabel: l10n.importHeaderToggle,
              ),
            ),
            for (var column = 0; column < table.columnCount; column++)
              ImportMappingRowWidget(
                column: column,
                header: headerOf(column),
                field: draft.mapping.fieldByColumn[column],
                onAssign: (field) => onAssign(column, field),
              ),
          ],
        ),
        if (!draft.mapping.isComplete) ...[
          MxInlineBanner(
            tone: MxBannerTone.warning,
            message: l10n.importMappingIncomplete,
          ),
          const SizedBox(height: AppSpacing.grouped),
        ],
        MxNote(text: l10n.importMappingNote),
      ],
    );
  }
}
```

`lib/features/transfer/presentation/widgets/items/import_preview_row_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/presentation/widgets/support/import_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';

/// One source row in the preview (kit 11 preview table): its number, the
/// term and the meaning on up to two lines each, why it will not be written,
/// and its status mark. The mark carries its words for TalkBack, so the
/// status is never colour alone (kit deviation K3).
class ImportPreviewRowWidget extends StatelessWidget {
  const ImportPreviewRowWidget({super.key, required this.row});

  final ImportRow row;

  static const int _maxLines = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final draft = row.draft;
    final note = l10n.importRowNote(row);
    final back = draft?.back.trim() ?? '';
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: AppSpacing.grouped,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.grouped,
          children: [
            Text(
              '${row.rowNumber}',
              semanticsLabel: l10n.importRowNumber(row.rowNumber),
              style: styles.counter,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.micro,
                children: [
                  if (draft != null) ...[
                    Text(
                      draft.front.trim().isEmpty
                          ? l10n.importRowEmptyCell
                          : draft.front.trim(),
                      maxLines: _maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: styles.contentTitle,
                    ),
                    Text(
                      back.isEmpty ? l10n.importRowEmptyCell : back,
                      maxLines: _maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: styles.rowDescription,
                    ),
                  ],
                  if (note != null)
                    Text(
                      note,
                      style: row.kind == ImportRowKind.invalid
                          ? styles.statusLabel(context.derivedColors.warningInk)
                          : styles.rowDescription,
                    ),
                ],
              ),
            ),
            _Mark(kind: row.kind, label: note ?? l10n.importRowReady),
          ],
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.kind, required this.label});

  final ImportRowKind kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (icon, color) = switch (kind) {
      ImportRowKind.ready => (AppIcons.check, context.semanticColors.mastery),
      ImportRowKind.invalid => (
        AppIcons.close,
        context.derivedColors.warningInk,
      ),
      ImportRowKind.duplicateInDeck || ImportRowKind.duplicateInSource => (
        AppIcons.cardDeck,
        colors.onSurfaceVariant,
      ),
      ImportRowKind.blank => (AppIcons.remove, colors.onSurfaceVariant),
    };
    return Semantics(
      label: label,
      child: IconTheme.merge(
        data: IconThemeData(color: color, size: AppIconSize.compact),
        child: Icon(icon),
      ),
    );
  }
}
```

`lib/features/transfer/presentation/widgets/sections/import_preview_section_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_preview_row_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// Step 3 of the import (kit 11): the counts, the first rows with their
/// status, and the duplicate policy (UC-TRANSFER-001 step 5, A4). A large
/// source shows its first rows and says so (kit deviation K2).
class ImportPreviewSectionWidget extends StatelessWidget {
  const ImportPreviewSectionWidget({
    super.key,
    required this.draft,
    required this.onIncludeDuplicates,
  });

  final CardImportDraft draft;
  final ValueChanged<bool> onIncludeDuplicates;

  /// The rows the table shows before "Showing the first …" (K2).
  static const int shownRows = 50;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preview = draft.preview!;
    final shown = preview.rows.take(shownRows).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxListSectionHeader(
          label: l10n.importSectionPreview,
          trailing: Text(
            l10n.importPreviewReady(preview.ready, preview.total),
            style: context.textStyles.counter,
          ),
        ),
        Wrap(
          spacing: AppSpacing.micro,
          runSpacing: AppSpacing.micro,
          children: [
            if (preview.ready > 0)
              MxBadge(
                label: l10n.importBadgeReady(preview.ready),
                tone: MxBadgeTone.mastery,
                icon: AppIcons.check,
              ),
            if (preview.invalid > 0)
              MxBadge(
                label: l10n.importBadgeInvalid(preview.invalid),
                tone: MxBadgeTone.warning,
                icon: AppIcons.alert,
              ),
            if (preview.duplicates > 0)
              MxBadge(
                label: l10n.importBadgeDuplicate(preview.duplicates),
                tone: MxBadgeTone.neutral,
                icon: AppIcons.cardDeck,
              ),
            if (preview.blank > 0)
              MxBadge(
                label: l10n.importBadgeBlank(preview.blank),
                tone: MxBadgeTone.neutral,
                icon: AppIcons.remove,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.grouped),
        MxSection(
          note: preview.total > shown.length
              ? l10n.importShowingFirst(shown.length, preview.total)
              : null,
          children: [for (final row in shown) ImportPreviewRowWidget(row: row)],
        ),
        if (preview.duplicates > 0)
          MxSection(
            children: [
              MxSettingsRow(
                label: l10n.importIncludeDuplicates,
                subtitle: l10n.importIncludeDuplicatesBody,
                onTap: () => onIncludeDuplicates(!draft.isIncludingDuplicates),
                trailing: MxToggle(
                  isOn: draft.isIncludingDuplicates,
                  onChanged: onIncludeDuplicates,
                  semanticLabel: l10n.importIncludeDuplicates,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
```

`lib/features/transfer/presentation/widgets/sections/import_commit_bar_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';

/// The import's commit bar (kit 11): Cancel, the step's one action, and a
/// caption that says what happens next. Nothing is written before Import
/// (UC-TRANSFER-001 step 6); while it runs, only waiting is possible.
class ImportCommitBarWidget extends StatelessWidget {
  const ImportCommitBarWidget({
    super.key,
    required this.draft,
    required this.onCancel,
    required this.onRead,
    required this.onPreview,
    required this.onCommit,
  });

  final CardImportDraft draft;
  final VoidCallback onCancel;
  final VoidCallback onRead;
  final VoidCallback onPreview;
  final VoidCallback onCommit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isBusy = draft.isBusy;
    final (label, icon, action, caption) = switch (draft.step) {
      CardImportStep.source => (
        l10n.importReadAction,
        AppIcons.arrowRight,
        draft.source == null ? null : onRead,
        draft.source == null
            ? l10n.importCaptionSource
            : l10n.importCaptionPrivate,
      ),
      CardImportStep.columns => (
        l10n.importPreviewAction,
        AppIcons.preview,
        draft.mapping.isComplete ? onPreview : null,
        l10n.importCaptionColumns,
      ),
      CardImportStep.preview => (
        l10n.importCommitAction(draft.willWrite),
        AppIcons.download,
        draft.willWrite > 0 ? onCommit : null,
        l10n.importCaptionPreview(draft.willWrite),
      ),
      CardImportStep.importing => (
        l10n.importCommitting,
        AppIcons.download,
        null,
        l10n.importCaptionPrivate,
      ),
    };
    final isImporting = draft.step == CardImportStep.importing;
    return MxFooterBar(
      caption: caption,
      child: Row(
        spacing: AppSpacing.control,
        children: [
          MxButton(
            label: l10n.commonCancel,
            tone: MxButtonTone.outline,
            onPressed: isImporting ? null : onCancel,
          ),
          Expanded(
            child: MxButton(
              label: label,
              icon: icon,
              isBlock: true,
              isLoading: isBusy,
              onPressed: isBusy ? null : action,
            ),
          ),
        ],
      ),
    );
  }
}
```

`lib/features/transfer/presentation/widgets/sections/import_result_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/domain/models/import_summary_model.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_section.dart';

/// How an import ended (kit 11 results; UC-TRANSFER-001 step 8, E4, E5):
/// the design system's empty state in the result's tone (kit deviation K4),
/// then what was added and skipped.
class ImportResultWidget extends StatelessWidget {
  const ImportResultWidget({super.key, required this.state});

  /// A [CardImportDone] or a [CardImportFailed].
  final CardImportState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (state) {
      CardImportDone(:final summary) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switch (summary.kind) {
            ImportSummaryKind.success => MxEmptyState(
              icon: AppIcons.learned,
              tone: MxEmptyStateTone.success,
              title: l10n.importDoneTitle,
              body: l10n.importDoneBody(summary.written),
            ),
            ImportSummaryKind.partial => MxEmptyState(
              icon: AppIcons.learned,
              tone: MxEmptyStateTone.success,
              title: l10n.importPartialTitle,
              body: l10n.importPartialBody,
            ),
            ImportSummaryKind.none => MxEmptyState(
              icon: AppIcons.cardDeck,
              tone: MxEmptyStateTone.neutral,
              title: l10n.importNoneTitle,
              body: l10n.importNoneBody,
            ),
          },
          if (summary.kind != ImportSummaryKind.none) ...[
            const SizedBox(height: AppSpacing.gutter),
            _Counts(summary: summary),
          ],
          if (summary.kind == ImportSummaryKind.partial)
            MxNote(text: l10n.importSkipNote),
        ],
      ),
      CardImportFailed(isTargetRejected: true) => MxEmptyState(
        icon: AppIcons.library,
        tone: MxEmptyStateTone.warning,
        title: l10n.importRejectsTitle,
        body: l10n.importRejectsBody,
      ),
      _ => MxEmptyState(
        icon: AppIcons.alert,
        tone: MxEmptyStateTone.danger,
        title: l10n.importFailedTitle,
        body: l10n.importFailedBody,
      ),
    };
  }
}

class _Counts extends StatelessWidget {
  const _Counts({required this.summary});

  final ImportSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = context.textStyles.counter;
    MxListRow row(IconData icon, String label, int value) => MxListRow(
      title: label,
      leading: MxIconTile(icon: icon),
      trailing: Text(l10n.importResultCount(value), style: count),
    );
    return MxSection(
      children: [
        row(AppIcons.check, l10n.importCountAdded, summary.written),
        if (summary.duplicatesSkipped > 0)
          row(
            AppIcons.cardDeck,
            l10n.importCountDuplicates,
            summary.duplicatesSkipped,
          ),
        if (summary.invalid > 0)
          row(AppIcons.alert, l10n.importCountInvalid, summary.invalid),
      ],
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
dart format lib/features/transfer
flutter analyze
```

Expected: `Formatted … (0 changed)`; no analyzer issue.

- [ ] **Step 3: Commit**

```bash
git add \
  lib/features/transfer/presentation/widgets/support/import_labels_widget.dart \
  lib/features/transfer/presentation/widgets/sections/import_step_tracker_widget.dart \
  lib/features/transfer/presentation/widgets/items/import_source_option_widget.dart \
  lib/features/transfer/presentation/widgets/overlays/import_option_sheet_widget.dart \
  lib/features/transfer/presentation/widgets/sections/import_source_section_widget.dart \
  lib/features/transfer/presentation/widgets/items/import_mapping_row_widget.dart \
  lib/features/transfer/presentation/widgets/sections/import_mapping_section_widget.dart \
  lib/features/transfer/presentation/widgets/items/import_preview_row_widget.dart \
  lib/features/transfer/presentation/widgets/sections/import_preview_section_widget.dart \
  lib/features/transfer/presentation/widgets/sections/import_commit_bar_widget.dart \
  lib/features/transfer/presentation/widgets/sections/import_result_widget.dart
git commit -m "$(cat <<'EOF'
feat(transfer): the import step widgets (kit 11, K1–K4)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 4: The import screen

**Files:**
- Create: `lib/features/transfer/presentation/screens/card_import_screen.dart`
- Create: `test/features/transfer/presentation/goldens/import_source_light.png`
- Create: `test/features/transfer/presentation/goldens/import_source_dark.png`
- Create: `test/features/transfer/presentation/goldens/import_mapping_light.png`
- Create: `test/features/transfer/presentation/goldens/import_mapping_dark.png`
- Create: `test/features/transfer/presentation/goldens/import_preview_light.png`
- Create: `test/features/transfer/presentation/goldens/import_preview_dark.png`
- Create: `test/features/transfer/presentation/goldens/import_partial_light.png`
- Create: `test/features/transfer/presentation/goldens/import_partial_dark.png`
- Test (create): `test/features/transfer/presentation/card_import_screen_test.dart`
- Test (create): `test/features/transfer/presentation/card_import_golden_test.dart`
- Test (create): `test/visual_audit/screens/features/transfer/screens/card_import_screen_visual_audit_test.dart`

**Interfaces:**
- Consumes: Task 2's controller, Task 3's widgets.
- Produces: `CardImportScreen({deckId, deckContext, onClose, onViewCards})`: the deck
  context and the tracker above one `MxScreenScroll` (F11), `PopScope` Back through
  `stepBack` (IT-NAV-012 step 4–5), the result footers of F3 and F4.

- [ ] **Step 1: Write the failing tests**

`test/features/transfer/presentation/card_import_screen_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

// The import screen over the real backend and a fake picker (UC-TRANSFER-001,
// IT-NAV-012, IT-CARD-014).

final _en = lookupAppLocalizations(const Locale('en'));

ImportPickedFile _file(String text) =>
    (name: 'vocab.csv', bytes: Uint8List.fromList(utf8.encode(text)));

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

Future<int> _cards(LibraryEnv env) async =>
    (await env.db.customSelect('SELECT COUNT(*) AS n FROM card').getSingle())
        .read<int>('n');

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  String deckId, {
  ImportPickedFile? file,
  VoidCallback? onClose,
  VoidCallback? onViewCards,
}) => pumpLibraryScreen(
  tester,
  env,
  CardImportScreen(
    deckId: deckId,
    deckContext: _context,
    onClose: onClose ?? () {},
    onViewCards: onViewCards ?? () {},
  ),
  overrides: [importFilePickerProvider.overrideWithValue(() async => file)],
);

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('a file becomes cards through the four steps (IT-CARD-014)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    var viewed = 0;
    await _pump(
      tester,
      env,
      deck.id,
      file: _file('front,back,tags\nmul,water,noun\nbul,fire,\n'),
      onViewCards: () => viewed++,
    );

    expect(find.text(_en.importPickTitle), findsOneWidget);
    await _tap(tester, _en.importPickAction);
    expect(find.text('vocab.csv'), findsOneWidget);

    await _tap(tester, _en.importReadAction);
    expect(find.text(_en.importHeaderToggle), findsOneWidget);
    expect(find.text(_en.importFieldFront), findsOneWidget);

    await _tap(tester, _en.importPreviewAction);
    expect(find.text(_en.importPreviewReady(2, 2)), findsOneWidget);

    await _tap(tester, _en.importCommitAction(2));
    expect(find.text(_en.importDoneTitle), findsOneWidget);
    expect(await _cards(env), 2);

    await _tap(tester, _en.importViewCards);
    expect(viewed, 1);
  });

  libraryTest(
    'Back steps back one step; at step 1 it closes (IT-NAV-012 step 4)',
    (tester, env) async {
      final root = await env.decks.root('Korean');
      final deck = await env.decks.sub(root.id, 'Words');
      var closed = 0;
      await _pump(
        tester,
        env,
        deck.id,
        file: _file('front,back\nmul,water\n'),
        onClose: () => closed++,
      );
      await _tap(tester, _en.importPickAction);
      await _tap(tester, _en.importReadAction);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(_en.importReadAction), findsOneWidget);
      expect(closed, 0);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(closed, 1);
    },
  );

  libraryTest('an unmapped back locks Preview and says why (BR-TRANSFER-002)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(tester, env, deck.id, file: _file('term,meaning\nmul,water\n'));
    await _tap(tester, _en.importPickAction);
    await _tap(tester, _en.importReadAction);

    expect(find.text(_en.importMappingIncomplete), findsOneWidget);
    await _tap(tester, _en.importPreviewAction);
    expect(find.text(_en.importHeaderToggle), findsOneWidget);
  });

  libraryTest('a Latin-1 file is refused at step 1 with guidance (E1)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await _pump(
      tester,
      env,
      deck.id,
      file: (
        name: 'latin.csv',
        bytes: Uint8List.fromList([0x63, 0xE9, 0x2C, 0x62]),
      ),
    );
    await _tap(tester, _en.importPickAction);
    await _tap(tester, _en.importReadAction);

    expect(find.text(_en.importProblemEncodingTitle), findsOneWidget);
    expect(await _cards(env), 0);
  });

  libraryTest(
    'duplicates are skipped unless included (A4); every row a duplicate locks Import (E3)',
    (tester, env) async {
      final root = await env.decks.root('Korean');
      final deck = await env.decks.sub(root.id, 'Words');
      await insertCard(
        env.db,
        id: 'x',
        deckId: deck.id,
        front: 'mul',
        back: 'water',
      );
      await _pump(tester, env, deck.id, file: _file('front,back\nmul,water\n'));
      await _tap(tester, _en.importPickAction);
      await _tap(tester, _en.importReadAction);
      await _tap(tester, _en.importPreviewAction);

      expect(find.text(_en.importRowDuplicateInDeck), findsOneWidget);
      expect(find.text(_en.importCaptionPreview(0)), findsOneWidget);

      await _tap(tester, _en.importIncludeDuplicates);
      expect(find.text(_en.importCommitAction(1)), findsOneWidget);
    },
  );
}
```

`test/features/transfer/presentation/card_import_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

// Kit 11's states as the app draws them, light and dark: the source, the
// mapping, a mixed preview and a partial result (spec §8.2 K1–K4).

final _en = lookupAppLocalizations(const Locale('en'));

/// Romanized fronts: the golden test font has no Hangul glyphs.
const _csv =
    'front,back,tags\n'
    'mul,water,noun\n'
    'bul,,\n'
    'sarang,love,\n'
    ',,\n'
    'mul,water,\n';

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

Future<String> _seed(LibraryEnv env) async {
  final root = await env.decks.root('Korean');
  final deck = await env.decks.sub(root.id, 'Words');
  await insertCard(
    env.db,
    id: 'x',
    deckId: deck.id,
    front: 'sarang',
    back: 'love',
  );
  return deck.id;
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> pump(WidgetTester tester, LibraryEnv env, String deckId) =>
        pumpLibraryGolden(
          tester,
          env,
          CardImportScreen(
            deckId: deckId,
            deckContext: _context,
            onClose: () {},
            onViewCards: () {},
          ),
          brightness,
          overrides: [
            importFilePickerProvider.overrideWithValue(
              () async => (
                name: 'words.csv',
                bytes: Uint8List.fromList(utf8.encode(_csv)),
              ),
            ),
          ],
        );

    libraryTest('import source, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pump(tester, env, deckId);
        await expectBoundaryGolden(tester, 'goldens/import_source_$theme.png');
      });
    });

    libraryTest('import mapping, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pump(tester, env, deckId);
        await _tap(tester, _en.importPickAction);
        await _tap(tester, _en.importReadAction);
        await expectBoundaryGolden(tester, 'goldens/import_mapping_$theme.png');
      });
    });

    libraryTest('import preview, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pump(tester, env, deckId);
        await _tap(tester, _en.importPickAction);
        await _tap(tester, _en.importReadAction);
        await _tap(tester, _en.importPreviewAction);
        await expectBoundaryGolden(tester, 'goldens/import_preview_$theme.png');
      });
    });

    libraryTest('import partial result, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pump(tester, env, deckId);
        await _tap(tester, _en.importPickAction);
        await _tap(tester, _en.importReadAction);
        await _tap(tester, _en.importPreviewAction);
        await _tap(tester, _en.importCommitAction(1));
        await expectBoundaryGolden(tester, 'goldens/import_partial_$theme.png');
      });
    });
  }
}
```

`test/visual_audit/screens/features/transfer/screens/card_import_screen_visual_audit_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/transfer/presentation/providers/import_file_picker_provider.dart';
import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../../../support/deck_fixtures.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

void main() {
  libraryTest('screen 11, the source step', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    await auditProductionScreen(
      tester,
      screen: CardImportScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        CardImportScreen(
          deckId: deck.id,
          deckContext: _context,
          onClose: () {},
          onViewCards: () {},
        ),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });

  libraryTest('screen 11, the preview step', (tester, env) async {
    final root = await env.decks.root('Korean');
    final deck = await env.decks.sub(root.id, 'Words');
    final file = (
      name: 'words.csv',
      bytes: Uint8List.fromList(utf8.encode('front,back\nmul,water\nbul,\n')),
    );
    await auditProductionScreen(
      tester,
      screen: CardImportScreen,
      pump: (brightness, scale) async {
        await pumpLibraryScreen(
          tester,
          env,
          CardImportScreen(
            deckId: deck.id,
            deckContext: _context,
            onClose: () {},
            onViewCards: () {},
          ),
          brightness: brightness,
          textScale: scale,
          overrides: [
            importFilePickerProvider.overrideWithValue(() async => file),
          ],
        );
        // The scope outlives a re-pump: drive the wizard only the first time.
        if (find.text(_en.importPickAction).evaluate().isEmpty) return;
        for (final label in [
          _en.importPickAction,
          _en.importReadAction,
          _en.importPreviewAction,
        ]) {
          await tester.ensureVisible(find.text(label).last);
          await tester.tap(find.text(label).last);
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/transfer/presentation/card_import_screen_test.dart
```

Expected: FAIL to compile: `CardImportScreen` does not exist.

- [ ] **Step 3: Implement**

`lib/features/transfer/presentation/screens/card_import_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/presentation/controllers/card_import_controller.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_commit_bar_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_mapping_section_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_preview_section_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_result_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_source_section_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_step_tracker_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

/// Imports cards from a file or pasted text into [deckId] (UC-TRANSFER-001,
/// kit 11): a full-screen task above the shell (IT-NAV-012). [deckContext]
/// is the deck's path and name that `app/` passes in, as for the card
/// editor; [onClose] leaves the import, [onViewCards] leaves it for the
/// deck's cards.
class CardImportScreen extends ConsumerStatefulWidget {
  const CardImportScreen({
    super.key,
    required this.deckId,
    required this.deckContext,
    required this.onClose,
    required this.onViewCards,
  });

  final String deckId;
  final Widget Function(String deckId, String currentLabel) deckContext;
  final VoidCallback onClose;
  final VoidCallback onViewCards;

  @override
  ConsumerState<CardImportScreen> createState() => _CardImportScreenState();
}

class _CardImportScreenState extends ConsumerState<CardImportScreen> {
  CardImportController get _wizard =>
      ref.read(cardImportControllerProvider(widget.deckId).notifier);

  /// Android Back steps back one step (IT-NAV-012 step 4); at step 1 and on
  /// a result it closes; while writing it does nothing (step 5).
  void _onBack() {
    if (_wizard.stepBack()) return;
    widget.onClose();
  }

  void _close() {
    final state = ref.read(cardImportControllerProvider(widget.deckId));
    if (state case CardImportDraft(step: CardImportStep.importing)) return;
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cardImportControllerProvider(widget.deckId));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: switch (state) {
        final CardImportDraft draft => _wizardShell(context, draft),
        _ => _resultShell(context, state),
      },
    );
  }

  Widget _appBar(BuildContext context, String title) => MxAppBar(
    title: title,
    density: MxAppBarDensity.content,
    leading: MxIconButton(
      icon: AppIcons.close,
      semanticLabel: context.l10n.importClose,
      onPressed: _close,
    ),
  );

  Widget _wizardShell(BuildContext context, CardImportDraft draft) {
    final l10n = context.l10n;
    final step = draft.step;
    return MxAppShell(
      appBar: _appBar(context, l10n.importTitle),
      // The deck and the step stay above the scroll, as on the card editor.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.deckContext(widget.deckId, l10n.importBreadcrumb),
          ImportStepTrackerWidget(current: step),
          Expanded(child: _wizardScroll(draft)),
        ],
      ),
      footer: ImportCommitBarWidget(
        draft: draft,
        onCancel: _close,
        onRead: () => unawaited(_wizard.readSource()),
        onPreview: () => unawaited(_wizard.previewRows()),
        onCommit: () => unawaited(_wizard.commit()),
      ),
    );
  }

  Widget _wizardScroll(CardImportDraft draft) {
    final step = draft.step;
    return MxScreenScroll(
      children: [
        const SizedBox(height: AppSpacing.micro),
        ImportSourceSectionWidget(
          // A new source or a fresh start rebuilds the pasted text field.
          key: ValueKey(draft.sourceKind),
          draft: draft,
          onChooseKind: _wizard.chooseSourceKind,
          onChooseFile: () => unawaited(_wizard.chooseFile()),
          onPaste: _wizard.pasteText,
          onClear: _wizard.clearSource,
          onChooseSheet: (index) =>
              unawaited(_wizard.readSource(sheetIndex: index)),
        ),
        const SizedBox(height: AppSpacing.gutter),
        if (step == CardImportStep.columns)
          ImportMappingSectionWidget(
            draft: draft,
            onHeaderRow: (isOn) => _wizard.setHasHeaderRow(hasHeaderRow: isOn),
            onAssign: _wizard.assignColumn,
          ),
        if (step == CardImportStep.preview)
          ImportPreviewSectionWidget(
            draft: draft,
            onIncludeDuplicates: (isOn) =>
                _wizard.setIncludingDuplicates(isIncluding: isOn),
          ),
        if (step == CardImportStep.importing)
          _ImportingCard(count: draft.willWrite),
      ],
    );
  }

  Widget _resultShell(BuildContext context, CardImportState state) {
    final l10n = context.l10n;
    final (secondary, primary) = switch (state) {
      CardImportDone(summary: final summary) when summary.written == 0 => (
        (l10n.importAnother, _wizard.startOver),
        (l10n.importBackToDeck, widget.onClose, AppIcons.back),
      ),
      CardImportDone() => (
        (l10n.importAnother, _wizard.startOver),
        (l10n.importViewCards, widget.onViewCards, AppIcons.cardDeck),
      ),
      CardImportFailed(isTargetRejected: true) => (
        null,
        (l10n.importCloseAction, widget.onClose, AppIcons.close),
      ),
      _ => (
        (l10n.importCloseAction, widget.onClose),
        (l10n.importTryAgain, () => unawaited(_wizard.retry()), AppIcons.retry),
      ),
    };
    return MxAppShell(
      appBar: _appBar(context, l10n.importResultsTitle),
      body: MxScreenScroll(children: [ImportResultWidget(state: state)]),
      footer: MxFooterBar(
        child: Row(
          spacing: AppSpacing.control,
          children: [
            if (secondary case (final label, final onPressed))
              Expanded(
                child: MxButton(
                  label: label,
                  tone: MxButtonTone.outline,
                  isBlock: true,
                  onPressed: onPressed,
                ),
              ),
            Expanded(
              child: MxButton(
                label: primary.$1,
                icon: primary.$3,
                isBlock: true,
                onPressed: primary.$2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 4 while the commit runs (kit 11 importing): all or nothing
/// (BR-TRANSFER-004).
class _ImportingCard extends StatelessWidget {
  const _ImportingCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final title = l10n.importImportingTitle(count);
    return MxCard(
      child: Column(
        spacing: AppSpacing.grouped,
        children: [
          MxSpinner(size: MxSpinnerSize.large, semanticLabel: title),
          Text(
            title,
            textAlign: TextAlign.center,
            style: styles.emptyTitleCompact,
          ),
          Text(
            l10n.importImportingBody,
            textAlign: TextAlign.center,
            style: styles.emptyBody,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run, render the goldens and look at them**

```bash
flutter test test/features/transfer test/visual_audit/screens/features/transfer
flutter test --tags golden --update-goldens test/features/transfer/presentation/card_import_golden_test.dart
```

Expected: PASS. Eight goldens: `import_{source,mapping,preview,partial}_{light,dark}.png`.
Compare them with `docs/shared/ui/screen-handoff/img/11-card-import/` (Task 6 captures
them; the kit is the authority): the tracker sits on one row at 360 dp; the deck
context and the tracker line up with the cards (16 dp); the mapping rows end in a
field trigger; the preview shows the four badges and the row reasons.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/features/transfer/presentation/screens/card_import_screen.dart \
  test/features/transfer/presentation/card_import_screen_test.dart \
  test/features/transfer/presentation/card_import_golden_test.dart \
  test/visual_audit/screens/features/transfer/screens/card_import_screen_visual_audit_test.dart \
  test/features/transfer/presentation/goldens/import_source_light.png \
  test/features/transfer/presentation/goldens/import_source_dark.png \
  test/features/transfer/presentation/goldens/import_mapping_light.png \
  test/features/transfer/presentation/goldens/import_mapping_dark.png \
  test/features/transfer/presentation/goldens/import_preview_light.png \
  test/features/transfer/presentation/goldens/import_preview_dark.png \
  test/features/transfer/presentation/goldens/import_partial_light.png \
  test/features/transfer/presentation/goldens/import_partial_dark.png
git commit -m "$(cat <<'EOF'
feat(transfer): the import screen (kit 11, UC-TRANSFER-001, IT-NAV-012)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 5: The route and the entry points

**Files:**
- Modify: `lib/app/router/app_routes.dart`
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/features/deck/presentation/screens/deck_level_screen.dart`
- Modify: `lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart`
- Modify: `lib/features/deck/presentation/widgets/sections/deck_unset_state_widget.dart`
- Modify: `test/features/deck/presentation/goldens/library_deck_unset_light.png`
- Modify: `test/features/deck/presentation/goldens/library_deck_unset_dark.png`
- Test (modify): `test/support/library_harness.dart`
- Test (modify): `test/features/deck/presentation/deck_action_sheet_test.dart`
- Test (modify): `test/features/deck/presentation/open_deck_screen_test.dart`
- Test (modify): `test/app/library_routes_test.dart`

**Interfaces:**
- Produces: `AppRoutes.cardImportChild = 'cards/import'` and
  `AppRoutes.importCards(deckId)` → `/decks/deck/<id>/cards/import`, on the root
  navigator (F1); `DeckLevelScreen.onImportCards`; `DeckAction.importCards` and the
  sheet's `canImport`; `DeckUnsetStateWidget.onImportCards`.

- [ ] **Step 1: Write the failing tests**

`test/support/library_harness.dart` (apply this diff):

```diff
diff --git a/test/support/library_harness.dart b/test/support/library_harness.dart
--- a/test/support/library_harness.dart
+++ b/test/support/library_harness.dart
@@ -181,6 +181,7 @@ DeckLevelScreen deckScreen({
   Widget Function(String deckId)? cardFab,
   VoidCallback? onSearch,
   ValueChanged<String>? onOpenAlgorithm,
+  ValueChanged<String>? onImportCards,
 }) => DeckLevelScreen(
   deckId: deckId,
   onOpenDeck: onOpenDeck ?? (_) {},
@@ -188,6 +189,7 @@ DeckLevelScreen deckScreen({
   onSearch: onSearch ?? () {},
   onOpenAlgorithm: onOpenAlgorithm ?? (_) {},
   onAddCard: onAddCard ?? (_) {},
+  onImportCards: onImportCards ?? (_) {},
   cardContent: cardContent ?? (_) => const SizedBox.shrink(),
   cardAppBar:
       cardAppBar ??
```

`test/features/deck/presentation/deck_action_sheet_test.dart` (apply this diff):

```diff
diff --git a/test/features/deck/presentation/deck_action_sheet_test.dart b/test/features/deck/presentation/deck_action_sheet_test.dart
index 8288129..010487f 100644
--- a/test/features/deck/presentation/deck_action_sheet_test.dart
+++ b/test/features/deck/presentation/deck_action_sheet_test.dart
@@ -71,6 +71,40 @@ void main() {
     expect(find.text(_en.deckReviewAlgorithm), findsNothing);
   });
 
+  libraryTest(
+    'a deck that takes cards offers Import; a root and a deck of decks do not (BR-TRANSFER-008)',
+    (tester, env) async {
+      final korean = await env.decks.root('Korean');
+      final words = await env.decks.sub(korean.id, 'Words');
+      final grammar = await env.decks.sub(korean.id, 'Grammar');
+      await env.decks.sub(grammar.id, 'Particles');
+      await insertCard(env.db, id: 'c1', deckId: words.id, front: 'mul');
+      final imported = <String>[];
+
+      for (final (deckId, isOffered) in [
+        (korean.id, false),
+        (grammar.id, false),
+        (words.id, true),
+      ]) {
+        await pumpLibraryScreen(
+          tester,
+          env,
+          deckScreen(deckId: deckId, onImportCards: imported.add),
+        );
+        await _openSheet(tester);
+        expect(
+          find.text(_en.deckActionImport),
+          isOffered ? findsOneWidget : findsNothing,
+        );
+        await tester.tapAt(Offset.zero);
+        await tester.pumpAndSettle();
+      }
+
+      await _choose(tester, _en.deckActionImport);
+      expect(imported, [words.id]);
+    },
+  );
+
   libraryTest('Rename renames the open deck', (tester, env) async {
     final korean = await env.decks.root('Korean');
     await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
```

`test/features/deck/presentation/open_deck_screen_test.dart` (apply this diff):

```diff
diff --git a/test/features/deck/presentation/open_deck_screen_test.dart b/test/features/deck/presentation/open_deck_screen_test.dart
index 2e72710..8869264 100644
--- a/test/features/deck/presentation/open_deck_screen_test.dart
+++ b/test/features/deck/presentation/open_deck_screen_test.dart
@@ -123,6 +123,24 @@ void main() {
     expect(find.text('Verbs'), findsOneWidget);
   });
 
+  libraryTest('an empty sub-deck imports cards from a file (UC-TRANSFER-001)', (
+    tester,
+    env,
+  ) async {
+    final korean = await env.decks.root('Korean');
+    final words = await env.decks.sub(korean.id, 'Words');
+    final imported = <String>[];
+    await pumpLibraryScreen(
+      tester,
+      env,
+      deckScreen(deckId: words.id, onImportCards: imported.add),
+    );
+
+    await tester.ensureVisible(_unsetButton(_en.deckUnsetImport));
+    await tester.tap(_unsetButton(_en.deckUnsetImport));
+    expect(imported, [words.id]);
+  });
+
   libraryTest('a top-level deck offers sub-decks only (BR-DECK-005)', (
     tester,
     env,
```

`test/app/library_routes_test.dart` (apply this diff):

```diff
diff --git a/test/app/library_routes_test.dart b/test/app/library_routes_test.dart
index 56a5f66..1387cc0 100644
--- a/test/app/library_routes_test.dart
+++ b/test/app/library_routes_test.dart
@@ -224,6 +224,27 @@ void main() {
     expect(find.text('mul'), findsOneWidget);
   });
 
+  libraryTest(
+    'Import covers the shell; Close returns to the deck (IT-NAV-012)',
+    (tester, env) async {
+      await env.decks.sub((await env.decks.root('Korean')).id, 'Words');
+      await pumpMemoxApp(tester, env);
+      await _tap(tester, find.text('Korean'));
+      await _tap(tester, find.text('Words'));
+      await tester.ensureVisible(
+        find.widgetWithText(MxButton, _en.deckUnsetImport),
+      );
+      await _tap(tester, find.widgetWithText(MxButton, _en.deckUnsetImport));
+
+      expect(_barTitle(_en.importTitle), findsOneWidget);
+      expect(find.byType(MxBottomNav), findsNothing);
+
+      await _tap(tester, find.byTooltip(_en.importClose));
+      expect(_barTitle('Words'), findsOneWidget);
+      expect(find.byType(MxBottomNav), findsOneWidget);
+    },
+  );
+
   libraryTest('Close on a typed card asks; Discard leaves (RF2)', (
     tester,
     env,
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/deck/presentation/deck_action_sheet_test.dart test/features/deck/presentation/open_deck_screen_test.dart test/app/library_routes_test.dart
```

Expected: FAIL to compile: `DeckLevelScreen` has no `onImportCards`.

- [ ] **Step 3: Implement**

`lib/app/router/app_routes.dart` (apply this diff):

```diff
diff --git a/lib/app/router/app_routes.dart b/lib/app/router/app_routes.dart
index 3d8963f..f6b5aef 100644
--- a/lib/app/router/app_routes.dart
+++ b/lib/app/router/app_routes.dart
@@ -24,6 +24,9 @@ abstract final class AppRoutes {
   /// A deck's card editor in create mode, relative to [deckChild].
   static const String cardNewChild = 'cards/new';
 
+  /// A deck's card import (kit 11, IT-NAV-012), relative to [deckChild].
+  static const String cardImportChild = 'cards/import';
+
   /// The path parameter that names a card.
   static const String cardIdParam = 'cardId';
 
@@ -41,6 +44,10 @@ abstract final class AppRoutes {
   /// The card editor adding cards to [deckId].
   static String newCard(String deckId) => '${deck(deckId)}/$cardNewChild';
 
+  /// The card import into [deckId].
+  static String importCards(String deckId) =>
+      '${deck(deckId)}/$cardImportChild';
+
   /// A card's detail.
   static String card(String cardId) => '$decks/card/$cardId';
 
```

`lib/app/router/app_router.dart` (apply this diff):

```diff
diff --git a/lib/app/router/app_router.dart b/lib/app/router/app_router.dart
index 6490214..aaad1b4 100644
--- a/lib/app/router/app_router.dart
+++ b/lib/app/router/app_router.dart
@@ -18,6 +18,7 @@ import 'package:memox/features/deck/presentation/screens/deck_algorithm_screen.d
 import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';
 import 'package:memox/features/deck/presentation/screens/deck_search_screen.dart';
 import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
+import 'package:memox/features/transfer/presentation/screens/card_import_screen.dart';
 import 'package:memox/l10n/l10n_context.dart';
 import 'package:memox/shared/widgets/mx_app_shell.dart';
 import 'package:memox/shared/widgets/mx_bottom_nav.dart';
@@ -25,95 +26,112 @@ import 'package:memox/shared/widgets/mx_bottom_nav.dart';
 /// The app's routes: four top-level branches in a stateful shell, each
 /// keeping its own stack, plus the component gallery when [hasGallery]
 /// (debug builds by default, so release builds never register it).
-GoRouter buildAppRouter({bool hasGallery = kDebugMode}) => GoRouter(
-  initialLocation: AppRoutes.decks,
-  routes: [
-    StatefulShellRoute.indexedStack(
-      builder: (context, state, navigationShell) =>
-          _TabShell(navigationShell: navigationShell),
-      branches: [
-        // The Library (library spec §4): one page per deck level.
-        StatefulShellBranch(
-          routes: [
-            GoRoute(
-              path: AppRoutes.decks,
-              builder: (context, state) => _deckLevel(context),
-              routes: [
-                GoRoute(
-                  path: AppRoutes.deckChild,
-                  builder: (context, state) => _deckLevel(
-                    context,
-                    deckId: state.pathParameters[AppRoutes.deckIdParam],
-                  ),
-                  routes: [
-                    GoRoute(
-                      path: AppRoutes.cardNewChild,
-                      builder: (context, state) => CardEditorScreen.create(
-                        deckId: state.pathParameters[AppRoutes.deckIdParam]!,
-                        deckContext: _deckContext,
-                      ),
+GoRouter buildAppRouter({bool hasGallery = kDebugMode}) {
+  // The root navigator: a route on it covers the shell and its bottom bar.
+  final rootNavigator = GlobalKey<NavigatorState>();
+  return GoRouter(
+    navigatorKey: rootNavigator,
+    initialLocation: AppRoutes.decks,
+    routes: [
+      StatefulShellRoute.indexedStack(
+        builder: (context, state, navigationShell) =>
+            _TabShell(navigationShell: navigationShell),
+        branches: [
+          // The Library (library spec §4): one page per deck level.
+          StatefulShellBranch(
+            routes: [
+              GoRoute(
+                path: AppRoutes.decks,
+                builder: (context, state) => _deckLevel(context),
+                routes: [
+                  GoRoute(
+                    path: AppRoutes.deckChild,
+                    builder: (context, state) => _deckLevel(
+                      context,
+                      deckId: state.pathParameters[AppRoutes.deckIdParam],
                     ),
-                    GoRoute(
-                      path: AppRoutes.algorithmChild,
-                      builder: (context, state) => DeckAlgorithmScreen(
-                        deckId: state.pathParameters[AppRoutes.deckIdParam]!,
-                        onOpenAncestor: (id) => _openAncestor(context, id),
+                    routes: [
+                      GoRoute(
+                        path: AppRoutes.cardNewChild,
+                        builder: (context, state) => CardEditorScreen.create(
+                          deckId: state.pathParameters[AppRoutes.deckIdParam]!,
+                          deckContext: _deckContext,
+                        ),
                       ),
-                    ),
-                  ],
-                ),
-                GoRoute(
-                  path: AppRoutes.searchChild,
-                  builder: (context, state) => DeckSearchScreen(
-                    onOpenDeck: (id) => context.push(AppRoutes.deck(id)),
+                      // A full-screen task above the shell: no bottom bar
+                      // (IT-NAV-012 step 1).
+                      GoRoute(
+                        path: AppRoutes.cardImportChild,
+                        parentNavigatorKey: rootNavigator,
+                        builder: (context, state) => CardImportScreen(
+                          deckId: state.pathParameters[AppRoutes.deckIdParam]!,
+                          deckContext: _deckContext,
+                          onClose: () => context.pop(),
+                          onViewCards: () => context.pop(),
+                        ),
+                      ),
+                      GoRoute(
+                        path: AppRoutes.algorithmChild,
+                        builder: (context, state) => DeckAlgorithmScreen(
+                          deckId: state.pathParameters[AppRoutes.deckIdParam]!,
+                          onOpenAncestor: (id) => _openAncestor(context, id),
+                        ),
+                      ),
+                    ],
                   ),
-                ),
-                GoRoute(
-                  path: AppRoutes.cardChild,
-                  builder: (context, state) => CardDetailScreen(
-                    cardId: state.pathParameters[AppRoutes.cardIdParam]!,
-                    deckContext: _deckContext,
-                    onEdit: (id) =>
-                        unawaited(context.push(AppRoutes.editCard(id))),
+                  GoRoute(
+                    path: AppRoutes.searchChild,
+                    builder: (context, state) => DeckSearchScreen(
+                      onOpenDeck: (id) => context.push(AppRoutes.deck(id)),
+                    ),
                   ),
-                  routes: [
-                    GoRoute(
-                      path: AppRoutes.cardEditChild,
-                      builder: (context, state) => CardEditorScreen.edit(
-                        cardId: state.pathParameters[AppRoutes.cardIdParam]!,
-                        deckContext: _deckContext,
-                      ),
+                  GoRoute(
+                    path: AppRoutes.cardChild,
+                    builder: (context, state) => CardDetailScreen(
+                      cardId: state.pathParameters[AppRoutes.cardIdParam]!,
+                      deckContext: _deckContext,
+                      onEdit: (id) =>
+                          unawaited(context.push(AppRoutes.editCard(id))),
                     ),
-                  ],
+                    routes: [
+                      GoRoute(
+                        path: AppRoutes.cardEditChild,
+                        builder: (context, state) => CardEditorScreen.edit(
+                          cardId: state.pathParameters[AppRoutes.cardIdParam]!,
+                          deckContext: _deckContext,
+                        ),
+                      ),
+                    ],
+                  ),
+                ],
+              ),
+            ],
+          ),
+          _branch(AppRoutes.study, (context) => context.l10n.navStudy),
+          _branch(AppRoutes.progress, (context) => context.l10n.navProgress),
+          StatefulShellBranch(
+            routes: [
+              GoRoute(
+                path: AppRoutes.settings,
+                builder: (context, state) => PlaceholderScreen(
+                  title: context.l10n.navSettings,
+                  onOpenGallery: hasGallery
+                      ? () => context.push(AppRoutes.gallery)
+                      : null,
                 ),
-              ],
-            ),
-          ],
-        ),
-        _branch(AppRoutes.study, (context) => context.l10n.navStudy),
-        _branch(AppRoutes.progress, (context) => context.l10n.navProgress),
-        StatefulShellBranch(
-          routes: [
-            GoRoute(
-              path: AppRoutes.settings,
-              builder: (context, state) => PlaceholderScreen(
-                title: context.l10n.navSettings,
-                onOpenGallery: hasGallery
-                    ? () => context.push(AppRoutes.gallery)
-                    : null,
               ),
-            ),
-          ],
-        ),
-      ],
-    ),
-    if (hasGallery)
-      GoRoute(
-        path: AppRoutes.gallery,
-        builder: (context, state) => const GalleryScreen(),
+            ],
+          ),
+        ],
       ),
-  ],
-);
+      if (hasGallery)
+        GoRoute(
+          path: AppRoutes.gallery,
+          builder: (context, state) => const GalleryScreen(),
+        ),
+    ],
+  );
+}
 
 /// A Library level wired to the router: each deck opened is one more page,
 /// so Back climbs one level (library spec §4).
@@ -127,6 +145,7 @@ DeckLevelScreen _deckLevel(BuildContext context, {String? deckId}) {
     onOpenAlgorithm: (id) =>
         unawaited(context.push(AppRoutes.deckAlgorithm(id))),
     onAddCard: addCard,
+    onImportCards: (id) => unawaited(context.push(AppRoutes.importCards(id))),
     cardAppBar: (view, back, actions) =>
         CardDeckAppBarWidget(view: view, back: back, deckActions: actions),
     cardBreadcrumb: (id, child) =>
```

`lib/features/deck/presentation/screens/deck_level_screen.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/screens/deck_level_screen.dart b/lib/features/deck/presentation/screens/deck_level_screen.dart
index 6c05599..5160743 100644
--- a/lib/features/deck/presentation/screens/deck_level_screen.dart
+++ b/lib/features/deck/presentation/screens/deck_level_screen.dart
@@ -42,6 +42,7 @@ class DeckLevelScreen extends StatelessWidget {
     required this.cardAppBar,
     required this.cardBreadcrumb,
     required this.onAddCard,
+    required this.onImportCards,
     required this.cardFab,
   });
 
@@ -72,6 +73,10 @@ class DeckLevelScreen extends StatelessWidget {
   /// New card for [deckId]: the router opens the card editor.
   final ValueChanged<String> onAddCard;
 
+  /// Import cards into [deckId] (UC-TRANSFER-001): the router opens the
+  /// import screen.
+  final ValueChanged<String> onImportCards;
+
   /// A deck of cards' FAB, from the card feature like [cardContent] (spec
   /// D8). It hides itself while cards are selected.
   final Widget Function(String deckId) cardFab;
@@ -92,6 +97,7 @@ class DeckLevelScreen extends StatelessWidget {
       cardAppBar: cardAppBar,
       cardBreadcrumb: cardBreadcrumb,
       onAddCard: onAddCard,
+      onImportCards: onImportCards,
       cardFab: cardFab,
     ),
   };
@@ -108,6 +114,7 @@ class _OpenDeck extends ConsumerWidget {
     required this.cardAppBar,
     required this.cardBreadcrumb,
     required this.onAddCard,
+    required this.onImportCards,
     required this.cardFab,
   });
 
@@ -120,6 +127,7 @@ class _OpenDeck extends ConsumerWidget {
   cardAppBar;
   final Widget Function(String deckId, Widget breadcrumb) cardBreadcrumb;
   final ValueChanged<String> onAddCard;
+  final ValueChanged<String> onImportCards;
   final Widget Function(String deckId) cardFab;
 
   static const int _skeletonRows = 4;
@@ -143,6 +151,7 @@ class _OpenDeck extends ConsumerWidget {
         cardAppBar: cardAppBar,
         cardBreadcrumb: cardBreadcrumb,
         onAddCard: onAddCard,
+        onImportCards: onImportCards,
         cardFab: cardFab,
       ),
       AsyncError() => MxAppShell(
@@ -189,6 +198,7 @@ class _OpenDeckContent extends ConsumerWidget {
     required this.cardAppBar,
     required this.cardBreadcrumb,
     required this.onAddCard,
+    required this.onImportCards,
     required this.cardFab,
   });
 
@@ -201,6 +211,7 @@ class _OpenDeckContent extends ConsumerWidget {
   cardAppBar;
   final Widget Function(String deckId, Widget breadcrumb) cardBreadcrumb;
   final ValueChanged<String> onAddCard;
+  final ValueChanged<String> onImportCards;
   final Widget Function(String deckId) cardFab;
 
   @override
@@ -223,6 +234,7 @@ class _OpenDeckContent extends ConsumerWidget {
           parentId: deck.parentId,
           onOpenDeck: onOpenDeck,
           onOpenAlgorithm: onOpenAlgorithm,
+          onImportCards: canCreateCard ? () => onImportCards(deck.id) : null,
           isOpenDeck: true,
         ),
       ),
@@ -281,6 +293,9 @@ class _OpenDeckContent extends ConsumerWidget {
                 hasDeepestSubDecks: deck.depth == DeckEntity.maxDepth - 1,
                 emptyState: DeckUnsetStateWidget(
                   onAddCard: canCreateCard ? () => onAddCard(deck.id) : null,
+                  onImportCards: canCreateCard
+                      ? () => onImportCards(deck.id)
+                      : null,
                   onCreateSubDeck: canCreateDeck ? createSubDeck : null,
                 ),
               ),
```

`lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart b/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart
index 2795aa7..eda7090 100644
--- a/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart
+++ b/lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart
@@ -13,7 +13,8 @@ import 'package:memox/l10n/l10n_context.dart';
 import 'package:memox/shared/widgets/mx_snackbar.dart';
 
 /// Opens a deck's action sheet and then the chosen command's own dialog or
-/// sheet (spec §6.2): from a row's ⋮, or from the open deck's ⋮. It reads
+/// sheet (spec §6.2): from a row's ⋮, or from the open deck's ⋮.
+/// [onImportCards] offers Import on a deck that takes cards (UC-TRANSFER-001). It reads
 /// the deck's view once first, so a deck gone meanwhile says so instead
 /// (ruling C-L6).
 Future<void> openDeckActions(
@@ -24,6 +25,7 @@ Future<void> openDeckActions(
   required ValueChanged<String> onOpenDeck,
   required ValueChanged<String> onOpenAlgorithm,
   required bool isOpenDeck,
+  VoidCallback? onImportCards,
 }) async {
   // A row's deck has no listener yet: keep its view alive until it emits,
   // or the auto-disposed provider would never complete the read.
@@ -52,6 +54,7 @@ Future<void> openDeckActions(
     view: view,
     canReorder: canReorder,
     hasOpen: !isOpenDeck,
+    canImport: onImportCards != null,
   );
   if (action == null || !context.mounted) return;
   switch (action) {
@@ -63,6 +66,8 @@ Future<void> openDeckActions(
       await showMoveDeckSheet(context, deck: view.deck);
     case DeckAction.reviewAlgorithm:
       onOpenAlgorithm(deckId);
+    case DeckAction.importCards:
+      onImportCards?.call();
     case DeckAction.reorder:
       ref.read(deckReorderModeProvider(reorderLevel).notifier).start();
     case DeckAction.delete:
```

`lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart b/lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart
index bfaeffa..3e1e1be 100644
--- a/lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart
+++ b/lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart
@@ -9,7 +9,15 @@ import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
 import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
 
 /// What the deck action sheet can start (spec §6.2).
-enum DeckAction { open, rename, move, reviewAlgorithm, reorder, delete }
+enum DeckAction {
+  open,
+  rename,
+  move,
+  reviewAlgorithm,
+  importCards,
+  reorder,
+  delete,
+}
 
 /// A deck's commands (screen 01), from its row's ⋮ or the open deck's ⋮. It
 /// completes with the chosen one, which the caller then opens, or with null
@@ -19,12 +27,14 @@ Future<DeckAction?> showDeckActionSheet(
   required DeckView view,
   required bool canReorder,
   required bool hasOpen,
+  bool canImport = false,
 }) => showMxBottomSheet<DeckAction>(
   context,
   builder: (_) => DeckActionSheetWidget(
     view: view,
     canReorder: canReorder,
     hasOpen: hasOpen,
+    canImport: canImport,
   ),
 );
 
@@ -34,11 +44,16 @@ class DeckActionSheetWidget extends StatelessWidget {
     required this.view,
     required this.canReorder,
     required this.hasOpen,
+    this.canImport = false,
   });
 
   final DeckView view;
   final bool canReorder;
 
+  /// The deck takes cards: Import leads to the import screen (kit 07
+  /// deckActions, UC-TRANSFER-001).
+  final bool canImport;
+
   /// From a row, the deck is not open yet; Open leads.
   final bool hasOpen;
 
@@ -104,6 +119,13 @@ class DeckActionSheetWidget extends StatelessWidget {
           hasChevron: true,
           onTap: () => choose(DeckAction.move),
         ),
+      if (canImport)
+        MxActionSheetCommandRow(
+          icon: AppIcons.fileUp,
+          label: l10n.deckActionImport,
+          hasChevron: true,
+          onTap: () => choose(DeckAction.importCards),
+        ),
       if (canReorder)
         MxActionSheetCommandRow(
           icon: AppIcons.reorder,
```

`lib/features/deck/presentation/widgets/sections/deck_unset_state_widget.dart` (apply this diff):

```diff
diff --git a/lib/features/deck/presentation/widgets/sections/deck_unset_state_widget.dart b/lib/features/deck/presentation/widgets/sections/deck_unset_state_widget.dart
index b6af279..9990bc3 100644
--- a/lib/features/deck/presentation/widgets/sections/deck_unset_state_widget.dart
+++ b/lib/features/deck/presentation/widgets/sections/deck_unset_state_widget.dart
@@ -14,6 +14,7 @@ class DeckUnsetStateWidget extends StatelessWidget {
     super.key,
     required this.onAddCard,
     required this.onCreateSubDeck,
+    this.onImportCards,
   });
 
   /// Null for a top-level deck, which holds sub-decks only (BR-DECK-005).
@@ -22,11 +23,16 @@ class DeckUnsetStateWidget extends StatelessWidget {
   /// Null at the deepest level, where no sub-deck fits (BR-DECK-001).
   final VoidCallback? onCreateSubDeck;
 
+  /// The third way to fill the deck: cards from a file (UC-TRANSFER-001).
+  /// Null where no card fits.
+  final VoidCallback? onImportCards;
+
   @override
   Widget build(BuildContext context) {
     final l10n = context.l10n;
     final onAddCard = this.onAddCard;
     final onCreateSubDeck = this.onCreateSubDeck;
+    final onImportCards = this.onImportCards;
     final isOpen = onAddCard != null && onCreateSubDeck != null;
     return Column(
       crossAxisAlignment: CrossAxisAlignment.stretch,
@@ -62,6 +68,13 @@ class DeckUnsetStateWidget extends StatelessWidget {
                 tone: isOpen ? MxButtonTone.secondary : MxButtonTone.primary,
                 onPressed: onCreateSubDeck,
               ),
+            if (onImportCards != null)
+              MxButton(
+                label: l10n.deckUnsetImport,
+                icon: AppIcons.fileUp,
+                tone: MxButtonTone.outline,
+                onPressed: onImportCards,
+              ),
           ],
         ),
         if (isOpen) MxNote(text: l10n.deckUnsetNote),
```

- [ ] **Step 4: Run and re-render the unset golden**

```bash
flutter test test/features/deck test/app
flutter test --tags golden --update-goldens test/features/deck/presentation/deck_screens_golden_test.dart
flutter test --tags golden test/features/deck test/app
```

Expected: PASS. Only `library_deck_unset_{light,dark}.png` change: the unset deck gains
"Import cards from a file" under its two create choices.

- [ ] **Step 5: Commit**

```bash
git add \
  lib/app/router/app_routes.dart \
  lib/app/router/app_router.dart \
  lib/features/deck/presentation/screens/deck_level_screen.dart \
  lib/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart \
  lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart \
  lib/features/deck/presentation/widgets/sections/deck_unset_state_widget.dart \
  test/support/library_harness.dart \
  test/features/deck/presentation/deck_action_sheet_test.dart \
  test/features/deck/presentation/open_deck_screen_test.dart \
  test/app/library_routes_test.dart \
  test/features/deck/presentation/goldens/library_deck_unset_light.png \
  test/features/deck/presentation/goldens/library_deck_unset_dark.png
git commit -m "$(cat <<'EOF'
feat(transfer): open the import from the deck sheet and the unset deck (IT-NAV-012)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```


### Task 6: The screen's handoff, the documents and the gate

**Files:**
- Modify: `tools/design/screen_states.json`
- Create: `docs/shared/ui/screen-handoff/11-card-import.md`
- Modify: `docs/shared/ui/screen-handoff/00-index.md`
- Modify: `docs/shared/ui/screen-handoff/01-deck-list.md`
- Modify: `docs/shared/ui/screen-handoff/07-card-list.md`
- Modify: `docs/features/transfer/it-scenarios.md`
- Modify: `docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md`
- Modify: `docs/superpowers/specs/2026-09-26-card-transfer-design.md`
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`
- Modify: `docs/README.md`
- Modify: `docs/wbs_FE.md`
- Modify: `docs/shared/ui/screen-handoff/img/11-card-import/*.png (32 files)`
- Modify: `docs/_generated/traceability.md (generated)`

**Interfaces:** none (documents).

- [ ] **Step 1: Capture the kit's screen 11**

Add screen 11 to the capture manifest, then capture it from the kit (the artifact's
HTML, read with the Artifact tool's `read` action and saved locally):

`tools/design/screen_states.json` (apply this diff):

```diff
diff --git a/tools/design/screen_states.json b/tools/design/screen_states.json
index f603bcb..c259f11 100644
--- a/tools/design/screen_states.json
+++ b/tools/design/screen_states.json
@@ -77,6 +77,29 @@
         { "id": "delDeck", "label": "Deck → Trash" }
       ]
     },
+    {
+      "num": "11",
+      "dir": "11-card-import",
+      "title": "Card import",
+      "states": [
+        { "id": "empty", "label": "Source" },
+        { "id": "pasted", "label": "Pasted text" },
+        { "id": "fileSelected", "label": "File chosen" },
+        { "id": "badEncoding", "label": "Not UTF-8" },
+        { "id": "emptySheet", "label": "Empty sheet" },
+        { "id": "parsing", "label": "Reading" },
+        { "id": "mapping", "label": "Map columns" },
+        { "id": "mappingIncomplete", "label": "Back not mapped" },
+        { "id": "previewAll", "label": "Preview · all ready" },
+        { "id": "previewMix", "label": "Preview · mixed" },
+        { "id": "importing", "label": "Importing" },
+        { "id": "success", "label": "Imported" },
+        { "id": "partial", "label": "With skips" },
+        { "id": "none", "label": "Nothing added" },
+        { "id": "failed", "label": "Failed" },
+        { "id": "rejects", "label": "Deck rejects" }
+      ]
+    },
     {
       "num": "13",
       "dir": "13-study-home",
```

```bash
node tools/design/capture_screens.mjs --html <artifact.html> --only 11
```

Expected: 32 images in `docs/shared/ui/screen-handoff/img/11-card-import/`, one light and
one dark per state.

- [ ] **Step 2: Write the detail file and update the documents**

`docs/shared/ui/screen-handoff/11-card-import.md`:

```markdown
<!-- Hand-written screen handoff. Not generated by tools/docs/split_handoff.py. -->

# 11 · Card import

A full-screen task above the shell that adds many cards to one deck from a CSV, TSV or
XLSX file or from pasted text (IT-NAV-012). UC-TRANSFER-001; spec
[2026-09-26-card-transfer-design.md](../../../superpowers/specs/2026-09-26-card-transfer-design.md)
§8.

## Entry points

- The open deck's `⋮` sheet, "Import cards": a deck that holds cards or is unset. A root
  deck and a deck that holds sub-decks do not offer it (BR-TRANSFER-008).
- The unset deck's third action, "Import cards from a file".

Route: `/decks/deck/<id>/cards/import`, on the root navigator, so the bottom navigation
bar is gone while it is open.

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content) | Close; "Import cards", then "Import results" on the result. |
| Deck context | `DeckContextHeaderWidget`, injected by `app/` | Library › ancestors › deck › "Import", and the deck's name. It stays above the scroll with the tracker, as on the card editor. |
| Step tracker | `ImportStepTrackerWidget` | Source · Columns · Preview · Import (spec §8.1 ruling 4). Done steps check in the mastery colour, the current one is primary, later ones are muted. It stays on one row with stretching connectors and wraps at a large text scale. One semantic label: "Step {n} of 4: {name}". |
| 1 · Choose a source | `MxCard` options (`isSelected`) | Choose a file · Paste text, shown only before a source is read (K1). The file option picks through `file_picker`; the paste option opens an `MxTextField`. |
| Source chip | `MxCard` + `MxIconTile` | File name, then "{format} · UTF-8 · ready to read" or "{format} · {rows} · {columns}" once read; remove action. A workbook with several sheets adds a "Sheet: {name} ({i} of {n})" `MxChipTrigger` (ruling 2). |
| 2 · Map columns | `MxSection` of `ImportMappingRowWidget` | "First row is a header" `MxSettingsRow` with an `MxToggle` and the header sample; one row per column: "Column {A}", its header cell, an arrow, and an `MxChipTrigger` for the field (six fields or "Not imported") in a bottom sheet. |
| Mapping error | `MxInlineBanner` (warning) | Its own row when Term or Meaning is unmapped (K3). Preview is locked. |
| 3 · Preview | `MxListSectionHeader` + `MxBadge` + `MxSection` | "{ready} of {total} rows ready"; Ready, Invalid, Duplicate and Blank badges, only for counts above 0; one row per source row with its number, front and back (two lines each), its reason, and a status icon with a semantic label (K3); the first 50 rows and "Showing the first {n} of {m} rows" (K2); "Include duplicates" toggle when there is one. |
| Importing | `MxCard` + `MxSpinner` | "Adding {n} cards…". Close and Back do nothing until the write ends. |
| Footer | `MxFooterBar` | Cancel + the step action (Read and map columns · Preview rows · Import {n} cards) and a caption. |
| Result | `MxEmptyState` in the outcome's tone + `MxSection` counts + `MxNote` | By outcome (K4); see States. |

## States

| State | Light | Dark | V8 |
|---|---|---|---|
| empty (Source) | ![](img/11-card-import/empty-light.png) | ![](img/11-card-import/empty-dark.png) | Deck chip replaced by the deck context header. |
| pasted | ![](img/11-card-import/pasted-light.png) | ![](img/11-card-import/pasted-dark.png) | The paste field uses the body font, not monospace. |
| fileSelected | ![](img/11-card-import/fileSelected-light.png) | ![](img/11-card-import/fileSelected-dark.png) | The source options give way to the chip (K1). |
| badEncoding | ![](img/11-card-import/badEncoding-light.png) | ![](img/11-card-import/badEncoding-dark.png) | As drawn (E1). |
| emptySheet | ![](img/11-card-import/emptySheet-light.png) | ![](img/11-card-import/emptySheet-dark.png) | One copy for a file, a sheet or text with no row (E2); another sheet can still be chosen (A2). |
| parsing | ![](img/11-card-import/parsing-light.png) | ![](img/11-card-import/parsing-dark.png) | "Reading your file…" in the source area. |
| mapping | ![](img/11-card-import/mapping-light.png) | ![](img/11-card-import/mapping-dark.png) | Only canonical header names map by themselves (D2); the kit's `term`/`meaning` sample would stay unmapped. |
| mappingIncomplete | ![](img/11-card-import/mappingIncomplete-light.png) | ![](img/11-card-import/mappingIncomplete-dark.png) | The error is a banner of its own, not a red border (K3). |
| previewAll | ![](img/11-card-import/previewAll-light.png) | ![](img/11-card-import/previewAll-dark.png) | Rows stack front over back instead of three columns. |
| previewMix | ![](img/11-card-import/previewMix-light.png) | ![](img/11-card-import/previewMix-dark.png) | As previewAll; the invalid row is not tinted, its reason and icon say it. |
| importing | ![](img/11-card-import/importing-light.png) | ![](img/11-card-import/importing-dark.png) | As drawn; navigation is inert (IT-NAV-012 step 5). |
| success | ![](img/11-card-import/success-light.png) | ![](img/11-card-import/success-dark.png) | `MxEmptyState`, success tone; no deck name in the body. Import another file · View the cards (UC step 8). |
| partial | ![](img/11-card-import/partial-light.png) | ![](img/11-card-import/partial-dark.png) | As success, with the skipped counts and the skip note. |
| none | ![](img/11-card-import/none-light.png) | ![](img/11-card-import/none-dark.png) | Neutral tone; Import another file · Back to deck (ruling 1). |
| failed | ![](img/11-card-import/failed-light.png) | ![](img/11-card-import/failed-dark.png) | `MxEmptyState`, danger tone; Close · Try again, which returns to the preview. |
| rejects | ![](img/11-card-import/rejects-light.png) | ![](img/11-card-import/rejects-dark.png) | `MxEmptyState`, warning tone; Close only. |

Goldens: `test/features/transfer/presentation/goldens/import_{source,mapping,preview,partial}_{light,dark}.png`.

## Back

Android Back steps back one step and keeps the draft: Preview → Columns → Source. At
Source it closes; while importing it does nothing (IT-NAV-012 step 4–5).

## Deviations

| Artifact | V8 | Wins |
|---|---|---|
| "1 · Choose a source" stays above every later step | Collapses to the source chip once read | Spec §8.2 K1 |
| The preview renders every row | The first 50 rows and "Showing the first {n} of {m} rows" | Spec §8.2 K2, UC-TRANSFER-001 step 5 |
| Status by icon colour, an unmapped column by a red border, cells ellipsized | A semantic label per icon, the mapping error on its own row, cells wrap to two lines | Spec §8.2 K3 |
| A hand-built tinted hero per result | `MxEmptyState` in its success, neutral, warning and danger tones | Spec §8.2 K4 |
| Preview as a three-column table | Front over back in one column | K3: two-line cells do not fit three columns at 360 dp |
| Deck chip "{deck} · {n} cards" | The deck context header, no card count | The shared deck context of the card editor and detail |
| Success footer "Done" | Import another file · View the cards; `none`: Import another file · Back to deck | UC-TRANSFER-001 step 8, ruling 1 |
| Rejects footer "Choose another deck" | Close only | UC-TRANSFER-001 has no deck picker |
| `term`/`meaning` headers auto-mapped | Only the six canonical names map by themselves | Spec D2 |
| Monospace paste field and header cells | The body font | The theme has no monospace role |
| The file name is never kept | Shown in the chip while the wizard is open; never logged or stored | Amends spec §5.1: the name is needed on screen |
| Import under Coming soon | Import is live; Coming soon lists Export only until plan 2 of FE-B3 | FE-B3 plan 1 |

## Copy

- Steps: "Source" · "Columns" · "Preview" · "Import" · "Step {n} of 4: {name}".
- Source: "1 · Choose a source" · "Choose a file" · "CSV, TSV or XLSX · UTF-8" · "Paste text" · "Tab- or comma-separated rows" · "Pick a spreadsheet or text file" · ".csv, .tsv or .xlsx · UTF-8 · nothing is added until you confirm" · "Choose file" · "Each row makes one card".
- Problems: "This file is not UTF-8" · "This file can’t be read" · "There are no rows to import".
- Mapping: "2 · Map columns" · "First row is a header" · "Column {letter}" · "Term (front)" · "Meaning (back)" · "Example" · "Hint" · "Pronunciation" · "Tags" · "Not imported" · "Map one column to Term and one to Meaning. Both are required."
- Preview: "3 · Preview" · "{ready} of {total} rows ready" · "Ready · {n}" · "Invalid · {n}" · "Duplicate · {n}" · "Blank · {n}" · "Already in this deck" · "Repeated in the file (row {row})" · "Showing the first {shown} of {total} rows" · "Include duplicates".
- Footer: "Read and map columns" · "Preview rows" · "Import {n} cards" · "Importing…".
- Result: "Imported" · "Imported with skips" · "Nothing added" · "Import didn’t finish" · "This deck no longer accepts cards" · "Added as new cards" · "Skipped — duplicates" · "Skipped — invalid rows" · "View the cards" · "Import another file" · "Back to deck" · "Try again".
```

`docs/shared/ui/screen-handoff/00-index.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/00-index.md b/docs/shared/ui/screen-handoff/00-index.md
index 45c8c85..0ab75fa 100644
--- a/docs/shared/ui/screen-handoff/00-index.md
+++ b/docs/shared/ui/screen-handoff/00-index.md
@@ -40,8 +40,8 @@ The screens of the V3 handoff. The generated handoff next to this folder
 | 08 | Card create | 9 | FE-A2 | built | — (#33; UI-base §9 rows 79–84) |
 | 09 | Card edit | 9 | FE-A2 | built | — (#33; UI-base §9 rows 79–84) |
 | 10 | Card detail | 7 | FE-A2 | built | — (#35, #36; UI-base §9 rows 85–90) |
-| 11 | Card import | 16 | FE-B3 | out of V8 | — |
-| 12 | Card export | 9 | FE-B3 | out of V8 | — |
+| 11 | Card import | 16 | FE-B3 | aligned | [11-card-import.md](11-card-import.md) |
+| 12 | Card export | 9 | FE-B3 | not built | — |
 | 13 | Study home | 7 | FE-A8 | not built | [13-study-home.md](13-study-home.md) |
 | 14 | Study entry | 9 | FE-A6, FE-A7 | not built | [14-study-entry.md](14-study-entry.md) |
 | 15 | Study options | 7 | FE-A3 | not built | — |
```

`docs/shared/ui/screen-handoff/01-deck-list.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/01-deck-list.md b/docs/shared/ui/screen-handoff/01-deck-list.md
index d79c82a..e000bf2 100644
--- a/docs/shared/ui/screen-handoff/01-deck-list.md
+++ b/docs/shared/ui/screen-handoff/01-deck-list.md
@@ -25,7 +25,7 @@ One recursive screen for the Library root (`/decks`) and any open deck
 | Summary card | `MxCard` (hero) | For a deck holding sub-decks: the scheduler name ("SM-2"), "N sub-decks · N cards", overdue · today · new · N scheduled. "Study this deck" waits under Coming soon (FE-A6). |
 | List | as root | Header "N sub-decks" with the sort pill. |
 | FAB | `MxFab` | "New sub-deck"; none at level 10 (BR-DECK-001). |
-| By content type | — | `unset`: empty state with the two create choices (BR-DECK-007). `card`: the card list, screen 07. |
+| By content type | — | `unset`: empty state with the two create choices (BR-DECK-007) and "Import cards from a file" (screen 11). `card`: the card list, screen 07. |
 
 ## Action sheet
 
@@ -65,7 +65,7 @@ One `MxBottomSheet`, "Sort & filter":
 | rootRename | ![](img/01-deck-list/rootRename-light.png) | ![](img/01-deck-list/rootRename-dark.png) | As drawn. |
 | rootDelete | ![](img/01-deck-list/rootDelete-light.png) | ![](img/01-deck-list/rootDelete-dark.png) | **Deviation:** permanent delete. |
 | deckLoaded | ![](img/01-deck-list/deckLoaded-light.png) | ![](img/01-deck-list/deckLoaded-dark.png) | No donut, no "Mastered", no Study (Coming soon). |
-| deckEmpty | ![](img/01-deck-list/deckEmpty-light.png) | ![](img/01-deck-list/deckEmpty-dark.png) | `unset` deck: both create choices. |
+| deckEmpty | ![](img/01-deck-list/deckEmpty-light.png) | ![](img/01-deck-list/deckEmpty-dark.png) | `unset` deck: both create choices and "Import cards from a file" (screen 11). |
 | deckMaxDepth | ![](img/01-deck-list/deckMaxDepth-light.png) | ![](img/01-deck-list/deckMaxDepth-dark.png) | No FAB. |
 | deckLoading | ![](img/01-deck-list/deckLoading-light.png) | ![](img/01-deck-list/deckLoading-dark.png) | As drawn. |
 | deckError | ![](img/01-deck-list/deckError-light.png) | ![](img/01-deck-list/deckError-dark.png) | As drawn. |
```

`docs/shared/ui/screen-handoff/07-card-list.md` (apply this diff):

```diff
diff --git a/docs/shared/ui/screen-handoff/07-card-list.md b/docs/shared/ui/screen-handoff/07-card-list.md
index a5c50d8..f06574b 100644
--- a/docs/shared/ui/screen-handoff/07-card-list.md
+++ b/docs/shared/ui/screen-handoff/07-card-list.md
@@ -21,8 +21,8 @@ An open deck whose content type is `card`: the card section of `DeckLevelScreen`
 
 ## Deck action sheet (`⋮`)
 
-Rename · Move to another deck · Delete. Study, Import and Export wait under Coming soon
-(spec A4; FE-A6, FE-B3).
+Rename · Move to another deck · Import cards (screen 11) · Delete. Study and Export wait
+under Coming soon (spec A4; FE-A6, FE-B3).
 
 ## States
 
@@ -50,7 +50,7 @@ detail: a tap opens it (#35).
 | Artifact | V8 | Wins |
 |---|---|---|
 | Move to Trash with Undo, for cards and for the deck | Permanent delete with a count, no Undo | BR-DECK-022, BR-DECK-023, UC-CARD-002 |
-| Tags filter, Import, Export, Study | Hidden; named under Coming soon | Spec A4 (amended) |
+| Tags filter, Export, Study | Hidden; named under Coming soon | Spec A4 (amended) |
 | An empty card list | The deck is unset again: screen 01's unset state | BR-DECK-015, ruling E-L1 |
 | The flag in the streak colour | The flag in the warning colour; the theme has no streak token | Ruling E-L2 |
 | "Select all" as a text link | A compact secondary `MxButton` | Ruling E-L3 |
```

`docs/features/transfer/it-scenarios.md` (apply this diff):

```diff
diff --git a/docs/features/transfer/it-scenarios.md b/docs/features/transfer/it-scenarios.md
index d11a094..7c08753 100644
--- a/docs/features/transfer/it-scenarios.md
+++ b/docs/features/transfer/it-scenarios.md
@@ -12,7 +12,7 @@ Kịch bản kiểm thử tích hợp truy vết về feature này (theo cột "
 
 | Bước | Thao tác người dùng | Kết quả mong đợi |
 |---|---|---|
-| 1 | Mở Import từ overflow của Card List | Wizard che toàn màn; **không** còn bottom navigation bar; URL là `/decks/<id>/cards/import` |
+| 1 | Mở Import từ overflow của Card List | Wizard che toàn màn; **không** còn bottom navigation bar; URL là `/decks/deck/<id>/cards/import` |
 | 2 | Bấm Close khi chưa có draft | Quay về đúng Card List vừa rời; bottom bar trở lại |
 | 3 | Mở Import từ sheet tạo của deck `unset`, rồi Close | Quay về deck detail của chính deck đó — không rơi vào Card List; deck vẫn `unset` và vẫn đủ lựa chọn Create card/Create sub-deck |
 | 4 | Ở bước Preview/Import bấm Android Back | Lùi một bước và giữ state; ở bước Source thì hành xử như Close |
```

`docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md` (apply this diff):

```diff
diff --git a/docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md b/docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md
index f7b050d..28f2a79 100644
--- a/docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md
+++ b/docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md
@@ -3,7 +3,7 @@ id: UC-TRANSFER-001
 title: Import card hàng loạt vào một deck
 status: ready
 rules: [BR-CARD-001, BR-CARD-002, BR-CARD-003, BR-CARD-004, BR-DECK-004, BR-DECK-008, BR-DECK-010, BR-TAG-001, BR-TAG-002, BR-TRANSFER-001, BR-TRANSFER-002, BR-TRANSFER-003, BR-TRANSFER-004, BR-TRANSFER-005, BR-TRANSFER-006, BR-TRANSFER-009]
-code: [lib/features/transfer/domain/usecases/read_import_source_use_case.dart, lib/features/transfer/domain/usecases/preview_import_use_case.dart, lib/features/transfer/domain/usecases/commit_import_use_case.dart]
+code: [lib/features/transfer/domain/usecases/read_import_source_use_case.dart, lib/features/transfer/domain/usecases/preview_import_use_case.dart, lib/features/transfer/domain/usecases/commit_import_use_case.dart, lib/features/transfer/presentation/controllers/card_import_controller.dart, lib/features/transfer/presentation/screens/card_import_screen.dart]
 ---
 ## Mục tiêu / Actor / Precondition
 
```

`docs/superpowers/specs/2026-09-26-card-transfer-design.md` (apply this diff):

```diff
diff --git a/docs/superpowers/specs/2026-09-26-card-transfer-design.md b/docs/superpowers/specs/2026-09-26-card-transfer-design.md
index 818d25a..5d95651 100644
--- a/docs/superpowers/specs/2026-09-26-card-transfer-design.md
+++ b/docs/superpowers/specs/2026-09-26-card-transfer-design.md
@@ -123,8 +123,9 @@ feature's entry in the import map is added in the commit that creates the folder
 
 ### 5.1 Source and decoding
 
-- A source is either `FileSource(bytes, extension)` or `PastedSource(text)`. The file name
-  is never kept past choosing the format and is never logged.
+- A source is either `FileSource(bytes, extension)` or `PastedSource(text)`. The domain
+  never carries the file name; the wizard shows it on the source chip while it is open
+  (screen 11), and it is never logged or stored.
 - `.csv` and `.tsv` and pasted text: strip a UTF-8 BOM, then strict UTF-8 decode; failure →
   `badEncoding` with the guidance "Save the file as UTF-8 and try again". Pasted text
   splits on tab when its first line contains a tab, else on comma.
```

`docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (apply this diff):

```diff
diff --git a/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md b/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
index 63223e4..12a6cbb 100644
--- a/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
+++ b/docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md
@@ -506,6 +506,8 @@ item names where it comes from.
 | 101 | "Add details" is 48 tall (the touch minimum), not the kit's 42, with a solid `outlineVariant` edge instead of dashed: there is no dashed-border token (row 81); its field list is 12/600, not 12/500 | card editor fields (audit 2026-09-25) |
 | 102 | Single-line user text sits at line-height 1.5, not the kit's values (screen title 1.2, list row title 1.35, row sub-line and tag 1.4), so an ellipsized name keeps its stacked marks. A ListRow with a sub-line is about 4 px taller, and the screen title grows the app bar sooner under text scaling. The editor term (1.25) wraps instead of clipping and keeps the kit's value; a card row's back (`rowDescription`, 1.45) was measured holding the marks and keeps its value, pinned by the same golden | FE-C2 |
 | 103 | The detail field (kit OptionalField) grows from 48, the touch minimum, not the kit's 40: its whole box is the tap target, and the screen 09 visual audit failed Android's 48 dp guideline at 40 | FE-D2 visual audit |
+| 104 | Card import names the fields two ways: "Term (front)" / "Meaning (back)" on the mapping, "term" and "meaning" in its notes and row reasons. One vocabulary waits for a copy pass over screens 08–12 | critique 2026-09-26 P3 (transfer) |
+| 105 | Card import shows one spinner card while a large import writes, with no progress or waiting line | critique 2026-09-26 P3 (transfer) |
 
 Further contradictions found while implementing are appended here with the same
 rule applied. `docs/_generated/open-questions.md` is generated and is not
```

`docs/README.md` (apply this diff):

```diff
diff --git a/docs/README.md b/docs/README.md
index aa5efb8..5f74c4e 100644
--- a/docs/README.md
+++ b/docs/README.md
@@ -60,7 +60,7 @@ Hai trục độc lập (thuật toán SRS và StudyMode) và hai loại phiên:
 
 | # | Feature | Notes |
 |---|---|---|
-| N1 | Import/export | Sub-project sau (UC-TRANSFER-001, UC-TRANSFER-002, BR-TRANSFER-007…BR-TRANSFER-014): import CSV/TSV/XLSX, export nội dung — không phải backup |
+| N1 | Import/export | Trong V8.0 theo [spec card transfer](superpowers/specs/2026-09-26-card-transfer-design.md) (UC-TRANSFER-001, UC-TRANSFER-002, BR-TRANSFER-001…BR-TRANSFER-014): import CSV/TSV/XLSX hoặc văn bản dán (màn 11), export nội dung (sheet 12) — không phải backup. Backend BE-B3 xong; UI là FE-B3 |
 | N2 | Nhắc nhở ôn tập hằng ngày | Sub-project sau (UC-REMINDER-001, BR-REMINDER-001…BR-REMINDER-012): opt-in, mặc định tắt, một tóm tắt mỗi ngày dựng từ workload đến hạn tại thời điểm hiện tại. Quyền notification chỉ được xin **sau** khi người dùng bật (BR-REMINDER-011) |
 | N3 | Tag/phân loại card | Sub-project sau (UC-TAG-001, BR-TAG-003…BR-TAG-011): catalog phạm vi library, lọc nhiều tag theo OR, đổi tên có gộp, và xoá. Ngoài phạm vi: tag phân cấp, màu tag, taxonomy chia sẻ |
 
```

`docs/wbs_FE.md` (apply this diff):

```diff
diff --git a/docs/wbs_FE.md b/docs/wbs_FE.md
index 05855fb..f3f8b96 100644
--- a/docs/wbs_FE.md
+++ b/docs/wbs_FE.md
@@ -89,7 +89,7 @@ Quy ước giống [`wbs_BE.md`](wbs_BE.md):
 |---|---|---|---|---|---|---|
 | FE-B1 | Trash: màn hình Trash mở từ app bar, xoá vào Trash, khôi phục (UC-TRASH-001) | chưa bắt đầu | BE-B1, FE-A1, FE-A2 | M | [README trash](features/trash/README.md) | Sau BE-B1 |
 | FE-B2 | Danh mục tag và lọc card theo tag (UC-TAG-001) | chưa bắt đầu | BE-B2, FE-A2 | M | [ui.md](features/tags/ui.md), [kịch bản IT](features/tags/it-scenarios.md) | Sau BE-B2 |
-| FE-B3 | Import card vào deck và export card ra file (UC-TRANSFER-001, UC-TRANSFER-002) | chưa bắt đầu | BE-B3, FE-A2 | M | [README transfer](features/transfer/README.md), [kịch bản IT](features/transfer/it-scenarios.md) | Chọn file và chia sẻ file cần plugin nền tảng (xem Điểm chặn) |
+| FE-B3 | Import card vào deck và export card ra file (UC-TRANSFER-001, UC-TRANSFER-002) | đang làm | BE-B3, FE-A2 | M | [spec](superpowers/specs/2026-09-26-card-transfer-design.md), [plan import](superpowers/plans/2026-09-26-card-import-ui.md), [màn 11](shared/ui/screen-handoff/11-card-import.md); test trong `test/features/transfer/presentation/` | Plan 2: sheet export (màn 12), Export trên bulk bar và `⋮` |
 | FE-B4 | Thư viện starter: child flow trong Thư viện, kèm empty state khi chưa có deck (UC-STARTER-001) | chưa bắt đầu | BE-B4, FE-A1 | M | [ui.md](features/starter-decks/ui.md) | Sau BE-B4 |
 | FE-B5 | Nhắc học hằng ngày trong Cài đặt; chỉ xin quyền notification sau khi người dùng bật (UC-REMINDER-001; BR-REMINDER-011) | chưa bắt đầu | BE-B5, FE-A3 | S–M | [README reminders](features/reminders/README.md) | Sau BE-B5 |
 
@@ -145,7 +145,6 @@ bỏ nhánh này trước P1.
 | FE-A2, FE-A3, FE-A9 | Chưa có file chi tiết handoff cho màn 08–10, 15, 22, 23, 25, 26 ([index](shared/ui/screen-handoff/00-index.md)) | Các màn đó | Viết file chi tiết của màn trước khi lập plan |
 | FE-A1 (một phần) | Panel "Mastered x/y" trên danh sách deck chưa được định nghĩa | Chỉ phần panel đó | Chờ BR/UC của deck định nghĩa nó (điểm chặn "Mastery của danh sách deck" trong [`wbs_BE.md`](wbs_BE.md)) |
 | FE-C1 | Quyết định "implement the handoff as written" (spec UI base §2) giữ nguyên các token dưới ngưỡng contrast | Accessibility của toàn app | Chủ dự án quyết có sửa giá trị handoff không |
-| FE-B3 | Chọn file và chia sẻ file cần plugin nền tảng | Import/export | Quyết trong spec, kèm lý do và cách rollback |
 | FE-D3 | Không có emulator hoặc thiết bị | 8 kịch bản `DEVICE-E2E` | Môi trường chạy |
 
 ## Trạng thái kiểm chứng
```

- [ ] **Step 3: Regenerate the docs index and check**

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `docs/_generated/traceability.md` gains the two presentation paths of
UC-TRANSFER-001; the check reports no error (the existing warnings stay).

- [ ] **Step 4: The gate**

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh --force
```

Expected: every gate green (see "How this plan was checked" for the counts).

- [ ] **Step 5: Commit and push**

```bash
git add \
  tools/design/screen_states.json \
  docs/shared/ui/screen-handoff/11-card-import.md \
  docs/shared/ui/screen-handoff/00-index.md \
  docs/shared/ui/screen-handoff/01-deck-list.md \
  docs/shared/ui/screen-handoff/07-card-list.md \
  docs/features/transfer/it-scenarios.md \
  docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md \
  docs/superpowers/specs/2026-09-26-card-transfer-design.md \
  docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md \
  docs/README.md \
  docs/wbs_FE.md \
  docs/shared/ui/screen-handoff/img/11-card-import \
  docs/_generated/traceability.md
git commit -m "$(cat <<'EOF'
docs(transfer): screen 11 handoff, rows 11 and 12, FE-B3 in progress

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01CBRfGLtA4Pjvtdh6rAqFHe
EOF
)"
```

```bash
git push -u origin claude/lexilize-flashcard-app-lpklbs
```

- [ ] **Step 6: The Android build**

Run the repository's `build-apk` workflow on the branch (F10) and record its run in the
PR. `file_picker` is the one new plugin with native code.
