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

Fakes of the domain contracts, not mocks: `test/support/` holds the shared ones
(`fake_day_clock.dart`, `fake_reminder_platform.dart`, …), so a changed
signature is a compile error where it matters.

The gate runs the host suite bundled: `bundle_tests.py` folds every non-golden
test file into one entrypoint per core (at most 8), so files share a process. A test file
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

## What to test, honestly

Test business rules, state transitions, error paths, mappers, migrations and
anything with a conditional. Do not test the framework, generated code, or that
a constant equals itself.

Coverage percentage is a weak signal — a suite at 90% that never exercises a
failure path is worse than one at 60% that does. Ask which failure a test would
catch; if there is no answer, it is not earning its maintenance cost.
