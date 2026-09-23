---
id: UC-DECK-003
title: Xem danh sách deck với tiến độ
status: ready
rules: [BR-DECK-002, BR-DECK-003, BR-DECK-011, BR-STUDY-008, BR-STUDY-051]
code: []
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
4. Mở một deck hiển thị nội dung theo `content_type`: danh sách deck con, hoặc
   danh sách card, không bao giờ cả hai (BR-DECK-011).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Chưa có deck nào:** empty state với hai lối đi — thư viện starter (UC-STARTER-001)
  hoặc tạo deck mới (UC-DECK-001).
- **A2 — Dữ liệu đổi ở màn khác:** danh sách tự cập nhật qua stream từ Drift,
  không cần refresh thủ công.
- **A3 — Cây sâu nhiều cấp:** điều hướng xuống từng cấp; số liệu gộp luôn tính
  theo `root_id` (BR-DECK-002, BR-DECK-003).

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

Không áp dụng — ứng dụng local-only, không network ([quyết định nền tảng](../../../product/product.md#platform-decisions)).

## Acceptance criteria

- [ ] OPEN QUESTION: nguồn chưa có acceptance criteria dạng Given/When/Then; Postconditions giữ nguyên văn ở `## Local`.
