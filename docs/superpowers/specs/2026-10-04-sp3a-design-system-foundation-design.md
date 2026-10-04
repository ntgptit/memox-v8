# SP3a — Design-system foundation

Status: approved by the owner 2026-10-04 (rulings A1–A11) · Date: 2026-10-04 · Branch: `claude/wonderful-ride-dnypk9` (from
`master` at `37919b8`, PR #197 merged)

Sub-project 3a of the UI rebuild ([SP2 spec](2026-10-04-sp2-remove-legacy-ui-design.md) §1, §10).
SP2 left no theme, no tokens and no `Mx*` in code. SP3a rebuilds the reusable design system from
`DESIGN.md`: structured design data, a generator, the light and dark themes, the primitives and
the shared `Mx*` components. It builds no screen and no navigation shell.

This spec holds the architecture, the boundaries and the implementation strategy. The component
catalog lives in `DESIGN.md §Components` (A6). Progress is tracked in `docs/wbs_FE.md`. This spec
names components only to assign them; their contracts are in the catalog.

## 1. Owner rulings (2026-10-04)

- **A1 — Boundary.** SP3a is the reusable design-system foundation. SP3b is the navigation shell,
  the SCR-DECK-001 vertical slice and the feature components it needs. SP3c is the other 33
  screens.
- **A2 — Colour model (owner ruling D18).**
  - The `*-ink` concept is removed: no `primaryInk`, `status-*Ink`, `successInk`, `dangerInk`,
    `warningInk` or any similar derived ink role.
  - Material 3 roles keep their semantics. `primary` serves both as primary or accent text and
    icons on a surface, where contrast holds, and as a fill under `onPrimary`. It is not a
    fill-only colour.
  - The light `primary` changes from `#5265F5` to `#4151C6`, because the role must meet its
    semantics and its contrast. The legacy value is not kept to preserve the old look.
  - Content on a coloured surface uses its pair: `X → onX`, `XContainer → onXContainer`, for
    primary, secondary, tertiary and error. `onX` is never used as a "text version of X" on a
    surface.
  - Danger uses Material 3's `error*` roles. No parallel `danger` role exists without a business
    meaning distinct from `error`.
  - MemoX status and semantic colours (`status-new`, `status-learning`, `status-reviewing`,
    `status-mastered`, `success`, `warning`, `info`, `mastery`) are `DESIGN.md` extensions on
    the same model: `role → onRole → roleContainer → onRoleContainer`, but only the members
    that a real consumer uses. No `status-*-ink` is generated.
  - `streak` is a fill-only extension. It gets no text counterpart until a consumer exists.
  - `primaryFixed*`, `secondaryFixed*` and `tertiaryFixed*` are recomputed from the new palette.
  - A role that fails contrast is fixed in the role or the palette. No `*Ink` patches it.
  - Generated values are never edited by hand. The prose of "The Ink Is Not The Fill Rule" is
    rewritten for the new model: no fill and ink palettes, only a semantic role on its right
    ground.
  - If Impeccable proposes a different colour for taste alone, while the roles meet `DESIGN.md`
    and contrast, the role value does not change.
- **A3 — Single source for colour.**
  - Every light and dark colour value lives in the `DESIGN.md` frontmatter: `primary`,
    `primary-dark`, `on-primary`, `on-primary-dark`, and so on.
  - `.impeccable/design.json` never duplicates a colour value. Its `extensions` hold only
    metadata that the Stitch schema cannot: shadows and effects, motion, breakpoints, opacity,
    contrast consumer pairs, and generator or audit metadata.
  - When a sidecar entry becomes a canonical token, it moves into `DESIGN.md`. It is never kept
    in two places.
- **A4 — Classification rule.** The number of consuming domains is a signal of reuse, not a
  rule for promotion:
  1. A **generic visual contract** goes to SP3a when canonical screen specs in two or more
     domains need it.
  2. A **product-semantic contract** (mastery, workload, a deck, a study session) goes to the
     phase of its first real consumer, even when several domains reuse it later.
  3. A generic contract with one consumer domain is catalogued `planned` and built by its first
     consumer.
  4. Every known component is in the catalog, built or not. Deferring a build never drops a
     component from the catalog.
- **A5 — Naming.**
  - `Mx*` means the MemoX design-system UI vocabulary. It does not cover every reusable widget.
  - A product-semantic or feature component carries no `Mx` prefix: `MasteryDonut`,
    `MasteryRamp`, `WorkloadBreakdownLine`, `DeckPickerSheet`, `StudyTopBar`, `OutcomeTile`,
    `StudyCtaRow`, `SessionFooterHint`.
  - `DESIGN.md` names the public component API, and code follows it. A rename is proposed,
    reviewed, applied to `DESIGN.md` first, then to the catalog and specs, and only then to
    code. No alias is kept for an old name: no `typedef MxField = MxTextField`.
  - Separate contracts stay separate components: `MxSpinner` and `MxSkeleton`, `MxChipTrigger`
    and `MxFilterChip`.
  - `MxAppShell` is renamed `MxScreenScaffold` (proposed here; A5's rename order applies in
    Phase 1). It is a visual screen frame with an app-bar slot, one scroll or content region, a
    footer slot and a FAB slot. It is not the application navigation shell, and it knows no
    tab, router, destination or navigation state.
  - `MxBreadcrumb` takes presentation-neutral items only: label, current or enabled state,
    `onTap` and semantics. It knows no deck, ancestor, repository or route. A feature maps its
    own data into items.
- **A6 — Component catalog.** `DESIGN.md §Components` is the canonical catalog (schema in §4).
  No other store holds it. The WBS and this spec only refer to component names.
- **A7 — Golden namespaces.**
  - Screen goldens: `scr_<screen-id>__<state>__<variant>.png`, which resolve to a state in a
    screen spec (R16 of the [UI docs spec](2026-10-04-ui-docs-restructure-design.md)).
  - Component goldens: `mx_<component>__<state>__<variant>.png`, for example
    `mx_button__primary_enabled__light.png`. They resolve to a catalog entry.
  - The two namespaces never mix.
- **A8 — Phases.** One spec, four implementation phases, one plan per phase. Each phase runs
  through its plan, the owner's review of it, the implementation, the tests, Impeccable at its
  layer, the gate and a sign-off. A phase starts only after the previous phase is green and
  signed off.
- **A9 — Branch and PR.** All four phases share one branch and one final PR. Each phase has
  clear commit boundaries and ends with the gate green, so a reviewer can read each phase's diff
  on its own. No partial phase merges to `master`. If the branch grows too large to review, the
  work stops after a phase and the owner decides whether to split the PR.
- **A10 — Impeccable by layer.** A finding is fixed at the lowest layer that owns it: token,
  then theme, then primitive, then `Mx*`. SP3a has no screen, so it has no screen-local fix. A
  finding that changes a semantic or a token updates `DESIGN.md` first, gets reviewed, is
  regenerated, and is then implemented.

- **A11 — Approval rulings (2026-10-04).**
  - The repository holds no canonical dark palette, so Phase 1 establishes the dark set from
    the A2 model. `#AAB4FF` and `#141C66` are accepted as Phase 1 inputs once the generator
    proves their role, their contrast, full light and dark parity, and no `*Ink`. Phase 1 may
    adjust them to make the 45 roles consistent, updating `DESIGN.md` first.
  - The rename `MxAppShell` → `MxScreenScaffold` is approved, with no alias.
  - SP3a sets and builds only the `primitive` and `shared` layers. It designs no folder for a
    layer it does not build, but the catalog records every component's layer, consumers, owner
    phase and status.
  - CLAUDE.md drops the pointer to the legacy register. It only says where debt lives: in the
    screen spec's Rulings, or in the component's catalog entry.
  - Phase 1 removes the whole ink vocabulary, by meaning and not by renaming strings. That
    covers `DESIGN.md`, the 17 screen specs, both design skills, and the generator's schema and
    tests. A new `*Ink` or `*-ink` role or name makes the gate fail.
  - Phase 1 builds no `Mx*` component.

## 2. Scope

**In:**

- `DESIGN.md` structured data for both themes, the M3 mapping, the extensions and the catalog;
- the generator and its freshness, parity and contrast checks;
- `lib/core/theme/`: the generated tokens, the light and dark `ThemeData` and the component
  themes;
- `lib/shared/widgets/`: the primitives and the SP3a `Mx*` components, with widget tests and
  `mx_*` goldens;
- `check.py` support for the catalog and for `mx_*` goldens;
- wiring the new themes into `MemoxApp`. The placeholder shell is otherwise untouched, and SP3b
  deletes it.
- the documents the colour model changes: `DESIGN.md`, the screen specs that say "ink", the
  `flutter-design-system` and `flutter-theme-design` skills, and CLAUDE.md's "Known UI debt" row.

**Out:**

- the navigation shell, `MxBottomNav`, `MxNavRail`, every screen, and every product-semantic or
  feature component (SP3b, SP3c);
- any change to `domain/`, `data/`, BRs, use cases or Supabase;
- pruning ARB keys (SP3b and SP3c, screen by screen).

## 3. Phase 1 — Structured data, generator, theme

### 3.1 Structured data in `DESIGN.md`

- **Colours.** Every colour token has a light key and a `-dark` key in the frontmatter `colors`.
  - The M3 roles are the 45 non-deprecated colour roles of Flutter 3.47's `ColorScheme`. They
    are `primary`, `secondary` and `tertiary`, each with `on`, `container`, `onContainer`,
    `fixed`, `fixedDim`, `onFixed` and `onFixedVariant`; `error`, `onError`, `errorContainer`,
    `onErrorContainer`; `surface`, `onSurface`, `onSurfaceVariant`, `surfaceDim`,
    `surfaceBright`, the five `surfaceContainer*`; `outline`, `outlineVariant`, `shadow`,
    `scrim`, `inverseSurface`, `onInverseSurface` and `inversePrimary`.
  - `surfaceTint` is not a design colour. The theme pins it to transparent, so no elevation
    overlay changes a colour.
  - The deprecated `background`, `onBackground` and `surfaceVariant` are never set.
- **Extensions.** These are the A2 roles, each with only the members that a catalog consumer
  uses. Phase 1 lists each member with its consumer.
- **No paint-time alpha where the ground is known.** The derived tints of the old model (danger
  8/16 %, warning 12/18 %, success 10/18 %, the 14 % ghost border, `outlineEdge`) become solid
  roles: containers, `outlineVariant` and `outline`. Where a ground is not known, an alpha stays
  a named opacity in the sidecar.
- **Typography.** A mapping table assigns each of the 15 M3 `TextTheme` slots to a `DESIGN.md`
  role. No slot falls back to a Flutter default.
- **Values.** Phase 1 proposes the complete dark set and the new light roles in a `DESIGN.md`
  diff. The owner reviews that diff before anything is generated.
  - Light `primary` is `#4151C6` (A2). Measured: 4.94:1 on `surface-container-highest` up to
    6.53:1 on white, and 6.53:1 under white `onPrimary`.
  - Dark `primary` starts from `#AAB4FF` with `onPrimary` `#141C66`. Measured: 5.04:1 to 9.67:1
    on the dark grounds, and 7.70:1 for the pair.
  - D18 refers to a dark set proposed earlier. That set is not in this repository or this
    session, so Phase 1 proposes one here. The owner may supply the earlier values instead.
- **Prose.** The Colors section is rewritten for A2. That covers the role list, "The Ink Is Not
  The Fill Rule" and the semantic notes. The Components section takes the renames of A5 and the
  catalog of §4.

### 3.2 Generator

- **Location.** `tools/design/generate.py`, in Python like `tools/docs/`, tested with
  `unittest` and written test-first.
- **Inputs.** The `DESIGN.md` frontmatter (colours, typography, radii, spacing, component props)
  and the sidecar `extensions` (shadows, motion, breakpoints, opacity, contrast pairs).
- **Outputs.** `lib/core/theme/foundations/*.dart` (committed, never `*.g.dart`, which build_runner owns and git ignores): the light and dark `ColorScheme`, the
  extension `ThemeExtension` class with its light and dark instances, typography, radii,
  spacing, shadows, motion, opacity and breakpoints. Each file carries a do-not-edit header.
- **`--check` fails when:**
  - a role lacks its light or its dark value;
  - an M3 role is missing from the mapping;
  - an extension lacks a member that its consumer needs;
  - the generated Dart is stale;
  - the sidecar duplicates a colour value from `DESIGN.md`;
  - a colour key or extension member is named `*ink` or `*-ink` (A11);
  - a declared contrast pair falls below its threshold in either theme. The thresholds are 4.5:1
    for normal text, 3:1 for large text, and 3:1 for meaningful icons, control edges and
    progress fills against their track.
- **Gate.** `dod_check.sh` runs `generate.py --check` and the generator's tests.

### 3.3 Theme

- **Hand-written.** `lib/core/theme/app_theme.dart` builds light and dark `ThemeData` from the
  generated values: `useMaterial3`, the scheme, the `TextTheme`, the extension, `IconTheme`,
  the interaction fallbacks (splash, highlight, focus), `materialTapTargetSize: padded`,
  `visualDensity` and the scrollbar. These follow `flutter-theme-design` §I, "Foundation".
- **Component themes.** A component theme is added in the phase that builds its `Mx*`, so no
  theme slot exists without a component that uses it.
- **Parity test.** A Dart test reads the generated values and asserts that the built
  `ThemeData` carries them, in both themes.
- **Wiring.** `MemoxApp` uses the new themes with the stored theme mode.

### 3.4 Catalog and tooling

- The full catalog (§4) is written in `DESIGN.md`. Every SP3a component starts `planned`, and
  every SP3b and SP3c component is entered with its owner phase.
- `check.py` gains the catalog rules (§4.2) and the `mx_*` golden rules (§4.3). These are
  written test-first in `tools/docs/test_check.py`.

### 3.5 Documents

- The screen specs that name an ink (17 files) are reworded to the role that A2 assigns.
- The two design skills drop `primaryInk` and the legacy paths they still name.
- CLAUDE.md's "Known UI debt" row stops naming the legacy UI-base register. Screen debt lives
  in the screen spec's Rulings, and component debt lives in its catalog entry.
- The WBS gets SP3a phase rows.

### 3.6 Impeccable

Impeccable critiques the palette and the type scale against `DESIGN.md`, using the contrast
report and a rendered specimen of each theme that is not committed. Findings are handled under
A10, then the phase runs its single audit.

## 4. Component catalog

### 4.1 Schema

`DESIGN.md §Components` keeps its prose and adds one entry per component. Each entry is a fixed
list that `tools/docs` parses:

| Field | Values |
|---|---|
| Component | canonical name |
| Purpose | one line |
| Layer | `primitive` · `shared` · `app-shell` · `product-semantic` · `feature:<domain>` |
| Consumers | domains or SCR ids, from the screen specs |
| Owner phase | `SP3a` · `SP3b` · `SP3c` |
| Status | `planned` · `implementing` · `built` · `deprecated` |
| Variants | names |
| States | names |
| Accessibility | target, semantics, focus and text-scale contract |
| Tokens | the roles and tokens it reads |
| Golden | the required `<state>__<variant>` list, or `none — <reason>` |
| Replacement | for `deprecated` only |

Consumers are authored from a scan of the screen specs, because the specs do not name
components. `check.py` validates every consumer as an existing domain or SCR id, so the list
cannot point at a screen that does not exist.

### 4.2 Rules (`check.py`)

- **`planned`.** The entry exists, and code may not exist yet.
- **`implementing`.** The implementation file exists. Tests may be incomplete, as the current
  plan allows.
- **`built`.** The implementation file and its widget test exist at the paths for its layer.
  Every golden that the entry requires exists.
- **`deprecated`.** No consumer is added after deprecation, and `Replacement` names the
  successor when one exists.
- **Reference integrity.**
  - A public `Mx*` class in source that has no catalog entry is an ERROR.
  - An `Mx*` that a screen spec names but that has no catalog entry is an ERROR.
- **Placement.** A component under `lib/shared/widgets/` that is not `primitive` or `shared` is
  an ERROR, unless a promotion ruling is recorded in its entry.
- **Paths for SP3a's layers.**
  - `primitive`: `lib/shared/widgets/primitives/<snake>.dart`.
  - `shared`: `lib/shared/widgets/<snake>.dart`.
  - Each has its test at `test/shared/widgets/<snake>_test.dart`.
  - The `app-shell`, `product-semantic` and `feature:` paths are set by the SP3b spec, which
    builds the first of them. Until then those entries are `planned` only.

### 4.3 Goldens

- `check_legacy_ui` accepts both `scr_` and `mx_`. Any other prefix is still an ERROR.
- An `mx_*` golden is an ERROR when its component has no catalog entry, when its
  `<state>__<variant>` is not in the entry's Golden list, or when the entry's status is
  `planned` or `deprecated`.
- The orphan check for `scr_*` is unchanged. An `mx_*` golden that maps to an entry is never an
  orphan.
- Goldens render in the Linux container (`run_goldens.sh`). A branch that adds or changes them
  gets the `golden-compare` page before review.

### 4.4 Assignment

Each name below is a catalog entry. The entry holds the evidence and the contract.

- **SP3a, built in this sub-project** (generic, two or more domains):
  - Phase 2: the primitives (ink and press, focus ring, the 48 target, a minimum height that
    grows with text, disabled opacity); `MxButton`, `MxIconButton`, `MxFab`, `MxSpinner`,
    `MxTextField`, `MxFieldMessage`, `MxSearchField`, `MxToggle`, `MxOptionRow`,
    `MxSelectionCheckbox`, `MxStepper`, `MxSegmentedTray`, `MxFilterChip`, `MxChipTrigger`.
  - Phase 3: `MxCard`, `MxSection`, `MxNote`, `MxBadge`, `MxStatusBadge`, `MxTagChip`,
    `MxIconTile`, `MxLinearProgress`, `MxDialog`, `MxBottomSheet`, `MxSheetActions`,
    `MxSnackbar`, `MxInlineBanner`, `MxEmptyState`, `MxErrorState`, `MxSkeleton`.
  - Phase 4: `MxScreenScaffold`, `MxScreenScroll`, `MxAppBar`, `MxBreadcrumb`, `MxFooterBar`,
    `MxListRow`, `MxSettingsRow`, `MxListSectionHeader`, `MxActionSheetCommandRow`.
- **SP3b:**
  - `app-shell`: the navigation shell, `MxBottomNav`, `MxNavRail`.
  - `product-semantic` and `feature:deck`: `MasteryDonut`, `MasteryRamp` (built on
    `MxLinearProgress`), `WorkloadBreakdownLine`, `DeckPickerSheet`, the deck row and the due
    strip.
- **SP3c, `planned`** (one consumer domain, or a product semantic):
  - `shared`: `MxFloatingNotice`, `MxStatTile`, `MxStackedDayBars`, `MxActionPair`,
    `MxDashedNote`.
  - `feature:study`: `StudyTopBar`, `StudyCtaRow`, `SessionFooterHint`.
  - `feature:srs`: `OutcomeTile`.

`MxLinearProgress` knows value, tone, size and an accessibility value. It knows nothing of
mastery, due cards, workload, decks or study. Mastery is composed on top of it in SP3b.

## 5. Phases 2–4 — the component contract

Every SP3a component meets `flutter-theme-design`'s two contracts:

- **ThemeData slot.** Its theme slot is set in `app_theme.dart` in the same phase, with every
  state that applies decided: resting, pressed, focused, selected, disabled and error.
- **`Mx*` API.**
  - The API takes semantic variants only. No `Color`, `TextStyle`, `BorderRadius`, `BorderSide`,
    `BoxShadow`, `ButtonStyle`, internal padding or icon size.
  - The component guarantees a 48×48 target, RTL and semantics.
  - It does not clip at the default text scale, and no fixed height wraps text.

Each component also has:

- **A widget test** at its layer's path. It covers each state, the target size, semantics, RTL
  and both themes. It measures geometry with `getRect` where `DESIGN.md` states a size.
- **`mx_*` goldens** for the states that its entry requires, in light and dark.
- **A catalog status** that moves `planned → implementing → built` within the phase.

At the end of each phase:

- Impeccable critiques the phase's goldens against `DESIGN.md` and the catalog. Findings are
  fixed in one batch under A10, and one `impeccable audit` closes it (CLAUDE.md).
- The gate runs, the owner gets the `golden-compare` page, and the owner signs the phase off.

## 6. Order of work

1. This spec, approved by the owner.
2. **Phase 1** plan → owner approval → the `DESIGN.md` diff (values, mapping, catalog, renames)
   reviewed by the owner → generator → theme → `check.py` → documents → Impeccable → gate →
   sign-off.
3. **Phase 2** plan → … → sign-off.
4. **Phase 3** plan → … → sign-off.
5. **Phase 4** plan → … → sign-off.
6. A final whole-branch review on Opus, the `golden-compare` page for all `mx_*` goldens, then
   one PR when the owner asks.

Every step keeps `dod_check.sh` green.

## 7. Definition of done

- `DESIGN.md` holds every light and dark colour value, the M3 mapping, the extensions, the
  `TextTheme` mapping and the catalog. The sidecar duplicates no colour value.
- `generate.py --check` is green: no stale output, no missing role or variant, and every contrast
  pair passes in both themes.
- The parity test passes, and `MemoxApp` runs on the new themes.
- Every SP3a catalog entry is `built`, with its widget test and its required `mx_*` goldens.
  Every SP3b and SP3c entry is present with its owner phase.
- `check.py` and `check.py --ledger` pass, including the catalog and golden rules.
- Impeccable leaves no important finding open in any phase.
- `dod_check.sh` and `run_goldens.sh` are green.
- The owner reviewed the `golden-compare` page.
- The final whole-branch review is done, and its Critical and Important findings are fixed.
- Absent by design: the navigation shell, SCR-DECK-001, the deck row, mastery and every Library
  component (SP3b).

## 8. Risks

| Risk | Mitigation |
|---|---|
| A role meets contrast in light but fails in dark | `generate.py --check` tests every declared pair in both themes, and a failure is fixed in the role (A2) |
| The new `primary` shifts the brand look | Accepted by A2; Impeccable may not revert it for taste (A2, last point) |
| Catalog consumers go stale | `check.py` validates every consumer id; screen rebuilds update their entries |
| A component theme lands without its component, or the reverse | Each theme slot is added in the phase of its `Mx*` (§3.3); parity tests check both |
| The branch grows too large to review | A9: stop after a phase and ask the owner |
| A product-semantic component is built as `Mx*` too early | A4 and A5; the placement rule in `check.py` (§4.2) |

## 9. Handoff to SP3b

SP3b starts from:

- the generated themes in `MemoxApp`;
- every SP3a `Mx*` built;
- a catalog in which the SP3b entries are `planned`;
- the placeholder shell, which SP3b replaces with the navigation shell.

The SP3b spec sets the paths for the `app-shell`, `product-semantic` and `feature:` layers.
