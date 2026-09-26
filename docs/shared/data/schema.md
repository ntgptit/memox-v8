# Schema

Bảng, cột, index, quan hệ và các câu query bất biến (`-- N.`) của V8. Trích dẫn
`invariant Qn` trỏ vào mục "Bất biến" dưới đây. Bảng chỉ một feature dùng nằm ở
`data.md` của feature đó: [`deck_templates`](../../features/starter-decks/data.md),
[`delete_batches`](../../features/trash/data.md).

**Tài liệu này, không phải bảng tóm tắt ở §5 của
[`superpowers/specs/2026-09-21-memox-v8-foundation-design.md`](../../superpowers/specs/2026-09-21-memox-v8-foundation-design.md),
là nguồn thẩm quyền cho data model V8.**

Đây là tài liệu thiết kế: định nghĩa bảng và các bất biến phải đúng, không phải
SQL runtime thật.

**Mỗi cột của Study tồn tại vì một luật, và đây là ánh xạ.** `rules/` của các feature
nói **hành vi** chứ không chỉ định cột — đúng phân công của hai tài liệu — nên không
tra ngược được từ cột về luật nếu không có bảng này. Người viết M5 cần chiều đó.

| Cột | Tồn tại vì |
|---|---|
| `card_schedule.learned_at` | BR-STUDY-053 (đặt), BR-STUDY-051 (chia hai tập), BR-CARD-007 (định nghĩa `new`), BR-STUDY-050 (Reset xoá) |
| `study_session.session_kind` | BR-STUDY-051 |
| `study_session.card_limit` | BR-STUDY-003, BR-STUDY-024 |
| `study_session.cursor` | BR-STUDY-005 — nền của "sau ít nhất 3 thẻ khác" |
| `study_queue_items.mode` | BR-STUDY-022 |
| `study_queue_items.round` | BR-STUDY-059, BR-STUDY-061 |
| `study_queue_items.position` | BR-STUDY-002, BR-STUDY-061 |
| `study_queue_items.available_at` | BR-STUDY-005 |
| `study_queue_items.answers_in_session` | BR-SRS-016 (lượt đầu), BR-STUDY-073 (trần 3) |
| `study_queue_items.remaining_ms` · `is_revealed` | BR-STUDY-036 |
| `study_queue_items.hint_shown` | BR-STUDY-028 |
| `study_queue_items.meaning_slot` | BR-STUDY-049 |
| `study_guess_options` | BR-STUDY-037, BR-STUDY-043 |
| `study_session.direction` | BR-MODE-013 (điều kiện), BR-MODE-015 (`mixed`), BR-MODE-017 (khoá) |
| `study_queue_items.direction` | BR-MODE-015 — gán một lần, sống qua comeback và restart |
| `review_log.direction` | BR-MODE-016 — chép từ dòng hàng đợi, không suy luận |
| `review_log.mode` | BR-MODE-008 |
| `review_log.outcome_reason` | BR-STUDY-034 |
| `review_log.comparison_version` | BR-STUDY-027 |
| `review_log.used_hint` | BR-STUDY-028 |
| `deck.study_config` | BR-STUDY-056 |
| `app_settings.card_limit` · `new_card_order` | BR-STUDY-056, BR-STUDY-057 |

Ba nguyên tắc chi phối cách chia bảng:

1. **Nội dung, trạng thái lịch, và lịch sử có ba vòng đời khác nhau**, nên là ba
   bảng. Nội dung sửa mà không đụng lịch (BR-CARD-005); lịch đổi mỗi lần ôn; lịch sử chỉ
   thêm, không bao giờ sửa.
2. **`generation` có mặt ở mọi nơi trạng thái học tồn tại**, để "thuộc
   chu kỳ nào" là dữ kiện trong dữ liệu chứ không phải quy ước ngầm.
3. **Trạng thái được lưu tường minh, không suy luận** — `kind`,
   `session.status`, `end_reason`, `content_type`, `root_id` đều là cột thật.

---

## Tổng quan

```
app_settings (một dòng — mặc định tùy chọn học)

deck_templates (sub-project sau — Starter decks; asset JSON)
        │ sao chép một lần, không liên kết ghi ngược
        ▼
     deck ──┐ parent_id  (cây nhiều cấp)
       │  ▲  │ root_id    (mọi descendant trỏ thẳng về root)
       │  └──┘
       │
       ├──► card ──┬──► card_schedule  (1–1, mang generation)
       │            └──► review_log    (1–n, append-only, mang generation)
       │
       └──► study_session ──┬──► review_log
                             └──► study_queue_items  (một hàng đợi mỗi stage, BR-STUDY-022)
                                    └──► study_guess_options  (năm lựa chọn của một câu guess)
```

---

## `deck`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID sinh phía client |
| `name` | TEXT NOT NULL | BR-DECK-020 |
| `parent_id` | TEXT NULL | NULL = root deck. → `deck(id)` ON DELETE CASCADE |
| `root_id` | TEXT NOT NULL | root có `root_id = id`; descendant mang id của root (BR-DECK-002) |
| `depth` | INTEGER NOT NULL | Root = 1. `CHECK (depth <= 10)` là an toàn tầng DB (BR-DECK-001) |
| `content_type` | TEXT NOT NULL | `'unset'` \| `'card'` \| `'deck'` (BR-DECK-006…BR-DECK-012, BR-DECK-015) |
| `owner_id` | TEXT NULL | NULL = local profile. **Phạm vi:** sub-project sau — auth |
| `scheduler_type` | TEXT NULL | `'eight_box'` \| `'sm2'`. **NOT NULL trên root, NULL trên deck con** |
| `scheduler_version` | INTEGER NULL | cùng quy tắc NULL |
| `scheduler_config` | TEXT NULL | JSON tham số ghi đè của thuật toán. Cùng quy tắc NULL |
| `study_config` | TEXT NULL | JSON tùy chọn học ghi đè mặc định toàn app (BR-STUDY-056). NULL = theo mặc định. Chỉ trên root |
| `generation` | INTEGER NULL | bắt đầu từ 1, +1 mỗi lần reset (BR-SRS-020). Chỉ trên root |
| `first_answered_at` | DATETIME NULL | NULL = chưa thẻ nào hoàn tất chuỗi học mới ở generation hiện tại → scheduler mở khoá (BR-SRS-002). Được đặt bởi chính lần hoàn tất đầu tiên, cùng transaction (BR-SRS-003, BR-STUDY-053); chỉ Reset đưa về NULL (BR-SRS-024) |
| `source_template_id` | TEXT NULL | NULL = deck tự tạo (BR-STARTER-004). **Phạm vi:** sub-project sau — Starter decks |
| `source_template_version` | INTEGER NULL | version tại thời điểm sao chép. **Phạm vi:** sub-project sau — Starter decks |
| `delete_batch_id` | TEXT NULL | NULL = deck đang active. Khác NULL = tombstone thuộc batch đó (BR-TRASH-001, BR-TRASH-003). → `delete_batches(id)` ON DELETE CASCADE, từ v3, với index `idx_deck_delete_batch`: purge batch là xoá hàng (BR-TRASH-010) |
| `sibling_position` | INTEGER NOT NULL | Thứ tự manual trong nhóm cùng `parent_id`; tie-break bằng `id` (BR-SRS-007) |
| `created_at` | DATETIME NOT NULL | UTC |
| `updated_at` | DATETIME NOT NULL | UTC |

### Duyệt cây — hai loại query, hai quy tắc

Cây có tối đa **10 cấp**, root là cấp 1 (BR-DECK-001). Hai giới hạn khác nhau chi
phối cách viết query duyệt cây:

1. **Query duyệt subtree** (`subtreeDeckIds`, `subtreeCardCount`,
   `updateSubtreeRootDeck`) MUST cycle-safe bằng
   recursive `UNION` — mỗi node chỉ đi qua một lần vì dòng trùng bị loại — và
   MUST NOT dùng depth cap để cắt kết quả. Một cap biến dữ liệu hỏng thành kết
   quả thiếu trong im lặng: card count nói dối dialog xoá, root rewrite bỏ sót
   node — chính là vi phạm mà bất biến 6 tồn tại để bắt.
