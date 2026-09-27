# Deck mastery: BR/UC, count and screen 01 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Define deck mastery (BR-DECK-026) and the Progress sort (BR-DECK-027), count mastered cards in the level reads, and draw screen 01's mastery bar, summary donut and Progress sort as kit v3 does.

**Architecture:** The two level queries gain `mastered_count` in the statement they already run; `DeckTile` / `DeckLevel` carry it and `DeckLevelSort.progress` orders by it with integer cross-multiplication. `MasteryRamp` resolves its learning band to `statusLearningInk` and gains `percent`; `MxLinearProgress` gains a `.mastery` variant. `DeckRowWidget` draws the bar, `DeckSummaryCardWidget` the donut.

**Tech Stack:** Flutter 3.47.5, Riverpod 3, Drift (`.drift` named queries + build_runner), gen-l10n (en, vi), golden tests in the Linux container.

**Spec:** `docs/superpowers/specs/2026-09-27-deck-mastery-design.md` (R1–R4, D1–D13). Critique: `.impeccable/critique/2026-09-27T12-00-00Z__deck-mastery-kit.md`.

The code below was built and gated once in a scratch worktree (gate: 2369 tests green, 351 goldens green), so every diff here compiles and passes as written. Diffs are against `master` at `90e8221`.

## Global Constraints

- Mastery = active cards whose display status is `mastered` (box 8, or interval ≥ 128 days, and `learned_at IS NOT NULL`) ÷ **every** active card of the subtree, new cards included (R1). Trash counts for nothing. Never stored.
- A deck with no card has no fraction (`masteryFraction == null`); its bar is the bare track and its row says no percent.
- Progress sort: fraction ascending; decks with no card last (R2); ties fall back to `(sibling_position, id)`; compare by cross-multiplication, never floating point.
- The SQL literals `8` and `128` must agree with `CardDisplayStatus` (`lib/features/card/domain/models/card_display_status_model.dart`); the parity test pins it (D7).
- `MasteryRamp` < 34 % band = `derived.statusLearningInk` (R4); 34–66 % `statusReviewing`; ≥ 67 % `statusMastered`; 0 paints nothing.
- `MasteryRamp.percent(f)`: 0 only at 0, 100 only at 1, else `round` clamped to 1…99 (D13).
- The mastery bar is 5 tall on the progress track (`surfaceContainerHigh`), 12 (`AppSpacing.grouped`) under the meta; the fill keeps at least its height in from either end when 0 < f < 1 (D13).
- No schema change, no migration, no new dependency, no new shared widget (R3).
- Guard rules: no raw Material widgets or `Icon(color:)` in features, no string literals in `Text`, every string in `app_en.arb` and `app_vi.arb`.
- Gate: `GUARD_PY=/usr/bin/python3.13 bash .claude/skills/flutter-workflow/scripts/dod_check.sh --force`; goldens `TZ=UTC flutter test --tags golden` (Linux container only).

## Review Focus

1. A card promoted to mastered while the Library is open: the bar and the Progress order update without a refresh (stream re-read) — test in Task 2 (`a card that becomes mastered emits again with the new count`).
2. A huge deck with one mastered card (1 / 10,000): the bar still shows a visible sliver — test in Task 3 (`any mastery shows …`).
3. A deck at 99.6 %: the donut and the row must not claim 100 % — tests in Task 3 (`the percent never rounds to a lie`, donut `99.6% reads 99%`).
4. The open deck summary with the donut at text scale 2 on a 360 phone: nothing overflows — test in Task 4 (`the summary with its donut holds at text scale 2`).
5. An unlearned card whose box or interval already sits at the threshold (imported or reset data): never counted as mastered on either side — test in Task 2 (parity test, `new8` / `new128`).

---

### Task 1: BR-DECK-026, BR-DECK-027 and the UC amendments

**Files:**
- Create: `docs/features/deck/rules/BR-DECK-026-mastery-cua-deck.md`, `docs/features/deck/rules/BR-DECK-027-sap-theo-tien-do.md`
- Modify: `docs/features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md`, `docs/features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md`
- Regenerate: `docs/_generated/{index,open-questions,traceability}.md`

**Interfaces:**
- Produces: the IDs BR-DECK-026 and BR-DECK-027 that Tasks 2–5 name in test names and comments.

- [ ] **Step 1: Write the two BR files and amend the UCs**


`docs/features/deck/rules/BR-DECK-026-mastery-cua-deck.md`:

```diff
@@ -0,0 +1,40 @@
+---
+id: BR-DECK-026
+title: Mastery của deck
+status: active
+summary: Mastery của một deck là số thẻ `mastered` chia cho mọi thẻ active trong cả cây, kể cả thẻ mới; suy ra khi đọc, không lưu cột.
+superseded_by:
+---
+## Rule
+
+Mastery của một deck MUST là số thẻ active có trạng thái hiển thị `mastered` (BR-CARD-006, BR-SRS-013) trong cả cây của deck, chia cho **mọi** thẻ active của cây đó, kể cả thẻ `new`. Thẻ và deck trong Trash MUST NOT được tính. Tỉ lệ MUST được suy ra khi đọc và MUST NOT là cột trong DB. Deck không có thẻ nào MUST NOT có tỉ lệ: thanh mastery chỉ vẽ track rỗng.
+
+**Enforced by:** rule
+**Liên quan:** BR-CARD-006, BR-SRS-013, BR-DECK-002, BR-DECK-027
+
+## Lý do
+
+**Mẫu số gồm cả thẻ mới.** Thanh mastery trả lời "bao nhiêu phần của deck này đã ở lại
+với mình", không phải "mình đã đi được bao xa". Một deck lớn mới bắt đầu học vì thế
+hiện thấp, và điều đó đúng. Số liệu mẫu của kit cũng tính như vậy: 204 / 1.248 thẻ =
+16 %. Donut của card list (màn 07) cũng dùng đúng tỉ lệ `mastered / total`, nên hai màn
+không lệch nhau.
+
+**Không có tỉ lệ khi không có thẻ.** 0 / 0 không phải 0 %. Deck rỗng không có gì để
+thuộc, nên nó xếp cuối khi sort theo tiến độ (BR-DECK-027) và hàng của nó không đọc
+phần trăm nào.
+
+Chủ dự án chốt định nghĩa này ngày 2026-09-27
+([spec](../../../superpowers/specs/2026-09-27-deck-mastery-design.md) R1).
+
+## Ví dụ
+
+- Cây có 1.248 thẻ, 204 thẻ `mastered`: mastery 16 %.
+- Cây có 5 thẻ đều `new`: mastery 0 %.
+- Cây có 10 thẻ, 1 thẻ `mastered` nằm trong Trash: mastery 0 / 9.
+
+## Edge case
+
+- Thẻ chưa học xong lần đầu (`learned_at IS NULL`) không bao giờ `mastered`, kể cả khi
+  box hay interval chạm ngưỡng (BR-CARD-007).
+- Deck chỉ chứa deck con rỗng: không có tỉ lệ; donut ở tóm tắt của deck đó đọc 0 %.
```

`docs/features/deck/rules/BR-DECK-027-sap-theo-tien-do.md`:

```diff
@@ -0,0 +1,28 @@
+---
+id: BR-DECK-027
+title: Sắp theo tiến độ
+status: active
+summary: Sort Progress xếp deck theo mastery tăng dần; deck không có thẻ xếp cuối; bằng nhau thì theo thứ tự thủ công.
+superseded_by:
+---
+## Rule
+
+Sort "Progress · Least mastered first" MUST xếp các deck của một level theo mastery (BR-DECK-026) **tăng dần**. Deck không có thẻ nào MUST đứng sau mọi deck có thẻ. Hai deck có cùng tỉ lệ MUST giữ thứ tự thủ công `(sibling_position, id)`, như mọi kiểu sort khác. So sánh MUST dùng số nguyên (nhân chéo), để 1/2 và 2/4 bằng nhau.
+
+**Enforced by:** rule
+**Liên quan:** BR-DECK-026, UC-DECK-003, UC-DECK-006
+
+## Lý do
+
+Sort này trả lời câu "deck nào cần mình nhất". Deck rỗng không cần gì, nên đứng cuối
+thay vì đứng đầu cùng các deck 0 % (chủ dự án chốt ngày 2026-09-27,
+[spec](../../../superpowers/specs/2026-09-27-deck-mastery-design.md) R2). Đây là
+view-only sort: khi nó đang dùng, thao tác reorder bị ẩn (UC-DECK-006).
+
+## Ví dụ
+
+0 % (có thẻ) < 3,5 % < 16 % < 100 %, rồi tới các deck rỗng.
+
+## Edge case
+
+Bộ lọc "Only decks with due cards" lọc trước; sort chỉ xếp các deck còn lại.
```

`docs/features/deck/usecases/UC-DECK-003-xem-danh-sach-deck-voi-tien-do.md`:

```diff
@@ -2,8 +2,8 @@
 id: UC-DECK-003
 title: Xem danh sách deck với tiến độ
 status: ready
-rules: [BR-DECK-002, BR-DECK-003, BR-DECK-011, BR-STUDY-008, BR-STUDY-051]
-code: [lib/features/deck/domain/usecases/watch_deck_level_use_case.dart, lib/features/deck/domain/usecases/watch_deck_use_case.dart]
+rules: [BR-DECK-002, BR-DECK-003, BR-DECK-011, BR-DECK-026, BR-DECK-027, BR-STUDY-008, BR-STUDY-051]
+code: [lib/features/deck/domain/usecases/watch_deck_level_use_case.dart, lib/features/deck/domain/usecases/watch_deck_use_case.dart, lib/features/deck/domain/models/deck_level_model.dart, lib/features/deck/domain/models/deck_level_query_model.dart]
 ---
 ## Mục tiêu / Actor / Precondition
 
@@ -28,7 +28,12 @@ code: [lib/features/deck/domain/usecases/watch_deck_level_use_case.dart, lib/fea
    Overdue/Due today/New/Scheduled theo BR-STUDY-068 — lưới 2×2, mỗi hàng căn theo
    alphabetic baseline; Scheduled là tập trung tính, không actionable và không
    bao giờ là primary metric.
-4. Mở một deck hiển thị nội dung theo `content_type`: danh sách deck con, hoặc
+4. Mỗi deck có một thanh mastery: số thẻ `mastered` trên mọi thẻ của cây
+   (BR-DECK-026). Deck rỗng chỉ vẽ track. Thanh không có chữ, nên hàng đọc
+   "{n}% mastered" cho trình đọc màn hình.
+5. Mở một deck chứa deck con hiển thị ở tóm tắt một donut mastery của cả level,
+   cạnh dòng "Mastered · {thuật toán}".
+6. Mở một deck hiển thị nội dung theo `content_type`: danh sách deck con, hoặc
    danh sách card, không bao giờ cả hai (BR-DECK-011).
 
 ## Alternative / Error flow
@@ -40,6 +45,9 @@ code: [lib/features/deck/domain/usecases/watch_deck_level_use_case.dart, lib/fea
   không cần refresh thủ công.
 - **A3 — Cây sâu nhiều cấp:** điều hướng xuống từng cấp; số liệu gộp luôn tính
   theo `root_id` (BR-DECK-002, BR-DECK-003).
+- **A4 — Sắp xếp và lọc:** Manual, Newest, Name, Most due hoặc Progress
+  (BR-DECK-027), cùng bộ lọc chỉ giữ deck có thẻ đến hạn. Mọi sort kết thúc bằng
+  thứ tự thủ công.
 
 **Error flows:**
 - **E1 — Đọc thất bại:** màn hình lỗi có nút thử lại.
```

`docs/features/deck/usecases/UC-DECK-006-sap-xep-lai-deck-cung-cap.md`:

```diff
@@ -2,7 +2,7 @@
 id: UC-DECK-006
 title: Sắp xếp lại Deck cùng cấp
 status: ready
-rules: [BR-DECK-001, BR-DECK-002, BR-DECK-003, BR-DECK-004, BR-SRS-007]
+rules: [BR-DECK-001, BR-DECK-002, BR-DECK-003, BR-DECK-004, BR-DECK-027, BR-SRS-007]
 code: [lib/features/deck/domain/usecases/reorder_deck_use_case.dart]
 ---
 ## Mục tiêu / Actor / Precondition
@@ -27,8 +27,8 @@ Manual order.
 
 **Alternative flows:** Deck đầu không hiện Move up; deck cuối không hiện Move
 down; level chỉ có một deck không hiện thao tác reorder. Khi đang dùng sort theo
-tên, ngày, due hoặc tiến độ, thao tác bị ẩn để neighbour không bị suy ra từ một
-view-only order.
+tên, ngày, due hoặc tiến độ (BR-DECK-027), thao tác bị ẩn để neighbour không bị
+suy ra từ một view-only order.
 
 **Error flows:** Source hoặc target đã stale, hoặc không còn sibling → transaction
 từ chối và không ghi gì. Lỗi database ở bất kỳ update nào → toàn transaction
```


