# Data model — memox

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chốt hình dạng dữ liệu V8 và các bất biến phải luôn đúng |
| **Scope** | Bảng, cột, index, quan hệ, query bất biến. Ngoài phạm vi: SQL runtime |
| **Source of truth for** | Schema V8 · cột và kiểu · index · query bất biến |
| **Depends on** | `document-conventions.md`, `business-rules.md` |
| **Updated by** | `docs/superpowers/plans/2026-09-23-docs-v8-reset.md` — nâng lên data model V8 |
| **Last updated** | 2026-09-23 |

**Tài liệu này, không phải bảng tóm tắt ở §5 của
[`superpowers/specs/2026-09-21-memox-v8-foundation-design.md`](superpowers/specs/2026-09-21-memox-v8-foundation-design.md),
là nguồn thẩm quyền cho data model V8.**

Đây là tài liệu thiết kế: định nghĩa bảng và các bất biến phải đúng, không phải
SQL runtime thật.

**Mỗi cột của Study tồn tại vì một luật, và đây là ánh xạ.** `business-rules.md`
nói **hành vi** chứ không chỉ định cột — đúng phân công của hai tài liệu — nên không
tra ngược được từ cột về luật nếu không có bảng này. Người viết M5 cần chiều đó.

| Cột | Tồn tại vì |
|---|---|
| `card_schedule.learned_at` | BR-144 (đặt), BR-142 (chia hai tập), BR-90 (định nghĩa `new`), BR-152 (Reset xoá) |
| `study_session.session_kind` | BR-142 |
| `study_session.card_limit` | BR-24, BR-139 |
| `study_session.cursor` | BR-26 — nền của "sau ít nhất 3 thẻ khác" |
| `study_queue_items.mode` | BR-113 |
| `study_queue_items.round` | BR-115, BR-117 |
| `study_queue_items.position` | BR-23, BR-117 |
| `study_queue_items.available_at` | BR-26 |
| `study_queue_items.answers_in_session` | BR-77 (lượt đầu), BR-104 (trần 3) |
| `study_queue_items.remaining_ms` · `is_revealed` | BR-133 |
| `study_session.direction` | BR-203 (điều kiện), BR-205 (`mixed`), BR-207 (khoá) |
| `study_queue_items.direction` | BR-205 — gán một lần, sống qua comeback và restart |
| `review_log.direction` | BR-206 — chép từ dòng hàng đợi, không suy luận |
| `review_log.mode` | BR-98 |
| `review_log.outcome_reason` | BR-131 |
| `review_log.comparison_version` | BR-135 |
| `review_log.used_hint` | BR-136 |
| `deck.study_config` | BR-147 |
| `app_settings.card_limit` · `new_card_order` | BR-147, BR-148 |

Ba nguyên tắc chi phối cách chia bảng:

1. **Nội dung, trạng thái lịch, và lịch sử có ba vòng đời khác nhau**, nên là ba
   bảng. Nội dung sửa mà không đụng lịch (BR-10); lịch đổi mỗi lần ôn; lịch sử chỉ
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
                             └──► study_queue_items  (một hàng đợi mỗi stage, BR-113)