2. **Query probe độ sâu** (`deckDepthProbe` — cấp của một deck, chính nó là
   bước 1; `subtreeHeightProbe` — chiều cao subtree, chính nó là 1) mang cột
   depth nên `UNION` không khử trùng được; chúng MUST nhận giới hạn duyệt qua
   **parameter** do caller suy từ hằng số domain duy nhất, và chạm giới hạn
   MUST được caller coi là lỗi (từ chối thao tác), không phải một câu trả lời
   ngắn hơn.

Giới hạn 10 cấp được cưỡng chế ở repository (`createSubDeck`, `moveDeck` —
kiểm trước mọi mutation), và kiểm tra được bằng bất biến 15. Cycle protection
là concern riêng: bất biến 8 phát hiện cycle, với safety cap riêng của một
diagnostic checker.

### `root_id` — vì sao tồn tại

Xác định root bằng cách đi ngược `parent_id` cần đệ quy, và không diễn đạt
được thành một điều kiện JOIN đơn giản — mà JOIN đó nằm trong query nóng nhất của
app.

`COALESCE(parent_id, id)` **bị cấm** (BR-DECK-003). Nó có nghĩa "cha, hoặc
chính nó nếu không có cha", nên với deck ở cấp 3 nó trả về deck cấp 2 chứ không
phải root. Với cây một cấp nó đúng — và đó chính là điều khiến nó nguy hiểm.

Cái giá: di chuyển subtree phải cập nhật `root_id` **và** `depth` cho toàn bộ
subtree trong một transaction, bằng recursive CTE (BR-DECK-018). Bỏ sót một node tạo
ra descendant trỏ sai root hoặc sai độ sâu — dữ liệu hỏng im lặng, vì query vẫn
chạy và chỉ trả về kết quả thiếu.

### `content_type` — bao gồm cả root

**Sub-deck đang `card` hoặc `deck` mà không còn direct card lẫn direct child
deck là dữ liệu không hợp lệ** (BR-DECK-015) — invariant 29 bắt nó.

