# Study P1b — Study Entry (FE-A6) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Screen 14, the Study Entry, reachable from a deck's action sheet and from the card list's summary, showing the deck's New and Due, the overdue note, the Learn row, the review modes and the nothing-due state; and the app closing yesterday's open sessions when it starts.

**Architecture:** A read-only screen in `lib/features/study/presentation/` over `WatchStudyEntryUseCase`. What the entry may offer is a pure function of the entry and the set of study modes the app has built (`builtStudyModes`, empty in P1b: spec §3 "unbuilt stages are never offered"), so this phase opens no session; P1c builds the session screen and P2 makes `sm2` usable. The deck's name and breadcrumb come from the deck feature, composed by `app/` (D16).

**Tech Stack:** Flutter 3.47.5, Riverpod 3 codegen, go_router, Drift (in-memory in tests), `flutter gen-l10n`.

**Spec:** [docs/superpowers/specs/2026-09-26-study-ui-design.md](../specs/2026-09-26-study-ui-design.md) — D1, D9, D10, D13, D15, D16, D19, §3. Screen: [14-study-entry.md](../../shared/ui/screen-handoff/14-study-entry.md). Built on [P1a](2026-09-26-study-p1a-foundations.md).

## Global Constraints

- `study` imports only `study_mode`, `srs`, `settings`, `card` (`test/architecture/boundary_rules.dart`); the deck's name and path come in as widgets built by `app/`.
- Presentation files end in `_screen`, `_widget`, `_controller`, `_state`, `_page`, `_view` or `_provider`.
- Every user-facing string is an ARB key in `app_en.arb` and `app_vi.arb`; no interpolated literal in a widget (guard `no_literal_user_string`).
- No `ref.read` in a `build()` body, even inside a closure (guard `no_ref_read_in_build`): read in a method.
- No colour, text style, radius or padding passed to a shared widget. Screen 14 uses no D14 tone; its stat tiles take `primary` above zero and `plain` at zero (D17 as reworded after the P1a review).
- `builtStudyModes` is `const <StudyMode>{}` in this plan; nothing on the entry starts or continues a session.
- Goldens on Linux only; Hangul renders as boxes in the test fonts, so golden seeds use Latin/Vietnamese names.

## Review Focus

1. A deck deleted while its entry is open must leave the entry with a message, not a spinner or a crash — pinned in Task 4 (deleted-deck test).
2. New and Due must never be summed into one action, and a zero stays a visible 0 (IT-STUDY-001) — pinned in Task 4.
3. A mode the backend cannot run shows its reason; a mode the app has not built says "Coming soon"; neither is tappable — pinned in Task 2 (offer tests) and Task 4.
4. Back from the entry returns to the deck it was opened from, with no session created (IT-NAV-008) — pinned in Task 5 (route test).
5. A session left open yesterday is closed as interrupted when the app starts, without delaying the first frame — pinned in Task 5.

---

## File map

| File | Action | Responsibility |
|---|---|---|
| `lib/l10n/app_en.arb`, `app_vi.arb` | modify | entry copy |
| `lib/features/study/presentation/providers/watch_study_entry_use_case_provider.dart` | create | use case wiring |
| `lib/features/study/presentation/providers/study_entry_provider.dart` | create | the entry stream per deck |
| `lib/features/study/presentation/providers/abandon_stale_sessions_use_case_provider.dart` | create | use case wiring |
| `lib/features/study/presentation/states/study_entry_offer_state.dart` | create | what the entry offers (pure) |
| `lib/features/study/presentation/widgets/support/study_labels_widget.dart` | create | labels of modes, kinds, schedulers, reasons |
| `lib/features/study/presentation/widgets/sections/study_entry_hero_widget.dart` | create | hero |
| `lib/features/study/presentation/widgets/sections/study_entry_learn_widget.dart` | create | Learn row |
| `lib/features/study/presentation/widgets/sections/study_entry_review_widget.dart` | create | review modes |
| `lib/features/study/presentation/widgets/sections/study_entry_body_widget.dart` | create | the states |
| `lib/features/study/presentation/screens/study_entry_screen.dart` | create | the screen |
| `lib/features/deck/presentation/widgets/sections/deck_study_header_widget.dart` | create | deck name + breadcrumb for `app/` |
| `lib/app/router/app_routes.dart`, `app_router.dart` | modify | route, entry points |
| `lib/app/app.dart` | modify | stale-session sweep |
| deck action sheet, deck actions flow, deck level screen and its bodies | modify | `DeckAction.study`, `onOpenStudy` |
| `lib/features/card/presentation/widgets/sections/card_deck_summary_widget.dart`, `card_list_section_widget.dart` | modify | "Study this deck" |
| `lib/features/deck/presentation/widgets/overlays/deck_coming_soon_sheet_widget.dart` | modify | Study leaves Coming soon |
| tests, goldens, companion, docs | create/modify | proofs and records |

---

### Task 1: Strings

**Files:** Modify `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`.

**Interfaces — Produces** (`context.l10n`): `studyEntryOverline(String algorithm, int limit)`, `studyEntryNew`, `studyEntryDue`, `studyEntryOverdue(int count)`, `studyEntryNothingTitle`, `studyEntryNothingBody`, `studyEntryLearnTitle`, `studyEntryLearnStagesSm2`, `studyEntryLearnStagesEightBox`, `studyEntryLearnCount(int shown, int total)`, `studyEntryReviewHeader`, `studyEntryModeMatchBody`, `studyEntryModeGuessBody`, `studyEntryModeRecallBody`, `studyEntryModeFillBody`, `studyEntryModeCards(int count)`, `studyEntryNotAvailable`, `studyEntryUnavailableNote`, `studyEntryReasonNoExample`, `studyEntryReasonTooFewPairs`, `studyEntryReasonTooFewMeanings`, `studyComingSoon`, `studyEntryDeckGone`, `deckStudy`, `cardStudyThisDeck(int due)`.

- [ ] **Step 1: Add the English keys** (each with an `@` description "Screen handoff 14 (FE-A6): …" or "Screen handoff 07/01 (FE-A6 D10): …"; placeholders typed `String`/`int`):

