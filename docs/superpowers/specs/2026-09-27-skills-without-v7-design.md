# MemoX V8 — The skills and documents without V7 (package 12c)

Status: approved 2026-09-27 (scope, the two V7 documents, the checklist, the pin and
design sections 1–2 in conversation, then this spec); amended during planning (§12.1–
§12.3) and during execution (§12.4) · Path: architectural

## 1. Intent

Build BE-D7 of [`docs/wbs_BE.md`](../../wbs_BE.md), with BE-D3 folded in, widened by
the owner on 2026-09-27: the skills the repo owns keep nothing of V7. Packages 12a
(BE-D5, the verification tooling) and 12b (BE-D6, the guard and the design-token hook)
removed V7 from the tools; this package removes it from the instructions the agents
read before they touch the code. The owner's words: "tao không còn muốn phụ thuộc vào
V7 bất kì thứ gì nữa", "Cả các skill trong gói này", "Chỉ bỏ V7".

Success means:

- no file of the 14 repo-owned skills (§2) names V7, cites a V7 decision (`AD-nn`),
  a V7 business rule (`BR-nn`), a V7 milestone (`M99.61`, `A20.1`, `P1-08`), V7's
  22-phase checklist, or a V7 document (`docs/wbs.md`, `docs/checklist.md`,
  `docs/architecture.md`), and none asks for a Widgetbook catalog or V7's
  `test/demo/` goldens; what they cite is V8's (§4);
- a contract test in the gate pins that, so a later edit cannot bring V7 back
  unnoticed (§7);
- `feature_blueprint.md`, `phase-index.md`, the two screen-gallery scripts and the
  `project-documentation` install receipt are gone; `project-baseline.md` describes
  V8's database as it stands;
- BE-D3's two drifts are fixed: `host-coverage-map.md` no longer says V8 has no tests,
  and `flutter-workflow` no longer points at `docs/wbs.md`;
- `CLAUDE.md`, the V7 provenance recorded in `docs/`, and the vendored skills are
  unchanged (§10).

## 2. Context (2026-09-27)

