# Use cases — Study session

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Đặc tả luồng người dùng của đối tượng STUDY, dưới ID vĩnh viễn `UC-STUDY-nnn` |
| **Scope** | Luồng ôn tập một deck, mở tab Study, chọn chiều hỏi self-assess. |
| **Source of truth for** | UC-STUDY-nnn · main/alternative/error flow · UI state matrix |
| **Depends on** | `../document-conventions.md`, `../product/product.md`, `../business-rules/` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

## UC-STUDY-001 · Ôn tập một deck — luồng chính

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Người dùng bấm Study trên một deck. Đây là **cách duy nhất** một phiên được tạo — badge, danh sách và thông báo số đến hạn không tạo phiên (BR-STUDY-020)
**Preconditions:** Deck tồn tại và có ít nhất một thẻ thuộc một trong hai tập của BR-STUDY-051

Đây là luồng chạy hằng ngày và là vertical slice đầu tiên nên xây.

**Hai loại phiên, không phải một.** *Học mới* đưa thẻ chưa biết qua chuỗi stage và
kết thúc bằng việc khởi tạo lịch; *ôn tập* đưa thẻ đến hạn qua **một** cách hỏi
do người dùng chọn và cập nhật lịch. Chúng không bao giờ trộn thẻ (BR-STUDY-051).

**Main flow:**
1. Người dùng bấm Study. Còn phiên `in_progress` của cùng ngày học thì màn chọn có
   thêm đường **tiếp tục phiên đó**; chọn một trong hai đường bên dưới sẽ đóng nó
   lại (BR-STUDY-072). Hệ thống đếm hai tập, **không trộn** (BR-STUDY-051):
   **học mới** = thẻ `learned_at IS NULL`; **ôn tập** = thẻ `learned_at IS NOT
   NULL AND due_at <= now`. Cả hai hiện kèm số lượng.
2. Tập ôn tập rỗng ⇒ lối đó không mở được, kèm thời điểm thẻ gần nhất đến hạn
   (BR-STUDY-008, BR-STUDY-054). Không có thao tác nào ôn sớm hơn hạn.
3. **Chọn Học mới** — hệ thống lấy tối đa `card_limit` thẻ chưa học, theo
   `new_card_order` của tùy chọn hiệu lực (BR-STUDY-056, BR-STUDY-057), rồi tạo
   `study_session` với `session_kind = 'learning'` và chuỗi stage của thuật toán
   (BR-MODE-003, BR-MODE-004). Người dùng **không chọn** stage.
4. **Chọn Ôn tập** — hệ thống hiện các mode chấm điểm của thuật toán: `eight_box`
   → `match`, `guess`, `recall`, `fill`; `sm2` → `self_assess` (BR-STUDY-055). `browse`
   không có mặt. Mỗi mode hiện **số thẻ của riêng nó** (BR-STUDY-044) — `fill` chỉ nhận
   thẻ có `example` — và mode không đủ dữ liệu bị vô hiệu hoá kèm lý do (BR-MODE-009,
   BR-STUDY-045). Chỉ còn một mode thì vào thẳng, không hiện màn chọn. Sau khi
   chọn, hệ thống lấy **toàn bộ** thẻ đến hạn theo `due_at` tăng dần, tối đa
   `card_limit` (BR-STUDY-002, BR-STUDY-003), và tạo phiên với `session_kind = 'reviewing'`.
5. Cả hai loại phiên ghi `card_limit` đã dùng vào phiên (BR-STUDY-024) và dựng hàng đợi
   trong cùng transaction (BR-STUDY-021, BR-STUDY-022).
6. Người dùng trả lời một thẻ. Nguồn của `action` tùy mode: `self_assess` lấy
   **trực tiếp từ người dùng** qua `supportedActions` — 2 nút với `eight_box`, 4 với
   `sm2` (BR-STUDY-009); bốn mode chấm điểm chấm ra kết quả **nhị phân** rồi ánh xạ theo
   BR-MODE-012 (BR-MODE-011). Hệ thống **so `session.generation` với generation hiện
   tại của root** (BR-SRS-026); lệch thì đi E4.
7. Hệ thống xác định `kind` và ghi tường minh (BR-SRS-015):
   - phiên `learning` ⇒ `learning`, hoặc `relearning` nếu là lượt lặp trong round;
     **không đổi lịch** (BR-STUDY-023, BR-STUDY-052, BR-STUDY-053);
   - phiên `reviewing` ⇒ `scheduled` ở lượt đầu của thẻ, `relearning` ở các lượt
     lặp (BR-STUDY-023).
