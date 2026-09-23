# MemoX V8 — Folder architecture design

Status: approved 2026-09-23 · amended while writing the plan (§6.3 table, §8 items 3
and 5, §9 item 4 and the rule count in its follow-up list) · Path: architectural

## 1. Intent

No document that V8 owns states its folder layout.
[ADR-010](../../shared/decisions/ADR-010-kien-truc-lop-v8-va-tooling.md) decision 2
adopts "the layer structure the tooling assumes, described in the
[`flutter-architecture`](../../../.claude/skills/flutter-architecture/SKILL.md) skill".
That skill, and the skills around it (`flutter-feature-slice` and its blueprint,
`flutter-drift/references/project-baseline.md`, `flutter-testing`,
`flutter-project-setup`), describe memox-v7 as built. They cite V7 documents that do
not exist here: `docs/architecture.md` for AD-12 and AD-15, `docs/wbs.md`, and
`--ruleset memox-v7`. The revised [foundation plan](../plans/2026-09-23-memox-v8-foundation.md)
then chose a flat `domain/` and a barrel per feature. The tooling that ADR-010 meant to
keep working rejects both (§2).

This spec fixes one folder architecture for V8 and records it in a new ADR-011. After
it, the ADR, the skills, the tooling (code-verification guard `memox-v8`,
`check_architecture.py`, `build_verification_plan.py` and its CI tests,
`test/architecture/boundaries_test.dart`) and the foundation plan say the same thing.

**Success:**

- After the change, the phased gate of §8 passes on the repository.
- A stub tree of the revised foundation layout (§10) passes the guard `memox-v8` with
  0 errors, `check_architecture.py` with exit 0, and the known-layer CI test.
- ADR-011 exists, and the skills cite it for the folder layout, AD-12 and AD-15 instead
  of V7 documents.
- The foundation plan's File Structure, task paths and verification gate follow this
  spec before its Task 2 runs.
- Every rule added to `boundaries_test.dart` and `check_architecture.py` is shown to
  fail on a planted violation.

## 2. Evidence (2026-09-23)

Stub trees were built in a scratch directory and run through the repository's own
gates. The stubs carry real file names and paths but placeholder contents, so only
name and path rules were exercised. The repository was not modified.

| Gate | Foundation plan layout (flat `domain/`, barrels) | Layout of this spec |
|---|---|---|
| Guard `memox-v8` | 11 × ERROR `memox.naming.domain_file_role_suffix` (`deck.dart`, `deck_rules.dart`, `sm2.dart`, …) | 0 errors |
| `test_every_feature_source_uses_a_known_top_level_layer` (`test_ci_tooling.py:772`, logic replicated) | fails on the three barrels | passes |
| `check_architecture.py` | `zero scope: presentation` | `zero scope: presentation`, addressed in §8 |
| Planner, change to the deck entity | `deck/domain/deck.dart` selects `deck` only | `deck/domain/entities/deck_entity.dart` selects all 13 features |
| Planner, change to a barrel | full suite, "feature source path has no recognised layer" | not applicable |

The plan has two more problems:

- Its Clarification 3 has the barrel re-export the `di/` provider. A dependent
  feature's `domain/` would then reach Riverpod and Drift transitively.
  `boundaries_test.dart` checks direct imports only, so it would not see this.
- Its Task 2 puts every feature's rejection reasons into one `enum Rejection` in
  `lib/core/outcome.dart` (plan line 568). That gives `core/` business knowledge.

`dod_check.sh --force` on the current tree fails three gates because there is no code
yet:

- `generated`: no code generation exists yet.
- `architecture`: five zero scopes.
- `guard`: 0 errors and 41 warnings. The `memox-v8` profile, copied from V7, sets
  `warning_as_error: true`.

Format, analyze, docs, the CI tooling tests, the guard self-tests and `flutter test`
pass. The foundation plan gates only on `flutter analyze` and `flutter test`, so none
of the problems above showed up.

## 3. Decisions

Chosen by the project owner on 2026-09-23.

