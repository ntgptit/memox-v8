# SP1: retire the UI kit, make DESIGN.md the UI authority — design

Status: draft 2026-09-30, awaiting owner review ·
Path: architectural (sub-project 1 of 4) · Owner rulings 2026-09-30 (§3): R1–R6

## 1. Intent

The 2026-09-30 Impeccable critique of all 28 screens found that many of the app's
weakest spots are drawn by the artifact "MemoX — Mobile UI Kit v3"
(<https://claude.ai/artifact/UCesgHkzYHKsZwhwVshKRE>): the three-way progress block on
screen 07, the triple-stated numbers on screen 21, the doubled Save on screens 08/09.
Under the current rules every fix would become a recorded deviation from the kit.

The owner ruled that the kit no longer holds. The app, as built and reviewed through its
goldens, becomes the UI authority, recorded in a `DESIGN.md` generated from the code.
Fixes then change the app and its record, with no deviation bookkeeping.

The work is decomposed into four sub-projects, each with its own spec, plan and PR:

| # | Sub-project | Changes |
|---|---|---|
| **SP1** (this spec) | Retire the kit, establish DESIGN.md | docs, tools, gates; no Dart, no goldens |
| SP2 | Shared design system fixes from the critique | `lib/shared`, `lib/core/theme`, goldens |
| SP3a | Library and card screens (01–12) | features, goldens |
| SP3b | Study, progress and settings screens (13–27) | features, goldens |

SP1 goes first so SP2/SP3 only update DESIGN.md and the detail files, never a deviation
table.

Success means:

- no live document names the kit, its images or the design handoff as an authority;
- `DESIGN.md` describes the visual system the app ships today;
- every screen detail file describes the app, and its States table names goldens;
- `python tools/docs/check.py`, the `tools/docs` Python tests and the guard pass;
- nothing under `docs/superpowers/` or `.impeccable/critique/` changes, apart from this spec and its plan.

## 2. Current state

- **Kit images:** `docs/shared/ui/screen-handoff/img/` (19 MB), embedded in the States
  tables of 27 detail files (about 440 image links).
- **Deviation tables:** a `## Deviations` section in most detail files
  (`| Artifact | V8 | Wins |`); the "Wins" column carries rulings (E-L1, D14, …).
- **Design handoff:** `docs/shared/ui/design-handoff/` (foundations, theme binding,
  46 widget contracts), generated from `docs/shared/ui/design-handoff.json` by
  `tools/docs/split_handoff.py`; `tools/docs/check.py` (`check_design_handoff`) fails when
  the folder differs from a fresh split.
- **Capture tooling:** `tools/design/` (`capture_screens.mjs`, `capture_lib.mjs`,
  `capture_lib.test.mjs`, `screen_states.json`); used only to capture kit images. CI does
  not run it.
- **State checklist:** `docs/shared/ui/screen-state-checklist.md` counts kit states
  (209 of 211 done, 2 not built by design).
- **References:** `CLAUDE.md` (layers table, "A screen's workflow", "Where knowledge
  lives", "UI source of truth"), `PRODUCT.md` (Brand Commitments, Evidence on Hand),
  `docs/README.md` (tree, split command, check description), `docs/wbs_FE.md`, the guard
  rule `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-token-rules.yaml`
  (header comment only). No skill under `.claude/skills/`, no `AGENTS.md`, no Dart file
  references them.
- **Historical documents:** about 500 links from `docs/superpowers/plans/` and
  `docs/superpowers/specs/` point into `img/` and `design-handoff/`. `check.py` checks links
  everywhere, and skips only id checks under `superpowers/` (`SKIP_ID_CHECK`).

## 3. Owner rulings (2026-09-30)

- **R1.** The kit is retired as UI authority; no deviations are recorded against it.
- **R2.** The new authority is a `DESIGN.md` generated from the app
  (`/impeccable document`), recorded by an ADR.
- **R3.** `DESIGN.md` replaces the design handoff: `design-handoff/`, its JSON, its split
  tool and its check go.
- **R4.** Delete `screen-handoff/img/`, remove the deviation tables (keep BR/UC, states,
  rulings), update `CLAUDE.md` and `PRODUCT.md`, remove the kit-only capture tooling.
- **R5.** Historical documents stay byte-identical; `check.py` skips link checks under
  `docs/superpowers/`, as it already skips id checks there.
- **R6.** The folder keeps its name `docs/shared/ui/screen-handoff/`.

## 4. Design

### 4.1 ADR-019

`docs/shared/decisions/ADR-019-app-la-chuan-ui.md`, in Vietnamese like the other ADRs,
status `active`. It records:

- **Context:** the kit and the design handoff were the visual authority; the critique of
  2026-09-30 found kit-drawn problems; fixing them meant recording deviations.
- **Decision:** precedence becomes BR/UC > `DESIGN.md` together with the goldens the owner
  reviewed > the screen's detail file. A UI change updates `DESIGN.md` (when it touches the
  visual system) and the screen's detail file in the same PR. The kit artifact stays on
  claude.ai as history and is never read as a source.
- **Consequences:** the files removed in §4.3; Impeccable critiques against `DESIGN.md` and
  the quality floor; the UI-base debt register (spec 2026-09-23 §9) remains the list of
  known UI debt, not of kit deviations.

### 4.2 DESIGN.md

Generated at the repository root by `/impeccable document` from `lib/core/theme/` and
`lib/shared/widgets/`, next to `PRODUCT.md`. It covers:

- foundations: colour roles light and dark, type scale, spacing, radius, elevation,
  motion, as the tokens define them;
- theme binding: which Material 3 component theme each slot sets;
- the Mx widget catalogue: purpose and variants of each shared widget;
- the copy voice for failures (local-first: say nothing was lost, then offer the retry),
  carried over from `design-handoff/widgets/error-state.md`.

The generator derives it from the shipped code, not from the handoff. Before deleting the
handoff, the implementer compares the two and carries any rule the code enforces but the
generated draft misses (for example a contrast pair or a touch-target rule) into
`DESIGN.md`. Anything in the handoff that the code does not implement is dropped.

### 4.3 Deletions

- `docs/shared/ui/screen-handoff/img/`
- `docs/shared/ui/design-handoff/` and `docs/shared/ui/design-handoff.json`
- `tools/docs/split_handoff.py`, `tools/docs/test_split_handoff.py`, and in
  `tools/docs/check.py` the `split_handoff` import, `check_design_handoff`, its call and
  its docstring lines
- `tools/design/` (all four files)
- `docs/shared/ui/screen-state-checklist.md`

### 4.4 Screen detail files

For each of the 28 files in `docs/shared/ui/screen-handoff/`:

- **States table:** the Light/Dark columns become the golden file names
  (`` `card_list_light.png` ``), following the Tag filter section of `07-card-list.md`,
  with one line naming the goldens folder. A state with no golden says "no golden". The
  "V8" column becomes "App" and describes behaviour only; "As drawn" is removed or replaced
  by what the app does.
- **Deviations:** the section is removed. Each row's "V8" text is checked against the
  file's Layout and States; if the file does not already say it, it moves there as
  behaviour. A row whose "Wins" names a ruling (E-L1, D14, FE-B1 D3, …) moves to a
  `## Rulings` section (created when the file has none), stated as the rule, not as a
  difference from the kit.
- **Wording:** "the kit draws", "as the artifact draws" and similar phrases are rewritten
  to describe the app. "Not in the kit" notes (16a, 27, tag filter) become "Shaped by
  Impeccable before the plan" or are removed.
- Copy sections, BR/UC references and accessibility notes stay.

`00-index.md`: drop the Source and Authority bullets, the Images and State checklist
bullets; the Status values shrink to `built` and `out of V8`; every screen row reads
`built`; the shared rules stay, reworded where they cite the artifact ("as the artifact
draws them").

### 4.5 References

- **`CLAUDE.md`:**
  - Layers table and bullets: "Impeccable judges UI against `DESIGN.md`, not against its
    own taste."
  - A screen's workflow: step 1 reads the screen's detail file, its goldens and
    `DESIGN.md`; step 3 critiques against `DESIGN.md`; `shape` is for a screen or state not
    built yet; step 5 audits the goldens against `DESIGN.md`.
  - Where knowledge lives: "Deviations from the kit or a UI spec" becomes "The visual
    system → `DESIGN.md`; a screen's behaviour, states and rulings → its detail file; known
    UI debt → the UI-base register (§9)".
  - "UI source of truth" section rewritten around `DESIGN.md`, the goldens and ADR-019;
    keeps "after building a screen, update its row in the screen index".
- **`PRODUCT.md`:** Brand Commitments point the failure copy voice and the visual system
  at `DESIGN.md`; Evidence on Hand drops the kit images and the design handoff and names
  `DESIGN.md`.
- **`docs/README.md`:** remove the `design-handoff*` tree entries, the paragraphs about the
  handoff and the split command, the `check.py` handoff description; describe
  `screen-handoff/` as the per-screen record of the app; list ADR-019 wherever ADRs are
  listed.
- **`docs/wbs_FE.md`:** links into removed paths become plain text or point at the detail
  file.
- **Guard rule header:** "The visual system (`DESIGN.md`): no hardcoded colours, text
  styles or padding — everything comes from design tokens." No rule logic changes.

### 4.6 check.py link scope

Add `superpowers` to the folders whose links are not checked, next to `SKIP_ID_CHECK`
(one tuple or one condition), and update the module docstring ("links are checked
everywhere except docs/superpowers/"). All other link checks stay, so every broken link
in a live document still fails.

### 4.7 Verification

- `python tools/docs/check.py` exits 0.
- `python -m unittest discover -s tools/docs -p "test_*.py"` passes; `test_check.py` gains a case showing a broken link under `docs/superpowers/` is not reported while one elsewhere still is (with `test_split_handoff.py` deleted).
- The guard runs clean.
- `git diff --stat master -- docs/superpowers .impeccable` lists only this spec and its plan.
- A final grep finds no live reference (outside `docs/superpowers/`, ADR-019, which names the kit as history, and
  `.impeccable/critique/`) to `UCesgHkzYHKsZwhwVshKRE`, `UI Kit v3`, `design-handoff`,
  `screen-handoff/img`, `screen-state-checklist`, `tools/design`.
- No Dart or golden file changes, so no Flutter gate is needed.

## 5. Out of scope

- Any UI change (SP2, SP3a, SP3b).
- Deleting the kit artifact on claude.ai.
- Renaming `screen-handoff/`.
- Editing historical plans, specs or critique snapshots.
