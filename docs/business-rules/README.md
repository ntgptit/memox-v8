# Business rules — chỉ mục

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Chính sách đánh số ID và chỉ mục các file business rules theo đối tượng |
| **Scope** | Chính sách ID cho `BR-<CODE>-nnn`; danh mục file, code và phạm vi của từng đối tượng. Ngoài phạm vi: nội dung từng rule (từng file `*.md` trong thư mục này) |
| **Source of truth for** | Chính sách đánh số BR · danh mục file business rules |
| **Depends on** | `../document-conventions.md`, `../product/product.md` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

Format tuân theo `../document-conventions.md` §6.2. Từ khoá MUST / SHOULD / MAY
theo §3. Prose **không** chứa từ khoá là giải thích, không phải rule (§9).

## Chính sách đánh số

**ID rule là định danh vĩnh viễn. MUST NOT đánh số lại** (`../document-conventions.md` §7).

ID có dạng `BR-<CODE>-nnn`, ba chữ số, trong đó `<CODE>` là mã đối tượng ở bảng
dưới. Rule mới của một đối tượng append vào số tiếp theo **trong đúng file của
đối tượng đó**.

Đây là **lần đánh số lại duy nhất** của quá trình chuyển sang V8, thực hiện bởi
`docs/superpowers/specs/2026-09-23-docs-restructure-design.md` để mỗi ID tự nói
lên file nó thuộc về. Từ thời điểm này, ID **vĩnh viễn theo đúng nghĩa cũ**:
không đánh số lại lần nữa, không tái sử dụng số đã bỏ trống. Rule bị thay thế
MUST đánh `superseded by BR-<CODE>-nnn` ở cột Status và giữ nguyên ID.

## Danh mục file

| File | Code | Phạm vi |
|---|---|---|
| [`deck.md`](deck.md) | `DECK` | Cây deck, tên và xoá deck (V8.0) |
| [`card.md`](card.md) | `CARD` | Nội dung card, cờ, di chuyển, thao tác hàng loạt, chi tiết card (V8.0) |
| [`srs.md`](srs.md) | `SRS` | Hai scheduler, khoá/đổi scheduler, reset và generation (V8.0) |
| [`study.md`](study.md) | `STUDY` | Vòng đời phiên học, hàng đợi, round, Study Home (V8.0) |
| [`study-mode.md`](study-mode.md) | `MODE` | Tập StudyMode, chuỗi stage, chiều hỏi của `self_assess` (V8.0) |
| [`progress.md`](progress.md) | `PROGRESS` | Tiến độ theo deck và Progress overview (V8.0) |
| [`settings.md`](settings.md) | `SETTINGS` | Tuỳ chọn ứng dụng (V8.0) |
| [`search.md`](search.md) | `SEARCH` | Tìm kiếm toàn thư viện (V8.0) |
| [`privacy.md`](privacy.md) | `PRIVACY` | Luật riêng tư chung (V8.0) |
| [`trash.md`](trash.md) | `TRASH` | Trash và restore (sub-project sau) |
| [`tags.md`](tags.md) | `TAG` | Mô hình dữ liệu tag và quản lý tag (sub-project sau) |
| [`transfer.md`](transfer.md) | `TRANSFER` | Import và export card (sub-project sau) |
| [`starter-decks.md`](starter-decks.md) | `STARTER` | Starter deck / template (sub-project sau) |
| [`reminders.md`](reminders.md) | `REMINDER` | Nhắc học hằng ngày (sub-project sau) |

`tools/check_docs_refs.py` đọc mọi file trong thư mục này khi giải quyết trích
dẫn `BR-<CODE>-nnn`.
