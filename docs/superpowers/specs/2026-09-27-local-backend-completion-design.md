# Local backend completion — roadmap for the backend items left in `wbs_BE.md`

Status: approved by the owner (2026-09-27): run G1 → G5 back to back, merging each package once green · Path: architectural ·
WBS: [`wbs_BE.md`](../../wbs_BE.md)

## 1. Intent

Finish every backend item still open in `wbs_BE.md` while `memox-api-services`
is being built, so that the app's local store is clean and complete before the
first sync slice of [ADR-013](../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md)
pushes its data to the server.

"Backend" here means what `wbs_BE.md` covers: `lib/core/` and
`lib/features/*/{domain,data,di}/`, plus the documentation and tooling items
it carries (BE-D*).

Success means:

- every open WBS backend row ends `xong` or is closed with its reason;
- text in the store has one Unicode form (NFC) before sync starts;
- batch operations work past SQLite's bind-variable limit;
- no skill or document still describes V7;
- all 22 UCs carry Given/When/Then acceptance criteria;
- the daily reminder reaches a real Android device, or the one step that
  needs a device is named as the only thing left.

## 2. Decisions taken with the owner (2026-09-27)

| # | Item | Decision |
|---|---|---|
| D1 | Scope | The WBS backend rows only. The app-side sync slices of ADR-013 (steps 3–4 of the [sync spec](2026-09-27-server-sync-design.md) §9) get their own plan once the server fixes the wire format |
| D2 | BE-C5 | Unicode NFC through the `unorm_dart` package (pure Dart, covers Hangul). Normalise on every text write and inside `foldText`; one migration re-folds stored text. Done **before** the sync migration. *Outcome:* #114 (sync, v4) merged first, so G1 ships as v4 → v5; its deck-name rewrites run under the capture triggers and are queued, so the server receives NFC names |
| D3 | BE-C1 | **Closed.** Names keep code-unit order; the WBS row records the owner's choice |
| D4 | BE-D4 | Only the `## Acceptance criteria` section of the 18 UCs that hold the placeholder is written. Frontmatter, flows, rules and `status` are not touched |
| D5 | BE-B5b | Included as the last package. Its Dart side is built and tested on the host. The APK build and the device check run only once an Android SDK or a device is available (the container blocks `dl.google.com`); until then the package stops at that step and says so |
| D6 | Order | G1 (BE-C5) → G2 (BE-C2, BE-C1 closed) → G3 (BE-D7 with BE-D3) → G4 (BE-D4) → G5 (BE-B5b) |

## 3. How each package runs

The owner approves this roadmap once; the packages then run back to back.

1. **Package plan.** Written with writing-plans at
   `docs/superpowers/plans/2026-09-27-local-backend-g<N>-<topic>.md`, from this
   spec's section for the package. It is committed with the package, and
   nobody is asked to approve it: this spec is the approval.
2. **Execute it natively.** Use executing-plans, TDD, the ledger, and
   `task-done` per task.
3. **Final whole-branch review** on the most capable model, then one fix pass.
   Each fix goes RED → GREEN.
4. **Records.** Update the WBS row, `schema.md`, the rules and the UC `code:`
   fields, in the same PR as the change.
5. **Ship.** Merge `origin/master`, then run the gate: `dod_check.sh`, the
   goldens, and `tools/docs/check.py`. Open the PR with the package's rulings
   in its body, and squash-merge it once CI is green. Then sync the branch
   and start the next package.

**Stop only for:**

- an irreversible or destructive action outside the branch;
- a security-sensitive change;
- a precedence conflict that would change data or business behaviour beyond
  what this spec decides;
- a failure whose root cause cannot be found;
- D5's device step.

**After G5:** one report to the owner. It lists each package's PR, the rulings
with their cost if wrong, the deferred minors, and any open question G4
recorded.

## 4. G1 — BE-C5: Unicode NFC

**Problem:** the same word can arrive precomposed or decomposed: Vietnamese
`é` versus `e` + U+0301, and Hangul pasted from macOS as separate jamo.
`foldText` only trims and lower-cases, so the import duplicate check
(BR-TRANSFER-003), tag names (BR-TAG-001), search, and Fill answers
(BR-STUDY-026) treat the two forms as different strings.

