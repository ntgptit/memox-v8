# Shared overlay API and owner rulings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the owner's rulings of 2026-10-08 on the shared-widget review: option A of SW-REV-008/009 (a standard sheet head, a one-action footer, a picker error sheet and a shared confirm dialog), the neutral "gone" state everywhere, and one "Close selection" label.

**Architecture:** Four additions to existing shared files, no new widget file: `MxBottomSheet(title, subtitle)`, `MxSheetActions.single`, `MxDeckPickerErrorSheet` beside the loading sheet, and `showMxConfirm` beside `showMxDialog`. Callers migrate only where the new API draws the same pixels, or where the owner ruled the change (the sheet subtitle role, the gone tone, the label).

**Tech Stack:** Flutter 3.47.5, the repo's widget harness, `run_tests.sh`, `run_goldens.sh`, `dod_check.sh`.

**Spec:** the owner's answers of 2026-10-08 (option A; gone tone neutral; "Close selection"), the SW-REV-008, 009 and 011 comments on Linear DEV-135, and `DESIGN.md`.

## Global Constraints

- Components hold no copy: every label is a parameter (`DESIGN.md` › Components).
- Colours, sizes and type only from the theme and tokens; the guard holds.
- A dialog's or sheet's confirm whose title names the object is the verb alone; Cancel and the confirm share the row 1 : 1 (DEV-179).
- A gone item reads in the neutral tone (owner 2026-10-08).
- The selection bar's close reads "Close selection" on Card list and Trash (owner 2026-10-08).

## Review Focus

- A sheet title that is user data and long (a deck name, a Trash entry): it stops at two lines with an ellipsis (Task 3 test).
- A confirm whose confirm cannot go (`canConfirm: false`): Cancel still closes it with false (Task 1 test).
- Back and a scrim tap on a shared confirm: false, never null (Task 1 test).
- A picker that fails to load: the sheet keeps its head and a way out, and Retry reloads (Task 3 test).
- TalkBack on a titled sheet: the route is named by the title (Task 3 test).

---

### Task 1: `showMxConfirm` and its callers (SW-REV-009)

**Files:** Modify `lib/shared/widgets/mx_dialog.dart`; migrate `card_discard`, `deck_discard`, `deck_switch_algorithm`, `starter_repeat_add`, `study_exit`, `sync_keep`, `tag_delete` dialogs and `account_confirm_dialog_widget.dart`; Test `test/shared/widgets/mx_dialog_test.dart`.

**Interfaces:**
- Produces: `Future<bool> showMxConfirm(BuildContext context, {required String title, required String body, required String cancelLabel, required String confirmLabel, Widget? content, bool isDestructive = false, bool isWarning = false, bool canConfirm = true})`.

- [ ] Failing tests: the confirm returns true; Cancel, Back and the scrim return false; `isDestructive` and `isWarning` reach the confirm's tone; `canConfirm: false` disables the confirm and Cancel still returns false; `content` sits under the body.
- [ ] Implement in `mx_dialog.dart` with `MxDialog` and `MxSheetActions`.
- [ ] Migrate the seven feature dialogs: each keeps its public `show…` function and its copy, and its private widget class goes. `confirmAccountStep` wraps `showMxConfirm` with `commonCancel`; `AccountConfirmDialogWidget` goes.
- [ ] Run the shared and the callers' feature tests; commit.

### Task 2: `MxSheetActions.single` (SW-REV-008)

**Files:** Modify `lib/shared/widgets/mx_sheet_actions.dart`; migrate the one-button footers (`account_confirm_dialog_widget.dart` last admin, `card_tag_filter_sheet_widget.dart`, `deck_level_query_sheets_widget.dart`, `study_direction_sheet_widget.dart`, `card_export_sheet_widget.dart`, `mx_deck_picker_sheet.dart`); Test `test/shared/widgets/mx_sheet_actions_test.dart`.