| # | Topic | Decision | Rejected |
|---|---|---|---|
| D1 | Inside a feature | The buckets and file suffixes the tooling enforces (§5). A folder exists only once it holds a real file | flat `domain/` with barrels; scaffolding the whole V7 tree |
| D2 | Feature dependencies | Two graphs. Docs `depends_on` stays the data direction used for verification. The Dart import map is the contract direction, acyclic, with `srs` at the base (§6.3) | rewriting `depends_on` to the contract direction; forcing the code onto the docs DAG |
| D3 | Public surface | Import `domain/{entities,models,repositories,failures}` directly; no barrels | a barrel that re-exports domain only |
| D4 | Use cases | AD-12 ratified: in a feature with a UI, every interaction goes through its own use case, thin ones included | a use case only when it holds logic |
| D5 | AD-12 exceptions | None, settings included | exemptions listed in the ADR |
| D6 | Rejection reasons | One enum per feature in `domain/failures/`; `Outcome` in `core/error/` is generic | one `Rejection` enum in `core/` |
| D7 | Pure business rules | Members of the entity, or of a value object in `domain/models/`; reasons in `domain/failures/` | a new `domain/rules/` bucket |
| D8 | Widget folders | AD-15 ratified: `widgets/{sections,items,overlays,support}/`, one level deep | deciding in the UI sub-project |
| D9 | Record | A new ADR-011 that refines ADR-010 decision 2; ADR-010 stays and points to it | editing ADR-010 |
| D10 | Verification gate | Phased (§8) | the full `dod_check.sh` now; `flutter analyze` and `flutter test` only |
| D11 | `lib/core/` | One folder per concern | flat files for small primitives |
| D12 | Shared test infrastructure | `test/support/` | `test/helpers/` |

## 4. Target structure

The tree shows where things go, not what to create. A folder appears with its first
real file (D1, §5).

```
lib/
├── main.dart                 ProviderScope + runApp, nothing else
├── app/                      composition root: MemoxApp, retry policy
│   └── router/               app_router.dart; route paths and shell come with the UI
├── core/                     infrastructure that knows no feature
│   ├── database/             connection.dart (the only file that opens a DB),
│   │   │                     app_database.dart, di/database_provider.dart
│   │   ├── tables/           *.drift
│   │   └── queries/          *.drift, from the first named query
│   ├── error/                failure.dart, outcome.dart
│   └── id/                   new_id.dart (client UUID, ADR-007)
├── l10n/                     app_en.arb, app_vi.arb, from the first UI string
├── shared/
│   └── widgets/              Mx* components, from the design-system sub-project
└── features/<f>/             <f> from ADR-010 decision 1
    ├── domain/               plain Dart
    │   ├── entities/
    │   ├── models/
    │   ├── repositories/
    │   ├── failures/
    │   └── usecases/
    ├── data/
    │   ├── datasources/
    │   ├── mappers/
    │   ├── repositories/
    │   └── models/
    ├── di/
    └── presentation/
        ├── screens/
        ├── controllers/
        ├── states/
        ├── providers/
        └── widgets/{sections,items,overlays,support}/

test/
├── architecture/             boundaries_test.dart
├── app/                      once app/ has behaviour (router, bootstrap)
├── core/<concern>/           mirrors lib/core/<concern>/
├── database/                 schema-wide: schema, migration, invariants
├── integration/              cross-feature flows on real SQLite
├── features/<f>/<layer>/     mirrors lib/features; the planner selects by this path
│   └── support/              feature-local fakes, when needed
└── support/                  shared: test_database.dart, fake clock, builders

drift_schemas/                schema snapshots, at the repository root
```

## 5. Buckets, suffixes and when a folder appears