| Key | English | Vietnamese |
|---|---|---|
| `studyEntryOverline` | `{algorithm} · cards per session {limit}` | `{algorithm} · {limit} thẻ mỗi phiên` |
| `studyEntryNew` | `New` | `Mới` |
| `studyEntryDue` | `Due` | `Đến hạn` |
| `studyEntryOverdue` | `{count} of the due cards are overdue` | `{count} thẻ đến hạn đã quá hạn` |
| `studyEntryNothingTitle` | `Nothing to do right now` | `Hiện chưa có gì để học` |
| `studyEntryNothingBody` | `Every card is learned and resting. Cards cannot be reviewed before they are due.` | `Mọi thẻ đã học và đang nghỉ. Thẻ chỉ ôn được khi đến hạn.` |
| `studyEntryLearnTitle` | `Learn new cards` | `Học thẻ mới` |
| `studyEntryLearnStagesSm2` | `Browse, then self-assess` | `Xem thẻ, rồi tự đánh giá` |
| `studyEntryLearnStagesEightBox` | `Browse → match → guess → recall → fill` | `Xem → ghép → đoán → nhớ lại → điền` |
| `studyEntryLearnCount` | `{shown} of {total} new · in creation order` | `{shown} trên {total} thẻ mới · theo thứ tự tạo` |
| `studyEntryReviewHeader` | `Review · choose how cards are asked` | `Ôn tập · chọn cách hỏi thẻ` |
| `studyEntryModeMatchBody` | `Pair terms with meanings, up to 5 at a time` | `Ghép từ với nghĩa, tối đa 5 cặp một lần` |
| `studyEntryModeGuessBody` | `Pick the meaning out of five` | `Chọn nghĩa đúng trong năm` |
| `studyEntryModeRecallBody` | `Recall the meaning within 20 seconds` | `Nhớ lại nghĩa trong 20 giây` |
| `studyEntryModeFillBody` | `Type the term for the meaning` | `Gõ từ cho nghĩa` |
| `studyEntryModeCards` | `{count} cards` | `{count} thẻ` |
| `studyEntryNotAvailable` | `Not available` | `Chưa dùng được` |
| `studyEntryUnavailableNote` | `A mode that is not available lacks suitable cards for this review — it comes back when the cards qualify.` | `Chế độ chưa dùng được là vì thiếu thẻ phù hợp cho lần ôn này — nó sẽ có lại khi thẻ đủ điều kiện.` |
| `studyEntryReasonNoExample` | `Needs an example on the due cards` | `Cần ví dụ trên các thẻ đến hạn` |
| `studyEntryReasonTooFewPairs` | `Needs at least two due cards` | `Cần ít nhất hai thẻ đến hạn` |
| `studyEntryReasonTooFewMeanings` | `Needs five different meanings among the due cards` | `Cần năm nghĩa khác nhau trong các thẻ đến hạn` |
| `studyComingSoon` | `Coming soon` | `Sắp có` |
| `studyEntryDeckGone` | `This deck no longer exists` | `Bộ thẻ này không còn nữa` |
| `deckStudy` | `Study` | `Học` |
| `cardStudyThisDeck` | `Study this deck · {due} due` | `Học bộ thẻ này · {due} đến hạn` |

(Check first with `grep -n '"deckStudy"\|"studyComingSoon"' lib/l10n/app_en.arb`; if a key exists, keep it and skip the row.) Check `ModeUnavailableReason` for every value (`grep -n "^  [a-z][A-Za-z]*,$" lib/features/study_mode/domain/models/stage_eligibility_model.dart`) and add one `studyEntryReason…` key per value that the table does not already cover.

- [ ] **Step 2: Generate and test**

Run: `flutter gen-l10n && flutter analyze && flutter test test/l10n`
Expected: generation succeeds, clean, PASS.

- [ ] **Step 3: Commit** — `git add lib/l10n && git commit -m "feat(l10n): Study Entry strings (FE-A6)"`

---

### Task 2: What the entry offers

**Files:**
- Create: `lib/features/study/presentation/states/study_entry_offer_state.dart`, `lib/features/study/presentation/widgets/support/study_labels_widget.dart`
- Test: `test/features/study/presentation/study_entry_offer_state_test.dart`

**Interfaces:**
- Consumes: `StudyEntry`, `ReviewModeOption`, `stageSequenceOf(SchedulerType)`, `ModeUnavailableReason`.
- Produces:

```dart
const Set<StudyMode> builtStudyModes = <StudyMode>{};

enum ReviewOfferStatus { available, unavailable, comingSoon }

final class ReviewOffer {
  final ReviewModeOption option;
  final ReviewOfferStatus status;
}

final class StudyEntryOffer {
  final bool isNothingDue;
  final bool canLearn;
  final bool isLearnComingSoon;
  final int learnShown;
  final List<ReviewOffer> reviews;
  final bool canContinue;
}

StudyEntryOffer studyEntryOfferOf(StudyEntry entry, {Set<StudyMode> built = builtStudyModes});
```

and the label extension `StudyLabels on AppLocalizations`: `studyMode(StudyMode)`, `studyScheduler(SchedulerType)`, `studyReason(ModeUnavailableReason)`, `studyModeBody(StudyMode)` (null for modes with no entry description).

- [ ] **Step 1: Failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/presentation/states/study_entry_offer_state.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

// Spec §3: what the Study Entry offers is what the app has built.

StudyEntry _entry({
  SchedulerType type = SchedulerType.eightBox,
  int fresh = 3,
  int due = 2,
  List<ReviewModeOption> reviews = const [],
}) => StudyEntry(
  schedulerType: type,
  cardLimit: 2,
  newCardCount: fresh,
  dueCardCount: due,
  overdueCardCount: 0,
  nextDueAt: null,
  reviewModes: reviews,
  resumable: null,
);

ReviewModeOption _mode(StudyMode mode, {ModeUnavailableReason? reason}) =>
    ReviewModeOption(
      mode: mode,
      cardCount: reason == null ? 2 : 0,
      unavailableReason: reason,
      isDirectionRequired: false,
    );

