---
name: flutter-testing
description: Testing strategy and patterns for this Flutter app — unit tests for use cases, repositories, mappers, validators, Drift queries and migrations and error mapping; Riverpod controller tests for state transitions; widget tests with ProviderScope covering loading/empty/error/dark-mode/text-scale; golden tests with stable rendering; and integration tests for the 60-scenario UI suite (cold start, navigation, CRUD, restart, deep links and the optional sign-in and account flows). Use this skill whenever writing, fixing or reviewing any test, setting up mocks or fakes, deciding what needs test coverage, debugging a flaky or failing test, or configuring golden-test tolerances.
---

# Testing

Testing strategy in one line: **test what can be wrong, at the cheapest level
that can catch it.** A rule that can be tested as a pure function should not be
tested through a widget — a widget test that fails tells you far less about why.

Record the strategy in `docs/shared/testing/` (`README.md` and
`testing-pyramid-audit.md` hold it today), including what you have deliberately
decided not to test and why.

## Layout

```
test/
├── architecture/       boundaries_test.dart, boundary_rules.dart (ADR-011)
├── app/                once app/ has behaviour: router, bootstrap
├── core/<concern>/     mirrors lib/core/<concern>/
├── database/           schema-wide: schema, migration, invariants
├── integration/        cross-feature flows on real SQLite
├── features/<feature>/
│   ├── domain/         entity rules, value objects, use cases
│   ├── data/           repository, mapper, DAO
│   └── presentation/   controller, widget; support/ for feature-local fakes
└── support/            shared: test_database.dart, fake clock, builders, pump helpers
```

