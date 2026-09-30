# Critique 2026-09-30, remaining items — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the critique items PR #161 left: dismissible and hint notes, screen 27 inline problems, the slimmer 13 hero, one-sentence algorithms, "3 of 23", and a measured Guess contrast.

**Architecture:** A local-only Drift table (`dismissed_note`, schema v11) behind a keep-alive store in `lib/core/notes/`; `MxNote` gains `onDismiss` and a `.hint` form; features wire them. Screen 27 swaps its floating notice for an `MxInlineBanner`.

**Tech Stack:** Flutter 3.47.5, Riverpod, Drift, ARB l10n, goldens in `memox-golden:3.47.5`.

**Spec:** `docs/superpowers/specs/2026-09-30-critique-remaining-design.md`

## Global Constraints

- Tests at the default text scale only (PRODUCT.md). Light and dark stay.
- `dismissed_note` never syncs (no trigger, no `server_version`); `schemaVersion` 10 → 11 through the flutter-drift workflow (dump, steps, generate), never `make-migrations`.
- Features import `core/notes/di/*` only; no new feature-to-feature edge.
- Components hold no copy: `dismissLabel` is required with `onDismiss`.
- Every new string in `app_en.arb` and `app_vi.arb`; no unused ARB key left.
- Guard (`memox-v8`) clean: no `Icon(color:)`, no raw numbers, no literals in UI.

## Review Focus

- A dismissed note must stay hidden after the screen is rebuilt and after the database is reopened (stream from the table, not widget state).
- The migration from v10 keeps every existing row and ends at the same schema as a fresh install.
- Screen 27 with a failure **and** refused rows shows the refused banner with both actions (the notice showed refused first).
- Section notes as hints must keep their text readable (noteText in `onSurfaceVariant` on the page ground ≥ 4.5:1 — the contrast test already covers `onSurfaceVariant` on page).
- The 13 hero with overdue 0 and today > 0 still reads correctly (zero terms drop).

---

### Task 1: Guess contrast pair

- [ ] Add the pair to `test/core/theme/token_contrast_test.dart` (spec §3.5); run; if it fails, raise `AppOpacity.muted` to the lowest passing value and record it in DESIGN.md; commit `test(theme): faded Guess options meet 4.5:1`.

### Task 2: Copy (02, 21)

- [ ] Tests asserting the new en strings (spec §3.4); RED; update ARB en/vi; `flutter gen-l10n`; fix tests that pinned old text; GREEN; commit `fix(copy): one sentence per algorithm, wrong turns read "of"`.

### Task 3: Study home hero (13)

- [ ] Test: the hero's `MxWorkloadBreakdownLine` has `newCount`/`scheduledLabel` absent (no "new"/"scheduled" in the hero); RED; pass only overdue and today; GREEN.
- [ ] Rewrite BR-STUDY-068 (Vietnamese, the store definitions stay; the hero states Due with its two halves), UC-STUDY-002 body, 13 record; `python tools/docs/generate.py`; commit `fix(study): the home hero states what is due`.

### Task 4: `MxNote.hint` and section notes

- [ ] Tests: `MxNote.hint` has no `DecoratedBox` decoration; `MxSection(note:)` renders `MxNote` in hint form; RED; implement (spec §3.1); switch 11's mapping note to `.hint`; GREEN; commit `feat(shared): MxNote.hint for footnotes; section notes use it`.

### Task 5: `dismissed_note` table and store

- [ ] Add `ui_state.drift` with the table, include it, bump to v11 with `m.createTable`; run build_runner, schema dump, steps, generate; extend `test/drift/migration_test.dart` (v10 → v11, every `migrateAndValidate` to 11); `docs/shared/data/schema.md`.
- [ ] Test `DismissedNoteStore`: `dismiss` then `watchDismissed` emits the key; a reopened database still has it; RED → implement `lib/core/notes/{dismissed_note_store.dart,note_keys.dart,di/dismissed_notes_providers.dart}` → GREEN; commit `feat(core): local dismissed-note store (schema v11)`.

### Task 6: Dismissible notes on 06, 03, 11

- [ ] Tests: `MxNote(onDismiss:)` shows a close button with the label and calls back; on each screen, tapping it hides the note and it stays hidden after re-pump; RED; implement `onDismiss`/`dismissLabel`, `commonDismissNote` en/vi, wire the three screens; GREEN; commit `feat(ui): dismissible notes on Trash, Starter decks and Import`.

### Task 7: Screen 27 inline problems

- [ ] Tests: with a failure, no `MxFloatingNotice`, an `MxInlineBanner` with the failure sentence sits above "Sync now"; with refused rows, the banner carries Keep and Try again that run their tasks; RED; implement; GREEN; commit `fix(settings): sync problems sit under the status, above Sync now`.

### Task 8: Goldens and review

- [ ] Regenerate in the container (copy back only changed PNGs); rerun golden suite; commit; build the golden-compare page(s); owner review.

### Task 9: Records and gate

- [ ] DESIGN.md, records 02, 03, 06, 11, 13, 21, 24, 27, `wbs_FE.md` FE-D7; docs check; `dod_check.sh`; final review; PR; merge after the owner approves the goldens.