8. Lượt `scheduled` tính trạng thái mới bằng thuật toán (BR-SRS-008/BR-SRS-009 hoặc
   BR-SRS-011/BR-SRS-012) và cập nhật study state, `answer_count`, `lapse_count`. Lượt
   `learning` và `relearning` chỉ cập nhật `last_answered_at`.
9. Hệ thống ghi một dòng `review_log` kèm `kind` (BR-SRS-019) — ngay lập tức
   (BR-STUDY-004).
10. **Chỉ ở phiên `learning`:** thẻ đi hết **stage cuối mà chính nó tham gia** — stage
    bỏ qua nó theo BR-STUDY-071 không được tính — ⇒ hệ thống đặt `learned_at`
    và khởi tạo lịch ở mức thấp nhất — `eight_box` box 1, `sm2` interval 1 — với
    `due_at` là đầu ngày học kế tiếp (BR-STUDY-053, BR-STUDY-074). Đây là **một sự kiện,
    không phải một lượt đánh giá**, nên không có `action` nào được ghi.
11. Nếu đây là thẻ **đầu tiên hoàn tất chuỗi học mới** của root ở generation này,
    hệ thống đặt `first_answered_at` → thuật toán bị khoá từ đây (BR-SRS-003).
12. Nếu action khác `forgotten`/`again`, card rời hàng đợi (BR-STUDY-007).
13. Hết hàng đợi: session → `completed`, `end_reason = NULL`, `ended_at` được đặt
    (BR-STUDY-013). Hiện tổng kết.

**Alternative flows:**
- **A1 — Thẻ trả lời sai:** cách nó quay lại **tùy mode**, không tùy loại phiên.
  Với `self_assess`: quay lại trong cùng hàng đợi sau ít nhất 3 thẻ khác, trần 3
  lượt (BR-STUDY-005, BR-STUDY-073). Với bốn mode chấm điểm: thẻ ở lại tập không đạt và quay lại
  ở **round sau**, không trần (BR-STUDY-059, BR-STUDY-069) — xem A0c.
- **A0 — Hết hàng đợi của một stage (chỉ phiên `learning`):** hệ thống chuyển
  `current_mode` sang stage kế trong `stageSequence` và chạy tiếp trên **cùng tập
  thẻ**, với thứ tự xoáo riêng (BR-STUDY-022). Hết stage cuối mới là hết phiên (BR-STUDY-013).
  Phiên `reviewing` chỉ có một mode, nên hết hàng đợi là hết phiên.
- **A0c — Hết một round của stage chấm điểm:** tập thẻ không đạt rỗng thì stage
  hoàn tất (BR-STUDY-069); còn thẻ thì dựng round mới **chỉ từ tập đó**, với thứ tự xoáo
  riêng (BR-STUDY-059, BR-STUDY-061). Thẻ từng sai trong round vẫn thuộc tập đó kể cả khi sau
  đó làm đúng (BR-STUDY-060). Không có trần số round.
- **A0b — Thẻ không đủ dữ liệu cho stage đang chạy:** bỏ qua **có ghi nhận** ở stage
  đó, không xoá khỏi deck, và vẫn xuất hiện ở các stage khác mà nó đủ dữ liệu
  (BR-STUDY-071) — ví dụ thẻ không có `example` thì vắng ở `fill` nhưng có ở `guess`.
- **A2b — Thẻ chạm trần 3 lượt `relearning` ở `self_assess`:** thẻ rời hàng đợi dù
  lượt cuối vẫn là `forgotten`/`again`, và hệ thống bật cờ đánh dấu (BR-STUDY-073).
  Trong phiên `reviewing`, lịch đã được đặt ở lượt `scheduled` đầu nên thẻ vẫn đến
  hạn lại sớm. Trong phiên `learning`, thẻ chưa có lịch và cũng chưa `learned_at`,
  nên nó ở lại tập học mới — cờ là dấu cho lần sau. Cờ chỉ được bật, không bao
  giờ tự tắt (BR-CARD-009).
- **A2 — Card quay lại được đánh giá lần nữa:** lượt đó là `relearning` (BR-SRS-017).
  Ghi history và cập nhật `last_answered_at`, nhưng không đổi lịch. Đánh giá khác
  `forgotten`/`again` thì rời hàng đợi; lại `forgotten`/`again` thì quay lại lần
  nữa.
