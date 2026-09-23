# Use cases — Progress

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Đặc tả luồng người dùng của đối tượng PROGRESS, dưới ID vĩnh viễn `UC-PROGRESS-nnn` |
| **Scope** | Luồng xem tiến độ học và tiến độ theo deck. |
| **Source of truth for** | UC-PROGRESS-nnn · main/alternative/error flow · UI state matrix |
| **Depends on** | `../document-conventions.md`, `../product/product.md`, `../business-rules/` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

## UC-PROGRESS-001 · Xem tiến độ học

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Chạm tab **Tiến độ / Progress** ở bottom navigation, hoặc mở deep
link `/progress`
**Preconditions:** Không có. Màn hình mở được kể cả khi chưa từng học một lượt
nào — trạng thái "chưa có gì" là một mặt hợp lệ, không phải lỗi.

**Main flow:**
1. Người dùng mở tab Progress. Hệ thống chụp **một** snapshot của
   `clockProvider` và `utcOffsetProvider` rồi dựng ranh giới ngày theo BR-PROGRESS-013.
2. Hệ thống mở **một** stream đọc lịch sử học, gộp ngay trong SQLite thành các
   hàng *card-day* rồi thành các hàng *active-day* (BR-PROGRESS-011); không tải hàng
   `review_log` thô lên tầng trên và không đọc từng ngày một.
3. Trong lúc chờ emission đầu tiên, màn hình hiện trạng thái loading có nhãn
   cho screen reader.
4. Emission tới. Hệ thống hiển thị ba khối, cùng một snapshot:
   **Current streak** (BR-PROGRESS-016), **Today** với tổng số card cùng phân rã
   Learning/Reviewing (BR-PROGRESS-014), và **Last 7 days** đúng bảy cột theo thứ tự
   cũ → mới, ngày trống là 0 (BR-PROGRESS-015).
   Ba khối này **không chiếm cả màn**: `/progress` là một màn duy nhất, và
   chúng là phần đầu của cấp thư viện trong UC-PROGRESS-002 — cùng một vùng cuộn, dưới
   chúng là bộ chọn khoảng, bảng tổng và danh sách deck. Bố cục chi tiết thuộc
   phạm vi thiết kế UI, ngoài phạm vi tài liệu này; ở đây chỉ ghi rằng hai use
   case dùng chung một màn, vì đọc riêng UC-PROGRESS-001 sẽ hiểu nhầm thành một tab ba khối.
5. Người dùng đọc xong và rời tab. Hệ thống không ghi gì trong toàn bộ luồng
   (BR-PROGRESS-009).

**Alternative flows:**
- **A1 — Hôm nay chưa học nhưng hôm qua có:** Today hiện 0, và streak **vẫn
  giữ** chuỗi kết thúc ở hôm qua (BR-PROGRESS-016). Copy nói rõ đây là chuỗi đang giữ,
  không phải chuỗi đã mất.
- **A2 — Chưa từng học lượt nào:** cả ba khối rỗng. Hệ thống hiện một mặt
  empty của cả màn với CTA thật dẫn sang branch Study, không phải một màn ba
  khối toàn số 0.
- **A3 — Có một lượt mới ghi trong lúc màn đang mở:** người dùng học ở tab khác
  rồi quay lại, hoặc một answer được ghi khi màn còn sống — các con số tự cập
  nhật, không cần Retry và không nháy toàn trang (BR-PROGRESS-018).
- **A4 — Local midnight trôi qua trong lúc màn đang mở:** cửa sổ bảy ngày trượt
  một ngày, Today về 0, và streak chuyển sang nhánh "hôm qua active" của
  BR-PROGRESS-016 — tất cả không cần thao tác nào (BR-PROGRESS-018).
- **A5 — Reset learning progress ở màn khác rồi quay lại:** mọi con số giữ
  nguyên, vì reset không đụng lịch sử (BR-PROGRESS-017).
- **A6 — Xoá một card hoặc một deck ở màn khác rồi quay lại:** hoạt động của
  các card đã xoá biến mất khỏi mọi ngày, kể cả ngày quá khứ (BR-PROGRESS-017).
- **A7 — Chỉ lướt `browse` rồi thoát:** không có gì đổi — `browse` không ghi
  answer nên không tạo hoạt động (BR-PROGRESS-012).

**Error flows:**
- **E1 — Đọc lịch sử thất bại:** hệ thống map exception thành `Failure`; màn
  hình hiện mặt lỗi kèm `Retry`. Thông báo MUST NOT lộ SQL, tên bảng hay nội
  dung card (BR-PRIVACY-002).
- **E2 — Retry vẫn lỗi:** màn hình ở lại mặt lỗi; MUST NOT tự thử lại vòng lặp
  và MUST NOT ghi gì (BR-PROGRESS-009).

**Postconditions:** Database không đổi ở mọi nhánh, kể cả nhánh lỗi và nhánh
Retry (BR-PROGRESS-009). Không session nào được mở, tiếp tục hay đóng.

**Business rules:** BR-PRIVACY-002, BR-STUDY-074, BR-MODE-005, BR-PROGRESS-009, BR-PROGRESS-010, BR-PROGRESS-011, BR-PROGRESS-012,
BR-PROGRESS-013, BR-PROGRESS-014, BR-PROGRESS-015, BR-PROGRESS-016, BR-PROGRESS-017, BR-PROGRESS-018