UC-DECK-003's `code:` names `deck_level_model.dart` and `deck_level_query_model.dart`, which exist already; Task 2 changes them.

- [ ] **Step 2: Regenerate and check the docs**

Run: `/usr/bin/python3.13 tools/docs/generate.py && /usr/bin/python3.13 tools/docs/check.py`
Expected: `OK docs/_generated: generated 3 files`, then `PASS — 0 error(s)` (45 warnings, all pre-existing).

- [ ] **Step 3: Commit**

```bash
git add docs/features/deck docs/_generated
git commit -m "docs(deck): BR-DECK-026 deck mastery and BR-DECK-027 the Progress sort"
```

### Task 2: `mastered_count`, the model and the Progress sort

**Files:**
- Modify: `lib/core/database/queries/deck_queries.drift`, `lib/features/deck/data/mappers/deck_mapper.dart`, `lib/features/deck/domain/models/deck_level_model.dart`, `lib/features/deck/domain/models/deck_level_query_model.dart`, `lib/features/deck/presentation/widgets/overlays/deck_level_query_sheets_widget.dart`, `lib/features/deck/presentation/widgets/support/deck_level_query_label_widget.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Create test: `test/features/deck/data/deck_mastery_parity_test.dart`
- Modify tests: `test/features/deck/data/deck_level_read_test.dart`, `test/features/deck/domain/deck_level_model_test.dart`, `test/features/deck/presentation/deck_level_screen_test.dart`, `test/features/deck/presentation/deck_row_widget_test.dart`

**Interfaces:**
- Consumes: `statusCountsOf(Iterable<CardSchedule>)` from `lib/features/card/data/mappers/card_mapper.dart` (test only); `insertCard(db, {box, intervalDays, learnedAt, …})` from `test/support/card_fixtures.dart`.
- Produces: `DeckTile.masteredCount` (int, required), `double? DeckTile.masteryFraction`; `DeckLevel.cardCount`, `DeckLevel.masteredCount`, `double DeckLevel.masteryFraction` (0 with no card); `DeckLevelSort.progress`; l10n `deckSortProgress`, `deckSortProgressHint`.

- [ ] **Step 1: Write the failing tests**


`test/features/deck/data/deck_mastery_parity_test.dart`:

```diff
@@ -0,0 +1,84 @@
+import 'package:flutter_test/flutter_test.dart';
+import 'package:memox/core/database/app_database.dart';
+import 'package:memox/features/card/data/mappers/card_mapper.dart';
+import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
+import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
+
+import '../../../support/card_fixtures.dart';
+import '../../../support/deck_fixtures.dart';
+import '../../../support/test_database.dart';
+
+// BR-DECK-026, spec D7: the SQL count of mastered cards and the Dart display
+// status (BR-CARD-006, BR-SRS-013) agree at every threshold, so neither side
+// can move alone.
+
+final _now = DateTime(2026, 9, 23, 10);
+final _today = DateTime(2026, 9, 23);
+final _learned = DateTime(2026, 5, 1);
+
+void main() {
+  late AppDatabase db;
+  late DeckRepositoryImpl repo;
+
+  setUp(() {
+    db = openTestDatabase();
+    repo = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 1));
+  });
+  tearDown(() => db.close());
+
+  Future<(int, int)> sqlAndDart() async {
+    final [tile] = await repo
+        .watchLevel(parentId: null, now: _now, startOfToday: _today)
+        .first;
+    final schedules = await db.select(db.cardSchedule).get();
+    return (tile.masteredCount, statusCountsOf(schedules).mastered);
+  }
+
+  test('eight boxes: box 7 is not mastered, box 8 is, an unlearned card '
+      'never is (BR-DECK-026)', () async {
+    final root = await repo.root('Boxes');
+    final leaf = await repo.sub(root.id, 'Leaf');
+    await insertCard(db, id: 'b1', deckId: leaf.id, learnedAt: _learned);
+    await insertCard(
+      db,
+      id: 'b7',
+      deckId: leaf.id,
+      learnedAt: _learned,
+      box: 7,
+    );
+    await insertCard(
+      db,
+      id: 'b8',
+      deckId: leaf.id,
+      learnedAt: _learned,
+      box: 8,
+    );
+    await insertCard(db, id: 'new8', deckId: leaf.id, box: 8);
+
+    expect(await sqlAndDart(), (1, 1));
+  });
+
+  test('SM-2: 127 days is not mastered, 128 is, an unlearned card never is '
+      '(BR-DECK-026)', () async {
+    final root = await repo.root('Intervals', SchedulerType.sm2);
+    final leaf = await repo.sub(root.id, 'Leaf');
+    await insertCard(db, id: 'd1', deckId: leaf.id, learnedAt: _learned);
+    await insertCard(
+      db,
+      id: 'd127',
+      deckId: leaf.id,
+      learnedAt: _learned,
+      intervalDays: 127,
+    );
+    await insertCard(
+      db,
+      id: 'd128',
+      deckId: leaf.id,
+      learnedAt: _learned,
+      intervalDays: 128,
+    );
+    await insertCard(db, id: 'new128', deckId: leaf.id, intervalDays: 128);
+
+    expect(await sqlAndDart(), (1, 1));
+  });
+}
```

`test/features/deck/data/deck_level_read_test.dart`:

```diff
@@ -125,6 +125,28 @@ void main() {
     },
   );
 
