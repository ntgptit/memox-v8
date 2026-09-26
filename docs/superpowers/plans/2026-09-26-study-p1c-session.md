# Study P1c — Session shell, Browse (16), Summary (21) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A study session as one full-screen route: the session shell (top bar, context line, exit, feedback hold, write errors, ended states), screen 16 Browse, and screen 21 Session summary — so a Browse stage runs end to end and every way a session ends shows its summary or leaves as the UC says.

**Architecture:** `/study/session/:sessionId` on the root navigator (spec D2). `StudySessionScreen` watches `WatchStudySessionUseCase` and picks its body with an exhaustive switch: the summary once the session has ended, else the current mode's body (D3) — Browse in this phase, a "coming soon" body for the five modes P2–P4 build. One `@riverpod` controller per session owns every write (D4), drops a second command while one runs (BR-STUDY-004), keeps a busy-database answer for Retry (E2) and holds a graded turn's item on screen until its mode releases it (D5). The summary's content is a pure mapping from the ended view (tested alone), drawn by a presentational widget. Browse's look-back reads a trail of the round's shown cards added to the session read model (BR-STUDY-048), so it survives a resume.

**Tech Stack:** Flutter 3.47.5, Riverpod 3 codegen, go_router, Drift (in-memory in tests), `flutter gen-l10n`.

**Spec:** [docs/superpowers/specs/2026-09-26-study-ui-design.md](../specs/2026-09-26-study-ui-design.md) — D2–D8, D11, D14, D17–D20, §3. Screens: [16-study-browse.md](../../shared/ui/screen-handoff/16-study-browse.md), [21-session-summary.md](../../shared/ui/screen-handoff/21-session-summary.md). UC-STUDY-001 (steps 5–13, A3, A5, E2–E5). Built on [P1a](2026-09-26-study-p1a-foundations.md) and [P1b](2026-09-26-study-p1b-entry.md).

**Owner ruling (2026-09-26, before this plan):** spec D8 said the ✕ "abandons, then pops to the entry, which offers Continue" — an abandoned session cannot be continued (UC-STUDY-001 A3/A3b, BR-STUDY-072) and the kit's `leftEarly` summary would never show. Ruled: ✕ and system Back abandon at once (no confirm) and the same route then shows the summary "You left early" (D2); Done returns to the deck. Task 10 amends D8.

## Global Constraints

- `study` imports only `study_mode`, `srs`, `settings`, `card` (`test/architecture/boundary_rules.dart`); `presentation/` never imports `data/`; `app/` composes and routes.
- Presentation files end in `_screen`, `_widget`, `_controller`, `_state`, `_page`, `_view` or `_provider`.
- Every user-facing string is an ARB key in `app_en.arb` and `app_vi.arb`; no interpolated literal in a widget (guard `no_literal_user_string`).
- No `ref.read` in a `build()` body, even inside a closure (guard `no_ref_read_in_build`): read in a method.
- Features pass no `Color`, `TextStyle`, radius or padding to shared widgets and never restyle text with `copyWith`; a missing role is added to `MxTextStyles` under `flutter-theme-design`. No `Icon(color:)` in features (icon colour through `IconTheme`/the shared widget).
- Mode widgets never call a use case; they call the session controller (D4).
- `builtStudyModes` becomes `{StudyMode.browse}`; the entry still offers nothing (Learn needs the whole stage sequence, spec §3), so sessions in this phase's tests are opened through the repositories.
- The session repository reads the wall clock (its DI passes no `now`): tests open sessions at `DateTime.now()`, not at the harness's fake day, or an answer may meet an expired session.
- Goldens on Linux only (`TZ=UTC`); Hangul renders as boxes in the test fonts, so golden seeds use Latin/Vietnamese text.

## Review Focus

1. A second tap or swipe while a write is in flight is dropped, never queued (BR-STUDY-004) — pinned in Task 4 (busy test).
2. A busy database keeps the card on screen with the answer kept for Retry, and nothing advances (UC-STUDY-001 E2) — pinned in Task 4 (lock test) and Task 8 (banner test).
3. Looking back never writes and never moves the counter; forward from a look-back returns to the live card without answering it (BR-STUDY-048, IT-MODE-002 steps 5–6) — pinned in Task 7.
4. The deck deleted or reset elsewhere while the session is open leaves the screen once, to the right place, with a message (A5, E4) — pinned in Task 8.
5. System Back on the summary does what Done does; it never returns to a closed session (D2) — pinned in Task 8.

---

## File map

| File | Action | Responsibility |
|---|---|---|
| `lib/l10n/app_en.arb`, `app_vi.arb` | modify | session, Browse, summary copy |
| `lib/core/theme/mx_text_styles.dart`, `foundations/app_icons.dart` | modify | study face and summary type roles; two glyphs |
| `lib/features/study/domain/models/study_session_view_model.dart` | modify | `TrailCard`, `StudySessionView.trail` |
| `lib/features/study/data/datasources/study_view_dao.dart`, `mappers/study_session_view_mapper.dart`, `repositories/study_session_view_repository_impl.dart` | modify | the Browse trail read |
| `lib/features/study/presentation/providers/*_use_case_provider.dart`, `study_session_provider.dart` | create | use cases and the session stream |
| `lib/features/study/presentation/states/study_turn_state.dart` | create | busy, held, unsaved |
| `lib/features/study/presentation/controllers/study_session_controller.dart` | create | the session's commands |
| `lib/features/study/presentation/states/session_ending_state.dart` | create | how an ended view is shown (pure) |
| `lib/features/study/presentation/widgets/sections/session_summary_*_widget.dart` | create | screen 21 |
| `lib/features/study/presentation/widgets/sections/study_browse_widget.dart`, `widgets/support/session_*_widget.dart` | create | screen 16 and the shell's pieces |
| `lib/features/study/presentation/screens/study_session_screen.dart` | create | the session route's screen |
| `lib/features/study/presentation/states/study_entry_offer_state.dart` | modify | `builtStudyModes = {browse}` |
| `lib/app/router/app_routes.dart`, `app_router.dart` | modify | the session route |
| tests, goldens, companion, docs | create/modify | proofs and records |

---

### Task 1: Strings

**Files:** Modify `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`.

**Interfaces — Produces** (`context.l10n`; keys exactly as named):

| Key | English | Vietnamese | Placeholders |
|---|---|---|---|
| `studySessionClose` | `Close the session` | `Đóng phiên` | |
| `studySessionCounter` | `{current} / {total}` | `{current} / {total}` | current int, total int |
| `studyKindLearning` | `Learning` | `Học mới` | |
| `studyContextLearning` | `{deck} · {kind} · stage {stage} of {stages} · {mode}` | `{deck} · {kind} · giai đoạn {stage}/{stages} · {mode}` | deck String, kind String, stage int, stages int, mode String |
| `studyBrowseTerm` | `Term` | `Thuật ngữ` | |
| `studyBrowseMeaning` | `Meaning` | `Nghĩa` | |
| `studyBrowseHint` | `Swipe left for next, right to look back · nothing is graded here` | `Vuốt trái để sang thẻ tiếp, vuốt phải để xem lại · ở đây không chấm điểm` | |
| `studyBrowseLookingBack` | `Looking back` | `Đang xem lại` | |
| `studyBrowseNext` | `Next card` | `Thẻ tiếp theo` | |
| `studyBrowsePrevious` | `Previous card` | `Thẻ trước` | |
| `studyModeNotBuiltTitle` | `{mode} is coming soon` | `{mode} sắp có` | mode String |
| `studyModeNotBuiltBody` | `Close the session; every answer so far is kept.` | `Hãy đóng phiên; mọi câu trả lời đến giờ vẫn được giữ.` | |
| `studyAnswerBusyTitle` | `Couldn't save that answer` | `Chưa lưu được câu trả lời` | |
| `studyAnswerBusyBody` | `The device is busy. Your answer is kept — try again.` | `Máy đang bận. Câu trả lời vẫn được giữ — hãy thử lại.` | |
| `studySessionErrorTitle` | `Couldn't read this session` | `Không đọc được phiên này` | |
| `studySessionErrorBody` | `Your answers are safe on this device. Try again in a moment.` | `Câu trả lời của bạn vẫn an toàn trên máy. Hãy thử lại sau giây lát.` | |
| `studySessionStaleToast` | `This session ended: the deck's learning progress was reset.` | `Phiên đã kết thúc: tiến độ học của bộ thẻ vừa được đặt lại.` | |
| `summaryAppBar` | `Session summary` | `Tổng kết phiên` | |
| `summaryKindLearning` | `Learning session` | `Phiên học mới` | |
| `summaryKindReview` | `Review session` | `Phiên ôn tập` | |
| `summaryOverline` | `{kind} · {deck}` | `{kind} · {deck}` | kind String, deck String |
| `summaryCards` | `{count, plural, =1{1 card} other{{count} cards}}` | `{count} thẻ` | count int |
| `summaryReviewFinished` | `Review finished` | `Ôn tập xong` | |
| `summaryReviewFinishedBody` | `You reviewed {cards}. Their next due dates are set.` | `Bạn đã ôn {cards}. Lịch đến hạn tiếp theo đã được đặt.` | cards String |
| `summaryLearningFinished` | `Learning finished` | `Học mới xong` | |
| `summaryLearningFinishedBody` | `{cards} finished learning. They come back tomorrow at 00:00.` | `{cards} đã học xong. Chúng quay lại lúc 00:00 ngày mai.` | cards String |
| `summaryLeftEarly` | `You left early` | `Bạn đã dừng sớm` | |
| `summaryLeftEarlyLearningBody` | `The {kept} cards you finished are kept. The other {left} stay new and will be offered again.` | `{kept} thẻ bạn đã học xong được giữ. {left} thẻ còn lại vẫn là thẻ mới và sẽ được đưa ra lại.` | kept int, left int |
| `summaryLeftEarlyReviewBody` | `The {kept} cards you reviewed are kept. The other {left} are still due.` | `{kept} thẻ bạn đã ôn được giữ. {left} thẻ còn lại vẫn đến hạn.` | kept int, left int |
| `summaryInterrupted` | `Session interrupted` | `Phiên bị gián đoạn` | |
| `summaryInterruptedBody` | `This session from yesterday was closed by the system and could not be resumed today. Every answer you gave is kept.` | `Phiên từ hôm qua đã bị hệ thống đóng và không thể tiếp tục hôm nay. Mọi câu trả lời của bạn vẫn được giữ.` | |
| `summaryReset` | `Ended by a reset` | `Kết thúc vì đặt lại tiến độ` | |
| `summaryResetBody` | `Learning progress of this deck was reset while you were studying, so this session could not continue. Answers given before the reset stay in the history of the earlier cycle.` | `Tiến độ học của bộ thẻ đã được đặt lại khi bạn đang học, nên phiên này không thể tiếp tục. Câu trả lời trước khi đặt lại vẫn nằm trong lịch sử của chu kỳ trước.` | |
| `summarySchedulerChanged` | `Ended by an algorithm change` | `Kết thúc vì đổi thuật toán` | |
| `summarySchedulerChangedBody` | `The deck switched to a different review algorithm, so its learning sequence changed. Every card is new again; start learning from the deck.` | `Bộ thẻ đã chuyển sang thuật toán ôn tập khác nên chuỗi học đã thay đổi. Mọi thẻ lại là thẻ mới; hãy bắt đầu học từ bộ thẻ.` | |
| `summaryContentDeleted` | `Ended — content moved to Trash` | `Kết thúc — nội dung đã vào Thùng rác` | |
| `summaryContentDeletedBody` | `A card in this session was moved to Trash, so the session ended. Answers given before that are kept.` | `Một thẻ trong phiên đã được chuyển vào Thùng rác nên phiên kết thúc. Câu trả lời trước đó vẫn được giữ.` | |
| `summarySaveError` | `Stopped by a save error` | `Dừng vì lỗi lưu` | |
| `summarySaveErrorBody` | `An answer could not be written to this device, so the session stopped. Everything saved before that is kept; the unanswered cards are still due.` | `Một câu trả lời không ghi được vào máy nên phiên đã dừng. Mọi thứ đã lưu trước đó vẫn được giữ; các thẻ chưa trả lời vẫn đến hạn.` | |
| `summaryStatReviewed` | `Reviewed` | `Đã ôn` | |
| `summaryStatLearned` | `Learned` | `Đã học` | |
| `summaryStatAnswered` | `Answered` | `Đã trả lời` | |
| `summaryStatWrong` | `Wrong` | `Sai` | |
| `summaryWrongOf` | `{wrong} / {total}` | `{wrong} / {total}` | wrong int, total int |
| `summaryFactsHeader` | `This session` | `Phiên này` | |
| `summaryFactLearned` | `Cards that finished learning` | `Thẻ đã học xong` | |
| `summaryFactLearnedSub` | `Now scheduled, due tomorrow` | `Đã có lịch, đến hạn ngày mai` | |
| `summaryFactReviewed` | `Cards reviewed` | `Thẻ đã ôn` | |
| `summaryFactReviewedSub` | `Schedules updated` | `Lịch đã được cập nhật` | |
| `summaryFactAnswered` | `Cards answered` | `Thẻ đã trả lời` | |
| `summaryFactWrong` | `Wrong turns` | `Lượt sai` | |
| `summaryFactWrongSub` | `of {total} turns` | `trên {total} lượt` | total int |
| `summaryFactWrongCameBack` | `of {total} turns · wrong cards came back in later rounds` | `trên {total} lượt · thẻ sai quay lại ở các vòng sau` | total int |
| `summaryNoteHistory` | `Nothing was lost — the answers are in the history.` | `Không mất gì — các câu trả lời vẫn nằm trong lịch sử.` | |
| `summaryNoteTrash` | `Restore the card from Trash to include it in the next review.` | `Khôi phục thẻ từ Thùng rác để đưa nó vào lần ôn tới.` | |
| `summaryDone` | `Done` | `Xong` | |
| `summaryDoneCaption` | `Done returns you to the deck.` | `Xong sẽ đưa bạn về bộ thẻ.` | |

