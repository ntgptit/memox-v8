# Type scale A and one hierarchy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the type scale smaller (scale A) and give each level of the
hierarchy one role across the app.

**Architecture:**
- The scale lives in `AppTypography.build`; every role and every ForUI slot
  reads it, so F1 is one edit.
- The ForUI slots that draw text no role names (the dialog's title, the tab
  bar's labels, a field's description and counter) are set once in
  `app_theme.dart` from `MxTextRoles`, so every consumer inherits them.
- The rest is a role choice at the site.

**Tech Stack:** Flutter 3.47.5, ForUI 0.27.6.

**Spec:** `docs/superpowers/specs/2026-10-20-type-scale-and-hierarchy-design.md`

Execution: native, in the main loop (owner, 2026-10-20: "Áp dụng tất cả").

## Global Constraints

- Scale A: `xs3` 10, `xs2` 12, `xs` 13, `sm` 15, `md` 16, `lg` 18, `xl` 20,
  `xl2` 26; the line heights stay per step.
- A role takes only `copyWith(color:)` or the mono family (The Twelve Roles
  Rule); no raw `TextStyle` outside `lib/core/theme/` (the guard).
- `package:forui` stays in `lib/core/theme/`, `lib/shared/` and `lib/app/`.
- Weights stop at 600.

## Review Focus

1. A Vietnamese title with stacked marks (Ẳ, Ổ) in a dialog: the new
   1.5 line height does not clip it. Pinned in Task 1 (the dialog test reads
   the role, whose height the typography test pins).
2. The tab bar at 360dp with Vietnamese labels: 12 still fits one line
   (The One Line Rule). Pinned by the shell goldens in Task 4.
3. A selected tab: only its colour changes, its width does not jump. Pinned
   in Task 1.
4. A field with supporting text and then an error: both lines are `caption`,
   so the box does not move. Pinned in Task 1.
5. A sheet title of two lines (a long deck name) at 16/600: still two lines
   with an ellipsis. Pinned by the existing sheet test in Task 2.

---

### Task 1: The scale and the theme's slots (F1–F4)

**Files:**
- `lib/core/theme/app_typography.dart`: the sizes; the roles' doc comments.
- `lib/core/theme/app_theme.dart`: `dialogStyle`, the tab bar's `textStyle`,
  `style.formFieldStyle.descriptionTextStyle` and the text fields' counter.
- `test/core/theme/app_typography_test.dart`: the new sizes; the line-height
  bar by step (`md` and under 1.5).
- `test/shared/widgets/mx_dialog_test.dart`, `mx_bottom_nav_test.dart`,
  `mx_text_field_test.dart`: the role each slot draws.

- [ ] Step 1: Change the expected sizes to `[10, 12, 13, 15, 16, 18, 20, 26]`
  and run the typography test: it fails.
- [ ] Step 2: Change the sizes; update the doc comments; the test passes.
- [ ] Step 3: Write the slot tests: the dialog's title equals
  `texts.sectionTitle` in the foreground; a tab's label is `meta`'s size and
  weight, selected or not; a field's supporting text and counter are
  `caption`'s size and weight. They fail.
- [ ] Step 4: Set the slots in `_build` from `MxTextRoles(typography)`. The
  tests pass.
- [ ] Step 5: Commit "Theme: type scale A; the dialog, tab bar and field
  slots read the roles (DEV-323)".

### Task 2: Shared widgets (F5, F6)

**Files:** `mx_bottom_sheet.dart`, `mx_error_state.dart` and their tests.

- [ ] Step 1: Change the expectations to `sectionTitle`; they fail.
- [ ] Step 2: Change the roles; the tests pass.
- [ ] Step 3: Commit with Task 3.

### Task 3: Feature sites (F5, F7–F12)

**Files:** the sites listed in the spec §4; each site's own test where it
asserts a role.

- [ ] Step 1: Change each role as the spec's table says.
- [ ] Step 2: `rg` the tests for the old role at each site and update them.
- [ ] Step 3: Run `dod_check.sh --changed`.
- [ ] Step 4: Commit "UI: one role per level across the app (DEV-323)".

### Task 4: Docs and goldens (F13)

- [ ] Step 1: Rewrite DESIGN.md's Hierarchy prose; regenerate its
  frontmatter with
  `MEMOX_WRITE_DESIGN_DOCS=1 flutter test test/tools/design_doc_test.dart`;
  run `python3 tools/design/check.py`.
- [ ] Step 2: Update the screen detail files and the shared widget inventory
  rows that state a size or a role that changed (`rg` for `16/500`, `18/600`,
  `14/400` and the role names).
- [ ] Step 3: `run_goldens.sh --update`; look at a sample of each screen in
  light and dark.
- [ ] Step 4: Commit "Goldens and docs: type scale A (DEV-323)".

### Task 5: Verification and review

- [ ] Run `dod_check.sh` and `run_goldens.sh` on the final tree.
- [ ] Run one Impeccable audit of the changed states.
- [ ] Run the final whole-branch review on Opus; fix its findings in one batch
  and rerun the gate.
- [ ] Rerun check degrade and check similar on the final diff.
- [ ] Build the golden-compare page, get the owner's approval, then open the
  pull request.