**UI states:** loading · loaded-normal (có hoạt động trong cửa sổ) ·
loaded-today-zero-streak-retained (A1) · empty-lifetime + CTA sang Study (A2) ·
error + Retry (E1/E2). Live refresh (A3) và midnight rollover (A4) là **chuyển
tiếp giữa hai loaded**, không phải state thứ sáu; luật cấm hạ màn về loading khi
đã có dữ liệu nằm ở BR-PROGRESS-018.

---

## UC-PROGRESS-002 · Xem tiến độ theo deck

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Mở tab Progress, hoặc chạm một hàng deck trên màn hình tiến độ
**Preconditions:** Không có. Thư viện rỗng và thư viện chưa học lần nào đều là
trạng thái hợp lệ và có màn hình riêng.

**Main flow:**
1. Người dùng mở tab Progress. Hệ thống hiển thị **cấp thư viện** ngay dưới
   ba khối tổng quan của UC-PROGRESS-001 — cùng một màn `/progress`, một vùng cuộn: bộ
   chọn khoảng 7/30 ngày, một bảng tổng cho toàn bộ dữ liệu, và một hàng cho
   mỗi root deck (BR-PROGRESS-003). Chỉ cấp thư viện có phần đầu đó; `/progress/:deckId`
   là cấp của một deck và mở thẳng vào bộ chọn.
2. Mỗi hàng mang tên deck, đường dẫn của nó khi có, và bốn số của khoảng đang
   chọn: số thẻ đã học, số ngày có học, số card-day học mới và số card-day ôn
   tập (BR-PROGRESS-001, BR-PROGRESS-002, BR-PROGRESS-005). Số của một hàng phủ **toàn bộ subtree** của
   deck đó (BR-PROGRESS-004).
3. Danh sách sắp theo số thẻ đã học giảm dần, tie-break bằng tên đã fold rồi
   id; deck chưa học gì vẫn hiện và đứng cuối (BR-PROGRESS-006).
4. Người dùng chạm `30 ngày`. Mọi số trên màn hình và thứ tự danh sách đổi ngay
   sang khoảng dài hơn — không có lần đọc thứ hai và không có trạng thái loading
   (BR-PROGRESS-003, BR-PROGRESS-006).
5. Người dùng chạm một hàng. Hệ thống mở **cấp của deck đó**: cùng bố cục, tổng
   của riêng subtree đó, và một hàng cho mỗi deck con trực tiếp. Back trả về
   đúng cấp vừa rời, ở mọi độ sâu.
6. Trong lúc màn hình mở, một lượt học được ghi ở nơi khác — hoặc một thẻ được
   chuyển deck, hoặc một deck bị xoá — thì các số tự cập nhật (BR-PROGRESS-008).

**Alternative flows:**
- **A1 — Deck chứa thẻ chứ không chứa deck con:** cấp đó không có hàng nào để
  liệt kê. Hệ thống vẫn hiện bộ chọn và bảng tổng của chính deck đó, kèm một
  dòng nói rằng tổng ở trên đã là toàn bộ — vì cấp này **không** rỗng, nó chỉ
  không có gì để đi sâu thêm.
- **A2 — Thư viện chưa có deck nào:** hệ thống chỉ hiện empty state và **không**
  hiện bộ chọn hay bảng tổng: không có deck thì không có khoảng nào để có gì
  xảy ra trong đó. Không có nút hành động — bước tiếp theo nằm ở tab Thư viện,
  và một nút nhảy tab từ màn hình tiến độ đọc như một đường vòng.
- **A3 — Có deck nhưng khoảng đang chọn không có hoạt động nào:** danh sách
  **vẫn liệt kê đủ mọi deck** với các số 0, và bảng tổng mang thêm một dòng
  giải thích cùng gợi ý đổi sang khoảng dài hơn (BR-PROGRESS-006). Trạng thái này trung
  tính: không dùng màu lỗi, không trách móc.
- **A4 — Nửa đêm địa phương đi qua khi màn hình đang mở:** cửa sổ trượt một
  ngày và hệ thống tự đọc lại, dù không có write nào trong database (BR-PROGRESS-003,
  BR-PROGRESS-008).

**Error flows:**
- **E1 — Đọc dữ liệu thất bại:** hệ thống hiện lý do đã localize theo **kiểu**
  failure — không bao giờ là `Failure.message` — cùng `Try again`, và nói rõ
  lịch sử học không bị ảnh hưởng vì đọc tiến độ không ghi gì (BR-PROGRESS-007). Retry mở
  lại lần đọc từ đầu.
- **E2 — Deck của deep link không còn tồn tại:** đây **không** phải lỗi. Hệ
  thống hiện một empty state riêng và chỉ đề nghị đường quay lại cấp thư viện;
  `Try again` cố ý vắng mặt vì đọc lại sẽ thất bại y hệt.

**Postconditions:** Database không đổi — nội dung, timestamp, `content_type`,
study state, history, cờ và tag đều nguyên vẹn, và không session nào được mở
hay đóng (BR-PROGRESS-007).

**Business rules:** BR-SRS-023, BR-PRIVACY-001, BR-DECK-001, BR-DECK-002, BR-DECK-003, BR-SRS-015, BR-STUDY-074, BR-PROGRESS-001,
BR-PROGRESS-002, BR-PROGRESS-003, BR-PROGRESS-004, BR-PROGRESS-005, BR-PROGRESS-006, BR-PROGRESS-007, BR-PROGRESS-008

**UI states:** loading · mixed activity (một số deck có, một số không) ·
all-zero (có deck, khoảng rỗng) · no decks (cấp thư viện) · no sub-decks (cấp
deck chứa thẻ) · read error + retry · deck missing + đường quay lại. Không có
state "empty selection": bộ chọn luôn có đúng một khoảng được chọn.
