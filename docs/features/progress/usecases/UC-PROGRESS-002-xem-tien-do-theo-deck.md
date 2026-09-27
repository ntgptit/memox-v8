---
id: UC-PROGRESS-002
title: Xem tiến độ theo deck
status: ready
rules: [BR-DECK-001, BR-DECK-002, BR-DECK-003, BR-CORE-001, BR-PROGRESS-001, BR-PROGRESS-002, BR-PROGRESS-003, BR-PROGRESS-004, BR-PROGRESS-005, BR-PROGRESS-006, BR-PROGRESS-007, BR-PROGRESS-008, BR-SRS-015, BR-SRS-023, BR-STUDY-074]
code: [lib/features/progress/domain/usecases/watch_progress_use_case.dart, lib/features/progress/domain/usecases/watch_deck_progress_use_case.dart, lib/features/progress/presentation/screens/progress_screen.dart, lib/features/progress/presentation/screens/deck_progress_screen.dart, lib/features/progress/presentation/providers/deck_progress_provider.dart, lib/features/progress/presentation/providers/progress_range_provider.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Mở tab Progress, hoặc chạm một hàng deck trên màn hình tiến độ
**Preconditions:** Không có. Thư viện rỗng và thư viện chưa học lần nào đều là
trạng thái hợp lệ và có màn hình riêng.

## Main flow

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

## Alternative / Error flow

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

## UI

**UI states:** loading · mixed activity (một số deck có, một số không) ·
all-zero (có deck, khoảng rỗng) · no decks (cấp thư viện) · no sub-decks (cấp
deck chứa thẻ) · read error + retry · deck missing + đường quay lại. Không có
state "empty selection": bộ chọn luôn có đúng một khoảng được chọn.

## Local

**Postconditions:** Database không đổi — nội dung, timestamp, `content_type`,
study state, history, cờ và tag đều nguyên vẹn, và không session nào được mở
hay đóng (BR-PROGRESS-007).

## API

Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/decisions/ADR-001-quyet-dinh-nen-tang.md)).

## Acceptance criteria

- [ ] **Given** thư viện có ít nhất một root deck, **when** mở tab Progress, **then** cấp thư viện hiện bộ chọn 7/30 ngày, một bảng tổng cho toàn bộ dữ liệu, và một hàng cho mỗi root deck với bốn số của nó, sắp theo số thẻ đã học giảm dần rồi tên đã fold rồi id; deck chưa học vẫn hiện và đứng cuối (BR-PROGRESS-001, BR-PROGRESS-002, BR-PROGRESS-004, BR-PROGRESS-005, BR-PROGRESS-006).
- [ ] **Given** cấp thư viện hoặc cấp một deck đang mở ở khoảng 7 ngày, **when** người dùng chạm "30 ngày", **then** mọi số và thứ tự danh sách đổi ngay sang khoảng 30 ngày, không có state loading (BR-PROGRESS-003).
- [ ] **Given** người dùng chạm một hàng deck, **when** cấp của deck đó mở ra, **then** hệ thống hiện tổng của riêng subtree deck đó và một hàng cho mỗi deck con trực tiếp; back trả về đúng cấp vừa rời.
- [ ] **Given** cấp của một deck đang mở, **when** một lượt học được ghi, một deck con đổi tên, hoặc deck bị xoá ở nơi khác, **then** các số trên màn tự cập nhật (BR-PROGRESS-008).
- [ ] **Given** một deck chỉ chứa thẻ (không có deck con), **when** mở cấp của deck đó, **then** hệ thống vẫn hiện bộ chọn và bảng tổng của chính deck đó kèm dòng nói rõ tổng ở trên đã là toàn bộ, không hiện danh sách hàng nào (A1).
- [ ] **Given** thư viện chưa có deck nào, **when** mở tab Progress, **then** hệ thống chỉ hiện empty state, không hiện bộ chọn khoảng và không hiện bảng tổng (A2).
- [ ] **Given** có deck nhưng khoảng đang chọn không có hoạt động nào, **when** đọc xong, **then** danh sách vẫn liệt kê đủ mọi deck với số 0, và bảng tổng có thêm dòng gợi ý đổi sang khoảng dài hơn (BR-PROGRESS-006, A3).
- [ ] **Given** cấp thư viện hoặc cấp một deck đang mở gần nửa đêm, **when** local midnight trôi qua, **then** cửa sổ của khoảng đang chọn trượt một ngày và hệ thống tự đọc lại mà không có write nào trong database (BR-PROGRESS-003, BR-PROGRESS-008, A4).
- [ ] **Given** lần đọc tiến độ theo deck thất bại, **when** màn hình nhận lỗi, **then** hệ thống hiện mặt lỗi chung kèm Retry, và Retry đọc lại (E1).
- [ ] **Given** deep link tới `/progress/:deckId` của một deck đã bị xoá, ở trong Trash, hoặc không tồn tại, **when** mở màn, **then** hệ thống hiện một empty state riêng chỉ với đường quay lại cấp thư viện, không hiện Retry (E2).
- [ ] OPEN QUESTION: E1 nói lý do hiện ra được localize theo kiểu failure — code luôn hiện cùng một tiêu đề và thân lỗi chung (`progressErrorTitle`, `progressErrorBody`) bất kể kiểu failure (`lib/features/progress/presentation/screens/deck_progress_screen.dart:47-54`) (E1).
