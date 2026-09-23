# Use cases — chỉ mục

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Actor và quy ước dùng chung cho mọi UC, cộng chỉ mục UC theo đối tượng |
| **Scope** | Must-have của MVP. Ngoài phạm vi: should/nice-to-have, và mọi thứ ở mục "Điều đã cố ý không đặc tả" |
| **Source of truth for** | Actor và quy ước UC · danh mục file use-cases theo đối tượng |
| **Depends on** | `../document-conventions.md`, `../product/product.md`, `../business-rules/` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

Chỉ đặc tả must-have. Should-have và nice-to-have viết khi tới lượt — đặc tả
trước những thứ có thể bị cắt là lãng phí.

Luồng viết bằng ngôn ngữ người dùng, không nói theo màn hình hay widget. Màn
hình sẽ đổi; luồng thì không.

**ID use case là định danh vĩnh viễn**, dạng `UC-<CODE>-nnn`, cùng chính sách
đánh số với BR (xem [`../business-rules/README.md`](../business-rules/README.md)).
UC mới append vào số tiếp theo **trong đúng file của đối tượng đó**; không đánh
số lại. Chỉ mục 22 UC hiện có nằm ở bảng "Danh mục file" dưới đây.

**Các UC nối vào nhau thế nào thì xem [`../product/master-flow.md`](../product/master-flow.md).**
Tài liệu này đặc tả từng UC riêng lẻ và cố ý không vẽ đồ thị giữa chúng — mỗi UC
mô tả mình và im lặng về những UC bên cạnh, nên câu "xong bước này thì đi đâu"
không có chỗ nào ở đây trả lời. Cạnh của đồ thị đó là thứ `master-flow.md` sở
hữu; nó tham chiếu ngược về đây bằng ID và không phát biểu lại luồng nào.

## Danh mục file

| File | Code | Số UC |
|---|---|---|
| [`starter-decks.md`](starter-decks.md) | `STARTER` | 1 |
| [`deck.md`](deck.md) | `DECK` | 6 |
| [`card.md`](card.md) | `CARD` | 2 |
| [`study.md`](study.md) | `STUDY` | 3 |
| [`srs.md`](srs.md) | `SRS` | 1 |
| [`transfer.md`](transfer.md) | `TRANSFER` | 2 |
| [`progress.md`](progress.md) | `PROGRESS` | 2 |
| [`settings.md`](settings.md) | `SETTINGS` | 1 |
| [`reminders.md`](reminders.md) | `REMINDER` | 1 |
| [`tags.md`](tags.md) | `TAG` | 1 |
| [`search.md`](search.md) | `SEARCH` | 1 |
| [`trash.md`](trash.md) | `TRASH` | 1 |

---

## Điều đã cố ý không đặc tả

| Thứ | Vì sao |
|---|---|
| Đưa deck con lên thành root deck | Cần quyết định scheduler mới; là tính năng riêng, không phải phép di chuyển (UC-DECK-005 A2) |
| ~~Tìm kiếm card (S1)~~ | **Đã đặc tả** — UC-SEARCH-001 và BR-SEARCH-001…BR-SEARCH-009 phủ tên deck, hai mặt card và tên tag. Ngoài phạm vi v1: fuzzy/semantic search, bỏ dấu, và tìm trong `example`/`hint`/`pronunciation` |
| ~~Thống kê / streak (S2)~~ | **Đã đặc tả** — UC-PROGRESS-001 với BR-PROGRESS-009…BR-PROGRESS-018 chốt đơn vị đếm, partition, streak và phạm vi v1; UC-PROGRESS-002 với BR-PROGRESS-001…BR-PROGRESS-008 chốt tiến độ theo deck; UC-STUDY-002 với BR-STUDY-075…BR-STUDY-077 chốt tab Study đọc thư viện thật |
| Đảo chiều card (S3) | Should-have — **một nửa đã đặc tả**: UC-STUDY-003 và BR-MODE-013…BR-MODE-019 cho phép hỏi ngược trong một phiên `self_assess` của deck `sm2` mà **không** ghi lại thẻ, nên phần còn mở là đảo chiều ở các mode khác |
| ~~Export (nửa còn lại của N1)~~ | **Đã đặc tả** — UC-TRANSFER-002 và BR-TRANSFER-007…BR-TRANSFER-014 chốt scope, encoder, filename, share và quyền riêng tư trước khi viết code, đúng điều kiện mà mục này đặt ra. Còn nice-to-have ngoài phạm vi export nội dung: backup/restore, sync và `.apkg`. |
| ~~Nhắc nhở hằng ngày (N2)~~ | **Đã đặc tả** — UC-REMINDER-001 và BR-REMINDER-001…BR-REMINDER-012 chốt opt-in, phạm vi due-only, riêng tư của copy, thứ tự cấp bách và vòng đời lịch trước khi viết code. Còn ngoài phạm vi: nhắc theo thẻ mới, nhiều lượt nhắc trong ngày, và nhắc theo từng deck. |
| Media trong card | Ngoài MVP; quy tắc reset (BR-SRS-021) đã đặt sẵn, và khi thêm sẽ lưu trong thư mục riêng của ứng dụng như mọi dữ liệu riêng tư khác, không phải bộ nhớ dùng chung. Tag đã rời khỏi hàng này: nó được đặc tả ở BR-TAG-001/BR-TAG-002 và ở UC-TAG-001/BR-TAG-003…BR-TAG-011 |
| Tag phân cấp, màu tag, taxonomy chia sẻ | Ngoài phạm vi Tag Management v1 — UC-TAG-001 chốt tag là nhãn phẳng, là định danh văn bản, không phải hệ thống deck thứ hai |
| Đăng nhập, đồng bộ | Ngoài MVP |
| Scheduler thứ ba | Abstraction đã sẵn sàng; thêm khi có nhu cầu thật |