- `master` is at `dc9303f` (#102).
- **The repo-owned skills** are the 13 `flutter-*` skills (`flutter-architecture`,
  `flutter-data-layer`, `flutter-design-system`, `flutter-drift`,
  `flutter-feature-slice`, `flutter-navigation`, `flutter-product-spec`,
  `flutter-project-setup`, `flutter-ship`, `flutter-state-riverpod`,
  `flutter-testing`, `flutter-theme-design`, `flutter-workflow`) and
  `project-documentation`. Every other directory under `.claude/skills/` is vendored
  (ECC per `CLAUDE.md`, Superpowers, Impeccable) and is not the repo's to edit.
- **The survey.** A scan of the 14 skills for the markers of §7 finds 208 lines in 44
  files. By kind:
  - V7 decisions `AD-01`…`AD-23` (68 citations), often as `(AD-05 in
    docs/architecture.md)`;
  - V7 business rules `BR-04`…`BR-231` (about 35 citations), 22 of them in the two
    gallery scripts and the blueprint;
  - V7 milestones and audit items (`M99.61`, `M100.34`, `A20.1 P1-08`, `M2.2`), mostly
    in `flutter-theme-design`'s Vietnamese references and in script comments;
  - V7's 22-phase checklist: `flutter-workflow` routes by it (`docs/checklist.md`,
    the "Checklist phase" column, `references/phase-index.md`), and nine skills open
    with "Covers checklist Phase N" or cite "(Phase 15.4)";
  - V7's documents: `docs/wbs.md` (the ledger in `flutter-workflow`, the Definition
    of Done, `flutter-feature-slice`, `flutter-drift`, `flutter-ship`,
    `flutter-state-riverpod`, `flutter-architecture`), `docs/architecture.md`
    (`flutter-data-layer`, `flutter-product-spec`, `flutter-project-setup`,
    `flutter-drift`). Neither exists in V8;
  - Widgetbook: the Definition of Done, `flutter-feature-slice` (SKILL and checklist)
    and `flutter-design-system` ask for a catalog entry in `widgetbook/`. V8 has no
    `widgetbook/`;
  - V7 by name: `flutter-workflow`'s description ("work starts on memox-v7"),
    `flutter-drift` ("memox-v7 is not greenfield"), `flutter-feature-slice` ("V7's
    `features/deck` slice").
- **Two documents describe V7's code.**
  `flutter-feature-slice/assets/feature_blueprint.md` (1233 lines) records V7's
  `features/deck` and `features/card`, including a presentation layer V8 has not built;
  it opens with a "V7 reference" banner. `flutter-drift/references/project-baseline.md`
  (179 lines) records "what memox-v7 has already settled" for Drift, and
  `flutter-drift` tells the agent to read it before any structural change. ADR-010
  decision 2 links it; ADR-011's "Hệ quả" calls both "tài liệu tham khảo V7".
- **Two tools are V7's.** `flutter-testing/scripts/build_screen_gallery.py` (710 lines)
  builds a page from `test/demo/`, which V8 does not have, and lists V7's screens and
  rules; `splice_screen_gallery.py` merges two of its pages. Nothing else calls them.
- **The install receipt.** `project-documentation/.installation.json` records its
  canonical source as `C:\Users\ntgpt\.codex\worktrees\616d\memox-v7\.agents\skills\project-documentation`.
  Without a receipt, `skill_distribution.py inspect` treats the copy it inspects as
  canonical (`scope: canonical`, `managed: false`).
- **BE-D3.** `docs/shared/testing/host-coverage-map.md` opens "V8 chưa có test nào";
  V8 has had host tests since the foundation, and the gate ran 2281 on `dc9303f`.
- **The Definition of Done** already asks that a new or updated golden be compared,
  state by state, with the concept or canonical reference; the Widgetbook line beside
  it is what V8 cannot do.
- **The gate** runs `python -m unittest discover` over
  `.claude/skills/flutter-workflow/scripts/tests` as its "CI tooling tests" step (66
  tests on `dc9303f`).
- **Outside the skills, "V7" also appears** in `lib/` and `test/` as FE ruling ids
  (`F1–F4, V1, V4, V6, V7, V10` of FE-A6), in `.github/workflows/` as action versions
  (`actions/checkout@v7`), in five `docs/` files as provenance, and in `CLAUDE.md`'s
  "V7 is a reference, not a template". None is MemoX V7 as a dependency except the
  last two, which the owner keeps (§10).

## 3. Decisions

| # | Decision | Choice |
|---|---|---|
| D1 | Scope | The 14 repo-owned skills, cleaned of every V7 marker of §7, plus BE-D3 (owner, 2026-09-27: "Sạch hẳn V7") |
| D2 | How a marker goes | Each one takes one disposition (§4): point at V8's source, state the reason in place, or remove what only V7 needed |
| D3 | `project-baseline.md` | Rewritten as V8's baseline, checked against `lib/core/database/`, `docs/shared/data/schema.md` and the ADRs (owner) |
| D4 | `feature_blueprint.md` | Removed; `flutter-feature-slice` keeps the method and points at V8's `lib/features/deck` and `lib/features/card` (owner) |
| D5 | The 22-phase checklist | Gone: `flutter-workflow` routes by topic, `phase-index.md` is removed, and no skill cites a phase; the dependency order stays as the skill's own text (owner) |
| D6 | The progress ledger | `docs/wbs_BE.md`, `docs/wbs_FE.md`, and a screen's row in the screen handoff index |
| D7 | Widgetbook | Removed from the Definition of Done and the skills; the golden-parity item already in the Definition of Done is V8's check |
| D8 | The screen-gallery scripts | Removed |
| D9 | The install receipt | Removed; V8's copy of `project-documentation` is its canonical source. The payload and `skill-manifest.json` are unchanged |
| D10 | The pin | A contract test in the CI tooling tests (§7), not a guard rule: the guard checks the app, not the agents' instructions (owner) |

## 4. Dispositions

Every marker of §7 in the 14 skills takes exactly one:

- **(a) V8's source.** The citation moves to the V8 document that holds the same
  decision or rule: an ADR in `docs/shared/decisions/`, a `BR-<AREA>-NNN` or
  `UC-<AREA>-NNN` in `docs/features/`, the WBS files, or V8's code.
- **(b) The reason in place.** When V8 has no document for it, the sentence states the
  reason itself and drops the number.
- **(c) Removed.** Text that only V7 needed (a V7 incident, a milestone, a catalog V8
  does not have) goes, together with any sentence that exists only to explain it.

History goes: "until M99.2…", "(bug thật, M99.61)", "Đã ship (M99.66)" lose the
milestone; the lesson stays when it still holds for V8, as a plain statement.

### 4.1 V7 decisions

| V7 | What it said | V8 |
|---|---|---|
| AD-01, AD-05 | Local-only; no network, no `dio` | ADR-001 ("Data posture: local-only, không network") |
| AD-03 | No authentication yet | ADR-001 ("Authentication: chưa có auth") |
| AD-03 | Client-generated UUID keys | ADR-007 |
| AD-04 | The Web build is the E2E channel | ADR-001 (the Web row) |
| AD-08 | One place opens the database; no content in any log | ADR-002 |
| AD-11 | (cited only in `feature_blueprint.md`) | removed with it |
| AD-12 | One use case per interaction | ADR-011 D4 (and D5: no exception) |
| AD-13 | A layer's own code may reach outside it (`check_drift.py`, the feature checklist) | ADR-011 when it states the same rule, else (b) |
| AD-15 | Four widget buckets, one level deep | ADR-011 D8 |
| AD-17 | A feature's data shape is not a template | (b) |
| AD-18 | Pure rules under `domain/models/` | ADR-011 D7 |
| AD-02, AD-23 | `.drift` files; surface recipes by meaning | (b) |

`docs/architecture.md` as the place to record a decision becomes
`docs/shared/decisions/` (an ADR), per `CLAUDE.md`'s "Where knowledge lives".

### 4.2 V7 business rules

A `BR-nn` cited as the reason for a rule becomes the V8 rule that says the same thing
when one exists (for example, "first child fixes the deck's content type" is V8's
ADR-006 and the deck rules under `docs/features/deck/rules/`); otherwise the sentence
states the rule in words (b). The examples in `flutter-product-spec` and its
`business_rules_template.md` use V8's numbering, `BR-<AREA>-NNN`.

### 4.3 Per skill

- **`flutter-workflow`.**
  - The description drops "memox-v7" and the checklist.
  - The routing table keeps "you are doing → load skill" and loses the phase column.
  - The first step reads `docs/wbs_BE.md` and `docs/wbs_FE.md`.
  - "Keeping the ledger honest" names the two WBS files and the screen handoff index.
  - The worked examples are V8's `lib/features/deck/README.md` and
    `lib/features/card/README.md`.
  - `references/phase-index.md` is removed.
  - The Definition of Done loses the Widgetbook item and names the WBS files.
  - `check_flutter_version.sh` states its reason without V7's milestones.
- **`flutter-feature-slice`.**
  - `assets/feature_blueprint.md` is removed.
  - SKILL.md keeps the method: layering, where a rule is enforced, what a use case may
    know, which test sits at which level, and what does not transfer between features.
  - Its examples are V8's deck and card slices.
  - The checklist (`assets/feature_checklist.md`) and the SKILL's own list lose
    Widgetbook and `docs/wbs.md`.
- **`flutter-design-system`.** The Widgetbook paragraph goes. "(Phase 15.4)" becomes
  "golden light and dark, per `flutter-testing`".
- **`flutter-drift`.**
  - `references/project-baseline.md` is rewritten as "What V8's database has settled",
    from V8's `lib/core/database/`, `schema.md` and ADR-001, 002, 007, 008 and 011.
    Each claim is checked against the code: the layout, the connection, identity and
    time, reads and pagination, what the schema does not do, and executable
    invariants.
  - SKILL.md and the references drop "memox-v7", `AD-nn` and `BR-nn` per §4.1–4.2.
  - `check_drift.py` cites ADR-002 and ADR-010/011.
- **`flutter-testing`.**
  - `scripts/build_screen_gallery.py` and `scripts/splice_screen_gallery.py` are
    removed.
  - `golden.Dockerfile` explains the Linux renderer without V7's milestones.
  - SKILL.md and `integration-test-harness.md` cite V8's rules.
- **`flutter-architecture`.**
  - SKILL.md cites ADR-011 D4, D7 and D8 without the AD numbers.
  - `check_architecture.py` states why `domain/models/` exists (ADR-011 D7).
  - `analysis_options.yaml` and SKILL.md drop the `docs/wbs.md` pointer; the
    descoping of `custom_lint` is stated in place.
- **`flutter-product-spec`.**
  - The documentation table names V8's files: the two WBS files, `shared/decisions/`,
    and `features/<f>/api.md` for an API.
  - `assets/wbs_template.md` is removed: it is V7's milestone format; V8's WBS files
    are the format.
  - `business_rules_template.md` uses `BR-<AREA>-NNN`.
- **`project-documentation`.** `.installation.json` is removed.
- **`flutter-theme-design`, `flutter-data-layer`, `flutter-navigation`,
  `flutter-state-riverpod`, `flutter-project-setup`, `flutter-ship`.** Per §4.1–4.2.
  Each loses "Covers checklist Phase N", milestones and `docs/wbs.md` /
  `docs/architecture.md`.

## 5. BE-D3

- `host-coverage-map.md` opens by saying what the table is (a map from each scenario
  to its execution profile and its UC/BR), without "V8 chưa có test nào" and without a
  test count that would drift.
- The `flutter-workflow` pointer to `docs/wbs.md` is §4.3's.

## 6. Documents

- ADR-011, "Hệ quả": the blueprint is removed, the baseline describes V8, and the
  remaining V7 references in the skills are gone (BE-D7). ADR-010's link to
  `project-baseline.md` still resolves.
- `docs/wbs_BE.md`: BE-D7 and BE-D3 move to "Đã xong" with this spec and plan; "Bước
  tiếp theo" is BE-B5b; an update entry for 2026-09-27.
- `docs/_generated/` regenerated by the docs tooling.

## 7. The contract test

`.claude/skills/flutter-workflow/scripts/tests/test_skills_without_v7.py`, a `unittest`
module, run by the gate's "CI tooling tests" step:

- `REPO_OWNED_SKILLS`: the 14 directory names of §2, listed explicitly. A test asserts
  each exists under `.claude/skills/`.
- `V7_MARKERS`:

  | Marker | Pattern |
  |---|---|
  | MemoX V7 by name | `(?i)memox[-_ ]v7`, `(?i)\bv7\b` |
  | V7 decisions and rules | `\bAD-\d`, `\bBR-\d` |
  | V7 milestones and audit items | `\bM\d+\.\d+\b`, `A20\.1`, `\bP[1-3]-\d\d\b` |
  | V7's checklist | `(?i)\bphase \d`, `docs/checklist\.md` |
  | V7's documents | `docs/wbs\.md`, `docs/architecture\.md` |
  | V7's catalog and goldens | `(?i)widgetbook`, `test/demo` |
  | Removed files | `feature_blueprint`, `phase-index`, `screen_gallery` |

- The main test walks every file of the 14 skills except `tests/` and `__pycache__/`
  directories, reads it as UTF-8, and fails with one `path:line: text` per match.
  `tests/` is excluded because the CI tooling tests themselves assert that Widgetbook
  and `memox-api` are absent.
- A second test asserts `project-documentation/.installation.json` does not exist.
- Written first, it fails on `dc9303f` with the §2 survey. When a pattern matches V8
  text that is not V7 (for example Material's `M3`), the plan narrows the pattern and
  records why; there is no allowlist.

## 8. Verification

- The contract test fails before the cleanup, then passes after.
- The gate (`dod_check.sh`) passes after every task: CI tooling tests (66 plus the
  new ones), hook tests, guard tests, the guard on the tree, host tests, the docs check
  with 0 errors.
- `python .claude/skills/project-documentation/scripts/skill_distribution.py inspect
  --root . --active .claude/skills/project-documentation` reports `scope: canonical`
  and no integrity error.
- A repo-wide search for `feature_blueprint`, `phase-index`, `screen_gallery` and
  `.installation.json` finds only the history under `docs/superpowers/`.
- Every relative link in the changed skills resolves to an existing file.

## 9. Order

The plan cuts the work so that each task leaves the gate green: the contract test
first (its failing list is the work list), then the `flutter-workflow` routing and
the Definition of Done, then the removed files and their pointers, then the rewritten
baseline, then the remaining skills, then the documents. The test turns green in the
last skill task.

## 10. Out of scope

- `CLAUDE.md`, including "V7 is a reference, not a template", which is a project rule
  about preserving V7's business behavior.
- V7 provenance recorded in `docs/` (five files outside `docs/superpowers/`) and the
  specs and plans under `docs/superpowers/`, which are the record of their day.
- The vendored skills under `.claude/skills/`.
- `lib/`, `test/` and `.github/`: their "V7" is an FE ruling id or an action version.
- A Widgetbook catalog or a screen gallery for V8: a product decision, not this
  package's.

## 11. Risks and rollback

- **A rewritten baseline states something V8 does not do.** Each claim is checked
  against the code during the prototype, and the final review reads it against
  `lib/core/database/`.
- **Removing the blueprint loses guidance the next FE package wanted.** The method
  stays in `flutter-feature-slice`; the presentation half returns with the FE
  packages, from V8's own screens. The file stays in git history.
- **A marker pattern catches V8 text.** Narrow the pattern and record why (§7).
- **Rollback:** revert the squash commit; the package changes only skills, one test
  file and documents.

## 12. Amendments (2026-09-27, during planning)

Planning ran on `master` as it moved, after the approval above. What follows amends
§2–§10: the owner's decisions came through the popup; the rest are rulings the
prototype needed, each with its reason.

### 12.1 `master` moved: ADR-012 and ADR-013

`master` moved to `3f78fb6` (#103–#109), and the branch merged it (`5792aa1`). Two
ADRs arrived that change §4.1:

- ADR-012 (the app calls APIs through Retrofit on one shared Dio) says it replaces
  AD-05. `dio`, `retrofit` and `json_annotation` arrive with the first API call; DTOs
  are `json_serializable`, never Freezed.
- ADR-013 (the server is canonical; the app is offline-first and syncs) replaces
  ADR-001's Data posture and Authentication rows and "Drift is the source of truth".

| V7 | What it said | V8 |
|---|---|---|
| AD-01 | Local-first; sync deferred | ADR-013 |
| AD-03 | No authentication yet | ADR-013 (identity now, login later) |
| AD-05 | No network, no `dio` | ADR-012 |

ADR-001 keeps the rows still in force: the platforms, and the Web build as the E2E
channel.

A skill does not cite a superseded row as if it held. A sentence that said
"local-only (ADR-001)", "no auth (ADR-001)" or "Drift is the source of truth" now
follows ADR-012 or ADR-013, and so does the V7 guidance next to it that ADR-013
contradicts: the sync flow that flagged rows `isPendingSync`, the cache table that put
a TTL on decks, the repository example that read the network first. The package does
not write the sync or network guidance ADR-013's roadmap will need; that comes with
the slices that build sync.

### 12.2 The owner's decisions after approval

- **The eight lines of `lib/` and `test/` that cite AD-12 and AD-15** (two
  controllers, three use-case tests, `boundary_rules.dart` and a test name) cite
  ADR-011 D4 and D8, in the `flutter-architecture` task; `boundary_rules.dart`'s
  message changes with them. The contract test still scans skills only. This narrows
  §10's "`lib/`, `test/` and `.github/`".
- **Cited paths are pinned.** Every path in backticks that a repo-owned skill cites
  under `lib/`, `test/`, `docs/`, `tools/` or `integration_test/`, or under its own
  `assets/`, `references/` or `scripts/`, exists. A placeholder (`<feature>`, `*`, `…`,
  `{…}`, `$…`) names no file, and generated output (`*.g.dart`, `/generated/`) is not
  in a fresh checkout, so neither is checked.
- **`flutter-theme-design`** loses what is V7's: milestones, history, and the
  "Đã ship" claims about APIs or widgets V8 does not have. Its contract checklists and
  the `[x]` rules that still hold stay. Reconciling the skill with V8's
  `lib/core/theme/`, `lib/shared/widgets/` and the design handoff is FE-D4 in
  `wbs_FE.md`, done with the first FE package that touches the design system.

### 12.3 Rulings

- **The repo-owned skills are 15.** §2 missed `spring-boot-mybatis-review`, which
  `CLAUDE.md` names among the repo's rules. It cites nothing of V7 and joins
  `REPO_OWNED_SKILLS`. `VENDORED_SKILLS` names the other 35 directories (ECC,
  Superpowers, Impeccable), and a test pins that every directory under
  `.claude/skills/` is in one list or the other, so no skill leaves the scan unnoticed.
- **The contract test grows task by task.** §9 has it written first and green only
  after the last skill task. Each task instead adds the skills it cleans, so the gate
  stays green after every task and each red run lists exactly that task's work.
- **The markers widen** beyond §7's table, each for a V7 trace the table missed:
  `\bM\d+\.\d+[a-z]*\b` and `\bM\d+ R\d+\b` (a milestone with a letter suffix, a
  review round), `(?i)\bphases? \d` (the plural "Phases 4 and 5"),
  `docs/api-spec\.md`, and names V8 does not have: `card_review_states`,
  `review_history`, `parent_deck_id`, `root_deck_id`, `SurfaceColumnRule`.
- **V7 without a marker goes too** where it contradicts V8: V7's "due" (without
  `learned_at`), the emptied deck, V7's error model (a `Failure` per kind, a
  `ValidationFailure` with a set of problems) where ADR-011 D6 holds, dependency
  tables that were not V8's `pubspec.yaml`, the `@freezed` state example, generated
  code said to be committed, and the reference `analysis_options.yaml` claiming to be
  the root's copy. Names that only illustrate (`deck.dart` as a counterexample,
  `dio_error_mapper.dart`) stay, unpinned.