Each key gets `"@key": {"description": "Screen handoff 16 (FE-A6 P1c): …"}` (or 21, or "Session shell") and its typed `placeholders`. "Study this deck" reuses `studyThisDeck`; the deck-gone toast reuses `studyEntryDeckGone`; a stat value reuses `studyCount`; the mode names reuse `studyMode(…)` from `StudyLabels`.

- [ ] **Step 1:** Add the keys with a script over both files (as P1b's Task 1 did), then `flutter gen-l10n`.
- [ ] **Step 2:** Run `flutter gen-l10n && flutter analyze && flutter test test/l10n` — Expected: generates, clean, PASS.
- [ ] **Step 3:** Commit — `feat(l10n): study session, Browse and summary strings (FE-A6)`.

---

### Task 2: Type roles and glyphs

**Files:**
- Modify: `lib/core/theme/mx_text_styles.dart`, `lib/core/theme/foundations/app_icons.dart`
- Test: `test/core/theme/mx_text_styles_test.dart`

**Interfaces — Produces:** `MxTextStyles.studyTerm` (32/700, −0.5, 1.15, onSurface), `studyMeaning` (24/600, −0.3, onSurface), `studyDetail` (14/400, 1.5, onSurfaceVariant — pronunciation and example), `sessionHint` (12/400, 0.3 tracking, onSurfaceVariant), `summaryTitle` (24/700, −0.4, 1.15, onSurface), `summaryBodyStrong` (`emptyBody` at 700 in onSurface), `factValue(Color ink)` (16/700 tabular). `AppIcons.pause` (`Icons.pause_circle_outline`, kit pause-circle), `AppIcons.swipe` (`Icons.keyboard_double_arrow_right`, kit chevrons-right). Values from the kit source (`StudyScreenV3`, `SessionStatusHero`, `SessionFooterHint`, `ResultRow`).

- [ ] **Step 1: Failing test** — append to `test/core/theme/mx_text_styles_test.dart` (its `expectStyle` helper):

```dart
  test('study faces: term 32/700 at -0.5, meaning 24/600 at -0.3, detail '
      '14/400 in the variant ink (kit StudyScreenV3)', () {
    expectStyle(
      styles.studyTerm,
      size: 32,
      weight: FontWeight.w700,
      tracking: -0.5,
      color: scheme.onSurface,
    );
    expect(styles.studyTerm.height, 1.15);
    expectStyle(
      styles.studyMeaning,
      size: 24,
      weight: FontWeight.w600,
      tracking: -0.3,
      color: scheme.onSurface,
    );
    expectStyle(
      styles.studyDetail,
      size: 14,
      weight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
    );
    expect(styles.studyDetail.height, 1.5);
    expectStyle(
      styles.sessionHint,
      size: 12,
      weight: FontWeight.w400,
      tracking: 0.3,
      color: scheme.onSurfaceVariant,
    );
  });

  test('summary: title 24/700 at -0.4, the body strong run at 700 in '
      'onSurface, a fact value 16/700 tabular in its ink', () {
    expectStyle(
      styles.summaryTitle,
      size: 24,
      weight: FontWeight.w700,
      tracking: -0.4,
      color: scheme.onSurface,
    );
    expectStyle(
      styles.summaryBodyStrong,
      size: styles.emptyBody.fontSize!,
      weight: FontWeight.w700,
      color: scheme.onSurface,
    );
    const ink = Color(0xFF123456);
    final value = styles.factValue(ink);
    expectStyle(value, size: 16, weight: FontWeight.w700, color: ink);
    expect(value.fontFeatures, contains(const FontFeature.tabularFigures()));
  });
```

- [ ] **Step 2:** Run `flutter test test/core/theme/mx_text_styles_test.dart` — Expected: FAIL (getters missing).
- [ ] **Step 3: Implement** in `mx_text_styles.dart`, next to the related roles, reusing `AppTypography.withWeight` and the file's constants (add `_studyTermSize = 32`, `_studyTermTracking = -0.5`, `_studyTermHeight = 1.15`, `_studyMeaningSize = 24`, `_studyMeaningTracking = -0.3`, `_hintTracking = 0.3`, `_summaryTitleTracking = -0.4`, `_factValueSize = 16`; `_noteHeight` is 1.5 already):

```dart
  /// A study card's term (kit Browse): 32/700 at 1.15, -0.5 tracking. It
  /// wraps and never ellipsizes (FE-A6 D19).
  TextStyle get studyTerm =>
      AppTypography.withWeight(
        _texts.headlineSmall!.copyWith(fontSize: _studyTermSize),
        FontWeight.w700,
      ).copyWith(
        height: _studyTermHeight,
        letterSpacing: _studyTermTracking,
        color: _scheme.onSurface,
      );

  /// A study card's meaning (kit Browse): 24/600, -0.3 tracking.
  TextStyle get studyMeaning =>
      AppTypography.withWeight(
        _texts.headlineSmall!.copyWith(fontSize: _studyMeaningSize),
        FontWeight.w600,
      ).copyWith(letterSpacing: _studyMeaningTracking, color: _scheme.onSurface);

  /// A study card's pronunciation and example: 14/400 at 1.5, variant ink.
  TextStyle get studyDetail =>
      AppTypography.withWeight(_texts.bodyMedium!, FontWeight.w400).copyWith(
        height: _noteHeight,
        color: _scheme.onSurfaceVariant,
      );

  /// A session's footer hint (kit SessionFooterHint): 12, 0.3 tracking.
  TextStyle get sessionHint =>
      AppTypography.withWeight(_texts.labelSmall!, FontWeight.w400).copyWith(
        letterSpacing: _hintTracking,
        color: _scheme.onSurfaceVariant,
      );

  /// The session summary's title (kit SessionStatusHero): 24/700 at 1.15.
  TextStyle get summaryTitle =>
      AppTypography.withWeight(_texts.headlineSmall!, FontWeight.w700)
          .copyWith(
            height: _studyTermHeight,
            letterSpacing: _summaryTitleTracking,
            color: _scheme.onSurface,
          );

  /// The bold run of the summary's body, such as "20 cards" (kit).
  TextStyle get summaryBodyStrong =>
      AppTypography.withWeight(emptyBody, FontWeight.w700).copyWith(
        color: _scheme.onSurface,
      );

  /// A summary fact's value (kit ResultRow): 16/700 tabular, in [ink].
  TextStyle factValue(Color ink) =>
      AppTypography.withWeight(
        _texts.bodyLarge!.copyWith(fontSize: _factValueSize),
        FontWeight.w700,
      ).copyWith(fontFeatures: _tabular, color: ink);
```

(If `headlineSmall` is not 24 in `app_typography.dart`, `studyMeaning`/`summaryTitle` still set the size explicitly: keep the constants.) In `app_icons.dart`: `static const IconData pause = Icons.pause_circle_outline; // pause-circle` and `static const IconData swipe = Icons.keyboard_double_arrow_right; // chevrons-right`.

- [ ] **Step 4:** Run `flutter test test/core/theme && flutter analyze` — Expected: PASS, clean.
- [ ] **Step 5:** Commit — `feat(theme): study face and summary type roles; pause and swipe glyphs (FE-A6)`.

---

### Task 3: The Browse trail (read model)

**Files:**
- Modify: `lib/features/study/domain/models/study_session_view_model.dart`, `lib/features/study/data/datasources/study_view_dao.dart`, `lib/features/study/data/mappers/study_session_view_mapper.dart`, `lib/features/study/data/repositories/study_session_view_repository_impl.dart`
- Test: `test/features/study/data/watch_session_test.dart`

**Interfaces — Produces:**

```dart
/// A card Browse already showed in this round, for looking back
/// (BR-STUDY-048): what the card face draws.
final class TrailCard {
  const TrailCard({
    required this.cardId,
    required this.front,
    required this.back,
    required this.pronunciation,
    required this.example,
  });
  final String cardId;
  final String front;
  final String back;
  final String? pronunciation;
  final String? example;
}
```

and `StudySessionView.trail` (`final List<TrailCard> trail;`, constructor `this.trail = const []`): in `browse`, the round's completed cards in the order served, oldest first; empty in every other mode and once the session has ended.

- [ ] **Step 1: Failing test** — add to `watch_session_test.dart` (its `tree`, `learning`, `answer`, `viewOf` helpers):

```dart
  test('Browse carries the cards it already showed in the round, oldest '
      'first, for looking back; a look back writes nothing (BR-STUDY-048)', () async {
    final (_, leaf) = await tree();
    for (final id in ['a', 'b', 'c']) {
      await insertCard(db, id: id, deckId: leaf.id, front: 'front $id');
    }
    final id = await learning(leaf);
    expect((await viewOf(id)).trail, isEmpty);

    final first = (await viewOf(id)).currentItem!.cardId;
    await answer(id, const AdvanceAnswer());
    final second = (await viewOf(id)).currentItem!.cardId;
    await answer(id, const AdvanceAnswer());

    final view = await viewOf(id);
    expect([for (final card in view.trail) card.cardId], [first, second]);
    expect(view.trail.first.front, 'front $first');
    expect(view.progress!.completed, 2);
  });

  test('a graded stage carries no trail', () async {
    final (_, leaf) = await tree();
    for (final id in ['a', 'b']) {
      await insertCard(db, id: id, deckId: leaf.id);
    }
    final id = await learning(leaf);
    await answer(id, const AdvanceAnswer());
    await answer(id, const AdvanceAnswer());

    final view = await viewOf(id);
    expect(view.currentMode, isNot(StudyMode.browse));
    expect(view.trail, isEmpty);
  });
```

Run: `flutter test test/features/study/data/watch_session_test.dart` — Expected: FAIL (`trail` undefined).

- [ ] **Step 2: Implement.**

`study_view_dao.dart` — a record and a query next to `boardPairs`:

```dart
/// A card Browse showed in a round: its faces for looking back.
typedef TrailRecord = ({
  String cardId,
  String front,
  String back,
  String? pronunciation,
  String? example,
});

  /// The completed rows of [round] of [mode], in the order served
  /// (BR-STUDY-048: the trail must keep that order). A card in the Trash is
  /// left out (BR-TRASH-002).
  Future<List<TrailRecord>> trail(
    String sessionId,
    String mode,
    int round,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT c.id, c.front, c.back, c.pronunciation, c.example'
          ' FROM study_queue_items q JOIN card c ON c.id = q.card_id'
          ' AND c.delete_batch_id IS NULL'
          ' WHERE q.session_id = ? AND q.mode = ? AND q.round = ?'
          " AND q.status = 'completed' AND q.position >= 0"
          ' ORDER BY q.position',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(mode),
            Variable<int>(round),
          ],
          readsFrom: {_db.studyQueueItems, _db.card},
        )
        .get();
    return [
      for (final row in rows)
        (
          cardId: row.read<String>('id'),
          front: row.read<String>('front'),
          back: row.read<String>('back'),
          pronunciation: row.read<String?>('pronunciation'),
          example: row.read<String?>('example'),
        ),
    ];
  }
```

(Check the column names against `lib/core/database/tables/` — `grep -n "pronunciation\|example" lib/core/database/tables/*card*.dart` — and the tombstone-filter allowlist test: the query names `delete_batch_id`, so `test/architecture/tombstone_filter_test.dart` passes.)

`study_session_view_mapper.dart` — `ServedRow` gains `List<TrailRecord>? trail`; `studySessionViewOf` passes `trail: [for (final card in served?.trail ?? const <TrailRecord>[]) TrailCard(cardId: card.cardId, front: card.front, back: card.back, pronunciation: card.pronunciation, example: card.example)]`.

`study_session_view_repository_impl.dart` — in `_servedOf`, the record adds `trail: head.mode == StudyMode.browse.code ? await _views.trail(session.id, head.mode, head.round) : null,`.

- [ ] **Step 3:** Run `flutter test test/features/study test/architecture && flutter analyze` — Expected: PASS, clean.
- [ ] **Step 4:** Commit — `feat(study): the session view carries Browse's trail for looking back (BR-STUDY-048)`.

---

### Task 4: Session providers and controller

**Files:**
- Create: `lib/features/study/presentation/providers/watch_study_session_use_case_provider.dart`, `study_session_provider.dart`, `answer_study_turn_use_case_provider.dart`, `abandon_study_session_use_case_provider.dart`, `resume_study_session_use_case_provider.dart`; `lib/features/study/presentation/states/study_turn_state.dart`; `lib/features/study/presentation/controllers/study_session_controller.dart`
- Test: `test/features/study/presentation/study_session_controller_test.dart`

**Interfaces — Produces:**

```dart
// study_session_provider.dart
@riverpod
Stream<Outcome<StudySessionView, StudyRejection>> studySession(Ref ref, String sessionId);

// study_turn_state.dart
final class StudyTurnState {
  const StudyTurnState({this.isBusy = false, this.held, this.unsaved});
  /// A write is running; every other command is dropped (BR-STUDY-004).
  final bool isBusy;
  /// A graded turn's item and result, on screen until its mode releases it
  /// (spec D5).
  final HeldTurn? held;
  /// The answer a busy database refused, kept for Retry (UC-STUDY-001 E2).
  final PendingAnswer? unsaved;
}
final class HeldTurn { const HeldTurn(this.item, this.result); final StudyItem item; final TurnResult result; }
final class PendingAnswer {
  const PendingAnswer(this.item, this.answer, {required this.holdsFeedback});
  final StudyItem item; final StudyAnswer answer; final bool holdsFeedback;
}

// study_session_controller.dart
@riverpod
class StudySessionController extends _$StudySessionController {
  StudyTurnState build(String sessionId);
  Future<void> answer(StudyItem item, StudyAnswer answer, {bool holdsFeedback = false});
  Future<void> retry();
  void release();
  Future<void> abandon();
  Future<void> settle();
}
```

- [ ] **Step 1: Failing tests** (`study_session_controller_test.dart`):

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/di/study_session_repository_provider.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';
import 'package:memox/features/study/presentation/providers/study_session_provider.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// Spec D4, D5; BR-STUDY-004; UC-STUDY-001 A3, E2, E3.

/// The real session repository, except that [answerTurn] finds the
/// database busy while [isLocked] (UC-STUDY-001 E2).
final class _LockableSessions implements StudySessionRepository {
  _LockableSessions(this._inner);
  final StudySessionRepository _inner;
  var isLocked = false;

  @override
  Future<Outcome<TurnResult, StudyRejection>> answerTurn({
    required String sessionId,
    required String cardId,
    required StudyAnswer answer,
    DateTime? now,
  }) {
    if (isLocked) throw const DatabaseLockedFailure(cause: 'test');
    return _inner.answerTurn(
      sessionId: sessionId,
      cardId: cardId,
      answer: answer,
      now: now,
    );
  }

  @override
  Future<Outcome<void, StudyRejection>> revealRecallAnswer({
    required String sessionId,
    required String cardId,
    required int remainingMs,
    DateTime? now,
  }) => _inner.revealRecallAnswer(
    sessionId: sessionId,
    cardId: cardId,
    remainingMs: remainingMs,
    now: now,
  );

  @override
  Future<Outcome<void, StudyRejection>> saveRecallTime({
    required String sessionId,
    required String cardId,
    required int remainingMs,
    DateTime? now,
  }) => _inner.saveRecallTime(
    sessionId: sessionId,
    cardId: cardId,
    remainingMs: remainingMs,
    now: now,
  );

  @override
  Future<Outcome<void, StudyRejection>> showFillHint({
    required String sessionId,
    required String cardId,
    DateTime? now,
  }) => _inner.showFillHint(sessionId: sessionId, cardId: cardId, now: now);

  @override
  Future<void> failSession({required String sessionId, DateTime? now}) =>
      _inner.failSession(sessionId: sessionId, now: now);

  @override
  Future<Outcome<void, StudyRejection>> abandonSession({
    required String sessionId,
    DateTime? now,
  }) => _inner.abandonSession(sessionId: sessionId, now: now);

  @override
  Future<Outcome<void, StudyRejection>> resumeSession({
    required String sessionId,
    DateTime? now,
  }) => _inner.resumeSession(sessionId: sessionId, now: now);

  @override
  Future<void> abandonStaleSessions({DateTime? now}) =>
      _inner.abandonStaleSessions(now: now);
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late _LockableSessions sessions;

  setUp(() {
    db = openTestDatabase();
    sessions = _LockableSessions(
      studySessionRepository(db, DateTime.now),
    );
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        dayClockProvider.overrideWithValue(FakeDayClock(DateTime.now())),
        studySessionRepositoryProvider.overrideWithValue(sessions),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<String> browsing(List<String> ids) async {
    final root = await DeckRepositoryImpl(db).root('Korean');
    for (final id in ids) {
      await insertCard(db, id: id, deckId: root.id);
    }
    final opened = await studyEntryRepository(db, DateTime.now)
        .openLearningSession(deckId: root.id);
    return (opened as Ok<String, StudyRejection>).value;
  }

  Future<StudySessionController> controllerOf(String id) async {
    container.listen(studySessionControllerProvider(id), (_, _) {});
    container.listen(studySessionProvider(id), (_, _) {});
    await container.read(studySessionProvider(id).future);
    return container.read(studySessionControllerProvider(id).notifier);
  }

  Future<StudyItem> servedOf(String id) async =>
      ((await container.read(studySessionProvider(id).future))
              as Ok<StudySessionView, StudyRejection>)
          .value
          .currentItem!;

  test('a second command while a write runs is dropped (BR-STUDY-004)', () async {
    final id = await browsing(['a', 'b', 'c']);
    final controller = await controllerOf(id);
    final item = await servedOf(id);

    await Future.wait([
      controller.answer(item, const AdvanceAnswer()),
      controller.answer(item, const AdvanceAnswer()),
    ]);

    final view = (await watchSessionOnce(db, id));
    expect(view.progress!.completed, 1);
    expect(container.read(studySessionControllerProvider(id)).isBusy, isFalse);
  });

  test('a busy database keeps the answer for Retry and moves nothing '
      '(UC-STUDY-001 E2)', () async {
    final id = await browsing(['a', 'b']);
    final controller = await controllerOf(id);
    final item = await servedOf(id);

    sessions.isLocked = true;
    await controller.answer(item, const AdvanceAnswer());
    final state = container.read(studySessionControllerProvider(id));
    expect(state.unsaved?.item.cardId, item.cardId);
    expect((await watchSessionOnce(db, id)).progress!.completed, 0);

    sessions.isLocked = false;
    await controller.retry();
    expect(container.read(studySessionControllerProvider(id)).unsaved, isNull);
    expect((await watchSessionOnce(db, id)).progress!.completed, 1);
  });

  test('a graded turn is held on screen until released (spec D5)', () async {
    final root = await DeckRepositoryImpl(db).root('Korean');
    for (final id in ['a', 'b']) {
      await insertCard(
        db,
        id: id,
        deckId: root.id,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime.now().subtract(const Duration(hours: 1)),
        box: 2,
      );
    }
    await lockScheduler(db, root.id);
    final opened = await studyEntryRepository(db, DateTime.now)
        .openReviewSession(deckId: root.id, mode: StudyMode.recall);
    final id = (opened as Ok<String, StudyRejection>).value;
    final controller = await controllerOf(id);
    final item = await servedOf(id);

    await controller.answer(
      item,
      const RecallAnswer(RecallOutcome.forgot),
      holdsFeedback: true,
    );
    final held = container.read(studySessionControllerProvider(id)).held!;
    expect(held.item.cardId, item.cardId);
    expect(held.result.isCorrect, isFalse);

    controller.release();
    expect(container.read(studySessionControllerProvider(id)).held, isNull);
  });

  test('abandon ends the session as user_exit and keeps its turns '
      '(UC-STUDY-001 A3)', () async {
    final id = await browsing(['a', 'b']);
    final controller = await controllerOf(id);
    await controller.answer(await servedOf(id), const AdvanceAnswer());

    await controller.abandon();

    final session = await sessionOf(db, id);
    expect(
      (session.read<String>('status'), session.read<String>('end_reason')),
      ('abandoned', 'user_exit'),
    );
  });

  test('a stalled session settles and serves again (spec D12)', () async {
    final id = await browsing(['a', 'b', 'c']);
    final controller = await controllerOf(id);
    final item = await servedOf(id);
    await hardDeleteCards(db, {item.cardId});
    expect((await watchSessionOnce(db, id)).isStalled, isTrue);

    await controller.settle();

    expect((await watchSessionOnce(db, id)).isStalled, isFalse);
  });
}
```

Add to `test/support/study_fixtures.dart` the helper the tests use:

```dart
/// [sessionId]'s screen, read once through the real view repository.
Future<StudySessionView> watchSessionOnce(AppDatabase db, String sessionId) async =>
    (await StudySessionViewRepositoryImpl(db).watchSession(sessionId).first)!;
```

(Fix the imports as the analyzer asks: `StudyItem`, `StudySessionView` from `study_session_view_model.dart`; the fixture `root` extension from `deck_fixtures.dart`. If hard-deleting the served card of a Browse round does not stall the session, stall it the way `watch_session_test.dart`'s stalled test does and reuse that setup.)

Run: `flutter test test/features/study/presentation/study_session_controller_test.dart` — Expected: FAIL (controller missing).

- [ ] **Step 2: Providers** (one per file, the P1b pattern; the use cases take the repository providers of `lib/features/study/di/`):

```dart
@riverpod
WatchStudySessionUseCase watchStudySessionUseCase(Ref ref) =>
    WatchStudySessionUseCase(ref.watch(studySessionViewRepositoryProvider));

/// [sessionId]'s screen, again after every turn; notFound once its deck is
/// in the Trash or the session is gone (UC-STUDY-001 A5, E5).
@riverpod
Stream<Outcome<StudySessionView, StudyRejection>> studySession(
  Ref ref,
  String sessionId,
) => ref.watch(watchStudySessionUseCaseProvider)(sessionId: sessionId);

@riverpod
AnswerStudyTurnUseCase answerStudyTurnUseCase(Ref ref) =>
    AnswerStudyTurnUseCase(ref.watch(studySessionRepositoryProvider));

@riverpod
AbandonStudySessionUseCase abandonStudySessionUseCase(Ref ref) =>
    AbandonStudySessionUseCase(ref.watch(studySessionRepositoryProvider));

@riverpod
ResumeStudySessionUseCase resumeStudySessionUseCase(Ref ref) =>
    ResumeStudySessionUseCase(ref.watch(studySessionRepositoryProvider));
```

- [ ] **Step 3: State and controller.**

`study_turn_state.dart` — the three classes of the Interfaces block, with the doc comments shown there.

`study_session_controller.dart`:

```dart
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/providers/abandon_study_session_use_case_provider.dart';
import 'package:memox/features/study/presentation/providers/answer_study_turn_use_case_provider.dart';
import 'package:memox/features/study/presentation/providers/resume_study_session_use_case_provider.dart';
import 'package:memox/features/study/presentation/states/study_turn_state.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_session_controller.g.dart';

/// The one write path of a session (spec D4): its answers, its end, and the
/// settling of a stalled round. The session's stream shows what happened;
/// this holds only what the stream cannot: a write running, a turn held on
/// screen (D5), an answer a busy database refused (E2).
@riverpod
class StudySessionController extends _$StudySessionController {
  @override
  StudyTurnState build(String sessionId) => const StudyTurnState();

  /// Answers [item]. [holdsFeedback] keeps it on screen with its result
  /// until [release] (D5). A busy database keeps the answer for [retry]
  /// (E2); any other failure has already failed the session, whose summary
  /// the stream shows (E3, spec D6). Dropped while a write runs
  /// (BR-STUDY-004).
  Future<void> answer(
    StudyItem item,
    StudyAnswer answer, {
    bool holdsFeedback = false,
  }) async {
    if (state.isBusy) return;
    state = const StudyTurnState(isBusy: true);
    final pending = PendingAnswer(item, answer, holdsFeedback: holdsFeedback);
    try {
      final outcome = await ref.read(answerStudyTurnUseCaseProvider)(
        sessionId: sessionId,
        cardId: item.cardId,
        answer: answer,
      );
      state = switch (outcome) {
        Ok(:final value) when holdsFeedback => StudyTurnState(
          held: HeldTurn(item, value),
        ),
        // A refusal (the card moved on, the session closed) is the stream's
        // to show; nothing is held.
        _ => const StudyTurnState(),
      };
    } on DatabaseLockedFailure {
      state = StudyTurnState(unsaved: pending);
    } on Failure {
      state = const StudyTurnState();
    }
  }

  /// The answer a busy database refused, once more (E2).
  Future<void> retry() async {
    final pending = state.unsaved;
    if (pending == null) return;
    await answer(
      pending.item,
      pending.answer,
      holdsFeedback: pending.holdsFeedback,
    );
  }

  /// The held turn's mode met its continue condition (D5).
  void release() {
    if (state.held == null) return;
    state = const StudyTurnState();
  }

  /// ✕ and system Back: the session ends as `user_exit`; its turns stay
  /// (A3, BR-STUDY-014, BR-STUDY-019). The stream then shows the summary.
  Future<void> abandon() async {
    try {
      await ref.read(abandonStudySessionUseCaseProvider)(sessionId: sessionId);
    } on Failure {
      // The session stays open; the next start closes it (BR-STUDY-072).
    }
  }

  /// A stalled round (its cards were deleted) moves on (spec D12).
  Future<void> settle() async {
    if (state.isBusy) return;
    state = const StudyTurnState(isBusy: true);
    try {
      await ref.read(resumeStudySessionUseCaseProvider)(sessionId: sessionId);
    } on Failure {
      // The stream still shows the stalled session; its error state offers
      // nothing to retry, so the person closes it.
    } finally {
      state = const StudyTurnState();
    }
  }
}
```

- [ ] **Step 4:** Run `dart run build_runner build --delete-conflicting-outputs && flutter test test/features/study/presentation/study_session_controller_test.dart && flutter analyze` — Expected: PASS, clean.
- [ ] **Step 5:** Commit — `feat(study): the session controller — one write at a time, held turns, busy retry (FE-A6 D4, D5)`.

---

### Task 5: How an ended session shows (pure)

**Files:**
- Create: `lib/features/study/presentation/states/session_ending_state.dart`
- Test: `test/features/study/presentation/session_ending_state_test.dart`

**Interfaces — Produces:**

```dart
/// The summary states of screen 21 V8 can reach.
enum SummaryOutcome {
  reviewFinished,
  learningFinished,
  leftEarly,
  interrupted,
  reset,
  schedulerChanged,
  contentDeleted,
  saveError,
}

/// The hero's tone (FE-A6 D14): ok, paused, ended, error.
enum SummaryTone { success, paused, ended, error }

/// How the screen treats a session that is no longer open.
sealed class SessionEnding { const SessionEnding(); }
/// Show screen 21.
final class ShowSummary extends SessionEnding { const ShowSummary(this.outcome); final SummaryOutcome outcome; }
/// Leave with a toast: the session was written from a stale generation
/// (UC-STUDY-001 E4) — never a summary (handoff 21 ruling).
final class LeaveStale extends SessionEnding { const LeaveStale(); }

/// Null while [view] is open.
SessionEnding? sessionEndingOf(StudySessionView view);

extension SummaryOutcomeRules on SummaryOutcome {
  SummaryTone get tone;
  /// The footer's "Study this deck" (kit: loaded, learning, large, leftEarly).
  bool get canStudyAgain;
  /// The hero's three stats: only the ok and paused tones draw them (kit).
  bool get drawsStats;
  /// The facts card: every state but schedulerChanged (kit).
  bool get drawsFacts;
}
```

- [ ] **Step 1: Failing tests:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/states/session_ending_state.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

// Handoff 21's states; UC-STUDY-001 steps 13, A3, E3, E4.

StudySessionView _view(
  SessionStatus status, {
  SessionEndReason? reason,
  SessionKind kind = SessionKind.reviewing,
}) => StudySessionView(
  sessionId: 's',
  deckId: 'd',
  deckName: 'Nhà hàng',
  kind: kind,
  status: status,
  endReason: reason,
  currentMode: StudyMode.recall,
  direction: null,
  stages: const [StudyMode.recall],
  currentItem: null,
  progress: null,
  summary: status == SessionStatus.inProgress
      ? null
      : const SessionSummary(
          cardCount: 3,
          learnedCardCount: null,
          wrongTurnCount: 1,
          answeredCardCount: 2,
          turnCount: 3,
        ),
);

SummaryOutcome? _outcome(StudySessionView view) => switch (sessionEndingOf(view)) {
  ShowSummary(:final outcome) => outcome,
  _ => null,
};

void main() {
  test('an open session has no ending', () {
    expect(sessionEndingOf(_view(SessionStatus.inProgress)), isNull);
  });

  test('every end V8 can reach maps to its summary state', () {
    expect(
      _outcome(_view(SessionStatus.completed)),
      SummaryOutcome.reviewFinished,
    );
    expect(
      _outcome(_view(SessionStatus.completed, kind: SessionKind.learning)),
      SummaryOutcome.learningFinished,
    );
    for (final (status, reason, outcome) in [
      (SessionStatus.abandoned, SessionEndReason.userExit, SummaryOutcome.leftEarly),
      (SessionStatus.abandoned, SessionEndReason.interrupted, SummaryOutcome.interrupted),
      (SessionStatus.invalidated, SessionEndReason.schedulerReset, SummaryOutcome.reset),
      (SessionStatus.invalidated, SessionEndReason.schedulerChanged, SummaryOutcome.schedulerChanged),
      (SessionStatus.invalidated, SessionEndReason.contentDeleted, SummaryOutcome.contentDeleted),
      (SessionStatus.failed, SessionEndReason.persistenceError, SummaryOutcome.saveError),
    ]) {
      expect(_outcome(_view(status, reason: reason)), outcome, reason: '$reason');
    }
  });

  test('a stale generation leaves, with no summary (UC-STUDY-001 E4)', () {
    expect(
      sessionEndingOf(
        _view(
          SessionStatus.invalidated,
          reason: SessionEndReason.staleGeneration,
        ),
      ),
      isA<LeaveStale>(),
    );
  });

  test('tones, stats, facts and Study this deck follow the kit', () {
    expect(SummaryOutcome.reviewFinished.tone, SummaryTone.success);
    expect(SummaryOutcome.leftEarly.tone, SummaryTone.paused);
    expect(SummaryOutcome.interrupted.tone, SummaryTone.paused);
    expect(SummaryOutcome.reset.tone, SummaryTone.ended);
    expect(SummaryOutcome.contentDeleted.tone, SummaryTone.ended);
    expect(SummaryOutcome.saveError.tone, SummaryTone.error);
    expect(
      [for (final outcome in SummaryOutcome.values) if (outcome.canStudyAgain) outcome],
      [
        SummaryOutcome.reviewFinished,
        SummaryOutcome.learningFinished,
        SummaryOutcome.leftEarly,
      ],
    );
    expect(SummaryOutcome.saveError.drawsStats, isFalse);
    expect(SummaryOutcome.interrupted.drawsStats, isTrue);
    expect(SummaryOutcome.schedulerChanged.drawsFacts, isFalse);
    expect(SummaryOutcome.saveError.drawsFacts, isTrue);
  });
}
```

Run — Expected: FAIL (file missing).

- [ ] **Step 2: Implement** `session_ending_state.dart` with the Interfaces block's types and:

```dart
SessionEnding? sessionEndingOf(StudySessionView view) {
  final learning = view.kind == SessionKind.learning;
  return switch ((view.status, view.endReason)) {
    (SessionStatus.inProgress, _) => null,
    (SessionStatus.completed, _) => ShowSummary(
      learning ? SummaryOutcome.learningFinished : SummaryOutcome.reviewFinished,
    ),
    (_, SessionEndReason.staleGeneration) => const LeaveStale(),
    (_, SessionEndReason.userExit) => const ShowSummary(SummaryOutcome.leftEarly),
    (_, SessionEndReason.interrupted) => const ShowSummary(SummaryOutcome.interrupted),
    (_, SessionEndReason.schedulerReset) => const ShowSummary(SummaryOutcome.reset),
    (_, SessionEndReason.schedulerChanged) => const ShowSummary(SummaryOutcome.schedulerChanged),
    (_, SessionEndReason.contentDeleted) => const ShowSummary(SummaryOutcome.contentDeleted),
    // failed/persistence_error, and any end the schema's matrix forbids.
    (_, SessionEndReason.persistenceError || null) => const ShowSummary(SummaryOutcome.saveError),
  };
}

extension SummaryOutcomeRules on SummaryOutcome {
  SummaryTone get tone => switch (this) {
    SummaryOutcome.reviewFinished || SummaryOutcome.learningFinished => SummaryTone.success,
    SummaryOutcome.leftEarly || SummaryOutcome.interrupted => SummaryTone.paused,
    SummaryOutcome.reset || SummaryOutcome.schedulerChanged || SummaryOutcome.contentDeleted => SummaryTone.ended,
    SummaryOutcome.saveError => SummaryTone.error,
  };

  bool get canStudyAgain => switch (this) {
    SummaryOutcome.reviewFinished || SummaryOutcome.learningFinished || SummaryOutcome.leftEarly => true,
    _ => false,
  };

  bool get drawsStats => switch (tone) {
    SummaryTone.success || SummaryTone.paused => true,
    SummaryTone.ended || SummaryTone.error => false,
  };

  bool get drawsFacts => this != SummaryOutcome.schedulerChanged;
}
```

- [ ] **Step 3:** Run `flutter test test/features/study/presentation/session_ending_state_test.dart && flutter analyze` — Expected: PASS, clean.
- [ ] **Step 4:** Commit — `feat(study): how an ended session shows, from the kit's states (handoff 21)`.

---

### Task 6: Screen 21, the session summary

**Files:**
- Create: `lib/features/study/presentation/widgets/sections/session_summary_widget.dart` (the body and footer), `session_summary_hero_widget.dart`, `session_summary_facts_widget.dart`
- Test: `test/features/study/presentation/session_summary_test.dart`

**Interfaces:**
- Consumes: Task 1 strings, Task 2 roles/glyphs, Task 5 types, `MxCard(isSuccess/isWarning/isDanger)`, `MxIconTile(size: MxIconTileSize.large, tone: …)`, `MxStatTile`, `MxListSectionHeader`, `MxListRow`, `MxNote`, `MxFooterBar`, `MxButton`, `MxAppBar`, `MxAppShell`, `MxScreenScroll`.
- Produces: `SessionSummaryWidget({required StudySessionView view, required SummaryOutcome outcome, required VoidCallback onDone, required VoidCallback onStudyDeck})` — a whole page (`MxAppShell` with the app bar and footer).

**Layout (kit `StudyResultScreenV3`, `SessionStatusHero`):**
- App bar: `MxAppBar(title: l10n.summaryAppBar, density: MxAppBarDensity.content)`, no leading, no actions (the kit's muted 14/600 title is the content density's title; record the ink difference if the golden shows it).
- Hero: tone → `MxCard` flag: success `isSuccess`, ended `isWarning`, error `isDanger`, paused plain; `MxIconTile(size: large)` tone success→`success`, paused→`tinted`, ended→`caution`, error→`danger`, glyph success→`AppIcons.learned`, paused→`AppIcons.pause`, ended→`AppIcons.resetProgress`, error→`AppIcons.alert`. Then, centred: overline `summaryOverline(kind, view.deckName)` upper-cased (`styles.overline`, `semanticsLabel` the plain text), `summaryTitle`, the body (`styles.emptyBody`; the count run in `summaryBodyStrong` where the kit bolds it), and when `outcome.drawsStats && summary.hasAnswers` a row of three `MxStatTile(layout: inline)`: finished (`summaryStatReviewed`/`summaryStatLearned`, the finished count), `summaryStatAnswered`, `summaryStatWrong` with `summaryWrongOf(wrong, turns)`; the first stat's emphasis `primary`, the others `plain`.
- Finished count: learning → `summary.learnedCardCount`; review → `summary.answeredCardCount`.
- Bodies: reviewFinished `summaryReviewFinishedBody(summaryCards(finished))` bold run `summaryCards(finished)`; learningFinished `summaryLearningFinishedBody(summaryCards(finished))`, bold run the same; leftEarly learning `summaryLeftEarlyLearningBody(finished, cardCount − finished)`, review `summaryLeftEarlyReviewBody(finished, cardCount − finished)`; the others their fixed body.
- Facts (`outcome.drawsFacts && summary.hasAnswers`): `MxListSectionHeader(label: summaryFactsHeader)`, a full-bleed `MxCard` of three `MxListRow`s, each `leading: MxIconTile(icon: …)` (learned / `cardDeck` / `lapses`), `trailing: Text(value, style: styles.factValue(ink))`: finished (`summaryFactLearned`+`summaryFactLearnedSub` or `summaryFactReviewed`+`summaryFactReviewedSub`, ink `derivedColors.successInk`), answered (`summaryFactAnswered`, ink `colors.onSurface`), wrong (`summaryFactWrong`, sub `summaryFactWrongCameBack(turns)` when wrong > 0 else `summaryFactWrongSub(turns)`, value `summaryWrongOf`, ink `derivedColors.warningInk` when wrong > 0 else `colors.onSurface`); the last row `hasDivider: false`.
- Note: schedulerChanged `MxNote(text: summaryNoteHistory)`; contentDeleted `MxNote(text: summaryNoteTrash, icon: AppIcons.history)`.
- Footer: `MxFooterBar(caption: summaryDoneCaption, child: Row(spacing: AppSpacing.control, …))`: when `outcome.canStudyAgain` an `Expanded` `MxButton(label: studyThisDeck, tone: outline, icon: AppIcons.play, isBlock: true, onPressed: onStudyDeck)`, then `Expanded(flex: …)` `MxButton(label: summaryDone, icon: AppIcons.check, isBlock: true, onPressed: onDone)` (kit flex 1 : 1.2 — use flex 5 : 6).
- D18: `!summary.hasAnswers` → no stats and no facts.

- [ ] **Step 1: Failing tests** (`session_summary_test.dart`; `pumpLibraryScreen` hosts the widget; views built by hand):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/states/session_ending_state.dart';
import 'package:memox/features/study/presentation/widgets/sections/session_summary_widget.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';

import '../../../support/library_harness.dart';

// Screen 21: handoff states; UC-STUDY-001 steps 13, A3, E3; FE-A6 D18.

final _en = lookupAppLocalizations(const Locale('en'));

StudySessionView summaryView({
  SessionKind kind = SessionKind.reviewing,
  SessionStatus status = SessionStatus.completed,
  SessionEndReason? reason,
  SessionSummary summary = const SessionSummary(
    cardCount: 20,
    learnedCardCount: null,
    wrongTurnCount: 3,
    answeredCardCount: 20,
    turnCount: 23,
  ),
}) => StudySessionView(
  sessionId: 's',
  deckId: 'd',
  deckName: 'Nhà hàng',
  kind: kind,
  status: status,
  endReason: reason,
  currentMode: StudyMode.recall,
  direction: null,
  stages: const [StudyMode.recall],
  currentItem: null,
  progress: null,
  summary: summary,
);

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  StudySessionView view,
  SummaryOutcome outcome, {
  VoidCallback? onDone,
  VoidCallback? onStudyDeck,
}) => pumpLibraryScreen(
  tester,
  env,
  SessionSummaryWidget(
    view: view,
    outcome: outcome,
    onDone: onDone ?? () {},
    onStudyDeck: onStudyDeck ?? () {},
  ),
);

void main() {
  libraryTest('a finished review: title, body, three stats and three facts '
      '(handoff 21 loaded)', (tester, env) async {
    var done = 0;
    var again = 0;
    await _pump(
      tester,
      env,
      summaryView(),
      SummaryOutcome.reviewFinished,
      onDone: () => done++,
      onStudyDeck: () => again++,
    );

    expect(find.text(_en.summaryReviewFinished), findsOneWidget);
    expect(
      find.text(_en.summaryReviewFinishedBody(_en.summaryCards(20)), findRichText: true),
      findsOneWidget,
    );
    expect(
      [for (final tile in tester.widgetList<MxStatTile>(find.byType(MxStatTile))) (tile.label, tile.value)],
      [
        (_en.summaryStatReviewed, '20'),
        (_en.summaryStatAnswered, '20'),
        (_en.summaryStatWrong, _en.summaryWrongOf(3, 23)),
      ],
    );
    expect(find.byType(MxListRow), findsNWidgets(3));
    expect(find.text(_en.summaryFactWrongCameBack(23)), findsOneWidget);

    await tester.tap(find.widgetWithText(MxButton, _en.summaryDone));
    await tester.tap(find.widgetWithText(MxButton, _en.studyThisDeck));
    expect((done, again), (1, 1));
  });

  libraryTest('left early in learning: the finished cards are kept, the rest '
      'stay new (handoff 21 leftEarly)', (tester, env) async {
    await _pump(
      tester,
      env,
      summaryView(
        kind: SessionKind.learning,
        status: SessionStatus.abandoned,
        reason: SessionEndReason.userExit,
        summary: const SessionSummary(
          cardCount: 12,
          learnedCardCount: 4,
          wrongTurnCount: 2,
          answeredCardCount: 9,
          turnCount: 14,
        ),
      ),
      SummaryOutcome.leftEarly,
    );

    expect(find.text(_en.summaryLeftEarly), findsOneWidget);
    expect(find.text(_en.summaryLeftEarlyLearningBody(4, 8)), findsOneWidget);
    expect(find.text(_en.summaryFactLearned), findsOneWidget);
    expect(find.widgetWithText(MxButton, _en.studyThisDeck), findsOneWidget);
  });

  libraryTest('an ended or failed session draws no stats and offers no '
      'Study this deck (handoff 21 reset, saveError)', (tester, env) async {
    await _pump(
      tester,
      env,
      summaryView(status: SessionStatus.failed, reason: SessionEndReason.persistenceError),
      SummaryOutcome.saveError,
    );

    expect(find.text(_en.summarySaveErrorBody), findsOneWidget);
    expect(find.byType(MxStatTile), findsNothing);
    expect(find.byType(MxListRow), findsNWidgets(3));
    expect(find.widgetWithText(MxButton, _en.studyThisDeck), findsNothing);
  });

  libraryTest('an algorithm change draws no facts and says nothing was lost '
      '(handoff 21 schedulerChanged)', (tester, env) async {
    await _pump(
      tester,
      env,
      summaryView(status: SessionStatus.invalidated, reason: SessionEndReason.schedulerChanged),
      SummaryOutcome.schedulerChanged,
    );

    expect(find.byType(MxListRow), findsNothing);
    expect(find.text(_en.summaryNoteHistory), findsOneWidget);
  });

  libraryTest('a session that ended before its first turn draws neither '
      'stats nor facts (FE-A6 D18)', (tester, env) async {
    await _pump(
      tester,
      env,
      summaryView(
        status: SessionStatus.abandoned,
        reason: SessionEndReason.userExit,
        summary: const SessionSummary(
          cardCount: 5,
          learnedCardCount: null,
          wrongTurnCount: 0,
          answeredCardCount: 0,
          turnCount: 0,
        ),
      ),
      SummaryOutcome.leftEarly,
    );

    expect(find.byType(MxStatTile), findsNothing);
    expect(find.byType(MxListRow), findsNothing);
  });

  libraryTest('the summary holds at text scale 2 (FE-A6 D19)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      SessionSummaryWidget(
        view: summaryView(),
        outcome: SummaryOutcome.reviewFinished,
        onDone: () {},
        onStudyDeck: () {},
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
```

Run — Expected: FAIL (widget missing).

- [ ] **Step 2: Implement** the three widgets per the Layout list. The body's bold run: in `session_summary_hero_widget.dart`, a private helper

```dart
/// [body] with its [strong] run in the strong role, as the kit bolds the
/// count; the whole [body] when it does not contain [strong].
Text _bodyText(BuildContext context, String body, String? strong) {
  final styles = context.textStyles;
  final start = strong == null ? -1 : body.indexOf(strong);
  if (start < 0) {
    return Text(body, style: styles.emptyBody, textAlign: TextAlign.center);
  }
  return Text.rich(
    TextSpan(
      style: styles.emptyBody,
      children: [
        TextSpan(text: body.substring(0, start)),
        TextSpan(text: strong, style: styles.summaryBodyStrong),
        TextSpan(text: body.substring(start + strong!.length)),
      ],
    ),
    textAlign: TextAlign.center,
  );
}
```

Stat values use `l10n.studyCount(n)`. The page: `MxAppShell(appBar: …, body: MxScreenScroll(children: [gap micro, hero, gap grouped, facts?, note?]), footer: MxFooterBar(…))` — check `MxAppShell`'s `footer` slot (`lib/shared/widgets/mx_app_shell.dart`) and use it as the kit's `BottomBar`.

- [ ] **Step 3:** Run `flutter test test/features/study/presentation/session_summary_test.dart && flutter analyze && python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8` — Expected: PASS, clean, guard passes.
- [ ] **Step 4:** Commit — `feat(study): screen 21, the session summary (FE-A6)`.

---

### Task 7: Screen 16, Browse

**Files:**
- Create: `lib/features/study/presentation/widgets/sections/study_browse_widget.dart`; `lib/features/study/presentation/widgets/support/session_context_line_widget.dart`, `session_footer_hint_widget.dart`
- Test: `test/features/study/presentation/study_browse_test.dart`

**Interfaces:**
- Consumes: `StudySessionView` (with `trail`), Task 1–2, `MxCard(isFullBleed)`, `MxBadge`.
- Produces:
  - `SessionContextLineWidget({required String text})` — the centred overline under the top bar (kit `SessionContextLine`: overline, centred, padding 0/16/20 with a −4 pull → `EdgeInsets.fromLTRB(gutter, 0, gutter, section)`).
  - `SessionFooterHintWidget({required IconData icon, required String text})` — centred glyph + `sessionHint` text (kit `SessionFooterHint`), the glyph in the hint's ink through `IconTheme.merge`.
  - `StudyBrowseWidget({required StudySessionView view, required StudyItem item, required bool isBusy, required VoidCallback onAdvance})` — the card and its swipe; the shell (Task 8) draws the top bar and context line around it.

**Behaviour (handoff 16, BR-STUDY-048, D20):**
- State: `_lookBack` (0 = the live card). Showing: `_lookBack == 0 ? item : view.trail[view.trail.length - _lookBack]` (a `TrailCard`; map the live `StudyItem` to the same face fields).
- Swipe (horizontal drag end, |dx| > 70 or |velocity| > 600): left → `_lookBack > 0 ? _lookBack-- : onAdvance()` (dropped while `isBusy`); right → `_lookBack < view.trail.length ? _lookBack++ : nothing`. While dragging, the card follows the finger (`Transform.translate`), and returns on release; with reduced motion it does not follow.
- When the live item changes (`didUpdateWidget`, new `cardId`), `_lookBack` resets to 0.
- While `_lookBack > 0`: an `MxBadge(label: studyBrowseLookingBack, tone: neutral)` at the card's top-right (BR-STUDY-048: the screen says it is looking back); counter unchanged.
- Card: full-bleed `MxCard`, two `Expanded` halves separated by a hairline (`Divider` from the theme, indent 20): top — overline `studyBrowseTerm` at the top-left (Positioned 16/20), centred `front` in `studyTerm` (wraps), pronunciation in `studyDetail`; bottom — overline `studyBrowseMeaning`, centred `back` in `studyMeaning`, example in `studyDetail`.
- Semantics: the card is one container with `customSemanticsActions`: `studyBrowseNext` always (it advances or steps forward), `studyBrowsePrevious` only when `_lookBack < view.trail.length` (IT-MODE-002 step 7).
- Below the card: `SessionFooterHintWidget(icon: AppIcons.swipe, text: studyBrowseHint)` — the text never changes (D20).

- [ ] **Step 1: Failing tests** (`study_browse_test.dart`) — through the real screen once Task 8 exists would couple the tasks; here pump the widget over a real session's view, watched by a small host:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';
import 'package:memox/features/study/presentation/providers/study_session_provider.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_browse_widget.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_badge.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

// Screen 16: IT-MODE-002; BR-STUDY-048; FE-A6 D20.

final _en = lookupAppLocalizations(const Locale('en'));

/// Browse over [sessionId]'s live view, answering through the controller.
class _Host extends ConsumerWidget {
  const _Host(this.sessionId);
  final String sessionId;

  void _advance(WidgetRef ref, StudyItem item) => ref
      .read(studySessionControllerProvider(sessionId).notifier)
      .answer(item, const AdvanceAnswer());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turn = ref.watch(studySessionControllerProvider(sessionId));
    return switch (ref.watch(studySessionProvider(sessionId))) {
      AsyncData(value: Ok(:final value)) when value.currentItem != null =>
        Material(
          child: StudyBrowseWidget(
            view: value,
            item: value.currentItem!,
            isBusy: turn.isBusy,
            onAdvance: () => _advance(ref, value.currentItem!),
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

Future<String> _session(LibraryEnv env, List<String> ids) async {
  final root = await env.decks.root('Korean');
  for (final id in ids) {
    await insertCard(env.db, id: id, deckId: root.id, front: 'front $id', back: 'back $id');
  }
  final opened = await studyEntryRepository(env.db, DateTime.now)
      .openLearningSession(deckId: root.id);
  return (opened as Ok<String, StudyRejection>).value;
}

Future<void> _swipe(WidgetTester tester, double dx) async {
  await tester.drag(find.byType(StudyBrowseWidget), Offset(dx, 0));
  await tester.pumpAndSettle();
}

String _front(WidgetTester tester) => tester
    .widgetList<Text>(find.textContaining('front '))
    .single
    .data!;

void main() {
  libraryTest('both faces show at once, labelled, with no grading control '
      '(IT-MODE-002 steps 1–3)', (tester, env) async {
    final id = await _session(env, ['a', 'b', 'c']);
    await pumpLibraryScreen(tester, env, _Host(id));
    await tester.pumpAndSettle();

    expect(find.text(_en.studyBrowseTerm.toUpperCase()), findsOneWidget);
    expect(find.text(_en.studyBrowseMeaning.toUpperCase()), findsOneWidget);
    expect(find.textContaining('back '), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.text(_en.studyBrowseHint), findsOneWidget);
  });

  libraryTest('left advances one stop; right looks back without writing; '
      'left from a look-back returns and does not answer twice '
      '(IT-MODE-002 steps 4–6, BR-STUDY-048)', (tester, env) async {
    final id = await _session(env, ['a', 'b', 'c']);
    await pumpLibraryScreen(tester, env, _Host(id));
    await tester.pumpAndSettle();
    final first = _front(tester);

    await _swipe(tester, -300);
    final second = _front(tester);
    expect(second, isNot(first));
    expect((await watchSessionOnce(env.db, id)).progress!.completed, 1);

    await _swipe(tester, 300);
    expect(_front(tester), first);
    expect(find.widgetWithText(MxBadge, _en.studyBrowseLookingBack), findsOneWidget);
    expect((await watchSessionOnce(env.db, id)).progress!.completed, 1);

    await _swipe(tester, -300);
    expect(_front(tester), second);
    expect((await watchSessionOnce(env.db, id)).progress!.completed, 1);

    await _swipe(tester, -300);
    expect((await watchSessionOnce(env.db, id)).progress!.completed, 2);
  });

  libraryTest('a right swipe on the round\'s first card does nothing '
      '(FE-A6 D20)', (tester, env) async {
    final id = await _session(env, ['a', 'b']);
    await pumpLibraryScreen(tester, env, _Host(id));
    await tester.pumpAndSettle();
    final first = _front(tester);

    await _swipe(tester, 300);

    expect(_front(tester), first);
    expect(find.byType(MxBadge), findsNothing);
  });

  libraryTest('the card offers Next always and Previous only when there is a '
      'card behind (IT-MODE-002 step 7)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final id = await _session(env, ['a', 'b', 'c']);
    await pumpLibraryScreen(tester, env, _Host(id));
    await tester.pumpAndSettle();

    bool hasAction(String label) => tester
        .getSemantics(find.byType(StudyBrowseWidget))
        .getSemanticsData()
        .customSemanticsActionIds!
        .map(CustomSemanticsAction.getAction)
        .any((action) => action?.label == label);

    expect(hasAction(_en.studyBrowseNext), isTrue);
    expect(hasAction(_en.studyBrowsePrevious), isFalse);
    await _swipe(tester, -300);
    expect(hasAction(_en.studyBrowsePrevious), isTrue);
    handle.dispose();
  });
}
```

(`CustomSemanticsAction.getAction` takes the id; if the semantics node of `StudyBrowseWidget` is not the one carrying the actions, find it with `find.bySemanticsLabel` of the term, or give the card's `Semantics` a key and `getSemantics(find.byKey(…))`.)

Run — Expected: FAIL (widget missing).

- [ ] **Step 2: Implement** the three widgets per the Behaviour list. `StudyBrowseWidget` is a `StatefulWidget` (UI state only: `_lookBack`, `_dragDx`); it never reads a provider. Face fields: a private record `({String front, String back, String? pronunciation, String? example})` from either the `StudyItem` or a `TrailCard`.
- [ ] **Step 3:** Run `flutter test test/features/study/presentation/study_browse_test.dart && flutter analyze && python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8` — Expected: PASS, clean.
- [ ] **Step 4:** Commit — `feat(study): screen 16, Browse — both faces, swipe on, look back (FE-A6)`.

---

### Task 8: The session screen and route

**Files:**
- Create: `lib/features/study/presentation/screens/study_session_screen.dart`; `lib/features/study/presentation/widgets/sections/study_mode_not_built_widget.dart`
- Modify: `lib/features/study/presentation/states/study_entry_offer_state.dart` (`builtStudyModes = {StudyMode.browse}`), `lib/app/router/app_routes.dart`, `lib/app/router/app_router.dart`
- Test: `test/features/study/presentation/study_session_screen_test.dart`, `test/app/library_routes_test.dart`

**Interfaces:**
- Produces: `StudySessionScreen({required String sessionId, required ValueChanged<String> onDone, required ValueChanged<String> onStudyDeck, required ValueChanged<String?> onLeave})` — `onDone(deckId)` and `onStudyDeck(deckId)` from the summary; `onLeave(deckId)` after a toast: the deck for E4, null (the Library) for A5. `AppRoutes.studySession(String id)` → `/study/session/$id`, `AppRoutes.studySessionPath = '/study/session/:$sessionIdParam'`, `sessionIdParam = 'sessionId'`.

**Behaviour:**
- Body by `ref.watch(studySessionProvider(sessionId))`:
  - loading → `MxAppShell(body: Center(MxSpinner(semanticLabel: commonLoading)))` (the kit's 21 `loading` frame is not reachable: the summary arrives with the session's view, D2 — record it in handoff 21);
  - error → `MxErrorState(title: studySessionErrorTitle, body: studySessionErrorBody, retryLabel: commonRetry, onRetry: _retry)` inside a shell with a close `MxIconButton` that calls `onLeave(null)` (E5);
  - `Rejected` → nothing (the listener leaves);
  - `Ok(view)` with `sessionEndingOf(view)` a `ShowSummary` → `SessionSummaryWidget(onDone: () => onDone(view.deckId), onStudyDeck: () => onStudyDeck(view.deckId))`;
  - `Ok(view)` open → the shell: `MxStudyTopBar(modeLabel: l10n.studyMode(view.currentMode), current: min(progress.completed + 1, progress.total), total: progress.total, counterLabel: studySessionCounter(…), closeLabel: studySessionClose, onClose: _abandon)`, `SessionContextLineWidget(text: studyContextLearning(view.deckName, studyKindLearning, view.currentStageIndex + 1, view.stages.length, l10n.studyMode(view.currentMode)))` for a learning session (a review session's line arrives with the review modes in P2), then the body by an exhaustive `switch (view.currentMode)`: `browse` → `StudyBrowseWidget(…, onAdvance: () => _advance(item))`; `selfAssess`, `match`, `guess`, `recall`, `fill` → `StudyModeNotBuiltWidget(mode: …)` (`MxEmptyState(icon: AppIcons.upcoming, title: studyModeNotBuiltTitle(mode name), body: studyModeNotBuiltBody, isCompact: true)`); when `turn.unsaved != null`, an `MxInlineBanner(tone: danger, title: studyAnswerBusyTitle, message: studyAnswerBusyBody, actions: [MxButton(label: commonRetry, size: compact, onPressed: _retry)])` above the hint.
  - An open view with `isStalled` or no `progress` → the shell with a spinner body (the listener settles it).
  - The item drawn is `turn.held?.item ?? view.currentItem`.
- `ref.listen(studySessionProvider(sessionId), …)` in `build` → `_onView`: `Rejected(notFound)` → toast `studyEntryDeckGone`, `onLeave(null)` (A5); `Ok(view)` with `LeaveStale` → toast `studySessionStaleToast`, `onLeave(view.deckId)` (E4); `Ok(view)` stalled → `settle()`. Each leave runs once: guard with `ModalRoute.of(context)?.isCurrent` as P1b does.
- System Back: `PopScope(canPop: false, onPopInvokedWithResult: (didPop, _) => _onBack(didPop))`: an open session → `_abandon()` (the summary follows, owner ruling); an ended one → `onDone(deckId)`.
- Methods, not closures reading `ref` in build: `_abandon()`, `_advance(StudyItem)`, `_retry()`, `_settle()`, `_onView(…)`, `_onBack(bool)` — `StudySessionScreen` is a `ConsumerStatefulWidget` so they reach `ref`.

**Router:** a top-level `GoRoute(path: AppRoutes.studySessionPath, builder: …)` beside the gallery route (root navigator, no tab bar, D2):

```dart
    GoRoute(
      path: AppRoutes.studySessionPath,
      builder: (context, state) => StudySessionScreen(
        sessionId: state.pathParameters[AppRoutes.sessionIdParam]!,
        onDone: (deckId) => context.go(AppRoutes.deck(deckId)),
        onStudyDeck: (deckId) => context.go(AppRoutes.studyEntry(deckId)),
        onLeave: (deckId) => context.go(
          deckId == null ? AppRoutes.decks : AppRoutes.deck(deckId),
        ),
      ),
    ),
```

- [ ] **Step 1: Failing tests.**

`study_session_screen_test.dart` (the `_session` helper of Task 7; pump `StudySessionScreen` with recording callbacks):

```dart
  libraryTest('the shell names the mode, the round and the stage '
      '(handoff 16; BR-STUDY-049)', (tester, env) async {
    final id = await _session(env, ['a', 'b', 'c']);
    await _pumpScreen(tester, env, id);

    final bar = tester.widget<MxStudyTopBar>(find.byType(MxStudyTopBar));
    expect((bar.modeLabel, bar.current, bar.total), (_en.cardModeBrowse, 1, 3));
    // The stages the session has rows in (IT-MODE-001), read, not assumed.
    final stages = (await watchSessionOnce(env.db, id)).stages.length;
    expect(
      find.text(
        _en
            .studyContextLearning(
              'Korean',
              _en.studyKindLearning,
              1,
              stages,
              _en.cardModeBrowse,
            )
            .toUpperCase(),
      ),
      findsOneWidget,
    );
  });

  libraryTest('✕ abandons at once and the same screen shows "You left early" '
      '(owner ruling on D8; UC-STUDY-001 A3)', (tester, env) async {
    final id = await _session(env, ['a', 'b']);
    await _pumpScreen(tester, env, id);

    await tester.tap(find.byTooltip(_en.studySessionClose));
    await tester.pumpAndSettle();

    expect(find.text(_en.summaryLeftEarly), findsOneWidget);
    final session = await sessionOf(env.db, id);
    expect(session.read<String>('end_reason'), 'user_exit');
  });

  libraryTest('system Back on the summary is Done: it never returns to a '
      'closed session', (tester, env) async {
    final id = await _session(env, ['a']);
    final done = <String>[];
    await _pumpScreen(tester, env, id, onDone: done.add);
    await tester.tap(find.byTooltip(_en.studySessionClose));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(done, hasLength(1));
  });

  libraryTest('a busy database shows the error on the same card and Retry '
      'saves it (UC-STUDY-001 E2)', (tester, env) async {
    final id = await _session(env, ['a', 'b']);
    final sessions = LockableSessions(
      studySessionRepository(env.db, DateTime.now),
    )..isLocked = true;
    await _pumpScreen(
      tester,
      env,
      id,
      overrides: [studySessionRepositoryProvider.overrideWithValue(sessions)],
    );
    final front = _front(tester);

    await tester.drag(find.byType(StudyBrowseWidget), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text(_en.studyAnswerBusyTitle), findsOneWidget);
    expect(_front(tester), front);

    sessions.isLocked = false;
    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();
    expect(find.text(_en.studyAnswerBusyTitle), findsNothing);
    expect(_front(tester), isNot(front));
  });

  libraryTest('the deck moved to the Trash leaves once, for the Library, '
      'with a message (UC-STUDY-001 A5)', (tester, env) async {
    final id = await _session(env, ['a', 'b']);
    final left = <String?>[];
    await _pumpScreen(tester, env, id, onLeave: left.add);

    final session = await sessionOf(env.db, id);
    await env.decks.deleteDeck(deckId: session.read<String>('deck_id'));
    await tester.pumpAndSettle();

    expect(left, [null]);
    expect(find.text(_en.studyEntryDeckGone), findsOneWidget);
  });

  libraryTest('a write from a stale generation leaves for the deck, with no '
      'summary (UC-STUDY-001 E4)', (tester, env) async {
    final id = await _session(env, ['a', 'b']);
    final left = <String?>[];
    await _pumpScreen(tester, env, id, onLeave: left.add);

    await env.db.customUpdate(
      "UPDATE study_session SET status = 'invalidated', "
      "end_reason = 'stale_generation', ended_at = ? WHERE id = ?",
      variables: [Variable<DateTime>(DateTime.now()), Variable<String>(id)],
      updates: {env.db.studySession},
    );
    await tester.pumpAndSettle();

    final session = await sessionOf(env.db, id);
    expect(left, [session.read<String>('deck_id')]);
    expect(find.text(_en.studySessionStaleToast), findsOneWidget);
    expect(find.text(_en.summaryReset), findsNothing);
  });

  libraryTest('a mode not built yet says so; ✕ still leaves (spec §3)', (
    tester,
    env,
  ) async {
    final id = await _session(env, ['a', 'b']);
    await _pumpScreen(tester, env, id);
    for (var i = 0; i < 2; i++) {
      await tester.drag(find.byType(StudyBrowseWidget), const Offset(-300, 0));
      await tester.pumpAndSettle();
    }

    // Browse is done; the next stage has no screen yet.
    expect(find.byType(StudyModeNotBuiltWidget), findsOneWidget);
    expect(find.byType(MxStudyTopBar), findsOneWidget);
  });
```

where `_pumpScreen(tester, env, id, {onDone, onStudyDeck, onLeave, overrides})` (passing `overrides` to `pumpLibraryScreen`) hosts `StudySessionScreen` in `MxAppShell`-less `pumpLibraryScreen` inside a `Navigator` route (as P1b's deleted-deck test does, so `isCurrent` is true), defaulting the callbacks to no-ops. The E2 test uses Task 4's `_LockableSessions`: move it to `test/support/study_fixtures.dart` as the public `LockableSessions` in this task and import it in both test files; `_front` is Task 7's helper, copied. (The stale-generation update needs `status`/`end_reason`/`ended_at` to satisfy the table's check; if `deck_id` is not the column name, read it from `lib/core/database/tables/`.)

`test/app/library_routes_test.dart` — add (imports: `package:go_router/go_router.dart`, `app_routes.dart`, `study_session_screen.dart`, `study_fixtures.dart`, `card_fixtures.dart`):

```dart
  libraryTest('a session is a full-screen route with no tab bar; ✕ shows '
      'its summary and Done returns to its deck (FE-A6 D2)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await insertCard(env.db, id: 'n1', deckId: korean.id);
    final opened = await studyEntryRepository(env.db, DateTime.now)
        .openLearningSession(deckId: korean.id);
    final id = (opened as Ok<String, StudyRejection>).value;
    await pumpMemoxApp(tester, env);

    unawaited(
      GoRouter.of(tester.element(find.byType(MxBottomNav)))
          .push(AppRoutes.studySession(id)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(StudySessionScreen), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);

    await _tap(tester, find.byTooltip(_en.studySessionClose));
    await _tap(tester, find.text(_en.summaryDone));

    expect(find.byType(StudySessionScreen), findsNothing);
    expect(_barTitle('Korean'), findsOneWidget);
  });
```

Run — Expected: FAIL (screen and route missing).

- [ ] **Step 2: Implement** the screen, the not-built widget, the route constants and the route; set `builtStudyModes = {StudyMode.browse}` with its doc line "Browse (P1c); the rest arrive in P2–P4" and run `flutter test test/features/study/presentation/study_entry_offer_state_test.dart` (unchanged expectations: Learn still needs the whole sequence).
- [ ] **Step 3:** Run `dart run build_runner build --delete-conflicting-outputs && flutter test --exclude-tags golden test/features/study test/app && flutter analyze && python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8 && bash .claude/skills/flutter-architecture/scripts/check_architecture.sh` — Expected: PASS, clean.
- [ ] **Step 4:** Commit — `feat(study): the session route — shell, exit to summary, ended states (FE-A6 D2–D8)`.

---

### Task 9: Goldens and visual audit

**Files:**
- Create: `test/visual_audit/screens/features/study/screens/study_session_screen_visual_audit_test.dart`, `test/features/study/presentation/study_session_golden_test.dart`, goldens
- [ ] **Step 1: Companion** — two `libraryTest`s calling `auditProductionScreen(tester, screen: StudySessionScreen, pump: …)`: a Browse session (three cards, one with pronunciation and example), and the same session after ✕ (the summary). Run `flutter test test/visual_audit` — Expected: PASS.
- [ ] **Step 2: Goldens** (tag `golden`, both brightnesses, `pumpLibraryGolden`, Latin/Vietnamese text): `study_browse` (a learning session on "Động từ" whose served card has front `ăn uống`, back `to eat and drink`, pronunciation `an uong`, example `Tôi ăn sáng lúc 7 giờ.` — seed that one card only so it is served), `study_browse_looking_back` (two cards, swipe left then right), and screen 21 from hand-built views pumped as `SessionSummaryWidget` (the `summaryView` helper of Task 6 moved to `test/support/study_fixtures.dart`): `summary_review` (20/20, 3/23), `summary_learning` (learned 12, 12, 5/53), `summary_left_early` (learning 4, 9, 2/14 of 12), `summary_interrupted` (review 7, 7, 1/8), `summary_reset` (review 5, 5, 0/5), `summary_scheduler_changed`, `summary_content_deleted` (review 3, 3, 0/3), `summary_save_error` (review 11, 11, 2/13) — the kit's numbers.
  Run `TZ=UTC flutter test --tags golden --update-goldens test/features/study`, then `TZ=UTC flutter test --tags golden` (every golden passes; only new files appear in `git status`). Open each PNG next to `docs/shared/ui/screen-handoff/img/16-study-browse/default-light.png` and `img/21-session-summary/*-light.png`.
- [ ] **Step 3:** Commit — `test(study): session and summary goldens and visual audit (FE-A6)`.

---

### Task 10: Records

- [ ] Spec: amend D8 to "Exit: the ✕ and system Back abandon the session at once, with no confirm (handoff 16); the same route then shows the summary 'You left early' (D2), whose Done returns to the deck. | Owner, 2026-09-26: an abandoned session cannot be continued (UC-STUDY-001 A3, A3b)." Add to §3's P1 row that the Browse trail joins the read model (BR-STUDY-048).
- [ ] `docs/shared/ui/screen-handoff/16-study-browse.md`: a "Built (FE-A6 P1c)" note (the look-back badge, the drag that follows the finger with no tilt, pronunciation in the body face — V8 has no monospace face), deviations for those.
- [ ] `21-session-summary.md`: `contentDeleted` is reachable since BE-B1 (Trash) and is built with the kit's copy (replace the "Not captured" paragraph and the deviation row); `large` shows the review body without "— the session limit" (the read model has no `card_limit`; a later read-model addition); `loading` is not reachable (D2); the left-early body of a review session is a V8 addition ("The {n} cards you reviewed are kept. The other {m} are still due.").
- [ ] Index rows 16 and 21 → `built (P1c)`; `docs/wbs_FE.md` FE-A6 evidence adds P1c; `python3 tools/docs/generate.py && python3 tools/docs/check.py` — Expected: 0 errors.
- [ ] Run `GUARD_PY=python3.13 bash .claude/skills/flutter-workflow/scripts/dod_check.sh` and `TZ=UTC flutter test --tags golden` — Expected: green.
- [ ] Commit — `docs(study): P1c records — D8 ruling, handoffs 16 and 21 (FE-A6)`.