| Folder | File suffix | Holds | Appears with |
|---|---|---|---|
| `domain/entities/` | `_entity` | immutable domain objects; pure rules as members (D7) | the first entity |
| `domain/models/` | `_model`, `_scheduler`, `_mode` | value objects, enums of stored codes, read models; `srs` scheduler strategies (`_scheduler`) and `study_mode` modes (`_mode`) | the first such type |
| `domain/repositories/` | `_repository` | contracts, one implementation each for ADR-010's reason | the first repository |
| `domain/failures/` | `_failure` | the feature's rejection-reason enums (D6) | the first rejection |
| `domain/usecases/` | `_use_case` | one per UI interaction (D4, D5) | the feature's first screen |
| `data/datasources/` | `_dao`, `_data_source` | a DAO per bounded context; a data source only when several DAOs or exception mapping need one | the first DAO |
| `data/mappers/` | `_mapper` | row to entity, when the mapping is not trivial | the first such mapping |
| `data/repositories/` | `_repository_impl` | contract implementations; every write in one transaction | with the contract |
| `data/models/` | `_model` | DTOs | the first wire format, none while ADR-001 holds |
| `di/` | `_provider` | the repository provider, typed as the contract; it constructs the implementation directly, as the foundation plan does | the first repository |
| `presentation/screens/`, `controllers/`, `states/` | `_screen`, `_controller`, `_state` | screen, its controllers and state classes | the first screen |
| `presentation/providers/` | `_provider` | use-case providers | the first use case |
| `presentation/widgets/<bucket>/` | `_widget` | placed by AD-15: overlays, then items, then sections, then support; the first match wins | the bucket's first widget |

- The folder never replaces the suffix: `entities/deck_entity.dart`, not
  `entities/deck.dart`. These are exactly the suffixes that
  `memox.naming.*_file_role_suffix` and `_SUFFIX_RULES` in `check_architecture.py`
  enforce.
- Every feature file sits in a bucket of its layer: `<layer>/<bucket>/<file>.dart`,
  and `presentation/widgets/<bucket>/<file>.dart` for widgets. The one exception is
  `di/`, which is flat. No file sits directly in `domain/`, `data/`, `presentation/`
  or `widgets/`, and the feature root holds no file.
- These are not created until an ADR opens the need: `core/network/`,
  `core/storage/`, `app/config/` and build flavors (ADR-001: local-only),
  `shared/models/`, `shared/extensions/`, `core/utils/`, `app/di/`.

## 6. Dependencies

### 6.1 Inside a feature

```
presentation ──► domain ◄── data
      │                      ▲
      └────────► di ─────────┘      di wires data to the domain contract
```

- `domain/` is plain Dart: no Flutter, Riverpod, Drift or `core/database/`. `meta` is
  allowed.
- `data/` may import its own `domain/` and `core/`.
- `di/` may import its own `data/` and `domain/`, and `core/`.
- `presentation/` may import its own `domain/` and `di/`, and the rest of its own
  `presentation/`, but never `data/`. Under AD-12 a controller reaches a repository
  only through a use case.
- `core/` imports no feature, and nothing from `app/` or `shared/`. `shared/` imports
  only `core/`. `app/` composes features, and no feature imports `app/`.

### 6.2 Between features (D3)

A file may import another feature's `domain/entities/`, `domain/models/`,
`domain/repositories/` and `domain/failures/`. A file in `presentation/` or `di/` may
also import another feature's `di/`. No file imports another feature's `data/`,
`presentation/` or `domain/usecases/`. There are no barrels.

### 6.3 Two dependency graphs (D2)

| Graph | Direction | Declared in | Used for |
|---|---|---|---|
| `depends_on` | data: X reads data or a business contract that Y owns | `docs/features/*/README.md` | `verification_impact_map.json` (test widening), docs integrity |
| Dart import map | contract: X imports Y's public buckets | `test/architecture/boundary_rules.dart` | compile-time boundaries |

- The import map must be acyclic, and the test itself checks this. The foundation's
  entries are `srs → ∅`, `deck → {srs}` and `card → {deck, srs}`. `srs` reads `deck`
  and `card` rows through `core/database/`, not through their Dart code. A new feature
  adds its entry in the commit that creates its folder.
- The graphs differ on purpose where a business contract points one way and the data
  the other. `deck` and `card` need `srs` contracts (BR-SRS-001, BR-CARD-004,
  UC-CARD-002), while `srs` reads `deck` and `card` data for reset and the scheduler
  lock.
- Test selection stays safe. `discover_test_consumers` in `build_verification_plan.py`
  selects every test that transitively imports a changed file, so a contract edge that
  `depends_on` does not list is still covered.
- The `depends_on` definition in [`docs/README.md`](../../README.md) (line 281) gains
  one sentence: the Dart import direction between features is governed by ADR-011 and
  may differ from this graph.

## 7. Use cases, rules and rejections

