---
id: UC-SEARCH-001
title: Tìm kiếm toàn thư viện
status: ready
rules: [BR-DECK-001, BR-DECK-002, BR-DECK-003, BR-DECK-009, BR-SEARCH-001, BR-SEARCH-002, BR-SEARCH-003, BR-SEARCH-004, BR-SEARCH-005, BR-SEARCH-006, BR-SEARCH-007, BR-SEARCH-008, BR-SEARCH-009, BR-TAG-001]
code: [lib/features/search/domain/usecases/search_library_use_case.dart, lib/features/search/presentation]
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

Không áp dụng — UC chạy trên Drift và không gọi mạng; đồng bộ với server chạy ngoài UC ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md), [ADR-015](../../../shared/decisions/ADR-015-supabase-lam-backend.md)).

## Acceptance criteria

- [ ] **Given** màn tìm kiếm chưa có từ nào, **when** hiển thị, **then** hệ thống nói rõ tìm được tên deck, mặt trước và mặt sau card, và tên tag, và chưa đọc gì (BR-SEARCH-003).
- [ ] **Given** người dùng gõ, **when** 250 ms im lặng trôi qua, **then** từ tìm được fold bằng đúng hàm của các cột đã lưu và đúng một lần đọc trang đầu chạy; từ gõ trước đó không bao giờ được đọc (BR-SEARCH-002, BR-SEARCH-003).
- [ ] **Given** có kết quả, **when** hiển thị, **then** deck đứng trước card, mỗi nhóm có số đếm riêng, và một card chỉ khớp qua mặt trước, mặt sau hoặc tên tag, không bao giờ qua example, hint hay pronunciation (BR-SEARCH-001, BR-SEARCH-005).
- [ ] **Given** nhiều kết quả khớp, **when** xếp hạng, **then** mỗi nhóm xếp khớp đúng trước khớp tiền tố trước khớp chứa, bậc của một card là bậc tốt nhất trong các trường nó khớp, và hoà thì xét văn bản đã fold, rồi `created_at`, rồi `id` (BR-SEARCH-004, BR-SEARCH-007).
- [ ] **Given** một card khớp qua nhiều trường, **when** hiển thị, **then** nó xuất hiện đúng một lần; card chỉ khớp qua tag thì nêu tag khớp tốt nhất; dòng deck có đường dẫn tổ tiên, dòng card có đường dẫn deck chứa nó (BR-SEARCH-006).
- [ ] **Given** một kết quả, **when** chạm, **then** kết quả deck mở deck đó, kết quả card mở chi tiết chỉ đọc của card đó (BR-SEARCH-008).
- [ ] **Given** hơn 50 kết quả, **when** hiển thị, **then** số đếm báo còn nhiều hơn, và tải thêm nối trang kế tiếp theo con trỏ keyset, không lặp và không sót (BR-SEARCH-007, A1).
- [ ] **Given** chỉ một nhóm có kết quả, **when** hiển thị, **then** nhóm còn lại không vẽ tiêu đề rỗng (A2).
- [ ] **Given** deck hoặc tag của một kết quả đang hiện bị đổi tên, di chuyển hoặc xoá ở nơi khác, **when** thay đổi xảy ra, **then** kết quả đang hiện cập nhật tại chỗ mà không cần tìm lại (BR-SEARCH-008, A3).
- [ ] **Given** ô nhập đang có chữ, **when** người dùng xoá trắng, **then** màn về trạng thái ban đầu ngay, không chờ debounce và không đọc gì (BR-SEARCH-003, A4).
- [ ] **Given** đọc trang đầu thất bại, **when** lỗi xảy ra, **then** màn hiện lỗi kèm Retry, không hiện kết quả cũ, và Retry đọc lại từ trang đầu (E1).
- [ ] **Given** đọc một trang sau thất bại, **when** lỗi xảy ra, **then** kết quả đã có giữ nguyên, chỉ cuối danh sách hiện lỗi kèm Retry, và Retry đọc lại đúng con trỏ đó (E2).