- **A3 — Thoát giữa phiên:** session → `abandoned`, `end_reason = user_exit`,
  `ended_at` được đặt (BR-STUDY-014). Mọi đánh giá đã ghi **vẫn giữ** (BR-STUDY-004, BR-STUDY-019).
  Hàng đợi **được lưu** (BR-STUDY-021), nên xem A3b.
- **A3b — Mở lại app khi còn phiên `in_progress`:** cùng ngày học thì cho tiếp
  đúng hàng đợi đó — đúng thẻ đang dở, đúng thứ tự, đúng số lượt đã dùng. Ngày
  học khác thì phiên đó chuyển `abandoned` với `end_reason = interrupted`, và
  người dùng dựng phiên mới (BR-STUDY-072). App bị hệ điều hành thu hồi rơi vào
  đúng nhánh này, và nó khác `user_exit`: người dùng không hề bỏ cuộc.
- **A4 — Còn card quá hạn ngoài giới hạn 50:** ở tổng kết nói rõ còn bao nhiêu và
  cho phép bắt đầu phiên tiếp theo ngay.
- **A5 — Xoá deck đang ôn dở:** kết thúc phiên, quay về danh sách.

**Error flows:**
- **E1 — Không còn card nào đến hạn lúc bắt đầu:** empty state tích cực (BR-STUDY-008),
  kèm thời điểm card gần nhất đến hạn. **Không** phải màn hình lỗi, và **không**
  tạo session.
- **E2 — Ghi đánh giá thất bại nhưng còn tiếp tục được:** hiện lỗi ngay, **không**
  chuyển sang card tiếp theo. Người dùng thử lại action đó. Chuyển tiếp khi chưa
  ghi được là âm thầm mất tiến độ.
- **E3 — Lỗi ghi không thể tiếp tục:** session → `failed`,
  `end_reason = persistence_error` (BR-STUDY-018). Các lượt đã ghi thành công **vẫn giữ**
  (BR-STUDY-019). Hiện lỗi và đưa người dùng về danh sách deck.
- **E4 — Generation của session đã lỗi thời** (root bị reset ở màn khác trong lúc
  phiên đang mở): **từ chối ghi**, session → `invalidated`,
  `end_reason = stale_generation` (BR-STUDY-017). Thông báo phiên đã hết hiệu lực vì tiến
  độ học vừa được đặt lại, đóng phiên và quay về danh sách. **Không** ghi bất kỳ
  phần nào của đánh giá đó.
- **E5 — Đọc card thất bại:** màn hình lỗi có nút thử lại.

**Postconditions:**
- Mỗi card đã đánh giá có trạng thái lịch đúng loại lượt, đúng scheduler và đúng
  generation.
- Mỗi lượt đánh giá có đúng một dòng `review_log` mang `kind`,
  `scheduler_type` và `generation` tại thời điểm đó.
- `first_answered_at` của root khác NULL sau khi **thẻ đầu tiên hoàn tất chuỗi
  học mới** (bước 10–11, BR-SRS-003, BR-STUDY-053) — **không** phải sau lượt `scheduled`
  đầu tiên. Một phiên `reviewing` chỉ chạy được trên thẻ đã có `learned_at`,
  nên tới lúc đó cột này đã được đặt rồi.
- `study_session.status` và `end_reason` phản ánh đúng cách phiên kết thúc, theo
  ma trận ở `data-model.md`.
- Nếu E4 xảy ra, **không** có dòng history nào được ghi cho lượt đó.

**Business rules:** BR-SRS-003, BR-SRS-008, BR-SRS-009, BR-SRS-010, BR-SRS-011, BR-SRS-012, BR-SRS-018, BR-SRS-019, BR-STUDY-001, BR-STUDY-002, BR-STUDY-003, BR-STUDY-004, BR-STUDY-005, BR-STUDY-006, BR-STUDY-007, BR-STUDY-008, BR-STUDY-009, BR-SRS-025, BR-SRS-026, BR-SRS-014, BR-SRS-015, BR-SRS-016, BR-SRS-017, BR-STUDY-010, BR-STUDY-011, BR-STUDY-013, BR-STUDY-014, BR-STUDY-015, BR-STUDY-017, BR-STUDY-018, BR-STUDY-019
**UI states:** loading · loaded (mặt trước) · loaded (đã lật) · submitting ·
empty · error

`submitting` tách khỏi `loaded` là đúng nguyên tắc "dữ liệu và trạng thái tác vụ
là hai chuyện": trong lúc ghi đánh giá, nội dung card vẫn hiện, chỉ các nút bị
khoá để tránh bấm đúp.

