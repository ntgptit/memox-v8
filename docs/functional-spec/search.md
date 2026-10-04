# Search — functional specification

Các chức năng của feature search. Định dạng: [docs/README.md](../README.md), mục "UC, FN và screen
spec". Search không có failure type riêng: lỗi đọc database đi theo mô hình lỗi của ADR-016.

## FN-SEARCH-001 — Tìm trong toàn thư viện
Status: active · Code: [lib/features/search/domain/usecases/search_library_use_case.dart, lib/features/search/domain/models/library_search_model.dart, lib/features/search/domain/models/search_cursor_model.dart, lib/features/search/domain/models/search_hit_model.dart]

### Precondition

Không có. Thư viện rỗng vẫn tìm được, và không có kết quả nào.

### Input

- Từ cần tìm: văn bản tự do.
- Con trỏ của trang cuối cần đọc tới: không có nghĩa là trang đầu.

### Kết quả

Từ cần tìm được chuẩn hoá bằng đúng hàm gập chữ mà các cột đã lưu dùng (bỏ khoảng trắng hai đầu,
không phân biệt hoa thường). Gập ra rỗng thì kết quả là **chưa tìm**, và không gì được đọc.

Ngược lại, một stream các kết quả từ trang đầu tới con trỏ đã cho, mỗi trang 50 dòng, phát lại sau
mỗi lần ghi có thể làm kết quả đổi (đổi tên, di chuyển, xoá, đổi tên tag):

- **Deck** đứng trước **card**. Chỉ bốn trường được tìm: tên deck, mặt trước và mặt sau của card,
  và tên tag của card — không bao giờ example, hint hay phiên âm.
- Mỗi nhóm xếp theo bậc khớp: khớp đúng, rồi khớp tiền tố, rồi khớp chứa; bậc của một card là bậc
  tốt nhất trong các trường nó khớp. Hoà thì theo văn bản đã gập, rồi `created_at`, rồi `id`, nên
  thứ tự là toàn phần.
- Một kết quả deck mang tên deck, các deck tổ tiên từ root xuống và loại nội dung của deck. Một kết
  quả card mang mặt trước, mặt sau, deck chứa nó cùng các tổ tiên, và tên tag đã làm nó khớp
  **chỉ** khi không mặt nào khớp. Mỗi card xuất hiện đúng một lần dù khớp qua nhiều trường.
- Con trỏ để đọc thêm một trang, hoặc không có khi không còn gì phía sau. Trang sau nối theo con
  trỏ, không theo vị trí, nên một lần ghi xen giữa hai trang không làm lặp hay sót dòng.

Không ghi gì, và không phiên học nào được mở.

### Lỗi

- Đọc database thất bại: stream báo lỗi; đọc lại với cùng con trỏ là thử lại.

### Business rules

- BR-DECK-003
- BR-SEARCH-001
- BR-SEARCH-002
- BR-SEARCH-003
- BR-SEARCH-004
- BR-SEARCH-005
- BR-SEARCH-006
- BR-SEARCH-007
- BR-SEARCH-008
- BR-SEARCH-009
- BR-TAG-001