void main() {
  test('with nothing built, nothing is offered: Learn and every runnable '
      'mode are coming soon, an unrunnable mode keeps its reason', () {
    final offer = studyEntryOfferOf(
      _entry(
        reviews: [
          _mode(StudyMode.match),
          _mode(StudyMode.fill, reason: ModeUnavailableReason.noExample),
        ],
      ),
    );

    expect(offer.canLearn, isFalse);
    expect(offer.isLearnComingSoon, isTrue);
    expect(offer.canContinue, isFalse);
    expect([for (final review in offer.reviews) review.status], [
      ReviewOfferStatus.comingSoon,
      ReviewOfferStatus.unavailable,
    ]);
  });

  test('Learn is offered only when every stage of the sequence is built '
      '(BR-MODE-004)', () {
    final sequence = stageSequenceOf(SchedulerType.sm2).toSet();

    expect(
      studyEntryOfferOf(
        _entry(type: SchedulerType.sm2),
        built: sequence,
      ).canLearn,
      isTrue,
    );
    expect(
      studyEntryOfferOf(
        _entry(type: SchedulerType.sm2),
        built: {StudyMode.browse},
      ).canLearn,
      isFalse,
    );
  });

  test('a built runnable mode is available', () {
    final offer = studyEntryOfferOf(
      _entry(reviews: [_mode(StudyMode.recall)]),
      built: {StudyMode.recall},
    );

    expect(offer.reviews.single.status, ReviewOfferStatus.available);
  });

  test('no new card: Learn is neither offered nor coming soon; its count '
      'is capped by the session limit', () {
    expect(studyEntryOfferOf(_entry(fresh: 0)).isLearnComingSoon, isFalse);
    expect(studyEntryOfferOf(_entry(fresh: 5)).learnShown, 2);
  });

  test('nothing new and nothing due is the nothing-due state '
      '(BR-STUDY-008)', () {
    expect(studyEntryOfferOf(_entry(fresh: 0, due: 0)).isNothingDue, isTrue);
    expect(studyEntryOfferOf(_entry(fresh: 0, due: 1)).isNothingDue, isFalse);
  });
}
```

- [ ] **Step 2: Run to see it fail**

Run: `flutter test test/features/study/presentation/study_entry_offer_state_test.dart`
Expected: FAIL — the file does not exist.

- [ ] **Step 3: Implement**

`study_entry_offer_state.dart`:

```dart
import 'dart:math';

import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The study modes the app has a screen for. It grows each phase and goes
/// once all six are built (spec §3): an unbuilt stage is never offered.
const Set<StudyMode> builtStudyModes = <StudyMode>{};

/// How the entry shows a review mode.
enum ReviewOfferStatus {
  /// Runnable and built: it can be picked.
  available,

  /// The backend cannot run it on these cards; its reason shows
  /// (BR-STUDY-044, BR-MODE-009).
  unavailable,

  /// Runnable, but the app has no screen for it yet (spec §3).
  comingSoon,
}

/// A review mode and how the entry shows it.
final class ReviewOffer {
  const ReviewOffer({required this.option, required this.status});

  final ReviewModeOption option;
  final ReviewOfferStatus status;
}

/// What the Study Entry offers (UC-STUDY-001 steps 2–4; spec §3).
final class StudyEntryOffer {
  const StudyEntryOffer({
    required this.isNothingDue,
    required this.canLearn,
    required this.isLearnComingSoon,
    required this.learnShown,
    required this.reviews,
    required this.canContinue,
  });

  /// Nothing new and nothing due (BR-STUDY-008, BR-STUDY-054).
  final bool isNothingDue;

  /// New cards exist and every stage of the sequence is built (BR-MODE-004).
  final bool canLearn;

  /// New cards exist but a stage of the sequence is not built.
  final bool isLearnComingSoon;

  /// The new cards a learning session would take, capped by the session
  /// limit (BR-STUDY-003).
  final int learnShown;
  final List<ReviewOffer> reviews;

  /// A resumable session whose current mode is built (BR-STUDY-075).
  final bool canContinue;
}

StudyEntryOffer studyEntryOfferOf(
  StudyEntry entry, {
  Set<StudyMode> built = builtStudyModes,
}) {
  final hasNew = entry.newCardCount > 0;
  final isSequenceBuilt = stageSequenceOf(
    entry.schedulerType,
  ).every(built.contains);
  final resumable = entry.resumable;
  return StudyEntryOffer(
    isNothingDue: entry.newCardCount == 0 && entry.dueCardCount == 0,
    canLearn: hasNew && isSequenceBuilt,
    isLearnComingSoon: hasNew && !isSequenceBuilt,
    learnShown: min(entry.newCardCount, entry.cardLimit),
    reviews: [
      for (final option in entry.reviewModes)
        ReviewOffer(
          option: option,
          status: switch ((option.unavailableReason, built.contains(option.mode))) {
            (_?, _) => ReviewOfferStatus.unavailable,
            (null, true) => ReviewOfferStatus.available,
            (null, false) => ReviewOfferStatus.comingSoon,
          },
        ),
    ],
    canContinue: resumable != null && built.contains(resumable.mode),
  );
}
```

(If `stageSequenceOf` lives in `study_mode.dart` as found at line 58, the import above covers it.)

`study_labels_widget.dart` (switches must be exhaustive; one case per enum value):

```dart
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The study screens' names for the domain's modes, schedulers and reasons.
extension StudyLabels on AppLocalizations {
  String studyMode(StudyMode mode) => switch (mode) {
    StudyMode.browse => cardModeBrowse,
    StudyMode.selfAssess => cardModeSelfAssess,
    StudyMode.match => cardModeMatch,
    StudyMode.guess => cardModeGuess,
    StudyMode.recall => cardModeRecall,
    StudyMode.fill => cardModeFill,
  };

  /// The entry's one-line description of a review mode; null for a mode
  /// the entry never lists (BR-STUDY-055).
  String? studyModeBody(StudyMode mode) => switch (mode) {
    StudyMode.match => studyEntryModeMatchBody,
    StudyMode.guess => studyEntryModeGuessBody,
    StudyMode.recall => studyEntryModeRecallBody,
    StudyMode.fill => studyEntryModeFillBody,
    StudyMode.browse || StudyMode.selfAssess => null,
  };

  String studyScheduler(SchedulerType type) => switch (type) {
    SchedulerType.eightBox => deckSchedulerEightBox,
    SchedulerType.sm2 => deckSchedulerSm2,
  };

