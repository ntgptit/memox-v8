---
id: UC-SEARCH-001
title: Tìm kiếm toàn thư viện
status: ready
rules: [BR-DECK-001, BR-DECK-002, BR-DECK-003, BR-DECK-009, BR-SEARCH-001, BR-SEARCH-002, BR-SEARCH-003, BR-SEARCH-004, BR-SEARCH-005, BR-SEARCH-006, BR-SEARCH-007, BR-SEARCH-008, BR-SEARCH-009, BR-TAG-001]
code: []
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Bấm biểu tượng tìm kiếm ở header của Library, ở bất kỳ cấp nào
**Preconditions:** Không có. Thư viện rỗng vẫn mở được màn tìm kiếm.

## Main flow

**Main flow:**
1. Hệ thống mở màn tìm kiếm như một route con của nhánh Library — thanh dưới còn
   nguyên, Back trả về đúng cấp vừa rời — và đưa con trỏ vào ô nhập ngay.
2. Trước khi gõ, màn hình nói rõ tìm được những gì: tên deck, mặt trước và mặt
   sau của card, tên tag. Chưa có statement nào chạy (BR-SEARCH-003).
3. Người dùng gõ. Sau 250ms im lặng, hệ thống chuẩn hoá câu truy vấn bằng đúng
   hàm fold mà các cột đã lưu dùng (BR-SEARCH-002) và đọc **một trang** kết quả.
4. Kết quả hiện thành hai mục — Deck trước, Card sau (BR-SEARCH-005). Mỗi mục xếp theo
   khớp đúng → khớp tiền tố → khớp chứa, phần bằng nhau phá hoà bằng tên đã fold,
   `created_at` rồi `id` (BR-SEARCH-004, BR-SEARCH-007).
5. Một dòng deck hiển thị đường dẫn tổ tiên phía trên tên. Một dòng card hiển thị
   đường dẫn deck chứa nó, mặt trước, một dòng tóm tắt mặt sau, và tên tag đã làm
   nó khớp khi card khớp **chỉ** qua tag (BR-SEARCH-006).
6. Mở một kết quả deck đi tới deck đó. Mở một kết quả card đi tới chi tiết card ở
   chế độ đọc (BR-SEARCH-008).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Còn kết quả phía sau:** cuối danh sách có hành động tải thêm; trang kế
  tiếp nối bằng keyset nên không lặp và không sót hàng (BR-SEARCH-007).
- **A2 — Chỉ có deck, hoặc chỉ có card:** mục không có kết quả không được vẽ tiêu
  đề rỗng.
- **A3 — Dữ liệu đổi ở màn khác:** đổi tên, di chuyển, xoá hoặc đổi tên tag cập
  nhật ngay kết quả và đường dẫn đang hiển thị (BR-SEARCH-008).
- **A4 — Xoá trắng ô nhập:** về trạng thái ban đầu ngay lập tức, không chờ
  debounce và không đọc gì (BR-SEARCH-003).

**Error flows:**
- **E1 — Trang đầu đọc lỗi:** màn hình lỗi có nút thử lại; danh sách để trống, vì
  kết quả của truy vấn cũ nằm dưới một thông báo lỗi là lời nói dối.
- **E2 — Trang sau đọc lỗi:** giữ nguyên những gì đã tìm được, chỉ dải cuối danh
  sách đổi thành thông báo và nút thử lại.

## UI

**UI states:** initial (chưa gõ) · debouncing · loading trang đầu · mixed ·
decks-only · cards-only · no results · loading trang sau · lỗi trang sau · lỗi
trang đầu

## Local

**Postconditions:** Không đổi gì — use case chỉ đọc, và không mở phiên học nào
(BR-SEARCH-008).

Ghi chú từ mục "Business rules" của nguồn:

BR-SEARCH-001, BR-SEARCH-002, BR-SEARCH-003, BR-SEARCH-004, BR-SEARCH-005, BR-SEARCH-006, BR-SEARCH-007,
BR-SEARCH-008, BR-SEARCH-009. Ngoài ra BR-DECK-001…BR-DECK-003 cho đường dẫn, BR-DECK-009 cho việc mở một deck
chứa card, và BR-TAG-001 cho danh tính tag.


## API

Không áp dụng — ứng dụng local-only, không network ([quyết định nền tảng](../../../product/product.md#platform-decisions)).

## Acceptance criteria

- [ ] OPEN QUESTION: nguồn chưa có acceptance criteria dạng Given/When/Then; Postconditions giữ nguyên văn ở `## Local`.
