# Library Phase 4a: Card Editor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cards are added one after another and edited on their own screen, following the V3 kit's card editor (screens 08 and 09). "New card" is reachable from every deck that can hold cards.

**Architecture:**
- **Editor.** The card feature gains `CardEditorScreen` in create and edit modes, built from feature-local blocks: field, tag editor, footer, edit summary, and the gone state.
  - Validation is live, with `CardDraft`'s static rules, and Save stays disabled until the card is valid.
  - A dirty form asks before it is discarded.
  - Failures stay inside the form: a save failure is an inline banner, a refusing deck is a warning banner, and a gone card or deck is an empty state.
- **Deck screen.** It gains `onAddCard`. Its unset state shows the kit's two buttons (New card, New sub-deck), and its FAB follows the kit (New sub-deck for a deck that can nest, New card for a deck of cards). It hides the FAB while the card list selects.
- **Composition (D8).** The deck path over the editor is a deck-feature widget that `app/` passes in.
- **Scope split.** The card detail, its history, row tap → detail, and the edit route arrive in phase 4b.

**Tech Stack:** Flutter 3.47.5, Dart 3.13.4, Riverpod 3.4.3 codegen, go_router 18, Drift 2.35, gen-l10n (en/vi), intl.

**Spec:** `docs/superpowers/specs/2026-09-24-library-screens-design.md` (§4, §5, §6.1, §6.5, §9, §10 row 4).
- **Visual authority:** the MemoX Mobile UI Kit v3 (artifact `UCesgHkzYHKsZwhwVshKRE`):
  - 08 Card create: `FlashcardCreateScreenV3`;
  - 09 Card edit: `FlashcardEditScreenV3`;
  - 01 Deck list, unset state `deckEmpty`;
  - 07 Card list FAB.
- **Owner decision (2026-09-24, plan review):** adopt the kit's editor layout, failure handling, discard confirm and copy, and split phase 4 into 4a and 4b. Where the kit and spec §6.5 differ, the kit wins (rulings P4a-L1…L10).

## Global Constraints

- **UI only.** No file under `lib/features/*/domain`, `data`, `di` or `lib/core/database` changes (spec §12).
- **Import map:** `card → {deck, srs, tags}` (domain models, entities, failures and di), `deck → {srs}`. `app/` composes; `deck` never imports `card`, and `card` never imports `deck/presentation`.
- **One use case per interaction** (AD-12). Writes go through `CardActionsController`; the edit form reads `cardDetailProvider(cardId)`.
- **Guard memox-v8 at 0/0:**
  - no raw `IconButton`, `TextButton`, `ListTile`, `Card`, `Checkbox`, `BorderSide`, `RoundedRectangleBorder`, and no `Icon(color:)`;
  - no `ref.read` lexically in `build()`;
  - `build()` within `flutter.max_build_lines`: split into widgets, and build lists in data methods;
  - no defaulted provider or notifier parameter;
  - in the ARB, `placeholders` comes before `description`.
- **Copy:** `app_en.arb` (with `@key`) and `app_vi.arb`. Run `flutter gen-l10n` after ARB edits, and `build_runner` after `@riverpod` edits.
- **Tests** run through the real backend (`libraryTest`, `pumpLibraryScreen`, `pumpMemoxApp`). Goldens are 3x light and dark, with Latin or romanized text (the golden font has no Hangul).
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Rulings (phase 4a)

| # | Ruling |
|---|---|
| P4a-L1 | **Kit layout wins over spec §6.5.** The editor has:<br>• an app bar with Close (create) or Back (edit), the title and a compact Save (disabled until valid);<br>• the deck path and a destination line;<br>• a "Required" legend;<br>• "Front · Term" and "Back · Meaning" with counts;<br>• in create, the optional fields behind "Add details", and in edit, under "Optional details";<br>• "Tags · optional · n / 10" with an Add tag button;<br>• a footer with Cancel and "Save card" / "Save changes" over a caption line. |
| P4a-L2 | **Validation is live.** Length errors show as the person types. A blank front or back shows its message once that field has been touched. Save stays disabled while the card is invalid, and the use case checks again on save. |
| P4a-L3 | **Failures stay in the form.** A save failure shows the kit's inline danger banner, and Save becomes "Retry save". A deck that no longer takes cards shows a warning banner and keeps Save disabled. A refusal about one field shows under that field; any other refusal shows in a snackbar. |
| P4a-L4 | **Gone, not popped.** A card deleted while editing, or a deck deleted while adding, replaces the form with the kit's empty state ("… is no longer here", Back to deck). Nothing is written, and the person reads why. |
| P4a-L5 | **Discard confirm.** Leaving a changed form asks "Discard changes?" (edit) or "Discard this card?" (create), with Keep editing and Discard. A saved or untouched form leaves at once. |
| P4a-L6 | **Flag.** The kit's create screen carries no flag. In edit, the flag is an app bar toggle: the glyph changes and the node carries the toggled state. `Icon(color:)` is banned, so the glyph does not recolour. |
| P4a-L7 | **The deck path is a deck-feature widget**, `DeckContextHeaderWidget(deckId, currentLabel)`, passed in by `app/` (D8). It pins the breadcrumb and a destination line (tile and deck name) under the app bar. The kit's pill border is dropped, because `BorderSide` is banned. |
| P4a-L8 | **Tags.** Add tag is an outline chip button; the kit's dashed border has no design-system token. It opens an inline tag field, and Done adds the tag and keeps the field open. At 10 tags the button hides and a warning line explains. The removable chip's whole 48 area removes the tag. Only chips are saved. |
| P4a-L9 | **Unset deck, and the FAB.** An unset deck shows the kit's two buttons, New card and New sub-deck, with the note on what decides the deck's content; at the deepest level it shows New card only. The FAB is New sub-deck where a sub-deck fits, and New card on a deck of cards; it hides while cards are selected. |
| P4a-L10 | **Out of scope, though the kit shows them.** Move to Trash and Open Trash (Trash is deferred, `PRODUCT.md`), Import cards, and the card detail (phase 4b). The edit summary's "Details" link goes back (`maybePop`), because the detail is the page under the editor in 4b. |

## Review Focus

1. **Adding several cards in a row.**
   - Expected: each Save clears the form and focus returns to the front. A double tap adds one card, and the form is not dirty after a save.
   - Pinned in Task 3.
2. **Leaving a changed form with Back or Close.**
   - Expected: the discard dialog appears. Keep editing keeps every character; Discard leaves.
   - Pinned in Task 3.
3. **A card deleted while its editor is open.**
   - Expected: the gone state replaces the form and nothing is written.
   - Pinned in Task 3.
4. **A save that fails in the database.**
   - Expected: the inline banner appears, the typed content stays, and "Retry save" saves.
   - Pinned in Task 3.
5. **Hangul and Vietnamese at text scale 2.**
   - Expected: counts are in characters as people see them ("한국어" is 3), and nothing overflows.
   - Pinned in Tasks 2 and 3.

---

### Task 1: Editor plumbing: providers, create and edit commands, icons, copy

**Files:**
- Create in `lib/features/card/presentation/providers/`: `create_card_use_case_provider.dart`, `edit_card_use_case_provider.dart`, `watch_card_detail_use_case_provider.dart`, `card_detail_provider.dart`
- Modify:
  - `lib/features/card/presentation/controllers/card_actions_controller.dart`
  - `lib/core/theme/foundations/app_icons.dart`
  - `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
  - `test/support/library_harness.dart`
- Test: `test/features/card/presentation/card_actions_controller_test.dart` (extend)

**Interfaces:**
- Produces:
  - `cardDetailProvider(String cardId)`: `Stream<Outcome<CardDetail, CardRejection>>`.
  - `CardActionsController`:
    - `createCard({required String deckId, required CardDraft draft})` → `Future<Outcome<CardEntity, CardRejection>>`;
    - `editCard({required String cardId, required CardDraft draft})` → `Future<Outcome<void, CardRejection>>`.
  - Icons: `AppIcons.details`, `example`, `hint`, `pronunciation`, `clock`, `searchOff`.
  - `LibraryEnv.cards` (a real `CardRepository`).

- [ ] **Step 1: Write the failing tests**

In `test/support/library_harness.dart`, give `LibraryEnv` a real card repository. Import `CardRepositoryImpl`, `CardRepository`, `ScheduleRepositoryImpl` and `TagRepositoryImpl`:

```dart
final class LibraryEnv {
  LibraryEnv(this.db, this.clock)
    : decks = DeckRepositoryImpl(db),
      cards = CardRepositoryImpl(
        db,
        ScheduleRepositoryImpl(db),
        TagRepositoryImpl(db),
      );