**Interfaces:**
- Produces: `MxSheetActions.single({Key? key, required String label, required VoidCallback? onPressed, MxButtonTone tone = MxButtonTone.primary, bool isInSheet = false})`.

- [ ] Failing test: one block button spanning the row, in the given tone, its press reaching `onPressed`, null disabling it; the sheet form keeps the ghost rule and 8 16 16.
- [ ] Implement as the `children` path with one `Expanded(MxButton(isBlock: true))`.
- [ ] Migrate the footers whose button carries no other flag; keep any that does, with the reason in the commit.
- [ ] Run the shared and feature tests; commit.

### Task 3: `MxBottomSheet(title, subtitle)` and `MxDeckPickerErrorSheet` (SW-REV-008)

**Files:** Modify `lib/shared/widgets/mx_bottom_sheet.dart`, `mx_deck_picker_sheet.dart`; migrate the sheets with a plain head (`monitoring_choice`, `monitoring_status`, `monitoring_device_user`, `user_role`, `card_sort`, `card_flag`, `deck_level_query`, `speech_language`, `study_direction`, `import_option`, `deck_action`, `trash_entry_actions`, `card_tag_filter`) and the three picker error branches (`card_move`, `deck_move`, `trash_restore`); Test `mx_bottom_sheet_test.dart`, `mx_deck_picker_sheet_test.dart`.

**Interfaces:**
- Produces: `MxBottomSheet({…, String? title, String? subtitle})` (asserts `header == null || title == null`, `subtitle` needs `title`); `MxDeckPickerErrorSheet({required String title, String? rule, required String errorTitle, required String errorBody, required String retryLabel, required VoidCallback onRetry, bool isRetrying = false, required String dismissLabel, required VoidCallback onDismiss})`.

- [ ] Failing tests: the head is `compactTitle` 20 in and 4 down, 12 under, the title at most two lines with an ellipsis, the subtitle in `noteText` 4 below; the route is named by the title; the error sheet keeps the picker's head, an `MxErrorState` with Retry, and a dismiss footer.
- [ ] Implement: the head moves from `_PickerHead` into `MxBottomSheet`; the picker and its loading sheet use `title`/`subtitle`.
- [ ] Migrate the plain heads to `title`. The two whose sub-line is `rowDescription` (Trash entry actions, Tag filter) take `noteText` with it, per the owner's option A (1.45 → 1.5 line height, 0.6 dp). Heads with other content (merge choice at 16 in, tag actions' chip, export, starter algorithm) stay `header`.
- [ ] Migrate the three picker error branches to `MxDeckPickerErrorSheet`.
- [ ] Run the shared and feature tests; commit.

### Task 4: The neutral gone state and one close label (SW-REV-011)

**Files:** `deck_gone_state_widget.dart`, `study_options_screen.dart`, `deck_progress_screen.dart`, `monitoring_detail_screen.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`; their tests.

- [ ] Failing tests: the deck's gone state, its copies in Study options and Deck progress, and Monitoring's gone event are an `MxEmptyState` in the neutral tone; Trash's selection close reads the Card list's label.
- [ ] Implement: `tone: MxEmptyStateTone.neutral`; Monitoring's gone event moves from `MxErrorState` to `MxEmptyState(neutral, searchOff)`; `trashSelectionClose` takes `cardSelectionClose`'s text in English and Vietnamese.
- [ ] Run the tests; commit.

### Task 5: Documents, goldens and review

- [ ] `DESIGN.md`: MxBottomSheet's title and subtitle, `MxSheetActions.single`, `showMxConfirm`, `MxDeckPickerErrorSheet`; a gone item is `MxEmptyState` in the neutral tone, and MxErrorState is the load failure only. Screen detail files that describe a changed gone state or close label follow.
- [ ] `dod_check.sh` PASS; `run_goldens.sh --update`; a golden-compare page for the owner; final whole-branch review; push to pull request number 267.
