# Business rules — Trash và restore

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Phát biểu luật nghiệp vụ của đối tượng TRASH, dưới ID vĩnh viễn `BR-TRASH-nnn` |
| **Scope** | Luật Trash và restore (soft-delete). |
| **Source of truth for** | BR-TRASH-nnn của đối tượng này |
| **Depends on** | `../document-conventions.md`, `../product/product.md` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

**Phạm vi:** sub-project sau — Trash (spec §2).

## Trash và restore

**Phạm vi:** sub-project sau — Trash (spec §2).

Soft-delete thay thế delete cứng cho **card và deck** — nhưng chỉ **từ khi
sub-project này triển khai**. Trong V8.0, xoá card hoặc deck vẫn là xoá cứng
theo cascade đúng như BR-DECK-022/BR-DECK-023 phát biểu nguyên văn; chưa rule nào dưới đây
chi phối hành vi hiện tại. Các rule dưới đây **không** phát biểu lại BR-DECK-022/BR-DECK-023
(xoá deck kéo theo cả cây) hay BR-DECK-015 (`content_type` tự về `unset`) — chúng
nói phần mà tombstone thêm vào, và **khi Trash triển khai**, BR-TRASH-001… sẽ đổi
"kéo theo cả cây" của BR-DECK-022 thành *đánh dấu* cả cây chứ không *xoá* cả cây.