  final AppDatabase db;
  final FakeDayClock clock;
  final DeckRepository decks;
  final CardRepository cards;
}
```

Append inside `main()` of `test/features/card/presentation/card_actions_controller_test.dart`. Import `card_draft_model.dart` and `card_failure.dart`:

```dart
  test('createCard saves the content, the flag and the tags', () async {
    final ids = await seed();
    final outcome = await actions().createCard(
      deckId: ids.words,
      draft: const CardDraft(
        front: 'bap',
        back: 'rice',
        isFlagged: true,
        tagNames: ['food'],
      ),
    );

    expect(outcome, isA<Ok<Object?, CardRejection>>());
    expect(await count('SELECT COUNT(*) AS n FROM card WHERE is_flagged'), 2);
    expect(await count('SELECT COUNT(*) AS n FROM card_tags'), 1);
  });

  test('editCard replaces the content and the tags', () async {
    await seed();
    await actions().editCard(
      cardId: 'a',
      draft: const CardDraft(front: 'new', back: 'back', tagNames: ['x', 'y']),
    );

    expect(
      await count("SELECT COUNT(*) AS n FROM card WHERE front = 'new'"),
      1,
    );
    expect(await count('SELECT COUNT(*) AS n FROM card_tags'), 2);
  });

  test('editCard is refused for a card that is gone', () async {
    await seed();
    await actions().deleteCards(cardIds: {'a'});
    final outcome = await actions().editCard(
      cardId: 'a',
      draft: const CardDraft(front: 'new', back: 'back'),
    );

    expect(
      outcome,
      isA<Rejected<Object?, CardRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        CardRejection.notFound,
      ),
    );
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/card/presentation/card_actions_controller_test.dart`
Expected: FAIL to compile, because `createCard` is not defined.

- [ ] **Step 3: Implement**

**Use-case providers**, one file each, shaped like phase 3's. Each has `import 'package:memox/features/card/di/card_repository_provider.dart';`, the use case import and `riverpod_annotation`:

| Provider file | Function | Body |
|---|---|---|
| `create_card_use_case_provider.dart` | `createCardUseCase` | `CreateCardUseCase(ref.watch(cardRepositoryProvider))` |
| `edit_card_use_case_provider.dart` | `editCardUseCase` | `EditCardUseCase(ref.watch(cardRepositoryProvider))` |
| `watch_card_detail_use_case_provider.dart` | `watchCardDetailUseCase` | `WatchCardDetailUseCase(ref.watch(cardRepositoryProvider))` |

`lib/features/card/presentation/providers/card_detail_provider.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/presentation/providers/watch_card_detail_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_detail_provider.g.dart';

/// A card as its editor (and, in 4b, its detail) reads it, again on every
/// change; `Rejected(notFound)` once it is gone (BR-CARD-019).
@riverpod
Stream<Outcome<CardDetail, CardRejection>> cardDetail(Ref ref, String cardId) =>
    ref.watch(watchCardDetailUseCaseProvider)(cardId: cardId);
```

**Controller.** In `card_actions_controller.dart`, add these after `deleteCards`. Import the two use-case providers, `card_entity.dart` and `card_draft_model.dart`:

```dart
  Future<Outcome<CardEntity, CardRejection>> createCard({
    required String deckId,
    required CardDraft draft,
  }) => ref.read(createCardUseCaseProvider)(deckId: deckId, draft: draft);

  Future<Outcome<void, CardRejection>> editCard({
    required String cardId,
    required CardDraft draft,
  }) => ref.read(editCardUseCaseProvider)(cardId: cardId, draft: draft);
```

**Icons.** In `app_icons.dart`, add after `selectAll`:

```dart
  static const IconData details = Icons.auto_awesome_outlined; // sparkles
  static const IconData example = Icons.chat_bubble_outline; // message-square
  static const IconData hint = Icons.lightbulb_outline; // lightbulb
  static const IconData pronunciation = Icons.text_fields; // type
  static const IconData clock = Icons.schedule; // clock
  static const IconData searchOff = Icons.search_off; // search-x
```

**Copy.** Run this script as in phases 2–3, then `flutter gen-l10n`. `UPDATE` rewrites existing strings to the kit's copy:

```python
import json
from pathlib import Path

INT = {"type": "int"}
STRING = {"type": "String"}

KEYS = {
    "cardAddTitle": ("New card", "Thẻ mới", "Card editor title in create mode, and its breadcrumb segment.", None),
    "cardEditTitle": ("Edit card", "Sửa thẻ", "Card editor title in edit mode.", None),
    "cardEditCrumb": ("Edit", "Sửa", "Breadcrumb segment of the card editor in edit mode.", None),
    "cardClose": ("Close", "Đóng", "Accessible name of the editor's close control.", None),
    "cardSave": ("Save", "Lưu", "Compact Save in the editor's app bar.", None),
    "cardSaveCard": ("Save card", "Lưu thẻ", "Footer save button in create mode.", None),
    "cardSaveChanges": ("Save changes", "Lưu thay đổi", "Footer save button in edit mode.", None),
    "cardRetrySave": ("Retry save", "Lưu lại", "Footer save button after a failed save.", None),
    "cardRequiredLegend": ("Required", "Bắt buộc", "Legend and marker for required card fields.", None),
    "cardFieldFront": ("Front · Term", "Mặt trước · Thuật ngữ", "Label of the card's front field.", None),
    "cardFieldBack": ("Back · Meaning", "Mặt sau · Nghĩa", "Label of the card's back field.", None),
    "cardFrontHint": ("The term you want to remember", "Thuật ngữ bạn muốn nhớ", "Hint in the front field.", None),
    "cardBackHint": ("The meaning; separate several with commas", "Nghĩa; nhiều nghĩa thì cách nhau bằng dấu phẩy", "Hint in the back field.", None),
    "cardAddDetails": ("Add details: example, hint, pronunciation", "Thêm chi tiết: ví dụ, gợi ý, phát âm", "Opens the optional fields in create mode.", None),
    "cardOptionalDetails": ("Optional details", "Chi tiết tuỳ chọn", "Overline above the optional fields in edit mode.", None),
    "cardOptional": ("optional", "tuỳ chọn", "Suffix after an optional field's label.", None),
    "cardFieldExample": ("Example sentence", "Câu ví dụ", "Label of the example field.", None),
    "cardFieldHint": ("Hint", "Gợi ý", "Label of the hint field.", None),
    "cardFieldPronunciation": ("Pronunciation", "Phát âm", "Label of the pronunciation field.", None),
    "cardExampleHint": ("A sentence using this term", "Một câu có dùng thuật ngữ này", "Hint in the example field.", None),
    "cardHintHint": ("A clue that jogs memory without giving the answer", "Gợi ý giúp nhớ ra mà không lộ đáp án", "Hint in the hint field.", None),
    "cardPronunciationHint": ("Romanisation or a note on how to say it", "Phiên âm hoặc ghi chú cách đọc", "Hint in the pronunciation field.", None),
    "cardFieldCount": ("{count} / {limit}", "{count} / {limit}", "A field's character count against its limit.", {"count": INT, "limit": INT}),
    "cardTags": ("Tags", "Nhãn", "Overline of the tag editor.", None),
    "cardTagsMeta": ("optional · {count} / {limit}", "tuỳ chọn · {count} / {limit}", "After the Tags overline: optional, and tags used against the limit.", {"count": INT, "limit": INT}),
    "cardAddTag": ("Add tag", "Thêm nhãn", "Opens the inline tag input.", None),
    "cardTagRemove": ("Remove {tag}", "Bỏ nhãn {tag}", "Accessible name of a removable tag chip.", {"tag": STRING}),
    "cardTagLimit": ("A card can carry 10 tags. Remove one to add another.", "Một thẻ có tối đa 10 nhãn. Bỏ bớt một nhãn để thêm nhãn khác.", "Warning at the tag limit.", None),
    "cardFlagLabel": ("Flag this card", "Gắn cờ thẻ này", "Accessible name of the edit app bar's flag toggle when off.", None),
    "cardFrontBlank": ("Add the term to remember.", "Hãy thêm thuật ngữ cần nhớ.", "Error under a touched, blank front.", None),
    "cardBackBlank": ("Add a meaning so this card can be answered.", "Hãy thêm nghĩa để thẻ có thể được trả lời.", "Error under a touched, blank back.", None),
    "cardFrontTooLong": ("The term can be at most 60 characters. Move the rest into the meaning or an example.", "Thuật ngữ tối đa 60 ký tự. Chuyển phần còn lại sang nghĩa hoặc ví dụ.", "Error under a front past 60 characters.", None),
    "cardBackTooLong": ("The meaning can be at most 240 characters.", "Nghĩa tối đa 240 ký tự.", "Error under a back past 240 characters.", None),
    "cardOptionalTooLong": ("Keep this to 240 characters.", "Tối đa 240 ký tự.", "Error under an optional field past 240 characters.", None),
    "cardCaptionRequired": ("Front and back are required to save.", "Cần mặt trước và mặt sau để lưu.", "Editor footer caption while front or back is blank.", None),
    "cardCaptionFix": ("Fix the marked field to enable save.", "Sửa ô được đánh dấu để lưu.", "Editor footer caption while a field is invalid.", None),
    "cardCaptionKeepAdding": ("You can keep adding cards after saving.", "Sau khi lưu, bạn có thể thêm thẻ tiếp.", "Create footer caption when the card is valid.", None),
    "cardCaptionSaving": ("Saving to this device…", "Đang lưu vào máy…", "Editor footer caption while saving.", None),
    "cardCaptionEdit": ("Editing content never changes the schedule or history.", "Sửa nội dung không làm đổi lịch ôn hay lịch sử.", "Edit footer caption when the card is valid.", None),
    "cardCaptionDeckRejects": ("This deck can't take cards now.", "Bộ thẻ này hiện không nhận thẻ.", "Create footer caption when the deck refuses cards.", None),
    "cardSaveFailedTitle": ("Couldn't save card.", "Không lưu được thẻ.", "Inline banner title after a failed save.", None),
    "cardSaveFailedBody": ("Nothing was lost. Tap Save to try again.", "Không mất gì cả. Bấm Lưu để thử lại.", "Inline banner body after a failed save.", None),
    "cardDeckRejectsTitle": ("This deck no longer accepts cards.", "Bộ thẻ này không còn nhận thẻ.", "Warning banner when the deck now holds sub-decks.", None),
    "cardDeckRejectsBody": ("It now holds sub-decks.", "Giờ nó chứa các bộ thẻ con.", "Warning banner body when the deck refuses cards.", None),
    "cardGoneTitle": ("This card is no longer here", "Thẻ này không còn nữa", "Editor state when the card was deleted meanwhile.", None),
    "cardGoneBody": ("It was deleted while you were editing. Your changes were not saved.", "Thẻ đã bị xoá trong lúc bạn sửa. Các thay đổi chưa được lưu.", "Body of the gone card state.", None),
    "cardDeckGoneTitle": ("This deck is no longer here", "Bộ thẻ này không còn nữa", "Editor state when the deck was deleted meanwhile.", None),
    "cardDeckGoneBody": ("It was deleted while you were adding cards. This card was not saved.", "Bộ thẻ đã bị xoá trong lúc bạn thêm thẻ. Thẻ này chưa được lưu.", "Body of the gone deck state.", None),
    "cardBackToDeck": ("Back to deck", "Về bộ thẻ", "Action of the gone states.", None),
    "cardDiscardTitle": ("Discard changes?", "Bỏ các thay đổi?", "Discard dialog title in edit mode.", None),
    "cardDiscardBody": ("Leaving now keeps the card as it was saved.", "Rời đi bây giờ thì thẻ giữ nguyên như lần lưu trước.", "Discard dialog body in edit mode.", None),
    "cardDiscardNewTitle": ("Discard this card?", "Bỏ thẻ này?", "Discard dialog title in create mode.", None),
    "cardDiscardNewBody": ("What you typed is not saved.", "Những gì bạn đã nhập sẽ không được lưu.", "Discard dialog body in create mode.", None),
    "cardKeepEditing": ("Keep editing", "Tiếp tục sửa", "Discard dialog: stay.", None),
    "cardDiscard": ("Discard", "Bỏ", "Discard dialog: leave without saving.", None),
    "cardSummaryAnswers": ("{count, plural, =1{1 answer} other{{count} answers}}", "{count} lượt trả lời", "Edit summary: answers so far.", {"count": INT}),
    "cardSummaryLapses": ("{count, plural, =1{1 lapse} other{{count} lapses}}", "{count} lần quên", "Edit summary: lapses so far.", {"count": INT}),
    "cardSummaryDue": ("due {date}", "đến hạn {date}", "Edit summary: the due date.", {"date": STRING}),
    "cardLoadErrorEditTitle": ("Couldn't load this card", "Không tải được thẻ này", "Error state title when the card to edit fails to load.", None),
    "cardAddedToast": ("Card added", "Đã thêm thẻ", "Snackbar after a card is created.", None),
    "cardNewCard": ("New card", "Thẻ mới", "Opens the card editor: the card list's FAB and its empty state action.", None),
    "deckNewCard": ("New card", "Thẻ mới", "Adds a card to the open deck (unset state and FAB).", None),
    "deckNewSubDeck": ("New sub-deck", "Bộ thẻ con mới", "Adds a sub-deck from the unset state.", None),
    "deckUnsetNote": ("The first card or sub-deck decides what this deck holds. Once it is empty again, both options come back.", "Thẻ hoặc bộ thẻ con đầu tiên quyết định bộ thẻ này chứa gì. Khi trống lại, cả hai lựa chọn sẽ quay lại.", "Note under the unset deck's buttons.", None),
}

UPDATE = {
    "deckUnsetTitle": ("What goes in here?", "Bộ thẻ này chứa gì?"),
    "deckUnsetBody": ("Add cards to study them here, or nest sub-decks to organise further. A deck holds one or the other.", "Thêm thẻ để học ngay tại đây, hoặc lồng bộ thẻ con để sắp xếp thêm. Mỗi bộ thẻ chỉ chứa một trong hai."),
    "deckUnsetDeepestBody": ("This deck is at the deepest level, so it holds cards.", "Bộ thẻ này đã ở cấp sâu nhất nên chỉ chứa thẻ."),
}

for path, is_template in (("lib/l10n/app_en.arb", True), ("lib/l10n/app_vi.arb", False)):
    file = Path(path)
    data = json.loads(file.read_text(encoding="utf-8"))
    for key, (en, vi, description, placeholders) in KEYS.items():
        assert key not in data, key
        data[key] = en if is_template else vi
        if is_template:
            meta = {}
            if placeholders:
                meta["placeholders"] = placeholders
            meta["description"] = description
            data["@" + key] = meta
    for key, (en, vi) in UPDATE.items():
        assert key in data, key
        data[key] = en if is_template else vi
    file.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
```

- [ ] **Step 4: Generate and run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/features/card/presentation test/features/deck/presentation
```

Expected: PASS, with 3 new controller tests. The deck tests read the updated unset copy through `_en`.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(card): editor plumbing: create and edit commands, detail stream, icons, kit copy

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Editor building blocks and the deck context header

**Files:**
- Create in `lib/features/card/presentation/widgets/`:
  - `sections/card_field_widget.dart`, `sections/card_tag_editor_widget.dart`, `sections/card_editor_footer_widget.dart`, `sections/card_edit_summary_widget.dart`, `sections/card_gone_widget.dart`
  - `items/card_removable_tag_chip_widget.dart`
  - `overlays/card_discard_dialog_widget.dart`
- Create: `lib/features/deck/presentation/widgets/sections/deck_context_header_widget.dart`
- Test: `test/features/card/presentation/card_editor_blocks_test.dart`

**Interfaces:**
- Consumes (Task 1): copy keys and icons.
- Produces:
  - `CardFieldWidget({required String label, required String hint, required int limit, required TextEditingController controller, IconData? icon, bool isRequired, bool isMultiline, FocusNode? focusNode, String? errorText, ValueChanged<String>? onChanged})`.
  - `CardTagEditorWidget({required List<String> tags, required ValueChanged<List<String>> onChanged})`.
  - `CardEditorFooterWidget({required String caption, required String saveLabel, required bool hasFailed, required bool isSaving, required VoidCallback onCancel, required VoidCallback? onSave})`.
  - `CardEditSummaryWidget({required CardDetail detail, required VoidCallback onOpenDetails})`.
  - `CardGoneWidget({required String title, required String body, required VoidCallback onBack})`.
  - `showCardDiscardDialog(BuildContext, {required bool isNew})` → `Future<bool>`.
  - `DeckContextHeaderWidget({required String deckId, required String currentLabel})`.

- [ ] **Step 1: Write the failing tests**

`test/features/card/presentation/card_editor_blocks_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_discard_dialog_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_footer_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_field_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_tag_editor_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _host(Widget child) =>
    Scaffold(body: SingleChildScrollView(child: child));

/// A tag editor that keeps its own list, as the form does.
class _Tags extends StatefulWidget {
  const _Tags();

  @override
  State<_Tags> createState() => _TagsState();
}

class _TagsState extends State<_Tags> {
  var tags = <String>[];

  @override
  Widget build(BuildContext context) => CardTagEditorWidget(
    tags: tags,
    onChanged: (next) => setState(() => tags = next),
  );
}

void main() {
  libraryTest('a field counts characters as people see them (RF5)', (
    tester,
    env,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        CardFieldWidget(
          label: _en.cardFieldFront,
          hint: _en.cardFrontHint,
          limit: 60,
          controller: controller,
          isRequired: true,
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), '한국어');
    await tester.pump();

    expect(find.text(_en.cardFieldCount(3, 60)), findsOneWidget);
    expect(find.text(_en.cardRequiredLegend), findsOneWidget);
  });

  libraryTest('an optional field shows its count once typed', (
    tester,
    env,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpLibraryScreen(
      tester,
      env,
      _host(
        CardFieldWidget(
          label: _en.cardFieldHint,
          hint: _en.cardHintHint,
          limit: 240,
          controller: controller,
        ),
      ),
    );
    expect(find.text(_en.cardFieldCount(0, 240)), findsNothing);

    await tester.enterText(find.byType(EditableText), 'Việt');
    await tester.pump();
    expect(find.text(_en.cardFieldCount(4, 240)), findsOneWidget);
  });

  libraryTest('tags: Add tag opens the input, duplicates fold, ten is the limit', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _host(const _Tags()));
    Future<void> add(String name) async {
      await tester.enterText(find.byType(EditableText), name);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }

    expect(find.byType(EditableText), findsNothing);
    await tester.tap(find.text(_en.cardAddTag));
    await tester.pump();
    await add('Verb');
    await add('verb');
    expect(find.bySemanticsLabel(_en.cardTagRemove('Verb')), findsOneWidget);
    expect(find.text(_en.cardTagsMeta(1, 10)), findsOneWidget);

    for (var i = 0; i < 9; i++) {
      await add('tag $i');
    }
    expect(find.text(_en.cardTagLimit), findsOneWidget);
    expect(find.text(_en.cardAddTag), findsNothing);

    await tester.tap(find.bySemanticsLabel(_en.cardTagRemove('Verb')));
    await tester.pump();
    expect(find.text(_en.cardTagLimit), findsNothing);
  });

  libraryTest('the footer turns a failure into an inline banner and a retry', (
    tester,
    env,
  ) async {
    var saves = 0;
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        bottomNavigationBar: CardEditorFooterWidget(
          caption: _en.cardCaptionKeepAdding,
          saveLabel: _en.cardSaveCard,
          hasFailed: true,
          isSaving: false,
          onCancel: () {},
          onSave: () => saves++,
        ),
      ),
    );

    expect(find.byType(MxInlineBanner), findsOneWidget);
    expect(find.text(_en.cardSaveFailedTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(MxButton, _en.cardRetrySave));
    expect(saves, 1);
  });

  libraryTest('the discard dialog answers Discard or Keep editing', (
    tester,
    env,
  ) async {
    final answers = <bool>[];
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: Builder(
          builder: (context) => MxButton(
            label: 'Leave',
            onPressed: () async =>
                answers.add(await showCardDiscardDialog(context, isNew: true)),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.text(_en.cardDiscardNewTitle), findsOneWidget);
    await tester.tap(find.text(_en.cardKeepEditing));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.cardDiscard));
    await tester.pumpAndSettle();

    expect(answers, [false, true]);
  });

  libraryTest('the deck context names the path and the destination', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: DeckContextHeaderWidget(
          deckId: words.id,
          currentLabel: _en.cardAddTitle,
        ),
      ),
    );

    for (final crumb in [_en.navLibrary, 'Korean', 'Words', _en.cardAddTitle]) {
      expect(
        find.descendant(
          of: find.byType(MxBreadcrumb),
          matching: find.text(crumb),
        ),
        findsOneWidget,
      );
    }
    expect(find.text('Words'), findsNWidgets(2));
  });

  libraryTest('tags and fields hold at 2x and meet the guidelines', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _host(const _Tags()),
      textScale: 2,
    );
    await tester.tap(find.text(_en.cardAddTag));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'từ vựng tiếng Hàn');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/card/presentation/card_editor_blocks_test.dart`
Expected: FAIL to compile, because the block files do not exist.

- [ ] **Step 3: Implement**

`lib/features/card/presentation/widgets/sections/card_field_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// One card field (kit 08/09): the overline label, "Required" or
/// "· optional", the count against the limit, then the input. A required
/// field always shows its count; an optional one shows it once typed.
class CardFieldWidget extends StatelessWidget {
  const CardFieldWidget({
    super.key,
    required this.label,
    required this.hint,
    required this.limit,
    required this.controller,
    this.icon,
    this.isRequired = false,
    this.isMultiline = false,
    this.focusNode,
    this.errorText,
    this.onChanged,
  });

  final String label;
  final String hint;

  /// In characters as a person sees them (BR-CARD-002, BR-CARD-003).
  final int limit;
  final TextEditingController controller;

  /// The optional fields' glyph (kit `OptionalField`).
  final IconData? icon;
  final bool isRequired;
  final bool isMultiline;
  final FocusNode? focusNode;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.micro,
      children: [
        _FieldHeader(
          label: label,
          icon: icon,
          isRequired: isRequired,
          controller: controller,
          limit: limit,
        ),
        MxTextField(
          controller: controller,
          focusNode: focusNode,
          hintText: hint,
          errorText: errorText,
          isMultiline: isMultiline,
          textInputAction: isMultiline
              ? TextInputAction.newline
              : TextInputAction.next,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _FieldHeader extends StatelessWidget {
  const _FieldHeader({
    required this.label,
    required this.icon,
    required this.isRequired,
    required this.controller,
    required this.limit,
  });

  final String label;
  final IconData? icon;
  final bool isRequired;
  final TextEditingController controller;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final colors = context.colors;
    final icon = this.icon;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.micro),
      child: Row(
        spacing: AppSpacing.micro,
        children: [
          if (icon != null) Icon(icon, size: AppIconSize.inline),
          Flexible(
            child: Text(
              label.toUpperCase(),
              semanticsLabel: label,
              style: styles.overline,
            ),
          ),
          if (isRequired)
            Text(
              l10n.cardRequiredLegend,
              style: styles.overline.copyWith(color: colors.primary),
            )
          else
            Text('· ${l10n.cardOptional}', style: styles.rowDescription),
          const Spacer(),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final count = value.text.characters.length;
              if (!isRequired && count == 0) return const SizedBox.shrink();
              return Text(
                l10n.cardFieldCount(count, limit),
                style: count > limit
                    ? styles.counter.copyWith(color: colors.error)
                    : styles.counter,
              );
            },
          ),
        ],
      ),
    );
  }
}
```

`lib/features/card/presentation/widgets/items/card_removable_tag_chip_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';

/// A tag on the card being edited (kit `RemovableTagChip`): a primary-tinted
/// pill with an ✕. Its whole 48 area removes the tag (ruling P4a-L8); the
/// read-only `MxTagChip` is a different control.
class CardRemovableTagChipWidget extends StatelessWidget {
  const CardRemovableTagChipWidget({
    super.key,
    required this.name,
    required this.onRemove,
  });

  final String name;
  final VoidCallback onRemove;

  static const double _tint = 0.10;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: context.l10n.cardTagRemove(name),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onRemove,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.touchTarget),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: _tint),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSize.chip),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.grouped,
                    end: AppSpacing.control,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      color: colors.primary,
                      size: AppIconSize.inline,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: AppSpacing.micro,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.tagLabel.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        ),
                        const Icon(AppIcons.close),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

`lib/features/card/presentation/widgets/sections/card_tag_editor_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/widgets/items/card_removable_tag_chip_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The card's tags (kit 08/09): "Tags · optional · n / 10", removable chips,
/// and Add tag, which opens an inline input. Done adds the tag and keeps the
/// input open for the next one; an empty Done closes it. A name already
/// there, however spelled, adds nothing (BR-TAG-001). At the limit the
/// button gives way to a warning (ruling P4a-L8).
class CardTagEditorWidget extends StatefulWidget {
  const CardTagEditorWidget({
    super.key,
    required this.tags,
    required this.onChanged,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  @override
  State<CardTagEditorWidget> createState() => _CardTagEditorWidgetState();
}

class _CardTagEditorWidgetState extends State<CardTagEditorWidget> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  var _isAdding = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _open() {
    setState(() => _isAdding = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _add(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _isAdding = false;
        _error = null;
      });
      return;
    }
    final folded = TagEntity.fold(trimmed);
    if (widget.tags.any((tag) => TagEntity.fold(tag) == folded)) {
      _input.clear();
      _focus.requestFocus();
      return;
    }
    final next = [...widget.tags, trimmed];
    if (CardDraft.checkTagNames(next) case Rejected(:final reason)) {
      setState(() => _error = context.l10n.cardRejection(reason));
      return;
    }
    setState(() => _error = null);
    _input.clear();
    widget.onChanged(next);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final isFull = widget.tags.length >= TagEntity.maxPerCard;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.control,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.micro),
            child: Row(
              spacing: AppSpacing.micro,
              children: [
                const Icon(AppIcons.tag, size: AppIconSize.inline),
                Text(
                  l10n.cardTags.toUpperCase(),
                  semanticsLabel: l10n.cardTags,
                  style: styles.overline,
                ),
                Flexible(
                  child: Text(
                    l10n.cardTagsMeta(widget.tags.length, TagEntity.maxPerCard),
                    style: styles.rowDescription,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: AppSpacing.micro,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final tag in widget.tags)
                CardRemovableTagChipWidget(
                  name: tag,
                  onRemove: () =>
                      widget.onChanged([...widget.tags]..remove(tag)),
                ),
              if (!isFull && !_isAdding)
                MxButton(
                  label: l10n.cardAddTag,
                  icon: AppIcons.add,
                  size: MxButtonSize.chip,
                  tone: MxButtonTone.outline,
                  onPressed: _open,
                ),
            ],
          ),
          if (_isAdding && !isFull)
            MxTextField(
              controller: _input,
              focusNode: _focus,
              hintText: l10n.cardTagHint,
              errorText: _error,
              textInputAction: TextInputAction.done,
              onSubmitted: _add,
            ),
          if (isFull)
            MxFieldMessage(
              message: l10n.cardTagLimit,
              tone: MxFieldMessageTone.warning,
            ),
        ],
      ),
    );
  }
}
```

`lib/features/card/presentation/widgets/sections/card_editor_footer_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