---

## UC-STUDY-002 · Mở tab Study và chọn việc để học

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Chạm tab Study, deep link `/study`, hoặc quay về sau khi kết thúc một phiên
**Preconditions:** Không có

**Main flow:**
1. Hệ thống đọc **một snapshot** gồm session có thể học tiếp và toàn bộ root deck
   kèm workload — cùng một transaction, không phải hai lần đọc rời. Màn
   hình là **chỉ-đọc**: vào tab, cuộn hay đổi tab không ghi gì (BR-PROGRESS-011).
2. Nếu có đúng một session hợp lệ đang mở, Resume card đứng đầu màn hình và nói
   deck nào, loại phiên gì, đang ở chặng nào — cả hai giá trị lấy từ chính hàng
   session, không suy ra (BR-SRS-015, BR-MODE-008).
3. Dưới Resume là danh sách root deck, mỗi hàng có tên deck, nhãn scheduler khi
   biết, ba con số Overdue/Due today/New và **một** hành động Study. Thứ tự giảm
   dần theo ba khoá đó, tie-break theo tên đã fold rồi `id` (BR-STUDY-076).
4. Chạm Resume mở đúng session và đúng lượt đã lưu (BR-STUDY-036), không tạo session
   thứ hai. Chạm Study trên một deck mở study entry của deck đó (UC-STUDY-001), nơi lựa
   chọn giữa học mới và ôn tập mới được đưa ra.
5. Kết thúc, bỏ dở hoặc invalidate một phiên rồi quay lại: danh sách tự cập nhật
   qua stream, không reload cả route và không giữ con số cũ.

**Alternative flows:**
- **A1 — Không có session nào đang mở:** không có Resume card — không phải một
  thẻ rỗng, cũng không phải nút bị vô hiệu hoá.
- **A2 — Session của ngày học cũ, generation đã đổi, deck hoặc card đã bị xoá:**
  không quảng cáo Resume. Việc đóng session cũ vẫn thuộc BR-STUDY-072 và xảy ra khi
  người dùng thực sự vào luồng, không phải khi màn hình này rần.
- **A3 — Mọi deck đều không còn gì đến hạn:** danh sách vẫn hiển thị, kèm một dòng
  nói hiện chưa có thẻ nào tới hạn; deck vẫn mở được để học trước (BR-STUDY-008).
- **A4 — Thư viện chưa có deck nào:** empty state dẫn tới Starter Library (UC-STARTER-001),
  lối thứ hai là về Library.
- **A5 — Có deck nhưng chưa có card nào:** zero state riêng, dẫn về Library để thêm
  thẻ — không phải CTA starter, và không bịa số Due (BR-STUDY-077).

**Error flows:**
- **E1 — Đọc thất bại:** trạng thái lỗi có nút thử lại, không nêu tên bảng, câu truy
  vấn hay đường dẫn. Copy nói rõ không có gì bị thay đổi — đúng theo cấu trúc, vì
  màn hình này không có đường ghi nào.

**Postconditions:** Không đổi gì — use case chỉ đọc. Mọi write phát sinh sau đó đều
thuộc UC-STUDY-001, bắt đầu từ một lần chạm tường minh.

**Business rules:** BR-STUDY-075, BR-STUDY-076, BR-STUDY-077. Ngoài ra BR-STUDY-008, BR-STUDY-017, BR-STUDY-020, BR-STUDY-072,
BR-STUDY-074, BR-STUDY-036, BR-STUDY-051, BR-STUDY-068.
**UI states:** loading · loaded (resume + danh sách) · loaded (không resume) ·
loaded (mọi workload bằng 0) · empty (không deck) · empty (không card) · error

---

## UC-STUDY-003 · Chọn chiều hỏi cho một phiên self-assess

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Bấm `Review` ở Study Entry của một deck chạy `sm2`
**Preconditions:** Root deck của deck đang mở dùng scheduler `sm2` (BR-DECK-025), có ít
nhất một thẻ đến hạn (BR-STUDY-054), và mode ôn duy nhất thuật toán này offer là
`self_assess` (BR-STUDY-055) — ba điều kiện của BR-MODE-013

**Main flow:**
1. Người dùng bấm `Review`. Vì `sm2` chỉ offer một mode, hệ thống bỏ qua màn chọn
   mode (BR-STUDY-055) và mở sheet chọn **chiều hỏi**.