- **Two more V7 documents go:** `flutter-testing/references/integration-test-harness.md`
  (V7's `integration_test/` harness; its three defect classes move into the skill),
  and `flutter-product-spec/assets/wbs_template.md`, which §4.3 already removes.
- **§4.3's worked examples** are `lib/features/deck/` and `lib/features/card/`: the
  two READMEs it names do not exist.
- **§8's search** for the removed files also finds the contract test's markers,
  `skill_distribution.py`'s receipt constant (the code that reads a receipt, not one),
  and the record of the removal in ADR-011 and `wbs_BE.md`.
- **Counts on the new base:** the CI tooling tests are 67 at `5792aa1` (§2's 66 and
  the `api` job's test from #104), then 71, 73, 74 and 76; the host tests are 2349.

### 12.4 `master` moved again, during execution: ADR-014 and the deck sync slice

While the package ran, `master` took #110–#116: the deck sync slices on the server
(#110) and in the app (#114), ADR-014, BE-C5, BE-C2 and deck mastery. The branch
merged it. ADR-014 replaces ADR-013's rows #1 (in part), #2, #4 (push), #5 and #8: the
outbox pushes commands and field patches in order, "the operation the server receives
last wins" holds for patches only, and the server is canonical for SRS. #114 added
`dio`, `retrofit`, `json_annotation` and `connectivity_plus` to `pubspec.yaml`, with
`lib/core/network/`, `lib/core/sync/` and `sync.drift`; BE-C5 added `unorm_dart`.

About 25 lines the package had written against `3f78fb6` became false: "no API call
yet", "sync is not built", "the outbox keeps one entry per entity", "the app
recomputes the schedule and the server runs no scheduler". The owner decided on
2026-09-27, through the popup, to correct them in this package (Task 8), under §12.1's
rule:

- a skill states what exists now, and names where it lives;
- it cites ADR-014 where ADR-014 replaced an ADR-013 row, instead of restating either
  ADR's protocol;
- it writes no new sync guidance: that comes with BE-E2…BE-E7 in `wbs_BE.md`.

`flutter-project-setup`'s dependency table said it was `pubspec.yaml` as it stands,
and nothing checked it. `test_skill_dependency_table.py`, beside the contract test,
now does: every package in `pubspec.yaml` has a row, every row names one, and no
package waits in "Add only when" for a need it already has. It failed first with the
seven packages the table lacked. The CI tooling tests are then 80, and the host tests
2429 on the merged base.

The final review found two more leftovers no marker can see: `networking.md` still
mapped `DioException` to V7's `Failure` per error kind, and a sentence in
`dynamic-sql-semantics.md` stated ADR-013's superseded conflict row. Both now follow
ADR-011 D6 and ADR-014, and the contract test also checks that every `…Failure` a
skill names is defined in `lib/core/error/failure.dart`; the CI tooling tests are 82.

A ruling from execution: `flutter-navigation`'s description deferred route guards "until
auth lands, ADR-001", which cites the Authentication row ADR-013 replaced; it cites
ADR-013 instead, as the skill's body does.
