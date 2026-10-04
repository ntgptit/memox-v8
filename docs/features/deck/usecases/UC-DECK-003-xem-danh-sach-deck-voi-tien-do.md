---
id: UC-DECK-003
title: Xem danh sách deck với tiến độ
status: ready
rules: [BR-DECK-002, BR-DECK-003, BR-DECK-011, BR-DECK-026, BR-DECK-027, BR-STUDY-008, BR-STUDY-051]
code: [lib/features/deck/domain/usecases/watch_deck_level_use_case.dart, lib/features/deck/domain/usecases/watch_deck_use_case.dart, lib/features/deck/domain/models/deck_level_model.dart, lib/features/deck/domain/models/deck_level_query_model.dart]
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Mở app, hoặc quay về từ màn khác
**Preconditions:** Không có

## Main flow

**Main flow:**
1. Hệ thống lấy toàn bộ root deck kèm số card đến hạn — **một query gộp** theo
   `root_id`, không phải N+1 query và không duyệt cây trong Dart.
2. Người dùng thấy mỗi deck với tên, tổng số card trong cây, **hai** số của
   BR-STUDY-046 — card chưa học (New) và card đến hạn (Due), không bao giờ gộp — và
   chế độ ôn tập đang dùng.
3. Deck có card đến hạn được làm nổi bật bằng **cả biểu tượng lẫn chữ**, không
   chỉ bằng màu. Deck tile hiển thị **total Due + New**; biểu tượng lớn phân ba
   trạng thái lịch theo BR-STUDY-067 — chưa đến hạn (outlined, neutral), đến hạn hôm
   nay (filled, vai time-pressure vàng/streak), quá hạn (missed + badge số ngày,
   cặp error container đỏ) — khác nhau bằng hình dạng/fill/badge chứ không chỉ
   màu. Hero level summary breakdown thành bốn tập rời nhau
   Overdue/Due today/New/Scheduled theo BR-STUDY-068 — lưới 2×2, mỗi hàng căn theo
   alphabetic baseline; Scheduled là tập trung tính, không actionable và không
   bao giờ là primary metric.
4. Mỗi deck có một thanh mastery: số thẻ `mastered` trên mọi thẻ của cây
   (BR-DECK-026). Deck rỗng chỉ vẽ track. Thanh không có chữ, nên hàng đọc
   "{n}% mastered" cho trình đọc màn hình.
5. Mở một deck chứa deck con hiển thị ở tóm tắt một donut mastery của cả level,
   cạnh dòng "Mastered · {thuật toán}".
6. Mở một deck hiển thị nội dung theo `content_type`: danh sách deck con, hoặc
   danh sách card, không bao giờ cả hai (BR-DECK-011).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Chưa có deck nào:** empty state với hai lối đi — thư viện starter (UC-STARTER-001)
  hoặc tạo deck mới (UC-DECK-001).
- **A2 — Dữ liệu đổi ở màn khác:** danh sách tự cập nhật qua stream từ Drift,
  không cần refresh thủ công.
- **A3 — Cây sâu nhiều cấp:** điều hướng xuống từng cấp; số liệu gộp luôn tính
  theo `root_id` (BR-DECK-002, BR-DECK-003).
- **A4 — Sắp xếp và lọc:** Manual, Newest, Name, Most due hoặc Progress
  (BR-DECK-027), cùng bộ lọc chỉ giữ deck có thẻ đến hạn. Mọi sort kết thúc bằng
  thứ tự thủ công.

**Error flows:**
- **E1 — Đọc thất bại:** màn hình lỗi có nút thử lại.

## UI

**UI states:** loading · loaded · empty · error

## Local

**Postconditions:** Không đổi gì — use case chỉ đọc.

Ghi chú từ mục "Business rules" của nguồn:

BR-STUDY-051 — hai tập "chưa học" và "đến hạn" phải khớp **hệt** UC-STUDY-001, nếu
không con số ở danh sách sẽ lệch với số card thực sự ôn được. Dùng chung một
named query. Ngoài ra BR-DECK-002, BR-DECK-003, BR-DECK-011.

## API

Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/decisions/ADR-001-quyet-dinh-nen-tang.md)).

## Acceptance criteria

- [ ] **Given** nhiều root deck với card ở nhiều cấp, **when** danh sách deck tải hoặc phát lại, **then** mỗi lần phát chỉ chạy đúng một câu lệnh gộp theo `root_id`, không phải một câu mỗi deck, kể cả khi cây sâu nhiều cấp (BR-DECK-002, BR-DECK-003, A3).
- [ ] **Given** deck có card mới, card đến hạn hôm nay và card quá hạn, **when** xem danh sách, **then** số New và số Due hiện tách biệt, không bao giờ gộp, và Due bằng Overdue cộng Due today (BR-STUDY-051).
- [ ] **Given** cây có N card active trong đó M card `mastered`, **when** xem hàng deck, **then** thanh mastery vẽ theo tỉ lệ M/N và hàng đọc phần trăm cho trình đọc màn hình; deck không có card chỉ vẽ track và không đọc phần trăm (BR-DECK-026).
- [ ] **Given** một card `mastered` đang ở Trash, **when** tính mastery của deck chứa nó, **then** card đó không được tính ở cả tử số lẫn mẫu số (BR-DECK-026).
- [ ] **Given** một deck `content_type = 'deck'`, **when** mở nó, **then** màn hiện danh sách deck con; một deck `content_type = 'card'` thì hiện danh sách card; không màn nào hiện cả hai (BR-DECK-011).
- [ ] **Given** không deck nào có card đến hạn, **when** xem danh sách, **then** trạng thái được trình bày bình thường, không phải lỗi (BR-STUDY-008).
- [ ] **Given** chưa có deck nào, **when** mở danh sách, **then** hệ thống hiện empty state với hai lối: tạo deck mới và mở thư viện starter (A1).
- [ ] **Given** danh sách đang mở, **when** dữ liệu đổi ở nơi khác (thêm card, card thành `mastered`, deck mới), **then** danh sách tự cập nhật mà không cần làm mới tay (A2).
- [ ] **Given** các deck có mastery khác nhau và có deck không có card, **when** chọn sort Progress, **then** deck sắp theo mastery tăng dần, deck không có card đứng cuối, và hai deck bằng nhau giữ thứ tự thủ công (BR-DECK-027, A4).
- [ ] **Given** bộ lọc chỉ-deck-có-thẻ-đến-hạn đang bật và không deck nào có thẻ đến hạn, **when** xem danh sách, **then** danh sách rỗng và nói rõ lý do (A4).
- [ ] **Given** đọc dữ liệu lỗi, **when** tải danh sách, **then** hệ thống hiện lỗi bằng lời thường kèm Retry, và Retry tải lại (E1).