/// The editor's save bar (kit 08/09): an inline banner after a failed save,
/// Cancel and the save button, and the caption line (ruling P4a-L3).
class CardEditorFooterWidget extends StatelessWidget {
  const CardEditorFooterWidget({
    super.key,
    required this.caption,
    required this.saveLabel,
    required this.hasFailed,
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });

  final String caption;
  final String saveLabel;
  final bool hasFailed;
  final bool isSaving;
  final VoidCallback onCancel;

  /// Null while the card is not valid.
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxFooterBar(
      caption: caption,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.control,
        children: [
          if (hasFailed)
            MxInlineBanner(
              tone: MxBannerTone.danger,
              title: l10n.cardSaveFailedTitle,
              message: l10n.cardSaveFailedBody,
              isInCommitBar: true,
            ),
          Row(
            spacing: AppSpacing.control,
            children: [
              MxButton(
                label: l10n.commonCancel,
                tone: MxButtonTone.outline,
                onPressed: onCancel,
              ),
              Expanded(
                child: MxButton(
                  label: hasFailed ? l10n.cardRetrySave : saveLabel,
                  icon: hasFailed ? AppIcons.retry : AppIcons.check,
                  isBlock: true,
                  isLoading: isSaving,
                  onPressed: onSave,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

`lib/features/card/presentation/widgets/sections/card_edit_summary_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// Between parts of the summary line.
const String _separator = ' · ';

/// Where the edited card stands (kit 09's history strip): status, answers,
/// lapses and the due date. It leads to the detail (ruling P4a-L10).
class CardEditSummaryWidget extends StatelessWidget {
  const CardEditSummaryWidget({
    super.key,
    required this.detail,
    required this.onOpenDetails,
  });

  final CardDetail detail;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final schedule = detail.schedule;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final parts = [
      l10n.cardStatus(detail.displayStatus),
      l10n.cardSummaryAnswers(schedule.answerCount),
      l10n.cardSummaryLapses(schedule.lapseCount),
      if (schedule.dueAt case final dueAt?)
        l10n.cardSummaryDue(DateFormat.MMMd(locale).format(dueAt.toLocal())),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: MxCard(
        isFullBleed: true,
        child: MxListRow(
          title: parts.join(_separator),
          leading: const MxIconTile(icon: AppIcons.clock),
          hasChevron: true,
          onTap: onOpenDetails,
          hasDivider: false,
        ),
      ),
    );
  }
}
```

`lib/features/card/presentation/widgets/sections/card_gone_widget.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// The editor once its card or deck is gone (ruling P4a-L4): it says why and
/// that nothing was saved, and leads back to the deck.
class CardGoneWidget extends StatelessWidget {
  const CardGoneWidget({
    super.key,
    required this.title,
    required this.body,
    required this.onBack,
  });

  final String title;
  final String body;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => MxScreenScroll(
    children: [
      const SizedBox(height: AppSpacing.gutter),
      MxEmptyState(
        icon: AppIcons.searchOff,
        title: title,
        body: body,
        tone: MxEmptyStateTone.neutral,
        actionLabel: context.l10n.cardBackToDeck,
        onAction: onBack,
      ),
    ],
  );
}
```

`lib/features/card/presentation/widgets/overlays/card_discard_dialog_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Asks before a changed form is left (ruling P4a-L5). Completes true to
/// discard, false to keep editing.
Future<bool> showCardDiscardDialog(
  BuildContext context, {
  required bool isNew,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => CardDiscardDialogWidget(isNew: isNew),
    ) ??
    false;

class CardDiscardDialogWidget extends StatelessWidget {
  const CardDiscardDialogWidget({super.key, required this.isNew});

  /// A card not saved yet, rather than changes to a saved one.
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      width: MxDialogWidth.medium,
      title: isNew ? l10n.cardDiscardNewTitle : l10n.cardDiscardTitle,
      body: isNew ? l10n.cardDiscardNewBody : l10n.cardDiscardBody,
      actions: MxSheetActions(
        cancelLabel: l10n.cardKeepEditing,
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: l10n.cardDiscard,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }
}
```

`lib/features/deck/presentation/widgets/sections/deck_context_header_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/presentation/providers/deck_view_provider.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

/// Where a card operation writes (kit 08/09): the deck's path ending in the
/// operation, and a line naming the destination deck. It is not a picker.
/// `app/` passes it to the card editor (ruling P4a-L7, spec D8).
class DeckContextHeaderWidget extends ConsumerWidget {
  const DeckContextHeaderWidget({
    super.key,
    required this.deckId,
    required this.currentLabel,
  });

  final String deckId;

  /// The operation's segment: "New card", "Edit".
  final String currentLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(
    deckViewProvider(deckId),
  )) {
    AsyncData(value: Ok(:final value)) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxBreadcrumb(
          segments: [
            MxBreadcrumbSegment(label: context.l10n.navLibrary),
            for (final entry in value.breadcrumb)
              MxBreadcrumbSegment(label: entry.name),
            MxBreadcrumbSegment(label: value.deck.name),
            MxBreadcrumbSegment(label: currentLabel),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            0,
            AppSpacing.gutter,
            AppSpacing.control,
          ),
          child: Row(
            spacing: AppSpacing.control,
            children: [
              const MxIconTile(icon: AppIcons.library),
              Flexible(
                child: Text(
                  value.deck.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.settingsLabel,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    _ => const SizedBox.shrink(),
  };
}
```

- [ ] **Step 4: Run the tests**

```bash
flutter test test/features/card/presentation/card_editor_blocks_test.dart
```

Expected: PASS, 7 tests.

- If `find.bySemanticsLabel` does not reach the chip's label under `excludeSemantics`, find the chip by `find.widgetWithText(CardRemovableTagChipWidget, 'Verb')` and record a test-only ruling.
- If `context.textStyles.tagLabel` or `overline` has another name in `mx_text_styles.dart`, use the name `MxTagChip` and `MxListSectionHeader` use, and record a ruling.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(card): editor building blocks and the deck context header

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: The card editor screen, create and edit

**Files:**
- Create: `lib/features/card/presentation/screens/card_editor_screen.dart`, `lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart`
- Test: `test/features/card/presentation/card_editor_screen_test.dart`

**Interfaces:**
- Consumes:
  - Task 1: `createCard` / `editCard`, `cardDetailProvider`.
  - Task 2: the building blocks and `DeckContextHeaderWidget` (tests only).
- Produces:
  - `CardEditorScreen.create({required String deckId, required Widget Function(String deckId, String currentLabel) deckContext})`.
  - `CardEditorScreen.edit({required String cardId, required Widget Function(String deckId, String currentLabel) deckContext})`.

- [ ] **Step 1: Write the failing tests**

`test/features/card/presentation/card_editor_screen_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/create_card_use_case.dart';
import 'package:memox/features/card/presentation/providers/create_card_use_case_provider.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/card_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

CardEditorScreen _create(String deckId) =>
    CardEditorScreen.create(deckId: deckId, deckContext: _context);

CardEditorScreen _edit(String cardId) =>
    CardEditorScreen.edit(cardId: cardId, deckContext: _context);

/// Front, back, then the tag input once opened; the optional fields sit
/// between them once "Add details" is open.
Finder _field(int index) => find.byType(EditableText).at(index);

Finder _footerSave(String label) => find.widgetWithText(MxButton, label);

Future<String> _words(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  return (await env.decks.sub(korean.id, 'Words')).id;
}

Future<int> _count(LibraryEnv env, String sql, [List<String> args = const []]) async =>
    (await env.db
            .customSelect(
              sql,
              variables: [for (final arg in args) Variable<String>(arg)],
            )
            .getSingle())
        .read<int>('n');

bool _isEnabled(WidgetTester tester, String label) =>
    tester.widget<MxButton>(_footerSave(label)).onPressed != null;

/// Cards whose create fails the first way a real database can.
final class _FailingCards implements CardRepository {
  @override
  Future<Outcome<CardEntity, CardRejection>> createCard({
    required String deckId,
    required CardDraft draft,
    DateTime? now,
  }) => Future.error(const UnknownDatabaseFailure(cause: '/data/memox.sqlite'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  libraryTest('Save waits for a front and a back', (tester, env) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));

    expect(_isEnabled(tester, _en.cardSaveCard), isFalse);
    expect(find.text(_en.cardCaptionRequired), findsOneWidget);
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    await tester.pump();

    expect(_isEnabled(tester, _en.cardSaveCard), isTrue);
    expect(find.text(_en.cardCaptionKeepAdding), findsOneWidget);
  });

  libraryTest('Save adds the card, clears the form and refocuses (RF1)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    await tester.tap(find.text(_en.cardAddTag));
    await tester.pump();
    await tester.enterText(_field(2), 'food');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveCard));
    await tester.pumpAndSettle();

    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card'), 1);
    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card_tags'), 1);
    expect(find.text(_en.cardAddedToast), findsOneWidget);
    expect(find.text('bap'), findsNothing);
    expect(tester.widget<EditableText>(_field(0)).focusNode.hasFocus, isTrue);

    // Saved, so leaving asks nothing.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(_en.cardDiscardNewTitle), findsNothing);
  });

  libraryTest('a double tap on Save adds one card', (tester, env) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveCard));
    await tester.tap(_footerSave(_en.cardSaveCard), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card'), 1);
  });

  libraryTest('errors show as the person types (ruling P4a-L2)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(1), 'x');
    await tester.enterText(_field(1), '');
    await tester.enterText(_field(0), 'a' * (CardDraft.maxFrontLength + 1));
    await tester.pump();

    expect(find.text(_en.cardBackBlank), findsOneWidget);
    expect(find.text(_en.cardFrontTooLong), findsOneWidget);
    expect(find.text(_en.cardCaptionFix), findsOneWidget);
    expect(_isEnabled(tester, _en.cardSaveCard), isFalse);
  });

  libraryTest('Add details opens the optional fields', (tester, env) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    expect(find.text(_en.cardExampleHint), findsNothing);

    await tester.tap(find.text(_en.cardAddDetails));
    await tester.pump();
    for (final hint in [
      _en.cardExampleHint,
      _en.cardHintHint,
      _en.cardPronunciationHint,
    ]) {
      expect(find.text(hint), findsOneWidget);
    }
  });

  libraryTest('Back on a changed form asks; Keep editing keeps it (RF2)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await tester.enterText(_field(0), 'bap');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text(_en.cardDiscardNewTitle), findsOneWidget);
    await tester.tap(find.text(_en.cardKeepEditing));
    await tester.pumpAndSettle();
    expect(find.text('bap'), findsOneWidget);
  });

  libraryTest('a failed save keeps the form and offers Retry save (RF4)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(
      tester,
      env,
      _create(deckId),
      overrides: [
        createCardUseCaseProvider.overrideWithValue(
          CreateCardUseCase(_FailingCards()),
        ),
      ],
    );
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveCard));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardSaveFailedTitle), findsOneWidget);
    expect(_footerSave(_en.cardRetrySave), findsOneWidget);
    expect(find.text('bap'), findsOneWidget);
    expect(find.textContaining('sqlite'), findsNothing);
  });

  libraryTest('a deck that now holds decks refuses with a warning banner', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId));
    await env.decks.sub(deckId, 'Verbs');
    await tester.enterText(_field(0), 'bap');
    await tester.enterText(_field(1), 'rice');
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveCard));
    await tester.pumpAndSettle();

    expect(find.text(_en.cardDeckRejectsTitle), findsOneWidget);
    expect(_isEnabled(tester, _en.cardSaveCard), isFalse);
    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card'), 0);
  });

  libraryTest('edit starts from the card, flags in the app bar, saves', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    final card = await env.cards.card(
      deckId,
      const CardDraft(front: 'bap', back: 'rice', tagNames: ['food']),
    );
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();

    expect(find.text('bap'), findsOneWidget);
    expect(find.bySemanticsLabel(_en.cardTagRemove('food')), findsOneWidget);
    expect(find.textContaining(_en.cardSummaryAnswers(0)), findsOneWidget);
    await tester.tap(find.byTooltip(_en.cardFlagLabel));
    await tester.enterText(_field(1), 'cooked rice');
    await tester.pump();
    await tester.tap(_footerSave(_en.cardSaveChanges));
    await tester.pumpAndSettle();

    expect(
      await _count(
        env,
        'SELECT COUNT(*) AS n FROM card WHERE back = ? AND is_flagged',
        ['cooked rice'],
      ),
      1,
    );
  });

  libraryTest('a card deleted while editing shows it is gone (RF3)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    final card = await env.cards.card(deckId);
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    await tester.enterText(_field(1), 'changed');
    await env.cards.deleteCards(cardIds: {card.id});
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.cardGoneTitle), findsOneWidget);
    expect(find.text(_en.cardBackToDeck), findsOneWidget);
    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card'), 0);
  });

  libraryTest('the editor holds Hangul at 2x and meets the guidelines (RF5)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    await pumpLibraryScreen(tester, env, _create(deckId), textScale: 2);
    await tester.enterText(_field(0), List.filled(4, '한국어 단어').join(' '));
    await tester.pump();

    expect(find.text(_en.cardFieldCount(27, 60)), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
```

("한국어 단어" is 6 characters as people see them; four of them with three spaces make 27.)

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/card/presentation/card_editor_screen_test.dart`
Expected: FAIL to compile, because `card_editor_screen.dart` does not exist.

- [ ] **Step 3: Implement**

`lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_discard_dialog_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_edit_summary_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_footer_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_field_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_gone_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_tag_editor_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

enum _Field { front, back, example, hint, pronunciation }

/// The card editor's form (kit 08/09), in create mode for [deckId] or in
/// edit mode for [detail]'s card. Validation is live; Save waits for a valid
/// card; a changed form asks before it is left (rulings P4a-L1…L6).
class CardEditorFormWidget extends ConsumerStatefulWidget {
  const CardEditorFormWidget({
    super.key,
    required this.deckId,
    required this.deckContext,
    this.detail,
  });

  /// The deck the card is written to.
  final String deckId;
  final Widget Function(String deckId, String currentLabel) deckContext;

  /// The card to edit; null creates.
  final CardDetail? detail;

  @override
  ConsumerState<CardEditorFormWidget> createState() =>
      _CardEditorFormWidgetState();
}

class _CardEditorFormWidgetState extends ConsumerState<CardEditorFormWidget> {
  late final _card = widget.detail?.card;
  late final _front = TextEditingController(text: _card?.front);
  late final _back = TextEditingController(text: _card?.back);
  late final _example = TextEditingController(text: _card?.example);
  late final _hint = TextEditingController(text: _card?.hint);
  late final _pronunciation = TextEditingController(text: _card?.pronunciation);
  final _frontFocus = FocusNode();
  late var _tags = [for (final tag in widget.detail?.tags ?? const []) tag.name];
  late var _isFlagged = _card?.isFlagged ?? false;
  late var _isDetailsOpen = !_isCreating;
  late var _saved = _draft();
  final _touched = <_Field>{};
  var _isSaving = false;
  var _hasFailed = false;
  var _deckRejects = false;
  var _isGone = false;
  var _isLeaving = false;

  bool get _isCreating => widget.detail == null;

  List<TextEditingController> get _controllers => [
    _front,
    _back,
    _example,
    _hint,
    _pronunciation,
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _frontFocus.dispose();
    super.dispose();
  }

  static String? _optional(TextEditingController controller) =>
      controller.text.trim().isEmpty ? null : controller.text;

  CardDraft _draft() => CardDraft(
    front: _front.text,
    back: _back.text,
    example: _optional(_example),
    hint: _optional(_hint),
    pronunciation: _optional(_pronunciation),
    isFlagged: _isFlagged,
    tagNames: _tags,
  );

  bool get _isDirty {
    final draft = _draft();
    return draft.front != _saved.front ||
        draft.back != _saved.back ||
        draft.example != _saved.example ||
        draft.hint != _saved.hint ||
        draft.pronunciation != _saved.pronunciation ||
        draft.isFlagged != _saved.isFlagged ||
        !listEquals(draft.tagNames, _saved.tagNames);
  }

  /// Ruling P4a-L2: a blank side speaks once touched; a long one at once.
  String? _sideError(
    _Field field,
    Outcome<void, CardRejection> rule,
    String blank,
    String tooLong,
  ) => switch (rule) {
    Ok() => null,
    Rejected(reason: CardRejection.blankContent) =>
      _touched.contains(field) ? blank : null,
    Rejected() => tooLong,
  };

  Map<_Field, String?> _errors(AppLocalizations l10n) {
    String? optional(TextEditingController controller) =>
        switch (CardDraft.checkOptional(controller.text)) {
          Ok() => null,
          Rejected() => l10n.cardOptionalTooLong,
        };
    return {
      _Field.front: _sideError(
        _Field.front,
        CardDraft.checkFront(_front.text),
        l10n.cardFrontBlank,
        l10n.cardFrontTooLong,
      ),
      _Field.back: _sideError(
        _Field.back,
        CardDraft.checkBack(_back.text),
        l10n.cardBackBlank,
        l10n.cardBackTooLong,
      ),
      _Field.example: optional(_example),
      _Field.hint: optional(_hint),
      _Field.pronunciation: optional(_pronunciation),
    };
  }

  String _caption(AppLocalizations l10n, Map<_Field, String?> errors) {
    if (_isSaving) return l10n.cardCaptionSaving;
    if (_deckRejects) return l10n.cardCaptionDeckRejects;
    if (errors.values.any((error) => error != null)) return l10n.cardCaptionFix;
    if (_front.text.trim().isEmpty || _back.text.trim().isEmpty) {
      return l10n.cardCaptionRequired;
    }
    return _isCreating ? l10n.cardCaptionKeepAdding : l10n.cardCaptionEdit;
  }

  VoidCallback? get _onSave => _draft().check() is Ok && !_isSaving && !_deckRejects
      ? () => unawaited(_save())
      : null;

  void _touch(_Field field) => setState(() => _touched.add(field));

  Future<void> _save() async {
    if (_isSaving) return;
    final draft = _draft();
    setState(() {
      _isSaving = true;
      _hasFailed = false;
    });
    final actions = ref.read(cardActionsControllerProvider.notifier);
    try {
      final Outcome<Object?, CardRejection> outcome = _isCreating
          ? await actions.createCard(deckId: widget.deckId, draft: draft)
          : await actions.editCard(cardId: _card!.id, draft: draft);
      if (!mounted) return;
      _afterSave(outcome, draft);
    } on Failure {
      // Ruling P4a-L3: said in the form, with the typed content kept.
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _hasFailed = true;
      });
    }
  }

  void _afterSave(Outcome<Object?, CardRejection> outcome, CardDraft draft) {
    final l10n = context.l10n;
    switch (outcome) {
      case Ok() when _isCreating:
        _clearForNext();
        showMxSnackbar(context, message: l10n.cardAddedToast);
      case Ok():
        _saved = draft;
        _leave();
      case Rejected(reason: CardRejection.notACardContainer):
        setState(() {
          _isSaving = false;
          _deckRejects = true;
        });
      case Rejected(reason: CardRejection.notFound):
        setState(() => _isGone = true);
      case Rejected(:final reason):
        setState(() => _isSaving = false);
        showMxSnackbar(context, message: l10n.cardRejection(reason));
    }
  }

  /// UC-CARD-001 A4: the next card starts from an empty form.
  void _clearForNext() {
    for (final controller in _controllers) {
      controller.clear();
    }
    setState(() {
      _tags = [];
      _isFlagged = false;
      _touched.clear();
      _isSaving = false;
      _saved = _draft();
    });
    _frontFocus.requestFocus();
  }

  /// Leaves once the frame shows the form as leaving, so the guard lets go.
  void _leave() {
    setState(() => _isLeaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(Navigator.of(context).maybePop());
    });
  }

  Future<void> _confirmLeave() async {
    final discard = await showCardDiscardDialog(context, isNew: _isCreating);
    if (discard && mounted) _leave();
  }

  void _back() => unawaited(Navigator.of(context).maybePop());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final errors = _errors(l10n);
    return PopScope(
      canPop: _isLeaving || _isGone || !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmLeave());
      },
      child: MxAppShell(
        appBar: _appBar(l10n),
        footer: _isGone
            ? null
            : CardEditorFooterWidget(
                caption: _caption(l10n, errors),
                saveLabel: _isCreating ? l10n.cardSaveCard : l10n.cardSaveChanges,
                hasFailed: _hasFailed,
                isSaving: _isSaving,
                onCancel: _back,
                onSave: _onSave,
              ),
        body: _isGone
            ? CardGoneWidget(
                title: _isCreating ? l10n.cardDeckGoneTitle : l10n.cardGoneTitle,
                body: _isCreating ? l10n.cardDeckGoneBody : l10n.cardGoneBody,
                onBack: _leave,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  widget.deckContext(
                    widget.deckId,
                    _isCreating ? l10n.cardAddTitle : l10n.cardEditCrumb,
                  ),
                  Expanded(
                    child: MxScreenScroll(children: _fields(l10n, errors)),
                  ),
                ],
              ),
      ),
    );
  }

