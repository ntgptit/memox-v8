# Business rules — Tìm kiếm toàn thư viện

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Phát biểu luật nghiệp vụ của đối tượng SEARCH, dưới ID vĩnh viễn `BR-SEARCH-nnn` |
| **Scope** | Luật tìm kiếm toàn thư viện (Global Library Search). |
| **Source of truth for** | BR-SEARCH-nnn của đối tượng này |
| **Depends on** | `../document-conventions.md`, `../product/product.md` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

## Tìm kiếm toàn thư viện

Global Library Search (UC-SEARCH-001). Các rule dưới đây **không** phát biểu lại luật
nội dung card (BR-CARD-001, BR-CARD-002, BR-CARD-003), luật tag (BR-TAG-001) hay luật riêng tư chung
(BR-PRIVACY-001…BR-PRIVACY-004) — chúng chỉ nói phần mà việc tìm kiếm thêm vào.

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-SEARCH-001 | active | Tìm kiếm MUST bao phủ đúng bốn trường: tên deck, mặt trước card, mặt sau card và tên tag. MUST NOT tìm trong `example`, `hint`, `pronunciation`, dữ liệu scheduler, study state hay review history. Deck và card đã bị xoá MUST NOT xuất hiện; khi Trash tồn tại (feature riêng), nội dung soft-deleted MUST bị loại bằng cùng một predicate đặt ở một chỗ duy nhất. | rule + store | UC-SEARCH-001, BR-TAG-001 |
| BR-SEARCH-002 | active | Cả câu truy vấn lẫn dữ liệu được so sánh MUST đi qua **một** hàm chuẩn hoá dùng chung — trim rồi hạ chữ theo Unicode của Dart. SQL MUST NOT dùng `lower()` hay `COLLATE NOCASE` để thay thế: chúng chỉ fold ASCII, nên `CÔNG NGHỆ` sẽ không tìm được bằng `công nghệ`. Chuẩn hoá MUST là case-only; MUST NOT bỏ dấu. | rule + store | UC-SEARCH-001, BR-TAG-001 |
| BR-SEARCH-003 | active | Câu truy vấn chuẩn hoá thành rỗng MUST trả về trạng thái ban đầu và MUST NOT phát sinh bất kỳ statement nào tới database. Truy vấn có nội dung MUST được debounce **250ms** ở seam provider/controller, MUST NOT debounce bên trong widget nhập liệu. Xoá trắng ô tìm kiếm MUST có hiệu lực ngay, không chờ hết cửa sổ debounce. Mỗi lần đọc MUST có định danh riêng; kết quả hoặc lỗi đến sau khi truy vấn đã đổi MUST bị bỏ. Rời màn hình MUST huỷ cửa sổ đang chờ. | UI | UC-SEARCH-001 |
| BR-SEARCH-004 | active | Trong mỗi nhóm, kết quả MUST xếp theo ba bậc khớp: khớp đúng toàn bộ, khớp tiền tố, rồi khớp chứa. Bậc của một card MUST là bậc **tốt nhất** trong các trường nó khớp (front, back, tag). MUST NOT dùng điểm số suy đoán: thứ tự phải giải thích được và phải ổn định giữa hai lần đọc. | rule + store | UC-SEARCH-001 |
| BR-SEARCH-005 | active | Kết quả MUST được chia hai nhóm và trình bày theo thứ tự **Deck trước, Card sau**. Một trang MUST lấp đầy bằng deck trước; card MUST NOT xuất hiện khi nhóm deck chưa hết. Hai nhóm MUST NOT đan xen nhau ở bất kỳ trang nào. | rule + UI | UC-SEARCH-001 |
| BR-SEARCH-006 | active | Một card khớp nhiều trường hoặc nhiều tag MUST chỉ sinh **một** kết quả. Việc gộp MUST xảy ra ở tầng truy vấn bằng phép gộp tương quan, MUST NOT dựa vào `DISTINCT` sau một phép JOIN nhân bản hàng. | store | UC-SEARCH-001, BR-TAG-001 |
| BR-SEARCH-007 | active | Phân trang MUST là keyset. Khoá phân trang MUST gồm đúng bốn thành phần theo đúng thứ tự sắp xếp: bậc khớp, văn bản đã fold dùng để sắp, `created_at`, rồi `id` — nên thứ tự là toàn phần và không hai hàng nào bằng nhau. MUST NOT dùng `OFFSET`. Một lần ghi xen giữa hai trang MUST NOT làm lặp hàng hay bỏ sót hàng. | store | UC-SEARCH-001 |
| BR-SEARCH-008 | active | Kết quả MUST là chỉ-đọc: MUST NOT ghi bất cứ gì và MUST NOT mở phiên học. Đổi tên deck tổ tiên, di chuyển card hoặc deck, đổi tên tag và xoá MUST cập nhật kết quả cùng đường dẫn đang hiển thị mà không cần thao tác thủ công. Mở một kết quả deck MUST đi tới màn deck tương ứng; mở một kết quả card MUST đi tới màn chi tiết card ở chế độ đọc và MUST NOT đi tới màn sửa card. Khi route chi tiết card chưa tồn tại, hệ thống MUST khai báo đích đến bằng một kiểu dữ liệu và nói rõ là chưa mở được, MUST NOT dựng màn chi tiết thứ hai và MUST NOT âm thầm thay bằng màn khác. | store + UI | UC-SEARCH-001, BR-DECK-009 |
| BR-SEARCH-009 | active | MUST NOT thêm bảng FTS hay index mới cho tìm kiếm khi chưa có `EXPLAIN QUERY PLAN` và số đo trên dữ liệu ở quy mô thực chứng minh là cần. Việc đọc MUST NOT theo kiểu N+1: đường dẫn của mọi kết quả trên một trang MUST dẫn xuất từ một lần đọc cây deck duy nhất, và tag của mọi card trên trang MUST đến từ chính statement đã lấy card. | store | UC-SEARCH-001 |