**Design:**

- `lib/core/text/` owns two functions, and is the only importer of
  `unorm_dart`. A guard rule enforces that.
  - `storedText(raw)` = NFC(trim(raw)): the stored form of every
    user-entered string.
  - `foldText(raw)` = NFC(lower(NFC(trim(raw)))). Normalising again after
    lower-casing keeps the result NFC, because lower-casing can break it.
- **Write paths.** The six data-layer sites that `.trim()` user text today
  use `storedText` instead:
  - `card_dao` (front, back, example, hint, pronunciation);
  - `deck_repository_impl` (create, update, rename);
  - `tag_repository_impl` (create, rename, and the "name unchanged" check).

  Import and starter decks write through these, so they are covered too.
  Domain validators count grapheme clusters, so they already accept both
  forms and do not change.
- **Fill.** Its comparison changes, so `fillComparisonVersion` goes from 1
  to 2. Turns already recorded keep version 1 (BR-STUDY-026, BR-STUDY-027).
- **Migration v3 → v4.** It changes data only, not structure, and runs in one
  transaction:
  - re-store every user text column in NFC;
  - recompute `front_folded`, `back_folded` and `name_folded` in Dart,
    because SQLite has no NFC;
  - when two tags collide on `name_folded` after normalisation, keep the
    oldest (by `created_at`, then `id`), move the `card_tags` links to it,
    drop the duplicate links, and delete the other tags. These are the
    semantics of a rename that merges (BE-B2).

  The migration adds a v4 snapshot and an upgrade test, on the BE-D1
  framework.
- **Tests:**
  - precomposed and decomposed input give one stored form and one fold,
    for Vietnamese and for Hangul jamo;
  - the import finds a duplicate written in the other form;
  - search matches a card written in the other form;
  - a Fill answer typed in the other form is judged right, under version 2;
  - the migration merges colliding tags without losing a card link;
  - the migration is a no-op on text that is already NFC.
- **Records:**
  - `schema.md`: the `*_folded` definitions gain NFC;
  - BR-TAG-001 names NFC in its fold;
  - the sync spec notes that pushed text is NFC;
  - WBS BE-C5 → `xong`.
- **Rollback:** drop the NFC calls from the two functions. Stored text stays
  NFC, which every reader accepts.

## 5. G2 — BE-C2: chunked batches; BE-C1 closed

- **Helper.** `lib/core/database/` gains one chunking helper, which reads or
  writes an id list in chunks inside the caller's transaction.
  - The default chunk is 30 000 ids, which leaves room for the other
    variables a statement binds.
  - Tests may pass a smaller chunk size.
- **Where it applies.** Every `isIn(ids)` that takes a user-sized id list,
  across `card_dao`, `card_list_dao`, `tag_dao` and `trash_dao`:
  - reads concatenate the chunks before anything uses them;
  - a statement that filters on two lists chunks the larger one.
- **Tests:**
  - each DAO path gives the same result with a chunk size of 2 as with one
    pass;
  - one real test runs a batch move of 33 000 cards past the SQLite limit.
    It is tagged `slow` if it is too slow for the local gate, and it still
    runs in CI.
- **Records:**
  - WBS BE-C2 → `xong`;
  - BE-C1 → closed, with the owner's decision of 2026-09-27 (names keep
    code-unit order).

## 6. G3 — BE-D7 with BE-D3: nothing of V7 left in skills and documents

- **Skills and documents** (17 files today):
  - remove Widgetbook from the Definition of Done and from the
    `flutter-feature-slice` and `flutter-design-system` skills;
  - repoint `docs/wbs.md` to `docs/wbs_BE.md` and `docs/wbs_FE.md`, and
    repoint the V7 checklist to the V8 documents;
  - remove the V7 baselines and blueprints, and the installation record of
    `project-documentation`;
  - remove the V7 history from the comments of `check_format.sh`,
    `check_generated.sh` and `check_architecture.py`.
- **BE-D3.** `host-coverage-map.md` drops "V8 chưa có test nào" and points to
  the grep that counts the real coverage.
