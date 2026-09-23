---
name: flutter-architecture
description: The layering and code-style rules for this Flutter codebase — feature-first folder structure, what each layer may import, when a use case or an interface is actually worth creating, the analysis_options.yaml lint configuration, guard-clause control flow, banning magic values, and file/class naming conventions. Use this skill when creating a new feature folder, deciding where a file belongs, reviewing whether code respects layer boundaries, configuring or tightening lints, resolving an import that feels wrong, or when tempted to add an abstraction. Also use it before any code review or commit that adds new files. Covers checklist phases 4 and 5, and it ships `scripts/check_architecture.sh` to verify the boundaries mechanically.
---

# Architecture and code conventions

Covers checklist Phases 4 (structure, dependency rules) and 5 (lint, code style,
naming).

## Folder structure

The V8 layout is ADR-011 (`docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md`),
which refines ADR-010 decision 2. The tree says where a file goes, not what to
create: a folder appears with its first real file.

```
lib/
├── main.dart                 # ProviderScope + runApp, nothing else
├── app/                      # composition root: MemoxApp, retry policy
│   └── router/               # app_router.dart; paths and shell come with the UI
├── core/                     # infrastructure that knows no feature, one folder per concern
│   ├── database/             # connection.dart, app_database.dart, di/, tables/, queries/
│   ├── error/                # failure.dart, outcome.dart
│   └── id/                   # new_id.dart
├── l10n/                     # app_en.arb, app_vi.arb, from the first UI string
├── shared/
│   └── widgets/              # Mx* components, from the design-system sub-project
└── features/<feature>/       # names from ADR-010 decision 1
    ├── domain/               # plain Dart: entities/ models/ repositories/ failures/ usecases/
    ├── data/                 # datasources/ mappers/ repositories/ models/
    ├── di/                   # flat: repository providers, typed as the contract
    └── presentation/         # screens/ controllers/ states/ providers/
        └── widgets/          # exactly four buckets, one level deep (AD-15):
                              #   sections/ items/ overlays/ support/
```

| Folder | Suffix | Holds |
|---|---|---|
| `domain/entities/` | `_entity` | immutable domain objects; pure rules as members |
| `domain/models/` | `_model`, `_scheduler`, `_mode` | value objects, stored-code enums, read models; `srs` schedulers, `study_mode` modes |
| `domain/repositories/` | `_repository` | contracts, one implementation each |
| `domain/failures/` | `_failure` | the feature's rejection-reason enum |
| `domain/usecases/` | `_use_case` | one per UI interaction (AD-12) |
| `data/datasources/` | `_dao`, `_data_source` | a DAO per bounded context |
| `data/mappers/` | `_mapper` | row to entity, when the mapping is not trivial |
| `data/repositories/` | `_repository_impl` | contract implementations; every write in one transaction |
| `data/models/` | `_model` | DTOs; none while the app is local-only (ADR-001) |
| `di/` | `_provider` | repository providers; each constructs its implementation |
| `presentation/screens/`, `controllers/`, `states/` | `_screen`, `_controller`, `_state` | a screen, its controllers, its state classes |
| `presentation/providers/` | `_provider` | use-case providers |
| `presentation/widgets/<bucket>/` | `_widget` | placed by the four questions below |

Every feature file sits in a bucket of its layer; only `di/` is flat. No file
sits directly in `domain/`, `data/`, `presentation/` or `widgets/`, or at the
feature root, and there are no barrels: another feature imports the bucket file
it needs. The folder never replaces the suffix: `entities/deck_entity.dart`, not
`entities/deck.dart`. These wait for an ADR that opens the need:
`core/network/`, `core/storage/`, `core/utils/`, `app/config/` and flavors,
`app/di/`, `shared/models/`, `shared/extensions/`.

**Placing a widget** is four questions asked in order, stopping at the first
yes (AD-15, ratified for V8 by ADR-011 D8):

1. Does it open *over* the screen (`showModalBottomSheet`/`showDialog`)? → `overlays/`
2. Is it the repeated row of a list, or a part only that row uses? → `items/`
3. Does the screen compose it directly into its body or chrome? → `sections/`
4. Does it serve more than one bucket above (ARB mapping, render-only extension)? → `support/`

Buckets never nest, a bucket is created only when it has real content, and the
bucket list is app-wide: a fifth name is an ADR change, not a new folder.
`test/architecture/boundaries_test.dart` owns the full shape, with the rules in
`test/architecture/boundary_rules.dart`; the guard rule
`memox.architecture.widgets_grouped_into_buckets` is the second net.

`core/` is infrastructure with no knowledge of any feature. The moment
`core/database/` imports a feature entity, the boundary has broken — that code
belongs in the feature.

## Dependency rules

```
presentation ──► domain ◄── data
      │                      ▲
      └────────► di ─────────┘      di wires data to the domain contract
```

- **domain** is plain Dart: no Flutter, Riverpod or Drift, nothing from
  `core/database/`, `app/` or `shared/`, and no other layer. `meta` is allowed.
  The test is simple: a domain file must compile in a plain Dart package. If it
  needs `package:flutter` for `@immutable` or `Color`, restructure — `@immutable`
  can come from `meta`, and a `Color` in a domain entity means a UI concept
  leaked into the model.
- **data** implements the repository contracts of its own domain, and may import
  its own `domain/` and `core/`. Never the reverse.
- **di** may import its own `data/` and `domain/`, and `core/`. It is where a
  repository implementation is constructed.
- **presentation** may import its own `domain/` and `di/`, never `data/`. Every
  interaction it triggers, read or write, goes through exactly one use case
  (AD-12, ADR-011 D4–D5): never to a DAO, never to Drift.
