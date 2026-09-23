# Use cases — Starter deck

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Đặc tả luồng người dùng của đối tượng STARTER, dưới ID vĩnh viễn `UC-STARTER-nnn` |
| **Scope** | Luồng khởi động lần đầu và chọn starter deck. |
| **Source of truth for** | UC-STARTER-nnn · main/alternative/error flow · UI state matrix |
| **Depends on** | `../document-conventions.md`, `../product/product.md`, `../business-rules/` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

## UC-STARTER-001 · Khởi động lần đầu và chọn starter deck

| | |
|---|---|
| **Status** | active |

**Phạm vi:** sub-project sau — Starter decks (spec §2).

**Actor:** Người dùng mới cài app
**Trigger:** Mở app lần đầu sau khi cài
**Preconditions:** Chưa có deck nào

**Main flow:**
1. Người dùng mở app.
2. Hệ thống khởi tạo database.
3. Người dùng thấy màn hình chưa có deck, kèm hai lối đi: **chọn từ thư viện
   starter** hoặc **tạo deck mới**.
4. Người dùng mở thư viện starter deck.
5. Hệ thống đọc manifest template và hiện danh sách: tên, số card, ngôn ngữ,
   nguồn nội dung. Nội dung starter được ghi rõ là **fixture cho development và
   test** (BR-STARTER-010).
6. Người dùng chọn một starter deck.
7. Hệ thống hỏi **chế độ ôn tập** cho bản sao, gợi ý sẵn `default_scheduler_type`
   của template (BR-STARTER-004).
8. Hệ thống **tạo bản sao** trong một transaction (BR-STARTER-009): root deck mới với
   `content_type = 'deck'`, `root_id = id`, `generation = 1`; toàn
   bộ cây deck con với `content_type` đúng theo template; toàn bộ card; và study
state theo scheduler đã chọn (BR-CARD-004, BR-STARTER-003).
9. Bản sao xuất hiện trong danh sách deck. Toàn bộ card là thẻ **chưa học**
   (`learned_at IS NULL`), nên badge của deck hiện số New chứ không phải số
   đến hạn (BR-STUDY-051, BR-STUDY-046).
10. Người dùng bấm Study và bắt đầu phiên **học mới** ngay.

**Alternative flows:**
- **A1 — Bỏ qua thư viện, tự tạo deck:** đi thẳng UC-DECK-001.
- **A2 — Đã có bản sao từ đúng template và version đó:** hỏi xác nhận, nêu rõ đã
  tồn tại (BR-STARTER-008). Đồng ý thì tạo bản sao thứ hai — lựa chọn có ý thức, khác hoàn
  toàn với việc app tự tạo trùng (BR-STARTER-007).
- **A3 — Cập nhật app có template mới hoặc version mới:** template mới xuất hiện
  trong thư viện. Bản sao đã có **không** bị đụng đến (BR-STARTER-006).
- **A4 — Người dùng đã xoá bản sao:** template vẫn còn trong thư viện, lấy lại
  được.

**Error flows:**
- **E1 — Không mở được database:** màn hình lỗi rõ ràng với hành động thử lại.
  Không được là màn hình trắng — trắng không phân biệt được với treo.
- **E2 — Manifest hỏng hoặc thiếu:** thư viện hiện empty state; app vẫn dùng bình
  thường với luồng tạo deck thủ công.
- **E3 — Một file template hỏng:** bỏ qua đúng template đó, các template khác vẫn
  hiện.
- **E4 — Sao chép thất bại giữa chừng:** transaction rollback (BR-STARTER-009). Không có
  cây deck nửa vời.

**Postconditions:**
- Bản sao có `source_template_id`, `source_template_version`, `scheduler_type` đã
  chọn, `generation = 1`, `first_answered_at = NULL`.
- Mọi deck trong bản sao có `root_id` trỏ đúng root mới (BR-DECK-002).
- Mỗi card có đúng một study state khởi tạo theo scheduler đó.

**Business rules:** BR-CARD-004, BR-STARTER-001…BR-STARTER-009, BR-DECK-002, BR-STARTER-010
**UI states:** initial · loading · loaded · empty · submitting · error