`content_type` là NOT NULL cho **mọi** deck. Root deck được tạo thẳng với
`content_type = 'deck'` và giá trị đó bất biến — đó là cách BR-DECK-004 ("root chỉ chứa
deck con") trở thành một ràng buộc kiểm tra được bằng cùng một câu query như các
deck khác, thay vì một luật riêng phải nhớ.

| Deck | `content_type` khi tạo | Đổi được không |
|---|---|---|
| root | `'deck'` | không |
| deck con | `'unset'` | hệ thống tự duy trì theo direct children (BR-DECK-015): `unset` → `card`/`deck` ở phần tử con đầu tiên (BR-DECK-008); `card`/`deck` → `unset` khi direct child cuối bị xoá hoặc chuyển đi, trong cùng transaction |

### Cột scheduler chỉ trên root

Deck con để NULL và tra qua `root_id` (BR-DECK-025). Đây là cách khiến "deck con
không chọn scheduler riêng" bất khả thi về cấu trúc, thay vì chỉ là quy ước.

Index — composite, và thứ tự cột theo đúng thứ tự query lọc rồi sắp:
- `idx_deck_parent_position` trên `(parent_id, sibling_position, id)` — dựng cây
  (`rootDecks`, `childDecks`)
- `idx_deck_root_position` trên `(root_id, sibling_position, id)` — mọi query gộp
  theo cây (`decksInTree`, `allDecks`, hai subquery của `rootDeckSummaries`)

Mọi query đọc deck đều lọc theo một trong hai cột dẫn đầu rồi `ORDER BY
sibling_position, id`. Với index chỉ một cột, cả ba đều kết thúc bằng `USE TEMP B-TREE
FOR ORDER BY` — SQLite đọc hết row khớp rồi sắp, trước khi áp bất kỳ `LIMIT` nào.
Đo bằng `EXPLAIN QUERY PLAN`: thêm cột sắp vào index thì temp B-tree biến mất, và
subquery `total` của `rootDeckSummaries` trở thành **covering** (không chạm bảng).
Index composite thay thế bản một cột chứ không cộng thêm: cùng cột dẫn đầu thì nó
trả lời được mọi lookup cũ, giữ cả hai chỉ khiến mỗi insert bảo trì hai B-tree.

## `card`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID |
| `deck_id` | TEXT NOT NULL | → `deck(id)` ON DELETE CASCADE. Chỉ deck có `content_type = 'card'` (BR-DECK-009) |
| `front` | TEXT NOT NULL | BR-CARD-001, BR-CARD-002 |
| `back` | TEXT NOT NULL | BR-CARD-001, BR-CARD-002 |
| `front_folded` | TEXT NOT NULL DEFAULT '' | `front` đã trim + hạ hoa bằng Dart. Search so trên cột này |
| `back_folded` | TEXT NOT NULL DEFAULT '' | Như trên, cho `back` |
| `is_flagged` | INTEGER NOT NULL DEFAULT 0 | 0 \| 1. Cờ người dùng đánh dấu (BR-CARD-009) |
| `example` | TEXT NULL | Tuỳ chọn (BR-CARD-003) |
| `hint` | TEXT NULL | Tuỳ chọn (BR-CARD-003) |
| `pronunciation` | TEXT NULL | Tuỳ chọn (BR-CARD-003) |
| `delete_batch_id` | TEXT NULL | NULL = card đang active. Khác NULL = tombstone thuộc batch đó (BR-TRASH-001, BR-TRASH-003). → `delete_batches(id)` ON DELETE CASCADE, từ v3, với index `idx_card_delete_batch`: purge batch là xoá hàng (BR-TRASH-010) |
| `created_at` | DATETIME NOT NULL | UTC |
| `updated_at` | DATETIME NOT NULL | UTC |

**Hai cột `_folded` tồn tại vì `lower()` của SQLite chỉ hạ hoa ASCII.** Nó không
đụng tới `Ô`, `Ê`, `Đ`. Search từng so `instr(lower(front), :term)` với `:term`
đã được Dart hạ hoa theo Unicode — hai vế fold bằng hai luật khác nhau, nên thẻ
lưu `CÔNG NGHỆ` không tìm ra được bằng `công nghệ`, trong khi thẻ viết thường thì
tìm được. Fold cả hai vế trong Dart biến phép so thành byte-for-byte và đúng cho
mọi bảng chữ cái. Đây đúng là lập luận `tags.name_folded` đã dùng (BR-TAG-001),
áp cho hai mặt thẻ.

Chỉ hạ hoa, **không** bỏ dấu: `công` vẫn không khớp `cong`. Tìm kiếm không dấu là
quyết định sản phẩm (S1), không phải hệ quả phụ của một bản vá.

`DEFAULT ''` vì SQLite bắt buộc có default khi thêm cột NOT NULL. Mọi lượt ghi
đều đi qua repository và luôn ghi giá trị thật; phép tính hai cột này MUST chạy
bằng Dart chứ không phải SQL — `SET front_folded = lower(front)` sẽ ghi đúng
những giá trị hỏng mà cột này sinh ra để thay thế.

**Không có cột SRS nào ở đây**, và không có `generation` — card là nội
dung, nó sống xuyên qua mọi lần reset (BR-SRS-021). Reset learning progress không được
chạm vào bảng này.

Ba trường phụ để **NULL, không phải chuỗi rỗng**. NULL nghĩa là người dùng chưa
điền; chuỗi rỗng nghĩa là họ điền rồi xoá — và không màn nào phân biệt được hai
thứ đó, nên cho phép cả hai chỉ tạo ra hai cách biểu diễn một trạng thái. Lớp
domain trim rồi quy chuỗi rỗng về NULL trước khi ghi — cùng một điểm trim với
`front`/`back`.

`is_flagged` nằm ở đây chứ không ở `card_schedule` và đó là cùng một lập
luận: cờ là thứ người dùng đặt lên *nội dung* — "quay lại thẻ này" — nên nó phải
sống sót qua reset. Đặt nó cạnh `current_box` sẽ khiến reset xoá nó cùng lịch
(BR-CARD-009).

Index: `idx_card_deck_created` trên `(deck_id, created_at, id)` — composite,
theo đúng thứ tự `cardsByDeck` lọc rồi sắp. Đây là điều kiện để phân trang keyset
(`WHERE deck_id = ? AND (created_at, id) > (?, ?)`) là một range scan thật thay vì
một lần sắp toàn bộ deck rồi đặt `LIMIT` lên trên: đo trên 5.000 thẻ một deck, một
trang 50 thẻ đi từ 1193µs xuống 102µs.

## `tags`

**Phạm vi:** V8.0 cho việc gắn/gỡ tag trên thẻ (ADR-009 quyết định 4; chủ dự án chốt ngày 2026-09-23). Tag Management (UC-TAG-001) vẫn là sub-project sau.

Nhãn phân loại nội dung do người dùng đặt — `noun`, `people`, `verb`. Nội dung,
không phải lịch: reset giữ nguyên (BR-SRS-021, BR-TAG-001).

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID sinh phía client |
| `name` | TEXT NOT NULL | BR-TAG-001. Lưu nguyên dạng người dùng gõ |
| `name_folded` | TEXT NOT NULL | `lower(trim(name))`. Cột để **cưỡng chế** unique |
| `owner_id` | TEXT NULL | NULL = local profile |
| `created_at` | DATETIME NOT NULL | UTC |

Index: `UNIQUE (COALESCE(owner_id, ''), name_folded)`.

**`COALESCE`, không phải `(owner_id, name_folded)`**, vì SQLite coi các `NULL` là
khác nhau trong unique index: với profile cục bộ (`owner_id` NULL), `(NULL, 'noun')`
ghi hai lần vẫn lọt và BR-TAG-001 không còn được database giữ. Chủ dự án chốt ngày
2026-09-23: giữ nghĩa "NULL = local profile" như các bảng khác, chuẩn hoá NULL
ngay trong index.

**`name_folded` là một cột thật, không phải một expression index**, vì BR-TAG-001 đòi
unique không phân biệt hoa thường và SQLite chỉ có `NOCASE` cho ASCII — một tag
tiếng Việt `Động từ` và `động từ` sẽ lọt qua `COLLATE NOCASE`. Ghi cột đã fold
lúc insert thì phép so sánh là byte-với-byte và đúng cho mọi bảng chữ.

Tag **không** thuộc về một deck. Cùng một `noun` dùng lại ở mọi deck; buộc nó
theo deck sẽ sinh ra bản sao mỗi lần người dùng tạo deck mới, và lúc lọc thì
chúng là các tag khác nhau.

## `card_tags`

**Phạm vi:** V8.0 — như `tags` ở trên.

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `card_id` | TEXT NOT NULL | → `card(id)` ON DELETE CASCADE |
| `tag_id` | TEXT NOT NULL | → `tags(id)` ON DELETE CASCADE |

PK là `(card_id, tag_id)`. Index thứ hai `idx_card_tags_tag` trên `(tag_id,
card_id)` cho chiều ngược lại — "mọi thẻ mang tag này" là câu mà bộ lọc hỏi, và
PK không phục vụ được nó.

Cả hai FK đều `CASCADE`: xoá thẻ thì liên kết mất theo (BR-CARD-009 nói cùng điều đó
cho cờ), xoá tag thì nó biến khỏi mọi thẻ. Không có bản ghi mồ côi nào cần dọn.

## `card_schedule`

Một dòng cho mỗi card, tạo cùng lúc với card (BR-CARD-004). Xoá và tạo lại khi reset.

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `card_id` | TEXT PK | → `card(id)` ON DELETE CASCADE. PK vì quan hệ 1–1 |
| `scheduler_type` | TEXT NOT NULL | phải bằng scheduler của root deck |
| `scheduler_version` | INTEGER NOT NULL | |
| `generation` | INTEGER NOT NULL | phải bằng generation hiện tại của root (BR-SRS-029) |
| `learned_at` | DATETIME NULL | NULL = chưa xong chuỗi học mới (BR-STUDY-053). Đặt một lần, không bao giờ về NULL trừ khi Reset |
| `due_at` | DATETIME NULL | NULL = chưa có lịch, tức chưa học xong lần đầu. UTC |
| `last_answered_at` | DATETIME NULL | cập nhật ở cả `scheduled` lẫn `relearning` (BR-SRS-018) |
| `answer_count` | INTEGER NOT NULL DEFAULT 0 | chỉ đếm `scheduled` (BR-SRS-018) |
| `lapse_count` | INTEGER NOT NULL DEFAULT 0 | BR-SRS-018 |
| `current_box` | INTEGER NULL | **chỉ `eight_box`**: 1..8 |
| `ease_factor` | REAL NULL | **chỉ `sm2`**: mặc định 2.5, sàn 1.3 |
| `interval_days` | INTEGER NULL | **chỉ `sm2`** |
| `repetitions` | INTEGER NULL | **chỉ `sm2`** |

`scheduler_type` và `generation` lặp lại từ root là **denormalization có
chủ đích**: nó biến hai bất biến thành thứ kiểm tra được bằng query thay
vì bằng niềm tin. Query kiểm tra ở mục "Bất biến" bên dưới.

Cột riêng của từng scheduler để NULL khi không thuộc scheduler đang dùng. Phương
án gói vào JSON linh hoạt hơn nhưng mất type-safety và không query được — mâu
thuẫn trực tiếp với lý do dùng schema có kiểu tường minh thay vì JSON tự do.

Index: `idx_card_schedule_due` trên `(due_at)` — query nóng nhất của app.

## `review_log`

Append-only. Không sửa, không xoá — kể cả khi reset (BR-SRS-023). Chỉ mất khi card bị
xoá (cascade).

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID |
| `card_id` | TEXT NOT NULL | → `card(id)` ON DELETE CASCADE |
| `session_id` | TEXT NOT NULL | → `study_session(id)` |
| `scheduler_type` | TEXT NOT NULL | scheduler tại thời điểm đánh giá |
| `generation` | INTEGER NOT NULL | generation tại thời điểm đánh giá |
| `kind` | TEXT NOT NULL | `'learning'` \| `'scheduled'` \| `'relearning'` (BR-SRS-014, BR-SRS-015, BR-STUDY-052) |
| `mode` | TEXT NOT NULL | Chế độ học của lượt (BR-MODE-002, BR-MODE-008). `browse` không bao giờ xuất hiện ở đây (BR-MODE-005) |
| `outcome_reason` | TEXT NULL | `timeout` khi hết giờ ở `recall` (BR-STUDY-034); NULL khi người dùng tự trả lời |
| `comparison_version` | INTEGER NULL | chỉ `fill`: phiên bản chính sách so khớp đã dùng (BR-STUDY-027) |
| `used_hint` | INTEGER NULL | chỉ `fill`: 0 \| 1. Ghi nhận, không đổi `action` (BR-STUDY-028) |
| `direction` | TEXT NULL | `korean_to_meaning` \| `meaning_to_korean` (BR-MODE-016). NULL ở mọi lượt ngoài BR-MODE-013. **Không bao giờ `mixed`** — phiên trộn, lượt thì không (BR-MODE-015) |
| `action` | TEXT NOT NULL | `forgotten`/`remembered` hoặc `again`/`hard`/`good`/`easy` |
| `answered_at` | DATETIME NOT NULL | UTC |
| `next_due_at` | DATETIME NULL | hạn sau khi đánh giá |
| `previous_box` | INTEGER NULL | chỉ `eight_box` |
| `next_box` | INTEGER NULL | chỉ `eight_box` |
| `previous_ease_factor` | REAL NULL | chỉ `sm2` |
| `next_ease_factor` | REAL NULL | chỉ `sm2` |
| `previous_interval_days` | INTEGER NULL | chỉ `sm2` |
| `next_interval_days` | INTEGER NULL | chỉ `sm2` |

`kind` là cột thật, **không suy ra** từ việc so `previous_*` với `next_*`
(BR-SRS-015). Suy luận sai ở đúng một ca không hiếm: lượt `scheduled` trên card
ở box 8 trả lời `remembered` cũng có `previous_box == next_box == 8`.

Giữ history qua các lần reset là lý do bảng này mang `scheduler_type` và
`generation` thay vì tra ngược lên deck: deck chỉ biết generation
**hiện tại**, còn dòng history phải nói được nó thuộc chu kỳ nào theo luật nào.

Index: `idx_review_log_card` trên `(card_id, answered_at)`; `idx_review_log_session`
trên `(session_id)`.

Bảng này lớn nhanh nhất — mỗi lượt đánh giá một dòng, reset không dọn bớt. Đây là
bảng đầu tiên cần nhìn khi bàn về kích thước DB.

## `study_session`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID |
| `deck_id` | TEXT NOT NULL | → `deck(id)` ON DELETE CASCADE. Deck được ôn (thường là root hoặc một nhánh) |
| `root_id` | TEXT NOT NULL | root của cây tại thời điểm mở phiên |
| `generation` | INTEGER NOT NULL | generation lúc mở phiên (BR-SRS-025) |
| `session_kind` | TEXT NOT NULL | `learning` \| `reviewing` (BR-STUDY-051) |
| `current_mode` | TEXT NOT NULL | stage đang chạy: `browse` \| `self_assess` \| `match` \| `guess` \| `recall` \| `fill` (BR-MODE-002, BR-MODE-008). Phiên `reviewing` chỉ có một giá trị suốt phiên |
| `status` | TEXT NOT NULL | `in_progress` \| `completed` \| `abandoned` \| `invalidated` \| `failed` (BR-STUDY-010) |
| `end_reason` | TEXT NULL | `user_exit` \| `scheduler_reset` \| `scheduler_changed` \| `stale_generation` \| `persistence_error` \| `interrupted` \| `content_deleted` (BR-STUDY-012, BR-TRASH-004, BR-STUDY-016). NULL khi `in_progress` hoặc `completed`. **Phạm vi:** `content_deleted` là sub-project sau — Trash |
| `cursor` | INTEGER NOT NULL DEFAULT 0 | số lượt đã phục vụ trong phiên; nền của BR-STUDY-005 |
| `card_limit` | INTEGER NOT NULL | số thẻ tối đa của phiên, chốt lúc mở (BR-STUDY-003, BR-STUDY-024). Mặc định 20 |
| `direction` | TEXT NULL | `korean_to_meaning` \| `meaning_to_korean` \| `mixed` (BR-MODE-013, BR-MODE-015). Chốt lúc mở và khoá suốt phiên (BR-MODE-017). NULL ở mọi phiên ngoài BR-MODE-013 |
| `started_at` | DATETIME NOT NULL | UTC |
| `ended_at` | DATETIME NULL | NULL khi `in_progress` |

Ma trận `status` × `end_reason` hợp lệ:

| status | end_reason | Khi nào |
|---|---|---|
| `in_progress` | NULL | phiên đang mở |
| `completed` | NULL | hết queue (BR-STUDY-013) |
| `abandoned` | `user_exit` | người dùng thoát (BR-STUDY-014) |
| `abandoned` | `interrupted` | phiên của ngày học trước còn `in_progress` khi mở app (BR-STUDY-072) |
| `invalidated` | `scheduler_reset` | Reset learning progress chạy khi phiên đang mở (BR-STUDY-015). **Reset và chỉ reset** — `generation` bị bump |
| `invalidated` | `scheduler_changed` | đổi scheduler khi chưa khoá, phiên đang mở (BR-SRS-002, BR-STUDY-016). **Không phải reset:** generation giữ nguyên, tiến trình học không bị xoá — chỉ hàng đợi được chia lại. Tách khỏi `scheduler_reset` vì đọc riêng cột này không phân biệt được hai sự kiện, dù `generation` vẫn phân biệt được |
| `invalidated` | `stale_generation` | phiên generation cũ cố ghi lượt học (BR-STUDY-017) |
| `invalidated` | `content_deleted` | deck hoặc card mà phiên đang chạy trên đó bị chuyển vào Trash (BR-TRASH-004) |
| `failed` | `persistence_error` | lỗi không thể tiếp tục (BR-STUDY-018) |

Mọi tổ hợp khác là dữ liệu sai.

`generation` ở đây là thứ chặn tình huống: phiên mở trước khi
reset, người dùng quay lại bấm đánh giá sau khi reset. Mọi thao tác ghi so
generation của session với generation hiện tại của root và **từ chối** nếu lệch
(BR-SRS-026, BR-STUDY-017).

Các lượt học đã ghi thành công trước khi phiên kết thúc bất thường **vẫn được giữ**
(BR-STUDY-019) — chuyển `status` không kéo theo xoá `review_log`.

`interrupted` tách khỏi `user_exit` vì cùng lý do BR-SRS-015 lưu `kind` tường minh:
"người dùng bấm thoát" và "hệ điều hành thu hồi app" là hai sự kiện khác nhau, và
gộp chúng làm lịch sử nói rằng người dùng bỏ cuộc trong khi họ không hề.

**Một phiên mở trong toàn app** (quyết định chủ dự án 2026-09-24): app có tối đa một
session `in_progress`. Mở phiên mới, ở bất kỳ deck nào, đóng phiên đang mở trước trong
cùng transaction: `abandoned`/`user_exit` nếu nó bắt đầu trong ngày học hiện tại,
`abandoned`/`interrupted` nếu nó bắt đầu từ ngày học trước (BR-STUDY-072). Code và test
giữ luật này; một unique index sẽ cần một migration riêng, và chưa có.

**Phiên của một cây:** Reset và đổi scheduler của một root đóng mọi session `in_progress`
của cây đó (BR-STUDY-015, BR-STUDY-016): session mở trên chính root đó (`root_id`), và
session đang giữ trong hàng đợi một card nay thuộc cây đó. Một deck chỉ chuyển sang cây
khác khi hai root cùng scheduler và generation (BR-SRS-006), và card của nó ở lại hàng đợi
của session đang mở (IT-CONT-006). Không đóng session ấy thì mọi lượt trên các card đó bị
từ chối mãi (BR-STUDY-017) mà session vẫn mở.

## `study_queue_items`

**Phạm vi:** V8.0 — hàng đợi phiên học.

Hàng đợi của một phiên (BR-STUDY-021). Một dòng cho mỗi thẻ được nạp lúc mở phiên.

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `session_id` | TEXT NOT NULL | → `study_session(id)` ON DELETE CASCADE |
| `mode` | TEXT NOT NULL | stage mà dòng này thuộc về (BR-STUDY-022) |
| `round` | INTEGER NOT NULL DEFAULT 1 | vòng trong stage (BR-STUDY-059). `browse` và `self_assess` luôn `1` |
| `card_id` | TEXT NOT NULL | → `card(id)` ON DELETE CASCADE |
| `position` | INTEGER NOT NULL | thứ tự trong round đó (BR-STUDY-002, BR-STUDY-061). **Bất biến một khi round đã dựng**. Round 1 của mọi stage được dựng lúc mở phiên; một round sau được dựng (xáo lại, đánh số `0…n-1`) khi round trước nó hết dòng `pending`, và tới lúc đó các thẻ đã ghi danh vào nó mang `position = -1` |
| `status` | TEXT NOT NULL | `pending` \| `completed` (BR-STUDY-007) |
| `available_at` | INTEGER NOT NULL DEFAULT 0 | mốc `cursor` tối thiểu để thẻ được phục vụ lại (BR-STUDY-005) |
| `answers_in_session` | INTEGER NOT NULL DEFAULT 0 | số lượt đã đánh giá của dòng. `0` ở round 1 ⇒ lượt tới là lượt đầu của thẻ trong stage: `learning` ở phiên học mới, `scheduled` ở phiên ôn (BR-SRS-016, BR-STUDY-023). Mọi lượt sau đó, kể cả lượt đầu của round sau, là `relearning` |
| `remaining_ms` | INTEGER NULL | chỉ `recall`: thời gian còn lại của lượt đang dở (BR-STUDY-036). NULL ở mọi stage khác |
| `is_revealed` | INTEGER NOT NULL DEFAULT 0 | chỉ `recall`: đáp án đã lật chưa, để Resume không che lại (BR-STUDY-036) |
| `direction` | TEXT NULL | `korean_to_meaning` \| `meaning_to_korean` — chiều thật của **thẻ này**, gán một lần lúc dựng round (BR-MODE-015). NULL ở mọi stage ngoài `self_assess` của một phiên đủ điều kiện (BR-MODE-013) |
| `hint_shown` | INTEGER NOT NULL DEFAULT 0 | từ v2, chỉ `fill`: gợi ý của lượt đang dở đã hiện (BR-STUDY-028). `used_hint` của lượt đọc từ cột này, nên vẫn đúng khi app bị thu hồi rồi Tiếp tục. `0` ở mọi stage khác (invariant 38) |
| `meaning_slot` | INTEGER NULL | từ v2, chỉ `match`: chỗ `0…4` của nghĩa thẻ này trên bàn của nó (BR-STUDY-049). Một bàn là các vị trí `5k … 5k+4` của round. Gán khi round được chuẩn bị, xáo theo từng bàn, không trùng thứ tự term khi bàn có từ hai cặp. NULL ở mọi stage khác (invariant 39) |

PK là `(session_id, mode, round, card_id)` — một thẻ xuất hiện đúng một lần **trong
mỗi round của mỗi stage**, và mọi round có thứ tự độc lập (BR-STUDY-022, BR-STUDY-061).

Giới hạn thẻ của BR-STUDY-003 vì thế được đếm trên **tập thẻ riêng biệt của phiên**,
không phải trên số dòng — một phiên 20 thẻ × 5 stage đã là 100 dòng trước khi có
bất kỳ round nào. Xem invariant 18.

### Vì sao là `cursor` + `available_at`, không phải xáo lại `position`

BR-STUDY-005 bắt thẻ bị quên quay lại "sau ít nhất 3 thẻ khác". Cách thẳng tay là ghi
lại `position` rồi dịch mọi thẻ phía sau — mỗi lượt `forgotten` thành một loạt
UPDATE, và thứ tự gốc mất luôn.

Thay vào đó mỗi lượt tăng `study_session.cursor` lên 1, còn thẻ bị quên được đặt
`available_at = cursor + 3`. Không dịch gì, một số thay một số:

```sql
SELECT card_id FROM study_queue_items
WHERE session_id = :s AND status = 'pending' AND available_at <= :cursor
ORDER BY position LIMIT 1
```

Rỗng nhưng vẫn còn `pending` nghĩa là chỉ còn thẻ đang chờ quay lại — đúng vế thứ
hai của BR-STUDY-005 ("cuối hàng đợi nếu không đủ 3") — và phục vụ thẻ có `available_at`
nhỏ nhất. Vế đó thành một nhánh query, không phải một `if` ai đó phải nhớ viết.

### Vì sao hàng đợi là dữ liệu, không phải trạng thái tạm

Hàng đợi **mang luật** — thứ tự BR-STUDY-002, lượt quay lại BR-STUDY-005, trần BR-STUDY-073 — và một
cấu trúc mang luật phải nằm ở nơi mọi phép kiểm chạy được chạm tới nó, không
phải một nơi chỉ sống trong bộ nhớ của một màn hình.

Cái được kèm theo: phiên sống sót qua việc app bị hệ điều hành thu hồi (BR-STUDY-072),
và hàng đợi của phiên đã đóng trở thành dữ liệu thật — "phiên đó gồm những thẻ
nào, bỏ dở bao nhiêu" — thứ nếu không lưu thì không tồn tại ở bất kỳ đâu.

## `study_guess_options`

**Phạm vi:** V8.0, từ schema v2.

Năm lựa chọn của một câu `guess`, theo thứ tự hiển thị (BR-STUDY-037, BR-STUDY-043).
Câu được dựng khi round của nó bắt đầu được phục vụ, và không dựng lại khi Tiếp tục.

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `session_id` | TEXT NOT NULL | cùng `mode`, `round`, `card_id`: dòng hàng đợi của câu hỏi → `study_queue_items` ON DELETE CASCADE |
| `mode` | TEXT NOT NULL DEFAULT 'guess' | luôn `guess`; có mặt vì khoá ngoại ghép cần nó |
| `round` | INTEGER NOT NULL | round của câu hỏi |
| `card_id` | TEXT NOT NULL | thẻ đang hỏi |
| `slot` | INTEGER NOT NULL | vị trí hiển thị `0…4` |
| `option_card_id` | TEXT NOT NULL | → `card(id)` ON DELETE CASCADE. Đúng một lựa chọn là chính thẻ đang hỏi (invariant 40) |

PK là `(session_id, mode, round, card_id, slot)`, và một card xuất hiện tối đa một lần
trong một câu. Index `idx_study_guess_options_option` phục vụ cascade khi xoá card.

**Câu có ít hơn năm dòng là câu bị chặn** (BR-STUDY-040): nó không dựng được, hoặc mất
một lựa chọn vì card bị xoá. Câu bị chặn không hiện và không nhận lượt.

## `app_settings`

**Phạm vi:** V8.0 — mặc định toàn app: tuỳ chọn học và trình bày. Ba cột
`reminder_*` thuộc sub-project sau (xem ghi chú dưới bảng).

Một dòng, cho local profile. Mặc định toàn app của tùy chọn học (BR-STUDY-056) và hai
tuỳ chọn trình bày (BR-SETTINGS-005, BR-SETTINGS-006).

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | INTEGER PK | luôn `1`; `CHECK (id = 1)` giữ bảng ở đúng một dòng (BR-SETTINGS-001) |
| `card_limit` | INTEGER NOT NULL DEFAULT 20 | trần thẻ **mỗi phiên**, không phải mỗi ngày (BR-STUDY-003) |
| `new_card_order` | TEXT NOT NULL DEFAULT 'created' | `created` \| `random` (BR-STUDY-057) |
| `theme_mode` | TEXT NOT NULL DEFAULT 'system' | `system` \| `light` \| `dark` (BR-SETTINGS-005) |
| `language` | TEXT NOT NULL DEFAULT 'system' | `system` \| `en` \| `vi` (BR-SETTINGS-006) |
| `reminder_enabled` | INTEGER NOT NULL DEFAULT 0 | `0` \| `1`; mặc định tắt (BR-REMINDER-001). `CHECK (reminder_enabled IN (0, 1))` |
| `reminder_minute_of_day` | INTEGER NOT NULL DEFAULT 1200 | phút trong ngày **theo giờ địa phương**, `1200` = 20:00 (BR-REMINDER-002). `CHECK (reminder_minute_of_day BETWEEN 0 AND 1439)` |
| `reminder_last_delivered_at` | DATETIME NULL | lúc notification tóm tắt gần nhất được hiện; NULL nghĩa là chưa lần nào (BR-REMINDER-004). UTC |
| `updated_at` | DATETIME NOT NULL | UTC |

**Phạm vi:** sub-project sau — nhắc học hằng ngày. Ba cột `reminder_*` giữ ở
đây để nghiệp vụ không phải đào lại.

**`reminder_last_delivered_at` là bookkeeping của hệ thống, không phải lựa chọn
của người dùng, và nó nằm cùng bảng vì lần hoà giải lịch cần đọc nó **cùng lúc**
với giờ và cờ bật — hỏi riêng là hai snapshot của một dòng. Nó được ghi
bằng một `UPDATE` riêng chạm đúng một cột, vì người ghi nó là background isolate
còn người ghi hai cột kia là người dùng đang mở app; gộp lại thì một lượt chạy
nền có thể ghi đè lựa chọn vừa đổi.

**Ba cột nhắc học là cột thật, không phải JSON trong `study_config`.** Chúng
không phải tuỳ chọn học của một deck — không có ghi đè theo root, và không deck
nào mang giá trị riêng — nên chúng thuộc đúng bảng một-dòng này. Đọc chúng ra
kiểu đúng lúc build là điều một ô JSON không cho.

**`reminder_minute_of_day` là giờ địa phương, và cố ý không quy đổi UTC.** Mọi
cột `DATETIME` khác ở đây lưu UTC vì chúng là *thời điểm*; đây là một *giờ trong
ngày*, và quy đổi nó sang UTC lúc lưu làm giờ nhắc trôi đúng bằng lượng offset
đổi khi người dùng đi qua múi giờ khác — người dùng đặt 20:00 và nhận lúc 23:00
mà không có gì nói cho họ biết tại sao (BR-REMINDER-002).

Hai cột này chỉ có `CHECK`, không có bất biến trong mục `## Bất biến`. Lý do
giống điều bất biến 12 nói ngược lại: một `CHECK` đã khiến giá trị ngoài miền
không ghi được, nên một bất biến phủ chính miền đó là một test không dựng nổi
vi phạm của chính nó.

**Một bảng một dòng thay vì key-value.** Key-value đọc linh hoạt hơn nhưng mọi
giá trị thành `TEXT` và mọi lần đọc thành một phép ép kiểu không ai kiểm; một
dòng có cột thật thì `drift_dev` type-check ngay lúc build, và thêm một tùy chọn
là một migration — đúng mức nghiêm túc cần có cho thứ đổi hành vi học. BR-SETTINGS-001
nâng điều đó lên thành rule, nên một store key-value riêng cho theme và ngôn ngữ
là lựa chọn đã bị loại: nó tách một nửa tuỳ chọn của app sang một store thứ hai,
không có transaction chung với nửa còn lại và không watch được cùng một stream.

**`theme_mode` và `language` giữ lựa chọn, không giữ kết quả đã giải.** `'system'`
là một lựa chọn thật, khác hẳn với việc lưu `'light'` vì hôm nay platform đang
sáng: giá trị đã giải hết đúng ngay khi người dùng đổi cài đặt hệ điều hành, và
không có cách nào phân biệt được nó với một lựa chọn tường minh.

**`language` chứ không phải `locale`.** Cột giữ đúng ba giá trị của BR-SETTINGS-006, không
phải một BCP-47 tag đầy đủ — chưa có variant, script hay region nào trong
`supportedLocales`, và một cột hứa hẹn nhiều hơn thứ nó nhận là một cột sẽ được
ai đó ghi `vi-VN` vào.

**Ghi đè nằm ở `deck.study_config`, không ở đây.** Deck root MAY mang JSON ghi
đè; deck con MUST NOT (BR-STUDY-056), cùng quy tắc cột scheduler đã theo từ BR-DECK-025. Giá
trị hiệu lực = giá trị của root nếu có, ngược lại giá trị bảng này. Đổi bảng này
MUST NOT ghi `study_config`, và xoá `study_config` MUST NOT ghi bảng này
(BR-SETTINGS-003).

**Dạng của `study_config`:** `{"card_limit": <số nguyên 1–200>, "new_card_order":
"created" | "random"}`. Thiếu khoá, sai kiểu, `new_card_order` khác hai giá trị đó
hoặc `card_limit` ngoài 1–200 (BR-STUDY-003) làm giá trị ghi đè **không đọc được**:
giá trị hiệu lực là giá trị của bảng này, và việc đọc MUST NOT sửa text đã lưu
(IT-STUDY-013). Cột chỉ đổi khi người dùng lưu tuỳ chọn của root hoặc chọn
`Use app defaults` (UC-SETTINGS-001 A1). Khoá lạ bị bỏ qua.

## Bất biến — phải kiểm tra được bằng query

Mỗi query dưới đây **phải luôn trả về 0 dòng**. Chúng là đặc tả cho phần kiểm tra
tính toàn vẹn dữ liệu, và là nguồn của các trường hợp kiểm thử.

### Cây deck

**Sáu câu đầu và câu 15 đo `delete_batch_id IS NULL`.** Chúng nói về cây
người dùng đang nhìn thấy, và một tombstone không phải nội dung: không lọc thì
invariant 2 báo vi phạm cho mọi deck vừa được dọn rỗng đúng BR-TRASH-005, và invariant
29 im lặng cho đúng những deck lẽ ra phải `unset`.

```sql
-- 1. Root deck có card trực tiếp (BR-DECK-004)
SELECT c.id FROM card c
JOIN deck d ON d.id = c.deck_id
WHERE d.parent_id IS NULL AND c.delete_batch_id IS NULL;

-- 2. content_type = 'unset' nhưng đã có nội dung (BR-DECK-006, BR-DECK-008)
SELECT d.id FROM deck d
WHERE d.content_type = 'unset' AND d.delete_batch_id IS NULL
  AND (EXISTS (SELECT 1 FROM card c
               WHERE c.deck_id = d.id AND c.delete_batch_id IS NULL)
    OR EXISTS (SELECT 1 FROM deck s
               WHERE s.parent_id = d.id AND s.delete_batch_id IS NULL));

-- 29. Sub-deck đã rỗng nhưng vẫn mang type (BR-DECK-015, BR-TRASH-005)
--     Chiều ngược của invariant 2: 2 bắt `unset` còn nội dung, 29 bắt type còn
--     lại sau khi nội dung đã đi hết. Root không tham gia — root luôn `deck`
--     (BR-DECK-004), và một root rỗng là trạng thái bình thường.
SELECT d.id
FROM deck d
WHERE d.parent_id IS NOT NULL
  AND d.delete_batch_id IS NULL
  AND d.content_type IN ('card', 'deck')
  AND NOT EXISTS (
    SELECT 1 FROM card c
    WHERE c.deck_id = d.id AND c.delete_batch_id IS NULL
  )
  AND NOT EXISTS (
    SELECT 1 FROM deck child
    WHERE child.parent_id = d.id AND child.delete_batch_id IS NULL
  );

-- 3. content_type = 'card' nhưng có deck con (BR-DECK-009)
SELECT d.id FROM deck d
WHERE d.content_type = 'card' AND d.delete_batch_id IS NULL
  AND EXISTS (SELECT 1 FROM deck s
              WHERE s.parent_id = d.id AND s.delete_batch_id IS NULL);

-- 4. content_type = 'deck' nhưng có card trực tiếp (BR-DECK-010)
SELECT d.id FROM deck d
WHERE d.content_type = 'deck' AND d.delete_batch_id IS NULL
  AND EXISTS (SELECT 1 FROM card c
              WHERE c.deck_id = d.id AND c.delete_batch_id IS NULL);

-- 5. Root deck không mang content_type = 'deck'
SELECT d.id FROM deck d
WHERE d.parent_id IS NULL AND d.content_type <> 'deck';

-- 6. Descendant trỏ sai root (BR-DECK-019)
--    root_id của một deck phải bằng root_id của cha nó.
SELECT d.id FROM deck d
JOIN deck p ON p.id = d.parent_id
WHERE d.root_id <> p.root_id;

-- 7. Root deck không tự trỏ về chính nó (BR-DECK-002)
SELECT d.id FROM deck d
WHERE d.parent_id IS NULL AND d.root_id <> d.id;

-- 8. Cycle trong cây (BR-DECK-016)
--    Đi ngược từ mỗi deck lên tới root; gặp lại chính mình là cycle.
WITH RECURSIVE up(start_id, node_id, depth) AS (
  SELECT id, parent_id, 1 FROM deck WHERE parent_id IS NOT NULL
  UNION ALL
  SELECT u.start_id, d.parent_id, u.depth + 1
  FROM up u JOIN deck d ON d.id = u.node_id
  WHERE u.node_id IS NOT NULL AND u.depth < 64
)
SELECT DISTINCT start_id FROM up WHERE node_id = start_id;

-- 15. Deck sâu hơn 10 cấp (BR-DECK-001)
--     Đi xuống từ mỗi root, root là cấp 1. Chỉ hàng đang active: một subtree
--     đã nằm trong Trash không được tính vào giới hạn của cây đang sống, và
--     restore mới là nơi độ sâu của nó được thẩm định lại (BR-TRASH-006).
WITH RECURSIVE levels(id, depth) AS (
  SELECT id, 1 FROM deck
  WHERE parent_id IS NULL AND delete_batch_id IS NULL
  UNION ALL
  SELECT d.id, l.depth + 1
  FROM deck d JOIN levels l ON d.parent_id = l.id
  WHERE l.depth < 64 AND d.delete_batch_id IS NULL
)
SELECT id FROM levels WHERE depth > 10;

-- 9. Card study state không cùng scheduler hoặc generation với root (BR-SRS-028, BR-SRS-029)
SELECT s.card_id FROM card_schedule s
JOIN card c ON c.id = s.card_id
JOIN deck d ON d.id = c.deck_id
JOIN deck root ON root.id = d.root_id
WHERE s.generation <> root.generation
   OR s.scheduler_type <> root.scheduler_type;

-- 10. Deck con mang cột scheduler (BR-DECK-025)
SELECT d.id FROM deck d
WHERE d.parent_id IS NOT NULL
  AND (d.scheduler_type IS NOT NULL OR d.generation IS NOT NULL);

-- 11. Root deck thiếu scheduler (BR-SRS-001)
SELECT d.id FROM deck d
WHERE d.parent_id IS NULL
  AND (d.scheduler_type IS NULL OR d.generation IS NULL);

-- 30. Cây đã có thẻ học xong nhưng scheduler chưa khoá (BR-SRS-003, BR-STUDY-053)
SELECT root.id FROM deck root
WHERE root.parent_id IS NULL
  AND root.first_answered_at IS NULL
  AND EXISTS (
    SELECT 1 FROM card_schedule s
    JOIN card c ON c.id = s.card_id
    JOIN deck d ON d.id = c.deck_id
    WHERE d.root_id = root.id AND s.learned_at IS NOT NULL
  );
```

Query 30 **chỉ chạy một chiều**, và điều đó là cố ý. Có thẻ `learned_at` mà root
chưa khoá là dữ liệu sai: BR-SRS-003 nói thẻ đầu hoàn tất chuỗi thì scheduler khoá, và
`completeLearning` ghi cả hai trong cùng transaction. Chiều ngược lại — root đã
khoá mà không còn thẻ nào `learned_at` — là **hợp lệ**: người dùng học xong rồi
xoá thẻ cuối, và dấu "cây này đã từng được học" không mất đi vì nội dung bị xoá.
Chỉ Reset mới gỡ khoá (BR-SRS-024).

Chú ý query 9 dùng `d.root_id`, **không** dùng `COALESCE(d.parent_id,
d.id)`. Phiên bản cũ của tài liệu này dùng `COALESCE` và sẽ trả về sai root ngay
khi có deck ở cấp thứ ba (BR-DECK-003).

### Session

```sql
-- 12. Tổ hợp status × end_reason không hợp lệ (BR-STUDY-010, BR-STUDY-012, BR-STUDY-013, BR-STUDY-014, BR-STUDY-015, BR-STUDY-016, BR-STUDY-017, BR-STUDY-018)
SELECT id FROM study_session
WHERE NOT (
     (status = 'in_progress' AND end_reason IS NULL)
  OR (status = 'completed'   AND end_reason IS NULL)
  OR (status = 'abandoned'   AND end_reason IN ('user_exit','interrupted'))
  OR (status = 'invalidated'
      AND end_reason IN ('scheduler_reset','scheduler_changed','stale_generation','content_deleted'))
  OR (status = 'failed'      AND end_reason = 'persistence_error')
);

-- 13. Session đã kết thúc nhưng thiếu ended_at
SELECT id FROM study_session
WHERE status <> 'in_progress' AND ended_at IS NULL;
```

### Hàng đợi phiên

```sql
-- 16. Session completed nhưng hàng đợi còn thẻ chưa xong (BR-STUDY-013)
SELECT s.id FROM study_session s
WHERE s.status = 'completed'
  AND EXISTS (SELECT 1 FROM study_queue_items q
              WHERE q.session_id = s.id AND q.status = 'pending');

-- 17. Bộ đếm của hàng đợi âm, hoặc lượt vượt trần BR-STUDY-073
--     Trần 3 lượt relearning chỉ áp cho `self_assess` (BR-STUDY-005, BR-STUDY-073): 1 lượt
--     scheduled + 3 relearning = 4. Bốn stage chấm điểm lặp bằng round và
--     không có trần (BR-STUDY-069), nên chúng không bị ràng buộc này.
SELECT session_id FROM study_queue_items
WHERE available_at < 0 OR answers_in_session < 0 OR round < 1
   OR (mode = 'self_assess' AND answers_in_session > 4);

-- 24. Thẻ đã xong học mới nhưng không có lịch (BR-STUDY-053, BR-STUDY-058)
SELECT card_id FROM card_schedule
WHERE learned_at IS NOT NULL AND due_at IS NULL;

-- 28. Thẻ chưa xong học mới mà đã có lịch (BR-STUDY-053)
--     Chiều ngược của invariant 24, và nó lọt qua cả 24 lẫn 25: một thẻ có thể
--     mang `due_at` mà chưa từng có lượt `scheduled` nào nếu đường ghi nào đó
--     đặt lịch giữa chuỗi học mới. BR-STUDY-053 nói chuỗi MUST NOT làm thế.
SELECT card_id FROM card_schedule
WHERE learned_at IS NULL AND due_at IS NOT NULL;

-- 25. Thẻ chưa xong học mới mà đã có lượt `scheduled` (BR-STUDY-053, BR-STUDY-058)
--     Chuỗi học mới ghi `learning`/`relearning` và không đổi lịch; một lượt
--     `scheduled` ở đây nghĩa là lịch đã bị đặt giữa chừng.
--     Chỉ xét lượt cùng generation với study state: Reset giữ lượt cũ
--     (BR-SRS-023) còn thẻ học lại từ đầu, nên lượt `scheduled` của generation
--     trước không phải vi phạm.
SELECT a.id FROM review_log a
JOIN card_schedule s ON s.card_id = a.card_id
WHERE a.kind = 'scheduled' AND s.learned_at IS NULL
  AND a.generation = s.generation;

-- 26. `kind = 'learning'` nằm ngoài phiên học mới (BR-STUDY-052)
SELECT a.id FROM review_log a
JOIN study_session ss ON ss.id = a.session_id
WHERE a.kind = 'learning' AND ss.session_kind <> 'learning';

-- 27. Tùy chọn học nằm trên deck con (BR-STUDY-056)
SELECT id FROM deck
WHERE parent_id IS NOT NULL AND study_config IS NOT NULL;

-- 23. Cột đặc thù `fill` xuất hiện ở stage khác (BR-STUDY-027, BR-STUDY-028)
SELECT id FROM review_log
WHERE mode <> 'fill' AND (comparison_version IS NOT NULL OR used_hint IS NOT NULL);

-- 21. Trạng thái timer nằm ngoài `recall`, hoặc vượt ngưỡng 20 giây (BR-STUDY-031, BR-STUDY-036)
SELECT session_id FROM study_queue_items
WHERE (mode <> 'recall' AND (remaining_ms IS NOT NULL OR is_revealed <> 0))
   OR remaining_ms < 0 OR remaining_ms > 20000;

-- 22. `outcome_reason = timeout` ở stage không phải `recall` (BR-STUDY-034)
SELECT id FROM review_log
WHERE outcome_reason IS NOT NULL
  AND (outcome_reason <> 'timeout' OR mode <> 'recall');

-- 31. Chiều hỏi nằm ngoài chỗ nó được phép (BR-MODE-013, BR-MODE-015)
--     Bốn cách sai: một phiên mang chiều mà không phải `reviewing`/`self_assess`;
--     một dòng hàng đợi mang chiều ở stage khác `self_assess`; một dòng mang
--     chiều mà phiên của nó không mang; và một phiên có chiều mà dòng
--     `self_assess` của nó lại trống — `mixed` gán cho **mọi** thẻ.
--
--     **Không có mệnh đề `sm2`, và đó là chủ ý.** `study_session` không mang
--     `scheduler_type`; đọc thuật toán *hiện tại* của cây thì sai với đúng cây
--     đã Reset sang thuật toán khác — nó vẫn từng chạy `sm2`, và BR-SRS-019 đặt cột
--     ấy lên `review_log` chính vì lý do này. Điều kiện `sm2` vì thế thuộc
--     write path (BR-MODE-018), không thuộc một câu SQL đọc sau.
SELECT s.id FROM study_session s
WHERE (s.direction IS NOT NULL
       AND (s.session_kind <> 'reviewing' OR s.current_mode <> 'self_assess'))
   OR EXISTS (SELECT 1 FROM study_queue_items q
              WHERE q.session_id = s.id
                AND ((q.direction IS NOT NULL AND q.mode <> 'self_assess')
                  OR (q.direction IS NOT NULL AND s.direction IS NULL)
                  OR (s.direction IS NOT NULL AND q.mode = 'self_assess'
                      AND q.direction IS NULL)));

-- 32. Lượt lịch sử mang chiều mà dòng hàng đợi của nó không mang (BR-MODE-016)
--     Chiều của lượt MUST là bản chép của dòng nó được trả lời trên. So với
--     **tập** dòng của thẻ đó trong stage đó chứ không với một dòng: `review_log`
--     không mang `round`, nên "dòng nào" là câu hỏi bảng này không trả lời được —
--     và một mode có nhiều round sẽ làm phép so một-một sai ngay khi nó eligible.
SELECT a.id FROM review_log a
WHERE EXISTS (SELECT 1 FROM study_queue_items q
              WHERE q.session_id = a.session_id AND q.card_id = a.card_id
                AND q.mode = a.mode)
  AND NOT EXISTS (SELECT 1 FROM study_queue_items q
                  WHERE q.session_id = a.session_id AND q.card_id = a.card_id
                    AND q.mode = a.mode AND q.direction IS a.direction);

-- 38. `hint_shown` nằm ngoài `fill` (BR-STUDY-028)
--     CHECK của cột đã chặn; query giữ luật đọc được ở đây.
SELECT session_id FROM study_queue_items
WHERE hint_shown NOT IN (0, 1) OR (mode <> 'fill' AND hint_shown <> 0);

-- 39. `meaning_slot` nằm ngoài `match`, vượt 0–4, hoặc hai cặp của một bàn chung
--     một chỗ (BR-STUDY-049)
--     Bàn là các vị trí `5k … 5k+4` của round. Vế đầu CHECK đã chặn; vế sau thì
--     không, vì CHECK không nhìn được dòng khác.
SELECT session_id FROM study_queue_items
WHERE meaning_slot IS NOT NULL AND (mode <> 'match' OR meaning_slot NOT BETWEEN 0 AND 4)
UNION ALL
SELECT session_id FROM study_queue_items
WHERE mode = 'match' AND meaning_slot IS NOT NULL AND position >= 0
GROUP BY session_id, round, position / 5, meaning_slot
HAVING COUNT(*) > 1;

-- 40. Câu `guess` quá năm lựa chọn, hoặc không có đúng một đáp án đúng (BR-STUDY-037)
--     Hai lựa chọn cùng `back_folded` (BR-STUDY-039) không phải bất biến: sửa một
--     card sau khi câu đã dựng có thể làm điều đó đúng một cách hợp lệ. Bộ dựng
--     câu hỏi giữ luật ấy lúc dựng.
SELECT session_id FROM study_guess_options
GROUP BY session_id, round, card_id
HAVING COUNT(*) > 5 OR SUM(option_card_id = card_id) <> 1;

-- Bất biến 33-37: Trash, có hiệu lực từ schema v3 (BE-B1).

-- 33. Card đang active nằm trong một deck đã xoá (BR-TRASH-001, BR-TRASH-003)
--     Xoá một deck đánh dấu mọi descendant đang active, và restore luôn gắn
--     item vào một target đang active — nên không đường ghi nào tạo ra được
--     hàng này. Đây là bất biến mà toàn bộ chiến lược loại trừ một cột đứng
--     trên: nếu nó vỡ, "hàng còn sống ⇔ delete_batch_id IS NULL" không còn đúng
--     và mọi query active bắt đầu nói dối.
SELECT c.id FROM card c
JOIN deck d ON d.id = c.deck_id
WHERE c.delete_batch_id IS NULL AND d.delete_batch_id IS NOT NULL;

-- 34. Deck đang active nằm dưới một deck đã xoá (BR-TRASH-001, BR-TRASH-003)
SELECT d.id FROM deck d
JOIN deck p ON p.id = d.parent_id
WHERE d.delete_batch_id IS NULL AND p.delete_batch_id IS NOT NULL;

-- 35. Batch không còn hàng nào (BR-TRASH-010)
--     Purge xoá batch và để cascade dọn hàng, nên chiều ngược lại — hàng biến
--     mất mà batch còn — chỉ xảy ra khi một cascade theo parent_id đã đi
--     xuyên qua một batch mà điều kiện tiên quyết của BR-TRASH-010 lẽ ra phải chặn.
SELECT b.id FROM delete_batches b
WHERE NOT EXISTS (SELECT 1 FROM deck d WHERE d.delete_batch_id = b.id)
  AND NOT EXISTS (SELECT 1 FROM card c WHERE c.delete_batch_id = b.id);

-- 36. Tombstone bị xoá SAU tổ tiên đã xoá của nó (BR-TRASH-003)
--     Descendant luôn bị đánh dấu trước hoặc cùng lúc với tổ tiên, vì không
--     thao tác nào chạm tới được thứ đã bị ẩn. Thứ tự đó là cái làm cho
--     "batch eligible thì mọi descendant của nó cũng eligible" đúng, và BR-TRASH-010
--     dựa vào điều đó.
SELECT d.id FROM deck d
JOIN deck p ON p.id = d.parent_id
JOIN delete_batches db ON db.id = d.delete_batch_id
JOIN delete_batches pb ON pb.id = p.delete_batch_id
WHERE db.deleted_at > pb.deleted_at;

-- 37. Batch không trỏ về một item root mang chính batch đó (BR-TRASH-001)
SELECT b.id FROM delete_batches b
WHERE (b.item_type = 'deck' AND NOT EXISTS (
         SELECT 1 FROM deck d
         WHERE d.id = b.root_item_id AND d.delete_batch_id = b.id))
   OR (b.item_type = 'card' AND NOT EXISTS (
         SELECT 1 FROM card c
         WHERE c.id = b.root_item_id AND c.delete_batch_id = b.id));
```

Query 8 và 15 giới hạn `depth < 64` để bản thân chúng không thành vòng lặp vô
hạn khi dữ liệu đã hỏng — một checker treo là checker vô dụng. Cap đó là của
diagnostic checker; query production không dùng cap để cắt subtree (xem "Duyệt
cây" ở trên).

### Scheduler và generation

```sql

-- 19. Round nhảy số: stage có round N nhưng thiếu round N-1 (BR-STUDY-059)
SELECT q.session_id FROM study_queue_items q
WHERE q.round > 1
  AND NOT EXISTS (SELECT 1 FROM study_queue_items p
                  WHERE p.session_id = q.session_id AND p.mode = q.mode
                    AND p.round = q.round - 1);

-- 20. Round sau chứa thẻ không có ở round trước (BR-STUDY-059)
--     Tập của round N MUST là con của tập round N-1.
SELECT q.session_id FROM study_queue_items q
WHERE q.round > 1
  AND NOT EXISTS (SELECT 1 FROM study_queue_items p
                  WHERE p.session_id = q.session_id AND p.mode = q.mode
                    AND p.round = q.round - 1 AND p.card_id = q.card_id);

-- 18. Một phiên nạp quá số thẻ riêng biệt nó tự khai báo (BR-STUDY-003, BR-STUDY-024)
--     So với `card_limit` của **chính phiên đó**, không với một số viết cứng:
--     mặc định là 20 nhưng người dùng sẽ cài được, và một hằng số ở đây sẽ sai
--     ở đúng phiên đầu tiên họ đổi.
--     COUNT(DISTINCT card_id), không COUNT(*): mỗi thẻ có một dòng **mỗi round của
--     mỗi stage** (BR-STUDY-022, BR-STUDY-059), nên đếm dòng báo động giả ngay lập tức.
SELECT q.session_id FROM study_queue_items q
JOIN study_session s ON s.id = q.session_id
GROUP BY q.session_id, s.card_limit
HAVING COUNT(DISTINCT q.card_id) > s.card_limit;
```

Invariant 16 là thứ giữ cho `completed` có nghĩa. Không có nó, một phiên bỏ dở
được đánh dấu hoàn thành trông y hệt một phiên học hết — và sự khác nhau đó là
toàn bộ nội dung của BR-STUDY-013.

### Review log

```sql
-- 14. Lượt relearning làm đổi lịch (BR-SRS-017)
SELECT id FROM review_log
WHERE kind = 'relearning'
  AND (previous_box IS NOT next_box
    OR previous_ease_factor IS NOT next_ease_factor
    OR previous_interval_days IS NOT next_interval_days);
```

---

## Quyết định về ID và thời gian

Khoá chính: [ADR-007](../decisions/ADR-007-khoa-chinh-uuid-sinh-phia-client.md). Thời gian: [ADR-008](../decisions/ADR-008-datetime-luu-utc.md).

## Foreign keys

`PRAGMA foreign_keys = ON` trong `beforeOpen`. Không có nó, `ON DELETE CASCADE`
chỉ là chú thích. Cần test: xoá root deck → toàn bộ cây deck con, card, study
state, study answers và study session đều biến mất (BR-DECK-022).

Từ v3, `deck.delete_batch_id` và `card.delete_batch_id` trỏ tới
`delete_batches(id)`, `ON DELETE CASCADE`: xoá một batch xoá hàng của nó, và các
cascade sẵn có dọn study state, lịch sử, hàng đợi và quan hệ tag (BR-TRASH-010).
Cần test: xoá một batch không làm mất hàng nào của batch khác, kể cả sau khi
nâng cấp từ v1 hay v2.

## Chưa mô hình hoá

Media được nhắc trong quy tắc reset (BR-SRS-021: reset giữ nguyên nó) nhưng **chưa
thuộc V8.0** và chưa có bảng. Khi thêm, nó gắn với `card` và không mang
`generation` — nó là nội dung, và quy tắc "reset không chạm nội dung"
áp dụng nguyên vẹn.