```

---

## `deck`

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID sinh phía client |
| `name` | TEXT NOT NULL | BR-01 |
| `parent_id` | TEXT NULL | NULL = root deck. → `deck(id)` ON DELETE CASCADE |
| `root_id` | TEXT NOT NULL | root có `root_id = id`; descendant mang id của root (BR-56) |
| `depth` | INTEGER NOT NULL | Root = 1. `CHECK (depth <= 10)` là an toàn tầng DB (BR-55) |
| `content_type` | TEXT NOT NULL | `'unset'` \| `'card'` \| `'deck'` (BR-60…BR-66, BR-163) |
| `owner_id` | TEXT NULL | NULL = local profile. **Phạm vi:** sub-project sau — auth |
| `scheduler_type` | TEXT NULL | `'eight_box'` \| `'sm2'`. **NOT NULL trên root, NULL trên deck con** |
| `scheduler_version` | INTEGER NULL | cùng quy tắc NULL |
| `scheduler_config` | TEXT NULL | JSON tham số ghi đè của thuật toán. Cùng quy tắc NULL |
| `study_config` | TEXT NULL | JSON tùy chọn học ghi đè mặc định toàn app (BR-147). NULL = theo mặc định. Chỉ trên root |
| `generation` | INTEGER NULL | bắt đầu từ 1, +1 mỗi lần reset (BR-40). Chỉ trên root |
| `first_answered_at` | DATETIME NULL | NULL = chưa thẻ nào hoàn tất chuỗi học mới ở generation hiện tại → scheduler mở khoá (BR-12). Được đặt bởi chính lần hoàn tất đầu tiên, cùng transaction (BR-13, BR-144); chỉ Reset đưa về NULL (BR-44) |
| `source_template_id` | TEXT NULL | NULL = deck tự tạo (BR-34). **Phạm vi:** sub-project sau — Starter decks |
| `source_template_version` | INTEGER NULL | version tại thời điểm sao chép. **Phạm vi:** sub-project sau — Starter decks |
| `delete_batch_id` | TEXT NULL | NULL = deck đang active. Khác NULL = tombstone thuộc batch đó (BR-256, BR-258). → `delete_batches(id)` ON DELETE CASCADE. **Phạm vi:** sub-project sau — Trash |
| `sibling_position` | INTEGER NOT NULL | Thứ tự manual trong nhóm cùng `parent_id`; tie-break bằng `id` (BR-268) |
| `created_at` | DATETIME NOT NULL | UTC |
| `updated_at` | DATETIME NOT NULL | UTC |

### Duyệt cây — hai loại query, hai quy tắc

Cây có tối đa **10 cấp**, root là cấp 1 (BR-55). Hai giới hạn khác nhau chi
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

`COALESCE(parent_id, id)` **bị cấm** (BR-57). Nó có nghĩa "cha, hoặc
chính nó nếu không có cha", nên với deck ở cấp 3 nó trả về deck cấp 2 chứ không
phải root. Với cây một cấp nó đúng — và đó chính là điều khiến nó nguy hiểm.

Cái giá: di chuyển subtree phải cập nhật `root_id` **và** `depth` cho toàn bộ
subtree trong một transaction, bằng recursive CTE (BR-71). Bỏ sót một node tạo
ra descendant trỏ sai root hoặc sai độ sâu — dữ liệu hỏng im lặng, vì query vẫn
chạy và chỉ trả về kết quả thiếu.

### `content_type` — bao gồm cả root

**Sub-deck đang `card` hoặc `deck` mà không còn direct card lẫn direct child
deck là dữ liệu không hợp lệ** (BR-163) — invariant 29 bắt nó.

`content_type` là NOT NULL cho **mọi** deck. Root deck được tạo thẳng với
`content_type = 'deck'` và giá trị đó bất biến — đó là cách BR-58 ("root chỉ chứa
deck con") trở thành một ràng buộc kiểm tra được bằng cùng một câu query như các
deck khác, thay vì một luật riêng phải nhớ.

| Deck | `content_type` khi tạo | Đổi được không |
|---|---|---|
| root | `'deck'` | không |
| deck con | `'unset'` | hệ thống tự duy trì theo direct children (BR-163): `unset` → `card`/`deck` ở phần tử con đầu tiên (BR-62); `card`/`deck` → `unset` khi direct child cuối bị xoá hoặc chuyển đi, trong cùng transaction |

### Cột scheduler chỉ trên root

Deck con để NULL và tra qua `root_id` (BR-06). Đây là cách khiến "deck con
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
| `deck_id` | TEXT NOT NULL | → `deck(id)` ON DELETE CASCADE. Chỉ deck có `content_type = 'card'` (BR-63) |
| `front` | TEXT NOT NULL | BR-07, BR-08 |
| `back` | TEXT NOT NULL | BR-07, BR-08 |
| `front_folded` | TEXT NOT NULL DEFAULT '' | `front` đã trim + hạ hoa bằng Dart. Search so trên cột này |
| `back_folded` | TEXT NOT NULL DEFAULT '' | Như trên, cho `back` |
| `is_flagged` | INTEGER NOT NULL DEFAULT 0 | 0 \| 1. Cờ người dùng đánh dấu (BR-92) |
| `example` | TEXT NULL | Tuỳ chọn (BR-95) |
| `hint` | TEXT NULL | Tuỳ chọn (BR-95) |
| `pronunciation` | TEXT NULL | Tuỳ chọn (BR-95) |
| `delete_batch_id` | TEXT NULL | NULL = card đang active. Khác NULL = tombstone thuộc batch đó (BR-256, BR-258). → `delete_batches(id)` ON DELETE CASCADE. **Phạm vi:** sub-project sau — Trash |
| `created_at` | DATETIME NOT NULL | UTC |
| `updated_at` | DATETIME NOT NULL | UTC |

**Hai cột `_folded` tồn tại vì `lower()` của SQLite chỉ hạ hoa ASCII.** Nó không
đụng tới `Ô`, `Ê`, `Đ`. Search từng so `instr(lower(front), :term)` với `:term`
đã được Dart hạ hoa theo Unicode — hai vế fold bằng hai luật khác nhau, nên thẻ
lưu `CÔNG NGHỆ` không tìm ra được bằng `công nghệ`, trong khi thẻ viết thường thì
tìm được. Fold cả hai vế trong Dart biến phép so thành byte-for-byte và đúng cho
mọi bảng chữ cái. Đây đúng là lập luận `tags.name_folded` đã dùng (BR-93),
áp cho hai mặt thẻ.

Chỉ hạ hoa, **không** bỏ dấu: `công` vẫn không khớp `cong`. Tìm kiếm không dấu là
quyết định sản phẩm (S1), không phải hệ quả phụ của một bản vá.

`DEFAULT ''` vì SQLite bắt buộc có default khi thêm cột NOT NULL. Mọi lượt ghi
đều đi qua repository và luôn ghi giá trị thật; phép tính hai cột này MUST chạy
bằng Dart chứ không phải SQL — `SET front_folded = lower(front)` sẽ ghi đúng
những giá trị hỏng mà cột này sinh ra để thay thế.

**Không có cột SRS nào ở đây**, và không có `generation` — card là nội
dung, nó sống xuyên qua mọi lần reset (BR-41). Reset learning progress không được
chạm vào bảng này.

Ba trường phụ để **NULL, không phải chuỗi rỗng**. NULL nghĩa là người dùng chưa
điền; chuỗi rỗng nghĩa là họ điền rồi xoá — và không màn nào phân biệt được hai
thứ đó, nên cho phép cả hai chỉ tạo ra hai cách biểu diễn một trạng thái. Lớp
domain trim rồi quy chuỗi rỗng về NULL trước khi ghi — cùng một điểm trim với
`front`/`back`.

`is_flagged` nằm ở đây chứ không ở `card_schedule` và đó là cùng một lập
luận: cờ là thứ người dùng đặt lên *nội dung* — "quay lại thẻ này" — nên nó phải
sống sót qua reset. Đặt nó cạnh `current_box` sẽ khiến reset xoá nó cùng lịch
(BR-92).

Index: `idx_card_deck_created` trên `(deck_id, created_at, id)` — composite,
theo đúng thứ tự `cardsByDeck` lọc rồi sắp. Đây là điều kiện để phân trang keyset
(`WHERE deck_id = ? AND (created_at, id) > (?, ?)`) là một range scan thật thay vì
một lần sắp toàn bộ deck rồi đặt `LIMIT` lên trên: đo trên 5.000 thẻ một deck, một
trang 50 thẻ đi từ 1193µs xuống 102µs.

## `tags`

**Phạm vi:** sub-project sau — Tags. Bảng giữ ở đây để nghiệp vụ không phải đào lại.

Nhãn phân loại nội dung do người dùng đặt — `noun`, `people`, `verb`. Nội dung,
không phải lịch: reset giữ nguyên (BR-41, BR-93).

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID sinh phía client |
| `name` | TEXT NOT NULL | BR-93. Lưu nguyên dạng người dùng gõ |
| `name_folded` | TEXT NOT NULL | `lower(trim(name))`. Cột để **cưỡng chế** unique |
| `owner_id` | TEXT NULL | NULL = local profile |
| `created_at` | DATETIME NOT NULL | UTC |

Index: `UNIQUE (owner_id, name_folded)`.

**`name_folded` là một cột thật, không phải một expression index**, vì BR-93 đòi
unique không phân biệt hoa thường và SQLite chỉ có `NOCASE` cho ASCII — một tag
tiếng Việt `Động từ` và `động từ` sẽ lọt qua `COLLATE NOCASE`. Ghi cột đã fold
lúc insert thì phép so sánh là byte-với-byte và đúng cho mọi bảng chữ.

Tag **không** thuộc về một deck. Cùng một `noun` dùng lại ở mọi deck; buộc nó
theo deck sẽ sinh ra bản sao mỗi lần người dùng tạo deck mới, và lúc lọc thì
chúng là các tag khác nhau.

## `card_tags`

**Phạm vi:** sub-project sau — Tags.

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `card_id` | TEXT NOT NULL | → `card(id)` ON DELETE CASCADE |
| `tag_id` | TEXT NOT NULL | → `tags(id)` ON DELETE CASCADE |

PK là `(card_id, tag_id)`. Index thứ hai `idx_card_tags_tag` trên `(tag_id,
card_id)` cho chiều ngược lại — "mọi thẻ mang tag này" là câu mà bộ lọc hỏi, và
PK không phục vụ được nó.

Cả hai FK đều `CASCADE`: xoá thẻ thì liên kết mất theo (BR-92 nói cùng điều đó
cho cờ), xoá tag thì nó biến khỏi mọi thẻ. Không có bản ghi mồ côi nào cần dọn.

## `card_schedule`

Một dòng cho mỗi card, tạo cùng lúc với card (BR-09). Xoá và tạo lại khi reset.

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `card_id` | TEXT PK | → `card(id)` ON DELETE CASCADE. PK vì quan hệ 1–1 |
| `scheduler_type` | TEXT NOT NULL | phải bằng scheduler của root deck |
| `scheduler_version` | INTEGER NOT NULL | |
| `generation` | INTEGER NOT NULL | phải bằng generation hiện tại của root (BR-49) |
| `learned_at` | DATETIME NULL | NULL = chưa xong chuỗi học mới (BR-144). Đặt một lần, không bao giờ về NULL trừ khi Reset |
| `due_at` | DATETIME NULL | NULL = chưa có lịch, tức chưa học xong lần đầu. UTC |
| `last_answered_at` | DATETIME NULL | cập nhật ở cả `scheduled` lẫn `relearning` (BR-20) |
| `answer_count` | INTEGER NOT NULL DEFAULT 0 | chỉ đếm `scheduled` (BR-20) |
| `lapse_count` | INTEGER NOT NULL DEFAULT 0 | BR-20 |
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

Append-only. Không sửa, không xoá — kể cả khi reset (BR-43). Chỉ mất khi card bị
xoá (cascade).

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID |
| `card_id` | TEXT NOT NULL | → `card(id)` ON DELETE CASCADE |
| `session_id` | TEXT NOT NULL | → `study_session(id)` |
| `scheduler_type` | TEXT NOT NULL | scheduler tại thời điểm đánh giá |
| `generation` | INTEGER NOT NULL | generation tại thời điểm đánh giá |
| `kind` | TEXT NOT NULL | `'learning'` \| `'scheduled'` \| `'relearning'` (BR-75, BR-76, BR-143) |
| `mode` | TEXT NOT NULL | Chế độ học của lượt (BR-108, BR-98). `browse` không bao giờ xuất hiện ở đây (BR-111) |
| `outcome_reason` | TEXT NULL | `timeout` khi hết giờ ở `recall` (BR-131); NULL khi người dùng tự trả lời |
| `comparison_version` | INTEGER NULL | chỉ `fill`: phiên bản chính sách so khớp đã dùng (BR-135) |
| `used_hint` | INTEGER NULL | chỉ `fill`: 0 \| 1. Ghi nhận, không đổi `action` (BR-136) |
| `direction` | TEXT NULL | `korean_to_meaning` \| `meaning_to_korean` (BR-206). NULL ở mọi lượt ngoài BR-203. **Không bao giờ `mixed`** — phiên trộn, lượt thì không (BR-205) |
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
(BR-76). Suy luận sai ở đúng một ca không hiếm: lượt `scheduled` trên card
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
| `generation` | INTEGER NOT NULL | generation lúc mở phiên (BR-45) |
| `session_kind` | TEXT NOT NULL | `learning` \| `reviewing` (BR-142) |
| `current_mode` | TEXT NOT NULL | stage đang chạy: `browse` \| `self_assess` \| `match` \| `guess` \| `recall` \| `fill` (BR-108, BR-98). Phiên `reviewing` chỉ có một giá trị suốt phiên |
| `status` | TEXT NOT NULL | `in_progress` \| `completed` \| `abandoned` \| `invalidated` \| `failed` (BR-79) |
| `end_reason` | TEXT NULL | `user_exit` \| `scheduler_reset` \| `scheduler_changed` \| `stale_generation` \| `persistence_error` \| `interrupted` \| `content_deleted` (BR-80, BR-259, BR-164). NULL khi `in_progress` hoặc `completed`. **Phạm vi:** `content_deleted` là sub-project sau — Trash |
| `cursor` | INTEGER NOT NULL DEFAULT 0 | số lượt đã phục vụ trong phiên; nền của BR-26 |
| `card_limit` | INTEGER NOT NULL | số thẻ tối đa của phiên, chốt lúc mở (BR-24, BR-139). Mặc định 20 |
| `direction` | TEXT NULL | `korean_to_meaning` \| `meaning_to_korean` \| `mixed` (BR-203, BR-205). Chốt lúc mở và khoá suốt phiên (BR-207). NULL ở mọi phiên ngoài BR-203 |
| `started_at` | DATETIME NOT NULL | UTC |
| `ended_at` | DATETIME NULL | NULL khi `in_progress` |

Ma trận `status` × `end_reason` hợp lệ:

| status | end_reason | Khi nào |
|---|---|---|
| `in_progress` | NULL | phiên đang mở |
| `completed` | NULL | hết queue (BR-81) |
| `abandoned` | `user_exit` | người dùng thoát (BR-82) |
| `abandoned` | `interrupted` | phiên của ngày học trước còn `in_progress` khi mở app (BR-103) |
| `invalidated` | `scheduler_reset` | Reset learning progress chạy khi phiên đang mở (BR-83). **Reset và chỉ reset** — `generation` bị bump |
| `invalidated` | `scheduler_changed` | đổi scheduler khi chưa khoá, phiên đang mở (BR-12, BR-164). **Không phải reset:** generation giữ nguyên, tiến trình học không bị xoá — chỉ hàng đợi được chia lại. Tách khỏi `scheduler_reset` vì đọc riêng cột này không phân biệt được hai sự kiện, dù `generation` vẫn phân biệt được |
| `invalidated` | `stale_generation` | phiên generation cũ cố ghi lượt học (BR-84) |
| `invalidated` | `content_deleted` | deck hoặc card mà phiên đang chạy trên đó bị chuyển vào Trash (BR-259) |
| `failed` | `persistence_error` | lỗi không thể tiếp tục (BR-85) |

Mọi tổ hợp khác là dữ liệu sai.

`generation` ở đây là thứ chặn tình huống: phiên mở trước khi
reset, người dùng quay lại bấm đánh giá sau khi reset. Mọi thao tác ghi so
generation của session với generation hiện tại của root và **từ chối** nếu lệch
(BR-46, BR-84).

Các lượt học đã ghi thành công trước khi phiên kết thúc bất thường **vẫn được giữ**
(BR-86) — chuyển `status` không kéo theo xoá `review_log`.

`interrupted` tách khỏi `user_exit` vì cùng lý do BR-76 lưu `kind` tường minh:
"người dùng bấm thoát" và "hệ điều hành thu hồi app" là hai sự kiện khác nhau, và
gộp chúng làm lịch sử nói rằng người dùng bỏ cuộc trong khi họ không hề.

## `study_queue_items`

**Phạm vi:** V8.0 — hàng đợi phiên học.

Hàng đợi của một phiên (BR-102). Một dòng cho mỗi thẻ được nạp lúc mở phiên.

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `session_id` | TEXT NOT NULL | → `study_session(id)` ON DELETE CASCADE |
| `mode` | TEXT NOT NULL | stage mà dòng này thuộc về (BR-113) |
| `round` | INTEGER NOT NULL DEFAULT 1 | vòng trong stage (BR-115). `browse` và `self_assess` luôn `1` |
| `card_id` | TEXT NOT NULL | → `card(id)` ON DELETE CASCADE |
| `position` | INTEGER NOT NULL | thứ tự trong round đó (BR-23, BR-117). **Bất biến một khi round đã dựng** |
| `status` | TEXT NOT NULL | `pending` \| `completed` (BR-28) |
| `available_at` | INTEGER NOT NULL DEFAULT 0 | mốc `cursor` tối thiểu để thẻ được phục vụ lại (BR-26) |
| `answers_in_session` | INTEGER NOT NULL DEFAULT 0 | số lượt đã đánh giá; `0` ⇒ lượt tới là `scheduled` (BR-77) |
| `remaining_ms` | INTEGER NULL | chỉ `recall`: thời gian còn lại của lượt đang dở (BR-133). NULL ở mọi stage khác |
| `is_revealed` | INTEGER NOT NULL DEFAULT 0 | chỉ `recall`: đáp án đã lật chưa, để Resume không che lại (BR-133) |
| `direction` | TEXT NULL | `korean_to_meaning` \| `meaning_to_korean` — chiều thật của **thẻ này**, gán một lần lúc dựng round (BR-205). NULL ở mọi stage ngoài `self_assess` của một phiên đủ điều kiện (BR-203) |

PK là `(session_id, mode, round, card_id)` — một thẻ xuất hiện đúng một lần **trong
mỗi round của mỗi stage**, và mọi round có thứ tự độc lập (BR-113, BR-117).

Giới hạn thẻ của BR-24 vì thế được đếm trên **tập thẻ riêng biệt của phiên**,
không phải trên số dòng — một phiên 20 thẻ × 5 stage đã là 100 dòng trước khi có
bất kỳ round nào. Xem invariant 18.

### Vì sao là `cursor` + `available_at`, không phải xáo lại `position`

BR-26 bắt thẻ bị quên quay lại "sau ít nhất 3 thẻ khác". Cách thẳng tay là ghi
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
hai của BR-26 ("cuối hàng đợi nếu không đủ 3") — và phục vụ thẻ có `available_at`
nhỏ nhất. Vế đó thành một nhánh query, không phải một `if` ai đó phải nhớ viết.

### Vì sao hàng đợi là dữ liệu, không phải trạng thái tạm

Hàng đợi **mang luật** — thứ tự BR-23, lượt quay lại BR-26, trần BR-104 — và một
cấu trúc mang luật phải nằm ở nơi mọi phép kiểm chạy được chạm tới nó, không
phải một nơi chỉ sống trong bộ nhớ của một màn hình.

Cái được kèm theo: phiên sống sót qua việc app bị hệ điều hành thu hồi (BR-103),
và hàng đợi của phiên đã đóng trở thành dữ liệu thật — "phiên đó gồm những thẻ
nào, bỏ dở bao nhiêu" — thứ nếu không lưu thì không tồn tại ở bất kỳ đâu.

## `app_settings`

**Phạm vi:** V8.0 — mặc định toàn app: tuỳ chọn học và trình bày. Ba cột
`reminder_*` thuộc sub-project sau (xem ghi chú dưới bảng).

Một dòng, cho local profile. Mặc định toàn app của tùy chọn học (BR-147) và hai
tuỳ chọn trình bày (BR-214, BR-215).

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | INTEGER PK | luôn `1`; `CHECK (id = 1)` giữ bảng ở đúng một dòng (BR-210) |
| `card_limit` | INTEGER NOT NULL DEFAULT 20 | trần thẻ **mỗi phiên**, không phải mỗi ngày (BR-24) |
| `new_card_order` | TEXT NOT NULL DEFAULT 'created' | `created` \| `random` (BR-148) |
| `theme_mode` | TEXT NOT NULL DEFAULT 'system' | `system` \| `light` \| `dark` (BR-214) |
| `language` | TEXT NOT NULL DEFAULT 'system' | `system` \| `en` \| `vi` (BR-215) |
| `reminder_enabled` | INTEGER NOT NULL DEFAULT 0 | `0` \| `1`; mặc định tắt (BR-218). `CHECK (reminder_enabled IN (0, 1))` |
| `reminder_minute_of_day` | INTEGER NOT NULL DEFAULT 1200 | phút trong ngày **theo giờ địa phương**, `1200` = 20:00 (BR-219). `CHECK (reminder_minute_of_day BETWEEN 0 AND 1439)` |
| `reminder_last_delivered_at` | DATETIME NULL | lúc notification tóm tắt gần nhất được hiện; NULL nghĩa là chưa lần nào (BR-221). UTC |
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
mà không có gì nói cho họ biết tại sao (BR-219).

Hai cột này chỉ có `CHECK`, không có bất biến trong mục `## Bất biến`. Lý do
giống điều bất biến 12 nói ngược lại: một `CHECK` đã khiến giá trị ngoài miền
không ghi được, nên một bất biến phủ chính miền đó là một test không dựng nổi
vi phạm của chính nó.