Từ vựng: **batch** là một lần xoá của người dùng, mang một id riêng; **item root**
là chính card/deck người dùng đã chạm; **tombstone** là hàng còn nguyên trong
`card`/`deck` nhưng mang `delete_batch_id`; **purge** là xoá cứng vĩnh viễn.

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-TRASH-001 | active | Xoá card hoặc deck MUST là soft-delete trong **một** transaction và MUST NOT xoá cứng bất cứ hàng nào, kể cả descendant. Thao tác MUST tạo đúng một batch mang `deleted_at` và một item root. UI MUST nói item đã được chuyển vào Trash, MUST NOT nói đã xoá vĩnh viễn, và với thao tác xoá **một** item MUST cung cấp Undo ngay tại chỗ. Xoá nhiều item cùng lúc MUST tạo một batch cho mỗi item root, MUST NOT gộp thành một batch chung — mỗi item root là một thứ người dùng khôi phục được riêng. | store + UI | UC-TRASH-001, BR-DECK-022, BR-DECK-023 |
| BR-TRASH-002 | active | Card/deck/subtree đã soft-delete MUST bị loại khỏi mọi bề mặt active: Library và deck level, Card List, search, mọi đếm (card count, new/due/overdue/learned, sub-deck count), study eligibility và hàng đợi phiên, Progress, đếm card của tag, move target, import duplicate check và export. MUST NOT có màn hình nào tự vá điều này bằng lọc riêng: loại trừ MUST nằm trong chính query, và mọi query đọc `card`/`deck` MUST hoặc mang điều kiện loại trừ tombstone hoặc nằm trong allowlist có lý do kiểm tra được. | store | UC-TRASH-001, BR-CARD-010, BR-TRANSFER-003, BR-TRANSFER-007 |
| BR-TRASH-003 | active | Xoá một deck MUST đánh dấu deck đó cùng **mọi descendant đang active** — deck lẫn card — bằng **cùng một** batch và cùng một `deleted_at`. Descendant đã ở Trash từ một batch trước MUST giữ nguyên tombstone cũ và MUST NOT được gộp vào batch mới; restore batch mới MUST NOT hồi sinh chúng. Quan hệ batch MUST được lưu trên hàng, MUST NOT suy ra từ parent hiện tại. | store | UC-TRASH-001, BR-DECK-022 |
| BR-TRASH-004 | active | Soft-delete MUST giữ nguyên nội dung card, `card_schedule`, `review_log`, quan hệ tag và id của mọi hàng cho tới khi purge. Phiên `in_progress` chạm tới item vừa bị xoá — phiên của chính deck đó hoặc phiên có card đó trong hàng đợi — MUST bị đóng **trong cùng transaction** với `status = invalidated` và `end_reason = content_deleted`; lý do MUST được lưu, MUST NOT suy ra sau. Hàng đợi MUST NOT phục vụ một card đã bị ẩn. | store | UC-TRASH-001, BR-STUDY-010, BR-STUDY-011, BR-STUDY-017 |
| BR-TRASH-005 | active | Khi soft-delete lấy đi direct child **đang active** cuối cùng của một deck non-root, deck đó MUST tự về `content_type = unset` trong cùng transaction. Root MUST giữ `deck` (BR-DECK-004). MUST NOT có thao tác reset thủ công. Tombstone còn nằm trong deck MUST NOT được tính là nội dung khi đo điều kiện này. | store | UC-TRASH-001, BR-DECK-015, BR-DECK-004 |
| BR-TRASH-006 | active | Restore MUST hỏi target và MUST NOT ghi gì trước khi người dùng xác nhận. Target của một card MUST là deck đang active, non-root, `content_type` là `card` hoặc `unset`, và cùng root với card đó (BR-CARD-010). Target của một **sub-deck** MUST thoả **đúng** bộ luật của move (BR-DECK-001 độ sâu, BR-DECK-009/BR-DECK-010 loại nội dung, BR-DECK-017/BR-SRS-006 scheduler và generation của root) — MUST NOT có bộ luật thứ hai dành riêng cho restore. Item root là một **root deck** MUST chỉ có đúng một target hợp lệ là **top level**, vì root không có cha (BR-DECK-002) và move không áp dụng cho root; target đó vẫn MUST được người dùng xác nhận, và MUST NOT được chấp nhận cho bất kỳ item nào khác. Target `unset` MUST được set sang loại tương ứng trong chính transaction restore. Restore vi phạm bất kỳ điều kiện nào MUST bị từ chối bằng lý do có kiểu và MUST NOT ghi một phần. | rule + store | UC-TRASH-001, BR-DECK-001, BR-DECK-002, BR-DECK-009, BR-DECK-010, BR-DECK-017, BR-SRS-006, BR-CARD-010 |
| BR-TRASH-007 | active | Restore một batch MUST hồi sinh **đúng** những hàng mang batch đó và MUST NOT chạm hàng của batch khác. Id, nội dung, study state, history và tag MUST giữ nguyên. Vị trí cũ MUST NOT được chọn tự động; UI MAY preselect một target hợp lệ nhưng người dùng MUST xác nhận. Restore một deck MUST viết lại `root_id` cho **toàn bộ** subtree của nó, gồm cả tombstone nằm bên trong, để cây không có hàng nào trỏ sai root. | store | UC-TRASH-001, BR-DECK-018, BR-DECK-019 |
| BR-TRASH-008 | active | Undo là thao tác đảo ngược **một** batch vừa được tạo và MUST đưa mọi hàng của batch đó về đúng vị trí cũ, không hỏi target. Undo MUST áp dụng lại đầy đủ các điều kiện của BR-TRASH-006 lên vị trí cũ và MUST bị từ chối bằng lý do có kiểu khi vị trí cũ không còn hợp lệ — MUST NOT im lặng đặt vào chỗ khác. Undo MUST NOT khả dụng cho thao tác xoá nhiều item. | store + UI | UC-TRASH-001, BR-TRASH-001, BR-TRASH-006 |
| BR-TRASH-009 | active | Retention là **30 × 24 giờ** tính từ `deleted_at`. Một batch eligible để purge khi `now - deleted_at >= 30 ngày`; đúng biên 30 ngày MUST là eligible. Auto-purge MUST chạy khi app khởi động, khi resume và khi mở Trash, MUST idempotent, và MUST NOT phụ thuộc vào việc người dùng có mở Trash hay không. Thời điểm MUST đến từ clock được inject; mọi layer MUST NOT gọi `DateTime.now()`. | store | UC-TRASH-001 |
| BR-TRASH-010 | active | Purge MUST xoá cứng đúng các hàng của batch eligible và cascade sang study state, history, hàng đợi phiên và quan hệ tag của chúng. Purge MUST NOT chạy nếu bất kỳ descendant nào của hàng bị purge thuộc một batch **chưa** eligible hoặc còn đang active — batch đó MUST bị bỏ qua, MUST NOT bị purge một phần. Lỗi ở bất kỳ bước nào MUST rollback toàn bộ transaction và MUST để lại đồ thị deck ở trạng thái nhất quán. | store | UC-TRASH-001, BR-TRASH-009 |
| BR-TRASH-011 | active | Chọn nhiều trong Trash MUST tách theo loại item: một thao tác Restore hoặc Purge MUST NOT trộn card và deck. Purge vĩnh viễn MUST đi qua xác nhận mạnh nêu **đúng số lượng** item và nói rõ lịch sử học không khôi phục được. Vai trò màu destructive MUST chỉ dành cho purge vĩnh viễn; MUST NOT dùng cho soft-delete hay cho Restore. Focus mặc định của hộp thoại purge MUST là hành động an toàn. | UI | UC-TRASH-001, BR-CARD-012 |
| BR-TRASH-012 | active | Nội dung trong Trash là dữ liệu riêng tư cùng mức nội dung card (BR-PRIVACY-001, BR-PRIVACY-002): MUST NOT log nội dung card ở bất kỳ level nào, kể cả trong đường xoá, restore và purge. Trash MUST hiển thị đường dẫn gốc của item **chỉ như thông tin**, MUST NOT trình bày nó như nơi item sẽ được khôi phục về. | store + UI | UC-TRASH-001, BR-PRIVACY-001, BR-PRIVACY-002 |

BR-TRASH-003 nói "MUST NOT suy ra từ parent hiện tại" vì hai batch chồng nhau trong
cùng một subtree là trạng thái hợp lệ và bình thường: xoá một card hôm nay, xoá
deck chứa nó tuần sau. Parent trả lời *nó ở đâu*, không trả lời *nó đi cùng ai*.

BR-TRASH-002 là rule duy nhất trong tài liệu này bắt một *hình dạng thực thi* chứ không
chỉ một kết quả. Lý do là kinh nghiệm: một luật "đừng hiển thị X" trải trên sáu
mươi query sẽ đúng ở năm mươi chín chỗ, và chỗ thứ sáu mươi là chỗ không ai nhìn.