+  test(
+    'each tile counts the mastered cards of its subtree (BR-DECK-026)',
+    () async {
+      final [root] = await level(null).first;
+      final [mixedTile, noDueTile] = await level(library.id).first;
+
+      expect(
+        (root.masteredCount, mixedTile.masteredCount, noDueTile.masteredCount),
+        (1, 1, 0),
+      );
+      expect(mixedTile.masteryFraction, 0.25);
+    },
+  );
+
+  test('a mastered card in the Trash is not counted (BR-DECK-026)', () async {
+    await trashCardRow(db, 'master');
+
+    final [root] = await level(null).first;
+
+    expect((root.cardCount, root.masteredCount), (4, 0));
+  });
+
   test('decks and cards in the Trash are left out (spec §8)', () async {
     await insertCard(
       db,
```

`test/features/deck/data/deck_level_read_test.dart`:

```diff
@@ -139,6 +139,22 @@ void main() {
     },
   );
 
+  test('a card that becomes mastered emits again with the new count '
+      '(BR-DECK-026, UC-DECK-003 A2)', () async {
+    final emitted = <List<DeckTile>>[];
+    final subscription = level(null).listen(emitted.add);
+    await pumpEventQueue();
+
+    await db.customUpdate(
+      "UPDATE card_schedule SET current_box = 8 WHERE card_id = 'review'",
+      updates: {db.cardSchedule},
+    );
+    await pumpEventQueue();
+
+    expect([for (final tiles in emitted) tiles.single.masteredCount], [1, 2]);
+    await subscription.cancel();
+  });
+
   test('a mastered card in the Trash is not counted (BR-DECK-026)', () async {
     await trashCardRow(db, 'master');
 
```

`test/features/deck/domain/deck_level_model_test.dart`:

```diff
@@ -15,6 +15,7 @@ DeckTile _tile(
   int newCards = 0,
   int overdue = 0,
   int dueToday = 0,
+  int mastered = 0,
   DateTime? oldestDueAt,
 }) => DeckTile(
   id: id,
@@ -27,6 +28,7 @@ DeckTile _tile(
   newCount: newCards,
   overdueCount: overdue,
   dueTodayCount: dueToday,
+  masteredCount: mastered,
   oldestDueAt: oldestDueAt,
   startOfToday: _today,
 );
@@ -124,6 +126,26 @@ void main() {
       expect(_ids(level), ['z', 'y', 'w', 'x']);
     });
 
+    test('progress puts the least mastered first, decks with no card last, '
+        'then the manual order (BR-DECK-027)', () {
+      final level = DeckLevel.of([
+        _tile('empty', position: 0),
+        _tile('full', position: 1, cards: 10, mastered: 10),
+        _tile('half', position: 2, cards: 4, mastered: 2),
+        _tile('none', position: 3, cards: 5),
+        _tile('halfToo', position: 4, cards: 2, mastered: 1),
+        _tile('sliver', position: 5, cards: 10000, mastered: 1),
+      ], sort: DeckLevelSort.progress);
+      expect(_ids(level), [
+        'none',
+        'sliver',
+        'half',
+        'halfToo',
+        'full',
+        'empty',
+      ]);
+    });
+
     test('equal names keep the manual order', () {
       final level = DeckLevel.of([
         _tile('second', name: 'Same', position: 1),
@@ -170,6 +192,36 @@ void main() {
     });
   });
 
+  group('mastery (BR-DECK-026)', () {
+    test('a tile is mastered over every card, and has none with no card', () {
+      expect(_tile('e').masteryFraction, isNull);
+      expect(_tile('n', cards: 5).masteryFraction, 0);
+      expect(
+        _tile('h', cards: 1248, mastered: 204).masteryFraction,
+        closeTo(0.1635, 0.0001),
+      );
+      expect(_tile('f', cards: 10, mastered: 10).masteryFraction, 1);
+    });
+
+    test('the level sums every deck, whatever the filter; 0 with no card', () {
+      final tiles = [
+        _tile(
+          'due',
+          cards: 4,
+          mastered: 1,
+          overdue: 1,
+          oldestDueAt: DateTime(2026, 9, 20),
+        ),
+        _tile('idle', cards: 6, mastered: 3),
+      ];
+      final level = DeckLevel.of(tiles, filter: DeckLevelFilter.due);
+
+      expect((level.cardCount, level.masteredCount), (10, 4));
+      expect(level.masteryFraction, 0.4);
+      expect(DeckLevel.of([_tile('e')]).masteryFraction, 0);
+    });
+  });
+
   test('deckCount counts every deck of the level, whatever the filter', () {
     final tiles = [
       _tile('due', cards: 1, overdue: 1, oldestDueAt: DateTime(2026, 9, 20)),
```

`test/features/deck/presentation/deck_level_screen_test.dart`:

```diff
@@ -365,16 +365,44 @@ void main() {
     expect(find.byType(MxFab), findsOneWidget);
   });
 
-  libraryTest('the sort sheet offers only the sorts that work', (
-    tester,
-    env,
-  ) async {
+  libraryTest('the sort sheet offers the five sorts of the kit, Progress last '
+      '(BR-DECK-027)', (tester, env) async {
+    await _seed(env);
+    await pumpLibraryScreen(tester, env, deckScreen());
+    await tester.tap(find.text(_en.deckSortManual));
+    await tester.pumpAndSettle();
+
+    final rows = tester.widgetList<MxOptionRow>(find.byType(MxOptionRow));
+    expect(rows, hasLength(5));
+    expect(
+      (rows.last.title, rows.last.description),
+      (_en.deckSortProgress, _en.deckSortProgressHint),
+    );
+  });
+
+  libraryTest('sort by progress puts the least mastered first and the empty '
+      'deck last (BR-DECK-027)', (tester, env) async {
     await _seed(env);
+    final hangul = await env.decks.root('Hangul');
+    final letters = await env.decks.sub(hangul.id, 'Letters');
+    await insertCard(
+      env.db,
+      id: 'known',
+      deckId: letters.id,
+      learnedAt: DateTime(2026, 5, 1),
+      dueAt: DateTime(2026, 10, 30),
+      box: 8,
+    );
     await pumpLibraryScreen(tester, env, deckScreen());
     await tester.tap(find.text(_en.deckSortManual));
     await tester.pumpAndSettle();
+    await tester.tap(find.text(_en.deckSortProgress));
+    await tester.pumpAndSettle();
+    await tester.tap(find.text(_en.commonDone));
+    await tester.pumpAndSettle();
 
-    // Manual, recent, name, due: the progress sort waits (spec A4, amended).
-    expect(find.byType(MxOptionRow), findsNWidgets(4));
+    double top(String name) => tester.getTopLeft(find.text(name)).dy;
+    expect(top('Korean'), lessThan(top('Hangul')));
+    expect(top('Hangul'), lessThan(top('Kanji')));
   });
 }
```

`test/features/deck/presentation/deck_row_widget_test.dart`:

```diff
@@ -29,6 +29,7 @@ DeckTile _tile({
   newCount: 0,
   overdueCount: overdue,
   dueTodayCount: today,
+  masteredCount: 0,
   oldestDueAt: overdue > 0 ? DateTime(2026, 9, 20) : null,
   startOfToday: _today,
 );
```


- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/deck`
Expected: compile errors — `No named parameter with the name 'masteredCount'`, `The getter 'masteredCount' isn't defined`, `Member not found: 'progress'`, `The getter 'deckSortProgress' isn't defined`.

- [ ] **Step 3: Implement**


`lib/core/database/queries/deck_queries.drift`:

```diff
@@ -23,7 +23,9 @@ WHERE id = :deck_id AND delete_batch_id IS NULL;
 -- root_id in one statement. The sets are those of BR-STUDY-047 and
 -- BR-STUDY-051: New is an unlearned card; Due is a learned card whose due_at
 -- is at or before :now, Overdue before :start_of_today and Due today from it
--- on (BR-STUDY-068). Both come from Dart (BR-STUDY-068).
+-- on (BR-STUDY-068). Both come from Dart (BR-STUDY-068). Mastered is a
+-- learned card at box 8 or 128+ days (BR-DECK-026, BR-SRS-013); the literals
+-- match CardDisplayStatus, which a parity test pins.
 deckLevelOfRoots(:start_of_today AS DATETIME, :now AS DATETIME)
   AS DeckTileRow:
 SELECT
@@ -34,6 +36,7 @@ SELECT
   COALESCE(t.new_count, 0) AS new_count,
   COALESCE(t.overdue_count, 0) AS overdue_count,
   COALESCE(t.due_today_count, 0) AS due_today_count,
+  COALESCE(t.mastered_count, 0) AS mastered_count,
   t.oldest_due_at AS oldest_due_at
 FROM deck d
 LEFT JOIN (
@@ -44,6 +47,8 @@ LEFT JOIN (
       AND cs.due_at < :start_of_today) AS overdue_count,
     COUNT(*) FILTER (WHERE cs.learned_at IS NOT NULL
       AND cs.due_at >= :start_of_today AND cs.due_at <= :now) AS due_today_count,
+    COUNT(*) FILTER (WHERE cs.learned_at IS NOT NULL
+      AND (cs.current_box >= 8 OR cs.interval_days >= 128)) AS mastered_count,
     MIN(cs.due_at) FILTER (WHERE cs.learned_at IS NOT NULL
       AND cs.due_at <= :now) AS oldest_due_at
   FROM card c
@@ -75,6 +80,8 @@ counts AS (
       AND cs.due_at < :start_of_today) AS overdue_count,
     COUNT(*) FILTER (WHERE cs.learned_at IS NOT NULL
       AND cs.due_at >= :start_of_today AND cs.due_at <= :now) AS due_today_count,
+    COUNT(*) FILTER (WHERE cs.learned_at IS NOT NULL
+      AND (cs.current_box >= 8 OR cs.interval_days >= 128)) AS mastered_count,
     MIN(cs.due_at) FILTER (WHERE cs.learned_at IS NOT NULL
       AND cs.due_at <= :now) AS oldest_due_at
   FROM tree
@@ -90,6 +97,7 @@ SELECT
   COALESCE(counts.new_count, 0) AS new_count,
   COALESCE(counts.overdue_count, 0) AS overdue_count,
   COALESCE(counts.due_today_count, 0) AS due_today_count,
+  COALESCE(counts.mastered_count, 0) AS mastered_count,
   counts.oldest_due_at AS oldest_due_at
 FROM deck d
 JOIN deck r ON r.id = d.root_id AND r.delete_batch_id IS NULL
```

`lib/features/deck/data/mappers/deck_mapper.dart`:

```diff
@@ -39,6 +39,7 @@ DeckTile deckTileOf(DeckTileRow row, DateTime startOfToday) => DeckTile(
   newCount: row.newCount,
   overdueCount: row.overdueCount,
   dueTodayCount: row.dueTodayCount,
+  masteredCount: row.masteredCount,
   oldestDueAt: row.oldestDueAt,
   startOfToday: startOfToday,
 );
```

`lib/features/deck/domain/models/deck_level_model.dart`:

```diff
@@ -17,6 +17,7 @@ final class DeckTile {
     required this.newCount,
     required this.overdueCount,
     required this.dueTodayCount,
+    required this.masteredCount,
     required this.oldestDueAt,
     required this.startOfToday,
   });
@@ -36,6 +37,9 @@ final class DeckTile {
   final int overdueCount;
   final int dueTodayCount;
 
+  /// The subtree's cards whose display status is mastered (BR-DECK-026).
+  final int masteredCount;
+
   /// The `due_at` of the subtree's oldest Due card; null when none is Due.
   final DateTime? oldestDueAt;
   final DateTime startOfToday;
@@ -45,6 +49,11 @@ final class DeckTile {
   /// Learned cards not Due yet: the neutral set (BR-STUDY-068).
   int get scheduledCount => cardCount - newCount - dueCount;
 
+  /// Mastered over every card of the subtree (BR-DECK-026); null when the
+  /// subtree holds no card, which has nothing to master.
+  double? get masteryFraction =>
+      cardCount == 0 ? null : masteredCount / cardCount;
+
   DeckScheduleStatus get scheduleStatus =>
       DeckScheduleStatus.of(oldestDueAt, startOfToday);
 
@@ -64,6 +73,8 @@ final class DeckLevel {
     required this.scheduledCount,
     required this.maxOverdueDays,
     required this.deckCount,
+    required this.cardCount,
+    required this.masteredCount,
   });
 
   factory DeckLevel.of(
@@ -88,6 +99,8 @@ final class DeckLevel {
             tile.overdueDays > longest ? tile.overdueDays : longest,
       ),
       deckCount: tiles.length,
+      cardCount: sum((tile) => tile.cardCount),
+      masteredCount: sum((tile) => tile.masteredCount),
     );
   }
 
@@ -100,4 +113,13 @@ final class DeckLevel {
 
   /// Every deck of the level, whatever the filter (the open deck's summary).
   final int deckCount;
+
+  /// The cards of every deck of the level, whatever the filter.
+  final int cardCount;
+
+  /// The mastered cards among [cardCount] (BR-DECK-026).
+  final int masteredCount;
+
+  /// The level's mastery for the open deck's donut; 0 with no card.
+  double get masteryFraction => cardCount == 0 ? 0 : masteredCount / cardCount;
 }
```

`lib/features/deck/domain/models/deck_level_query_model.dart`:

```diff
@@ -2,8 +2,7 @@ import 'package:memox/core/text/folded_text.dart';
 import 'package:memox/features/deck/domain/models/deck_level_model.dart';
 
 /// How a level is ordered (UC-DECK-003, UC-DECK-006). Every order ends in the
-/// manual one, `(sibling_position, id)`, so equal keys stay stable. The
-/// "progress" order UC-DECK-006 names has no definition yet and is not here.
+/// manual one, `(sibling_position, id)`, so equal keys stay stable.
 enum DeckLevelSort {
   manual,
 
@@ -14,7 +13,10 @@ enum DeckLevelSort {
   recent,
 
   /// Most Due cards first.
-  due;
+  due,
+
+  /// Least mastered first; decks with no card last (BR-DECK-027).
+  progress;
 
   List<DeckTile> apply(List<DeckTile> tiles) => [...tiles]..sort(_compare);
 
@@ -24,12 +26,24 @@ enum DeckLevelSort {
       name => foldText(a.name).compareTo(foldText(b.name)),
       recent => b.createdAt.compareTo(a.createdAt),
       due => b.dueCount.compareTo(a.dueCount),
+      progress => _byMastery(a, b),
     };
     if (byKey != 0) return byKey;
     final byPosition = a.siblingPosition.compareTo(b.siblingPosition);
     if (byPosition != 0) return byPosition;
     return a.id.compareTo(b.id);
   }
+
+  /// Compares the fractions by cross-multiplication, so 1/2 and 2/4 are
+  /// equal without floating point (BR-DECK-027).
+  static int _byMastery(DeckTile a, DeckTile b) {
+    final aEmpty = a.cardCount == 0;
+    final bEmpty = b.cardCount == 0;
+    if (aEmpty || bEmpty) return aEmpty == bEmpty ? 0 : (aEmpty ? 1 : -1);
+    return (a.masteredCount * b.cardCount).compareTo(
+      b.masteredCount * a.cardCount,
+    );
+  }
 }
 
 /// Which decks of a level are shown (IT-DISC-003).
```

`lib/features/deck/presentation/widgets/overlays/deck_level_query_sheets_widget.dart`:

```diff
@@ -27,12 +27,13 @@ class DeckSortFilterSheetWidget extends ConsumerWidget {
 
   final String? parentId;
 
-  /// The handoff's order: manual, date added, name, most due.
+  /// The handoff's order: manual, date added, name, most due, progress.
   static const _sorts = [
     DeckLevelSort.manual,
     DeckLevelSort.recent,
     DeckLevelSort.name,
     DeckLevelSort.due,
+    DeckLevelSort.progress,
   ];
 
   DeckLevelQuery _query(WidgetRef ref) =>
@@ -74,7 +75,6 @@ class DeckSortFilterSheetWidget extends ConsumerWidget {
               description: _hint(l10n, sort),
               isSelected: sort == query.sort,
               onSelected: () => _query(ref).sortBy(sort),
-              // The progress sort waits under Coming soon (spec A4, amended).
               hasDivider: sort != _sorts.last,
             ),
           Padding(
@@ -117,5 +117,6 @@ class DeckSortFilterSheetWidget extends ConsumerWidget {
         DeckLevelSort.recent => l10n.deckSortRecentHint,
         DeckLevelSort.name => l10n.deckSortNameHint,
         DeckLevelSort.due => null,
+        DeckLevelSort.progress => l10n.deckSortProgressHint,
       };
 }
```

`lib/features/deck/presentation/widgets/support/deck_level_query_label_widget.dart`:

```diff
@@ -8,5 +8,6 @@ extension DeckLevelQueryLabel on AppLocalizations {
     DeckLevelSort.name => deckSortName,
     DeckLevelSort.recent => deckSortRecent,
     DeckLevelSort.due => deckSortDue,
+    DeckLevelSort.progress => deckSortProgress,
   };
 }
```

`lib/l10n/app_en.arb`:

```diff
@@ -140,6 +140,10 @@
   "@deckSortDue": {
     "description": "Deck order: most due cards first."
   },
+  "deckSortProgress": "Progress",
+  "@deckSortProgress": {
+    "description": "Deck order: least mastered first (BR-DECK-027)."
+  },
   "deckCreateRootTitle": "New deck",
   "@deckCreateRootTitle": {
     "description": "Title of the new top-level deck dialog."
@@ -1848,6 +1852,10 @@
   "@deckSortNameHint": {
     "description": "Screen handoff 01/04 (library alignment phase C): deckSortNameHint."
   },
+  "deckSortProgressHint": "Least mastered first",
+  "@deckSortProgressHint": {
+    "description": "Screen handoff 01: the Progress sort's sub-line (BR-DECK-027)."
+  },
   "deckFilterDueOnlyTitle": "Only decks with due cards",
   "@deckFilterDueOnlyTitle": {
     "description": "Screen handoff 01/04 (library alignment phase C): deckFilterDueOnlyTitle."
```

`lib/l10n/app_vi.arb`:

```diff
@@ -30,6 +30,7 @@
   "deckSortName": "Tên",
   "deckSortRecent": "Mới tạo",
   "deckSortDue": "Nhiều thẻ đến hạn",
+  "deckSortProgress": "Tiến độ",
   "deckCreateRootTitle": "Bộ thẻ mới",
   "deckNameHint": "Tên bộ thẻ",
   "deckSchedulerEightBox": "Tám hộp",
@@ -348,6 +349,7 @@
   "deckSortManualHint": "Kéo bộ thẻ để xếp",
   "deckSortRecentHint": "Mới nhất trước",
   "deckSortNameHint": "A → Z",
+  "deckSortProgressHint": "Ít thuộc nhất trước",
   "deckFilterDueOnlyTitle": "Chỉ bộ thẻ có thẻ đến hạn",
   "deckFilterDueOnlyBody": "Ẩn bộ thẻ không có gì đang chờ",
   "commonDone": "Xong",
```


Then regenerate: `dart run build_runner build --delete-conflicting-outputs && flutter gen-l10n`.

- [ ] **Step 4: Run the tests to see them pass**

Run: `flutter test --exclude-tags golden test/features/deck`
Expected: `All tests passed!` The deck goldens are left for Task 5.

- [ ] **Step 5: Commit**

```bash
git add lib/core/database lib/features/deck lib/l10n test/features/deck
git commit -m "feat(deck): count mastered cards per tile and sort by Progress (BR-DECK-026, BR-DECK-027)"
```

### Task 3: The mastery ramp's learning ink, its percent, and `MxLinearProgress.mastery`

**Files:**
- Modify: `lib/core/theme/mastery_ramp.dart`, `lib/shared/widgets/mx_linear_progress.dart`, `lib/shared/widgets/mx_mastery_donut.dart`
- Modify tests: `test/core/theme/mastery_ramp_test.dart` (rewritten), `test/shared/widgets/mx_linear_progress_test.dart`, `test/shared/widgets/mx_mastery_donut_test.dart`

**Interfaces:**
- Consumes: `MxDerivedColors.statusLearningInk` (exists), `context.derivedColors`.
- Produces: `MasteryRamp.fill(MxSemanticColors semantic, MxDerivedColors derived, double fraction) → Color?` (signature change: `MxMasteryDonut` is the only caller); `MasteryRamp.percent(double fraction) → int`; `const MxLinearProgress.mastery({Key? key, required double value})` with `bool isMastery`.

- [ ] **Step 1: Write the failing tests**


`test/core/theme/mastery_ramp_test.dart`:

```diff
@@ -1,40 +1,73 @@
 import 'package:flutter_test/flutter_test.dart';
 import 'package:memox/core/theme/app_color_schemes.dart';
 import 'package:memox/core/theme/mastery_ramp.dart';
+import 'package:memox/core/theme/mx_derived_colors.dart';
 import 'package:memox/core/theme/mx_semantic_colors.dart';
 
 void main() {
   const semantic = MxSemanticColors.light;
+  final derived = MxDerivedColors.resolve(AppColorSchemes.light, semantic);
 
   test('0% paints no fill, only the track', () {
-    expect(MasteryRamp.fill(semantic, 0), isNull);
+    expect(MasteryRamp.fill(semantic, derived, 0), isNull);
   });
 
-  test('below 34% is learning', () {
-    expect(MasteryRamp.fill(semantic, 0.01), semantic.statusLearning);
-    expect(MasteryRamp.fill(semantic, 0.3399), semantic.statusLearning);
+  test('below 34% is the learning ink (deck mastery spec R4)', () {
+    expect(
+      MasteryRamp.fill(semantic, derived, 0.01),
+      derived.statusLearningInk,
+    );
+    expect(
+      MasteryRamp.fill(semantic, derived, 0.3399),
+      derived.statusLearningInk,
+    );
+  });
+
+  test('in dark the learning ink is the kit amber itself', () {
+    const dark = MxSemanticColors.dark;
+    final darkDerived = MxDerivedColors.resolve(AppColorSchemes.dark, dark);
+    expect(MasteryRamp.fill(dark, darkDerived, 0.2), dark.statusLearning);
   });
 
   test('34% up to 67% is reviewing', () {
-    expect(MasteryRamp.fill(semantic, 0.34), semantic.statusReviewing);
-    expect(MasteryRamp.fill(semantic, 0.6699), semantic.statusReviewing);
+    expect(MasteryRamp.fill(semantic, derived, 0.34), semantic.statusReviewing);
+    expect(
+      MasteryRamp.fill(semantic, derived, 0.6699),
+      semantic.statusReviewing,
+    );
   });
 
   test('67% and above is mastered', () {
-    expect(MasteryRamp.fill(semantic, 0.67), semantic.statusMastered);
-    expect(MasteryRamp.fill(semantic, 1), semantic.statusMastered);
+    expect(MasteryRamp.fill(semantic, derived, 0.67), semantic.statusMastered);
+    expect(MasteryRamp.fill(semantic, derived, 1), semantic.statusMastered);
   });
 
   test('a fraction outside [0, 1] or NaN is rejected, not painted', () {
     for (final bad in [-0.01, 1.01, double.nan, double.infinity]) {
       expect(
-        () => MasteryRamp.fill(semantic, bad),
+        () => MasteryRamp.fill(semantic, derived, bad),
+        throwsArgumentError,
+        reason: '$bad',
+      );
+      expect(
+        () => MasteryRamp.percent(bad),
         throwsArgumentError,
         reason: '$bad',
       );
     }
   });
 
+  test('the percent never rounds to a lie: 0 only at 0, 100 only at 1 '
+      '(deck mastery spec D13)', () {
+    expect(
+      [
+        for (final f in [0.0, 0.0001, 0.004, 0.1635, 0.5, 0.996, 0.9999, 1.0])
+          MasteryRamp.percent(f),
+      ],
+      [0, 1, 1, 16, 50, 99, 99, 100],
+    );
+  });
+
   test('the track is surfaceContainerHigh (progress-track)', () {
     expect(
       MasteryRamp.track(AppColorSchemes.light),
```

`test/shared/widgets/mx_linear_progress_test.dart`:

```diff
@@ -1,5 +1,6 @@
 import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
+import 'package:memox/core/theme/mx_semantic_colors.dart';
 import 'package:memox/shared/widgets/mx_linear_progress.dart';
 
 import '../../support/widget_harness.dart';
@@ -34,6 +35,55 @@ void main() {
     handle.dispose();
   });
 
+  group('mastery (deck mastery spec D8, D13)', () {
+    Future<double> drawn(WidgetTester tester, double value) async {
+      await pumpMx(
+        tester,
+        SizedBox(width: 200, child: MxLinearProgress.mastery(value: value)),
+      );
+      await tester.pumpAndSettle();
+      return tester
+          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
+          .widthFactor!;
+    }
+
+    testWidgets('5 tall, filled in the ramp colour', (tester) async {
+      await pumpMx(
+        tester,
+        const SizedBox(width: 200, child: MxLinearProgress.mastery(value: 0.5)),
+      );
+      await tester.pumpAndSettle();
+
+      expect(tester.getSize(find.byType(MxLinearProgress)).height, 5);
+      final fill = tester.widget<ColoredBox>(
+        find.descendant(
+          of: find.byType(FractionallySizedBox),
+          matching: find.byType(ColoredBox),
+        ),
+      );
+      expect(fill.color, MxSemanticColors.light.statusReviewing);
+    });
+
+    testWidgets('any mastery shows, and a deck short of 100% never looks '
+        'full: the fill keeps its height in from either end', (tester) async {
+      expect(await drawn(tester, 0.0001), 5 / 200);
+      expect(await drawn(tester, 0.9999), 1 - 5 / 200);
+      expect(await drawn(tester, 0.5), 0.5);
+      expect(await drawn(tester, 1), 1);
+    });
+
+    testWidgets('0 paints the track alone', (tester) async {
+      expect(await drawn(tester, 0), 0);
+      expect(
+        find.descendant(
+          of: find.byType(FractionallySizedBox),
+          matching: find.byType(ColoredBox),
+        ),
+        findsNothing,
+      );
+    });
+  });
+
   test('a value outside 0 to 1 is a programming error', () {
     expect(() => MxLinearProgress(value: 1.2), throwsAssertionError);
   });
```

`test/shared/widgets/mx_mastery_donut_test.dart`:

```diff
@@ -1,6 +1,7 @@
 import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:memox/core/theme/app_color_schemes.dart';
+import 'package:memox/core/theme/mx_derived_colors.dart';
 import 'package:memox/core/theme/mx_semantic_colors.dart';
 import 'package:memox/shared/widgets/mx_mastery_donut.dart';
 
@@ -18,12 +19,13 @@ RenderObject _ring(WidgetTester tester) => tester.renderObject(
 void main() {
   final scheme = AppColorSchemes.light;
   final semantic = MxSemanticColors.light;
+  final derived = MxDerivedColors.resolve(scheme, semantic);
 
   testWidgets('56 box; the label is the percentage in the ramp colour', (
     tester,
   ) async {
     for (final (fraction, text, color) in [
-      (0.2, '20%', semantic.statusLearning),
+      (0.2, '20%', derived.statusLearningInk),
       (0.42, '42%', semantic.statusReviewing),
       (0.9, '90%', semantic.statusMastered),
     ]) {
@@ -50,7 +52,7 @@ void main() {
 
     expect(
       tester.widget<Text>(find.text('0%')).style!.color,
-      semantic.statusLearning,
+      derived.statusLearningInk,
     );
     expect(_ring(tester), paints..circle(color: scheme.surfaceContainer));
     expect(_ring(tester), isNot(paints..arc()));
@@ -66,6 +68,15 @@ void main() {
     expect(_ring(tester), paints..arc(color: semantic.statusMastered));
   });
 
+  testWidgets('the label never rounds to a lie: 99.6% reads 99%, 0.4% reads '
+      '1% (deck mastery spec D13)', (tester) async {
+    await pumpMx(tester, const MxMasteryDonut(fraction: 0.996));
+    expect(find.text('99%'), findsOneWidget);
+
+    await pumpMx(tester, const MxMasteryDonut(fraction: 0.004));
+    expect(find.text('1%'), findsOneWidget);
+  });
+
   testWidgets('at 2x the label stays inside the ring', (tester) async {
     await pumpMx(tester, const MxMasteryDonut(fraction: 1), textScale: 2);
 
```


- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/core/theme/mastery_ramp_test.dart test/shared/widgets/mx_linear_progress_test.dart test/shared/widgets/mx_mastery_donut_test.dart`
Expected: compile errors — `Too many positional arguments` on `MasteryRamp.fill`, `Member not found: 'percent'`, `Couldn't find constructor 'MxLinearProgress.mastery'`.

- [ ] **Step 3: Implement**


`lib/core/theme/mastery_ramp.dart`:

```diff
@@ -1,4 +1,5 @@
 import 'package:flutter/material.dart';
+import 'package:memox/core/theme/mx_derived_colors.dart';
 import 'package:memox/core/theme/mx_semantic_colors.dart';
 
 /// The single-colour mastery ramp (V3 MasteryRamp utility). One threshold
@@ -12,17 +13,34 @@ abstract final class MasteryRamp {
   static const double _masteredFrom = 0.67;
 
   /// The flat fill for [fraction] in `[0, 1]`, or null at 0, where only the
-  /// track is painted. Never a gradient.
-  static Color? fill(MxSemanticColors semantic, double fraction) {
+  /// track is painted. Never a gradient. The learning band is the learning
+  /// ink: the kit's amber is 1.73:1 on the track in light (deck mastery
+  /// spec R4); in dark the ink is the amber itself.
+  static Color? fill(
+    MxSemanticColors semantic,
+    MxDerivedColors derived,
+    double fraction,
+  ) {
     if (fraction.isNaN || fraction < 0 || fraction > 1) {
       throw ArgumentError.value(fraction, 'fraction', 'must be within [0, 1]');
     }
     if (fraction == 0) return null;
-    if (fraction < _reviewingFrom) return semantic.statusLearning;
+    if (fraction < _reviewingFrom) return derived.statusLearningInk;
     if (fraction < _masteredFrom) return semantic.statusReviewing;
     return semantic.statusMastered;
   }
 
+  /// [fraction] as a whole percent that never rounds to a lie: 0 only at 0,
+  /// 100 only at 1, and 1…99 between (deck mastery spec D13).
+  static int percent(double fraction) {
+    if (fraction.isNaN || fraction < 0 || fraction > 1) {
+      throw ArgumentError.value(fraction, 'fraction', 'must be within [0, 1]');
+    }
+    if (fraction == 0) return 0;
+    if (fraction == 1) return 100;
+    return (fraction * 100).round().clamp(1, 99);
+  }
+
   /// The unfilled track (progress-track = surfaceContainerHigh).
   static Color track(ColorScheme scheme) => scheme.surfaceContainerHigh;
 }
```

`lib/shared/widgets/mx_linear_progress.dart`:

```diff
@@ -4,40 +4,68 @@ import 'package:memox/core/theme/foundations/app_radius.dart';
 import 'package:memox/core/theme/mastery_ramp.dart';
 import 'package:memox/core/theme/theme_context.dart';
 
-/// A thin progress track (FE-A8 H2): the fill eases to [value] in primary
-/// over the progress track, at once under Remove animations. Decorative:
-/// the text beside it states the fraction, so it says nothing to TalkBack.
-/// Screens 13 and 14 draw it for a session's progress.
+/// A thin progress track (FE-A8 H2): the fill eases to [value] over the
+/// progress track, at once under Remove animations. Decorative: the text
+/// beside it, or its row's semantics, states the fraction, so it says
+/// nothing to TalkBack. Screens 13 and 14 draw it in primary for a
+/// session's progress; screen 01 draws [MxLinearProgress.mastery] for a
+/// deck's mastery.
 class MxLinearProgress extends StatelessWidget {
   const MxLinearProgress({super.key, required this.value})
-    : assert(value >= 0 && value <= 1, 'value is a fraction in [0, 1]');
+    : isMastery = false,
+      assert(value >= 0 && value <= 1, 'value is a fraction in [0, 1]');
+
+  /// The deck mastery bar (deck mastery spec D8, D13): 5 tall, filled in
+  /// the MasteryRamp colour. Some mastery always shows, and a deck not
+  /// wholly mastered never looks full: the fill keeps at least its height
+  /// in from either end.
+  const MxLinearProgress.mastery({super.key, required this.value})
+    : isMastery = true,
+      assert(value >= 0 && value <= 1, 'value is a fraction in [0, 1]');
 
   final double value;
+  final bool isMastery;
 
   static const double _height = 4;
+  static const double _masteryHeight = 5;
+
+  double get _barHeight => isMastery ? _masteryHeight : _height;
+
+  /// The width factor drawn for [fraction] on a bar [width] wide.
+  double _factor(double fraction, double width) {
+    if (!isMastery || fraction <= 0 || fraction >= 1) return fraction;
+    final inset = _barHeight / width;
+    if (inset >= 0.5) return 0.5;
+    return fraction.clamp(inset, 1 - inset);
+  }
 
   @override
   Widget build(BuildContext context) {
     final colors = context.colors;
+    final fill = isMastery
+        ? MasteryRamp.fill(context.semanticColors, context.derivedColors, value)
+        : colors.primary;
     return ExcludeSemantics(
       child: ClipRRect(
         borderRadius: BorderRadius.circular(AppRadius.full),
         child: SizedBox(
-          height: _height,
+          height: _barHeight,
           child: ColoredBox(
             color: MasteryRamp.track(colors),
-            child: Align(
-              alignment: AlignmentDirectional.centerStart,
-              child: TweenAnimationBuilder<double>(
-                tween: Tween(end: value),
-                duration: MediaQuery.disableAnimationsOf(context)
-                    ? Duration.zero
-                    : AppDurations.standard,
-                curve: Easing.standard,
-                builder: (context, fraction, _) => FractionallySizedBox(
-                  widthFactor: fraction,
-                  heightFactor: 1,
-                  child: ColoredBox(color: colors.primary),
+            child: LayoutBuilder(
+              builder: (context, constraints) => Align(
+                alignment: AlignmentDirectional.centerStart,
+                child: TweenAnimationBuilder<double>(
+                  tween: Tween(end: value),
+                  duration: MediaQuery.disableAnimationsOf(context)
+                      ? Duration.zero
+                      : AppDurations.standard,
+                  curve: Easing.standard,
+                  builder: (context, fraction, _) => FractionallySizedBox(
+                    widthFactor: _factor(fraction, constraints.maxWidth),
+                    heightFactor: 1,
+                    child: fill == null ? null : ColoredBox(color: fill),
+                  ),
                 ),
               ),
             ),
```

`lib/shared/widgets/mx_mastery_donut.dart`:

```diff
@@ -34,11 +34,14 @@ class MxMasteryDonut extends StatelessWidget {
   @override
   Widget build(BuildContext context) {
     final semantic = context.semanticColors;
+    final derived = context.derivedColors;
     // Ruling S10: 0% falls in the lowest band, so its label takes that colour.
-    final ink = MasteryRamp.fill(semantic, fraction) ?? semantic.statusLearning;
+    final ink =
+        MasteryRamp.fill(semantic, derived, fraction) ??
+        derived.statusLearningInk;
     final percent = NumberFormat.percentPattern(
       Localizations.localeOf(context).toString(),
-    ).format(fraction);
+    ).format(MasteryRamp.percent(fraction) / 100);
     final donut = SizedBox.square(
       dimension: _box,
       child: CustomPaint(
```


- [ ] **Step 4: Run the tests to see them pass**

Run: `flutter test test/core test/shared --exclude-tags golden`
Expected: `All tests passed!` (`mx_workload_donut_light.png` and the card list goldens change colour in the learning band; Task 5 regenerates them).

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme lib/shared/widgets test/core/theme test/shared/widgets
git commit -m "feat(shared): the mastery ramp's learning ink and percent, and MxLinearProgress.mastery (spec R4, D13)"
```

### Task 4: Screen 01's mastery bar and summary donut

**Files:**
- Modify: `lib/features/deck/presentation/widgets/items/deck_row_widget.dart`, `lib/features/deck/presentation/widgets/sections/deck_summary_card_widget.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Modify tests: `test/features/deck/presentation/deck_row_widget_test.dart`, `test/features/deck/presentation/open_deck_screen_test.dart`

**Interfaces:**
- Consumes: `DeckTile.masteryFraction`, `DeckLevel.masteryFraction` (Task 2); `MasteryRamp.percent`, `MxLinearProgress.mastery` (Task 3); `MxMasteryDonut(fraction:, semanticLabel:)`; l10n `cardStatusMastered` (exists).
- Produces: l10n `deckRowMastered(int percent)`, `deckSummaryMastered(String algorithm)`.

- [ ] **Step 1: Write the failing tests**


`test/features/deck/presentation/deck_row_widget_test.dart`:

```diff
@@ -6,6 +6,7 @@ import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
 import 'package:memox/l10n/generated/app_localizations.dart';
 import 'package:memox/shared/widgets/mx_badge.dart';
 import 'package:memox/shared/widgets/mx_card.dart';
+import 'package:memox/shared/widgets/mx_linear_progress.dart';
 
 import '../../../support/library_harness.dart';
 
@@ -18,6 +19,7 @@ DeckTile _tile({
   int cards = 1248,
   int overdue = 41,
   int today = 45,
+  int mastered = 0,
 }) => DeckTile(
   id: 'k',
   name: name,
@@ -29,7 +31,7 @@ DeckTile _tile({
   newCount: 0,
   overdueCount: overdue,
   dueTodayCount: today,
-  masteredCount: 0,
+  masteredCount: mastered,
   oldestDueAt: overdue > 0 ? DateTime(2026, 9, 20) : null,
   startOfToday: _today,
 );
@@ -89,6 +91,31 @@ void main() {
     expect(find.text(_en.deckRowEmpty), findsOneWidget);
   });
 
+  libraryTest('the mastery bar fills to the mastered share and the row says '
+      'the percent (BR-DECK-026)', (tester, env) async {
+    final handle = tester.ensureSemantics();
+    await pump(tester, env, _tile(mastered: 204));
+
+    final bar = tester.widget<MxLinearProgress>(find.byType(MxLinearProgress));
+    expect((bar.isMastery, bar.value), (true, 204 / 1248));
+    expect(
+      find.bySemanticsLabel(RegExp(_en.deckRowMastered(16))),
+      findsOneWidget,
+    );
+    handle.dispose();
+  });
+
+  libraryTest('a deck with no card draws the bare track and says no percent '
+      '(BR-DECK-026)', (tester, env) async {
+    final handle = tester.ensureSemantics();
+    await pump(tester, env, _tile(subDecks: 0, cards: 0, overdue: 0, today: 0));
+
+    final bar = tester.widget<MxLinearProgress>(find.byType(MxLinearProgress));
+    expect(bar.value, 0);
+    expect(find.bySemanticsLabel(RegExp('mastered')), findsNothing);
+    handle.dispose();
+  });
+
   libraryTest('⋮ is its own button, named for the deck', (tester, env) async {
     var more = 0;
     await pump(tester, env, _tile(), onMore: () => more++);
```

`test/features/deck/presentation/open_deck_screen_test.dart`:

```diff
@@ -10,6 +10,7 @@ import 'package:memox/shared/widgets/mx_button.dart';
 import 'package:memox/shared/widgets/mx_dialog.dart';
 import 'package:memox/shared/widgets/mx_fab.dart';
 import 'package:memox/shared/widgets/mx_list_section_header.dart';
+import 'package:memox/shared/widgets/mx_mastery_donut.dart';
 import 'package:memox/shared/widgets/mx_toggle.dart';
 
 import '../../../support/card_fixtures.dart';
@@ -281,6 +282,28 @@ void main() {
     expect(studied, [korean.id]);
   });
 
+  libraryTest('the summary shows the level mastery donut beside "Mastered · '
+      '{algorithm}" (BR-DECK-026)', (tester, env) async {
+    final korean = await env.decks.root('Korean');
+    final words = await env.decks.sub(korean.id, 'Words');
+    await env.decks.sub(korean.id, 'Grammar');
+    await insertCard(
+      env.db,
+      id: 'known',
+      deckId: words.id,
+      learnedAt: DateTime(2026, 5, 1),
+      dueAt: DateTime(2026, 10, 30),
+      box: 8,
+    );
+    await insertCard(env.db, id: 'fresh', deckId: words.id);
+    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
+
+    final donut = tester.widget<MxMasteryDonut>(find.byType(MxMasteryDonut));
+    expect(donut.fraction, 0.5);
+    final overline = _en.deckSummaryMastered(_en.deckSchedulerEightBox);
+    expect(find.text(overline.toUpperCase()), findsOneWidget);
+  });
+
   libraryTest('the summary counts every sub-deck under the due filter', (
     tester,
     env,
```

`test/features/deck/presentation/open_deck_screen_test.dart`:

```diff
@@ -304,6 +304,28 @@ void main() {
     expect(find.text(overline.toUpperCase()), findsOneWidget);
   });
 
+  libraryTest('the summary with its donut holds at text scale 2 on a 360 '
+      'phone', (tester, env) async {
+    final korean = await env.decks.root('Korean');
+    final words = await env.decks.sub(korean.id, 'Words');
+    await insertCard(
+      env.db,
+      id: 'late',
+      deckId: words.id,
+      learnedAt: DateTime(2026, 9, 1),
+      dueAt: DateTime(2026, 9, 22),
+    );
+    await pumpLibraryScreen(
+      tester,
+      env,
+      deckScreen(deckId: korean.id),
+      textScale: 2,
+    );
+
+    expect(find.byType(MxMasteryDonut), findsOneWidget);
+    expect(tester.takeException(), isNull);
+  });
+
   libraryTest('the summary counts every sub-deck under the due filter', (
     tester,
     env,
```


- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/deck/presentation/deck_row_widget_test.dart test/features/deck/presentation/open_deck_screen_test.dart`
Expected: compile errors — `The getter 'deckRowMastered' isn't defined`, `The getter 'deckSummaryMastered' isn't defined`.

- [ ] **Step 3: Implement**


`lib/features/deck/presentation/widgets/items/deck_row_widget.dart`:

```diff
@@ -1,6 +1,7 @@
 import 'package:flutter/material.dart';
 import 'package:memox/core/theme/foundations/app_icons.dart';
 import 'package:memox/core/theme/foundations/app_spacing.dart';
+import 'package:memox/core/theme/mastery_ramp.dart';
 import 'package:memox/core/theme/theme_context.dart';
 import 'package:memox/features/deck/domain/models/deck_level_model.dart';
 import 'package:memox/l10n/generated/app_localizations.dart';
@@ -9,11 +10,12 @@ import 'package:memox/shared/widgets/mx_badge.dart';
 import 'package:memox/shared/widgets/mx_card.dart';
 import 'package:memox/shared/widgets/mx_icon_button.dart';
 import 'package:memox/shared/widgets/mx_icon_tile.dart';
+import 'package:memox/shared/widgets/mx_linear_progress.dart';
 import 'package:memox/shared/widgets/mx_row_ink.dart';
 
 /// One deck of a level (screen 01): a card with the deck's tile, its name,
-/// "N due" when cards wait, what it holds, and ⋮ for its commands. A tap
-/// anywhere else opens it.
+/// "N due" when cards wait, what it holds, its mastery bar (BR-DECK-026),
+/// and ⋮ for its commands. A tap anywhere else opens it.
 class DeckRowWidget extends StatelessWidget {
   const DeckRowWidget({
     super.key,
@@ -63,30 +65,37 @@ class DeckRowWidget extends StatelessWidget {
               MxIconTile(icon: _glyph, size: MxIconTileSize.large),
               Expanded(
                 child: Column(
-                  crossAxisAlignment: CrossAxisAlignment.start,
-                  spacing: AppSpacing.micro,
+                  crossAxisAlignment: CrossAxisAlignment.stretch,
+                  spacing: AppSpacing.grouped,
                   children: [
-                    Row(
-                      spacing: AppSpacing.control,
+                    Column(
+                      crossAxisAlignment: CrossAxisAlignment.start,
+                      spacing: AppSpacing.micro,
                       children: [
-                        Expanded(
-                          child: Text(
-                            tile.name,
-                            maxLines: 1,
-                            overflow: TextOverflow.ellipsis,
-                            style: context.textStyles.rowTitle,
-                          ),
+                        Row(
+                          spacing: AppSpacing.control,
+                          children: [
+                            Expanded(
+                              child: Text(
+                                tile.name,
+                                maxLines: 1,
+                                overflow: TextOverflow.ellipsis,
+                                style: context.textStyles.rowTitle,
+                              ),
+                            ),
+                            if (tile.dueCount > 0)
+                              MxBadge(label: l10n.deckDueBadge(tile.dueCount)),
+                          ],
+                        ),
+                        Text(
+                          _meta(l10n),
+                          maxLines: 1,
+                          overflow: TextOverflow.ellipsis,
+                          style: context.textStyles.rowSubtitle,
                         ),
-                        if (tile.dueCount > 0)
-                          MxBadge(label: l10n.deckDueBadge(tile.dueCount)),
                       ],
                     ),
-                    Text(
-                      _meta(l10n),
-                      maxLines: 1,
-                      overflow: TextOverflow.ellipsis,
-                      style: context.textStyles.rowSubtitle,
-                    ),
+                    _MasteryBar(fraction: tile.masteryFraction),
                   ],
                 ),
               ),
@@ -102,3 +111,21 @@ class DeckRowWidget extends StatelessWidget {
     );
   }
 }
+
+/// The deck's mastery (BR-DECK-026): the bar is silent, so the row says the
+/// percent; a deck with no card draws the bare track and says nothing.
+class _MasteryBar extends StatelessWidget {
+  const _MasteryBar({required this.fraction});
+
+  final double? fraction;
+
+  @override
+  Widget build(BuildContext context) {
+    final value = fraction;
+    if (value == null) return const MxLinearProgress.mastery(value: 0);
+    return Semantics(
+      label: context.l10n.deckRowMastered(MasteryRamp.percent(value)),
+      child: MxLinearProgress.mastery(value: value),
+    );
+  }
+}
```

`lib/features/deck/presentation/widgets/sections/deck_summary_card_widget.dart`:

```diff
@@ -8,11 +8,12 @@ import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
 import 'package:memox/l10n/l10n_context.dart';
 import 'package:memox/shared/widgets/mx_button.dart';
 import 'package:memox/shared/widgets/mx_card.dart';
+import 'package:memox/shared/widgets/mx_mastery_donut.dart';
 import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';
 
-/// An open deck of decks at a glance (screen 01): its algorithm, what it
-/// holds, today's work with what is scheduled, and Study this deck while
-/// anything waits (FE-A6 D10). No mastery until BE-A7 (spec A5).
+/// An open deck of decks at a glance (screen 01): its mastery donut
+/// (BR-DECK-026) beside its algorithm, what it holds, today's work with what
+/// is scheduled, and Study this deck while anything waits (FE-A6 D10).
 class DeckSummaryCardWidget extends StatelessWidget {
   const DeckSummaryCardWidget({
     super.key,
@@ -33,46 +34,65 @@ class DeckSummaryCardWidget extends StatelessWidget {
     final styles = context.textStyles;
     final due = level.overdueCount + level.dueTodayCount;
     final cards = due + level.newCount + level.scheduledCount;
+    final overline = l10n.deckSummaryMastered(
+      l10n.schedulerType(schedulerType),
+    );
     return MxCard(
       isHero: true,
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
-        spacing: AppSpacing.micro,
+        spacing: AppSpacing.grouped,
         children: [
-          Text(
-            l10n.schedulerType(schedulerType).toUpperCase(),
-            style: styles.overline,
-          ),
-          Text(
-            l10n.deckRowMeta(
-              l10n.deckSubDeckCount(level.deckCount),
-              l10n.deckCardCount(cards),
-            ),
-            style: styles.rowTitle,
-          ),
-          MxWorkloadBreakdownLine(
-            overdueCount: level.overdueCount,
-            todayCount: level.dueTodayCount,
-            newCount: level.newCount,
-            overdueLabel: l10n.workloadOverdue,
-            todayLabel: l10n.workloadToday,
-            newLabel: l10n.workloadNew,
-            fallback: cards == 0
-                ? l10n.workloadNoCards
-                : l10n.workloadNothingDue(cards),
-            suffix: level.scheduledCount > 0
-                ? l10n.deckScheduledCount(level.scheduledCount)
-                : null,
+          Row(
+            spacing: AppSpacing.gutter,
+            children: [
+              MxMasteryDonut(
+                fraction: level.masteryFraction,
+                semanticLabel: l10n.cardStatusMastered,
+              ),
+              Expanded(
+                child: Column(
+                  crossAxisAlignment: CrossAxisAlignment.start,
+                  spacing: AppSpacing.micro,
+                  children: [
+                    Text(
+                      overline.toUpperCase(),
+                      semanticsLabel: overline,
+                      style: styles.compactOverline,
+                    ),
+                    Text(
+                      l10n.deckRowMeta(
+                        l10n.deckSubDeckCount(level.deckCount),
+                        l10n.deckCardCount(cards),
+                      ),
+                      style: styles.rowTitle,
+                    ),
+                    MxWorkloadBreakdownLine(
+                      overdueCount: level.overdueCount,
+                      todayCount: level.dueTodayCount,
+                      newCount: level.newCount,
+                      overdueLabel: l10n.workloadOverdue,
+                      todayLabel: l10n.workloadToday,
+                      newLabel: l10n.workloadNew,
+                      fallback: cards == 0
+                          ? l10n.workloadNoCards
+                          : l10n.workloadNothingDue(cards),
+                      suffix: level.scheduledCount > 0
+                          ? l10n.deckScheduledCount(level.scheduledCount)
+                          : null,
+                    ),
+                  ],
+                ),
+              ),
+            ],
           ),
-          if (onStudy != null && due + level.newCount > 0) ...[
-            const SizedBox(height: AppSpacing.control),
+          if (onStudy != null && due + level.newCount > 0)
             MxButton(
               label: due > 0 ? l10n.studyThisDeckDue(due) : l10n.studyThisDeck,
               icon: AppIcons.play,
               isBlock: true,
               onPressed: onStudy,
             ),
-          ],
         ],
       ),
     );
```

`lib/l10n/app_en.arb`:

```diff
@@ -1804,7 +1804,25 @@
   "deckRowEmpty": "Empty · add cards or a sub-deck",
   "@deckRowEmpty": {
     "description": "Screen handoff 01/04 (library alignment phase C): deckRowEmpty."
+  },  "deckRowMastered": "{percent}% mastered",
+  "@deckRowMastered": {
+    "placeholders": {
+      "percent": {
+        "type": "int"
+      }
+    },
+    "description": "Screen handoff 01: what a deck row's mastery bar says to TalkBack (BR-DECK-026)."
+  },
+  "deckSummaryMastered": "Mastered · {algorithm}",
+  "@deckSummaryMastered": {
+    "placeholders": {
+      "algorithm": {
+        "type": "String"
+      }
+    },
+    "description": "Screen handoff 01: the open deck's summary overline beside the mastery donut."
   },
+
   "deckDueBadge": "{count} due",
   "@deckDueBadge": {
     "placeholders": {
```

`lib/l10n/app_vi.arb`:

```diff
@@ -341,6 +341,8 @@
   "deckCardCount": "{count} thẻ",
   "deckRowMeta": "{subDecks} · {cards}",
   "deckRowEmpty": "Trống · thêm thẻ hoặc bộ thẻ con",
+  "deckRowMastered": "Đã thuộc {percent}%",
+  "deckSummaryMastered": "Đã thuộc · {algorithm}",
   "deckDueBadge": "{count} đến hạn",
   "deckMoreActions": "Thêm thao tác cho {name}",
   "deckSortPillDueOnly": "{sort} · Chỉ đến hạn",
```


Then `flutter gen-l10n`.

- [ ] **Step 4: Run the tests to see them pass**

Run: `flutter test --exclude-tags golden test/features/deck`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/deck lib/l10n test/features/deck
git commit -m "feat(deck): screen 01's mastery bar and the summary's donut (BR-DECK-026)"
```

### Task 5: Goldens, screen 01's handoff, the checklist, the WBS and UI-base §9

**Files:**
- Modify tests: `test/features/deck/presentation/deck_level_screen_golden_test.dart` (a seed with one deck per ramp band, and a new sort-sheet golden), `test/features/deck/presentation/deck_screens_golden_test.dart` (one mastered card in the seed)
- Regenerate goldens: `test/features/deck/presentation/goldens/library_*` (new: `library_sort_{light,dark}.png`), `test/features/card/presentation/goldens/card_list*_light.png`, `card_tag_filter_*_light.png`, `test/shared/widgets/goldens/mx_workload_donut_light.png`
- Modify docs: `docs/shared/ui/screen-handoff/01-deck-list.md`, `docs/shared/ui/screen-state-checklist.md`, `docs/wbs_BE.md`, `docs/wbs_FE.md`, `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`

**Interfaces:**
- Consumes: everything above. Produces: nothing new.

- [ ] **Step 1: Seed the goldens with mastered cards and add the sort-sheet golden**


`test/features/deck/presentation/deck_level_screen_golden_test.dart`:

```diff
@@ -3,36 +3,62 @@ library;
 
 import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
+import 'package:memox/l10n/generated/app_localizations.dart';
 
 import '../../../support/card_fixtures.dart';
 import '../../../support/deck_fixtures.dart';
 import '../../../support/golden_harness.dart';
 import '../../../support/library_harness.dart';
 
+final _en = lookupAppLocalizations(const Locale('en'));
+
+/// Korean (1 of 6 mastered, learning band), Kanji N5 (1 of 2, reviewing)
+/// and Hanja (1 of 1, mastered): one deck per MasteryRamp band.
+Future<void> _seed(LibraryEnv env) async {
+  final korean = await env.decks.root('Korean');
+  final kanji = await env.decks.root('Kanji N5');
+  final hanja = await env.decks.root('Hanja');
+  final words = await env.decks.sub(korean.id, 'Words');
+  final radicals = await env.decks.sub(kanji.id, 'Radicals');
+  final basics = await env.decks.sub(hanja.id, 'Basics');
+  for (var i = 0; i < 3; i++) {
+    await insertCard(
+      env.db,
+      id: 'late$i',
+      deckId: words.id,
+      learnedAt: DateTime(2026, 9, 1),
+      dueAt: DateTime(2026, 9, 20),
+    );
+  }
+  await insertCard(
+    env.db,
+    id: 'today',
+    deckId: words.id,
+    learnedAt: DateTime(2026, 9, 1),
+    dueAt: DateTime(2026, 9, 24),
+  );
+  await insertCard(env.db, id: 'new', deckId: words.id);
+  await insertCard(env.db, id: 'fresh', deckId: radicals.id);
+  for (final (id, deckId) in [
+    ('known', words.id),
+    ('radical', radicals.id),
+    ('hanja', basics.id),
+  ]) {
+    await insertCard(
+      env.db,
+      id: id,
+      deckId: deckId,
+      learnedAt: DateTime(2026, 5, 1),
+      dueAt: DateTime(2026, 10, 30),
+      box: 8,
+    );
+  }
+}
+
 void main() {
   for (final brightness in Brightness.values) {
     libraryTest('Library with decks, ${brightness.name}', (tester, env) async {
-      final korean = await env.decks.root('Korean');
-      await env.decks.root('Kanji N5');
-      await env.decks.root('Hanja');
-      final words = await env.decks.sub(korean.id, 'Words');
-      for (var i = 0; i < 3; i++) {
-        await insertCard(
-          env.db,
-          id: 'late$i',
-          deckId: words.id,
-          learnedAt: DateTime(2026, 9, 1),
-          dueAt: DateTime(2026, 9, 20),
-        );
-      }
-      await insertCard(
-        env.db,
-        id: 'today',
-        deckId: words.id,
-        learnedAt: DateTime(2026, 9, 1),
-        dueAt: DateTime(2026, 9, 24),
-      );
-      await insertCard(env.db, id: 'new', deckId: words.id);
+      await _seed(env);
       await withRealShadows(() async {
         await pumpLibraryGolden(tester, env, deckScreen(), brightness);
         await expectBoundaryGolden(
@@ -42,6 +68,20 @@ void main() {
       });
     });
 
+    libraryTest('Library sort sheet, ${brightness.name}', (tester, env) async {
+      await _seed(env);
+      await withRealShadows(() async {
+        await pumpLibraryGolden(tester, env, deckScreen(), brightness);
+        await tester.tap(find.text(_en.deckSortManual));
+        await tester.pump();
+        await tester.pump(const Duration(milliseconds: 400));
+        await expectBoundaryGolden(
+          tester,
+          'goldens/library_sort_${brightness.name}.png',
+        );
+      });
+    });
+
     libraryTest('Library first run, ${brightness.name}', (tester, env) async {
       await withRealShadows(() async {
         await pumpLibraryGolden(tester, env, deckScreen(), brightness);
```

`test/features/deck/presentation/deck_screens_golden_test.dart`:

```diff
@@ -12,7 +12,8 @@ import '../../../support/library_harness.dart';
 
 final _en = lookupAppLocalizations(const Locale('en'));
 
-/// Korean › {Words (3 overdue, 1 today, 1 new), Grammar}; Words › Verbs.
+/// Korean › {Words (3 overdue, 1 today, 1 new, 1 mastered), Grammar};
+/// Words › Verbs.
 Future<({String korean, String words})> _seed(LibraryEnv env) async {
   final korean = await env.decks.root('Korean');
   final words = await env.decks.sub(korean.id, 'Words');
@@ -35,6 +36,14 @@ Future<({String korean, String words})> _seed(LibraryEnv env) async {
     dueAt: DateTime(2026, 9, 24),
   );
   await insertCard(env.db, id: 'new', deckId: verbs.id);
+  await insertCard(
+    env.db,
+    id: 'known',
+    deckId: verbs.id,
+    learnedAt: DateTime(2026, 5, 1),
+    dueAt: DateTime(2026, 10, 30),
+    box: 8,
+  );
   return (korean: korean.id, words: words.id);
 }
 
```


- [ ] **Step 2: Regenerate the goldens in the Linux container and read them**

Run: `TZ=UTC flutter test --tags golden --update-goldens`, then `TZ=UTC flutter test --tags golden`
Expected: `All tests passed!` (351). Check:
- `library_decks_light.png`: Korean's bar in the dark learning ink (1 / 6), Kanji N5 half in indigo, Hanja full in green.
- `library_deck_open_*.png`: the donut at 17 % beside "MASTERED · EIGHT BOXES".
- `library_sort_*.png`: Progress, "Least mastered first", last of five.
- The card list goldens change only in the donut colour.

- [ ] **Step 3: Update screen 01's handoff, the checklist, the WBS and §9**


`docs/shared/ui/screen-handoff/01-deck-list.md`:

```diff
@@ -13,7 +13,7 @@ One recursive screen for the Library root (`/decks`) and any open deck
 | Search | `MxSearchField`, trigger mode | Hint "Search decks". A tap pushes `/decks/search` (screen 04). |
 | Due strip | `MxCard` (hero) + `MxIconTile` + `MxWorkloadBreakdownLine` | Bolt tile on primary, "N cards due", overdue · today · new. Display-only until Study home (FE-A8). Hidden when the library holds no card. |
 | Section header | `MxListSectionHeader` + `MxChipTrigger` | "N DECKS"; pill "Manual ⌄", or "Manual · Due only" tinted primary with the filter on. |
-| Rows | `MxCard` per deck, 8 apart | 44 px `MxIconTile` (layers = holds decks, copy = holds cards, folder-open = empty); name on one line with ellipsis; `MxBadge` "N due" when due > 0; meta "N sub-decks · N cards" or "Empty · add cards or a sub-deck"; trailing `⋮` (`MxIconButton`). |
+| Rows | `MxCard` per deck, 8 apart | 44 px `MxIconTile` (layers = holds decks, copy = holds cards, folder-open = empty); name on one line with ellipsis; `MxBadge` "N due" when due > 0; meta "N sub-decks · N cards" or "Empty · add cards or a sub-deck"; the mastery bar (`MxLinearProgress.mastery`, 5 tall, 12 under the meta, across the text column; BR-DECK-026), the bare track for a deck with no card; trailing `⋮` (`MxIconButton`). |
 | FAB | `MxFab` | "New deck". |
 
 ## Layout — open deck
@@ -22,7 +22,7 @@ One recursive screen for the Library root (`/decks`) and any open deck
 |---|---|---|
 | App bar | `MxAppBar` | Back, deck name, `⋮` (the deck's action sheet). |
 | Breadcrumb | `MxBreadcrumb` | Library › ancestors › deck. |
-| Summary card | `MxCard` (hero) | For a deck holding sub-decks: the scheduler name ("SM-2"), "N sub-decks · N cards", overdue · today · new · N scheduled. "Study this deck · {n} due" (primary block `MxButton`; "Study this deck" when only new cards wait) opens the Study Entry, screen 14 (FE-A6 D10); hidden when the subtree holds no card to study. |
+| Summary card | `MxCard` (hero) | For a deck holding sub-decks: `MxMasteryDonut` of the level (BR-DECK-026) beside "MASTERED · {algorithm}", "N sub-decks · N cards", overdue · today · new · N scheduled. "Study this deck · {n} due" (primary block `MxButton`; "Study this deck" when only new cards wait) opens the Study Entry, screen 14 (FE-A6 D10); hidden when the subtree holds no card to study. |
 | List | as root | Header "N sub-decks" with the sort pill. |
 | FAB | `MxFab` | "New sub-deck"; none at level 10 (BR-DECK-001). |
 | By content type | — | `unset`: empty state with the two create choices (BR-DECK-007) and "Import cards from a file" (screen 11). `card`: the card list, screen 07. |
@@ -46,8 +46,8 @@ One recursive screen for the Library root (`/decks`) and any open deck
 One `MxBottomSheet`, "Sort & filter":
 
 - Sort by (`MxOptionRow`): Manual order "Drag decks to arrange them" · Date added
-  "Newest first" · Name "A → Z" · Most due cards. Progress is absent until a BR/UC
-  defines it (blocked in `wbs_BE.md`).
+  "Newest first" · Name "A → Z" · Most due cards · Progress "Least mastered first"
+  (BR-DECK-027).
 - Toggle (`MxToggle`): "Only decks with due cards" / "Hides decks where nothing is
   waiting".
 - Button "Done".
@@ -56,19 +56,19 @@ One `MxBottomSheet`, "Sort & filter":
 
 | State | Light | Dark | V8 |
 |---|---|---|---|
-| rootLoaded | ![](img/01-deck-list/rootLoaded-light.png) | ![](img/01-deck-list/rootLoaded-dark.png) | As drawn, without the mastery bars (hidden). |
+| rootLoaded | ![](img/01-deck-list/rootLoaded-light.png) | ![](img/01-deck-list/rootLoaded-dark.png) | As drawn: every row carries its mastery bar (BR-DECK-026); the learning band is the darker learning ink in light (§9 row 141). |
 | rootLoading | ![](img/01-deck-list/rootLoading-light.png) | ![](img/01-deck-list/rootLoading-dark.png) | Skeletons in the row's shape; header kept. |
 | rootEmpty | ![](img/01-deck-list/rootEmpty-light.png) | ![](img/01-deck-list/rootEmpty-dark.png) | As drawn: "Create deck", then "Browse starter decks" (screen 03), and the footnote (FE-B4 §5.4). |
 | rootError | ![](img/01-deck-list/rootError-light.png) | ![](img/01-deck-list/rootError-dark.png) | As drawn, with Retry. |
 | rootSearch | ![](img/01-deck-list/rootSearch-light.png) | ![](img/01-deck-list/rootSearch-dark.png) | The field is a trigger: a tap opens screen 04 instead of typing here. |
-| rootSortFilter | ![](img/01-deck-list/rootSortFilter-light.png) | ![](img/01-deck-list/rootSortFilter-dark.png) | No "Progress" sort: it waits for a BR/UC. |
+| rootSortFilter | ![](img/01-deck-list/rootSortFilter-light.png) | ![](img/01-deck-list/rootSortFilter-dark.png) | As drawn: Progress orders least mastered first, decks with no card last (BR-DECK-027). |
 | rootDueEmpty | ![](img/01-deck-list/rootDueEmpty-light.png) | ![](img/01-deck-list/rootDueEmpty-dark.png) | As drawn. |
 | rootOverflow | ![](img/01-deck-list/rootOverflow-light.png) | ![](img/01-deck-list/rootOverflow-dark.png) | Rows as in "Action sheet"; Reorder added. |
 | rootCreate | ![](img/01-deck-list/rootCreate-light.png) | ![](img/01-deck-list/rootCreate-dark.png) | As drawn (BR-SRS-001). |
 | rootRename | ![](img/01-deck-list/rootRename-light.png) | ![](img/01-deck-list/rootRename-dark.png) | As drawn. |
 | rootDelete | ![](img/01-deck-list/rootDelete-light.png) | ![](img/01-deck-list/rootDelete-dark.png) | Moves to the Trash (UC-TRASH-001). The dialog has no glyph and names the deck in quotes, not bold. The confirm spins while the deck moves (FE-B1 D15). |
 | rootTrashed | ![](img/01-deck-list/rootTrashed-light.png) | ![](img/01-deck-list/rootTrashed-dark.png) | As drawn: Undo for 8 seconds, and until acted on under TalkBack (FE-B1 D3, D14). A refused Undo says why: "Can't undo. {reason} Restore it from Trash and choose a deck." |
-| deckLoaded | ![](img/01-deck-list/deckLoaded-light.png) | ![](img/01-deck-list/deckLoaded-dark.png) | No donut, no "Mastered". |
+| deckLoaded | ![](img/01-deck-list/deckLoaded-light.png) | ![](img/01-deck-list/deckLoaded-dark.png) | As drawn: the level's donut beside "MASTERED · {algorithm}"; the breakdown line ends in an ellipsis when it does not fit, as the kit's does. |
 | deckEmpty | ![](img/01-deck-list/deckEmpty-light.png) | ![](img/01-deck-list/deckEmpty-dark.png) | `unset` deck: both create choices and "Import cards from a file" (screen 11). |
 | deckMaxDepth | ![](img/01-deck-list/deckMaxDepth-light.png) | ![](img/01-deck-list/deckMaxDepth-dark.png) | No FAB. |
 | deckLoading | ![](img/01-deck-list/deckLoading-light.png) | ![](img/01-deck-list/deckLoading-dark.png) | As drawn. |
@@ -85,7 +85,8 @@ One `MxBottomSheet`, "Sort & filter":
 |---|---|---|
 | A trash glyph over the Move to Trash dialog's title, the deck's name in bold | No glyph; the name in quotes | `MxDialog` has no glyph slot; no per-site text styling |
 | "Can't undo — “{deck}” is in Trash too. Restore it from here and choose a deck." on screen 06 | "Can't undo. {reason} Restore it from Trash and choose a deck." where the deck was deleted | An Undo happens where the item was deleted; the rejection carries no deck name (FE-B1 D7) |
-| Mastery bar on every row, donut and "Mastered" on the summary | Hidden | Spec A5 (waits for a BR/UC definition, blocked in `wbs_BE.md`) |
+| The mastery bar's track is `surface-container` | `progress-track` (`surfaceContainerHigh`) | Foundations name progress-track for progress and mastery; the more visible of the two on the white card (§9 row 142) |
+| The < 34% band in the kit's amber | `statusLearningInk` in light (4.94:1 on the track); the amber itself in dark | Owner ruling R4, deck mastery spec (§9 row 141) |
 | Root search hint "Search decks, cards, tags" | "Search decks" | Spec A11 (waits for FE-A10) |
 | No reorder entry at the root | Reorder in the root deck's action sheet | Library spec D7 |
 | Layers and copy glyphs in the row's meta | Text only: "4 sub-decks · 1,248 cards" | Guard: no `Icon(color:)` in feature code |
@@ -101,15 +102,15 @@ One `MxBottomSheet`, "Sort & filter":
 
 | Element | Shown as | Waits for |
 |---|---|---|
-| Sort by progress | absent | a BR/UC definition (blocked in `wbs_BE.md`) |
-| Mastery bar, donut | hidden | a BR/UC definition (blocked in `wbs_BE.md`) |
 | Due strip tap | not interactive | FE-A8 |
 | Level-10 banner "This is level 10, the deepest a deck can go…" over sub-decks at level 10 | absent; the header says "· level 10" | a later phase (owner decision C-O6) |
 
 ## Copy
 
 - Root: "Library" · "Search decks" · "{n} cards due" · "{n} decks" · "Manual" · "Manual · Due only" · "New deck".
-- Row: "{n} due" · "{n} sub-deck(s)" · "{n} cards" · "Empty · add cards or a sub-deck" · "More actions for {name}".
+- Row: "{n} due" · "{n} sub-deck(s)" · "{n} cards" · "Empty · add cards or a sub-deck" · "More actions for {name}" · "{n}% mastered" (TalkBack only).
+- Summary: "Mastered · {algorithm}".
+- Sort: "Progress" · "Least mastered first".
 - First launch: "Start your library" · "A deck groups the sub-decks that hold your cards. Create one, or copy a starter deck to begin with content." · "Create deck" · "Browse starter decks" · "Everything stays on this device. Nothing is added until you choose."
 - Error: "Couldn't load your library" · "Your data is safe on this device. Try again in a moment."
 - Due filter, none: "Nothing due right now" · "No deck has cards waiting. The next card becomes due tomorrow at 00:00." · "Show all decks".
```

`docs/shared/ui/screen-state-checklist.md`:

```diff
@@ -32,11 +32,11 @@ Màn 14, 16, 16a và 17–21 là `aligned` trong index từ phase P5 của roadm
 
 ## Tổng hợp
 
-Kit có **26 màn, 211 state**. Xong **198**; một phần **2**; đã dựng nhưng chưa đối chiếu **0**; chưa làm **9**; không làm **2**. Màn 16a (6 state, không có trong kit) đã xong và không tính vào tổng.
+Kit có **26 màn, 211 state**. Xong **200**; một phần **0**; đã dựng nhưng chưa đối chiếu **0**; chưa làm **9**; không làm **2**. Màn 16a (6 state, không có trong kit) đã xong và không tính vào tổng.
 
 | # | Màn | Hạng mục FE | State | Xong | Một phần / chưa đối chiếu | Chưa làm | Không làm | Detail |
 |---|---|---|---|---|---|---|---|---|
-| 01 | Deck list · recursive | FE-A1 | 22 | 20 | 2 | 0 | 0 | [01-deck-list.md](screen-handoff/01-deck-list.md) |
+| 01 | Deck list · recursive | FE-A1 | 22 | 22 | 0 | 0 | 0 | [01-deck-list.md](screen-handoff/01-deck-list.md) |
 | 02 | Review algorithm & reset | FE-A4 | 9 | 9 | 0 | 0 | 0 | [02-review-algorithm.md](screen-handoff/02-review-algorithm.md) |
 | 03 | Starter decks | FE-B4 | 10 | 10 | 0 | 0 | 0 | [03-starter-decks.md](screen-handoff/03-starter-decks.md) |
 | 04 | Library search | FE-A1, FE-A10 | 5 | 5 | 0 | 0 | 0 | [04-library-search.md](screen-handoff/04-library-search.md) |
@@ -71,12 +71,12 @@ FE-A1 · [01-deck-list.md](screen-handoff/01-deck-list.md)
 
 | | State (kit) | Id ảnh | Trạng thái | Ghi chú |
 |---|---|---|---|---|
-| [~] | Root · decks | `rootLoaded` | một phần | Thanh mastery ẩn: chờ BR/UC của deck định nghĩa mastery (điểm chặn trong `wbs_BE.md`). |
+| [x] | Root · decks | `rootLoaded` | xong | Thanh mastery trên mỗi hàng (BR-DECK-026). |
 | [x] | Root · loading | `rootLoading` | xong |  |
 | [x] | Root · first launch | `rootEmpty` | xong | Create deck và "Browse starter decks" (FE-B4). |
 | [x] | Root · error | `rootError` | xong |  |
 | [x] | Root · search | `rootSearch` | xong |  |
-| [~] | Root · sort & filter | `rootSortFilter` | một phần | Chưa có sort "Progress": chờ BR/UC, cùng điểm chặn mastery. |
+| [x] | Root · sort & filter | `rootSortFilter` | xong | Có sort Progress (BR-DECK-027). |
 | [x] | Root · due filter, none | `rootDueEmpty` | xong |  |
 | [x] | Root · deck actions | `rootOverflow` | xong |  |
 | [x] | Root · create deck | `rootCreate` | xong |  |
@@ -490,3 +490,5 @@ FE-A3 · [26-language.md](screen-handoff/26-language.md)
   detail file riêng; 22 state chuyển sang xong.
 - **Cập nhật ngày 2026-09-27:** read model của phiên mang `card_limit`; `large` của màn 21
   chuyển sang xong.
+- **Cập nhật ngày 2026-09-27:** BR-DECK-026 và BR-DECK-027 định nghĩa mastery của deck;
+  `rootLoaded` và `rootSortFilter` của màn 01 chuyển sang xong.
```

`docs/wbs_BE.md`:

```diff
@@ -178,7 +178,6 @@ Không có hạng mục backend nào đang làm sau gói 12b (BE-D6).
 |---|---|---|---|
 | BE-C1 | Chưa chốt có thêm dependency collation hay không | Thứ tự sort tên deck | Chủ dự án quyết |
 | BE-C5 | Chưa chốt có chuẩn hoá Unicode (NFC) hay không, và nếu có thì bằng dependency nào | Kiểm trùng khi import, tên tag, tìm kiếm | Chủ dự án quyết; đổi phép fold là đổi dữ liệu đã lưu (`front_folded`, `back_folded`, `name_folded`), cần migration |
-| Mastery của danh sách deck | Chưa BR/UC nào nói thanh mastery, donut và dòng "Mastered" của màn 01 đếm gì, cũng như sort "tiến độ" mà UC-DECK-006 nhắc tới (đang là Coming soon). Trạng thái thẻ đã có ở BR-CARD-006…BR-CARD-008, và panel "mastered" của card list (IT-ORG-010) đã dựng trên số đếm của BE-A9 | Chỉ hai phần đó của danh sách deck; không thuộc Progress (BE-A7, spec gói 4 D1) | Bổ sung định nghĩa vào BR/UC của deck trước khi làm |
 | BE-B5b | Cần dependency cho lịch nền và notification cục bộ | Thêm package vào dự án | Quyết trong spec của BE-B5b, kèm lý do và cách rollback; ứng viên ở [spec gói 11a](superpowers/specs/2026-09-26-reminders-backend-design.md) §13 |
 | BE-B5b | Container của agent không có Android SDK (`dl.google.com` bị chặn trong network policy) và không có thiết bị | Không kiểm chứng được adapter, manifest và lịch nền | Chủ dự án mở `dl.google.com` cho môi trường, hoặc làm BE-B5b trên máy có SDK và thiết bị |
 | BE-D4 | Sửa UC `ready` là sửa hợp đồng ([`docs/README.md`](README.md), mục "Hợp đồng và phạm vi sửa") | 18 UC còn thiếu | Chủ dự án nêu phạm vi file được sửa |
@@ -248,3 +247,7 @@ Không có hạng mục backend nào đang làm sau gói 12b (BE-D6).
   `tools/docs/check.py` không có lỗi; UC liên quan có `code:` và có test chứa ID.
 - **Hoãn hoặc cắt:** giữ nguyên dòng, đổi trạng thái và ghi lý do.
 - **ID hạng mục:** không đánh số lại; hạng mục mới lấy số tiếp theo trong nhóm của nó.
+- **Cập nhật ngày 2026-09-27:** điểm chặn "Mastery của danh sách deck" đóng: BR-DECK-026
+  (mastery = thẻ `mastered` ÷ mọi thẻ active của cây) và BR-DECK-027 (sort Progress), đếm
+  trong hai truy vấn level của deck ([spec](superpowers/specs/2026-09-27-deck-mastery-design.md));
+  không đổi schema.
```

`docs/wbs_FE.md`:

```diff
@@ -74,7 +74,7 @@ Quy ước giống [`wbs_BE.md`](wbs_BE.md):
 
 | ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
 |---|---|---|---|---|---|---|
-| FE-A1 | Thư viện: danh sách deck và deck đang mở; tạo root/deck con, sửa, xoá (kèm deletion summary), di chuyển, sắp xếp, đổi scheduler (UC-DECK-001…UC-DECK-006) | bị chặn | BE-03 | L | [PR #28](https://github.com/ntgptit/memox-v8/pull/28), [PR #29](https://github.com/ntgptit/memox-v8/pull/29); căn theo screen handoff ở FE-A11; [ui.md](features/deck/ui.md), [kịch bản IT](features/deck/it-scenarios.md) | Chức năng xong; companion `test/visual_audit/` xong ở FE-D2. Còn: panel "Mastered x/y" và sort theo progress chờ BR/UC của deck định nghĩa (điểm chặn "Mastery của danh sách deck" trong [`wbs_BE.md`](wbs_BE.md)) |
+| FE-A1 | Thư viện: danh sách deck và deck đang mở; tạo root/deck con, sửa, xoá (kèm deletion summary), di chuyển, sắp xếp, đổi scheduler (UC-DECK-001…UC-DECK-006) | xong | BE-03 | L | [PR #28](https://github.com/ntgptit/memox-v8/pull/28), [PR #29](https://github.com/ntgptit/memox-v8/pull/29); căn theo screen handoff ở FE-A11; [ui.md](features/deck/ui.md), [kịch bản IT](features/deck/it-scenarios.md) | Chức năng xong; companion `test/visual_audit/` xong ở FE-D2. Thanh mastery, donut "Mastered" và sort Progress xong theo BR-DECK-026, BR-DECK-027 ([spec](superpowers/specs/2026-09-27-deck-mastery-design.md)) |
 | FE-A2 | Card: danh sách card (filter, tìm, đếm, Select all, thao tác hàng loạt), tạo/sửa card có tag, chi tiết card và lịch sử ôn (UC-CARD-001, UC-CARD-002) | xong | BE-04, BE-05, FE-A1 | L | Danh sách: [PR #31](https://github.com/ntgptit/memox-v8/pull/31), căn màn 07 ở [PR #46](https://github.com/ntgptit/memox-v8/pull/46), [#49](https://github.com/ntgptit/memox-v8/pull/49); editor và chi tiết: [#33](https://github.com/ntgptit/memox-v8/pull/33), [#35](https://github.com/ntgptit/memox-v8/pull/35); field editor theo kit: [#51](https://github.com/ntgptit/memox-v8/pull/51), [#52](https://github.com/ntgptit/memox-v8/pull/52) | Chức năng xong; companion `test/visual_audit/` xong ở FE-D2. Còn: file chi tiết handoff cho màn 08–10 |
 | FE-A3 | Cài đặt: mặc định học, theme, ngôn ngữ, reset về mặc định. Lưu theme và ngôn ngữ thay cho theme hệ thống đang cố định trong `app.dart` (UC-SETTINGS-001; BR-SETTINGS-005, BR-SETTINGS-006) | xong | BE-A1 | M | [spec](superpowers/specs/2026-09-26-settings-ui-design.md); [plan 1: màn 23, 25, 26, `MxStepper`, theme và ngôn ngữ toàn app](superpowers/plans/2026-09-26-settings-ui.md); [plan 2: màn 15 và hai lối vào](superpowers/plans/2026-09-27-study-options-ui.md); screen handoff [15](shared/ui/screen-handoff/15-study-options.md), [23](shared/ui/screen-handoff/23-settings.md), [25](shared/ui/screen-handoff/25-theme.md), [26](shared/ui/screen-handoff/26-language.md); [ui.md](features/settings/ui.md) | — |
 | FE-A4 | Xác nhận "Đặt lại tiến độ học" trên một root deck (UC-SRS-001) | xong | BE-A2, FE-A1 | S | [ui.md](features/srs/ui.md) | Màn 02 của screen handoff, phase D của FE-A11 (#42) |
@@ -144,7 +144,6 @@ so nội dung.
 
 | Hạng mục | Điểm chặn | Ảnh hưởng | Cần gì, từ ai |
 |---|---|---|---|
-| FE-A1 (một phần) | Panel "Mastered x/y" trên danh sách deck chưa được định nghĩa | Chỉ phần panel đó | Chờ BR/UC của deck định nghĩa nó (điểm chặn "Mastery của danh sách deck" trong [`wbs_BE.md`](wbs_BE.md)) |
 | FE-C1 | Quyết định "implement the handoff as written" (spec UI base §2) giữ nguyên các token dưới ngưỡng contrast | Accessibility của toàn app | Chủ dự án quyết có sửa giá trị handoff không |
 | FE-D3 | Không có emulator hoặc thiết bị | 8 kịch bản `DEVICE-E2E` | Môi trường chạy |
 
@@ -251,3 +250,5 @@ giờ mỗi trạng thái, cộng thêm phần tương tác phức tạp.
   Progress), hai cấp `/progress` và `/progress/:deckId`; `PlaceholderScreen` đã bỏ.
 - **Cập nhật ngày 2026-09-27:** FE-B2 và FE-B4 xong trong một plan: màn 03 và 05, chip Tags
   và bộ lọc tag của màn 07, app bar và `rootEmpty` của màn 01; sheet Coming soon đã bỏ.
+- **Cập nhật ngày 2026-09-27:** FE-A1 xong: thanh mastery trên mỗi hàng deck, donut
+  "Mastered" trên tóm tắt và sort Progress của màn 01 (BR-DECK-026, BR-DECK-027).
```

`docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`:

```diff
@@ -543,6 +543,8 @@ item names where it comes from.
 | 138 | Screen 05's toasts are one sentence ("Couldn't rename tag. Nothing changed — try again in a moment.") with Retry; the kit draws a bold title line over a body | `MxSnackbarContent` has one message |
 | 139 | Screen 05's dialogs quote tag names instead of bolding them, and "Delete this tag?" has no glyph and is left-aligned | No per-site text styling; `MxDialog` has no glyph slot |
 | 140 | Screen 07's Tags chip is an `MxFilterChip`, selected with the count of tags applied, and opens the tag filter sheet, which the kit does not draw; the kit's chip is a ghost trigger that never reads as selected | owner 2026-09-27, FE-B2 D3, D14 |
+| 141 | `MasteryRamp`'s < 34% band resolves to `statusLearningInk`: 4.94:1 on the progress track in light, the kit amber itself in dark. The kit's amber is 1.73:1 on the track in light. Screen 01's bars and every `MxMasteryDonut` (screens 01, 07) follow; the donut's label in that band also clears row 57 | Deck mastery spec R4 (owner ruling, critique P1) |
+| 142 | Screen 01's mastery bar keeps the progress track (`surfaceContainerHigh`) where the kit draws `surface-container`; its fill keeps at least its height in from either end, and a percent reads 0 only at 0 and 100 only at 100 (`MasteryRamp.percent`) | Deck mastery spec D13 (critique P2a, P2b, P3) |
 
 Further contradictions found while implementing are appended here with the same
 rule applied. `docs/_generated/open-questions.md` is generated and is not
```


- [ ] **Step 4: Run the gate**

Run: `GUARD_PY=/usr/bin/python3.13 bash .claude/skills/flutter-workflow/scripts/dod_check.sh --force` and `/usr/bin/python3.13 tools/docs/check.py`
Expected: `✓ mechanical gates passed` with `All tests passed!` (about 2371 tests); docs check `PASS — 0 error(s)`.

- [ ] **Step 5: Commit**

```bash
git add test docs
git commit -m "docs(deck): screen 01 mastery goldens, handoff, checklist, WBS and UI-base §9"
```