**Một bảng một dòng thay vì key-value.** Key-value đọc linh hoạt hơn nhưng mọi
giá trị thành `TEXT` và mọi lần đọc thành một phép ép kiểu không ai kiểm; một
dòng có cột thật thì `drift_dev` type-check ngay lúc build, và thêm một tùy chọn
là một migration — đúng mức nghiêm túc cần có cho thứ đổi hành vi học. BR-210
nâng điều đó lên thành rule, nên một store key-value riêng cho theme và ngôn ngữ
là lựa chọn đã bị loại: nó tách một nửa tuỳ chọn của app sang một store thứ hai,
không có transaction chung với nửa còn lại và không watch được cùng một stream.

**`theme_mode` và `language` giữ lựa chọn, không giữ kết quả đã giải.** `'system'`
là một lựa chọn thật, khác hẳn với việc lưu `'light'` vì hôm nay platform đang
sáng: giá trị đã giải hết đúng ngay khi người dùng đổi cài đặt hệ điều hành, và
không có cách nào phân biệt được nó với một lựa chọn tường minh.

**`language` chứ không phải `locale`.** Cột giữ đúng ba giá trị của BR-215, không
phải một BCP-47 tag đầy đủ — chưa có variant, script hay region nào trong
`supportedLocales`, và một cột hứa hẹn nhiều hơn thứ nó nhận là một cột sẽ được
ai đó ghi `vi-VN` vào.