  MxAppBar _appBar(AppLocalizations l10n) => MxAppBar(
    title: _isCreating ? l10n.cardAddTitle : l10n.cardEditTitle,
    density: MxAppBarDensity.content,
    leading: MxIconButton(
      icon: _isCreating ? AppIcons.close : AppIcons.back,
      semanticLabel: _isCreating ? l10n.cardClose : l10n.commonBack,
      onPressed: _back,
    ),
    actions: [
      // Ruling P4a-L6: the flag toggles here, in edit only.
      if (!_isCreating && !_isGone)
        Semantics(
          toggled: _isFlagged,
          child: MxIconButton(
            icon: _isFlagged ? AppIcons.flagged : AppIcons.flag,
            semanticLabel: _isFlagged ? l10n.cardFlagClear : l10n.cardFlagLabel,
            onPressed: () => setState(() => _isFlagged = !_isFlagged),
          ),
        ),
      if (!_isGone)
        MxButton(
          label: l10n.cardSave,
          size: MxButtonSize.compact,
          isLoading: _isSaving,
          onPressed: _onSave,
        ),
    ],
  );

  List<Widget> _fields(AppLocalizations l10n, Map<_Field, String?> errors) => [
    const SizedBox(height: AppSpacing.control),
    if (_deckRejects)
      MxInlineBanner(
        tone: MxBannerTone.warning,
        title: l10n.cardDeckRejectsTitle,
        message: l10n.cardDeckRejectsBody,
      ),
    if (widget.detail case final detail?)
      CardEditSummaryWidget(detail: detail, onOpenDetails: _back),
    CardFieldWidget(
      label: l10n.cardFieldFront,
      hint: l10n.cardFrontHint,
      limit: CardDraft.maxFrontLength,
      controller: _front,
      focusNode: _frontFocus,
      isRequired: true,
      errorText: errors[_Field.front],
      onChanged: (_) => _touch(_Field.front),
    ),
    CardFieldWidget(
      label: l10n.cardFieldBack,
      hint: l10n.cardBackHint,
      limit: CardDraft.maxBackLength,
      controller: _back,
      isRequired: true,
      isMultiline: true,
      errorText: errors[_Field.back],
      onChanged: (_) => _touch(_Field.back),
    ),
    ..._optionalFields(l10n, errors),
    CardTagEditorWidget(
      tags: _tags,
      onChanged: (tags) => setState(() => _tags = tags),
    ),
  ];