- **AD-12 without exceptions (D4, D5).** A feature with `presentation/` also has
  `domain/usecases/`. Every interaction its presentation triggers, read or write, goes
  through exactly one use case, and the use case runs the input validation. CLAUDE.md
  asks for a concrete reason to keep thin use cases. The reason: every feature has the
  same shape, so a new feature copies a known pattern, and each validation rule has one
  owner. The foundation has no presentation, so it creates no use case. Its public API
  is the repository contracts and the `di/` providers.
- **Rules that need the data as it is at write time** (depth, the content-type lock,
  emptiness, subtree move, stale generation) run inside the repository
  implementation's transaction. The use case is the entry point, not the place of the
  check.
- **Pure rules (D7)** are members of the entity, or of a value object in
  `domain/models/` (a deck name, a deck move). Use cases call them, and so does the
  repository implementation inside its transaction.
- **Rejections (D6).** `core/error/outcome.dart` holds `Outcome<T, R extends Enum>`,
  with `Ok` and `Rejected(R reason)`, and names no reason itself. Each feature declares
  its reasons in `domain/failures/<name>_failure.dart`, for example `DeckRejection`. A
  switch over them therefore stays exhaustive, and adding a reason touches only that
  feature. `Failure`, for unexpected database errors, stays in `core/error/failure.dart`.

## 8. Verification gate (D10)

Until the first `presentation/` file lands, the gate is:

1. `flutter analyze`.
2. `flutter test`, which includes `test/architecture/boundaries_test.dart`.
3. `check_architecture.py`. Its zero-scope rule stays mandatory for `all` only. The
   per-layer counts are reported, not required. Layers appear with their first real
   file (D1), so a tree with `domain/` and no `data/` yet is legitimate: that is the
   state after foundation Task 3, and today's tree has no feature at all. A renamed
   layer or folder is caught by name instead of by count, through item 4 and the
   shape rules of `boundaries_test.dart` (§9).
4. The CI tooling unit tests. They hold
   `test_every_feature_source_uses_a_known_top_level_layer`, which fails on any
   top-level feature folder outside `domain/`, `data/`, `di/` and `presentation/`. It
   therefore still catches the layer rename that the zero-scope rule was guarding
   against.
5. The guard `memox-v8`, failing on any error. A rule that has no targets yet declares
   `targets_pending: <layer>` in the ruleset's `config/overrides.yaml`. The guard
   reports such a rule at info level while it waits. Once the rule has targets, the
   declaration is reported as a `stale_targets_pending` warning, so the entry must go
   in the commit that adds the layer. A rule without targets and without the
   declaration still fails. The list starts at 40 rules on today's tree, which has no
   feature code. Foundation Tasks 3, 5, 7 and 10 retire 12 of them as their layers
   land. 28 remain after the foundation:
   - 25 wait for `presentation/` or `shared/` UI;
   - 1 waits for `lib/l10n/` (`memox.i18n.arb_entry_needs_description`, which also
     raises the `missing_target_path` for `app_en.arb`);
   - 2 wait for visual-audit tests.

From the first screen, the gate is the full `dod_check.sh`, with the guard back to
warnings-as-errors and an empty allowlist. The generated-code gate becomes mandatory
from the first task that adds code generation.

The root `README.md` and the foundation plan's Global Constraints state this gate.

## 9. Changes this spec requires

This section is the input to the implementation plan. No product code exists yet
beyond `lib/main.dart`, so every change is to documentation, skills, tooling or tests.

1. **ADR-011** in `docs/shared/decisions/`, written in Vietnamese like the other ADRs.
   It holds D1–D12, a short form of §5–§7 and the import-map policy. ADR-010 gains a
   pointer to it under "Hệ quả".
2. **`docs/README.md`**: the sentence from §6.3.
3. **Skills**, folder-architecture statements only:
   - `flutter-architecture/SKILL.md`: the tree and the dependency rules become §4–§6;
     AD-12 loses its carve-out; AD-12 and AD-15 cite ADR-011 instead of
     `docs/architecture.md`; the guard command uses `--ruleset memox-v8`.
   - `flutter-feature-slice/SKILL.md` and `assets/feature_blueprint.md`: point to
     ADR-011 for the layout; `data/models/` appears with its first file; a banner
     marks the blueprint as a V7 reference whose paths, including its `app/di/`
     binding, do not exist in V8.
   - `flutter-drift/references/project-baseline.md`: a banner marking it as the V7
     baseline. V8 names come from `schema.md`: `parent_id`, `root_id`, singular table
     names, and `delete_batch_id` in a later sub-project.
   - `flutter-testing/SKILL.md`: the `test/` tree of §4.
   - `flutter-project-setup/SKILL.md`: flavors and `EnvConfig` are deferred until an
     ADR opens networking (ADR-001).