**Ghi đè nằm ở `deck.study_config`, không ở đây.** Deck root MAY mang JSON ghi
đè; deck con MUST NOT (BR-147), cùng quy tắc cột scheduler đã theo từ BR-06. Giá
trị hiệu lực = giá trị của root nếu có, ngược lại giá trị bảng này. Đổi bảng này
MUST NOT ghi `study_config`, và xoá `study_config` MUST NOT ghi bảng này
(BR-212).

## `deck_templates`

**Phạm vi:** sub-project sau — Starter decks. Bảng giữ ở đây để nghiệp vụ không
phải đào lại.

**Đây không phải bảng runtime** — template là asset JSON:

```
assets/templates/
├── manifest.json
└── vi/
    └── starter_fixture_a.json
```

| Trường | Ghi chú |
|---|---|
| `template_id` | ổn định giữa các phiên bản app (BR-32) |
| `version` | tăng khi nội dung đổi |
| `locale` | `vi`, `en`, … |
| `title` | tên hiển thị |
| `content_source` | nguồn gốc nội dung, cho ghi công và kiểm tra bản quyền |
| `default_scheduler_type` | scheduler gợi ý; người dùng đổi được trước lượt học đầu |

Template mô tả **cả cây deck**, không chỉ một danh sách card, vì bản sao phải
dựng lại đúng cấu trúc `content_type` và `root_id`.