  /// In create, behind "Add details"; in edit, under "Optional details".
  List<Widget> _optionalFields(
    AppLocalizations l10n,
    Map<_Field, String?> errors,
  ) {
    if (!_isDetailsOpen) {
      return [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
          child: MxButton(
            label: l10n.cardAddDetails,
            icon: AppIcons.details,
            tone: MxButtonTone.outline,
            isBlock: true,
            onPressed: () => setState(() => _isDetailsOpen = true),
          ),
        ),
      ];
    }
    return [
      if (!_isCreating)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.micro,
            0,
            AppSpacing.micro,
            AppSpacing.control,
          ),
          child: Text(
            l10n.cardOptionalDetails.toUpperCase(),
            semanticsLabel: l10n.cardOptionalDetails,
            style: context.textStyles.overline,
          ),
        ),
      for (final (field, icon, label, hint, controller) in [
        (_Field.example, AppIcons.example, l10n.cardFieldExample, l10n.cardExampleHint, _example),
        (_Field.hint, AppIcons.hint, l10n.cardFieldHint, l10n.cardHintHint, _hint),
        (
          _Field.pronunciation,
          AppIcons.pronunciation,
          l10n.cardFieldPronunciation,
          l10n.cardPronunciationHint,
          _pronunciation,
        ),
      ])
        CardFieldWidget(
          label: label,
          hint: hint,
          icon: icon,
          limit: CardDraft.maxOptionalLength,
          controller: controller,
          isMultiline: true,
          errorText: errors[field],
          onChanged: (_) => _touch(field),
        ),
    ];
  }
}
```

`lib/features/card/presentation/screens/card_editor_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/card/presentation/providers/card_detail_provider.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_form_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_gone_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Adds cards one after another into a deck, or edits one (spec §6.5, kit
/// 08/09). [deckContext] is the deck path `app/` passes in (ruling P4a-L7).
class CardEditorScreen extends StatelessWidget {
  const CardEditorScreen.create({
    super.key,
    required String this.deckId,
    required this.deckContext,
  }) : cardId = null;

  const CardEditorScreen.edit({
    super.key,
    required String this.cardId,
    required this.deckContext,
  }) : deckId = null;

  final String? deckId;
  final String? cardId;
  final Widget Function(String deckId, String currentLabel) deckContext;

  @override
  Widget build(BuildContext context) {
    if (deckId case final deckId?) {
      return CardEditorFormWidget(deckId: deckId, deckContext: deckContext);
    }
    return _EditLoader(cardId: cardId!, deckContext: deckContext);
  }
}

/// The card to edit while it loads, fails or is gone (ruling P4a-L4).
class _EditLoader extends ConsumerWidget {
  const _EditLoader({required this.cardId, required this.deckContext});

  final String cardId;
  final Widget Function(String deckId, String currentLabel) deckContext;

  static const int _skeletonRows = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = cardDetailProvider(cardId);
    void back() => unawaited(Navigator.of(context).maybePop());
    final bar = MxAppBar(
      title: l10n.cardEditTitle,
      density: MxAppBarDensity.content,
      leading: MxIconButton(
        icon: AppIcons.back,
        semanticLabel: l10n.commonBack,
        onPressed: back,
      ),
    );
    return switch (ref.watch(provider)) {
      AsyncData(value: Ok(:final value)) => CardEditorFormWidget(
        key: ValueKey(cardId),
        deckId: value.card.deckId,
        detail: value,
        deckContext: deckContext,
      ),
      AsyncData(value: Rejected()) => MxAppShell(
        appBar: bar,
        body: CardGoneWidget(
          title: l10n.cardGoneTitle,
          body: l10n.cardGoneBody,
          onBack: back,
        ),
      ),
      AsyncError() => MxAppShell(
        appBar: bar,
        body: MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.cardLoadErrorEditTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(provider),
            ),
          ],
        ),
      ),
      _ => MxAppShell(
        appBar: bar,
        body: MxScreenScroll(
          children: [
            for (var i = 0; i < _skeletonRows; i++) const MxSkeletonRow(),
          ],
        ),
      ),
    };
  }
}
```

- [ ] **Step 4: Run the tests**

```bash
flutter test test/features/card/presentation/card_editor_screen_test.dart
```

Expected: PASS, 11 tests.

- If `flutter.max_build_lines` flags a `build()`, move the `MxAppShell` arguments into more data methods like `_appBar`, and record a ruling.
- If `handlePopRoute` leaves the test's only route instead of reaching `PopScope`, host the screen in a pushed route in the test, and record a test-only ruling.
- If `Semantics(toggled:)` merges oddly with the `MxIconButton` tooltip, keep the tooltip finder. The toggled state is checked in the Task 5 audit. Record a ruling.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(card): the card editor: live checks, continuous create, edit, discard confirm, in-form failures

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: New card from the deck screen, and the create route

**Files:**
- Create: `lib/features/card/presentation/widgets/sections/card_add_fab_widget.dart`
- Modify:
  - `lib/features/deck/presentation/screens/deck_level_screen.dart`
  - `lib/features/deck/presentation/widgets/sections/deck_unset_state_widget.dart`
  - `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart`
  - `lib/app/router/app_routes.dart`, `lib/app/router/app_router.dart`
  - `test/support/library_harness.dart`
- Test:
  - `test/features/deck/presentation/open_deck_screen_test.dart` (update and extend)
  - `test/features/card/presentation/card_list_section_test.dart` (extend)
  - `test/app/library_routes_test.dart` (extend)

**Interfaces:**
- Consumes:
  - Task 1: copy keys `deckNewCard`, `deckNewSubDeck`, `deckUnsetNote`, `cardNewCard`.
  - Task 3: `CardEditorScreen.create`.
  - Task 2: `DeckContextHeaderWidget`.
- Produces:
  - `DeckLevelScreen` gains `required ValueChanged<String> onAddCard` and `required Widget Function(String deckId) cardFab`.
  - `DeckUnsetStateWidget({required VoidCallback onAddCard, required VoidCallback? onCreateSubDeck})`.
  - `CardListSectionWidget({required String deckId, required VoidCallback onAddCard})`.
  - `CardAddFabWidget({required String deckId, required VoidCallback onAddCard})`: the FAB, which hides while cards are selected.
  - `AppRoutes.cardNewChild`, `AppRoutes.newCard(String deckId)`.

**Design note.** The FAB of a deck of cards comes from the card feature, like the list itself. `app/` passes it in as `cardFab` (spec D8), and it watches the card selection. So `deck` never learns whether cards are selected, and there is no state to report back.

- [ ] **Step 1: Write the failing tests**

In `test/support/library_harness.dart`, replace `deckScreen`:

```dart
DeckLevelScreen deckScreen({
  String? deckId,
  ValueChanged<String>? onOpenDeck,
  ValueChanged<String?>? onOpenAncestor,
  ValueChanged<String>? onAddCard,
  Widget Function(String deckId)? cardContent,
  Widget Function(String deckId)? cardFab,
}) => DeckLevelScreen(
  deckId: deckId,
  onOpenDeck: onOpenDeck ?? (_) {},
  onOpenAncestor: onOpenAncestor ?? (_) {},
  onSearch: () {},
  onAddCard: onAddCard ?? (_) {},
  cardContent: cardContent ?? (_) => const SizedBox.shrink(),
  cardFab: cardFab ?? (_) => const SizedBox.shrink(),
);
```

In `test/features/deck/presentation/open_deck_screen_test.dart`, import `package:memox/shared/widgets/mx_button.dart` and add:

```dart
Finder _unsetButton(String label) => find.widgetWithText(MxButton, label);
```

Then replace the tests from 'an empty deck offers a sub-deck; creating one lists it' through 'a deck of cards shows no deck list yet (ruling P2-L1)' with these:

```dart
  libraryTest('an empty deck offers a card or a sub-deck (ruling P4a-L9)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final added = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: korean.id, onAddCard: added.add),
    );

    expect(find.text(_en.deckUnsetTitle), findsOneWidget);
    expect(find.text(_en.deckUnsetNote), findsOneWidget);
    await tester.tap(_unsetButton(_en.deckNewCard));
    expect(added, [korean.id]);

    await tester.tap(_unsetButton(_en.deckNewSubDeck));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Words');
    await tester.tap(find.text(_en.deckCreateConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
    expect(find.text('Words'), findsOneWidget);
  });

  libraryTest('the FAB opens the new sub-deck dialog', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
    await tester.tap(find.byType(MxFab));
    await tester.pumpAndSettle();

    expect(find.text(_en.deckCreateSubTitle), findsOneWidget);
  });

  libraryTest('the deepest deck offers a card only', (tester, env) async {
    final chain = await _chain(
      env,
      DeckEntity.maxDepth,
      (level) => 'Level $level',
    );
    final added = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: chain.last.id, onAddCard: added.add),
    );

    expect(find.byType(MxFab), findsNothing);
    expect(find.text(_en.deckUnsetDeepestBody), findsOneWidget);
    expect(_unsetButton(_en.deckNewSubDeck), findsNothing);
    await tester.tap(_unsetButton(_en.deckNewCard));
    expect(added, [chain.last.id]);
  });

  libraryTest('a deck of cards takes its FAB from the card feature', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'new', deckId: words.id);
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(
        deckId: words.id,
        cardFab: (deckId) => Text('fab of $deckId'),
      ),
    );

    expect(_barTitle('Words'), findsOneWidget);
    expect(find.byType(MxListSectionHeader), findsNothing);
    expect(find.text('fab of ${words.id}'), findsOneWidget);
  });
