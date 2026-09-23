# Documentation

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chỉ mục tài liệu — cái gì tồn tại trong `docs/` và ai sở hữu cái gì |
| **Scope** | Toàn bộ `docs/`. Ngoài phạm vi: nội dung của từng tài liệu |
| **Source of truth for** | Danh mục tài liệu · trạng thái từng tài liệu · "đang làm X thì đọc file nào" |
| **Depends on** | `document-conventions.md` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

Format và thứ tự đọc: [`document-conventions.md`](document-conventions.md).

## What exists

| Document | Purpose | Status |
|---|---|---|
| [`document-conventions.md`](document-conventions.md) | Hợp đồng tài liệu: thứ tự đọc, header bắt buộc, template BR/UC/data model, và từ khoá MUST/SHOULD/MAY | frozen for MVP |
| [`product/product.md`](product/product.md) | Vấn đề, người dùng, quyết định nền tảng, và phạm vi MVP | frozen for MVP |
| [`product/master-flow.md`](product/master-flow.md) | Đồ thị nối UC thành hành trình, tách theo đối tượng deck / card / review | active |
| [`superpowers/specs/2026-09-21-memox-v8-foundation-design.md`](superpowers/specs/2026-09-21-memox-v8-foundation-design.md) | Kiến trúc nền tảng V8: Flutter viết lại từ đầu, giữ nghiệp vụ học của V7, không giữ kiến trúc hay cách triển khai của nó | draft for review |
| [`superpowers/specs/2026-09-23-docs-restructure-design.md`](superpowers/specs/2026-09-23-docs-restructure-design.md) | Thiết kế tách `business-rules/`/`use-cases/` theo đối tượng và đánh số lại BR/UC — nguồn của lần renumber duy nhất khi chuyển sang V8 | approved |
| [`business-rules/`](business-rules/README.md) | 269 BR (`BR-<CODE>-nnn`) theo đối tượng: cây deck, card, hai scheduler, session/reset, StudyMode, tiến độ, settings, tìm kiếm, riêng tư, và các sub-project sau (Trash, tags, transfer, starter deck, nhắc học) | frozen for MVP |
| [`data-model.md`](data-model.md) | Schema, cột, index, quan hệ, và các câu query bất biến giữ dữ liệu đúng | active |
| [`use-cases/`](use-cases/README.md) | 22 UC (`UC-<CODE>-nnn`) theo đối tượng cho phạm vi MVP | frozen for MVP |
| [`superpowers/plans/2026-09-21-memox-v8-foundation.md`](superpowers/plans/2026-09-21-memox-v8-foundation.md) | Kế hoạch triển khai nền tảng V8: Flutter skeleton, data model lõi, scheduler SRS thuần Dart, luật cây deck | — |
| [`it-scenarios/`](it-scenarios/) | Bộ kịch bản kiểm thử tích hợp theo hành trình người dùng: điều hướng, bộ thẻ, thẻ ghi nhớ, học và ôn tập | active |
| [`../tools/check_docs_refs.py`](../tools/check_docs_refs.py) | Gate: mọi `BR-<CODE>-nnn`/`UC-<CODE>-nnn`/`invariant Q<n>` được trích dẫn phải phân giải được tới một định nghĩa thật | active |

**ID là vĩnh viễn.** BR, UC và invariant không bao giờ được đánh số lại; luật
mới append vào số tiếp theo **trong đúng file của đối tượng nó ràng buộc**, kể
cả khi nó thuộc phần đầu file — chi tiết và lý do ở
[`document-conventions.md`](document-conventions.md) §7. Việc tách theo đối
tượng và đổi ID sang dạng `BR-<CODE>-nnn` / `UC-<CODE>-nnn` là **lần renumber
duy nhất** của quá trình chuyển sang V8; xem
[`superpowers/specs/2026-09-23-docs-restructure-design.md`](superpowers/specs/2026-09-23-docs-restructure-design.md).

## Đang làm việc trên X → đọc những file nào

