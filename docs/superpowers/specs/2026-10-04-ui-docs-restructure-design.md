# MemoX V8 — Documentation restructure for the UI rebuild — design

Status: design approved 2026-10-04 (in conversation, sections 1–4); first review 2026-10-04
asked for six changes (R13–R18), applied; awaits owner review ·
Path: architectural (changes the UI source of truth, supersedes ADR-019, changes `tools/docs/`) ·
Owner rulings 2026-10-04 (§2): R1–R18

## 1. Intent

The owner will delete the Flutter UI and build it again from scratch. The reason is code debt
in the presentation layer. The visual system and the UX are kept: the rebuilt app should look
and behave like today's app unless a later spec rules otherwise.

The documentation is not ready to drive that rebuild. Two problems were named:

1. **Scattered.** One screen is described across five or six places: its UCs, their BRs,
   `features/<f>/ui.md`, `shared/ui/navigation.md`, `shared/ui/screen-handoff/NN-*.md` and
   `DESIGN.md`.
2. **Missing behaviour and invariants.** Screen records list layout and states, but not which
   control triggers which system behaviour, how each outcome is shown, or invariants that a
   test can check.

There is also a structural problem that the rebuild creates. ADR-019 makes the *app* the UI
authority: `DESIGN.md` is derived from `lib/core/theme/` and `lib/shared/widgets/`, and each
screen record (`screen-handoff/`) describes a built screen, with its goldens. Deleting the UI
removes the code, and the owner ruled that the 526 goldens go with it (R2). After that, the
documents are the only description of what the UI must be. They have to be written *before*
the code and stand on their own.

Success: a contributor or an agent can rebuild one screen by reading the screen's spec, the
FNs it invokes, `DESIGN.md` and `SCREEN_CATALOG.md`, without opening the old code. Every
relation between documents is written in one direction only, and `tools/docs/check.py`
verifies it.

### 1.1 What exists today (2026-10-04)

| Item | Count | Where |
|---|---|---|
| Use cases | 22 files, ~2,200 lines | `docs/features/<f>/usecases/` |
| Business rules | 272 files, ~7,150 lines | `docs/features/<f>/rules/`, `docs/shared/rules/` |
| Screen records | 34 (01–33 and 16a) + index, ~2,700 lines | `docs/shared/ui/screen-handoff/` |
| Feature UI notes | 9 `ui.md` | `docs/features/<f>/ui.md` |
| Domain use case classes | 89 | `lib/features/*/domain/usecases/` |
| Files in `lib/` and `test/` citing a `UC-`/`BR-` ID | 665 | — |
| Goldens | 526 PNG | `test/**/goldens/` |
| Live files citing `screen-handoff`, `shared/ui/navigation` or a feature `ui.md` | 20 | listed in §6.4 |

`depends_on` in each `features/<f>/README.md` feeds `check.py` (cycle check) and
`.claude/skills/flutter-workflow/scripts/verification_impact_map.json`.

## 2. Owner rulings (2026-10-04)

- **R1 — Why the UI is rebuilt.** Code debt only. Visual system and UX are kept.
- **R2 — Goldens.** All current goldens are deleted with the old UI. New goldens are produced
  by the rebuilt UI and reviewed again, screen by screen.
- **R3 — Shape.** Six logical document kinds: PRODUCT, USE_CASES, FUNCTIONAL_SPEC,
  SCREEN_CATALOG, SCREEN_SPEC, DESIGN. "Six kinds" is not "six physical files": each kind is
  split by its reading unit.
- **R4 — IDs are kept.** Existing `UC-<DOMAIN>-NNN` and `BR-<DOMAIN>-NNN` IDs do not change.
  The 665 code and test files that cite them are untouched.
- **R5 — Split by reading unit.** `USE_CASES.md` is one file (revisit at about 40–50 UCs or
  about 4,000 lines). FUNCTIONAL_SPEC is one file per domain. SCREEN_SPEC is one file per
  screen. Catalog, navigation and design are single files.
- **R6 — Layer boundaries.**

  | Layer | Owns | Never contains |
  |---|---|---|
  | UC | the user's goal, actor, UC-level precondition, main and alternative flow, acceptance criteria | UI detail, layout, algorithms, rules |
  | FN | one system capability: precondition, input, result, errors, the BRs that govern it | buttons, dialogs, colours, positions |
  | BR | a business rule, invariant or constraint | UI flow, screens |
  | Screen spec | controls, interaction, UI states, control → FN, FN outcome → presentation, local navigation | restated rules or FN logic |

  An FN is a unit of behaviour that a PM or QA would ask to test ("create deck", "move deck"),
  not an implementation step ("insert row", "write outbox"). Not every UC step points to an
  FN: opening a screen or typing in a field does not.
