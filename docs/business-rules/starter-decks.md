# Business rules — Starter deck

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Phát biểu luật nghiệp vụ của đối tượng STARTER, dưới ID vĩnh viễn `BR-STARTER-nnn` |
| **Scope** | Luật starter deck / template. |
| **Source of truth for** | BR-STARTER-nnn của đối tượng này |
| **Depends on** | `../document-conventions.md`, `../product/product.md` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

**Phạm vi:** sub-project sau — Starter decks (spec §2).

## Starter deck (template)

**Phạm vi:** sub-project sau — Starter decks (spec §2).

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-STARTER-001 | active | Starter deck MUST là template, không phải deck của người dùng; MUST NOT xuất hiện trong danh sách deck và MUST NOT ôn trực tiếp được. | rule | UC-STARTER-001 |
| BR-STARTER-002 | active | Template MUST có `template_id` ổn định không đổi giữa các phiên bản app, kèm `version`, `locale`, `title`, `content_source`. | asset | — |
| BR-STARTER-003 | active | Dùng một starter deck MUST tạo bản sao: root deck mới với ID riêng, cây deck con, toàn bộ card, và study state theo scheduler đã chọn. | store | UC-STARTER-001 |
| BR-STARTER-004 | active | Bản sao MUST ghi `source_template_id` và `source_template_version` tại thời điểm sao chép. Template chỉ MAY gợi ý scheduler qua `default_scheduler_type`. | store | UC-STARTER-001 |
| BR-STARTER-005 | active | Sau khi sao chép, bản sao MUST là deck bình thường; MUST NOT có liên kết ghi ngược về template. | rule | — |
| BR-STARTER-006 | active | Nâng version template ở bản app mới MUST NOT ghi đè, sửa hay xoá bất kỳ bản sao nào đã tồn tại. | store | UC-STARTER-001 |
| BR-STARTER-007 | active | Tạo bản sao MUST idempotent theo `(source_template_id, source_template_version)`. | store | UC-STARTER-001 |
| BR-STARTER-008 | active | Người dùng cố ý thêm lại cùng một starter deck MAY được phép, nhưng MUST hỏi xác nhận nêu rõ đã tồn tại. | UI | UC-STARTER-001 |
| BR-STARTER-009 | active | Toàn bộ việc sao chép MUST nằm trong một transaction. | store | UC-STARTER-001 |
| BR-STARTER-010 | active | Nội dung starter hiện tại MUST được mô tả là fixture cho development và test; MUST NOT trình bày như nội dung production. | docs + UI | — |

BR-STARTER-006 và BR-STARTER-007 dễ nhầm là một. BR-STARTER-006 chống ghi đè dữ liệu người dùng khi app cập
nhật; BR-STARTER-007 chống tạo trùng khi mở lại app. Vi phạm BR-STARTER-006 làm mất công sức người
dùng; vi phạm BR-STARTER-007 làm bẩn danh sách deck. Cả hai chỉ lộ ra ở lần cập nhật thứ
hai, nên phải có test riêng cho từng cái.

BR-STARTER-010 tồn tại vì dự án chưa có nguồn nội dung từ vựng có bản quyền rõ ràng.

---

## Edge cases

Đây là **hệ quả** của các rule ở trên, không phải rule mới (§9).

| Case | Expected behaviour |
|---|---|
| Mở app lần đầu | Hiện thư viện starter deck để chọn. Không tự chèn vào dữ liệu người dùng |
| Thêm starter deck đã có bản sao | Hỏi xác nhận nêu rõ đã tồn tại (BR-STARTER-008) |
| Cập nhật app nâng version template | Không đụng vào bản sao đã có (BR-STARTER-006) |
| Bộ nhớ đầy khi sao chép starter deck | Transaction rollback (BR-STARTER-009); không để lại deck nửa vời |