  String studyReason(ModeUnavailableReason reason) => switch (reason) {
    ModeUnavailableReason.noExample => studyEntryReasonNoExample,
    ModeUnavailableReason.tooFewPairs => studyEntryReasonTooFewPairs,
    ModeUnavailableReason.tooFewMeanings => studyEntryReasonTooFewMeanings,
  };
}
```

Adjust the enum member names (`StudyMode.selfAssess`, `SchedulerType.eightBox`, the reasons) to the real ones (`grep -n "enum StudyMode" -A12 lib/features/study_mode/domain/models/study_mode.dart`); add a case for every reason value.

- [ ] **Step 4: Run and commit**

Run: `flutter test test/features/study/presentation/study_entry_offer_state_test.dart && flutter analyze`
Expected: PASS, clean.

```bash
git add lib/features/study/presentation test/features/study/presentation
git commit -m "feat(study): what the Study Entry offers, from what is built (FE-A6 §3)"
```

---

### Task 3: Providers and the deck header

**Files:**
- Create: `lib/features/study/presentation/providers/watch_study_entry_use_case_provider.dart`, `study_entry_provider.dart`, `abandon_stale_sessions_use_case_provider.dart`; `lib/features/deck/presentation/widgets/sections/deck_study_header_widget.dart`
- Test: `test/features/deck/presentation/deck_study_header_test.dart`

**Interfaces:**
- Produces: `watchStudyEntryUseCaseProvider`; `studyEntryProvider(String deckId)` → `Stream<Outcome<StudyEntry, StudyRejection>>`; `abandonStaleSessionsUseCaseProvider`; `DeckStudyHeaderWidget({required String deckId, required DeckStudyHeaderPart part})` with `enum DeckStudyHeaderPart { title, breadcrumb }`.

- [ ] **Step 1: The providers** (the day clock provider is `dayClockProvider`, `lib/core/clock/di/day_clock_provider.dart`; the repositories' providers are in `lib/features/study/di/`):

```dart
// watch_study_entry_use_case_provider.dart
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/study/di/study_entry_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/watch_study_entry_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_study_entry_use_case_provider.g.dart';

@riverpod
WatchStudyEntryUseCase watchStudyEntryUseCase(Ref ref) =>
    WatchStudyEntryUseCase(
      ref.watch(studyEntryRepositoryProvider),
      ref.watch(dayClockProvider),
    );
```

```dart
// study_entry_provider.dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/presentation/providers/watch_study_entry_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_entry_provider.g.dart';

/// [deckId]'s Study Entry, again on every change and at each local
/// midnight; notFound once the deck is gone (UC-STUDY-001 E1).
@riverpod
Stream<Outcome<StudyEntry, StudyRejection>> studyEntry(
  Ref ref,
  String deckId,
) => ref.watch(watchStudyEntryUseCaseProvider)(deckId: deckId);
```

```dart
// abandon_stale_sessions_use_case_provider.dart
import 'package:memox/features/study/di/study_session_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/abandon_stale_sessions_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'abandon_stale_sessions_use_case_provider.g.dart';

@riverpod
AbandonStaleSessionsUseCase abandonStaleSessionsUseCase(Ref ref) =>
    AbandonStaleSessionsUseCase(ref.watch(studySessionRepositoryProvider));
```

(`StudyRejection`'s file: `grep -rn "enum StudyRejection" lib/features/study/domain`.)

- [ ] **Step 2: Failing test for the deck header**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_study_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('the title names the deck; the breadcrumb runs from the '
      'Library to the deck (FE-A6 D16)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final lesson = await env.decks.sub(korean.id, 'Lesson');
    await pumpLibraryScreen(
      tester,
      env,
      Column(
        children: [
          DeckStudyHeaderWidget(
            deckId: lesson.id,
            part: DeckStudyHeaderPart.title,
          ),
          DeckStudyHeaderWidget(
            deckId: lesson.id,
            part: DeckStudyHeaderPart.breadcrumb,
          ),
        ],
      ),
    );

    expect(find.text('Lesson'), findsNWidgets(2));
    expect(find.text(_en.navLibrary), findsOneWidget);
    expect(find.text('Korean'), findsOneWidget);
  });
}
```

Run: `flutter test test/features/deck/presentation/deck_study_header_test.dart` — Expected: FAIL (no widget).

- [ ] **Step 3: The deck header** (`deck_study_header_widget.dart`; pattern of `deck_context_header_widget.dart`, which reads `deckViewProvider`):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/presentation/providers/deck_view_provider.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';

/// Which half of the Study Entry's deck context to draw.
enum DeckStudyHeaderPart { title, breadcrumb }

/// The deck a Study Entry is for: its name as the app bar's title, or its
/// path from the Library (screen 14). `app/` passes it to the study screen,
/// which may not read the deck feature (FE-A6 D16). Blank while loading and
/// once the deck is gone: the entry itself says so.
class DeckStudyHeaderWidget extends ConsumerWidget {
  const DeckStudyHeaderWidget({
    super.key,
    required this.deckId,
    required this.part,
  });

  final String deckId;
  final DeckStudyHeaderPart part;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = switch (ref.watch(deckViewProvider(deckId))) {
      AsyncData(value: Ok(:final value)) => value,
      _ => null,
    };
    if (view == null) return const SizedBox.shrink();
    return switch (part) {
      DeckStudyHeaderPart.title => Text(
        view.deck.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textStyles.screenTitle,
      ),
      DeckStudyHeaderPart.breadcrumb => MxBreadcrumb(
        segments: [
          MxBreadcrumbSegment(label: context.l10n.navLibrary),
          for (final entry in view.breadcrumb)
            MxBreadcrumbSegment(label: entry.name),
          MxBreadcrumbSegment(label: view.deck.name),
        ],
      ),
    };
  }
}
```

(If `MxAppBar`'s own title style differs from `screenTitle` in content density, use the role `MxAppBar` applies to `title` — read `mx_app_bar.dart` — so the entry's title looks like every other content bar.)

- [ ] **Step 4: Generate, run, commit**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/features/deck/presentation/deck_study_header_test.dart && flutter analyze && bash .claude/skills/flutter-architecture/scripts/check_architecture.sh`
Expected: PASS, clean.