| Đang làm việc trên | Đọc |
|---|---|
| Cây deck, tên/xoá deck | [`business-rules/deck.md`](business-rules/deck.md), [`use-cases/deck.md`](use-cases/deck.md) |
| Nội dung card, cờ, di chuyển, chi tiết card | [`business-rules/card.md`](business-rules/card.md), [`use-cases/card.md`](use-cases/card.md) |
| Scheduler `eight_box`/`sm2`, khoá/đổi scheduler, reset | [`business-rules/srs.md`](business-rules/srs.md), [`use-cases/srs.md`](use-cases/srs.md) |
| Phiên ôn tập, hàng đợi, round, Study Home | [`business-rules/study.md`](business-rules/study.md), [`use-cases/study.md`](use-cases/study.md) |
| StudyMode, chuỗi stage, chiều hỏi `self_assess` | [`business-rules/study-mode.md`](business-rules/study-mode.md), [`use-cases/study.md`](use-cases/study.md) |
| Tiến độ theo deck, Progress overview | [`business-rules/progress.md`](business-rules/progress.md), [`use-cases/progress.md`](use-cases/progress.md) |
| Tuỳ chọn ứng dụng (theme, ngôn ngữ, mặc định học) | [`business-rules/settings.md`](business-rules/settings.md), [`use-cases/settings.md`](use-cases/settings.md) |
| Tìm kiếm toàn thư viện | [`business-rules/search.md`](business-rules/search.md), [`use-cases/search.md`](use-cases/search.md) |
| Luật riêng tư chung | [`business-rules/privacy.md`](business-rules/privacy.md) |
| Trash và restore (sub-project sau) | [`business-rules/trash.md`](business-rules/trash.md), [`use-cases/trash.md`](use-cases/trash.md) |
| Tag: mô hình dữ liệu và quản lý (sub-project sau) | [`business-rules/tags.md`](business-rules/tags.md), [`use-cases/tags.md`](use-cases/tags.md) |
| Import/export card (sub-project sau) | [`business-rules/transfer.md`](business-rules/transfer.md), [`use-cases/transfer.md`](use-cases/transfer.md) |
| Starter deck / template (sub-project sau) | [`business-rules/starter-decks.md`](business-rules/starter-decks.md), [`use-cases/starter-decks.md`](use-cases/starter-decks.md) |
| Nhắc học hằng ngày (sub-project sau) | [`business-rules/reminders.md`](business-rules/reminders.md), [`use-cases/reminders.md`](use-cases/reminders.md) |
| Schema, cột, index, bất biến dữ liệu | [`data-model.md`](data-model.md) |
| Kiểm thử tích hợp theo hành trình | [`it-scenarios/`](it-scenarios/) |

## Business rules và use cases theo đối tượng

| Đối tượng | Code | BR file | UC file | Phạm vi |
|---|---|---|---|---|
| Deck | `DECK` | [`deck.md`](business-rules/deck.md) | [`deck.md`](use-cases/deck.md) | V8.0 |
| Card | `CARD` | [`card.md`](business-rules/card.md) | [`card.md`](use-cases/card.md) | V8.0 |
| SRS scheduler | `SRS` | [`srs.md`](business-rules/srs.md) | [`srs.md`](use-cases/srs.md) | V8.0 |
| Study session | `STUDY` | [`study.md`](business-rules/study.md) | [`study.md`](use-cases/study.md) | V8.0 |
| StudyMode | `MODE` | [`study-mode.md`](business-rules/study-mode.md) | — (bên trong `study.md`) | V8.0 |
| Progress | `PROGRESS` | [`progress.md`](business-rules/progress.md) | [`progress.md`](use-cases/progress.md) | V8.0 |
| Settings | `SETTINGS` | [`settings.md`](business-rules/settings.md) | [`settings.md`](use-cases/settings.md) | V8.0 |
| Search | `SEARCH` | [`search.md`](business-rules/search.md) | [`search.md`](use-cases/search.md) | V8.0 |
| Privacy | `PRIVACY` | [`privacy.md`](business-rules/privacy.md) | — | V8.0 |
| Trash | `TRASH` | [`trash.md`](business-rules/trash.md) | [`trash.md`](use-cases/trash.md) | sub-project sau |
| Tags | `TAG` | [`tags.md`](business-rules/tags.md) | [`tags.md`](use-cases/tags.md) | sub-project sau |
| Transfer (import/export) | `TRANSFER` | [`transfer.md`](business-rules/transfer.md) | [`transfer.md`](use-cases/transfer.md) | sub-project sau |
| Starter decks | `STARTER` | [`starter-decks.md`](business-rules/starter-decks.md) | [`starter-decks.md`](use-cases/starter-decks.md) | sub-project sau |
| Reminders | `REMINDER` | [`reminders.md`](business-rules/reminders.md) | [`reminders.md`](use-cases/reminders.md) | sub-project sau |

## The rule that keeps this useful

Tài liệu và code được cập nhật trong cùng một commit. Một tài liệu chậm hơn
code là có hại thật sự — phiên làm việc sau đọc nó, tin nó, và xây tiếp trên
một điều không còn đúng. Nếu một thay đổi làm tài liệu sai, phải sửa tài liệu
đó trước khi merge.