- **Between features**, a file may import another feature's
  `domain/{entities,models,repositories,failures}/`, file by file. A file in
  `presentation/` or `di/` may also import another feature's `di/`. Nothing
  imports another feature's `data/`, `presentation/` or `domain/usecases/`. If
  two features need the same thing, it moves to `core/`, or one feature exposes
  a domain contract the other depends on.
- **The import map is acyclic.** `allowedFeatureImports` in
  `test/architecture/boundary_rules.dart` lists the features each feature may
  import: `srs → ∅`, `deck → {srs}`, `card → {deck, srs}`. A new feature adds
  its entry in the commit that creates its folder. The map is the contract
  direction; `depends_on` in `docs/features/*/README.md` is the data direction
  and may differ (ADR-011 D2).
- `core/` imports no feature, `app/` or `shared/`. `shared/` imports only
  `core/`. `app/` composes features, and no feature imports `app/`.

Verify mechanically rather than by eye:

```bash
flutter test test/architecture
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
```

## Pragmatic, not ceremonial

Clean Architecture here is a means, not the goal. The checklist says so
explicitly, and it is the part most often ignored:

- **A layer appears with its first real file, and a feature with a screen has
  one use case per interaction** (AD-12, ratified by ADR-011 D4). A feature with
  no screen has no `presentation/` and no `domain/usecases/`; nothing is
  scaffolded for later. Once a feature has a screen, every interaction goes
  through its own use case, reads and thin ones included, and no feature is
  exempt, settings included (D5). Uniformity is what turns a new feature into a
  clone of a known shape rather than a judgement call at every operation, and it
  gives each input-validation rule one owner — the use case — instead of a
  controller and a repository that both check it.
- **A rule that needs the data as it stands at the moment of writing does not go
  in a use case.** Depth limits, first-child locks, emptiness checks and subtree
  moves run inside `runInTransaction`. Hoisting one above the repository puts the
  check outside the transaction — a race between the check and the write. Tidier
  place, wrong answer.
- **Do not write an interface for a single implementation you will never
  swap.** The exception that earns its keep is the repository contract, because
  it is what lets domain stay framework-free and lets tests substitute fakes.
  Beyond that, wait for the second implementation.
- **Do not build for imagined scale.** The cost of adding a layer later, once
  the need is real, is nearly always lower than the cost of carrying an unused
  one through every change.

The standard shape is ADR-011. A deviation from it is an ADR change approved
by the project owner, not a local exception, so the next person reads a
decision instead of an inconsistency.

## Control flow

Guard clauses, early return, fail fast:

```dart
Future<Deck> loadDeck(String id) async {
  if (id.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');

  final deck = await _repository.findById(id);
  if (deck == null) throw const NotFoundFailure(message: 'Deck not found');

  return deck;
}
```

Avoid `else`. An `else` almost always means the guard was written as a branch
instead of an exit — invert the condition and return early. Nested conditionals
are the readability problem this rule exists to prevent; after three levels
nobody reliably tracks which branch they are in.

`switch` on a sealed class or enum is the exception, and is encouraged — with no
`default` clause, so that adding a variant produces a compile error at every
place that must handle it. A `default` throws that safety away.

Never `catch (_) {}`. If a failure is genuinely ignorable, catch the specific
exception type and write the reason:

```dart
try {
  await _analytics.log(event);
} on AnalyticsException catch (e, s) {
  // Analytics must never break a user flow; log and continue.
  _logger.warning('analytics failed', e, s);
}
```

## No magic values

Any string or number carrying meaning goes in a named const, an enum or a
sealed class. This includes route paths, storage keys, API paths, retry counts,
page sizes, animation durations and every spacing value.

Finite state is an enum or sealed class — never loose strings, and never a set
of booleans. Three booleans encode eight states, of which perhaps three are
legal; the other five will eventually happen.

## Naming

Files are `snake_case` ending in the suffix that states the role; the table
under "Folder structure" pairs each folder with its suffixes, and the folder
never replaces the suffix.

`_model` means two things, told apart by its folder. In `domain/models/` it is
a value object, a stored-code enum or a read model: domain language, stable. In
`data/models/` it is a DTO, the wire shape, which changes when the API changes.
`_entity` is the domain object and changes with neither. The Drift row class is
none of these: only `data/` and `core/database/` use it, and the repository maps
it to the entity, so no row or DTO reaches the UI.

Booleans read as predicates: `isLoading`, `hasError`, `canSubmit`,
`shouldRetry`. Avoid `Utils`, `Manager`, `Helper` — they attract unrelated code
because nothing is out of scope for a name that means nothing.

## Lint

`references/analysis_options.yaml` is the configuration to copy into the project
root. It turns on `strict-casts`, `strict-inference`, `strict-raw-types`, and
promotes the rules that matter to `error`.

It deliberately does **not** declare a `custom_lint` plugin. `custom_lint` and
`riverpod_lint` are descoped — see `Deferred and descoped` in `docs/wbs.md`. Do
not add the block back: a plugin declared but not installed is silently ignored,
so the rules look configured and never run.

The Riverpod checks that `riverpod_lint` used to provide — `ref.read` inside
`build()` being the one that matters most — are now owned by
**code-verification-guard**, run as a separate gate:

```bash
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

Nothing merges with an analyzer error. A warning you intend to keep needs an
`// ignore:` with a comment saying why — a bare ignore is a defect with a lid on
it.

## Size limits

No file of thousands of lines, no widget of hundreds. When a `build()` method
grows past roughly a screenful, split by UI section into private widget classes
— not into `Widget _buildHeader()` methods, which look like a split but keep the
whole thing rebuilding as one unit. Separate widget classes give you `const`
constructors and narrower rebuilds for free.