```bash
git add lib/features/study/presentation lib/features/deck/presentation test/features/deck/presentation
git commit -m "feat(study): entry providers; the deck header for the entry (FE-A6 D16)"
```

---

### Task 4: The Study Entry screen

**Files:**
- Create: `lib/features/study/presentation/widgets/sections/study_entry_hero_widget.dart`, `study_entry_learn_widget.dart`, `study_entry_review_widget.dart`, `study_entry_body_widget.dart`; `lib/features/study/presentation/screens/study_entry_screen.dart`
- Test: `test/features/study/presentation/study_entry_screen_test.dart`

**Interfaces:**
- Consumes: Tasks 1–3; `MxStatTile`, `MxCard`, `MxListRow`, `MxOptionRow`, `MxBadge`, `MxNote`, `MxEmptyState`, `MxSkeletonList`, `MxListSectionHeader`, `MxAppShell`, `MxAppBar`, `MxIconButton`, `MxScreenScroll`, `showMxSnackbar`.
- Produces: `StudyEntryScreen({required String deckId, required Widget title, required Widget breadcrumb})`.

**Rulings carried by this task (P1b has nothing to start):** the footer is drawn only when the entry offers an action, so in P1b it is never drawn; the Learn row's trailing is the `Learn` button when `canLearn`, an `MxBadge` "Coming soon" when `isLearnComingSoon`, nothing otherwise; the resume banner is drawn only when `canContinue`; SM-2 has no review list on this screen (its direction sheet is P2). The deck gone: the screen pops and a snackbar says `studyEntryDeckGone`. New and Due tiles: `primary` emphasis when their count is above 0, `plain` at 0 (kit `eightBox`).

- [ ] **Step 1: Failing screen tests** (`library harness`; learned cards need `lockScheduler`, as in `test/features/study/data/watch_entry_test.dart`; import `lockScheduler` from `test/support/study_fixtures.dart`):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

// UC-STUDY-001 steps 1–4 on screen 14; IT-STUDY-001, IT-STUDY-004.

final _en = lookupAppLocalizations(const Locale('en'));

StudyEntryScreen _screen(String deckId) => StudyEntryScreen(
  deckId: deckId,
  title: const Text('Deck'),
  breadcrumb: const SizedBox.shrink(),
);

Future<void> _learned(LibraryEnv env, String deckId, String id, DateTime due,
    {String? example}) => insertCard(
  env.db,
  id: id,
  deckId: deckId,
  back: 'meaning $id',
  example: example,
  learnedAt: DateTime(2026, 9, 1),
  dueAt: due,
  box: 2,
);

void main() {
  libraryTest('New and Due are two figures, never one sum, and the overdue '
      'note counts the due cards from before today (IT-STUDY-001)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    final leaf = await env.decks.sub(root.id, 'Lesson');
    await insertCard(env.db, id: 'n1', deckId: leaf.id);
    await insertCard(env.db, id: 'n2', deckId: leaf.id);
    await _learned(env, leaf.id, 'd1', DateTime(2026, 9, 20));
    await _learned(env, leaf.id, 'd2', DateTime(2026, 9, 24, 8));
    await lockScheduler(env.db, root.id);
    await pumpLibraryScreen(tester, env, _screen(leaf.id));

    expect(find.byType(MxStatTile), findsNWidgets(2));
    expect(find.text('2'), findsNWidgets(2));
    expect(find.text(_en.studyEntryNew.toUpperCase()), findsOneWidget);
    expect(find.text(_en.studyEntryDue.toUpperCase()), findsOneWidget);
    expect(find.text('4'), findsNothing);
    expect(find.text(_en.studyEntryOverdue(1)), findsOneWidget);
  });

  libraryTest('Eight boxes lists its four review modes, each with its '
      'count or its reason, none tappable before it is built '
      '(IT-STUDY-004, spec §3)', (tester, env) async {
    final root = await env.decks.root('Korean');
    for (final id in ['a', 'b', 'c']) {
      await _learned(env, root.id, id, DateTime(2026, 9, 20));
    }
    await lockScheduler(env.db, root.id);
    await pumpLibraryScreen(tester, env, _screen(root.id));

    final rows = tester.widgetList<MxOptionRow>(find.byType(MxOptionRow));
    expect([for (final row in rows) row.title], [
      _en.cardModeMatch,
      _en.cardModeGuess,
      _en.cardModeRecall,
      _en.cardModeFill,
    ]);
    expect(rows.every((row) => row.onSelected == null), isTrue);
    expect(find.widgetWithText(MxBadge, _en.studyEntryNotAvailable),
        findsWidgets);
    expect(find.widgetWithText(MxBadge, _en.studyComingSoon), findsWidgets);
    expect(find.byType(MxFooterBar), findsNothing);
  });

  libraryTest('SM-2 lists no review modes on the entry; Learn is coming '
      'soon while its stages are not built', (tester, env) async {
    final root = await env.decks.root('Korean', SchedulerType.sm2);
    await insertCard(env.db, id: 'n1', deckId: root.id);
    await pumpLibraryScreen(tester, env, _screen(root.id));

    expect(find.byType(MxOptionRow), findsNothing);
    expect(find.text(_en.studyEntryLearnTitle), findsOneWidget);
    expect(find.text(_en.studyEntryLearnStagesSm2, findRichText: true),
        findsWidgets);
    expect(find.widgetWithText(MxBadge, _en.studyComingSoon), findsOneWidget);
  });

  libraryTest('nothing new and nothing due is the calm empty state '
      '(BR-STUDY-008)', (tester, env) async {
    final root = await env.decks.root('Korean');
    await _learned(env, root.id, 'later', DateTime(2026, 10, 1));
    await lockScheduler(env.db, root.id);
    await pumpLibraryScreen(tester, env, _screen(root.id));

    expect(find.byType(MxEmptyState), findsOneWidget);
    expect(find.text(_en.studyEntryNothingTitle), findsOneWidget);
    expect(find.byType(MxStatTile), findsNothing);
  });

  libraryTest('a deck deleted while its entry is open leaves with a message '
      '(UC-STUDY-001 E1)', (tester, env) async {
    final root = await env.decks.root('Korean');
    await insertCard(env.db, id: 'n1', deckId: root.id);
    await tester.pumpWidget(const SizedBox());
    await pumpLibraryScreen(
      tester,
      env,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => _screen(root.id)),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await env.decks.deleteDeck(deckId: root.id);
    await tester.pumpAndSettle();

    expect(find.byType(StudyEntryScreen), findsNothing);
    expect(find.text(_en.studyEntryDeckGone), findsOneWidget);
  });
}
```

(Use the deck repository's real delete method — `grep -n "Future<Outcome.*delete" lib/features/deck/domain/repositories/deck_repository.dart` — and `SchedulerType`'s real member names. `env.decks.root(name, type)` takes the scheduler as its second argument, as in `watch_entry_test.dart`.)

Run: `flutter test test/features/study/presentation/study_entry_screen_test.dart` — Expected: FAIL (no screen).

- [ ] **Step 2: The hero** (`study_entry_hero_widget.dart`):

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';

/// Screen 14's hero: the algorithm and the session limit, New and Due as
/// two figures that never merge (BR-STUDY-051), and the overdue note.
class StudyEntryHeroWidget extends StatelessWidget {
  const StudyEntryHeroWidget({super.key, required this.entry});

  final StudyEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final overline = l10n.studyEntryOverline(
      l10n.studyScheduler(entry.schedulerType),
      entry.cardLimit,
    );
    MxStatTileEmphasis emphasisOf(int count) => count > 0
        ? MxStatTileEmphasis.primary
        : MxStatTileEmphasis.plain;
    return MxCard(
      isHero: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.grouped,
        children: [
          Text(
            overline.toUpperCase(),
            semanticsLabel: overline,
            style: styles.overline,
          ),
          Row(
            spacing: AppSpacing.control,
            children: [
              Expanded(
                child: MxStatTile(
                  value: '${entry.newCardCount}',
                  label: l10n.studyEntryNew,
                  emphasis: emphasisOf(entry.newCardCount),
                  layout: MxStatTileLayout.boxed,
                ),
              ),
              Expanded(
                child: MxStatTile(
                  value: '${entry.dueCardCount}',
                  label: l10n.studyEntryDue,
                  emphasis: emphasisOf(entry.dueCardCount),
                  layout: MxStatTileLayout.boxed,
                ),
              ),
            ],
          ),
          if (entry.overdueCardCount > 0)
            Text(
              l10n.studyEntryOverdue(entry.overdueCardCount),
              style: styles.noteText,
            ),
        ],
      ),
    );
  }
}
```