```

Append inside `main()` of `test/features/card/presentation/card_list_section_test.dart`. Import `card_add_fab_widget.dart` and `package:memox/shared/widgets/mx_fab.dart`. `_seed` is the file's own helper for a deck with cards:

```dart
  libraryTest('New card: the FAB adds, and hides while selecting (P4a-L9)', (
    tester,
    env,
  ) async {
    final deckId = await _seed(env);
    var adds = 0;
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(
        deckId: deckId,
        cardContent: (id) =>
            CardListSectionWidget(deckId: id, onAddCard: () => adds++),
        cardFab: (id) => CardAddFabWidget(deckId: id, onAddCard: () => adds++),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MxFab));
    expect(adds, 1);

    await tester.longPress(find.byType(CardRowWidget).first);
    await tester.pump();
    expect(find.byType(MxFab), findsNothing);
  });
```

Append inside `main()` of `test/app/library_routes_test.dart`. Import `package:memox/shared/widgets/mx_button.dart`:

```dart
  libraryTest('New card opens the editor; cards are added one after another', (
    tester,
    env,
  ) async {
    await env.decks.root('Korean');
    await pumpMemoxApp(tester, env);
    await _tap(tester, find.text('Korean'));
    await _tap(tester, find.widgetWithText(MxButton, _en.deckNewCard));
    expect(_barTitle(_en.cardAddTitle), findsOneWidget);

    for (final (front, back) in [('bap', 'rice'), ('mul', 'water')]) {
      await tester.enterText(find.byType(EditableText).at(0), front);
      await tester.enterText(find.byType(EditableText).at(1), back);
      await tester.pump();
      await _tap(tester, find.widgetWithText(MxButton, _en.cardSaveCard));
    }
    await _tap(tester, find.byTooltip(_en.cardClose));

    expect(_barTitle('Korean'), findsOneWidget);
    expect(find.text('bap'), findsOneWidget);
    expect(find.text('mul'), findsOneWidget);
  });

  libraryTest('Close on a typed card asks; Discard leaves (RF2)', (
    tester,
    env,
  ) async {
    await env.decks.root('Korean');
    await pumpMemoxApp(tester, env);
    await _tap(tester, find.text('Korean'));
    await _tap(tester, find.widgetWithText(MxButton, _en.deckNewCard));
    await tester.enterText(find.byType(EditableText).at(0), 'bap');
    await tester.pump();
    await _tap(tester, find.byTooltip(_en.cardClose));
    expect(find.text(_en.cardDiscardNewTitle), findsOneWidget);

    await _tap(tester, find.text(_en.cardDiscard));
    expect(_barTitle('Korean'), findsOneWidget);
    expect(find.text(_en.deckUnsetTitle), findsOneWidget);
  });
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/deck/presentation/open_deck_screen_test.dart test/features/card/presentation/card_list_section_test.dart test/app/library_routes_test.dart`
Expected: FAIL to compile, because `DeckLevelScreen` has no `onAddCard` or `cardFab`.

- [ ] **Step 3: Implement**

`lib/features/card/presentation/widgets/sections/card_add_fab_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/card/presentation/states/card_selection_state.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