- **R7 — One direction.** Hand-written (canonical) relations are only:
  `UC → FN`, `FN → BR`, `SCREEN → FN`, `SCREEN → UC`, `SCREEN → SCREEN` (local navigation).
  Reverse relations (`FN → UC`, `FN → SCREEN`, `BR → FN`, `SCREEN → BR`, entry points, the full
  navigation graph, a feature's FN list) are generated into `docs/_generated/`.
- **R8 — `docs/features/<f>/` stays** as domain documentation: `README.md` (scope,
  terminology, `depends_on`), `rules/` (one BR per file, where it is today), `data.md`,
  `it-scenarios.md`. Only `usecases/` and `ui.md` leave it. `depends_on` keeps its current
  format (folder names).
- **R9 — Navigation.** An edge that starts at a control is written once, at that control in the
  screen spec. `NAVIGATION.md` holds application and router navigation only: root shell and
  tabs, deep links, system back and modal dismissal, guards, boot and recovery routing, and the
  master flows.
- **R10 — Screen spec template** as in §4.4. `Related Use Cases` is hand-written (it cannot be
  derived with the right meaning). `Related BR` is never written in a screen spec.
- **R11 — Language.** UC, FN and BR in Vietnamese. Screen spec, catalog and `DESIGN.md` in
  English (UI copy is written in English first). The normative part of one document does not
  mix two languages, except UI copy and technical terms.
- **R12 — PRODUCT.** The root `PRODUCT.md` (Impeccable's product record) is the only product
  document. Product semantics move there from `docs/README.md`; documentation semantics stay
  in `docs/README.md`.

Rulings from the first spec review:

- **R13 — No `UC → BR` path.** The only way from a UC to a BR is `UC → FN → BR`. A UC and a
  screen spec never cite a BR.
- **R14 — ADR-019 is kept, marked superseded.** It is not deleted or rewritten. ADR-021 is
  accepted and names it in `supersedes`.
- **R15 — `INV-UI-NNN` is for global UI invariants only.** It never restates `DESIGN.md` and never
  holds a rule that belongs to one screen.
- **R16 — State ↔ golden traceability** by a stable state key and a golden file name derived
  from it (§4.4.1).
- **R17 — `check.py`** separates ERROR from WARNING, checks every canonical reference, and
  rejects any authored reverse relation.
- **R18 — Nothing old is deleted before migration verification** proves that no information
  was lost (§7.1). This holds for the old documents and for the old UI code and goldens.

## 3. Scope and decomposition

The rebuild is three sub-projects, each with its own spec, plan and execution:

1. **This spec — documentation for the rebuild.**
2. **Delete the old UI.** Its spec fixes the scope (presentation only, or theme and shared
   widgets too). It cannot start before the migration verification of §7.1 has passed and the
   owner has signed it off (R18).
3. **Rebuild the UI**, screen by screen, through the screen workflow in `CLAUDE.md`.

Assumption carried into sub-project 2: only `presentation/` (and whatever sub-project 2 rules
on theme and shared widgets) is deleted. `domain/` and `data/` stay, so FNs can be written
against the existing domain use cases and failure types.

Out of scope here: any change to code in `lib/`, to tests, to BR content, to Supabase.

## 4. Design

### 4.1 Layout

```
PRODUCT.md                      # product source of truth (R12); Impeccable's record
DESIGN.md                       # visual system, hand-written authority (§4.7)
docs/
├── README.md                   # documentation map + conventions only
├── USE_CASES.md                # 22 UCs as sections, grouped by domain
├── NAVIGATION.md               # app/router navigation (R9)
├── functional-spec/
│   ├── README.md               # index: domain → file
│   └── <domain>.md             # FN-<DOMAIN>-NNN sections
├── screens/
│   ├── SCREEN_CATALOG.md       # every screen + invariants for every screen
│   └── spec/
│       └── SCR-<DOMAIN>-NNN-<slug>.md
├── features/<f>/
│   ├── README.md               # scope, terminology, depends_on
│   ├── rules/                  # BR-<DOMAIN>-NNN-<slug>.md, unchanged
│   ├── data.md                 # optional, unchanged
│   └── it-scenarios.md         # optional, unchanged
├── shared/                     # rules/ (BR-CORE), decisions/, data/, testing/ — unchanged
│                               # shared/ui/ is removed (§7 step 4)
├── glossary.md, wbs_*.md, superpowers/, agent/   # unchanged
└── _generated/                 # index, traceability, open questions, navigation graph
```

`DESIGN.md` and `PRODUCT.md` stay at the repo root: `CLAUDE.md`, ADR-019's successor and
Impeccable read them there.

### 4.2 PRODUCT.md

- Keep every Impeccable schema heading and the `<!-- impeccable:product-schema 1 -->`
  marker. Add `## MVP Scope` with `### Must`, `### Should`, `### Nice to have`,
  `### Out of scope`, moved from the "Sản phẩm" section of `docs/README.md` (problem, target
  users, core value, M1–M5, S1–S3, N1–N3, out of MVP).
- Classify before moving: product semantics go to `PRODUCT.md`; anything about the docs tree,
  IDs or tooling stays in `docs/README.md`.
- `PRODUCT.md` stays high level. It may name a capability; it does not cite individual UC, FN
  or BR IDs, except where the existing MVP "done when" text already cites BR IDs as evidence.
- `docs/README.md` says: "Product definition is owned by `/PRODUCT.md`. Do not duplicate
  product scope in this documentation tree." `check.py` errors if a second `PRODUCT.md`
  exists under `docs/`.
- The plan verifies against `.claude/skills/impeccable/reference/init.md` that an extra
  section is accepted by Impeccable's product record.

### 4.3 USE_CASES.md and FUNCTIONAL_SPEC

**Use case section** (one per UC, grouped under `## <Domain>`):

```markdown
### UC-DECK-001 — Tạo root deck
Status: ready · Code: [paths] · Invokes: FN-DECK-001

#### Mục tiêu / Actor / Precondition
#### Main flow          — system steps cite FN-IDs (e.g. "4. Hệ thống thực hiện FN-DECK-001.")
#### Alternative / Error flow
#### Acceptance criteria
```

- `Status` keeps today's values (`draft | ready | deprecated`); `superseded_by` when
  deprecated.
- The `rules:` frontmatter of today becomes `FN → BR`: the BRs move to the FNs the UC invokes.
  Today's `## UI` section is replaced by the screen specs. `## Local` and `## API` content
  moves into the FNs.
- The `UC → FN` relation is the `Invokes:` line; FN IDs cited in the flow must also be listed
  there (`check.py`).
- A UC never cites a BR (R13). Today's UC text cites BRs often ("scheduler thuộc root deck
  (BR-DECK-005)"); during migration each such citation is moved to the FN that the step
  invokes. A BR that governs no system action, so that no FN can carry it, is not linked to the
  UC: it is written as `> ⚠️ OPEN QUESTION:` for an owner ruling (the BR may be misplaced, or an
  FN is missing).

**FN section** (in `functional-spec/<domain>.md`, Vietnamese):

```markdown
## FN-DECK-001 — Tạo deck
Status: active · Code: [lib/features/deck/domain/usecases/…]

### Precondition
### Input
### Kết quả
### Lỗi                — failure types from the domain layer (e.g. a `*_failure.dart` case)
### Business rules     — BR-DECK-020, …   (the canonical FN → BR relation)
```

- `Status`: `draft | active | deprecated`, `superseded_by` when deprecated.
- FNs are derived from the 89 domain use case classes, the UCs and the BRs. A use case class
  that is internal plumbing (for example reconciling platform state) is not an FN unless a
  PM or QA would test it on its own. Queries a user sees ("xem danh sách deck với tiến độ") are
  FNs.
- `Lỗi` names real failure types; no new error codes are invented.
- Domain files follow the feature folders (`deck.md`, `card.md`, `study.md`, …). An FN's
  DOMAIN uses the same table as BR/UC (`study-mode` → `MODE`, `tags` → `TAG`, …).

### 4.4 Screen spec

One file per screen, `docs/screens/spec/SCR-<DOMAIN>-NNN-<slug>.md`, English:

```markdown
---
id: SCR-DECK-001
name: Library
domain: deck
status: draft | ready | built
route: [/decks, /decks/deck/:deckId]
---

# Library

## Purpose
## Related Use Cases          — hand-written (SCREEN → UC)
## Layout                     — regions by role, top to bottom; no widget class names
## States                     — one ### per state (§4.4.1): when it occurs, what it shows, Golden: line
## Controls                   — one ### per control:
                                 Type, Purpose, Enabled when (UI-only condition),
                                 Invokes: FN-…        (SCREEN → FN)
                                 #### On success — Navigate to: SCR-… (SCREEN → SCREEN) or the UI response
                                 #### On failure — <failure type> → presentation
## Responsive Behavior        — "Follows the shared floor" when nothing is screen-specific
## Accessibility              — same
## UI Invariants              — | Invariant | Enforced by |, screen-specific only
## Copy
## Rulings                    — UI decisions with date and reason
```

- No `## Navigation` section: an edge lives at its control (R9).
- No FN preconditions, inputs, rules, algorithms or persistence behaviour, and no BR ID
  anywhere in the file (R13). A screen may say how a validation failure is *shown* ("error
  below the field after Save"); the rule itself is a BR reached through the FN.
- `## UI Invariants` holds only invariants that belong to this screen. A global one is cited by
  its `INV-UI-NNN` ID, never restated (R15).
- `status: built` requires code and, for every golden-covered state, the goldens the owner
  reviewed (`golden-compare`).
- A section with nothing to say keeps its heading and says so (existing convention).
- Screens are the current 34 records (01–33 and 16a), not a new list: the UX is kept (R1).
  Where today one route serves two levels (the Library root and an open deck are one recursive
  screen) it stays one SCR. A dialog or sheet is part of its screen, not an SCR of its own,
  unless it has its own route.

#### 4.4.1 State keys and golden names (R16)

- Each state heading carries a stable **state key**: `` ### `root_loaded` · Root loaded ``.
  The key is `snake_case`, unique within the screen, and permanent like an ID: it is never
  renamed or reused. A state that is removed keeps its heading with `Status: removed`.
- Under the heading, one line declares its goldens:
  `Golden: light, dark` (the variants rendered) or `Golden: none — <reason>`.
- A golden file is named from the screen ID, the state key and the variant:
  `<scr_id>__<state_key>__<variant>.png`, the screen ID in lower `snake_case`. Example:
  `scr_deck_001__root_loaded__light.png`. Variants are `light`, `dark`, and any other the
  state declares (for example `light_text200` for a 200 % text-scale render).
- The golden lives under `test/**/goldens/`; its folder does not carry meaning. The name alone
  traces it to `SCR-DECK-001` state `root_loaded`.
- The test that renders a golden names the same key, so a failing golden points back to its
  spec state.

### 4.5 SCREEN_CATALOG.md

- Table: `ID | Screen | Domain | Route | Status | Spec`. Routes are checked against
  `lib/app/router/`.
- Section **Invariants for every screen**: `| ID | Invariant | Enforced by |`, with IDs
  `INV-UI-NNN` (permanent, like other IDs). Seeded from "Rules shared by every screen" in
  today's `00-index.md` and from behaviour invariants the rebuild must hold (text scale,
  keyboard never covers the focused field, no data lost when a save fails, the FAB never hides
  the last item, read-only differs from disabled). `Enforced by` is `—` until a test, golden or
  lint enforces it, so the gap stays visible.
- Scope (R15): an `INV-UI` is a **behaviour** that every screen must hold. It is not a visual
  value: touch targets, contrast, spacing and type stay in `DESIGN.md`, which the catalog links
  to and does not restate. It is not a screen's own rule: that stays in the screen's
  `## UI Invariants`. Each invariant is written in exactly one of these three places.

### 4.6 NAVIGATION.md

Sections: Root navigation · Shell and tabs · Back behaviour (system back, app-bar back, modal
dismiss, unsaved changes) · Deep links · Guards (account redirect, admin-only, mutation locked,
recovery) · Boot and system routing · Master flows. Content comes from today's
`docs/shared/ui/navigation.md` and the cross-screen diagrams in `features/<f>/ui.md`. Edges that
start at a control move to that control's screen spec. Diagrams cite SCR and UC IDs and restate
no flow.

### 4.7 Authority (new ADR, supersedes ADR-019)

- Order: BR, FN and UC > `DESIGN.md` > screen spec > goldens reviewed by the owner. A golden
  that disagrees with its spec is a defect in one of the two, resolved by the owner.
- `DESIGN.md` becomes a hand-written authority. It is no longer derived from code; code follows
  it. A PR that changes the visual system updates it first.
- A PR that changes a screen updates its spec and its catalog row.
- Kit v3 stays retired.
- ADR-019 is kept (R14): its frontmatter becomes `status: superseded`, `superseded_by: ADR-021`;
  its body is not changed. ADR-021 has `status: accepted`, `supersedes: [ADR-019]`.
- This extends the ADR status vocabulary in `docs/README.md` from `draft | active | deprecated`
  to `draft | accepted | superseded | deprecated`, and adds the `supersedes` field. The other 18
  ADRs that are `active` today become `accepted` in the same change (frontmatter only), so the two
  words never mean the same thing side by side. `check.py` requires `superseded_by` on a
  superseded ADR and checks that it and `supersedes` point at each other.

### 4.8 Tooling (`tools/docs/check.py`, `generate.py`)

`check.py` parses UC sections in `USE_CASES.md`, FN sections in `functional-spec/*.md`, and
screen spec frontmatter, state headings, `Golden:`, `Invokes:` and `Navigate to:` lines. It
keeps today's exit rule: any ERROR exits 1; WARNINGs are printed and do not fail (R17).

**Canonical references.** Each document kind may cite only these ID kinds; any other ID kind
in it is an ERROR.

| Document | May cite | Canonical relation it declares |
|---|---|---|
| `USE_CASES.md` | FN | `UC → FN` (`Invokes:`) |
| `functional-spec/*.md` | BR | `FN → BR` (`### Business rules`) |
| `screens/spec/*` | FN, UC, SCR, INV-UI | `SCREEN → FN`, `SCREEN → UC`, `SCREEN → SCREEN` |
| `SCREEN_CATALOG.md` | SCR | catalog rows |
| `NAVIGATION.md` | SCR, UC | router edges |
| `features/<f>/rules/*`, `README.md` | as today | as today |

**Authored reverse relations are rejected.** A section or field that states a generated
relation (`Used by`, `Related Screens` in an FN, `Related BR` in a screen, `Entry points`, a
feature's FN list, `Invoked by`) is an ERROR in a source file. Reverse relations exist only in
`_generated/`.

| ERROR (exit 1) | WARNING |
|---|---|
| ID kind not allowed in the document (table above) | active BR that no FN cites |
| cited UC/FN/BR/SCR/INV-UI ID that does not exist, or is deprecated without `superseded_by` | active FN that no UC and no screen invokes |
| FN, SCR or INV-UI ID malformed, duplicated, wrong DOMAIN, or file name ≠ `id` | `ready` UC whose FNs all have empty `Code` |
| FN cited in a UC flow but missing from its `Invokes:` line | screen state `Golden: none` on a `built` screen |
| authored reverse relation | `INV-UI` whose `Enforced by` is `—` |
| state key malformed, duplicated in its screen, or renamed (compared with git `HEAD`) | |
| `built` screen with a golden-covered state that has no matching golden file | |
| golden file under `test/**/goldens/` that matches no screen state (orphan), once the first `SCR` golden exists | |
| ADR `superseded` without `superseded_by`, or `supersedes`/`superseded_by` that do not point at each other | |
| a `PRODUCT.md` anywhere under `docs/` | |

The existing checks on `features/<f>/rules/`, `depends_on`, links and `invariant Qn` stay.
The orphan-golden check starts only when the first rebuilt golden lands, so the old goldens
do not fail it while they still exist.

`generate.py` adds to `_generated/`: `FN → UC`, `FN → SCREEN`, `BR → FN`, `SCREEN → BR` (via
FN), each screen's entry points, a feature's FN list, golden ↔ state, and the full navigation
graph (screen edges plus `NAVIGATION.md` routes). `verification_impact_map.json` is unchanged.

`test_check.py` gets a fixture for each new ERROR and WARNING.

## 5. Error handling and edge cases

- **A UC needs a BR no FN owns** (a rule about the flow itself, not a system action): no
  `UC → BR` link is made (R13). The case becomes an `OPEN QUESTION` for an owner ruling, and
  the migration ledger (§7.1) lists it as unresolved, which blocks verification until ruled.
- **A BR is enforced only in the UI** (`Enforced by: UI`): it still belongs to an FN (the FN the
  control invokes). The screen spec shows the failure; it does not restate the rule.
- **A contradiction found while migrating** (UC, BR, code and screen record disagree): not
  resolved silently. It is written as `> ⚠️ OPEN QUESTION:` at the target, as today.
- **An FN that maps to no domain use case** (behaviour that lives in a repository or a
  controller today): `Code` points to where it lives; the gap is noted for sub-project 3.

## 6. Migration impact

### 6.1 Removed

`docs/shared/ui/screen-handoff/` (index and 34 records), `docs/shared/ui/navigation.md`,
`docs/features/*/usecases/`, `docs/features/*/ui.md`, and the "Sản phẩm" section of
`docs/README.md` (moved, R12).

### 6.2 Moved without content change

None. Every moved piece changes form (UC files → sections; screen records → specs).

### 6.3 Kept unchanged

BR files and IDs, the text of ADR-001…020 (only frontmatter changes, §4.7), `shared/data/schema.md`,
`shared/testing/`, `features/<f>/data.md` and `it-scenarios.md`, `depends_on`, `glossary.md`,
`wbs_*.md`, `docs/superpowers/` (history; its links are not checked), `.impeccable/critique/`
(history).

### 6.4 Updated to point at the new homes

`CLAUDE.md` (table "Where knowledge lives"; step 1 of "A screen's workflow": read the screen
spec, its FNs, `SCREEN_CATALOG.md` and `DESIGN.md`), `PRODUCT.md`, `docs/README.md`,
`docs/agent/session-handoff.md`, `.claude/skills/flutter-workflow/SKILL.md`,
`docs/features/{starter-decks,transfer}/README.md`, `docs/wbs_BE.md`, `docs/wbs_FE.md`,
`docs/wbs_supabase.md`, `tools/docs/check.py` (its ADR-019 comment), the frontmatter of
`docs/shared/decisions/ADR-*.md` (§4.7).

## 7. Order of work

1. **Tooling, conventions, ADR-021**, proven on one domain (deck): `docs/README.md`
   conventions, `check.py`/`generate.py`/`test_check.py`, the deck FNs, the deck UCs in
   `USE_CASES.md`, and the deck screen specs. The gate passes.
2. **Remaining domains**, one at a time: FNs from the domain use cases, UCs moved into
   `USE_CASES.md` and pointed at FNs.
3. **All 34 screen specs, written from the current app** (code, goldens, today's screen
   records) **while the old UI still exists**. They end `ready`. This is the only full record
   of the UX the owner keeps (R1).
4. **Migration verification** (§7.1). The owner signs off the ledger.
5. **Retire the old homes** (§6.1) and update references (§6.4), only after step 4.
6. `PRODUCT.md` and `docs/README.md` split (§4.2) can run in parallel with step 2.

Each step ends with `python tools/docs/generate.py`, `python tools/docs/check.py` and the gate
(`dod_check.sh`). Steps may ship as separate PRs. Sub-project 2 (deleting the old UI) starts
only after step 5 is merged; before it deletes any golden, a git tag marks the last commit that
has them.

### 7.1 Migration verification (R18)

Nothing old is deleted until a **migration ledger** shows that every piece of information has a
new home or an owner-approved drop. The ledger is a table in the plan's execution ledger, one
row per source item:

| Source item | Granularity |
|---|---|
| UC file | each section (goal, precondition, each flow step, each alternative/error flow, each acceptance criterion, `## UI`, `## Local`, `## API`) |
| Screen record (`screen-handoff/NN`) | each layout region, each state row, each ruling, each copy string, each pending item |
| `features/<f>/ui.md` and `shared/ui/navigation.md` | each diagram node and edge |
| Golden PNG | each file → a screen state key and variant |
| "Sản phẩm" in `docs/README.md` | each paragraph and table row |

Each row ends in exactly one of: `moved → <new location>`, `superseded → <ID or ruling>`, or
`dropped — <reason>, approved <date>`. Verification passes when:

1. every row has an outcome and no outcome is blank or "TBD";
2. every `dropped` row carries the owner's approval;
3. no `OPEN QUESTION` raised during migration is unresolved;
4. `check.py` exits 0, `_generated/` is fresh, and the gate passes;
5. for each screen, every state of today's record and every golden of today maps to a state key
   in its spec.

The owner then signs off the ledger. Only then may step 5 and sub-project 2 delete anything.

## 8. Testing

- `tools/docs/test_check.py`: a fixture per new error and warning in §4.8.
- After each step: `generate.py` leaves `_generated/` fresh and `check.py` exits 0.
- Spot check per domain: for three FNs, the `Code` paths exist and the listed failure types
  exist in the domain layer.
- Migration completeness: the ledger and its five conditions in §7.1.