Nội dung starter hiện tại là **fixture do dự án tự tạo, chỉ phục vụ development
và test** (BR-87). Không mô tả nó như nội dung production ở bất kỳ đâu — UI, store
listing, hay tài liệu.

---

## `delete_batches`

**Phạm vi:** sub-project sau — Trash.

Một hàng cho mỗi **lần xoá** của người dùng (BR-256). Hàng của `deck`/`card`
không bị chép đi đâu cả — chúng chỉ nhận `delete_batch_id`.

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID sinh phía client |
| `item_type` | TEXT NOT NULL | `'card'` \| `'deck'` — loại của **item root**, tức thứ người dùng đã chạm (BR-266) |
| `root_item_id` | TEXT NOT NULL | id của card hoặc deck đó. Không phải FK: hai bảng đích, và cascade đã đi theo chiều ngược lại |
| `deleted_at` | DATETIME NOT NULL | UTC. Mốc duy nhất của retention 30 ngày (BR-264) |
| `owner_id` | TEXT NULL | NULL = local profile |

```sql
CREATE INDEX idx_delete_batches_deleted ON delete_batches (deleted_at, id);
CREATE INDEX idx_deck_delete_batch ON deck (delete_batch_id);
CREATE INDEX idx_card_delete_batch ON card (delete_batch_id);
```