/// New card on a deck of cards (kit 07). It gives way to the bulk bar while
/// cards are selected (ruling P4a-L9).
class CardAddFabWidget extends ConsumerWidget {
  const CardAddFabWidget({
    super.key,
    required this.deckId,
    required this.onAddCard,
  });

  final String deckId;
  final VoidCallback onAddCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(cardSelectionProvider(deckId)).isNotEmpty) {
      return const SizedBox.shrink();
    }
    return MxFab(
      icon: AppIcons.add,
      semanticLabel: context.l10n.cardNewCard,
      onPressed: onAddCard,
    );
  }
}
```

(Use the import path of `cardSelectionProvider` that `card_list_section_widget.dart` already uses.)

**Card list section.** In `card_list_section_widget.dart`:
- Add `required this.onAddCard` and `final VoidCallback onAddCard;` to `CardListSectionWidget`.
- Thread it through `_CardListScroll` (`required this.onAddCard`, `final VoidCallback onAddCard;`, passing `onAddCard: widget.onAddCard`) into `_CardListEmpty(request: request, onShowAll: onShowAll, onAddCard: onAddCard)`.
- In `_CardListEmpty`, add the field, and replace the last return with this:

```dart
    return MxEmptyState(
      icon: AppIcons.inbox,
      title: l10n.cardEmptyTitle,
      body: l10n.cardEmptyBody,
      actionLabel: l10n.cardNewCard,
      onAction: onAddCard,
    );
```

**Unset state.** Replace `deck_unset_state_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_note.dart';

/// A deck that holds nothing yet (UC-DECK-004, kit 01 `deckEmpty`): New card
/// and New sub-deck, and the note on what the first one decides (ruling
/// P4a-L9).
class DeckUnsetStateWidget extends StatelessWidget {
  const DeckUnsetStateWidget({
    super.key,
    required this.onAddCard,
    required this.onCreateSubDeck,
  });

  final VoidCallback onAddCard;

  /// Null at the deepest level, where no sub-deck fits (BR-DECK-001).
  final VoidCallback? onCreateSubDeck;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onCreateSubDeck = this.onCreateSubDeck;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.gutter,
      children: [
        MxEmptyState(
          icon: AppIcons.folder,
          title: l10n.deckUnsetTitle,
          body: onCreateSubDeck == null
              ? l10n.deckUnsetDeepestBody
              : l10n.deckUnsetBody,
        ),
        OverflowBar(
          alignment: MainAxisAlignment.center,
          spacing: AppSpacing.control,
          overflowSpacing: AppSpacing.control,
          overflowAlignment: OverflowBarAlignment.center,
          children: [
            MxButton(
              label: l10n.deckNewCard,
              icon: AppIcons.add,
              onPressed: onAddCard,
            ),
            if (onCreateSubDeck != null)
              MxButton(
                label: l10n.deckNewSubDeck,
                icon: AppIcons.library,
                tone: MxButtonTone.secondary,
                onPressed: onCreateSubDeck,
              ),
          ],
        ),
        if (onCreateSubDeck != null) MxNote(text: l10n.deckUnsetNote),
      ],
    );
  }
}
```

**Deck screen.** In `deck_level_screen.dart`:
- `DeckLevelScreen` gains two fields after `cardContent`, with `required this.onAddCard, required this.cardFab` in the constructor:

```dart
  /// New card for [deckId]: the router opens the card editor.
  final ValueChanged<String> onAddCard;

  /// A deck of cards' FAB, from the card feature like [cardContent] (spec
  /// D8). It hides itself while cards are selected.
  final Widget Function(String deckId) cardFab;