4. **Tooling:**
   - `check_architecture.py`: only the `all` zero scope stays fatal (§8).
     `test_architecture_checker.py` gains two fixtures that pass, one without
     `presentation/` and `di/` and one with only `lib/main.dart`, and one with an
     empty `lib/` that fails.
   - `boundaries_test.dart`: drop the barrel rule. Add the public-bucket rule (§6.2),
     domain purity for every `lib/features/*/domain/`, the shape rules (§4, §5 and
     D11: top-level `lib/` folders, layer buckets, `core/` concern folders) and the
     acyclicity check (§6.3). The rules live in `test/architecture/boundary_rules.dart`,
     so each one is proven on a planted violation.
   - The vendored guard: `targets_pending` support in the rule runner and in config
     validation, with tests. The `memox-v8` ruleset's `config/overrides.yaml` gets
     the allowlist (§8).
   - `build_verification_plan.py`: no change, since this layout is the one it expects.
5. **Foundation plan:**
   - File Structure, task paths and test paths follow §10.
   - Clarification 3 is rewritten per D3, and Clarification 5 per D2.
   - Task 2 drops the `Rejection` enum.
   - Tasks 3–9 get per-feature rejection enums, with rules on entities and value
     objects.
   - The Global Constraints gate follows §8.
6. **Root `README.md`:** the gate of §8.

Out of scope, and recorded as follow-up:

- V7 references in the skills that are not about folders, such as
  `docs/checklist.md`, `docs/wbs.md`, AD numbers in the data-layer and state skills,
  and the MX-VIS-001 and Widgetbook steps.
- The `memox-v8` guard ruleset still carries 13 rules with `memox_v7.design_system.*`
  ids.

## 10. Foundation plan paths

| Foundation plan (2026-09-23) | This spec |
|---|---|
| `lib/core/id.dart` | `lib/core/id/new_id.dart` |
| `lib/core/outcome.dart` with `enum Rejection` | `lib/core/error/outcome.dart`, generic; the reasons move to each feature's `domain/failures/` |
| `lib/features/{srs,deck,card}/<f>.dart` (barrels) | removed; importers name the public bucket file |
| `srs/domain/eight_box.dart`, `sm2.dart` | `srs/domain/models/eight_box_scheduler.dart`, `sm2_scheduler.dart` |
| `srs/domain/review_kind.dart` | `srs/domain/models/review_kind_model.dart` |
| `srs/domain/schedule_repository.dart` | `srs/domain/repositories/schedule_repository.dart` |
| `deck/domain/deck.dart` | `deck/domain/entities/deck_entity.dart` |
| `deck/domain/deck_rules.dart` | members of the deck entity and of value objects in `deck/domain/models/`; reasons in `deck/domain/failures/deck_failure.dart` |
| `deck/di/deck_providers.dart` | `deck/di/deck_repository_provider.dart` |
| `lib/app/router.dart` | `lib/app/router/app_router.dart` |
| `test/features/srs/sm2_test.dart` | `test/features/srs/domain/sm2_scheduler_test.dart` |

The remaining files follow the same rules, and the revised plan fixes their names.

## 11. Risks and rollback

- **The guard allowlist outlives its reason.** Each entry names the layer it waits for,
  and adopting the full gate requires an empty list.
- **The two dependency graphs drift apart.** Both are checked: the acyclic import map
  by `boundaries_test.dart`, `depends_on` by `ImpactMapMatchesTheDocsTest`. The
  planner's import closure keeps test selection safe however they differ.
- **Thin use cases under AD-12** are an accepted cost of D4 and D5.
- **Rollback:** the change touches documentation, skills, tooling and tests only.
  Reverting its commits restores the current state.