**`deleted_at` sống ở đây và chỉ ở đây.** Đặt nó lên hàng nữa là hai nguồn sự
thật cho một sự kiện, và không gì bắt chúng bằng nhau; `delete_batch_id IS NULL`
đã trả lời trọn vẹn câu hỏi mà mọi query active cần hỏi.

**Purge là `DELETE FROM delete_batches`,** và FK `ON DELETE CASCADE` từ
`deck.delete_batch_id`/`card.delete_batch_id` xoá hàng của batch; cascade sẵn
có của `card.deck_id`, `card_schedule`, `review_log`, `study_queue_items`
và `card_tags` lo phần còn lại (BR-265). Điều kiện tiên quyết của BR-265 —
không descendant nào thuộc batch chưa eligible — phải được kiểm **trước** khi
xoá, vì cascade theo `parent_id` không biết batch là gì.

## Bất biến — phải kiểm tra được bằng query

Mỗi query dưới đây **phải luôn trả về 0 dòng**. Chúng là đặc tả cho phần kiểm tra
tính toàn vẹn dữ liệu, và là nguồn của các trường hợp kiểm thử.

### Cây deck

**Sáu câu đầu và câu 15 đo `delete_batch_id IS NULL`.** Chúng nói về cây
người dùng đang nhìn thấy, và một tombstone không phải nội dung: không lọc thì
invariant 2 báo vi phạm cho mọi deck vừa được dọn rỗng đúng BR-260, và invariant
29 im lặng cho đúng những deck lẽ ra phải `unset`.

```sql
-- 1. Root deck có card trực tiếp (BR-58)
SELECT c.id FROM card c
JOIN deck d ON d.id = c.deck_id
WHERE d.parent_id IS NULL AND c.delete_batch_id IS NULL;

-- 2. content_type = 'unset' nhưng đã có nội dung (BR-60, BR-62)
SELECT d.id FROM deck d
WHERE d.content_type = 'unset' AND d.delete_batch_id IS NULL
  AND (EXISTS (SELECT 1 FROM card c
               WHERE c.deck_id = d.id AND c.delete_batch_id IS NULL)
    OR EXISTS (SELECT 1 FROM deck s
               WHERE s.parent_id = d.id AND s.delete_batch_id IS NULL));

-- 29. Sub-deck đã rỗng nhưng vẫn mang type (BR-163, BR-260)
--     Chiều ngược của invariant 2: 2 bắt `unset` còn nội dung, 29 bắt type còn
--     lại sau khi nội dung đã đi hết. Root không tham gia — root luôn `deck`
--     (BR-58), và một root rỗng là trạng thái bình thường.
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

-- 3. content_type = 'card' nhưng có deck con (BR-63)
SELECT d.id FROM deck d
WHERE d.content_type = 'card' AND d.delete_batch_id IS NULL
  AND EXISTS (SELECT 1 FROM deck s
              WHERE s.parent_id = d.id AND s.delete_batch_id IS NULL);

-- 4. content_type = 'deck' nhưng có card trực tiếp (BR-64)
SELECT d.id FROM deck d
WHERE d.content_type = 'deck' AND d.delete_batch_id IS NULL
  AND EXISTS (SELECT 1 FROM card c
              WHERE c.deck_id = d.id AND c.delete_batch_id IS NULL);

-- 5. Root deck không mang content_type = 'deck'
SELECT d.id FROM deck d
WHERE d.parent_id IS NULL AND d.content_type <> 'deck';

-- 6. Descendant trỏ sai root (BR-72)
--    root_id của một deck phải bằng root_id của cha nó.
SELECT d.id FROM deck d
JOIN deck p ON p.id = d.parent_id
WHERE d.root_id <> p.root_id;

-- 7. Root deck không tự trỏ về chính nó (BR-56)
SELECT d.id FROM deck d
WHERE d.parent_id IS NULL AND d.root_id <> d.id;

-- 8. Cycle trong cây (BR-69)
--    Đi ngược từ mỗi deck lên tới root; gặp lại chính mình là cycle.
WITH RECURSIVE up(start_id, node_id, depth) AS (
  SELECT id, parent_id, 1 FROM deck WHERE parent_id IS NOT NULL
  UNION ALL
  SELECT u.start_id, d.parent_id, u.depth + 1
  FROM up u JOIN deck d ON d.id = u.node_id
  WHERE u.node_id IS NOT NULL AND u.depth < 64
)
SELECT DISTINCT start_id FROM up WHERE node_id = start_id;

-- 15. Deck sâu hơn 10 cấp (BR-55)
--     Đi xuống từ mỗi root, root là cấp 1. Chỉ hàng đang active: một subtree
--     đã nằm trong Trash không được tính vào giới hạn của cây đang sống, và
--     restore mới là nơi độ sâu của nó được thẩm định lại (BR-261).
WITH RECURSIVE levels(id, depth) AS (
  SELECT id, 1 FROM deck
  WHERE parent_id IS NULL AND delete_batch_id IS NULL
  UNION ALL
  SELECT d.id, l.depth + 1
  FROM deck d JOIN levels l ON d.parent_id = l.id
  WHERE l.depth < 64 AND d.delete_batch_id IS NULL
)
SELECT id FROM levels WHERE depth > 10;

-- 9. Card study state không cùng scheduler hoặc generation với root (BR-48, BR-49)
SELECT s.card_id FROM card_schedule s
JOIN card c ON c.id = s.card_id
JOIN deck d ON d.id = c.deck_id
JOIN deck root ON root.id = d.root_id
WHERE s.generation <> root.generation
   OR s.scheduler_type <> root.scheduler_type;

-- 10. Deck con mang cột scheduler (BR-06)
SELECT d.id FROM deck d
WHERE d.parent_id IS NOT NULL
  AND (d.scheduler_type IS NOT NULL OR d.generation IS NOT NULL);

-- 11. Root deck thiếu scheduler (BR-11)
SELECT d.id FROM deck d
WHERE d.parent_id IS NULL
  AND (d.scheduler_type IS NULL OR d.generation IS NULL);

-- 30. Cây đã có thẻ học xong nhưng scheduler chưa khoá (BR-13, BR-144)
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
chưa khoá là dữ liệu sai: BR-13 nói thẻ đầu hoàn tất chuỗi thì scheduler khoá, và
`completeLearning` ghi cả hai trong cùng transaction. Chiều ngược lại — root đã
khoá mà không còn thẻ nào `learned_at` — là **hợp lệ**: người dùng học xong rồi
xoá thẻ cuối, và dấu "cây này đã từng được học" không mất đi vì nội dung bị xoá.
Chỉ Reset mới gỡ khoá (BR-44).

Chú ý query 9 dùng `d.root_id`, **không** dùng `COALESCE(d.parent_id,
d.id)`. Phiên bản cũ của tài liệu này dùng `COALESCE` và sẽ trả về sai root ngay
khi có deck ở cấp thứ ba (BR-57).

### Session

```sql
-- 12. Tổ hợp status × end_reason không hợp lệ (BR-79…BR-85)
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
-- 16. Session completed nhưng hàng đợi còn thẻ chưa xong (BR-81)
SELECT s.id FROM study_session s
WHERE s.status = 'completed'
  AND EXISTS (SELECT 1 FROM study_queue_items q
              WHERE q.session_id = s.id AND q.status = 'pending');