If the guard flags `'${entry.newCardCount}'` as a literal user string, add an ARB key `studyCount(int count)` = `{count}` (as `searchGroupCount` does) and use it.

- [ ] **Step 3: The Learn row** (`study_entry_learn_widget.dart`): an `MxCard(isFullBleed: true)` holding one `MxListRow` — `title: l10n.studyEntryLearnTitle`, `subtitle:` the stages line (`studyEntryLearnStagesSm2`/`…EightBox` by scheduler) `+ ' · ' +`… is an interpolated literal, so the subtitle is two keys joined through one more ARB key `studyEntryLearnLine(String stages, String count)` = `{stages} · {count}` (add it to Task 1's files in this step, en and vi identical) with `count: l10n.studyEntryLearnCount(offer.learnShown, entry.newCardCount)`; `trailing:` the `MxButton(label: l10n.studyEntryLearn …)` only when `offer.canLearn` (P1b: never; the button's `onPressed` is a `VoidCallback? onLearn` parameter the P1c/P2 phase wires), else `MxBadge(label: l10n.studyComingSoon, tone: MxBadgeTone.neutral)` when `offer.isLearnComingSoon`, else no trailing. Drawn only when `entry.newCardCount > 0`. Add the key `studyEntryLearn` = `Learn` / `Học` too.