Folders appear with their first test (ADR-011 D1, D12). The suites that came
with the UI are in place: visual audits under `test/visual_audit/` (MX-VIS-001,
which the guard's `memox.visual.*` rules also target) and goldens beside the
widget tests. A device end-to-end suite does not exist yet.

## Running tests

- A file: `flutter test test/path/x_test.dart`.
- Anything larger, a directory, several files or the suite:
  `bash .claude/skills/flutter-workflow/scripts/run_tests.sh <file|dir>…`.
  It bundles the files (one entrypoint per core), prints only failures and a
  summary, and keeps the JSON report and bundles under
  `.dart_tool/memox_test_bundles/` when a test fails. `flutter test <dir>`
  compiles and starts every file on its own, several times slower; a hook
  notes it when it happens.
- Run once. The summary lists every failing file with the command that
  re-runs it alone; running the same tests again only to filter the output
  another way pays the whole run twice.
- Goldens: `run_goldens.sh` (`--update` to rewrite), in the Linux container;
  `--changed` compares only the golden files the diff reaches.

`dod_check.sh --changed` and `run_goldens.sh --changed` pick tests by imports
(`build_verification_plan.py`): a changed Dart file selects every test that
imports it, directly or through a helper. So a test imports only the harness
it uses, and a shared helper never imports what most of its users do not need:
`library_harness.dart` is the backend, `deck_screen_harness.dart` the Library's
screens and `app_harness.dart` the whole app (`pumpMemoxApp`). One import of
`lib/app/app.dart` in a shared helper ties every screen to every test that
uses it; a real-tree test in `test_ci_tooling.py` fails when a screen selects
a quarter of the suite. A test that reads a repository file from disk instead
of importing it is declared in `verification_impact_map.json` `file_readers`,
which another test enforces.

Fakes of the domain contracts, not mocks: `test/support/` holds the shared ones
(`fake_day_clock.dart`, `fake_reminder_platform.dart`, …), so a changed
signature is a compile error where it matters.

The gate runs the host suite bundled: `bundle_tests.py` folds every non-golden
test file into one entrypoint per core (at most 8), so files share a process,
and splits the files by each one's time in the last run
(`.dart_tool/memox_test_timings.json`, written by `test_report.py`) so that no
bundle holds all the slow ones. A test file
therefore restores any global state it changes (statics, `debug*` overrides,
`HttpOverrides.global`, `tester.view`) through `addTearDown`, keeps library-level
annotations to `@Tags(['golden'])`, and has a synchronous `main`; the bundler
refuses the last two by name. When a test fails only bundled, run its file alone
with the command the gate's report prints, or the whole gate with
`MEMOX_TEST_BUNDLES=0`.

## Unit tests

Cover use cases, repositories, mappers, validators, Drift queries, migrations
and error mapping. For each: the success path, each failure path, and the edge
cases from `docs/features/<feature>/rules/` (each BR file has an `## Edge case` section).

The failure paths are the point. A repository test that only asserts the happy
path leaves untested exactly the code that runs when a user is having a bad day.

Repository tests here run against **real in-memory SQLite**
(`test/support/test_database.dart`), not a mocked executor — the thing
worth proving is that the SQL, the constraints and the transaction behave, and
a mock proves none of that (see `flutter-feature-slice` Step 4, which owns this
rule):

```dart
test('deleting the last card of a deck makes it unset (BR-DECK-015)', () async {
  final card = await cards.card(nouns.id);  // real repository, in-memory schema

  final result = await cards.deleteCards(cardIds: {card.id});

  expect(result, isA<Ok<List<String>, CardRejection>>());
  expect(await contentTypeOf(nouns.id), DeckContentType.unset);
});
```

**Error mapping deserves a dedicated table-driven test** — every
`SqliteException` code the app can hit mapped to its expected `Failure`
(`mapDatabaseError` in `lib/core/error/failure.dart` is the unit under test).
It is high-traffic code that manual testing almost never exercises. When a
repository maps API errors (ADR-012), the same table-driven treatment applies
to HTTP status codes and `DioExceptionType`.

**Migration tests** matter more than they look. Use Drift's schema fixtures to
migrate from each released version to current, and assert the data survived. A
migration bug only shows for users with existing data — everyone except you.

## Controller tests

No widgets needed. Build a container with overrides and read the notifier:

```dart
ProviderContainer makeContainer({required DeckRepository repository}) {
  final container = ProviderContainer(
    overrides: [deckRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);   // or providers leak between tests
  return container;
}
```

Cover: initial state, loading→loaded, loading→error, refresh, submit success,
submit failure, **duplicate submit**, and **no state update after dispose**.

The last two are the ones that catch real bugs. Duplicate submit reproduces the
double-tap; the dispose test reproduces the user leaving a screen mid-request,
which throws on a disposed notifier and is otherwise found in production.

```dart
test('does not update state after dispose', () async {
  final completer = Completer<List<Deck>>();
  when(() => repository.getDecks()).thenAnswer((_) => completer.future);

  final container = makeContainer(repository: repository);
  container.read(deckListControllerProvider);
  container.dispose();

  completer.complete([deck]);
  await Future<void>.delayed(Duration.zero);
  // Passes by not throwing — a disposed notifier assigned to would throw here.
});
```

## Widget tests

Always wrap in `ProviderScope` with overrides, and in the app theme and l10n
delegates — a widget test without the theme can pass while the real screen has
no styling.

Put the wrapper in `test/support/` once. Every test writing its own is how they
drift apart and stop reflecting the real app.

Cover per screen: main text and actions, loading, empty, error, validation
messages, small-screen overflow and dark mode, at the default text scale only
(large text is not a design target, PRODUCT.md 2026-09-30).

Overflow is caught by checking for an exception after pumping:

```dart
testWidgets('renders on a small phone without overflow', (tester) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(wrap(
    const DeckListScreen(),
    overrides: [/* ... */],
  ));
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
});
```

Find by semantic label or key, not by literal text — text moves to ARB and
changes with locale, and a test asserting English strings breaks the moment a
translation lands.

## Golden tests

For shared components and screens needing pixel parity. Light and dark, at a
standard mobile size.

Goldens fail for uninteresting reasons unless the rendering environment is
pinned: load a real font in `flutter_test_config.dart` (the default Ahem font
renders as boxes), and generate on one platform — CI-generated goldens will not
match locally-generated ones.

Do not golden-test anything with uncontrolled variation — relative timestamps,
random content, network images, animations mid-flight. Freeze or inject those,
or the test fails daily and gets ignored, which is worse than not having it.

The pixel-difference threshold for comparing against the design kit is under
3%. For golden regression tests between runs, keep tolerance at or
near zero — the whole point is to notice change.

## Integration tests

Host flows live in `test/integration/` and run with the rest of the suite. The
canonical list is the scenario catalog
(`docs/shared/testing/scenario-catalog.md`), and
`docs/shared/testing/agent-execution-guide.md` holds the execution rules: each
scenario's readiness, its profile (`HOST-FLOW`, `HOST-WIDGET`, `DEVICE-E2E`),
its setup and its cleanup. Read both before writing, running or debugging a
scenario.

Cover what the app actually has: cold start, the optional sign-in and account flows, main
navigation, deck/card CRUD through the UI, restart
with state restored, the review flows, and each deep link. The canonical list
is the 60 scenarios in `docs/shared/testing/scenario-catalog.md` — extend that
catalog rather than inventing parallel coverage.

Three defect classes deserve a test of their own:

1. **A pass-through seam that drops optional parameters** — a use case that
   accepts a sort or a search term and forwards neither. Lock every use case
   with optional parameters with a fake that records what it receives.
2. **A Drift stream that misses a table it reads** — see the `riverpod-drift.md`
   reference of `flutter-drift`: a write to that table must re-emit, and a
   repository-level test proves it.
3. **A scenario test that skips a documented step** — diff the test's steps
   against the scenario's table line by line; asserting less than the document
   is a quiet way of lowering the expected result.

Deep links and cold start are the highest-value cases here, because they are the
ones nobody exercises during development — you already have the app open.

Device scenarios (`DEVICE-E2E`) live in `integration_test/`, one file per phase,
and run by hand with `tools/device/run_device_e2e.sh` on an Android emulator or
phone (`docs/shared/testing/device-e2e.md`). A phase finds text through the
running tree's `AppLocalizations`, never a literal; it builds its fixture through
the UI; and it talks to the runner with `MEMOX-E2E:` lines (a real system Back, a
value for a later phase, a screenshot before a failure).

Flutter Web plus Playwright is a reasonable way to run flows early and cheaply,
but it is not a substitute: platform channels, secure storage, SQLite and deep
links all behave differently. Run the suite on a real Android and iOS device
before release.

## One behaviour, one test

The suite was deduplicated on 2026-10-18 (about 190 test declarations and
2,400 lines fewer, no behaviour lost). These rules keep it that way, for a new
test and for any later cleanup.

**Before writing a test, look for the one that already exists.** Search
(`rg`) for the widget, use case or query under test and read the tests that
pump or call it. If one already builds the same inputs, add the missing
assertion to it instead of writing a twin.

**What counts as a duplicate.** A test is a duplicate only when another test
with the same inputs makes, or strictly implies, every assertion it makes.
"Same inputs" covers sizes, widths, the text scale, the locale, the overrides,
the seed rows, the mode and the entry point. A similar name, a similar flow or
the same widget does not make a duplicate. These stay separate even when they
look alike:

- the same rule tested at another layer (repository, use case, controller,
  widget), since each one tests different wiring;
- another entry point (a UI Back and a system pop, a Cancel tap and
  `handlePopRoute`, `start()` and `recheckSession()`);
- the two sides of a boundary, a negative case, a regression and a state
  transition;
- a real path and a stub of it (an override that copies a controller method
  does not cover the real method).

**Removing a duplicate.** First move into the kept test any assertion it lacks.
Then carry the deleted test's ids (UC-, BR-, IT-, DEV-, M3F-, SW-REV-, audit
and critique ids) into the kept test's name or a comment *in the same file*.
`docs/_generated/traceability.md` lists a test file under every UC id the file
contains.