-- 17. Bộ đếm của hàng đợi âm, hoặc lượt vượt trần BR-104
--     Trần 3 lượt relearning chỉ áp cho `self_assess` (BR-26, BR-104): 1 lượt
--     scheduled + 3 relearning = 4. Bốn stage chấm điểm lặp bằng round và
--     không có trần (BR-119), nên chúng không bị ràng buộc này.
SELECT session_id FROM study_queue_items
WHERE available_at < 0 OR answers_in_session < 0 OR round < 1
   OR (mode = 'self_assess' AND answers_in_session > 4);

-- 24. Thẻ đã xong học mới nhưng không có lịch (BR-144, BR-149)
SELECT card_id FROM card_schedule
WHERE learned_at IS NOT NULL AND due_at IS NULL;

-- 28. Thẻ chưa xong học mới mà đã có lịch (BR-144)
--     Chiều ngược của invariant 24, và nó lọt qua cả 24 lẫn 25: một thẻ có thể
--     mang `due_at` mà chưa từng có lượt `scheduled` nào nếu đường ghi nào đó
--     đặt lịch giữa chuỗi học mới. BR-144 nói chuỗi MUST NOT làm thế.
SELECT card_id FROM card_schedule
WHERE learned_at IS NULL AND due_at IS NOT NULL;

-- 25. Thẻ chưa xong học mới mà đã có lượt `scheduled` (BR-144, BR-149)
--     Chuỗi học mới ghi `learning`/`relearning` và không đổi lịch; một lượt
--     `scheduled` ở đây nghĩa là lịch đã bị đặt giữa chừng.
SELECT a.id FROM review_log a
JOIN card_schedule s ON s.card_id = a.card_id
WHERE a.kind = 'scheduled' AND s.learned_at IS NULL;

-- 26. `kind = 'learning'` nằm ngoài phiên học mới (BR-143)
SELECT a.id FROM review_log a
JOIN study_session ss ON ss.id = a.session_id
WHERE a.kind = 'learning' AND ss.session_kind <> 'learning';

-- 27. Tùy chọn học nằm trên deck con (BR-147)
SELECT id FROM deck
WHERE parent_id IS NOT NULL AND study_config IS NOT NULL;

-- 23. Cột đặc thù `fill` xuất hiện ở stage khác (BR-135, BR-136)
SELECT id FROM review_log
WHERE mode <> 'fill' AND (comparison_version IS NOT NULL OR used_hint IS NOT NULL);

-- 21. Trạng thái timer nằm ngoài `recall`, hoặc vượt ngưỡng 20 giây (BR-128, BR-133)
SELECT session_id FROM study_queue_items
WHERE (mode <> 'recall' AND (remaining_ms IS NOT NULL OR is_revealed <> 0))
   OR remaining_ms < 0 OR remaining_ms > 20000;

-- 22. `outcome_reason = timeout` ở stage không phải `recall` (BR-131)
SELECT id FROM review_log
WHERE outcome_reason IS NOT NULL
  AND (outcome_reason <> 'timeout' OR mode <> 'recall');

-- 31. Chiều hỏi nằm ngoài chỗ nó được phép (BR-203, BR-205)
--     Bốn cách sai: một phiên mang chiều mà không phải `reviewing`/`self_assess`;
--     một dòng hàng đợi mang chiều ở stage khác `self_assess`; một dòng mang
--     chiều mà phiên của nó không mang; và một phiên có chiều mà dòng
--     `self_assess` của nó lại trống — `mixed` gán cho **mọi** thẻ.
--
--     **Không có mệnh đề `sm2`, và đó là chủ ý.** `study_session` không mang
--     `scheduler_type`; đọc thuật toán *hiện tại* của cây thì sai với đúng cây
--     đã Reset sang thuật toán khác — nó vẫn từng chạy `sm2`, và BR-21 đặt cột
--     ấy lên `review_log` chính vì lý do này. Điều kiện `sm2` vì thế thuộc
--     write path (BR-208), không thuộc một câu SQL đọc sau.
SELECT s.id FROM study_session s
WHERE (s.direction IS NOT NULL
       AND (s.session_kind <> 'reviewing' OR s.current_mode <> 'self_assess'))
   OR EXISTS (SELECT 1 FROM study_queue_items q
              WHERE q.session_id = s.id
                AND ((q.direction IS NOT NULL AND q.mode <> 'self_assess')
                  OR (q.direction IS NOT NULL AND s.direction IS NULL)
                  OR (s.direction IS NOT NULL AND q.mode = 'self_assess'
                      AND q.direction IS NULL)));

-- 32. Lượt lịch sử mang chiều mà dòng hàng đợi của nó không mang (BR-206)
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