- [ ] **Step 4: The review list** (`study_entry_review_widget.dart`): drawn only when `entry.reviewModes` has more than one mode (BR-STUDY-055; SM-2 has one and never shows it). `MxListSectionHeader(label: l10n.studyEntryReviewHeader)`, an `MxCard(isFullBleed: true)` of one `MxOptionRow` per `offer.reviews` — `title: l10n.studyMode(mode)`, `description:` the reason (`l10n.studyReason(reason)`) when `unavailable`, else `l10n.studyModeBody(mode)`; `isSelected: false`; `onSelected: null` for every status in P1b (an `available` row's selection is P1c/P2 work); `trailing: MxBadge` with `studyEntryModeCards(count)` (`tone: MxBadgeTone.primary`) when `available`, `studyEntryNotAvailable` (`neutral`) when `unavailable`, `studyComingSoon` (`neutral`) when `comingSoon`; `hasDivider` false on the last row — then `MxNote(text: l10n.studyEntryUnavailableNote)` when any row is `unavailable`.

- [ ] **Step 5: The body and the screen**

`study_entry_body_widget.dart` — a `ConsumerWidget` over `studyEntryProvider(deckId)`:

```dart
    return switch (ref.watch(studyEntryProvider(deckId))) {
      AsyncData(value: Ok(value: final entry)) => _loaded(context, entry),
      AsyncData(value: Rejected()) => const SizedBox.shrink(),
      AsyncError() => MxScreenScroll(children: [
        MxErrorState(
          title: l10n.searchErrorTitle,
          body: l10n.searchErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => _retry(ref),
        ),
      ]),
      _ => const MxScreenScroll(children: [MxSkeletonList()]),
    };
```

where `_retry(WidgetRef ref) => ref.invalidate(studyEntryProvider(deckId))` (a method, for the guard), and `_loaded` builds, with `final offer = studyEntryOfferOf(entry)`:
- `offer.isNothingDue` → `MxScreenScroll(children: [MxEmptyState(icon: AppIcons.learned, title: l10n.studyEntryNothingTitle, body: l10n.studyEntryNothingBody, tone: MxEmptyStateTone.success, isCompact: true)])`;
- otherwise `MxScreenScroll(children: [breadcrumb, gap, StudyEntryHeroWidget, gap, (learn row), gap, (review list)])`, the gaps `AppSpacing.grouped`.

(The error copy reuses the local-first `searchError*` pair only if its words fit; if they name search, add `studyEntryErrorTitle`/`Body` = "Couldn't read this deck" / "Your cards are safe on this device. Try again in a moment." in both ARBs.)

`study_entry_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/study/presentation/providers/study_entry_provider.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_entry_body_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 14: the Study Entry of a deck, the choice between Learn and
/// Review before a session opens (UC-STUDY-001 steps 1–4). The deck's name
/// and path come from `app/` (FE-A6 D16).
class StudyEntryScreen extends ConsumerWidget {
  const StudyEntryScreen({
    super.key,
    required this.deckId,
    required this.title,
    required this.breadcrumb,
  });

  final String deckId;
  final Widget title;
  final Widget breadcrumb;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The deck is gone (E1): leave with a word, once.
    ref.listen(studyEntryProvider(deckId), (_, next) {
      if (next case AsyncData(value: Rejected())) _leave(context);
    });
    return MxAppShell(
      appBar: MxAppBar(
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: context.l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
        titleWidget: title,
      ),
      body: StudyEntryBodyWidget(deckId: deckId, breadcrumb: breadcrumb),
    );
  }

  // The toast first, on this route's messenger (the shell's), then the pop.
  void _leave(BuildContext context) {
    showMxSnackbar(context, message: context.l10n.studyEntryDeckGone);
    unawaited(Navigator.of(context).maybePop());
  }
}
```

(`showMxSnackbar(context, message:)` returns the controller; it is not awaited.)

- [ ] **Step 6: Run, check, commit**

Run: `flutter test test/features/study/presentation && flutter analyze && python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`
Expected: PASS, clean, guard passes.

```bash
git add lib/features/study lib/l10n test/features/study
git commit -m "feat(study): screen 14, the Study Entry, read-only until modes are built (FE-A6)"
```

---

### Task 5: Route, entry points, stale sessions

**Files:**
- Modify: `lib/app/router/app_routes.dart`, `lib/app/router/app_router.dart`, `lib/app/app.dart`; `lib/features/deck/presentation/widgets/overlays/deck_action_sheet_widget.dart`, `…/support/deck_actions_flow_widget.dart`, `…/screens/deck_level_screen.dart` and the bodies that thread `onOpenAlgorithm` (`grep -rln "onOpenAlgorithm" lib/features/deck`), `…/overlays/deck_coming_soon_sheet_widget.dart`; `lib/features/card/presentation/widgets/sections/card_deck_summary_widget.dart`, `card_list_section_widget.dart`
- Test: `test/app/library_routes_test.dart`, `test/app/app_test.dart`, the deck action sheet test (`grep -rln "DeckActionSheetWidget\|showDeckActionSheet" test`), the coming-soon sheet test, the card summary test (`test/features/card/presentation/card_deck_summary_test.dart`)

**Interfaces:**
- Produces: `AppRoutes.studyChild = 'study'`, `AppRoutes.studyEntry(String deckId)` → `'${deck(deckId)}/study'`; `DeckAction.study`; `onOpenStudy` (`ValueChanged<String>`) threaded like `onOpenAlgorithm`; `CardDeckSummaryWidget.onStudy` / `CardListSectionWidget.onStudy` (`VoidCallback?`).

- [ ] **Step 1: Failing tests**

`test/app/library_routes_test.dart` — add (use the file's `_seed`, `_tap`, `_barTitle`, `_back` helpers and `pumpMemoxApp`):

```dart
  libraryTest('Study from a deck opens its entry; Back returns to that deck '
      'and no session is made (IT-NAV-008, FE-A6 D1, D10)', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await _tap(tester, find.text('Korean'));
    await _tap(tester, find.byTooltip(_en.deckMore));
    await _tap(tester, find.text(_en.deckStudy));

    expect(find.byType(StudyEntryScreen), findsOneWidget);
    await _back(tester);
    expect(_barTitle('Korean'), findsOneWidget);
    final sessions = await env.db
        .customSelect('SELECT COUNT(*) AS n FROM study_session')
        .getSingle();
    expect(sessions.read<int>('n'), 0);
  });
```

(Open the deck's ⋮ the way the file's other action-sheet tests do — `grep -n "deckMore\|byTooltip\|more" test/app/library_routes_test.dart` — and use that finder.)

`test/app/app_test.dart` — add:

```dart
  libraryTest("the app closes yesterday's open session as interrupted when "
      'it starts (BR-STUDY-072, FE-A6 D9)', (tester, env) async {
    final root = await env.decks.root('Korean');
    await insertCard(env.db, id: 'c1', deckId: root.id);
    await openLearningSessionAt(env, root.id, DateTime(2026, 9, 23, 20));
    await _pumpApp(tester, env);

    final status = await env.db
        .customSelect('SELECT status, end_reason FROM study_session')
        .getSingle();
    expect(
      (status.read<String>('status'), status.read<String>('end_reason')),
      ('abandoned', 'interrupted'),
    );
  });
```

where `openLearningSessionAt` opens a learning session with the study entry repository at a given time: add it to `test/support/study_fixtures.dart` if absent (`studyEntryRepository(db, () => at).openLearningSession(deckId: …)`, the factory `watch_entry_test.dart` uses).

Coming-soon sheet test: Study is no longer listed (`expect(find.text(_en.comingSoonStudy), findsNothing)`); Study options still is. Deck action sheet test: a Study row is present for a root and a sub-deck. Card summary test: with `onStudy` given and due cards, a button "Study this deck · {n} due" shows and calls it; with `onStudy` null it is absent.

Run the four test files — Expected: FAIL.

- [ ] **Step 2: Routes**

`app_routes.dart`:

```dart
  /// A deck's Study Entry, relative to [deckChild] (FE-A6 D1).
  static const String studyChild = 'study';

  /// [deckId]'s Study Entry.
  static String studyEntry(String deckId) => '${deck(deckId)}/$studyChild';
```

`app_router.dart`, a child of `AppRoutes.deckChild` next to `algorithmChild`:

```dart
                    GoRoute(
                      path: AppRoutes.studyChild,
                      builder: (context, state) {
                        final deckId =
                            state.pathParameters[AppRoutes.deckIdParam]!;
                        return StudyEntryScreen(
                          deckId: deckId,
                          title: DeckStudyHeaderWidget(
                            deckId: deckId,
                            part: DeckStudyHeaderPart.title,
                          ),
                          breadcrumb: DeckStudyHeaderWidget(
                            deckId: deckId,
                            part: DeckStudyHeaderPart.breadcrumb,
                          ),
                        );
                      },
                    ),
```

and in `_deckLevel`: `onOpenStudy: (id) => unawaited(context.push(AppRoutes.studyEntry(id)))`; in `cardContent`: `onStudy: () => unawaited(context.push(AppRoutes.studyEntry(view.deck.id)))`.

- [ ] **Step 3: The deck action and its thread**

`deck_action_sheet_widget.dart`: `enum DeckAction { open, study, rename, move, reviewAlgorithm, reorder, delete }`; in `_rows`, after Open, `MxActionSheetCommandRow(icon: AppIcons.play, label: l10n.deckStudy, onTap: () => choose(DeckAction.study))`; update the doc line "Study and Study options wait under Coming soon" to "Study options waits under Coming soon". `deck_actions_flow_widget.dart`: add `required ValueChanged<String> onOpenStudy` and `case DeckAction.study: onOpenStudy(deckId);`. Thread `onOpenStudy` through `DeckLevelScreen` and every widget that threads `onOpenAlgorithm` (same parameter shape, same places). `deck_coming_soon_sheet_widget.dart`: remove the Study entry from `_features`.

- [ ] **Step 4: "Study this deck"**

`card_deck_summary_widget.dart`: add `this.onStudy` (`final VoidCallback? onStudy;`, doc "Opens the deck's Study Entry (FE-A6 D10); null hides the action."); after the legend `Wrap`, when `onStudy != null && workload.overdue + workload.today > 0`:

```dart
            MxButton(
              label: l10n.cardStudyThisDeck(workload.overdue + workload.today),
              onPressed: onStudy,
              tone: MxButtonTone.secondary,
              icon: AppIcons.play,
              isBlock: true,
            ),
```

`card_list_section_widget.dart`: add `this.onStudy` and pass it to `CardDeckSummaryWidget`. Update screen 07's detail file row "Study this deck waits under Coming soon" in Task 7.

- [ ] **Step 5: The sweep at start**

`app.dart`: `MemoxApp` becomes a `ConsumerStatefulWidget` (`ConsumerState`); in `initState` after `registerFontLicense()`:

```dart
    // A session left open on an earlier day closes as interrupted before it
    // could be offered (BR-STUDY-072, FE-A6 D9). Unawaited: the Continue
    // offers already ignore an earlier day's session, so no frame waits.
    unawaited(_closeStaleSessions());
```

```dart
  Future<void> _closeStaleSessions() async {
    try {
      await ref.read(abandonStaleSessionsUseCaseProvider)();
    } on Failure {
      // A failed sweep leaves the sessions open; the next start retries.
    }
  }
```

(`Failure` from `lib/core/error/failure.dart`; `app/` may import a feature's presentation provider.) If the guard's error-handling rules reject the empty handler body, log through the app's logger the way other `on Failure` handlers in `lib/` do (`grep -rn "on Failure" lib | head`).

- [ ] **Step 6: Run and commit**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test --exclude-tags golden test/app test/features/deck test/features/card test/features/study && flutter analyze && python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`
Expected: PASS, clean.

```bash
git add lib test
git commit -m "feat(study): the entry's route and ways in; stale sessions close at start (FE-A6 D1, D9, D10)"
```

---

### Task 6: Goldens and visual audit

**Files:**
- Create: `test/visual_audit/screens/features/study/screens/study_entry_screen_visual_audit_test.dart`, `test/features/study/presentation/study_entry_golden_test.dart`, goldens
- Regenerate: goldens that show the deck action sheet, the Coming soon sheet and the card list summary (their content changed)

- [ ] **Step 1: Companion** — like `library_search_screen_visual_audit_test.dart`: two `libraryTest`s calling `auditProductionScreen(tester, screen: StudyEntryScreen, pump: …)` over an Eight boxes deck with new and due cards, and over a nothing-due deck; pass `title: const Text('Deck')`, `breadcrumb: const SizedBox.shrink()`.

Run: `flutter test test/visual_audit` — Expected: PASS.

- [ ] **Step 2: Goldens** — `study_entry_golden_test.dart` (tag `golden`, both brightnesses, `pumpLibraryGolden`, Latin/Vietnamese names only): `study_entry_eight_box` (2 new, 12 due of which 3 overdue, one due card without example so Fill is not available), `study_entry_sm2` (20 new, 0 due), `study_entry_nothing`, `study_entry_loading` (override `studyEntryProvider(id)` with a never-emitting stream). Pass real `DeckStudyHeaderWidget`s as title and breadcrumb so the goldens show the kit's bar and path.

Run: `TZ=UTC flutter test --tags golden` first without `--update-goldens`: only the action-sheet, Coming soon and card-summary goldens may fail (their content changed). Then `TZ=UTC flutter test --tags golden --update-goldens test/features/study test/features/deck test/features/card test/app`. Open every new or changed PNG next to `docs/shared/ui/screen-handoff/img/14-study-entry/{eightBox,sm2,nothing,loading}-light.png`; `git status` lists only those.

- [ ] **Step 3: Commit** — `git add test && git commit -m "test(study): Study Entry goldens and visual audit (FE-A6)"`

---

### Task 7: Records

- [ ] Update `docs/shared/ui/screen-handoff/14-study-entry.md` (a "P1b" note under States: `starting`, `refused`, `startFailed` and `resume` wait for P1c/P2 because nothing starts yet; Learn and runnable modes show "Coming soon"), `07-card-list.md` (Study this deck is live; remove it from the Coming soon deviation), `01-deck-list.md` if it lists Study under Coming soon, the screen index row 14 (`built`, P1b), `docs/wbs_FE.md` (FE-A6 evidence adds P1b), `docs/features/study/README.md` `code:` (add `lib/features/study/presentation`), `docs/_generated/`.

Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py` — Expected: 0 errors, warnings ≤ 57.
Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` and `TZ=UTC flutter test --tags golden` — Expected: green.

```bash
git add docs && git commit -m "docs(study): Study Entry P1b records (FE-A6)"
```