```

- Pass `onAddCard: onAddCard, cardFab: cardFab` from `DeckLevelScreen.build` into `_OpenDeck`, and from `_OpenDeck` into `_OpenDeckContent`. Both gain `required this.onAddCard, required this.cardFab` and the same two fields.
- In `_OpenDeckContent.build`, replace the `fab:` argument:

```dart
      // Ruling P4a-L9: a sub-deck where one fits, a card on a deck of cards.
      fab: switch (deck.contentType) {
        DeckContentType.card => cardFab(deck.id),
        _ when canCreateDeck && !isReordering => MxFab(
          icon: AppIcons.add,
          semanticLabel: l10n.deckCreateSub,
          onPressed: createSubDeck,
        ),
        _ => null,
      },
```

- Replace the `emptyState:` argument:

```dart
                emptyState: DeckUnsetStateWidget(
                  onAddCard: () => onAddCard(deck.id),
                  onCreateSubDeck: canCreateDeck ? createSubDeck : null,
                ),
```

- Update the `DeckUnsetStateWidget` doc reference, and remove ruling P2-L1's "a card once the editor arrives in phase 4" wording wherever it appears in `deck/presentation`.

**Routes.** In `app_routes.dart`, add after `deckSearch`:

```dart
  /// A deck's card editor in create mode, relative to [deckChild].
  static const String cardNewChild = 'cards/new';
```

And add after `deck(...)`:

```dart
  /// The card editor adding cards to [deckId].
  static String newCard(String deckId) => '${deck(deckId)}/$cardNewChild';
```

In `app_router.dart`, import `card_editor_screen.dart`, `card_add_fab_widget.dart` and `deck_context_header_widget.dart`. Give the deck `GoRoute` its child:

```dart
                GoRoute(
                  path: AppRoutes.deckChild,
                  builder: (context, state) => _deckLevel(
                    context,
                    deckId: state.pathParameters[AppRoutes.deckIdParam],
                  ),
                  routes: [
                    GoRoute(
                      path: AppRoutes.cardNewChild,
                      builder: (context, state) => CardEditorScreen.create(
                        deckId: state.pathParameters[AppRoutes.deckIdParam]!,
                        deckContext: _deckContext,
                      ),
                    ),
                  ],
                ),
```

Then replace `_deckLevel` and add `_deckContext`:

```dart
DeckLevelScreen _deckLevel(BuildContext context, {String? deckId}) {
  void addCard(String id) => unawaited(context.push(AppRoutes.newCard(id)));
  return DeckLevelScreen(
    deckId: deckId,
    onOpenDeck: (id) => context.push(AppRoutes.deck(id)),
    onOpenAncestor: (id) => _openAncestor(context, id),
    onSearch: () => context.push(AppRoutes.deckSearch),
    onAddCard: addCard,
    cardContent: (id) =>
        CardListSectionWidget(deckId: id, onAddCard: () => addCard(id)),
    cardFab: (id) =>
        CardAddFabWidget(deckId: id, onAddCard: () => addCard(id)),
  );
}

/// The deck path over the card editor (ruling P4a-L7, spec D8).
Widget _deckContext(String deckId, String currentLabel) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: currentLabel);
```

Keep `_deckLevel`'s doc comment. Update the phase-3 goldens' lambdas in `test/features/card/presentation/card_list_golden_test.dart` to `CardListSectionWidget(deckId: id, onAddCard: () {})`, and add `cardFab: (id) => CardAddFabWidget(deckId: id, onAddCard: () {})` so the goldens show the FAB (regenerated in Task 5). The hosts in `card_bulk_actions_test.dart`, `card_list_section_test.dart` and `card_selection_test.dart` become `CardListSectionWidget(deckId: deckId, onAddCard: () {})`.

- [ ] **Step 4: Run the tests**

```bash
flutter test test/features/deck test/features/card test/app/library_routes_test.dart
```

Expected:
- All new and updated tests PASS.
- The golden tests for `library_deck_unset_*` and `card_list_*` / `card_selection_*` FAIL on pixels only. They are regenerated in Task 5.
- Nothing else fails.

If a route test finds the editor's app bar title twice, because the breadcrumb also says "New card", keep `_barTitle`. It already scopes to `MxAppBar`.

- [ ] **Step 5: Gate and commit**

```bash
dart format lib test
flutter analyze
python .claude/skills/flutter-architecture/scripts/check_architecture.py
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
git add lib test
git commit -m "feat(deck,card): New card from the unset deck, the card list and its FAB; the create route

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Goldens, the flag's semantics, the deviation register, the full gate

**Files:**
- Create: `test/features/card/presentation/card_editor_golden_test.dart`
- Modify:
  - `test/features/card/presentation/card_editor_screen_test.dart` (one test)
  - `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (§9 register)
- Regenerate:
  - `test/features/deck/presentation/goldens/library_deck_unset_{light,dark}.png`
  - `test/features/card/presentation/goldens/card_list_{light,dark}.png`, `card_selection_{light,dark}.png`

**Interfaces:**
- Consumes: everything from Tasks 1–4.
- Produces: goldens `card_editor_create_*`, `card_editor_errors_*` and `card_editor_edit_*`, and register rows 79–83.

- [ ] **Step 1: Write the flag semantics test and the goldens**

Append inside `main()` of `card_editor_screen_test.dart`:

```dart
  libraryTest('the flag toggle reports its state (ruling P4a-L6)', (
    tester,
    env,
  ) async {
    final deckId = await _words(env);
    final card = await env.cards.card(deckId);
    await pumpLibraryScreen(tester, env, _edit(card.id));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byTooltip(_en.cardFlagLabel)),
      containsSemantics(hasToggledState: true, isToggled: false),
    );

    await tester.tap(find.byTooltip(_en.cardFlagLabel));
    await tester.pump();
    expect(
      tester.getSemantics(find.byTooltip(_en.cardFlagClear)),
      containsSemantics(hasToggledState: true, isToggled: true),
    );
  });
```

If the tooltip's node is not the one that carries the toggled state, find it with `find.bySemanticsLabel(_en.cardFlagLabel)` instead. Record a test-only ruling.

`test/features/card/presentation/card_editor_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

/// Korean › Words, empty. Romanized text: the golden font has no Hangul.
Future<String> _words(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  return (await env.decks.sub(korean.id, 'Words')).id;
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('card editor, create, $theme', (tester, env) async {
      final deckId = await _words(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          CardEditorScreen.create(deckId: deckId, deckContext: _context),
          brightness,
        );
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/card_editor_create_$theme.png',
        );
      });
    });

    libraryTest('card editor, errors and tags, $theme', (tester, env) async {
      final deckId = await _words(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          CardEditorScreen.create(deckId: deckId, deckContext: _context),
          brightness,
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(EditableText).at(0),
          'a' * (CardDraft.maxFrontLength + 4),
        );
        await tester.enterText(find.byType(EditableText).at(1), 'x');
        await tester.enterText(find.byType(EditableText).at(1), '');
        await tester.tap(find.text(_en.cardAddTag));
        await tester.pump();
        for (final tag in ['food', 'topik 1']) {
          await tester.enterText(find.byType(EditableText).at(2), tag);
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pump();
        }
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/card_editor_errors_$theme.png',
        );
      });
    });

    libraryTest('card editor, edit, $theme', (tester, env) async {
      final deckId = await _words(env);
      final card = await env.cards.card(
        deckId,
        const CardDraft(
          front: 'gamsahamnida',
          back: 'thank you',
          example: 'Dowajusyeoseo gamsahamnida.',
          pronunciation: 'gam-sa-ham-ni-da',
          isFlagged: true,
          tagNames: ['greeting', 'topik 1'],
        ),
      );
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          CardEditorScreen.edit(cardId: card.id, deckContext: _context),
          brightness,
        );
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/card_editor_edit_$theme.png',
        );
      });
    });
  }
}
```

- [ ] **Step 2: Run the new test, then generate and regenerate the goldens (Windows)**

```bash
flutter test test/features/card/presentation/card_editor_screen_test.dart
flutter test --update-goldens --tags golden test/features/card/presentation/card_editor_golden_test.dart test/features/card/presentation/card_list_golden_test.dart test/features/deck/presentation/deck_screens_golden_test.dart
```

Expected: the screen tests PASS, 12 tests. The golden files are written.

Then open each new or changed PNG and check it against kit 08, kit 09 and kit 01 `deckEmpty`:
- **Create:** the ✕ and compact Save; the path "Library › Korean › Words › New card" and the destination line; "FRONT · TERM Required 0 / 60"; the Add details button; "TAGS optional · 0 / 10" with Add tag; and the footer caption over Cancel and Save card.
- **Errors:** the front's too-long error and its count in the error colour; the back's blank error; two removable chips; and the caption "Fix the marked field to enable save."
- **Edit:** the flag glyph filled; the summary strip; "OPTIONAL DETAILS" with three fields, two filled; two chips; and Save changes.
- **Unset deck:** the two buttons (New card primary, New sub-deck secondary) and the note.
- **Card list and selection:** the New card FAB on the list, and no FAB while selecting.

Fix what the pictures show, then regenerate. One round, per the craft floor.

- [ ] **Step 3: Record the deviations**

Append these rows to the §9 register table of `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`, after row 78:

```markdown
| 79 | The card editor follows the V3 kit (08, 09) over library spec §6.5: live validation with Save disabled until valid, failures inside the form (inline banner, warning banner, gone state), and a discard confirm | library phase 4a P4a-L1…L5 |
| 80 | A new card has no flag control; the flag toggles from the edit app bar, and its glyph changes but does not recolour (`Icon(color:)` is banned) | library phase 4a P4a-L6 |
| 81 | The editor's deck context drops the kit's pill border, and Add tag is an outline chip, not dashed: no `BorderSide`, and no dashed-border token | library phase 4a P4a-L7, P4a-L8 |
| 82 | The editor offers no Move to Trash or Import cards; the edit summary's Details goes back, since the detail is the page under the editor from phase 4b | library phase 4a P4a-L10 |
| 83 | The edit mode is built and tested in phase 4a but has no route until phase 4b adds the card detail, which opens it | library phase 4a split |
```

In rows 71 and 77, append this to the first cell's text: ` — "Add card" closed by library phase 4a`.

- [ ] **Step 4: Run the full gate**

```bash
dart format --set-exit-if-changed lib test
flutter analyze
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python .claude/skills/flutter-architecture/scripts/check_architecture.py
flutter test
python tools/docs/check.py
GUARD_PY=python bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected:
- format clean; analyze "No issues found!";
- guard 0 errors / 0 warnings; architecture OK;
- every test passes, goldens included;
- the docs check passes; DoD passes.

**Scope check.** `git diff --stat master...HEAD -- lib/features/*/domain lib/features/*/data lib/features/*/di lib/core/database` must print nothing (UI only).

- [ ] **Step 5: Commit**

```bash
git add test docs
git commit -m "test(card): editor goldens and flag semantics; register phase 4a deviations

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