-- Bất biến 33-37: Phạm vi sub-project sau — Trash. Giữ số và nghĩa, có hiệu
-- lực từ khi delete_batches triển khai.

-- 33. Card đang active nằm trong một deck đã xoá (BR-256, BR-258)
--     Xoá một deck đánh dấu mọi descendant đang active, và restore luôn gắn
--     item vào một target đang active — nên không đường ghi nào tạo ra được
--     hàng này. Đây là bất biến mà toàn bộ chiến lược loại trừ một cột đứng
--     trên: nếu nó vỡ, "hàng còn sống ⇔ delete_batch_id IS NULL" không còn đúng
--     và mọi query active bắt đầu nói dối.
SELECT c.id FROM card c
JOIN deck d ON d.id = c.deck_id
WHERE c.delete_batch_id IS NULL AND d.delete_batch_id IS NOT NULL;

-- 34. Deck đang active nằm dưới một deck đã xoá (BR-256, BR-258)
SELECT d.id FROM deck d
JOIN deck p ON p.id = d.parent_id
WHERE d.delete_batch_id IS NULL AND p.delete_batch_id IS NOT NULL;

-- 35. Batch không còn hàng nào (BR-265)
--     Purge xoá batch và để cascade dọn hàng, nên chiều ngược lại — hàng biến
--     mất mà batch còn — chỉ xảy ra khi một cascade theo parent_id đã đi
--     xuyên qua một batch mà điều kiện tiên quyết của BR-265 lẽ ra phải chặn.
SELECT b.id FROM delete_batches b
WHERE NOT EXISTS (SELECT 1 FROM deck d WHERE d.delete_batch_id = b.id)
  AND NOT EXISTS (SELECT 1 FROM card c WHERE c.delete_batch_id = b.id);

-- 36. Tombstone bị xoá SAU tổ tiên đã xoá của nó (BR-258)
--     Descendant luôn bị đánh dấu trước hoặc cùng lúc với tổ tiên, vì không
--     thao tác nào chạm tới được thứ đã bị ẩn. Thứ tự đó là cái làm cho
--     "batch eligible thì mọi descendant của nó cũng eligible" đúng, và BR-265
--     dựa vào điều đó.
SELECT d.id FROM deck d
JOIN deck p ON p.id = d.parent_id
JOIN delete_batches db ON db.id = d.delete_batch_id
JOIN delete_batches pb ON pb.id = p.delete_batch_id
WHERE db.deleted_at > pb.deleted_at;

-- 37. Batch không trỏ về một item root mang chính batch đó (BR-256)
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

-- 19. Round nhảy số: stage có round N nhưng thiếu round N-1 (BR-115)
SELECT q.session_id FROM study_queue_items q
WHERE q.round > 1
  AND NOT EXISTS (SELECT 1 FROM study_queue_items p
                  WHERE p.session_id = q.session_id AND p.mode = q.mode
                    AND p.round = q.round - 1);

-- 20. Round sau chứa thẻ không có ở round trước (BR-115)
--     Tập của round N MUST là con của tập round N-1.
SELECT q.session_id FROM study_queue_items q
WHERE q.round > 1
  AND NOT EXISTS (SELECT 1 FROM study_queue_items p
                  WHERE p.session_id = q.session_id AND p.mode = q.mode
                    AND p.round = q.round - 1 AND p.card_id = q.card_id);

-- 18. Một phiên nạp quá số thẻ riêng biệt nó tự khai báo (BR-24, BR-139)
--     So với `card_limit` của **chính phiên đó**, không với một số viết cứng:
--     mặc định là 20 nhưng người dùng sẽ cài được, và một hằng số ở đây sẽ sai
--     ở đúng phiên đầu tiên họ đổi.
--     COUNT(DISTINCT card_id), không COUNT(*): mỗi thẻ có một dòng **mỗi round của
--     mỗi stage** (BR-113, BR-115), nên đếm dòng báo động giả ngay lập tức.
SELECT q.session_id FROM study_queue_items q
JOIN study_session s ON s.id = q.session_id
GROUP BY q.session_id, s.card_limit
HAVING COUNT(DISTINCT q.card_id) > s.card_limit;
```

Invariant 16 là thứ giữ cho `completed` có nghĩa. Không có nó, một phiên bỏ dở
được đánh dấu hoàn thành trông y hệt một phiên học hết — và sự khác nhau đó là
toàn bộ nội dung của BR-81.

### Review log

```sql
-- 14. Lượt relearning làm đổi lịch (BR-78)
SELECT id FROM review_log
WHERE kind = 'relearning'
  AND (previous_box IS NOT next_box
    OR previous_ease_factor IS NOT next_ease_factor
    OR previous_interval_days IS NOT next_interval_days);
```

---

## Quyết định về ID

Toàn bộ khoá chính là TEXT chứa UUID sinh phía client (spec V8 §3). Tạo dữ liệu
offline cần ID trước khi có server, và đổi kiểu khoá chính về sau là migration
đắt nhất có thể.

## Quyết định về thời gian

Mọi cột DATETIME lưu **UTC**. Chuyển sang giờ địa phương chỉ ở lớp hiển thị.

`due_at` so sánh sai một múi giờ nghĩa là card đến hạn sớm hoặc muộn một ngày, và
lỗi đó chỉ xuất hiện với người dùng đi qua múi giờ khác — gần như không bao giờ bị
phát hiện lúc dev.

## Foreign keys

`PRAGMA foreign_keys = ON` trong `beforeOpen`. Không có nó, `ON DELETE CASCADE`
chỉ là chú thích. Cần test: xoá root deck → toàn bộ cây deck con, card, study
state, study answers và study session đều biến mất (BR-03).

## Chưa mô hình hoá

Media được nhắc trong quy tắc reset (BR-41: reset giữ nguyên nó) nhưng **chưa
thuộc V8.0** và chưa có bảng. Khi thêm, nó gắn với `card` và không mang
`generation` — nó là nội dung, và quy tắc "reset không chạm nội dung"
áp dụng nguyên vẹn.