2. Hệ thống hiển thị ba lựa chọn — `Korean first` (gắn nhãn Recommended),
   `Meaning first`, `Mixed` — mỗi lựa chọn kèm một dòng mô tả bằng lời của bài
   tập, và một dòng nói lựa chọn không đổi được sau khi phiên bắt đầu (BR-MODE-017).
3. Người dùng chạm một lựa chọn. Chạm chỉ **chọn**, không mở phiên: lựa chọn bị
   khoá suốt phiên nên một cú chạm nhầm không được phép tiêu mất một phiên
   (BR-MODE-017).
4. Người dùng bấm `Start review`. Hệ thống khoá sheet trong lúc mở phiên — cú
   chạm thứ hai không sinh phiên thứ hai (BR-STUDY-004).
5. Hệ thống mở phiên với chiều đã chọn, materialize hàng đợi trong cùng
   transaction, và gán chiều cho từng dòng: một chiều duy nhất với hai lựa chọn
   cố định, hoặc chia gần đều một lần cho `mixed` (BR-MODE-015).
6. Màn phiên học mở ra. Mỗi thẻ hiện đề ở nửa trên theo chiều của dòng nó, và
   đáp án ở nửa dưới sau khi lật (BR-MODE-014). Tập action vẫn là bốn action của `sm2`
   (BR-STUDY-009) và lịch chạy y như trước (BR-MODE-019).

**Alternative flows:**
- **A1 — Đóng sheet:** người dùng vuốt xuống hoặc chạm ra ngoài. Chưa có gì được
  ghi, nên không có session nào để dọn (BR-STUDY-020, BR-MODE-017); màn Study Entry giữ
  nguyên.
- **A2 — Deck chạy `eight_box`:** sheet này không xuất hiện. Lối vào là màn chọn
  mode của BR-STUDY-055, và không đường nào từ đó dẫn tới chiều hỏi (BR-MODE-013).
- **A3 — Còn phiên bỏ dở:** sheet ba lối của BR-STUDY-072 hiện trước. Chọn `Continue`
  đọc chiều đã lưu và **không** hỏi lại (BR-MODE-017); chọn `Review` kết thúc phiên cũ
  rồi đi vào bước 1.
- **A4 — Phiên `mixed` đang chạy:** hai thẻ liên tiếp có thể hỏi hai chiều khác
  nhau. Đó là đúng bài tập người dùng chọn; chiều của mỗi thẻ đã cố định từ bước
  5 và không đổi khi thẻ quay lại (BR-STUDY-005, BR-MODE-015).

**Error flows:**
- **E1 — Deck đổi scheduler hoặc bị reset trong lúc sheet đang mở:** hệ thống đọc
  lại trước khi mở phiên; nếu `self_assess` không còn được offer thì sheet hiện
  một dòng lỗi và **giữ nguyên lựa chọn**, để người dùng thử lại mà không phải
  chọn lại (BR-SRS-003, BR-STUDY-015).
- **E2 — Không còn thẻ đến hạn tại thời điểm bấm Start:** phiên bị từ chối và
  không ghi dòng nào (BR-STUDY-020, BR-STUDY-054); sheet báo lỗi như E1.
- **E3 — Yêu cầu thiếu chiều:** không thể tạo từ UI này; use case vẫn từ chối là
  validation và không ghi session (BR-MODE-018).

**Postconditions:** `study_session.direction` giữ lựa chọn của phiên,
`study_queue_items.direction` giữ chiều thật của từng thẻ, và mỗi lượt ghi vào
`review_log.direction` chiều chép từ dòng hàng đợi (BR-MODE-016). Nội dung thẻ,
`card.updated_at` và toàn bộ lịch SRS không đổi (BR-MODE-019).

**Business rules:** BR-STUDY-004, BR-STUDY-009, BR-STUDY-020, BR-STUDY-072, BR-STUDY-051, BR-STUDY-054, BR-STUDY-055,
BR-MODE-013, BR-MODE-014, BR-MODE-015, BR-MODE-016, BR-MODE-017, BR-MODE-018, BR-MODE-019

**UI states:** initial (ba lựa chọn, Korean first đã chọn sẵn) · submitting
(Start hiện spinner, ba lựa chọn khoá) · failure (dòng lỗi, lựa chọn giữ nguyên,
Start dùng lại được). Không có state `loading` khi mở sheet — điều kiện khả dụng
đã được đọc trước khi sheet mở; không có state `empty`, vì ba lựa chọn là hằng
số.