**Same flow, different data: a table.** Write
`for (final c in cases) test('… ${c.name}', …)` (or a record list), so each
case is still one reported test and a failure still names its case.

- Each row keeps its original case's exact inputs. Use `null` for "not set"
  rather than a value that equals today's default, because an unset parameter
  and a default value are different inputs.
- Each row keeps every assertion its original case had. Applying a stronger
  assertion to every row is fine when it holds.
- Never fold independent behaviours into one big test, and never pack two cases
  into one test body.

**Setup copied twice becomes a helper, at the narrowest home:**

- private in the file when one file uses it;
- in the feature's `presentation/support/` (or `data/support/`) when one
  feature uses it;
- in `test/support/` when features share it, preferably in a *new, narrow* file
  that imports only what it needs.

Tests are selected by imports (`build_verification_plan.py`), so a new import
in a widely used helper (`test_database.dart`, `sync_fakes.dart`,
`study_fixtures.dart`) ties every importer to that code. Add to an existing
helper only; never change a signature other areas call. Keep a helper file
under the guard's 400-line limit (`common.no_large_source_file`). A UC id in a
shared helper's comment puts the helper in the traceability table, so ids stay
in the tests.

**Out of scope for merging.** The `test/visual_audit/` companions are pinned by
`screen_audit_coverage_test.dart` and the guard (MX-VIS-001). Golden tests
need the golden review. Leave both as they are.

**Prove it.** Run the touched files with `run_tests.sh` before and after the
change. The difference in count must equal the tests you meant to delete, and a
table keeps one test per case. Then reread the diff against the base for every
deleted test and every changed row. A row that changed an input, or a deletion
whose kept twin uses other inputs, is restored.

## What to test, honestly

Test business rules, state transitions, error paths, mappers, migrations and
anything with a conditional. Do not test the framework, generated code, or that
a constant equals itself.

Coverage percentage is a weak signal — a suite at 90% that never exercises a
failure path is worse than one at 60% that does. Ask which failure a test would
catch; if there is no answer, it is not earning its maintenance cost.