- **Guard against regression.** `tools/docs/check.py` reports an **error** when
  `.claude/skills/**` or `docs/**` mentions Widgetbook, `docs/wbs.md` or
  `memox-v7`. Historical records (ADRs, closed specs and plans) are excluded
  by path, each with its reason. The check fails before the clean-up and
  passes after it.
- **Records:** WBS BE-D7 and BE-D3 → `xong`.

## 7. G4 — BE-D4: acceptance criteria for 18 UCs

- **Scope (D4).** In 18 UC files, only the placeholder line of
  `## Acceptance criteria` (the open-question marker saying the source has no
  criteria yet) is replaced. UC-TRANSFER-001, UC-TRANSFER-002,
  UC-REMINDER-001 and UC-STARTER-001 already carry criteria and are not
  touched.
- **Form.** Follow those four UCs:
  `- [ ] **Given** … **when** … **then** … (BR-…, E2)`. There is at least one
  criterion per main-flow outcome and one per alternative or error flow.
- **Source.** Only the UC itself and its `active` rules. Every criterion is
  checked against the code and tests.
  - Where the UC and the code disagree, neither is edited. The criterion
    becomes an open-question line, with the repo's marker, inside the same
    section, as the
    placeholder convention already does.
  - These questions are listed in the PR and in the final report.
- **Guard.** `tools/docs/check.py` reports an error when a `ready` UC's
  acceptance criteria hold no Given/When/Then line.
- **Records:** WBS BE-D4 → `xong`, with any open questions it recorded.

## 8. G5 — BE-B5b: the daily reminder on Android

- **Dependencies:**
  - `android_alarm_manager_plus`: an inexact one-shot alarm with
    `allowWhileIdle`, rescheduled on reboot, calling a Dart callback;
  - `flutter_local_notifications`: shows the reminder under a fixed id and
    carries the tap payload.

  Spec 11a §13 chose these because every operation of its port exists in
  them. The package spec pins their versions.
- **Adapter.** `AndroidReminderPlatformRepository` implements the existing
  `ReminderPlatformRepository` port. The use cases do not change and keep
  their tests. Web keeps the "unsupported" adapter.
- **Serialising operations** (spec 11a §14):
  - A data-layer `ReminderOperationGate` runs Enable, Disable and Reconcile
    one at a time.
  - The background Deliver runs in its own isolate and reads the settings at
    fire time. An overlap therefore costs at most one late reminder, which
    D12 of spec 11a already accepts.
- **Entry points:**
  - a `@pragma('vm:entry-point')` background callback opens its own database
    connection and runs `DeliverReminderUseCase`;
  - a tap on the notification opens Study Home;
  - app start runs Reconcile through the gate.
- **Platform files:**
  - `AndroidManifest.xml`: `POST_NOTIFICATIONS` and the boot receiver;
  - gradle: core-library desugaring.
- **Verification:**
  - On the host: adapter tests against a thin wrapper around the plugins,
    tests of the gate's serialisation, and a test of the payload routing.
  - With an SDK or a device: `flutter build apk`, then a device check that
    the reminder fires, the tap opens Study Home, and it survives a reboot.
    Without one, the package stops here (D5). Its PR still ships the
    host-verified part, and the WBS row reads `đang làm` until the device
    check passes.
- **Records:**
  - WBS BE-B5b;
  - UC-REMINDER-001 `code:` gains the adapter;
  - the reminders README.
- **Rollback:** revert to the unsupported adapter and remove the two
  packages.

## 9. Risks

- **G1's migration touches every user row once.** It runs in one transaction;
  a failure rolls back and leaves v3 intact. It is tested on the upgrade
  framework with Vietnamese and Hangul data, including colliding tags.
- **G1 and the sync slice** both migrate the schema. G1 lands first (D2), so
  the sync migration builds on v4.
- **G2's chunking** changes no result, only how many statements run; the
  chunk-size-2 tests pin that.
- **G5 depends on the environment** (D5).
- **master moves under this work** (API services, FE packages). Each package
  merges `origin/master` before its gate.

## 10. Out of scope

- The app-side sync slices and login (ADR-013 steps 3–5).
- The server, `memox-api-services`.
- Mastery of the deck list. It needs rules written into the deck BR/UC first,
  as `wbs_BE.md` notes under blockers.
- BE-D1's per-migration work beyond G1's own snapshot.
